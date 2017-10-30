function [matlabtype] = getMatlabType(nrrdObj)
% Return the appropriate matlab data type, based on nrrdObj.type
%
% function [matlabtype] = getMatlabType(nrrdObj)
%
% Written By: Damon Hyde
% Last Edited: Mar 9, 2016
% Part of the cnlEEG Project
%



% Determine the matlabtype
switch (nrrdObj.type)
 case {'signed char', 'int8', 'int8_t'}
  matlabtype = 'int8';
  
 case {'uchar', 'unsigned char', 'uint8', 'uint8_t'}
  matlabtype = 'uint8';

 case {'short', 'short int', 'signed short', 'signed short int', ...
       'int16', 'int16_t'}
  matlabtype = 'int16';
  
 case {'ushort', 'unsigned short', 'unsigned short int', 'uint16', ...
       'uint16_t'}
  matlabtype = 'uint16';
  
 case {'int', 'signed int', 'int32', 'int32_t'}
  matlabtype = 'int32';
  
 case {'uint', 'unsigned int', 'uint32', 'uint32_t'}
  matlabtype = 'uint32';
  
 case {'longlong', 'long long', 'long long int', 'signed long long', ...
       'signed long long int', 'int64', 'int64_t'}
  matlabtype = 'int64';
  
 case {'ulonglong', 'unsigned long long', 'unsigned long long int', ...
       'uint64', 'uint64_t'}
  matlabtype = 'uint64';
  
 case {'float'}
  matlabtype = 'single';
  
 case {'double'}
  matlabtype = 'double';
  
 case '???'
  assert(false, 'NRRD data type has not been set');
 otherwise
  assert(false, 'Unknown matlabtype')
end

end