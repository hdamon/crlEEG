function fileOut = readFile(varargin)
% Generalized file reader for crlEEG
%
% function fileOut = readFile(varargin)
%
% Usage
% -----
%    f = crlEEG.readFile(fname)
%    f = crlEEG.readFile(fname,fpath)
%   
% Optional Param-Value Inputs
% ---------------------------
%   'readOnly' : If set true, file will be flagged as read only.
%                   DEFAULT: False
%
% Part of the crlEEG Project
% 2009-2018
%

  p = inputParser;
  p.KeepUnmatched = true;
  p.addOptional('fname',[],@(x) isempty(x)||ischar(x));
  p.addOptional('fpath',[],@(x) isempty(x)||ischar(x));        
  p.addParamValue('readOnly',false,@(x) islogical(x));
  p.parse(varargin{:});

[fName,fPath] = ...
  crlEEG.fileio.checkFileNameAndPath(p.Results.fname,p.Results.fpath);

[~,~,EXT] = fileparts(fName);

switch lower(EXT)
  case {'.nrrd','nhdr'}
    fileOut = crlEEG.fileio.NRRD(fName,fPath,...
                                'readonly',p.Results.readOnly,p.Unmatched);
  case '.edf'
    fileOut = crlEEG.fileio.EDF(fName,fPath,...
                                'readonly',p.Results.readOnly,p.Unmatched);
  case '.nii'
    fileOut = crlEEG.fileio.NIFTI(fName,fPath,...
                                'readonly',p.Results.readOnly,p.Unmatched);                              
  case '.ev2'
    fileOut = crlEEG.fileio.EV2(fName,fPath,...
                                'readonly',p.Results.readOnly,p.Unmatched);
  case '.eeg'
    fileOut = crlEEG.fileio.EEG(fName,fPath,...
                                'readonly',p.Results.readOnly,p.Unmatched);
  otherwise
    error('Unknown file extension');
end;  


end