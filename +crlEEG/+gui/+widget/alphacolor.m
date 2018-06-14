classdef alphacolor < handle
  % ALPHACOLOR : Colormap with Alpha Values and Interactive GUI
  %
  % ALPHACOLOR is a handle class object that allows the user to easily
  % select between a range of colormaps, and adjust both the range and
  % transparency of the colormap
  %
  % Uitools class for colormaps including an alpha value.
  %
  % Optional Param-Value Inputs
  % ---------------------------
  %   'type' : Colormap type. DEFAULT: 'jet'
  %  'range' : Range of colormap
  %   'cmap' : Manually defined clormap
  %  'alpha' : Colormap alpha level: Default: 1
  %  'depth' : Colormap Depth. DEFAULT: 265
  %  'interptype' : Alpha level interpolation type
  %
  % Written By: Damon Hyde
  % Last Edited: June 21, 2016
  % Part of the cnlEEG Project
  %
  
  properties
    type
    range
    interptype
  end
  
  properties (Dependent=true)
    cmap
    alpha
  end
  
  properties (Dependent=true,Hidden = true)
    depth; % # of values in the colormap
  end
  
  properties (Access=protected)
    gui
    storedVals
  end
  
  events
    updatedOut
  end
  
  methods
    
    %% Object Constructor
    function obj = alphacolor(varargin)
      
      p = inputParser;
      p.addParamValue('type','jet');
      p.addParamValue('range',[0 1]);
      p.addParamValue('cmap',[]);
      p.addParamValue('alpha',1);
      p.addParamValue('depth',256);
      p.addParamValue('interptype','linear');
      p.parse(varargin{:});
      
      assert(isempty(p.Results.cmap)||ismember('type',p.UsingDefaults),...
        'Cannot define both a type and a custom map');
      
      assert(ismember(numel(p.Results.alpha),[1 p.Results.depth]),...
        'Alpha must be a single scalar or have length equal to the depth of the colormap');
      
      obj.range = [-inf inf];
      if isempty(p.Results.cmap)
        obj.type  = p.Results.type;
        obj.depth = p.Results.depth;
      else
        obj.cmap = p.Results.cmap;
      end;
      obj.interptype = p.Results.interptype;
      obj.range = p.Results.range;
      obj.alpha = p.Results.alpha;
      
    end
    
    %% Dependent Property GET/SET Methods
    
    %% COLORMAP TYPE
    function set.type(obj,val)
      if isequal(val,'custom')&&...
          (~isfield(obj.storedVals,'cmap')||isempty(obj.storedVals.cmap)),
        obj.updateGUI; % This just refuses to set the custom type unless a
        % custom colormap has already been assigned.
        %obj.cmap = obj.cmap; % This makes the last selected colormap the
        %custom one
        return;
      end;
      
      if ~isequal(obj.type,val)
        obj.type = val;
        obj.updateGUI;
        notify(obj,'updatedOut');
      end;
    end;
    
    
    %% RANGE
    function set.range(obj,val)
      assert(isempty(val)||isnumeric(val)&&(numel(val)==2),...
        'Range must be a length 2 numeric vector');
      if isempty(val), val = [0 1]; end;
      if ~isequal(obj.range,val)
        obj.range = val;
        obj.updateGUI;
        notify(obj,'updatedOut');
      end;
    end;
    
    function set.interptype(obj,val)
      if isequal(val,'cubic'), val = 'pchip'; end;
      if ~isequal(obj.interptype,val)
        obj.interptype = val;
        obj.updateGUI;
        notify(obj,'updatedOut');
      end;
    end;
    
    %% COLORMAP VALUE
    function out = get.cmap(obj)
      switch obj.type
        case 'custom'
          out = obj.storedVals.cmap;
        case 'redblue'
          out = crlEEG.gui.util.redblue(obj.depth);
        otherwise
          out = feval(obj.type,obj.depth);
      end
    end;
    
    function set.cmap(obj,val)
      % Only gets called when directly setting the color map. Usually the
      % colormap will be selected from the defaults using obj.type.
      %
      assert(ismatrix(val)&&(size(val,2)==3),...
        'Invalid colormap');
      
      if ~isequal(obj.storedVals.cmap,val)
        obj.storedVals.cmap = val;
        obj.depth = size(val,1);
        obj.type = 'custom';  % This will notify the updatedOut event
        obj.updateGUI;
      end;
    end
    
    %% COLORMAP DEPTH
    function out = get.depth(obj)
      if isfield(obj.storedVals,'depth')
        out = obj.storedVals.depth;
      else
        out = [];
      end;
    end;
    
    function set.depth(obj,val)
      
      if ~isequal(obj.depth,val)
        if isfield(obj.storedVals,'alpha')&&~isempty(obj.storedVals.alpha)
          currAlpha = obj.storedVals.alpha;
          currDepth = obj.depth;
          scale = (val-1)/(currDepth-1);
          newPts = round(scale*(currAlpha(:,1)-1))+1;
          newAlpha = [newPts(:) currAlpha(:,2)];
          [~,iA] = unique(newAlpha(:,1));
          newAlpha = newAlpha(iA,:);
          obj.storedVals.alpha = newAlpha;
        end
        
        obj.storedVals.depth = val;
        obj.updateGUI;
        notify(obj,'updatedOut');
      end;
    end
    
    %% SET AND GET METHODS FOR COLORMAP ALPHA VALUES
    
    function set.alpha(obj,val)
      
      %% Input Checking
      isPts = ismatrix(val)&&~isscalar(val)&&(size(val,2)==2);
      assert(isPts||ismember(numel(val),[1 obj.depth]),...
        'Alpha must be a single scalar or have length equal to the depth of the colormap');
      
      if isPts
        foundFirst = (sum(val(:,1)==1)==1);
        foundLast  = (sum(val(:,1)==obj.depth)==1);
        
        assert(foundFirst&&foundLast,...
          ['When providing points for interpolation, points must ' ...
          'be present for the first and last values']);
        
        val(:,1) = round(val(:,1));
        assert(all(val(:,1)>0)&&all(val(:,1)<=obj.depth),...
          'Colormap index values out of range');
      end;
      
      if numel(val)==1
        %obj.storedVals.alpha = val*ones(obj.depth,1);
        obj.storedVals.alpha = [1 val ; obj.depth val];
      elseif numel(val)==obj.depth
        obj.storedVals.alpha = [(1:obj.depth)' val(:)];
      else
        obj.storedVals.alpha = val;
      end
      obj.updateGUI;
      notify(obj,'updatedOut');
    end
    
    function alphaOut = get.alpha(obj)
      % Compute the full alpha map from the provided points and
      % interpolation type using interp1()
      %
      ptsIn = obj.storedVals.alpha;
      
      alphaOut = interp1(ptsIn(:,1),ptsIn(:,2),1:obj.depth,obj.interptype);
    end
    
    
    function varargout = edit(obj,varargin)
      if ~isempty(obj.gui)&&ishghandle(obj.gui)
        % If there's a valid gui associated with it, just raise that
        % figure.
        figure(ancestor(obj.gui,'figure'));
      else
        % Open a new GUI
        obj.makeGUI(varargin{:});
      end
      
      if nargout>0
        varargout{1} = obj.gui;
      end;
    end
    
    function [rgb,varargout] = img2rgb(obj,img)
      % Convert the values in img to RGB values, using the alphacolor map.
      %
      % rgb = obj.img2rgb(img)
      % [rgb, alpha] = obj.img2rgb(img)
      %
      
      assert(isnumeric(img),'Input image must be numeric');
      
      imgSize = size(img);
      img = img(:);
      
      Qnan = isnan(img);
      Qinf = isinf(img);
      infSign = sign(img(Qinf));
      posInf = infSign==1;
      negInf = infSign==-1;
      
      
      range = obj.range;
      if ( range(1)==-inf ), range(1) = min(img(isfinite(img))); end;
      if ( range(2)== inf ), range(2) = max(img(isfinite(img))); end;
      
      
      if range(2)>range(1)
        idx = round(1+obj.depth*(img-range(1))/(range(2)-range(1)));
      else
        idx = ones(size(img));
      end;
      
      % Set values for NaN/Inf/-Inf
      idx(Qnan) = 1;
      idx(Qinf(posInf)) = obj.depth;
      idx(Qinf(negInf)) = 1;
      
      idx(idx<1) = 1;
      idx(idx>obj.depth) = obj.depth;
      
      rgb = ind2rgb(idx,obj.cmap);
      rgb = reshape(rgb,[imgSize 3]);
      
      if nargout>=2
        alpha = obj.alpha(idx);
        alpha = reshape(alpha,[imgSize]);
        
        varargout{1} = alpha;
      end;
      
    end
    
    
    %% Create Colormap GUI
    function guiObj = makeGUI(obj,varargin)
      
      p = inputParser;
      p.addParamValue('parent',[]);
      p.addParamValue('origin',[0 0],@(x) isvector(x)&numel(x)==2);
      p.addParamValue('size',[400 400]);
      p.addParamValue('name','');
      p.addParamValue('units','pixels');
      p.parse(varargin{:});
      
      if isempty(p.Results.parent)
        % Open a new figure and set it to the appropriate size.
        parent = figure;
        currPos = get(parent,'Position');
        currPos(3:4) = [420 420];
        set(parent,'Position',currPos);
      else
        parent = p.Results.parent;
      end;
      
      guiObj = uipanel(...
        'Parent',parent,...
        'Units','pixels',...
        'Position',[10 10 400 400],...
        'title',['ColorMap Editor:' p.Results.name]);
      
      %% Set up the Axes to Display the Colormap In
      cMapAxes = axes(...
        'Parent',guiObj,...
        'Units','normalized',...
        'Position',[0.03 0.6 0.94 0.37],...
        'ButtonDownFcn',@(h,evt) obj.selectAlpha);
      setappdata(guiObj,'cMapAxes',cMapAxes);
      
      %% Set up the Radio Button Group for Colormap Selection
      %
      radioGroup  = uibuttongroup(...
        'Parent',guiObj,...
        'Units','normalized',...
        'Position',[0.03 0.03 0.3 0.54],...
        'SelectionChangeFcn',@(h,evt)obj.updateColormapFromGUI);
      cmaps = crlEEG.gui.widget.alphacolor.colorMapList;
      cmaps(end+1).name = 'custom';
      setappdata(guiObj,'radioGroup',radioGroup);
      
      for i = 1:numel(cmaps)
        radioButtons(i) = uicontrol(radioGroup,...
          'Style','radiobutton',...
          'String',cmaps(i).name,...
          'Units','normalized',...
          'Position',[0.01 1-0.1*i 0.98 0.1]);
        if strcmpi(cmaps(i).name,obj.type)
          set(radioGroup,'SelectedObject',radioButtons(i));
        end;
      end
      setappdata(guiObj,'radioButtons',radioButtons);
      set(radioGroup,'Visible','on');
      
      %% Location Offsets for All the other buttons
      baseXLoc = 0.35;
      baseYLoc = 0.5;
      offsetY = 0.07;
      sizeY = 0.06;
      
      orderAlpha05 = 5;
      orderRange = 0 ;
      orderZeroTransp = 1;
      orderTransparent = 2;
      orderOpaque = 3;
      orderSymmetric = 4;
      orderInterp = 6;
      orderShift = 7;
      
      buttons(1) = uicontrol(...
        'Parent',guiObj,...
        'Style','pushbutton',...
        'String','Set Alpha = 0.5',...
        'Units','normalized',...
        'Position',[baseXLoc baseYLoc-orderAlpha05*offsetY 0.63 sizeY],...
        'Callback',@(h,evt) obj.resetAlpha);
      setappdata(guiObj,'buttons',buttons);
      
      cMapRange(1) = uicontrol(...
        'Parent', guiObj,...
        'Style','Text',...
        'String','Range:',...
        'Units','normalized',...
        'Position',[baseXLoc baseYLoc-orderRange*offsetY 0.2 sizeY]);
      
      cMapRange(2) = uicontrol(...
        'Parent',guiObj,...
        'Style','edit',...
        'Units','normalized',...
        'Position',[baseXLoc+0.2 baseYLoc-orderRange*offsetY 0.2 sizeY],...
        'Callback',@(h,evt) obj.updateColormapFromGUI);
      
      cMapRange(3) = uicontrol(...
        'Parent',guiObj,...
        'Style','edit',...
        'Units','normalized',...
        'Position',[baseXLoc+0.43 baseYLoc-orderRange*offsetY 0.2 sizeY],...
        'Callback',@(h,evt) obj.updateColormapFromGUI);
      setappdata(guiObj,'cMapRange',cMapRange);
      
      interpType(1) = uicontrol(...
        'Parent',guiObj,...
        'Style','text',...
        'Units','normalized',...
        'Position',[baseXLoc baseYLoc-orderInterp*offsetY 0.25 sizeY],...
        'String','InterpType:');
      
      interpType(2) = uicontrol(...
        'Parent', guiObj,...
        'Style','popupmenu',...
        'Units','normalized',...
        'Position',[baseXLoc+0.27 baseYLoc-orderInterp*offsetY 0.33 sizeY],...
        'String',{'linear','nearest','spline','cubic'},...
        'Callback',@(h,evt) obj.updateColormapFromGUI);
      setappdata(guiObj,'interpType',interpType);
      
      zerozero = uicontrol(...
        'Parent',guiObj,...
        'Style','pushbutton',...
        'String','Make Zero Transparent',...
        'Units','normalized',...
        'Position',[baseXLoc baseYLoc-orderZeroTransp*offsetY 0.63 sizeY],...
        'Callback',@(h,evt) obj.transparentZero);
      setappdata(guiObj,'zerozero',zerozero);
      
      transparent = uicontrol(...
        'Parent',guiObj,...
        'Style','pushbutton',...
        'String','Make Transparent',...
        'Units','normalized',...
        'Position',[baseXLoc baseYLoc-orderTransparent*offsetY 0.63 sizeY],...
        'Callback',@(h,evt) obj.makeTransparent);
      setappdata(guiObj,'transparent',transparent);
      
      opaque = uicontrol(...
        'Parent',guiObj,...
        'Style','pushbutton',...
        'String','Make Opaque',...
        'Units','normalized',...
        'Position',[baseXLoc baseYLoc-orderOpaque*offsetY 0.63 sizeY],...
        'Callback',@(h,evt) obj.makeOpaque);
      setappdata(guiObj,'opaque',opaque);
      
      shift(1) = uicontrol(...
        'Parent',guiObj,...
        'Style','pushbutton',...
        'String','Shift -',...
        'Units','normalized',...
        'Position',[baseXLoc baseYLoc-orderShift*offsetY 0.3 sizeY],...
        'Callback',@(h,evt) obj.shiftTransp(-0.05));
      
      shift(2) = uicontrol(...
        'Parent',guiObj,...
        'Style','pushbutton',...
        'String','Shift +',...
        'Units','normalized',...
        'Position',[baseXLoc+0.33 baseYLoc-orderShift*offsetY 0.3 sizeY],...
        'Callback',@(h,evt) obj.shiftTransp(0.05));
      setappdata(guiObj,'shift',shift);
     
      symetric = uicontrol(...
        'Parent',guiObj,...
        'Style','pushbutton',...
        'String','Symmetrize Colormap',...
        'Units','normalized',...
        'Position',[baseXLoc baseYLoc-orderSymmetric*offsetY 0.63 sizeY],...
        'Callback',@(h,evt) obj.makeSymmetric);

      obj.gui = guiObj;
      
      % Update the plot whenever the underlying colormap is modified.
      %  obj.listenTo{end+1} = addlistener(obj,'updatedOut',...
      %    @(h,evt) obj.updatePlot);
      obj.updateGUI;
    end
    %%
    %     function updateInterp(obj)
    %       interpType = getappdata(obj.gui,'interpType');
    %       string = get(interpType(2),'String');
    %       idx = get(interpType(2),'Value');
    %       obj.interptype = string{idx};
    %     end
    %
    %     function updateRange(obj)
    %       range = getappdata(obj.gui,'cMapRange');
    %       obj.range(1) = str2num(get(range(2),'String'));
    %       obj.range(2) = str2num(get(range(3),'String'));
    %     end
    %
    %     function getRangeFromColormap(obj)
    %       range = getappdata(obj.gui,'cMapRange');
    %       set(range(2),'String',num2str(obj.range(1)));
    %       set(range(3),'String',num2str(obj.range(2)));
    %     end;
   
    function makeSymmetric(obj)
      rangeLow = obj.range(1);
      rangeHigh = obj.range(2);

      peak = max([abs(rangeLow) abs(rangeHigh)]);
      obj.range(1) = -peak;
      obj.range(2) = peak;
      obj.updateGUI;
    end;

    function resetAlpha(obj)
      % Reset the colormap alpha to 0.5
      %
      obj.alpha = 0.5;
      obj.updateColormapFromGUI;
    end;
    
    function shiftTransp(obj,val)
      % Shift the overall transparency of the colormap by
      %
      alphaData = obj.storedVals.alpha;
      alphaData(:,2) = alphaData(:,2)+val;
      alphaData(alphaData(:,2)>1,2) = 1;
      alphaData(alphaData(:,2)<0,2) = 0;
      obj.alpha = alphaData;
      obj.updateColormapFromGUI;
    end
    
    function transparentZero(obj)
      alphaData = obj.storedVals.alpha;
      if ~ismember(alphaData(:,1),2)
        alphaData(end+1,:) = [2 alphaData(1,2)];
      else
        alphaData(ismember(alphaData(:,1),2),2) = alphaData(1,2);
      end;
      alphaData(1,2) = 0;
      alphaData = sortrows(alphaData,1);
      obj.alpha = alphaData;
      obj.updateColormapFromGUI;
    end
    
    function makeTransparent(obj)
      alphaData = obj.storedVals.alpha;
      alphaData(:,2) = 0;
      obj.alpha = alphaData;
      obj.updateColormapFromGUI;
    end
    
    function makeOpaque(obj)
      alphaData = obj.storedVals.alpha;
      alphaData(:,2) =  1;
      obj.alpha = alphaData;
      obj.updateColormapFromGUI;
    end
    
    function updateGUI(obj)
      % If a valid GUI object exists, update the GUI to be consistent with
      % the internal state of the alphacolor object.%
      %
      
      if isempty(obj.gui)||~ishghandle(obj.gui), return; end;
      
      adata = getappdata(obj.gui);
      
      % Update the Colormap Type
      cmaps = crlEEG.gui.widget.alphacolor.colorMapList;
      
      radioGroup = getappdata(obj.gui,'radioGroup');
      radioButtons = getappdata(obj.gui,'radioButtons');
      
      for i = 1:numel(cmaps)
        if strcmpi(get(radioButtons(i),'String'),obj.type)
          set(radioGroup,'SelectedObject',radioButtons(i));
        end;
      end
      
      % Update The Range Values
      range = getappdata(obj.gui,'cMapRange');
      set(range(2),'String',num2str(obj.range(1)));
      set(range(3),'String',num2str(obj.range(2)));
      
      % Update the Interpolation Type
      interpTypes = get(adata.interpType(2),'String');
      testVal = obj.interptype;
      if isequal(testVal,'pchip'), testVal = 'cubic'; end;
      idx = find(cellfun(@(x) isequal(x,testVal),interpTypes));
      set(adata.interpType(2),'Value',idx);
      
      cMapAxes = getappdata(obj.gui,'cMapAxes');
      
      axesDwnFcn = get(cMapAxes,'ButtonDownFcn');
      axes(cMapAxes); cla;
      i = image(permute(obj.cmap,[3 1 2]),'Parent',cMapAxes);
      set(i,'ButtonDownFcn',axesDwnFcn);
      axis off;
      set(gca,'XLim',[0.5 obj.depth+0.5]);
      XLim = get(gca,'XLim');
      hold on;
      
      % Plot the Line
      XData = linspace(XLim(1),XLim(2),obj.depth);
      YData = 1.5 - obj.alpha;
      p = plot(XData,YData,'k','LineWidth',2,'ButtonDownFcn',axesDwnFcn);
      
      % Plot the Points
      alphaData = obj.storedVals.alpha;
      XData = XData(alphaData(:,1));
      YData = 1.5 - alphaData(:,2);
      plot(XData,YData,'kx');
      set(cMapAxes,'ButtonDownFcn',axesDwnFcn);
      
    end
    
    function updateColormapFromGUI(obj)
      % Pull current values from the GUI and assign these to the
      % base colormap object.
      %
      % This only executes if obj.gui is a valid Matlab GUI object
      %
      if ~isempty(obj.gui)&&ishghandle(obj.gui)
        
        adata = getappdata(obj.gui);
        
        % Set the Type (ColorMap)
        selected = get(get(adata.radioGroup,'SelectedObject'),'String');
        obj.type = selected;
        
        % Set Interpolation Type
        string = get(adata.interpType(2),'String');
        idx = get(adata.interpType(2),'Value');
        obj.interptype = string{idx};
        
        % Set the Range
        obj.range(1) = str2double(get(adata.cMapRange(2),'String'));
        obj.range(2) = str2double(get(adata.cMapRange(3),'String'));
      end;
    end
    
  end
  
  methods (Access=protected)
    
    function selectAlpha(obj)
      % Protected Method for GUI Selection of Alpha Values
      %
      % This method is used in conjunction with the alphacolor GUI to allow
      % interactive selection of points to define a variable alpha map to
      % associate with the colormap.
      %
      selType = get(ancestor(obj.gui,'figure'),'SelectionType');
      
      cMapAxes = getappdata(obj.gui,'cMapAxes');
      
      % Find the list of currently selected points.
      alphaData = obj.storedVals.alpha;
      XLim = get(cMapAxes,'XLim');
      origXData = linspace(XLim(1),XLim(2),obj.depth);
      XData = origXData(alphaData(:,1));
      YData = 1.5 - alphaData(:,2);
      
      frac = max([1/obj.depth 0.05]);
      delta = round(frac*obj.depth);
      
      axesUnits = get(cMapAxes,'Units');
      set(cMapAxes,'Units','Normalized');
      pos = get(cMapAxes,'CurrentPoint');
      
      % Get info about selected point and assume it's new
      isNewPt = true;
      newX = pos(1,1);
      newY = 1.5 - pos(1,2);
      
      % Find proximity to existing points
      dist = abs(XData - newX);
      [minVal,idx] = min(dist);
      
      % Correct for offset in image
      [~,newX] = min(abs(origXData-newX));
      
      % If it's less than 10% of the total distance, match to closest point
      if minVal<delta, isNewPt = false; end;
      
      
      if ~isNewPt&&(ismember(alphaData(idx,1),[1 obj.depth]))
        alphaData(idx,2) = newY;
      else
        
        switch selType
          case 'normal'
            if isNewPt
              alphaData(end+1,:) = [newX newY];
            else
              alphaData(idx,1) = newX;
              alphaData(idx,2) = newY;
            end
            alphaData = sortrows(alphaData, 1);
          case 'alt'
            if ~isNewPt
              alphaData(idx,:) = []; %Remove the point if right clicking and we're close enough.
            end;
        end;
      end;
      
      obj.alpha = alphaData;
      set(cMapAxes,'Units',axesUnits);
      %obj.map.alpha = 1.5-pos(1,2);
      obj.updateColormapFromGUI;
    end
    
  end;
  
  methods (Static = true)
    function maps = colorMapList
      % COLORMAPLIST Return list of available colormaps
      %
      % function maps = colorMapList
      
      maps(1).name = 'jet';
      maps(2).name = 'gray';
      maps(3).name = 'hot';
      maps(4).name = 'parula';
      %maps(5).name = 'hsv';
      %maps(6).name = 'bone';
      %maps(7).name = 'copper';
      %maps(8).name = 'pink';
      %maps(9).name = 'colorcube';
      %maps(10).name = 'prism';
      maps(5).name = 'redblue';
      maps(6).name = 'prism';
      maps(7).name = 'winter';
      maps(8).name = 'spring';
      maps(9).name = 'summer';
      
    end
  end
end
