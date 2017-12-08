function nrrdView = threeview(nrrdObj,varargin)
% THREEVIEW - crlEEG.fileio.NRRD Viewer with Three Viewing Windows
%
% function nrrdView = threeview(nrrdObj,varargin)
%
% Should probably be ported over to be a handle object, so things stay nice
% and consistent when used in larger viewers
%

p = inputParser;
p.addOptional('nrrdOverlay',[],@(x)isa(x,'crlEEG.fileio.NRRD')||isa(x,'function_handle'));
p.addParamValue('parent',[],@(h) ishandle(h))
p.addParamValue('origin',[0 0],@(x) isvector(x) && numel(x)==2);
p.addParamValue('size',[530 530]);
p.addParamValue('cmap',[]);
p.addParamValue('disptype',[]);
p.addParamValue('overalpha',0.5);
parse(p,varargin{:});

% Parse Inputs
parentH     = p.Results.parent;
origin      = p.Results.origin;
imageSize   = nrrdObj.sizes(nrrdObj.domainDims);
nrrdOverlay = p.Results.nrrdOverlay;

% If no parent provided, open a new figure
if isempty(parentH)
  parentH = figure;
  origin = [ 0 0 ];
end;


viewSize = {[397.5 475] [397.5 475] 0.75*[530 700]};
origins = {[5 5] [5 viewSize{2}(2)+5] [viewSize{3}(1)+5 viewSize{3}(2)-95]};

panel = uitools.cnlUIObj('Parent',parentH,'size',[805 975]);

for idx = 1:3
  viewer{idx} = uitools.cnlImageViewer(imageSize,'Parent',panel.panel,...
    'origin',origins{idx},'size',viewSize{idx});
  viewer{idx}.title = nrrdObj.fname;
  viewer{idx}.fhnd_getImgSlice = @(a,b)nrrdObj.getSlice('axis',a,'slice',b);
  viewer{idx}.sliceImg.imgRange = ...
    @()nrrdObj.getImageRange(viewer{idx}.colorControl.currType);
  viewer{idx}.sliceControl.selectedAxis = idx;
  viewer{idx}.sliceImg.fhnd_linkedUpdate = @()updateAll;
  
  if isa(nrrdOverlay,'crlEEG.fileio.NRRD')
    viewer{idx}.fhnd_getOverlaySlice = ...
      @(a,b)nrrdOverlay.getSlice('axis',a,'slice',b);
    viewer{idx}.sliceImg.overlayRange = ...
      @()nrrdOverlay.getImageRange(viewer{idx}.overlayColor.currType);
  elseif isa(nrrdOverlay,'function_handle')
    error('Functionality not yet implemented');
  end;
end;

set(panel.parent,'units','pixels');
currPos = get(panel.parent,'position');
set(panel.parent,'position',[currPos(1) currPos(2) 815 985]);

% Make color and overlay color controls invisible for viewers 1 and 2
viewer{1}.colorControl.visible = 'off';
viewer{2}.colorControl.visible = 'off';
viewer{1}.overlayColor.visible = 'off';
viewer{2}.overlayColor.visible = 'off';
viewer{1}.sliceImg.imgCMap = @()viewer{3}.colorControl.currCMap;
viewer{2}.sliceImg.imgCMap = @()viewer{3}.colorControl.currCMap;
viewer{1}.sliceImg.imgType = @()viewer{3}.colorControl.currType;
viewer{2}.sliceImg.imgType = @()viewer{3}.colorControl.currType;
viewer{1}.sliceImg.overlayMap = @()viewer{3}.overlayColor.currCMap;
viewer{2}.sliceImg.overlayMap = @()viewer{3}.overlayColor.currCMap;
viewer{1}.sliceImg.overlayType = @()viewer{3}.overlayColor.currType;
viewer{2}.sliceImg.overlayType = @()viewer{3}.overlayColor.currType;

