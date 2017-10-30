function [validatedName] = checkFileNameForValidExtension(fname,extensions)
% Check that filename has a valid extension
%
% function [validatedName] = checkForValidFileExtension(fname,extensions)
%
% If the filename lacks any extension, and appropriate one will be appended
% to it (primarily to add it in for temporary filenames). 
%
% If fname does not have an extension, returns [fname extentions{1}]
%
% Inputs
% ------
%   fname:      Filename to check
%   extensions: Cell array of valid file extensions, with leading
%
% Outputs
% -------
%   validatedName: Filename with 
%
% Written By: Damon Hyde
% Part of the crlEEG Project
% 2009-2017
%

if ~exist('extensions','var'), extensions = {}; end;

assert(ischar(fname),'Input filename must be a character string');
assert(iscellstr(extensions),'Extensions must be provided as a cell string');

% Check for leading period in file extensions
for i = 1:numel(extensions)
  if ~isequal(extensions{i}(1),'.')
    extensions{i} = ['.' extensions{i}];
  end
end

if ~isempty(extensions)
  [fpath,~,ext] = fileparts(fname);
  assert(isempty(fpath),'Pass only the filename (without path) to checkFileNameForValidExtension()');
  if ismember(ext,extensions)
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