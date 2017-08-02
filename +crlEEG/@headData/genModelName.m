function modelName = genModelName(headDataObj)
% Generate Default cnlEEG Model Name, based on available MRI data.
%
% modelName = genModelName(headDataObj)
%
% Given as set of available files in a cnlHeadData object, generate a
% default modelname of the format:
%
% modelName = [ skinString '_' skullString '_' brainString '_' wmString ];
%
%
%

if isempty(headDataObj)
  modelName = 'EMPTYMODEL';
  return;
end

if ~isempty(headDataObj.getImage('seg.skin'))
  skinString = 'skinCRL';
else
  error('Must have a skin segmentation to build a model');
end

if ~isempty(headDataObj.getImage('seg.skull'))
  skullString = 'skullCRL';
else
  skullString = 'skullNONE';
end

useBrainRef = headDataObj.options.segmentation.useBrainSeg;
if ~isempty(headDataObj.getImage(useBrainRef))
fields = strsplit(useBrainRef,'.');
brainString = ['seg' fields{end}];
else
  brainString = 'segNONE';
end

useDTIRef = headDataObj.options.conductivity.useTensorImg;
if ~isempty(headDataObj.getImage(useDTIRef))
  wmString = 'wmCRL';
else
  wmString = 'wmNONE';
end

modelName = [skinString '_' skullString '_' brainString '_' wmString];

end