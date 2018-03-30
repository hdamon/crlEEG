function mapOut = getMapping(gridIn,gridOut,mapType)
% function mapOut = getMapGridToGrid(gridIn,gridOut)
%
% Return a mapping from one crlEEG.typegrid object to another.
%
%
% Written By: Damon Hyde
% Part of the cnlEEG Project
% 2009-2017
%

% % Warning added (and then commented) Feb 2017
% warning(['This code is likely unstable, and any use of it should be '...
%          'carefully examined. You probably want a ' ...
%          'crlEEG.typegridOnSpace object, anyway']);

if ~(isa(gridIn,'crlEEG.typegrid')&&isa(gridOut,'crlEEG.typegrid'))
  error('gridIn and gridOut must be of class cnlGrid');
end

if ~exist('mapType','var'), mapType = 'tent'; end;

switch lower(mapType)
  case 'tent'
    mapOut = crlEEG.typegrid.getMapping_Tent(gridIn.sizes,gridOut.sizes);
  case 'nearest'
    error('Nearest neighbor resampling has not yet been implemented');
  otherwise
    error('Unknown resampling type');
end

end