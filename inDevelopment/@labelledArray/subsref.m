function varargout = subsref(obj,s)
% subsref method for labelledArray objects
%

switch s(1).type
  case '.'    
    if length(s)>1
      tmp = subsref(obj,s(1));
      varargout = {subsref(tmp,s(2:end))};
    else
      [varargout{1:nargout}] = {builtin('subsref',obj,s)};
    end
  case '()'
    if length(s) == 1
      %% Implement obj(indices)
      if numel(obj)==1
        % Internal object indices can only be accessed individually        
        dimIdx = obj.getNumericIndex(s.subs{:});        
        varargout = {obj.subcopy(dimIdx{:})};
      else
        % Just use the builtin for arrays of objects
        varargout = {obj(s.subs{:})};
      end;
    else
      if numel(obj)==1
        % Get the right object, then reference into it.
        tmp = subsref(obj,s(1));
        varargout = {tmp.subsref(s(2:end))};
      else      
        % Use built-in for any other expression
        %  (IE: When you have an array of labelledArrays)
        varargout = {builtin('subsref',obj,s)};
      end;
    end
  case '{}'
    s2.type = '()';
    s2.subs = s(1).subs;
    tmp = obj.subsref(s2);
    
    if length(s)==1
      varargout = {tmp};
    else
      varargout = {tmp.subsref(s(2:end))};
    end;

  otherwise
    error('Not a valid indexing expression')
end