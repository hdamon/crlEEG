classdef infiniteSpace
% Constructs an infinite space bioelectric model.
%
% classdef infiniteSpace
%
% obj = crlEEG.headModel.EEG.infiniteSpace(varargin)
%
% The primary usage of this model in crlEEG is to rapidly compute an
% initial estimate of the head voltage distributions, to initialize the
% finite difference models and reduce the need for a large number of
% iterations to obtain good convergence.
%
% Properties:
%   electrodes: crlEEG.headModel.EEG.electrodes objects defining the
%                 measurement locations
%   outputpoints: A list of X-Y-Z locations the output voltage should be
%                   computed at.
%   conductivity: 
%
% Written By: Damon Hyde
% Part of the crlEEG Project
% 2009-2017
%
  
  properties
    electrodes    
    outputpoints
    conductivity
  end
  
  methods
    
    function obj = infiniteSpace(varargin)
      
      p = inputParser;
      p.addOptional('nrrdCond',[],@(x) isa(x,'crlEEG.file.NRRD'));
      p.addParamValue('electrodes',[],@(x) isa(x,'crlEEG.headModel.EEG.electrode');
      p.addParamValue('outputpoints',[]);
      p.addParamValue('conductivity',0.33);
      p.parse(varargin{:});
      
      obj.electrodes = p.Results.electrodes;      
      obj.conductivity = p.Results.conductivity;
      
      if ~isempty(p.Results.nrrdCond)
        obj.outputpoints = p.Results.nrrdCond.gridSpace.getGridPoints;
      else
        obj.outputpoints = p.Results.outputpoints;
      end;
            
    end
    
  end
  
end