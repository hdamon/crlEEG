function disp_FullWidth(message)

lineLength = 80;
msgLength = length(message);

msgLine = ['%%  ' message];
msgLine(lineLength-1:lineLength) = '%';

disp(repmat('%',1,lineLength));
disp(msgLine);
disp(repmat('%',1,lineLength));

end