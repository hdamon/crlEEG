function [rowRef colRef] = get_RefsForSparseMatrix(spaceIn)
% Get row and column references into the sparse projection matrix.
%
% function [rowRef colRef] = get_RefsForSparseMatrix(SpaceIn)
%
% For a cnlParcelSolutionSpace, returns the row and column references into
% a matrix of size (nParcels*nVecs) X (prod(SpaceIn.sizes)), where nParcels
% is the number of parcels in SpaceIn.nrrdParcel, and nVecs is the number
% of basis vectors to be defined per parcel.
%
% Written By: Damon Hyde
% Last Edited: July 27, 2015
% Part of the cnlEEG Project
%

group = spaceIn.nrrdParcel.get_ParcelGroupings;

% Get # of Parcels and Total Number of Rows in Output Matrix
nParcels = group.nParcel;
nRows = spaceIn.maxNVecs*nParcels;

% Get Row References - THere will be nVecs columns per parcel
rowRef = spaceIn.maxNVecs*(group.parcelRef(:)'-1);
rowRef = repmat(rowRef,spaceIn.maxNVecs,1);
for i = 1:spaceIn.maxNVecs
  rowRef(i,:) = rowRef(i,:) + i;
end

% Column references are the same for each of the nVec columns associated with
% a particular parcel
colRef = repmat(group.gridRef(:)',spaceIn.maxNVecs,1);

end