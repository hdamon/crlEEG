function plotOut = butterfly(timeseries,varargin)
% Butterfly timeseries plot
%
% plotOut = BUTTERFLY(timeseries,varargin)
%
% Required Inputs:
%   timeseries :  Nsamples x Nchannels Data Matrix
% 
% Optional Inputs:
%   'ax'     : Handle to a matlab axis to display in
%   'xvals'  : Values to display along X-Axis
%   'yrange' : Range to use for Y-Axis
%
% This object exists mostly to maintain a consistent structure across the
% entire uitools package. It additionally ensures that the resulting plot
% and axes keep the same button down function that the axis had prior to
% doing the plot.
%
% Written By: Damon Hyde
% Last Edited: May 24, 2016
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
xvals = timeseries.xvals;
yrange = p.Results.yrange;

%% Shift to appropriate axes, or open a new one.
if isempty(ax), figure; ax = axes; end;
axes(ax);

% If plotting a single timepoint, use X's.
if numel(xvals)==1, plotOpts = 'kx';
else                plotOpts = 'k';  end;

%% For long time series, only render a subset of timepoints      
if ( size(timeseries,1) > 10000 )&&~p.Results.plotAll
  useIdx = round(linspace(1,size(timeseries,1),10000));
  useIdx = unique(useIdx);
else
  useIdx = ':';
end;

%% Plot!
%plotOut = plot(xvals,timeseries.data,plotOpts);
plotOut = plot(xvals(useIdx),timeseries.data(useIdx,:),plotOpts,'ButtonDownFcn',get(ax,'ButtonDownFcn'));
%set(ax,'ButtonDownFcn',get(plotOut(1),'ButtonDownFcn'));

% Modify X Limits is plotting a single timepoint.
XLim = [xvals(1) xvals(end)];
if XLim(1)==XLim(2), XLim = XLim + [-0.1 0.1]; end;

% Make the y limits symmetric.
YLim = max(abs(yrange));
if YLim(1)==0, YLim = 0.1; end;
YLim = YLim./p.Results.scale;

axis([XLim(1) XLim(2) -YLim YLim]);

% Set Yticks.
ticks = linspace(0,YLim,6);
ticks = [-flipdim(ticks(2:end),2) ticks];
set(ax,'YTick',ticks);

e = log10(ticks(end));
e = sign(e)*floor(abs(e));
yt = ticks/10^e;

labels = cell(size(yt));
for i = 1:numel(yt)
  labels{i} = sprintf('%1.2f',yt(i));
end

set(ax,'YTickLabel',labels);

text(XLim(1),YLim(1)*0.95,sprintf('\\times 10^{%d}',e));

end

