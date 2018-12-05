classdef dualPlot < MatTSA.gui.timeseries.dualPlot
  % Subclassed dualPlot for crlEEG.EEG objects
  %
  
  properties
  end
  
  methods
    
    function obj = dualPlot(EEG,varargin)     
      obj = obj@MatTSA.gui.timeseries.dualPlot(EEG,varargin{:});
      
%       obj.listenTo{end+1} = ...
%         addlistener(obj.miniplot,'updatedOut',@(h,evt) obj.plotEventsOnMini);
      obj.plotEventsOnMini;
      
      obj.listenTo{end+1} = ...
        addlistener(obj.toggleplot,'updatedOut',@(h,evt) obj.plotEventsOnToggle);
      obj.plotEventsOnToggle;
    end
    
    function updateToggle(obj)
      updateToggle@MatTSA.gui.timeseries.dualPlot(obj);         
    end
    
    function updateWindow(obj)
      updateWindow@MatTSA.gui.timeseries.dualPlot(obj);
    end
    
    function plotEventsOnToggle(obj)
      tmpEVENTS = obj.toggleplot.timeseries.EVENTS;
      if ~isempty(tmpEVENTS)              
        tmpEVENTS.plot(obj.toggleplot.axes,'LineWidth',2);
      end
    end
    
    function plotEventsOnMini(obj)
      tmpEVENTS = obj.miniplot.timeseries.EVENTS;
      if ~isempty(tmpEVENTS)
        tmpEVENTS.plot(obj.miniplot.axes,'LineWidth',2);
      end
    end
    
    function captureMouseClick(obj,h,varargin)
      a = ancestor(obj.toggleplot.axes,'Figure');
      selType = a.SelectionType;
      switch lower(selType)
        case 'alt'
          c = uicontextmenu('Visible','on');
          obj.toggleplot.axes.UIContextMenu = c;
          m1 = uimenu(c,'Label','Mark Event');
          m2 = uimenu(c,'Label','bar');
          m3 = uimenu(c,'Label','baz');
          m(4) = uimenu(c,'Label','Cancel');          
        otherwise
          captureMouseClick@MatTSA.gui.timeseries.dualPlot(obj,h,varargin{:});
      end
      
    end
    
  end
  
end
