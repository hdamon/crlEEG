function matOut = get_MappingMatrix(nrrdParcel)
% function matOut = get_MappingMatrix(nrrdParcel)
%
% Given a cnlParcellation object, returns the matrix defining the mapping
% between each individual parcellation and the grid underlying the NRRD
% they're defined in.
%
% Written By: Damon Hyde
% Last Edited: June 9, 2015
% Part of the cnlEEG Project
%

% Get the appropriate row and column reference pairs
groupOut = get_ParcelGroupings(nrrdParcel);

% Build a sparse matrix, with all non-zero values being ones. 
matOut = sparse(groupOut.gridRef,groupOut.parcelRef,...
                ones(size(groupOut.parcelRef)),...
                groupOut.nGrid,groupOut.nParcel);

end