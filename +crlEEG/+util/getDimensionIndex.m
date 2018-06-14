function outIdx = getDimensionIndex(cellIn,refIn,isNumericValid)
% Reference into a cell string by name or number
%
% function out = getDimensionIndex(cellIn,refIn)
%
% Inputs
% ------
%         cellIn : Dimension definition to reference into: This can be:
%                     1) A cell array of strings
%                     2) A scalar numeric value
%                     With 1) 
%
%          refIn : Requested references. This can be:
%                     ':'       : Return all indices
%                     'string'  : Return a single index matching 'string'
%                     {'a' 'b'} : A cell array of strings to match
%                     numeric   : A numeric array
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
if isnumeric(cellIn)&&isscalar(cellIn)
  cellIn = repmat({''},cellIn,1);
  isStringValid = false;
else
  isStringValid = true;
end

if ischar(cellIn), cellIn = {cellIn}; end;
assert(iscellstr(cellIn),...
  'Input cellIn must be a character array or a cell array of character arrays');

if ~exist('isNumericValid','var'), isNumericValid = true; end;

if isequal(refIn,':')
  %% Requested Everything
    outIdx = refIn;
    return;

elseif islogical(refIn)
  assert(numel(refIn)==numel(cellIn),'FOOOO_-');
  outIdx = find(refIn);
  return;
   
elseif isnumeric(refIn)
  %% Numeric Reference
  if isNumericValid
    if any(refIn<1)||any(refIn>numel(cellIn))
      error('Requested index outside of available range');
    end;
    outIdx = refIn;
    %outIdx(outIdx<1) = nan;
    %outIdx(outIdx>numel(cellIn)) = nan;
    return;
  else
    error('Numeric indexing unavailable in this context');
  end;

elseif ischar(refIn)||iscellstr(refIn)
  %% String Reference 
  if ~isStringValid
    error('String indexing unavailable in this context');
  end;
  
  if ischar(refIn), refIn = {refIn}; end;
  cellIn = strtrim(cellIn);
  refIn = strtrim(refIn);
  outIdx = zeros(1,numel(refIn));
  for idx = 1:numel(outIdx)
    tmp = find(strcmp(refIn{idx},cellIn));
    if isempty(tmp)
      error('Requested string does not appear in cell array');
    end;
    assert(numel(tmp)==1,'Multiple string matches in cellIn');
    outIdx(idx) = tmp;
  end
    
else
  %% Otherwise, error.
  error('Incorrect reference type');
end;