classdef (Abstract) module < handle & matlab.mixin.Copyable
  % Base class for pipeline modules
  %
  % classdef (Abstract) cnlPipelineModule < handle
  %
  %
  % This is an object base class that allows the implementation of pretty
  % arbitrary data processing operations, and
  %
  % As of Dec 2016, these modules are SISO, but MIMO functionality is
  % expected to be added soon.
  %
  % Methods that need to be implemented by child classes:
  %   obj.Execute()
  %
  % This should be the method which actually implements whatever
  % functionality is desired.
  %
  %
  % Written By: Damon Hyde
  % Last Edited: March 14, 2016
  % Part of the cnlEEG Project
  %
  
  properties
    disabled = false;
    inputobj
  end;
  
  properties (Hidden=true)
    savesPrecomputedOutput = false;
  end
  
  properties (Dependent = true, Hidden=true)
    % Hidden to preventing executing upstream modules when displaying.
    input;
  end;
  
  properties (Dependent = true)
    output;
  end
  
  properties (Hidden=true,SetAccess=protected,GetAccess=public)
    inputTypes = {};
    outputType = [];
  end
  
  properties (Access=protected)
    needsRecompute = true;
    inputListener; % eventListener object to listen to input module for updates.
    validGUI;      % TRUE if obj.gui is a valid GUI handle object.
    gui;           % Matlab UI object with the module's GUI
    precomputedOutput;
  end
  
  events
    % Triggered whenever the pipeline module has an updated output. When
    % cnlPipelineModules are used as input to other modules, they
    % automatically listen for this event to trigger internal recomputation
    % of their own outputs.
    outputUpdated;
  end;
  
  methods
    
    function obj = cnlPipelineModule(varargin)
      % function out = cnlPipelineModule(saveOutput)
      %
      % I think this is all this constructor needs. Most everything is
      % implemented in the subclasses.
      
      %% Input Parsing
      p = inputParser;
      p.addOptional('input',[]);
      p.addParamValue('saveoutput',false,@(x) islogical(x));
      p.addParamValue('inputtypes',{},@(x) iscellstr(x));
      p.addParamValue('outputtype',[],@(x) ischar(x));
      p.parse(varargin{:});
      
      if isa(p.Results.input,'cnlPipelineModule')
        obj = p.Results.input;
      end;
      
      obj.inputTypes   = p.Results.inputtypes;
      obj.inputobj     = p.Results.input;
      obj.savesPrecomputedOutput = p.Results.saveoutput;
      
    end
    
    function set.disabled(obj,val)
      if ~isequal(obj.disabled,val)
        obj.disabled = val;
        notify(obj,'outputUpdated');
      end;
    end
    
    function createInputListener(obj,useEvent)
      % For specific input types, create a listener to watch for
      % updates to the input.
      obj.inputListener = [];
      
      if ~exist('useEvent','var'), useEvent = []; end;
      
      if isempty(useEvent)
        if ismember('outputUpdated',events(obj.inputobj))
          % The input object is a cnlPipelineModule
          useEvent = 'outputUpdated';
        elseif ismember('updatedOut',events(obj.inputobj));
          % What type of objects use this?
          useEvent = 'updatedOut';
        end
      end;
      
      if ~isempty(useEvent)
        obj.inputListener = addlistener(obj.inputobj,useEvent,...
          @(src,evt) recomputeAndNotify(obj,src,evt));
      end
    end
    
    function recomputeAndNotify(obj,~,~)
      % When the input listener triggers, notify any modules relying on the
      % current one that the output needs to be updated. Flag the current
      % module for recomputation. The actual recomputation will take place
      % when the next downstream module requests the output.
      obj.needsRecompute = true;
      obj.notify('outputUpdated');
    end;
    
    %% Set the input object
    function set.inputobj(obj,val)
      % function set.inputobj(obj,val)
      %
      % Ensure that the input matches one of obj.inputTypes
      assert(obj.isValidInputType(val),'Invalid module input type');
      if ~isequal(obj.inputobj,val)
        obj.inputobj = obj.checkInput(val);
        
        % Try Creating an input listener
        obj.createInputListener;
        
        % The input has been changed, so update the output and notify
        % listeners
        obj.recomputeAndNotify;
      end;
    end
    
    %% Get/Set for the input
    % obj.input behaves in an asynchonous way.
    %
    % Setting obj.input (ie: obj.input = val), assigns val to the hidden
    % property obj.inputobj.
    %
    % Getting obj.input behaves differently depending on the value of
    % obj.inputobj.
    %
    % If obj.inputobj is a:
    %
    %  cnlPipelineModule: obj.input returns obj.inputobj.output
    %  function_handle: obj.input returns eval(obj.inputobj)
    %  otherwise: obj.input returns obj.inputobj
    %
    
    function set.input(obj,val)
      obj.inputobj = val;
    end;
    
    function out = get.input(obj)
      % function out = get.input(obj)
      %
      %
      
      if isa(obj.inputobj,'cnlPipelineModule')
        % If the input in another pipeline module, fetch output from that
        % module.
        out = obj.inputobj.output;
      elseif isa(obj.inputobj,'function_handle')
        % If the input is a function handle, evaluate the function handle
        out = feval(obj.inputobj);
      else
        % Otherwise, use the provided input value
        out = obj.inputobj;
      end;
    end
    
    function valid = get.validGUI(obj)
      % Helper function used primarily in the construction of module GUIs.
      % Returns true if obj.gui exists and is a valid Matlab graphics
      % handle.
      valid = ~isempty(obj.gui)&&ishghandle(obj.gui);
    end
    
    function out = get.output(obj)
      % function out = get.output(obj)
      %
      % Compute the output of the pipeline module.
      %
      % IF obj.savePrecomputedOutput is:
      %   TRUE:
      %   IF obj.needsRecompute is:
      %     TRUE: Executes obj.Execute and stores it in
      %            obj.precomputedOutput
      %     FALSE: Outputs obj.precomputedOutput
      %   FALSE:
      %     Runs obj.Execute and returns the output
      %
      
      % If Disabled, Just Pass The Input Through
      if obj.disabled, out = obj.input; return; end;
      
      % If input is empty, return an empty array.
      if isempty(obj.inputobj), out = []; return; end;
      
      if obj.savesPrecomputedOutput
        % If precomputed output is saved, check if it needs to be
        % recomputed.
        if ~obj.needsRecompute
          % Use precomputed output
          out = obj.getPrecomputedOutput;
        else
          % Recompute if necessary
          tmp = obj.Execute;
          obj.setPrecomputedOutput(tmp);
          out = obj.getPrecomputedOutput;
          obj.needsRecompute = false;
        end;
      else
        % Otherwise, just run it.
        out = obj.Execute;
      end;
      
    end
    
    function varargout = GUI(obj,varargin)
      % Framework for constructing and using GUIs with cnlPipelineModules.
      %
      %
      p = inputParser;
      p.KeepUnmatched = true;
      p.addParamValue('origin',[]);
      p.addParamValue('size',[]);
      parse(p,varargin{:});
      
      % Raise figure with existing GUI, or create a new GUI in the current
      % figure.
      if obj.validGUI
        figure(ancestor(obj.gui,'figure'));
      else                        
        obj.gui = obj.makeGUI;
      end;
      
      % Set any properties that may have been provided.
      pos = get(obj.gui,'Position');
      if ~isempty(p.Results.origin)
        pos(1:2) = p.Results.origin;
      end
      if ~isempty(p.Results.size)
        pos(3:4) = p.Results.size;
      end;
      set(obj.gui,'Position',pos);
      
      set(obj.gui,p.Unmatched);
      
      % Sync the values in the GUI with the current object state.
      obj.syncGUI;
      
      % If an output is requested, give it the gui object.
      if nargout>0
        varargout{1} = obj.gui;
      end;
    end

    
  end
  
  methods (Access=protected)
    function isValid = isValidInputType(obj,val)
      % function isValid = isValidInputType(obj,val)
      %
      % Check that input value matches one of obj.inputTypes
      
      % Empty inputs are valid
      if isempty(val), isValid = true; return; end;
      
      % If inputTypes haven't been specified, accept only empty inputs
      if isempty(obj.inputTypes), isValid = isempty(val); return; end;
      
      if isa(val,'cnlPipelineModule')
        % If the input comes from a cnlPipelineModule, check that the
        % output type of that module matches the required input type
        isValid = any(cellfun(@(x) isequal(val.outputType,x),obj.inputTypes));
      elseif isa(val,'function_handle')
        % If it's a function handle, check that the output of evaluating it
        % is either a valid inputType, or empty (which we assume to mean
        % the function isn't fully configured yet).
        isValid = any(cellfun(@(x) isequal(feval(val),x),obj.inputTypes));
        isValid = isValid||isempty(feval(val));
      else
        % If the input is not from another pipeline module, check that it
        % matches one of the provided inputTypes
        isValid = any(cellfun(@(x) isa(val,x),obj.inputTypes));
      end;
    end
        
    function syncGUI(obj)
      % Just a dummy placeholder function, to be optionally overloaded by
      % child classes.
    end
    
    %% Default Set/Get Methods for obj.precomputedOutput.
    % Using these allows child classes to overload them and modify the
    % set/get operations for the precomputed output. This functionality is
    % NOT available with Matlab dependent properties.
    function out = getPrecomputedOutput(obj)
      out = obj.precomputedOutput;
    end
    
    function setPrecomputedOutput(obj,val)
      obj.precomputedOutput = val;
    end
    

    
  end
  
  %% Static Methods
  methods (Static = true)
    function out = staticFun(input,varargin)
      % This method should hopefully get
      error('Static functionality not yet implemented');
    end;
  end
  
  %% Abstract methods to be implemented in subclasses
  methods (Abstract)
    % The method to actually implement the module
    out = Execute(obj,varargin);
    % Method to instatiate a GUI for the module
    guiObj = makeGUI(obj);
  end
  
  methods (Abstract, Access = protected, Static = true)
    % The method to check and validate the input options
    out = checkInput(val);
  end;
  
end


