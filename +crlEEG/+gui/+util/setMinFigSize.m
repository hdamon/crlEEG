function setMinFigSize(figureH,uiObj,border)
% function setMinFigSize(figureH,origin,size)
%
% Given a figure and a UI object, resizes the figure so that the UI object
% will be fully visible. An optional border can be specified
%
%
% Written By: Damon Hyde
% Last Edited: May 23, 2016
% Part of the cnlEEG Project
%

if ~exist('border','var'), border = [10 10 10 10]; end;

objUnits = get(uiObj,'Units');
figUnits = get(figureH,'Units');

set(figureH,'Units','pixels');
set(uiObj,'Units','pixels');

posObj = get(uiObj,'Position');
currFigSize = get(figureH,'Position');

if ~all( (posObj(1:2)+posObj(3:4)) <= currFigSize(3:4))
  newBnd = [ currFigSize(3:4) ; posObj(1:2)+posObj(3:4)];
  newBnd = max(newBnd,[],1);
  set(figureH,'Position',[currFigSize(1:2) newBnd] + border);
end;

set(figureH,'Units',figUnits);
set(uiObj,'Units',objUnits);

end