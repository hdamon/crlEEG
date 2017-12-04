classdef NIFTI < crlEEG.fileio.baseobj
  % crlEEG front end object for the NIFTI toolbox
  %
  %
  
  properties (Constant, Hidden=true)
    validExts = {'.nii','.hdr'};
  end;
  
  properties
    hdr
    filetype
    fileprefix
    machine
    img
    original
  end
  
  methods
    function obj = NIFTI(varargin)
      
      
      % Test Functions
      fnameFcn = @(x) isempty(x)||isa(x,'crlEEG.fileio.NIFTI')||...
        (ischar(x) && ~ismember(lower(x),{'readonly'}));
      fpathFcn = @(x) isempty(x) || ...
        (ischar(x) && ~ismember(lower(x),{'readonly'}));
      
      % Input Parser Object
      p = inputParser;
      p.KeepUnmatched = true;
      p.addOptional('fname',[],fnameFcn);
      p.addOptional('fpath',[],fpathFcn);
      p.parse(varargin{:});
      
      %% Call Parent Constructor
      obj = obj@crlEEG.fileio.baseobj(p.Results.fname,p.Results.fpath,...
        p.Unmatched);
      
      %% Assign Properties
      % If a crlEEG.fileio.NRRD object was
      if isa(varargin{1},'crlEEG.fileio.NIFTI')
        obj.copyFields(varargin{1});
        return;
      end;
      
      % If the NRRD file exists on disk, read the header.
      if obj.existsOnDisk
        obj.read;
      else
        disp(['NRRD not located on disk. Creating empty object']);
      end;
    end
    
    function read(obj)
      f = load_nii(fullfile(obj.fpath,obj.fname));
      obj.hdr = f.hdr;
      obj.filetype = f.filetype;
      obj.fileprefix = f.fileprefix;
      obj.machine = f.machine;
      obj.img = f.img;
      obj.original = f.original;
    end
    
    function write(obj)
    end
    
    function copyFields(obj,source)
      % Copy field data from one object into another.
      assert(isa(source,'crlEEG.fileio.NIFTI'),...
        'Source must be a crlEEG.fileio.NIFTI object');
      obj.hdr = source.hdr;
      obj.filetype = source.filetype;
      obj.fileprefix = source.fileprefix;
      obj.machine = source.machine;
      obj.img = source.img;
      obj.original = source.original;
      
    end
    
  end
end