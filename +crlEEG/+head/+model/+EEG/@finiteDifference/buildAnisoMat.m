function [MatOut] = buildAnisoMat(nrrdIn,spaceScale)
% BUILDANISOMAT Build Anisotropic FD Model From Conductivity NRRD
%
% function [MatOut] = BUILDANISOMAT(nrrdIn,spaceScale)
%
% Function to build the model matrix associated with anisotropic diffusion
%
% This function assumes a couple things:
%
%   1) The orientation of the volume is such that each dimension of the
%   matrix corresponds to one of the basis vectors.
%   2) The anisotropy tensors are defined on this same basis
%
%
% Note that for the anisotropic medium, the computational nodes ARE NOT
% centered on the individual CT voxels, the way they are with the isotropic
% model.  Here, the computational nodes are at the CORNERS of the
% individual voxels. Thus when computing an inverse to obtain
% potential values, the sources must be placed at the corner of the
% appropriate voxel.
%
% Inputs:
% -------
%     VolIn   : A 2-d or 3-d Cell Array.  Each cell should be a 3x3 matrix
%                 describing the conductivity tensor at that location.
%                 Construction on a regular X-Y-Z grid is assumed.
%     sizes   : 1x3 matrix containing differential sizes along x, y, and z
%                 axes
%
% Written By: Damon Hyde 
% Part of the crlEEG Project
% 2009-2017
%

% Assume millimeter spacing if not otherwise provided
if ~exist('spaceScale','var'), spaceScale = 1e-3; end;

% Validate the input NRRD as a tensor NRRD
assert(isTensor(nrrdIn),'Input NRRD must be a tensor image');

sizes = spaceScale*nrrdIn.aspect;

% The size of the voxelated space
nX = nrrdIn.sizes(2);  nY = nrrdIn.sizes(3);  nZ = nrrdIn.sizes(4);

% The size of the FDM node-space
nNodesX = nX+1;  
nNodesY = nY+1;  
nNodesZ = nZ+1;
nNodesTot = nNodesX*nNodesY*nNodesZ;

% Differential Sizes along each cardinal direction
delX = sizes(1);
delY = sizes(2);
delZ = sizes(3);

%% Initialize Vectors
% Each row of the FDM matrix will have 19 elements
% Reserve space for the maximum possible number of elements
listRow = zeros(nNodesX,nNodesY,nNodesZ,19);
listCol = zeros(nNodesX,nNodesY,nNodesZ,19);
listVal = zeros(nNodesX,nNodesY,nNodesZ,19);

% If the parallel processing pool hasn't been started yet, do it now.
cnlStartMatlabPool

% Pull nrrd data array to improve parfor performance
data = nrrdIn.data; 

parfor idxX = 1:nNodesX 
  tic
  % Reserve space for the Row-Col-Value triplets in this slice
  sliceRow = zeros(nNodesY,nNodesZ,19);
  sliceCol = zeros(nNodesY,nNodesZ,19);
  sliceVal = zeros(nNodesY,nNodesZ,19);
  
  %% Iterate Across the Slice
  for idxY = 1:nNodesY 
    for idxZ = 1:nNodesZ 
      
      % Get Indices to Neighboring Voxels
      elementX = idxX + [ -1 -1  0  0 -1 -1  0  0 ];
      elementY = idxY + [  0 -1 -1  0  0 -1 -1  0 ];
      elementZ = idxZ + [ -1 -1 -1 -1  0  0  0  0 ];
      
      % Construct the Tensors for Each of the Eight Voxels Neighboring the
      % node under consideration.
      tensorElement = cell(8,1);
      exist_NonZeroElements = false;
      for idxE = 1:length(elementX)
        try
