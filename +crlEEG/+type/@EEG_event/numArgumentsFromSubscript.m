function n = numArgumentsFromSubscript(obj,s,indexingContext)
% numArgumentsFromSubscript for EEG_event objects  

% Default
if ~iscell(s(1).subs)
  n = builtin('numArgumentsFromSubscript',obj,s,indexingContext);
else
  % Invoked when passing a cell array as an indexing term
  %  IE: Using character based referencing.
  n = 1;
end;
  
% Optional overrides
   switch indexingContext
      case matlab.mixin.util.IndexingContext.Statement
        switch s(1).type
          case '()'
            if ischar(s(1).subs{1})             
             n = 1; % nargout for indexed reference used as statement            
            end  
          otherwise
        end;            
      case matlab.mixin.util.IndexingContext.Expression
        switch s(1).type
          case '()'            
          otherwise
        end;         
         %n = 1; % nargout for indexed reference used as function argument
      case matlab.mixin.util.IndexingContext.Assignment        
        
         %n = 1; % nargin for indexed assignment
   end
end