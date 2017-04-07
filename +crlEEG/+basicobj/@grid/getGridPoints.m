function ptsOut = getGridPoints(grid,idx)
% function ptsOut = getGridPoints(grid,idx)
%
% Get a list of all grid points in X, Y, and Z
%
% idx can be used to determine whether the index starts at zero or
% one using the IndexType.startatZero and IndexType.startatOne
% enumerated type.
%
% Written By: Damon Hyde
% Part of the cnlEEG Project
% 2009-2017
%

switch grid.dimension
  case 1
    X = 1:grid.sizes(1);
    Y = ones(size(X));
    Z = ones(size(X));
  case 2
    [X, Y]   = ndgrid(1:grid.sizes(1),1:grid.sizes(2));
    Z = ones(size(X));
  case 3
    [X, Y, Z] = ndgrid(1:grid.sizes(1),1:grid.sizes(2),1:grid.sizes(3));
end

if ~exist('idx','var')
  idx = grid.idxBy;
end;

ptsOut = [X(:) Y(:) Z(:)];

if idx==IndexType.startatZero
  ptsOut = ptsOut - 1;
end;

end