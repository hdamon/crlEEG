
function downSample(nrrdIn, downSampleLevel, method)
% DOWNSAMPLE - Downsample a NRRD File.
%
% function DownSample(nrrdIn, downSampleLevel, method)
%
% Downsample a NRRD
%
%  nrrdIn          - NRRD to downsample
%  downSampleLevel - either 1x1 or 3x1 variable defining downsampling level
%                       along each dimension
%  method          -
%
% Last Modified: Damon Hyde, 01/02/2014
% Part of the cnlEEG Project
%

% Default downsampling doesn't do anything.
if ( ~exist('downSampleLevel','var') ), downSampleLevel = 1; end;

% Set default interpolation mode to tent.
if ( ~exist('method','var')||isempty(method) ), method = 'tent'; end;

if length(downSampleLevel)==1
  downSampleLevel = ones(1,3)*downSampleLevel;
end;

% Get the grids.  
gridIn = nrrdIn.gridSpace;
gridOut = resample(gridIn,downSampleLevel);

sizeIn  = nrrdIn.sizes;
sizeOut = gridOut.sizes;

switch lower(method)
  case 'segmentation'
    crlEEG.disp('Starting Downsample of Segmentation');
    newData = dwnsmpSegmentation(nrrdIn,gridOut);
    newSize = sizeOut;
  case 'tent'
    crlEEG.disp('Using tent downsampling');
    map = getMapGridToGrid(gridIn,gridOut);
    %tmp = reshape(nrrdIn.data,prod(size(tmp.data)),1);
    switch lower(nrrdIn.kinds{1})
      case 'domain'      
       newData = map'*nrrdIn.data(:);
       newSize = sizeOut;
      case 'covariant-vector'
       map = kron(map,eye(sizeIn(1)));
       newData = map'*nrrdIn.data(:);
       newSize = [sizeIn(1) sizeOut];
      case '3D-symmetric-matrix'
        error('Downsampling of tensors not currently supported');
      case 'vector'
        tmp = reshape(nrrdIn.data(:),sizeIn(1),prod(sizeIn(2:end)));
        newData = map'*tmp';
        newSize = [sizeIn(1) sizeOut];
      otherwise
        error('Unknown nrrd type');
    end
end;

nrrdIn.sizes = newSize;
nrrdIn.spacedirections = gridOut.directions;
nrrdIn.spaceorigin     = gridOut.origin;
nrrdIn.data = reshape(newData,nrrdIn.sizes);

end

function newSeg = dwnsmpSegmentation(nrrdIn,gridOut)
% function newSeg = dwnsmpSegmentation(nrrdIn,downSampleLevel)
%
% Function for downsampling segmentations.  Computes a tent-type
% interpolation function, and assigns the labels on the new grid according
% to which label in the old grid contributes most to the next voxel
crlEEG.disp('Using Segmentation Downsampling Technique');
segVals = unique(nrrdIn.data);

map = getMapGridToGrid(nrrdIn.gridSpace,gridOut);

tmpOut = zeros([prod(gridOut.sizes) length(segVals)]);

for i = 1:length(segVals)
  currLabel = segVals(i);
    
  Q = nrrdIn.data==currLabel;
  
  tmpData = zeros(size(nrrdIn.data));
  tmpData(Q) = 1;
  tmpData = reshape(tmpData,numel(tmpData),1);
  
  newData = map'*tmpData;
  
  tmpOut(:,currLabel+1) = newData;
end

[~,newSeg] = max(tmpOut,[],2);
newSeg = reshape(newSeg-1,gridOut.sizes);

end


% %% We're dealing with a scalar NRRD
% if length(nrrdIn.sizes)==3
%
%   % Make sure we read the data before doing anything else!
%   dataIn  = nrrdIn.data;
%
%   % Get the new data size
%   tmpSizes = nrrdIn.sizes./downSampleLevel;
%   if mod(tmpSizes,1)~=0, warning('WARNING: uneven downsample'); end;
%   nrrdIn.sizes = floor(tmpSizes);   clear tmpSizes;
%   nrrdIn.spacedirections = nrrdIn.spacedirections*diag(downSampleLevel);
%
%   % Reserve space in memory
%   dataOut = zeros([prod(downSampleLevel) nrrdIn.sizes]);
%
%   % Iterate
%   idxOut = 0;
%   try
%   for idxX = 1:downSampleLevel(1)
%     for idxY = 1:downSampleLevel(2)
%       for idxZ = 1:downSampleLevel(3)
%         idxOut = idxOut + 1;
%         dataOut(idxOut,:,:,:) = dataIn(idxX:downSampleLevel(1):downSampleLevel(1)*nrrdIn.sizes(1),...
%                                        idxY:downSampleLevel(2):downSampleLevel(2)*nrrdIn.sizes(2),...
%                                        idxZ:downSampleLevel(3):downSampleLevel(3)*nrrdIn.sizes(3));
%       end
%     end
%   end
%   catch
%     keyboard;
%   end;
%
%   switch upper(method)
%     case 'MODE'
%       dataOut = squeeze(mode(dataOut,1));
%     case 'MEAN'
%       dataOut = squeeze(mean(dataOut,1));
%   end
%
%
% %
% %   for idxX = 1:size(dataOut,1)
% %     idxXin = (idxX-1)*downSampleLevel(1)+1;
% %     for idxY = 1:size(dataOut,2)
% %       idxYin = (idxY-1)*downSampleLevel(2)+1;
% %       for idxZ = 1:size(dataOut,3)
% %         idxZin = (idxZ-1)*downSampleLevel(3)+1;
% %         rangeX = idxXin:(idxXin+downSampleLevel(1)-1);
% %         rangeY = idxYin:(idxYin+downSampleLevel(2)-1);
% %         rangeZ = idxZin:(idxZin+downSampleLevel(3)-1);
% %         tmp = dataIn(rangeX,rangeY,rangeZ);
% %         switch upper(method)
% %           case 'MODE'
% %             dataOut(idxX,idxY,idxZ) = mode(tmp(:));
% %           case 'MEAN'
% %             dataOut(idxX,idxY,idxZ) = mean(tmp(:));
% %         end;
% %       end
% %     end
% %   end
%
%   nrrdIn.data = dataOut;
%
%   crlEEG.disp('%%%% Completed Downsample of Segmentation');
%
% %% We're dealing with a vector NRRD
% elseif (length(nrrdIn.sizes)==4)&&(nrrdIn.sizes(1)==3)
%   try
%   Nsize = nrrdIn.sizes;
%   Nsize(2:end) = floor(Nsize(2:end)./downSampleLevel);
%   DownSampledNormals = zeros(Nsize);
%
%   nrrdIn.sizes = size(DownSampledNormals);
%   nrrdIn.spacedirections = nrrdIn.spacedirections*diag(downSampleLevel);
%
%   xOrig = ((1:Nsize(2))-1)*downSampleLevel(1);
%   yOrig = ((1:Nsize(3))-1)*downSampleLevel(2);
%   zOrig = ((1:Nsize(4))-1)*downSampleLevel(3);
%   for xOffset = 1:downSampleLevel(1)
%     for yOffset = 1:downSampleLevel(2)
%       for zOffset = 1:downSampleLevel(3)
%         DownSampledNormals = DownSampledNormals + nrrdIn.data(:,xOrig+xOffset,yOrig+yOffset,zOrig+zOffset);
%       end
%     end
%   end
%
%   nrrdIn.data = DownSampledNormals/(prod(downSampleLevel));
%   catch
%     keyboard;
%   end;
% end;
% end
