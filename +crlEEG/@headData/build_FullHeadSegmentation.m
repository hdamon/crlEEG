function [FullSegmentation] = build_FullHeadSegmentation(headData,varargin) %options,modelDIR)
% function [fullSegmentation] =
%                  BUILD_FULLHEADSEGMENTATION(dirs,files,options)
%
% Function to combine multiple segmentations (Skin, ICC, Brain) into a
% single fully segmented head.  Currently uses a dilated intercranial
% cavity in place of an actual skull segmentation. All files are assumed to
% match in number of elements and spatial directions.
%
% Written By: Damon Hyde
% Part of the cnlEEG Project
% 2008-2016
%

mydisp('Building Combined Segmentation from cnlHeadData object.');

% Input Parsing
p = inputParser;
addRequired(p,'headData',@(x) isa(x,'crlEEG.headData'));
addOptional(p,'fName',[],@(x) ischar(x));
addOptional(p,'fPath',[],@(x) ischar(x));
parse(p,headData,varargin{:});

fName = p.Results.fName;
fPath = p.Results.fPath;

if exist(fName,'dir'), fPath = fName; fName = []; end;

%% Check if the Requested File Already Exists. Load and exit if it does.
test = exist(fullfile(fPath,fName),'file');
if test&&~(test==7) % Don't want directories
  mydisp('Loading Existing Full Head Segmentation Image');
  FullSegmentation = file_NRRD(fName,fPath);
  return;
end;

%% Initialize with the Skin Segmentation
mydisp(['Cloning Skin Segmentation to Begin']);
mydisp(['Skin Segmentation: ' headData.nrrdSkin.fname]);
FullSegmentation = clone(headData.nrrdSkin,fName,fPath);
FullSegmentation.readOnly = false;
FullSegmentation.data(FullSegmentation.data>0) = headData.condMap.Scalp.Label;

%% Determine Skull Segmentation
if isempty(headData.nrrdSkull)&&~isempty(headData.nrrdICC)&&(headData.skullThickness>0)
  mydisp('Dilating ICC to obtain skull region');
  mydisp(['ICC File: ' headData.nrrdICC.fname]);
  mydisp(['Skull Thickness: ' num2str(headData.skullThickness)]);
  
  dilatedicc = dilate_ICC(headData.nrrdICC,headData.skullThickness);
  Q = (dilatedicc>0);
  FullSegmentation.data(Q) = headData.condMap.HardBone.Label;
  
elseif ~isempty(headData.nrrdSkull)
  mydisp('Skull Segmentation Present');
  mydisp(['SkullSeg File : ' headData.nrrdSkull.fname]);
  
  % Build the skull
  if length(unique(headData.nrrdSkull.data(:)))==1
    mydisp(['Skull segmentation has only a single compartment']);
    % One compartment skull model
    Q = (headData.nrrdSkull.data>0);
    FullSegmentation.data(Q) = headData.condMap.HardBone.Label;
  elseif length(unique(headData.nrrdSkull.data(:)))==2
    mydisp(['Skull segmentation has two compartments']);
    % Two compartment skull model
    Q = (headData.nrrdSkull.data==1);
    FullSegmentation.data(Q) = headData.condMap.HardBone.Label; % Hard Bone
    Q = (headData.nrrdSkull.data==2);
    FullSegmentation.data(Q) = headData.condMap.SoftBone.Label; % Soft Bone
  else
    error('Not sure what to do with this skull segmentation. Too many segments in it');
  end
  
else
  warning('No Skull Segmentation Present');
end;

%% Take the ICC and fill it with CSF
if ~isempty(headData.nrrdICC)
  mydisp(['ICC Present: Filling with CSF']);
  mydisp(['ICC File: ' headData.nrrdICC.fname]);
  Qicc = headData.nrrdICC.data>0;
  FullSegmentation.data(Qicc) = headData.condMap.CSF.Label;
  headData.nrrdICC.data = [] ; % No need to keep the image around
end


%% Determine Internal Brain Segmentation
mydisp('Incorporating Internal Brain Structure');
brainNRRD = headData.nrrdBrain.(upper(headData.useBrainSeg));

% switch lower(headData.useBrainSeg)
%   case 'crl',  brainNRRD = headData.nrrdBrain.CRL;
%   case 'nmm',  brainNRRD = headData.nrrdBrain.NMM;
%   case 'nvm',  brainNRRD = headData.nrrdBrain.NVM;
%   case 'isbr', brainNRRD = headData.nrrdBrain.IBSR;
% end

assert(~isempty(brainNRRD),'Requested brain segmentation is empty');

Qbrain = (brainNRRD.data>0);
if ~isempty(Qicc), Qbrain = Qbrain&Qicc; end;
FullSegmentation.data(Qbrain) = brainNRRD.data(Qbrain);

%   %% Add iEEG Electrodes
%   if strcmpi(p.Results.type,'ieeg')
%     mydisp('Adding iEEG Electrodes into Segmentation');
%     %FullSegmentation.fname = 'nrrdFullSegmentation_iEEG.nhdr';
%     for i = 1:numel(headData.nrrdIEEG)
%       tmp = headData.nrrdIEEG(i).buildCondMap;
%       Q = find(tmp);
%       FullSegmentation.data(Q) = tmp(Q);
%     end;
%   end

%   %% Downsample Segmentation if Necessary
%   if any(dwnSmpLvl_Seg>1)
%     mydisp('Downsampling Segmentation');
%     FullSegmentation.DownSample(dwnSmpLvl_Seg,'segmentation');% = nrrdDownsample(nrrdFullSegmentation,options.modelDownSampleLevel);
%   end;
%   FullSegmentation.write;




mydisp('%%%% Completed Building Combined Segmentation');
end


function [dilatedicc] = dilate_ICC(icc,skullThickness)
tic
mydisp('Computing Dilation of ICC Segmentation');
aspect = icc.aspect;
filterSize = ceil(skullThickness./aspect);
filterSizeFull = 2*filterSize +1;

dilationFilter = zeros(filterSizeFull(1),filterSizeFull(2),filterSizeFull(3));

fX = (-filterSize(1):filterSize(1))*aspect(1);
fY = (-filterSize(2):filterSize(2))*aspect(2);
fZ = (-filterSize(3):filterSize(3))*aspect(3);
[fX fY fZ] = ndgrid(fX,fY,fZ);

dilationFilter = strel(sqrt(fX.^2 + fY.^2 + fZ.^2)<skullThickness);

dilatedicc = imdilate(icc.data,dilationFilter);
mydisp(['Completed Image Dilation in ' num2str(toc) ' seconds']);

end
