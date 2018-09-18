% Configure Matlab Path to Include the full crlEEG
function addCRLEEGPath()
[currDir,~,~] = fileparts(mfilename('fullpath'));

addpath(currDir);
addpath(...
     [currDir '/external/BioSig_2.92/tsa:'], ...
     [currDir '/external/BioSig_2.92/biosig/viewer/help:'], ...
     [currDir '/external/BioSig_2.92/biosig/viewer/utils:'], ...
     [currDir '/external/BioSig_2.92/biosig/viewer:'], ...
     [currDir '/external/BioSig_2.92/biosig/t501_VisualizeCoupling:'], ...
     [currDir '/external/BioSig_2.92/biosig/t500_Visualization:'], ...
     [currDir '/external/BioSig_2.92/biosig/t490_EvaluationCriteria:'], ...
     [currDir '/external/BioSig_2.92/biosig/t450_MultipleTestStatistic:'], ...
     [currDir '/external/BioSig_2.92/biosig/t400_Classification:'], ...
     [currDir '/external/BioSig_2.92/biosig/t300_FeatureExtraction:'], ...
     [currDir '/external/BioSig_2.92/biosig/t250_ArtifactPreProcessingQualityControl:'], ...
     [currDir '/external/BioSig_2.92/biosig/t200_FileAccess:'], ...
     [currDir '/external/BioSig_2.92/biosig/doc:'], ...
     [currDir '/external/BioSig_2.92/biosig/demo:'], ...
     [currDir '/external/BioSig_2.92/biosig:']);


