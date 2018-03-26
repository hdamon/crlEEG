function varargout = plot2D(elec,varargin)
% Plot a 2D point cloud of the electrode positions
%
% Given a spatial origin and set of basis functions, converts the X-Y-Z
% positions to spherical coordinates, and displays a scatter plot of
% electrode locations in 2D. The third basis function is used as the
% orientation of the Z-axis in the spherical coordinate system, and will be
% plotted at the center of the plot. 
%
% Inputs
% ------
%   elec   : array of crlEEG.head.model.EEG.electrode objects
%   origin : (x,y,z) origin of the coordinate system
%   basis  : basis vectors for the coordinate system
%
% Optional Param-Value Inputs
% ---------------
%       label : Logical value turning display of labels on/off 
%                 (Default: OFF)
% labelColors : Colors for the electrode marks
%  markerSize : Marker size for the electrode scatter plot.
%        axis : Handle to axis to display plot in. 
%                 (Default: New Figure)
%
% Needed Updates
% --------------
%  An EEG headnet object should be created that merges the electrode and
%  fiducial positions, internally stores the reference orientations, and
%  does the conversion to polar coordinates
%
p = inputParser;
p.addOptional('origin',[],@(x) isequal(size(x),[1 3]));
p.addOptional('basis',[],@(x) isequal(size(x),[3 3]));
p.addParamValue('label',false,@(x) islogical(x));
p.addParameter('labelColors',[]);
p.addParameter('labelColorMap','jet');
p.addParameter('markerSize',[],@(x) isnumeric(x)&&isscalar(x));
p.addParamValue('scale',0.95,@(x) isscalar(x));
p.addParamValue('figure',[],@(x) isa(x,'matlab.ui.Figure'));
p.addParamValue('axis',[],@(x) isa(x,'matlab.graphics.axis.Axes'));
p.addParamValue('plotlabels',[],@(x) iscellstr(x));
p.parse(varargin{:});

labelOn = p.Results.label;

% Select Correct Figure
if isempty(p.Results.figure)
  if isempty(p.Results.axis)
    figure;
  end;
else
  figure(p.Results.figure);
end;

% Select Correct Axis
if isempty(p.Results.axis)
  gca;
else
  axes(p.Results.axis);
end

[x,y] = elec.projPos('origin',p.Results.origin,...
                     'basis',p.Results.basis,...
                     'scale',p.Results.scale);

if ~isempty(p.Results.plotlabels)
 idx = elec.getNumericIndex(p.Results.plotlabels);
 x = x(idx);
 y = y(idx);
end;

currHold = ishold(gca);
hold on;
colors = zeros(numel(x),3);
if ~isempty(p.Results.labelColors)
  assert(size(p.Results.labelColors,1)==numel(x),'Must provide a color for each electrode');
  if size(p.Results.labelColors,2)==3
   colors = p.Results.labelColors;
  else
    assert(size(p.Results.labelColors,1)==1,'Provide either);
    
  end
end
outObj.scatter = scatter(x,y,p.Results.markerSize,colors,'filled');

if labelOn
  for i = 1:numel(elec)
    outObj.text(i) = text(x(i)+0.05,y(i)+0.05,elec(i).label);
  end
end;

if nargout>0
  varargout{1} = outObj;
end;

axis(p.Results.scale*[-2.1 2.1 -2.1 2.1]);

if ~currHold
  % Return hold to its original state
  hold off;
end
%axis([-1.25 1.25 -1.25 1.25]);
end