viewer{3}.colorControl.updatefunction = @()updateAll;
viewer{3}.overlayColor.updatefunction = @()updateAll;

% sliceImg{1}.setCross(@()sliceImg{2}.currSlice,@()sliceImg{3}.currSlice);
% sliceImg{2}.setCross(@()sliceImg{1}.currSlice,@()sliceImg{3}.currSlice);
% sliceImg{3}.setCross(@()sliceImg{1}.currSlice,@()sliceImg{2}.currSlice);
%viewer{1}.sliceImg.setCross(@()viewer{2}.sliceImg.currSlice,@()viewer{3}.sliceImg.currSlice);
%viewer{2}.sliceImg.setCross(@()viewer{1}.sliceImg.currSlice,@()viewer{3}.sliceImg.currSlice);
%viewer{3}.sliceImg.setCross(@()viewer{1}.sliceImg.currSlice,@()viewer{2}.sliceImg.currSlice);



% Update UI Locations For Each Viewer.
viewer{1}.setUILocations;
viewer{2}.setUILocations;
viewer{3}.setUILocations;

%panel.units = 'normalized';
%panel.position = [0.01 0.01 0.98 0.98];


% Set each viewer to a different default axis.
% viewer{1}.sliceControl.selectedAxis = 1;
% viewer{2}.sliceControl.selectedAxis = 2;
% viewer{3}.sliceControl.selectedAxis = 3;


nrrdView.viewer = viewer;
nrrdView.panel = panel;

