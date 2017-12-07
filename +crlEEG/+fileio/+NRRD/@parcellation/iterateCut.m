function [CutOut] = iterateCut(cMatrix,nFinal,cutsPerLvl,avgSize,depth)

if ~exist('depth','var'), depth = 0; end;
if ~exist('avgSize','var'), avgSize = size(cMatrix,1)/nFinal; end;
if ~exist('cutsPerLvl','var'), cutsPerLvl = 2; end;

crlEEG.disp(['Running iterateCut at a depth of ' num2str(depth)]);

finalDepth = ceil(log2(nFinal));

% Get the cut at this depth
[Ncut,~,~] = GraphPkg.NormCut(cMatrix,cutsPerLvl);

tmpSizes = sum(Ncut,1);
% 
% % Check is the computed cut generates parcels that are too small in size. 
% 
% tooSmall = tmpSizes<0.25*avgSize;
% if any(~tooSmall)&&(numel(tooSmall)>2)
%   for idx = 1:length(tmpSizes)
%     if tooSmall(idx)
%       % Merge into next smallest region. This may create unconnected
%       % parcels, however.
%       nextSmallest = find(tmpSizes==min(tmpSizes(~tooSmall)),1);      
%       tmpSizes(nextSmallest) = tmpSizes(nextSmallest)+tmpSizes(idx);
%       Ncut(:,nextSmallest) = Ncut(:,nextSmallest) + Ncut(:,idx);
%     end;
%   end;
% else
%   % We should only get here if the starting parcel was too small to begin
%   % with.
%   CutOut = sum(Ncut,2);
%   return;
% end
% tmpSizes = tmpSizes(~tooSmall);
% Ncut = Ncut(:,~tooSmall);

% Turn off display outputs, otherwise it's going to spam the console
global cnlDebug; 
if ~isempty(cnlDebug), tmp = cnlDebug; else tmp = true; end;
cnlDebug = false;

for i = 1:size(Ncut,2)
  
  Ncut = logical(Ncut);
  size_Cut = tmpSizes(i);
  if false&&(depth>=finalDepth)
    % We're at the deepest depth, so just return the previously computed
    % cut.
    Cut = Ncut(:,i);
  else
    if size_Cut<cutsPerLvl*avgSize
      % The region is too small to provide 
      crlEEG.disp('Region sufficiently small. Returning final cut.');
      Cut = Ncut(:,i);
    else
      crlEEG.disp('Iterating cut');
      mat1 = cMatrix(Ncut(:,i),Ncut(:,i));
      [tmpCut1] = cnlParcellation.iterateCut(mat1,nFinal,cutsPerLvl,avgSize,depth+1);
      Cut = zeros(size(Ncut,1),size(tmpCut1,2));
      Cut(Ncut(:,i),:) = tmpCut1;
    end  
  end;
  
  % Update the output Cut
  if i == 1;
    CutOut = Cut;
  else
    CutOut = [CutOut Cut];
  end
end;

cnlDebug = tmp;

% if depth == finalDepth
%   
%   CutOut = Ncut;
%   
% else
%   Ncut = logical(Ncut);
%     
%   mat1 = cMatrix(Ncut(:,1),Ncut(:,1));
%   [tmpCut1] = iterateCut(mat1,nFinal,depth+1);
%   Cut1 = zeros(size(Ncut,1),size(tmpCut1,2));
%   Cut1(Ncut(:,1),:) = tmpCut1;
%   
%   
%   mat2 = cMatrix(Ncut(:,2),Ncut(:,2));
%   [tmpCut2] = iterateCut(mat2,nFinal,depth+1);
%   Cut2 = zeros(size(Ncut,1),size(tmpCut2,2));
%   Cut2(Ncut(:,2),:) = tmpCut2;
%     
%   CutOut = [Cut1 Cut2];
%   
% end

end