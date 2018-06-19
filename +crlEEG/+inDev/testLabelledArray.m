%%
clear all; clear classes;
for i = 1:100, labels{i} = ['Chan' num2str(i)]; end;
test = labelledArray_withValues(randn(10000,100,3),'dimLabels',{2,labels},'dimValues',{1,1:10000; 2,linspace(0,1,100)},'dimNames',{'A' 'B' 'C'});