function build_AllHeadFiles(obj)
% Build all possible files derived from input head data.
%
% This is a single object method that calls the following:
%
% If obj.nrrdFullHead is empty (the full head segmentation), calls:
%   obj.nrrdFullHead = obj.build_FullHeadSegmentation;
%
% If obj.nrrdConductivity is empty (the full head conductivity map), calls:
%   obj.nrrdConductivity = obj.build_FullHeadConductivity;
%
% If obj.nrrdCorticalConstraints is empty (Vector image of cortical
% constraints), calls:
%   obj.nrrdCorticalConstraints = obj.build_FullCorticalConstraints;
%
% Written By: Damon Hyde
% Part of the crlEEG Project
% 2009-2017
%


%% Output path for model-specific files
fPath = fullfile(obj.rootdirectory,obj.options.subdir.models);
fPath = fullfile(fPath,obj.modelName);

if ~exist(fPath,'dir')
  mkdir(fPath);
end;

%% Build/Load The Full Segmentation
Ref = obj.options.segmentation.outputImgField;
fName = obj.options.segmentation.outputImgFName;
if isempty(obj.getImage(Ref))
  obj.setImage(Ref,obj.build_FullHeadSegmentation(fName,fPath));
end

%% Build/Load the Conductivity Image
Ref = obj.options.conductivity.outputCondField;
fName = obj.options.conductivity.outputCondFName;
if isempty(obj.getImage(Ref))
  obj.setImage(Ref,obj.build_FullHeadConductivity(fName,fPath));  
end

%% Build/Load the Cortical Constraint Images
% This is slightly different, because we usually want these ending up in
% the same directory as the MRI
if isfield(obj.images,'surfNorm')
  if isstruct(obj.images.surfNorm)
    f = fields(obj.images.surfNorm);
    for i = 1:numel(f)
      obj.setImage(['cortConst.' f{i}],...
        obj.build_FullCorticalConstraints(obj.images.surfNorm.(f{i}),...
          ['vec_CortConst_' f{i} '.nrrd'],obj.images.surfNorm.(f{i}).fpath));
    end
  else
    obj.setImage('cortConst', ...
      obj.build_FullCorticalConstraints(obj.images.surfNorm,...
          'vec_CortConst.nrrd',obj.images.surfNorm.fpath));
  end
end;  


end