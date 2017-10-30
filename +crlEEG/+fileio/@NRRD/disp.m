function disp(obj)
% function disp(obj)
%
% Overload of display function for crlEEG.fileio.NRRD objects
%
% Written By: Damon Hyde
% Part of the cnlEEG project
% 2016
%

% If we have an array of NRRDs, loop across them.
for idx = 1:numel(obj)
  
  % Display Filename and Path
  disp(['            fname: ' obj(idx).fname]);
  displaypath = obj(idx).fpath;
  if length(displaypath)>35
    displaypath = ['...' displaypath(end-34:end)];
  end;
  disp(['            fpath: ' displaypath]);
  
  % Optional Datafile Name, for Separate NHDR/Data Files
  if ~isempty(obj(idx).data_fname)
    disp(['       data_fname: ' obj(idx).data_fname]);
  end;
  
  if ~strcmpi(obj(idx).content,'???')
    disp(['          content: ' obj(idx).content]);    end;
  
  if ~strcmpi(obj(idx).type,'???')
    disp(['             type: ' obj(idx).type]);       end;
  
  if ~strcmpi(obj(idx).dimension,'???')
    disp(['        dimension: ' num2str(obj(idx).dimension)]); end;
  
  if ~strcmpi(obj(idx).space,'???')
    disp(['            space: ' obj(idx).space]);      end;
  
  if ~strcmpi(obj(idx).sizes,'???')
    disp(['            sizes:  [' num2str(obj(idx).sizes) ']']); end;
  
  if ~strcmpi(obj(idx).endian,'???')
    disp(['           endian: ' obj(idx).endian]); end;
  
  if ~strcmpi(obj(idx).encoding,'???')
    disp(['         encoding: ' obj(idx).encoding]); end;
  
  if ~all(isnan(obj(idx).spaceorigin))
    disp(['      spaceorigin:  [ ' num2str(obj(idx).spaceorigin) ' ]']); end;
  
  if ~all(strcmpi(obj(idx).kinds,'???'))
    Str = ['            kinds:  {' ];
    for i = 1:length(obj(idx).kinds)
      Str = [Str ' ''' obj(idx).kinds{i} ''''];
    end;
    Str = [Str ' }'];
    disp(Str); end;
  
  if ~any(isnan(obj(idx).thicknesses))
    disp(['      thicknesses: ' num2str(obj(idx).thicknesses)]); end;
  
  if ~all(isnan(obj(idx).spacedirections))
    Str = num2str(obj(idx).spacedirections);
    disp(['  spacedirections:  [' Str(1,:) ']']);
    for i = 2:size(Str,1)
      disp(['                    [' Str(i,:) ']']);end;
  end;
  
  if ~all(strcmpi('???',obj(idx).spaceunits))
    disp(['       spaceunits: ' obj(idx).spaceunits]); end;
  
  if ~strcmpi(obj(idx).centerings{1},'???')
    Str = ['            centerings:  {' ];
    for i = 1:length(obj(idx).centerings)
      Str = [Str ' ''' obj(idx).centerings{i} ''''];
    end;
    Str = [Str ' }'];
    disp(Str); end;
  
  if ~all(isnan(obj(idx).measurementframe(:)))
    Str = num2str(obj(idx).measurementframe);
    disp([' measurementframe: [' Str(1,:) ']']);
    for i = 2:size(obj(idx).measurementframe,1)
      disp(['                   [' Str(i,:) ']']);
    end;
  end;
  
  tmpStr = {'false','true'};
  boolToString = @(x) tmpStr{x+1};
  
  disp(['         ReadOnly: ' boolToString(obj(idx).readOnly)]);
  disp(['          hasData: ' boolToString(obj(idx).hasData)]);
  disp(' ');
end;
end