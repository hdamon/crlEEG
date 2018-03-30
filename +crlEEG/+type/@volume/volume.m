classdef volume 
  % Basic type for n dimensional gridded volumes
  %
  %
  
  properties
    name
    data 
    elementSize
    grid    
  end
  
  properties (Dependent = true)
    range
    displayRange
  end
    
  
  methods
    
    function obj = volume(varargin)
      
      p = inputParser;
      
      
      
    end
    
    

    
    
  end
  
end
  
    