function ptsOut = getGridPoints(grid,idx)
% function ptsOut = getGridPoints(grid,idx)
%
% Extends the functionality of the cnlGrid method to cnlGridSpace
% objects.  Rather than return coordinates as X-Y-Z indices, this
% returns the X-Y-Z locations in the 3D space defined by
% cnlGridSpace.directions and cnlGridSpace.origin.
%
% Inputs:
%   grid : The cnlGridSpace object to operate on
%   idx  : (optional) List of voxels to return locations for
%
% Written By: Damon Hyde
% Last Edited: Jun 9, 2015
% Part of the cnlEEG Project
% 2009-2017
%

% Get indices of each cell/node, using start-at-zero indexing
pts = getGridPoints@crlEEG.typegrid(grid,IndexType.startatZero);

% Get location of each cell/node
ptsOut = pts*grid.directions' + repmat(grid.origin,size(pts,1),1);

% If we only want certain locations, restrict the list.
if exist('idx','var')
  ptsOut = ptsOut(idx,:);
end;
end