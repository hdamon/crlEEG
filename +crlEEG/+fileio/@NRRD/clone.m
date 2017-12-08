function objOut = clone(obj,fname,fpath)
% function objOut = clone(obj,fname,fpath)
%
% Uses the abilities of matlab.mixin.Copyable to create a copy of a
% crlEEG.fileio.NRRD object.  Does both a shallow copy of the object, and a
% deep copy of both the header and data files.
%
% Written By: Damon Hyde
% Last Edited: March 10, 2016
% Part of the cnlEEG Project
%

% Only a path provided.
if exist('fname','var')&&exist(fname,'dir')&&~exist('fpath','dir')
  fpath = fname;
  fname = [];
end;

needsFName = ~exist('fname','var')||isempty(fname);
needsFPath = ~exist('fpath','var')||isempty(fpath);

[path,name,~] = fileparts(tempname());
if (needsFName && needsFPath)
  fname = [name '.nrrd'];
  fpath = path;
elseif needsFName
  fname = [name '.nrrd'];
elseif needsFPath
  fpath = './';
end;

% Read data if not already available
if ~obj.hasData&(obj.existsOnDisk)
  obj.readData;
end;

% Construct a fresh crlEEG.fileio.NRRD
objOut = copy(obj); % First copy the NRRD

% Cloned NRRDs are by default write-capable
objOut.readOnly = false;

% Change file names
objOut.fname = fname;
objOut.fpath = fpath;

end