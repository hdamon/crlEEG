classdef EEG < MatTSA.timeseries
  % Object class for EEG data
  %
  % classdef EEG < MatTSA.timeseries
  %
  % Built on the MatTSA.timeseries object class (itself built on the
  % labelledArray object class), this adds data set naming, events, and
  % tracking of applied filters.
  %
  %
  % Properties
  % ----------
  %    setname
  %    fname : (Not really used ATM)
  %    fpath
  %    EVENTS : Stores information about events
  %    filters : Stores a history of filters applied to the data
  %
  
  properties
    setname
    fname
    fpath
  end
  
  properties (Dependent = true)    
    EVENTS
  end
  
  properties
    filters = cell(0);
  end
  
  properties (Access=protected)
    EVENTS_
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
    
    function out = eventsFromEV2(obj,EV2)
      
      types = EV2.dataByType;
      newEVENTS = [];
      for i = 1:numel(types)
        for j = 1:numel(types{i}.Type)
          new = crlEEG.event('description',['Spike ' num2str(i)],...
                             'type',types{i}.Type(j),...
                             'latencyTime',types{i}.Offset(j));
          newEVENTS = [newEVENTS new];
        end;
      end
      
      newEVENTS = [obj.EVENTS newEVENTS];
      
      out = obj.copy;
      out.EVENTS = newEVENTS;
      
    end
    
    function out = get.EVENTS(obj)
      out = obj.EVENTS_;
      % Compute Latency Times
      if ~isempty(out)
      latencies = {out.latency};
      startTime = obj.tVals(1);
      sampleRate = obj.sampleRate;
      for i = 1:numel(out)
        out(i).latencyTime = startTime + (latencies{i}-1)/sampleRate;
      end
      end;
    end
    
    function set.EVENTS(obj,val)
      if isempty(val), obj.EVENTS_ = []; return; end;
      assert(isa(val,'crlEEG.event'));
      
      keepEVENTS = false(1,numel(val));
      for i = 1:numel(val)
        if isempty(val(i).latency)&&~isempty(val(i).latencyTime)
          % Convert a latency time into a sample latency.
          val(i).latency = round(obj.sampleRate*(val(i).latencyTime-obj.tVals(1))+1);
          val(i).latencyTime = [];
        end;
        
        % Discard events that are outside the sample collection range
        if (val(i).latency>0)&(val(i).latency<size(obj,1))
          keepEVENTS(i) = true;
        end;
                        
