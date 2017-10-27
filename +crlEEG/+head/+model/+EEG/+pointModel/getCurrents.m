function currents = getCurrents(Electrode,ModelSize,Current)
% Given a list of electrodes in the model, output the appropriate
% current input pattern for solving the

assert(isa(Electrode,'crlEEG.headModel.EEG.electrode'),...
  'Input electrode array must be a crlEEG.headModel.EEG.electrode object');

currents = zeros(prod(ModelSize),1);

currents(Electrode.Nodes)   = Current;
end