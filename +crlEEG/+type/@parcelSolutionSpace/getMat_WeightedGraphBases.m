function matOut = getMat_WeightedGraphBases(spaceIn,type,LeadField,nrrdVec)
% GETMAT_WEIGHTEDGRAPHBASES Construct a mapping matrix for smooth graph based bases on a parcellation
% 
% function matOut = getMat_GraphWeighted(spaceIn,LeadField,nrrdVec)
%
% Inputs:
%   spaceIn : cnlParcelSolutionSpace being constructed
%   type    : Type of graph 
%
% Outputs:
%   matOut : The 
%
% Written By: Damon Hyde
% Last Edited: Aug 11, 2015
% Part of the cnlEEG Project
%

%% Start
mydisp('START: Computing Weighted Graph Bases');

%% Input Checking
assert(isa(LeadField,'cnlLeadField'),...
  'A cnlLeadField must be provided to build the solution space from');
assert(eq(cnlGridSpace(spaceIn),cnlGridSpace(LeadField.origSolutionSpace)),...
  'Leadfield and Parcellation Must Be Defined on the Same Grid');
assert(LeadField.canCollapse,'A collapsible leadfield is required');

%% Set the Leadfield
LeadField.currSolutionSpace = LeadField.origSolutionSpace;
LeadField.isCollapsed = true;

%% Build the Graph
voxLField = LeadField.currSolutionSpace.Voxels;

graph = cnlImageGraph(nrrdVec.data,3,'voxList',voxLField,'distType',type,...
                   'nbrType','none','Leadfield',LeadField.currMatrix);

%% Get the Output Column and Row References                 
group = spaceIn.nrrdParcel.get_ParcelGroupings;
[rowRef, colRef] = spaceIn.get_RefsForSparseMatrix;
nRows = spaceIn.maxNVecs*group.nParcel;

%% Extract All the Needed Submatrices and Appropriate Indices
parcelData = cell(group.nParcel,1);
tic
for idxP = 1:group.nParcel
  voxelsInParcel = find(group.parcelRef == idxP);
  inParcel = ismember(graph.imVox,group.gridRef(voxelsInParcel));
  inImage = ismember(group.gridRef(voxelsInParcel),graph.imVox);
  
  parcelData{idxP}.subGraph = graph.Cmatrix(inParcel,inParcel);
  parcelData{idxP}.idx = voxelsInParcel(inImage);
end;
toc

%% Do the Decompositions in Parallel
mydisp('Starting Parallel Computation of Parcel Bases');
parcelSolutions = cell(group.nParcel,1);
maxVecs = spaceIn.maxNVecs;
tic
%cnlStartMatlabPool;
for idxP = 1:group.nParcel
   %voxelsInParcel = find(group.parcelRef == idxP);   
   %inParcel = ismember(graph.imVox,group.gridRef(voxelsInParcel));   
   %subGraph = graph.Cmatrix(inParcel,inParcel);
   subGraph = parcelData{idxP}.subGraph;
   
   %D = diag(subGraph*ones(size(subGraph,2),1));
   D = spdiags(subGraph*ones(size(subGraph,2),1),0,size(subGraph,2),size(subGraph,2));
   L = D-subGraph;
   if maxVecs<=size(L,2)
     [V D] = eigs(L,maxVecs,'SA');
   else
     [V D] = eig(L);
   end
   
   % Check to ensure that only a single eigenvalue is zero or close to
   % zero.  If more than one exists, the parcel is probably not connected,
   % and the parcellation should be recomputed before building a solution
   % space based on it.
   D = diag(D);
   closeToZero = abs(D)<1e-10;
   if sum(closeToZero)>1
     disp([num2str(sum(closeToZero)) ' eigenvalues are close to zero']);
     keyboard
   end
   
   % 
   parcelBases = zeros(maxVecs,size(V,1));
   for i = 1:maxVecs
     if i<=size(V,2)
       % Why am I normalizing these basis functions in this way?
       parcelBases(i,:) = V(:,i); %/max(abs(V(:,i))); %sum(inParcel)/norm(V(:,i),1);
     else
       warning('Failed to compute basis functions');
       parcelBases(i,:) = zeros(1,numel(voxelsInParcel));
     end
   end;
          
   parcelSolutions{idxP}.bases = parcelBases;
   parcelSolutions{idxP}.idx   = parcelData{idxP}.idx;
   
end
toc

%% With everything computed (in parallel), put it all together.
mydisp('Assembling Final Output Matrix');
newVals = zeros(size(rowRef));
for idxP = 1:group.nParcel
  nBases = size(parcelSolutions{idxP}.bases,1);
  idxVox = parcelSolutions{idxP}.idx;
  newVals(1:nBases,idxVox) = parcelSolutions{idxP}.bases;
end

matOut = sparse(rowRef,colRef,newVals,nRows,group.nGrid);

%% Finish
mydisp('COMPLETE: Computation of Weighted Graph Bases');
end