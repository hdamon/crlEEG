classdef headNet 
  % A collection of electrodes and fiducials is a headNet
  %
  % Properties
  % ----------
  %    type
  %    electrodes : Electrode Object
  %                   ( Class: crlEEG.head.model.EEG.electrode )
  %    fiducials : Fiducial Object
  %                   ( Class: crlEEG.head.model.EEG.electrode )
  %
  % Dependent Properties
  % --------------------
  %
  %
  % 
  % Part of the crlEEG Project
  % 2009-2017
  %

  properties
    type
    electrodes
    fiducials
  end  
  
  properties (Constant,Hidden=true)
    validTypes = {'10-10','10-20','hd128','hd256'};
  end
  
  methods
    function obj = headNet(varargin)
      
      % Return an empty object
      if nargin==0, return; end;
      
      % 
      if (isa(varargin{1},'headNet'))
        obj = varargin{1};
        return;
      end
      
      % Legacy Support
      if isa(varargin{1},'cnlElectrodes')
        crlEEG.disp('Converting from old cnlElectrodes object');
        
        opts.electrodes = crlEEG.head.model.EEG.electrode(varargin{1});
        opts.fiducials = crlEEG.head.model.EEG.electrode(...
                                'label',varargin{1}.FIDLabels,...
                                'position',varargin{1}.FIDPositions);
        obj = headNet(opts);
        return;        
      end
      
      p = inputParser;
      p.addParamValue('type',[]);
      p.addParamValue('electrodes',[],...
                            @(x) isa(x,'crlEEG.head.model.EEG.electrode'));
      p.addParamValue('fiducials',[],...
                            @(x) isa(x,'crlEEG.head.model.EEG.electrode'));
      p.addParamValue('elecLabel',[]);
      p.addParamValue('elecPosition',[0 0 0]);
      p.addParamValue('elecVoxels',[]);
      p.addParamValue('elecConductivities',[]);
      p.addParamValue('elecNodes',[]);
      p.addParamValue('elecImpedance',1000);
      p.addParamValue('elecModel','pointModel');
      p.addParamValue('fidLabel',[]);
      p.addParamValue('fidPosition',[0 0 0]);
      p.parse(varargin{:});
      
      
      
      if ~isempty(p.Results.electrodes)
        obj.electrodes = p.Results.electrodes;
      else
        obj.electrodes = crlEEG.head.model.EEG.electrodes(...
                            'label',p.Results.elecLabel,...
                            'position',p.Results.elecPosition,...
                            'voxels',p.Results.elecVoxels,...
                            'conductivities',p.Results.elecConductivities,...
                            'nodes',p.Results.elecNodes,...
                            'impedance',p.Results.elecImpedance,...
                            'model',p.Results.elecModel);
      end
      
      if ~isempty(p.Results.type)
        obj.type = p.Results.type;
      else
        if ~isempty(obj.electrodes)
          obj.type = obj.discoverType;
        end;
      end;
             
      if ~isempty(p.Results.fiducials)
        obj.fiducials = p.Results.fiducials;
      else
        obj.fiducials = crlEEG.head.model.EEG.electrodes(...
                            'label',p.Results.fidLabel,...
                            'position',p.Results.fidPosition);
      end;
            
    end
    
    function type = discoverType(obj)
      % Try to discover a head net type from the electrodes
      
      switch numel(obj.electrodes)
        case 73
          type = '10-10';
        case 128
          type = 'hd128';
        case 256
          type = 'hd256';
        otherwise
          error('Unable to identify head net type');
      end      
    end
    
    function obj = set.type(obj,val)
      validatestring(val,obj.validTypes);
      obj.type = val;
    end
    
    function obj = set.electrodes(obj,val)
      crlEEG.util.assert.instanceOf('crlEEG.head.model.EEG.electrode',val);
      obj.electrodes = val;
    end
    
    function obj = set.fiducials(obj,val)
      crlEEG.util.assert.instanceOf('crlEEG.head.model.EEG.electrode',val);
      obj.fiducials = val;
    end;
    
    function val = center(obj)
      % Return the center of the headNet
      val = obj.electrodes.center;
    end
    
    function val = basis(obj)
      % Get a set of basis functions for the identification of polar
      % coordinates
      %
      % Tries to use fiducial markers for this, and just uses the 
      % electrodes if that fails.
      %
      
      origin = obj.center;
      
     % relPos = obj.electrodes.position - repmat(origin,numel(obj.electrodes),1);
     % relFID = obj.fiducials.position - repmat(origin,numel(obj.fiducials),1);
      
      % Get the up direction
      try
        upPos = obj.fiducials('Cz').position;
      catch
        % Just use the basis from the electrodes
        val = obj.electrodes.basis;
        return;
      end
      
      % Get the forward direction
      try
        frontPos = obj.fiducials('Nz').position;
      catch
        try
          frontPos = obj.fiducials('FidNz').position;
        catch
          val = obj.electrodes.basis;
          return;
        end
      end
      
      vecZ = upPos - origin; vecZ = vecZ./norm(vecZ);
      vecX = frontPos - origin; vecX = vecX./norm(vecX);
      vecX = vecX - vecZ*(vecZ*vecX'); vecX = vecX./norm(vecX);
      
      vecY = cross(vecZ,vecX);
      
      val = [vecX(:) vecY(:) vecZ(:)];      
                  
    end

    function out = plot(obj,varargin)
      out = obj.electrodes.plot2D('origin',obj.center,'basis',obj.basis,varargin{:});
    end
    
  end
  

  
  
end
