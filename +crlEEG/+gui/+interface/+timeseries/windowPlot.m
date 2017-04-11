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
  
  properties
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
      p.addRequired('timeseries',@(x) isa(x,'crlEEG.gui.data.timeseries'));
      parse(p,timeseries,varargin{:});
      
      %% Initialize Base Object
      obj = obj@crlEEG.gui.uipanel(...
        'units','pixels',...
        'position',[10 10 600 200]);
      
      %% Initialize Axes
      obj.axes = axes(...
        'Parent',obj.panel,...
        'Units','normalized',...
        'Position',[0.03 0.5 0.94 0.48]);
      
      %% Initialize Zoom Buttons
      obj.zoomButtons = crlEEG.gui.widget.dualbutton(...
        'parent',obj.panel,...
        'units','normalized',...
        'position',[0.01 0.02 0.32 0.45],...
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
        'units','normalized',...
        'position',[0.34 0.02 0.32 0.45],...
        'title','Shift');
      obj.listenTo{end+1} = addlistener(obj.shiftButtons,'leftPushed',...
        @(h,evt) obj.shiftWindow(-1));
      obj.listenTo{end+1} = addlistener(obj.shiftButtons,'rightPushed',...
        @(h,evt) obj.shiftWindow(+1));
      
      %% Initialize Select Buttons
      obj.selButtons = crlEEG.gui.widget.dualbutton(...
        'parent',obj.panel,...
        'units','normalized',...
        'position',[0.67 0.02 0.32 0.45],...
        'title','Select',...
        'leftLabel','Start',...
        'rightLabel','End');
      obj.listenTo{end+1} = addlistener(obj.selButtons,'leftPushed',...
        @(h,evt) obj.setStart);
      obj.listenTo{end+1} = addlistener(obj.selButtons,'rightPushed',...
        @(h,evt) obj.setEnd);
      
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
      
      obj.updateImage;
    end
    
    function adjustZoom(obj,val)
      obj.windowSize = (1+val*obj.zoomScale)*obj.windowSize;
      obj.updateImage;
    end
    
    function nearest = sampleNum(obj,val)
      nearest = abs(val-obj.timeseries.xvals);
      nearest = find(nearest==min(nearest));
    end;
    
    function setEnd(obj)
      k = 1;
      while k==1
        k = waitforbuttonpress;
      end
      newPos = get(obj.axes,'CurrentPoint');
      
      obj.windowEnd = obj.sampleNum(newPos(1,1));
      obj.updateImage;
    end
    
    function setStart(obj)
      k = 1;
      while k==1
        k = waitforbuttonpress;
      end
      newPos = get(obj.axes,'CurrentPoint');
      
      obj.windowStart = obj.sampleNum(newPos(1,1));
      obj.updateImage;
    end;
    
    
    
    %% Methods for Window Size Setting
    function set.windowStart(obj,val)
      
      % Window Always Starts at 1 if data is empty
      if isempty(obj.timeseries), obj.windowStart = 1; return; end;
      
      % Make sure the windowPlot start point is and integer within range
      val = round(min(size(obj.timeseries,1),max(1,val)));
      
      % Update Stored Value
      if val<=obj.storedVals.windowEnd
        obj.storedVals.windowStart = val;
      end;
      
    end
    
    function out = get.windowStart(obj)
      out = obj.storedVals.windowStart;
    end
    
    function set.windowEnd(obj,val)
      % Window always ends at 1 if data is empty
      if isempty(obj.timeseries), obj.windowEnd = 1; return; end;
      
      % Make sure windowPlot end point is an integer within range.
      val = round(min(size(obj.timeseries,1),max(1,val)));
      
      if val>=obj.storedVals.windowStart
        obj.storedVals.windowEnd = val;
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
      if abs(delta)<1, delta = sign(delta); end;
      
      newSize = currSize + round(delta);
      
      obj.windowEnd = obj.windowStart + newSize - 1;
      
    end
    
    function out = get.windowSize(obj)
      out = obj.storedVals.windowEnd - obj.storedVals.windowStart + 1;
    end
    
    %% Methods for Getting the Windowed Data
    function out = get.windowSeries(obj)
      out = obj.timeseries(obj.windowStart:obj.windowEnd,:);
    end;
    
    function out = get.windowData(obj)
      out = obj.timeseries(obj.windowStart:obj.windowEnd,:);
    end
    
    function out = get.windowXVals(obj)
      out = obj.timeseries.xvals(obj.windowStart:obj.windowEnd);
    end
    

    
    %% Methods for Updating the Data Plot
    function updateImage(obj)
      if isempty(obj.timeseries), return; end;
      
      axes(obj.axes);
      
      if (size(obj.timeseries,1) < 10000)
        crlEEG.gui.render.timeseries.butterfly(obj.timeseries,'ax',obj.axes);
      else
        useIdx = round(linspace(1,size(obj.timeseries,1),10000));
        useIdx = unique(useIdx);
        crlEEG.gui.render.timeseries.butterfly(obj.timeseries(useIdx,:),'ax',obj.axes);
      end
      
      YLim = get(obj.axes,'YLim');
      hold on;
      XVal1 = obj.timeseries.xvals(obj.windowStart);
      XVal2 = obj.timeseries.xvals(obj.windowEnd);
      obj.vLine{1} = plot([XVal1 XVal1],[YLim(1) YLim(2)],'r');
      set(obj.vLine{1},'linewidth',2);
      obj.vLine{2} = plot([XVal2 XVal2],[YLim(1) YLim(2)],'r');
      set(obj.vLine{2},'linewidth',2);
      hold off;
      
      XLim(1) = obj.timeseries.xvals(1); XLim(2) = obj.timeseries.xvals(end);
      if (XLim(1)==XLim(2)),
        XLim(1) = XLim(1) - 0.1;
        XLim(2) = XLim(2) + 0.1;
      end;
      
      axis([XLim(1) XLim(2) YLim(1) YLim(2)]);
      notify(obj,'updatedOut');
      
    end
    
    
    
  end
  
  methods (Static=true,Access=protected)
    function p = parseInputs(varargin)
      
    end
  end
  
end
