classdef labelledArray < handle & matlab.mixin.Copyable
  % Handle array array with labelled axes
  %
  % obj = labelledArray(array,varargin)
  %
  % Inputs
  % ------
  %   array : The array to put in the array
  %
  % Optional Param-Value Inputs
  % ---------------------------
  %  'dimNames'  : dimNames for each dimension.
  %  'dimLabels' : An cell array defining dimLabels for one or more dimensions.
  %               This array must be of size (N X 2), arranged as:
  %                { <DIMENSION A> , <CellString of dimLabels> ;
  %                  <DIMENSION B> , <CellString of dimLabels> }
  %               Each dimension must be a scalar numeric value, with no
  %               repeats. Each cell string must have a number of elements
  %               equal to the current size of the array along that
  %               dimension.
  %  'dimValues' : A cell array of dimValues along one or more dimensions. Cell
  %               array should be formatted as for 'dimLabels', except instead
  %               of the dimValues beign cell strings, they must be numeric
  %               vectors.
  %
  % Overloaded Functions
  % --------------------
  %    size : Behaves in one of two ways:
  %             1) For an array of labelledarray objects, returns the size
  %                   of the array.
  %             2) For a single labelledarray object, returns the size of
  %                   the array.
  %
  %   ndims : Behavines in one of two ways:
  %             1) For an array of labelledarray objects, returns the size
  %                   of the array.
  %             2) For a single labelledarray object, returns the size of
  %                   the array.
  %
  % NOTE: The easiest way to determine which behavior will be elicited is
  %         to check numel(obj).  If numel(obj)>1, you get standard
  %         behavior.
  %
  % Referencing into labelledarray Objects
  % -------------------------------------
  %   Referencing for labelledarray objects behaves slightly differently
  %   than for normal Matlab arrays.
  %
  %  obj.<property> : Behaves normally.
  %
  %  obj(<indices>) : Behaves in one of two ways:
  %                     1) If obj is an array of labelledarray objects, this
  %                          references into the array
  %                     2) If obj is a single labelledarray object, this
  %                          returns a new object with the array, dimValues,
  %                          and dimLabels subselected according to the
  %                          indices.
  %
  %  obj{<indices>} : References into an array of labelledarray objects.
  %                     This works correctly in combination with (), so
  %                     that expressions such as:
  %                       obj{i}(x,y,z)       and
  %                       obj{i}.array(x,y,z)
  %                     work as expected.
  %
  
  properties (Hidden,Dependent)
    array
    dimNames
    dimLabels
    % dimValues
  end
  
  properties (Access=protected) % Should possibly be private?
    array_   % The array array
    dimNames_  % dimNames for each dimension
    dimLabels_ % dimLabels for individual elements of each axis
    % dimValues_ % dimValues for each axis (time,frequency,etc)
  end
  
  methods
    
    %%
    function obj = labelledArray(array,varargin)
      
      if nargin>0
        
        checkType = @(x) iscell(x) && ((size(x,2)==2)||(numel(x)==ndims(array)));
        
        p = inputParser;
        p.addRequired('array',@(x) (isnumeric(x)||isa(x,'labelledArray')));
        p.addParameter('dimLabels',[],@(x) isempty(x)||checkType(x));
        %p.addParameter('dimValues',[],@(x) isempty(x)||checkType(x));
        p.addParameter('dimNames',[],@(x) isempty(x)||checkType(x));
        p.parse(array,varargin{:});
        
        obj.array   = p.Results.array;
        obj.dimNames  = p.Results.dimNames;
        obj.dimLabels = p.Results.dimLabels;
        %obj.dimValues = p.Results.dimValues;
      end
      
    end
    
    %% Overloaded Functions
    %%%%%%%%%%%%%%%%%%%%%%%
    
    %%
    function out = size(obj,dim)      
      %% Return the size of a labelledArray object
      %
      % out = size(obj,dim)
      %
      % Behaves in one of two ways:
      %  1) If obj is a single labelledArray object, returns the
      %				size of obj.array_
      %	 2) If obj is an array of labelledArray objects, returns the
      %				size of the array.
      %
      if numel(obj)==1
        if ~exist('dim','var')
          out = size(obj.array);
        else
          out = size(obj.array,dim);
        end;
      else
        out = builtin('size',obj);
      end
    end
    
    %%
    function out = ndims(obj)
      % Get dimensionality of array
      %
      % Ignores trailing singleton dimensions.
      %
      
      if numel(obj)==1
