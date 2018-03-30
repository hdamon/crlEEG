function matOut = getMat_LeadFieldWeighted(spaceIn,LeadField)
% Compute a solution basis set based on the SVD of the leadfield
%
% function matOut = getMat_LeadFieldWeighted(spaceIn,LeadField)
%
% A method of cnlParcelSolutionSpace objects.
%
% Inputs:
%  spaceIn   : cnlParcelSolutionSpace object
%  LeadField : cnlLeadField object
%
% Outputs:
%  matOut : Matrix mapping the MRI volume the leadfield is defined on
%             onto a set of basis functions
%
% NOTE: This function is largely deprecated. It's still in here, but it's
% probably better to use a graph weighted cnlParcelSolutionSpace rather
% than a leadfield weighted one.
%
% Written By: Damon Hyde
% Last Edited: June 9, 2015
% Part of the cnlEEG Project
%


%% Input checking
assert(isa(LeadField,'cnlLeadField'),...
  'A cnlLeadField must be provided to build the solution space from');
assert(eq(cnlGridSpace(spaceIn),cnlGridSpace(LeadField.origSolutionSpace)),...
  'Leadfield and Parcellation Must Be Defined on the Same Grid');
assert(LeadField.canCollapse,'A collapsible leadfield is required');

%%
group = spaceIn.nrrdParcel.get_ParcelGroupings;

[rowRef colRef] = spaceIn.get_RefsForSparseMatrix;
nRows = spaceIn.maxNVecs*group.nParcel;


% Get the list of voxels modeled by the provided leadfield, and create a
% mapping from references into the NRRD grid to references into the
% leadfield.
LeadField.currSolutionSpace = LeadField.origSolutionSpace;
LeadField.isCollapsed = true;

voxLField = LeadField.currSolutionSpace.Voxels;
indexesIntoLeadField = zeros(prod(spaceIn.nrrdParcel.sizes),1);
indexesIntoLeadField(voxLField) = 1:length(voxLField);

maxVecs = spaceIn.maxNVecs;
isNormalized = spaceIn.normalized;
removeMean = spaceIn.removeMean;
currMatrix = LeadField.currMatrix;

% Serial Computation to Reduce the Communication Overhead of the Parallel
% Phase
parcelData = cell(group.nParcel,1);
tic
for idxP = 1:group.nParcel
  % Find the voxels in that parcel
  voxelsInParcel = find(group.parcelRef==idxP);
  
  % Find the index into the leadfield, and eliminate voxels that are
  % outside the space modeled by the leadfield
  currIdxIntoLeadField = indexesIntoLeadField(group.gridRef(voxelsInParcel));
  isModeled = ( currIdxIntoLeadField~=0 );
  currIdxIntoLeadField = currIdxIntoLeadField(isModeled);
  
  % Get the appropriate submatrix from the leadfield and normalize it.
  subMat = currMatrix(:,currIdxIntoLeadField);
  
  parcelData{idxP}.vox    = voxelsInParcel(isModeled);
  parcelData{idxP}.subMat = subMat;
end
toc

parcelSolutions = cell(group.nParcel,1);
mydisp('Starting Parallel Computation of Parcel Bases');
tic
parfor idxP = 1:group.nParcel
  
%   % Find the voxels in that parcel
%   voxelsInParcel = find(group.parcelRef==idxP);
%   
%   % Find the index into the leadfield, and eliminate voxels that are
%   % outside the space modeled by the leadfield
%   currIdxIntoLeadField = indexesIntoLeadField(group.gridRef(voxelsInParcel));
%   isModeled = ( currIdxIntoLeadField~=0 );
%   currIdxIntoLeadField = currIdxIntoLeadField(isModeled);
%   
%   % Get the appropriate submatrix from the leadfield and normalize it.
%   subMat = currMatrix(:,currIdxIntoLeadField);
  
  subMat = parcelData{idxP}.subMat;
    
  if isNormalized
    nrms = sqrt(sum(subMat.^2,1));
    Q = nrms==0;
    nrms = 1./nrms;
    nrms(Q) = 0;
    subMat = subMat*spdiags(nrms(:),0,numel(nrms),numel(nrms));
  end;
  
  if removeMean
    meanMat = mean(subMat,2);
    subMat = subMat - repmat(meanMat,1,size(subMat,2));
  end;
  
  % Get the svd of the submatrix
  [U S V] = svd(subMat,'econ');
  
  parcelBases = zeros(maxVecs,size(subMat,2));
  if removeMean
    % First basis vector is all ones
    nV = size(subMat,2);%numel(voxelsInParcel(isModeled));
    parcelBases(1,:) = (1./nV)*ones(1,nV);
    
    % Remaining vectors from SVD
    for i = 1:(maxVecs-1)
      if i<=size(V,2)
        parcelBases(i+1,:) = V(:,i)';
      end;
    end;
  else
    % Basis vectors only from SVD
    for i = 1:(maxVecs)
      if i<=size(V,2)
        parcelBases(i,:) = V(:,i)';
      end;
    end;
  end;
  
  parcelSolutions{idxP}.bases = parcelBases;
  parcelSolutions{idxP}.idx = parcelData{idxP}.vox;
  
end;
toc

% With everything computed (in parallel), put it all together.
mydisp('Assembling Final Output Matrix');
newVals = zeros(size(rowRef));
for idxP = 1:group.nParcel
  nBases = size(parcelSolutions{idxP}.bases,1);
  idxVox = parcelSolutions{idxP}.idx;
  newVals(1:nBases,idxVox) = parcelSolutions{idxP}.bases;
end

matOut = sparse(rowRef,colRef,newVals,nRows,group.nGrid);




end