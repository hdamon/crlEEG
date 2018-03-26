classdef EEG < crlEEG.type.data.timeseries
  % Object class for EEG data
  %
  % classdef EEG < crlEEG.type.data.timeseries
  %
  
  properties
    setname
    filename
    filepath        
    decomposition    
  end
  
  methods
    
    function obj = EEG(varargin)
      % Constructor method for crlEEG.type.data.EEG objects    
            
      p = inputParser;
      p.KeepUnmatched = true;
      p.addOptional('data',[],@(x) (isnumeric(x)&&ismatrix(x))||...
                                    isa(x,'crlEEG.type.data.timeseries')||...
                                    isa(x,'crlEEG.type.data.EEG') );
      p.addOptional('labels',[],@(x) isempty(x)||iscellstr(x));     
      p.addParameter('setname',[],@ischar);
      p.addParameter('filename',[],@ischar);     
      p.parse(varargin{:});            
                  

      obj = obj@crlEEG.type.data.timeseries(p.Results.data,p.Results.labels,p.Unmatched);
            
    end    
    
    function decompose(obj,varargin)
      % Run one of a range of decompositions
      p = inputParser;
      p.KeepUnmatched = true;
      p.addParameter('type','timefrequency');
      p.addParameter('method','eeglab');
      p.parse(varargin{:});                  
    end    
    
    function n = numArgumentsFromSubscript(obj,s,indexingContext)
      
      n = numArgumentsFromSubscript@crlEEG.type.data.timeseries(...
                  obj,s,indexingContext);
    end
    
    %% Methods with their own m-files
    EEG = setReference(EEG,method);
    
  end
  
end