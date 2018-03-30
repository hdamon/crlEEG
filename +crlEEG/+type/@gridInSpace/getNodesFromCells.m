function [nodeList] = getNodesFromCells(grid,cellList)
% function [nodeList] = GETNODESFROMCELLS(grid,cellList)
%
% Given cellList, a list of indices into a cell-centered cnlGridSpace
% (grid), returns the list of nodes in the alternate node-centered
% cnlGridSpace.
%
% Written By: Damon Hyde
% Last Edited: Jun 2, 2015
% Part of the cnlEEG Project
%


if ~strcmpi(grid.centering,'cell')
  error('getNodesFromCells requires a cell-centered grid as input');
end;

[idxX, idxY, idxZ] =ind2sub(grid.sizes,cellList);

idxXAniso = [idxX ; idxX+1 ; idxX   ; idxX+1 ; idxX   ; idxX+1 ; idxX   ; idxX+1 ];
idxYAniso = [idxY ; idxY   ; idxY+1 ; idxY+1 ; idxY   ; idxY   ; idxY+1 ; idxY+1 ];
idxZAniso = [idxZ ; idxZ   ; idxZ   ; idxZ   ; idxZ+1 ; idxZ+1 ; idxZ+1 ; idxZ+1 ];
idxAniso = [idxXAniso(:) idxYAniso(:) idxZAniso(:)];
idxAniso = unique(idxAniso,'rows');

nodeList = sub2ind(grid.sizes+[1 1 1],idxAniso(:,1),idxAniso(:,2),idxAniso(:,3));

return