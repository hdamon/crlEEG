classdef EDF < crlBase.baseFileObj
  % classdef EDF < crlBase.baseFileObj
  %
  % Object class for EDF files.
  %
  % USAGE: out = EDF(filename,filepath)
  %
  % Inherited Properties:
  %   fname        : Name of EDF File
  %   fpath        : Path to EDF File
  %   validExts    : Cell array of valid EDF extensions (Just .edf)
  %   existsOnDisk : Boolean value, true if file exists in defined location
  %
  % Properties:
  %   data    : Data as read by biosig. Time by Electrodes
  %   header  : Header as read by biosig
  %   nEpochs : Number of detected epochs
  %   epochs_start : start time of each detected epoch
  %   epochs_end   : end time of each detected epoch
  %
  % Dependent Properties
  %   labels    : Cell array of electrode labels, extracted from the EDF header
  %
  % Written By: Damon Hyde
  % Last Edited: Jan 16, 2015
  % Part of the cnlEEG Project
  
    
  properties (SetAccess = private, GetAccess = public)
    data
    
    nEpochs
    epochs_start
    epochs_end
  end
  
  properties (SetAccess = private, GetAccess= public, Hidden = true);
    header
  end;
  
  properties (Dependent = true)
    labels
    data_epoched
    sampleRate
  end
  
  properties (Constant,Hidden=true)
    validExts = {'.edf'};
  end
  
  methods
    
    function obj = EDF(varargin)
      
      %% Input Parsing
      
      % Test Functions
      fnameFcn = @(x) isempty(x)||isa(x,'crlEEG.fileio.EDF')||...
        (ischar(x) && ~isequal(lower(x),'readonly'));
      fpathFcn = @(x) isempty(x)||...
        (ischar(x) && ~isequal(lower(x),'readonly'));
      
      % Input Parser
      p = inputParser;
      p.KeepUnmatched = true;
      p.addOptional('fname',[],fnameFcn);
      p.addOptional('fpath',[],fpathFcn);
      p.addOptional('dataAndHeader',[]);
      p.parse(varargin{:});
      
      obj = obj@crlBase.baseFileObj(p.Results.fname,p.Results.fpath,...
                                        p.Unmatched);
                                      
      if ~isempty(p.Results.dataAndHeader)
        obj.header = p.Results.dataAndHeader{1};
        obj.data = p.Results.dataAndHeader{2};
      end;
    end
    
    %% Typecasting
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function out = MatTSA.timeseries(obj)
      % Convert EDF file to a GUI data object
      out = MatTSA.timeseries(obj.data,...
                          'chanLabels',obj.labels,...
                          'dataUnits',obj.header.PhysDim(1:size(obj.data,2)),...
                          'samplerate',obj.header.SampleRate,...
                          'tVals',(1./obj.sampleRate)*[0:(size(obj.data,1)-1)]);
    end    
    
    function out = crlEEG.EEG(obj)
      out = crlEEG.EEG(obj.data,...
                          'chanLabels',obj.labels,...
                          'dataUnits',obj.header.PhysDim(1:size(obj.data,2)),...
                          'samplerate',obj.header.SampleRate,...
                          'tVals',(1./obj.sampleRate)*[0:(size(obj.data,1)-1)],...
                          'EVENTS',crlEEG.event(obj));
    end;
        
    function out = crlEEG.event(obj)
      %% Extract EEG_event objects from the EDF Header
      %
      if isempty(obj.header.EVENT.POS)
        % If not latencies defined, return an empty object.
        out = crlEEG.event;
        return;
      end;
      
      latency = round(obj.header.EVENT.POS);
      if isfield(obj.header.EVENT,'TYP')
        type = obj.header.EVENT.TYP;
      else
        type = [];
      end;
            
      if isfield(obj.header.EVENT,'CodeDesc')
        desc(1:numel(latency)) = {'EDFEVENT'};      
        realType = type~=32766;
        desc(realType) = obj.header.EVENT.CodeDesc(type(realType));
      else
        desc = [];
      end;
      
      % Return an event object
      out = crlEEG.event('latency',latency,...
                         'type',type,...
                         'description',desc);
    end
    
    function obj = purge(obj)
      % function obj = purge(obj)
      %
      % Clear the data and header fields of the object.  THis is mostly
      % useful if the data is REALLY big, and you don't want to cart it all
      % around all the time.
      obj.data   = [];
      obj.header = [];
    end
    
    function repair(obj)
      %  function repair(obj)
      %
      %  Use 1D spline interpolation to fill in NaN values.  This is done
      %  independently for each electrode measurement.
      %
      obj.read;
      nE = size(obj.data,2);
      nT = size(obj.data,1);
      for i = 1:nE
        X = 1:nT;
        V = obj.data(:,i);
        Q = find(~isnan(V));
        if isempty(Q)
          V = zeros(size(V));
        else
          Xin = X(Q);
          Vin = V(Q);
          V = interp1(Xin,Vin,X,'spline');
        end;
        obj.data(:,i) = V;
      end
    end
    
    %% Read and write functions to complete the file abstract object type
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function read(obj)
      % function read(obj)
      %
      % Read the EDF file from disk.  Overwrites whatever values are in
      % obj.data and obj.header and, and automatically runs
      % obj.detectEpochs to find regions of zero-padding and delineate them
      % into epochs.
      %
      currentDIR = pwd;
      cd(obj.fpath);
      [obj.data, obj.header] = sload(obj.fname);
      %obj.detectEpochs;
      cd(currentDIR);
    end
    
    function write(obj)
      % function write(obj)
      %
      % Writing of EDF files is not currently supported
      %error('Writing of EDF files not currently supported');
      
      head = obj.header;
      head.FileName = fullfile(obj.fpath,obj.fname);
      head.Type = 'EDF';            
      head = sopen(head,'w');
      head = swrite(head,obj.data);
      head = sclose(head);
      obj.header = head;
                  
    end
    
    function varargout = plot(obj,varargin)
      %% Open a 
      tmp = MatTSA.timeseries(obj);
      p = tmp.plot(varargin{:});
      if nargout>0, varargout{1} = p; end;
    end;
            
    %% Get methods for the EDF Data and Header, to enable automated file
    %% reading in the event that the data hasn't been read from the file yet.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function out = get.data(obj)
      % function out = get.data(obj)
      %
      % Overloaded get method for obj.data.  This just checks to see if any
      % values have been assigned to obj.data yet, and if not, calls
      % obj.read to read them from the file.
      %
      
      if isempty(obj.data)
        obj.read;
      end
      out = obj.data;
    end
    
    function out = get.header(obj)
      % function out = get.header(obj)
      %
      % Overloaded get method for obj.header.  Checks to see if obj.header
      % is empty, and if it is, attempts to read the file from disk.
      %
      
      if isempty(obj.header)
        obj.read;
      end;
      out = obj.header;
    end
    
    %% Get methods for dependent properties
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function out = get.labels(obj)
      % function out = get.labels(obj)
      %
      % Read the electrode labels from the EDF header.  If there are more
      % labels than there are electrodes in the data, returns just the
      % first N labels, where N is size(obj.data,2) (the number of
      % electrodes).
      %
      
      if ~isempty(obj.header)
        out = obj.header.Label;
        if numel(out)>size(obj.data,2)
          out = out(1:size(obj.data,2));
        end;
      end;
    end
    
    function out = get.sampleRate(obj)
      if ~isempty(obj.header)
        out = obj.header.SampleRate;
      end;
    end;
    
    function out = get.data_epoched(obj)
      % function out = get.data_epoched(obj)
      %
      % Returns a cell array with the data for each detected epoch in a
      % separate cell.  Epochs are detected using obj.detectEpochs, and
      % then extracted from obj.data while discarding
      %if isempty(obj.nEpochs), obj.detectEpochs; end;
      if isempty(obj.nEpochs), out = []; return; end;
      out = cell(1,obj.nEpochs);
      for idx = 1:obj.nEpochs
        out{idx} = obj.data(obj.epochs_start(idx):obj.epochs_end(idx),:);
      end
    end
        
    %% Methods with their own m-files
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    detectEpochs(obj);
    out = extract_EpochsUsingEV2(obj,EV2,width);
  end
end
