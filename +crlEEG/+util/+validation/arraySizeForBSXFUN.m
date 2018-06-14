function isValid = arraySizeForBSXFUN(sizeA,sizeB)
% Check that matrix sizes are compatible for bsxfun operation

maxlen = max([numel(sizeA) numel(sizeB)]);

tmpA = ones(1,maxlen);
tmpB = ones(1,maxlen);
tmpA(1:numel(sizeA)) = sizeA;
tmpB(1:numel(sizeB)) = sizeB;

test = ( tmpA==tmpB );
isValid = all((tmpA(~test)==1)|(tmpB(~test)==1));

end
