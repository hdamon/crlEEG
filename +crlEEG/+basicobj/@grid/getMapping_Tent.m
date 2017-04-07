function mapOut = getMapping_Tent(gridIn,gridOut)
%
% function mapOut = getMapping_Tent(gridIn,gridOut)
%
%  Given grid sizes gridIn and gridOut, computes a matrix mapOut that maps
%  an image X defined on gridIn such that mapOut*X is that image on
%  gridOut.  The matrix matOut is row normalized
%
% Written By: Damon Hyde
% Last Major Edit: Dec 9, 2013
% Part of the cnlEEG Project
% 2009-2017
%

% Obtain interpolation weights for each dimension
weightsX = getAxesWeights(gridIn(1),gridOut(1));
weightsY = getAxesWeights(gridIn(2),gridOut(2));
weightsZ = getAxesWeights(gridIn(3),gridOut(3));

% Construct interpolation matrices for each dimension
%  - With each subsequent dimension converted, more of the kronecker
%  product moves to the output space.
mapX = kron(speye(gridIn(2)*gridIn(3)),weightsX);
mapY = kron(speye(gridIn(3)),kron(weightsY,speye(gridOut(1))));
mapZ = kron(weightsZ,speye(gridOut(1)*gridOut(2)));

% Build the full interpolation matrix
%mapOut = mapZ*mapY*mapX;
mapOut = mapX*mapY*mapZ;

end

function weights = getAxesWeights(nOut,nIn)
inPtsXLo = (0:(nIn-1));   inPtsXLo = repmat(inPtsXLo, nOut,1);
inPtsXHi = (1:nIn);       inPtsXHi = repmat(inPtsXHi, nOut,1);

outPtsX = linspace(0,nIn,nOut+1);
outPtsXLo = outPtsX(1:end-1)';  outPtsXLo = repmat(outPtsXLo, 1, nIn);
outPtsXHi = outPtsX(2:end)';    outPtsXHi = repmat(outPtsXHi, 1, nIn);

testLow  = (outPtsXLo - inPtsXHi) > 0;
testHigh = (outPtsXHi - inPtsXLo) < 0;
hasOverlap = ~(testLow | testHigh);

highEnd = min(inPtsXHi,outPtsXHi); highEnd(~hasOverlap) = 0;
lowEnd  = max(inPtsXLo,outPtsXLo); lowEnd(~hasOverlap) = 0;
weights = sparse(highEnd - lowEnd);
end