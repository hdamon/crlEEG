function varargout = testTopo(data,x,y,varargin)
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
  %  '

  %% Input Parsing
  p = inputParser;
  p.addParamValue('plotDiam',4);
  p.addParamValue('xyScale',1);
  p.addParamValue('circRadius',1.6);
  p.addParamValue('cmap',[]);
  p.parse(varargin{:});
 
  if isempty(p.Results.cmap)
    cmap = crlEEG.gui.widget.alphacolor;
    cmap.range = [min(data(:)) max(data(:))];
  else
    cmap = p.Results.cmap; 
  end;
  topoOut.cmap = cmap;
  
  plotDiam = p.Results.plotDiam;
  scale = p.Results.scale;
  
  %% Scale locations and interpolate on a regular grid
  x = scale*x; y = scale*y;
  F = scatteredInterpolant(x(:),y(:),data(:));
  %F.ExtrapolationMethod = 'none';
  
  xGrid = linspace(-plotDiam/2,plotDiam/2,500);
  yGrid = linspace(-plotDiam/2,plotDiam/2,500);
  [X Y] = meshgrid(xGrid,yGrid);
  
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
  if ~holdStatus, hold off; end;
  
  a = gca; a.YDir = 'normal'; axis off;
  
  if nargout>0
    varargout{1} = topoOut;
  end;
end

  