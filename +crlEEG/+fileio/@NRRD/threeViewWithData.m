function nrrdView = threeViewWithData(nrrdObj,data,overlay)
% THREEVIEWWITHDATA Visualizer for 4D NRRDS with associated data
%
% function nrrdView = threeViewWithData(nrrdObj,data)
%
% Written By: Damon Hyde
% Last Edited: June 2015
% Part of the cnlEEG Project
%

if nrrdObj.domainDims(1)
  error('For vector viewing, the first dimension must not be a domain');
end

if (size(data,1)~=nrrdObj.sizes(1))
  error('The first dimension of the provided data must match the size of the first nrrd dimension');
end;

threeview = nrrdObj.threeview(overlay);

fhnd_UpdateImgs = threeview.viewer{1}.sliceImg.fhnd_linkedUpdate;

dataview = uitools.cnlDataPlot('data',data);
dataview.selectedX = 1;

for i = 1:numel(threeview.viewer)
  threeview.viewer{i}.fhnd_getImgSlice = ...
    @(a,b)nrrdObj.getSlice('axis',a,'slice',b,'otherdim',dataview.selectedX);
  threeview.viewer{i}.sliceImg.imgRange = ...
    @()nrrdObj.getImageRange(threeview.viewer{i}.colorControl.currType,false);
end;

dataview.fhnd_UpdateSelectedX = fhnd_UpdateImgs;

nrrdView.threeview = threeview;
nrrdView.dataview = dataview;

end
