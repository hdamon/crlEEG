classdef EEG < crlEEG.type.data.timeseries
  
  properties
  end
  
  methods
    
    function obj = EEG(varargin)
                  
      p = inputParser;
      p.KeepUnmatched = true;
      p.parse(varargin{:});
      
      obj = obj@crlEEG.type.data.timeseries(p.Unmatched);
      
           
    end    
    
  end
  
end