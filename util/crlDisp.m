function crlDisp(stringIn,priority,offset,disablefdisp)
  % Replacement for disp() with added functionality.
  %
  % function mydisp(stringIn,varargin)
  %
  % Inputs:
  %    stringIn : String to display
  % 
  % Optional Parameter-Value Pairs:
  %    'priority' : Set display priority of message. Priority 0 messages
  %                  will ignore cnlDebug and always be displayed (assuming
  %                  cnlDisplayPriority>0)
  %                   DEFAULT: 1
  %    'offset'   : Manually set the indentation of the line
  %                   DEFAULT: 0
  %    'disablefdisp': Disable prepending of the function name
  %                   DEFAULT: FALSE
  %
  % Global Variables Used:
  %   cnlDebug : DEFAULT: TRUE
  %   cnlDisplayPriority: DEFAULT: 4
  %
  % A cnlEEG replacement for the disp() function to improve display of 
  % status messages during execution of long code runs. The primary
  % feature of this function is to take the provided input string and 
  % prepend it with a string indicating the calling function, with the 
  % current stack depth represented by indenting the start of the line.
  % This allows the user to more easily identify their location in a 
  % complex set of running code than would otherwise be possible with
  % disp() alone.
  %
  % Additionally, this function uses the global variables cnlDebug and
  % cnlDisplayPriority to determine whether a particular message should be
  % displayed. While this functionality isn't currently used extensively in
  % cnlEEG, it w
  %
  % This adds a number of leading
  % spaces equal to the depth of the function stack.  It also looks for a
  % global variable called cnlDebug. If this is set to false, it will turn
  % off all display.
  %
  % Written By: Damon Hyde
  % Last Edited: Feb 4, 2016
  % Part of the cnlEEG Project
  %
  
  global cnlDebug
  global cnlDisplayPriority
  
  if isempty(cnlDebug), cnlDebug = true; end;
  if isempty(cnlDisplayPriority), cnlDisplayPriority = 4; end;
  if ~exist('priority','var')|isempty(priority), priority = 1; end;
  if ~exist('offset','var')|isempty(offset), offset = 0; end;
  if ~exist('disablefdisp','var'), disablefdisp = false; end;
  
  forceDisp = (priority==0);
  
  doDisplay = (priority<=cnlDisplayPriority)&&(cnlDebug||forceDisp);
  
  if doDisplay
    [ST I ] =dbstack('-completenames');
    
    % Get leading spaces
    if ~isnan(offset)
      depth = length(dbstack);
      numSpaces = 2*(depth-2) + offset;
      if numSpaces<0, numSpaces = 0; end;
      leading = blanks(numSpaces);
    else
      leading = [];
    end;
    
    % Get function name to prepend things with
    if ~disablefdisp
      % Add function names to the beginning of things...
      if numel(ST)>=2
      fName = ST(2).name;
      fFile = ST(2).file;
      else
        fName = [];
        fFile = [];
      end;
      
      if isempty(strfind(fName,'.'))
        % We aren't already designated as a class function
        findAt = strfind(fFile,'@');
        if ~isempty(findAt)
          if numel(findAt==1)
            prepend = fFile(findAt:end);
            findCut = strfind(prepend,'/');
            prepend = prepend(1:(findCut-1));
            prepend = [prepend '::' fName ' '];
          else
            builtin('disp','WHOAH.... a class inside a class?? CHECK IT OUT');
            keyboard;
          end;
        else
          prepend = [ fName ' '];
        end;
      else
        prepend = [ fName ' '];
      end
    else
      prepend = [];
    end
    
%    if ~isempty(prepend)
      tmp = blanks(45);
      if (length(prepend)<(length(tmp)-length(leading)))&~disablefdisp
        prepend(end+1:(length(tmp)-length(leading)-1)) = '.';
      end;
      tmp((length(leading)+1):(length(prepend)+length(leading))) = prepend;
      stringIn = [tmp stringIn];
%    else
%      stringIn = [leading stringIn];
%    end;
    
    builtin('disp',stringIn)
    
    %   if ~isnan(offset)
    %     depth = length(dbstack);
    %     numSpaces = 2*(depth-2) + offset;
    %     if numSpaces<0, numSpaces = 0; end;
    %
    %     leading(1:numSpaces) = ' ';
    %     if 1==0 %depth>3
    %       builtin('disp',[leading '-' stringIn]);
    %     else
    %       builtin('disp',[leading stringIn]);
    %     end;
    %   else
    %     builtin('disp',stringIn);
    %   end;
  end;
  
  return;