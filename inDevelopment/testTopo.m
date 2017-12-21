function varargout = testTopo(data,x,y,varargin)

  % Input Parsing
  p = inputParser;
  p.addParamValue('diam',4);
  p.addParamValue('scale',1);
  p.addParamValue('thresh',1.6);
  p.addParamValue('cmap',[]);
  p.parse(varargin{:});
 
  if isempty(p.Results.cmap),
    cmap = crlEEG.gui.widget.alphacolor;
    cmap.range = [min(data(:)) max(data(:))];
  else
    cmap = p.Results.cmap; 
  end;
  topoOut.cmap = cmap;
  
  diam = p.Results.diam;
  scale = p.Results.scale;
  
  x = scale*x; y = scale*y;
  F = scatteredInterpolant(x(:),y(:),data(:));
  
  xGrid = linspace(-diam/2,diam/2,500);
  yGrid = linspace(-diam/2,diam/2,500);
  [X Y] = meshgrid(xGrid,yGrid);
  
  D = F(X,Y);
  
  % NaN's outside the circle
  r = sqrt(X.^2+Y.^2); 
  Q = r>p.Results.thresh;
  D(Q) = nan;
  
  [Dimg, Dalpha] = cmap.img2rgb(D);
  
  holdStatus = ishold(gca);
  hold on;
  topoOut.img = image(xGrid,yGrid,Dimg);
  if ~holdStatus, hold off; end;
  
  a = gca; a.YDir = 'normal'; axis off;
  
  if nargout>0
    varargout{1} = topoOut;
  end;
end

  