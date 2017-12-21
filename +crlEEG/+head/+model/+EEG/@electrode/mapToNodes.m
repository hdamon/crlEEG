function [elecOut] = mapToNodes(elecIn,nrrdIn,mapType,pushToSurf)
% function [elecOut] = mapToNodes(elecIn,nrrdIn,mapType)
%
% Inputs:
%   elecIn    : cnlElectrodes object
%   nrrdIn    : file_NRRD object
%  mapType    : either 'iso' or 'aniso'
%  pushToSurf : Flag to determine whether electrodes should be moved to the
%                 scalp surface.
%
% Takes the values in elecIn.Locations and identifies the corresponding
% nodes in nrrdIn, and stores them in elecOut.Nodes.
%


% Default to anisotropic node mapping
if ~exist('mapType','var')||isempty(mapType) 
  mydisp('Defaulting to anisotropic node mapping');
  mapType = 'aniso'; 
end;

% By default, push electrodes to surface
if ~exist('pushToSurf','var')||isempty(pushToSurf)
  mydisp('Defaulting to push-to-surface mode');
  pushToSurf = true; 
end;

% Get the grid that we're mapping onto and the list of nodes that are
% inside and outside the volume.
%
switch lower(mapType)
  case 'aniso'
    FDGrid = getAlternateGrid(nrrdIn.gridSpace);
    NodesInside = nrrdIn.gridSpace.getNodesFromCells(nrrdIn.nonZeroVoxels);
    NodesOutside = nrrdIn.gridSpace.getNodesFromCells(nrrdIn.zeroVoxels);
    
    % Make sure all nodes at the boundary of the space are in the Outside
    % list
    altGrid = nrrdIn.gridSpace.getAlternateGrid;
    tmp = ones(altGrid.sizes);
    tmp(2:end-1,2:end-1,2:end-1) = 0;
    AlsoOutside = find(tmp);
    
    NodesOutside = [NodesOutside(:); AlsoOutside(:)];
    NodesOutside = unique(NodesOutside);        
  case 'iso'
    %error('You shouldn''t be using an isotropic model.');
    FDGrid = nrrdIn.gridSpace;
    NodesInside = nrrdIn.nonZeroVoxels;
    NodesOutside = nrrdIn.zeroVoxels;
  otherwise
    error('Unknown mapping type.  Should be either iso or aniso');
end

% Get All the Positions from the Electrodes Object
Positions = zeros(numel(elecIn),3);
for i = 1:numel(elecIn)
  Positions(i,:) = elecIn(i).position;
end

% Move Electrodes inside the head to the surface;
if pushToSurf      
  elecNodes = getNearestNodes(FDGrid,NodesOutside,Positions);    
  Positions = FDGrid.getGridPoints(elecNodes);
end;
  
% Get Final Node Indices and X-Y-Z Locations
elecNodes = getNearestNodes(FDGrid,NodesInside,Positions);
newLoc = FDGrid.getGridPoints(elecNodes);

% 
elecOut = elecIn;
for i = 1:numel(elecOut)
  elecOut(i).nodes = elecNodes(i);
  elecOut(i).position = Positions(i,:);  
end;

end
