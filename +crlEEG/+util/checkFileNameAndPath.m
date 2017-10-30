function [fName, fPath] = checkFileNameAndPath(varargin)
% DEPRECATED FUNCTION STUB

warning('crlEEG.util.checkFileNameAndPath is deprecated. Use crlEEG.fileIO version instead');

[fName,fPath] = crlEEG.fileio.checkFileNameAndPath(varargin{:});

end
