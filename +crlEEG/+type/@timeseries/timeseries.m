classdef timeseries < handle & matlab.mixin.Copyable
  % crlEEG.gui data class for time series data
  %
  % Data is stored as: time X channels
  %
  % While this duplicates some of the functionality of other types,
  % this is used exclusively in the crlEEG.gui rendering package to provide
  % a common interface.
  %
  % obj = crlEEG.type.timeseries(data,labels,varargin)
  %
  % Inputs
  % ------
  %   data : nTime x nChannels array of time series data
  %   labels : (Optional) Cell array of length nChannels containing label strings
  %   
  % Param-Value Pairs
  % -----------------
  %  yunits : Units for the data (DEFAULT: 'uV')
  %  xunits : Units of time (DEFAULT: 'sec')
  %   xvals : Timings associated with each sample. 
  % sampleRate : Sample rate for the data (DEFAULTL: 1Hz)
  % 
  % Referencing into timeseries objects
  % -----------------------------------
  % One of the primary motivators behind creating this library was to
  % simplify the way in which EEG object can be accessed, sliced, and
  % referenced.
  %
  % Toward that end, crlEEG.type.timeseries objects are referenced slightly
  % differently whether they are 
  % 
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
    chanType
  end;
    
  properties (Access=protected)
    data_;
    sampleRate_;
    xvals_;
    labels_;
    yunits_;
    chanType_;
  end;
        
  methods
    
    function obj = timeseries(varargin)
      
      %% Input Parsing
      if nargin>0
        p = inputParser;
        p.addRequired('data',@(x) (isnumeric(x)&&ismatrix(x))||...
                                    isa(x,'crlEEG.type.timeseries'));
        p.addOptional('labels',[],@(x) isempty(x)||iscellstr(x));
        p.addParameter('xvals',[],@(x) isempty(x)||isvector(x));
        p.addParameter('sampleRate',1,@(x) isnumeric(x)&&isscalar(x));
        p.addParameter('yunits','uV',@(x) ischar(x)||iscellstr(x));
        p.addParameter('chanType',[],@(x) ischar(x)||iscellstr(x));
        p.addParameter('xunits','sec',@ischar);
                        
        p.parse(varargin{:});
        
        if isa(p.Results.data,'crlEEG.type.timeseries')
          obj = obj.copyValuesFrom(p.Results.data);
          return;
        end
        
        %% Set Object Properties
        obj.data   = p.Results.data;
        obj.labels = p.Results.labels;
        obj.xvals  = p.Results.xvals;
        obj.sampleRate = p.Results.sampleRate;
        obj.yUnits = p.Results.yunits;
        obj.chanType = p.Results.chanType;
        obj.xUnits = p.Results.xunits;
      end;
    end
    
    function obj = copyValuesFrom(obj,valObj)
      % Individually copy values from a second object
      obj.data   = valObj.data;
      obj.labels = valObj.labels;
      obj.xvals  = valObj.xvals;
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
      %
      if ~exist('idxRow','var'), idxRow = ':'; end;
      if ~exist('idxCol','var'), idxCol = ':'; end;
      
      % Need to use copy here, because derived classes need to be
      % maintained
      out = obj.copy;      
      out.labels_ = out.labels(idxCol);
      out.xvals_  = out.xvals(idxRow);        
      out.yunits_ = out.yUnits(idxCol);  
      out.chanType_ = out.chanType(idxCol);
      tmp = out.data(idxRow,idxCol);
      out.data_ = tmp;
    end
        
    %% Overloaded 
    function out = size(obj,dim)
      if numel(obj)==1
       if ~exist('dim','var')
         out = size(obj.data);
       else
         out = size(obj.data,dim);
       end;
      else
        out = builtin('size',obj);
      end
    end           
    
    %% Main crlEEG.type.timeseries plotting function
    function out = plot(obj,varargin)
      % Overloaded plot function for crlEEG.type.timeseries objects
      %
      % Inputs
      % ------
      %   obj : crlEEG.type.timeseries object
      % 
      % Param-Value Pairs
      % -----------------
      %   'type' : Type of plot to display (DEFAULT: 'dualplot')
      %              Valid Options:
      %                'dualplot'  : 
      %                'butterfly' : Plot each channel on top of one
      %                               another in the same axis.
      %                'split'     : Display each channel as it's own
      %                               plot in the same axis
      %               
      %
      %
      % All other inputs are passed directly to the plotting function.
      %
      
      p = inputParser;
      p.KeepUnmatched = true;
      p.addParamValue('type','dualplot',@(x) ischar(x));
      p.parse(varargin{:});
            
      switch lower(p.Results.type)
        case 'dualplot'
          out = crlEEG.gui.timeseries.interface.dualPlot(obj,p.Unmatched);
        case 'butterfly'
          out = butterfly(obj,p.Unmatched);
        case 'split'
          out = split(obj,p.Unmatched);
        otherwise
          error('Unknown plot type');
      end                     
    end

    %% Plotdata is modified a bit to improve display
    function out = getPlotData(obj)      
      % Return modified timeseries data for plotting
      %
      % out = getPlotData(obj)
      %
      % Data channels are returned unchanged. Boolean and auxillary
      % channels have their amplitude modified so that they are in the
      % range [0 max(obj.data(:,<datachannels>)]
      %
      % This is intended to help with plot scaling when 
      % plotting multiple channels.
      %
      out = obj.data;
      
      % Boolean Data Channels
      boolChan = obj.getChannelsByType('bool');
      out(:,boolChan) = 0.75*obj.yrange(2)*out(:,boolChan); 
      
      % Auxilliary Channels
      auxChan = obj.getChannelsByType('aux');      
      for i = 1:numel(auxChan)        
          m = max(abs(out(:,auxChan(i))));
          out(:,auxChan(i)) = 0.75*(obj.yrange(2)/m)*out(:,auxChan(i));        
      end
        
    end    
    
    %% Add/Remove Channels from a Timeseries Objects
    function addChannel(obj,data,label,units,type,replace)
      % Add a channel to a timeseries object
      %
      % function addChannel(obj,data,label,units,type,replace)
      %
      % Inputs
      % ------
      %   obj   : Timeseries object to add channel to
      %  data   : Vector containing 
      %  label  : Channel label(s)
      %  units  : Physical Units
      %   type  : Type of Channel ('data','aux','bool')
      % replace : When set to true, replaces an existing channel
      %
      % If the input data is a matrix, label must be a cell string of
      % channel labels. Units and type can then either be a single
      % character string (Uniform across channels), or cell arrays with
      % individual values for each channel.
      % 
            
      assert(size(data,1)==size(obj,1),'Channel Data Size is Incorrect');
      if iscellstr(label)
        assert(size(data,2)==numel(label),'Incorrect number of labels provided');
      else
        assert(size(data,2)==1,'Incorrect number of labels provided');
      end;
            
      % Recurse
      if iscellstr(label)
        if ~exist('units','var')||isempty(units), units = repmat({'_'},numel(label),1); end;
        if ~exist('type','var')||isempty(type), type = repmat({'data'},numel(label),1); end;
        
        if ~iscellstr(units)
          units = repmat(units,numel(label),1);
        end;
        
        if ~iscellstr(type)
          type = repmat(typs,numel(label),1);
        end;
        
        for i = 1:numel(label)
          addChannel(obj,data(:,i),label{i},units{i},type{i});
        end;
        
        return;
      end
      
      % Defaults
      if ~exist('units','var')||isempty(units), units = '_'; end;
      if ~exist('type','var')||isempty(type), type = 'data'; end;
      if ~exist('replace','var'), replace = false; end;
      
      % Add a single label
      if ismember(label,obj.labels_)
        if replace
          warning('Channel replacement unimplemented');
          return;
        else
          error('Channel already exists');
        end;
      else
         obj.labels_{end+1} = label;
         obj.yunits_{end+1} = units;
         obj.chanType_{end+1} = type;
         obj.data_ = [obj.data data(:)];        
      end
    end;
        
    function removeChannel(obj,label)
      % Remove one or more channels from a timeseries object
      %
      % function removeChannel(obj,label)
      %
      % Inputs
      %    obj : crlEEG.type.timeseries object
      %  label : List of channel labels to remove. Can be either a string,
      %           or a cell array of strings.
      %
      
      if ~iscell(label), label = {label}; end;
            
      assert(iscellstr(label),'Labels must be provided as strings');
      
      idx = ~ismember(obj.labels,label);
           
      % Truncate the internal channels
      obj.labels_ = obj.labels_(idx);
      obj.yunits_ = obj.yunits_(idx);
      obj.data_ = obj.data_(:,idx);
    end
           
    %% Retrieve Channels By Type
    function out = isChannelType(obj,val)
      % Returns a logical array that is true if a channels yUnits type
      % matches val
      out = cellfun(@(x) isequal(x,val),obj.chanType);
    end
    
    function out = getChannelsByType(obj,val)
      out = find(obj.isChannelType(val));
    end
    
    %% Retrieve Channels By Physical Units
    function out = isUnitType(obj,val)
      % 
      % function out = isUnitType(obj,val)
      %
      % Returns a logical array 
      out = cellfun(@(x) isequal(x,val),obj.yUnits);
    end
    
    function out = getChannelByUnits(obj,val)
      out = find(obj.isUnitType(obj,val));
    end
            
    %% GET/SET METHODS FOR DEPENDENT PROPERTIES
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %% Get/Set Methods for obj.chanType
    function out = get.chanType(obj)
      if ~isempty(obj.chanType_)
        out = obj.chanType_;
      else
        [out{1:size(obj,2)}] = deal('data');
      end;
    end; % END get.chanType    
    function set.chanType(obj,val)
      if isempty(val), obj.chanType_ = []; return; end;
      assert(ischar(val)||iscellstr(val),...
              'chanType must be a character string or cell array of strings');
      if ~iscellstr(val)
        [cellVal{1:size(obj,2)}] = deal(val); 
      else
        cellVal = val;
      end;
      
      assert(numel(cellVal)==size(obj,2),...
              'chanType must have a number of elements equal to the number of channels');
      obj.chanType_ = cellVal;                        
    end % END set.chanType
                
    %% Get/Set Methods for obj.yUnits
    function out = get.yUnits(obj)
      if ~isempty(obj.yunits_)
        out = obj.yunits_;
      else
        out{1:size(obj,2)} = deal('uV');
      end;
    end;    
    function set.yUnits(obj,val)
      if isempty(val), obj.yunits_ = []; return; end;
      assert(ischar(val)||iscellstr(val),...
              'yunits must be a character string or cell array of strings');
      if ~iscellstr(val)
        [cellVal{1:size(obj,2)}] = deal(val); 
      else
        cellVal = val;
      end;
      
      assert(numel(cellVal)==size(obj,2),...
              'yunits must have a number of elements equal to the number of channels');
      obj.yunits_ = cellVal;                        
    end    
    
    %% Get/Set Methods for Data
    function out = get.data(obj)
      out = obj.data_;
    end    
    function set.data(obj,val)
      if ~isempty(obj.labels_)
        assert(size(val,2)==numel(obj.labels_),...
                'Number of channels in data must match number of labels');              
      end
      if ~isempty(obj.xvals_)
        assert(size(val,1)==numel(obj.xvals_),...
                'Number of timepoints must match numel(obj.xvals)');
      end
      obj.data_ = val;
    end
           
    %% Set/Get Methods for obj.labels
    function out = get.labels(obj)
      if isempty(obj.labels_)              
        % Default channel labels        
        out = cell(1,size(obj.data,2));
        for i = 1:size(obj.data,2),
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
      assert(isempty(obj.data)||(numel(val)==size(obj,2)),...
        'Number of labels must match number of channels');
      obj.labels_ = strtrim(val);
    end % END set.labels
            
    %% Get/Set Methods for obj.sampleRate
    function out = get.sampleRate(obj)
      if ~isempty(obj.sampleRate_)
       out = obj.sampleRate_;
      else
       out = 1;
      end;
    end;   
    function set.sampleRate(obj,val)
      if isempty(val), obj.sampleRate = []; return; end;
      assert(isnumeric(val)&&isscalar(val),...
         'Sample rate must be a scalar numeric value');
       obj.sampleRate_ = val;
    end
            
    %% Get/Set Methods for obj.xvals    
    function out = get.xvals(obj)
      if ~isempty(obj.xvals_)
        out = obj.xvals_;
      else    
        % Default timing values
        out = (1./obj.sampleRate)*(0:size(obj.data,1)-1);
      end;
    end    
    function set.xvals(obj,val)
      if isempty(val), obj.xvals_ = []; return; end;
      assert( isvector(val) && numel(val)==size(obj.data,1),...
            'xVals vector length must match size(obj.data,1)');
      assert( issorted(val), 'xVals should be a sorted list of time values');
      obj.xvals_ = val;
    end;    
    
    %% Get/Set Methods for obj.yrange
    function rangeOut = get.yrange(obj)
      dataChans = obj.getChannelsByType('data');   
      if ~any(dataChans)
        rangeOut = [0 1]; return;
      end;
      rangeOut = [min(min(obj.data(:,dataChans))) ...
                  max(max(obj.data(:,dataChans)))];                
    end;                  
    function set.yrange(obj,~)
      error('obj.yrange is derived from obj.data');
    end;
        
    %% Get/Set Methods for obj.xrange
    function rangeOut = get.xrange(obj)
      rangeOut = [obj.xvals(1) obj.xvals(end)];
    end;    
    function set.xrange(obj,~)
      error('obj.xrange is derived from obj.xvals');
    end;     
    
    %% Methods with their own m-files
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    plotOut = butterfly(tseries,varargin)
    
    
    %% Deprecated functionality.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function out = getDataChannels(obj)
      warning('DEPRECATED');
      out = obj.getChannelsByType('data');
    end    
    function out = getBoolChannels(obj)
      warning('DEPRECATED');
      out = obj.getChannelsByType('bool');
    end    
    function out = getAuxChannels(obj)
      warning('DEPRECATED');
      out = obj.getChannelsByType('aux');
    end        
    function out = isDataChannel(obj)
      warning('DEPRECATED');
      out = obj.isChannelType('data');
    end    
    function out = isBoolChannel(obj)
      warning('DEPRECATED');
      out = obj.isChannelType('bool');
    end    
    function out = isAuxChannel(obj)
      warning('DEPRECATED');
      out = obj.isChannelType('aux');
    end    
    
  end;
  
  methods (Static=true)
  end
  
end
