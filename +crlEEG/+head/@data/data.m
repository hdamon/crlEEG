classdef data < handle
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
    rootdirectory
    options
    images     
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
    OBJECT_VERSION = '1.0';
     
    % Definition for root options structure
    DEFAULT_OPTIONS = struct(...
      'segmentation', crlEEG.head.data.DEFAULT_SEGMENTATION_OPTIONS,...
      'conductivity', crlEEG.head.data.DEFAULT_CONDUCTIVITY_OPTIONS,...
      'subdir',       crlEEG.head.data.DEFAULT_SUBDIRECTORIES );

    % Default Directory Definitions
    DEFAULT_SUBDIRECTORIES = struct(...
      'data'   , 'sourceanalysis/data_for_sourceanalysis',...
      'models' , 'sourceanalysis/models'...
      );
    
    % Default Segmentation Options
    DEFAULT_SEGMENTATION_OPTIONS = struct(...
          'skullThickness', 4, ...
          'useSkinSeg'  , 'seg.skin',...
          'useSkullSeg' , 'seg.skull',...
          'useICCSeg'   , 'seg.ICC',...
          'useBrainSeg' , 'seg.brain.CRL', ...          
          'brainMap', crlEEG.head.data.DEFAULT_BRAIN_SEGMENTATION_LABEL_MAP,...
          'skullMap', crlEEG.head.data.DEFAULT_SKULL_SEGMENTATION_LABEL_MAP,...
          'outputImgField', 'seg.fullHead',...
          'outputImgFName', 'FullSegmentation.nrrd',...
          'outputImgFPath', './'...
          );
        
    % Default Conductivity Options
    DEFAULT_CONDUCTIVITY_OPTIONS = struct(...
          'CSFFraction'    , 0, ...          
          'useTensorImg'   , 'tensors.CRL',...
          'useAniso'       , true, ...
          'condMap'        , crlEEG.head.data.DEFAULT_CONDUCTIVITY_MAP,...            
          'outputCondField', 'conductivity',...
          'outputCondFName', 'AnisotropicConductivity.nrrd',...
          'outputCondFPath', './'...
          );      
                                          
    % Map from skull segmentation to tissue type
    DEFAULT_SKULL_SEGMENTATION_LABEL_MAP = struct(...
      'HardBone' , 1 , ...
      'SoftBone' , 2 , ...
      'Sinus'    , 3  ...
    );
        
    % Map from brain segmentation to tissue type
    DEFAULT_BRAIN_SEGMENTATION_LABEL_MAP = struct(...
      'Gray' , 4 , ...
      'White', 7 , ...
      'CSF'  , 5   ...
    );
    
    % Map from tissue type to output segmentation label and conductivity
    DEFAULT_CONDUCTIVITY_MAP = struct(...
      'Scalp',    struct('Label',1,'Conductivity',0.43) ,...
      'Bone',     struct('Label',2,'Conductivity',0.01) ,...      
      'Gray',     struct('Label',4,'Conductivity',0.33),...
      'CSF',      struct('Label',5,'Conductivity',1.79),...
      'Air',      struct('Label',6,'Conductivity',1e-6),...
      'White',    struct('Label',7,'Conductivity',0.142),...
      'HardBone', struct('Label',8,'Conductivity',0.0064),...
      'SoftBone', struct('Label',9,'Conductivity',0.02864),...
      'Sinus'   , struct('Label',10,'Conductivity',1e-6)...
    );
    
    % Used to configure the default file names that the head.data object
    % will look for. Note that the search function
    % (crlEEG.head.data.scanForDefaults) will also preferentially select
    % filenames with the suffix "_fixed", as it assumes these are manually
    % corrected versions of the files output by the crkit automated
    % pipeline.
    %
    % Format: 
    %  'FIELDNAME.SUBFIELD', 'NRRDTYPE', 'OPTIONS', {'DEFAULT1' 'DEFAULT2'}
    %
    % 
    DEFAULT_FILE_NAMES = {...
      'MRI.T1',          'nrrd',     [], { 'MRI_T1'              }; ...
      'MRI.T2',          'nrrd',     [], { 'MRI_T2'              }; ...
      'MRI.DTI',         'nrrd',     [], { 'tensors_crl'         }; ...
      'seg.brain.CRL',   'nrrd',     [], { 'seg_brain_crl'       }; ...
      'seg.brain.IBSR',  'nrrd',     [], { 'seg_brain_ibsr'      }; ...
      'seg.brain.NMM',   'nrrd',     [], { 'seg_brain_nmm'       }; ...
      'seg.brain.NVM',   'nrrd',     [], { 'seg_brain_nvm'       }; ...
      'seg.skin',        'nrrd',     [], { 'seg_skin_crl'        }; ...
      'seg.skull',       'nrrd',     [], { 'seg_skull_crl'       }; ...
      'seg.ICC',         'nrrd',     [], { 'seg_icc_crl'         }; ...
      'parcel.IBSR',   'parcel', 'IBSR', { 'parcel_ibsr_crl'     }; ...
      'parcel.NMM',    'parcel',  'NMM', { 'parcel_nmm_crl'      }; ...      
      'parcel.NVM',    'parcel',  'NVM', { 'parcel_nvm_crl'      }; ...
      'tensors.CRL',     'nrrd',     [], { 'tensors_cusp90_crl' 'tensors_dwi_crl' }; ...
      'surfNorm.CRL',    'nrrd',     [], { 'vec_CortOrient_crl'  };...
      'surfNorm.IBSR',   'nrrd',     [], { 'vec_CortOrient_ibsr' };...
      'surfNorm.NMM',    'nrrd',     [], { 'vec_CortOrient_nmm'  };...
      'surfNorm.NVM',    'nrrd',     [], { 'vec_CortOrient_nvm'  };...
      'cortConst.CRL',   'nrrd',     [], { 'vec_CortConst_CRL'   };...
      'cortConst.IBSR',  'nrrd',     [], { 'vec_CortConst_IBSR'  };...
      'cortConst.NMM',   'nrrd',     [], { 'vec_CortConst_NMM'   };...
      'cortConst.NVM',   'nrrd',     [], { 'vec_CortConst_NVM'   };...
      };
    
  end
  
  %% Public Methods
  methods
    
    %% Main Constructor
    function obj = data(varargin)
      % Object constructor
      if nargin>0        
        
        %% Return a copy of the input crlEEG.headData object
        if isa(varargin{1},'headData')
          crlEEG.disp('Just copying values over');
          obj.options = p.Results.headData.options;
          obj.images  = p.Results.headData.images;
          obj.modelName = p.Results.headData.modelName;
          crlEEG.disp('END CONSTRUCTOR');
          return;
        end
        
        %% Parse Inputs        
        p = inputParser;
        p.KeepUnmatched = true;
        addOptional(p,'dirSearch',[],@(x) exist(x,'dir'));
        addParamValue(p,'JSONLoad',[],@(x) exist(x,'file'));
        addParamValue(p,'structDef',[],@(x) isstruct(x));      
        parse(p,varargin{:});
        
        %% Set Default Options
        obj.options = obj.DEFAULT_OPTIONS;                                
        
        %% Assign values
        if ~isempty(p.Results.dirSearch)
          obj.rootdirectory = p.Results.dirSearch;          
          obj.scanForDefaults(fullfile(obj.rootdirectory,obj.options.subdir.data));
        elseif ~isempty(p.Results.JSONLoad)
          obj.loadFromJSON(p.Results.JSONLoad);
        elseif ~isempty(p.Results.structDef)
          obj.loadFromStruct(p.Results.structDef);
        end
                                 
      end;
      
      crlEEG.disp('END CONSTRUCTOR');
    end;
    
    %% Public Methods for Load/Save
    function loadFromStruct(obj,structDef)
      % Load a crlEEG.headData object from a structure definition
      %
      % function loadFromStruct(obj,structDef)
      
      obj.convert_StructToFiles(structDef.images);
      obj.options = structDef.options;
    end;

    function loadFromJSON(obj,fpath)
      % Load a crlEEG.headData object from a JSON definition
      %
      JSON = loadjson(fpath);
      if isfield(JSON,'headData')             
        obj.loadFromStruct(JSON.headData);        
      else
        error('Unable to locate headData structure in JSON object');
      end;
    end;
    
    function objStruct = struct(obj)
      objStruct.version   = obj.OBJECT_VERSION;
      objStruct.modelName = obj.modelName;
      objStruct.images    = obj.convert_FilesToStruct;
      objStruct.options   = obj.options;
    end
    
    function varargout = saveToJSON(obj,fpath)      
      % Save the headDa
      if ~exist('fpath','var'), fpath ='', end;
      json = savejson('headData',struct(obj),fpath);      
      varargout{1} = json;
    end;
    
    
    %% getImage()/setImage()
    %
    function out = getImage(obj,ref)
      % Fetch a value from the crlEEG.headData.images structure
      %
      % function out = getImage(obj,ref)
      %
      % ref : A string reference into the obj.images structure of the form 
      %         "FOO.BAR.BAZ.ImageName"
      %
      % Returns the image if it exists. If the image does not exist, it
      % returns an empty array rather than error. This allows isempty() to
      % be employed in testing for the existance of images, rather than
      % having to use isfield()
      %
      
      if isempty(ref), out = obj.images; return; end;
      
      % Strip leading period, if present
      if ref(1)=='.', ref = ref(2:end); end
      
      fields = strsplit(ref,'.');
      
      ref = @() getfield(obj,'images');
      for i = 1:numel(fields)
        ref = @() getfield(ref(),fields{i});
      end;
      
      try
        out = ref();
      catch
        %warning('Unable to locate requested image: Returning Empty Array');
        out = [];
      end                        
    end
    
    function setImage(obj,ref,img)            
      % Set a value in the crlEEG.headData.images structure
      %
      % function setImage(obj,ref,img)            
      %
      
      % Strip leading period, if present
      if ref(1)=='.', ref = ref(2:end); end
      
      fields = strsplit(ref,'.');
      switch numel(fields)
        case 1          
          obj.images.(fields{1}) = img;
        case 2
          obj.images.(fields{1}).(fields{2}) = img;
        case 3
          obj.images.(fields{1}).(fields{2}).(fields{3}) = img;
        otherwise
          error('crlEEG.headData.setImage only supports field indexing to a depth of 3');
      end
        
    end
    
    function out = isempty(obj)
      % function out = isempty(obj)
      %
      % Overloaded isempty() method for data objects.  Returns true if
      % obj.images is empty
      %
      out = isempty(obj.images);      
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


  end
  
  methods (Static=true)
    
    %nrrdCond = get_DTIConductivities(nrrdCond,nrrdSeg,nrrdDiffTensors,whitelabel,DSLevel);
    symOut = convert_DiffTensorToCondTensor(diffTensorVals,varargin);
        
    function obj = construct_FromRootDIR(varargin)
      
      obj = crlEEG.headData(varargin{:});            
      obj.build_AllHeadFiles;
      
      
    end
    
%     function nrrdList = nrrdList
%       % function nrrdList = nrrdList;
%       %
%       % Return a list of all crlEEG.headData properties that contain the
%       % string 'nrrd'. (IE: A list of all NRRDs stored within).
%       %
%       nrrdList = properties('crlEEG.headData');
%       keep = false(size(nrrdList));
%       for i = 1:length(nrrdList)
%         if (length(nrrdList{i})>4)&&(strcmpi(nrrdList{i}(1:4),'nrrd'))
%           keep(i) = true;
%         end;
%       end;
%       nrrdList = nrrdList(keep);
%     end
    
  end
  
  methods (Access=private)
    
    out = genModelName(obj);
    structOut = convert_FilesToStruct(obj);
    convert_StructToFiles(obj,struct);    
    
    
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