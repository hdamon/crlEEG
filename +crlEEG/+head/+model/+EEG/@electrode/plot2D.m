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
%   label : Logical value turning display of labels on/off (Default: OFF)
%    axis : Handle to axis to display plot in
%

p = inputParser;
p.addOptional('origin',[],@(x) isequal(size(x),[1 3]));
p.addOptional('basis',[],@(x) isequal(size(x),[3 3]));
p.addParamValue('label',false,@(x) islogical(x));
p.addParamValue('scale',0.95,@(x) isscalar(x));
p.addParamValue('figure',[],@(x) isa(x,'matlab.ui.Figure'));
p.addParamValue('axis',[],@(x) isa(x,'matlab.graphics.axis.Axes'));
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

origin = p.Results.origin;
basis = p.Results.basis;

% Try and compute these if they weren't provided
if ~exist('origin','var')||isempty(origin)
  warning('Estimating electrode cloud center. This may not work correctly');
  origin = mean(subsref(elec,substruct('.','position')),1);
end;

if ~exist('basis','var')||isempty(basis)
  crlEEG.disp('Attempting to identify an appropriate basis set');
  try
   upPos = subsref(elec,substruct('()',{'Cz'}));
   upPos = upPos.position;
   frontPos = subsref(elec,substruct('()',{'Nz'}));
   frontPos = frontPos.position;
  catch
    try 
      upPos = subsref(elec,substruct('()',{'E80'}));
      upPos = upPos.position;
      frontPos = subsref(elec,substruct('()',{'E17'}));
      frontPos = frontPos.position;
    catch
      error('Could not locate an appropriate set of reference points');
    end;
  end;
  
  vecZ = upPos - origin; vecZ = vecZ./norm(vecZ);
  vecX = frontPos - origin; vecX = vecX./norm(vecX);
  vecX = vecX - vecZ*(vecZ*vecX'); vecX = vecX./norm(vecX);
  
  vecY = cross(vecZ,vecX);
  
  basis = [vecX(:) vecY(:) vecZ(:)];              
end

% Get positions relative to center
relPos = subsref(elec,substruct('.','position')) - repmat(origin,numel(elec),1);
newPos = (basis'*relPos')';
X = newPos(:,1); Y = newPos(:,2); Z = newPos(:,3);

% Compute Polar Coordinates
r = sqrt(X.^2 + Y.^2 + Z.^2);
theta = acos(Z./r);
phi = atan(Y./X);
phi(X<0) = phi(X<0) + pi;

%theta = (p.Results.scale/max(theta))*theta;
theta = 2*theta/pi;
%drawHeadCartoon(gca);
x = -theta.*sin(phi);
y = theta.*cos(phi);

currHold = ishold(gca);
hold on;
outObj.scatter = scatter(x,y,[],[0 0 0],'filled');

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