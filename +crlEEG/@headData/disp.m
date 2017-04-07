function disp(headData)
% DISP Overloaded display method for crlEEG.headData objects
%
% function disp(headData)
%
% Written By: Damon Hyde
% Part of the cnlEEG Project
% 2009-2017
%

nrrdList = crlEEG.headData.nrrdList;

disp(['Constructed Images']);
nrrdList = displayNRRD(headData.nrrdFullHead,'nrrdFullHead',nrrdList);
nrrdList = displayNRRD(headData.nrrdConductivity,'nrrdConductivity',nrrdList);

disp(['Raw MRI Images']);
nrrdList = displayNRRD(headData.nrrdT1,'nrrdT1',nrrdList);
nrrdList = displayNRRD(headData.nrrdT2,'nrrdT2',nrrdList);
nrrdList = displayNRRD(headData.nrrdDTI,'nrrdDTI',nrrdList);

disp(['Segmentation Images']);
nrrdList = displayNRRD(headData.nrrdSkin,'nrrdSkin',nrrdList);
nrrdList = displayNRRD(headData.nrrdSkull,'nrrdSkull',nrrdList);
nrrdList = displayNRRD(headData.nrrdICC,'nrrdICC',nrrdList);

disp(['Brain Segmentations']);
nrrdList = displayStruct(headData.nrrdBrain,'nrrdBrain',nrrdList);

disp(['Parcellations']);
nrrdList = displayStruct(headData.nrrdParcel,'nrrdParcel',nrrdList);

disp(['Surface Normal Files']);
nrrdList = displayStruct(headData.nrrdSurfNorm,'nrrdSurfNorm',nrrdList);

disp(['Other images']);

for idx = 1:length(nrrdList)
  [~] = displayNRRD(headData.(nrrdList{idx}),nrrdList{idx},[]);
end;

end

function listOut = displayStruct(S,name,ListIn)
if isstruct(S)
f = fields(S);
ListIn(ismember(ListIn,name)) = [];
for i = 1:numel(f)
  [~] = displayNRRD(S.(f{i}),[name '.' f{i}],[]);
end
end;
listOut = ListIn;

end

function listOut = displayNRRD(nrrdIn,name,listIn)
% Display the name of the object field, and the name of the file in it.
%

dispName = blanks(25);
dispName(end-length(name)+1:end) = name;

if ~isempty(nrrdIn)
  disp([dispName ': ' nrrdIn(1).fname]);
else
  disp([dispName ': EMPTY']);
end;

isOnList = ismember(listIn,name);
listOut = listIn(~isOnList);
  
dispName = blanks(20);
for idx = 2:numel(nrrdIn)
  if isa(nrrdIn(idx),'')
  disp([dispName ': ' nrrdIn(idx).fname])
  isOnList = ismember(listIn,name);
  listOut = listIn(~isOnList);
  end;
end

end
