function matLeadField = compute_LeadField(FDModel,elecIdx,gndIdx,baseSolSpace,varargin)
% Compute a Leadfield matrix from a cnlFDModel object
%
% function matLeadField = computeLeadField(FDModel,Electrodes,baseSolSpace,origSolSpace)
%
% Given a properly configured cnlFDModel object, with matFDM already
% computed,
%
% Inputs:
%   FDModel      : cnlFDModel object.
%   elecNodes    : Indices of nodes to compute
%   gndNode      : Index of node in FDModel to use as common ground
%   baseSolSpace : cnlSolutionSpace the FDModel is defined on
%   origSolSpace : cnlSolutionSpace of desired leadfield
%   doParallelComp : Flag to enable parallel computation
%
%
%
% Written By: Damon Hyde
% Last Edited: Aug 16, 2016
% Part of the cnlEEG Project
%

%% Input Parsing
p = inputParser;
p.addRequired('FDModel',@(x) isa(x,'crlEEG.head.model.EEG.finiteDifference'));
p.addRequired('elecIdx');
p.addRequired('gndIdx');
p.addRequired('baseSolSpace',@(x) isa(x,'cnlSolutionSpace'));
p.addOptional('origSolSpace',[],@(x) isa(x,'cnlSolutionSpace'));
p.addOptional('doParallelComp',true,@(x) numel(x)==1);

parse(p,FDModel,elecIdx,gndIdx,baseSolSpace,varargin{:});

%% Necessary Assertions about the Input FDModel
assert(~isempty(FDModel.electrodes),...
  'Electrodes must first be defined in the cnlFDModel object');
assert(~isempty(FDModel.matFDM),...
  'cnlFDModel.matFDM must be precomputed before calling compute_LeadField');

if numel(gndIdx)==1
 gndIdx = gndIdx*ones(1,numel(elecIdx));
end;

assert(numel(gndIdx)==numel(elecIdx),...
  ['Number of ground nodes must either be 1 or match the number ' ...
   'of electrode nodes']);

%% Obtain a Mapping from the Initial Solution Space to the Final Desired
%% Output Space
if isempty(p.Results.origSolSpace)
  % If no origSolSpace is provided, the output is in baseSolSpace
  origSolSpace = baseSolSpace;
  matDownSample = 1;
else
  origSolSpace = p.Results.origSolSpace;
  matDownSample = getMapping(baseSolSpace,p.Results.origSolSpace);
end

%% Get All Input Current Maps
mydisp('Computing Input Currents');
Currents_In = FDModel.getCurrents(gndIdx,-1,elecIdx,1);

%% Parallel computation flag
doParallelComp = p.Results.doParallelComp;

%% Compute Solution for all Electrode-Ground Pairs
if doParallelComp
  cnlStartMatlabPool;
  mydisp('Parallel pool started. Ready to compute leadfield');
  
  % Convert the FD Model into a very standard matlab variables. THis is to
  % to make the parallel computation faster. Matlab seems to get quite
  % confused if you try to pass the FD object.
  tol         = FDModel.tol;
  maxIt       = FDModel.maxIt;
  sizeCondImg = FDModel.imgSize;
  aspect      = FDModel.aspect;
  voxInVol    = FDModel.voxInside;  
  matFDM      = FDModel.matFDM;
  
  tmp = cell(size(Currents_In,2),1);
  parfor i = 1:numel(elecIdx)
    mydisp(['Started solution for electrode ' num2str(i)]);
    tmp{i} = solveElectrode(matFDM,full(Currents_In(:,i)),matDownSample,...
                tol,maxIt,sizeCondImg,aspect,voxInVol);
  end;
  
  matLeadField = cat(2,tmp{:});
  
else
  
  matLeadField = zeros(3*origSolSpace.nVoxels,FDModel.electrodes.nElec);
  %Do Computations Serially
  mydisp('Using Serial Computation');
  for i = 1:FDModel.electrodes.nElec
    mydisp(['Started solution for electrode ' num2str(i)]);
    tmp = solveElectrode(FDModel,i,gndIdx,matDownSample);
    matLeadField(:,i) = tmp(:);
  end;
end;

end % computeLeadField


function rowOut = solveElectrode(matFDM,Currents_In,matDownSample,...
                          tol,maxIt,sizeCondImg,aspect,voxInVol)
%
% function rowOut = solveElectrode(ElecNode,Electrodes.GndNode,FDModel,downSample,solutionPoints)
%
% Computes a row of the weight matrix, given source and ground electrode
% locations, a finite difference model to construct from, information about
% post-computation downsampling, and a list of voxels to be kept

