classdef timeseries < handle & matlab.mixin.Copyable
  % crlEEG.gui data class for time series data
  %
  % Data is stored as: time X channels
  %
  % While this duplicates some of the functionality of other type.datas,
  % this is used exclusively in the crlEEG.gui rendering package to provide
  % a common interface.
  %
  % obj = crlEEG.type.data.timeseries(data,labels,varargin)
  %
  % Inputs
  % ------
  %   data : nTime x nChannels array of time series data
  %   labels : (Optional) Cell array of length nChannels containing label strings
  %   
  % Param-Value Pairs
  % -----------------
  %   xvals : Timings associated with each sample. Uses sample indices if
  %             this is not provided.
  %
  % Written By: Damon Hyde
  % Part of the crlEEG Project
  % 2009-2017
  %
  
  properties
    data
  end;
  
  properties (Dependent = true)
    labels;
    xvals  
    xrange
    sampleRate
  end
  
  properties
    xScale = 'sec';
  end;
  
  properties (Dependent = true)       
    yrange
    yScale
  end;
    
  properties (Access=protected)
    sampleRate_internal;
    xvals_internal;
    labels_internal;
    yscale_internal;
  end;
    
  methods
    
    function obj = timeseries(varargin)
      
      %% Input Parsing
      if nargin>0
        p = inputParser;
        p.addRequired('data',@(x) (isnumeric(x)&&ismatrix(x))||...
                                    isa(x,'crlEEG.type.data.timeseries'));
        p.addOptional('labels',[],@(x) isempty(x)||iscellstr(x));
        p.addParameter('xvals',[],@(x) isempty(x)||isvector(x));
        p.addParameter('sampleRate',1,@(x) isnumeric(x)&&isscalar(x));
        p.addParameter('yscale','uV',@(x) ischar(x)||iscellstr(x));
        p.addParameter('xscale','sec',@ischar);
                        
        p.parse(varargin{:});
        
        if isa(p.Results.data,'crlEEG.type.data.timeseries')
          obj = obj.copyValuesFrom(p.Results.data);
          return;
        end
        
        %% Set Object Properties
        obj.data   = p.Results.data;
        obj.labels = p.Results.labels;
        obj.xvals  = p.Results.xvals;
        obj.sampleRate = p.Results.sampleRate;
        obj.yScale = p.Results.yscale;
        obj.xScale = p.Results.xscale;
      end;
    end
    
    function obj = copyValuesFrom(obj,valObj)
      % Individually copy values from a second object
      obj.data = valObj.data;
      obj.labels = valObj.labels;
      obj.xvals = valObj.xvals;
      obj.sampleRate = valObj.sampleRate;
      obj.yScale = valObj.yScale;
      obj.xScale = valObj.xScale;
    end
    
    %% SubCopy
    function out = subcopy(obj,idxRow,idxCol)
      % Copy object, including only a subset of timepoints and columns. If
      % not provided or empty, indices default to all values.
      %
      % Mostly intended as a utility function to simplify subsref.
      
      if ~exist('idxRow','var'), idxRow = ':'; end;
      if ~exist('idxCol','var'), idxCol = ':'; end;
      
      out = obj.copy;
      out.data = out.data(idxRow,idxCol);
      out.labels = out.labels(idxCol);
      out.xvals = out.xvals(idxRow);        
      out.yScale = out.yScale(idxCol);      
    end
    
    
    %% Overloaded 
    function out = size(obj,dim)
      if ~exist('dim','var')
        out = size(obj.data);
      else
        out = size(obj.data,dim);
      end;
    end           
    
    %% Dependent Properties
    function rangeOut = get.yrange(obj)
      rangeOut = [min(obj.data(:)) max(obj.data(:))];
    end;
    
    function rangeOut = get.xrange(obj)
      rangeOut = [obj.xvals(1) obj.xvals(end)];
    end;
    
    function out = get.yScale(obj)
      if ~isempty(obj.yscale_internal)
        out = obj.yscale_internal;
      else
        out{1:size(obj,2)} = deal('uV');
      end;
    end;
    
    function set.yScale(obj,val)
      if isempty(val), obj.yscale_internal = []; return; end;
      assert(ischar(val)||iscellstr(val),...
              'yscale must be a character string or cell array of strings');
      if ~iscellstr(val)
        [cellVal{1:size(obj,2)}] = deal(val); 
      else
        cellVal = val;
      end;
      
      assert(numel(cellVal)==size(obj,2),...
              'yscale must have a number of elements equal to the number of channels');
      obj.yscale_internal = cellVal;                        
    end
    
    %% Set/Get Methods for obj.labels
    function out = get.labels(obj)
      if isempty(obj.labels_internal)              
        % Default channel labels        
        out = cell(1,size(obj.data,2));
        for i = 1:size(obj.data,2)
          out{i} = ['Chan' num2str(i)];
        end
        return;
      end;
      
      out = obj.labels_internal;      
    end
    
    function set.labels(obj,val)
      % Redirect to internal property
      if isempty(val), obj.labels_internal = []; return; end;        
      assert(iscellstr(val),'Labels must be provided as a cell array of strings');
      assert(numel(val)==size(obj.data,2),...
        'Number of labels must match number of channels');
      obj.labels_internal = val;
    end;
            
    %% Get/Set Methods for obj.sampleRate
    function out = get.sampleRate(obj)
      if ~isempty(obj.sampleRate_internal)
       out = obj.sampleRate_internal;
      else
       out = 1;
      end;
    end;
    
    function set.sampleRate(obj,val)
      if isempty(val), obj.sampleRate = []; return; end;
      assert(isnumeric(val)&&isscalar(val),...
         'Sample rate must be a scalar numeric value');
       obj.sampleRate_internal = val;
    end
    
    %% obj.xvals is the publically available interface 
    % for the internal property obj.xvals_internal.
    function out = get.xvals(obj)
      if ~isempty(obj.xvals_internal)
        out = obj.xvals_internal;
      else    
        % Default timing values
        out = (1./obj.sampleRate)*(0:size(obj.data,1)-1);
      end;
    end
    
    function set.xvals(obj,val)
      if isempty(val), obj.xvals_internal = []; return; end;
      assert( isvector(val) && numel(val)==size(obj.data,1),...
            'xVals vector length must match size(obj.data,1)');
      assert( issorted(val), 'xVals should be a sorted list of time values');
      obj.xvals_internal = val;
    end;            
    
    function out = plot(obj,varargin)
      
      p = inputParser;
      p.KeepUnmatched = true;
      p.addParamValue('type','dualplot',@(x) ischar(x));
      p.parse(varargin{:});
            
      switch lower(p.Results.type)
        case 'dualplot'
          out = crlEEG.gui.timeseries.interface.dualPlot(obj,p.Unmatched);
        case 'butterfly'
          out = crlEEG.gui.timeseries.render.butterfly(obj,p.Unmatched);
        case 'split'
          out = crlEEG.gui.timeseries.render.split(obj,p.Unmatched);
        otherwise
          error('Unknown plot type');
      end                     
    end
    
  end;
end
