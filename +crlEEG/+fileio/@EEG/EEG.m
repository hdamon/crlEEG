classdef EEG < crlBase.baseFileObj
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
      p.addOptional('fname',[],@(x) crlBase.baseFileObj.fnameFcn(x,'crlEEG.fileio.EEG'));
      p.addOptional('fpath',[],@(x) crlBase.baseFileObj.fpathFcn(x));      
      p.parse(varargin{:});
            
      %% Call Parent Constructor
      obj = obj@crlBase.baseFileObj(p.Results.fname,p.Results.fpath,...
                                      p.Unmatched); 
      if obj.existsOnDisk
        obj.read;
      end;
    end
    
    function out = crlEEG.fileio.EDF(obj)
      
      newFName = [obj.fname(1:end-4) '.edf'];
            
      head = obj.header;
      head.TYPE = 'EDF';
      head.FileName = fullfile(obj.fpath,newFName);      
      
      for i = 1:numel(head.PhysDim)
        head.PhysDim{i}(ismember(head.PhysDim{i},'µ')) = 'u';
      end
      
      out = crlEEG.fileio.EDF(newFName,obj.fpath,'dataAndHeader',{head,obj.data});
      
    end
    
    function out = crlEEG.EEG(obj)
      % Typecast to crlEEG.EEG
      out = crlEEG.EEG(obj.data,'chanLabels',obj.header.Label,'sampleRate',obj.header.SampleRate);
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
