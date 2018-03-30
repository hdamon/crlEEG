function plotWithDecomposition(eegIn,varargin)
%% Plot a crlEEG.type.EEG object alongside an associated decomposition
%
%

%% Input Parsing
p = inputParser;
p.KeepUnmatched = true;
p.addParameter('Parent',[]);
p.addParameter('decompType','eeglab');
p.addParameter('marks',[]);
p.addParameter('imgRange',[0 0.07]);
p.addParameter('showChan',1);
p.addParameter('logImg',false);
parse(p,varargin{:});

% Open a new figure if one is not provided
if isempty(p.Results.Parent)
  parent = figure;
else
  parent = p.Results.Parent;
end;

% 
marks = p.Results.marks;

% Raise the appropriate figure, clear it, and move it into position/
f1 = figure(parent); clf;
f1.Position = [10 10 2550 950];

% Set up a 
p1 = uipanel('Parent',f1);
p1.Position = [0.001 0.5 0.999 0.499];
ax = axes('Parent',p1);

% Get the appropriate decomposition and display it.
tmp = eegIn.decomposition.(p.Results.decompType)(:,:,p.Results.showChan);
tmp.imagesc('parent',f1,'logImg',p.Results.logImg);

set(gca,'YDir','normal'); colormap('jet');
a = gca;
%a.Position = [0.01 0.05 0.98 0.9];
a.Position = [0.025 0.05 0.965 0.9];

if ~isempty(marks)
a.Title.String = ['Onset: ' num2str(marks.startOffset(i)/1000) 's  Duration:' num2str(marks.durations(i)) 's'];
end;
drawnow;
%f2 = figure(2); clf;
p2 = eegIn.plot('Parent',f1,'units','normalized','position',[0.001 0.001 0.999 0.499]);
%f2.Position = [ 8 35 2550 425];
%p2.Position = [0.001 0.001 0.999 0.499];

if ~isempty(marks)
a = p2.toggleplot.axes;
axes(a);
xVal = marks.startOffset/1000;
plot([xVal(:) xVal(:)],a.YLim,'r','linewidth',2);
xVal =(marks.startOffset+marks.durations*1000)/1000;
plot([xVal(:) xVal(:)],a.YLim,'r','linewidth',2);
end;

end