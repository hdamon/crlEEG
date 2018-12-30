function outStruct = allFilesInDirectory(rootDir,executeFcn,varargin)
% Recursively process all files of a particular type within a directory.
%
% outStruct = crlEEG.batchProcess.allFilesInDirectory(rootDir,varargin)
%
% WARNING: This function is likely to take a LONG time to run, depending on
%           how many EDF files there are. It's just going to process all of
%           them!
%
% Inputs
% ------
%   rootDir : Directory to start the search in.
%
% Param-Value Inputs
% ------------------
%  'fileExtensions' : String or cellstring array of search values to send
%                       to  dir() in finding files to process.
%                         DEFAULT: {'*.edf','*.EDF'}
%  'recurseSubdirs' : Flag enabling recursion through subdirectories when
%                       processing. If set to true, will descend into each
%                       subdirectory and attempt to process any EDF files
%                       present there. 
%                         DEFAULT: false
%
% Optional Inputs
% ---------------
%  varargin : All unmatched varargin values are sent to
%               blockProcessSingleEEGFile. Available inputs to that
%               function are duplicated below. See
%               blockProcessSingleEEGFile for more information.
%
% Param-Value Inputs From blockProcessSingleEEGFile (As of 10/11/2018)
% ------------------
%   Reproduced here for simplicity.
% ------------------
%        'blockSize' : Block size (in seconds) to average over.
%                          DEFAULT: 30 seconds
%      'channelName' : Name of the channel or channels to analyze. Can either
%                        be a single channel name in a character string, or a
%                        cell array of names.
%                          DEFAULT: 'EEG'
%  'batchFuncHandle' : Function handle for preprocessing of the full EEG signal
%                        prior to block processing. The handle should
%                        take a single absolute or relative filepath as input, and
%                        return a single structure as the output. The function
%                        can use additional parameters, but these should
%                        be defined in the call constructing the function
%                        handle.
%                          DEFAULT: [] (No preprocessing)
%  'skipIfProcessed' : If set to true, the function will skip processing
%                         the file if the output is already present.
%                          DEFAULT: false
%    'loadIfSkipped' : If set to true, when skipping file processing,
%                         the function will try to load and return the
%                         output. If set to false, outStruct will return an
%                         empty array.
%                           DEFAULT: false
%      'returnEmpty' : Flag to enable/disable broadcasting returned values. If
%                          set to true, the function will return the block
%                          processed outputStruct. If false,
%                          blockProcessSingleEEGFile will return an empty
%                          array. This can be used when processing multiple
%                          files to prevent running out of memory trying to
%                          store all the results.
%                            DEFAULT: false (Returns output)
%       'saveOutput' : Flag to enable automated saving of output. When
%                          true, the output structure will be saved to a
%                          .MAT file (v7.3) with a filename as defined
%                          below.
%                            DEFAULT: false
%    'outputPostfix' : Postfix to append to fNameIn when saving. The output
%                          file will be named [fNameIn outpuPosFix '.mat']
%                            DEFAULT: '_Processed'
%         'fPathOut' : Path to save the output file to. If not provided and
%                          file output is requested, the output file will
%                          be saved in the same directory as the source
%                          data file.
%                            DEFAULT: []
%
%
% Output
% ------
%  outStruct : A structure with fields:
%                      dir  : Directory being processed
%             processedEDFs : Output from processing any EDFs in that
%                               directory
%                   subDirs : Similar structures for all subdirectories
%                               (if 'recurseSubdirs' is set to true)
%
%

%% CleanUp Function
retDir = pwd;
Cleaner = onCleanup(@(x) cd(retDir));

%% Input Parsing
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('rootDir',@(x) exist(x,'dir'));
%p.addRequired('executeFcn',@(x) isempty(x)||isa(x,'function_handle'));
p.addParameter('recurseSubdirs',false);
p.parse(rootDir,executeFcn,varargin{:});

%% Get List of Files/Directories
outStruct.dir = rootDir;
cd(rootDir);

% So things don't run TOTALLY rampant.
% -- Only want to descend, and prevent infinite recursion
d = dir;
[~,keep] = setdiff({d.name},{'.','..'});
d = d(keep);

%% Process EDFs is there are any.
outStruct.processedFiles = processAllIndividualFiles(pwd,executeFcn,p.Unmatched);

%% Find subdirectories and recurse through them.
if p.Results.recurseSubdirs
  dirFlag = [d.isdir];
  d = d(dirFlag);
  
  for i = 1:numel(d)
    % Recurse across subdirectories
    subDir = fullfile(d(i).folder,d(i).name);    
    outStruct.subDirs(i) = crlEEG.batchProcess.allFilesInDirectory(subDir,varargin{:});
  end
  
  % Ensure the field exists, for consistency in array construction.
  if ~isfield(outStruct,'subDirs')
    outStruct.subDirs = [];
  end
else
  outStruct.subDirs = [];
end

end

function outStruct = processAllIndividualFiles(dataDir,varargin)
% Block process all EDFs in a particular directory.
%
% miceOut = processAllIndividualFiles(dataDir)
%
% Inputs
% ------
%  dataDir : Directory of data
%
% Param-Value Inputs
% ------------------
%  'fileExtensions' : 
%
% Optional Inputs
% ---------------
%  varargin : Additional varargin values are sent directly to
%               blockProcessSingleEEGFile. See that function's help for
%               more details of available options.
%
% Output
% ------
%  outStruct : An array of structures or objects of size 1 X nFiles, where
%               nFiles is the number of EDF files in the directory.
%
%
%

%% Cleanup Function
% This makes sure that when exiting the function, you always return to the
% same directory you started in.
%
retDir = pwd;
Cleaner = onCleanup(@() cd(retDir));

%% Input Parsing
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('dataDir',@(x) exist(x,'dir'));
p.addParameter('fileExtensions',{'*.edf','*.EDF'});
p.parse(dataDir,varargin{:});

fExt = p.Results.fileExtensions;
if ischar(fExt), fExt = {fExt}; end

%% Loop across files in the data directory
files = cellfun(@(x) dir(fullfile(dataDir,x)),fExt,'UniformOutput',false);
files = [files{:}];

for idxF = 1:numel(files)
  fname = files(idxF).name;
  fpath = files(idxF).folder;
  tmpOut = crlEEG.batchProcess.singleFile(fname,fpath,varargin{:});
  
  if isa(tmpOut,'MException')
    % Raise the command line if an exception is returned.
    keyboard;
  elseif ~isempty(tmpOut)
    % If blockProcessSingelEEGFile returns an empty array, this will
    % ultimately just leave an empty structure in the appropriate position,
    % unless it's the last file processed.
    outStruct(1,idxF) = tmpOut;
  end   
end
  
% Return an empty array if nothing was found/done.
if ~exist('outStruct','var'), outStruct = []; end

end

