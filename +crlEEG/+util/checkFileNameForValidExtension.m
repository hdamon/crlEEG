function [validatedName] = checkFileNameForValidExtension(fname,extensions)
% Check that filename has a valid extension
%
% function [validatedName] = checkForValidFileExtension(fname,extensions)
%
% If the filename lacks any extension, and appropriate one will be appended
% to it (primarily to add it in for temporary filenames).
%
% Written By: Damon Hyde
% Part of the crlEEG Project
% 2009-2017
%

if ~exist('extensions','var'), extensions = {}; end;

assert(ischar(fname),'Input filename must be a character string');
assert(iscellstr(extensions),'Extensions must be provided as a cell string');

if ~isempty(extensions)
  [fpath,~,ext] = fileparts(fname);
  assert(isempty(fpath),'Pass only the filename (without path) to checkFileNameForValidExtension()');
  if validatestring(ext,extensions)
    validatedName = fname;
  elseif isempty(ext)
    validatedName = [fname extensions{1}];
  else
    error(['Filename must have one of these extensions: ' extensions{:}]);
  end  
else
  validatedName = fname;
end;

end