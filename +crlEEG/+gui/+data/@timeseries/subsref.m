function varargout = subsref(obj,s)
switch s(1).type
  case '.'    
    varargout = {builtin('subsref',obj,s)};    
  case '()'
    if length(s) == 1
      % Implement obj(indices)
      if numel(obj)==1
        % Accessing as obj(a)
        if numel(s.subs)==1
          % If the subsref is a cell array, we're indexing by
          % electrode labels.
          %
          if iscellstr(s.subs{1}) % Cell array of strings            
            outIdx = getIdxFromStringCell(s.subs{1});
          elseif ischar(s.subs{1}) % Single character string            
            outIdx = getIdxFromStringCell({s.subs{1}});          
          else % Poorly defined            
            error('Use 2D Indexing with Numeric Values');
          end;
          varargout = {crlEEG.gui.data.timeseries(obj.data(:,outIdx),obj.labels(outIdx),...
                            'xvals',obj.xvals)};
        elseif numel(s.subs)==2
          % Accessing as obj(a,b)
          
          % Get Output Electrode Indexing
          if isnumeric(s.subs{2}) % Numeric indexing
            outIdx = s.subs{2};
          elseif isequal(s.subs{2},':') 
            outIdx = 1:size(obj.data,2);
          elseif iscellstr(s.subs{2})
            outIdx = getIdxFromStringCell(s.subs{2});
          elseif ischar(s.subs{2})
            outIdx = getIdxFromStringCell({s.subs{2}});
          else
            error('Unsupported channel indexing format');
          end;
          
          % Only allow numeric second dimension indexing
          assert(isequal(s.subs{1},':')||isnumeric(s.subs{1}),'Second dimension indexing must be numeric');
          
          varargout = ...
            { ...
            crlEEG.gui.data.timeseries(obj.data(s.subs{1},outIdx),...
            obj.labels(outIdx),'xvals',obj.xvals(s.subs{1})) ...
            };
                    
        else
          error('Invalid indexing expression');
        end;
      else
        varargout = {obj(s.subs{:})};
      end;
    elseif length(s) == 2 && strcmp(s(2).type,'.')
      % Implement obj(ind).PropertyName
      if numel(s(1).subs)==1
        tmp = obj.subsref(s(1));
        varargout = {builtin('subsref',tmp,s(2))};
      else
        varargout = {builtin('subsref',obj,s)};
      end;
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

  function outIdx = getIdxFromStringCell(cellIn)
    outIdx = zeros(1,numel(cellIn));
    for idx = 1:numel(outIdx)
      tmp = find(strcmp(cellIn{idx},obj.labels));
      assert(numel(tmp)==1,'Invalid Index Labels');
      outIdx(idx) = tmp;
    end
  end

end


