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
      obj.type_ = val;
      %error('Cannot set decomposition type after creation');
    end
    
    %% Set/Get Methods for obj.labels
    function out = get.labels(obj)
      if isempty(obj.labels_)              
        % Default channel labels        
        out = cell(1,size(obj.tfX,3));
        for i = 1:size(obj.tfX,3),
          out{i} = ['Chan' num2str(i)];
        end
        return;
      end;      
      out = obj.labels_;      
    end % END get.labels
    
    function set.labels(obj,val)
      % Redirect to internal property
      if isempty(val), obj.labels_ = []; return; end;        
      if ischar(val), val = {val}; end;
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
      obj.tx_ = val(:);
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
      obj.fx_ = val(:);
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
    
    function tfOut = selectTimes(tfIn,timesOut,varargin)
      % Select a subset of times from a time-frequency decomposition
      %
      % function tfOut = selectTimes(tfIn,timesOut)
      %
      % Inputs
      % ------
      %      tfIn : timeFrequencyDecomposition object
      %  timesOut : Timepoints to include in the output
      %               timeFrequencyDecomposition
      %
      % Outputs
      % -------
      %  tfOut : timeFrequencyDecomposition object with subselected times.
      %
      % Part of the crlEEG project
      % 2009-2018
      %
            
      % Output range must be sorted
      assert(issorted(timesOut),'Output times must be sorted');
      inRange = ( timesOut(1) >= tfIn.tx(1) ) & ( timesOut(end) <= tfIn.tx(end));
      
      % Just drop them?
      timesOut(timesOut<tfIn.tx(1)) = [];
      timesOut(timesOut>tfIn.tx(end)) = [];
      
      %assert(inRange,'Requested times are out of range');
      
      % Get indices of the time range to search in.
      [~,searchStart] = min(abs(tfIn.tx-timesOut(1)));
      [~,searchEnd]   = min(abs(tfIn.tx-timesOut(end)));
            
      % Initialize output index
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
        
        idxSearch = idxSearch-1; % Take one step back. 
        outIdx(idxOut) = idxSearch; % Update output                        
      end
      
      % Don't duplicate points in the output?
      %outIdx = unique(outIdx);
      
      % Select the appropriate points to output.
      s.type = '()';
      s.subs = {':' outIdx ':'};
      
      tfOut = tfIn.subsref(s);
            
    end
    
    function varargout = imagesc(obj,varargin)
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
      
      %% Get Channels to Show
      if isempty(p.Results.showChan)
        idxChan = 1;
      else
        idxChan = p.Results.showChan;
      end;
      
      %% Get Object Parent
      if isempty(p.Results.parent)
        par = figure;
      else
        if ishghandle(p.Results.parent,'figure')
         figure(p.Results.parent);
        elseif ishghandle(p.Results.parent,'axes')
          axes(p.Results.parent);
        end
      end;
      
      %% Get Frequency Band Indices
      if ~isempty(p.Results.showBand)
        [~,idxLow] = min(abs(obj.fx-p.Results.showBand(1)));
        [~,idxHi ] = min(abs(obj.fx-p.Results.showBand(2)));
        idxF = idxLow:idxHi;
      else
        idxF = 1:numel(obj.fx);
      end
      
      %% Get Time Indices
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
      
      %% Get the Image to Display.
      s(1).type = '.';
      s(1).subs = 'tfX';
      s(2).type = '()';
      s(2).subs = {idxF idxT idxChan};
      
      showImg = obj.subsref(s);
      s(2).subs = {idxF ':' idxChan};
      rangeImg = obj.subsref(s);
           
      % Take Magnitude if Complex.
      if any(any(imag(showImg)))
        showImg = abs(showImg);
        rangeImg = abs(rangeImg);
      end;
                    
      %% Get Image Range
      if isempty(p.Results.range)
        imgRange(1) = prctile(rangeImg(:),0.001);
        imgRange(2) = prctile(rangeImg(:),99.999);
      else
        imgRange = p.Results.range;
      end
      
      %% If log requested
      if p.Results.logImg
        showImg = log10(showImg);
        imgRange = log10(imgRange);
      end;            
      
      %% Get the RGB Image
      cmap = p.Results.colormap;    
      if isempty(cmap.range)||isequal(cmap.range,[0 1])
        % Only override if it's the default
        cmap.range = imgRange;
      end;
      [rgb,alpha] = cmap.img2rgb(showImg);
      tData = obj.tx(idxT);
      fData = obj.fx(idxF);
      
            
      img = image(tData,[],rgb,'AlphaData',alpha);
      
      currAxis = gca;
      showF = obj.fx(idxF(round(currAxis.YTick)));
      for i = 1:numel(showF)
        fLabel{i} = num2str(showF(i));
      end;
      currAxis.YTickLabel = fLabel;
      
      
      set(gca,'YDir','normal');
      ylabel('Frequency');
      xlabel('Time');
      
      if nargout>0
        varargout{1} = img;
      end;
      
    end % imagesc()
    
    function out = subsrefTFX(obj,varargin)
      % Not sure this is entirely needed. Might be a bit of a hack
      if ~isempty(varargin)
        s(1).type = '.';
        s(1).subs = 'tfX';
        s(2).type = '()';
        s(2).subs = varargin;
        out = obj.subsref(s);
      else
        out = obj.tfX;
      end             
    end
    
    function out = PSD(obj,varargin)
      % Convert a time-frequency decomposition to power spectral density            
      out = abs(obj.subsrefTFX(varargin{:})).^2;      
    end
    
    function out = abs(obj,varargin)
      % Convert a time-frequency decomposition to spectral magnitude      
      out.tfX = abs(obj.subsrefTFX(varargin{:}));
    end;
    
    function out = PLF(obj,varargin)  
      % Convert a time-frequency decomposition to Phase Locking Factor
      %
      % (NEEDS TO BE AVERAGED ACROSS A LOT OF DECOMPOSITIONS)      
      tmp = obj.subsrefTFX(varargin{:});
      out = tmp./abs(tmp);
    end;
              
    function isValid = isConsistent(obj,b)
      % Check consistency between timeFrequencyDecomposition objects
      %
      % Used to check if math operations can be applied between two
      % timefrequency decompositions
      %
      isValid = isa(b,'timeFrequencyDecomposition');      
      if ~isValid, return; end;
            
      fxEqual = true;
      if size(obj,1)==size(b,1)
       % If frequency dimensions are equal, check that they're the same
       fxEqual = isequal(obj.fx,b.fx);
      end;
      
      txEqual = true;
      if size(obj,2)==size(b,2)
        % If time dimensions are equal, check that they're the same.
        txEqual = isequal(round(obj.tx,8),round(b.tx,8));
      end
      
      chanEqual = true;
