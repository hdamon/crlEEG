classdef EEG_event
  % Class for EEG Events
  %
  % Constructor
  % -----------  
  %  obj = EEG_event(latency,type,description)
  %
  % Properties
  % ----------
  %   description:
  %   type:
  %   latency: Latency of the event (in samples)
  %
  %
  properties
    description
    type
    latency
  end
  
  methods
    
    function obj = EEG_event(latency,type,description)
      
      if nargin>0&&~isempty(latency)
        % Events are primarily described by their latencies
        assert(isnumeric(latency)&&isvector(latency),...
          'Latency must be a numeric vector');
        nEvents = numel(latency);
        
        % Check input types
        assert(isnumeric(type)&&isvector(type),...
          'Type must be a numeric vector');
        if isscalar(type)
          type(1:nEvents) = type;
        end
        assert(numel(type)==nEvents,...
          'Must provide either a single type or one per event');
        
        if exist('description','var')
          % Check input Descriptions
          assert(ischar(description)||iscellstr(description),...
            'Description must be a character string or cellstr');
          if ischar(description),
            description = {description};
          end;
          if isscalar(description),
            description(1:nEvents) = description;
          end;
          assert(numel(description)==nEvents,...
            'Must provide either a single description or one per event');
        else
          description(1:nEvents) = {''};
        end;
        
        if numel(latency)>1
          % Recurse for multiple objects
          for i = 1:numel(latency)
            obj(i) = crlEEG.type.EEG_event(latency(i),type(i),description{i});
          end
          return
        end
        
        % Instantiate Single Object
        obj.latency = latency;
        obj.type = type;
        obj.description = description{1};
        
      end
    end
    
    function out = get.type(obj)
      out = [];
      for i = 1:numel(obj)
        out = [out obj(i).type];
      end;
    end
    
    function out = eventNames(obj)
      out = {};
      for i = 1:numel(obj)
        out = {out{:} obj(i).description};
      end;
    end
    
    function out = isempty(obj)
      % Returns true if the entire array obj is full of empty
      % crlEEG.type.EEG_event objects
      %
      if numel(obj)==1      
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
