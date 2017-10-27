function matOut = modifyFDMatrix(Electrodes,matIn)
% The complete electrode model adds a row and column to the FD matrix
% for each individual electrode.
%
[row,col,val] = find(matIn);

nNodes = size(matIn,1);
nElec = Electrodes.nElec;

nodes = Electrodes.Nodes;

for idxE = 1:nElec
  eNodes = nodes{idxE};
  
  next = nNodes + idxE;
  
  newVals = -1./(Electrodes(idxE).Impedance*ones(numel(eNodes),1));
  
  row = [row ; next*ones(numel(eNodes),1)];
  col = [col ; eNodes(:)];
  val = [val ; newVals];
  
  row = [row ; eNodes(:)];
  col = [col ; next*ones(numel(eNodes),1)];
  val = [val ; newVals];
  
  row = [row ; next];
  col = [col ; next];
  val = [val ; -sum(newVals)];
  
end

matOut = sparse(row,col,val,nNodes+nElec,nNodes+nElec);
end