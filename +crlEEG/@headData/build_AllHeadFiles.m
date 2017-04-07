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

if isempty(obj.nrrdFullHead)
  obj.nrrdFullHead = obj.build_FullHeadSegmentation;
end

if isempty(obj.nrrdConductivity)
  obj.nrrdConductivity = obj.build_FullHeadConductivity;
end

if isempty(obj.nrrdCorticalConstraints)
  obj.nrrdCorticalConstraints = obj.build_FullCorticalConstraints;
end

end