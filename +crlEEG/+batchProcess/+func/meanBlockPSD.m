function output = meanBlockPSD(EEG,varargin)
% A General Block Processing Function for Mouse Mouse EEG
%
% This function is written to be paired with
% crlEEG.batchProcess.
%
% Inputs
% ------
%   EEG : A crlEEG.EEG object
%
% Param-Value Inputs
% ------------------
%  'outputFrequencies' : Output frequencies for the analysis
%                          DEFAULT: 0.5:0.5:120
%
% Output
% ------
%  output : An output structure
%
% Function Description
% --------------------
%  This function performs the following processing steps:
%
%     a) Wavelet Decomposition
%     b) Interpolate to Output Frequencies
%     c) Normalize Per Timepoint
%
% If all data channels in the input object as accompanied by an auxilliary
% channel names <chanName>_forAnalysis, when averaging across the block,
% only those timepoint where <chanName>_forAnalysis is true will be used in
% computing the mean.
%
% This function then creates an output structure with several fields:
%     outStruct.decomp : MatTSA.tfDecomp object with one column per block
%              .normDecomp : Same as above, but normalized per-timepoint before
%                               averaging across the block;
%              .totPow : Total power at all (original) timepoints.
%              .nSamples : Number of samples used in the computation of the
%                           mean value. Compare to the length of .totPow to
%                           determine the fraction of timepoints used (A
%                           rough measure of data quality).

p = inputParser;
p.addParameter('outputFrequencies',[0.5:0.5:120],@(x) isnumeric(x)&&isvector(x));
p.parse(varargin{:});

% Under what conditions should we reject an entire blocK?
testChans = strcat(EEG.chanLabels,'_forAnalysis');
if all(ismember(testChans,EEG.chanLabels))
  % Check that all channels have at least some valid timepoints to
  % process.
  tmpData = EEG.data(:,testChans);
  hasCheck = true;
else
  % Just go ahead and try to process it
  tmpData = 1;
  hasCheck = false;
end;

%% If 
if ~all(any(tmpData,1))
  if ~iscellstr(EEG.chanLabels)
    tmp = {EEG.chanLabels};
  else
    tmp = EEG.chanLabels;
  end;
  
  % Reject a block of any of the channels has zero useable timepoints.
  outDecomp = MatTSA.tfDecomp(nan(numel(p.Results.outputFrequencies),...
    numel(tmp)));
  outDecomp.decompType = 'wavelet_PSD';
  outDecomp.dataType = 'PSD';
  
  outDecomp.chanLabels = tmp;
  outDecomp.tVals = mean(EEG.tVals);
  outDecomp.fVals = p.Results.outputFrequencies;
  
  % Empty Total Power Structure
  totPow = MatTSA.tfDecomp(nan(1,size(EEG,'time'),numel(tmp)));
  totPow.decompType = 'wavelet_PSD';
  totPow.dataType = 'PSD';
  totPow.chanLabels = tmp;
  totPow.tVals = EEG.tVals;
  totPow.fVals = mean(p.Results.outputFrequencies);
  
  
  % Configure an "Empty" output
  output.decomp = outDecomp;
  output.normDecomp = outDecomp;
  output.totPow = totPow;
  output.nSamples = 0;
  
  return;
end;

% Compute wavelet decomposition and interpolate to desired frequencies
A = EEG.timefrequency('method','wavelet').PSD;
A = A.interpFrequencies(p.Results.outputFrequencies);

% Normalize Power
%
% There are two potential ways of normalizing power. This computation uses
% the power spectral density, which itself is the square of the magnitude
% of the complex coefficients computed by the wavelet decomposition.
%
% The two ways I see of doing this:
%  1) Normalize by the 2-norm of the power spectral density (first line)
%  2) Normalize by the sum of the power spectral density (second line)
%
% Not really sure which is the "correct" way to do it, so I'm mentioning it
% here and leaving both coded (but Option #2 commented)
%
totPow = sqrt(sum(A.^2,'frequency'));
%totPow = sum(A,'frequency');
Anorm = A./totPow;

if hasCheck
  % With artifact reject, need to run per-channel
  output.decomp     = MatTSA.tfDecomp;
  output.normDecomp = MatTSA.tfDecomp;
  chanName = EEG.chanLabels;
  if ischar(chanName), chanName = {chanName}; end;
  for i = 1:numel(chanName)
    % Mean and Std of Decomposition
    useTimes = find(EEG.data(:,[chanName{i} '_forAnalysis']));
    output.decomp = cat(3,output.decomp,...
      mean(A(:,useTimes,chanName{i}),'time'));
    output.stdDecomp = cat(3,output.stdDecomp,...
      std(A(:,useTimes,chanName{i})),'time');
    % Mean and Std Of Normalized Decomp
    output.normDecomp = cat(3,output.normDecomp,...
      mean(Anorm(:,useTimes,chanName{i})),'time');
    output.stdNormDecomp = cat(3,output.stdNormDecomp,...
      std(Anorm(:,useTimes,chanName{i})),'time');
    output.nSamples = numel(useTimes);
  end;
else
  % Average over all timepoints
  output.decomp = mean(A,'time');
  output.stdDecomp = std(A,'time');
  
  if isempty(output.decomp.tVals), keyboard; end;
  output.normDecomp = mean(Anorm,'time');
  output.normDecomp.decompType = 'wavelet_PSD_normalized';
  output.stdNormDecomp = std(Anorm,'time');
  output.nSamples = size(A,'time');
end

output.normDecomp.decompType = [output.normDecomp.decompType '_normalized'];

% Total Power is the Same Either Way
%output.totPow = totPow;

end