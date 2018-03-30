classdef (Abstract) adaptable   
  % classdef crlEEG.type.matrix.adaptable
  %
  % Abstract class for defining adaptable matrices.  
  %
  % Contains the main functionality for adaptable matrices (those that
  % routinely need to be modified or altered in some way). 
  %
  % Parameters defining the adaptability are defined in the concrete
  % subclass, as is the method rebuildCUrrMatrix(obj), which constructs the new
  % currMatrix based on the altered parameters.
  %  
  % Properties:
  % -----------
  %  New:   origMatrix
  %         currMatrix
  %         isTransposed
  %         needsRebuild
  %
  % Methods:
  % --------
  %      adaptable(matrix)  :  object constructor
  %      ctranspose
  %      mtimes
  %      size
  %      subsref
  %       
  % Abstract Methods:
  % -----------------
  %      rebuildCurrMatrix : 
  %      canRebuild :
  %
  % Part of the crlEEG Project
  % 2009-2018
  %
  
  properties
    origMatrix
  end
  
  properties (SetAccess = protected, GetAccess=public)
    currMatrix
    isTransposed = false;
   % needsRebuild = false;
   % stillLoading = true;
  end
    
  methods
    function obj = adaptable(matrix)                 
      if nargin>0        
       assert(isempty(matrix)||ismatrix(matrix),...
                'Input must be a matrix');
        
       obj.origMatrix = matrix;      
       obj.currMatrix = matrix;      
      else
       obj.origMatrix = [];
       obj.currMatrix = [];
      end;
    end

    function [out] = ctranspose(in)
      out = in;
      out.currMatrix = out.currMatrix';
      out.isTransposed = ~in.isTransposed;
    end;        

    function [out] = transpose(in)
      out = in;
      out.currMatrix = out.currMatrix.';
      out.isTransposed = ~in.isTransposed;
    end;
    
%     function out = get.currMatrix(obj)
%       keyboard
%       if obj.needsRebuild
%         keyboard;
%         warning(['Forcing rebuild in get.currMatrix.  This will run, ' ...
%                 'but likely VERY SLOWLY.  Add an obj.rebuildCurrMatrix ' ...
%                 'statement before using']);
%        % obj = obj.rebuildCurrMatrix; 
%         
%       end;
%       out = []; %obj.currMatrix;
%     end;
          
    function out = mtimes(a,b)
      if isa(a,'adaptable')
        C1 = a.currMatrix;
      else
        C1 = a;
      end;
      
      if isa(b,'adaptable')
        C2 = b.currMatrix;
      else
        C2 = b;
      end
      
      out = C1*C2;
    end       
               
    function out = size(obj,dim)  
      out = size(obj.currMatrix);
      if exist('dim','var')
        if (dim<=length(out))
          out = out(dim);
        else
          out = 1;
        end;
      end;
    end;
    
    function out = subsref(obj,S)
      switch S(1).type
        case '{}'
          error('Brace referencing not permitted with adaptable type');
        case '()'
          out = subsref(obj.currMatrix,S(1));
        case '.'
          out = builtin('subsref',obj,S);
      end

    end
       
  end
   

  methods (Abstract)
    obj = rebuildCurrMatrix(obj);
    out = canRebuild(obj);
  end
  
end
