function [groupOut] = get_ParcelGroupings(nrrdParcel)
% function [groupOut] = GET_PARCELGROUPINGS(nrrdIn)
%
% Given an input parcellation nrrdParcel, returns a structure that provides
% a set of index pairs mapping each parcellation onto the principal NRRD
% gridSpace.
%
% Constructing a sparse matrix as:
%   A = sparse(groupOut.parcelRef,groupOut.gridRef,...
%               ones(size(groupOut.parcelRef)), ...
%               groupOut.nParcel, groupOut.nGrid);
%
% Will produce a sparse matrix mapping parcels onto the fully voxelized
% space. 
%
% Input:
%  nrrdParcel : cnlParcellation object.
%
% Output Structure:
%  groupOut.gridRef      : Index into NRRD grid of each non-zero voxel
%  groupOut.parcelRef    : Index into list of parcels for each non-zero voxel
%  groupOut.parcelLabels : Parcel label for each non-zero voxel
%  groupOut.nGrid        : Total # of grid points
%  groupOut.nParcel      : Total # of parcels
%
% Written By: Damon Hyde
% Last Edited: June 9, 2015
% Part of the cnlEEG Project
%

% Get list of parcel labels
parcelList = unique(nrrdParcel.data(:));
parcelList = parcelList(parcelList>0);

% Set the size of the final matrix
nParcel = length(parcelList);
nGrid = prod(nrrdParcel.sizes);

% Get row and column references
gridRef = 1:prod(nrrdParcel.sizes);
parcelLabels = nrrdParcel.data(:);

% Remove references to voxels outside the parcellated volume
Q = find(ismember(parcelLabels,parcelList));
gridRef = gridRef(Q);
parcelLabels = parcelLabels(Q);
parcelLabels = parcelLabels(:)';

% Renumber parcels so that they're sequential starting at 1.
refIdx(parcelList) = 1:length(parcelList);
parcelRef = refIdx(parcelLabels);

% Put together the output structure
groupOut.gridRef = gridRef;
groupOut.parcelRef = parcelRef;
groupOut.parcelLabels = parcelLabels;
groupOut.nGrid = nGrid;
groupOut.nParcel = nParcel;

end