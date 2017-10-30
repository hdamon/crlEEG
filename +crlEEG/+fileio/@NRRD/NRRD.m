classdef NRRD < crlEEG.fileio.baseobj & matlab.mixin.Copyable
  % Object for reading/manipulating NRRD files
  %  
  % Usage:
  %   nrrdObj = FILE_NRRD(fname,fpath,readonly)
  %
  % Inputs (All are optional):
  %   fname : Name of NRRD file
  %           DEFAULT: Temporary Filename
  %   fpath : Path of NRRD file
  %           DEFAULT: With fname provided: Current Matlab directory
  %                    Without fname provided: Temporary directory
  %   readonly : Flag to set NRRD as read only.
  %           DEFAULT: FALSE
  %
  % NRRD will handle both .nrrd files, in raw or gzip compressed data
  % forms, as well as separate header/data NRRDs. For separated files, the
  % filename of the header should be provided to the constructor.
  %
  % Currently, NRRD supports a subset of the possible fields that can
  % be assigned to a NRRD file:
  %   content
  %   type
  %   dimension
  %   space
  %   sizes
  %   endian
  %   encoding
  %   spaceorigin
  %   kinds
  %   thicknesses
  %   spacedirections
  %   spaceunits
  %   centerings
  %   measurementframe
  %   
  %
  % Written By: Damon Hyde
  % Last Edited: Aug 22, 2016
  % Part of the cnlEEG Project
  %
  
  properties (Constant, Hidden=true)
    validExts = {'.nrrd', '.nhdr'};
  end;
    
  properties   
    %% NRRD Header Fields
    content     = '???';
    type        = '???';
    dimension   = '???';
    space       = '???';
    sizes       = '???';
    endian      = '???';
    encoding    = '???';
    spaceorigin = [NaN NaN NaN];
    
    % tensor has to have headerInfo.kinds = [{'3D-masked-symmetric-matrix'} \
    % {'space'} {'space'} {'space'}];
    kinds = [{'???'} {'???'} {'???'}];
    
    thicknesses = NaN; %: don't care for now
    
    % space directions: tensor data is expected to have 10 values (the first
    % one representing 'none', scalar data is expected to have 9 values
    spacedirections = [NaN NaN NaN; NaN NaN NaN; NaN NaN NaN];
    
    % these fields are optional:
    spaceunits = [{'???'} {'???'} {'???'}];
    centerings = [{'???'} {'cell'} {'cell'} {'cell'}];
    measurementframe = [NaN NaN NaN; NaN NaN NaN; NaN NaN NaN];
    
    % For use with separate header/data files
    data
        
  end
  
  properties ( Dependent = true )
    matlabtype
    data_fname
  end;
  
  properties (Dependent = true, Transient = true);
    gridSpace
    domainDims
    nonZeroVoxels
    zeroVoxels
    nVoxels    
    aspect
  end;
  
  properties (Hidden = true)
    imgRanges;
  end
  
  properties (Access = private)
    data_fname_stored;
    data_fname_matching_fname;
  end;
  
  properties (Access = private, Dependent = true)
    DEFAULT_DATA_FNAME
  end
  
  properties ( GetAccess=public, SetAccess=protected )
    hasData = false;
  end
  

  
  methods
    
    function obj = NRRD(varargin)
      % Constructor for file_NRRD objects.
      %
      % function obj = file_NRRD(fname,fpath)
      %
          
      
      %% Input Parsing
      
      % Test Functions
      fnameFcn = @(x) isempty(x)||isa(x,'crlEEG.fileio.NRRD')||...
                        (ischar(x) && ~ismember(lower(x),{'readonly'}));
      fpathFcn = @(x) isempty(x) || ...
                        (ischar(x) && ~ismember(lower(x),{'readonly'}));
      
      % Input Parser Object
      p = inputParser;
      p.KeepUnmatched = true;
      p.addOptional('fname',[],fnameFcn);
      p.addOptional('fpath',[],fpathFcn);      
      p.parse(varargin{:});
            
      %% Call Parent Constructor
      obj = obj@crlEEG.fileio.baseobj(p.Results.fname,p.Results.fpath,...
                                      p.Unmatched);      
      
      %% Assign Properties
      % If a crlEEG.fileio.NRRD object was 
      if isa(varargin{1},'crlEEG.fileio.NRRD')    
        obj.copyFields(varargin{1});
        return;
      end;
      
      % If the NRRD file exists on disk, read the header.
      if obj.existsOnDisk
        obj.read;
      else
        disp(['NRRD not located on disk. Creating empty object']);
      end;
      
    end
    
    function read(obj)
      % Read NRRD
      %
      % function read(obj)
      %
      % This only reads the header information. To read data, access
      % obj.data.
      %
      readHeader(obj);
    end
    
    function write(obj)
      if ~obj.readOnly
        writeHeader(obj);
        writeData(obj);
      else
        warning('NRRD is flagged as read only');
      end;
    end
    
    function save(obj)
      warning('NRRD.save is deprecated. Please use NRRD.write instead');
      write(obj)
    end

    
    function set.data_fname(obj,fname)
      
      assert(isequal(obj.fext,'.nhdr'),['Do not set data_fname unless using ' ...
        'separate data and header files']);
      
      if (isequal(fname,obj.DEFAULT_DATA_FNAME))
        % If the provided format fits the default, don't save anything
        return;
      else
        % Otherwise save the desired data_fname, and store the associated
        % header filename, to make sure nothing changes.
        obj.data_fname_stored = fname;
        obj.data_fname_matching_fname = obj.fname;
      end;
    end
    
    function fname = get.data_fname(obj)
      
      if isequal(obj.fext,'.nrrd')
        fname = [];
      elseif isequal(obj.fext,'.nhdr');
        if isempty(obj.data_fname_stored)
          fname = obj.DEFAULT_DATA_FNAME;
        else
          if isequal(obj.fname,obj.data_fname_matching_fname)
            % The current header file name matches the one at the time the
            % data_fname was set
            fname = obj.data_fname_stored;
          else
            warning(['data_fname was set, and the filename appears to '...
              'have changed. Clearing data_fname and using default']);
            obj.data_fname_stored = [];
            obj.data_fname_matching_fname = [];
            fname = obj.DEFAULT_DATA_FNAME;
          end;
        end;
      else
        assert(false,'File extension does not appear to be a NRRD');
      end;
      
    end
    
    function [fname] = get.DEFAULT_DATA_FNAME(obj)
      [~,name,ext] = fileparts(obj.fname);
      switch obj.encoding
        case 'raw'
          fname = [name '.raw'];
        case {'gz', 'gzip'}
          fname = [name '.gz'];
        case {'txt','text','ascii'}
          fname = [name '.txt'];
        otherwise
          assert(false,'Unknown encoding type');
      end;
    end;
    
    function purgeData(obj)
      warning('NRRD.purgeData is deprecated. use obj.data=[] instead');
      obj.data = [];
    end
    
    function out = get.data(obj)
      if ~obj.hasData
        try
          crlEEG.disp(['Reading Data for ' obj.fname ]);
          obj.readData;
          obj.hasData = true;
        catch
          disp(['Error reading data for ' obj.fname]);
          keyboard;
          obj.data = [];
        end;
      end
      out = obj.data;
    end
    
    function set.data(obj,val)
      % function set.data(obj,val)
      %
      % Overloaded set function for file_NRRDData.data.  This does a bunch
      % of data checking to make sure that the NRRD isn't getting too
      % screwed up.
      %
      % Allows:
      %  1) Clearing of data, ie: obj.data = [];
      %  2) Setting of data to the default value. ie: obj.data = '???';
      %  3) Setting of data, as long as the size of the new value matches
      %        obj.sizes.
      %
      dataSize = size(val);
      if all(dataSize==0)
        crlEEG.disp('Clearing data field');
        obj.data = '???';
        obj.hasData = false;
      elseif strcmpi(val,'???');
        crlEEG.disp('Setting default data field');
        obj.data = val;
        obj.hasData = false;
      elseif (numel(dataSize)==numel(obj.sizes))&&all(dataSize==obj.sizes)
        obj.data = val;
        obj.hasData = true;
      else
        error('Attempting to change the size of the NRRD data');
      end;
      obj.imgRanges = [];
    end
    
    function DownSample(obj,level,method)
      warning('Use nrrd.downSample instead');
      if ~exist('level','var'), level = []; end;
      if ~exist('method','var'), method = []; end;
      
      downSample(obj,level,method);
    end;
    
    
    function out = get.matlabtype(obj)
      out = obj.getMatlabType;
    end;
    
    function out = get.gridSpace(obj)
      % function out = get.gridSpace(obj)
      %
      % Returns the cnlGridSpace associated with the NRRD.  This is
      % equivalent to calling
      % out=cnlGridSpace(sizes,obj.spaceorigin,obj.spacedirections)
      % where sizes has been extracted from obj.sizes to include only spatial
      % domain dimensions.
      assert(~isempty(obj.spaceorigin)&&~isempty(obj.spacedirections),...
        'NRRD must have a valid spaceorigin and spacedirections to obtain a gridSpace');
      
      
      sizes = obj.sizes(obj.domainDims);
      out = cnlGridSpace(sizes,obj.spaceorigin,obj.spacedirections);
    end
    
    function out = get.domainDims(obj)
      % function out = get.domainDims(obj)
      %
      %
      out = false(1,length(obj.sizes));
      for i = 1:length(obj.sizes)
        if strcmpi(obj.kinds{i},'domain');
          out(i) = true;
        end
      end
    end
    
    function out = get.zeroVoxels(obj)
      % function out = get.zeroVoxels(obj)
      %
      % Return list of indices into domain dimensions of voxels with a
      % nonzero value in any of the associated non-domain dimensions.
      %
      if ~strcmpi(obj.sizes,'???')
        domainDims = obj.domainDims;
        sizes   = obj.sizes;
        nVoxels = prod(sizes(domainDims));
        nData   = prod(sizes(~domainDims));
        
        tmp = reshape(obj.data,[nData nVoxels]);
        tmp = sum(tmp,1);
        out = find(tmp==0);
      else
        warning(sprintf(['Requested zeroVox from a NRRD with undefined sizes.\n' ...
          'Returning an empty vector']))
        out = [];
      end;
    end
    
    
    function out = get.nonZeroVoxels(obj)
      % function out = get.nonZeroVoxels(obj)
      %
      % Return list of indices into domain dimensions of voxels with a
      % nonzero value in any of the associated non-domain dimensions.
      %
      if ~strcmpi(obj.sizes,'???')
        domainDims = obj.domainDims;
        sizes   = obj.sizes;
        nVoxels = prod(sizes(domainDims));
        nData   = prod(sizes(~domainDims));
        
        tmp = reshape(obj.data,[nData nVoxels]);
        tmp = sum(tmp,1);
        out = find(tmp~=0);
      else
        warning(sprintf(['Requested nonZeroVox from a NRRD with undefined sizes.\n' ...
          'Returning an empty vector']))
        out = [];
      end;
    end
    
    function out = get.nVoxels(obj)
      % function out = get.nVoxels(obj)
      %
      % Get the total number of voxels in the volume.
      if ~strcmpi(obj.sizes,'???')
        domainDims = obj.domainDims;
        out = prod(obj.sizes(domainDims));
      else
        out = [];
      end;
    end
    
    function out = isscalar(nrrdIn)
      % function out = isscalar(nrrdIn)
      %
      % Returns a boolean true value if all members of the kinds field are
      % "domain".  Returns boolean false otherwise.
      out = false;
      if all(strcmp(nrrdIn.kinds,'domain'))
        out = true;
      end;
    end
    
        
    function aspect = get.aspect(nrrdIn)
      aspect = sqrt(sum(nrrdIn.spacedirections.^2,1));
    end;
    
    
    function aspect = getAspect(nrrdIn)
      % function aspect = getAspect(nrrdIn)
      %
      % Get the voxel aspect ratio, computed as the norm of each column of
      % nrrdIn.spacedirections
      warning('getAspect is deprecated. Use obj.aspect instead');
      aspect = nrrdIn.aspect;
    end;
    
    function normalizeVectors(nrrdIn)
      % function normalizeVectors(nrrdIn)
      %
      % Normalize the lengths in a vectorfield
      
      switch nrrdIn.kinds{1}
        case {'vector', 'covariant-vector'}
          Norms = sqrt(squeeze(sum(nrrdIn.data.^2,1)));
          
          foo = zeros([3 size(Norms)]);
          foo(1,:,:,:) = Norms;
          foo(2,:,:,:) = Norms;
          foo(3,:,:,:) = Norms;
          Q = find(foo>0);
          nrrdIn.data(Q) = nrrdIn.data(Q)./foo(Q);
        otherwise
          warning('NRRD Is not a vector image');
      end;
    end;
    
    %% Methods with their own m-files
    downSample(nrrdIn,downSampleLevel,method);
    nrrdOut = convertToRGB(nrrdIn,fname,fpath);
    %img = GetSlice(nrrdIn,axis,slice,varargin);
    nrrdView = view(obj,varargin);
    nrrdView = threeview(obj,varargin);
    nrrdView = threeViewWithData(obj,data,overlay);
    rangeOut = getImageRange(obj,type,collapseVec);
    out = getSlice(nrrdObj,varargin);
    copyFields(obj,source);
    
  end
  
  methods (Access=private)
    [matlabtype] = getMatlabType(nrrdObj);
    parseHeaderField(nrrdObj,fieldname,value);
    readHeader(nrrdObj);
    readData(nrrdObj);
    writeHeader(nrrdObj);
    writeData(nrrdObj);
    
  end
  
end

