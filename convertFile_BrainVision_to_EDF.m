function edfOut = convertFile_BrainVision_to_EDF(fNameIn,fPathIn,fNameOut,fPathOut)
% Convert EEG File from BrainVision to EDF FOrmat
%
% edfOut = convertFile_BrainVision_To_EDF(fNameIn,fNameOut)
%     Convert fNameIn (A .eeg file) to fNameOut (A .edf file)
%
% edfOut = convertFile_BrainVision_to_EDF(fNameIn,fPathIn,fNameOut,fPathOut)
%     Use input/output directoryes fPathIn and fPathOut
%
% edfOut = convertFile_BrainVision_to_EDF
%     Use a file selection GUI for both input and output
%
% edfOut = convertFile_Brainvision_to_EDF(fNameIn)
%     Use a file selection GUI only for the output
%    
if exist('fPathIn','var')&&~exist(fPathIn,'dir')
  fNameOut = fPathIn;
end;

if ~exist('fNameIn','var'), fNameIn = [] ; end;
if ~exist('fPathIn','var'),  fPathIn  = [] ; end;
if ~exist('fNameOut','var'), fNameOut = [] ; end;
if ~exist('fPathOut','var'), fPathOut = [] ; end;

if isempty(fNameIn)
  [fNameIn,fPathIn ] = uigetfile({'*.eeg'});
end

if isempty(fNameOut)
  tmpName = strsplit(fNameIn,'.');
  tmpName = tmpName{1}; 
  tmpName = [tmpName '.edf'];
  [fNameOut,fPathOut] = uiputfile(tmpName);
end

fileIo = crlEEG.readFile(fNameIn,fPathIn);

edfOut = crlEEG.fileio.EDF(fileIo);
edfOut.fname = fNameOut;
edfOut.fpath = fPathOut;
edfOut.write;




  