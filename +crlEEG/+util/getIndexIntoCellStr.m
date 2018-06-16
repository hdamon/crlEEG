function outIdx = getIndexIntoCellStr(cellIn,refIn,isNumericValid)

if ~exist('isNumericValid','var'), isNumericValid = true; end;

warning('getIndexIntoCellStr is deprecated. Functionality is duplicated in getDimensionIndex');
outIdx = crlEEG.util.getDimensionIndex(cellIn,refIn,isNumericValid);
end