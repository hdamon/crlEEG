classdef timeseries < handle
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
  %   xvals : Timings associated with each sample. Plots sample indices if
  %             this is not provided.
  %
  % Written By: Damon Hyde
  % Part of the crlEEG Project
  % 2009-2017
  %
  
  properties
    data
    xScale = 'uV';
    yScale = 'sec';
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
    
    function obj = timeseries(varargin)
      
      %% Input Parsing
      if nargin>0
        p = inputParser;
        p.addRequired('data',@(x) (isnumeric(x)&&ismatrix(x))||...
                                    isa(x,'crlEEG.type.data.timeseries'));
        p.addOptional('labels',[],@(x) isempty(x)||iscellstr(x));
        p.addParamValue('xvals',[],@(x) isempty(x)||isvector(x));
        p.parse(varargin{:});
        
        %% Set Object Properties
        obj.data   = p.Results.data;
        obj.labels = p.Results.labels;
        obj.xvals  = p.Results.xvals;
      end;
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
    
    %% Set/Get Methods for obj.labels
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
            
    %% obj.xvals is the publically available interface 
    % for the internal property obj.xvals_internal.
    function out = get.xvals(obj)
      if ~isempty(obj.xvals_internal)
        out = obj.xvals_internal;
      else        
        out = 1:size(obj.data,1);
      end;
    end
    
    function set.xvals(obj,val)
      if isempty(val), obj.xvals_internal = []; return; end;
      assert( isvector(val) && numel(val)==size(obj.data,1),...
            'xVals vector length must match size(obj.data,1)');
      assert( issorted(val), 'xVals should be a sorted list of time values');
      obj.xvals_internal = val;
    end;            
    
    function out = plot(obj)
      out = crlEEG.gui.timeseries.interface.dualPlot(obj);
    end
    
  end;
end
