function currents = getCurrents(Electrodes,ModelSize,AnodeIdx,CathodeIdx)
% In the Complete Electrode Model, currents are applied at the
% auxilliary nodes added by modifyFDMatrix
%
currents = zeros(prod(ModelSize)+Electrodes.nElec,1);

currents(prod(ModelSize)+AnodeIdx)   =  1;
currents(prod(ModelSize)+CathodeIdx) = -1;

end