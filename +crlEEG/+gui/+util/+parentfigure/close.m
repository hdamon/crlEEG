function success = close(obj)
% Close an object's parent figure
%
% success = crlEEG.gui.util.parentfigure.close(obj)
%
% Inputs
% ------
%  obj : uicontrol or crlEEG.gui.uipanel object
%  
% Output
% ------
%  success : True if object succesfully located figure closed
%
% Written By: Damon Hyde
% Part of the crlEEG Project
% 2009-2017
%

if ~isempty(obj)&&ishghandle(obj)
  delete(ancestor(obj,'figure'));
end;

end