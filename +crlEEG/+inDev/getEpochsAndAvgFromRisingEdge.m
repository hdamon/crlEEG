function [epochs] = getEpochsAndAvgFromRisingEdge(EEG,activeChan,eventDesc,varargin)
% Extract events at the rising edge of a binary channel
%
% Inputs
% ------
%         EEG : crlEEG.EEG object
%  activeChan : Label of binary channel in EEG to evaluate
%   eventDesc : Description to assign to the events
%
% Outputs
% -------
%   epochs : Array of crlEEG.EEG objects containing individual epochs
% avgEpoch : The averaged epochs.
%

p = inputParser;
p.addRequired('activeChan',@(x) ischar(x));
p.addRequired('eventDesc',@(x) ischar(x));
p.addParameter('preTime',3,@(x) isscalar(x)&&isnumeric(x));
p.addParameter('postTime',3,@(x) isscalar(x)&&isnumeric(x));
p.parse(activeChan,eventDesc,varargin{:});


EMG = EEG.data(:,activeChan);

eventIdx = [];
for i = 2:size(EEG,1)
  prevPt = EMG(i-1);
  nextPt = EMG(i);
  
  if (prevPt==0)&&(nextPt==1)
    eventIdx(end+1) = i;
  end
end

preTime = p.Results.preTime;
postTime = p.Results.postTime;

% Drop early and late events
eventIdx(eventIdx<preTime*EEG.sampleRate) = [];
eventIdx(eventIdx>(length(EMG)-postTime*EEG.sampleRate)) = [];

% Remove Bad Events
%badEvents = [1 3 22 37];
%eventIdx(badEvents) = [];

events = crlEEG.event;
for i = 1:numel(eventIdx)
  events(i) = crlEEG.event(eventIdx(i),1,eventDesc);
end
EEG.EVENTS = events;
epochs = extractEpochsByName(EEG,eventDesc,preTime,postTime);

%avgEpoch = averageEpochs(epochs);

end
