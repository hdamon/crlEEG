classdef dualbutton < crlEEG.gui.uipanel
  % UI Object for Dual Button Panel
  %
  % Create a uiPanel with two buttons in it.
  %
  % Written By: Damon Hyde
  % Last Edited: Jun 8, 2016
  % Part of the cnlEEG Project
  %
  
  properties (Dependent=true)
    leftLabel
    rightLabel
  end
  
  properties (Access=protected)
    LButton
    RButton
  end
  
  events
    leftPushed
    rightPushed
  end
  
  methods
    
    function obj = dualbutton(varargin)

      %% Input Parsing
      p = inputParser;
      p.KeepUnmatched = true;
      addParamValue(p,'leftLabel','<-');
      addParamValue(p,'rightLabel','->');
      parse(p,varargin{:});
            
      %% Initialize UI Objects
      obj = obj@crlEEG.gui.uipanel(...        
        'units','pixels',...
        'position',[10 10 200 50]);
                     
      % Initialize Left Button Object
      obj.LButton = uicontrol(...
        'Parent',obj.panel,...
        'Style','pushbutton',...
        'String',p.Results.leftLabel,...
        'Units','normalized',...
        'Position', [0.02 0.02 0.47 0.96]);
      set(obj.LButton,'Callback',@(h,evt) notify(obj,'leftPushed'));
      
      % Initialize Right Button Object
      obj.RButton = uicontrol(...
        'Parent',obj.panel,...
        'Style','pushbutton',...
        'String',p.Results.rightLabel,...
        'Units','normalized',...        
        'Position', [0.51 0.02 0.47 0.96]);
      set(obj.RButton,'Callback',@(h,evt) notify(obj,'rightPushed'));
        
      %% Set any panel parameters that were provided
      setUnmatched(obj,p.Unmatched)
    end
    
    function out = get.leftLabel(obj)
      out = get(obj.LButton,'String');
    end
    
    function out = get.rightLabel(obj)
      out = get(obj.RButton,'String');
    end
    
    function set.leftLabel(obj,val)
      set(obj.LButton,'String',val);
    end
    
    function set.rightLabel(obj,val)
      set(obj.RButton,'String',val);
    end;
    
  end
  

end
