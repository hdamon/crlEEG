function [varargout] = view(nrrdObj,varargin)
  % VIEW View slices from a crlEEG.fileio.NRRD object.
  %
  % function nrrdView = view(nrrdObj,varargin)
  %
  % A basic slice viewer for visualizing NRRDS.
  %
  % Should probably be ported over to be a handle object, so things stay nice
  % and consistent when used in larger viewers
  %
            
   
  p = inputParser;
  p.KeepUnmatched = true;
  p.addOptional('nrrdOverlay',[],@(x)isa(x,'crlEEG.fileio.NRRD')||isa(x,'function_handle'));
  p.addParamValue('cmap',[]);
  p.addParamValue('disptype',[]);
  p.addParamValue('overalpha',0.5);
  parse(p,varargin{:});
  
  volumes = cell(0);
  volumes{1} = nrrdObj.data;
  
  names = cell(0);
  names{1} = nrrdObj.fname;
  
  for i = 1:numel(p.Results.nrrdOverlay)
    volumes{i+1} = p.Results.nrrdOverlay(i).data;
    names{i+1} = p.Results.nrrdOverlay(i).fname;
  end;
  
  renderer = uitools.render.volStack3DSliced(volumes,names,...
    p.Unmatched,'aspect',nrrdObj.aspect);
  
  if ( numel(renderer.volumes)>1 )
      % Set background to grey colormap
      renderer.volumes(2).colormap.type = 'gray';
      
      % Set foreground to 'abs' display, and make zero transparent.
      renderer.volumes(1).pipeline{1}.functionType = 'abs';
      renderer.volumes(1).colormap.transparentZero;            
  end;
  
  varargout{1} = renderer.render;
  varargout{1}.units = 'normalized';
      
  
end

