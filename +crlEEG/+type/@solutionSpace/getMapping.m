function matOut = getMapping(spaceIn,spaceOut)
% function matOut = getMapping(spaceOut,spaceIn)
%
% Given spaceOut and spaceIn as solutionSpaces, returns a matrix mapping
% spaceIn to spaceOut by right multiplication
%

checkCompatibility(spaceIn,spaceOut);

% Map the Input Space to Its Fundamental Grid (Left Multiplier)
mydisp('Obtaining map from Input Space to Input Grid');
%inGrid = speye(prod(spaceIn.sizes));
%inGrid = inGrid(spaceIn.Voxels,:);
inGrid = spaceIn.matGridToSolSpace;

% Map the Output Space to Its Fundamental Grid (Right Multiplier)
mydisp('Obtaining map from Output Grid to Output Space');
%outGrid = speye(prod(spaceOut.sizes));
%outGrid = outGrid(:,spaceOut.Voxels);
outGrid = spaceOut.matGridToSolSpace';

% Get Map Betweens Grids (this is just 1 if they're identical)
mydisp('Obtaining map from Input Grid to Output Grid');
gridToGrid = getMapGridToGrid(spaceIn,spaceOut);

% Get the total mapping matrix
matOut = inGrid*gridToGrid*outGrid;


end

