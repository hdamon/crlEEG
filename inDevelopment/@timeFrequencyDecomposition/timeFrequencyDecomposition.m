classdef timeFrequencyDecomposition < handle & matlab.mixin.Copyable
% A simple class for manipulating time frequency decompositions.
%
%
% function obj = timeFrequencyDecomposition(type,tfX,tx,fx,labels)
%
% Properties
% ----------
%   type : Name of the decomposition
%   tfX  : nFrequency X nTime x nChannel array of decomposition parameters
%   tx   : Time values for each column in tfX
%   fx   : Frequency values for each row in tfX
%  labels: Cell string array of channel labels
%
%
  
  properties (Dependent = true)
    type   
    labels % Channel labels
    tfX
    tx
    trange   
    fx    
    frange    
  end
 
  properties
    params
  end
  
  properties (Access=protected)
    type_
    labels_
    tfX_
    tx_
    fx_
  end
  
  methods
    
    function obj = timeFrequencyDecomposition(type,tfX,tx,fx,labels)
      if nargin>0
      obj.type_ = type;
      obj.tfX = tfX;
      obj.tx = tx;
      obj.fx = fx;      
      obj.labels = labels;
      end;
    end
    
    function out = get.trange(obj)
      out = [obj.tx(1) obj.tx(end)];
    end
    
    function out = get.frange(obj)
      out = [obj.fx(1) obj.fx(end)];
    end;
    
    %% Set/Get Methods for obj.type
    function out = get.type(obj)
      out = obj.type_;
    end   
    function set.type(obj,val)
      error('Cannot set decomposition type after creation');
    end
    
    %% Set/Get Methods for obj.labels
    function out = get.labels(obj)
      if isempty(obj.labels_)              
        % Default channel labels        
        out = cell(1,size(obj.tfX,2));
        for i = 1:size(obj.tfX,2),
          out{i} = ['Chan' num2str(i)];
        end
        return;
      end;      
      out = obj.labels_;      
    end % END get.labels
    function set.labels(obj,val)
      % Redirect to internal property
      if isempty(val), obj.labels_ = []; return; end;        
      assert(iscellstr(val),'Labels must be provided as a cell array of strings');      
      assert(isempty(obj.tfX)||(numel(val)==size(obj,3)),...
        'Number of labels must match number of channels');
      obj.labels_ = strtrim(val);
    end % END set.labels
    
    %% Set/Get Methods for obj.tfX
    function out = get.tfX(obj)
      out = obj.tfX_;
    end
    
    function set.tfX(obj,val)
      if ~isempty(obj.labels_)
        assert(size(val,3)==numel(obj.labels_),...
          '3rd Dimension must match number of channels');
      end
      if ~isempty(obj.tx_)
        assert(size(val,2)==numel(obj.tx_),...
          '2nd Dimension must match number of timepoints');
      end
      if ~isempty(obj.fx_)
        assert(size(val,1)==numel(obj.fx_),...
          '1st Dimension must match number of timepoints');
      end;
      
      obj.tfX_ = val;      
    end
    
    %% Set/Get Methods for obj.tx
    function out = get.tx(obj)
      out = obj.tx_;
    end
    
    function set.tx(obj,val)
      if isempty(val), obj.tx_ = []; return; end;
      assert(isvector(val) && numel(val)==size(obj.tfX,2),...
              'tx vector length must match size(obj.tfX,2)');
      assert(issorted(val),'tx vector must be sorted');
      obj.tx_ = val;
    end
    
    %% Set/Get Methods for obj.fx
    function out = get.fx(obj)
      % No default value for frequencies
      out = obj.fx_;
    end
    
    function set.fx(obj,val)
      if isempty(val), obj.fx_ = []; return; end;
      assert(isvector(val)&&numel(val)==size(obj.tfX,1),...
        'Frequency vector should match size(obj.tfX,1)');
      assert(issorted(val),'Frequency vector should be sorted');
      obj.fx_ = val;
    end
       
    function out = size(obj,dim)
      if numel(obj==1)
       if ~exist('dim','var')
         out = size(obj.tfX);
       else
         out = size(obj.tfX,dim);
       end;
      else
        out = builtin('size',obj);
      end
    end       
              
    %% SubCopy
    function out = subcopy(obj,fIdx,tIdx,chanIdx)
      % Copy object, including only a subset of timepoints and columns. If
      % not provided or empty, indices default to all values.
      %
      % Mostly intended as a utility function to simplify subsref.
      %
      if ~exist('fIdx','var'), fIdx = ':'; end;
      if ~exist('tIdx','var'), tIdx = ':'; end;
      if ~exist('chanIdx','var'),chanIdx = ':'; end;      
      
      out = obj.copy;                 
      out.tx_ = out.tx_(tIdx);
      out.fx_ = out.fx_(fIdx);
      out.labels_ = out.labels(chanIdx);
      out.tfX_  = out.tfX_(fIdx,tIdx,chanIdx);        
      
    end
    
    function out = subtract_baseline(obj,baseline)
      % Subtract a baseline frequency spectrum from all tfX columns.      
      assert(size(baseline,1)==size(obj.tfX,1),...
                'Incorrect Baseline Size');
      
      out = obj;
      out.tfX = abs(out.tfX) - repmat(baseline,1,size(out.tfX,2));
    end        
    
    function tfOut = selectTimes(tfIn,timesOut)
      % Select a portion of the 
      
      assert(issorted(timesOut),'Output times must be sorted');
      inRange = ( timesOut(1) >= tfIn.tx(1) ) & ( timesOut(end) <= tfIn.tx(end));
      assert(inRange,'Requested times are out of range');
      
      [~,searchStart] = min(abs(tfIn.tx-timesOut(1)));
      [~,searchEnd] = min(abs(tfIn.tx-timesOut(end)));
            
      outIdx = nan(numel(timesOut),1);
      outIdx(1) = searchStart;
      outIdx(end) = searchEnd;
                  
      idxSearch = searchStart;
      for idxOut = 2:(numel(timesOut)-1)
        minDeltaT = 1e100; % initialize minimum                
        deltaT = abs(tfIn.tx(idxSearch)-timesOut(idxOut));
        while deltaT<minDeltaT          
          minDeltaT = deltaT;  % Found a new minimum
          idxSearch = idxSearch+1; % Advance to next time point
          deltaT = abs(tfIn.tx(idxSearch)-timesOut(idxOut));  % Update deltaT       
        end;
        
        idxSearch = idxSearch-1; % Take one step back
        outIdx(idxOut) = idxSearch; % Update output                        
      end
       
      
      s.type = '()';
      s.subs = {':' outIdx ':'};
      
      tfOut = tfIn.subsref(s);
      
      
    end
    
    function imagesc(obj,varargin)
      % Overloaded imagesc method for timeFrequencyDecomposition objects
      %
      % Inputs
      % ------
      %
      % Optional Inputs
      % ------
      %  range: Range to display
      %
      % Optional Param-value Inputs
      % ---------------------------
      %  showChan : Index of channel to display
      %    logImg : Flag to turn on logarithmic display
      %  showBand : 1x2 Array: [lower upper] frequency band
      %    parent : Matlab gui handle to parent to 
      %
      %
      
      import crlEEG.util.validation.*
                  
      p = inputParser;
      p.KeepUnmatched = true;
      p.addOptional('range',[],@(x) emptyOk(x,@(x) isNumericVector(x,2)));
      p.addParameter('showChan',1);
      p.addParameter('logImg',false);
      p.addParameter('showBand',[],@(x) emptyOk(x,@(x) isNumericVector(x))); 
      p.addParameter('showTimes',[],@(x) emptyOk(x,@(x) isNumericVector(x))); 
      p.addParameter('parent',[],@(x) ishghandle(x));
      p.addParameter('colormap',crlEEG.gui.widget.alphacolor,@(x) isa(x,'crlEEG.gui.widget.alphacolor'));
      p.parse(varargin{:});
      
      if isempty(p.Results.showChan)
        idxChan = 1;
      else
        idxChan = p.Results.showChan;
      end;
      
      if isempty(p.Results.parent)
        par = figure;
      else
        if ishghandle(p.Results.parent,'figure')
         figure(p.Results.parent);
        elseif ishghandle(p.Results.parent,'axes')
          axes(p.Results.parent);
        end
      end;
      
      if ~isempty(p.Results.showBand)
        [~,idxLow] = min(abs(obj.fx-p.Results.showBand(1)));
        [~,idxHi ] = min(abs(obj.fx-p.Results.showBand(2)));
        idxF = idxLow:idxHi;
      else
        idxF = ':';
      end
      
      if ~isempty(p.Results.showTimes)
        if numel(p.Results.showTimes)==2
          % Treat it as a range
          [~,idxLow] = min(abs(obj.tx-p.Results.showTimes(1)));
          [~,idxHi ] = min(abs(obj.tx-p.Results.showTimes(2)));
          idxT = idxLow:idxHi;
        else
          idxT = p.Results.showTimes;
        end;
      else
        idxT = ':';
      end;
      
      s(1).type = '.';
      s(1).subs = 'tfX';
      s(2).type = '()';
      s(2).subs = {idxF idxT idxChan};
      
      showImg = abs(obj.subsref(s));
                          
      if isempty(p.Results.range)
        imgRange(1) = 0;
        imgRange(2) = prctile(abs(showImg(:)),99);
      else
        imgRange = p.Results.range;
      end
      
      if p.Results.logImg
        showImg = log10(showImg);
        imgRange = log10(imgRange);
      end;
      
      cmap = p.Results.colormap;    
      if isempty(cmap.range)||isequal(cmap.range,[0 1])
        % Only override if it's the default
        cmap.range = imgRange;
      end;
      [rgb,alpha] = cmap.img2rgb(abs(showImg));
      tData = obj.tx(idxT);
      fData = obj.fx(idxF);
      
      img = image(tData,fData,rgb,'AlphaData',alpha);
            
%       if p.Results.logImg
%         img = imagesc(obj.tx(idxT),obj.fx(idxF),log10(abs(showImg)),log10(imgRange));
%       else      
%         img =  imagesc(obj.tx(idxT),obj.fx(idxF),abs(showImg),imgRange);
%       end;
      set(gca,'YDir','normal');
      ylabel('Frequency');
      xlabel('Time');
      
      if nargout>0
       % varargout{1} = img;
      end;
      
    end
    
  end
  
end