%   imgsize = [300 300];
%   ctrlsize = [300 40];
%
%   origins = {[ 0 0 ] [ 0 imgsize(2)+10+ctrlsize(2) ] ...
%     [imgsize(1)+10 imgsize(2)+10+ctrlsize(2)]};
%
%   colorcontrol = uitools.cnlColorControl('parent',gcf,...
%     'origin',[imgsize(1)+15 origins{2}(2)-75],'title','Primary Image Color Control');
%   colorcontrol.updatefunction = @updateAll;
%
%   if ~isempty(nrrdOverlay)
%     color2 = uitools.cnlColorControl('parent',figureH,...
%       'origin',[imgsize(1) + 15 origins{2}(2) - 160]);
%     color2.updatefunction = @updateAll;
%     set(color2.panel,'title','Overlay Image');
%
%     alpha = uitools.cnlSliderPanel([0 1],'parent',figureH,...
%       'origin',[imgsize(1)+15 origins{2}(2) - 225]);
%     set(alpha.panel,'title','Overlay Alpha');
%     alpha.updatefunction = @(x)updateAlpha(x);
%     if isempty(p.Results.overalpha)
%       alpha.selectedValue = 0.5;
%     else
%       alpha.selectedValue = p.Results.overalpha;
%       set(alpha.panel,'Visible','off');
%     end
%   end;
%
%   for idx = 1:3
%     %nrrdView{idx} = nrrdObj.view('figure',figureH,'origin',origins{idx},'size',[300 300]);
%
%     if ~isempty(nrrdOverlay)
%       sliceImg{idx} = uitools.cnlSliceView_withOverlay('parent',figureH,...
%         'title',nrrdObj.fname,...
%         'origin',origins{idx} + [5 ctrlsize(2)+15],'size',imgsize);
%     else
%       sliceImg{idx} = uitools.cnlSliceView('parent',figureH,...
%         'title',nrrdObj.fname,...
%         'origin',origins{idx} + [5 ctrlsize(2)+15],'size',imgsize);
%     end;
%
%     sliceImg{idx}.fhnd_getSlice = ...
%       @(a,b)nrrdObj.getSlice_RGB('axis',a,'slice',b,...
%       'type',colorcontrol.currType,'cmap',colorcontrol.currCMap);
%
%     if ~isempty(nrrdOverlay)
%       if isa(nrrdOverlay,'crlEEG.fileio.NRRD');
%       sliceImg{idx}.fhnd_getOverlaySlice = ...
%         @(a,b)nrrdOverlay.getSlice_RGB('axis',a,'slice',b,...
%         'type',color2.currType,'cmap',color2.currCMap);
%       elseif isa(nrrdOverlay,'function_handle');
%         sliceImg{idx} = f
%       end
%     end
%
%     % Set things so that when one image updates, they all update
%     sliceImg{idx}.fhnd_linkedUpdate = @()updateAll;
%
%     slicecontrol{idx} = uitools.cnlSliceControl(nrrdObj.sizes,'parent',gcf,...
%       'origin',origins{idx}+[5 10]);
%     slicecontrol{idx}.size = ctrlsize;
%     slicecontrol{idx}.updatefunction = @(a,b)sliceImg{idx}.updateSelections(a,b);
%
%   end;
%
% sliceImg{1}.setCross(@()sliceImg{2}.currSlice,@()sliceImg{3}.currSlice);
% sliceImg{2}.setCross(@()sliceImg{1}.currSlice,@()sliceImg{3}.currSlice);
% sliceImg{3}.setCross(@()sliceImg{1}.currSlice,@()sliceImg{2}.currSlice);
%
%   tmp = get(figureH,'Position');
%   set(figureH,'Position',[tmp(1:2) 2*imgsize(1)+20 2*imgsize(2)+2*ctrlsize(2)+30]);
%
%   for idx = 1:3
%     sliceImg{idx}.normalized = true;
%     slicecontrol{idx}.normalized = true;
%   end;
%   colorcontrol.normalized = true;
%   if exist('color2','var')
%     color2.normalized = true;
%     alpha.normalized = true;
%   end
%
%   nrrdView.sliceImg = sliceImg;
%   nrrdView.slicecontrol = slicecontrol;
%   nrrdView.colorcontrol = colorcontrol;
%   if exist('color2','var')
%     nrrdView.overlaycolor = color2;
%     nrrdView.alphacontrol = alpha;
%   end;

  function updateAlpha(val)
    for idx = 1:3
      viewer{idx}.sliceImg.alphaOverlay = val;
    end;
  end

  function updateAll
    
    % Clear current axis indicator lines
    for idx = 1:3
      viewer{idx}.sliceImg.crossX = [];
      viewer{idx}.sliceImg.crossY = [];
      viewer{idx}.sliceImg.crossSlices = [];
    end;
    
    for idx = 1:3
      % Get current axis for the image to be updated
      
      vLines = [];
      hLines = [];
      
      % Loop across other images
      %
      % Note that the settings for adding horizontal and vertical lines is
      % very dependent upon the particular way in which the images are
      % visualized.  As of April 3, 2015, this appears to work properly,
      % but may fail if things are changed too much.
      for idx2 = setdiff(1:3,idx)
        currAxis = viewer{idx2}.sliceImg.currAxis;
        currSlice = viewer{idx2}.sliceImg.currSlice;
        switch viewer{idx}.sliceImg.currAxis;
          case 1,
            if     currAxis==2,
              vLines = [vLines currSlice];
            elseif currAxis==3,
              hLines = [hLines viewer{idx}.sliceImg.axes.YLim(2)-currSlice];
            end;
          case 2,
            if     currAxis==1,
              vLines = [vLines currSlice];
            elseif currAxis==3,
              hLines = [hLines viewer{idx}.sliceImg.axes.YLim(2)-currSlice];
            end;
          case 3,
            if     currAxis==1,
              vLines = [vLines currSlice];
            elseif currAxis==2,
              hLines = [hLines currSlice];
            end;
        end
      end;
      
      viewer{idx}.sliceImg.setCross(vLines,hLines);
      
      viewer{idx}.sliceImg.updateImage;
      % Determine what lines need to be drawn
    end
    
    %     for idx = 1:3
    %       % Update the images for each plot.  This automatically invokes
    %       % updateImage, so the call below will become redundant.
    %       sliceImg{idx}.updateImage;
    %     end
  end

end


