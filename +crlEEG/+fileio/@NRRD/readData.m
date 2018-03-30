function readData(nrrdObj)

%% Move to the right directory, and make sure we move back when done
tmpDir = pwd;
returnToDir = onCleanup(@() cd(tmpDir));
cd(nrrdObj.fpath);

%% Open the appropriate file, and make sure it's closed when done.
if ~isempty(nrrdObj.data_fname)
  crlEEG.disp(['Reading data from separate file: ' nrrdObj.data_fname]);
  fid = fopen(nrrdObj.data_fname,'rb');
  assert(fid>0,['Failed to open NRRD data file ' nrrdObj.data_fname]);
else
  fid = fopen(nrrdObj.fname,'rb');
  assert(fid>0,['Failed to open NRRD file ' nrrdObj.fname]);
  % Move past the header by looking for the blank line
  while (true)
    line = fgetl(fid);
    if (isempty(line)||feof(fid))
      break;
    end;
  end
end;
closeFile = onCleanup(@() fclose(fid));

assert(~isequal(nrrdObj.encoding,'???') && ...
       ~isequal(nrrdObj.dimension,'???') && ...
       ~isequal(nrrdObj.sizes,'???'), ...
       'Required header fields are missing');
if (isequal(nrrdObj.endian,'???')), nrrdObj.endian = 'little'; end;     
     
assert(numel(nrrdObj.sizes)==nrrdObj.dimension,...
        'Sizes field does not match dimension field');
 
      
typecast = nrrdObj.matlabtype;
%typecast = [nrrdObj.matlabtype '=>' nrrdOBj.matlabtype];

switch (nrrdObj.encoding)
 case {'raw'}
  
  data = fread(fid, inf, typecast);
  
 case {'gzip', 'gz'}

  tmpBase = tempname();
  tmpFile = [tmpBase '.gz'];
  fidTmp = fopen(tmpFile, 'wb');
  assert(fidTmp > 3, 'Could not open temporary file for GZIP decompression')
  
  tmp = fread(fid, inf, 'uint8=>uint8');
  fwrite(fidTmp, tmp, 'uint8');
  fclose(fidTmp);
        
  gunzip(tmpFile)
  system(['rm ' tmpFile]);
  
  fidTmp = fopen(tmpBase, 'r');
  
  %meta.encoding = 'raw';
  %data = readData(fidTmp, meta, type);
  
  data = fread(fidTmp,inf,typecast);    
  fclose(fidTmp);
  system(['rm ' tmpBase]);
  
  
 case {'txt', 'text', 'ascii'}
  
  data = fscanf(fid, '%f');
  data = cast(data, type);
  
 otherwise
  assert(false, 'Unsupported encoding')
end

data = adjustEndian(data,nrrdObj.endian);

assert(numel(data)==prod(nrrdObj.sizes),...
  'Data size does not match nrrdObj.sizes');

nrrdObj.data = reshape(data,nrrdObj.sizes);

end


function data = adjustEndian(data, endian)
[~,~,endian] = computer();
needToSwap = (isequal(endian, 'B') && isequal(lower(endian), 'little')) || ...
             (isequal(endian, 'L') && isequal(lower(endian), 'big'));
         
if (needToSwap)
    data = swapbytes(data);
end
end