%          elementRef = sub2ind(size(VolIn),elementX(idxE),elementY(idxE),elementZ(idxE));
          diffTensorVals = data(:,elementX(idxE),elementY(idxE),elementZ(idxE));
          diffTensor = zeros(3,3);
          diffTensor(:,1)   = diffTensorVals(1:3);
          diffTensor(1,:)   = diffTensorVals(1:3)';
          diffTensor(2:3,2) = diffTensorVals(4:5);
          diffTensor(2,2:3) = diffTensorVals(4:5)';
          diffTensor(3,3)   = diffTensorVals(6);          
          tensorElement{idxE} = diffTensor;
          if any(tensorElement{idxE}(:)); exist_NonZeroElements = true; end;
        catch
          % Use an all zero tensor matrix
          tensorElement{idxE} = zeros(3,3);
        end;
      end

      % Only continue is there are non-zero tensors around the current
      % node.
      if exist_NonZeroElements
        % Get Indices of Neighboring Nodes
        nodeNeighborsX = idxX + [  1  0 -1  0  1 -1 -1  1  0  0  0  0  0  0  1 -1 -1  1 0];
        nodeNeighborsY = idxY + [  0  1  0 -1  1  1 -1 -1  0  0  1  1 -1 -1  0  0  0  0 0];
        nodeNeighborsZ = idxZ + [  0  0  0  0  0  0  0  0  1 -1  1 -1 -1  1  1  1 -1 -1 0];

        % Linear indicies into output matrix
        nodeRef = -1*ones(length(nodeNeighborsX),1);
        for idxNode = 1:length(nodeNeighborsX)
          try
            nodeRef(idxNode) = sub2ind([nNodesX nNodesY nNodesZ],nodeNeighborsX(idxNode),nodeNeighborsY(idxNode),nodeNeighborsZ(idxNode));
          catch
            nodeRef(idxNode) = -1;
          end          
        end;
        useNodes = find(nodeRef ~= (-1));

        % Build the 18 Coefficients for each of the 18 Nodes
        A = zeros(19,1);

        A(1)  = (1/4)*(1/delX^2)*(tensorElement{3}(1,1) + tensorElement{4}(1,1) + tensorElement{7}(1,1) + tensorElement{8}(1,1));

        A(2)  = (1/4)*(1/delY^2)*(tensorElement{1}(2,2) + tensorElement{4}(2,2) + tensorElement{5}(2,2) + tensorElement{8}(2,2));

        A(3)  = (1/4)*(1/delX^2)*(tensorElement{1}(1,1) + tensorElement{2}(1,1) + tensorElement{5}(1,1) + tensorElement{6}(1,1));

        A(4)  = (1/4)*(1/delY^2)*(tensorElement{2}(2,2) + tensorElement{3}(2,2) + tensorElement{6}(2,2) + tensorElement{7}(2,2));

        A(5)  =  (1/4)*(1/(delX*delY))*(tensorElement{4}(1,2) + tensorElement{8}(1,2));

        A(6)  = -(1/4)*(1/(delX*delY))*(tensorElement{1}(1,2) + tensorElement{5}(1,2));

        A(7)  =  (1/4)*(1/(delX*delY))*(tensorElement{2}(1,2) + tensorElement{6}(1,2));

        A(8)  = -(1/4)*(1/(delX*delY))*(tensorElement{3}(1,2) + tensorElement{7}(1,2));

        A(9)  =  (1/4)*(1/delZ^2)*(tensorElement{5}(3,3) + tensorElement{6}(3,3) + tensorElement{7}(3,3) + tensorElement{8}(3,3));

        A(10) =  (1/4)*(1/delZ^2)*(tensorElement{1}(3,3) + tensorElement{2}(3,3) + tensorElement{3}(3,3) + tensorElement{4}(3,3));

        A(11) =  (1/4)*(1/(delY*delZ))*(tensorElement{5}(2,3) + tensorElement{8}(2,3));

        A(12) = -(1/4)*(1/(delY*delZ))*(tensorElement{1}(2,3) + tensorElement{4}(2,3));

        A(13) =  (1/4)*(1/(delY*delZ))*(tensorElement{2}(2,3) + tensorElement{3}(2,3));

        A(14) = -(1/4)*(1/(delY*delZ))*(tensorElement{6}(2,3) + tensorElement{7}(2,3));

        A(15) =  (1/4)*(1/(delX*delZ))*(tensorElement{7}(1,3) + tensorElement{8}(1,3));

        A(16) = -(1/4)*(1/(delX*delZ))*(tensorElement{5}(1,3) + tensorElement{6}(1,3));

        A(17) =  (1/4)*(1/(delX*delZ))*(tensorElement{1}(1,3) + tensorElement{2}(1,3));

        A(18) = -(1/4)*(1/(delX*delZ))*(tensorElement{3}(1,3) + tensorElement{4}(1,3));

        A(19) = -sum(A(1:18));

        nNew = length(useNodes);

        %% Assign the Row-Col-Value triplets        
        sliceRow(idxY,idxZ,1:nNew) = ( nodeRef(19)*ones(nNew,1) );
        sliceCol(idxY,idxZ,1:nNew) = ( nodeRef(useNodes)        );
        sliceVal(idxY,idxZ,1:nNew) = (       A(useNodes)        );     
      end
    end    
  end
  
  listRow(idxX,:,:,:) = sliceRow;
  listCol(idxX,:,:,:) = sliceCol;
  listVal(idxX,:,:,:) = sliceVal;  
  disp(['Completed iteration ' num2str(idxX) ' in ' num2str(toc) ' seconds']);    
end

%% Remove Row-Col-Value Triplets that are outside the volume.
crlEEG.disp('Extracting Row-Column Pairs and Values');
listRow = listRow(:);
listCol = listCol(:);
listVal = listVal(:);
remove = (listRow==0)|(listCol==0);
listRow = listRow(~remove);
listCol = listCol(~remove);
listVal = listVal(~remove);

%% Construct Sparse Output Matrix
crlEEG.disp('Constructing Final Finite Difference Matrix');
MatOut = sparse(listRow,listCol,listVal,nNodesTot,nNodesTot);

end


