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
    filters = cell(0);
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
    
    function EEGout = applyStandardFilter(EEGIn,fType,varargin)
      % Simplifies calls to filter an eeg using the standard methods.
      EEGout = EEGIn.filtfilt(EEGIn.standardFilters(fType,EEGIn.sampleRate,varargin{:}));
    end
    
    function EEGout = filtfilt(EEGIn,f)
      % Filtfilt for crlEEG.type.EEG objects includes tracking of all
      % applied filters in the obj.filters property.
      %
      
      EEGout = EEGIn.filtfilt@crlEEG.type.timeseries(f);
      
      
      EEGout.filters{end+1} = f;
      
    end
    
    function n = numArgumentsFromSubscript(obj,s,indexingContext)
      % Not 100% sure this is necessary, but probably not a bad idea.
      n = numArgumentsFromSubscript@crlEEG.type.timeseries(...
                  obj,s,indexingContext);
    end
    
    %% Methods with their own m-files
    EEG = setReference(EEG,method);
    
  end
  
  methods (Static=true)
    fOut = standardFilters(fType,sampleRate,varargin);
  end
  
end