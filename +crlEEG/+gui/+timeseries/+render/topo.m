function varargout = topo(timeseries,timepoint,varargin)
% Topographic plots of timeseries data
%
% Inputs
% ------
%   timeseries : Input timeseries object
%                 ( Class : crlEEG.type.data.timeseries )
%   timepoint  : Index into timeseries to plot topographic map of.
%   
% Optional Inputs
% ---------------
%   ax : axis to plot to
%
% Param-Value Inputs
% ------------------
%   'headNet' : Headnet for defining the geometry
%                 ( Class : crlEEG.head.model.EEG.headNet )
%   'x','y' :  X and Y coordinates to plot the data at. Both must be provided
%                 to use this option.
%
% Part of the crlEEG project
% 2009-2017
%


%% Input Parsing
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('timeseries',@(x) isa(x,'crlEEG.type.data.timeseries'));
p.addRequired('timepoint',@(x) isnumeric(x)&&isscalar(x));
p.addOptional('ax',[],@(x) ishghandle(x)&&strcmpi(get(x,'type'),'axes'));
p.addParamValue('headNet',[],@(x) isa(x,'headNet'));
p.addParamValue('x',[],@(x) isnumeric(x)&&isvector(x));
p.addParamValue('y',[],@(x) isnumeric(x)&&isvector(x));
parse(p,timeseries,timepoint,varargin{:});

headNet = p.Results.headNet;

% If no axis provided, open a new figure with Axes
ax = p.Results.ax;
if isempty(ax), figure; ax = axes; end;
axes(ax);

if ~isempty(headNet)
  % Plot using a headmap object    
  elecPlot = headNet.plot('axis',ax,'plotlabels',timeseries.labels);
        
  topoPlot = plotTopo(timeseries.data(timepoint,:),...
    elecPlot.scatter.XData,...
    elecPlot.scatter.YData,...
    p.Unmatched);    
  uistack(elecPlot.scatter,'top');
else
  % Plot using X-Y values
  assert(~isempty(p.Results.x)&&~isempty(p.Results.y),...
            'Both X and Y values must be provided');
  elecPlot = [];
  topoPlot = plotTopo(data,x,y,p.Unmatched);       
end

topoOut.figure = gcf;
topoOut.axis = gca;
topoOut.elecPlot = elecPlot;
topoOut.topoPlot = topoPlot;
topoOut.headCartoon = crlEEG.gui.util.drawHeadCartoon(gca,'diam',1.2);

if nargout>0
  varargout{1} = topoOut;
end;

end

function varargout = plotTopo(data,x,y,varargin)

  % Input Parsing
  p = inputParser;
  p.addParamValue('diam',4);
  p.addParamValue('scale',1);
  p.addParamValue('thresh',1.6);
  p.addParamValue('cmap',[]);
  p.parse(varargin{:});
 
  if isempty(p.Results.cmap)
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
  %F.ExtrapolationMethod = 'none';
  
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
  topoOut.img.AlphaData = ones(size(D));
  topoOut.img.AlphaData(isnan(D)) = 0;
  if ~holdStatus, hold off; end;
  
  a = gca; a.YDir = 'normal'; axis off;
  
  if nargout>0
    varargout{1} = topoOut;
  end;
end
