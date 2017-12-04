classdef (Abstract) adaptableMatrix 
  
  % classdef adaptableMatrix
  %
  % Class for defining adaptable matrices.  It's an abstract class, do it
  % can't be used on it's own. I'm putting the main functionality (origMatrix, currMatrix,
  % isTransposed, ctranspose() and mtimes(), here.
  %
  % Parameters defining the adaptability are defined in the concrete
  % subclass, as is the method rebuildCUrrMatrix(obj), which constructs the new
  % currMatrix based on the altered parameters.
  %
  % Part of the cnlEEG project, 2013
  %
  % Properties:
  %  New:   origMatrix
  %         currMatrix
  %         isTransposed
  %         needsRebuild
  %
  % Methods:
  %      adaptableMatrix(matrix)  :  object constructor
  %      ctranspose
  %      mtimes
  %      size
  %      subsref
  %       
  % Abstract Methods:
  %      rebuildCurrMatrix : 
  
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
    function obj = adaptableMatrix(matrix)                 
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
      if isa(a,'adaptableMatrix')
        C1 = a.currMatrix;
      else
        C1 = a;
      end;
      
      if isa(b,'adaptableMatrix')
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
          error('Brace referencing not permitted with adaptableMatrix type');
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
