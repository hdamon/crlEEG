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
  
  
  properties (Dependent = true)
    data
    labels;
    xvals  
    xrange
    sampleRate
  end
  
  properties
    xUnits = 'sec';
  end;
  
  properties (Dependent = true)       
    yrange
    yUnits
  end;
    
  properties (Access=protected)
    data_internal;
    sampleRate_internal;
    xvals_internal;
    labels_internal;
    yunits_internal;
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
        p.addParameter('yunits','uV',@(x) ischar(x)||iscellstr(x));
        p.addParameter('xunits','sec',@ischar);
                        
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
        obj.yUnits = p.Results.yunits;
        obj.xUnits = p.Results.xunits;
      end;
    end
    
    function obj = copyValuesFrom(obj,valObj)
      % Individually copy values from a second object
      obj.data = valObj.data;
      obj.labels = valObj.labels;
      obj.xvals = valObj.xvals;
      obj.sampleRate = valObj.sampleRate;
      obj.yUnits = valObj.yUnits;
      obj.xUnits = valObj.xUnits;
    end
    
    %% SubCopy
    function out = subcopy(obj,idxRow,idxCol)
      % Copy object, including only a subset of timepoints and columns. If
      % not provided or empty, indices default to all values.
      %
      % Mostly intended as a utility function to simplify subsref.
      %dbstack
      if ~exist('idxRow','var'), idxRow = ':'; end;
      if ~exist('idxCol','var'), idxCol = ':'; end;
      
%       out = crlEEG.type.data.timeseries(...
%                  obj.data_internal(idxRow,idxCol),...
%                  obj.labels(idxCol),...
%                  'xvals',obj.xvals(idxRow),...
%                  'samplerate',obj.sampleRate,...
%                  'yunits',obj.yUnits(idxCol),...
%                  'xunits',obj.xUnits);
      
      out = obj.copy;      
      out.labels_internal = out.labels(idxCol);
      out.xvals_internal = out.xvals(idxRow);        
      out.yunits_internal = out.yUnits(idxCol);    
      tmp = out.data(idxRow,idxCol);
      out.data_internal = tmp;
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
     
      %rangeOut = [min(obj.data(:)) max(obj.data(:))];
      %return;
      dataChans = ~cellfun(@(x) isequal(x,'bool'),obj.yUnits);
            
      rangeOut = [min(min(obj.data(:,dataChans))) ...
                  max(max(obj.data(:,dataChans)))];
    end;
    
    function rangeOut = get.xrange(obj)
      rangeOut = [obj.xvals(1) obj.xvals(end)];
    end;
    
    function out = get.yUnits(obj)
      if ~isempty(obj.yunits_internal)
        out = obj.yunits_internal;
      else
        out{1:size(obj,2)} = deal('uV');
      end;
    end;
    
    function set.yUnits(obj,val)
      if isempty(val), obj.yunits_internal = []; return; end;
      assert(ischar(val)||iscellstr(val),...
              'yunits must be a character string or cell array of strings');
      if ~iscellstr(val)
        [cellVal{1:size(obj,2)}] = deal(val); 
      else
        cellVal = val;
      end;
      
      assert(numel(cellVal)==size(obj,2),...
              'yunits must have a number of elements equal to the number of channels');
      obj.yunits_internal = cellVal;                        
    end
    
    function addChannel(obj,data,label,units,replace)
      % Add a channel to 
      
      assert(size(data,1)==size(obj,1),'Incorrect Data Size');
                  
      % Recurse
      if iscellstr(label)
        if ~exist('units','var'), units = repmat({'_'},numel(label),1);        
        for i = 1:numel(label)
          addChannel(obj,data(:,i),label{i},units{i});
        end;
        end;
        return;
      end
      
      % Defaults
      if ~exist('units','var'), units = '_'; end;
      if ~exist('replace','var'), replace = false; end;
      
      % Add a single label
      if ismember(label,obj.labels_internal)
        if replace
          warning('Channel replacement unimplemented');
          return;
        else
          error('Channel already exists');
        end;
      else
         obj.labels_internal{end+1} = label;
         obj.yunits_internal{end+1} = units;
         obj.data_internal = [obj.data data(:)];        
      end
    end;
    
    function out = isDataChannel(obj)
      out = ~obj.isBoolChannel;
    end
    
    function out = isBoolChannel(obj)
      out = cellfun(@(x) isequal(x,'bool'),obj.yUnits);
    end
    
    function out = getDataChannels(obj)
      out = find(obj.isDataChannel);
    end;
    
    function out = getBoolChannels(obj)
      out = find(obj.isBoolChannel);
    end;
    
    %% Set Method for obj.data
    function out = get.data(obj)
      out = obj.data_internal;
    end
    
    function set.data(obj,val)
      if ~isempty(obj.labels_internal)
        assert(size(val,2)==numel(obj.labels_internal),...
                'Number of channels in data must match number of labels');              
      end
      if ~isempty(obj.xvals_internal)
        assert(size(val,1)==numel(obj.xvals_internal),...
                'Number of timepoints must match numel(obj.xvals)');
      end
      obj.data_internal = val;
    end
        
    function out = getPlotData(obj)      
      out = obj.data;
      out(:,obj.getBoolChannels) = 0.5*obj.yrange(2)*out(:,obj.getBoolChannels);                  
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
      assert(isempty(obj.data)||(numel(val)==size(obj,2)),...
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
