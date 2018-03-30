classdef adaptableOnSpace < crlEEG.type.matrix.adaptable
  
  % function obj = adaptableOnSpace(matrix,solSpace,colPerVox)
  %
  % Inputs:
  %   matrix      :
  %   solSpace    : cnlSolutionSpace the matrix is defined on
  %   colPerVox   : Number of matrix columns per voxel
  %   isCollapsed : For matrices with colPerVox>1, flag to determine whether
  %                   or not to collapse those columns into a single column
  %                   per voxel.
  %   collapseMat : Matrix to execute the collapse of origmatrix
  %
  % Basic class for all linear operators defined on a cnlSolutionSpace.  That
  % is, some subset of points in a 3D space.  This is the parent class for
  % all linear spatial regularization matrices, as well as all leadfields.
  % The class implements overloaded ctranspose and mtimes operators, and
  % includes functionality for transforming from one cnlSolutionSpace to
  % another compatible one.  It also supports having multiple matrix columns
  % per spatial voxel, and handles collapsing this down to a single column
  % per voxel, if desired.
  %
  % Properties:
  %   Inherited:  origMatrix     < crlEEG.type.matrix.adaptable
  %               currMatrix     < crlEEG.type.matrix.adaptable
  %               isTransposed   < crlEEG.type.matrix.adaptable
  %               needsRebuild   < crlEEG.type.matrix.adaptable
  %   New:        origSolutionSpace
  %               currSolutionSpace
  %               colPerVox
  %               isCollapsed
  %               matCollapse 
  % 
  % Written By: Damon Hyde
  % Last Edited: Aug 17, 2015
  % Part of the cnlEEG Project
  %
  
  properties (GetAccess=public, SetAccess=protected);
    origSolutionSpace;
    colPerVox = 1;
  end
  
  properties
    currSolutionSpace;
    
    % Stuff to enable multiple columns per voxel.  Primarily important for
    % leadfields.
    isCollapsed = false;
    matCollapse = [];
  end
  
  properties (Hidden=true)    
    disableRebuild = false;
  end
  
  properties (Hidden=true, Dependent=true)
    stillLoading; %% Deprecated
    canCollapse;
  end;
  
  methods
    function obj = adaptableOnSpace(matrix,solSpace,colPerVox)
      % function obj = adaptableOnSpace(matrix,solSpace,colPerVox)
      %
      % Constructor function for adaptableOnSpace class.
      %
      % Inputs:
      %   matrix    :  The original matrix, defined on solSpace
      %   solSpace  :  A cnlSolutionSpace object
      %   colPerVox : (optional) Define the number of columns per voxel in
      %                 the matrix. Primarily for leadfields.
      
      obj = obj@crlEEG.type.matrix.adaptable;
      
      if nargin>0
        if ~(isnumeric(matrix)&&exist('solSpace','var')&&isa(solSpace,'cnlSolutionSpace'))
          error(['adaptableOnSpace can be called in exactly one way, to ' ...
            'make sure that things run properly.  Please check the ' ...
            'documentation for proper syntax']);
        end
        
        if ~exist('colPerVox','var'), colPerVox = 1; end;
        
        if size(matrix,2)~=solSpace.nVoxels*colPerVox;
          error(['Input matrix is not of the correct size']);
        end;
        
        obj.origMatrix = matrix;
        obj.origSolutionSpace = solSpace;
        obj.colPerVox = colPerVox;
        obj.currSolutionSpace = solSpace;        
      end;
    end;
    
    function obj = set.disableRebuild(obj,val)
      % If we set this to true, rebuild the matrix.
      obj.disableRebuild = val;
      if ~obj.disableRebuild
        obj = obj.rebuildCurrMatrix;
      end
    end
    
    function obj = set.currSolutionSpace(obj,newSolSpace)
      % function obj = set.currSolutionSpace(obj,newSolSpace)
      %
      % Set currSolutionSpace, after first doing a compatibility check.
      % Then rebuild the matrix if the stillLoading flag is unset.
      %
      assert(isa(newSolSpace,'cnlSolutionSpace'),...
                'newSolSpace must be a cnlSolutionSpace object');
      
      if ~isequal(obj.currSolutionSpace,newSolSpace)      
       obj.currSolutionSpace = newSolSpace;  
       obj = obj.rebuildCurrMatrix;
      end;
    end;
    
    function obj = set.stillLoading(obj,val)
      % Legacy support for obj.stillLoading. Deprecated Feb 2016
      warning('adaptableOnSpace.stillLoading is deprecated. Use obj.disableRebuild instead');
      obj.disableRebuild = val;
    end;
    
    function out = get.stillLoading(obj)
      % Legacy support for obj.stillLoading. Deprecated Feb 2016.
      warning('adaptableOnSpace.stillLoading is deprecated. Use obj.disableRebuild instead');
      out = obj.disableRebuild;
    end;                      
    
    function obj = set.isCollapsed(obj,val)
      % function obj = set.isCollapsed(obj,val)
      %
      %
      if ~islogical(val), error('Input value must be a logical'); end;
      
      % Don't recompute if we aren't changing something.
      if obj.isCollapsed==val, return; end;
      
      obj.isCollapsed = val;
      obj = obj.rebuildCurrMatrix;
    end
    
    function out = get.canCollapse(obj)
      % function out = get.canCollapse(obj)
      %
      % Dependant property get function.  True if obj.matCollapse is not
      % empty, false if it is.
      %
      if ~isempty(obj.matCollapse), out = true;
      else out = false; end;
    end
    
    
    
    function obj = set.matCollapse(obj,matCollapse)
      % function obj = set.matCollapse(obj,matCollapse)
      %
      %
      if ~isempty(matCollapse)
        matSize = size(matCollapse);
        if (matSize(1)~=size(obj.origMatrix,2))| ...
            (matSize(2)~=size(obj.origMatrix,2)/obj.colPerVox)
          % this might end up being an issue with saving/loading ^^^
          error('Incorrect dimensionality for matCollapse');
        end;
        
        obj.matCollapse = matCollapse;
      else % We just want to clear it.
        obj.matCollapse = [];
      end;
    end
           
    function S = saveobj(obj)
      S = obj.getStruct;      
    end
    
    function S = getStruct(obj)
      S.origMatrix = obj.origMatrix;
      S.origSolutionSpace = obj.origSolutionSpace;
      S.colPerVox = obj.colPerVox;
      S.currSolutionSpace = obj.currSolutionSpace;
      S.matCollapse = obj.matCollapse;
      S.isCollapsed = obj.isCollapsed;
      S.isTransposed = obj.isTransposed;
    end
    
    function obj = loadFromStruct(obj,S)      
      obj.origMatrix = S.origMatrix;
      obj.origSolutionSpace = S.origSolutionSpace;
      obj.colPerVox = S.colPerVox;      
      obj.currSolutionSpace = S.currSolutionSpace;      
      obj.matCollapse = S.matCollapse;
      obj.isCollapsed = S.isCollapsed;
      obj.isTransposed = S.isTransposed;
    end;
    
    % Methods with their own m-files.
    obj = rebuildCurrMatrix(obj);
  end
  
  %% Static Methods
  methods (Static = true)
    
    function obj = loadobj(S)
      obj = adaptableOnSpace;      % Initialize Empty Object
      obj.disableRebuild = true;     % Keep it from rebuilding repeatedly
      obj = loadFromStruct(obj,S);         % Load properties
      obj.disableRebuild = false;    % Reenable rebuilding of currMatrix
      %obj = obj.rebuildCurrMatrix; % Rebuild currMatrix
    end
  end
  
end