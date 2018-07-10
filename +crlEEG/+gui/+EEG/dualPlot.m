classdef dualPlot < MatTSA.gui.timeseries.dualPlot
  % Subclassed dualPlot for crlEEG.EEG objects
  %
  
  properties
  end
  
  methods
    
    function obj = dualPlot(EEG,varargin)     
      obj = obj@MatTSA.gui.timeseries.dualPlot(EEG,varargin{:});
      
      obj.listenTo{end+1} = ...
        addlistener(obj.toggleplot,'updatedOut',@(h,evt) obj.plotEvents);
      obj.plotEvents;
    end
    
    function updateToggle(obj)
      updateToggle@MatTSA.gui.timeseries.dualPlot(obj);         
    end
    
    function plotEvents(obj)
      tmpEVENTS = obj.toggleplot.timeseries.EVENTS;
      for i = 1:numel(tmpEVENTS)
        tmpEVENTS(i).plot(obj.toggleplot.axes,'LineWidth',2);
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
