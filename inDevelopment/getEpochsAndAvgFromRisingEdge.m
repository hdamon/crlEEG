function [epochs,avgEpoch] = getEpochsAndAvgFromRisingEdge(EEG,activeChan,eventDesc)
% Extract events at the rising edge of a binary channel
%
% Inputs
% ------
%         EEG : crlEEG.type.EEG object
%  activeChan : Label of binary channel in EEG to evaluate
%   eventDesc : Description to assign to the events
%
% Outputs
% -------
%   epochs : Array of crlEEG.type.EEG objects containing individual epochs
% avgEpoch : The averaged epochs.
%

EMG = EEG.data(:,activeChan);

eventIdx = [];
for i = 2:size(EEG,1)
  prevPt = EMG(i-1);
  nextPt = EMG(i);
  
  if (prevPt==0)&&(nextPt==1)
    eventIdx(end+1) = i;
  end
end

% Drop early and late events
eventIdx(eventIdx<1250) = [];
eventIdx(eventIdx>(length(EMG)-1250)) = [];

% Remove Bad Events
%badEvents = [1 3 22 37];
%eventIdx(badEvents) = [];

events = crlEEG.type.EEG_event;
for i = 1:numel(eventIdx)
  events(i) = crlEEG.type.EEG_event(eventIdx(i),1,eventDesc);
end
EEG.EVENTS = events;
epochs = extractEpochsByName(EEG,eventDesc,2,1);

avgEpoch = averageEpochs(epochs);

end