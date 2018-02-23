function isValid = isNumericVector(x,length)
%% Check is value is a numeric vector, with optional length argument

if ~exist('length','var'),length = []; end;

isValid = isnumeric(x)&&isvector(x);

if isValid&&~isempty(length)
  isValid = ( numel(x)==length );
end
  
end
  