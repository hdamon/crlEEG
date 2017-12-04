function S = getStruct(matrixObj)
  % Convert a cnlMatrixOnSpace object into a struct
  %
      
  S.origMatrix = matrixObj.origMatrix;  
  S.isTransposed = matrixObj.isTransposed;
  S.origSolutionSpace = matrixObj.origSolutionSpace;
  S.currSolutionSpace = matrixObj.currSolutionSpace;
  S.isCollapsed = matrixObj.isCollapsed;
  S.isTransposed = matrixObj.isTransposed;
  S.matCollapse = matrixObj.matCollapse;
  S.colPerVox = matrixObj.colPerVox;
  
  
end