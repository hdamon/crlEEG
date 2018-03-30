function obj = rebuildCurrMatrix(obj)
% Rebuild currMatrix to match currSolutionSpace
%
% function obj = REBUILDCURRMATRIX(obj)
%
% Rebuild the current cnlMatrixOnSpace.  First computes the transform
% matrix between obj.origSolutionSpace and obj.currSolutionSpace. Then
% determines if the currMatrix is to be collapsed, and if so, applies
% obj.matCollapse.  Finally, converts the matrix into the new space
% by applying the transform.
%
% If obj.disableRebuild is true, returns an empty matrix without triggering
% a warning. 
%
% If obj.canRebuild is false, throws a warning and returns an empty matrix.
%
% Written By: Damon Hyde
% Last Edited: Feb 3, 2016
% Part of the cnlEEG Project
%



if obj.disableRebuild
  % Silent return of empty matrix if rebuild has been diabled;
 % crlEEG.disp('Rebuild currently disabled. Returning empty matrix');
  obj.currMatrix = [];
  return;
end;

crlEEG.disp('Started rebuilding cnlMatrixOnSpace object');

if ~obj.canRebuild
  warning('Cannot currently rebuild matrix. Returning empty array');
  obj.currMatrix = []; % Set it to empty so we don't accidentally use it.
  return;
end;

matTransform = getMapping(obj.origSolutionSpace,obj.currSolutionSpace);

if ~obj.isCollapsed,  
  matTransform = kron(matTransform,speye(obj.colPerVox));  
  obj.currMatrix = obj.origMatrix;
else obj.currMatrix = obj.origMatrix*obj.matCollapse;  
end;

obj.currMatrix = obj.currMatrix*matTransform;

crlEEG.disp('Completed rebuilding cnlMatrixOnSpace object');

end