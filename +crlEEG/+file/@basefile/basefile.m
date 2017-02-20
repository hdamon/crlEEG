classdef basefile < handle
%
% classdef BASEFILE < handle
%
% SuperClass for all other filetypes.
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
    
  properties (Hidden = true)
    validExts = [];
  end;
  
  properties (Dependent = true, SetAccess = protected, Hidden = true)
    fname_short;
    fext;
  end
  
  properties (Dependent = true, SetAccess=protected);    
    existsOnDisk;
  end
  
  methods
    %% Object Constructor

    function obj = basefile(fname,fpath,validExts)            
      if nargin>0
        
        if isa(fname,'basefile'), 
          obj.fname = fname.fname; 
          obj.fpath = fname.fpath;
          obj.validExts = fname.validExts;
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
                  
        % Path defaults to the current one                
        if ~exist('fpath','var')||isempty(fpath), fpath = './'; end;
        if ~exist('validExts','var'), validExts = []; end;
        
        % Set list of valid extensions
        obj.validExts = validExts;
        
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
      %fname = checkName(obj,fname);   
            
      if ~isempty(obj.validExts)
        [path,name,ext] = fileparts(fname);
        if validatestring(ext,obj.validExts)
          obj.fname = [name ext];
          if ~isempty(path)
            obj.fpath = path;
          end;
        else
          error(['File must have one of these extensions: ' obj.validExts{:}]);
        end
      else
        obj.fname = fname;
      end
      
    end;
    
    function out = get.fname_short(obj)
      [~,out,~] = fileparts(obj.fname);
    end;
    
    function out = get.fext(obj)
      [~,~,out] = fileparts(obj.fname);
    end;
    
    function out = get.existsOnDisk(obj)
      out = exist([obj.fpath obj.fname],'file');        
    end
            
    %% Functionality for Checking Paths
    function set.fpath(obj,fpath)
      obj.fpath = file.checkPath(fpath);
    end;
                           
  end % Methods
  
  methods (Static=true, Access=protected)
    function fpath = checkPath(fpath)
      if exist(['./' fpath],'dir') % It's a relative path
        fpath = [pwd '/' fpath];
      elseif exist(fpath,'dir') % It's an absolute path
        fpath = fpath;
      else
        warning off backtrace
        warning(['Can''t locate directory: ' fpath ]);
        warning on backtrace
        fpath = './';
      end;
      
      fpath = file.cleanPath(fpath);
      
      % Make sure the path ends in a /
      if ~strcmpi(fpath(end),'/')
        fpath(end+1) = '/';
      end
    end;
    
    function fpath = cleanPath(fpath)
      % function fpath = cleanPath(fpath)
      %
      % Remove '/./' and '//' strings from file pathnames and replace with
      % '/'
      fpath = strrep(fpath,'/./','/');
      fpath = strrep(fpath,'//','/');            
    end;
        
%     function fpath = rmstringfrompath(fpath,string,replace)
%       % function fpath = rmstringfrompath(fpath,string,replace)
%       %
%       % Remove 'string' from 'fpath' and replace with 'replace'
%       nOff = length(string);
%       Q = strfind(fpath,string);
%       while length(Q)>0
%         fpath = [fpath(1:Q(1)-1) replace fpath(Q(1)+nOff:end)];
%         Q = strfind(fpath,string);
%       end;
%     end
    
  end % Static Methods
  
  methods (Abstract)
    read(fileIn,varargin);
    write(fileIn,varargin);
  end;
  
end
