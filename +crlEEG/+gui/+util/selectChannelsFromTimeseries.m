classdef selectChannelsFromTimeseries < handle
  % Select a subset of channels from a crlEEG.type.data.timeseries object
  %
  % obj = crlEEG.gui.util.selectChannelsFromTimeseries(timeseries)
  %
  % Input
  % -----
  %   timeseries : crlEEG.type.data.timeseries object
  %
  %
  properties    
    currChannels
  end
  
  properties (Dependent = true)
    input
    output
  end
  
  properties (Hidden =true)
    setPos = [ 2000 100 110 550]; % In pixels
  end
  
  properties (Access=private)
    gui
    inputInternal
    origChannels
  end
  
  events
    updatedOut
  end
  
  methods
    
    function obj = selectChannelsFromTimeseries(timeseries)      
      if nargin>0       
       obj.input = timeseries;
       obj.currChannels = obj.input.labels;
      end
    end
           
    function set.setPos(obj,val)
      obj.setPos = val;
      if ~isempty(obj.gui)&&ishghandle(obj.gui)
        set(ancestor(obj.gui,'figure'),'Position',obj.setPos);
      end
    end
    
    function editChannels(obj)
      % Raise or open a GUI to edit selected channels
      %
      if ~crlEEG.gui.util.parentfigure.raise(obj.gui)
        
        f = figure('Units','pixels','Position',obj.setPos);
        obj.gui = uicontrol(f,'Style','listbox',...
          'Units','normalized',...
          'Position',[0.02 0.02 0.96 0.96],...
          'Callback',@(h,evt) obj.changeSel);
        set(obj.gui,'Units','normalized');
        obj.syncGUI;
      end
    end
    
    function set.input(obj,timeseries)
      assert(isa(timeseries,'crlEEG.type.data.timeseries'),...
              'Input must be a crlEEG.type.data.timeseries object');
      if ~isequal(obj.inputInternal,timeseries)
        obj.inputInternal = timeseries;
        
        if ~isequal(obj.inputInternal.labels,obj.origChannels)
          % Only update the selected channels if the overall list has
          % changed.
          obj.origChannels = obj.inputInternal.labels;
          obj.currChannels = obj.origChannels;
        else          
          notify(obj,'updatedOut');
        end;        
      end      
    end

    
    function out = get.input(obj)
      out = obj.inputInternal;
    end
    
    function set.currChannels(obj,val)
      % Set method for
      % crlEEG.gui.util.selectChannelsFromTimeseries.selectedStrings
      %
      % Provides input checking, and notifies output when set value is
      % changed (but not otherwise)
      %
      assert(ischar(val)||iscellstr(val),'Input must be a cell string');
      if ischar(val), val = {val}; end;
      if ~isequal(obj.currChannels,val)
        obj.currChannels = val;
        obj.syncGUI;        
        notify(obj,'updatedOut');
      end
    end
    
    function out = get.output(obj)
      out = obj.input(:,obj.currChannels);   
    end
    
  end
  
  methods (Access=private)
    
    function syncGUI(obj)
      % Make sure that the selected channels in the GUI match those in the
      % obj.currChannels
      %disp('SyncingGUI')
      if ~isempty(obj.input)
        if ~isempty(obj.gui)&&ishghandle(obj.gui)
          allChan = obj.input.labels;
          if ~isequal(allChan,obj.gui.String)
            obj.gui.String = allChan;
            obj.gui.Value = 1:numel(allChan);
            obj.gui.Max = numel(allChan);
          end
          
          chanInInput = find(ismember(obj.input.labels,obj.currChannels));
          if ~isequal(chanInInput,obj.gui.Value)
            obj.gui.Value = chanInInput;
          end;
        end
      end;
    end
    
    function changeSel(obj)            
      % Callback function when obj.gui selection changes
      obj.currChannels = obj.input.labels(obj.gui.Value);
    end;
    
    function closeGUI(obj)      
      % Callback to close gui figure.
        crlEEG.gui.util.parentfigure.close(obj.gui);      
    end
  end
  
end