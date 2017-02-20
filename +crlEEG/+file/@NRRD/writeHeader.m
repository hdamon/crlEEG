% NHDR header reader
% -------------------------------------------------------------------------
% Description:
% 	Write NHDR header and corresponding data in NRRD file
% 
% Usage: 
%   writeHeader( 'dataTest.nhdr', hdrMRI )
% Input:
%   - nhdrFileName: file name of nrrd header (.nhdr)
%   - nrrdHeader: nrrd structure
% 
% Output:
%
% Comments:
% 
% Notes:
%   Writes NRRD structure to file.
% 
% -------------------------------------------------------------------------

function  writeHeader(nrrdObj)

% Move to the right directory, and make sure we move back when done
tmpDir = pwd;
returnToDir = onCleanup(@() cd(tmpDir));
cd(nrrdObj.fpath);

% Open the header file for writing.
fid = fopen( nrrdObj.fname, 'w+' );
assert(fid>0,['Failed to open ' nrrdObj.fname ' for writing']);

% If failed to open for writing, try opening it for reading.
if (fid == -1)
  fid_test = fopen(nrrdObj.fname,'r');
  assert(fid_test>0,['ABORT: ' nrrdObj.fname ' does not exist']);
  warning(['File ' nrrdObj.fname ' exists but appears to be read-only. '...
              'Skipping file write']);
  return;
end
closeHeader = onCleanup(@() fclose(fid));

fprintf( fid, 'NRRD0004\n' );
fprintf( fid, '# Complete NRRD file format specification at:\n' );
fprintf( fid, '# http://teem.sourceforge.net/nrrd/format.html\n' );
fprintf( fid, 'content: %s\n', nrrdObj.content);
fprintf( fid, 'type: %s\n', nrrdObj.type );
fprintf( fid, 'dimension: %d\n', nrrdObj.dimension );
fprintf( fid, 'space: %s\n', nrrdObj.space );
fprintf( fid, 'sizes: ' );

for iI=1:length( nrrdObj.sizes )
  fprintf( fid, '%d', nrrdObj.sizes(iI) );
  if ( iI~=length( nrrdObj.sizes ) )
    fprintf( fid, ' ' );
  end
end
fprintf( fid, '\n' );

fprintf( fid, 'space directions: ' );
% if first kind is 3D-masked-symmetric-matrix, assume tensor data.
if strcmp(nrrdObj.kinds(1), '3D-masked-symmetric-matrix')||...
   strcmp(nrrdObj.kinds(1), '3D-symmetric-matrix')||...
   strcmp(nrrdObj.kinds(1), 'RGB-color')||...
   strcmp(nrrdObj.kinds(1), 'vector')||...
   strcmp(nrrdObj.kinds(1),'covariant-vector')
    fprintf( fid, 'none ' );
end

sd = nrrdObj.spacedirections;
fprintf( fid, '(%f,%f,%f) (%f,%f,%f) (%f,%f,%f)\n', ...
 sd(1,1), sd(2,1), sd(3,1), sd(1,2), sd(2,2), sd(3,2), sd(1,3), sd(2,3), sd(3,3) );

fprintf( fid, 'kinds: ' );
for iI=1:length( nrrdObj.kinds )
  fprintf( fid, '%s', nrrdObj.kinds{iI} );
  if ( iI~=length( nrrdObj.kinds ) )
    fprintf( fid, ' ' );
  end
end
fprintf( fid, '\n' );

if any(strcmp(fieldnames(nrrdObj),'endian'))
  fprintf( fid, 'endian: %s\n', nrrdObj.endian );
end

% for now encoding is raw since nrrdSave does encoding in raw
fprintf( fid, 'encoding: %s\n', nrrdObj.encoding );
%fprintf( fid, 'encoding: \n');

so = nrrdObj.spaceorigin;
fprintf( fid, 'space origin: (%f,%f,%f)\n', so(1), so(2), so(3) );

% check if there is a measurement frame
if any(strcmp(fieldnames(nrrdObj),'measurementframe'))
  if ~all(isnan(nrrdObj.measurementframe(:)))
    mf = nrrdObj.measurementframe;
    fprintf( fid, 'measurement frame: (%f,%f,%f) (%f,%f,%f) (%f,%f,%f)\n', ...
        mf(1,1), mf(2,1), mf(3,1), mf(1,2), mf(2,2), mf(3,2), mf(1,3), mf(2,3), mf(3,3) );
  end
end

% check if field thickness is there
if any(strcmp(fieldnames(nrrdObj),'thicknesses'))
  if ~any(isnan(nrrdObj.thicknesses))
    fprintf( fid, 'thicknesses: ' );
    for iI=1:length( nrrdObj.thicknesses )
        fprintf( fid, '%f', nrrdObj.thicknesses(iI) );
        if ( iI~=length( nrrdObj.thicknesses ) )
            fprintf( fid, ' ' );
        end
    end
    fprintf( fid, '\n' );
    %thick = nrrdHeader.thicknesses;
    %fprintf( fid, 'thicknesses: %f %f %f\n', thick(1), thick(2), thick(3) );
  end
end

% check if field centerings is there
if any(strcmp(fieldnames(nrrdObj),'centerings'))  
  if ~strcmpi(nrrdObj.centerings{1},'???')
    fprintf( fid, 'centerings: ' );
    for iI=1:length( nrrdObj.centerings )
        fprintf( fid, '%s', char(nrrdObj.centerings(iI)) );
        if ( iI~=length( nrrdObj.centerings ) )
            fprintf( fid, ' ' );
        end
    end
    fprintf( fid, '\n' );
    
    %ce = nrrdHeader.centerings;
    %fprintf( fid, 'centerings: %s %s %s\n', char(ce(1)), char(ce(2)), char(ce(3)) );
  end
end

% check if field spaceunits is there
if any(strcmp(fieldnames(nrrdObj),'spaceunits'))
  if ~all(strcmpi('???',nrrdObj.spaceunits))
    fprintf( fid, 'space units: ' );
    for iI=1:length( nrrdObj.spaceunits )
        fprintf( fid, '\"%s\"', char(nrrdObj.spaceunits(iI)) );
        if ( iI~=length( nrrdObj.spaceunits ) )
            fprintf( fid, ' ' );
        end
    end
    fprintf( fid, '\n' );
    
    %su = nrrdHeader.spaceunits;
    %fprintf( fid, 'space units: %s %s %s\n', char(su(1)), char(su(2)), char(su(3)) );
  end
end

if ~isempty(nrrdObj.data_fname)
  fprintf( fid, 'data file: %s\n', nrrdObj.data_fname);
end;

%% Blank line at the end
fprintf(fid,'\n');

end