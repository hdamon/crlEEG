classdef bioSig < crlEEG.fileio.baseobj
  %% Object Class for Reading Files with BioSig
  %
  % A lightweight crlEEG object oriented wrapper for BioSig
  %
  
  properties
    data
    header
  end
  
  properties (Constant,Hidden=true)
    validExts = {'.eeg'};
  end
  
  methods
    
    function obj = bioSig(varargin)
      
      p = inputParser;
      p.KeepUnmatched = true;
      p.addOptional('fname',[],@(x) crlEEG.fileio.baseobj.fnameFcn(x,'crlEEG.fileio.BioSig'))
      p.addOptional('fpath',[],@(x) crlEEG.fileio.baseobj.fpathFcn(x));
      p.parse(varargin{:});
      
      obj = obj@crlEEG.fileio.baseobj(p.Results.fname,p.Results.fpath,...    
                                        p.Unmatched);
                                      
      if obj.existsOnDisk
        obj.read;
      end;
      
    end
    
    function read(obj)
      [d h] = sload(fullfile(obj.fpath,obj.fname));
      obj.data = d;
      obj.header = h;
    end
    
    function write(obj)
      error('Writing out with BioSig is a pain');
    end
  end
  
end