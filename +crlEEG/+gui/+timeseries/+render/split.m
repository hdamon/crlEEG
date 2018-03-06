function plotOut = split(tseries,varargin)
% Split Data Plot With Labels
%
% THIS HELP IS OUT OF DATE AND NEEDS TO BE REWRITTEN
%
% Inputs:
%   data (required): (nSamples X nChannels data matrix)
%   ax   (optional): (Axis to plot to)
%
% Param-Value Inputs:
%   'xvals'    : Values along X-axis (otherwise assumed to be 1:N)
%   'yrange'   : Range of values to display on Y-Axis
%   'scale'    : Scaling factor
%   'labels'   : Labels for each channel
%
% Written By: Damon Hyde
% Last Edited; May 24, 2016
% Part of the cnlEEG Project
%

%% Input Parsing
p = inputParser;
p.addRequired('tseries',@(x) isa(x,'crlEEG.type.data.timeseries'));
p.addOptional('ax',[],@(x) ishghandle(x)&&strcmpi(get(x,'type'),'axes'));
p.addParamValue('xrange',tseries.xrange,@(x) isvector(x)&&(numel(x)==2));
p.addParamValue('yrange',tseries.yrange,@(x) isvector(x)&&(numel(x)==2));
p.addParamValue('scale',1,@(x) isnumeric(x)&&numel(x)==1);
p.addParamValue('plotAll',false,@(x) islogical(x));
p.parse(tseries,varargin{:});

ax = p.Results.ax;
xrange = p.Results.xrange;
yrange = p.Results.yrange;
scale = p.Results.scale;
xvals = tseries.xvals;
labels = tseries.labels;

%% If no axis provided, open a new figure with Axes
if isempty(ax), figure; ax = axes; end;
axes(ax);

%% For long time series, only render a subset of timepoints      
if ( size(tseries,1) > 10000 )&&~p.Results.plotAll
  useIdx = round(linspace(1,size(tseries,1),10000));
  useIdx = unique(useIdx);
else
  useIdx = ':';
end;

% Get data range and scale
%delta = yrange(2)-yrange(1);
delta = max(abs(yrange));

boolChan = tseries.isBoolChannel;
data = tseries.getPlotData;
data = scale * ( data(useIdx,:)./delta );

% Plot things.
hold on;
for i = 1:size(data,2)
  offset = size(data,2) - (i -1);
  ax.NextPlot = 'add';
  if boolChan(i)
    color = 'b';
  else
    color = 'k';
  end;
  plotOut(i) = plot(xvals(useIdx),data(:,i)+offset,color,...
                      'ButtonDownFcn',get(ax,'ButtonDownFcn'));
 % set(ax,'ButtonDownFcn',get(plotOut(i),'ButtonDownFcn'));
end;
ax.XLim = xrange;
ax.YLim = [0 size(data,2)+1];

ticks = 1:size(data,2);
if isempty(labels), labels = 1:size(data,2); end
set(ax,'YTick',ticks);
if exist('flip')
  set(ax,'YTickLabel',flip(labels));
else
  % Compatibility w/ earlier matlab versions.
  set(ax,'YTickLabel',flipdim(labels,2));
end
end

