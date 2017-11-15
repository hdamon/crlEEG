classdef timeplay < crlEEG.gui.uipanel
  % UI Object For Playing Time Data
  %
  % classdef timeplay < crlEEG.gui.uipanel
  %
  % Create a set of UI controls for controlling playback of time series
  % data.
  %
  % obj = crlEEG.gui.widget.timeplay(varargin)
  %
  % Optional Inputs:
  %   'range' : Set the range of timepoints available. For the moment,
  %               these need to be integers.
  %   'current' : Set the currently selected timepoint.  
  %   'externalsync' : Set flag for externaling syncing (DEFAULT: FALSE)
  %
  % Properties:
  %   idxRange : Min and max of index values
  %   currIdx  : Currently selected idx
  %   externalSync : Flag to set external syncing of the play process.
  %    
  % External Sync:
  %  The externalSync flag provides the ability to control the timing of
  %  each step either internally or externally. When externalSync==FALSE, a
  %  new step will be taken every 0.1 seconds. If externalSync is set to
  %  TRUE, an initial step will be taken (Triggering the obj.updatedOut
  %  event). It then trusts that there is an external listener paying
  %  attention to that event, which will subsequently trigger another call
  %  to obj.nextStep, thus continuing the cycle.
  %
  % Events
  %   updatedOut : Triggered whenever currIdx is changed.
  %
  % Written By: Damon Hyde
  % Last Edited: May 2016
  % Part of the cnlEEG Project
  %
  
  properties
    idxRange   
    externalSync = false;
  end
  
  properties (Dependent = true)
    currIdx;
  end
    
  properties (Hidden=true)
    % Things that shouldn't be getting set by anyone, but which are nice to
    % leave exposed just in case. 
    stepTime = 1;
    pauseTime = 0.1;
    ffwdStep = 10;
    keepPlaying = false;
  end;
  
  properties (Access=protected)
    storedVals
    playButton
    pauseButton
    fwdButton
    ffwdButton
    bckButton
    fbckButton
    spdUpButton
    spdDwnButton
    spdDisp
    selDisp
    isPlaying    
  end
  
  methods
    function objOut = timeplay(varargin)
      
      %p = uitools.controls.timeplay.parseInputs(varargin{:});
      
      p = inputParser;
      p.KeepUnmatched = true;
      addParamValue(p,'range',[1 1]);
      addParamValue(p,'current',1);
      addParamValue(p,'externalsync',false);
      parse(p,varargin{:});
      
      objOut= objOut@crlEEG.gui.uipanel(...
              'units' , 'pixels',...
              'position', [ 10 10 450 50]);
      
      objOut.idxRange = p.Results.range;
      objOut.currIdx  = p.Results.current;
      ovjOut.externalSync = p.Results.externalsync;
      
      objOut.initializeButtons;
      
      set(objOut.panel,p.Unmatched);
      
    end
    
    function out = get.currIdx(obj)
      if isfield(obj.storedVals,'currIdx')
        out = obj.storedVals.currIdx;
      else
        out = [];
      end;
    end
    
    
    function set.currIdx(obj,val)
      
      if isprop(obj,'idxRange')&&(numel(obj.idxRange)==2)
        if ( val<obj.idxRange(1) )
          obj.storedVals.currIdx = obj.idxRange(1);
          obj.isPlaying = false;
        elseif (val>obj.idxRange(2) )
          obj.storedVals.currIdx = obj.idxRange(2);
          obj.isPlaying = false;
        else                                  
          obj.storedVals.currIdx = val;        
        end;
      
        set(obj.selDisp,'String',num2str(obj.storedVals.currIdx));
        notify(obj,'updatedOut');
        
      end;            
    end
    
     function nextStep(obj)
      % Only take the next step if we're currently playing;
      if obj.isPlaying
        obj.shiftIdx(obj.stepTime);
      end;
    end;
    
  end
  
  methods (Access=protected,Static=true)
    function p = parseInputs(varargin)
      % Input Parsing Function for the Object Constructor
      p = inputParser;
      addParamValue(p,'parent',[]);
      addParamValue(p,'origin',[10 10]);
      addParamValue(p,'size',[450,50]);
      addParamValue(p,'title','');
      addParamValue(p,'units','pixels');
      addParamValue(p,'range',[1 1]);
      addParamValue(p,'current',1);
      parse(p,varargin{:});
    end
  end
  
  methods (Access=protected)
    function initializeButtons(obj)
      allPositions = [ 0.015 0.05 0.06 0.9 ; ...
                       0.08  0.05 0.1 0.65 ;...
                       0.18  0.05 0.06 0.9;...
                       0.28  0.05 0.07 0.9;...
                       0.36  0.05 0.07 0.9;...
                       0.45 0.05 0.07 0.9;...
                       0.53 0.05 0.07 0.9;...                       
                       0.62  0.05 0.07 0.9;...
                       0.70  0.05 0.07 0.9;...
                       0.8  0.05 0.18 0.65];
      
      obj.spdUpButton = uicontrol('Parent',obj.panel,...
        'Style','pushbutton',...
        'String','+',...
        'Units','normalized',...
        'BusyAction','cancel',...
        'Position', allPositions(1,:));
      set(obj.spdUpButton,'Callback',@(h,evt)obj.spdChange(1));
      
      obj.spdDisp = uicontrol('Parent',obj.panel,...
        'Style','text',...
        'String','1',...
        'Units','normalized',...
        'HorizontalAlignment', 'center',...
        'Position',allPositions(2,:));      
      
      obj.spdDwnButton = uicontrol('Parent',obj.panel,...
        'Style','pushbutton',...
        'String','-',...
        'Units','normalized',...
        'BusyAction','cancel',...
        'Position', allPositions(3,:));
      set(obj.spdDwnButton,'Callback',@(h,evt)obj.spdChange(-1));
      
      obj.fbckButton = uicontrol('Parent',obj.panel,...
        'Style','pushbutton',...
        'String','<<',...
        'Units','normalized',...
        'Position', allPositions(4,:));
      set(obj.fbckButton,'Callback',@(h,evt)obj.shiftIdx(-obj.ffwdStep));
      
      obj.bckButton = uicontrol('Parent',obj.panel,...
        'Style','pushbutton',...
        'String','<',...
        'Units','normalized',...
        'Position', allPositions(5,:));
      set(obj.bckButton,'Callback',@(h,evt)obj.shiftIdx(-1));
           
      obj.playButton = uicontrol('Parent',obj.panel,...
        'Style','pushbutton',...
        'String','|>',...
        'Units','normalized',...
        'Interruptible','on',...
        'Position', allPositions(6,:));
      set(obj.playButton,'Callback',@(h,evt)obj.play);
      
      obj.pauseButton = uicontrol('Parent',obj.panel,...
        'Style','pushbutton',...
        'String','||',...
        'Units','normalized',...
        'BusyAction','cancel',...
        'Position', allPositions(7,:));
      set(obj.pauseButton,'Callback',@(h,evt)obj.pause);
      
      obj.fwdButton = uicontrol('Parent',obj.panel,...
        'Style','pushbutton',...
        'String','>',...
        'Units','normalized',...
        'Position', allPositions(8,:));
      set(obj.fwdButton,'Callback',@(h,evt)obj.shiftIdx(1));
      
      obj.ffwdButton = uicontrol('Parent',obj.panel,...
        'Style','pushbutton',...
        'String','>>',...
        'Units','normalized',...
        'Position', allPositions(9,:));
      set(obj.ffwdButton,'Callback',@(h,evt)obj.shiftIdx(obj.ffwdStep));
      
      obj.selDisp = uicontrol('Parent',obj.panel,...
        'Style','text',...
        'String','1',...
        'Units','normalized',...
        'HorizontalAlignment', 'right',...
        'Position',allPositions(10,:));      
    end;
    
    function play(obj,~,varargin)
      obj.isPlaying = true;
      if ~obj.externalSync
        % Just update the frame at a fixed framerate
        while obj.isPlaying
          obj.nextStep;
          pause(obj.pauseTime);
        end;
      else
        % Just take a single step, and trust that the external control will
        % continue to trigger next steps
        obj.nextStep;
      end;    
    end
            
    function pause(obj,~,varargin)
      obj.isPlaying = false;
    end;
    
    
    function spdChange(obj,val,~,varargin)
      % Change the step size for use when playing
      obj.stepTime = obj.stepTime+val;
      set(obj.spdDisp,'String',num2str(obj.stepTime));      
    end;
    
    function shiftIdx(obj,shift,~,varargin)
      % function shiftXVal(obj,shift,h,varargin)
      %
      % Shift currently selected timepoint by a fixed number of timepoints.
      %
      % Inputs:
      %  obj         : cnlDataPlot object
      %  shift       : number of timepoints to shift by
      %  h, varargin : Callback inputs provided by matlab
      %
      % Written By: Damon Hyde
      % Last Edited: Aug 17, 2015
      % Part of the cnlEEG Project
      %
                
      obj.currIdx = obj.currIdx + shift;       
            
    end
    
  end
  
end





