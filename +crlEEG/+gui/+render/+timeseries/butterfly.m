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
p.addRequired('timeseries',@(x) isa(x,'crlEEG.gui.data.timeseries'));
p.addOptional('ax',[],@(x) ishghandle(x)&&strcmpi(get(x,'type'),'axes'));
p.addParamValue('yrange',timeseries.yrange,@(x) isvector(x)&&(numel(x)==2));
p.parse(timeseries,varargin{:});

ax = p.Results.ax;
xvals = timeseries.xvals;
yrange = p.Results.yrange;

if isempty(xvals), xvals = 1:size(timeseries,1); end;
if isempty(ax), figure; ax = axes; end;
axes(ax);

if numel(xvals)==1, plotOpts = 'kx';
else                plotOpts = 'k';  end;

plotOut = plot(xvals,timeseries.data,plotOpts,'ButtonDownFcn',get(ax,'ButtonDownFcn'));
set(ax,'ButtonDownFcn',get(plotOut(1),'ButtonDownFcn'));

XLim = [xvals(1) xvals(end)];
if XLim(1)==XLim(2), XLim = XLim + [-0.1 0.1]; end;

YLim = max(abs(yrange));

axis([XLim(1) XLim(2) -YLim YLim]);

ticks = linspace(0,YLim,6);
ticks = [-flipdim(ticks(2:end),2) ticks];
labels = 10^(-2)*round(ticks*10^2);
set(ax,'YTick',ticks);
set(ax,'YTickLabel',labels);

end

