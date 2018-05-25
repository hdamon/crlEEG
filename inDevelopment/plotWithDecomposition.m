function pOut = plotWithDecomposition(eegIn,varargin)

p = inputParser;
p.KeepUnmatched = true;
p.addParameter('Parent',[]);
p.addParameter('decompType','eeglab');
p.addParameter('marks',[]);
p.addParameter('imgRange',[]);
p.addParameter('showChan',1);
p.addParameter('showBand',[]);
p.addParameter('showTimes',[]);
p.addParameter('position',[10 10 2550 950]);
p.addParameter('cmap',crlEEG.gui.widget.alphacolor);
p.addParameter('logImg',false);
parse(p,varargin{:});

if isempty(p.Results.Parent)
  parent = figure;
else
  parent = p.Results.Parent;
end;

marks = p.Results.marks;

f1 = figure(parent); clf;
f1.Position = p.Results.position;

showChan = p.Results.showChan;
if ~iscell(showChan), showChan = {showChan}; end;
nChan = numel(showChan);
if nChan==0, showChan = {[]}; nChan = 1; end;

unitHeight = 1/(nChan+1);
cmap = p.Results.cmap;
for i = 1:nChan
  p1(i) = crlEEG.gui.timeFrequencyDecomposition.showTF(...
    eegIn.decomposition.(p.Results.decompType),...
    'Parent',f1,...
    'showBand',p.Results.showBand, ...
    'showTimes',p.Results.showTimes,...
    'showChan',showChan{i},...
    'colormap',cmap,...
    'logImg',p.Results.logImg,...
    'range',p.Results.imgRange,...
    'units','normalized',...
    'position',[0.001 (nChan-i+1)*unitHeight 0.999 0.999*unitHeight]);
  %p1(i).Units = 'normalized';
  %p1(i).Position = [0.001 i*unitHeight 0.999 0.999*unitHeight];
end;


% Times = ':'; nRows = 400;
% %img = imagesc(winCenters{i}(Times)/1000,fx{i}(1:nRows),(pxx{i}(1:nRows,Times)),[0 2e-9]);
% tmp = eegIn.decomposition.(p.Results.decompType);
% tmp.imagesc('parent',f1,...
%   'showBand',p.Results.showBand, 'showTimes',p.Results.showTimes,...
% 'showChan',p.Results.showChan,'logImg',p.Results.logImg,'range',p.Results.imgRange);
% %img = imagesc(tmp.tx,tmp.fx,abs(tmp.tfX(:,:,1)),p.Results.imgRange);
%
% blargh = uicontrol('Style','popup',...
%                    'String',tmp.labels,...
%                    'Parent', p1,...
%                    'Units','normalized',...
%                    'Position',[0.01 0.01 0.15 0.1],...
%                    'Callback',@(h,evt) updateDecomp);
%
% set(gca,'YDir','normal'); colormap('jet');
% a = gca;
% %a.Position = [0.01 0.05 0.98 0.9];
% a.Position = [0.025 0.05 0.965 0.9];
%
% if ~isempty(marks)
% a.Title.String = ['Onset: ' num2str(marks.startOffset(i)/1000) 's  Duration:' num2str(marks.durations(i)) 's'];
% end;
drawnow;
%f2 = figure(2); clf;
tmpEEG = eegIn.copy;
tmpEEG.decomposition = [];
p2 = tmpEEG.plot('Parent',f1,'units','normalized','position',[0.001 0.001*unitHeight 0.999 0.999*unitHeight]);
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


foo = addlistener(p2.toggleplot,'updatedOut',@(h,evt) updateDecomp);

pOut.p_tf = p1;
pOut.p_eeg = p2;

  function updateDecomp
    for k = 1:numel(p1)
      p1(k).showTimes = p2.toggleplot.xrange;
    end;
    
    
    %axes(ax);
    
    %tmp.imagesc('parent',f1,...
    % 'showBand',p.Results.showBand, 'showTimes',p2.toggleplot.xrange,...
    % 'showChan',blargh.String{blargh.Value},'logImg',p.Results.logImg,'range',p.Results.imgRange);
    %set(ax,'YDir','normal'); colormap('jet');
  end

end