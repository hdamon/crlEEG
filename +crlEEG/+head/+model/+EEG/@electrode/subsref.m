function varargout = subsref(obj,s)
switch s(1).type
  case '.'
    if length(s) == 1
      % Implement obj.PropertyName      
      switch s(1).subs
        case {'plot3D','plot2D','center','basis','projPos'}
          % This is really a bit of a hack, and something should be done to
          % improve this behavior.
          %obj.(s(1).subs);
          varargout = {obj.(s(1).subs)};
          return;
        
        case {'center'}
          % More hack code
          varargout = {obj.center};
                          
        case 'basis'
          % More hack code
          varargout = {obj.basis};
          
        otherwise          
          tmp = cell(size(obj));
          for i = 1:numel(obj)
            tmp{i} = builtin('subsref',obj(i),s);
          end;
          
          switch s(1).subs
            case 'position'
              % This returns an array
              varargout = {cat(1,tmp{:})};
                         
            otherwise
              % Everything else returns a cell array
              varargout = {tmp};
          end;          
      end;
      %varargout = {builtin('subsref',obj,s)};
      
    elseif length(s) == 2 && strcmp(s(2).type,'()')
      % Implement obj.PropertyName(indices)
      switch s(1).subs
        case {'plot2D', 'plot3D', 'getNumericIndex','projPos'}
          % This if for calling these with additional arguments
          %obj.(s(1).subs)(s(2).subs{:});
          varargout = {obj.(s(1).subs)(s(2).subs{:})};
        otherwise
          tmp = obj.subsref(s(1));
          varargout = {builtin('subsref',tmp,s(2))};
      end;
      
    else
      varargout = {builtin('subsref',obj,s)};
    end
    
  case '()'
    if length(s) == 1
      % Implement obj(indices)
      varargout = {indexObj(obj,s)};     
      
    elseif length(s) == 2 && strcmp(s(2).type,'.')
      % Implement obj(ind).PropertyName
      [tmpObj,remS] = indexObj(obj,s);
      varargout = {tmpObj.subsref(remS)};      
      
    elseif length(s) == 3 && strcmp(s(2).type,'.') && strcmp(s(3).type,'()')
      % Implement obj(indices).PropertyName(indices)      
      [tmpObj,remS] = indexObj(obj,s);
      varargout = {tmpObj.subsref(remS)};
      
    else
      % Use built-in for any other expression
      [tmpObj,remS] = indexObj(obj,s);
      varargout = {tmpObj.subsref(remS)};
    end
    
  case '{}'
    error('Brace indexing not supported by crlEEG.head.model.EEG.electrode');
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


function [objOut,remS] = indexObj(obj,s)

if iscellstr(s(1).subs{1})||ischar(s(1).subs{1})
  % Get the referenced element
  outIdx = obj.getNumericIndex(s(1).subs{1});
  if ~any(isnan(outIdx))
   objOut = obj(outIdx);
  else
    error('Invalid index');
  end;
else
  objOut = builtin('subsref',obj,s(1));
end;

remS = s(2:end);
end

