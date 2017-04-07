function [idxOut] = getNearestNodes(grid,UseNodes,Positions)
% function [idxOut] = getNearestNodes(grid,vox,Positions)
%
% Given a cnlGridSpace input, and a list of voxels to compare to, finds the
% indices into the main grid corresponding to the nodes closest to the
% locations in Positions.
%
% Written By: Damon Hyde
% Part of the cnlEEG Project
% 2009-2017
%

% Get X-Y-Z locations of each grid point, and restrict the list.
Pts = grid.getGridPoints;
Pts = Pts(UseNodes,:);

% For each position to be shifted, find the closest node.
idxOut = zeros(size(Positions,1),1);
for i = 1:size(Positions,1)    
  dist = Pts - repmat(Positions(i,:),size(Pts,1),1);
  dist = sqrt(sum(dist.^2,2));
  
  q = find(dist==min(dist));
  if numel(q)>1, % Pick a random node if there's more than one
   q = q(ceil(numel(q)*rand(1,1)));
  end;
  idxOut(i) = UseNodes(q);
end

end