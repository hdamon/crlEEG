function epochsOut = extractEpochsByName(EEG,lookForDescription,preTime,postTime)
% Return an array of epochs extracted by name.
%
% Inputs
% ------
%           EEG : crlEEG.type.EEG object to extract epochs from
% targetTrigger : Name of the events to look for
%       preTime : Time in seconds to window before trigger
%      postTime : Time in seconds to window after trigger
%
% Outputs
% -------
%  epochsOut : Array of crlEEG.type.EEG objects containing the requested
%               epochs.
%
% Part of the crlEEG Project
% 2009-2018
%

% Find Matching Events
tmpEvents = EEG.EVENTS('description',lookForDescription);
disp(['Found ' num2str(numel(tmpEvents)) ' events of description: ' lookForDescription]);

% Determine how many samples before/after each event are needed
preSamples  = ceil(EEG.sampleRate*preTime);
postSamples = ceil(EEG.sampleRate*postTime);

% Get an Epoch for Each Event
idxOut = 0;
epochsOut = crlEEG.type.EEG;
for i = 1:numel(tmpEvents)
  % Test that there are enough samples to get the requested window
  testPre   = tmpEvents(i).latency > preSamples; % Too close to the beginning
  testPost  = tmpEvents(i).latency < size(EEG,1)-postSamples; % Too close to the end
  if testPre && testPost
    idxOut = idxOut + 1;    
    epochsOut(idxOut) = extractEpochAroundEvent(EEG,tmpEvents(i),preTime,postTime);    
  end;
end
 
end