classdef scalar3D < handle
    
  properties
    name
    data
    grid
    orientation
  end
  
  properties (Dependent = true)
    aspect
    range
  end
  
  properties (Access = protected)
    range_internal;
  end
  
  events
    objUpdated
  end
    
  methods
    
    function obj = scalar3D(varargin)
      p = inputParser;
      p.KeepUnmatched = true;
      p.addOptional('data',[]);
      p.addParamValue('orientation','left-posterior-superior',@(x) ischar(x));
      p.addParamValue('name','VOL',@(x) ischar(x));
      p.addParamValue('grid',[],@(x) isa(x,'crlEEG.basicobj.gridInSpace'));
      parse(p,varargin{:});
      
      obj.data = p.Results.data;
      obj.name = p.Results.name;
      obj.orientation = p.Results.orientation;
      
      if ~isempty(p.Results.grid)
        obj.grid = p.Results.grid;
      else
        obj.grid = crlEEG.basicobj.gridInSpace(size(obj),p.Unmatched);      
      end
    end
    
    function s = size(obj,dim)
      % Overloaded size method.
      if exist('dim','var')
        s = size(obj.data,dim);
      else
        s = size(obj.data);
      end;
    end
    
    function set.data(obj,val)
      if isempty(val), obj.data = []; return; end;
      assert(numel(size(val))==3,'scalar3D is for three dimensional volumes');
      assert(isnumeric(val),'scalar3D requires a numeric input');
      if ~isequal(obj.data,val)
        obj.data = val;    
        obj.updateRange;
        notify(obj,'objUpdated');
      end; 
    end;
    
    function out = getSliceByIndex(obj,axis,slice)
      assert(exist('axis','var')&&~isempty(axis),'Must select an axis');
      assert(ismember(axis,1:obj.grid.dimension),...
                'Invalid axis identifier');
      assert(exist('slice','var')&&~isempty(slice),'Must select a slice');
      assert((slice>0)&&(slice<size(obj,axis)),...
                'Selected slice is out of range');
      idx = {':'};
      idx = idx(ones(1,obj.grid.dimension));
      idx{axis} = slice;
      
      % Should this get squeezed?
      out = (obj.data(idx{:}));              
    end
    
  end
  
  methods (Access=protected)
    function checkConsistency(obj)
      dSize = size(obj.data);
      gSize = 1;
      
    end
    
    function updateRange(obj)
      % Exclude infinite and non-number values
      Qnan = isnan(obj.data(:));
      Qinf = isinf(obj.data(:));
      valid = ~Qnan & ~Qinf;
      obj.range_internal = [min(obj.data(valid)) max(obj.data(valid))];
    end;
  end
end