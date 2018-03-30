classdef EEG < crlEEG.type.timeseries
  % Object class for EEG data
  %
  % classdef EEG < crlEEG.type.timeseries
  %
  
  properties
    setname
    fname
    fpath        
    EVENTS
    decomposition    
  end
  
  methods
    
    function obj = EEG(varargin)
      % Constructor method for crlEEG.type.EEG objects    
            
      p = inputParser;
      p.KeepUnmatched = true;
      p.addOptional('data',[],@(x) (isnumeric(x)&&ismatrix(x))||...
                                    isa(x,'crlEEG.type.timeseries')||...
                                    isa(x,'crlEEG.type.EEG') );
      p.addOptional('labels',[],@(x) isempty(x)||iscellstr(x));     
      p.addParameter('EVENTS',[],@(x) isa(x,'crlEEG.type.EEG_event'));
      p.addParameter('setname',[],@ischar);
      p.addParameter('fname',[],@ischar);     
      p.parse(varargin{:});            
                  
      obj = obj@crlEEG.type.timeseries(p.Results.data,p.Results.labels,p.Unmatched);
            
      obj.setname = p.Results.setname;
      obj.fname = p.Results.fname;
      obj.EVENTS = p.Results.EVENTS; 
      
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
      % Not 100% sure this is necessary, but probably not a bad idea.
      n = numArgumentsFromSubscript@crlEEG.type.timeseries(...
                  obj,s,indexingContext);
    end
    
    %% Methods with their own m-files
    EEG = setReference(EEG,method);
    
  end
  
end