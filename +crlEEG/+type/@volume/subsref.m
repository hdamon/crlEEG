function varargout = subsref(obj,s)
switch s(1).type
  case '.'    
    varargout = {builtin('subsref',obj,s)};    
  case '()'
    if length(s) == 1
      % Implement obj(indices)
      varargout = {builtin('subsref',obj,s)};
           
    elseif length(s) == 2 && strcmp(s(2).type,'.')
      % Implement obj(ind).PropertyName
       varargout = {builtin('subsref',obj,s)};
      
    elseif length(s) == 3 && strcmp(s(2).type,'.') && strcmp(s(3).type,'()')
      % Implement obj(indices).PropertyName(indices)
      varargout = {builtin('subsref',obj,s)};
    else
      % Use built-in for any other expression
      varargout = {builtin('subsref',obj,s)};
    end
  case '{}'
    
    varargout = {builtin('subsref',obj,s)};
    
  otherwise
    error('Not a valid indexing expression')
end

end


