classdef EV2 < crlEEG.fileio.baseobj
  % Object class for EV2 Files
  %
  % classdef file_EV2 < file
  %
  %
  % Properties:
  %   ID
  %   Type
  %   Response
  %   Acc
  %   RT
  %   Offset
  %   useTypes
  %  
  % Dependent Properties:
  %   dataByType
  %
  % Written By: Damon Hyde
  % Last Edited: July 30, 2015
  % Part of the cnlEEG Project
  %
  
  properties
    ID
    Type
    Response
    Acc
    RT
    Offset
    useTypes
  end
  
  properties
    dataByType
  end
  
  properties (Constant, Hidden=true)
    validExts = {'.ev2'};
  end
  
  methods
    
    function obj = file_EV2(fname,fpath)
            
      % Input Parser Object
      p = inputParser;
      p.KeepUnmatched = true;
      p.addOptional('fname',[],@(x) crlEEG.fileio.baseobj.fnameFcn(x,'crlEEG.fileio.EV2'));
      p.addOptional('fpath',[],@(x) crlEEG.fileio.baseobj.fpathFcn(x));      
      p.parse(varargin{:});
            
      %% Call Parent Constructor
      obj = obj@crlEEG.fileio.baseobj(p.Results.fname,p.Results.fpath,...
                                      p.Unmatched);         
        if obj.existsOnDisk
          obj.read;
        end                     
    end
    
    function read(obj)
      returnDIR = pwd;
      cd(obj.fpath);
      fid = fopen(obj.fname,'r');
      
      if fid<0, 
        warning(['File "', obj.fname,'" does not exist!']);
        keyboard;
      end;
      
              header = fgetl(fid);
        data = textscan(fid,'%d %f %d %d %d %f');
        
        obj.ID = data{1}';
        obj.Type = data{2}';
        obj.Response = data{3}';
        obj.Acc = data{4}';
        obj.RT = data{5}';
        obj.Offset = data{6}';
      
        obj.useTypes = unique(obj.Type);
    end
    
    function out = get.dataByType(obj)
      typeList = unique(obj.Type);
           
      tmp = ismember(typeList,obj.useTypes);
      typeList = typeList(tmp);
     
      out = cell(numel(typeList),1);
      
      for i =1:numel(typeList)
        Q = find(obj.Type==typeList(i));
        out{i}.ID = obj.ID(Q);
        out{i}.Type = obj.Type(Q);
        out{i}.Response = obj.Response(Q);
        out{i}.Acc = obj.Acc(Q);
        out{i}.RT = obj.RT(Q);
        out{i}.Offset = obj.Offset(Q);
      end;            
    end
    
    function write(obj)
      error('Writing EV2 files not currently supported');
    end
    
  end
  
end
