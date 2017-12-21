function varargout = dataTopo(elec,center,basis,data,cmap)
% Draw a 2D scalp topography with electrode locations
%
% Inputs
% ------
%  elec : crlEEG.head.model.EEG.electrode object
%  center : point to use as center of spherical coordinates
%  basis : basis set to use in computing relative coordinates
%  data : data to display in topography plot
figure;

if ~exist('cmap','var') 
  cmap = crlEEG.gui.widget.alphacolor; 
  cmap.range = [min(data(:)) max(data(:))];
end;

elecPlot = elec.plot2D(center,basis,'figure',gcf);
topoPlot = testTopo(data,elecPlot.scatter.XData,...
                         elecPlot.scatter.YData,...
                         'cmap',cmap);
uistack(elecPlot.scatter,'top');

topoOut.figure = gcf;
topoOut.axis = gca;
topoOut.elecPlot = elecPlot;
topoOut.topoPlot = topoPlot;
topoOut.headCartoon = crlEEG.gui.util.drawHeadCartoon(gca);

if nargout>0
  varargout{1} = topoOut;
end;

end