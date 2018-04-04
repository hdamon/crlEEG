function varargout = subsref(obj,s)
%% Subsref for crlEEG.type.EEG_event
%
   switch s(1).type
      case '.'
        [varargout{1:nargout}] = builtin('subsref',obj,s);
        return;
         if length(s) == 1
            % Implement obj.PropertyName
            ...
         elseif length(s) == 2 && strcmp(s(2).type,'()')
            % Implement obj.PropertyName(indices)
            ...
         else
            [varargout{1:nargout}] = builtin('subsref',obj,s);
         end
      case '()'
         if length(s) == 1
            % Implement obj(indices)
            if (numel(s.subs)==2&&ischar(s.subs{1})) 
              switch validatestring(s.subs{1},{'type','description'})
                case 'type'                 
                  idx = find(cellfun(@(x) x==s.subs{2},{obj.type}));
                  [varargout{1:nargout}] = obj(idx);
                case 'description'
                  testString = validatestring(s.subs{2},unique({obj.description}));
                  idx = find(cellfun(@(x) isequal(x,testString),{obj.description}));
                  [varargout{1:nargout}] = obj(idx);                  
              end
            else
              [varargout{1:nargout}] = builtin('subsref',obj,s);
            end
         elseif length(s) == 2 && strcmp(s(2).type,'.')
            % Implement obj(ind).PropertyName
            tmpObj = obj.subsref(s(1));
            [varargout{1:nargout}] = builtin('subsref',tmpObj,s(2));
         elseif length(s) == 3 && strcmp(s(2).type,'.') && strcmp(s(3).type,'()')
            % Implement obj(indices).PropertyName(indices)
            [varargout{1:nargout}] = builtin('subsref',obj,s);
         else
            % Use built-in for any other expression
            [varargout{1:nargout}] = builtin('subsref',obj,s);
         end
      case '{}'
        [varargout{1:nargout}] = builtin('subsref',obj,s);
        return;
         if length(s) == 1
            % Implement obj{indices}
            ...
         elseif length(s) == 2 && strcmp(s(2).type,'.')
            % Implement obj{indices}.PropertyName
            ...
         else
            % Use built-in for any other expression
            [varargout{1:nargout}] = builtin('subsref',obj,s);
         end
      otherwise
         error('Not a valid indexing expression')
   end