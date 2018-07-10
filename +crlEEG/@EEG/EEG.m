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
    
    function obj = setStartTime(obj,startTime)
      % Shift the starting point of the time series, and adjust timings for
      % all events and decompositions as well.
      delta = startTime-obj.tRange(1);
      
      obj.tVals = obj.tVals + delta;
      
      if ~isempty(obj.decomposition)
        decompNames = fields(obj.decomposition);
        for i = 1:numel(decompNames)
          obj.decomposition.(decompNames{i}).tVals = ...
            obj.decomposition.(decompNames{i}).tVals + delta;
        end;
      end
      
      if ~isempty(obj.EVENTS)
        for i = 1:numel(obj.EVENTS)
          obj.EVENTS(i).latencyTime = obj.EVENTS(i).latencyTime + delta;
        end
      end
            
    end
    
    function out = cat(dim,obj,a,varargin)
      % Concatenate timeseries objects
      %
      %
      
      assert(isa(a,class(obj)),'Can only concatenate like objects');
      
      out = cat@MatTSA.timeseries(dim,obj,a);
      
      if dim==1
        tmp = a.EVENTS;
        for i = 1:numel(tmp)
          tmp(i).latency = tmp(i).latency+size(obj,1);
        end;
        out.EVENTS = [obj.EVENTS tmp];
      else
        out.EVENTS = [obj.EVENTS a.EVENTS];
      end;
      
      if ~isempty(varargin)
        % Recurse when concatenating multiple objects
        out = cat(dim,out,varargin{:});
      end;
      
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
    
    function out = plot(obj,varargin)
      
      p = inputParser;
      p.KeepUnmatched = true;
      p.addParameter('type','dualplot',@(x) ischar(x));
      p.parse(varargin{:});
      
      switch lower(p.Results.type)
        case 'dualplot'
          out = crlEEG.gui.EEG.dualPlot(obj,p.Unmatched);
        otherwise
          % Use the superclass plot method otherwise.
          out = plot@MatTSA.timeseries(obj,varargin{:});
      end
    end
    
    %% Methods with their own m-files
    EEG = setReference(EEG,method);
    
  end
  
  methods (Access=protected)
    function [out, varargout] = subcopy(obj,varargin)
      
      [out,dimIdx] = subcopy@MatTSA.timeseries(obj,varargin{:});
      
      if ~isempty(out.EVENTS)
        timeIdx = dimIdx{obj.timeDim}; % Get indices used for time referencing
        newEVENTS = out.EVENTS;
        removeEvents = [];
        
        if isequal(timeIdx,':')
          % Unmodified time axis
                    
        else
          % Need to shift event timing.
          for idxEvent = 1:numel(out.EVENTS)
            currEVENT = newEVENTS(idxEvent);
            
            if ( currEVENT.latency>min(timeIdx) ) && ...
                ( currEVENT.latency<max(timeIdx) )
              
              % Find closest sample in the new index set
              [~,newSampleLatency] = min(abs(out.EVENTS(idxEvent).latency-timeIdx));
              
              newEVENTS(idxEvent).latency = newSampleLatency;
              newEVENTS(idxEvent).latencyTime = out.tRange(1) + (newSampleLatency-1)*(1/obj.sampleRate);
            else
              removeEvents = [removeEvents idxEvent];
            end;
          end
          newEVENTS(removeEvents) = [];
          out.EVENTS = newEVENTS;
        end;
      end
      
      if nargout>1
        varargout{1} = dimIdx;
      end;
      
    end
  end;
  
  methods (Static=true)
    fOut = standardFilters(fType,sampleRate,varargin);
  end
  
end
