classdef dataexplorer < crlEEG.gui.uipanel
  % Tool for exploring time series timeseries
  %
  % classdef dataexplorer < uitools.baseobjs.gui
  %
  % Written By: Damon Hyde
  % Last Edited: June 10, 2016
  % Part of the cnlEEG Project
  %
  
  
  properties (Dependent=true)
    currIdx
    externalSync
  end
    
  properties (Dependent=true, Hidden=true)
    selectedX    
  end
  
  properties (SetAccess=protected)
    miniplot
    toggleplot
    playcontrols
    chanselect
    displayChannels
    vLine
  end
  
  methods
    
    function obj = dataexplorer(timeseries,varargin)
      
      p = inputParser;
      p.addRequired('timeseries',@(x) isa(x,'crlEEG.gui.data.timeseries'));
      p.addParamValue('title','TITLE', @(x) ischar(x));
      parse(p,timeseries);           
           
      %% Initialize Base Object
      obj = obj@crlEEG.gui.uipanel(...
        'units','pixels',...
        'position',[10 10 600 807]);
      obj.ResizeFcn = @(h,evt) obj.resizeInternals;
     
      % Set up the channel selection object
      obj.chanselect = crlEEG.gui.util.selectChannelsFromTimeseries;
      obj.chanselect.input = p.Results.timeseries;
      
      %% Initialize Mini Plot
      obj.miniplot = crlEEG.gui.interface.timeseries.windowPlot(...
        obj.chanselect.output,...
        'parent',obj.panel,...
        'units','pixels',...
        'position',[0 5 600 100],...        
        'title',p.Results.title);
      obj.miniplot.Title = [];
                       
      %% Initialize Toggle Plot
      obj.toggleplot = crlEEG.gui.interface.timeseries.togglePlot(...
        obj.chanselect.output,...
        'parent',obj.panel,...
        'units','pixels',...
        'position',[0 105 600 700]);
      
      %% Initialize Time Controls
      obj.playcontrols = crlEEG.gui.widget.timeplay(...
        'parent',obj.panel,...
        'units','pixels',...
        'position',[325 10 400 30],...        
        'units','pixels',...
        'range',[1 size(obj.miniplot.timeseries,1)]);
                    
      %% Add listeners 
      % Update the toggleplot whenever the miniplot updates
      obj.listenTo{end+1} = ...
        addlistener(obj.miniplot,'updatedOut',@(h,evt) obj.updateImage);
      obj.listenTo{end+1} = ...
        addlistener(obj.chanselect,'updatedOut',@(h,evt) obj.updateMini);
      % Update the current index whenever the automated player updates
      obj.listenTo{end+1} = ...
        addlistener(obj.playcontrols,'updatedOut',@(h,evt)obj.updatedIdx);      
      % Update the displayed line whenever the toggleplot updates
      obj.listenTo{end+1} = ...
        addlistener(obj.toggleplot,'updatedOut',@(h,evt) obj.updateLine);    
      
      set(obj.toggleplot.axes,'ButtonDownFcn', @(h,evt) obj.captureMouseClick(h,evt));
      
      set(get(obj.panel,'Parent'),'KeyPressFcn',@obj.keyPress);
      
     % uitools.setMinFigSize(gcf,obj.origin,obj.size,5);
      
      obj.miniplot.Units = 'normalized';
      obj.toggleplot.Units = 'normalized';      
      
      %obj.size  = p.Results.size;
      %obj.Units = p.Results.units;
            
      setUnmatched(obj,p.Unmatched);
      
      crlEEG.gui.util.setMinFigSize(gcf,obj);
      set(obj,'Units','normalized');
      obj.resizeInternals;
      obj.updateImage;
        
    end
    
    function resizeInternals(obj)
      
      currUnits = obj.Units;
      obj.Units = 'pixels';
      pixPos = obj.Position;
      
      % Get Figure Position
      figPos = getpixelposition(ancestor(obj,'figure'));
      newPos = [figPos(1)-110 figPos(2) 110 figPos(4)];
      obj.chanselect.setPos = newPos;
      
      obj.Units = currUnits;      
    end
    
    function set.externalSync(obj,val)
      if val
        obj.playcontrols.externalSync = true;
        obj.listenTo{2}.Recursive = true;
      else
        obj.playcontrols.externalSync = false;
        obj.listenTo{2}.Recursive = false;
      end
    end
    
    function out = get.externalSync(obj)
      out = obj.playcontrols.externalSync;
    end;
    
    function nextStep(obj)
      obj.playcontrols.nextStep;
    end;
    
    function out = get.selectedX(obj)
      warning('dataexplorer.selectedX is a deprecated property. Use dataexplorer.currIdx instead');
      out = obj.currIdx;
    end
    
    function out = get.currIdx(obj)
      out = [];
      if ~isempty(obj.playcontrols)
      out = obj.playcontrols.currIdx;      
      end;
    end;
    
    function updatedIdx(obj)
      % Callback when obj.playcontrols.currIdx updates
      %
      %
      shiftLeft = obj.playcontrols.currIdx<obj.miniplot.windowStart;
      shiftRight = obj.playcontrols.currIdx>obj.miniplot.windowEnd;
      if ~(shiftLeft||shiftRight)
        obj.updateLine;
      elseif shiftLeft
        obj.miniplot.shiftWindow(-5);
      elseif shiftRight
        obj.miniplot.shiftWindow(+5);
      end            
      notify(obj,'updatedOut');
      
    end
    
    function captureMouseClick(obj,h,varargin)
      % ButtonDwnFcn callback for the main data plot axes
      %
      %
      
      a = ancestor(obj.toggleplot.axes,'Figure');
      selType = a.SelectionType;
      switch lower(selType)
        case 'normal'
          obj.pickXVal;
        case 'alt'         
          c = uicontextmenu('Visible','on');
          obj.toggleplot.axes.UIContextMenu = c;
          m1 = uimenu(c,'Label','Mark Event');
          m2 = uimenu(c,'Label','bar');
          m3 = uimenu(c,'Label','baz');
          m(4) = uimenu(c,'Label','Cancel');
        case 'open'
          disp('doubleclick');
        otherwise
          keyboard;
          error('Unknown selection type');
      end      
    end
    
    function pickXVal(obj)
      % ButtonDwnFcn callback for the main data plot axes
      %
      
      pos = get(obj.toggleplot.axes,'CurrentPoint');
      %disp(['Current Position: ' num2str(pos(1))]);
      xvals = obj.miniplot.windowSeries.xvals;
      idx = find(abs(xvals-pos(1))==min(abs(xvals-pos(1))));
      idx = idx(1);
      range = obj.miniplot.windowStart:obj.miniplot.windowEnd;
      %disp(['Current Idx: ' num2str(range(idx))]);
      obj.playcontrols.currIdx = range(idx);         
    end
    
    
    function updateLine(obj)
      % Update (plot) the vertical line denoting the currently selected
      % timepoint.
      range = obj.miniplot.windowStart:obj.miniplot.windowEnd;
      if ~isempty(obj.vLine)&&ishandle(obj.vLine)        
        delete(obj.vLine);        
      end;
      if ~isempty(obj.playcontrols.currIdx)
        if ismember(obj.playcontrols.currIdx,range)
          xVal = obj.miniplot.timeseries.xvals(obj.playcontrols.currIdx);
          yRange = get(obj.toggleplot.axes,'YLim');
          axes(obj.toggleplot.axes); hold on;
          tmp = get(obj.toggleplot.axes,'ButtonDownFcn');
          obj.vLine = plot([xVal xVal],yRange,'r','linewidth',2,...
            'ButtonDownFcn',tmp);
          set(obj.toggleplot.axes,'ButtonDownFcn',tmp);
          hold off;
            
        end
      end      
    end
    
    function updateMini(obj)
      obj.miniplot.timeseries = obj.chanselect.output;
      %obj.chanselect.input = obj.miniplot.windowSeries;
    end
    
    function updateImage(obj)
      % Update the data set associated with the toggleplot.
      %
      
      % Get new timeseries with a restricted list of channels
      timeseries = obj.miniplot.windowSeries;
            
      % Subsample time to reduce plot complexity, if needed.
      xVals = timeseries.xvals;
      if ( numel(xVals)>10000 )
        pick = round(linspace(1,numel(xVals),10000));
        pick = unique(pick);
        timeseries = timeseries(pick,:);        
      end;
      
      obj.toggleplot.timeseries = timeseries;     
      obj.toggleplot.yrange = obj.chanselect.output.yrange;                      
    end
    
    function keyPress(obj,h,evt)
      % function keyPress(obj,h,evt)
      %
      % Callback for handling arrow keys in the main plot figure;
      %
      
      switch evt.Key
        case 'downarrow'
          obj.toggleplot.scale = obj.toggleplot.scale*1.1;          
        case 'uparrow'
          obj.toggleplot.scale = obj.toggleplot.scale*0.9;          
        case 'leftarrow'
          obj.miniplot.shiftWindow(-1);
        case 'rightarrow'
          obj.miniplot.shiftWindow(+1);
        case 'pageup'
          if isempty(evt.Modifier)
            str = '';
          else
            str = evt.Modifier{1};
          end;
          switch str
            case 'shift'           
              % Ensure the number of display channels is always increased
              % by at least 1
              newdisplay = round(1.1*obj.toggleplot.nDisplay);
              if newdisplay ==obj.toggleplot.nDisplay,
                newdisplay = newdisplay + 1;
              end;
              obj.toggleplot.nDisplay = newdisplay;
            otherwise              
              obj.toggleplot.shiftDisplayed(-1);
          end;
        case 'pagedown'
          if isempty(evt.Modifier)
            str = '';
          else
            str = evt.Modifier{1};
          end;
            
          switch str
            case 'shift'     
              % Ensure the number of displayed channels is always decreased
              % by at least 1.
              newdisplay = round(0.9*obj.toggleplot.nDisplay);
              if newdisplay==obj.toggleplot.nDisplay
                newdisplay = newdisplay - 1;
              end
              obj.toggleplot.nDisplay = newdisplay;
            otherwise
             obj.toggleplot.shiftDisplayed(1);
          end;
      end
    end    
    
    
  end
  
  methods (Static=true,Access=protected)
    function p = parseInputs(varargin)

    end
  end
  
end
    