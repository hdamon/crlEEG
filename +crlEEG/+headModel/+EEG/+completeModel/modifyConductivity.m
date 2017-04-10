function nrrdObj = modifyConductivity(Electrodes,nrrdObj)
% The Complete Electrode Model removes electrode voxels from the
% computational domain and replaces them with boundary conditions
%
assert(isa(Electrodes,'crlEEG.headModel.EEG.electrode'),...
  'Input electrode array must be a cnlElectrodes object');

for idxE = 1:numel(Electrodes)
  nrrdObj.data(Electrodes(idxE).Voxels) = 0;
end;
end


