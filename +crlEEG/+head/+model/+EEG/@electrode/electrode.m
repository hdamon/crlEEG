classdef electrode
  % Class for EEG electrode objects in crlEEG
  %
  % 
  %
  % Properties:
  % -----------
  %  label          : Electrode Name
  %  position       : Centroid Location (X-Y-Z)
  %  voxels         : Index of Voxels Occupied by Electrode
  %  conductivities : Vector of Voxel Isotropic Conductivities
  %  nodes          : Nodes in the Head Space for the contact surface
  %  impedance      : Electrode Impedance (DEFAULT: 1000 Ohm)
  %  model          : Type of electrode model to use (Point or Complete)
  %
  %
  % Written By: Damon Hyde
  % Part of the cnlEEG Project
  % 2009-2017
  %
  
  %%
  properties
    label
    position
    voxels
    conductivities
    nodes
    impedance
    model
  end
  
  properties (Constant,Hidden)
    validModelTypes = {'pointModel','completeModel'};
  end
  
  %%
  methods
    
    %%
    function obj = electrode(varargin)
      
      % Return an empty object
      if nargin==0, return; end;
      
      % If passed an electrode, return an electrode.
      if (nargin>0)&&(isa(varargin{1},'crlEEG.head.model.EEG.electrode'))
        obj = varargin{1};
        return;
      end;
      
      % Input Validation Functions
      validateLabels    = @(x) isempty(x)||ischar(x)||iscellstr(x);
      validatePositions = @(x) ismatrix(x)&&any(size(x)==3);
      isNumVec          = @(x) isempty(x)||isnumeric(x)&&isvector(x);
      validateAllNumVec = @(x) isNumVec(x)||all(cellfun(isNumVec,x));
      validateModel     = @(x) ischar(x)||iscellstr(x);
      
      % Input Parsing
      p = inputParser;
      p.addParamValue('label'         ,[] , validateLabels);
      p.addParamValue('position'      ,[0 0 0] , validatePositions);
      p.addParamValue('voxels'        ,[] , validateAllNumVec);
      p.addParamValue('conductivities',0 , validateAllNumVec);
      p.addParamValue('nodes'         ,[] , validateAllNumVec);
      p.addParamValue('impedance'     ,1000 , isNumVec);
      p.addParamValue('model'         ,'pointModel',validateModel);
      p.parse(varargin{:});
      
      % Parse Labels
      label = p.Results.label; if ~iscell(label), label = {label}; end;
      
      position  = p.Results.position;
      if (size(position,1)==3)&&~(size(position,2)==3)
        % Reorient matrix if needed. Assume 3x3 matrices arrive correctly
        % oriented
        position = position';
      end;
      nodes     = p.Results.nodes;
      if ~iscell(nodes), nodes = {nodes}; end;
      voxels    = p.Results.voxels;
      if ~iscell(voxels), voxels = {voxels}; end;
      conductivities = p.Results.conductivities;
      if ~iscell(conductivities), conductivities = {conductivities}; end;
      impedance = p.Results.impedance;
      model     = p.Results.model;
      if ~iscell(model), model = {model}; end;
      
      % Determine how many electrodes we're trying to define
      nElec = [numel(label) size(position,1) numel(conductivities) ...
        numel(voxels) numel(nodes) numel(impedance) numel(model)];
      
      nElec(nElec==1) = [];
      if ~isempty(nElec)
        assert(all(nElec==nElec(1)),'Input size mismatch');
        nElec = nElec(1);
      else
        nElec = 1;
      end;
      
      % Make sure input data is sized correctly
      if nElec>1
        
        if (numel(label)==1)
          if isempty(label{1})
            warning('Assigning default electrode names');
            for i = 1:nElec
              label{i} = ['E' num2str(i)];
            end;
          else
            error('Cannot provide only a partial list of electrode names');
          end;
        end;
        
        if (size(position,1)==1)
          if all(position==[0 0 0])
            position = repmat(position,nElec,1);
          else
            error('Mismatch in size of input positions');
          end
        end;
        
        
        if ( numel(conductivities)==1 )
          if ( numel(conductivities{1})>1 )
            error('Conductivities not present for all electrodes');
          else
            conductivities = repmat(conductivities,1,nElec);
          end;
        end;
        
        if numel(voxels)==1
          if ~isempty(voxels{1})
            error('Must provide voxel list for each electrode individually');
          else
            % Just duplicates an empty matrix
            voxels = repmat(voxels,1,nElec);
          end;
        end;
        
        if numel(nodes)==1
          if ~isempty(nodes{1})
            error('Must provide node list for each electrode individually');
          else
            nodes = repmat(nodes,1,nElec);
          end;
        end
        
        if numel(impedance)==1, impedance = repmat(impedance,nElec,1); end;
        
        if numel(model)==1, model = repmat(model,1,nElec); end;
      end;
      
      % Finally, construct the actual objects.
      obj(nElec) = crlEEG.head.model.EEG.electrode;
      
      for i = 1:nElec
        obj(i).label = label{i};
        obj(i).position = position(i,:);
        obj(i).voxels = voxels{i};
        obj(i).conductivities = conductivities{i};
        obj(i).nodes = nodes{i};
        obj(i).impedance = impedance(i);
        obj(i).model = model{i};        
      end
      
    end % END electrode() constructor
    
    %%
    function obj = validate(obj)
      % Validate match between number of conductivities and number of
      % voxels
      if numel(obj.conductivities)==1 && ( numel(obj.voxels)>1 )
        obj.conductivities = repmat(obj.conductivities,1,numel(obj.voxels));
      end;
      
      isValid = ( numel(obj.conductivities)==numel(obj.voxels) ) || ...
        ( numel(obj.voxels)==0 );
      assert(isValid,'Number of voxels and provided conductivities do not match');
    end
    
    %% Property Set Methods
    function obj = set.label(obj,val)
      % Label must be a character string
      assert(ischar(val),'Label must be a character string');
      obj.label = val;
    end
    
    function obj = set.position(obj,val)
      % Position must be a 1x3 or 3x1 vector
      assert(isnumeric(val)&&(numel(val)==3),...
        'Position must be X-Y-Z coordinates');
      obj.position = val(:)';
    end
    
    function obj = set.voxels(obj,val)
      obj.voxels = val;
      obj = obj.validate;
    end
    
    function obj = set.nodes(obj,val)
      obj.nodes = val;
      obj = obj.validate;
    end
    
    function obj = set.conductivities(obj,val)
      assert(isnumeric(val)&&(isvector(val)),...
        'Conductivity must be a numeric vector');
      obj.conductivities = val;
    end
    
    function obj = set.impedance(obj,val)
      assert(isnumeric(val)&&isscalar(val),...
        'Electrode impedance must be a numeric scalar');
      obj.impedance = val;
    end
    
    function obj = set.model(obj,val)
      obj.model = validatestring(val,obj.validModelTypes);
    end
    
    %% Overloaded Methods
    function isEq = eq(a,b)
      % Overloaded eq(a,b) method for crlEEG.head.model.EEG.electrode objects
      if ~isa(a,'crlEEG.head.model.EEG.electrode'), isEq = false; return; end;
      if ~isa(b,'crlEEG.head.model.EEG.electrode'), isEq = false; return; end;
      
      assert((numel(a)==1)||(numel(b)==1)||isequal(size(a),size(b)),...
        'Matrix dimensions must agree');
      
      % Return a value if we're comparing singular electrodes
      if ( numel(a)==1 ) && ( numel(b) == 1 )
        isEq = isequal(a.label,b.label) && ...
               isequal(a.position,b.position) && ...
               isequal(a.voxels,b.voxels) && ...
               isequal(a.conductivities,b.conductivities) && ...
               isequal(a.nodes,b.nodes) && ...
               isequal(a.impedance,b.impedance) && ...
               isequal(a.model,b.model);
        return;
      elseif ( numel(a) == 1 )
        isEq = false(size(b));
        for i = 1:numel(b)
          isEq(i) = a==b(i);
        end;
      elseif ( numel(b) == 1 )
        isEq = false(size(a));
        for i = 1:numel(a)
          isEq(i) = a(i)==b;
        end;
      else
        isEq = false(size(a));
        
        for i = 1:numel(a)
          isEq(i) = a(i)==b(i);
        end;        
      end;                              
    end
    
  end
  
  %%
  methods
    % Calls to the following three methods are redirected to the associated
    % package associated witht he model type.
    %
    
    %%
    function outIdx = getNumericIndex(obj,cellIn)
      % Get the numeric indices associated with specific electrode names.
      %
      % Returns NaN's if an electrode requested by name is not present in
      % the array.
      %
      
      % Just spit it back if it's already numeric.
      if isnumeric(cellIn)
        outIdx = cellIn;
        return;
      end;
      
      assert(iscellstr(cellIn)||ischar(cellIn),'FOOERR');
      if ischar(cellIn), cellIn = {cellIn}; end;
      outIdx = zeros(1,numel(cellIn));
      for idx = 1:numel(outIdx)
        tmp = find(strcmp(cellIn{idx},{obj.label}));
        if isempty(tmp), tmp = nan; end;
        assert(numel(tmp)==1,'Multiple Electrodes Match Requested Label');
        outIdx(idx) = tmp;
      end
    end
    
    %%
    function s = struct(obj)
      % Typecast an electrode object to a struct
      s.label = obj.label;
      s.position = obj.position;
      s.voxels = obj.voxels;
      s.conductivities = obj.conductivities;
      s.impedance = obj.impedance;
      s.model = obj.model;
    end                
  end
  
end






