classdef parcellation < crlEEG.fileio.NRRD
  % Extension of crlEEG.fileio.NRRD for parcellations
  %
  % classdef parcellation < crlEEG.fileio.NRRD
  %
  % Constructor Syntax:
  %   function obj = parcellation(fname,fpath,parcelType,readOnly)
  %
  % Properties:
  %
  % Written By: Damon Hyde
  % Last Edited: Aug 12, 2015
  % Part of the cnlEEG Project
  %
  
  properties
    parcelType = 'ibsr';
  end % PROPERTIES
  
  properties (Dependent=true)
    nParcel
  end
  
  properties (Hidden = true, Constant)
    validParcels = {'nmm' 'ibsr' 'nvm' 'none'};
  end
  
  methods
    
    function obj = parcellation(varargin)
      
      % Input Parsing      
      validParcels = crlEEG.fileio.NRRD.parcellation.validParcels;
      
      fnameFcn = @(x) isempty(x)||isa(x,'crlEEG.fileio.NRRD.parcellation')||...
            (ischar(x)&& ~ismember(lower(x),{'parceltype' 'readonly'}));
      fpathFcn = @(x) isempty(x)||...
            (ischar(x)&& ~ismember(lower(x),{'parceltype' 'readonly'}));
            
      p = inputParser;
      p.addOptional('fname',[],fnameFcn);
      p.addOptional('fpath',[],fpathFcn);
      p.addParamValue('parcelType','none',@(x) ischar(validatestring(lower(x),validParcels)));
      p.addParamValue('readOnly',false,@(x) islogical(x));
      parse(p,varargin{:});
      
      % Build base crlEEG.fileio.NRRD object and set object properties.
      obj = obj@crlEEG.fileio.NRRD(p.Results.fname,p.Results.fpath,'readOnly',p.Results.readOnly);
      obj.parcelType = lower(p.Results.parcelType);
                
    end
    
    function set.parcelType(obj,val)
      if validatestring(val,obj.validParcels)
        obj.parcelType = val;
      else
        error('Invalid parcellation type');
      end;
    end
    
    %     function objOut = clone(obj,fname,fpath)
    %       if ~exist('fname','var'), fname = 'NewParcel.nhdr'; end;
    %       if ~exist('fpath','var'), fpath = './'; end;
    %
    %       objOut = clone@crlEEG.fileio.NRRD(obj,fname,fpath);
    %     %  objOut.parcelType = obj.parcelType;
    %
    %     end
    
    function out = get.nParcel(obj)
      out = numel(unique(obj.data(:)))-1;
    end
    
    function parcelOut = clone(parcelIn,fname,fpath)
      if ~exist('fname','var'), fname = []; end;
      if ~exist('fpath','var'), fpath = []; end;
      tmpNrrd = clone@crlEEG.fileio.NRRD(parcelIn,fname,fpath);
      parcelOut = parcellation(tmpNrrd,[],parcelIn.parcelType);
    end
    
    function removeWhiteMatter(parcelIn)
      % Set White Matter Parcel Labels to Zero
      %
      % function removeWhiteMatter(parcelIn)
      %
      % Uses parcellation.getMapping to associated parcel labels with
      % tissue types, and sets all labels associated with the white matter
      % to zero, effectively removing them from the parcellation.
      %
      % Written By: Damon Hyde
      % Last Edited: March 10, 2016
      % Part of the cnlEEG Project
      %
      try
        map = parcellation.getMapping(parcelIn.parcelType);
      catch
        warning('Could get mapping. Data unchanged');
        return
      end
      
      parcelIn.data(ismember(parcelIn.data,map.whiteLabels)) = 0;
    end
    
    function removeSubCorticalGray(parcelIn)
      % Set Subcortical Gray Matter Parcel Labels to Zero
      %
      % function removeSubCorticalGray(parcelIn)
      %
      % Uses parcellation.getMapping to associated parcel labels with
      % tissue types, and sets all labels associated with subcortical gray
      % matter to zero, effectively removing them from the parcellation.
      %
      % Written By: Damon Hyde
      % Last Edited: March 10, 2016
      % Part of the cnlEEG Project
      %
      try
        map = parcellation.getMapping(parcelIn.parcelType);
      catch
        warning('Could get mapping. Data unchanged');
        return
      end
      
      parcelIn.data(ismember(parcelIn.data,map.subcorticalLabels)) = 0;
    end
    
    function removeCSF(parcelIn)
      % Set CSF Parcel Labels to Zero
      %
      % function removeWhiteMatter(parcelIn)
      %
      % Uses parcellation.getMapping to associated parcel labels with
      % tissue types, and sets all labels associated with the CSF
      % to zero, effectively removing them from the parcellation.
      %
      % Written By: Damon Hyde
      % Last Edited: March 10, 2016
      % Part of the cnlEEG Project
      %
      try
        map = parcellation.getMapping(parcelIn.parcelType);
      catch
        warning('Could get mapping. Data unchanged');
        return
      end
      
      parcelIn.data(ismember(parcelIn.data,map.csfLabels)) = 0;
    end
    
    
    
    % Methods with their own m-file
    nrrdParcel      = fourLabelSeg(nrrdParcel,fname,fpath);
    nrrdParcel      = cortexOnly(nrrdParcel,fname,fpath);
    nrrdSubParcel   = subparcellate(nrrdParcel,varargin);
    [nrrdParcelOut] = mapToSegmentation(nrrdParcel,varargin);
    nrrdOut = subparcellateByLeadfield(nrrdIn,nrrdVec,type,LeadField,voxLField,nFinal,fName);
    parcelOut = ensureConnectedParcels(parcelIn,varargin);
    [groupOut]   = get_ParcelGroupings(nrrdParcel);
    locationsOut = get_ParcelLocations(parcelIn)
    
  end % METHODS
  
  methods (Static=true)
    % Static Methods with their own m-file
    mappingOut = getMapping(type);
    NVM  = getNVMMapping;
    IBSR = getIBSRMapping;
    NMM  = getNMMMapping;
    [CutOut] = iterateCut(cMatrix,nFinal,cutsPerLvl,avgSize,depth);
  end
  
end % CLASSDEF
