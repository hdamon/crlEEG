classdef windowPlot < crlEEG.gui.uipanel
  % Plot for Selecting a Sub-Window of Time Data
  %
  % classdef windowPlot < crlEEG.gui.uipanel
  %
  % p = uitools.plots.windowPlot(data,varargin)
  %
  % Inputs:
  %   data : nSamples x nChannels Data Matrix
  %
  % Param-Value Pairs:
  %   xvals : x-Axis Values for Each of the N Samples
  %
  % Events:
  %   updatedOut : Notified when the displayed image is updated through
  %                 a call to updateImage.
  %
  % Written By: Damon Hyde
  % Last Edited: June 8, 2016
  % Part of the cnlEEG Project
  %
  
  properties (Dependent=true)
    timeseries
  end
  
  properties (Hidden = true)
    axes
  end
  
  properties (Dependent = true)
    % Tracking of Window Size/Location
    windowStart % Value stored in storedVals.windowStart
    windowEnd   % Value stored in storedVals.windowEnd
    windowSize  % Computed from windowStart and windowEnd
    
    windowData
    windowRange
    windowIdx
    windowXVals
    windowSeries
  end
  
  properties (Hidden=true,SetAccess=protected)
    storedVals
    
    zoomButtons
    zoomScale = 0.1;
    
    shiftButtons
    shiftScale = 0.1;
    
    selButtons
    
    vLine
    
  end
  
  methods
    function obj = windowPlot(timeseries,varargin)
      %% uitools.plots.windowPlot object constructor
      
      %% Input Parsing
      p = inputParser;
      p.KeepUnmatched = true;
      p.addRequired('timeseries',@(x) isa(x,'crlEEG.type.data.timeseries'));
      parse(p,timeseries,varargin{:});
      
      %% Initialize Base Object
      obj = obj@crlEEG.gui.uipanel(...
        'units','pixels',...
        'position',[10 10 500 150]);
      obj.ResizeFcn = @(h,evt) obj.resizeInternals;
      
      %% Initialize Axes
      obj.axes = axes('Parent',obj.panel);
      
      %% Initialize Zoom Buttons
      obj.zoomButtons = crlEEG.gui.widget.dualbutton(...
        'parent',obj.panel,...
        'leftLabel','-',...
        'rightLabel','+',...
        'title','Zoom');
      obj.listenTo{end+1} = addlistener(obj.zoomButtons,'leftPushed',...
        @(h,evt) obj.adjustZoom(+1));
      obj.listenTo{end+1} = addlistener(obj.zoomButtons,'rightPushed',...
        @(h,evt) obj.adjustZoom(-1));
      
      %% Initialize Shift Buttons
      obj.shiftButtons = crlEEG.gui.widget.dualbutton(...
        'parent',obj.panel,...
        'title','Shift');
      obj.listenTo{end+1} = addlistener(obj.shiftButtons,'leftPushed',...
        @(h,evt) obj.shiftWindow(-1));
      obj.listenTo{end+1} = addlistener(obj.shiftButtons,'rightPushed',...
        @(h,evt) obj.shiftWindow(+1));
      
      %% Initialize Select Buttons
      obj.selButtons = crlEEG.gui.widget.dualbutton(...
        'parent',obj.panel,...
        'title','Select',...
        'leftLabel','Start',...
        'rightLabel','End');
      obj.listenTo{end+1} = addlistener(obj.selButtons,'leftPushed',...
        @(h,evt) obj.setStart(h,evt));
      obj.listenTo{end+1} = addlistener(obj.selButtons,'rightPushed',...
        @(h,evt) obj.setEnd(h,evt));
      
      obj.resizeInternals;
      
      %% Adjust figure size
      %uitools.setMinFigSize(gcf,obj.origin,obj.size,5);
      
      %% Initialize stored values
      obj.storedVals.windowStart = 1;
      obj.storedVals.windowEnd   = 1;
      
      %% Set Data, xvals, and initial windowPlot size, then draw
      obj.timeseries = p.Results.timeseries;
      obj.windowSize = size(obj.timeseries,1);
      
      setUnmatched(obj,p.Unmatched);
      
      obj.updateImage;
      
    end
    
    function val = get.timeseries(obj)
      if isfield(obj.storedVals,'timeseries')
        val = obj.storedVals.timeseries;
      else
        % Return an empty timeseries?
        val = []; %crlEEG.type.data.timeseries;
      end;
    end;
    
    function set.timeseries(obj,val)
      % Set Method for crlEEG.gui.timeseries.interface.windowPlot
      %
      %
      
      % Input Checking
      if isempty(val), obj.storedVals.timeseries = []; return; end;
      crlEEG.assert.instanceOf('crlEEG.type.data.timeseries',val);
      
      if isfield(obj.storedVals,'timeseries')
        if ~isequal(obj.storedVals.timeseries,val)
          obj.storedVals.timeseries = val;
          obj.windowStart = 1;
          obj.windowEnd = size(obj.storedVals.timeseries,1);
          obj.updateImage;          
        end;
      else
        obj.storedVals.timeseries = val;
        obj.windowStart = 1;
        obj.windowEnd = size(obj.storedVals.timeseries,1);
        obj.updateImage;        
      end;
      
    end;    
      
    
    function resizeInternals(obj)
      currUnits = obj.Units;
      obj.Units = 'pixels';
      pixPos = obj.Position;
      
      obj.zoomButtons.Units = 'pixels';
      obj.zoomButtons.Position = [5 5 100 35];
      
      obj.shiftButtons.Units = 'pixels';
      obj.shiftButtons.Position = [110 5 100 35];
      
      obj.selButtons.Units = 'pixels';
      obj.selButtons.Position = [215 5 100 35];      
                  
      axesPos = [5 41 pixPos(3)-10 pixPos(4)-41];
      if axesPos(3)<1, axesPos(3) = 1; end;
      if axesPos(4)<1, axesPos(4) = 1; end;
      
      set(obj.axes,'Units','Pixels');
      set(obj.axes,'Position',axesPos);
                  
      
      % Set units back to where they were
      obj.Units = currUnits;
    end
    
    
    %% Button Callback Functions
    function shiftWindow(obj,val)
      shift = val*obj.shiftScale*obj.windowSize;
      
      % Always shift by at least one sample
      if floor(shift)==0, shift = sign(shift); end;
      
      boundLeft = (obj.windowStart+shift <= 0);
      boundRght = (obj.windowEnd  +shift > size(obj.timeseries,1));
      
      currSize = obj.windowSize;
      if boundLeft
        obj.windowStart = 1;
        obj.windowEnd   = obj.windowStart + currSize - 1;
      elseif boundRght
        obj.windowStart = size(obj.timeseries,1) - currSize + 1;
        obj.windowEnd = size(obj.timeseries,1);
      else
        obj.windowStart = obj.windowStart + shift;
        obj.windowEnd = obj.windowEnd + shift;
      end;
            
    end
    
    function adjustZoom(obj,val)
      obj.windowSize = (1+val*obj.zoomScale)*obj.windowSize;      
    end
    
    function nearest = sampleNum(obj,val)
      % Return sample number nearest to requested X value
      %
      % nearest = sampleNum(obj,val)
      %
      nearest = abs(val-obj.timeseries.xvals);
      nearest = find(nearest==min(nearest));
    end;
    
    function setEnd(obj,h,evt)
      % Callback for graphically setting end position
      k = 1;
      while k==1
        k = waitforbuttonpress;
      end
      newPos = get(obj.axes,'CurrentPoint');
      
      obj.windowEnd = obj.sampleNum(newPos(1,1));      
    end
    
    function setStart(obj,h,evt)
      % Callback for graphically setting start position
      k = 1;
      while k==1
        k = waitforbuttonpress;
      end
      newPos = get(obj.axes,'CurrentPoint');
      
      obj.windowStart = obj.sampleNum(newPos(1,1));      
    end;
    
    
    
    %% Methods for Window Size Setting
    function set.windowStart(obj,val)
      
      % Window Always Starts at 1 if data is empty
      if isempty(obj.timeseries), obj.windowStart = 1; return; end;
      
      % Make sure the windowPlot start point is an integer within range
      val = round(min(size(obj.timeseries,1),max(1,val)));
      
      % Update Stored Value
      if val<=obj.storedVals.windowEnd&&...
          obj.storedVals.windowEnd~=val
        obj.storedVals.windowStart = val;
        obj.updateLine(1,obj.storedVals.windowStart);
        notify(obj,'updatedOut');
      end;
      
    end
    
    function out = get.windowStart(obj)
      out = obj.storedVals.windowStart;
    end
    
    function set.windowEnd(obj,val)
      % Window always ends at 1 if data is empty
      if isempty(obj.timeseries), obj.storedVals.windowEnd = 1; return; end;
      
      % Make sure windowPlot end point is an integer within range.
      val = round(min(size(obj.timeseries,1),max(1,val)));
      
      if val>=obj.storedVals.windowStart&&...
          obj.storedVals.windowEnd ~= val
        obj.storedVals.windowEnd = val;
        obj.updateLine(2,obj.storedVals.windowEnd);
        notify(obj,'updatedOut');
      end
    end
    
    function out = get.windowEnd(obj)
      out = obj.storedVals.windowEnd;
    end;
    
    function set.windowSize(obj,val)
      
      % Do nothing if it's a negative value
      if (val<=0), return; end;
      
      currSize = obj.storedVals.windowEnd - obj.storedVals.windowStart + 1;
      
      delta = val - currSize;
      if abs(delta)<2, delta = sign(delta); end;
      delta = round(delta);
      
      obj.windowStart = obj.windowStart - delta/2;
      obj.windowEnd = obj.windowEnd + delta/2;
            
    end
    
    function out = get.windowSize(obj)
      out = obj.storedVals.windowEnd - obj.storedVals.windowStart + 1;
    end
    
    %% Methods for Getting the Windowed Data
    function out = get.windowSeries(obj)
      out = obj.timeseries(obj.windowStart:obj.windowEnd,:);
    end;
    
    function out = get.windowData(obj)
      warning(['crlEEG.gui.timeseries.interface.windowPlot.windowData '...
               'is deprecated. Use '...
               'crlEEG.gui.timeseries.interface.windowPlot.windowSeries ' ...
               'instead.']);
      out = obj.windowSeries;
    end
    
    function out = get.windowXVals(obj)
      warning('This functionality is deprecated. use obj.windowSeries.xvals instead');
      out = obj.timeseries.xvals(obj.windowStart:obj.windowEnd);
    end
        
    %% Methods for Updating the Data Plot
    function updateImage(obj)
      % Complete redraw of windowPlot
      %
      
      if isempty(obj.timeseries), return; end;      
      axes(obj.axes);
            
      if (size(obj.timeseries,1) < 10000)
        crlEEG.gui.timeseries.render.butterfly(obj.timeseries,'ax',obj.axes);
      else
        % For data sets with greater than 10k data points, only plot a
        % subsample of the data 
        useIdx = round(linspace(1,size(obj.timeseries,1),10000));
        useIdx = unique(useIdx);
        crlEEG.gui.timeseries.render.butterfly(obj.timeseries(useIdx,:),'ax',obj.axes);
      end      
      
      % Catch zero-length X axes definitions.
      XLim(1) = obj.timeseries.xvals(1); XLim(2) = obj.timeseries.xvals(end);
      if (XLim(1)==XLim(2)),
        XLim(1) = XLim(1) - 0.1;
        XLim(2) = XLim(2) + 0.1;
      end;
      YLim = get(obj.axes,'YLim'); 
      
      %set(obj.axes,'XTick',[]);
      set(obj.axes,'YTick',[]);
      
      XTick = get(obj.axes,'XTick');
      Label = get(obj.axes,'XTickLabel');
               
      axis(obj.axes);
      for i = 1:numel(XTick)
        text(XTick(i), YLim(1) + 0.1*(YLim(2)-YLim(1)),Label{i});
        obj.axes.XTickLabel{i} = '';
      end;
      %set(obj.axes,'XTickLabel',[]);
            
      axis([XLim(1) XLim(2) YLim(1) YLim(2)]);
      
      obj.drawLines;            
    end
    

    function updateLine(obj,linenum,idx)
      % Method to update individual vertical lines in a windowPlot
      XVal = obj.timeseries.xvals(idx);      
      if numel(obj.vLine)==2
        % Can only update if we've already plotted both.
        set(obj.vLine{linenum},'XData',XVal*[1 1])
      end;
    end;
    
              
    function drawLines(obj)
      % Draw the vertical lines denoting the boundary of the selected
      % region
      %
     
      axes(obj.axes);
      hold on;      
      XVal = obj.timeseries.xvals([obj.windowStart obj.windowEnd]);
      YLim = get(obj.axes,'YLim'); 

      obj.vLine{1} = plot(XVal(1)*[1 1],YLim,'r');       
      set(obj.vLine{1},'linewidth',2);
      obj.vLine{2} = plot(XVal(2)*[1 1],YLim,'r');
      set(obj.vLine{2},'linewidth',2);      
      hold off;            
    end    
    
  end
  
  methods (Static=true,Access=protected)
    function p = parseInputs(varargin)
      
    end
  end
  
end
