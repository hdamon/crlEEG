function isEqual = compareSizes(sizeA,sizeB)
% Compare the size of two objects, with possible different dimensionalities
%
%

maxlen = max([numel(sizeA) numel(sizeB)]);
sA = zeros(1,maxlen);
sB = zeros(1,maxlen);
sA(1:numel(sizeA)) = sizeA;
sB(1:numel(sizeB)) = sizeB;

isEqual = sA==sB;

end