%         if ~isempty(val(i).latency)&&~isempty(val(i).latencyTime)
%           assert(val(i).latencyTime==(obj.tVals(1) + (val(i).latency-1)*(1/obj.sampleRate)),...
%                   'Event latencies are inconsistent');
%         elseif isempty(val(i).latencyTime)
%           val(i).latencyTime = obj.tVals(1) + (val(i).latency-1)/obj.sampleRate;
%         elseif isempty(val(i).latency)
%           val(i).latency = val(i).latencyTime*obj.sampleRate;
%         end        
      end
                  
      obj.EVENTS_ = sort(val(keepEVENTS));
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
          tmpEVENTS(i) = obj.EVENTS(i);
          tmpEVENTS(i).latencyTime = obj.EVENTS(i).latencyTime + delta;
          
        end
        obj.EVENTS = tmpEVENTS;
      end
            
    end
    
    function out = cat(dim,obj,a,varargin)
      % Concatenate timeseries objects
      %
      % Calls cat@MatTSA.timeseries, and additionally performs
      % concatenation of events.
      %
      
      assert(isa(a,class(obj)),'Can only concatenate like objects');
      
      out = cat@MatTSA.timeseries(dim,obj,a);
      
      if dim==1
        tmp = a.EVENTS;
        for i = 1:numel(tmp)
          tmp(i).latency = tmp(i).latency+size(obj,1);
          tmp(i).latencyTime = [];
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
      % Apply one of the standard filters to a crlEEG.EEG object
      %
      % EEGout = applyStandardFilter(EEGIn,fType,varargin)
      %
      % This method uses filtfilt() to perform zero-phase filtering.
      %
      % Inputs
      % ------
      %   EEGIn  : crlEEG.EEG object to filter
      %   fType  : Filter type
      % varargin : Filter Options
      %
      % Outputs
      % -------
      %  EEGout : Copy of the input object, with appropriate filter applied
      %             to the data.
      %
      % See crlEEG.EEG.standardFilters for available filter options.
      %
      EEGout = EEGIn.filtfilt(EEGIn.standardFilters(fType,EEGIn.sampleRate,varargin{:}));
    end
    
    function EEGout = filter(EEGIn,f)
      % Overloaded to add filter tracking
      EEGout = EEGIn.filter@MatTSA.timeseries(f);
      EEGout.filters{end+1} = f;
    end
    
    function EEGout = filtfilt(EEGIn,f)
      % Filtfilt for crlEEG.type.EEG objects includes tracking of all
      % applied filters in the obj.filters property.      
      %
      % EEGout = filtfilt(EEGIn,dFilter)
      %
      % Inputs
      % ------
      %    EEGIn : A crlEEG.EEG object to be filtered
      %  dFilter : A Matlab digital filter (typically created with designfilt)
      %
      % Output
      % ------
      %   EEGout : A new crlEEG.EEG object, copied from the
      %                 original, with the specified filter applied to
      %                 all data channels.
      %      
      
      EEGout = EEGIn.filtfilt@MatTSA.timeseries(f);
      EEGout.filters{end+1} = f;
    end
    
    function n = numArgumentsFromSubscript(obj,s,indexingContext)
      % Not 100% necessary, but nice to have
      n = numArgumentsFromSubscript@MatTSA.timeseries(...
        obj,s,indexingContext);
    end
    
    function out = plot(obj,varargin)
      % Plot function for crlEEG.EEG objects
      %
      % crlEEG.EEG objects have a dualPlot function that overloads the
      % version from MatTSA.timeseries.
      %
      
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
      
      %% Copy EVENTS and adjust latency appropriately.
      if ~isempty(out.EVENTS)
        timeIdx = dimIdx{obj.timeDim}; % Get indices used for time referencing
        newEVENTS = out.EVENTS;
        removeEvents = [];
        
        if isequal(timeIdx,':')
          % Unmodified time axis                    
        else
          % Need to shift event timing.
          startTime = out.tRange(1);
          sampleRate = obj.sampleRate;
          
          latencies = {newEVENTS.latency};
          
          for idxEvent = 1:numel(out.EVENTS)               
            if ( latencies{idxEvent}>min(timeIdx) ) && ...
                ( latencies{idxEvent}<max(timeIdx) )
              
              % Find closest sample in the new index set
              [~,newSampleLatency] = min(abs(latencies{idxEvent}-timeIdx));
              newLatencyTime = startTime + (newSampleLatency-1)*(1/sampleRate);
                            
              newEVENTS(idxEvent).latency = newSampleLatency;
              newEVENTS(idxEvent).latencyTime = newLatencyTime;
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
    
    function [bands,varargout] = standardBands(type)
      % Returns standard EEG frequency bands 
      %
      % Inputs
      % ------
      %   type : String to declare desired output format. 
      %             DEFAULT: 'standard'
      %
      % Output Formats
      % --------------
      %        'standard' : 
      %   'subreferenced' : 
      %
      %
      if ~exist('type','var'), type = 'standard'; end;
      
      bandNames = {'0.5-4','4-7','7-13','8-13','13-30','30-50','50-70','70-100','>100'};
      
      switch lower(type)
        case 'standard'
          % Standard EEG Frequency Bands, sampled at 4 Samples/Hz
          bands{1} = linspace(0.5,4,15); % Delta
          bands{2} = linspace(4.25,7,12); % Theta
          bands{3} = linspace(7.25,13,24); % Alpha
          bands{4} = linspace(8.25, 13,20); % Mu
          bands{5} = linspace(13.25,30,68); % Beta
          bands{6} = linspace(30.25,50,80); % Gamma
          bands{7} = linspace(50.25,70,80);
          bands{8} = linspace(70.25,100,120);
          bands{9} = linspace(100.25,150,200);
          
          if nargout>1
            %varargout{1} = {'Delta' , 'Theta', 'Alpha', 'Mu', 'Beta', 'LowGamma','MidGamma','HighGamma','Over100'};
            varargout{1} = bandNames;
          end;
        case 'subreferenced'
          fullSpectrum = [0.5:0.25:150];
          
          bands{1} = [1:15];
          bands{2} = [16:27];
          bands{3} = [28:51];
          bands{4} = [32:51];
          bands{5} = [52:119];
          bands{6} = [120:199];
          bands{7} = [200:279];
          bands{8} = [280:399];
          bands{9} = [400:599];
          
          if nargout==2
            varargout{1} = fullSpectrum;
          elseif nargout>2
            varargout{1} = bandNames;
            varargout{2} = fullSpectrum;
          end
          
      end
      
    end
    
    
  end
  
end
