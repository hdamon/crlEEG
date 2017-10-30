function scanForDefaults(obj,searchDir)
% Scan a directory for NRRDS with default file naming
%
% function scanForDefaults(obj,searchDir)
%
% crlEEG.headData method to scan a directory for default file names, as
% defined in obj.DEFAULT_FILE_NAMES.
%
% For each entry in DEFAULT_FILE_NAMES (defined in the main crlEEG.headData
% file), this method attempts to find an associated .NRRD or .NHDR file.
% Entries in DEFAULT_FILE_NAMES are formatted as:
%   { <propertyName> , <nrrdType> , <options> , { <fileName(s) } }
%
% propertyName is the name of the crlEEG.headData property that the file
% will be assigned to.
%
% nrrdType is the type of NRRD to load the file as. Currently supported
% options are:
%     'nrrd' : Load file as a crlEEG.fileio.NRRD object
%   'parcel' : Load file as a crlEEG.fileio.NRRD.parcel object, with 
%                parcellation labelling assigned as defined by the string
%                in the <options> field.
% 
% fileNames should be a cell array of strings, without file extensions.
%
% scanForDefaults will scan the directory searchDir for .NRRD or .NHDR
% files with the appropriate filenames.
%
% Additionally, scanForDefaults will preferentially scan for files named
% [fileName '_fixed.nrrd'] or [fileName '_fixed.nhdr'], as it assumes these
% are manually modified versions of the files automatically generated by
% the CRL pipeline, which should be left unedited.
%
% Written By: Damon Hyde
% Part of the crlEEG Project
% 2009-2017
%

% Return to pwd on exit
currentDir = pwd;
C = onCleanup(@() cd(currentDir));

for i = 1:size(obj.DEFAULT_FILE_NAMES,1)
  obj = findDefault(obj,obj.DEFAULT_FILE_NAMES(i,:),searchDir);
end;

% Reminder to put iEEG/sEEG support back in at some point.
% if exist('iEEG_Electrodes','dir'),
%   cd iEEG_Electrodes
%   d = dir;
%   tmpIdx = 0;
%   for i = 1:numel(d)
%     [~,fname,ext] = fileparts(d(i).name);
%     if strcmp(ext,'.nrrd')
%       tmpIdx = tmpIdx+1;
%       if tmpIdx==1
%         obj.nrrdIEEG = cnliEEGElectrodeMap(d(i).name,'./','grid'); obj.nrrdIEEG.namePrefix = fname;
%       else
%         obj.nrrdIEEG(tmpIdx) = cnliEEGElectrodeMap(d(i).name,'./','grid');  obj.nrrdIEEG(tmpIdx).namePrefix = fname;
%       end;
%     end
%   end;
% end

end

function obj = findDefault(obj,fieldData,filePath)
% Search for default files
%
% function obj = findDefault(obj,fieldData,filePath)
%

fieldName  = fieldData{1};
fieldType  = fieldData{2};
fieldParam = fieldData{3};
fileName   = fieldData{4};

% Check for all possible variants
foundOne = false;
for i = 1:numel(fileName)
  [tmpPath,fName,~] = fileparts(fileName{i});
  
  % Check File Path, if Provided in Filename
  if ~isempty(tmpPath)
    if exist(filePath,'var')&&~isempty(filePath)
      error('Provide path in either filename or filePath, not both');
    else
      filePath = tmpPath;
    end;
  end
  
  % Look for .nrrd files first, then .nhdr
  %
  % Files with the filename [fName '_fixed'] are chosen preferentially.
  %
  if exist(fullfile(filePath,[fName '_fixed.nrrd']),'file')
    fName = [fName '_fixed.nrrd'];    
  elseif exist(fullfile(filePath,[fName '_fixed.nhdr']),'file')
    fName = [fName '_fixed.nhdr'];
  elseif exist(fullfile(filePath,[fName '.nrrd']),'file')
    fName = [fName '.nrrd'];    
  elseif exist(fullfile(filePath,[fName '.nhdr']),'file')
    fName = [fName '.nhdr'];
  else
    continue;
  end;
  
  % Once one is found, stop looking for others.
  disp(['Found: ' fName]);
  foundOne = true;
  break;
end;

% If we made it here without finding a file, we're done.
if ~foundOne, return; end;

% Load it as the appropriate file type
switch (lower(fieldType))
  case 'nrrd'
    tmpData = crlEEG.fileio.NRRD(fName,filePath,'readOnly',true);
  case 'parcel'
    % To be replaced the parcellation filetype later.
    tmpData = crlEEG.fileio.NRRD.parcellation(fName,filePath,'parcelType',fieldParam,'readOnly',true);
  otherwise
    error('Unknown field type');
end;

% Set the field in the .images structure
obj.setImage(fieldName,tmpData);

end
