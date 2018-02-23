function n = numArgumentsFromSubscript(obj,s,indexingContext)
  
% Default
n = builtin('numArgumentsFromSubscript',obj,s,indexingContext);

% Optional overrides
   switch indexingContext
      case matlab.mixin.util.IndexingContext.Statement
        switch s(1).type
          case '()'
            if numel(obj)==1
             % When 
             n = 1; % nargout for indexed reference used as statement            
            end  
          otherwise
        end;            
      case matlab.mixin.util.IndexingContext.Expression
         
         %n = 1; % nargout for indexed reference used as function argument
      case matlab.mixin.util.IndexingContext.Assignment        
        
         %n = 1; % nargin for indexed assignment
   end
end