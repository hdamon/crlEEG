function parseHeaderField(nrrdObj,fieldname,value)
% Parsing and assignment of NRRD Header Fields from String Values
%
%


switch lower(fieldname)
  case 'content'
    nrrdObj.content = removeExcessDelimiters(value,' ');
  case 'type'
    nrrdObj.type = removeExcessDelimiters(value,' ');
  case 'endian'
    nrrdObj.endian = removeExcessDelimiters(value,' ');
  case 'encoding'
    nrrdObj.encoding = removeExcessDelimiters(value,' ');
  case {'datafile', 'data file'}
    nrrdObj.data_fname = removeExcessDelimiters(value,' ');
  case 'dimension'
    nrrdObj.dimension = sscanf(value,'%i');
  case 'space'
    nrrdObj.space = removeExcessDelimiters(value,' ');
  case {'spacedirections', 'space directions'}
    tmpvalue = strrep(value,'none','');
    iSD = extractNumbersWithout(tmpvalue,{'(', ')', ','});
    if (length(iSD)~=9 & length(iSD)~=10)
      fprintf('Warning: %i space directions found.\n', iSD );
    end
    nrrdObj.spacedirections = [iSD(1) iSD(4) iSD(7); ...
      iSD(2) iSD(5) iSD(8); ...
      iSD(3) iSD(6) iSD(9)];
  case 'sizes'
    iSizes = sscanf(value,'%i');
    nrrdObj.sizes = iSizes';
  case 'thicknesses'
    sThicknesses = extractStringList(value);
    iThicknesses = [];
    lenThicknesses = length(sThicknesses);
    for iI=1:lenThicknesses
      iThicknesses = [iThicknesses, str2num( sThicknesses{iI} ) ];
    end
    nrrdObj.thicknesses = iThicknesses;
  case 'kinds'
    nrrdObj.kinds = extractStringList(value);
  case 'centerings'
    nrrdObj.centerings = extractStringList(value);
  case 'spaceunits'
    nrrdObj.spaceunits = extractStringList(value);
  case {'spaceorigin', 'space origin'}
    iSo = extractNumbersWithout(value,{'(',')',','});
    nrrdObj.spaceorigin = iSo';
  case 'measurementframe'
    iMF = extractNumbersWithout( value, {'(',')',','} );
    nrrdObj.measurementframe = [iMF(1) iMF(4) iMF(7); ...   
                                   iMF(2) iMF(5) iMF(8); ...
                                   iMF(3) iMF(6) iMF(9)];
  case 'modality'
     nrrdObj.modality = removeExcessDelimiters( extractKeyValueString( value ), ' ');   
  case 'dwmri_b-value'
    nrrdObj.bvalue = str2num( extractKeyValueString(value) );    
  case 'dwmri_gradient_'
    [iGNr, dwiGradient] = extractGradient(value);
    nrrdObj.gradients(iGNr+1,:) = dwiGradient;    
  otherwise
    disp(['NRRD Field ' fieldname ' is unsupported by this library, skipping']);
end

end

function sl = removeExcessDelimiters( strList, delim )
% Remove excess characters from a string
% 

if ( isempty( strList ) )
  sl = [];
  return;
end

indxList = [];
len = length( strList );

iStart = 1;
while ( iStart<len & strList(iStart)==delim )
  iStart = iStart+1;
end

iEnd = len;
while ( iEnd>1 & strList(iEnd)==delim )
  iEnd = iEnd-1;
end

iLastWasDelimiter = 0;
for iI=iStart:iEnd  
  if ( strList(iStart)~=delim )
    indxList = [indxList; iI ];
    iLastWasDelimiter = 0;
  else
    if ( ~iLastWasDelimiter )
      indxList = [indxList; iI];
    end
    iLastWasDelimiter = 1;
  end  
end

sl = strList(indxList);
end

function iNrs = extractNumbersWithout( inputString, withoutTokens )
% Remove delimiters and return a string of numbers
%
auxStr = inputString;

for iI=1:length( withoutTokens )  
  auxStr = strrep( auxStr, withoutTokens{iI}, ' ' );  
end

iNrs = sscanf( auxStr, '%f' );
end

function sl = extractStringList( strList )
% Extract a list of strings 
%

strList = removeExcessDelimiters( strList, ' ' );
delimiterIndices = strfind(strList,' ');
numDelimiters = length(delimiterIndices);

if (numDelimiters>=1)
  sl{1} = strList(1:delimiterIndices(1)-1);
else
  sl{1} = strList;
end

for iI=1:numDelimiters-1
  sl{iI+1} = strList(delimiterIndices(iI)+1:delimiterIndices(iI+1)-1);
end

if (numDelimiters>=2)
  sl{numDelimiters+1} = strList(delimiterIndices(end)+1:end);
end

end

function [iGNr, dwiGradient] = extractGradient( st )

% first get the gradient number
iGNr = str2num( st(1:4) );

% find where the assignment is
assgnLoc = strfind( st, ':=' );

if ( isempty(assgnLoc) )
  dwiGradient = [];
  return;
else 
  dwiGradient = sscanf( st(assgnLoc+2:end), '%f' );  
end

end


function kvs = extractKeyValueString( st )

assgnLoc = strfind( st, ':=' );

if ( isempty(assgnLoc) )
  kvs = [];
  return;
else  
  kvs = st(assgnLoc(1)+2:end);  
end

end
