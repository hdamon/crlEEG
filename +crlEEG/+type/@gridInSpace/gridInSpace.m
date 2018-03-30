classdef gridInSpace < crlEEG.typegrid
  % classdef gridInSpace < cnlGrid
  %
  % Class defining a cnlGrid embedded in three dimensional space.
  % crlEEG.type.gridInSpace is used to extend cnlGrid to 3D voxelized volumes embedded
  % in real space.  If a 1D or 2D space is defined, it is by default embedded
  % in a fully 3D space, and values for the origin and directions properties
  % will be appropriately buffered with zeros if necessary
  %
  % Constructor Syntax:
  %   obj = crlEEG.typegridInSpace(sizes,origin,directions);
  %          sizes      : 1xN    vector of integer sizes
  %          origin     : 1x3    vector defining space origin
  %          directions : 3xNdim matrix of length 3 vectors defining the space
  %
  % origin and directions are optional parameters.
  %
  % Properties:
  %   Inherited:  sizes       < cnlGrid
  %               dimension   < cnlGrid
  %         New:  origin
  %               directions
  %               orientation
  %               centering = 'cell'
  %
  % Written By: Damon Hyde
  % Last Edited: June 9, 2015
  % Part of the cnlEEG Project
  %
  properties
    % Inherited:
    % sizes
    % dimension
    origin
    directions
    orientation = 'Left-Posterior-Superior';
    centering = 'cell';
  end
  
  properties (Dependent = true)
    voxSize
    boundingBox
    center
    aspect
  end
  
  methods
    
    function obj = gridInSpace(varargin)
      % Constructor Syntax:
      %   obj = crlEEG.typegridInSpace(sizes,origin,directions);
      %         sizes      : 1xN    vector of integer sizes
      %         origin     : 1x3    vector defining space origin
      %         directions : 3xNdim matrix of length 3 vectors defining the space
      %
      % origin and directions are optional parameters.
      
      % Initialize Underlying Grid Object
      obj = obj@crlEEG.typegrid;
      
      % Pass a grid in, get a grid out.
      if nargin>0
      if isa(varargin{1},'crlEEG.typegridInSpace')
        obj.sizes      = sizes.sizes;
        obj.origin     = sizes.origin;
        obj.directions = sizes.directions;
        obj.centering  = sizes.centering;
        return
      end;
      end;
      
      p = inputParser;
      p.addOptional('sizes',[1 1 1],      @(x) isnumeric(x) && isvector(x) );
      p.addParamValue('origin',[0 0 0],   @(x) isnumeric(x) && isvector(x) );
      p.addParamValue('directions',eye(3),@(x) isnumeric(x) && ismatrix(x) );
      p.addParamValue('centering','cell',@(x) ismember(x,{'cell' 'node'}));
      p.parse(varargin{:});
                  
      obj.sizes      = p.Results.sizes;
      obj.origin     = p.Results.origin;
      obj.centering  = p.Results.centering;
      
      dir = p.Results.directions;
      if ismember('directions',p.UsingDefaults)
        dir = dir(:,1:obj.dimension);
      end
      obj.directions = dir;
            
    end
    
    %% Get/Set 
    function set.aspect(obj,val)
      error('Cannot directly set the aspect property of a crlEEG.typegridInSpace object');
    end;
    
    function out = get.aspect(obj)
      % Returns the aspect ratio of the crlEEG.typegridInSpace object
      out = sqrt(sum(obj.directions.^2,1));
    end
    
    function isEqual = eq(a,b)
      % Checks equality of crlEEG.typegridInSpace objects
      %
      % Equality is defined as having the same underlying grids, and
      % origins/direction definitions within 0.01 base units of each other.
      %
      assert(isa(a,'crlEEG.typegridInSpace')&&isa(b,'crlEEG.typegridInSpace'),...
        'Both inputs must be crlEEG.typegridInSpace objects');
      
      isEqual = false;
      if eq@crlEEG.typegrid(a,b)
        if all(abs(a.origin-b.origin)<1e-2) && ...
            all(abs(a.directions(:)-b.directions(:))<1e-2)
          isEqual = true;
        end;
      end
    end
    
    %% Methods with their own m-files
    objOut = getAlternateGrid(obj,type);
    idxOut = getNearestNodes(grid,UseNodes,Positions);
    ptsOut = getGridPoints(grid,idx);
    nodeList = getNodesFromCells(grid,cellList);
    out = resample(obj,resampleLevel);
    obj = straightenDirections(obj);
    
    
    function obj = set.origin(obj,newOrigin)
      % function obj = set.origin(obj,newOrigin)
      %
      %      
      if numel(newOrigin)==3
        obj.origin = newOrigin(:)';
      elseif numel(newOrigin)==obj.dimension;
        tmp = zeros(1,3); 
        tmp(1:obj.dimension) = newOrigin;
        obj.origin = tmp(:)';
      else
        error(['New origin (Dimensionality:' num2str(numel(newOrigin)) ...
                ') does not match grid dimensionality of ' num2str(obj.dimension)]);
      end;
    end
    
    %% Get/Set Methods for the Dependent Property obj.center
    function center = get.center(obj)
      % function center = get.center(obj)
      %
      % Returns the geometric center of the bounding box for the
      % crlEEG.typegridInSpace.
      
      bbox = obj.boundingBox;
      center = 0.125*sum(bbox,1);
    end
    
    function obj = set.center(obj,val)
      % function obj = set.center(obj)
      %
      % Set the center of teh
      currCenter = obj.center;
      shiftVec = val - currCenter;
      crlEEG.disp(['Shifting by' num2str(shiftVec)]);
      obj.origin = obj.origin+shiftVec;
    end
    
    function box = get.boundingBox(obj)
      % function box = get.boundingBox(obj)
      %
      %
      box = getBoundingBox(obj);
    end;
    
    function obj = set.directions(obj,val)
      % function obj = set.directions(obj,val)
      %
      %
      if ndims(val)==2
        if size(val,2)==obj.dimension
          obj.directions = val;
        elseif obj.dimension==0
          % Hopefully just hitting this on load.
          obj.directions = val;
        else
          error('Directions matrix needs to be an 3 \times Ndims matrix');
        end
      else
        error('Directions matrix is not a matrix');
      end
    end
  end
  
end
