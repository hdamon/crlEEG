classdef headData < handle
  % Container Class for Input MRI Data in crlEEG
  %
  % The container class for a full set of data files from which a cnlModel
  % can be constructed.
  %
  % Additionally, uses the individual images to construct a full head
  % segmentation and associated anisotropic conductivity image.
  %
  % Options and Defaults:
  % nrrdT1       : file_NRRD Object to T1 Image
  % nrrdT2       : file_NRRD Object to T2 Image
  % nrrdDTI      : file_NRRD Object to Single Tensor Image
  % nrrdSkin     : NRRD file for skin segmentation
  % nrrdSkull    : NRRD file for skull segmentation
  % nrrdICC      : NRRD file for ICC segmentation
  % nrrdBrain    : Structure of NRRD files containing brain segmentation(s)
  % nrrdParcel   : Structure of NRRD Files containing brain parcellations
  % nrrdCSFFractions
  % nrrdSurfNorm : Structure of NRRD Files Containing Cortical Orientation
  %                   Information
  % nrrdPVSeg
  % isFrozen = false;
  %
  % The cnlEEG.headData object can be configured to look for a set of
  % default files, all located in a single directory
  %  
  % Written By: Damon Hyde
  % Last Edited: Nov 23, 2015
  % Part of the cnlEEG Project
  %
  
  properties
    
    % Segmentation Options
    skullThickness = 4; % Units are as used by the NRRD Files
    useBrainSeg = 'CRL';
    
    % Conductivity Options
    CSFFraction = 0;
    condMap
    useAniso = true;
    
    % Structures to Hold all the NRRDS
    MRI
    Vector
    Tensor
    Segmentation
    Parcellation
        
    % Flag to prevent files from being changed.
    isFrozen = false;
    
    % Raw MRI Data
    nrrdT1   = [];
    nrrdT2   = [];
    nrrdDTI  = [];
    
    % Stuff for building the model segmentation
    %  These can technically be computed from the above, but we store them
    %  separately since they're processed outside of matlab with the main CRL pipeline.
    nrrdSkin  = [];
    nrrdSkull = [];
    nrrdICC   = [];
    
    % Brain Segmentations Available from CRL Pipeline
    nrrdBrain;
    
    % Parcellations from CRL Pipeline
    nrrdParcel
    
    % iEEG/sEEG Electrode Maps
    nrrdIEEG
    
    % Other useful head data
    nrrdCSFFractions  = [];
    nrrdSurfNorm      = [];
    nrrdPVSeg         = [];
    
    %
    nrrdFullHead
    nrrdConductivity
    nrrdCorticalConstraints
  end
  
  properties (Dependent = true)
    modelName
  end;
  
  %% Protected Properties
  properties (Access=protected)
    storedModelName
  end;
  
  properties (Dependent = true, Access=protected)
    DEFAULT_MODELNAME
  end
  
  properties (Constant=true,Access=protected)
    DEFAULT_FNAME_SEGMENTATION = 'FullSegmentation.nrrd';
    DEFAULT_FNAME_CONDUCTIVITY = 'AnisotropicConductivity.nrrd';
    
    DEFAULT_CONDUCTIVITY_MAP = struct(...
      'Scalp',    struct('Label',1,'Conductivity',0.43) ,...
      'HardBone', struct('Label',2,'Conductivity',0.0064),...
      'SoftBone', struct('Label',3,'Conductivity',0.02864),...
      'Gray',     struct('Label',4,'Conductivity',0.33),...
      'CSF',      struct('Label',5,'Conductivity',1.79),...
      'Air',      struct('Label',6,'Conductivity',1e-6),...
      'White',    struct('Label',7,'Conductivity',0.142) );
    
    % Used to configure the default file names that the headData object
    % will look for.
    %
    % Format: 
    %  'FIELDNAME.SUBFIELD', 'NRRDTYPE', 'OPTIONS', {'DEFAULT1' 'DEFAULT2'}
    %
    % 
    DEFAULT_FILE_NAMES = {...
      'nrrdT1',          'nrrd',   [],    { 'MRI_T1'       }; ...
      'nrrdT2',          'nrrd',   [],    { 'MRI_T2'       }; ...
      'nrrdDTI',         'nrrd',   [],    { 'tensors_crl'  }; ...
      'nrrdBrain.CRL',   'nrrd',   [],    { 'seg_brain_crl'}; ...
      'nrrdBrain.IBSR',  'nrrd',   [],    { 'seg_brain_ibsr'}; ...
      'nrrdBrain.NMM',   'nrrd',   [],    {'seg_brain_nmm'}; ...
      'nrrdBrain.NVM',   'nrrd',   [],    {'seg_brain_nvm'}; ...
      'nrrdSkin',        'nrrd',   [],    {'seg_skin_crl_fixed' 'seg_skin_crl'}; ...
      'nrrdSkull',       'nrrd',   [],    {'seg_skull_crl'}; ...
      'nrrdICC',         'nrrd',   [],    {'seg_icc_crl'}; ...
      'nrrdParcel.IBSR', 'parcel', 'IBSR',{'parcel_ibsr_crl'}; ...
      'nrrdParcel.NMM',  'parcel', 'NMM', {'parcel_nmm_crl'}; ...      
      'nrrdParcel.NVM',  'parcel', 'NVM', {'parcel_nvm_crl'}; ...
      'nrrdSurfNorm.CRL',    'nrrd',   [],    {'vec_CortOrient_crl'};...
      'nrrdSurfNorm.IBSR',    'nrrd',  [],    {'vec_CortOrient_ibsr'};...
      'nrrdSurfNorm.NMM',    'nrrd',   [],    {'vec_CortOrient_nmm'};...
      'nrrdSurfNorm.NVM',    'nrrd',   [],    {'vec_CortOrient_nvm'}};
    
  end
  
  %% Public Methods
  methods
    function obj = headData(varargin)
      % Object constructor
      if nargin>0
        
        %% If the first input was itself a data object, just copy the
        %% values over and return the result
        if isa(varargin{1},'headData')
          crlEEG.disp('Just copying values over');
          tmp = properties('headData');
          for i = 1:length(tmp)
            obj.(tmp{i}) = p.Results.headData.(tmp{i});
          end
          crlEEG.disp('END CONSTRUCTOR');
          return;
        end
        
        %% Parse Inputs
        p = inputParser;
        p.KeepUnmatched = true;
        addOptional(p,'dirSearch',[],@(x) isa(x,'char'));
        
        % Add all nrrd* Properties as Parameter-Value Pairs
        nrrdList = crlEEG.headData.nrrdList;
        for i = 1:numel(nrrdList)
          addParamValue(p,nrrdList{i},[],@(x) isa(x,'crlEEG.file.NRRD')|isempty(x));
        end;
        parse(p,varargin{:});
        
        %% Assign values
        if isempty(p.Results.dirSearch)
          crlEEG.disp('Setting object properties');
          for i = 1:length(nrrdList)
            obj.(nrrdList{i}) = p.Results.(nrrdList{i});
          end
        else
          obj.scanForDefaults(p.Results.dirSearch);
        end
        
        obj.condMap = obj.DEFAULT_CONDUCTIVITY_MAP;
        
      end;
      
      crlEEG.disp('END CONSTRUCTOR');
    end;
    
    
    function out = isempty(obj)
      % function out = isempty(obj)
      %
      % Overloaded isempty() method for data objects.  Returns true
      % if all obj.nrrd* fields are empty.
      nrrdList = obj.nrrdList;
      out = true;
      for idx = 1:numel(nrrdList)
        if ~isempty(obj.(nrrdList{idx}))
          out = false;
        end;
      end
    end
    
    %% Get/Set Methods for Model Names
    function out = get.modelName(obj)
      % Returns the default name if an alternate has not been set.
      if isempty(obj.storedModelName)
        out = obj.DEFAULT_MODELNAME;
      else
        out = obj.storedModelName;
      end;
    end
    
    function set.modelName(obj,val)
      obj.storedModelName = val;
    end;
    
    function out = get.DEFAULT_MODELNAME(obj)
      out = obj.genModelName;
    end;
    
    
    scanForDefaults(obj,dir);
    
    function obj = purgeAll(obj)
      % function obj = purgeAll(obj)
      %
      % Purge data from all nrrds associated with the data object
      tmp = properties(obj);
      for i = 1:length(tmp)
        if strcmp(tmp{i}(1:4),'nrrd')
          if ~isempty(obj.(tmp{i}))
            obj.(tmp{i}).purgeData;
          end
        end
      end
    end
    
    %% Overloaded Set Properties For All NRRD Fields    
    function set.nrrdSkin(obj,val)
      obj.nrrdSkin = checkNRRD(obj,'nrrdSkin',val);
    end
    
    function set.nrrdSkull(obj,val)
      obj.nrrdSkull = checkNRRD(obj,'nrrdSkull',val);
    end
           
    function set.nrrdICC(obj,val)
      obj.nrrdICC = checkNRRD(obj,'nrrdICC',val);
    end
    
    function set.nrrdT1(obj,val)
      obj.nrrdT1 = checkNRRD(obj,'nrrdT1',val);
    end
    
    function set.nrrdT2(obj,val)
      obj.nrrdT2 =  checkNRRD(obj,'nrrdT2',val);
    end
    
    function set.nrrdDTI(obj,val)
      obj.nrrdDTI = checkNRRD(obj,'nrrdDiffTensors',val);
    end
    
    function set.nrrdCSFFractions(obj,val)
      obj.nrrdCSFFractions = checkNRRD(obj,'nrrdCSFFractions',val);
    end
    
