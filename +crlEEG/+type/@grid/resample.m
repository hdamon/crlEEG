function out = resample(obj,resampleLevel)
% Generate a new grid with a different number of samples
%
% crlEEG.typegrid.RESAMPLE
%
% function out = RESAMPLE(obj,resamplelevel)
%
% Returns a new crlEEG.typegrid object, resampled according to the
% values in resampleLevel.
%
% That is, the output grid will be of size:
%   out = round(in.sizes.*resampleLevel);
%
% Written By: Damon Hyde
% Part of the cnlEEG Project
% 2009-2017
%

if numel(resampleLevel)==1, resampleLevel = resampleLevel*ones(1,obj.dimension); end;

if numel(resampleLevel)~=obj.dimension,
  error('resampleLevel must be either a single scalar or of the same length as the dimension of the grid');
end;

newSizes = round(obj.sizes.*resampleLevel);
out = cnlGrid(newSizes);
end