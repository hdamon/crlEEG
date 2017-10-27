function imgsOut = convert_FilesToStruct(obj)
% Pull filenames and
%
% function structOut = convertFilesToStruct(obj)
%

imgsOut = recurse(obj,'');

end


function out = recurse(obj,ref)

curr = obj.getImage(ref);

if isstruct(curr)
  out = [];
  f = fields(curr);
  for i = 1:numel(f)
    tmp = recurse(obj,[ref '.' f{i}]);
    out.(f{i}) = tmp;
  end
else
  out = struct( 'fieldName',[],...
                'type',[],...
                'options',[],...
                'fname',[],...
                'fpath',[]); %,...
                %'fullImage',[]);
  
  assert(isa(curr,'crlEEG.file.baseobj'),'This should be a crlEEG.file object');
  
  out.fieldName = ref;
  
  if curr.existsOnDisk
    
    switch class(curr)
      case 'crlEEG.file.NRRD'
        out.type = 'NRRD';
      case 'crlEEG.file.NRRD.parcellation'
        out.type = 'parcel';
        out.options = curr.parcelType;
      case 'crlEEG.file.NRRD.iEEGElectrodeMap'
        out.type = 'iEEGMap';
      otherwise
        error('Unknown image type');
    end
    
    out.fname = curr.fname;
    out.fpath = curr.fpath;
    
  else
    %out.fullImage = curr;
  end;
  
end


end