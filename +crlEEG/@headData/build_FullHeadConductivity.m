function [nrrdAnisoCond] = build_FullHeadConductivity(headData,varargin)
% Construct a map of conductivity tensors from a crlEEG.headData object.
%
% function [nrrdAnisoCond] = BUILD_CONDUCTIVITY(nrrdSeg,condObj)
%
% crlEEG.headData method to construct a map of conductivity tensors.
%
% headData is a crlEEG.headData object, and must have a full head
% sementation constructed before calling this method. This can be manually
% assigned, or constructed using headData.build_FullHeadSegmentation
%
% build_FullHeadConductivity supports two optional inputs to assign the
% name and path for the NRRD file that is outputs. This can be called in
% any of the following ways:
%
% headData.build_FullHeadConductivity(fname,fpath);
% headData.build_FullHeadConductivity(fname);
% headData.build_FullHeadConductivity(fpath);
%
% If fname is not provided, a random temporary file name will be assigned.
% If fpath is not provided, the file will be set to a random temporary
%                             directory.
%
% Written By: Damon Hyde
% Part of the crlEEG Project
% 2009-2017
%

% Input Parsing
p = inputParser;
addRequired(p,'headData',@(x) isa(x,'crlEEG.headData'));
addOptional(p,'fName',[],@(x) ischar(x));
addOptional(p,'fPath',[],@(x) ischar(x));
parse(p,headData,varargin{:});

fName = p.Results.fName;
fPath = p.Results.fPath;

if exist(fName,'dir'), fPath = fName; fName = []; end;

% Make sure we have a head segmentation.
assert(~isempty(headData.nrrdFullHead),...
  'Full Head Segmentation Must Be Constructed Before Constructing Conductivity Image');

% % Input Parsing
% p = inputParser;
% addRequired(p,'nrrdSeg',   @(x) isa(x,'crlEEG.file.NRRD'));
% addOptional(p,'nrrdDTI',[],@(x) isa(x,'crlEEG.file.NRRD')||iscell(x)||isempty(x));
% addParamValue(p,'useDTIData',false, @islogical);
% addParamValue(p,'usePVSulci',false, @islogical);
% addParamValue(p,'useAniso',true, @islogical);
% addParamValue(p,'dir_Model','./', @(x) exist(x,'dir'));
% addParamValue(p,'fName_IsoNRRD',    'IsotropicConductivity.nhdr');
% addParamValue(p,'fName_AnisoNRRD','AnisotropicConductivity.nhdr');
% addParamValue(p,'map_labeltoconductivity',[]);
% addParamValue(p,'force_CondRebuild',false);
% addParamValue(p,'segDwnSample',[]);
% addParamValue(p,'whitelabel',7);
%
% parse(p,nrrdSeg,varargin{:});
%
% nrrdSeg         = p.Results.nrrdSeg;
% nrrdDTI         = p.Results.nrrdDTI;
% useDTIData      = p.Results.useDTIData;
% usePVSulci      = p.Results.usePVSulci;
% useAniso        = p.Results.useAniso;
% dir_Model       = p.Results.dir_Model;
% fName_IsoNRRD   = p.Results.fName_IsoNRRD;
% fName_AnisoNRRD = p.Results.fName_AnisoNRRD;
% force_Rebuild   = p.Results.force_CondRebuild;
% segDwnSample    = p.Results.segDwnSample;
%
% map_labeltoconductivity = headData.map_labeltoconductivity;

%% Get the Conductivity Image
test = exist(fullfile(fPath,fName),'file');
if test&&(test~=7)
  %% If it's already been writtin out, just load it.
  mydisp('Loading Existing Anisotropic Conductivity');
  nrrdAnisoCond = crlEEG.file.NRRD(fName,fPath);
  return;
end;

