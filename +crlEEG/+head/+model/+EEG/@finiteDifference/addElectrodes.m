% Add one or more electrodes to a crlEEG.head.model.EEG.finiteDifference
% object
%
% function obj = addElectrodes(obj,electrodes)
%
% finiteDifference.addElectrodes() adds one or more electrodes to the
% finite difference model. 
%
% Electrodes that are already present in the model will not be added again.
%
% If the system matrix has already been constructed, additional electrodes
% can still be added, as long as they do not require modification of the
% conductivity map. This typically occurs when using the complete electrode
% model to incorporate implanted ECOG/sEEG electrodes.
%
% Inputs:
% -------
%   obj : crlEEG.head.model.EEG.finiteDifference object
%   electrodes : array of crlEEG.type.sensor.electrode objects
%
% Outputs:
% --------
%   obj : crlEEG.head.model.EEG.finiteDifference object with electrodes
%             added.
%
%
%

function obj = addElectrodes(obj,electrodes)
  % Just a loop across the elements of the electrodes array.  
  for i = 1:numel(electrodes)
    obj = addElectrode(obj,electrodes(i));
  end;
  
end

function obj = addElectrode(obj,electrode)
  % Add a single electrode to the FDM object
  
  assert(isa(electrode,'crlEEG.type.sensor.electrode'),...
            'Input must be a crlEEG.type.sensor.electrode object');
  assert(numel(electrode)==1,['Input must be a single object '...
                              '(And why are we getting here?)']);
  
  % Check that it's not already in the model
  if any(obj.electrodes==electrode)
    warning(['Electrode: ' electrode.label ' already found in model']);
    return;
  end;
       
  % Check that the electrode can be added
  if ~isempty(intersect(electrode.voxels,obj.voxInside))
    if obj.isBuilt
     error(['Cannot add electrode: ' electrode.label ...
            'Electrode volume overlaps with '...
            'previously constructed finite difference volume. ' ...
            'Clear obj.matFDM to proceed. Adding this electrode will' ...
            'require recomputation of the finite difference matrix.'...
            ]);
    end;
    
  
  end
  
  %% Add it to the list.
  if isempty(obj.electrodes)
    obj.electrodes = electrode;
  else
    obj.electrodes(end+1) = electrode;               
  end;
  
end