classdef cnlParcelSolutionSpace < cnlSolutionSpace
  
  % classdef cnlParcelSolutionSpace < cnlSolutionSpace
  %  
  % cnlParcelSolutionSpace is used to define a solution space based on
  % parcels.
  %
  % This class primarily acts to provide a mapping between the parcels
  % identified in nrrdParcel, and the basis vectors used to compute the
  % inverse solution.  These basis vectors can be constructed in one of
  % several ways, as defined by the obj.type property.
  %
  % Constructor Syntax: 
  %   obj = cnlParcelSolutionSpace(nrrdParcel,type,LeadField,nVec,normalized)
  %
  %   type      : 'group'  : Just cluster all voxels in each parcel
  %               'lfield' : Cluster voxels in each parcel, and create nVec
  %                          basis functions for each parcel, as the first 
  %                          nVec right singular vectors of the SVD from 
  %                          the appropriate submatrix of LeadField.
  %               'graph'  : Construct basis functions on each parcel using
  %                          the first nVecs eigenvectors of the local
  %                          connectivity graph.
  %   normalized: Flag to normalize the columns of the sub-LeadField before
  %                 taking the SVD.
  %   LeadField : Leadfield to use for construction of bases
  %                 (Must be provided if type='lfield')
  %   nVec      : Number of singular vectors per parcel (Default = 3)
  %
  % Properties:
  %   Inherited:  sizes       < cnlSolutionSpace < cnlGridSpace < cnlGrid
  %               dimension   < cnlSolutionSpace < cnlGridSpace < cnlGrid
  %               origin      < cnlSolutionSpace < cnlGridSpace
  %               directions  < cnlSolutionSpace < cnlGridSpace
  %               description < cnlSolutionSpace
  %               Voxels      < cnlSolutionSpace
  %         New:  nrrdParcel
  %               type
  %               nVecs
  %               normalized
  %               removeMean
  %
  % Written By: Damon Hyde
  % Last Modified: June 9, 2015
  % Part of the cnlEEG Project
  %
  
  properties
    nrrdParcel
    type       = 'group';
    normalized = false;
    removeMean = false;
    nVecs 
  end
  
  properties (Dependent = true)
    nParcel
  end
          
  properties (Hidden = true)
    overcomplete
    maxNVecs = 5;
    storeMat % Deprecated, but included for backwards compatibility.
  end
  
  methods
    function obj = cnlParcelSolutionSpace(nrrdParcel,varargin)
      % function obj = cnlParcelSolutionSpace(nrrdParcel,type,LeadField,nVec)
      %
      %
      
      obj = obj@cnlSolutionSpace;
      
      if nargin>0
        
        if ~isa(nrrdParcel,'cnlParcellation')
          error(['First input to cnlParcelSolutionSpace needs to be a ' ...
            'cnlParcellation object containing the parcellation']);
        end
        
        p = inputParser;
        p.addOptional('type','group',@(x)isa(x,'char'));
        p.addParameter('LeadField',[],@(x)isa(x,'cnlLeadField'));
        p.addParameter('nVec',1);
        p.addParameter('normalized',false);
        p.addParameter('removeMean',false);
        p.addParameter('nrrdVec',[]);
        
        p.parse(varargin{:});
                    
        % Set cnlSolutionSpace attributes
        obj.sizes      = nrrdParcel.sizes;
        obj.origin     = nrrdParcel.spaceorigin;
        obj.directions = nrrdParcel.spacedirections;
        obj.Voxels = find(nrrdParcel.data);
        
        % Set cnlParcelSolutionSpace attributes
        obj.nrrdParcel = nrrdParcel;
        obj.type = p.Results.type;
        obj.nVecs = p.Results.nVec;
        if obj.nVecs>obj.maxNVecs, obj.maxNVecs = obj.nVecs; end;        
        obj.normalized = p.Results.normalized;
        obj.removeMean = p.Results.removeMean;       
                       
        % Build and store the grid to parcellation mapping matrix
        obj.overcomplete = getMatGridToSolSpace(obj,p.Results);  
        obj.matStored = obj.getFinalMat;
      end;
    end
    
    function out = get.nParcel(obj)
      if ~isempty(obj.nrrdParcel)
        out = obj.nrrdParcel.nParcel;
      end
    end
    
    function matOut = getFinalMat(obj)
      % function matOut = getFinalMat(obj)
      %
      % Given a precomputed obj.overcomplete matrix, extracts the number of
      % basis functions per parcel requested in obj.nVecs, up to the
      % maximum of obj.maxNVecs
      %

      if strcmpi(obj.type,'group')
        matOut = obj.overcomplete;
      else
      
        nParcel = obj.nrrdParcel.nParcel;
        maxNVecs = obj.maxNVecs;
        
        if obj.nVecs>obj.maxNVecs
          error('Object not configured to supply that many vectors per parcel');
        end
        
        offsets = 0:maxNVecs:maxNVecs*(nParcel-1);
        offsets = repmat(offsets(:),1,obj.nVecs);
        ref = repmat([1:(obj.nVecs)],nParcel,1);
        
        ref = ref + offsets;
        ref = ref';

        matOut = obj.overcomplete(ref(:),:);

      end;
    end
        
    function isEqual = eq(a,b)
      assert(isa(a,'cnlParcelSolutionSpace')&&isa(b,'cnlParcelSolutionSpace'),...
         'Both inputs must be cnlParcelSolutionSpace objects');
       
      isEqual = false;
      if eq@cnlSolutionSpace(a,b)
        isEqual = true;
        if isequal(a.overcomplete,b.overcomplete)
          isEqual = true;
        end;
      end
    end
    
    % Methods with their own m-files
    inGrid = getMatGridToSolSpace(spaceIn,type,LeadField,nVecs);
    [row col] = get_RefsForSparseMatrix(spaceIn); 
  end;
  
  
  methods (Static=true)
    function out = loadobj(obj)

      out = obj;

      if isstruct(obj)
        warning('Loaded cnlParcelSolutionSpace object as a struct.  Something seems wrong');
        keyboard;
      end;
      
      % Backwards compatibility with older cnlParcelSolutionSpaces
      if isfield(obj,'storeMat')|isprop(obj,'storeMat')
        if ~isempty(obj.storeMat)&&isempty(obj.matStored)
        warning(['Loading an older cnlParcelSolutionSpace object. ' ...
                  'This is compatible for now, but may not remain so']);
        out.matStored = obj.storeMat;
        end;
      end

    end
    
        
        
    
  end
  
end

