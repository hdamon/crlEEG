function dataOut = extract_EpochsUsingEV2(edfObj,ev2File,epochWidth)
% Uses marking from an EV2 file to extract epochs from a larger EDF
%
% function dataOut = extract_EpochsFromEDF(edfObj,ev2File)


offset = round(epochWidth/2);

dataOut = cell(numel(ev2File.dataByType),1);

for i = 1:numel(ev2File.dataByType) 
  clear epochCell;
  ev2data = ev2File.dataByType{i};
  marks = ev2data.Offset;
  marks = round(marks*edfObj.header.SampleRate);
  
  start = marks-offset;
  stop  = marks+offset;
  
  for j = 1:numel(start)
    epochCell{j} = edfObj.data(start(j):stop(j),:);
  end
  
  dataOut{i} = epochCell;
  
end

end