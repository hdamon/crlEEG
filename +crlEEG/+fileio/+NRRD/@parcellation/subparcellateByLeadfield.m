function nrrdOut = subparcellateByLeadfield(nrrdIn,nrrdVec,type,LeadField,nFinal,fName)
% function nrrdOut = SUBPARCELLATEBYLEADFIELD(nrrdIn,nrrdVec,type,LeadField,nFinal,fName)
%
% Inputs:
%   nrrdIn     : Input cnlParcellation to start from
%   nrrdVec    : Cortical orientation constraints
%   type       : Distance type to use in the cortical connectivity graph
%   LeadField  : cnlLeadField object to use for weighting.
%   nFinal     : Target number of parcellations in output NRRD
%   fName      : Filename for the output parcellation NRRD
%
% Outputs:
%   nrrdOut    : cnlParcellation NRRD with the new subparcellated volume
%
% Written By: Damon Hyde
% Last Edited: June 9, 2015
% Part of the cnlEEG Project
%
 

%% Input Parsing
% p = inputParser;
% p.addOptional('type','basic');
% p.addParamValue('nrrdVec',[],@(x) isa(x,'crlEEG.fileio.NRRD'));
% p.addParamValue('LeadField',[],@(x) isa(x,'cnlLeadField'));
% p.addParamValue('


% Reset LeadField to it's original solution space, and collapse 
LeadField.currSolutionSpace = LeadField.origSolutionSpace;
LeadField.isCollapsed = true;

voxLField = LeadField.currSolutionSpace.Voxels;

segLabels = unique(nrrdIn.data);

avgSize = numel(find(nrrdIn.data))/nFinal;

graph = cnlImageGraph(nrrdVec.data,3,'voxList',voxLField,'distType',type,...
                   'nbrType','none','Leadfield',LeadField.currMatrix);

tic
for i = 2:length(segLabels)

 crlEEG.disp(['Subparcellating Label #' num2str(i)]);
 voxIdx = find(nrrdIn.data(voxLField)==segLabels(i));
       
 crlEEG.disp(['There are ' num2str(length(voxIdx)) ' voxels in this parcel']);
 
 nTarget = length(voxIdx)/avgSize;
 
 if length(voxIdx)>1.5*avgSize
   crlEEG.disp(['Subparcellating into ' num2str(nTarget) ' regions']);
   Ncut = cnlParcellation.iterateCut(graph.Cmatrix(voxIdx,voxIdx),nTarget);
 else
   crlEEG.disp(['Parcel too small to subparcellate. Leaving as is']);
   Ncut = ones(length(voxIdx),1);
 end;
 
 cutSize = sum(Ncut,1);
 
 crlEEG.disp(['Divided parcel into ' num2str(size(Ncut,2)) ' regions']);
 crlEEG.disp(['Maximum size: ' num2str(max(cutSize))]);
 crlEEG.disp(['Minimum size: ' num2str(min(cutSize))]);
 
 OutImg{i} = Ncut*(1:size(Ncut,2))';
   
end;
tic

tmp = zeros(nrrdIn.sizes);
baseLabel = 0;

%tmp((nrrdIn.data(voxLField)==segLabels(2))) = OutImg{2};
%baseLabel = max(OutImg{2});

for i = 2:length(OutImg)
  voxIdx = (nrrdIn.data(voxLField)==segLabels(i));
  
  tmp(voxLField(voxIdx)) = OutImg{i}+baseLabel;
  baseLabel = baseLabel+max(OutImg{i});
end;

nrrdOut = clone(nrrdIn,fName,nrrdIn.fpath);
nrrdOut.data = tmp;


end