function success = raise(obj)
% Change focus to object's parent figure.
%
% success = crlEEG.gui.util.parentfigure.changeto(obj)
%
% Inputs
% ------
%  obj : uicontrol or crlEEG.gui.uipanel object
%
% Output
%  success : True if object succesfully found and figure focus changed
%
% Written By: Damon Hyde
% Part of the crlEEG Project
% 2009-2017
%

if ~isempty(obj)&&(ishghandle(obj)||isa(obj,'crlEEG.gui.uipanel'))
  if ishghandle(obj)
    figure(ancestor(obj,'figure'));
  elseif isa(obj,'crlEEG.gui.uipanel')
    figure(ancestor(obj.panel,'figure'));
  end
  success = true;
else
  success = false;
end;

end