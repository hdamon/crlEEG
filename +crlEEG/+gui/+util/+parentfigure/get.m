function parentFig = get(obj)
% Returns the parent figure of a gui object

if ~isempty(obj)&&(ishghandle(obj)||isa(obj,'crlEEG.gui.uipanel'))
  if ishghandle(obj)
    parentFig = ancestor(obj,'figure');
  elseif isa(obj,'crlEEG.gui.uipanel')
    parentFig = ancestor(obj.panel,'figure');
  end
end

  