function copyFields(nrrdObj,source)
% Manual copy of all non-dependent NRRD Fields
%
% function copyFields(nrrdObj,source)
%
% Written By: Damon Hyde
% Last Edited: 
% Part of the cnlEEG Project
%

nrrdObj.content = source.content;
nrrdObj.type = source.type;
nrrdObj.dimension = source.dimension;
nrrdObj.space = source.space;
nrrdObj.sizes = source.sizes;
nrrdObj.endian = source.endian;
nrrdObj.encoding = source.encoding;
nrrdObj.spaceorigin = source.spaceorigin;
nrrdObj.kinds = source.kinds;
nrrdObj.thicknesses = source.thicknesses;
nrrdObj.spacedirections = source.spacedirections;
nrrdObj.spaceunits = source.spaceunits;
nrrdObj.centerings = source.centerings;
nrrdObj.measurementframe = source.measurementframe;
nrrdObj.data = source.data;
nrrdObj.readOnly = source.readOnly;
nrrdObj.data_fname_stored = source.data_fname_stored;
nrrdObj.data_fname_matching_fname = source.data_fname_matching_fname;
nrrdObj.hasData = source.hasData;

end