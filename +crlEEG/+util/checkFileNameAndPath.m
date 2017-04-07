function [fName fPath] = checkFileNameAndPath(fName,fPath)
% Provides validation of file names and paths
%
% 
%
% Written By: Damon Hyde
% Part of the crlEEG Project
% 2009-2017
%
 
switch nargin
  case 0
    % No input provided. This will return
    fName = [];
    fPath = [];
  case 1
    [path,name,ext] = fileparts(fName);
    fName = [name ext];
    fPath = path;
    if isempty(fPath), fPath = './'; end;
  case 2
    [path,name,ext] = fileparts(fName);
    if ~isempty(path)
      error('Define path in either fName or fPath, but not both');
    end
    fName = [name ext];
    fPath = path;
end

% Generate temporary filenames and paths, as needed
if isempty(fName)||isempty(fPath)
  [tmpPath,tmpName] = fileparts(tempname());

  if isempty(fPath)
    % When no path is provided, default to the current directory if given a
    % filename, and the temporary directory if no name is provided.
    if isempty(fName), fPath = tmpPath; 
    else               fPath = './';
    end
  end;
  
  if isempty(fName), fName = tmpName; end;
end

end