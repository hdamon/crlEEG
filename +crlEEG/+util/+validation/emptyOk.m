function isValid = emptyOk(x,fHandle)
% Adds empty set validity to existing validation function
%
%

if isempty(x), 
  isValid = true;
  return;
end

isValid = fHandle(x);
end