%% Get the conductivity map as a vector
f = fields(headData.condMap);
map_labeltoconductivity = [0];
for i = 1:numel(f)
  nextLabel = headData.condMap.(f{i}).Label+1;
  nextCond  = headData.condMap.(f{i}).Conductivity;
  assert( (nextLabel>numel(map_labeltoconductivity))||...
    (map_labeltoconductivity(nextLabel)~=0),...
    'Duplicate Labels in Conductivity Map!');
  map_labeltoconductivity(nextLabel) = nextCond;
end

%% Construct Isotropic Conductivity Tensors from the Segmentation
mydisp('Building Anisotropic Conductivity')
nrrdAnisoCond               = clone(headData.nrrdFullHead,fName,fPath);
nrrdAnisoCond.content       = 'AnisotropicConductivity';
nrrdAnisoCond.type          = 'float';
nrrdAnisoCond.kinds         = { '3D-symmetric-matrix' nrrdAnisoCond.kinds{:} };
nrrdAnisoCond.sizes         = [6 headData.nrrdFullHead.sizes];
nrrdAnisoCond.dimension     = 4;
nrrdAnisoCond.data          = zeros([6 headData.nrrdFullHead.sizes]);
nrrdAnisoCond.data(1,:,:,:) = map_labeltoconductivity(headData.nrrdFullHead.data+1);
nrrdAnisoCond.data(4,:,:,:) = map_labeltoconductivity(headData.nrrdFullHead.data+1);
nrrdAnisoCond.data(6,:,:,:) = map_labeltoconductivity(headData.nrrdFullHead.data+1);

%% Replace White Matter Conductivities w/ Those Computed from DTI
if ~isempty(headData.nrrdDTI)
  nrrdAnisoCond = get_DTIConductivities(nrrdAnisoCond,...
    headData.nrrdFullHead,headData.nrrdDTI,headData.condMap.White.Label);
end;

%% Partial Volume Fractions Within Sulci Regions
if false ; %usePVSulci
  error('Partial Volume Sulci not yet fully implemented');
  condObj = cnlModel.getPVSulci(condObj);
end;

%% Select the correct conductivity image for the model being constructed
% (The isotropic model is all but totally extinct now)
if headData.useAniso
  nrrdCond = nrrdAnisoCond;
else
  nrrdCond = nrrdIsoCond;
end;

end



