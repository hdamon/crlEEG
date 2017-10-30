function readHeader(nrrdObj)
% Read and Parse the NRRD Header
% 
% Written By: Damon Hyde
% Modified from mathworks provided code
% Last Edited: Mar 9, 2016
% Part of the cnlEEG Project
%

% Move to the right directory, and make sure we move back when done
tmpDir = pwd;
returnToDir = onCleanup(@() cd(tmpDir));
cd(nrrdObj.fpath);

% Open file and set cleanup 
fid = fopen(nrrdObj.fname,'rb');
assert(fid>0, ['Failed to open ' nrrdObj.fname ' for reading']);
cleaner = onCleanup(@() fclose(fid));

% Make sure it looks like a NRRD
line = fgetl(fid);
assert(numel(line) >= 4, 'Bad file signature');
assert(isequal(line(1:4),'NRRD'), 'File does not appear to be a NRRD');

meta = struct([]);

while (true)  
   line = fgetl(fid);
   
   % Exit if at end of header
   if (isempty(line)), break; end
         
   % Skip comment lines
   if (isequal(line(1),'#')), continue; end;
   
   % Parse line
   parsed = regexp(line, ':=?\s*','split','once');
   assert(numel(parsed)==2, 'Error parsing line');
   
   fieldname = lower(parsed{1});
   value = parsed{2};
   
   % For Debugging
   %disp(['Field: ' fieldname ' Value: ' value]);
   
   parseHeaderField(nrrdObj,fieldname,value);

   % If we're at the end of the file, exit
   if (feof(fid)), break; end;
end

end