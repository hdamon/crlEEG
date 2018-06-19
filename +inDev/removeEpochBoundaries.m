function EEGOut = removeEpochBoundaries(EEGIn)
% Remove those silly BESA epoch divisions.
%
% When BESA exports data in EDF format, it introduces periods of uniform 
% non-zero signal as a buffer between the epochs. Not sure if this is in
% the EDF standard or not, but it's what BESA does.
%
% This script detects those periods and removes them from the EEG.
%
% Event latencies are corrected for the shift



epochDetectA = sum(abs(EEGIn.data(1:end-1,:)-EEGIn.data(2:end,:)),2);
epochDetectB = sum(abs(EEGIn.data(2:end,:)-EEGIn.data(1:end-1,:)),2);
epochDetect = ([epochDetectA ; 1]==0) | ([1 ; epochDetectB] ==0);

% If no epoch boundaries are detected, just return the input
if ~any(epochDetect), 
  EEGOut = EEGIn.copy;
  return; 
end;

% Location of first point to be removed
offset = find(epochDetect,1);
nEpochs = 1;
done = false;
while ~done
  [start(nEpochs),finish(nEpochs),offset] = findNextEpoch(epochDetect,offset);
  if isempty(offset), done = true;
  else
    nEpochs = nEpochs + 1;
  end;
end

% Compute Latency Shifts
latencyshift = zeros(1,size(EEGIn,1));

for i = 1:nEpochs
  windowSize = finish(i)-start(i)+1;
  latencyshift(finish(i)+1:end) = latencyshift(finish(i)+1:end)-windowSize;
end

% Fix Event Timings
events = EEGIn.EVENTS;
if ~isempty(events)
  for i = 1:numel(events)
    events(i).latency = events(i).latency + latencyshift(round(events(i).latency));    
  end
end;

EEGOut = EEGIn(~epochDetect,:);
deltaT = 1./EEGOut.sampleRate;
EEGOut.xvals = deltaT*(1:size(EEGOut,1)) - deltaT;
EEGOut.EVENTS = events;

%% SANITY CHECK
for i = 1:numel(events)
  foo = norm(EEGIn.data(EEGIn.EVENTS(i).latency,:)-...
              EEGOut.data(EEGOut.EVENTS(i).latency,:));
end

if any(foo)
  disp('Mismatched data when removing epoch boundaries');
  keyboard;
end;

end


function [start, finish, newoffset] = findNextEpoch(detect,offset)

% Epoch goes from the next nonzero point to the timepoint immediately
% preceding the next all-zero value.
start  = offset ;
finish = offset + find(~detect((offset+1):end),1) - 1;

if isempty(finish)
  % Ran off the end of the sequence
  finish = length(detect);
end

newoffset = find(detect((finish+1):end),1);  

if ~isempty(newoffset)
  newoffset = finish + newoffset;  
end;

end