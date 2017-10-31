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
        outIdx = getIdxFromStringCell(s.subs{1});
        varargout = {obj(outIdx)};
        %elseif ischar(s.subs{1})
        %  % Provided a single character string
        %  outIdx = getIdxFromStringCell({s.subs{1}});
        %  varargout = {cnlLabelledData(obj.data(outIdx,:),obj.labels(outIdx),...
        %    'epochstart',obj.epochs_start, 'epochend',obj.epochs_end)};
      else
        % Poorly defined indexing. Don't allow it.
        varargout = {builtin('subsref',obj,s)};
      end;
      
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

 function outIdx = getIdxFromStringCell(cellIn)
    assert(iscellstr(cellIn)||ischar(cellIn),'FOOERR');
    if ischar(cellIn), cellIn = {cellIn}; end;
    outIdx = zeros(1,numel(cellIn));
    for idx = 1:numel(outIdx)
      tmp = find(strcmp(cellIn{idx},{obj.label}));
      assert(numel(tmp)==1,'Multiple Electrodes Match Requested Label');
      outIdx(idx) = tmp;
    end
  end

end


