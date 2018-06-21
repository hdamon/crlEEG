classdef EEG < crlEEG.fileio.baseobj
  %% Object class for reading .eeg files
  %
  % This is primarily a lightweight front end for BioSig.
  %
  %
  
  properties
    data
    header
  end
  
  properties (Constant,Hidden=true)
    validExts = {'.eeg'};
  end
  
  methods
    
    function obj = EEG(varargin)      
      % Input Parser Object
      p = inputParser;
      p.KeepUnmatched = true;
      p.addOptional('fname',[],@(x) crlEEG.fileio.baseobj.fnameFcn(x,'crlEEG.fileio.EEG'));
      p.addOptional('fpath',[],@(x) crlEEG.fileio.baseobj.fpathFcn(x));      
      p.parse(varargin{:});
            
      %% Call Parent Constructor
      obj = obj@crlEEG.fileio.baseobj(p.Results.fname,p.Results.fpath,...
                                      p.Unmatched); 
      if obj.existsOnDisk
        obj.read;
      end;
    end
    
    function out = crlEEG.EEG(obj)
      % Typecast to crlEEG.EEG
      out = crlEEG.EEG(obj.data,obj.header.Label,'sampleRate',obj.header.SampleRate);
    end
    
    function read(obj)
      [d h] = sload(fullfile(obj.fpath,obj.fname));
      obj.data = d;
      obj.header = h;
    end
    
    function write(obj)
      error('EEG File Writing Currently Unimplemented');
    end
    
  end
  
end