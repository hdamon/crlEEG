classdef solutionSpace < crlEEG.type.gridInSpace
% Object class for grid-type solution spaces
%
% classdef solutionSpace < crlEEG.type.gridInSpace
%
% The crlEEG.type.solutionSpace object is used to combine a description of
% a voxelized space as a crlEEG.type.gridInSpace object, with a list of
% voxels indexed into that space at which at solution should be defined.
%
% Constructor Syntax:
%   obj = solutionSpace(spaceDef,Voxels,desc);
%          spaceDef :  Either a crlEEG.type.gridInSpace, or a file_NRRD to identify a
%                        grid space from.
%          Voxels   :  List of voxels for the solutionSpace to be defined
%                        at.
%          desc     :  Text description of the solution space
%
% Properties:
%   Inherited:  sizes       <  crlEEG.type.gridInSpace < cnlGrid
%               dimension   <  crlEEG.type.gridInSpace < cnlGrid
%               origin      <  crlEEG.type.gridInSpace
%               directions  <  crlEEG.type.gridInSpace
%   New:    description
%           Voxels
    
  properties
    % Inherited:    
    % sizes
    % dimension
    % origin    
    % directions
    description
    Voxels    
  end
  
  properties (Dependent=true)
    nVoxels
    matGridToSolSpace
  end;
  
  properties (Hidden=true)
    matGridToSolSpace_
  end
  
  methods
    
    function obj = solutionSpace(spaceDef,Voxels,desc)
      %
      % function obj = solutionSpace(spaceDef,Voxels,desc)
      %
      % solutionSpace constructor.
      %   Inputs:  spaceDef:  either a crlEEG.type.gridInSpace, or a file_NRRD to
      %                         identify a grid space from.
      %            Voxels:    List of voxels for the solutionspace to be
      %                         defined at.  Defaults to 1:prod(obj.sizes)
      %            desc:      Text description of the solution space
      %
      %
      
      obj = obj@crlEEG.type.gridInSpace;
      
      if nargin>0
        gridSpace = solutionSpace.parseSpaceDef(spaceDef);
        
        obj.sizes = gridSpace.sizes;
        obj.origin = gridSpace.origin;
        obj.directions = gridSpace.directions;
        
        % Parse and check voxel list
        if exist('Voxels','var')
          if (max(Voxels)>prod(obj.sizes))||(min(Voxels)<1)
            error('Trying to use solution points outside the volume');
          else
            [Voxels order] = sort(Voxels);
            if any((order(1:end-1)-order(2:end))>0)
              error('Voxel list must be sorted in ascending order');
            else
              obj.Voxels = Voxels;
            end;
          end
        else
          obj.Voxels = 1:prod(obj.sizes);
        end;
        
        if exist('desc','var')
          obj.description = desc;
        end;
        
        obj.matGridToSolSpace_ = getMatGridToSolSpace(obj);
        
      end;
    end;
    
    function inGrid = get.matGridToSolSpace(spaceIn)
      % function inGrid = get.matGridToSolSpace(spaceIn)
      %
      %
      if isempty(spaceIn.matGridToSolSpace_)
        inGrid = getMatGridToSolSpace(spaceIn);
      else
        inGrid = spaceIn.matGridToSolSpace_;
      end
    end
    
    function inGrid = getMatGridToSolSpace(spaceIn)
      % function inGrid = getMatGridToSolSpace(spaceIn)
      %
      %
      inGrid = speye(prod(spaceIn.sizes));
      inGrid = inGrid(spaceIn.Voxels,:);
    end
    
      
    function out = getSolutionGrid(obj)
      % function out = getSolutionGrid(obj)
      %
      %
      warning('Deprecated functionality carried over from previous object oriented code.  Use solutionSpace.getGridPoints instead')      
      keyboard;
      out = obj.getGridPoints;
    end
   
    function out = SpaceSize(obj,idx)
      % function out = SpaceSize(obj,idx)
      %
      %
      warning('Deprecated. Space size now stored in solutionSpace.sizes');
      keyboard;
      if exist('idx','var')
        out = obj.sizes(idx)
      else
        out = obj.sizes;
      end;
    end;
    
    function out = get.nVoxels(obj)
      % function out = get.nVoxels(obj)
      %
      out = length(obj.Voxels);
    end
    
%     function matOut = getNvalMapping(spaceIn,spaceOut,nVal)
%       if ~exist('nVal'), nVal = 3; end;
%       matOut = getMapGridToGrid(spaceIn,spaceOut);
%       matOut = kron(matOut,speye(nVal));
%     end
    
    matOut = getMapping(spaceIn,spaceOut);
    
    function isEqual = eq(a,b)
      assert(isa(a,'solutionSpace')&&isa(b,'solutionSpace'),...
        'Both inputs must be solutionSpace objects');
      
      isEqual = false;
      if eq@crlEEG.type.gridInSpace(a,b)
        if isequal(a.Voxels,b.Voxels)
          isEqual = true;
        end;
      end
      
    end
    
  end
  
  
  methods (Static=true, Access=private)
    
    function gridSpace = parseSpaceDef(spaceDef)
      % function gridSpace = parseSpaceDef(spaceDef)
      %
      if isa(spaceDef,'crlEEG.type.gridInSpace')
        gridSpace = crlEEG.type.gridInSpace(spaceDef);
      elseif isa(spaceDef,'file_NRRD')     
        gridSpace = spaceDef.gridSpace;
        %gridSpace = crlEEG.type.gridInSpace(spaceDef.sizes(spaceDef.domainDims), ...
        %                         spaceDef.spaceorigin,spaceDef.spacedirections);  
      elseif isa(spaceDef,'crlEEG.fileio.NRRD')
        gridSpace = spaceDef.gridSpace;
      else
        error(['Not sure how to extract space information from a ' class(spaceDef) ' object.  Use a crlEEG.type.gridInSpace or file_NRRD object instead']);        
      end
    end
            
  end
  
%   methods (Static = true)
%     function out = loadobj(obj)
%       % function out = loadobj(obj)
%       %
%       if isstruct(obj)
%         disp('Loading solutionSpace as a structure');
%         spaceDef = crlEEG.type.gridInSpace(obj.sizes,obj.origin,obj.directions);
%         solutionSpace = solutionSpace(spaceDef,obj.Voxels,obj.description);
%         solutionSpace.idxBy = obj.idxBy;
%         out = solutionSpace;
%       else
%         disp('Loading solutionSpace as an object');
%         out = obj;        
%       end;
%     end
%   end;
  
end