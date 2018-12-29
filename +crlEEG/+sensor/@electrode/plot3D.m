function varargout = plot3D(elecObj,varargin)
% Plot
%
% Display electrode locations in a new


%% Input Parsing
p = inputParser;
addOptional(p,'surfMRI',[],@(x) isa(x,'file_NRRD'));
addParamValue(p,'resid',[]);
addParamValue(p,'edgecolor',[]);
addParamValue(p,'posNear',[]);
addParamValue(p,'figRef',[]);
addParamValue(p,'ax',[]);

parse(p,varargin{:});

resid     = p.Results.resid;
edgecolor = p.Results.edgecolor;
posNear   = p.Results.posNear;
surfMRI   = p.Results.surfMRI;
figRef    = p.Results.figRef;
ax        = p.Results.ax;

if isempty(figRef)
  figRef = figure;
end

%% Open the figure and lock it
currFig = figure(figRef);

% Select the correct axes
if ~isempty(ax)
 axes(ax);
 hold on;
end

%% Display Surface MRI, if Provided
if ~isempty(surfMRI)
  headSurf = ExtractIsosurface(surfMRI);
  headSurf.FAlpha = 0.9;
  ViewSurface(currFig,headSurf);
end

%% Display Electrode Locations
%positions = subsref(elecObj,substruct('.','position'));
positions = cat(1,elecObj.position);
if iscell(positions)
  % If we're using a patch/CEM model, use the mean location for plotting.
  for i = 1:numel(positions)
    tmpPos(i,:) = mean(positions{i},1);
  end
  positions = tmpPos;
end

%%
names = {elecObj.label};
nPlot = numel(elecObj);
hold on;
cmap = [];
if isempty(positions), return; end % if no data points, return

% Create proto-sphere
[sX sY sZ] = sphere(30);
sX = sX * 2;
sY = sY * 2;
sZ = sZ * 2;

% Adjust colormap
if ~isempty(resid)
  [n,xout] = hist( resid );
  cmap = colormap(jet(length(xout)+2));
end

if ~isempty(edgecolor)
  maxcolors = 5;
  cmap = colormap(jet(maxcolors));
  if edgecolor>maxcolors, edgecolor = maxcolors; end
  cmap = cmap(edgecolor,:);
end

for i = 1 : nPlot
  % Get x-y-z location
  x = positions(i,1);
  y = positions(i,2);
  z = positions(i,3);
  
  % Get the name
  if numel(names)>=i
    ElecName = names{i};
  else
    ElecName = num2str(i);
  end;
  
  if ~isempty(resid)
    if resid(i)<xout(1), ind = 1;
    elseif resid(i)>xout(end), ind = length(xout)+2;
    else ind = floor((resid(i)-xout(1))/abs(diff(xout(1:2)))) + 2; end
    outObj.sphere(i) = surf( gca, sX+x, sY+y, sZ+z, 'EdgeColor', cmap(ind,:) ); % plot sphere
    utObj.text(i) = text(x,y,z,[ElecName],'Color','red');
  elseif ~isempty(edgecolor)
    outObj.sphere(i) = surf( gca, sX+x, sY+y, sZ+z, edgecolor*ones(size(sZ)), 'EdgeColor', cmap ); % plot sphere, edge color as in cmap
    colormap(cmap)
    utObj.text(i) = text(x,y,z,[ElecName],'Color','red');
  else
    outObj.sphere(i) = surf( gca, sX+x, sY+y, sZ+z ); % plot sphere, edge color default (black)
    outObj.text(i) = text(x+5,y+5,z+5,[ElecName],'Color','red');
  end
  
  % surf( gca, sX+x, sY+y, sZ+z, 'CData', sC, 'EdgeColor', sE(1,:) ); % plot sphere
  if(isempty(posNear)) continue; end
  
  
  %       x2 = posNear(i,1);
  %       y2 = posNear(i,2);
  %       z2 = posNear(i,3);
  %       plot3([x2 x], [y2 y], [z2 z],'-r','LineWidth',2);
end

hold off; % unlock figure data

if nargout>0
  varargout{1} = outObj;
end;

% %% Display Fiducial Locations
% positions = elecObj.FIDPositions;
% names = elecObj.FIDLabels;
% nPlot = numel(names);
% plotPositions;

%%
  function plotPositions
    %% DEPRECATED FUNCTION
    hold on;
    cmap = [];
    if isempty(positions), return; end % if no data points, return
    
    % Create proto-sphere
    [sX sY sZ] = sphere(30);
    sX = sX * 2;
    sY = sY * 2;
    sZ = sZ * 2;
    
    % Adjust colormap
    if ~isempty(resid)
      [n,xout] = hist( resid );
      cmap = colormap(jet(length(xout)+2));
    end
    
    if ~isempty(edgecolor)
      maxcolors = 5;
      cmap = colormap(jet(maxcolors));
      if edgecolor>maxcolors, edgecolor = maxcolors; end
      cmap = cmap(edgecolor,:);
    end
    
    for i = 1 : nPlot
      % Get x-y-z location
      x = positions(i,1);
      y = positions(i,2);
      z = positions(i,3);
      
      % Get the name
      if numel(names)>=i
        ElecName = names{i};
      else
        ElecName = num2str(i);
      end;
      
      if ~isempty(resid)
        if resid(i)<xout(1), ind = 1;
        elseif resid(i)>xout(end), ind = length(xout)+2;
        else ind = floor((resid(i)-xout(1))/abs(diff(xout(1:2)))) + 2; end
        surf( gca, sX+x, sY+y, sZ+z, 'EdgeColor', cmap(ind,:) ); % plot sphere
        text(x,y,z,[ElecName],'Color','red')
      elseif ~isempty(edgecolor)
        surf( gca, sX+x, sY+y, sZ+z, edgecolor*ones(size(sZ)), 'EdgeColor', cmap ); % plot sphere, edge color as in cmap
        colormap(cmap)
        text(x,y,z,[ElecName],'Color','red')
      else
        surf( gca, sX+x, sY+y, sZ+z ); % plot sphere, edge color default (black)
        text(x+5,y+5,z+5,[ElecName],'Color','red')
      end
      
      % surf( gca, sX+x, sY+y, sZ+z, 'CData', sC, 'EdgeColor', sE(1,:) ); % plot sphere
      if(isempty(posNear)) continue; end
      
      
      x2 = posNear(i,1);
      y2 = posNear(i,2);
      z2 = posNear(i,3);
      plot3([x2 x], [y2 y], [z2 z],'-r','LineWidth',2);
    end
    
    hold off; % unlock figure data
  end
end