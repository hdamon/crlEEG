function convert_StructToFiles(obj,structIn,forceClear)
% Private method to load image files from a structure
%
% This is intended to be used in combination with convert_FilesToStruct so
% that a basic Matlab structure can be saved to a .mat file along with the
% main FDM file. This will make it significantly more accessible to other
% users, as crlEEG won't be needed to make sense of the data.
%
% Should also get used with a JSON writing option.
%
% Written By: Damon Hyde
% Part of the crlEEG Project
% 2009-2017
%

if ~exist('forceClear','var'),forceClear = false; end;
if forceClear, obj.images = []; end;

recurse(obj,'',structIn);

end

function recurse(obj,ref,structIn)

if isfield(structIn,'type')
  curr = structIn;
  switch lower(structIn.type)
    case 'nrrd'
      tmpImg = crlEEG.fileio.NRRD(structIn.fname,structIn.fpath);
    case 'parcel'
      tmpImg = crlEEG.fileio.NRRD.parcellation(...
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