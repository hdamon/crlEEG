function  detectEpochs(obj)
% function  detectEpochs(obj)
%
% Detect epochs in an EDF file. This method scans obj.data to identify any
% timepoints at which all electrodes are equal to zero.  This zero padding
% separates one epoch from another.  The total number of epochs, as well as
% the start and end times of each epoch are then updated in:
%
% obj.nEpochs
% obj.epochs_start
% obj.epochs_end
%
% Written By: Damon Hyde
% Last Edited: Jan 16, 2015
% Part of the cnlEEG Project.

% Find locations of zero padding
epochDetect = sum(obj.data,2);
epochDetect = epochDetect==0;

% Find locations where two neighboring timepoints are identically equal.
% Technically this is probably not th ebest way to do this, but the
% probability of it happening in real data is very very small.
epochDetectA = obj.data(1:(end-1),:) - obj.data(2:end,:);
epochDetectA = sum(abs(epochDetectA),2);
epochDetectB = obj.data(2:end,:) - obj.data(1:(end-1),:);
epochDetectB = sum(abs(epochDetectB),2);
epochDetect = ([epochDetectA ; 1]==0) | ([1 ; epochDetectB] == 0);

nEpochs = 1;
offset = find(~epochDetect,1)-1; % Find the first datapoint without all zeros
idx = 1;

done = false;

while ~done
  [start(idx), finish(idx), offset] = findNextEpoch(epochDetect,offset);
  if isempty(offset), done = true;
  else    
    idx = idx + 1;
    nEpochs = nEpochs + 1;
  end;
end

% Assign values to object properties
obj.epochs_start = start;
obj.epochs_end = finish;
obj.nEpochs = nEpochs;

end

function [start, finish, newoffset] = findNextEpoch(detect,offset)

% Epoch goes from the next nonzero point to the timepoint immediately
% preceding the next all-zero value.
start  = offset + 1;
finish = offset + find(detect((offset+1):end),1) - 1;
if isempty(finish), finish = length(detect); end;

newoffset = find(~detect((finish+1):end),1);  

if ~isempty(newoffset)
  newoffset = newoffset - 1;
  newoffset = finish + newoffset;
end;

end