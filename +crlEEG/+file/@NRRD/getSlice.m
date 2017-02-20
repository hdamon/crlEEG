function out = getSlice(nrrdObj,varargin)
% function out = GETSLICE(nrrdObj,axis,slice)
%
% THis isn't particularly robust, and will only work properly for 3D or 4D
% NRRDs
%
% Written By: Damon Hyde
% Last Edited: March 2015
% Part of the cnlEEG Project

% Input Parsing
p = inputParser;
p.addParamValue('axis',1);
p.addParamValue('slice',1);
p.addParamValue('otherDim',[]);
parse(p,varargin{:});

axis = p.Results.axis;
slice = p.Results.slice;
otherDim = p.Results.otherDim;

if ~nrrdObj.domainDims(1)
  % Default for other dimension selection
  % Returns all slices along the first dimension
  if isempty(otherDim), 
    otherDim = 1:nrrdObj.sizes(1); 
  end;
  
  % Pick the appropriate slices
  switch(axis)
    case 1
      out = nrrdObj.data(otherDim,slice,:,:);
    case 2
      out = nrrdObj.data(otherDim,:,slice,:);
    case 3
      out = nrrdObj.data(otherDim,:,:,slice);
  end  
else
  % It's a 3D NRRD, just pick the appropriate slice
  switch(axis)
    case 1
      out = nrrdObj.data(slice,:,:); 
    case 2
      out = nrrdObj.data(:,slice,:);
    case 3
      out = nrrdObj.data(:,:,slice);
  end
end

out = squeeze(out);

end