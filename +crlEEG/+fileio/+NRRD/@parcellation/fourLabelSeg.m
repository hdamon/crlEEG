function [segOut] = fourLabelSeg(parcel,fname,fpath)
% function [parcel] = fourLabelSeg(parcel)
%
% Given a parcellation, return the associated four tissue type
% segmentation. The parcellation is relabeled as:
%      4 = Cortex
%      5 = CSF
%      6 = Subcortical Grey Matter
%      7 = White Matter
%
% Written By: Damon Hyde
% Feb 20, 2014
% Last Modified: Feb 20, 2014

if ~exist('fname','var'), fname = 'SegOut.nhdr'; end;
if ~exist('fpath','var'), fpath = './'; end;

map = cnlParcellation.getMapping(parcel.parcelType);

segOut = clone(parcel,fname,fpath);
segOut = crlEEG.fileio.NRRD(segOut);

segOut.data(ismember(parcel.data,map.cortexLabels)) = 4;
segOut.data(ismember(parcel.data,map.subcorticalLabels)) = 4;
segOut.data(ismember(parcel.data,map.csfLabels)) = 5;
segOut.data(ismember(parcel.data,map.whiteLabels)) = 7;

end