%         if isempty(obj.array_)
%           out = 0;
%           return;
%         end
        out = builtin('ndims',obj.array_);
      else
        out = builtin('ndims',obj);
      end;
    end
    
    %%
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
      %								dimension dimNames.
      %
      
      newOrder = obj.getDimensionOrdering(order);
      
      out = obj.copy;
      out.array_   = permute(obj.array_,newOrder);
      out.dimNames_  = obj.dimNames_(newOrder);
      out.dimLabels_ = obj.dimLabels_(newOrder);
      %out.dimValues_ = obj.dimValues_(newOrder);
      
    end
    
    %% array Get/Set Methods
    function set.array(obj,val)
      % Done this way so it can be overloaded by subclasses.
      obj.setArray(val);
    end;    
    
    function out = get.array(obj)
      out = obj.array_;
    end;
    
    %% Name Get/Set Methods
    %%%%%%%%%%%%%%%%%%%%%%%
    function set.dimNames(obj,val)
      % Set Dimension Names
      %
      
      if isempty(val)
        % Gets an empty cell for each dimension
        obj.dimNames_ = cell(obj.ndims,1);
        return;
      end;
      
      val = obj.validateCellInput(val);
      
      for i = 1:size(val,1)
        currDim = val{i,1};
        currVal = val{i,2};
        
        assert(isnumeric(currDim)&&isscalar(currDim),...
          'Dimension parameter must be a numeric scalar');
        
        % Convert char to cellstr
        if ischar(currVal), currVal = {currVal}; end;
        assert(iscellstr(currVal)||isempty(currVal),...
          ['dimNames must be strings or cellstrings']);
      end
      
      % Assign dimNames if All Checks Passed
      for i = 1:size(val,1)
        if isempty(val{i,2})
          obj.dimNames_{val{i,1}} = [];
        else
          obj.dimNames_{val{i,1}} = strtrim(val{i,2});
        end;
      end
      
    end
        
    function out = get.dimNames(obj)
      out = obj.dimNames_;
    end;
    
    %% Label Get/Set Methods
    %%%%%%%%%%%%%%%%%%%%%%%%
    function set.dimLabels(obj,val)
      
      if isempty(val)        
        % Empty cell for each dimension
        obj.dimLabels_ = cell(obj.ndims,1);
        return;
      end
      
      val = obj.validateCellInput(val);
      
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
          ['dimLabels must be strings or cellstrings']);
        
        assert(isempty(currVal)||(numel(currVal)==size(obj.array_,currDim)),...
          'Must provide dimLabels for the full dimension');
      end
      
      % Assign dimLabels if All Checks Passed
      for i = 1:size(val,1)
        if isempty(val{i,2})          
          % Empty dimension
          obj.dimLabels_{val{i,1}} = [];
        else
          obj.dimLabels_{val{i,1}} = strtrim(val{i,2});        
        end;
      end
      
    end
    
    %%
    function out = get.dimLabels(obj)
      out = obj.dimLabels_;
    end;
    
  end
  
  %% Protected Methods
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  methods (Access=protected)
    
    %%
    function newOrder = getDimensionOrdering(obj,order)
      %% Get the numeric indices of the new ordering.
      %
      % newOrder = getDimensionOrdering(obj,order)
      %
      % Inputs
      % ------
      %    obj : labelledArray object
      %  order : New dimension ordering for the object
      %           Can be:
      %             1) A numeric vector indexing the dimensions
      %             2) A cell array, with either numeric dimension indices
      %                 or character strings referencing index names.
      %
      % Outputs
      % -------
      %  newOrder : New order, with numeric dimension referencing
      %
      newOrder = nan(1,numel(order));
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
      else
        error('Invalid permutation argument');
      end
      
      assert(numel(unique(newOrder))==numel(newOrder),...
                'Each dimension can only be used once');
      
    end;
    
    %%
    function idxOut = getDimensionIndex(obj,dimRefs)
      %% Return the numeric index of the dimension, given a numeric or name based reference
      %
      % idxOut = getDimByName(obj,dimRef)
      %
      % Inputs
      % ------
      %		obj  : labelledArray object
      %	dimRef : Numeric vector of dimension indices, character string with
      %             a single name, or a cell array of numeric indices and 
      %             character strings.
      %
      % Outputs
      % -------
      %  idxOut : Numeric index of the dimensions associated with
      %							the strings in dimNames
      %
      %
      
      assert((isnumeric(dimRefs)&&isvector(dimRefs))||...
              ischar(dimRefs)||iscell(dimRefs),...
        'See getDimensionIndex help for input format requirements');
      
      if ischar(dimRefs), dimRefs = {dimRefs}; end;
      
      if ~isnumeric(dimRefs)
        % Get numeric indices from a cell array
       idxOut = nan(1,numel(dimRefs));
       
       for idxRef = 1:numel(dimRefs)
         currRef = dimRefs{idxRef};
         if ischar(currRef)         
           if ~isempty(obj.dimNames)
             matchedName = validatestring(currRef,obj.dimNames);
             idx{idxRef} = find(ismember(obj.dimNames,matchedName));
           end;