function nrrdCond = get_DTIConductivities(nrrdCond,nrrdSeg,nrrdDiffTensors,whitelabel)
% GETDTICONDUCTIVITIES
%
% function getDTIConductivities(nrrdCond,nrrdSeg,nrrdDiffTensors,whitelabel,DSLevel)
%
% Inputs:
%    nrrdCond : crlEEG.file.NRRD of anisotropic conductivity image
%    nrrdSeg  : crlEEG.file.NRRD of segmentation image
%    nrrdDiffTensors : crlEEG.file.NRRD of diffusion tensors.
%
% Optional Inputs:
%    whitelabel : Labels of voxels to assign anisotropic conductivities
%           `       (DEFAULT: 7)
%
% Outputs:
%    nrrdCond : updated crlEEG.file.NRRD with anisotropic conductivities
%
% Written By: Damon Hyde
% Last Edited: Feb 4, 2016
% Part of the cnlEEG Project
%

mydisp('Using Anisotropic Conductivities From Diffusion Imaging');

%% Input Parsing
p = inputParser;
p.addRequired('nrrdCond',@(x) isa(x,'crlEEG.file.NRRD')&&strcmpi(x.kinds{1},'3D-symmetric-matrix'));
p.addRequired('nrrdSeg' ,@(x) isa(x,'crlEEG.file.NRRD')&&all(x.sizes==nrrdCond.sizes(2:end)));
p.addRequired('nrrdDiffTensors',@(x) ...
  (isa(x,'crlEEG.file.NRRD') && validateSingleTensor(x,nrrdCond))||...
  (         iscell(x) &&  validateMultiTensor(x,nrrdCond))     );
p.addOptional('whitelabel',7,   @(x) isnumeric(x));
parse(p,nrrdCond,nrrdSeg,nrrdDiffTensors,whitelabel);
DSLevel = [1 1 1];


% Are we using a multi-Tensor image
multiTensor = iscell(nrrdDiffTensors);

% Read/Reshape Tensor Data for easier access
if multiTensor
  mydisp('Using Multi-Tensor Model');
  nTensor = numel(nrrdDiffTensors);
  
  % Get the weighting for each of the compartments
  tensorWeights = nrrdDiffTensors{1}.data;
  tensorWeights = reshape(tensorWeights,nTensor,[]);
  
  % Get Tensor Data for Each Compartment
  for idx = 2:nTensor
    tensorData{idx-1} = reshape(nrrdDiffTensors{idx}.data,6,[]);
  end
  
  % Build a set of tensors for the isotropic component of the DCI image.
  % This assumes that the isotropic conductivity is equivalent to CSF.
  % Should probably be made selectable.
  tmpTensor = 0.00238*[1 0 0 1 0 1]';
  tensorData{end+1} = repmat(tmpTensor,1,prod(nrrdDiffTensors{idx}.sizes(2:end)));
  
else
  
  mydisp('Using Single Tensor Model');
  nTensor = 1;
  tensorWeights = ones(1,prod(nrrdDiffTensors.sizes(2:end)));
  tensorData{1} = reshape(nrrdDiffTensors.data,[6 prod(nrrdDiffTensors.sizes(2:end))]);
  nrrdDiffTensors = {nrrdDiffTensors};
end;

%% Computation
voxels_WhiteMatter = find(ismember(nrrdSeg.data,whitelabel));

mydisp('Computing Conductivity Tensors');

[refX, refY, refZ] = ind2sub(nrrdSeg.sizes,voxels_WhiteMatter);

% If we've downsampled, index into Tensor image isn't the same
refX2 = ceil(refX/DSLevel(1));
refY2 = ceil(refY/DSLevel(2));
refZ2 = ceil(refZ/DSLevel(3));

idxTensor = sub2ind(nrrdDiffTensors{1}.sizes(2:4),refX2,refY2,refZ2);

dataOut = nrrdCond.data;

for i = 1:length(voxels_WhiteMatter)
  % Periodic output
  if mod(i,100000)==0
    mydisp(['Completed ' num2str(i) ' of ' num2str(length(voxels_WhiteMatter)) ' tensors.']);
  end
  
  meanTensor = zeros(6,1);
  for idx = 1:nTensor
    tmpTensor = crlEEG.headData.convert_DiffTensorToCondTensor(tensorData{idx}(:,idxTensor(i)));
    meanTensor = meanTensor + tensorWeights(idx,idxTensor(i))*tmpTensor;
  end;
  
  % If the tensor is non-zero, insert it into the image.
  if any(meanTensor)
    dataOut(:,refX(i),refY(i),refZ(i)) = meanTensor;
  end;
end

nrrdCond.data = dataOut;

end

function isValid = validateSingleTensor(nrrdIn,nrrdCond)
% Does it claim to be a tensor?
isValid = strcmpi(nrrdIn.kinds{1},'3D-symmetric-matrix');
% Does the size match the conductivity image?
isValid = isValid&&all(nrrdIn.sizes==nrrdCond.sizes);
end

function isValid = validateMultiTensor(nrrdIn,nrrdCond)
% Are the number of weights equal to the number of tensors
isValid = nrrdIn{1}.sizes(1)==(numel(nrrdIn));
% Does the size match the conductivity image
isValid = isValid && all(nrrdIn{1}.sizes(2:end)==nrrdCond.sizes(2:end));
% Are all the other images tensors
for idx = 2:numel(nrrdIn)
  isValid = isValid && strcmpi(nrrdIn{idx}.kinds{1},'3D-symmetric-matrix');
end

end

%nrrdCond.data(:,refX(i),refY(i),refZ(i))

