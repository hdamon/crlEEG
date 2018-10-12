function EEG = defaultEEGPreprocessingFunc(EEG,varargin)
% A General Preprocessing Function for Most Mouse EEG
%
% EEG = defaultEEGPreprocessingFunc(EEG,varargin)
%
% This function is written to be paired with generalBlockFunction() when
% calling blockProcessAll()
%
% Inputs
% ------
%    EEG : crlEEG.EEG object to preprocess
%
% Param-Value Inputs
% ------------------
%   'limitRecordingLength' : Total recording length (in seconds) to limit
%                              the processing to. Additional timepoints are
%                              simply discarded.
%            'channelName' : Name of the channel or channels to analyze. Can either
%                              be a single channel name in a character string, or a
%                              cell array of names.
%                                DEFAULT: ':' (Operates on all channels)
%   'runArtifactRejection' : Flag to enable threshold based artifact
%                              rejection.
%
% Param-Value Inputs for removeArtifactsByThrehold()
% ------------------
%  artifactThreshold: artifactThreshold to apply to EEG absolute magnitude in determining
%               artifacts.
%                 DEFAULT: 350e-6 (300uV)
%  excludeTime : Time window (in seconds) to remove (set to zero) around
%                   detected artifacts.
%                 DEFAULT: 200e-3 (200ms)
%  includeTime : Time window (in seconds) around artifacts to exclude from
%                   further analysis
%                 DEFAULT: 10  (10s)

%% Input Parsing
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('EEG',@(x) isa(x,'crlEEG.EEG'));
p.addParameter('limitRecordingLength',[]);
p.addParameter('runArtifactRejection',false);
p.addParameter('channelName','EEG');
p.parse(EEG,varargin{:});

if ~isempty(p.Results.limitRecordingLength)
  disp(['    Limiting recording length']);
  % Limit total length of the recording to be considered
  nSamples = round(p.Results.limitRecordingLength*EEG.sampleRate);
  if nSamples>size(EEG,'time')
    nSamples = size(EEG,'time');
  end;
  EEG = EEG(1:nSamples,:);
end

%% Restrict Channel List
EEG = EEG(:,p.Results.channelName);

if p.Results.runArtifactRejection
  disp(['    Running artifact rejection']);
  % Reject artifacts by threshold
  %
  % The way the artifact rejection is handled here is a bit
  % undergeneralized. This should be modified so that there's a general
  % "preprocessing" component that can be selected and specified.
  EEG = removeArtifactsByThreshold(EEG,p.Unmatched,'operateInPlace',true,'channelName',p.Results.channelName);
end

end