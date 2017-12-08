function rangeOut = getImageRange(obj,type,collapseVec)
% function rangeOut = getImageRange(obj,type,vIdx)
%
% Returns the image range

error('crlEEG.fileio.NRRD.getImageRange is deprecated. Please cease use.');

if ~exist('type','var'), type = 'true'; end;
if ~exist('collapseVec','var'), collapseVec = true; end;

% Determine the index of the image type we're requesting.
allTypes = uitools.cnlColorControl.dispTypeList;

idx = 0;
found = false;
while ~found
  idx = idx+1;
  if idx>numel(allTypes)
    error('crlEEG.fileio.NRRD:unknownType',...
      'Unknown display type');
  end
  found = strcmpi(type,allTypes(idx).name);
end;

  
% Compute the image range if it's not already stored.
if (numel(obj.imgRanges)<idx)||isempty(obj.imgRanges{idx})  
  img = feval(allTypes(idx).fPre,obj.data);  
  if ~obj.domainDims(1)&collapseVec
    img2 = squeeze(sum(img,1));   
  else
    img2 = img;
  end
  img = feval(allTypes(idx).fPost,img);
  img2 = feval(allTypes(idx).fPost,img2);
    
  obj.imgRanges{idx}.collapsed = [min(img2(:)) max(img2(:))];  
  obj.imgRanges{idx}.individual = [min(img(:)) max(img(:))];
    
end;

if collapseVec
  tmp = obj.imgRanges{idx}.collapsed;
else
  tmp = obj.imgRanges{idx}.individual;
end
imgMin = tmp(1);
imgMax = tmp(2);

rangeOut = [imgMin imgMax];

end


function types = getAllTypes

types(1).name = 'true';
types(1).fPre  = @(x)x;
types(1).fPost = @(x)x;

types(2).name = 'norm';
types(2).fPre  = @(x)x.^2;
types(2).fPost = @(x)sqrt(x);

types(3).name = 'abs';
types(3).fPre  = @(x)abs(x);
types(3).fPost = @(x)x;

types(4).name = 'parcel';
types(4).fPre  = @(x)mod(x,30);
types(4).fPost = @(x)x;

types(5).name = 'exp';
types(5).fPre  = @(x)x;
types(5).fPost = @(x)x;

types(6).name = 'log';
types(6).fPre  = @(x)log10(abs(x));
types(6).fPost = @(x)x;


end