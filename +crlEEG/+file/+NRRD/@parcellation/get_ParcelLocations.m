function locationsOut = get_ParcelLocations(parcelIn)
% Compute the centroid location of each parcel in a cnlParcellation
%
% function locationsOut = get_ParcelLocations(parcelIn)
%
% Given a cnlParcellation, returns a nParcel X 3 matrix containing the
% X-Y-Z locations of the centroid of each parcel, in the 3D space defined
% by parcelIn.gridSpace
%
% Written By: Damon Hyde
% Last Edited: Aug 13, 2015
% Part of the cnlEEG Project
%

group = parcelIn.get_ParcelGroupings;
tmpmat = sparse(group.parcelRef,group.gridRef,ones(size(group.parcelRef)),group.nParcel,group.nGrid);

nvox = sum(tmpmat,2);
tmpmat = diag(1./nvox)*tmpmat;

pts = parcelIn.gridSpace.getGridPoints;

locationsOut = tmpmat*pts;

end