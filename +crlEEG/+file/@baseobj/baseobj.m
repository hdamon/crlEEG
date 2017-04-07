classdef (Abstract) baseobj < handle
%
% classdef crlEEG.file.BASEOBJ < handle
%
% Abstract superClass for all other filetypes.
%
% To use in the constructor for a derived class:
%    f = obj@FILE(fname,fpath,validExts);
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
%   existsOnDisk  :  Boolean value.  Returs exist([obj.fpath obj.fname],'file');
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
  end
  
  properties (Dependent = true, Hidden=true);    
    existsOnDisk;
    fname_short;
    fext;
    date;
  end
  
  properties (Access=protected)
    
  end
      
  properties (Abstract, Constant, Hidden = true)
    validExts;
  end;
          
  methods
    %% Object Constructor

    function obj = baseobj(fname,fpath)            
      if nargin>0
        
        if isa(fname,'baseobj'), 
          obj.fname = fname.fname; 
          obj.fpath = fname.fpath;          
          return; 
        end;
        
        % Check if fname contains the full path
        [path, name, ext] = fileparts(fname);
        
        % Get the actual filename
        fname = [name ext];
        
        % Determine which variable contains the path.        
        if ~isempty(path) % Found a path in fname        
          if ~exist('fpath','var')||isempty(fpath)
            % Use the path defined in fname if nothing else provided
            fpath = path; 
          else
            % If a path was identified from fname, and fpath is not empty,
            % error out because of conflict.`
            error('Define path either in fname or fpath, but not both'); 
          end
        end;
                  
        % Path defaults to the present working directory                
        if ~exist('fpath','var')||isempty(fpath), fpath = pwd; end;
        
        % Check that the path exists, and make sure we have the full path
        %
        % Note that if both [pwd '/' path] and [path] exist as directories
        % (unlikely, but technically possible), that this defaults to the
        % [pwd '/' path] option.                                
        obj.fpath = fpath;
        
        % Define filename and check if it exists
        obj.fname = fname;                
                        
      end;
    end;
  

    %% Functionality for checking filenames
    function set.fname(obj,fname)
      % Set the filename,             
      if ~isempty(obj.validExts)
        [path,name,ext] = fileparts(fname);
        if validatestring(ext,obj.validExts)
          obj.fname = [name ext];
          if ~isempty(path)
            error('Cannot set file path for a crlEEG.file.NRRD object this way');
          end;
        else
          error(['File must have one of these extensions: ' obj.validExts{:}]);
        end
      else
        obj.fname = fname;
      end
      
    end;
    
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
      obj.fpath = crlEEG.file.baseobj.checkPath(fpath);
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
  end % Static Methods
  
  %% Abstract Methods
  methods (Abstract)
    read(fileIn,varargin);
    write(fileIn,varargin);
  end;
  
end
