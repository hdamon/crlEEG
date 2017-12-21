function varargout = drawHeadCartoon(varargin)
% Plot a cartoon head diagram
%
% Usage:
%    drawHead()   : Open a new figure and draw the default head.
%    drawHead(ax) : Draw a head in axes ax
%
% Optional Inputs:
%  'diam'     : Diameter of the head circle (DEFAULT: 1)
%  'center'   : Location of the head center (DEFAULT: [0 0])
%  'CIRCGRID'     : Number of points to use in plotting head circle
%                    DEFAULT: 360
%  'HEADCOLOR'    : Color to plot the head in. DEFAULT: 'black'
%  'HLINEWIDTH'   : Width of lines in head plot. DEFAULT: 2
%  'NOSEDIRECTION': Vector to point the noise along. DEFAULT: [0 1]
%  'PLOT3D'       : Flag to enable 3D plotting (DEFAULT: FALSE)
%  'ZVAL'         : Location along Z-axis when plotting in 3D
%
% SOME OF THIS CODE CAME FROM THE EEGLAB topoplot() FUNCTION:
%
% Copyright (C) Colin Humphries & Scott Makeig, CNL / Salk Institute, Aug, 1996
%                                          
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

p = inputParser;
p.addOptional('ax',@(x) ishghandle(x));
p.addParamValue('CIRCGRID',360,@(x) isscalar(x));
p.addParamValue('HEADCOLOR','black',@(x) isstr(x));
p.addParamValue('HLINEWIDTH',2,@(x) isnumeric(x)&&isscalar(x));
p.addParamValue('NOSEDIRECTION',[0 1],@(x) isnumeric(x)&&(numel(x)==2));
p.addParamValue('PLOT3D',false,@(x) islogical(x));
p.addParamValue('ZVAL',1,@(x) isnumeric(x)&&isscalar(x));
p.addParamValue('diam',1,@(x) isnumeric(x)&&isscalar(x));
p.addParamValue('center',[0 0],@(x) isnumeric(x)&&(numel(x)==2));
parse(p,varargin{:});

if ~ishghandle(p.Results.ax)
  figure;
  ax = axes;
else
  ax = p.Results.ax;  
end;

center = p.Results.center;
diam = p.Results.diam;

HEADCOLOR = p.Results.HEADCOLOR;
HLINEWIDTH = p.Results.HLINEWIDTH;

circ = linspace(0,2*pi,360);
rx = sin(circ);
ry = cos(circ);

headx = [[rx(:)' rx(1) ]*(diam)  [rx(:)' rx(1)]*diam];
heady = [[ry(:)' ry(1) ]*(diam)  [ry(:)' ry(1)]*diam];
headx = headx+center(1);
heady = heady+center(2);

%% Nose Points
rmax = diam;
base  = rmax-.0046;
basex = 0.18*rmax;                   % nose width
tip   = 1.15*rmax;
tiphw = .04*rmax;                    % nose tip half width
tipr  = .01*rmax;                    % nose tip rounding
NoseX = [basex; tiphw; 0; -tiphw; -basex];
NoseY = [base; tip-tipr; tip; tip-tipr; base];

%% Ear Points
q = .04; % ear lengthening
EarX  = [.497-.005  .510  .518  .5299 .5419  .54    .547   .532   .510   .489-.005]; % rmax = 0.5
EarY  = [q+.0555 q+.0775 q+.0783 q+.0746 q+.0555 -.0055 -.0932 -.1313 -.1384 -.1199];
EarX  = EarX*diam*2;
EarY  = EarY*diam*2;

LEarX =  EarX; LEarY = EarY;
REarX = -EarX; REarY = EarY;

%% Rotate Orientation
v = p.Results.NOSEDIRECTION;
v = v(:)./norm(v);
inner = v'*[0 1]';
theta = acosd(inner);
if inner<0, theta = theta+90; end;
if v(1)>0, theta = -theta; end;

rot = [cosd(theta) -sind(theta); sind(theta) cosd(theta)];

Nose = rot*[NoseX(:) NoseY(:)]';
LEar = rot*[LEarX(:) LEarY(:)]';
REar = rot*[REarX(:) REarY(:)]';

%% Adjust Center
NoseX = Nose(1,:) + center(1);
NoseY = Nose(2,:) + center(2);
LEarX = LEar(1,:) + center(1);
LEarY = LEar(2,:) + center(2);
REarX = REar(1,:) + center(1);
REarY = REar(2,:) + center(2);

if ~p.Results.PLOT3D
  %% Plot in 2D
  axes(ax); hold on;
  ringh= plot(headx,heady);
  set(ringh, 'color',HEADCOLOR,'linewidth', HLINEWIDTH);
  plotOut.head = ringh;
  plotOut.nose = plot(NoseX,NoseY,'Color',HEADCOLOR,'LineWidth',HLINEWIDTH); % plot nose
  plotOut.lEar = plot(LEarX,LEarY,'color',HEADCOLOR,'LineWidth',HLINEWIDTH); % plot left ear
  plotOut.rEar = plot(REarX,REarY,'color',HEADCOLOR,'LineWidth',HLINEWIDTH); % plot right ear
else
  %% Plot in 3D
  axes(ax); hold on;
  ringh= plot3(headx,heady,p.Results.ZVAL*ones(size(heady)));
  set(ringh, 'color',HEADCOLOR,'linewidth', HLINEWIDTH);
  plotOut.head = ringh;
  plotOut.nose = plot3(NoseX,NoseY,p.Results.ZVAL*ones(size(NoseY)),'Color',HEADCOLOR,'LineWidth',HLINEWIDTH); % plot nose
  plotOut.lEar = plot3(LEarX,LEarY,p.Results.ZVAL*ones(size(LEarY)),'color',HEADCOLOR,'LineWidth',HLINEWIDTH); % plot left ear
  plotOut.rEar = plot3(REarX,REarY,p.Results.ZVAL*ones(size(REarY)),'color',HEADCOLOR,'LineWidth',HLINEWIDTH); % plot right ear
end
  
if nargout>0
  varargout{1} = plotOut;
end

end