%            if isempty(idx{idxRef})
%              % Don't think we ever actually get here?
%              error(['Dimension name: ' currRef ' not found']);
%            end
         elseif isnumeric(currRef)&&isscalar(currRef)
           idxOut(idxRef) = currRef;
         else
           error('Unknown reference type');
         end           
       end
      else
        idxOut = dimRefs;
      end
      
      assert(all(floor(idxOut)==idxOut)&&all(idxOut>=1)&&all(idxOut<=obj.ndims),...
                'Requested dimension is out of range');
      
    end
    
    
    %%
    function idxOut = getNumericIndex(obj,varargin)
      %% Get numeric indexing into a single labelledArray object
      %
      % idxOut = getNumericIndex(obj,varargin)
      %
      % Inputs
      % ------
      %      obj : A labelledarray object
      % varargin : Cell array of indexes into each dimension.
      %              This must satisfy numel(varargin)==obj.ndims
      %              Provided indexing dimValues can be:
      %                       ':' : All dimValues
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
      %assert(numel(varargin)==obj.ndims,...
      %  'Indexing into labelledArray objects must include all dimensions');
      
      % Get Indexing for each dimension
      idxOut = cell(obj.ndims,1);
      for idxDim = 1:obj.ndims
        if idxDim<=numel(varargin)          
          idxOut{idxDim} = obj.indexIntoDimension(idxDim,varargin{idxDim});
        else
          idxOut{idxDim} = ':';
        end;
      end
    end
    
    %%
    function idxOut = indexIntoDimension(obj,dim,index)
      %% Numeric or name based indexing into a single dimension
      
      if isempty(obj.dimLabels_{dim})
        cellIn = [];
        isStringValid = false;
      else
        cellIn = obj.dimLabels_{dim};
        isStringValid = true;
      end;
      
      if isequal(index,':')
        %% Requested Everything
        idxOut = index;
        return;
        
      elseif islogical(index)
        %% Logical Indexing
        assert(numel(index)==size(obj,dim),'FOOOO_-');
        idxOut = find(index);
        return;
        
      elseif isnumeric(index)
        %% Numeric Reference
        if any(index<1)||any(index>size(obj,dim))
          error('Requested index outside of available range');
        end;
        idxOut = index;
        %idxOut(idxOut<1) = nan;
        %idxOut(idxOut>numel(cellIn)) = nan;
        return;
                
      elseif ischar(index)||iscellstr(index)
        %% String Reference
        if ~isStringValid
          error('String indexing unavailable for this dimension');
        end;
        
        if ischar(index), index = {index}; end;
        cellIn = strtrim(cellIn);
        index = strtrim(index);
        idxOut = zeros(1,numel(index));
        for idx = 1:numel(idxOut)
          tmp = find(strcmp(index{idx},cellIn));
          if isempty(tmp)
            error('Requested string does not appear in cell array');
          end;
          assert(numel(tmp)==1,'Multiple string matches in cellIn');
          idxOut(idx) = tmp;
        end
        
      else
        %% Otherwise, error.
        error('Incorrect reference type');
      end;
      
    end
    
    %%
    function out = copyValuesFrom(obj,valObj)
      %% Individually copies dimValues from another object
      %
      % out = copyValuesFrom(obj,valObj)
      %
      % Inputs
      % ------
      %     obj : labelledArray object
      %  valObj : labelledArray object to copy dimValues from
      %
      % Output
      % ------
      %     out : New labelledArray object with dimValues copied from valObj
      %
      % This method is designed to allow copying of object dimValues from one
      % object to another without losing the class of the original passed
      % object. This is primarily used in the constructor when constructing
      % subclasses.
      %%%%
      
      assert(isa(valObj,'labelledArray'),...
              'Can only copy from a labelledArray object');
      
      out = obj.copy;
      out.array_   = valObj.array_;
      out.dimNames_  = valObj.dimNames_;
      out.dimLabels_ = valObj.dimLabels_;
      %out.dimValues_ = valObj.dimValues_;
    end
    
    %%
    function [out,varargout] = subcopy(obj,varargin)
      %% Copy a subset of the object
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
      %  out : labelledArray object with array, dimLabels, and dimValues
      %           subselected based on the provided indices.
      %%%%%%%%%%%
      
      dimIdx = obj.getNumericIndex(varargin{:});
      
      assert(numel(obj)==1,'Passed multiple objects. Not sure why we''re getting here');      
      assert(numel(varargin)==obj.ndims,...
        'Must include referencing for all dimensions');
      
      tmparray = obj.array(varargin{:});
      tmpdimLabels = cell(obj.ndims,1);      
      
      for idxDim = 1:obj.ndims        
        if ~isempty(obj.dimLabels{idxDim})
          tmpdimLabels{idxDim} = obj.dimLabels{idxDim}(dimIdx{idxDim});
        end        
      end;
      
      out = obj.copy;
      out.array_ = tmparray;
      out.dimLabels_ = tmpdimLabels;     
      
      if nargout==2
        % Pass out the index, if requested.
        varargout{1} = dimIdx;
      end;
                 
    end
    
    %%
    function validCell = validateCellInput(obj,val)
      %% Check cell input arrays, and convert style if necessary.
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      assert(iscell(val)&&((size(val,2)==2)||...
        (numel(val)==obj.ndims)),'Incorrect input shape');
      
      % Check if input is already formatted correctly
      isValid = true;
      validCell = cell(size(val,1),2);
      if size(val,2)==2
        for i = 1:size(val,1)
          
          newDim = obj.getDimensionIndex(val{i,1});
          newVal = val{i,2};
          
          if isnan(newDim)||(~(size(obj,newDim)==numel(newVal)))
            isValid = false;
            break;
          end
          validCell{i,1} = newDim;
          validCell{i,2} = newVal;
        end
      else
        isValid = false;
      end;
      if isValid, return; end;
      
      % All dimensions are defined
      if numel(val)==obj.ndims
        validCell = cell(numel(val),2);
        for i = 1:obj.ndims
          validCell{i,1} = i;
          validCell{i,2} = val{i};
        end
        return;
      end
      
      error('Invalid input');
    end
    
    %%
    function setArray(obj,val)
      %% Set array method
      %%%%%%%%%%%%%%%%%%%
      
      if ~isempty(obj.array_)
        % Check Overall Dimensionality
        nDims = builtin('ndims',val);
        if (nDims~=obj.ndims)&&(obj.ndims~=0)
          error('array dimensionality does not match existing size');
        end
        
        % Check Individual Dimension Sizes
        for idxDim = 1:nDims
          dimSize = size(val,idxDim);
          
          if ( dimSize ~= size(obj.array_,idxDim) )
            error(['Input array does not match current size on dimension: ' num2str(idxDim)]);
          end
        end
      end
      
      obj.array_ = val;
      
      %% Initialize dimLabels and dimValues
      if isempty(obj.dimLabels_)
        obj.dimLabels_ = cell(obj.ndims,1);
      end
      
%       if isempty(obj.dimValues_)
%         obj.dimValues_ = cell(obj.ndims,1);
%       end
      
      if isempty(obj.dimNames_)
        obj.dimNames_ = cell(obj.ndims,1);
      end;
      
    end    
    
  end
  
  
  
end
