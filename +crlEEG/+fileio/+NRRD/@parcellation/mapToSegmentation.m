function [nrrdParcelOut] = mapToSegmentation(nrrdParcel,varargin)
% function [nrrdParcelOut] = mapToSegmentation(nrrdParcel,nrrdSeg,nrrdName,nrrdPath)
%
% Maps the cnlParcellation contained in nrrdParcel, and maps it onto the
% cortical structures defined in nrrdSeg.  If provided, nrrdName and
% nrrdPath provide the filename and path for the output nrrd. 
%
% Inputs:
%   nrrdParcel : cnlParcellation object
% Optional Argument Value Pairs:
%   fname : Filename to assign to the output parcellation
%             DEFAULT: ParcelOut.nhdr
%   fpath : Filepath to assign to the output parcellation
%             DEFAULT: ./
%   greylabel  : Segmentation label for grey matter
%                 DEFAULT: 4
%   whitelabel : Segmentation label for white matter
%                 DEFAULT: 7
%
% Default values are:
%     nrrdName = 'ParcelOut.nhdr';
%     nrrdPath = './';
%
% Written By: Damon Hyde
% Last Edited: Jan 14, 2015
% Part of the cnlEEG Project
%

crlEEG.disp('Parcellating Segmentation');

%% Input Parsing
p = inputParser;
p.addRequired('nrrdSeg',@(x) isa(x,'crlEEG.fileio.NRRD'));
p.addParamValue('fname'     ,'ParcelOut.nhdr')
p.addParamValue('fpath'     ,'./'            ,@(x) (exist(x,'dir')) );
p.addParamValue('greylabel' ,4               ,@(x) isnumeric(x) && (numel(x)==1) );
p.addParamValue('whitelabel',7               ,@(x) isnumeric(x) && (numel(x)==1) );
p.parse(varargin{:});

nrrdSeg    = p.Results.nrrdSeg;
nrrdName   = p.Results.fname;
nrrdPath   = p.Results.fpath;
greylabel  = p.Results.greylabel;
whitelabel = p.Results.whitelabel;


% Get Mapping
parcelMap = cnlParcellation.getMapping(nrrdParcel.parcelType);

% Initialize Output
crlEEG.disp('Initializing Output Parcellation');
nrrdParcelOut = clone(nrrdSeg,nrrdName,nrrdPath);
nrrdParcelOut = cnlParcellation(nrrdParcelOut,[],nrrdParcel.parcelType);
nrrdParcelOut.data = zeros(size(nrrdParcelOut.data));

%% Indicies of Cortex/SubCortex/White Matter in Parcellation
crlEEG.disp('Working on cortical labels');
ParcelCortex    = ismember(nrrdParcel.data,[parcelMap.cortexLabels parcelMap.subcorticalLabels]);
ParcelSubCortex = ismember(nrrdParcel.data,[parcelMap.subcorticalLabels]);
ParcelWhite     = ismember(nrrdParcel.data,[parcelMap.whiteLabels]);
ParcelAllGrey   = ParcelCortex | ParcelSubCortex;

segCortex  = nrrdSeg.data==greylabel;
segCortexA = segCortex & (~ParcelAllGrey); % Voxels we need nearest neighbor for
segCortexB = segCortex &   ParcelAllGrey ; % Voxels where the label matches up

nearest = getNearest(nrrdSeg.sizes,find(ParcelCortex),find(segCortexA));

% % Get XYZ locations for voxels
% [Xtarget Ytarget Ztarget] = ind2sub(nrrdSeg.sizes,find(segCortexA));
% [X Y Z] = ind2sub(nrrdSeg.sizes,find(ParcelCortex));
% 
% % Do a Delaunay Triangulation and use nearestNeighbor() to find the nearest
% % points
% dt = DelaunayTri(X(:),Y(:),Z(:));
% nearest = nearestNeighbor(dt,[Xtarget(:) Ytarget(:) Ztarget(:)]);
% nearest = dt.X(nearest,:);
% nearest = sub2ind(nrrdSeg.sizes,nearest(:,1),nearest(:,2),nearest(:,3));

nrrdParcelOut.data(segCortexA) = nrrdParcel.data(nearest)    ;
nrrdParcelOut.data(segCortexB) = nrrdParcel.data(segCortexB) ;

% Do it all again for the white matter
crlEEG.disp('Working on White matter Labels');
segWhite = nrrdSeg.data==whitelabel;
segWhiteA = segWhite & (~ParcelWhite);
segWhiteB = segWhite & ( ParcelWhite);

nearest = getNearest(nrrdSeg.sizes,find(ParcelWhite),find(segWhiteA));

[Xtarget Ytarget Ztarget] = ind2sub(nrrdSeg.sizes,find(segWhiteA));
[X Y Z] = ind2sub(nrrdSeg.sizes,find(ParcelWhite));

dt = DelaunayTri(X(:),Y(:),Z(:));
nearest = nearestNeighbor(dt,[Xtarget(:) Ytarget(:) Ztarget(:)]);
nearest = dt.X(nearest,:);
nearest = sub2ind(nrrdSeg.sizes,nearest(:,1),nearest(:,2),nearest(:,3));

nrrdParcelOut.data(segWhiteA) = nrrdParcel.data(nearest);
nrrdParcelOut.data(segWhiteB) = nrrdParcel.data(segWhiteB);

%nrrdParcelOut = nrrdParcelOut.ensureConnectedParcels;
crlEEG.disp('Done parcellating segmentation');
end

function nearest = getNearest(imgSize,targetLoc,startLoc)
  [Xtarget Ytarget Ztarget] = ind2sub(imgSize,startLoc);
  [X Y Z] = ind2sub(imgSize,targetLoc);
  dt = DelaunayTri(X(:),Y(:),Z(:));
  
nearest = nearestNeighbor(dt,[Xtarget(:) Ytarget(:) Ztarget(:)]);
nearest = dt.X(nearest,:);
nearest = sub2ind(imgSize,nearest(:,1),nearest(:,2),nearest(:,3));  
end

