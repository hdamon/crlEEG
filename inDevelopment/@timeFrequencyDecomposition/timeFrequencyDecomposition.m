classdef timeFrequencyDecomposition
% A simple class for manipulating time frequency decompositions.
%
%
% function obj = timeFrequencyDecomposition(type,tfX,tx,fx)
%
% Properties
% ----------
%   type : Name of the decomposition
%   tfX  : nFrequency X nTime matrix of decomposition parameters
%   tx   : Time values for each column in tfX
%   fx   : Frequency values for each row in tfX
%
%

  properties
    type
    params
    tfX
    tx
    fx    
  end

  methods
    
    function obj = timeFrequencyDecomposition(type,tfX,tx,fx)
      obj.type = type;
      obj.tfX = tfX;
      obj.tx = tx;
      obj.fx = fx;      
    end
    
    function out = subtract_baseline(obj,baseline)
      % Subtract a baseline frequency spectrum from all tfX columns.
      baseline = baseline(:);
      assert(numel(baseline)==size(obj.tfX,1),...
                'Incorrect Baseline Size');
      
      out = obj;
      out.tfX = abs(out.tfX) - repmat(baseline,1,size(out.tfX,2));
    end        
    
  end
  
end

