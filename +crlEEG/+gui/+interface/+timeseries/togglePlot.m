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
    yrange
    scale
    doSplit = false;
  end
  
  properties
    axes
    plot    
  end
  
  properties (Hidden=true)
    toggleBtn    
    shiftBtn
    displayChannels
  end
  
  methods
    
    function obj = togglePlot(timeseries,varargin)
   
      %% Input Parsing
      p = inputParser;
      p.KeepUnmatched = true;
      p.addRequired('timeseries',@(x) isa(x,'crlEEG.gui.data.timeseries'));      
      p.addOptional('ax',[],@(x) ishghandle(x)&&strcmpi(get(x,'type'),'axes'));      
      p.addParamValue('yrange',timeseries.yrange,@(x) isvector(x)&&(numel(x)==2));
      p.addParamValue('scale',1,@(x) isnumeric(x)&&numel(x)==1);
           
      parse(p,timeseries,varargin{:});
                  
      %% Initialize cnlUIObj
      obj = obj@crlEEG.gui.uipanel(...
          'units','pixels',...
          'position',[10 10 600 600]);
      
      %% Add the Toggle Button
      obj.toggleBtn = uicontrol('Parent',obj.panel,...
        'Style','pushbutton',...
        'String','Toggle Split View',...
        'Units','pixels',...
        'Position',[5 5 125 30]);
      set(obj.toggleBtn,'Callback',@(h,evt)obj.toggleSplit);
      set(obj.toggleBtn,'Units','normalized');
      pos = get(obj.toggleBtn,'Position');
      
      %% Set up the Plot Axis
      axisYstart = pos(2)+pos(4)+0.05;
      axisYsize = 0.99 - axisYstart;
      
      obj.axes = axes('Parent',obj.panel,'Units','Normalized',...
        'Position',[0.1 axisYstart 0.85 axisYsize]); 
      
      obj.shiftBtn(1) = uicontrol('Parent',obj.panel,...
        'Style','pushbutton',...
        'String','<-',...
        'Units','normalized',...
        'Position',[0.96 axisYstart 0.02 axisYsize/2-0.02],...
        'Callback',@(h,evt) obj.shiftDisplayed(1));
      
      obj.shiftBtn(2) = uicontrol('Parent',obj.panel,...
        'Style','pushbutton',...
        'String','->',...
        'Units','normalized',...
        'Position',[0.96 axisYstart+axisYsize/2 0.02 axisYsize/2-0.02],...
        'Callback',@(h,evt) obj.shiftDisplayed(-1));
              
      %% Set Property Values
      obj.timeseries   = p.Results.timeseries;      
      obj.yrange = p.Results.yrange;
      obj.scale  = p.Results.scale;      
            
      nDisp = 30;
      if size(obj.timeseries.data,2)<nDisp, nDisp = size(obj.timeseries.data,2); end;
      obj.displayChannels = 1:nDisp;
      
      % Set Desired UIPanel properties
      obj.setUnmatched(p.Unmatched);
      
      %% Do Initial Display of Plot
      obj.updateImage;
    end
    
    function shiftDisplayed(obj,shiftDir)      
      dispIdx = obj.displayChannels;
      shift = round(0.25*numel(dispIdx))*shiftDir;
      maxIdx = size(obj.timeseries,2);     
      tmp = dispIdx + shift;
      if any(tmp-maxIdx>0), shift = shift-(max(tmp)-maxIdx); end;
      if any(tmp<1), shift = shift - (min(tmp) - 1); end;
      obj.displayChannels = dispIdx + shift;      
      obj.updateImage;
    end
    
    function toggleSplit(obj)
      % Function toggle between a split and butterfly plot
      obj.doSplit = ~obj.doSplit;
      obj.updateImage;
    end
            
    function updateImage(obj)
      axes(obj.axes);
      cla;                 
                  
      if obj.doSplit % Do a split plot
        dispChan = obj.displayChannels;
        obj.plot = crlEEG.gui.render.timeseries.split(obj.timeseries(:,dispChan),obj.axes,...
                                    'yrange',obj.yrange,'scale',obj.scale);
      else % Just do a butterfly plot
        obj.plot = crlEEG.gui.render.timeseries.butterfly(obj.timeseries,obj.axes,...
                                          'yrange',obj.yrange);
      end;
         
      notify(obj,'updatedOut');
    end
    
  end
  
end