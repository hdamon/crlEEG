function out =  timefrequency(tseries,varargin)
%% Compute time-frequency decompositions of crlEEG.type.timeseries objects
%
% Inputs
% ------
%   tseries : A crlEEG.type.timeseries object to decompose
%   method  : Type of decomposition to compute
%               Valid values:
%                 'multitaper'  : Use pmtm for multitaper decomposition
%                 'spectrogram' : Use Matlab's spectrogram functionality.
%                 'fft'         : Use a fast fourier transform
%                 'eeglab'      : Use EEGlab's timefreq() function
%
% 'fft' and 'eeglab' are likely to be deprecated soon.
%
% Parameters for MultiTaper
% -------------------------
%    windowSize : Size of the time window (DEFAULT: 1024)
%            nw : Multitaper Parameter (DEFAULT: 3)
%     FFTLength : Length of FFT (DEFAULT: 1024)
%         freqs : Frequencies to compute decomposition at.
%       nOutput : Number of times to output at
%                   If nOutput<=1: Treated as a fraction of the total
%                                   samples
%                   Otherwise: Treated as an explicit number of samples
%
% MULTITAPER REQUIRES THE SIGNAL PROCESSING TOOLBOX
%
% Parameters for Spectrogram:
% ---------------------------
%   'window' :  Window to use for FFT computation 
%                 DEFAULT: hamming(2048)
%  'overlap' :  Number of samples to overlap the windows
%                 DEFAULT: 2038
%    'freqs' :  Vector defining the frequencies of the output
%
% Output
% ------
%    out.tfX : Time-frequency decomposition values
%    out.tx  : Times (in seconds) the decomposition was computed at
%    out.fx  : Frequencies the decomposition was computed at
%
% Part of the crlEEG project
% 2009-2018
%

%% Input Parsing
validTypes = {'multitaper' 'eeglab' 'spectrogram'};
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('tseries',@(x) isa(x,'crlEEG.type.timeseries'));
p.addOptional('method','multitaper',@(x) ismember(x,validTypes));
p.parse(tseries,varargin{:});

switch p.Results.method
  case 'fft'
    out = fft(tseries,p.Unmatched);
  case 'spectrogram'
    out = runspectrogram(tseries,p.Unmatched);
  case 'multitaper'
    out = multitaper(tseries,p.Unmatched);
  case 'eeglab'
    out = eeglab(tseries,p.Unmatched);
  otherwise
    error('Unknown decomposition type');
end;

end

%% Spectrogram Based Decomposition
function out = runspectrogram(tseries,varargin)
% Compute a time-frequency decomposition using Matlab's spectrogram
% 
% function out = runspectrogram(tseries,varargin)
%
% Inputs
% ------
%   tseries : crlEEG.type.timeseries object
%
% Param-Value Pairs
% --------
%   'window' :  Window to use for FFT computation 
%                 DEFAULT: hamming(2048)
%  'overlap' :  Number of samples to overlap the windows
%                 DEFAULT: 2038
%  'freqs'   :  Vector defining the frequencies of the output
%  
% REQUIRES THE SIGNAL PROCESSING TOOLBOX
% 

%% Input Parsing
p = inputParser;
p.addParameter('window',hamming(2048));
p.addParameter('overlap',2038); % every 10th sample
p.addParameter('freqs',linspace(0,50,100));
p.parse(varargin{:});

%% Computation
dataChans = logical(tseries.isChannelType('data'));
data = tseries.data(:,dataChans);
for i = 1:size(data,2)  
  [s(:,:,i),f,t] = spectrogram(data(:,i),...
    p.Results.window,...
    p.Results.overlap,...
    p.Results.freqs,...
    tseries.sampleRate);
end;

%% Output Parsing
out = timeFrequencyDecomposition('spectrogram',s,t+tseries.xrange(1),f,tseries.labels(dataChans));
out.params = varargin;

end

