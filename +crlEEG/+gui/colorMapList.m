function maps = colorMapList
% COLORMAPLIST Return list of available colormaps
%
% function maps = colorMapList

warning('crlEEG.gui.colorMapList is deprecated. Please change to using crlEEG.alphacolor.colorMapList instead');

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
maps(5).name = 'cool';
maps(6).name = 'autumn';
maps(7).name = 'winter';
maps(8).name = 'spring';
maps(9).name = 'summer';

end