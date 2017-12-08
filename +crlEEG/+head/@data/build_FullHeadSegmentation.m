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

crlEEG.disp('Building Combined Segmentation from cnlHeadData object.');

% Input Parsing
p = inputParser;
addRequired(p,'headData',@(x) isa(x,'crlEEG.head.data'));
addOptional(p,'fName','',@(x) ischar(x));
addOptional(p,'fPath','',@(x) ischar(x));
parse(p,headData,varargin{:});

fName = p.Results.fName;
fPath = p.Results.fPath;

if exist(fName,'dir'), fPath = fName; fName = ''; end;

%% Check if the Requested File Already Exists. Load and exit if it does.
test = exist(fullfile(fPath,fName),'file');
if test&&~(test==7) % Don't want directories
  crlEEG.disp('Loading Existing Full Head Segmentation Image');
  FullSegmentation = crlEEG.fileio.NRRD(fName,fPath);
  return;
end;

% Segmentation and conductivity options, for easier reference
segOpts = headData.options.segmentation;
condOpts = headData.options.conductivity;

%% Initialize with the Skin Segmentation
crlEEG.disp(['Cloning Skin Segmentation to Begin']);

skinFile = headData.getImage(segOpts.useSkinSeg);

crlEEG.disp(['Skin Segmentation: ' skinFile.fname]);
FullSegmentation = clone(skinFile,fName,fPath);
FullSegmentation.readOnly = false;
FullSegmentation.data(FullSegmentation.data>0) = condOpts.condMap.Scalp.Label;

%% Determine Skull Segmentation
skullFile = headData.getImage(segOpts.useSkullSeg);
ICCFile = headData.getImage(segOpts.useICCSeg);

if isempty(skullFile) && ~isempty(ICCFile) && segOpts.skullThickness>0
  % Use dilation of ICC when skull file is absent
  crlEEG.disp('Dilating ICC to obtain skull region');
  crlEEG.disp(['ICC File: ' ICCFile.fname]);
  crlEEG.disp(['Skull Thickness: ' num2str(segOpts.skullThickness)]);
  
  dilatedicc = dilate_ICC(ICCFile,segOpts.skullThickness);
  Q = (dilatedicc>0);
  FullSegmentation.data(Q) = condOpts.condMap.Bone.Label;
  
elseif ~isempty(skullFile)
  % A skull file is provided
  crlEEG.disp('Skull Segmentation Present');
  crlEEG.disp(['SkullSeg File : ' skullFile.fname]);
  
  % Build the skull
  if length(unique(skullFile.data(:)))==1
    crlEEG.disp(['Skull segmentation has only a single compartment']);
    % One compartment skull model
    Q = (skullFile.data>0);
    FullSegmentation.data(Q) = condOpts.condMap.Bone.Label;
  elseif length(unique(skullFile.data(:)))<=3    
    crlEEG.disp(['Skull segmentation has multiple compartments']);    
    fields = filenames(segOpts.skullMap);
    for i = 1:numel(fields)
      Q = skullFile.data==segOpts.skullMap.(fields(i));
      FullSegmentation.data(Q) = condOpts.condMap.(fields(i)).Label;
    end
    
  else
    error('Not sure what to do with this skull segmentation. Too many segments in it');
  end
  
else
  warning('No Skull Segmentation Present');
end;

%% Take the ICC and fill it with CSF

if ~isempty(ICCFile)
  crlEEG.disp(['ICC Present: Filling with CSF']);
  crlEEG.disp(['ICC File: ' ICCFile.fname]);
  Qicc = ICCFile.data>0;
  FullSegmentation.data(Qicc) = condOpts.condMap.CSF.Label;
  ICCFile.data = [] ; % No need to keep the image around
end


%% Determine Internal Brain Segmentation
crlEEG.disp('Incorporating Internal Brain Structure');
brainFile = headData.getImage(segOpts.useBrainSeg);

assert(~isempty(brainFile),'Requested brain segmentation is empty');

% Mask w/ the ICC image
Qbrain = (brainFile.data>0);
if ~isempty(Qicc), Qbrain = Qbrain&Qicc; end;

fields = fieldnames(segOpts.brainMap);
for i = 1:numel(fields)
  Qvalid = ( brainFile.data ==segOpts.brainMap.(fields{i}) );
  FullSegmentation.data(Qbrain&Qvalid) = condOpts.condMap.(fields{i}).Label;
end

crlEEG.disp('%%%% Completed Building Combined Segmentation');
end


function [dilatedicc] = dilate_ICC(icc,skullThickness)
tic
crlEEG.disp('Computing Dilation of ICC Segmentation');
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
crlEEG.disp(['Completed Image Dilation in ' num2str(toc) ' seconds']);

end
