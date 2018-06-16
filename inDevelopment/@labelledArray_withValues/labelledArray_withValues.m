classdef labelledArray_withValues < labelledArray
  % Adds dimension units and values to a labelledArray
  
  properties (Hidden, Dependent)
    dimValues
    dimUnits
  end
  
  properties (Access = protected)
    dimValues_
    dimUnits_
  end
  
  methods
    
    function obj = labelledArray_withValues(varargin)
      
      checkType = @(x) iscell(x) && ((size(x,2)==2)||(numel(x)==ndims(array)));
      
      p = inputParser;
      p.KeepUnmatched = true;
      p.addOptional('array',[],@(x) isnumeric(x)||isa(x,'labelledArray')||isa(x,'labelledArray_withValues'));
      p.addParameter('dimUnits',[],@(x) isempty(x)||checkType(x));
      p.addParameter('dimValues',[],@(x) isempty(x) ||checkType(x));
      p.parse(varargin{:});
      
      obj = obj@labelledArray(p.Results.array,p.Unmatched);
      obj.dimUnits  = p.Results.dimUnits;
      obj.dimValues = p.Results.dimValues;
    end

    function out = permute(obj,order)
      
      newOrder = obj.getDimensionOrdering(order);
      out = obj.permute@labelledArray(newOrder);
      out.dimValues_ = obj.dimValues_(newOrder);
      obj.dimUnits_ = obj.dimUnits_(newOrder);
      
    end
    
    
    %% Label Get/Set Methods
    function set.dimUnits(obj,val)
      
      if isempty(val)
        obj.dimUnits_ = cell(obj.ndims,1);
        return;
      end
      
      val = obj.validateCellInput(val);      
      
      % Check Input
      for i = 1:size(val,1)
        currDim = val{i,1};
        currVal = val{i,2};
       
				if ischar(currDim)
					currDim = obj.getDimByName(currDim); 
				end;
	 
        assert(isnumeric(currDim)&&isscalar(currDim),...
          'Dimension parameter must be a numeric scalar');
        
        % Convert char to cellstr
        if ischar(currVal), currVal = {currVal}; end;
        assert(iscellstr(currVal)||isempty(currVal),...
          ['dimUnits must be strings or cellstrings']);
        
        assert(isempty(currVal)||...
               numel(currVal)==1 ||...
               (numel(currVal)==size(obj.array_,currDim)),...
          'Must provide dimUnits for the full dimension');
      end
      
      % Assign dimUnits if All Checks Passed
      for i = 1:size(val,1)
        if ~isempty(val{i,2})
          obj.dimUnits_{val{i,1}} = strtrim(val{i,2});
        else
          obj.dimUnits_{val{i,1}} = {''};
        end;
      end
      
    end
    
    function out = get.dimUnits(obj)
      out = obj.dimUnits_;
    end;    


    
    %% Value Get/Set Methods
    function set.dimValues(obj,val)
      
      if isempty(val)
        obj.dimValues_ = cell(obj.ndims,1);
        return;
      end;
      
      val = obj.validateCellInput(val);
            
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
        
        assert(isempty(currVal)||(numel(currVal)==size(obj.array_,currDim)),...
          'Most provide dimValues for the full dimension');
      end
      
      % Assign dimValues if All Checks Passed
      for i = 1:size(val,1)
        obj.dimValues_{i} = val{i,2};
      end
    end
    
    function out = get.dimValues(obj)
      out = obj.dimValues_;
    end;
    
  end    
    
  methods (Access=protected)
    
    function setArray(obj,val)
      obj.setArray@labelledArray(val);
      
      if isempty(obj.dimValues_)
        obj.dimValues_ = cell(obj.ndims,1);
      end
      
      if isempty(obj.dimUnits_)
        obj.dimUnits_ = cell(obj.ndims,1);
      end;
    end
    
    function out = copyValuesFrom(obj,valObj)
      
      assert(isa(valObj,'labelledArray_withValues'),...
                'Can only copy from a labelledArray_withValues object');
      out = obj.copyValuesFrom@labelledArray(valObj);
      out.dimValues_ = valObj.dimValues_;
      out.dimUnits_  = valObj.dimUnits_;
    end
    
    function [out,varargout] = subcopy(obj,varargin)
      
      [out,dimIdx] = obj.subcopy@labelledArray(varargin{:});
      
      tmpdimValues = cell(obj.ndims,1);
      tmpdimUnits  = cell(obj.ndims,1);
      
      for idxDim = 1:obj.ndims               
        currValues = obj.dimValues{idxDim};
        if ~isempty(currValues)
          tmpdimValues{idxDim} = currValues(dimIdx{idxDim});
        end;
        
        currUnits = obj.dimUnits{idxDim};
        if ~isempty(currUnits)
          if ischar(currUnits)
            tmpdimUnits{idxDim} = currUnits;
          else
            tmpdimUnits{idxDim} = currUnits(dimIdx{idxDim});
          end
        end;
      end
      out.dimUnits_  = tmpdimUnits;
      out.dimValues_ = tmpdimValues;
      
      if nargout==2
        varargout{1} = dimIdx;
      end;
    end
    
  end
  
  
end