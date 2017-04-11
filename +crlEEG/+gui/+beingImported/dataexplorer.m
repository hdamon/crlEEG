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
        'position',[10 10 610 812]);
     
      %% Initialize Mini Plot
      obj.miniplot = crlEEG.gui.interface.timeseries.windowPlot(...
        p.Results.timeseries,...
        'parent',obj.panel,...
        'units','pixels',...
        'position',[0 0 600 100],...        
        'title',p.Results.title);
      
      %% Initialize Toggle Plot
      obj.toggleplot = crlEEG.gui.interface.timeseries.togglePlot(...
        obj.miniplot.windowSeries,...
        'parent',obj.panel,...
        'units','pixels',...
        'position',[0 100 600 700]);
      
      %% Initialize Time Controls
      obj.playcontrols = crlEEG.gui.widget.timeplay(...
        'parent',obj.panel,...
        'units','pixels',...
        'position',[150 110 450 30],...        
        'units','pixels',...
        'range',[1 size(obj.miniplot.timeseries,1)]);
        
      %% Add listeners 
      obj.listenTo{end+1} = ...
        addlistener(obj.miniplot,'updatedOut',@(h,evt)obj.updateImage);
      obj.listenTo{end+1} = ...
        addlistener(obj.playcontrols,'updatedOut',@(h,evt)obj.updatedIdx);      
      obj.listenTo{end+1} = ...
        addlistener(obj.toggleplot,'updatedOut',@(h,evt) obj.updateLine);    
      
      set(obj.toggleplot.axes,'ButtonDownFcn', @(h,evt) obj.pickXVal(h,evt));
      
      set(get(obj.panel,'Parent'),'KeyPressFcn',@obj.keyPress);
      
     % uitools.setMinFigSize(gcf,obj.origin,obj.size,5);
      
      obj.miniplot.Units = 'normalized';
      obj.toggleplot.Units = 'normalized';
      obj.playcontrols.Units = 'normalized';
      
      %obj.size  = p.Results.size;
      %obj.Units = p.Results.units;
            
      setUnmatched(obj,p.Unmatched);
      
      obj.updateImage;
        
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
    
    function pickXVal(obj,h,varargin)
      pos = get(obj.toggleplot.axes,'CurrentPoint');
      
      xvals = obj.toggleplot.timeseries.xvals;
      idx = find(abs(xvals-pos(1))==min(abs(xvals-pos(1))));
      idx = idx(1);
      range = obj.miniplot.windowStart:obj.miniplot.windowEnd;
      obj.playcontrols.currIdx = range(idx);         
    end
    
    function updateLine(obj)
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
    
    function updateImage(obj)
      
      timeseries = obj.miniplot.windowData;
      xVals = obj.miniplot.windowXVals;
      
      if ( numel(xVals)>10000 )
        pick = round(linspace(1,numel(xVals),10000));
        pick = unique(pick);
        timeseries = timeseries(pick,:);
        xVals = xVals(pick);
      end;
      
      obj.toggleplot.timeseries = timeseries;
      %obj.toggleplot.xvals = xVals;
      obj.toggleplot.updateImage;                        
    end
    
        function keyPress(obj,h,evt)
      % function keyPress(obj,h,evt)
      %
      % Callback for handling arrow keys in the main plot figure;
      %
      % Written By: Damon Hyde
      % Last Edited: Aug 17, 2015
      % Part of the cnlEEG Project
      %
      
      switch evt.Key
        case 'downarrow'
          obj.toggleplot.scale = obj.toggleplot.scale*1.1;
          obj.updateImage;
        case 'uparrow'
          obj.toggleplot.scale = obj.toggleplot.scale*0.9;
          obj.updateImage;
        case 'leftarrow'
          obj.miniplot.shiftWindow(-1);
        case 'rightarrow'
          obj.miniplot.shiftWindow(+1);
      end
    end    
    
    
  end
  
  methods (Static=true,Access=protected)
    function p = parseInputs(varargin)

    end
  end
  
end
    