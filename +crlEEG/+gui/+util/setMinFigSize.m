function setMinFigSize(figureH,origin,imgsize,border)
% function setMinFigSize(figureH,origin,size)
%
% Resize the figure pointed to by figureH such that an image defined by the
% origin and size will be fully displayed in the figure.
%
% Written By: Damon Hyde
% Last Edited: May 23, 2016
% Part of the cnlEEG Project
%

if ~exist('border','var'), border = [10 10 10 10]; end;

currFigSize = get(figureH,'Position');
 if ~all( (origin+[imgsize]) <= currFigSize(3:4))    
    newBnd = [ currFigSize(3:4) ; origin+imgsize];
    newBnd = max(newBnd,[],1);
    set(figureH,'Position',[currFigSize(1:2) newBnd] + border);
 end;
 
end