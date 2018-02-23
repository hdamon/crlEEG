classdef uipanel < handle & matlab.mixin.SetGet
  % CNLUIOBJ Base class for UI objects in cnlEEG
  %
  % classdef crlEEG.uitools.uipanel < handle
  %
  % cnlUIObj is a basic object class to act as the parent for UI objects that
  % require passing a bunch of figure/parent/panel/axes handles around.
  % This object type just provides a container for these.
  %
  % This is really just a CNL specific wrapper for a uipanel object, since
  % (as best I can find in April 2015) you cannot inherit from uicontrols
  % objects.
  %
  % Recommended usage for child class constructors:
  %
  %       p = inputParser;
  %       p.KeepUnmatched = true;
  %       addParamValue(p,'parent',[]);
  %       addParamValue(p,'origin',[10 10]);
  %       addParamValue(p,'size',[700 700]);
  %       addParamValue(p,'title','');
  %       addParamValue(p,'data',[]);
  %       addParamValue(p,'fhnd',[]);
  %       parse(p,varargin{:});
  %
  %       objOut = objOut@uitools.cnlUIObj('parent',p.Results.parent,...
  %                 'origin',p.Results.origin,'size',p.Results.size,...
  %                 'title',p.Results.title);
  %
  % This way, the inputparser can be used to set default values for a
  % specific child class without having to define them at runtime.
      
  properties (Dependent=true,Hidden=true)
    BorderType
    BorderWidth
    FontAngle
    FontName
    FontSize
    FontUnits
    FontWeight
    ForegroundColor
    HighlightColor
    ShadowColor
    Title
    TitlePosition
    BackgroundColor
    Position
    ResizeFcn
    Units
    BeingDeleted
    Children
    Clipping
    CreateFcn
    DeleteFcn
    BusyAction
    HandleVisibility
    HitTest
    Interruptible
    Parent
    Selected
    SelectionHighlight
    Tag
    Type
    UIContextMenu
    UserData
    Visible
  end
  
  properties (Hidden = true)
    panel
    listenTo = cell(0);
  end;
  
  properties (Hidden = true, Dependent = true)
    normalized;  
  end
  
  events
    updatedOut
  end
  
  methods
    
    function uiObj = uipanel(varargin)
      % CNLUIOBJ Base class for UI objects in cnlEEG
      %
      % function uiObj = cnlUIObj(varargin)
      %      
      uiObj.panel = uipanel(varargin{:});   
      set(uiObj.panel,'DeleteFcn',@(h,evt) uiObj.delete);
    end;
    
    function delete(obj)
      delete(obj.panel);
    end;
        
    function setUnmatched(obj,unmatched)
      % A bit of a hack to make sure that the units field is set first, so
      % resizing of the uipanel works correctly.      
      if isfield(unmatched,'units')
        obj.Units = unmatched.units;
        rmfield(unmatched,'units');
      elseif isfield(unmatched,'Units')
        obj.Units = unmatched.Units;
        rmfield(unmatched,'Units');        
      end
      set(obj,unmatched);      
    end
    
    %% Properties Redirected to the Internal UIPanel 
    function out = get.BorderType(obj)
      out = get(obj.panel,'BorderType');
    end
    
    function set.BorderType(obj,val)
      set(obj.panel,'BorderType',val);
    end
    
    
    function out = get.BorderWidth(obj)
      out = get(obj.panel,'BorderWidth');
    end;

    function set.BorderWidth(obj,val)
      set(obj.panel,'BorderWidth',val);
    end;

    function out = get.FontAngle(obj)
      out = get(obj.panel,'FontAngle');
    end;

    function set.FontAngle(obj,val)
      set(obj.panel,'FontAngle',val);
    end;

    function out = get.FontName(obj)
      out = get(obj.panel,'FontName');
    end;

    function set.FontName(obj,val)
      set(obj.panel,'FontName',val);
    end;

    function out = get.FontSize(obj)
      out = get(obj.panel,'FontSize');
    end;

    function set.FontSize(obj,val)
      set(obj.panel,'FontSize',val);
    end;

    function out = get.FontUnits(obj)
      out = get(obj.panel,'FontUnits');
    end;

    function set.FontUnits(obj,val)
      set(obj.panel,'FontUnits',val);
    end;

    function out = get.FontWeight(obj)
      out = get(obj.panel,'FontWeight');
    end;

    function set.FontWeight(obj,val)
      set(obj.panel,'FontWeight',val);
    end;

    function out = get.ForegroundColor(obj)
      out = get(obj.panel,'ForegroundColor');
    end;

    function set.ForegroundColor(obj,val)
      set(obj.panel,'ForegroundColor',val);
    end;

    function out = get.HighlightColor(obj)
      out = get(obj.panel,'HighlightColor');
    end;

    function set.HighlightColor(obj,val)
      set(obj.panel,'HighlightColor',val);
    end;

    function out = get.ShadowColor(obj)
      out = get(obj.panel,'ShadowColor');
    end;

    function set.ShadowColor(obj,val)
      set(obj.panel,'ShadowColor',val);
    end;

    function out = get.Title(obj)
      out = get(obj.panel,'Title');
    end;

    function set.Title(obj,val)
      set(obj.panel,'Title',val);
    end;

    function out = get.TitlePosition(obj)
      out = get(obj.panel,'TitlePosition');
    end;

    function set.TitlePosition(obj,val)
      set(obj.panel,'TitlePosition',val);
    end;

    function out = get.BackgroundColor(obj)
      out = get(obj.panel,'BackgroundColor');
    end;

    function set.BackgroundColor(obj,val)
      set(obj.panel,'BackgroundColor',val);
    end;

    function out = get.Position(obj)
      out = get(obj.panel,'Position');
    end;

    function set.Position(obj,val)
      set(obj.panel,'Position',val);
    end;

    function out = get.ResizeFcn(obj)
      out = get(obj.panel,'ResizeFcn');
    end;

    function set.ResizeFcn(obj,val)
      set(obj.panel,'ResizeFcn',val);
    end;

    function out = get.Units(obj)
      out = get(obj.panel,'Units');
    end;

    function set.Units(obj,val)
      set(obj.panel,'Units',val);
    end;

    function out = get.BeingDeleted(obj)
      out = get(obj.panel,'BeingDeleted');
    end;

    function set.BeingDeleted(obj,val)
      set(obj.panel,'BeingDeleted',val);
    end;

    function out = get.Children(obj)
      out = get(obj.panel,'Children');
    end;

    function set.Children(obj,val)
      set(obj.panel,'Children',val);
    end;

    function out = get.Clipping(obj)
      out = get(obj.panel,'Clipping');
    end;

    function set.Clipping(obj,val)
      set(obj.panel,'Clipping',val);
    end;

    function out = get.CreateFcn(obj)
      out = get(obj.panel,'CreateFcn');
    end;

    function set.CreateFcn(obj,val)
      set(obj.panel,'CreateFcn',val);
    end;

    function out = get.DeleteFcn(obj)
      out = get(obj.panel,'DeleteFcn');
    end;

    function set.DeleteFcn(obj,val)
      set(obj.panel,'DeleteFcn',val);
    end;

    function out = get.BusyAction(obj)
      out = get(obj.panel,'BusyAction');
    end;

    function set.BusyAction(obj,val)
      set(obj.panel,'BusyAction',val);
    end;

    function out = get.HandleVisibility(obj)
      out = get(obj.panel,'HandleVisibility');
    end;

    function set.HandleVisibility(obj,val)
      set(obj.panel,'HandleVisibility',val);
    end;

    function out = get.HitTest(obj)
      out = get(obj.panel,'HitTest');
    end;

    function set.HitTest(obj,val)
      set(obj.panel,'HitTest',val);
    end;

    function out = get.Interruptible(obj)
      out = get(obj.panel,'Interruptible');
    end;

    function set.Interruptible(obj,val)
      set(obj.panel,'Interruptible',val);
    end;

    function out = get.Parent(obj)
      out = get(obj.panel,'Parent');
    end;

    function set.Parent(obj,val)
      set(obj.panel,'Parent',val);
    end;

    function out = get.Selected(obj)
      out = get(obj.panel,'Selected');
    end;

    function set.Selected(obj,val)
      set(obj.panel,'Selected',val);
    end;

    function out = get.SelectionHighlight(obj)
      out = get(obj.panel,'SelectionHighlight');
    end;

    function set.SelectionHighlight(obj,val)
      set(obj.panel,'SelectionHighlight',val);
    end;

    function out = get.Tag(obj)
      out = get(obj.panel,'Tag');
    end;

    function set.Tag(obj,val)
      set(obj.panel,'Tag',val);
    end;

    function out = get.Type(obj)
      out = get(obj.panel,'Type');
    end;

    function set.Type(obj,val)
      set(obj.panel,'Type',val);
    end;

    function out = get.UIContextMenu(obj)
      out = get(obj.panel,'UIContextMenu');
    end;

    function set.UIContextMenu(obj,val)
      set(obj.panel,'UIContextMenu',val);
    end;

    function out = get.UserData(obj)
      out = get(obj.panel,'UserData');
    end;

    function set.UserData(obj,val)
      set(obj.panel,'UserData',val);
    end;

    function out = get.Visible(obj)
      out = get(obj.panel,'Visible');
    end;

    function set.Visible(obj,val)
      set(obj.panel,'Visible',val);
    end;

%%    
   
    function out = get.normalized(obj)
      if ishandle(obj.panel)
        out = strcmpi(get(obj.panel,'Units'),'normalized');      
      else
        out = [];
      end
    end
    
    function set.normalized(obj,val)      
      if ishandle(obj.panel)        
        if val==true          
          set(obj.panel,'Units','normalized');
          set(obj.panel,'FontUnits','normalized');
        else          
          set(obj.panel,'Units','pixels');
          set(obj.panel,'FontUnits','points');
        end;
      end;
    end
    
  end
  
end