%     function set.nrrdSurfNorm(obj,val)
%       obj.nrrdSurfNorm = checkNRRD(obj,'nrrdSurfNorm',val);
%     end
    
    function set.nrrdPVSeg(obj,val)
      obj.nrrdPVSeg =  checkNRRD(obj,'nrrdPVSeg',val);
    end
    
  end
  
  methods (Static=true)
    
    %nrrdCond = get_DTIConductivities(nrrdCond,nrrdSeg,nrrdDiffTensors,whitelabel,DSLevel);
    symOut = convert_DiffTensorToCondTensor(diffTensorVals,varargin);
        
    function nrrdList = nrrdList
      % function nrrdList = nrrdList;
      %
      % Return a list of all crlEEG.headData properties that contain the
      % string 'nrrd'. (IE: A list of all NRRDs stored within).
      %
      nrrdList = properties('crlEEG.headData');
      keep = false(size(nrrdList));
      for i = 1:length(nrrdList)
        if (length(nrrdList{i})>4)&&(strcmpi(nrrdList{i}(1:4),'nrrd'))
          keep(i) = true;
        end;
      end;
      nrrdList = nrrdList(keep);
    end
    
  end
  
  methods (Access=private)
    
    out = genModelName(obj);
    
    function val = checkNRRD(obj,field,val)
      % function setNRRD(obj,field,val)
      %
      % Helper function to do validity checking when setting NRRD fields.
      if ~obj.isFrozen
        if isa(val,'crlEEG.file.NRRD');
          if val.existsOnDisk
            crlEEG.disp([' Setting ' field ' to ' val.fname]);
          else
            warning(['NRRD file ' val.fname ' does not seem to exist on disk']);
          end;
        elseif isempty(val)
          crlEEG.disp(['Clearing ' field ]);
        else
          error('Invalid NRRD Object');
        end;
      else
        val = obj.(field);
        warning(['Can''t change obj.' field '.  The options have been frozen']);
      end;
    end
  end
  
end