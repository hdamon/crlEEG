function save_AllGeneratedFiles(obj)
% Save out all the files that have been generated


%% Build/Load The Full Segmentation
Ref = obj.options.segmentation.outputImgField;
fName = obj.options.segmentation.outputImgFName;
tmp = obj.getImage(Ref);
if ~isempty(tmp)
  tmp.write;  
end

%% Build/Load the Conductivity Image
Ref = obj.options.conductivity.outputCondField;
fName = obj.options.conductivity.outputCondFName;
tmp = obj.getImage(Ref);
if ~isempty(tmp)
  tmp.write;
end

%% Build/Load the Cortical Constraint Images
% This is slightly different, because we usually want these ending up in
% the same directory as the MRI
if isfield(obj.images,'surfNorm')
  if isstruct(obj.images.surfNorm)
    f = fields(obj.images.surfNorm);
    for i = 1:numel(f)
      tmp = obj.getImage(['cortConst.' f{i}]);      
      if ~isempty(tmp);
        tmp.write;
      end;      
    end
  else
    tmp =obj.getImage('cortConst');
    if ~isempty(tmp)
      tmp.write;
    end;    
  end
end;  

end