classdef selectXYZSlice < crlEEG.gui.uipanel
  % UI Object for Selecting and X-Y-Z Slice
  %
  % classdef selectXYZSlice < crlEEG.gui.uipanel
  %
  %
  
  properties
    imageSize
  end
  
  properties (Dependent = true)
    selectedAxis;
    selectedSlice;
  end
  
  properties (Access=protected)
    axSel
    buttons
    sliceSelect
    sliceLabel
  end
  
  methods
    
    function obj = selectXYZSlice(imageSize,varargin)
      % Set up input parsing to make sure the defaults passed to cnlUIObj
      % are appropriate for a cnlSliceControl panel
      p = inputParser;
      p.KeepUnmatched = true;      
      p.addParamValue('labels',{'X' 'Y' 'Z'});         
      parse(p,varargin{:});
      
      % Initialize Superclass
      obj = obj@crlEEG.gui.uipanel(...
                  'units','pixels',...
                  'position',[0 0 330 50],...
                  'title','Slice Selection');
                 
      labels = p.Results.labels;
            
      if numel(labels)~=numel(imageSize)
        error('crlEEG.gui.widger.selectXYZSlice:SizeMismatch',...
          'Number of labels must equal the number of dimensions in imageSize');
      end;
        
      if numel(imageSize)>3, error('imageSize needs to be of dimension 3 or less'); end;
      obj.imageSize = imageSize;
            
      % Draw Button Panel to Control Axis Selection
      obj.axSel = uibuttongroup( 'Parent',obj.panel,'Units','Pixels',...
        'Position', [5 5 100 27],'SelectionChangeFcn',@obj.callback_SelectAxis);
      if length(labels)>=1
      obj.buttons(1) = uicontrol(obj.axSel,'Style','radiobutton',...
        'String', labels{1}, 'Position', [3 0 33 22]);
      end;
      if length(labels)>=2
      obj.buttons(2) = uicontrol(obj.axSel,'Style','radiobutton', ...
        'String', labels{2}, 'Position', [33 0 33 22]);
      end;
      if length(labels)==3
      obj.buttons(3) = uicontrol(obj.axSel,'Style','radiobutton', ...
        'String', labels{3}, 'Position', [63 0 33 22]);
      end;
      set(obj.axSel,'Visible','on')
      
      % Draw Slider for slice selection and text to report current/max slice
      obj.sliceSelect = uicontrol('Style','slider',...
        'Parent', obj.panel, ...
        'Max',obj.imageSize(1),'Min',1,'Value',ceil(obj.imageSize(1)/2),...
        'Callback',@obj.callback_SelectSlice, ...
        'SliderStep',[1/imageSize(1) 10*(1/imageSize(1))],...
        'Position', [115 5 150 22]);
      
      obj.sliceLabel = uicontrol('Style','text',...
        'Parent',obj.panel,...
        'String',[num2str(round(get(obj.sliceSelect,'Value'))) '/' num2str(imageSize(1))],...
        'Position', [265 5 60 22]);

      % Set all units on all objects inside the panel to normalized
      set(obj.axSel,'Units','normalized');
      set(obj.axSel,'FontUnits','normalized');
      set(obj.buttons(1),'Units','normalized');
      set(obj.buttons(1),'FontUnits','normalized');
      set(obj.buttons(2),'Units','normalized');
      set(obj.buttons(2),'FontUnits','normalized');
      set(obj.buttons(3),'Units','normalized');
      set(obj.buttons(3),'FontUnits','normalized');
      set(obj.sliceSelect,'Units','normalized');
      set(obj.sliceLabel,'Units','normalized');
      set(obj.sliceLabel,'FontUnits','normalized');
      
      set(obj.panel,'visible','on');
       
      set(obj.panel,p.Unmatched);
    end;

    %% Callbacks for Axis and Slice Selection
    function callback_SelectSlice(obj,h,EventData)
      % Callback when the slice selection slider is adjusted
      %
      % Note: Not called when manually setting obj.selectedSlice.
      %
      obj.setSliceLabel(obj.selectedSlice);
      notify(obj,'updatedOut');
    end    
    
    function callback_SelectAxis(obj,h,EventData)
     % Callback when the X-Y-Z Radio Buttons Are Changed
     %
     % Note: Not called when manually setting obj.selectedAxis
     %
     obj.setSliceSelRange;     
     notify(obj,'updatedOut');
    end
        
    function set.imageSize(obj,val)
      obj.imageSize = val;      
      obj.setSliceSelRange;      
    end
    
    function setSliceSelRange(obj)
      % Update the range of the slice selection slide
      
      if ishghandle(obj.sliceSelect)
        initialSlice = ceil(obj.imageSize(obj.selectedAxis)/2);
        set(obj.sliceSelect,'Max',obj.imageSize(obj.selectedAxis));
        set(obj.sliceSelect,'Value',initialSlice);
        set(obj.sliceSelect,'SliderStep',...
          [1/obj.imageSize(obj.selectedAxis) 10*(1/obj.imageSize(obj.selectedAxis))]);
        obj.setSliceLabel(initialSlice);
      end;
    end
    
    function setSliceLabel(obj,slice)
      if ishghandle(obj.sliceLabel)
        set(obj.sliceLabel,'String',[num2str(slice) '/' num2str(obj.imageSize(obj.selectedAxis))]);
      end;
    end
       
    %% Get/Set Selected Alice
    function out = get.selectedSlice(obj)
      if ishghandle(obj.sliceSelect)
        out = round(get(obj.sliceSelect,'Value'));
      else % Error catching in case sliceSelect hasn't been defined yet
        out = 1;
      end;
    end
    
    function set.selectedSlice(obj,val)     
      if ~isequal(obj.selectedSlice,val)                
        set(obj.sliceSelect,'Value',val);
        obj.setSliceLabel(obj.selectedSlice);       
        notify(obj,'updatedOut');
      end;
    end
        
    %% Get/Set Selected Axis
    function out = get.selectedAxis(obj)
      switch get(get(obj.axSel,'SelectedObject'),'String')
        case get(obj.buttons(1),'String'), out = 1;
        case get(obj.buttons(2),'String'), out = 2;
        case get(obj.buttons(3),'String'), out = 3;
        otherwise, out = 0;
      end
    end
    
    function set.selectedAxis(obj,val)
      % Set the selected axis and update the uipanel appropriately
      if ishghandle(obj.axSel)
        % Make sure the selected object is consistent
        newSelection = obj.buttons(val);
        
        if ~isequal(get(obj.axSel,'SelectedObject'),newSelection)
          set(obj.axSel,'SelectedObject',newSelection);
                
          % Set slice range, labels, and update the image.
          obj.setSliceSelRange;        
          notify(obj,'updatedOut');
        end;
      end
    end
    

            
  end
end

    
    