function parcelOut = ensureConnectedParcels(parcelIn,varargin)
% Relabel parcels so that each is fully connected
%
% function parcelOut = ensureConnectedParcels(parcelIn)
%
% Iterates through each parcel, and relabels all extra connected
% components.  The neighbors of these components are then identified, and
% the regions are merged given sufficient connectivity.  Isolated voxels
% which are not connected to larger regions are removed from the
% parcellation.
%
% Written By: Damon Hyde
% Last Edited: Aug 6, 2015
% Part of the cnlEEG Project
%

crlEEG.disp(['Ensuring all parcels are simply connected'],4);

%% Input Parsing
p = inputParser;
p.addParamValue('fname','tmpConnectedParcel.nhdr');
p.addParamValue('fpath','./');
p.addParamValue('minsize',10);
parse(p,varargin{:});

% Get parcel labels and eliminate background parcel
parcelLabels = unique(parcelIn.data(:));
parcelLabels(parcelLabels==0) = [];
nParcel = length(parcelLabels);

outLabel = 10*max(parcelLabels); % Label for floating parcels
minSize = p.Results.minsize;

%% Get statistics on parcel size
nVoxInParcel = zeros(1,nParcel);
for i = 1:numel(parcelLabels)
  nVoxInParcel(i) = numel(find(parcelIn.data==parcelLabels(i)));
end;
meanSize = mean(nVoxInParcel);
stdSize = std(nVoxInParcel);

%% Initialize Output
parcelOut = clone(parcelIn,p.Results.fname,p.Results.fpath);
parcelOut.data = zeros(parcelOut.sizes);

crlEEG.disp('Labelling all floating connected components');
for idxP = 1:nParcel
  currLabel     = parcelLabels(idxP);      
  currParcelImg = (parcelIn.data==currLabel);
  idxParcelVox  = find(currParcelImg);
  nVoxInParcel(idxP) = numel(idxParcelVox);
   
%    if idxP==510
%      keyboard;
%    end;
  
  % If the parcel is too small, try reassigning it and move to the next
  % parcel
  if (nVoxInParcel(idxP)<minSize)
    parcelOut.data(idxParcelVox) = outLabel; 
    continue;
  end;
    
  % Get Connected Components of Current Parcel  
  %nVoxInParcel = sum(parcelOut.data(:)==currLabel);
  CC = bwconncomp(currParcelImg,6);   
  
  % If the parcel is already a single connected component, then we're all
  % set. Just assign the label and move to the next parcel
  if CC.NumObjects==1
    parcelOut.data(idxParcelVox) = currLabel;
    continue;
  end;
  
  % If more than once connected component was identified, we need to 
  crlEEG.disp(['Found ' num2str(CC.NumObjects) ' connected components in parcel ' num2str(idxP)],5);
 
  % Get maximum length
  lengths = zeros(CC.NumObjects,1);
  for i = 1:numel(lengths)
    lengths(i) = numel(CC.PixelIdxList{i});
  end;
  maxLen = max(lengths);
  
  % Pick one to keep
  keepParcel = (lengths==maxLen);
  
  % If the largest connected component isn't at least half the size of
  % the full parcel, reassign all components to other parcels
  if maxLen<minSize, keepParcel = false&keepParcel; end;
        
  % If there's more than one candidate to retain, pick one at random
  if sum(keepParcel)>1, 
    Q = find(keepParcel);
    keepIdx = Q(randperm(numel(Q),1));
    keepParcel = false&keepParcel;
    keepParcel(keepIdx) = true;
  end
  
  % Assign labels in output parcellation
  for idxCC = 1:CC.NumObjects
    if keepParcel(idxCC) %numel(CC.PixelIdxList{idxCC})==maxLen
      parcelOut.data(CC.PixelIdxList{idxCC}) = currLabel;
    else
      parcelOut.data(CC.PixelIdxList{idxCC}) = outLabel;
    end
  end

end;

%% Get statistics on parcel size
parcelLabelsOut = unique(parcelOut.data(:));
nVoxInParcel = zeros(1,numel(parcelLabelsOut));
for i = 1:numel(parcelLabelsOut)
  nVoxInParcel(i) = numel(find(parcelOut.data==parcelLabelsOut(i)));
end;
%keyboard;

% Get Image connectivity and connected components to be reassigned.
imgConn = parcelOut.gridSpace.getGridConnectivity;
CC = bwconncomp(parcelOut.data==outLabel,6);

crlEEG.disp('Merging unconnected components into other parcels');
for idxCC = 1:CC.NumObjects
  tmpConn = imgConn(:,CC.PixelIdxList{idxCC});
  tmpConn = sum(tmpConn,2);
  tmpConn = tmpConn>0;
  
  nbrLabels = parcelOut.data(tmpConn);
  nbrLabels(nbrLabels==0) = [];
  nbrLabels(nbrLabels==outLabel) = [];
  
  if ~isempty(nbrLabels)
    done = false;
    mostCommonLabelOrig = mode(nbrLabels);    
    while ~done    
     mostCommonLabel = mode(nbrLabels);
     freqMostCommon = numel(find(nbrLabels==mostCommonLabel));
     
     if freqMostCommon > meanSize + 2*stdSize
       % If the parcel to merge into is too large, try to find a different
       % parcel to merge into
       nbrLabels(nbrLabels==mostCommonLabel) = [];
     elseif isempty(nbrLabels)
       % If we've run out of options, just merge into the original largest
       % one
       newParcelVal = mostCommonLabelOrig;
       done = true;
     else
       % If it's not too big, just go ahead and merge it in
       newParcelVal = mostCommonLabel;
       done = true;
     end;     
    end;

    crlEEG.disp(['Merged floating component into parcel ' num2str(mostCommonLabel)],5);    
  else    
    newParcelVal = 0;
  end
  
  parcelOut.data(CC.PixelIdxList{idxCC}) = newParcelVal;
  
end

  
crlEEG.disp(['Completed merging of disconnected parcels'],4);  

end