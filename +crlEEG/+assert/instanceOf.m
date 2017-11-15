function instanceOf(type,obj)

try
  assert(isa(obj,type),...
    ['Input must be a ' type ' object.']);
catch ERR
  throwAsCaller(ERR);
end

end
