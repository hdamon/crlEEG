classdef showTF < crlEEG.gui.uipanel
% Provides a GUI interface for crlEEG.type.timeFrequencyDecomposition objects
%
% 
  properties
    tfDecomp
    ax
  end;
  
  properties (Dependent =true)
    showBand
    showTimes
    logImg
    imgRange
    showChan
  end
   
  properties (Hidden)
    chanSelect
  end
  
  properties (Access=protected)
    showBand_
    showTimes_
    logImg_
    imgRange_ = [];
  end
  
  
  %% METHODS
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  methods
    
    function obj = showTF(tfDecomp,varargin)
      
        p = inputParser
        p.KeepUnmatched = true;
        p.addRequired('tfDecomp',@(x) isa(x,'timeFrequencyDecomposition'));
        p.addParameter('title','TITLE',@(x) ischar(x));
        p.addParameter('showBand',[]);
        p.addParameter('showTimes',[]);
        p.addParameter('logImg',false);
        p.parse(tfDecomp,varargin{:});
        
        if ~isfield(p.Unmatched,'Parent')
          Parent = figure;
        else
          Parent = p.Unmatched.Parent;
        end
        
        obj = obj@crlEEG.gui.uipanel(...
          'units','pixels',...
          'position',[2 2 600 200],...
          'parent',Parent);
        obj.ResizeFcn = @(h,evt) obj.resizeInternals();
        obj.ax = axes('parent',obj.panel,...
                      'units','pixels',...
                      'Position',[50 50 545 145]);
        obj.ax.Units = 'normalized';
        
        obj.tfDecomp = p.Results.tfDecomp;
        
        obj.chanSelect = uicontrol('Style','popup',...
                                   'String',obj.tfDecomp.labels,...
                                   'Parent',obj.panel,...
                                   'Units','pixels',...                 
                                   'Position',[2 2 50 30],...
                                   'CallBack',@(h,evt) updateImage(obj));
        
        obj.showBand_ = p.Results.showBand;
        obj.showTimes_ = p.Results.showTimes;
        obj.logImg_ = p.Results.logImg;
                                 
        obj.updateImage;        
        obj.Units = 'normalized';
    end      
    
    function out = get.showBand(obj)
      out = obj.showBand_;
    end;
    
    function set.showBand(obj,val)
      if ~isequal(obj.showBand_,val)
        obj.showBand_ = val;
        obj.updateImage;
      end;
    end

    function out = get.showTimes(obj)
      out = obj.showTimes_;
    end
    
    function set.showTimes(obj,val)
      if ~isequal(obj.showTimes_,val)
        obj.showTimes_ = val;
        obj.updateImage;
      end
    end    
    
    function out = get.logImg(obj)
      out = obj.logImg_;
    end;
    
    function set.logImg(obj,val)
      if ~isequal(obj.logImg_,val)
        obj.logImg_ = val;
        obj.updateImage;
      end;
    end
    
    function out = get.imgRange(obj)
      out = obj.imgRange_;
    end
    
    function set.imgRange(obj,val)
      if ~isequal(obj.imgRange_,val)
        obj.imgRange_ = val;
        obj.updateImage;
      end;
    end
      
    
    function resizeInternals(obj)
      currUnits = obj.Units;
      cleanup = onCleanup(@() set(obj,'Units',currUnits));
      
      obj.Units = 'pixels';
      pixPos = obj.Position;
      
      obj.chanSelect.Units = 'pixels';
      obj.chanSelect.Position = [2 2 50 30];
            
      obj.ax.Units = 'pixels';
      xSize = max([5 0.99*(pixPos(3)-50)]);
      ySize = max([5 0.99*(pixPos(4)-50)]);
      obj.ax.Position = [50 50 xSize ySize];            
    end
    
    function out = get.showChan(obj)
      out = obj.chanSelect.String{obj.chanSelect.Value};
    end
        
    function updateImage(obj)
      axes(obj.ax); cla;
      obj.tfDecomp.imagesc('parent',obj.ax,...
                           'showBand',obj.showBand,...
                           'showChan',obj.showChan,...
                           'showTimes',obj.showTimes,...
                           'logImg',obj.logImg,...
                           'range',obj.imgRange)
                         
      set(obj.ax,'YDir','normal');      
      %obj.ax.Position = [0.025 0.05 0.965 0.9];
    end
    
  end
  
  %%  PROTECTED METHODS
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  methods (Access=protected)
  end
  
  %%  STATIC PROTECTED METHODS
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  methods (Static=true,Access=protected)
    function p = parseInputs(varargin)

    end
  end
    
  
end
