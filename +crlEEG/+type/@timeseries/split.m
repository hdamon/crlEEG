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
%   'chandisp' :
%   'timedisp' :
%   'sampdisp' :
%   'scale'    : Scaling factor
%   'labels'   : Labels for each channel
%   'plotAll'  : Flag to force plotting of all timepoints. When set to 
%                 false, sequences with more than 10k points will be 
%                 subsampled to improve plotting speed.
%
% Written By: Damon Hyde
% Last Edited; May 24, 2016
% Part of the cnlEEG Project
%

import crlEEG.util.validation.isNumericVector

%% Input Parsing
p = inputParser;
p.addRequired('tseries',@(x) isa(x,'crlEEG.type.timeseries'));
p.addOptional('ax',[],@(x) ishghandle(x)&&strcmpi(get(x,'type'),'axes'));
p.addParamValue('xrange',tseries.xrange,@(x) isNumericVector(x,2));
p.addParamValue('yrange',tseries.yrange,@(x) isNumericVector(x,2));
p.addParamValue('chandisp',[],@(x) isNumericVector(x));
p.addParamValue('timedisp',[],@(x) isNumericVector(x,2));
p.addParamValue('sampdisp',[],@(x) isNumericVector(x,2));
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

if ~isempty(p.Results.timedisp)
  error('Not yet implemented');
end;

% Get the range of samples to display
if ~isempty(p.Results.sampdisp)
  sampRange = p.Results.sampdisp;
else
  % Default to displaying everything
  sampRange = [1 size(tseries,1)];
end;

if ~isempty(p.Results.chandisp)
  chanDisp = p.Results.chandisp;
else
  chanDisp = ':';
end;

%% For long time series, only render a subset of timepoints      
useIdx = round(linspace(sampRange(1),sampRange(2),10000));
useIdx = unique(useIdx);

xvals = xvals(useIdx);
xrange = [xvals(1) xvals(end)];
labels = labels(chanDisp);

% Get data range and scale
%delta = yrange(2)-yrange(1);
delta = max(abs(yrange));

dataChan = tseries.isChannelType('data');
dataChan = dataChan(chanDisp);
data = tseries.getPlotData;
data = data(useIdx,chanDisp);
data(:,dataChan) = scale * ( data(:,dataChan)./delta );
data(:,~dataChan) = data(:,~dataChan)./delta;

% Plot things.
hold on;
for i = 1:size(data,2)
  offset = size(data,2) - (i -1);
  ax.NextPlot = 'add';
  color = 'k'; % Default to black
  if ~dataChan(i)
    color = 'b';  
  end;
  plotOut(i) = plot(xvals,data(:,i)+offset,color,...
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

