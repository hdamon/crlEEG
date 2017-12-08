classdef finiteDifference
  % Class for constructing Finite Difference Bioelectric Models
  %
  % This object class constructs finite difference models from 3D maps of
  % conductivity, as described in <CITATION>
  %
  % To construct a finite difference model, execute a call as:
  %    FDModel = crlEEG.head.model.EEG.finiteDifference(nrrdCond)
  %  
  % Where nrrdCond is a crlEEG.fileio.NRRD of symmetric conductivity tensors.
  %
  % The constructor can also be called without any arguments, but nrrdCond
  % will need to be set before much else can be done.  
  %
  % Setting the Conductivity Map
  % ----------------------------
  %   The first thing to do is to set the conductivity map that will be
  %   used for model construction. Most methods will simply error out until
  %   this has been completed.
  %
  %   This can be done as part of the initial constructor call by providing
  %   a tensor volume object as the first parameter:
  %     FDModel = crlEEG.head.model.EEG.finiteDifference(nrrdCond)
  %
  %   Or by setting the 
  %
  % Adding Electrodes 
  % -----------------
  %   Electrodes are added to the model as crlEEG.head.model.EEG.electrode
  %   objects.
  %
  %   This can be done during the initial constructor call:
  %    FDModel =
  %    crlEEG.head.model.EEG.finiteDifference(nrrdCond,'electrodes',electrodeObj)
  %
  %   Or by calling the addElectrodes method:
  %    obj = obj.addElectrodes(electrodeObj);
  %
  %   Duplicate electrodes will only be added once, and electrodes using
  %   the complete electrode model or otherwise occupying physical space
  %   (ie: electrode.voxels field is not empty) can not be added after the
  %   model has been configured.
  %
  % Completing the Configuration
  % ----------------------------
  %   Once the conductivity map and electrodes have been assigned, the
  %   model needs to be configured prior to constructing the system matrix.
  %   This is done by calling:
  %
  %   obj = obj.configure;
  %
  %   Running this method also sets the obj.isConfigured flag to true. Once
  %   configured, the model will no longer allow changes to the electrodes
  %   without changing that flag back to false (which will subsequently
  %   require rerunning the configuration method again).
  %
  % Building the FD Matrix
  % ----------------------
  %   
  %   
  %
  % AFTER THE MODEL IS BUILT:
  % -------------------------
  %
  % Once the model is fully constructed, there are several things you can
  % do with it. See the help files for each individual method for more
  % detailed usage instructions.
  %
  % Compute an Induced Voltage Field
  % --------------------------------
  %
  % Compute the Gradient of an Induced Voltage Field
  % ------------------------------------------------
  %
  % Build a LeadField Matrix
  % ------------------------
  %  Probably the most common use. 
  %
  %  lField = obj.compute_LeadField(elecIdx,gndIdx,baseSolSpace,varargin)
  %
  % 
  %
  %
  %
  % Properties:
  %   fname : File name where finite difference matrix is stored
  %   fpath : Path where the matrix file is stored
  %   nrrdCond : crlEEG.fileio.NRRD of conductivity tensors from which the finite
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
  %   crlEEG.fileio.NRRD
  
  %%
  properties  
    % NRRD object with the spatial map of conductivity tensors.
    %  NOTE: This will eventually be changed to use a new internal datatype
    %           for arbitrary volumetric images, which will make it easier
    %           to incorporate data from image types other than just .NRRDs
    nrrdCond                
  end
  
  properties (GetAccess=public,SetAccess=protected)   
    nrrdCondModified
    matFDM        % The finite difference system matrix
    electrodes    % An array of crlEEG.head.model.EEG.electrode objects
  end
  
  properties
    % Filename and path to save the system matrix to
    fname = 'FDModel.mat';
    fpath = './';
    
    % Convergence Properties
    tol          = 1e-6;
    maxIt        = 2500;
    spaceScaling = 1e-3;
    
    % Flags to ensure the model is properly constructed before certain
    % methods are called.
    isConfigured = false;
    isBuilt      = false;      
    
  end
  
  properties (Hidden=true)          
    idxRow_Electrode % Individual row in the model associated with each electrode
  end
  
  properties (Dependent=true) 
    imgSize
    aspect
    voxInside
    nElectrodes    
  end
   
  %%
  methods
    
    function obj = finiteDifference(nrrdCond,varargin)
                  
      if nargin>0
        % Check if we were handed a finiteDifference
        if isa(nrrdCond,'crlEEG.head.model.EEG.finiteDifference')
          crlEEG.disp('Passed finiteDifference to constructor.  Returning passed model');
          obj = nrrdCond;
          return;                  
        end
                       
        % Primary property is the conductivity NRRD
        assert(isa(nrrdCond,'crlEEG.fileio.NRRD'),...
                  'Input must be a crlEEG.fileio.NRRD object');
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
      %   1) Must be a crlEEG.fileio.nrrdCond object
      %   2) Its first dimension must be of length 6
      %   3) Its first dimension must be of kind "3D-symmetric-matrix"
      %   4) It must have three spatial dimensions:
      %           sum(nrrdCond.domainDims==3)
      %
                 
      if ~isempty(nrrdCond) % Only test if we're not clearing it.
        assert(nrrdCond.isTensor,'obj.nrrdCond value must be a tensor nrrd');
      end;
      
      % Assignment. Save a copy of the original input.
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
        % Clearing the value
        if isempty(val) 
          obj.matFDM = []; 
          obj.isBuilt = false;
          crlEEG.disp('Cleared matFDM field');
          return; 
        end;
        
        % Assertions
        assert(ismatrix(val)&&(size(val,1)==size(val,2)),...
                'matFDM should be a square matrix');
        assert(isequal(size(val,1),obj.getModelSize('noelec'))||...
               isequal(size(val,1),obj.getModelSize('full')),...
                'matFDM does not match the expected size');
              
        obj.matFDM = val;        
      else
        error('obj.nrrdCond needs to be set before setting obj.matFDM');
      end;
    end
    
    %% Dependent Get Methods
    function out = get.imgSize(obj)
      % Returns the size of the current conductivity image
      if isempty(obj.nrrdCond), out = []; return; end;
      out = obj.nrrdCond.sizes(obj.nrrdCond.domainDims);
    end

    function sizeOut = getModelSize(obj,opt)      
      % Returns the size of the model. This is larger then the image size
      % because the model places the computational nodes at the corners of
      % each physical voxel, and electrodes using the complete electrode
      % model add additional rows/columns of boundary conditions.
                  
        % Base # of rows in a FD model
        baseRows = prod(obj.imgSize+[1 1 1]);
        
        numComplete = 0;
        for i = 1:numel(obj.electrodes)
          if isequal(obj.electrodes(i).model,'completeModel')
            numComplete = numComplete + 1;
          end;
        end;      
        
        if ~exist('opt','var'),opt = 'full'; end;
        switch opt
          case 'noelec'
            sizeOut = baseRows;
          case 'full'
            sizeOut = baseRows + numComplete;
          case 'otherwise'
            error('Unknown size requested')
        end
    end;    
    
    function out = get.voxInside(obj)
      % Returns a list of all the non-zero voxels in the volume
      if isempty(obj.nrrdCond), out = []; return; end;
      out = obj.nrrdCond.nonZeroVoxels;
    end
    
    function out = get.aspect(obj)
      % Returns the physical aspect ratio of the model
      if isempty(obj.nrrdCond), out = []; return; end;
      out = obj.nrrdCond.aspect;
    end;
    
    function out = get.nElectrodes(obj)
      % Returns the number of electrodes in the model
      out = numel(obj.electrodes);
    end;
                
    %% Main Build Methods    
     
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
        assert(~isempty(obj.nrrdCond),...
                  'finiteDifference.nrrdCond must be defined before calling the build function');
                                        
        % Build from scratch
        if ~isempty(obj.nrrdCond)          
          crlEEG.disp('Computing Finite Difference Matrix');          
          %tmpCond = clone(obj.nrrdCond,'FDModel_Cond.nrrd',obj.fpath);
          
          % Update Conductivity to Include Electrodes Using Complete Model
          obj = obj.modifyConductivityMap;          
          
          % Construct the Stiffness Matrix
          matFDM = obj.buildAnisoMat(obj.nrrdCond,obj.spaceScaling); 
          
          % Save the matrix and conductivity
          save([obj.fpath obj.fname],'matFDM','-v7.3');
          obj.nrrdCond.write;
        else
          error('finiteDifference.nrrdCond must be defined before calling the build function');
        end;
      end
      
      % Add auxilliary nodes to incorporate electrode boundary conditions      
      obj.matFDM = obj.addElectrodesToFDMMatrix(matFDM); 
      obj.isBuilt = true;
    end
       
   
    
    function [matFDM,success] = tryLoad(obj)
      % function [matFDM,success] = tryLoad(obj) 
      %
      % Try to load the obj.matFDM from [obj.fpath obj.fname].  If
      % successful, return success=true and the matrix stored in matFDM.
      % Otherwise, return an empty matrix in matFDM and success=FALSE
      
      if exist(fullfile(obj.fpath, obj.fname),'file')
        crlEEG.disp('Successfully found existing FD Model File');
        load(fullfile(obj.fpath, obj.fname));
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
  
  %% Public Static Methods
  methods (Static=true)
    function obj = loadobj(S)
      crlEEG.disp('Loading FDModel Object');
      obj = crlEEG.head.model.EEG.finiteDifference;
      obj = reload(obj,S);
    end
    
    [anisoNodes] = convert_NodesIsoToAniso(IsoNodes,isoImgSize);    
  end
  
  %% Private Methods
  methods (Access=private)
     %%
     function obj = modifyConductivityMap(obj)
      % Update the conductivity map to include the conductivities in each
      % model that will be using the complete electrode model. Point
      % electrodes leave the conductivities unchanged.
      %
      
      % Create a copy of the original provided conductivity map
      obj.nrrdCondModified = clone(obj.nrrdCond);
      obj.nrrdCondModified.fname = 'nrrdCond_FDMModified.nrrd';
      obj.nrrdCondModified.encoding = 'gzip';
      
      % Add Electrodes
      for i = 1:numel(obj.electrodes)
        switch obj.electrodes(i).model
          case 'pointModel'
            continue;
          case 'completeModel'
            obj.nrrdCondModified.data(obj.electrodes(i).voxels) = ...
              obj.electrodes(i).conductivities;
          otherwise
            error('Unknown electrode type');
        end
      end
     end
     
     %%
     function matFDM = addElectrodesToFDMMatrix(obj,matFDM)
       
       [row,col,val] = find(matFDM);
       
       nNodes = obj.getModelSize('noelec');
       nElec = numel(obj.electrodes);
       offset = 0;
       % List of rows used to access the electrode
       %
       % This is a cell array because while point and complete electrode
       % models use
       obj.idxRow_Electrode = cell(1,numel(obj.electrodes));
       
       for i = 1:numel(obj.electrodes)
         switch (obj.electrodes(i).model)
           case 'pointModel'
             % Use the node list from the electrode
             obj.idxRow_Electrode{i} = obj.electrodes(i).nodes;
           case 'completeModel'
             %
             offset = offset+1;
             eNodes = obj.electrodes(i).nodes;
             
             % Index of new row/column
             newRow = nNodes + offset;
             newCol = newRow;
             
             obj.idxRow_Electrode{i} = newRow;
             
             newVals = -1./(obj.electrodes(i).impedance*ones(numel(eNodes),1));
             
             % New Row
             row = [row ; newRow*ones(numel(eNodes),1)];
             col = [col ; eNodes(:)];
             val = [val ; newVals];
             
             % New Column
             row = [row ; eNodes(:)];
             col = [col ; newCol*ones(numel(eNodes),1)];
             val = [val ; newVals];
             
             % Value on Diagonal
             row = [row ; newRow];
             col = [col ; newCol];
             val = [val ; -sum(newVals)];
             
           otherwise
             error('Unknown electrode model');
         end
       end
       
       % Build Modified System Matrix
       matFDM = sparse(row,col,val,...
                         obj.getModelSize('full'),obj.getModelSize('full'));
       
     end
    
    %%
    function currents = getCurrents(FDModel,AnodeIdx,totalAnodeCurrent,CathodeIdx,totalCathodeCurrent)
      % Construct matrix of input currents between one or more pairs of
      % electrodes
      %
      %
      
      if ~FDModel.isBuilt 
        error('finiteDifference model must be built before constructing currents'); 
      end;
      
      assert(isscalar(totalAnodeCurrent)||...
              isequal(size(AnodeIdx),size(totalAnodeCurrent)),...
              ['totalAnodeCurrent must either be a scalar, or a vector ' ...
              'with a size matching AnodeIdx']);
            
      assert(isscalar(totalCathodeCurrent)||...
              isequal(size(CathodeIdx),size(totalCathodeCurrent)),...
              ['totalCathodeCurrent must either be a scalar, or a vector ' ...
              'with a size matching CathodeIdx']);            
            
      assert(isscalar(AnodeIdx)||isscalar(CathodeIdx)||...
                isequal(size(AnodeIdx),size(CathodeIdx)),...
                ['Either the size of AnodeIdx and CathodeIdx must match, ' ...
                 'or one must be a scalar']);
            
      if isscalar(AnodeIdx)
        AnodeIdx = AnodeIdx*ones(size(CathodeIdx));
      end
      
      if isscalar(totalAnodeCurrent)
        totalAnodeCurrent = totalAnodeCurrent*ones(size(AnodeIdx));
      end;
      
      if isscalar(CathodeIdx)
        CathodeIdx = CathodeIdx*ones(size(AnodeIdx));
      end;
      
      if isscalar(totalCathodeCurrent)
        totalCathodeCurrent = totalCathodeCurrent*ones(size(CathodeIdx));
      end;
      
      currents = sparse(FDModel.getModelSize,numel(AnodeIdx),numel(AnodeIdx)*2);
      
      for i = 1:numel(AnodeIdx)
        anodeCurrent = zeros(FDModel.getModelSize,1);
        cathodeCurrent = zeros(FDModel.getModelSize,1);
        
        anodeRows = FDModel.idxRow_Electrode{AnodeIdx(i)};
        cathodeRows = FDModel.idxRow_Electrode{CathodeIdx(i)};
        
        anodeCurrent(anodeRows) = totalAnodeCurrent(i)/numel(anodeRows);
        cathodeCurrent(cathodeRows) = totalCathodeCurrent(i)/numel(cathodeRows);
        
        currents(:,i) = sparse(anodeCurrent + cathodeCurrent);
      end;
    end
  end
  
  %% Private Static Methods
  methods (Static=true,Access=private)
    %% Static method to build the system matrix
    matOut = buildAnisoMat(nrrdIn,spaceScale);              
  end
  

  
end
