function outStruct = preBlockPost(fullFilePath,varargin)
% General batch processing function for mouse EEG
%
% Performs a combination of pre-processing, block processing, and
% post-processing of EEG files.
%
% Inputs
% ------
%   fullFilePath : Full path (absolute or relative) to the file to be
%                   processed.
%
% Param-Value Inputs
% ------------------
%    'preFunc' : Function handle for preprocessing. Needs to take a single 
%                  crlEEG.EEG object as an input
%  'blockFunc' : Function handle for block processing. Needs to take a
%                  single crlEEG.EEG object as an input, and return a 
%                  single structure as the output. See help for
%                  crlEEG.EEG.blockProcess for more information.
%  'blockSize' : Size of blocks (in seconds) that the block processing
%                   function will be applied to.
%   'postFunc' : Function handle for post-processing. Needs to take the
%                   output structure from blockFunc as input, and return
%                   another single structure as the output.

%% Input Parsing
defaultPreFunc = @crlEEG.batchProcess.func.defaultEEGPreprocessingFunc;
defaultBlockFunc = @crlEEG.batchProcess.func.meanBlockPSD;

p = inputParser;
p.KeepUnmatched = true;
p.addRequired('fullFilePath',@(x) exist(x,'file'));
p.addParameter('preFunc',defaultPreFunc,@(x) isa(x,'function_handle'));
p.addParameter('blockFunc',defaultBlockFunc,@(x) isa(x,'function_handle'));
p.addParameter('postFunc',[],@(x) isa(x,'function_handle'));
p.parse(fullFilePath,varargin{:});

%% Save name and path separately.
[path,name,ext] = fileparts(fullFilePath);
outStruct.fName = [name ext];
outStruct.fPath = path;

%% Read the EEG File
EEG = crlEEG.EEG(crlEEG.readFile(fullFilePath));

%% Run Pre-Processing
if ~isempty(p.Results.preFunc)
  disp(['  Running preprocessing function']);
  EEG = p.Results.preFunc(EEG);
end;
%outStruct.EEG = EEG;

%% Run Block Processing
if ~isempty(p.Results.blockFunc)
  disp(['  Running block processing function']);
  resultStruct = EEG.blockProcess(p.Results.blockFunc,p.Unmatched,'outputType','[]');
  % Assign Structure Fields to the Output
  f = fields(resultStruct);
  for i = 1:numel(f)
    outStruct.(f{i}) = resultStruct.(f{i});
  end;
end;

%% Run Post-Processing
if ~isempty(p.Results.postFunc)
  disp(['  Running post processing function']);
  outStruct = p.Results.postFunc(resultStruct);
end;

end
  

