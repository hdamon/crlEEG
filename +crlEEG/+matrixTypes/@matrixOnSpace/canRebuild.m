function out = canRebuild(obj)
% Check If A cnlLeadField Can Build obj.currMatrix
%
% function out = canRebuild(obj)
%
% Check a bunch of parameters to see whether or not currMatrix can be
% built yet
%
% Written By: Damon Hyde
% Last Edited: April 22, 2016
% Part of the cnlEEG Project
%

% If any of these are missing, can't build currMatrix
if isempty(obj.origMatrix),        out = false; return; end;
if isempty(obj.origSolutionSpace), out = false; return; end;
if isempty(obj.currSolutionSpace), out = false; return; end;

% Check compatibility of solution spaces
if ~checkCompatibility(obj.origSolutionSpace,obj.currSolutionSpace)
  error('currSolutionSpace is incompatible with origSolutionSpace');
end

% Check that the matrix can actually be collapsed
if obj.isCollapsed&&(~obj.canCollapse)
  error('obj.isCollapsed is set to true, but obj.matCollapse is not defined');
end

out = true;

end