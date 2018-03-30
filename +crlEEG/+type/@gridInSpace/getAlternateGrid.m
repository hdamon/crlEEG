function objOut = getAlternateGrid(obj,type)
% function objOut = getAlternateGrid(obj,type)
%
% Given a cell-centered grid, return the associated node centered grid.  
% Given a node-centered grid, return the associated cell centered grid.
% 
% If type is provided, return that type of grid, whether it is the same as
% the input grid, or the alternate.
%
% Written By: Damon Hyde
% Last Edited: Jun 2, 2015
% Part of the cnlEEG Project
% 2009-2017
%

if ~exist('type','var')
  if strcmpi(obj.centering,'cell')
    type = 'node';
  elseif strcmpi(obj.centering,'node')
    type = 'cell';
  else
    error('Unknown centering type');
  end;
end;

switch lower(type)
  case 'cell'
    if strcmpi(obj.centering,'cell')
      objOut = obj;
    else
      newSizes = obj.sizes-1;
      nDim = length(obj.sizes);
      newOrigin = obj.origin + (0.5*obj.directions*ones(nDim,1))';
      newDirections = obj.directions;
      objOut = crlEEG.typegridInSpace(newSizes,'origin',newOrigin,'directions',newDirections,'centering','cell');
    end
  case 'node'
    if strcmpi(obj.centering,'node')
      objOut = obj;
    else
      newSizes = obj.sizes + 1;
      nDim = length(obj.sizes);
      newOrigin = obj.origin - (0.5*obj.directions*ones(nDim,1))';
      newDirections = obj.directions;
      objOut = crlEEG.typegridInSpace(newSizes,'origin',newOrigin,'directions',newDirections,'centering','node');
    end;
  otherwise
    error('Unknown centering type');
end
end