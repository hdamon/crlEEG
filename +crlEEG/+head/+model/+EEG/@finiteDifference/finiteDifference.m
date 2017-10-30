classdef finiteDifference
  % Class for constructing Finite Difference Bioelectric Models
  %
  % This object class constructs finite difference models from 3D maps of
  % conductivity, as described in <CITATION>
  %
  % To construct a finite difference model, execute a call as:
  %    FDModel = crlEEG.head.model.EEG.finiteDifference(nrrdCond)
  %
  % The constructor can also be called without any arguments, but nrrdCond
  % will need to be set before much else can be done.
  %
  % Where nrrdCond is a file_NRRD of symmetric conductivity tensors.
  %
  % Properties:
  %   fname : File name where finite difference matrix is stored
  %   fpath : Path where the matrix file is stored
  %   nrrdCond : file_NRRD of conductivity tensors from which the finite
  %                 difference model is constructed
  %   matFDM   : The finite difference matrix itself.  This is a transient
  %                 property that is only stored on disk and not stored 
  %                 with the matlab object when it is saved to a .mat file.
  %   tol      : Target tolerance when solving the FDM problem
  %               DEFAULT: 1e-6
  %   maxIt    : Maximum number of MINRES iterations when solving
  %               DEFAULT: 2500
  %
  % Note that this object will ALWAYS load from a preexisting file if it is
  % available at the designated location.  If you want to rebuild the
  % finite difference matrix file, either point it to a different location,
  % or delete the existing file.
  %
  % Object dependencies:
  % 
  % Requires:
  %   crlEEG.file.NRRD
  
  
  properties
    fname  = 'FDModel.mat';
    fpath  = './';
    
    nrrdCond              
  end
  
  properties (GetAccess=public,SetAccess=protected)    
    matFDM
    electrodes
  end
  
  properties (Hidden=true)
    % Convergence Properties
    tol          = 1e-6;
    maxIt        = 2500;
    spaceScaling = 1e-3;
    
    isBuilt = false;        
  end
  
  properties (Dependent=true) 
    imgSize
    aspect
    voxInside
    nElectrodes
    modelSize
  end
   
  methods
    
    function obj = finiteDifference(nrrdCond,varargin)
                  
      if nargin>0
        % Check if we were handed a finiteDifference
        if isa(nrrdCond,'crlEEG.head.model.EEG.finiteDifference')
          mydisp('Passed finiteDifference to constructor.  Returning passed model');
          obj = nrrdCond;
          return;                  
        end
                       
        % Primary property is the conductivity NRRD
        assert(isa(nrrdCond,'crlEEG.file.NRRD'),...
                  'Input must be a crlEEG.file.NRRD object');
        obj.nrrdCond = nrrdCond;                        
      end;
      
      % Parse Varargin                 
      p = inputParser;
      p.addParamValue('fname','FDmodel.mat');
      p.addParamValue('fpath','./');
      p.addParamValue('spacescaling',1e-3);
      p.addParamValue('electrodes',[]);
      p.addParamValue('tol',1e-6);
      p.addParamValue('maxit',2500);      
      p.parse(varargin{:});
      
      % Set defaults from the inputParser
      obj.fname        = p.Results.fname;
      obj.fpath        = p.Results.fpath;
      obj.spaceScaling = p.Results.spacescaling;
      obj.electrodes   = p.Results.electrodes;
      obj.tol          = p.Results.tol;
      obj.maxIt        = p.Results.maxit;      
    end
    
    %% Non-dependent Set Methods
    function obj = set.nrrdCond(obj,nrrdCond)
      % function obj = set.nrrdCond(obj,val)
      %
      % crlEEG.head.model.EEG.finiteDifference.nrrdCond:
      %   1) Must be a crlEEG.file.nrrdCond object
      %   2) Its first dimension must be of length 6
      %   3) Its first dimension must be of kind "3D-symmetric-matrix"
      %   4) It must have three spatial dimensions:
      %           sum(nrrdCond.domainDims==3)
      %
                 
      if ~isempty(nrrdCond) % Only test if we're not clearing it.
        assert(obj.validateTensorNRRD(nrrdCond);
      end;
      
      % Assignment
      obj.nrrdCond = clone(nrrdCond,'internalFDCond.nrrd');
            
    end
    
    function obj = set.matFDM(obj,val)
      % function obj = set.matFDM(obj,val)
      %
      % Before setting obj.matFDM, ensures that obj.nrrdCond is defined,
      % and that the size of matFDM matches the size of nrrdCond
      %
      % This method is likely unneeded, as matFDM has private setaccess,
      % and should only be assiged from obj.build()
      if ~isempty(obj.nrrdCond)
        imgSize = obj.nrrdCond.sizes(obj.nrrdCond.domainDims);
        
        % Test Conditions
        matchImgSize = prod(imgSize+[1 1 1])==size(val,1);
        matchImgSizePlus = ...
                  ( prod(imgSize+[1 1 1]) + obj.nElectrodes )==size(val,1);
        
        isPEM = ismatrix(val)&&matchImgSize;
        isCEM = ismatrix(val)&&matchImgSizePlus;
        
        isValid = isPEM||isCEM;
        
        if (isValid)
          obj.matFDM = val;
        elseif isempty(val)
          mydisp('Clearing matFDM field');
          obj.matFDM = [];    
        else
          error('Unknown error');
        end
      else
        error('obj.nrrdCond needs to be set before setting obj.matFDM');
      end;
    end
    
    %% Dependent Get Methods
    function out = get.imgSize(obj)
      if isempty(obj.nrrdCond), out = []; return; end;
      out = obj.nrrdCond.sizes(obj.nrrdCond.domainDims);
    end
    
    function out = get.voxInside(obj)
      if isempty(obj.nrrdCond), out = []; return; end;
      out = obj.nrrdCond.nonZeroVoxels;
    end
    
    function out = get.aspect(obj)
      if isempty(obj.nrrdCond), out = []; return; end;
      out = obj.nrrdCond.aspect;
    end;
    
    function out = get.nElectrodes(obj)
      out = numel(obj.electrodes);
    end;
    
    function out = get.modelSize(obj)
      if isempty(obj.nrrdCond), out = []; return; end;
      out = obj.nrrdCond.sizes = [1 1 1];
    end;
        
    %% Main Build Method    
    function obj = build(obj)
      % function obj = build(obj)
      %
      % finiteDifference method to construct the actual finite difference matrix.
      %
      % Requires that nrrdCond be set or this will throw an error.
      %
      % If [obj.fpath obj.fname] exists, build() will load the finite
      % difference matrix from the .mat file.
            
      [matFDM,loaded] = tryLoad(obj);
      
      if ~loaded            
        % Build from scratch
        if ~isempty(obj.nrrdCond)          
          crlEEG.disp('Computing Finite Difference Matrix');
          tmpCond = clone(obj.nrrdCond,'FDModel_Cond.nrrd',obj.fpath);
          obj.nrrdCond = obj.elecModel.modifyConductivity(obj.electrodes,tmpCond);          
          
          matFDM = obj.buildAnisoMat(obj.nrrdCond,obj.spaceScaling);         
          save([obj.fpath obj.fname],'matFDM','-v7.3');
          obj.nrrdCond.write;
        else
          error('finiteDifference.nrrdCond must be defined before calling the build function');
        end;
      end
      
      % Add auxilliary nodes to incorporate electrode boundary conditions
      obj.matFDM = obj.elecModel.modifyFDMatrix(obj.electrodes,matFDM);            
    end
       
    function currents = getCurrents(FDModel,AnodeIdx,CathodeIdx)
      currents = FDModel.elecModel.getCurrents(...
        FDModel.electrodes,FDModel.imgSize+[1 1 1],AnodeIdx,CathodeIdx);
    end
    
    function [matFDM,success] = tryLoad(obj)
      % function [matFDM,success] = tryLoad(obj) 
      %
      % Try to load the obj.matFDM from [obj.fpath obj.fname].  If
      % successful, return success=true and the matrix stored in matFDM.
      % Otherwise, return an empty matrix in matFDM and success=FALSE
      
      if exist([obj.fpath obj.fname],'file')
        mydisp('Successfully found existing FD Model File');
        load([obj.fpath obj.fname]);
        success = true;
      else
        matFDM = [];
        success = false;
      end;
      
    end
    
    function S = saveobj(obj)
      S.fname      = obj.fname;
      S.fpath      = obj.fpath;
      S.nrrdCond   = obj.nrrdCond;   
      S.tol        = obj.tol;
      S.maxIt      = obj.maxIt;
      S.imgSize    = obj.imgSize;
      S.voxInside  = obj.voxInside;
      S.aspect     = obj.aspect;
      S.electrodes = obj.electrodes;
      S.elecModel  = obj.elecModel;
      
      % Make sure the FD Matrix File Exists
      if ~exist(fullfile(obj.fpath,obj.fname),'file')
        save(fullfile(obj.fpath,obj.fname),obj.matFDM);
      end;
    end
    
    function obj = reload(obj,S)
      obj.fname      = S.fname;
      obj.fpath      = S.fpath;
      obj.nrrdCond   = S.nrrdCond;
      obj.tol        = S.tol;
      obj.maxIt      = S.maxIt;
      obj.imgSize    = S.imgSize;
      obj.voxInside  = S.voxInside;
      obj.aspect     = S.aspect;
      obj.electrodes = S.electrodes;
      obj.elecModel  = S.elecModel;
      
      [matFDM,loaded] = tryLoad(obj);      
      if loaded
        obj.matFDM = obj.elecModel.modifyFDMatrix(obj.electrodes,matFDM);
      end;
    end
    
  end
  
  methods (Static=true,Access=private)
    matOut = buildAnisoMat(nrrdIn,spaceScale);    
    
    function isTensorNRRD = validateTensorNRRD(nrrdCond)
      % Returns true if nrrdCond is a tensor NRRD
      %
      % Otherwise, returns an error
      %
      
        % Tests
        isNRRD   = isa(nrrdCond,'file_NRRD');
        isTensor = (nrrdCond.sizes(1)==6) && ...
          (strcmpi(nrrdCond.kinds{1},'3D-symmetric-matrix'));
        is3D     = sum(nrrdCond.domainDims)==3;
                        
        % Assertions
        assert(isNRRD,'Input nrrdCond must be a file_NRRD object');
        assert(isTensor,'Input nrrdCond must be a map of conductivity tensors');
        assert(is3D,'Input nrrdCond must have three spatial dimensions');
        
        % nrrdCond is valid if we reach here.
        isTensorNRRD = true;
    end
    
    
  end
  
  methods (Static=true)
    function obj = loadobj(S)
      mydisp('Loading FDModel Object');
      obj = crlEEG.head.model.EEG.finiteDifference;
      obj = reload(obj,S);
    end
    
    [anisoNodes] = convert_NodesIsoToAniso(IsoNodes,isoImgSize);
    
    Potentials = solveForPotentials_Static(FDModel,Currents_In);
    gradOut = solveForGradient_Static(FDModel,Currents_In);
  end
  
end
