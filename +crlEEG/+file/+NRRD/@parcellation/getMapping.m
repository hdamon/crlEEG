function [mappingOut] = getMapping(type)
% function [mappingOut] = getMapping(type)
%
% Get the mapping between parcellation labels and tissue types
% (grey/subcortical grey/white/csf), as well as the associated anatomic
% region labels.
%
% Current valid parcellation types: ibsr, nmm, nvm
%
% Written By: Damon Hyde
% Last Edited: April 22, 2016
% Part of the cnlEEG project, 2014
%

switch lower(type)
  case 'ibsr'
    mappingOut = cnlParcellation.getIBSRMapping;
  case 'nmm'
    mappingOut = cnlParcellation.getNMMMapping;
  case 'nvm'
    mappingOut = cnlParcellation.getNVMMapping;
  otherwise
    error('Mapping not available for undefined parcellation types');
end;

mappingOut.cortexLabels = [];
mappingOut.subcorticalLabels = [];
mappingOut.whiteLabels = [];
mappingOut.csfLabels = [];

% Loop across parcels and identify which ones are Grey, Subcortical Grey,
% White, and CSF.
for i = 1:size(mappingOut.mapping,1)
  newParcel = mappingOut.mapping{i,1};
  switch mappingOut.mapping{i,2}
    case 4
      mappingOut.cortexLabels = [ mappingOut.cortexLabels newParcel];
    case 5
      mappingOut.csfLabels = [mappingOut.csfLabels newParcel];
    case 6
      mappingOut.subcorticalLabels = [mappingOut.subcorticalLabels newParcel];
    case 7
      mappingOut.whiteLabels = [mappingOut.whiteLabels newParcel];
  end
end;

end