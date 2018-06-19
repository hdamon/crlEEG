function avgEpoch = averageEpochs(epochIn)
% Average a waveform across epochs


avgEpoch = zeros(size(epochIn(1)));

if ~isempty(epochIn(1).decomposition)
  decompNames = fields(epochIn(1).decomposition);
  for i = 1:numel(decompNames)
    decompOut.(decompNames{i}) = zeros(size(epochIn(1).decomposition.(decompNames{i})));
  end
end

for i = 1:numel(epochIn)
  avgEpoch = avgEpoch + epochIn(i).data;
  
  if exist('decompOut','var')
    for j = 1:numel(decompNames)
      decompOut.(decompNames{j}) = decompOut.(decompNames{j}) + ...
                  abs(epochIn(i).decomposition.(decompNames{j}).tfX).^2;
    end
  end  
end

avgEpoch = avgEpoch./numel(epochIn);



avgEpoch = crlEEG.type.EEG(avgEpoch,epochIn(1).labels,...
  'sampleRate',epochIn(1).sampleRate,...
  'xvals',epochIn(1).xvals);

if exist('decompOut','var')
  for i = 1:numel(decompNames)
    decompOut.(decompNames{i}) = decompOut.(decompNames{i})/numel(epochIn);

    tmpDecomp = timeFrequencyDecomposition(...
                  epochIn(1).decomposition.(decompNames{i}).type,...
                  decompOut.(decompNames{i}),...
                  epochIn(1).decomposition.(decompNames{i}).tx,...
                  epochIn(1).decomposition.(decompNames{i}).fx,...
                  epochIn(1).decomposition.(decompNames{i}).labels);
    avgEpoch.decomposition.(decompNames{i}) = tmpDecomp;
  end 
end

end