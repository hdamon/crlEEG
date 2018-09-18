classdef event
  % Class for EEG Events
  % --------------------
  %  
  % Constructor
  % -----------
  %  obj = event(varargin)
  %
  % Param-Value Properties
  % ----------
  %   description :
  %          type :
  %       latency : Latency of the event (in samples)
  %   latencyTime : Time of the event (in seconds or other time units)
  %
  % When constructing an event, either (or both) the sample latency and
  % time latency can be assigned. When assigned to the EVENTS field of a
  % crlEEG.EEG object, the two values will be checked for consistency, with
  % the assumption that:
  %
  %     obj.latencyTime = EEG.tVals(1) + (obj.latency-1)*EEG.sampleRate;
  %
  % This assumes even temporal sampling in the EEG signal.
  %
  % If only one of the two latency values has been set when assigned to an
  % EEG object, the other value will be populated based on the same
  % assumption as above.
  % 
  %
  %
  properties
    description
    type
    latency
    latencyTime
  end
  
  properties (Hidden = true)
    line % Gui object
  end
  
  methods
    
    function obj = event(varargin)
      %% Constructor for crlEEG.event objects
      if nargin>0
        
        %% Input Parsing
        p = inputParser;
        p.addParameter('latency',[],@(x) isempty(x)||isnumeric(x)&&isvector(x));
        p.addParameter('latencyTime',[],@(x) isempty(x)||isnumeric(x)&&isvector(x));
        p.addParameter('type',[], @(x) isempty(x)||isnumeric(x)&&isvector(x));
        p.addParameter('description',[],@(x) isempty(x)||ischar(x)||iscellstr(x));
        p.parse(varargin{:});
        
        latency     = p.Results.latency;
        latencyTime = p.Results.latencyTime;
        type        = p.Results.type;
        description = p.Results.description;
        
        % Get number of events    
        if iscell(description) && ( numel(description)==1 )
          % Strip off cell wrapper for single descriptions
          description = description{1};
        end;
        
        if ischar(description)
          nDesc = 1;
        else
          nDesc = numel(description);
        end;
        
        nEvent = max([numel(latency) numel(latencyTime) numel(type) nDesc]);
        
        % Each value must either be empty, or match the number of events
        assert(ismember(numel(latency),[0 nEvent]),...
          'Inconsistent number of latencies provided');
        assert(ismember(numel(latencyTime),[0 nEvent]),...
          'Inconsistent number of latency times provided');
        assert(ismember(numel(type),[0 nEvent]),...
          'Inconsistent number of types provided');
        assert(ismember(nDesc,[0 nEvent]),...
          'Inconsistent number of descriptions provided');
        
        %% Recurse if multiple events are provided.
        if nEvent>1
          for i = 1:nEvent
            if isempty(latency)
              nextLatency = [];
            else
              nextLatency = latency(i);
            end;
            
            if isempty(latencyTime)
              nextLatencyTime = [];
            else
              nextLatencyTime = latencyTime(i);
            end
            
            if isempty(type)
              nextType = [];
            else
              nextType = type(i);
            end;
            
            if isempty(description)
              nextDescription = [];
            else
              nextDescription = description{i};
            end;
            
            obj(i) = crlEEG.event('latency',nextLatency,...
              'latencyTime',nextLatencyTime,...
              'type',nextType,...
              'description',nextDescription);
          end
          return;
        end
                
        %% Instantiate Single Object
        obj.latency     = latency;
        obj.latencyTime = latencyTime;
        obj.type        = type;
        obj.description = description;
        
      end
    end
    
    function [objOut,idx] = sort(obj,varargin)
      [~,idx] = sort([obj.latency]);
      
      objOut = obj(idx);
    end
    
    function obj =  plot(obj,ax,varargin)
      % Plot a crlEEG.event on an axis
      %
      % Inputs
      % ------
      %       obj : crlEEG.event object to plot
      %        ax : Axis to plot to. Opens new figure if not provided;
      %  varargin : All additional parameters are passed directly to the 
      %               main Matlab plot function.
      %
      % Output
      % ------
      %      obj : crlEEG.event object
      %
      
      
      %
      if ~exist('ax','var'), figure; ax = axes; end;
                    
      
      axes(ax); hold on;
      yRange = get(ax,'YLim');
      xRange = get(ax,'XLim');
      tmp = get(ax,'ButtonDownFcn');
      
      for i = 1:numel(obj)
                                              
      xVal = obj(i).latencyTime;
      
      if ( xVal>xRange(1) ) && (xVal<xRange(2))                              
        plot([xVal xVal],yRange,varargin{:},'ButtonDownFcn',tmp);
        if ~isempty(obj(i).description)
        text(xVal+0.005*(xRange(2)-xRange(1)),0.95*yRange(2),obj(i).description);
        end;        
      end
      
      end
      set(ax,'ButtonDownFcn',tmp);        
      hold off;      
    end
    
    
    function out = isempty(obj)
      % Returns true if the entire array obj is full of empty
      % crlEEG.event objects
      %
      if numel(obj)==0
        out = true;
      elseif numel(obj)==1
        out = isempty(obj.description)&&isempty(obj.type)&&isempty(obj.latency);
      else
        isEmpty = true;
        for i = 1:numel(obj)
          out = isEmpty&&obj(i).isempty;
        end;
      end;
    end
    
  end
  
end
