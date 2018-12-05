function n = numArgumentsFromSubscript(obj,s,indexingContext)    

   if ismember(s(end).subs,{'plot3D','plot2D','center','basis','projPos'})
     n = 1;
   else
     n = builtin('numArgumentsFromSubscript',obj,s,indexingContext);
   end
   
end