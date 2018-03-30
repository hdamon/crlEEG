function varargout = checkCompatibility(spaceIn,spaceOut)
% Check compatibility of two solutionSpaces
%
% function isCompatible = checkCompatibility(spaceIn,spaceOut)
%
% Checks to see if spaceIn can be transformed to spaceOut.  In practice,
% this means that the voxels in spaceOut are a subset of those in spaceIn.
%
% Part of the crlEEG Project
% 2009-2018
%

if isa(spaceIn,'cnlSolutionSpace')&&(isa(spaceOut,'cnlSolutionSpace'))
  boxIn = spaceIn.getBoundingBox;
  boxOut = spaceIn.getBoundingBox;
  %if all(all(round(1000*boxIn)==round(1000*boxOut)))
  if all(all(floor(100*boxIn)==floor(100*boxOut)))
    if all(spaceIn.sizes==spaceOut.sizes)
      % Built on same size grid
      isCompatible = checkCompList(spaceIn.Voxels,spaceOut.Voxels);
    else
      % Built on different grids
      matGridToGrid = getMapGridToGrid(spaceIn,spaceOut);
      spaceInVoxInspaceOut = find(sum(matGridToGrid(spaceIn.Voxels,:),1));
      isCompatible = checkCompList(spaceInVoxInspaceOut,spaceOut.Voxels);
    end;
  else
    error('Both spaces must have the same bounding box');
  end
else
  error('Both inputs must be solution spaces');
end;

if ~isCompatible
  warning('Solution spaces are incompatible');
end;

% Output, if requested
if nargout==1, varargout{1} = isCompatible; end;

end

function isCompatible = checkCompList(VoxA,VoxB)
% function isCompatible = checkCompList(VoxA,VoxB)
%
% Determines if voxB is a subset of voxA
if all(ismember(VoxB,VoxA))
  isCompatible = true;
else
  isCompatible = false;
end;
end