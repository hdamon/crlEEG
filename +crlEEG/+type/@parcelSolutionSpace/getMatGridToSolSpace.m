function mat_Mapping = getMatGridToSolSpace(spaceIn,p)
% Get mapping matrix from parcel solutionspace to underlying grid space
%
% function mat_Mapping = getMatGridToSolSpace(spaceIn,type,LeadField,nVecs)
%
% This method overloads @cnlSolutionSpace.getMatGridToSolSpace, and adds
% functionality for computing matrices to project solutions computed on
% parcellized bases onto the original grid space.
%
% Written By: Damon Hyde
% Last Edited: July 23, 2015
% Part of the cnlEEG Project
%

% Input Checking
% if ~exist('nrrdParcel','var')
%   error('Must define nrrdParcel when using a parcelled solution space');
% end

switch lower(p.type)
  case 'group'
    % We just want to cluster the appropriate voxels together, so we just
    % using the mapping matrix from the cnlParcellation object.
    mydisp('Building Piecewise Constant Bases on Parcellation');
    mat_Mapping = spaceIn.nrrdParcel.get_MappingMatrix';    
  case 'graph'
    %error('Not fully implemented yet');
    mat_Mapping = getMat_WeightedGraphBases(spaceIn,'basic',p.LeadField,p.nrrdVec);
  case 'hybridgraph'
    mat_Mapping = getMat_WeightedGraphBases(spaceIn,'hybridretained',p.LeadField,p.nrrdVec);
  case 'weightedgraph'
    error('Not yet implemented');
  case 'lfield'
    %
    mat_Mapping = getMat_LeadFieldWeighted(spaceIn,p.LeadField);    
  otherwise
    error('Unknown cnlParcelSolutionSpace type');
end

end
