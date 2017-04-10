classdef electrode 
  % HELP TEXT NO LONGER VALID
  % Abstract class for electrode models
  % 
  % This is an abstract class meant to act as the parent for incorporating
  % various types of electrode models into the FD forward model. Two
  % abstract functions need to be defined:
  %
  % modifyConductivity : Modify the conductivity NRRD to incorporate the
  %                       electrodes
  % modifyFDMatrix : Add columns/rows to the FD Matrix to 
  %
  % NOTE: Not sure if an abstract class like this is absolutely necessary
  %
  % Written By: Damon Hyde
  % Last Edited: April 10, 2017
  % Part of the cnlEEG Project
  % 2009-2017
  %
  
  properties
    label
    position
    nodes
    conductivities
    voxels
    impedance    
    model
  end
  
  methods
    
    function obj = electrode(varargin)
      
      % If passed an electrode, return an electrode.
      if (nargin>0)&&(isa(varargin{1},'crlEEG.headModel.EEG.electrode'));
        obj = varargin{1};
        return;
      end;
      
      validModels = {'pointModel', 'completeModel'};
      
      % Input Parsing
      p = inputParser;
      p.addParamValue('label',[],@(x) ischar(x));
      p.addParamValue('position',[0 0 0],@(x) isempty(x)||isvector(x));
      p.addParamValue('nodes',[],@(x) isnumeric(x)&&isvector(x));
      p.addParamValue('conductivities',0, @(x) isnumeric(x)&&isvector(x));
      p.addParamValue('voxels',[],@(x) isnumeric(x)&&isvector(x));
      p.addParamValue('impedance',[],@(x) isnumeic(x)&&isscalar(x));  
      p.addParamValue('model','pointModel',@(x) validatestring(x,validModels));
      p.parse(varargin{:});
      
      % Assign Properties
      obj.label     = p.Results.label;
      obj.position  = p.Results.position;
      obj.nodes     = p.Results.nodes;
      obj.voxels    = p.Results.voxels;
      obj.impedance = p.Results.impedance;
      obj.model     = p.Results.model;
                  
    end
    
    function obj = set.position(obj,val)
      assert(isnumeric(val)&&(numel(val)==3),...
        'Position must be X-Y-Z coordinates');
      obj.position = val(:)';
    end;
    
    
  end
  
  methods 
    % Calls to the following three methods are redirected to the associated
    % package associated witht he model type.
    %
    
    % Method to get the input currents associated with this electrode
    function currents = getCurrents(Electrode,ModelSize,Current)
      currents = crlEEG.headModel.EEG.(Electrode.model).getCurrents(Electrode,ModelSize,Current);
    end;

    % Method to Modify the Conductivity of nrrdIn Appropriately    
    function nrrdOut = modifyConductivity(Electrode,nrrdIn)
      nrrdOut = crlEEG.headModel.EEG.(Electrode.model).modifyConductivity(Electrode,nrrdIn);
    end;
    
    % Method to Modify a Finite Difference Matrix
    function matOut  = modifyFDMatrix(Electrode,matIn)    
      matOut = crlEEG.headModel.EEG.(Electrode.model).modifyFDMatrix(Electrode,matIn);
    end;
  end
  
end
    
    
    
    
    
  
  