function EEG = setReference(EEG,method)

switch method
  case 'avgref'
    EEG = avgRef(EEG);
  otherwise
    error('Unknown referencing type');
end

end


function EEG = avgRef(EEG)

idxData = getChannelsByType(EEG,'data');

data = EEG.data(:,idxData);
meanSig = mean(data,2);
meanSig = repmat(meanSig,1,size(data,2));
EEG.data(:,idxData) = EEG.data(:,idxData)-meanSig;


end