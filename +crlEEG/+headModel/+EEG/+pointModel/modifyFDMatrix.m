
    
    function matOut = modifyFDMatrix(~,matIn)
      % Point Electrode Models don't need to modify the FD Matrix
      matOut = matIn;
    end