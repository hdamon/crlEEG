classdef labelledArray < handle & matlab.mixin.Copyable
  % Handle data array with labelled axes
  %
  % obj = labelledArray(data,varargin)
  %
  % Inputs
  % ------
  %   data : The data to put in the array
  %
  % Optional Param-Value Inputs
  % ---------------------------
	%  'names'  : Names for each dimension.
  %  'labels' : An cell array defining labels for one or more dimensions.
  %               This array must be of size (N X 2), arranged as:
  %                { <DIMENSION A> , <CellString of Labels> ;
  %                  <DIMENSION B> , <CellString of Labels> }
  %               Each dimension must be a scalar numeric value, with no
  %               repeats. Each cell string must have a number of elements
  %               equal to the current size of the data along that
  %               dimension.
  %  'values' : A cell array of values along one or more dimensions. Cell
  %               array should be formatted as for 'labels', except instead
  %               of the values beign cell strings, they must be numeric
  %               vectors.
  %
  % Overloaded Functions
  % --------------------
  %    size : Behaves in one of two ways:
  %             1) For an array of labelledData objects, returns the size
  %                   of the array.
  %             2) For a single labelledData object, returns the size of
  %                   the data.
  %
  %   ndims : Behavines in one of two ways:
  %             1) For an array of labelledData objects, returns the size
  %                   of the array.
  %             2) For a single labelledData object, returns the size of
  %                   the data.
  %
  % NOTE: The easiest way to determine which behavior will be elicited is
  %         to check numel(obj).  If numel(obj)>1, you get standard
  %         behavior.
  %
  % Referencing into labelledData Objects
  % -------------------------------------
  %   Referencing for labelledData objects behaves slightly differently
  %   than for normal Matlab arrays.
  %
  %  obj.<property> : Behaves normally.
  %
  %  obj(<indices>) : Behaves in one of two ways:
  %                     1) If obj is an array of labelledData objects, this
  %                          references into the array
  %                     2) If obj is a single labelledData object, this
  %                          returns a new object with the data, values,
  %                          and labels subselected according to the
  %                          indices.
  %
  %  obj{<indices>} : References into an array of labelledData objects.
  %                     This works correctly in combination with (), so
  %                     that expressions such as:
  %                       obj{i}(x,y,z)       and
  %                       obj{i}.data(x,y,z)
  %                     work as expected.
  %
  
  properties (Hidden,Dependent)
    data
		names
    labels
    values
  end
  
  properties (Access=protected) % Should possibly be private?
    data_   % The data array
		names_  % Names for each dimension
    labels_ % Labels for individual elements of each axis
    values_ % Values for each axis (time,frequency,etc)
  end
  
  methods
    
    function obj = labelledArray(data,varargin)
      
      if nargin>0
        
        checkType = @(x) iscell(x) && (size(x,2)==2);
        
        p = inputParser;
        p.addRequired('data',@(x) (isnumeric(x)||isa(x,'labelledArray')));
        p.addParameter('labels',[],@(x) isempty(x)||checkType(x));
        p.addParameter('values',[],@(x) isempty(x)||checkType(x));
				p.addParameter('names',[],@(x) isempty(x)||checkTYpe(x));
        p.parse(data,varargin{:});
        
        obj.data   = p.Results.data;
				obj.names  = p.Results.names;
        obj.labels = p.Results.labels;
        obj.values = p.Results.values;
      end
      
    end
    
    %% Overloaded
    function out = size(obj,dim)
			% Return the size of a labelledArray object
			% 
			% out = size(obj,dim)
			%
			% Behaves in one of two ways:
			%  1) If obj is a single labelledArray object, returns the
			%				size of obj.data_
			%	 2) If obj is an array of labelledArray objects, returns the 
			%				size of the array.
			%
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
    
    function out = ndims(obj)
      % Get dimensionality of array
      %
      % Ignores trailing singleton dimensions.
      %
      
      if numel(obj)==1
        if isempty(obj.data_)
          out = 0;
          return;
        end
        out = builtin('ndims',obj.data_);
      else
        out = builtin('ndims',obj);
      end;
    end		

		function out = permute(obj,order)
		  % Permute the order of the array
			%
			% out = permute(obj,order)
			%
			% Inputs
			% ------
			%  obj : labelledArray object
			%  order : One of two forms:
			%						1) A numeric array of dimension indices
			%						2) A cell array combining numeric indices and
			%								dimension names.
			%	
	
			% Get the numeric indices of the new ordering.	
			if isnumeric(order)&&isvector(order)
				newOrder = order;
			elseif iscell(order)
				for i = 1:numel(order)
					if isnumeric(order{i})&&isscalar(order{i})
						newOrder(i) = order{i};
					elseif ischar(order{i})
					  newOrder(i) = obj.getDimByName(order{i});
					else
						error('Invalid permutation argument');
					end;
				end
			end
			
			out = obj.copy;
			out.data_   = permute(obj.data_,newOrder);
			out.names_  = obj.names_(newOrder);
			out.labels_ = obj.names_(newOrder);
			out.values_ = obj.names_(newOrder);

		end

    %% Data Get/Set Methods
    function set.data(obj,val)
      %% Set data method
      
      if ~isempty(obj.data_)
        % Check Overall Dimensionality
        nDims = builtin('ndims',val);
        if (nDims~=obj.ndims)&&(obj.ndims~=0)
          error('Data dimensionality does not match existing size');
        end
        
        % Check Individual Dimension Sizes
        for idxDim = 1:nDims
          dimSize = size(val,idxDim);
          
          if ( dimSize ~= size(obj.data_,idxDim) )
            error(['Input data does not match current size on dimension: ' num2str(idxDim)]);
          end
        end
      end
      
      obj.data_ = val;
      
      %% Initialize labels and values
      if isempty(obj.labels_)
        obj.labels_ = cell(obj.ndims,1);
      end
      
      if isempty(obj.values_)
        obj.values_ = cell(obj.ndims,1);
      end
      
    end
    
    function out = get.data(obj)
      out = obj.data_;
    end;
   
		%% Name Get/Set Methods
		function set.names(obj,val)
			
			if isempty(val)
				obj.names_ = cell(obj.ndims,1);
			end;

			assert(iscell(val)&&size(val,2)==2);

			for i = 1:size(val,1)
				currDim = val{i,1};
	      currVal = val{i,2};
        
        assert(isnumeric(currDim)&&isscalar(currDim),...
          'Dimension parameter must be a numeric scalar');
        
        % Convert char to cellstr
        if ischar(currVal), currVal = {currVal}; end;
        assert(iscellstr(currVal)||isempty(currVal),...
          ['Names must be strings or cellstrings']);
      end
      
      % Assign Names if All Checks Passed
      for i = 1:size(val,1)
        obj.names_{val{i,1}} = val{i,2};
      end
  	
		end
 
    %% Label Get/Set Methods
    function set.labels(obj,val)
      
      if isempty(val)
        obj.labels_ = cell(obj.ndims,1);
        return;
      end
      
      assert(iscell(val)&&size(val,2)==2,'Incorrect input shape');
      
      % Check Input
      for i = 1:size(val,1)
        currDim = val{i,1};
        currVal = val{i,2};
       
				if ischar(currDim), 
					currDim = obj.getDimByName(currDim); 
				end;
	 
        assert(isnumeric(currDim)&&isscalar(currDim),...
          'Dimension parameter must be a numeric scalar');
        
        % Convert char to cellstr
        if ischar(currVal), currVal = {currVal}; end;
        assert(iscellstr(currVal)||isempty(currVal),...
          ['Labels must be strings or cellstrings']);
        
        assert(isempty(currVal)||(numel(currVal)==size(obj.data_,currDim)),...
          'Must provide labels for the full dimension');
      end
      
      % Assign Labels if All Checks Passed
      for i = 1:size(val,1)
        obj.labels_{val{i,1}} = val{i,2};
      end
      
    end
    
    function out = get.labels(obj)
      out = obj.labels_;
    end;
    
    %% Value Get/Set Methods
    function set.values(obj,val)
      
      if isempty(val)
        obj.values_ = cell(obj.ndims,1);
        return;
      end;
      
      assert(iscell(val)&&size(val,2)==2,'Incorrect input shape');
      
      for i = 1:size(val,1)
        currDim = val{i,1};
        currVal = val{i,2};

				if ischar(currDim),
					currDim = obj.getDimByName(currDim);
				end;

        assert(isnumeric(currDim)&&isscalar(currDim),...
          'Dimension parameter must be a numeric scalar');
        
        assert(isempty(currVal)||(isnumeric(currVal)&&isvector(currVal)),...
          'Value inputs must be numeric vectors');
        
        assert(isempty(currVal)||(numel(currVal)==size(obj.data_,currDim)),...
          'Most provide values for the full dimension');
      end
      
      % Assign Values if All Checks Passed
      for i = 1:size(val,1)
        obj.values_{i} = val{i,2};
      end
    end
    
    function out = get.values(obj)
      out = obj.values_;
    end;
    
  end
  
  %% Protected Methods
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  methods (Access=protected)
   
		function idxOut = getDimByName(obj,names)
			% Return the numeric index of the dimension associated with a name
			%
			% idxOut = getDimByName(obj,names)
			%	
			% Inputs
			% ------
			%		obj : labelledArray object
			%	names : Character string or stringcell of dimension names
			%
			% Outputs	
			% -------
			%  idxOut : Numeric index of the dimensions associated with
			%							the strings in names
			%
			%
	
				assert(ischar(names)|iscellstr(names),...
								'Dimension names must be strings of cellstrings');

				if ischar(names), names = {names}; end;

				idxOut = nan(1,numel(names));
				for i = 1:numel(names)
					matchedName = validateString(names{i},obj.names);
					idx{i} = find(ismember(obj.names,matchedName);
					if isempty(idx{i})
						error(['Dimension name: ' names{i} ' not found']);
					end
				end

		end

		function indexOrder = getIndexOrder(obj,varargin)
			% 
    end

		function idxOut = anyIndexToNumeric(obj,varargin)
			% Super generalized conversion of indexing into numeric indices
			%
			% idxOut = rectifyIndexing(obj,varargin)
			%
			% Inputs
			% ------
			%       obj : labelledArray object
			%  varargin : Input indexing
			%
			% What options for indexing should this support?
			%  1) Straight up numeric indexing
			%				obj(x,y,z)
			%	 2) Name indexing along each dimension
			%				obj({'A' 'B' 'C'},'X','foo')
			%  3) Name indexing by both dimension and index
			%       obj({'dimA', {'A' 'B' 'C'}},{'dimB', {'X' 'Y' 'Z'}},[1 2 3]})
			%
			% How much freedom should be allowed in the indexing?
			% Should arbitrary indexing with automatic permutation be supported?
			%


			% Straight up numeric indexing
			fullyNumeric = true;
			for i = 1:numel(varargin)
				if isnumeric(varargin{i})&&
		end
 
    function idxOut = getNumericIndex(obj,varargin)
      % Get numeric indexing into a single labelledArray object
      %
      % idxOut = getNumericIndex(obj,varargin)
      %
      % Inputs
      % ------
      %      obj : A labelledData object
      % varargin : Indexes into each dimension.
      %              This must satisfy numel(varargin)==obj.ndims
      %              Provided indexing values can be:
      %                       ':' : All Values
      %                cellString : Reference by name
      %             numericVector : Reference by numeric index
      %
      % Outputs
      % -------
      %  idxOut : Cell array of numeric indices into each dimension.
      %
      %
      
      assert(numel(obj)==1,'Multiple objects passed. Not sure why we''re getting here');
      
      % Strict for now, might loosen later
      assert(numel(varargin)==obj.ndims,...
        'Indexing into labelledArray objects must include all dimensions');
      
      % Get Indexing for each dimension
      idxOut = cell(obj.ndims,1);
      for idxDim = 1:obj.ndims
        if ~isempty(obj.labels_{idxDim})
					% Dimension has names	
          idxOut{idxDim} = ...
            crlEEG.util.getDimensionIndex(obj.labels_{idxDim},varargin{idxDim});
        else
					% Dimension does not have names
          idxOut{idxDim} = ...
            crlEEG.util.getDimensionIndex(size(obj.data_,idxDim),varargin{idxDim});
        end
      end
    end
    
    function out = copyValuesFrom(obj,valObj)
      % Individually copies values from another object
      %
      % out = copyValuesFrom(obj,valObj)
      %
			% Inputs
			% ------
			%     obj : labelledArray object
			%  valObj : labelledArray object to copy values from
			%
			% Output
			% ------
			%     out : New labelledArray object with values copied from valObj
			%
			% This method is designed to allow copying of object values from one
			% object to another without losing the class of the original passed
			% object. This is primarily used in the constructor when constructing
			% subclasses.
			%
      
      out = obj.copy;
      out.data_   = valObj.data_;
			out.names_  = valObj.names_;
      out.labels_ = valObj.labels_;
      out.values_ = valObj.values_;
    end
        
    function out = subcopy(obj,varargin)
      % Copy a subset of the object
      %
      % out = subcopy(obj,varargin);
      %
      % Inputs
      % ------
      %       obj : A labelledArray object
      %  varargin : Numeric indexes into each dimension.
      %               NOTE: Must satisfy numel(varargin)==obj.ndims
      %
      % Outputs
      % -------
      %  out : labelledArray object with data, labels, and values
      %           subselected based on the provided indices.
      %
      
      dimIdx = obj.getNumericIndex(varargin{:});
      
      assert(numel(obj)==1,'Passed multiple objects. Not sure why we''re getting here');
      
      assert(numel(varargin)==obj.ndims,...
        'Must include referencing for all dimensions');
      
      tmpData = obj.data(varargin{:});
      tmpLabels = cell(obj.ndims,1);
      tmpValues = cell(obj.ndims,1);
      
      for idxDim = 1:obj.ndims
        
        if ~isempty(obj.labels{idxDim})
          tmpLabels(idxDim) = obj.labels{idxDim}(dimIdx{idxDim});
        end
                
        if ~isempty(obj.values{idxDim})
          tmpValues(idxDim) = obj.values{idxDim}(dimIdx{idxDim});
        end
      end;
      
      out = obj.copy;
      out.data_ = tmpData;
      out.labels_ = tmpLabels;
      out.values_ = tmpValues;
      
      %out = labelledArray(tmpData,'labels',tmpLabels,'values',tmpValues);
      
    end
  end
  
end
