classdef togglePlot < crlEEG.gui.uipanel
  % An interface for crlEEG.gui.data.timeseries data 
  %
  % classdef toggle < uitools.cnlUIObj
  %
  % Provides a UI interface for toggling between a split and a butterfly
  % plot.
  %
  % Written By: Damon Hyde
  % Last Edited: June 1, 2016
  % Part of the cnlEEG Project
  %  
  
  properties (SetObservable,AbortSet)
    timeseries    
    scale
    doSplit = false;
  end
  
  properties
    axes
    plot    
  end
  
  properties (Dependent)
    yrange
  end
  properties (Hidden=true)
    toggleBtn        
    shiftBtn    
  end
  
  properties (Hidden=true,Dependent)
    displayRange
    nDisplay
  end
  
  properties (Access=private)
    internalYRange
    internalChan    
  end
  
  methods
    
    function obj = togglePlot(timeseries,varargin)
   
      %% Input Parsing
      p = inputParser;
      p.KeepUnmatched = true;
      p.addRequired('timeseries',@(x) isa(x,'crlEEG.gui.data.timeseries'));      
      p.addOptional('ax',[],@(x) ishghandle(x)&&strcmpi(get(x,'type'),'axes'));      
      p.addParamValue('yrange',[],@(x) isvector(x)&&(numel(x)==2));
      p.addParamValue('scale',0.5,@(x) isnumeric(x)&&numel(x)==1);
           
      parse(p,timeseries,varargin{:});
                  
      %% Initialize cnlUIObj
      obj = obj@crlEEG.gui.uipanel(...
          'units','pixels',...
          'position',[10 10 600 600]);
      
      obj.ResizeFcn = @(h,evt) obj.resizeToggleplot;
        
      %% Add the Toggle Button
      obj.toggleBtn = uicontrol('Parent',obj.panel,...
        'Style','pushbutton',...
        'String','Split/Butterfly');%,...
        %'Units','pixels',...
        %'Position',[5 5 100 20]);
      set(obj.toggleBtn,'Callback',@(h,evt)obj.toggleSplit);
      %set(obj.toggleBtn,'Units','normalized');
     
                       
      %% Set up Plot Axes
      obj.axes = axes('Parent',obj.panel); %,'Units','Pixels',...
        %'Position',[70 30 300 300]); 
      
      obj.shiftBtn(1) = uicontrol('Parent',obj.panel,...
        'Style','pushbutton',...
        'String','<-',...
        ...%'Units','normalized',...
        ...%'Position',[0.96 axisYstart 0.02 axisYsize/2-0.02],...
        'Callback',@(h,evt) obj.shiftDisplayed(1));
      
      obj.shiftBtn(2) = uicontrol('Parent',obj.panel,...
        'Style','pushbutton',...
        'String','->',...
        ...%'Units','normalized',...
        ...%'Position',[0.96 axisYstart+axisYsize/2 0.02 axisYsize/2-0.02],...
        'Callback',@(h,evt) obj.shiftDisplayed(-1));
              
      % Initial Sizing Callback
      obj.Position = [10 10 600 600];
      
      %% Set Property Values
      obj.timeseries   = p.Results.timeseries;      
      obj.yrange = p.Results.yrange;
      obj.scale  = p.Results.scale;      
            
      % Select Channels to Display. Up to 30 is the default.
      nDisp = 30;
      if size(obj.timeseries.data,2)<nDisp, nDisp = size(obj.timeseries.data,2); end;
      obj.displayRange = [1 nDisp];
      
      % Set Desired UIPanel properties
      obj.setUnmatched(p.Unmatched);
      
      crlEEG.gui.util.setMinFigSize(gcf,obj);
      
      %% Do Initial Display of Plot
      obj.updateImage;
    end
    
    function set.scale(obj,val)
      % Update the image when the scale changes.
      if ~isequal(obj.scale,val)
        obj.scale = val;
        obj.updateImage;
      end;
    end
    
    function val = get.yrange(obj)
      if ~isempty(obj.internalYRange)
        val = obj.internalYRange;
      else
        val = obj.timeseries.yrange;
      end;
    end
    
    function set.yrange(obj,val)
      disp('setting y range');
      if ~isequal(obj.internalYRange,val)
        obj.internalYRange = val;
        disp('Updating from y range')
        obj.updateImage;
      end;       
    end
    
    function set.timeseries(obj,val)
      assert(isa(val,'crlEEG.gui.data.timeseries'),...
              'Must be a crlEEG.gui.data.timeseries object');            
      if ~isequal(obj.timeseries,val)
        % Only update if there's a change.
        obj.timeseries = val;  
        obj.updateImage;
      end;
    end
    
    function resizeToggleplot(obj)
      % Callback to adjust internal sizings of toggleplot uipanel when
      % parent panel is resized.
      
      % Size Definitions
      btnWidth    = 30;
      axesXOffset = 70;
      axesYOffset = 35;
      toggleBtnSize = [ 5 5 100 20];
      
      % Do Everything in Pixels
      currUnits = obj.Units;
      obj.Units = 'pixels';
      pixPos = obj.Position;
      
      xSize = pixPos(3);     
      ySize = pixPos(4);
      
      % Toggle Button in Lower Left Corner
      set(obj.toggleBtn,'Units','pixels');
      set(obj.toggleBtn,'Position',toggleBtnSize);                  
      
      % Axes Offset from Toggle Button
      obj.axes.Units = 'pixels';
      axesPos = get(obj.axes,'Position');
      axesPos(1) = axesXOffset;
      axesPos(2) = toggleBtnSize(2)+axesYOffset;
      axesPos(3) = xSize - axesPos(1) - btnWidth; if axesPos(3)<=0, axesPos(3) = 1; end;
      axesPos(4) = ySize - axesPos(2); if axesPos(4)<=0, axesPos(4) = 1; end;
      set(obj.axes,'Position',axesPos);
      
      % Shift Buttons
      btnHeight = (ySize-axesPos(2)-5)/2;
      set(obj.shiftBtn(1),'Units','pixels');
      set(obj.shiftBtn(1),'Position',[xSize-btnWidth axesPos(2) btnWidth btnHeight]);
      
      set(obj.shiftBtn(2),'Units','pixels');
      set(obj.shiftBtn(2),'Position',[xSize-btnWidth axesPos(2)+btnHeight+5 btnWidth btnHeight]);
      
      %disp(['Panel Position:' num2str(pixPos)]);
      obj.Units = currUnits;
    end
    
    %% Get/Set for obj.nDisplay
    function out = get.nDisplay(obj)
      tmp = obj.displayRange;
      out = tmp(2) - tmp(1) + 1;
    end;
    
    function set.nDisplay(obj,val)
      val = round(val);
      if val==obj.nDisplay
        return;        
      else
        % Reduce Number of Channels
        currRange = obj.displayRange;
        
        newRange = [currRange(1) currRange(1)+val];        
        
        % If we go off the end, add it to the beginning instead
        if newRange(2)>size(obj.timeseries,2)
          extraLen = newRange(2) -size(obj.timeseries,2);
          newRange(2) = size(obj.timeseries,2);
          newRange(1) = newRange(1) - extraLen;
        end
        
        % Can go before the first index
        if newRange(1)<1, newRange(1) = 1; end;
        
        obj.displayRange = newRange;
      end;      
    end
    
    %% Get/Set for obj.displayChannels
    function set.displayRange(obj,val)
      % Set the range of channels to display in the split toggleplot.
      assert(isnumeric(val)&&(numel(val)==2),...
        'Input must be a numeric vector with two elements');
      
      if ( val(1) < 1 )
        val(1) = 1;
      end;
      
      if ( val(2) > size(obj.timeseries,2) )
        val(2) = size(obj.timeseries,2);
      end;
      
      if ~isequal(val,obj.internalChan)
        obj.internalChan = val;
        obj.updateImage;
      end;
    end
    
    function val = get.displayRange(obj)      
      if obj.internalChan(2)>size(obj.timeseries,2)
        obj.internalChan(2) = size(obj.timeseries,2);
      end;
      val = obj.internalChan;
    end
    
    function shiftDisplayed(obj,shiftDir)    
      % Shift the window on which channels are displayed
      shift = shiftDir*round(0.25*obj.nDisplay);
      if shift==0, shift = 1; end;
      
      newRange = obj.displayRange +shift;
      
      if newRange(1)<1, 
        newRange = newRange - newRange(1) + 1; 
      end;
      
      if newRange(2)>size(obj.timeseries,2),
        newRange = newRange - (newRange(2)-size(obj.timeseries,2));
      end;
      
      obj.displayRange = newRange;            
    end
    
    %%
    function toggleSplit(obj)
      % Callback for toggle between a split and butterfly plot
      obj.doSplit = ~obj.doSplit;
      obj.updateImage;
    end
      
    %%
    function updateImage(obj)      
      try
        % Clear axis, and make sure the next plot doesn't modify callbacks
        cla(obj.axes);
        set(obj.axes,'NextPlot','add');
        
        % Plot
        if obj.doSplit % Do a split plot
          dispChan = obj.displayRange(1):obj.displayRange(2);
          obj.plot = crlEEG.gui.render.timeseries.split(obj.timeseries(:,dispChan),obj.axes,...
            'yrange',obj.yrange,'scale',obj.scale);
        else % Just do a butterfly plot
          obj.plot = crlEEG.gui.render.timeseries.butterfly(obj.timeseries,obj.axes,...
            'yrange',obj.yrange);
        end;
        
        notify(obj,'updatedOut');
      catch
      end;
    end
    
  end
  
end