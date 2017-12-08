% Validate a Tensor NRRD
function isTensorNRRD = isTensor(nrrdCond)
% Returns true if nrrdCond is a tensor NRRD with three spatial dimensions
%
% Otherwise, returns an error
%

% Tests
isNRRD   = isa(nrrdCond,'crlEEG.fileio.NRRD');
isTensor = (nrrdCond.sizes(1)==6) && ...
  (strcmpi(nrrdCond.kinds{1},'3D-symmetric-matrix'));
is3D     = sum(nrrdCond.domainDims)==3;

% Assertions
assert(isNRRD,'Input nrrdCond must be a crlEEG.fileio.NRRD object');
assert(isTensor,'Input nrrdCond must be a map of conductivity tensors');
assert(is3D,'Input nrrdCond must have three spatial dimensions');

% nrrdCond is valid if we reach here.
isTensorNRRD = true;
end