%% Multi-taper time-frequency decomposition using pmtm
function out = multitaper(tseries,varargin)
% Compute a time-frequency decomposition using Thompson's Multitaper
%
%  out = multitaper(tseries,varargin)
%
% Inputs
% ------
%   tseries : A crlEEG.type.timeseries object
%
% Param-Value Inputs
% ------------------
%    windowSize : Size of the time window (DEFAULT: 1024)
%            nw : Multitaper Parameter (DEFAULT: 3)
%     FFTLength : Length of FFT (DEFAULT: 1024)
%         freqs : Frequencies to compute decomposition at.
%       nOutput : Number of times to output at
%                   If nOutput<=1: Treated as a fraction of the total
%                                   samples
%                   Otherwise: Treated as an explicit number of samples
%
% REQUIRES THE SIGNAL PROCESSING TOOLBOX
%
% 

%% Imports
import crlEEG.util.validation.isScalarNumeric;

%% Input Parsing
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('tseries',@(x) isa(x,'crlEEG.type.timeseries'));
p.addParameter('windowSize',1024,@isScalarNumeric);
p.addParameter(        'nw',   3,@isScalarNumeric);
p.addParameter( 'FFTlength',1024,@isScalarNumeric);
p.addParameter('freqs',[]);
p.addParameter(   'nOutput',   1,@isScalarNumeric);
p.parse(tseries,varargin{:});

%% Execute

% Determine number of outputs
winSize = 2^nextpow2(p.Results.windowSize);
if p.Results.nOutput<=1
  % As a fraction of input length
  nOutput = p.Results.nOutput*size(tseries,1);
else
  % As an explicit number of samples
  nOutput = p.Results.nOutput;
end;
nOutput = floor(nOutput);

% Find window centers
winCenters = linspace(winSize/2,size(tseries,1)-winSize/2,nOutput);
winCenters = ceil(winCenters);

% Eliminate Repeats
winCenters = unique(winCenters);

times = tseries.xrange(1) + (winCenters-1)/tseries.sampleRate;

