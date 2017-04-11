function gradOut = solveForGradient(FDModel,Currents_In)
% SOLVEFORGRADIENT Solve cnlFDModel and return gradient of voltage field
%
% function gradOut = solveForGradient(FDModel,Currents_In)
%
% Solve the FDM problem for the potentials at each solution node (at the voxel
% corners), and then compute the gradient within each voxel.

mydisp('Solving FD Model to compute Gradient at Voxel Centers');

% Compute the potentials
Potentials = FDModel.solveForPotentials(Currents_In);
mydisp('Finished computing potentials');

% Reshape the potentials into a cube
mydisp('Get image size and aspect');
sizeCondImg     = FDModel.imgSize;
aspect          = FDModel.aspect;
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

voxInVol = FDModel.voxInside;
gradOut = zeros(3,prod(sizeCondImg));
gradOut(1,voxInVol) = meanX(voxInVol);
gradOut(2,voxInVol) = meanY(voxInVol);
gradOut(3,voxInVol) = meanZ(voxInVol);
gradOut = reshape(gradOut,[3 sizeCondImg]);

end