% Set Input Currents
%mydisp('Setting currents');
%Currents_In = setCurrents(FDModel.imgSize+[1 1 1],ElecNode,GndNode);
%Currents_In = FDModel.getCurrents(ElecIdx,GndIdx);

disp(['Input currents of size: ' num2str(size(Currents_In))]);
disp(['Model of size: ' num2str(size(matFDM))]);

% Compute Leadfield Row - Potential Gradient at Each Voxel Center
mydisp('Solving for gradient');
%gradV_atVoxCenters = FDModel.solveForGradient(Currents_In);
tStart = clock;
[Potentials, Flag, Residual, Iters] = minres(matFDM,Currents_In,tol,maxIt);

% Display a few things
mydisp(['Completed solution for Electrode in ' num2str(etime(clock,tStart)) ' seconds']);
if Flag==0
  mydisp(['MINRES Converged in ' num2str(Iters) ' iterations to within ' num2str(tol)]);
elseif Flag==1
  mydisp(['MINRES Completed AFter ' num2str(Iters) ' iterations to residual ' num2str(Residual)]);
else
  mydisp('ERROR While Running MINRES');
end;

% Compute and display the residual error
err = matFDM*Potentials(:)-Currents_In;
err = norm(err(:))/norm(Currents_In);
mydisp(['FD Model Solution Obtained with Relative Error: ' num2str(err)]);

% The only time we should get a NaN number in the error is if Current_In is
% zero.
if norm(Currents_In)~=0 && isnan(err)
  error('Something is wrong if we''re getting a NaN error value');
end;

% Split the vector of potentials into those that represent actual physical
% voltages in the model grid space, and those corresponding to auxilliary
% nodes defined by the electrode model
%
nNodes = prod(sizeCondImg+[1 1 1]);
AuxNodes = Potentials(nNodes+1:end);
Potentials = Potentials(1:nNodes);

gradV_atVoxCenters = getGradient(Potentials,sizeCondImg,aspect,voxInVol);

% Do the pre-save downsampling.  This should hopefully end up being
% unneeded soon.
mydisp('Downsampling to resolution for output');
gradV_atVoxCenters = reshape(gradV_atVoxCenters,[3 prod(sizeCondImg)]);
gradV_atVoxCenters = gradV_atVoxCenters*matDownSample;
%gradV_atVoxCenters = gradV_atVoxCenters;

%mydisp(['Downsampled in ' num2str(etime(clock,tStep)) ' seconds']);
rowOut =  gradV_atVoxCenters(:);
mydisp('Finished solving for electrode');

end

function gradOut = getGradient(Potentials,sizeCondImg,aspect,voxInVol)
Potentials = reshape(Potentials,sizeCondImg+[1 1 1]);

% Compute change along each edge of each cell
mydisp('Get Delta X/Y/Z');
deltaX = (Potentials(2:end,:,:) - Potentials(1:end-1,:,:))/aspect(1);
deltaY = (Potentials(:,2:end,:) - Potentials(:,1:end-1,:))/aspect(2);
deltaZ = (Potentials(:,:,2:end) - Potentials(:,:,1:end-1))/aspect(3);

% Take the mean across each set of four parallel edges and vectorize
mydisp('Take mean of Delta');
meanX = deltaX(:,1:end-1,1:end-1)+deltaX(:,2:end,1:end-1) + ...
  deltaX(:,1:end-1,2:end) + deltaX(:,2:end,2:end);
meanY = deltaY(1:end-1,:,1:end-1)+deltaY(2:end,:,1:end-1) + ...
  deltaY(1:end-1,:,2:end) + deltaY(2:end,:,2:end);
meanZ = deltaZ(1:end-1,1:end-1,:)+deltaZ(2:end,1:end-1,:) + ...
  deltaZ(1:end-1,2:end,:) + deltaZ(2:end,2:end,:);
meanX = meanX/4;  meanY = meanY/4;  meanZ = meanZ/4;
meanX = meanX(:); meanY = meanY(:); meanZ = meanZ(:);

% Form this into a vector image, with nonzero values only at those voxels
% with nonzero conductivity.  Otherwise, sensitivities will exist outside
% the volume.
mydisp('Building Gradient Volume');

%voxInVol = FDModel.voxInside;
gradOut = zeros(3,prod(sizeCondImg));
gradOut(1,voxInVol) = meanX(voxInVol);
gradOut(2,voxInVol) = meanY(voxInVol);
gradOut(3,voxInVol) = meanZ(voxInVol);
gradOut = reshape(gradOut,[3 sizeCondImg]);

end