% Get indices for each window
indices = repmat([-winSize/2+1:winSize/2]',[1 length(winCenters)]);
indices = indices + repmat(winCenters,[size(indices,1) 1]);

% Rearrange data matrix

doChans = tseries.getChannelsByType('data');

for idxChan = 1:numel(doChans)
  disp(['Computing decomposition for channel #' num2str(idxChan)]);
  tseriesData = tseries.data(:,idxChan);
  tseriesData = tseriesData(indices);
  
  % Select frequencies, either using the length of the FFT, or a specific
  % list of desired frequencies.
  f = p.Results.FFTlength;
  if ~isempty(p.Results.freqs)
    f = p.Results.freqs;
  end;
  
  % Compute multi-taper
  [pxx,fx] = pmtm(tseriesData,p.Results.nw,f,tseries.sampleRate);
  
  pxxOut(:,:,idxChan) = pxx;
  
end;

out = timeFrequencyDecomposition('multitaper',pxxOut,times,fx,tseries.labels(doChans));
out.params.windowSize = winSize;
out.params.nOutput = nOutput;
out.params.FFTlength = p.Results.FFTlength;
out.params.nw = p.Results.nw;

%out.type = 'multitaper';
%out.tfX = pxx;
%out.fx = fx;
%out.tx = times;

end

%% Fast Fourier Transform based decomposition
function out = fft(tseries,varargin)
% Compute time-frequency decomposition using the FFT
%
% This functionality is likely unnecessary, as the spectrogram method above
% uses the FFT.
%
error('NOT COMPLETE');
import crlEEG.util.validation.*;
taperTypes = {'hanning' 'hamming' 'blackmanharris' 'none'};
p = inputParser;
p.addRequired('tseries',@(x) isa(x,'crlEEG.type.timeseries'));
p.addParameter('windowSize',[],@isScalarNumeric);
p.addParameter('ffttaper','hanning',@(x) ismember(x,taperTypes));
p.addParameter('fftlength',1024,@isScalarNumeric);
p.parse(tseries,varargin{:});

windowSize = p.Results.windowSize;
if isempty(windowSize)
  windowSize = size(tseries,1);
end;

% Get output frequencies
nFreqs = windowSize/2;

end

%% Use EEGLab's timefreq() function to compute the decomposition
function out = eeglab(tseries,varargin)
%% Use EEGLab's timefreq function.
%
% MAY NOT SUPPORT ALL FUNCTIONALITY IN timefreq()
%
% THIS IS LIKELY DEPRECATED BECAUSE FUNCTIONALITY IS DUPLICATED BY THE
% SPECTROGRAM FUNCTION ABOVE
%

import crlEEG.util.validation.*;
p = inputParser;
p.addRequired('tseries',@(x) isa(x,'crlEEG.type.timeseries'));
p.addParameter('nOutput', 1000, @isScalarNumeric);
p.addParameter('windowSize',1024, @isScalarNumeric);
p.addParameter('tlimits',[],@(x) isNumericVector(x,2) );
p.addParameter('timesout',[]);
p.addParameter('detrend','off',@ischar);
p.addParameter('type','phasecoher',@ischar);
p.addParameter('cycles',0, @(x) isScalarNumeric(x)||isNumericVector(x,2));
p.addParameter('verbose','on',@ischar);
p.addParameter('padratio',1,@isScalarNumeric);
p.addParameter('freqs',[0 50],@(x) isNumericVector(x,2) );
p.addParameter('freqscale','linear',@ischar);
p.addParameter('nfreqs',[]);
p.addParameter('timeStretchMarks',[]);
p.addParameter('timeStretchRefs',[]);
p.parse(tseries,varargin{:});


g.winsize = 2^nextpow2(p.Results.windowSize);
if p.Results.nOutput<=1
  % As a fraction of input length
  nOutput = p.Results.nOutput*size(tseries,1);
else
  % As an explicit number of samples
  nOutput = p.Results.nOutput;
end;
nOutput = floor(nOutput);

tmioutopt = { 'ntimesout' nOutput };
g.srate = tseries.sampleRate;

if isempty(p.Results.tlimits)
  g.tlimits = [1 size(tseries,1)];
else
  g.tlimits = p.Results.tlimits;
end;

g.detrend   =  p.Results.detrend;
g.type      = p.Results.type;
g.tlimits   = 1000*tseries.xrange; % EEGLab wants things in milliseconds
g.timesout  = 1000*p.Results.timesout;
g.cycles    = p.Results.cycles;
g.verbose   = p.Results.verbose;
g.padratio  = p.Results.padratio;
g.freqs     = p.Results.freqs;
g.freqscale = p.Results.freqscale;
g.nfreqs    = p.Results.nfreqs;
g.timeStretchMarks = p.Results.timeStretchMarks;
g.timeStretchRefs  = p.Results.timeStretchRefs;
timefreqopts = cell(0);

[alltfX freqs timesout R] = timefreq(tseries.data(:,1)', g.srate, tmioutopt{:}, ...
  'winsize', g.winsize, 'tlimits', g.tlimits, 'timesout', g.timesout', 'detrend', g.detrend, ...
  'itctype', g.type, 'wavelet', g.cycles, 'verbose', g.verbose, ...
  'padratio', g.padratio, 'freqs', g.freqs, 'freqscale', g.freqscale, ...
  'nfreqs', g.nfreqs, 'timestretch', {g.timeStretchMarks', g.timeStretchRefs}, timefreqopts{:});

out = timeFrequencyDecomposition('eeglab',alltfX,timesout/tseries.sampleRate,freqs);

%out.type = 'eeglab';
%out.tfX = alltfX;
%out.fx = freqs;
%out.tx = timesout/tseries.sampleRate;

end
