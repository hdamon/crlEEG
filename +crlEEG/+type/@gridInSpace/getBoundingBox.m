function boxOut = getBoundingBox(gridSpace)
% Get the bounding box of a crlEEG.typegridInSpace object
%
% function boxOut = getBoundingBox(gridSpace)
%
% Returns an 8x3 matrix of X-Y-Z coordinates defining in the bounding box
% around a crlEEG.typegridInSpace object. The behavior of this is
% dependent upon whether the grid is defined as being cell or node
% centered.
%
% For a cell centered grid, the origin is located at the center of the
% first voxel, and thus the bounding box is offset from this point by 0.5
% steps along each of the principal axes.
%
% For a node centered grid, the origin is located in one corner of the
% bounding box, and the bounding box is directly computed from there.
%
% Written By: Damon Hyde
% Last Edited: Feb 4, 2016
% Part of the cnlEEG Project
% 2009-2017
%

tmpSize = zeros(1,3);
if strcmpi(gridSpace.centering,'cell')
  tmpSize(1:gridSpace.dimension) = gridSpace.sizes;
else
  % If it's node centered, the total size is grid.directions times
  % grid.sizes-1
  tmpSize(1:gridSpace.dimension) = gridSpace.sizes-1;
end;

if gridSpace.dimension>0
  tmpDir = zeros(3,3);
  tmpDir(:,1:gridSpace.dimension) = gridSpace.directions;
  % Get the vectors from the origin to each of the corners
  shiftVec = tmpDir.*repmat(tmpSize,3,1);
  
  origin = gridSpace.origin;
  
  if strcmpi(gridSpace.centering,'cell')
    % For cell centered grids, the origin is at the center of the first
    % cell, not the corner.
    origin = origin + (tmpDir*[-0.5 -0.5 -0.5]')';
  end
    
  corner(1,:) = origin;
  corner(2,:) = origin + shiftVec(:,1)';
  corner(3,:) = origin + shiftVec(:,2)';
  corner(4,:) = origin + shiftVec(:,3)';
  corner(5,:) = origin + shiftVec(:,1)' + shiftVec(:,2)';
  corner(6,:) = origin + shiftVec(:,1)' + shiftVec(:,3)';
  corner(7,:) = origin + shiftVec(:,2)' + shiftVec(:,3)';
  corner(8,:) = origin + shiftVec(:,1)' + shiftVec(:,2)' + shiftVec(:,3)';
  
  boxOut = corner;
else
  boxOut = zeros(8,1);
end;

end