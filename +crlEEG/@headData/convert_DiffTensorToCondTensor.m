function [SymOut] = convert_DiffTensorToCondTensor(diffTensorVals,varargin)
%function [SymOut] = convert_DiffTensorToCondTensor(diffTensorVals,varargin)
%
%  Given an input diffusion tensor, compute the associated conductivity
%  tensor using the method of Tuch (PNAS 2001).

%% Set Relationship Type
if (length(varargin)>=1)&&(~isempty(varargin{1})),
  method = varargin{1};
else
  method = 'fractional';
end;

%% Set Relationship Parameters
if length(varargin)==2, error('Incorrect Number of Arguments'); end;

switch lower(method)
  case 'linear'
    if length(varargin)==3
      k = varargin{2};
      De = varargin{3};
    elseif length(varargin)>1
      error('Incorrect Number of Arguments');
    else
      k = 0.844;
      De = 0.124;
    end;
  case 'fractional'
    if length(varargin)==4
      Se = varargin{2};
      De = varargin{3};
      Di = varargin{4};
    elseif length(varargin)>1
      error('Incorrect Number of Arguments');
    else
      Se = 1.52;
      De = 2.04;
      Di = 0.117;
    end
  otherwise
    error('Unknown method type');
end;


%% Get Eigen-Decomposition of diffusion Tensor
diffTensorVals = 1000*diffTensorVals(:); % Why is this being done?
diffTensor = zeros(3,3);
diffTensor(:,1)   = diffTensorVals(1:3);
diffTensor(1,:)   = diffTensorVals(1:3)';
diffTensor(2:3,2) = diffTensorVals(4:5);
diffTensor(2,2:3) = diffTensorVals(4:5)';
diffTensor(3,3)   = diffTensorVals(6);

[eigVec eigVal] = eig(diffTensor);
eigVal = diag(eigVal);

eigValOut = zeros(size(eigVal));
for idx = 1:length(eigVal)
  switch lower(method)
    case 'linear'
      eigValOut(idx) = k*(eigVal(idx)-De);
    case 'fractional'
      BetaD = (Di-De)/(Di+2*De);
      Numer = 3*(eigVal(idx)-De)*(BetaD+2);
      Denom = eigVal(idx)*(4*BetaD^3 - 5*BetaD - 2) + De*(8*BetaD^3 - 7*BetaD + 2);
      eigValOut(idx) = Se*(1 + Numer/Denom);
  end;
end;

eigValOut = diag(eigValOut);

condTensor = eigVec*eigValOut*eigVec';

SymOut = condTensor([1:3 5:6 9]);
SymOut = SymOut(:);

return;