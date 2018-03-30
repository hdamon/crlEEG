function out = resample(obj,resampleLevel)
% function out = resample(obj,resampleLevel)
%
%

if numel(resampleLevel)==1, resampleLevel = resampleLevel*ones(1,obj.dimension); end;

if numel(resampleLevel)~=obj.dimension,
  error('resampleLevel must be either a single scalar or of the same length as the dimension of the grid');
end;

% Get the new number of samples along each dimension
newSizes = round(obj.sizes./resampleLevel);

newDirections = obj.directions*diag(obj.sizes./newSizes);


newOrigin = obj.origin;
% If we're cell centered, the origin needs to be moved accordingly
nDims = length(obj.sizes);
if strcmpi(obj.centering,'cell')
  % Shift it to the corner of the volume
  newOrigin = newOrigin - 0.5*(obj.directions*ones(nDims,1))';
  % Shift it to the center of the new voxels
  newOrigin = newOrigin + 0.5*(newDirections*ones(nDims,1))';
end;

out = crlEEG.typegridInSpace(newSizes,newOrigin,newDirections);
end