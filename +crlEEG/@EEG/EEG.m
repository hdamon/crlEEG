classdef EEG < MatTSA.timeseries
  % Object class for EEG data
  %
  % classdef EEG < MatTSA.timeseries
  %
  % Built on the MatTSA.timeseries object class (itself built on the
  % labelledArray object class), this adds data set naming, events, and
  % tracking of applied filters.
  %
  
  properties
    setname
    fname
    fpath
    EVENTS    
    filters = cell(0);
  end
  
  methods
    
    function obj = EEG(varargin)
      % Constructor method for crlEEG.EEG objects
      
      p = inputParser;
      p.KeepUnmatched = true;
      p.addOptional('data',[],@(x) (isnumeric(x)&&ismatrix(x))||...
        isa(x,'MatTSA.timeseries')||...
        isa(x,'crlEEG.EEG') );      
      p.addParameter('EVENTS',[],@(x) isa(x,'crlEEG.event'));
      p.addParameter('setname',[],@ischar);
      p.addParameter('fname',[],@ischar);
      p.parse(varargin{:});
      
      obj = obj@MatTSA.timeseries(p.Results.data,p.Unmatched);
      
      obj.setname = p.Results.setname;
      obj.fname   = p.Results.fname;
      obj.EVENTS  = p.Results.EVENTS;
      
    end
            
    function setStartTime(obj,startTime)
      % Shift the starting point of the time series, and adjust timings for
      % all decompositions as well.
      delta = startTime-obj.xrange(1);
      
      obj.xvals = obj.xvals + delta;
      
      if ~isempty(obj.decomposition)
        decompNames = fields(obj.decomposition);
        for i = 1:numel(decompNames)
          obj.decomposition.(decompNames{i}).tx = ...
            obj.decomposition.(decompNames{i}).tx + delta;
        end;
      end
      
    end
    
    %% Filtering Options
    function EEGout = applyStandardFilter(EEGIn,fType,varargin)
      % Simplifies calls to filter an eeg using the standard methods.
      EEGout = EEGIn.filtfilt(EEGIn.standardFilters(fType,EEGIn.sampleRate,varargin{:}));
    end

    function EEGout = filter(EEGIn,f)
      % Overloaded to add filter tracking
      EEGout = EEGIn.filter@crlEEG.type.timeseries(f);
      EEGout.filters{end+1} = f;
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
      n = numArgumentsFromSubscript@MatTSA.timeseries(...
        obj,s,indexingContext);
    end
    
    %% Methods with their own m-files
    EEG = setReference(EEG,method);
    
  end
  
  methods (Access=protected)
    function out = subcopy(obj,varargin)
      % Likely unnecessary
      out = subcopy@MatTSA.timeseries(obj,varargin{:});
      
      
    end
  end;
  
  methods (Static=true)
    fOut = standardFilters(fType,sampleRate,varargin);
  end
  
end