%       if size(obj,3)==size(b,3)
%         chanEqual = isequal(obj.labels,b.labels);
%       end
      
      sizeValid = crlEEG.util.validation.arraySizeForBSXFUN(size(obj),size(b));
      
      isValid = sizeValid && txEqual && fxEqual && chanEqual;      
    end
    
    function [fx,tx,chan] = consistentDimensions(obj,b)
      assert(isa(b,'timeFrequencyDecomposition'),...
                'Second input must be a timeFrequencyDecomposition object');
              
      assert(isConsistent(obj,b),'Inconsistent decomposition sizes');  
      
      sizeEqual = crlEEG.util.validation.compareSizes(size(obj),size(b));
      
      fields = {'fx' 'tx' 'labels'};        
      fx = [];
      tx = [];
      chan = [];
      for i = 1:numel(sizeEqual)
        if sizeEqual(i)
          tmp = obj.(fields{i});
        else
          if size(obj,i)==1
            tmp = b.(fields{i});
          elseif size(b,i)==1
            tmp = obj.(fields{i});
          else
            error('Shouldn''t be getting here');
          end;
        end
        switch i
          case 1
            fx = tmp;
          case 2
            tx = tmp;
          case 3
            chan = tmp;
        end
      end                            
    end
    
    function decompOut = applyFcnToTFX(obj,b,funcHandle)
      % Use bsxfun to apply funcHandle to obj.tfX
      %
      % decompOut = applyFcnToTFX(obj,b,funcHandle)
      %
      % Inputs
      % ------
      %        obj : timeFrequencyDecomposition object
      %          b : Value to apply
      % funcHandle : Function handle
      %
      % Checks the consistency of the inputs, and then calls:
      %
      % tfX = bsxfun(funcHandle,obj,tfX,coeff)
      %
      % When b is:
      %   A timeFrequencyDecomposition obj:  coeff = b.tfX
      %                          OTHERWISE:  coeff = b;
      %
      %      
      
      for idxObj = 1:numel(obj)
      
      if isa(b,'timeFrequencyDecomposition')
        assert(isConsistent(obj(idxObj),b),'Inconsistent decomposition sizes');
        coeff = b.tfX;
        [fx,tx,chan] = consistentDimensions(obj(idxObj),b);
      else
        coeff = b;
        fx = obj(idxObj).fx;
        tx = obj(idxObj).tx;
        chan = obj(idxObj).labels;
      end;
            
      tfX = bsxfun(funcHandle,obj.tfX,coeff);
      newType = [obj.type '_' func2str(funcHandle)];
      decompOut(idxObj) = timeFrequencyDecomposition(newType,tfX,tx,fx,chan);      
      
      end;
      
      %% Reshape if its an array of objects
      if numel(decompOut)>1
        decompOut = reshape(decompOut,size(obj));
      end;
    end
    
    function out = plus(obj,b)      
      out = applyFcnToTFX(obj,b,@plus);      
      if isa(b,'timeFrequencyDecomposition')
      for i = 1:numel(out.labels)
        if numel(b.labels)==1, idxB = 1; else, idxB = i; end;
        out.labels{i} = [obj.labels{i} '+' b.labels{idxB}];
      end
      end;
    end;
    
    function out = minus(obj,b)      
      out = applyFcnToTFX(obj,b,@minus);      
      if isa(b,'timeFrequencyDecomposition')
        for i = 1:numel(out.labels)
          if numel(b.labels)==1, idxB = 1; else, idxB = i; end;
          out.labels{i} = [obj.labels{i} '-' b.labels{idxB}];
        end
      end;
    end;    
    
    function out = rdivide(obj,b)
      out = applyFcnToTFX(obj,b,@rdivide);   
      if isa(b,'timeFrequencyDecomposition')
      for i = 1:numel(out.labels)
        if numel(b.labels)==1, idxB = 1; else, idxB = i; end;
        out.labels{i} = ['(' obj.labels{i} ')/' b.labels{idxB}];        
      end
      end;      
    end
    
    function out = times(obj,b)
      out = applyFcnToTFX(obj,b,@times);      
      if isa(b,'timeFrequencyDecomposition')
        for i = 1:numel(out.labels)
          if numel(b.labels)==1, idxB = 1; else, idxB = i; end;
          out.labels{i} = [obj.labels{i} '*' b.labels{idxB}];
        end
      end;
    end;
    
    function out = cat(dim,obj,a,varargin)
      
      switch dim
        case 1
          error('Concatenation along frequency axis not implemented');
        case 2
          error('Concatenation along time axis not implemented');
        case 3
          assert(isequal(obj.fx,a.fx),'Frequencies must match');
          assert(isequal(obj.tx,a.tx),'Times must match');

          newType = ['cat(' obj.type ',' a.type ')'];
          concat = cat(3,obj.tfX,a.tfX);
          labels = [obj.labels ; a.labels]; %#ok<PROPLC>
          
          out = timeFrequencyDecomposition(newType,concat,...
                                            obj.tx,obj.fx,labels); %#ok<PROPLC>
          
          if ~isempty(varargin)
            out = cat(3,out,varargin{:});
          end
        otherwise
          error('Invalid dimension for concatenation');
      end;
                        
    end
    
    function out = mean(obj,dim)
      if ~exist('dim','var'), dim = 1; end;
      
      switch dim
        case 1          
          tx = obj.tx; %#ok<PROPLC>
          fx = 0; %#ok<PROPLC>
          labels = obj.labels;           %#ok<PROPLC>
          newType = ['MeanF(' obj.type ')'];          
        case 2
          tx = 0; %#ok<PROPLC>
          fx = obj.fx; %#ok<PROPLC>
          labels = obj.labels; %#ok<PROPLC>
          newType = ['MeanT(' obj.type ')'];
        case 3
          tx = obj.tx; %#ok<PROPLC>
          fx = obj.fx; %#ok<PROPLC>
          labels = {'MeanChan'}; %#ok<PROPLC>
          newType = ['MeanC(' obj.type ')'];
        otherwise
          error('Invalid dimension selection');
      end
      
      meanTFX = mean(obj.tfX,dim);
      out = timeFrequencyDecomposition(newType,meanTFX,tx,fx,labels); %#ok<PROPLC>
      
    end
    
    
  end
  
end

