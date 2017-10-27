function [Potentials varargout] = solveForPotentials(FDModel,Currents_In,varargin)
% SOLVEFORPOTENTIALS Solve Finite Difference Model and Return Voltage Map
%
% function Potentials = solve_FDModel(FDModel,Currents_In)
%
% Inputs:  FDModel     : cnlFDModel Object
%          Currents_In : Input Currents for Solution
%          Potentials  : Returns the voltage potential at each node in the
%                         FDM matrix

mydisp(['Solving FD Model to Compute Potential Distribution']);

p = inputParser;
p.addParamValue('M1',[]);
p.addParamValue('M2',[]);
p.addParamValue('X0',[]);
p.parse(varargin{:});

% Set convergence tolerance and maxiterations
tol   = FDModel.tol;
maxIt = FDModel.maxIt;

% Get the solution using the builtin MINRES solver
tStart = clock;
[Potentials, Flag, Residual, Iters] = ...
  minres(FDModel.matFDM,Currents_In,tol,maxIt,p.Results.M1,p.Results.M2,...
  p.Results.X0);  

% Display a few things
mydisp(['Completed solution for Electrode in ' num2str(etime(clock,tStart)) ' seconds']);
if Flag==0
  mydisp(['MINRES Converged in ' num2str(Iters) ' iterations to within ' num2str(tol)]);
elseif Flag==1
  mydisp(['MINRES Completed AFter ' num2str(Iters) ' iterations to residual ' num2str(Residual)]);
else
  mydisp('ERROR While Running MINRES');
end;

% Compute and display the residual error
err = FDModel.matFDM*Potentials(:)-Currents_In;
err = norm(err(:))/norm(Currents_In);
mydisp(['FD Model Solution Obtained with Relative Error: ' num2str(err)]);

% The only time we should get a NaN number in the error is if Current_In is
% zero.
if norm(Currents_In)~=0 && isnan(err)
  error('Something is wrong if we''re getting a NaN error value');
end;

% Split the vector of potentials into those that represent actual physical
% voltages in the model grid space, and those corresponding to auxilliary
% nodes defined by the electrode model
%
nNodes = prod(FDModel.imgSize+[1 1 1]);
AuxNodes = Potentials(nNodes+1:end);
Potentials = Potentials(1:nNodes);

if nargout>1
  varargout{1} = AuxNodes;
end;

end