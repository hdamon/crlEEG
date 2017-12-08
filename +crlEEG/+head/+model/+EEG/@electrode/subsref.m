function varargout = subsref(obj,s)
switch s(1).type
  case '.'
    if length(s) == 1
      % Implement obj.PropertyName
      varargout = {builtin('subsref',obj,s)};
    elseif length(s) == 2 && strcmp(s(2).type,'()')
      % Implement obj.PropertyName(indices)
      varargout = {builtin('subsref',obj,s)};
    else
      varargout = {builtin('subsref',obj,s)};
    end
  case '()'
    if length(s) == 1
      % Implement obj(indices)
      if iscellstr(s.subs{1})|ischar(s.subs{1})
        % Provided a cell array of strings
        outIdx = obj.getNumericIndex(s.subs{1});
        varargout = {obj(outIdx)};
      else
        % 
        varargout = {builtin('subsref',obj,s)};
      end;
      
    elseif length(s) == 2 && strcmp(s(2).type,'.')
      % Implement obj(ind).PropertyName
      
%       if iscellstr(s(1).subs{1})|ischar(s(1).subs{1})
%        % Get the referenced element      
%        outIdx = obj.getNumericIndex(s(1).subs{1});
%        tmpObj = obj(outIdx);
%       else
%         tmpObj = builtin('subsref',obj,s(1));
%       end;
%                   
%       varargout = {builtin('subsref',tmpObj,s(2))};
      
      varargout = {builtin('subsref',obj,s)};
    elseif length(s) == 3 && strcmp(s(2).type,'.') && strcmp(s(3).type,'()')
      % Implement obj(indices).PropertyName(indices)
            
      varargout = {builtin('subsref',obj,s)};
    else
      % Use built-in for any other expression
      varargout = {builtin('subsref',obj,s)};
    end
  case '{}'
    if length(s) == 1
      % Implement obj{indices}
      varargout = {builtin('subsref',obj,s)};
    elseif length(s) == 2 && strcmp(s(2).type,'.')
      % Implement obj{indices}.PropertyName
      varargout = {builtin('subsref',obj,s)};
    else
      % Use built-in for any other expression
      varargout = {builtin('subsref',obj,s)};
    end
  otherwise
    error('Not a valid indexing expression')
end

 

end


