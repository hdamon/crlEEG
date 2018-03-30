function outIdx = getIndexIntoCellStr(cellIn,refIn,isNumericValid)
% Reference into a cell string by name or number
%
% function out = getIndexIntoCellStr(cellIn,refIn)
%
% Inputs
% ------
%   cellIn : Cell array of strings to reference into
%    refIn : Requested references. This can be:
%             ':'       : Return all indices
%             'string'  : Return a single index matching 'string'
%             {'a' 'b'} : A cell array of strings to match
%             numeric   : A numeric array
% isNumericValid : Flag to determine if numeric indexing should be allowed. 
%                     DEFAULT: True
%
% Output
% ------
%   outIdx : The requested indices, either as a numeric array, or
%              as ':' if all indices are requested.
% 
% Part of the crlEEG Project
% 2009-2018
%

%% Input Checking
if ischar(cellIn)
  cellIn = {cellIn};
end;
assert(iscellstr(cellIn),...
  'Input cellIn must be a character array or a cell array of character arrays');

if ~exist('isNumericValid','var'), isNumericValid = true; end;

if isequal(refIn,':')
  %% Requested Everything
    outIdx = refIn;
    return;

elseif islogical(refIn)
  assert(numel(refIn)==numel(cellIn),'FOOOO');
  outIdx = find(refIn);
    
elseif isnumeric(refIn)
  %% Numeric Reference
  if isNumericValid
    outIdx = refIn;
    outIdx(outIdx<1) = nan;
    outIdx(outIdx>numel(cellIn)) = nan;
  else
    error('Invalid numeric indexing');
  end;

elseif ischar(refIn)||iscellstr(refIn)
  %% String Reference 
  if ischar(refIn), refIn = {refIn}; end;
  cellIn = strtrim(cellIn);
  refIn = strtrim(refIn);
  outIdx = zeros(1,numel(refIn));
  for idx = 1:numel(outIdx)
    tmp = find(strcmp(refIn{idx},cellIn));
    if isempty(tmp), tmp = nan; end;
    assert(numel(tmp)==1,'Multiple string matches in cellIn');
    outIdx(idx) = tmp;
  end
    
else
  %% Otherwise, error.
  error('Incorrect reference type');
end;