    function nrrdOut = modifyConductivity(~,nrrdIn)
      % Point Electrode Models don't need to modify the conductivity
      nrrdOut = nrrdIn;
    end