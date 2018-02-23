function plotOut = split(timeseries,varargin)
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
p.addRequired('timeseries',@(x) isa(x,'crlEEG.type.data.timeseries'));
p.addOptional('ax',[],@(x) ishghandle(x)&&strcmpi(get(x,'type'),'axes'));
p.addParamValue('yrange',timeseries.yrange,@(x) isvector(x)&&(numel(x)==2));
p.addParamValue('scale',1,@(x) isnumeric(x)&&numel(x)==1);
p.addParamValue('plotAll',false,@(x) islogical(x));
p.parse(timeseries,varargin{:});

ax = p.Results.ax;
yrange = p.Results.yrange;
scale = p.Results.scale;
xvals = timeseries.xvals;
labels = timeseries.labels;

%% If no axis provided, open a new figure with Axes
if isempty(ax), figure; ax = axes; end;
axes(ax);

%% For long time series, only render a subset of timepoints      
if ( size(timeseries,1) > 10000 )&&~p.Results.plotAll
  useIdx = round(linspace(1,size(timeseries,1),10000));
  useIdx = unique(useIdx);
else
  useIdx = ':';
end;

% Get data range and scale
delta = yrange(2)-yrange(1);

delta = max(abs(yrange));

% Scale Data
data = timeseries.data(useIdx,:)./delta;
data = data*scale;

% Plot things.
hold on;
for i = 1:size(data,2)
  offset = size(data,2) - (i -1);
  plotOut(i) = plot(xvals(useIdx),data(:,i)+offset,'k',...
                      'ButtonDownFcn',get(ax,'ButtonDownFcn'));
 % set(ax,'ButtonDownFcn',get(plotOut(i),'ButtonDownFcn'));
end;

axis([xvals(1) xvals(end) 0 size(data,2) + 1]);

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

