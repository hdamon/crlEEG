function EEGOut = extractEpochAroundEvent(EEGIn,EVENT,preTime,postTime)
% Extract an epoch from an EEG around a specific event
%
% Inputs
% ------
%    EEGIn : crlEEG.EEG object to extract the epoch from
%    EVENT : crlEEG.event object to 
%  preTime : Time in seconds to extract before event.
% postTime : Time in seconds to extract after event.
%
% Outputs
% -------
%   EEGOut : crlEEG.EEG object with the extracted epoch
%             This will have a single EVENT that corresponds to the
%
% Part of the crlEEG project
% 2009-2018
%

% Event latency is in samples
latency = round(EVENT.latency);

% Number of samples before/after event to extract
nPre  = floor(preTime*EEGIn.sampleRate);
nPost = floor(postTime*EEGIn.sampleRate);

% Specific Samples to Extract
idxOut = (latency-nPre):(latency+nPost);

% Window the EEG.
EEGOut = EEGIn(idxOut,:);

% Modify Event Latency to be Consistent with Epoch
EVENT.latency = nPre+1;
EEGOut.EVENTS = EVENT;

% Modify the Timings to center on the event.
setStartTime(EEGOut,-preTime);

%xvals = -preTime:(1/EEGIn.sampleRate):postTime;
%EEGOut.xvals = xvals;

end
