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

if ~isempty(headDataObj.nrrdSkin)
  skinString = 'skinCRL';
else
  error('Must have a skin segmentation to build a model');
end

if ~isempty(headDataObj.nrrdSkull)
  skullString = 'skullCRL';
else
  skullString = 'skullNONE';
end


brainString = ['seg' headDataObj.useBrainSeg];
% if ~isempty(headDataObj.nrrdBrain)
%   if ~isempty(findstr(headDataObj.nrrdBrain.fname,'brain_crl'));
%     brainString = 'segCRL';
%   elseif ~isempty(findstr(headDataObj.nrrdBrain.fname,'nvm_crl'));
%     brainString = 'segNVM';
%   elseif ~isempty(findstr(headDataObj.nrrdBrain.fname,'brain_nvm'));
%     brainString = 'segNVM';
%   elseif ~isempty(findstr(headDataObj.nrrdBrain.fname,'brain_nmm'));
%     brainString = 'segNMM';
%   elseif ~isempty(findstr(headDataObj.nrrdBrain.fname,'brain_ibsr'));
%     brainString = 'segIBSR';
%   elseif ~isempty(findstr(headDataObj.nrrdBrain.fname,'nmm_crl'));
%     brainString = 'segNMM';
%   elseif ~isempty(findstr(headDataObj.nrrdBrain.fname,'ibsr_crl'));
%     brainString = 'segIBSR';
%   end;
% else
%   brainString = 'segNONE';
% end;

if ~isempty(headDataObj.nrrdDTI)
  wmString = 'wmCRL';
else
  wmString = 'wmNONE';
end

modelName = [skinString '_' skullString '_' brainString '_' wmString];

end