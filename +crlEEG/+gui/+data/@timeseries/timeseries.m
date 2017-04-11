classdef timeseries < handle
  % crlEEG.gui data class for time series data
  %
  % Data is stored as: time X channels
  %
  % While this duplicates some of the functionality of other datatypes,
  % this is used exclusively in the crlEEG.gui rendering package to provide
  % a common interface.
  %
  % Written By: Damon Hyde
  % Part of the crlEEG Project
  % 2009-2017
  %
  
  properties
    data
  end;
  
  properties (Dependent = true)
    xvals
    yrange
    labels;
  end;
  
  properties (Access=protected)
    xvals_internal;
    labels_internal;
  end;
    
  methods
    
    function obj = timeseries(data,varargin)
      
      %% Input Parsing
      p = inputParser;
      p.addRequired('data',@(x) isnumeric(x)&&ismatrix(x));
      p.addOptional('labels',[],@(x) isempty(x)||iscellstr(x));        
      p.addParamValue('xvals',[],@(x) isempty(x)||isvector(x));        
      p.parse(data,varargin{:});
      
      %% Set Object Properties
      obj.data   = p.Results.data;
      obj.labels = p.Results.labels;
      obj.xvals  = p.Results.xvals;
    end
    
    function out = size(obj,dim)
      if ~exist('dim','var')
        out = size(obj.data);
      else
        out = size(obj.data,dim);
      end;
    end
    
    function rangeOut = get.yrange(obj)
      rangeOut = [min(obj.data(:)) max(obj.data(:))];
    end;
    
    function out = get.labels(obj)
      if ~isempty(obj.labels_internal)
        out = obj.labels_internal;
      else
        % Default channel labels
        warning('Shouldn''t be getting here');
        out = cell(1,size(obj.data,2));
        for i = 1:size(obj.data,2)
          out{i} = ['Chan' num2str(i)];
        end
      end;
    end
    
    function set.labels(obj,val)
      % Redirect to internal property
      if isempty(val) 
        % Default channel labels
        out = cell(1,size(obj.data,2));
        for i = 1:size(obj.data,2)
          out{i} = ['Chan' num2str(i)];
        end
        obj.labels_internal = out;
        return; 
      end;
      assert(iscellstr(val),'Labels must be provided as a cell array of strings');
      assert(numel(val)==size(obj.data,2),...
        'Number of labels must match number of channels');
      obj.labels_internal = val;
    end;
            
    function out = get.xvals(obj)
      if ~isempty(obj.xvals_internal)
        out = obj.xvals_internal;
      else
        warning('Shouldn''t be getting here');
        out = 1:size(obj.data,1);
      end;
    end
    
    function set.xvals(obj,val)
      if isempty(val), obj.xvals_internal = 1:size(obj.data,1); return; end;
      assert( isvector(val) && numel(val)==size(obj.data,1),...
            'xVals vector length must match size(obj.data,1)');
      assert( issorted(val), 'xVals should be a sorted list of time values');
      obj.xvals_internal = val;
    end;            
    
  end;
end
