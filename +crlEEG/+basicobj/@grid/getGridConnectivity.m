function [varargout] = getGridConnectivity(grid,conSize)
% function [varargout] = getGridConnectivity(grid,conSize)
%
% Given a grid of size [a b c], returns a matrix of size (abc)X(abc) with ones
% in the places associated with a physical connection between voxels along
% one of the three cardinal axes
%
% conSize can be 6, 18, or 26, depending on the desired connectivity level.
%
% These values define the neighborhoods as:
%    6 : All voxels with a taxicab distance of 1 or less
%   18 : All voxels with a taxicab distance of 2 or less
%   26 : All voxels in a 3x3 cube centered on each voxel
%
% Other values for conSize are taken as a radius 
%
% Written By: Damon Hyde
% Part of the cnlEEG Project
% 2009-
%

if ~exist('conSize','var'), conSize = 6; end;

% if ~ismember(conSize,[6 18 26])
%   error('conSize must be 6, 18, or 26');
% end

if ismember(conSize,[6 18 26])
  crlEEG.disp(['Using special case of ' num2str(conSize) ' connectivity']);
else
  crlEEG.disp(['Connecting to all voxels in neighborhood with radius ' num2str(conSize)]);
end;

%crlEEG.disp('Starting Computation of Grid Connectivity');

SpaceSize = grid.sizes;

if length(SpaceSize)==1
  SpaceSize = [SpaceSize 1 1];
elseif length(SpaceSize)==2
  SpaceSize = [SpaceSize 1];
end;

%crlEEG.disp('Getting initial grid');
[idxX, idxY, idxZ] = ndgrid(1:SpaceSize(1),1:SpaceSize(2),1:SpaceSize(3));

%crlEEG.disp('Preallocating space for neighors');
if ismember(conSize,[6 18 26]);
  idxX2 = kron(idxX(:),ones(conSize,1));
  idxY2 = kron(idxY(:),ones(conSize,1));
  idxZ2 = kron(idxZ(:),ones(conSize,1));
else
  nTotal = (2*conSize+1)^3-1;
  idxX2 = kron(idxX(:),ones(nTotal,1));
  idxY2 = kron(idxY(:),ones(nTotal,1));
  idxZ2 = kron(idxZ(:),ones(nTotal,1));
end;

%crlEEG.disp('Computing neighbor locations');
switch conSize
  case 6
    % Convert to Indices of Neighbors
    %idxX2 = idxX2 + kron(ones(numel(idxX),1),[ 1 -1  0  0  0  0 ]');
    %idxY2 = idxY2 + kron(ones(numel(idxY),1),[ 0  0  1 -1  0  0 ]');
    %idxZ2 = idxZ2 + kron(ones(numel(idxZ),1),[ 0  0  0  0  1 -1 ]');
  %  crlEEG.disp('Computing 6-connectivity');
    idxX2 = idxX2 + repmat([1 -1 0  0 0  0]',numel(idxX),1);
    idxY2 = idxY2 + repmat([0  0 1 -1 0  0]',numel(idxY),1);
    idxZ2 = idxZ2 + repmat([0  0 0  0 1 -1]',numel(idxZ),1);
  case 18
  %  crlEEG.disp('Computing 18-connectivity');
    idxX2 = idxX2 + repmat([-1 -1 -1 -1 -1  0  0  0  0  0  0  0  0  1  1  1  1  1]',numel(idxX),1);
    idxY2 = idxY2 + repmat([-1  1  0  0  0 -1 -1 -1  0  0  1  1  1 -1  1  0  0  0]',numel(idxY),1);
    idxZ2 = idxZ2 + repmat([ 0  0 -1  1  0 -1  0  1 -1  1 -1  0  1  0  0 -1  1  0]',numel(idxZ),1);
  case 26
  %  crlEEG.disp('Computing 26-connectivity');
    idxX2 = idxX2 + repmat([-1 -1 -1 -1 -1 -1 -1 -1 -1  0  0  0  0  0  0  0  0  1  1  1  1  1  1  1  1  1]',numel(idxX),1);
    idxY2 = idxY2 + repmat([-1 -1 -1  0  0  0  1  1  1 -1 -1 -1  0  0  1  1  1 -1 -1 -1  0  0  0  1  1  1]',numel(idxY),1);
    idxZ2 = idxZ2 + repmat([-1  0  1 -1  0  1 -1  0  1 -1  0  1 -1  1 -1  0  1 -1  0  1 -1  0  1 -1  0  1]',numel(idxZ),1);
  otherwise
  %  crlEEG.disp(['Computing connectivity in a radius of ' num2str(conSize)]);
    [Xoff Yoff Zoff] = ndgrid(-conSize:conSize,-conSize:conSize,-conSize:conSize);
    test = (Xoff==0)&(Yoff==0)&(Zoff==0);
    Xoff = Xoff(~test);
    Yoff = Yoff(~test);
    Zoff = Zoff(~test);
    idxX2 = idxX2 + repmat(Xoff,numel(idxX),1);
    idxY2 = idxY2 + repmat(Yoff,numel(idxY),1);
    idxZ2 = idxZ2 + repmat(Zoff,numel(idxZ),1);
end

% Trim Those that Fall Outside the Image Volume
%crlEEG.disp('Trimming to retain only neighbors within volume');
Q = ( ( idxX2<1 ) | ( idxX2>SpaceSize(1) ) | ( idxY2<1 ) | ( idxY2>SpaceSize(2) ) | ( idxZ2<1 ) | ( idxZ2>SpaceSize(3) ) );
idxX2 = idxX2(~Q); idxY2 = idxY2(~Q); idxZ2 = idxZ2(~Q);

%idxX2(Q)  = []; idxY2(Q)  = []; idxZ2(Q)  = [];

% Column and Row Indexes Into Sparse matrix
%crlEEG.disp('Finding column indices');
colIdx    = sub2ind(SpaceSize,idxX2,idxY2,idxZ2);

%crlEEG.disp('Finding row indices');
rowIdx = 1:prod(SpaceSize);
rowIdx = kron(rowIdx(:),ones(conSize,1));
rowIdx = rowIdx(~Q);

if nargout ==1
 % crlEEG.disp('Constructing sparse connectivity matrix');
  varargout{1} = sparse(rowIdx,colIdx,ones(size(colIdx)),prod(SpaceSize),prod(SpaceSize));
elseif nargout ==2
  varargout{1} = rowIdx;
  varargout{2} = colIdx;
end;

crlEEG.disp('Completed Computation of Connectivity');
end


