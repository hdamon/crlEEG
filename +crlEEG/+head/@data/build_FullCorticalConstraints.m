function [varargout] = build_FullCorticalConstraints(headData,surfNormImg,varargin)
% BUILD_FULLCORTICALCONSTRAINTS
%
% function [nrrdCortConst] = BUILD_FULLCORTICALCONSTRAINTS(headData,fName,fPath)
%
% Given a cnlHeadData object whose obj.nrrdCortConst field is not empty,
% returns a new file_NRRD object with cortical orientation vectors
% interpolated to fill all available white matter and CSF spaces.
%
% If no filename is provided, the returned NRRD will have a random
% filename generated with tempname()
%
% Written By: Damon Hyde
% Part of the cnlEEG Project
% 2009-2016
%


%% Input Parsing
p = inputParser;
addRequired(p,'headData',@(x) isa(x,'crlEEG.headData'));
addRequired(p,'surfNormImg',@(x) isa(x,'crlEEG.file.NRRD'));
addOptional(p,'fName','',@(x) ischar(x));
addOptional(p,'fPath','',@(x) ischar(x));
parse(p,headData,surfNormImg,varargin{:});

fName = p.Results.fName;
fPath = p.Results.fPath;

if exist(fName,'dir'), fPath = fName; fName = ''; end;

%% If the file already exists on disk, just load it.
test = exist(fullfile(fPath,fName),'file');
if test && (test~=7)
  crlEEG.disp('Loading Existing Cortical Constraints');
  nrrdCortConst = crlEEG.file.NRRD(fName,fPath);
  varargout{1} = nrrdCortConst;
  return;
end;

%% Compute Constraint Vectors, if Necessary
crlEEG.disp('Computing Cortical Constraint Vectors from Surface Normals');

% Convert StreamLine Vectors to Cortical Tangents
nrrdCortConst = clone(surfNormImg, fName,fPath);
nrrdCortConst.data = -nrrdCortConst.data;
nrrdCortConst.encoding = 'gzip';
nrrdCortConst.normalizeVectors;

% Find points to compute at
done = false;
%condMap = headData.options.conductivity.condMap;
%checkLabels = [condMap.Gray.Label condMap.White.Label condMap.CSF.Label];
%ref = headData.options.segmentation.outputImgField;
%imgFullHead = headData.getImage(ref);
%toCheck = find(ismember(imgFullHead.data,checkLabels));
ref = headData.options.segmentation.useICCSeg;
imgICC = headData.getImage(ref);
toCheck = find(imgICC.data>0);

% Preemptively remove those voxels which already have vectors.
crlEEG.disp('Excluding points with vectors already computed');
Vectors = nrrdCortConst.data(:,toCheck);
Vectors = reshape(Vectors,[3,numel(toCheck)]);
Vectors = sum(Vectors,1);
toCheck(find(Vectors)) = [];

crlEEG.disp(['Computing Approximate Surface Normals for Voxels ' ...
  ' Outside Extracted Grey Matter Region']);

Vectors = nrrdCortConst.data;

sizes = imgICC.sizes;

tic
nIt = 0;
while ~done
  nIt = nIt+1;
  crlEEG.disp([num2str(length(toCheck)) ' Voxels remain to be checked']);
  
  % Loop across voxels and update vector approximations
  for i = 1:length(toCheck)
    index = toCheck(i);
    % Get all vectors in the neighboring regions
    
    [x y z] = ind2sub(sizes,index);    
    xRange = x-1:x+1; xRange(xRange<1) = []; xRange(xRange>sizes(1)) = [];
    yRange = y-1:y+1; yRange(yRange<1) = []; yRange(yRange>sizes(2)) = [];
    zRange = z-1:z+1; zRange(zRange<1) = []; zRange(zRange>sizes(3)) = [];
    
    tmpVec = Vectors(:,xRange,yRange,zRange);
    tmpVec = reshape(tmpVec,[3 numel(tmpVec)/3]);
    if any(tmpVec(:))
      % We have some neighbors with vectors
      [u s v] = svd(tmpVec);
      Vectors(:,x,y,z) = u(:,1); % Take the first singular vector as the vector at this point
      toCheck(i) = -1;
    end;
    
    if mod(numel(toCheck),100000)==0
      crlEEG.disp(['Completed ' num2str(i) ' nodes in ' num2str(toc) ' seconds']);
    end;
  end;
  
  % Remove completed voxels from the list
  Q = find(toCheck==-1);
  toCheck(Q) = [];
  
  % Check if we're done
  if (numel(toCheck)==0)||(numel(Q)==0)
    % We're finished if we have done every voxel, or have completed a
    % loop without doing anything.
    done = true;
  end;
  disp(['Completed iteration for a total of ' num2str(toc) ' seconds']);
end;

% Update the data in the nrrdCortConst object and save
nrrdCortConst.data = Vectors;
nrrdCortConst.normalizeVectors;
nrrdCortConst.readOnly = false;

if nargout ==1
  varargout{1} = nrrdCortConst;
end;

crlEEG.disp('Completed Cortical Constraint Matrix');
return


