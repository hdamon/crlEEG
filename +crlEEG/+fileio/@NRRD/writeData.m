function writeData(nrrdObj)
% Write NRRD Data To File
%
% Written By: Damon Hyde
% Last Edited: March 9, 2016
% Part of the cnlEEG Project
%


%% Move to the right directory, and make sure we move back when done
tmpDir = pwd;
returnToDir = onCleanup(@() cd(tmpDir));
cd(nrrdObj.fpath);

%% Check that we actually have data to write
assert(numel(nrrdObj.data)==prod(nrrdObj.sizes),...
  'Writing failed. Data does not appear to be present in NRRD object.');

%% Open the appropriate file, and make sure it's closed when done.
if ~isempty(nrrdObj.data_fname)
  crlEEG.disp(['Writing data to separate file: ' nrrdObj.data_fname]);
  fid = fopen(nrrdObj.data_fname,'w+');
  assert(fid>0,['Failed to open NRRD data file ' nrrdObj.data_fname]);
else
  fid = fopen(nrrdObj.fname,'a+');
  assert(fid>0,['Failed to open NRRD file ' nrrdObj.fname]);  
  fseek(fid,0,'eof');  
end;
closeFile = onCleanup(@() fclose(fid));

switch (nrrdObj.encoding)
  case {'raw'}
    fwrite(fid,cast(nrrdObj.data,nrrdObj.matlabtype),nrrdObj.matlabtype);
  case {'gzip','gz'}
    tmpBase = tempname();
    fidTmp = fopen(tmpBase,'w');
    assert(fidTmp > 3, 'Could not open temporary file for GZIP compression');
    
    fwrite(fidTmp,cast(nrrdObj.data,nrrdObj.matlabtype),nrrdObj.matlabtype);
    fclose(fidTmp);
    
    % Compress the data
    gzip(tmpBase);
    
    % Open and read the compressed data
    fidTmp = fopen([tmpBase '.gz'],'rb');
    cleaner = onCleanup(@() fclose(fidTmp));
    tmp = fread(fidTmp,inf,'uint8=>uint8');
    
    % Write the compressed data to the appropriate file
    fwrite(fid,tmp,'uint8');
                
  case {'txt','ascii','text'}
    assert(false,'Writing of ASCII data currently unsupported');
  otherwise
    assert(false,'Unsupported Encoding');
end

end