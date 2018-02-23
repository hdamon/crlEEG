function isValid = isScalarNumeric(x)
% Check if a value is both scalar and numeric.

isValid = isscalar(x)&&isnumeric(x);

end