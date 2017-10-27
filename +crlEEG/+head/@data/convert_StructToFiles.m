function convert_StructToFiles(obj,structIn,forceClear)
% Private method to load image files from 

if ~exist('forceClear','var'),forceClear = false; end;
if forceClear
 obj.images = [];
end;

recurse(obj,'',structIn);

end

function recurse(obj,ref,structIn)

if isfield(structIn,'type')
  curr = structIn;
  switch lower(structIn.type)
    case 'nrrd'
      tmpImg = crlEEG.file.NRRD(structIn.fname,structIn.fpath);
    case 'parcel'
      tmpImg = crlEEG.file.NRRD.parcellation(...
        structIn.fname,structIn.fpath,...
        'parcelType',structIn.options);
    case 'ieegmap'
      error('Not supported yet');
    otherwise
      error('Unknown image type');
  end
  obj.setImage(ref,tmpImg);
elseif isstruct(structIn)
  f = fields(structIn);
  for i = 1:numel(f)
    recurse(obj,[ref '.' f{i}],structIn.(f{i}));
  end
end
end