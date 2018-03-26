classdef (Abstract) baseobj < handle 
% classdef crlEEG.fileio.BASEOBJ < handle
%
% Abstract superClass for all other filetypes.
%
% To use in the constructor for a derived class:
%    f = obj@FILE(fname,fpath,validExts);
%
% crlEEG.fileio.basobj is an abstract class definition for file
% reader/writer objects. It provides basic filename and path handling, as
% well as 
%
% Creates a file object for the file located at [fpath fname]. Checks that
% the file extension for fname is in the list validExts.  If fpath is not
% provided (or is empty), then tries to identify a path from fname.  If
% that's not available, defaults to looking in the current directory.
%
% Properties: 
%   fname       : File name
%   fpath       : Path to file (Automatically turned into an absolute path)
%   validExts   : List of valid file extensions (optional)
%
% Dependent Properties
%   fname_short   :  Filename without extension
%   fext          :  File extension alone (includes leading . )
%   fullfile      :  Full file location with path
%   existsOnDisk  :  Boolean value.  Returs exist([obj.fullfile],'file');
%   date          :  Last edited date for the file
%
% Abstract Methods: (Must be defined in child classes)
%   read(obj,varargin)   :  Method to read from disk
%   write(obj,varargin)  :  Method to write to disk
%
% Written By: Damon Hyde
% Created: Dec 10, 2013
% Edited: March 10, 2016
% Part of the cnlEEG Project
%

  properties
    fname;
    fpath;      
    readOnly;
  end
  
  properties (Dependent = true, Hidden=true);    
    existsOnDisk;
    fname_short;
    fext;
    fullfile;
    date;
  end
  
  properties (Access=protected)
    
  end
      
  properties (Abstract, Constant, Hidden = true)
    validExts;
  end;
          
  methods
    %% Object Constructor

    function obj = baseobj(varargin)
      
      if nargin>0
        
        % If a crlEEG.fileio.baseobj object was passed in, return a new
        % object with the properties copied.
        if isa(varargin{1},'crlEEG.fileio.baseobj')
          obj.fname = varargin{1}.fname;
          obj.fpath = varargin{1}.fpath;   
          obj.readOnly = varargin{1}.readOnly;
          return;
        end;
        
        % Otherwise, parse as a fname/fpath pair.
        p = inputParser;
        p.addOptional('fname',[],@(x) isempty(x)||ischar(x));
        p.addOptional('fpath',[],@(x) isempty(x)||ischar(x));        
        p.addParamValue('readOnly',false,@(x) islogical(x));
        p.parse(varargin{:});
        
        [fName, fPath] = ...
          crlEEG.fileio.checkFileNameAndPath(p.Results.fname,p.Results.fpath);
        
        fName = crlEEG.fileio.validateFileExtension(fName,obj.validExts);
        
        obj.fname = fName;
        obj.fpath = fPath;
        obj.readOnly = p.Results.readOnly;
        
      end;
    end;
  

    %% Functionality for checking filenames
    function set.fname(obj,fname)
      % Set the filename, 
      obj.fname = crlEEG.fileio.validateFileExtension(fname,obj.validExts);           
    end;
    
    function out = get.fullfile(obj)
      out = fullfile(obj.fpath,obj.fname);
    end;
    
    function out = get.date(obj)
      d = dir(obj.fullfile);
      out = d.date;
    end
    
    function out = get.fname_short(obj)
      % Returns the filename without its extension
      [~,out,~] = fileparts(obj.fname);
    end;
    
    function out = get.fext(obj)
      % Returns the file extension, with leading period.
      [~,~,out] = fileparts(obj.fname);
    end;
    
    function out = get.existsOnDisk(obj)
      % Returns true if the file exists on disk.
      out = exist([obj.fpath obj.fname],'file');        
    end
            
    %% Functionality for Checking Paths
    function set.fpath(obj,fpath)
      obj.fpath = crlEEG.fileio.baseobj.checkPath(fpath);
    end;
                           
  end % Methods
  
  %% Static Protected Methods
  methods (Static=true, Access=protected)
    
    function fpath = checkPath(fpath)
      % Validate the provided path, ensuring that it is both an absolute
      % path, and includes a file separator at the end.
      %
      
      if exist(['./' fpath],'dir') 
        % If path is relative, pad with current working directory.
        fpath = [pwd '/' fpath];
      elseif exist(fpath,'dir') 
        % If path is absolute, just use it.
        fpath = fpath;
      else
        warning off backtrace
        warning(['Can''t locate directory: ' fpath ]);
        warning on backtrace
        fpath = './';
      end;
      
      % Get full path 
      fpath = fullfile([fpath filesep]);     
    end;      
    
    function out = fnameFcn(in,objtype)
      out = isempty(in) || isa(in,objtype) || ...
                (ischar(in) && ~ismember(lower(in),{'readonly'}));
    end
    
    function out = fpathFcn(in)
      out = isempty(in) ||  ...
                (ischar(in) && ~ismember(lower(in),{'readonly'}));
    end
      
    
  end % Static Methods
  
  %% Abstract Methods
  methods (Abstract)
    read(fileIn,varargin);
    write(fileIn,varargin);
  end;
  
end
