function out =  timefrequency(tseries,varargin)
%% Compute time-frequency decompositions of crlEEG.type.data.timeseries objects
% 
% Inputs
% ------
%   tseries : A crlEEG.type.data.timeseries object to decompose
%   method  : Type of decomposition to compute
%               Valid values:
%                 'fft' : Use a fast fourier transform
%                 'multitaper' : Use pmtm for multitaper decomposition
%                 'eeglab' : Use EEGlab's timefreq() function
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
validTypes = {'multitaper' 'eeglab'};
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('tseries',@(x) isa(x,'crlEEG.type.data.timeseries'));
p.addOptional('method','multitaper',@(x) ismember(x,validTypes));
p.parse(tseries,varargin{:});

switch p.Results.method
  case 'fft'
    out = fft(tseries,p.Unmatched);
  case 'multitaper'
    out = multitaper(tseries,p.Unmatched);
  case 'eeglab'
    out = eeglab(tseries,p.Unmatched);
  otherwise
    error('Unknown decomposition type');
end;

end

%% Fast Fourier Transform based decomposition
function out = fft(tseries,varargin)
error('NOT COMPLETE');
import crlEEG.util.validation.*;
taperTypes = {'hanning' 'hamming' 'blackmanharris' 'none'};
p = inputParser;
p.addRequired('tseries',@(x) isa(x,'crlEEG.type.data.timeseries'));
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


function out = multitaper(tseries,varargin)
%% Multi-taper time-frequency decomposition using pmtm
%
% REQUIRES THE SIGNAL PROCESSING TOOLBOX
%

%% Imports
import crlEEG.util.validation.isScalarNumeric;

%% Input Parsing
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('tseries',@(x) isa(x,'crlEEG.type.data.timeseries'));
p.addParameter('windowSize',1024,@isScalarNumeric);
p.addParameter(        'nw',   3,@isScalarNumeric);
p.addParameter( 'FFTlength',1024,@isScalarNumeric);
p.addParameter(   'nOutput',   1,@isScalarNumeric);
p.parse(tseries,varargin{:});

%% Execute

% Determine number of outputs
winSize = 2^nextpow2(p.Results.windowSize);
if p.Results.nOutput<=1
  % As a fraction of input length
  nOutput = size(tseries,1)/p.Results.nOutput;
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

times = winCenters/tseries.sampleRate;

% Get indices for each window
indices = repmat([-winSize/2+1:winSize/2]',[1 length(winCenters)]);
indices = indices + repmat(winCenters,[size(indices,1) 1]);

% Rearrange data matrix
tseriesData = tseries.data;
tseriesData = tseriesData(indices);

% Compute multi-taper
[pxx,fx] = pmtm(tseriesData,p.Results.nw,p.Results.FFTlength,tseries.sampleRate);

out.type = 'multitaper';
out.tfX = pxx;
out.fx = fx;
out.tx = times;

end

%%
function out = eeglab(tseries,varargin)
%% Use EEGLab's timefreq function.
%
% MAY NOT SUPPORT ALL FUNCTIONALITY IN timefreq()
%

import crlEEG.util.validation.*;
p = inputParser;
p.addRequired('tseries',@(x) isa(x,'crlEEG.type.data.timeseries'));
p.addParameter('nOutput', 1000, @isScalarNumeric);
p.addParameter('windowSize',1024, @isScalarNumeric);
p.addParameter('tlimits',[],@(x) isNumericVector(x,2) );
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
  nOutput = size(tseries,1)/p.Results.nOutput;
else
  % As an explicit number of samples
  nOutput = p.Results.nOutput;
end;

tmioutopt = { 'ntimesout' nOutput };
g.srate = tseries.sampleRate;

if isempty(p.Results.tlimits)
  g.tlimits = [1 size(tseries,1)];
else
  g.tlimits = p.Results.tlimits;
end;

g.detrend  =  p.Results.detrend;
g.type      = p.Results.type;
g.cycles    = p.Results.cycles;
g.verbose   = p.Results.verbose;
g.padratio  = p.Results.padratio;
g.freqs     = p.Results.freqs;
g.freqscale = p.Results.freqscale;
g.nfreqs    = p.Results.nfreqs;
g.timeStretchMarks = p.Results.timeStretchMarks;
g.timeStretchRefs  = p.Results.timeStretchRefs;
timefreqopts = cell(0);

[alltfX freqs timesout R] = timefreq(tseries.data', g.srate, tmioutopt{:}, ...
  'winsize', g.winsize, 'tlimits', g.tlimits, 'detrend', g.detrend, ...
  'itctype', g.type, 'wavelet', g.cycles, 'verbose', g.verbose, ...
  'padratio', g.padratio, 'freqs', g.freqs, 'freqscale', g.freqscale, ...
  'nfreqs', g.nfreqs, 'timestretch', {g.timeStretchMarks', g.timeStretchRefs}, timefreqopts{:});

out.type = 'eeglab';
out.tfX = alltfX;
out.fx = freqs;
out.tx = timesout/tseries.sampleRate;

end
