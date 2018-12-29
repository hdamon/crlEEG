function varargout = dataTopo(elec,data,varargin)
% Draw a 2D scalp topography with electrode locations
%
% Inputs
% ------
%  elec : crlEEG.head.model.EEG.electrode object
%  data : data to display in topography plot
%
% Outputs
% -------
%   varargout{1} : Structure with plot handles
%
% Part of the cnlEEG Project
% 2009-2018
%


% Input Parsing
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('elec');
p.addRequired('data');
p.addParameter('cmap',[],@(x) isa(x,'guiTools.widget.alphacolor'));
p.addParameter('figure',[],@(x) ishghandle(x));
p.addParameter('axis',[],@(x) ishghandle(x));
p.parse(elec,data,varargin{:});

% Figure Selection
if ~isempty(p.Results.figure)
  figure(p.Results.figure);
else
  figure;
end

% Set Default Colormap
cmap = p.Results.cmap;
if isempty(cmap)
  cmap = guiTools.widget.alphacolor; 
  cmap.range = [min(data(:)) max(data(:))];
end

% Plot Electrode Locations
elecPlot = elec.plot2D('figure',gcf,varargin{:});
elecPlot = elecPlot(1);

% Draw Topographic Plot
topoPlot = drawTopo(data,elecPlot.scatter.XData,...
                         elecPlot.scatter.YData,...
                         'cmap',cmap,varargin{:});
uistack(elecPlot.scatter,'top');
if isfield(elecPlot,'text')
  uistack(elecPlot.text,'top');
end

  topoOut.figure = gcf;
  topoOut.axis = gca;
  topoOut.elecPlot = elecPlot;
  topoOut.topoPlot = topoPlot;
  topoOut.headCartoon = guiTools.util.drawHeadCartoon(gca);

% Optional Outputs
if nargout>0
  varargout{1} = topoOut;
end

end

function varargout = drawTopo(data,x,y,varargin)
  % Topographic Data Plot
  %
  % Inputs
  % ------
  %   data : Data to be plotted
  %    x,y : 2D Data Locations
  %
  % Optional
  % --------
  %  'plotDiam'  : Overall plotDiameter of plot 
  %  'scale' : Scaling of x-y Locations
  %  'circRadius' : Radius circle to display
  %  'cmap' : guiTools.widget.alphacolor object
  %

  %% Input Parsing
  p = inputParser;
  p.KeepUnmatched = true;
  p.addParameter('plotDiam',4);
  p.addParameter('xyScale',1);
  p.addParameter('circRadius',1.75);
  p.addParameter('cmap',[],@(x) isa(x,'guiTools.widget.alphacolor'));
  p.parse(varargin{:});
 
  if isempty(p.Results.cmap)
    cmap = guiTools.widget.alphacolor;
    cmap.range = [min(data(:)) max(data(:))];
  else
    cmap = p.Results.cmap; 
  end
  topoOut.cmap = cmap;
  
  plotDiam = p.Results.plotDiam;
  scale = p.Results.xyScale;
  
  %% Scale locations and interpolate on a regular grid
  x = scale*x; y = scale*y;
  F = scatteredInterpolant(x(:),y(:),data(:));
  F.ExtrapolationMethod = 'none';
  
  xGrid = linspace(-plotDiam/2,plotDiam/2,500);
  yGrid = linspace(-plotDiam/2,plotDiam/2,500);
  [X, Y] = meshgrid(xGrid,yGrid);
  
  D = F(X,Y);
  
  % NaN's outside the circle
  r = sqrt(X.^2+Y.^2); 
  Q = r>p.Results.circRadius;
  D(Q) = nan;
  
  % Get Color Image
  [Dimg, Dalpha] = cmap.img2rgb(D);
  
  holdStatus = ishold(gca);
  hold on;
  topoOut.img = image(xGrid,yGrid,Dimg);
  topoOut.img.AlphaData = ones(size(D));
  topoOut.img.AlphaData(isnan(D)) = 0;
  if ~holdStatus, hold off; end
  
  a = gca; a.YDir = 'normal'; axis off;
  
  if nargout>0
    varargout{1} = topoOut;
  end
end
