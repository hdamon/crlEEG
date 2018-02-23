function instanceOf(type,obj)
% Assert object type and throw as caller if failed.
%
%

try
  assert(isa(obj,type),...
    ['Input must be a ' type ' object.']);
catch ERR
  throwAsCaller(ERR);
end

end
