function obj = addElectrodes(obj,electrodes)
  % Add an array of electrodes to the FDM object
  
  for i = 1:numel(electrodes)
    obj = addElectrode(obj,electrodes(i));
  end;
  
end

function obj = addElectrode(obj,electrode)
  % Add a single electrode to the FDM object
  
  assert(isa(electrode,'crlEEG.head.model.electrode'),...
            'Input must be a crlEEG.head.model.electrode object');
  assert(numel(electrode)==1,['Input must be a single object '...
                              '(And why are we getting here?)']);
  
  % Check that it's not already in the model
  if any(obj.electrodes==electrode)
    warning(['Electrode: ' electrode.label ' already found in model']);
    return;
  end;
       
  % Check that the electrode can be added
  if ~isempty(intersect(electrode.Voxels,obj.voxInside))
    if obj.isBuilt
     error(['Cannot add electrode: ' electrode.label ...
            'Electrode volume overlaps with '...
            'previously constructed finite difference volume. ' ...
            'Clear obj.matFDM to proceed. Adding this electrode will' ...
            'require recomputation of the finite difference matrix.'...
            ]);
    else       
      obj.electrodes(end+1) = electrode;
      
      % Set Conductivities in the Volume.
      if isequal(electrode.model,'completeModel')
        obj.nrrdCond.data(electrode.voxels) = electrode.conductivities;
      end;
    end
  end
        
end