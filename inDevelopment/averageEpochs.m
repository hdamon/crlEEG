function avgEpoch = averageEpochs(epochIn,avgType)
% Average a waveform across epochs
%
% Defaults to averaging power spectral densities
%

if ~exist('avgType','var'), avgType = 'PSD'; end;

avgEpoch = zeros(size(epochIn(1)));

if ~isempty(epochIn(1).decomposition)
  decompNames = fields(epochIn(1).decomposition);
  for idxName = 1:numel(decompNames)
    % Create a new decomposition with zeros in the tfX field.
    tmpDecomp = epochIn(1).decomposition.(decompNames{idxName}).copy;
    tmpDecomp.type = [tmpDecomp.type 'AvgDecomp'];
    tmpDecomp.tfX = zeros(size(tmpDecomp));                          
    decompOut.(decompNames{idxName}) = tmpDecomp;
  end
end

for idxEpoch = 1:numel(epochIn)
  avgEpoch = avgEpoch + epochIn(idxEpoch).data;
  
  if exist('decompOut','var')
    for idxName = 1:numel(decompNames)
      tmpDecomp = epochIn(idxEpoch).decomposition.(decompNames{idxName}).PSD;
      decompOut.(decompNames{idxName}) = decompOut.(decompNames{idxName}) + ...
                                      tmpDecomp;
    end
  end  
end

avgEpoch = avgEpoch./numel(epochIn);
avgEpoch = crlEEG.type.EEG(avgEpoch,epochIn(1).labels,...
  'sampleRate',epochIn(1).sampleRate,...
  'xvals',epochIn(1).xvals);

if exist('decompOut','var')
  for idxName = 1:numel(decompNames)    
     tmpDecomp = decompOut.(decompNames{idxName})./numel(epochIn);    
     tmpDecomp.type = ['AvgDecomp_' avgType '_N' num2str(numel(epochIn))];
     avgEpoch.decomposition.(decompNames{idxName}) = tmpDecomp;
  end 
end

end