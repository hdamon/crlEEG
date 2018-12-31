function outStruct = singleFile(fNameIn,varargin)
% Generalized Batch Processing of Single Files
%
% outStruct = crlEEG.batchProcess.singleFile(fNameIn,fPathIn,varargin)
%
% Inputs
% ------
%   fNameIn : Filename
%   fPathIn : Path to file (optional)
%
% Param-Value Inputs
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
% Output
% ------
%    outputStruct : Structure or object containing fields that have been
%                     concatenated across blocks.
%                   NOTE: If processing fails, the function returns the
%                         MException object that was thrown by the error.
%
% Processing Pipeline:
% ---------
%  1) Read File
%  2) Restrict file to listed channel(s)
%  3) Run a preprocessing function (if provided)
%  4) Use crlEEG.EEG.blockProcess to process EEG in blocks and generate the
%       output object/structure.
%
% DEFAULT Processing Function:
% ----------------------------
%  If no value is provided for 'blockFunc', this function will apply a
%  default processing function that performs the following functions:
%
%     a) Wavelet Decomposition
%     b) Interpolate to Output Frequencies
%     c) Normalize Per Timepoint
%
% This function then creates an output structure with several fields:
%     outStruct.decomp : MatTSA.tfDecomp object with one column per block
%              .normDecomp : Same as above, but normalized per-timepoint before
%                               averaging across the block;
%              .totPow : Total power at all (original) timepoints.
%              .nSamples : Number of samples used in the computation of the
%                           mean value. Compare to the length of .totPow to
%                           determine the fraction of timepoints used (A
%                           rough measure of data quality).
%
%

%% Cleanup Function
% This makes sure that when exiting the function, you always return to the
% same directory you started in.
%
retDir = pwd;
Cleaner = onCleanup(@() cd(retDir));

%% Input Parsing
% Not sure why this isn't an intrinsic part of the inputParser object
allFields = {'batchFuncHandle','skipIfProcessed','loadIfSkipped',...
             'returnEmpty','saveOutput','outputPostfix','fPathOut'};

p = inputParser;
p.KeepUnmatched = true;
p.addRequired('fNameIn',@(x) ischar(x));
p.addOptional('fPathIn',[],@(x) ischar(x)&&~ismember(x,allFields));
p.addParameter('batchFuncHandle',[],@(x) isempty(x)||isa(x,'function_handle'));
p.addParameter('skipIfProcessed', false , @(x) isscalar(x)&&islogical(x) );
p.addParameter('loadIfSkipped'  , false , @(x) isscalar(x)&&islogical(x) );
p.addParameter('returnEmpty'    , false , @(x) isscalar(x)&&islogical(x) );
p.addParameter('saveOutput'     , false , @(x) isscalar(x)&&islogical(x) );
p.addParameter('outputPostfix','_Processed',@(x) ischar(x));
p.addParameter('postLoadFcn',[],@(x) isa(x,'function_handle'));
p.addParameter('fPathOut',[],@(x) exist(x,'dir'));
p.parse(fNameIn,varargin{:});

fNameIn = p.Results.fNameIn;
fPathIn = p.Results.fPathIn;

%% Set Full Input Location
fullInputPath = fullfile(p.Results.fPathIn,p.Results.fNameIn);

%% Get Full Output Location
[~,tmpName,~] = fileparts(fNameIn);
fNameOut = [tmpName p.Results.outputPostfix '.mat'];
fPathOut = p.Results.fPathOut;
if isempty(fPathOut)
  % By default, save in the same location as the data file
  fPathOut = fPathIn;
end
fullOutputPath = fullfile(fPathOut,fNameOut);

%% If the output file already exists, and skipIfProcessed is true
if p.Results.skipIfProcessed&&exist(fullOutputPath,'file')
  disp(['Processing already completed for file: ' newline ...
    '     ' fullInputPath]);
  if p.Results.loadIfSkipped
    % Load the precomputed output, if desired.
    load(fullOutputPath);
    % Check that the correct output is available
    assert(logical(exist('outStruct','var')),...
      ['The file: ' fNameOut ' does not provide the required variable ''outStruct''.']);
  else
    % Return an empty output
    outStruct = [];
  end
  if ~isempty(p.Results.postLoadFcn)
    outStruct = p.Results.postLoadFcn(outStruct);
  end;
  return;
end

%% Start the Actual Processing
disp(['Beginning Batch Processing for File: ' newline ...
      '      ' fullInputPath]);

%% Run the batch processing function.
if ~isempty(p.Results.batchFuncHandle)
  outStruct = p.Results.batchFuncHandle(fullInputPath);
else
  outStruct = [];
end

%% Save output, if desired
if p.Results.saveOutput
  cd(fPathOut);
  save(fNameOut,'-v7.3','outStruct');
end

if ~isempty(p.Results.postLoadFcn)
  outStruct = p.Results.postLoadFcn(outStruct);
end

disp(['Completed Batch Processing']);
end
