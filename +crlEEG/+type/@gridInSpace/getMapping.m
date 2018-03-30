function mapOut = getMapping(gridIn,gridOut,mapType)
% Compute the mapping matrix between two spatial grids
%
% function mapOut = getMapping(gridIn,gridOut)
%
% Get linear mapping from one cnlGridSpace to another. 
%
%
% This should be expanded to include both tent and nearest neighbor
% mappings
%
% Written By: Damon Hyde
% Part of the cnlEEG Project
% 2009-2017
%


% Check that both objects are crlEEG.typegridInSpace objects
if ~(isa(gridIn,'crlEEG.type.gridInSpace')&&isa(gridOut,'crlEEG.type.gridInSpace'))
  error('gridIn and gridOut must be of class cnlGridSpace');
end

% Set default mapping type
if ~exist('mapType','var'), mapType = 'tent'; end;

% Check To Make Sure Bounding Boxes of Node Centered Grids Match.
%
% This is only done because of the way the underlying crlEEG.typegrid
% object is being used to construct the mappings. Ideally this would be
% implemented in a more generalized fashion, to allow mapping between
% arbitrary spatial grids, and include either NaN or ZERO values for those
% points outside the source volume.
%
boxIn  = gridIn.getAlternateGrid('node').getBoundingBox;
boxOut = gridOut.getAlternateGrid('node').getBoundingBox;

if ~( all(all(round(10*boxIn)==round(10*boxOut)))|| ...
      all(all(floor(10*boxIn)==floor(10*boxOut)))|| ...
      all(all( ceil(10*boxIn)== ceil(10*boxOut))) )
  
  error(['Bounding Boxes don''t match.  Currently maps are only available '...
         'between spaces with matching bounding boxes']);
end;

% Get Mapping
mapOut = getMapping@crlEEG.typegrid(gridIn,gridOut,mapType);

end