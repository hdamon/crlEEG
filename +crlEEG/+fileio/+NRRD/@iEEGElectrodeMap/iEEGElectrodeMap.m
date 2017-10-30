classdef iEEGElectrodeMap < crlEEG.fileio.NRRD
  % classdef cnliEE1GElectrodeMap < crlEEG.fileio.NRRD
  %
  % Class used to import iEEG electrode locations from a labelled NRRD
  % file.
  %
  % Written By: Damon Hyde
  % Last Edited: July 18, 2016
  % Part of the cnlEEG Project
  %
     
  properties
    gridType = 'grid';
    namePrefix 
  end
  
  properties (Constant = true, Hidden = true, Access=protected)
    validTypes = {'grid' 'depth'};
  end
    
  properties (Dependent = true)
    elecLoc
    elecNodes
    elecVoxels
    elecLabels
    nElectrodes
  end
  
  properties (Constant = true)
    cond_Metal    = 8;
    cond_Silicone = 9;
  end
  
  methods
    
    function obj = iEEGElectrodeMap(fname,fpath,varargin)
      
      %% Input Parsing      
      if ~exist('fname','var'), fname = []; end;
      if ~exist('fpath','var'), fpath = []; end;
      
      % Parsing Functions
      fnameFcn = @(x) (ischar(x)&& ~ismember(lower(x),{'gridtype'}))||...
                          isa(x,'crlEEG.fileio.NRRD.iEEGElectrodeMap');
      fpathFcn = @(x) (ischar(x)&& ~ismember(lower(x),{'gridtype'}));
            
      % InputParser Object
      p = inputParser;
      p.addOptional('fname',[],fnameFcn);
      p.addOptional('fpath',[],fpathFcn);
      p.addParamValue('gridType','grid',@(x) ischar(x));
      p.parse(varargin{:});
                  
      %% Initialize parent Object
      obj = obj@crlEEG.fileio.NRRD(fname,fpath);
            
      %% Set Properties
      if isa(fname,'iEEGElectrodeMap')
        obj.gridType = fname.gridType;
      else
        obj.gridType = gridType;
      end;
      
    end
    
    function disp(obj)
      % Overloaded disp() method for crlEEG.fileio.NRRD.iEEGElectrodeMap
      % objects
      obj.disp@crlEEG.fileio.NRRD;
      disp(['          Grid Type: ' obj.gridType]);
      disp(['         Name Prefix: ' obj.namePrefix]);      
    end
    
    function set.gridType(obj,val)
      % Set the type of grid described in the NRRD file. 
      %
      % This can be either:
      %   'grid' : for use with strips and grids on the cortical surface
      %   'depth': For depth electrodes and sEEG electrodes
      %
      if validatestring(val,obj.validTypes)
        obj.gridType = val;
      else
        error('Invalid invasive electrode type')
      end;
    end
    
    function out = get.nElectrodes(obj)
      % Returns the number of electrodes in the NRRD
      out = length(unique(obj.data(:)))-1;
    end
    
    function out = get.elecLoc(obj)
      % out = get.elecLoc(obj)
      %
      % Returns the X-Y-Z location of the centroid of each electrode
      %
      p = getGridPoints(obj.gridSpace);
      enum = unique(obj.data(:));
      enum(enum==0) = [];
      idxE = 0;
      
      out = zeros(obj.nElectrodes,3);      
      for j = 1:length(enum)
        i = enum(j);
        if (i~=0), 
          idxE = idxE+1;
          Q = obj.data(:)==i;        
          out(idxE,:) = mean(p(Q,:),1);       

        end;
        if any(isnan(out)), keyboard; end;
      end
    end
     
    function out = get.elecVoxels(obj)
      % out = get.elecVoxels(obj)
      %
      % Returns a cell array of voxel indices associated with each
      % electrode
      %
      
      enum = unique(obj.data(:));
      enum(enum==0) = [];
      
      out = cell(obj.nElectrodes,1);
      for i = 1:length(enum)
        out{i} = find(obj.data(:)==enum(i));
      end;
            
    end
    
    function out = get.elecNodes(obj)
      % out = get.elecNodes(obj)
      %
      % Returns a cell array of node indicies
      enum = unique(obj.data(:));
      enum(enum==0) = [];
      
      c = obj.gridSpace.center;
      p = getGridPoints(obj.gridSpace);
         
      out = cell(obj.nElectrodes,1);
      for i = 1:length(enum)
        Q = find(obj.data==enum(i));
        switch obj.gridType
          case 'grid'
            % Grid type assumes that half the volume of the electrode is
            % nonconducting. This returns the index to the half of the
            % electrode voxels closest to the center of the brain.
            d = p(Q,:)-repmat(c,length(Q),1);
            d = sqrt(sum(d.^2,2));
            Q1 = Q(d<median(d));
            out{i} = obj.gridSpace.getNodesFromCells(Q1);
          case 'depth'
          out{i} = obj.gridSpace.getNodesFromCells(Q);
        end;
      end;              
    end    
    
    function out = get.elecLabels(obj)
      % function out = get.elecLabels(obj)
      %
      %
      allnums = unique(obj.data(:));
      for i = 1:obj.nElectrodes
        out{i} = [obj.namePrefix num2str(allnums(i+1))];
      end
    end
    
    function out = getElecConn(obj,type)
      % Returns a cell array with the connectivity matrix for each
      % electrode
      
      % Use an anisotropic grid by default
      if ~exist('type','var')||isempty(type),
        type = 'aniso';
      end;
      
      altConn = obj.gridSpace.getAlternateGrid;
      altMat = altConn.getGridConnectivity;
      
      enum = unique(obj.data(:));
      enum(enum==0) = [];
      
      out = cell(numel(enum),1);
      for i = 1:numel(enum)
        Q = find(obj.data==enum);
        Qalt = obj.gridSpace.getNodesFromCells(Q);
        out{i}.mat = altMat(Qalt,Qalt);
        out{i}.idx = Qalt;
      end
      
    end
    
    function out = buildCondMap(obj)
      warning('iEEGElectrodeMap.buildCondMap is deprecated');
      c = obj.gridSpace.center;
      p = getGridPoints(obj.gridSpace);
      
      out = zeros(obj.sizes);
      for i = 1:obj.nElectrodes
        Q = find(obj.data==i);
        
        d = p(Q,:) - repmat(c,length(Q),1);
        d = sqrt(sum(d.^2,2));
        
        if strcmpi(obj.gridType,'grid')
          % Grids and strips are a combination of metal and silicone
          Q1 = Q(d<median(d));
          Q2 = Q(d>=median(d));
          out(Q1) = obj.cond_Metal;
          out(Q2) = obj.cond_Silicone;
        else
          % Depth electrodes are assumed to just be made of metal.
          out(Q) = obj.cond_Metal;
        end;
        
      end
      
    end
    
  end
  
end
