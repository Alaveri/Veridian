{$I COMPILER.INC}

{
TODO:
TGroupBox
TImage
Taskbar menu

Alt-Tab

Window Arrangement
Screen edge snap
Undo
Redo
Edit menu options

Later:
TMemo?
}

unit Controls;

interface

uses
  AplObj,
  AplApps,
  AplTypes,
  AplConst,
  Drawing,
  MouseDrv,
  Graphics,
  GraphApp,
  Lists,
  Streams,
  Actions,
  KeyDrv,
  Events,
  VeriType,
  VeriCons,
  Colors;

type
  PControl = ^TControl;
  PControlList = ^TControlList;
  PDesktopControlList = ^TDesktopControlList;
  PButtonList = ^TButtonList;
  PDesktop = ^TDesktop;
  PCaptionControl = ^TCaptionControl;
  PActionControl = ^TActionControl;
  PFocusControl = ^TFocusControl;
  PPopUp = ^TPopUp;
  PLabel = ^TLabel;
  PButton = ^TButton;
  PPanel = ^TPanel;
  PContentControl = ^TContentControl;
  PTextControl = ^TTextControl;
  PVisualControl = ^TVisualControl;
  PWrapRenderProc = ^TWrapRenderProc;

  TControlPredicate = function(AItem: PControl): boolean;
  TWrapRenderProc = procedure(AControl: PContentControl; var ARect: TRect;
    const APos: TPoint; AText: PChar; ALength: word; var ACounter: word);

  TControlOption = (
    coClipping,
    coStayOnTop
  );

  TControlOptions = set of TControlOption;

  TControlList = object(TIdentifiableList)
  private
  public
    Owner: PControl;
    constructor Create(AOwner: PControl);
    function GetItemById(const AId: string): PControl;
    function GetItem(AIndex: integer): PControl;
    function Add(AItem: PControl): integer;
    procedure SetItem(AIndex: integer; AItem: PControl);
    procedure Insert(AIndex: integer; AItem: PControl);
    procedure Init; virtual;
  end;

  TDesktopControlList = object(TControlList)
  private
  public
    constructor Create(AOwner: PControl);
  end;

  TButtonList = object(TIdentifiableList)
  private
  public
    function GetItemById(const AId: string): PButton;
    function GetItem(AIndex: integer): PButton;
    function Add(AItem: PButton): integer;
    procedure SetItem(AIndex: integer; AItem: PButton);
    procedure Insert(AIndex: integer; AItem: PButton);
  end;

  TControl = object(TEventObject)
  private
    procedure InternalPaintRegion(ARect: TRect; AExclude: PControl);
  public
    X, Y: integer;
    Width, Height: integer;
    MouseCursor: PMouseCursor;
    Parent: PControl;
    Controls: PControlList;
    Align: TAlign;
    Tag: integer;
    Margins: TSpacing;
    Padding: TSpacing;
    { Defines what the control's bounds are in relation to.  Valid value are:
      rpAbsolute - Bounds are relative to absolute screen coordinates.
      rpParentClient - Bounds are relative to the parent's client area, usually
        the area inside the parents's borders and bevels.
      rpParentContent - Bounds are relative to the parent's content area,
        usually the client area adjusted for additional parent controls such as
        scroll bars.  For views, this is the area that scrolls within the view.
        This is the default value.
      rpParentRelative - Bounds are relative to the parent's bounds, not
        including any borders, bevels, padding or other controls. }
    Position: TRelativePosition;
    Visible: boolean;
    Enabled: boolean;
    OnKeyPress: PKeyEventProc;
    OnMouseDown: PMouseEventProc;
    OnMouseMove: PMouseEventProc;
    OnMouseUp: PMouseEventProc;
    OnMouseClick: PMouseEventProc;
    OnMouseDoubleClick: PMouseEventProc;
    OnMouseEnter: PMouseEventProc;
    OnMouseLeave: PMouseEventProc;
    OnMouseWheelChanged: PMouseEventProc;
    OnDragStart: PMouseEventProc;
    OnDragMove: PMouseEventProc;
    OnDragEnd: PMouseEventProc;
    OnEnter: PEventProc;
    OnExit: PEventProc;
    OnRun: PEventProc;
    ControlOptions: TControlOptions;
    destructor Free; virtual;
    function BorderWidth: byte; virtual;
    function BevelWidth: byte; virtual;
    function OuterWidth: byte;
    function SpacingWidth: integer;
    function SpacingHeight: integer;
    function CreateControlList: PControlList; virtual;
    function GetSize: word;
    function ScaleX(APercent: real): integer;
    function ScaleY(APercent: real): integer;
    function FindControl(const AId: string): PControl;
    function ContainsControl(AControl: PControl): boolean;
    function FindControlThat(AFunc: TControlPredicate): PControl;
    function BringToFront: boolean;
    function SendToBack: boolean;
    function CanDrag(var AEvent: TMouseEvent): boolean; virtual;
    function CanUndo: boolean;
    function IsMouseOver: boolean;
    function IsVisible: boolean;
    function IsEnabled: boolean;
    function IsVisibleAndEnabled: boolean;

    function IsActionControl: boolean; virtual;
    function IsFocusControl: boolean; virtual;
    function IsView: boolean; virtual;
    function IsWindow: boolean; virtual;
    function IsDesktop: boolean; virtual;
    function IsContentControl: boolean; virtual;
    function IsTextControl: boolean; virtual;
    function IsDialogButton: boolean; virtual;
    function IsButton: boolean; virtual;
    function IsVisualControl: boolean; virtual;
    function IsTaskButton: boolean; virtual;
    function IsMenuItemContainer: boolean; virtual;
    function IsMenuItem: boolean; virtual;
    function IsMainMenuItem: boolean; virtual;
    function IsCheckBox: boolean; virtual;
    function IsRadioButton: boolean; virtual;

    { Returns X position of the control's client area.  This is usually the area
      inside the control's borders, bevels, padding, etc. }
    function ClientX: integer; virtual;
    { Returns Y position of the control's client area.  This is usually the area
      inside the control's borders, bevels, padding, etc. }
    function ClientY: integer; virtual;
    { Returns width of the control's client area.  This is usually the area
      inside the control's borders, bevels, padding, etc. }
    function ClientWidth: integer; virtual;
    { Returns height of the control's client area.  This is usually the area
      inside the control's borders, bevels, padding, etc. }
    function ClientHeight: integer; virtual;
    { Returns X position of the control's content area.  This is usually the
      area inside the control's borders, bevels, padding, etc, adjusted for
      other controls such as scroll bars. }
    function ContentX: integer; virtual;
    { Returns Y position of the control's content area.  This is usually the
      area inside the control's borders, bevels, padding, etc, adjusted for
      other controls such as scroll bars. }
    function ContentY: integer; virtual;
    { Returns the X offset of the control's content area.  For Views, this
      is defined by the View's scroll position. }
    function ContentOffsetX: integer; virtual;
    { Returns the Y offset of the control's content area.  For Views, this
      is defined by the View's scroll position. }
    function ContentOffsetY: integer; virtual;
    { Returns width of the control's content area.  This is usually the area
      inside the control's borders, bevels, padding, etc, adjusted for other
      controls such as scroll bars. }
    function ContentWidth: integer; virtual;
    { Returns height of the control's content area.  This is usually the area
      inside the control's borders, bevels, padding, etc, adjusted for other
      controls such as scroll bars. }
    function ContentHeight: integer; virtual;
    { Returns the X position of the control in absolute screen coordinates. }
    function ScreenX: integer;
    { Returns the Y position of the control in absolute screen coordinates. }
    function ScreenY: integer;
    { Returns the X position of the control based on the control's Position
      value. }
    function CalculatedX: integer;
    { Returns the Y position of the control based on the control's Position
      value. }
    function CalculatedY: integer;
    { Gets a rectangle set to the control's X, Y, Width, and Height values. }
    procedure GetBounds(var ARect: TRect);
    { Gets the bounds of the control based on the control's Position value. }
    procedure GetCalculatedBounds(var ARect: TRect);
    { Gets the area defined as the client area of the control.  This is usually
      the area inside the control's borders, bevels, padding, etc. }
    procedure GetClientRect(var ARect: TRect);
    { Gets the area defined as the content area of the control.  This is usually
      the client area adjusted for other parent controls such as scroll bars. }
    procedure GetContentRect(var ARect: TRect);
    { Gets the content area of the control in absolute screen coordinates. }
    procedure GetContentScreenRect(var ARect: TRect);
    { Gets the content area of the control in absolute screen coordinates,
      adjusted by the control's ContentOffsetX and Y.  For Views, the offsets
      are set based on the View's scroll position. }
    procedure GetContentDrawRect(var ARect: TRect);
    { Equivalent to GetClientRect in absolute screen coordinates. }
    procedure GetClientScreenRect(var ARect: TRect);
    { Gets the area of the screen that the control occupies. }
    procedure GetScreenBounds(var ARect: TRect);
    { Gets the clipping area of the control in screen coordinates. If clipping
      is enabled in the control's ControlOptions, then the graphics viewport is
      set to this value automatically in BeginDrawing. }
    procedure GetClipRect(var ARect: TRect);
    { Gets the area of the screen that the control occupies, adjusted by the
      control's ContentOffsetX and Y.  This area is passed into the Paint method
      when the control's Draw or DrawControl method is called, with the graphics
      viewport set to the value of GetClipRect. }
    procedure GetDrawRect(var ARect: TRect);
    { Adjusts the specified rectangle by a control's ContentOffsetX and Y, and
      by the offsets of any parent controls that have a Position value of
      rpParentContent. }
    constructor Create(AId: string);
    constructor CreateParent(AId: string; AParent: PControl);
    procedure OffsetRect(AControl: PControl; var ARect: TRect);
    procedure KeyPress(var AEvent: TKeyEvent); virtual;
    procedure MouseDown(var AEvent: TMouseEvent); virtual;
    procedure MouseUp(var AEvent: TMouseEvent); virtual;
    procedure MouseMove(var AEvent: TMouseEvent); virtual;
    procedure MouseEnter(var AEvent: TMouseEvent); virtual;
    procedure MouseLeave(var AEvent: TMouseEvent); virtual;
    procedure MouseClick(var AEvent: TMouseEvent); virtual;
    procedure MouseDoubleClick(var AEvent: TMouseEvent); virtual;
    procedure MouseWheelChanged(var AEvent: TMouseEvent); virtual;
    procedure DragStart(var AEvent: TDragEvent); virtual;
    procedure DragMove(var AEvent: TDragEvent); virtual;
    procedure DragEnd(var AEvent: TDragEvent); virtual;
    procedure Init; virtual;
    procedure Layout; virtual;
    procedure AlignControl;
    procedure SetWidthHeight(AWidth, AHeight: word); virtual;
    procedure SetWidth(AWidth: word); virtual;
    procedure SetHeight(AHeight: word); virtual;
    procedure SetBounds(APX, APY: integer; AWidth, AHeight: integer); virtual;
    procedure SetBoundsRect(var ARect: TRect); virtual;
    procedure SetSize(AWidth, AHeight: integer); virtual;
    procedure SetXY(APX, APY: integer); virtual;
    procedure SetEnabled(AEnabled: boolean); virtual;
    procedure SetStayOnTop(AStayOnTop: boolean);
    procedure DrawControl(ADrawControls: boolean); virtual;
    procedure Draw; virtual;
    procedure DrawSelf;
    procedure DrawDoubleBuffered;
    procedure DrawControls; virtual;
    procedure Hide; virtual;
    procedure HideEx(var AStart, AEnd: TRect); virtual;
    procedure Show; virtual;
    procedure Run; virtual;
    procedure BeginDrawing; virtual;
    procedure EndDrawing; virtual;
    procedure Paint(ARect: TRect); virtual;
    procedure PaintRegion(var ARect: TRect; AExclude: PControl); virtual;
  end;

  TVisualControl = object(TControl)
  private
  public
    ForeColor: byte;
    BackColor: byte;
    FillPattern: PFillPattern;
    LinePattern: PLinePattern;
    Font: PFont;
    function IsVisualControl: boolean; virtual;
    procedure Init; virtual;
    procedure SetForeColor(AForeColor: byte);
    procedure SetBackColor(ABackColor: byte);
    procedure SetFillPattern(AFillPattern: PFillPattern);
    procedure SetLinePattern(ALinePattern: PLinePattern);
  end;

  TPanel = object(TVisualControl)
  private
  public
    TransparentBack: boolean;
    BorderColor: byte;
    BorderStyle: TBorderStyle;
    BevelStyle: TBevelStyle;
    ShadowColor: byte;
    LightColor: byte;
    function BorderWidth: byte; virtual;
    function BevelWidth: byte; virtual;
    procedure Init; virtual;
    procedure SetBorderColor(AColor: byte);
    procedure SetBorderStyle(AStyle: TBorderStyle);
    procedure Paint(ARect: TRect); virtual;
  end;

  TContentControl = object(TPanel)
  private
  public
    HorzAlign: THorzAlign;
    VertAlign: TVertAlign;
    AutoSize: boolean;
    function IsContentControl: boolean; virtual;
    procedure GetAlign(var ABounds: TRect; var ASize: TSize;
      var AResult: TPoint);
    procedure Init; virtual;
    procedure Layout; virtual;
    procedure SetHorzAlign(AHorzAlign: THorzAlign);
    procedure SetVertAlign(AVertAlign: TVertAlign);
    procedure SetAutoSize(AAutoSize: boolean);
    procedure SetXY(APX, APY: integer); virtual;
  end;

  TCaptionControl = object(TContentControl)
  private
    procedure RenderWrappedText(var ARect: TRect; AText: PChar;
      var ACounter: word; ARenderProc: TWrapRenderProc);
  public
    Caption: PChar;
    Wrap: boolean;
    VertSpacing: byte;
    constructor CreateCaption(const AId, ACaption: string; AParent: PControl);
    function ContentHeight: integer; virtual;
    function ContentWidth: integer; virtual;
    procedure Init; virtual;
    procedure Paint(ARect: TRect); virtual;
    procedure SetCaption(ACaption: string);
    procedure SetWrap(AWrap: boolean);
    procedure GetTextAlign(var ABounds: TRect; var AResult: TPoint);
    function TrueTextWidth(const AText: string): integer;
    function GetCaption: string; virtual;
    function LineCount: word;
    function MaxLineWidth: word;
    destructor Free; virtual;
  end;

  TActionControl = object(TCaptionControl)
  private
  public
    Action: PAction;
    ShowShortcut: boolean;
    ShortcutDisplayName: PChar;
    Shortcut: word;
    ShortcutColor: byte;
    ShortcutSpacing: integer;
    DisabledColor, DisabledBackColor: byte;
    constructor CreateId(AId: string; AAction: PAction);
    constructor CreateParent(AId: string; AAction: PAction; AParent: PControl);
    destructor Free; virtual;
    procedure Init; virtual;
    procedure Paint(ARect: TRect); virtual;
    procedure Enable;
    procedure Disable;
    function ContentWidth: integer; virtual;
    function ContentHeight: integer; virtual;
    function GetAltHotKey: word; virtual;
    function GetHotKey: word; virtual;
    function IsActionControl: boolean; virtual;
    function GetCaption: string; virtual;
    function GetShortcut: word; virtual;
    function GetShortcutDesc: string; virtual;
    procedure SetAction(AAction: PAction);
    procedure SetForeColorEnabled(AColor: byte);
  end;

  TDesktop = object(TActionControl)
  private
  public
    ActionList: PActionList;
    procedure Init; virtual;
    procedure Layout; virtual;
    function ContentX: integer; virtual;
    function ContentY: integer; virtual;
    function ContentWidth: integer; virtual;
    function ContentHeight: integer; virtual;
    function CreateControlList: PControlList; virtual;
    function IsDesktop: boolean; virtual;
    destructor Free; virtual;
  end;

  TFocusControl = object(TActionControl)
  private
    FCursorX: integer;
    FCursorY: integer;
  public
    UsesCursor: boolean;
    AcceptsTab: boolean;
    AcceptsEnter: boolean;
    FocusedColor, FocusedBackColor: byte;
    FocusRectColor: byte;
    FocusRectWidth: byte;
    CanFocus: boolean;
    TabOrder: integer;
    constructor CreateId(AId: string);
    constructor CreateParent(AId: string; AParent: PControl);
    function CursorX: integer;
    function CursorY: integer;
    function Focused: boolean;
    function IsFocusControl: boolean; virtual;
    procedure Init; virtual;
    procedure Focus; virtual;
    procedure UnFocus; virtual;
    procedure SetFocus(AFocus, ARedraw: boolean); virtual;
    procedure MouseDown(var AEvent: TMouseEvent); virtual;
    procedure Paint(ARect: TRect); virtual;
  end;

  TPopUp = object(TPanel)
  private
    FBackBuffer: PMemoryStream;
  public
    procedure Init; virtual;
    procedure Show; virtual;
    procedure Hide; virtual;
    destructor Free; virtual;
  end;

  TLabel = Object(TCaptionControl)
  private
  public
    procedure Init; virtual;
    procedure Paint(ARect: TRect); virtual;
    procedure Clear; virtual;
    procedure Layout; virtual;
    destructor Free; virtual;
  end;

  TButton = object(TFocusControl)
  private
  public
    Down: boolean;
    Toggle: boolean;
    DownBackColor: byte;
    HighlightColor: byte;
    Clickable: boolean;
    function IsButton: boolean; virtual;
    procedure Init; virtual;
    procedure Paint(ARect: TRect); virtual;
    procedure Draw; virtual;
    procedure MouseDown(var AEvent: TMouseEvent); virtual;
    procedure MouseClick(var AEvent: TMouseEvent); virtual;
    procedure MouseEnter(var AEvent: TMouseEvent); virtual;
    procedure MouseLeave(var AEvent: TMouseEvent); virtual;
  end;

  TTextControl = object(TFocusControl)
  private
  public
    Text: PChar;
    TextAlign: THorzAlign;
    HighlightColor: byte;
    TextOffsetX: shortint;
    TextOffsetY: shortint;
    constructor CreateText(const AId, AText: string; AParent: PControl);
    destructor Free; virtual;
    function GetText: string; virtual;
    function GetCursorForeColor: byte; virtual;
    function GetCursorBackColor: byte; virtual;
    function IsTextControl: boolean; virtual;
    procedure GetCursorRect(var ARect: TRect); virtual;
    procedure Init; virtual;
    procedure SetText(const AText: string); virtual;
    procedure Paint(ARect: TRect); virtual;
  end;

var
  Desktop: PDesktop;

implementation

uses
  AplStr,
  AplUtils,
  Veridian,
  Gr8Drv,
  Strings;

function TControl.IsVisualControl: boolean;
begin
  IsVisualControl := false;
end;

function TControl.IsMenuItemContainer: boolean;
begin
  IsMenuItemContainer := false;
end;

function TControl.IsMenuItem: boolean;
begin
  IsMenuItem := false;
end;

function TControl.IsMainMenuItem: boolean;
begin
  IsMainMenuItem := false;
end;

function TControl.IsCheckBox: boolean;
begin
  IsCheckBox := false;
end;

function TControl.IsRadioButton: boolean;
begin
  IsRadioButton := false;
end;

function TControl.IsTaskButton: boolean;
begin
  IsTaskButton := false;
end;

function TControl.IsButton: boolean;
begin
  IsButton := false;
end;

function TControl.IsActionControl: boolean;
begin
  IsActionControl := false;
end;

function TControl.IsFocusControl: boolean;
begin
  IsFocusControl := false;
end;

function TControl.IsTextControl: boolean;
begin
  IsTextControl := false;
end;

function TControl.IsDialogButton: boolean;
begin
  IsDialogButton := false;
end;

function TControl.IsView: boolean;
begin
  IsView := false;
end;

function TControl.IsWindow: boolean;
begin
  IsWindow := false;
end;

function TControl.IsDesktop: boolean;
begin
  IsDesktop := false;
end;

function TControl.IsContentControl: boolean;
begin
  IsContentControl := false;
end;

constructor TControl.Create(AId: string);
begin
  inherited CreateId(AId);
end;

constructor TControl.CreateParent(AId: string; AParent: PControl);
begin
  inherited CreateId(AId);
  Parent := AParent;
  if Assigned(Parent) then
    AParent^.Controls^.Add(@self);
end;

procedure TControl.OffsetRect(AControl: PControl; var ARect: TRect);
begin
  if Assigned(AControl^.Parent) then begin
    if AControl^.Position = rpParentContent then
      ARect.Translate(AControl^.Parent^.ContentOffsetX, AControl^.Parent^.ContentOffsetY);
    OffsetRect(AControl^.Parent, ARect);
  end;
end;

function TControl.IsMouseOver: boolean;
begin
  IsMouseOver := VeridianApp^.MouseOverControl = @self;
end;

function TControl.IsEnabled: boolean;
var
  parentControl: PControl;
  result: boolean;
  function ControlEnabled(AControl: PControl): boolean;
  var
    actionControl: PActionControl;
  begin
    ControlEnabled := AControl^.Enabled;
    if not AControl^.IsActionControl then
      exit;
    actionControl := PActionControl(AControl);
    if Assigned(actionControl^.Action) then
      ControlEnabled := actionControl^.Action^.Enabled;
  end;
begin
  IsEnabled := false;
  result := ControlEnabled(@self);
  if result and (VeridianApp^.ActiveDialog = @self) then begin
    IsEnabled := true;
    exit;
  end;

  parentControl := Parent;
  while Assigned(parentControl) do begin
    if Assigned(VeridianApp^.ActiveDialog) and (parentControl = PControl(VeridianApp^.ActiveDialog)) then
      break;
    if not ControlEnabled(parentControl) then begin
      result := false;
      break;
    end;
    parentControl := parentControl^.Parent;
  end;
  IsEnabled := result;
end;


function TControl.IsVisibleAndEnabled: boolean;
begin
  IsVisibleAndEnabled := IsVisible and IsEnabled;
end;

function TControl.IsVisible: boolean;
var
  par: PControl;
begin
  IsVisible := Visible;
  if not Visible then
    exit;
  par := Parent;
  while Assigned(par) do begin
    if not par^.Visible then begin
      IsVisible := false;
      exit;
    end;
    par := par^.Parent;
  end;
end;

function TControl.CanDrag(var AEvent: TMouseEvent): boolean;
begin
  CanDrag := false;
end;

function TControl.CanUndo: boolean;
begin
  CanUndo := false;
end;

function TControl.ContentX: integer;
var
  result: integer;
begin
  result := ClientX;
  ContentX := result;
end;

function TControl.ContentY: integer;
var
  result: integer;
begin
  result := ClientY;
  ContentY := result;
end;

function TControl.ContentWidth: integer;
begin
  ContentWidth := ClientWidth;
end;

function TControl.ContentHeight: integer;
begin
  ContentHeight := ClientHeight;
end;

procedure TControl.GetBounds(var ARect: TRect);
begin
  ARect.CreateDims(X, Y, Width, Height);
end;

procedure TControl.GetCalculatedBounds(var ARect: TRect);
begin
  ARect.CreateDims(CalculatedX, CalculatedY, Width, Height);
end;

procedure TControl.GetClientRect(var ARect: TRect);
begin
  ARect.CreateDims(ClientX, ClientY, ClientWidth, ClientHeight);
end;

procedure TControl.GetContentRect(var ARect: TRect);
begin
  ARect.CreateDims(ContentX, ContentY, ContentWidth, ContentHeight);
end;

procedure TControl.GetContentScreenRect(var ARect: TRect);
begin
  GetContentRect(ARect);
  ARect.Translate(ScreenX, ScreenY);
end;

procedure TControl.GetClientScreenRect(var ARect: TRect);
begin
  GetClientRect(ARect);
  ARect.Translate(ScreenX, ScreenY);
end;

function TControl.ScreenX: integer;
var
  result: integer;
begin
  result := CalculatedX;
  ScreenX := result;
  if Position = rpAbsolute then
    exit;
  if not Assigned(Parent) then
    exit;
  Inc(result, Parent^.ScreenX);
  ScreenX := result;
end;

function TControl.ScreenY: integer;
var
  result: integer;
begin
  result := CalculatedY;
  ScreenY := result;
  if Position = rpAbsolute then
    exit;
  if not Assigned(Parent) then
    exit;
  Inc(result, Parent^.ScreenY);
  ScreenY := result;
end;

function TControl.ContentOffsetX: integer;
begin
  ContentOffsetX := 0;
end;

function TControl.ContentOffsetY: integer;
begin
  ContentOffsetY := 0;
end;

procedure TControl.GetScreenBounds(var ARect: TRect);
begin
  ARect.CreateDims(ScreenX, ScreenY, Width, Height);
end;

procedure TControl.GetContentDrawRect(var ARect: TRect);
begin
  GetContentScreenRect(ARect);
  OffsetRect(@self, ARect);
end;

procedure TControl.GetDrawRect(var ARect: TRect);
begin
  GetScreenBounds(ARect);
  OffsetRect(@self, ARect);
end;

procedure TControl.GetClipRect(var ARect: TRect);
var
  parentRect: TRect;
  par: PControl;
  current: PControl;
begin
  GetDrawRect(ARect);
  if not Assigned(Parent) then
    exit;
  case Position of
    rpParentContent: Parent^.GetContentScreenRect(parentRect);
    rpParentClient: Parent^.GetClientScreenRect(parentRect);
    rpParentRelative: Parent^.GetScreenBounds(parentRect);
    rpAbsolute: exit;
  end;
  Parent^.OffsetRect(Parent, parentRect);
  ARect.Intersect(parentRect);
  par := Parent;
  while Assigned(par) do begin
    par^.GetClipRect(parentRect);
    ARect.Intersect(parentRect);
    if par^.Position = rpAbsolute then
      break;
    par := par^.Parent;
  end;
end;

procedure TControl.Init;
begin
  inherited Init;
  Parent := nil;
  Controls := CreateControlList;
  X := 0;
  Y := 0;
  Width := 0;
  Height := 0;
  Include(ControlOptions, coClipping);
  Visible := true;
  Enabled := true;
  Align := alNone;
  Position := rpParentContent;
  Margins.Create;
  Padding.Create;
  Tag := 0;
  ControlOptions := [coClipping];
  OnDragEnd := nil;
  OnDragMove := nil;
  OnDragStart := nil;
  OnEnter := nil;
  OnExit := nil;
  OnKeyPress := nil;
  OnMouseDown := nil;
  OnMouseMove := nil;
  OnMouseUp := nil;
  OnMouseDown := nil;
  OnMouseClick := nil;
  OnMouseDoubleClick := nil;
  OnMouseEnter := nil;
  OnMouseLeave := nil;
  OnMouseWheelChanged := nil;
  OnEnter := nil;
  OnExit := nil;
  OnRun := nil;
  MouseCursor := VeridianApp^.MouseCursors^.GetItemById('Default');
end;

function TControl.CreateControlList: PControlList;
begin
  CreateControlList := New(PControlList, Create(@Self));
end;

procedure TControl.SetWidthHeight(AWidth, AHeight: word);
begin
  Width := AWidth;
  Height := AHeight;
  Draw;
end;

procedure TControl.SetWidth(AWidth: word);
begin
  Width := AWidth;
  Draw;
end;

procedure TControl.SetHeight(AHeight: word);
begin
  Height := AHeight;
  Draw;
end;

procedure TControl.Hide;
var
  rect, empty: TRect;
begin
  GetDrawRect(rect);
  empty.Create;
  HideEx(rect, empty);
end;

{ Hides only areas that are not intersected by AStart and AEnd. }
procedure TControl.HideEx(var AStart, AEnd: TRect);
var
  partialRect, rect: TRect;
  var sx, sy, ex, ey: integer;
  var sw, sh, ew, eh: integer;
  var sr, sb, er, eb: integer;
begin
  if not IsVisible then
    exit;
  Visible := false;
  if not Assigned(Parent) then
    exit;
  Desktop^.BeginDrawing;
  VeridianApp^.CursorOff;
  sx := AStart.X; sy := AStart.Y; ex := AEnd.X; ey := AEnd.Y;
  sw := AStart.Width; sh := AStart.Height; ew := AEnd.Width; eh := AEnd.Height;
  sr := AStart.Right; sb := AStart.Bottom; er := AEnd.Right; eb := AEnd.Bottom;

  if not AStart.IntersectsRect(AEnd) then
    Desktop^.PaintRegion(AStart, @self)
  else begin
    if (sw = ew) and (sh = eh) then begin
      { Moved }
      if (ex >= sx) and (ey >= sy) then begin
        { Increased X and Y }
        partialRect.CreateDims(sx, sy, sw, ey - sy);
        Desktop^.PaintRegion(partialRect, @self);
        partialRect.SetDims(sx, ey, ex - sx, sh);
        Desktop^.PaintRegion(partialRect, @self);
      end
      else if (ex <= sx) and (ey <= sy) then begin
        { Decreased X and Y }
        partialRect.CreateDims(er + 1, sy, sx - ex, sh);
        Desktop^.PaintRegion(partialRect, @self);
        partialRect.SetDims(sx, eb + 1, sw, sy - ey + 1);
        Desktop^.PaintRegion(partialRect, @self);
      end
      else if (ex >= sx) and (ey <= sy) then begin
        { Increased X and Decreased Y }
        partialRect.CreateDims(sx, eb + 1, sw, sy - ey);
        Desktop^.PaintRegion(partialRect, @self);
        partialRect.SetDims(sx, sy, ex - sx, sh - ey + sy);
        Desktop^.PaintRegion(partialRect, @self);
      end
      else if (ex <= sx) and (ey >= sy) then begin
        { Decreased X and Increased Y }
        partialRect.CreateDims(sx, sy, sw, ey - sy);
        Desktop^.PaintRegion(partialRect, @self);
        partialRect.SetDims(er + 1, sy, sx - ex, sh);
        Desktop^.PaintRegion(partialRect, @self);
      end;
    end
    else if (sx = ex) and (sy = ey) then begin
      { Resized Right, Bottom Right, or Bottom }
      if (ew < sw) and (eh < sh) then begin
        { Decreased Width and Height }
        partialRect.CreateDims(er + 1, sy, sr - er, sh);
        Desktop^.PaintRegion(partialRect, @self);
        partialRect.SetDims(sx, eb + 1, sw - (sw - ew), sh - eh);
        Desktop^.PaintRegion(partialRect, @self);
      end
      else if (ew < sw) then begin
        { Decreased Width }
        partialRect.CreateDims(er + 1, sy, sr - er, sh);
        Desktop^.PaintRegion(partialRect, @self);
      end
      else if (eh < sh) then begin
        { Decreased Height }
        partialRect.CreateDims(sx, eb + 1, sw, sb - eb);
        Desktop^.PaintRegion(partialRect, @self);
      end
    end
    else begin
      { Resized remaining cases }
      if ex > sx then begin
        { Resized left, top left, or bottom left }
        if (ey = sy) and (sh = eh) then begin
          { Resized Left }
          partialRect.CreateDims(sx, sy, ex - sx, sh);
          Desktop^.PaintRegion(partialRect, @self);
        end
        else if ey > sy then begin
          { Resized Top Left }
          partialRect.CreateDims(sx, sy, sw, ey - sy);
          Desktop^.PaintRegion(partialRect, @self);
          partialRect.SetDims(sx, sy + (ey - sy), ex - sx, eh);
          Desktop^.PaintRegion(partialRect, @self);
        end
        else if eb < sb then begin
          { Resized Bottom Left }
          partialRect.CreateDims(sx, sy, ex - sx, sh);
          Desktop^.PaintRegion(partialRect, @self);
          partialRect.SetDims(ex, eb + 1, ew, sb - eb);
          Desktop^.PaintRegion(partialRect, @self);
        end
      end
      else if ex = sx then begin
        if (ey > sy) and (er < sr) then begin
          { Resized Top Right }
          partialRect.CreateDims(sx, sy, sw, ey - sy);
          Desktop^.PaintRegion(partialRect, @self);
          partialRect.SetDims(er + 1, ey, sr - er, sh - (ey - sy));
          Desktop^.PaintRegion(partialRect, @self);
        end
        else begin
          { Resized Top }
          partialRect.CreateDims(sx, sy, sw, ey - sy);
          Desktop^.PaintRegion(partialRect, @self);
        end;
      end;
    end;
  end;
  Desktop^.EndDrawing;
end;

procedure TControl.Show;
begin
  if IsVisible then
    exit;
  Visible := true;
  Draw;
end;

procedure TControl.AlignControl;
var
  rect: TRect;
  index: integer;
  selfIndex: integer;
  control: PControl;
  offsetX, offsetY: integer;
begin
  if not Assigned(Parent) then
    exit;
  if Align = alNone then
    exit;
  rect.CreateDims(0, 0, Parent^.ContentWidth, Parent^.ContentHeight);
  selfIndex := Parent^.Controls^.IndexOf(@self);
  offsetX := 0;
  offsetY := 0;
  for index := 0 to selfIndex - 1 do begin
    control := Parent^.Controls^.GetItem(index);
    if (control^.Position <> rpParentContent) or (control = @self)
      or not (control^.IsVisible) then
      continue;
    if (control^.Align = alNone) or ((Align <> alClient) and (control^.Align <> Align)) then
      continue;
    case control^.Align of
      alLeft: Inc(offsetX, control^.Width);
      alRight: Dec(offsetX, control^.Width);
      alTop: Inc(offsetY, control^.Height);
      alBottom: Dec(offsetY, control^.Height);
    end;
  end;
  case Align of
    alLeft: SetBounds(rect.X + offsetX + 1, rect.Y + offsetY + 1,
      Width, rect.Height);
    alRight: SetBounds(rect.Right - Width + offsetX + 1, rect.Y + offsetY,
      Width, rect.Height);
    alTop: SetBounds(rect.X + offsetX + 1, rect.Y + offsetY + 1,
      rect.Width, Height);
    alBottom: SetBounds(rect.X + offsetX + 1, rect.Bottom - Height + offsetY + 1,
      rect.Width, Height);
  end;
  if Align <> alClient then
    exit;
  for index := 0 to Parent^.Controls^.Count - 1 do begin
    control := Parent^.Controls^.GetItem(index);
    if control = @self then
      continue;
    case control^.Align of
      alLeft: begin
        Dec(rect.Width, control^.Width);
        Inc(rect.X, control^.Width);
      end;
      alRight: Dec(rect.Width, control^.Width);
      alTop: begin
        Dec(rect.Height, control^.Height);
        Inc(rect.Y, control^.Height);
      end;
      alBottom: Dec(rect.Height, control^.Height);
    end;
  end;
  SetBoundsRect(rect);
end;

procedure TControl.Layout;
begin
  AlignControl;
end;

function TControl.ScaleX(APercent: real): integer;
begin
  ScaleX := Round(Graph^.Mode^.Width * APercent / 100);
end;

function TControl.ScaleY(APercent: real): integer;
begin
  ScaleY := Round(Graph^.Mode^.Height * APercent / 100);
end;

procedure TControl.DrawControl(ADrawControls: boolean);
var
  rect: TRect;
begin
  if not IsVisible then
    exit;
  Layout;
  if not VeridianApp^.State.DrawEnabled then
    exit;
  BeginDrawing;
  GetDrawRect(rect);
  Paint(rect);
  if ADrawControls then
    DrawControls;
  EndDrawing;
end;

procedure TControl.Draw;
begin
  DrawControl(true);
end;

procedure TControl.DrawSelf;
begin
  DrawControl(false);
end;

procedure TControl.DrawControls;
var
  index: integer;
begin
  for index := 0 to Controls^.Count - 1 do
    Controls^.GetItem(index)^.Draw;
end;

procedure TControl.BeginDrawing;
var
  visualControl: PVisualControl;
begin
  VeridianApp^.PushState;
  Mouse.PushState;
  Graph^.PushState;
  VeridianApp^.HideMouseCursor;
  if IsVisualControl then begin
    visualControl := PVisualControl(@self);
    Graph^.SetForeColor(visualControl^.ForeColor);
    Graph^.SetBackColor(visualControl^.BackColor);
    Graph^.State^.Font := visualControl^.Font;
    if (coClipping in ControlOptions) then
      GetClipRect(Graph^.State^.ViewPort);
  end;
end;

procedure TControl.EndDrawing;
var
  desktopItemRect, rect: TRect;
  cursor: PMouseCursor;
  item: PControl;
  index: integer;
begin
  Graph^.PopState;
  Mouse.PopState;
  VeridianApp^.PopState;
  cursor := VeridianApp^.MouseCursor;
  cursor^.X := Mouse.State.X;
  cursor^.Y := Mouse.State.Y;
  if Mouse.State.Visible then begin
    cursor^.Visible := Mouse.State.Visible;
    VeridianApp^.DrawMouseCursor(Mouse.State);
  end else begin
    cursor^.Visible := false;
  end;
  if PControl(Parent) <> PControl(Desktop) then
    exit;
  if coStayOnTop in ControlOptions then
    exit;
  GetBounds(rect);
  for index := 0 to Desktop^.Controls^.Count - 1 do begin
    item := Desktop^.Controls^.GetItem(index);
    if item = @self then
      continue;
    if not (item^.IsVisible and (coStayOnTop in item^.ControlOptions)) then
      continue;
    item^.GetBounds(desktopItemRect);
    if desktopItemRect.IntersectsRect(rect) then begin
      item^.Draw;
    end;
  end;
end;

procedure TControl.SetStayOnTop(AStayOnTop: boolean);
begin
  if (coStayOnTop in ControlOptions) = AStayOnTop then
    exit;

  if AStayOnTop then begin
    if PControl(Parent) <> PControl(Desktop) then begin
      Parent^.Controls^.RemoveItem(@self);
      Desktop^.Controls^.Add(@self);
      Parent := Desktop;
    end;
    BringToFront;
    Draw
  end
  else begin
    Parent^.Controls^.RemoveItem(@self);
    Parent^.Controls^.Add(@self);
  end;
end;

procedure TVisualControl.Init;
begin
  inherited Init;
  ForeColor := VeridianApp^.Colors.Button;
  BackColor := VeridianApp^.Colors.ButtonBack;
  FillPattern := nil;
  LinePattern := nil;
  Font := VeridianApp^.GetFont('System');
end;

function TVisualControl.IsVisualControl: boolean;
begin
  IsVisualControl := true;
end;

procedure TVisualControl.SetLinePattern(ALinePattern: PLinePattern);
begin
  LinePattern := ALinePattern;
  Draw;
end;

function TControl.GetSize: word;
var
  index: integer;
  control: PControl;
  result: word;
begin
  result := 0;
  for index := 0 to Controls^.Count - 1 do begin
    control := Controls^.GetItem(index);
    Inc(result, SizeOf(control^));
  end;
  Inc(result, SizeOf(self));
  GetSize := result;
end;

function TControl.ContainsControl(AControl: PControl): boolean;
var
  index: integer;
  control: PControl;
begin
  ContainsControl := false;
  for index := 0 to Controls^.Count - 1 do begin
    control := Controls^.GetItem(index);
    if control = AControl then begin
      ContainsControl := true;
      exit;
    end;
    if control^.ContainsControl(AControl) then begin
      ContainsControl := true;
      exit;
    end;
  end;
end;

function TControl.FindControlThat(AFunc: TControlPredicate): PControl;
var
  index: integer;
  control: PControl;
  found: boolean;
begin
  FindControlThat := nil;
  for index := 0 to Controls^.Count - 1 do begin
    control := Controls^.GetItem(index);
    if AFunc(control) then begin
      FindControlThat := control;
      exit;
    end;
  end;
  if AFunc(@self) then
    FindControlThat := @self;
end;

function TControl.FindControl(const AId: string): PControl;
var
  index: integer;
  control: PControl;

begin
  FindControl := nil;
  for index := 0 to Controls^.Count - 1 do begin
    control := Controls^.GetItem(index);
    if StrLIComp(control^.Id, @AId[1], Length(AId)) = 0 then begin
      FindControl := control;
      exit;
    end;
  end;
  if StrLIComp(Id, @AId[1], Length(AId)) = 0 then
    FindControl := control;
end;

function TControl.CalculatedX: integer;
var
  result: integer;
begin
  result := X;
  CalculatedX := result;
  if not Assigned(Parent) then
    exit;
  case Position of
    rpParentContent: Inc(result, Parent^.ContentX);
    rpParentClient: Inc(result, Parent^.ClientX);
    rpAbsolute, rpParentRelative: result := X;
  end;
  Inc(result, Margins.Left);
  CalculatedX := result;
end;

function TControl.ClientX: integer;
begin
  ClientX := Padding.Left + OuterWidth;
end;

function TControl.CalculatedY: integer;
var
  result: integer;
begin
  result := Y;
  CalculatedY := result;
  if not Assigned(Parent) then
    exit;
  case Position of
    rpParentContent: Inc(result, Parent^.ContentY);
    rpParentClient: Inc(result, Parent^.ClientY);
    rpAbsolute, rpParentRelative: result := Y;
  end;
  Inc(result, Margins.Top);
  CalculatedY := result;
end;

function TControl.ClientY: integer;
begin
  ClientY := Padding.Top + OuterWidth;
end;

function TControl.ClientWidth: integer;
begin
  ClientWidth := Width - 2 * OuterWidth - Padding.Width;
end;

function TControl.ClientHeight: integer;
begin
  ClientHeight := Height - 2 * OuterWidth - Padding.Height;
end;

procedure TControl.SetBounds(APX, APY: integer; AWidth, AHeight: integer);
var
  rect: TRect;
begin
  rect.CreateDims(APX, APY, AWidth, AHeight);
  SetBoundsRect(rect);
end;

procedure TControl.SetBoundsRect(var ARect: TRect);
begin
  X := ARect.X;
  Y := ARect.Y;
  Width := ARect.Width;
  Height := ARect.Height;
end;

procedure TControl.SetSize(AWidth, AHeight: integer);
begin
  Width := AWidth;
  Height := AHeight;
end;

procedure TControl.SetXY(APX, APY: integer);
begin
  X := APX;
  Y := APY;
end;

function TControl.SpacingWidth: integer;
begin
  SpacingWidth := Margins.Width + Padding.Width;
end;

function TControl.SpacingHeight: integer;
begin
  SpacingHeight := Margins.Height + Padding.Height;
end;

procedure TControl.Paint;
begin
  if IsVisualControl then begin
    Graph^.State^.Font := PVisualControl(@self)^.Font;
  end;
end;

procedure TControl.DrawDoubleBuffered;
var
  rect: TRect;
begin
  Graph^.PushState;
  Graph^.SetDrawPage(Graph^.OffScreenPage);
  GetDrawRect(rect);
  Draw;
  Graph^.CopyFromOffScreen(rect, rect);
  Graph^.PopState;
end;

procedure TControl.PaintRegion(var ARect: TRect; AExclude: PControl);
var
  clipRect: TRect;
begin
  VeridianApp^.PushState;
  VeridianApp^.CursorOff;
  Graph^.PushState;
  Graph^.SetDrawPage(Graph^.OffScreenPage);
  InternalPaintRegion(ARect, AExclude);
  Graph^.CopyFromOffScreen(ARect, ARect);
  Graph^.PopState;
  VeridianApp^.PopState;
end;

procedure TControl.InternalPaintRegion(ARect: TRect; AExclude: PControl);
var
  index: integer;
  control: PControl;
  rect: TRect;
begin
  if (@self = AExclude) or not IsVisible then
    exit;
  if ARect.IsEmpty then
    exit;

  GetDrawRect(rect);
  if not rect.IntersectsRect(ARect) then
    exit;

  BeginDrawing;
  ARect.Intersect(Graph^.State^.ViewPort);
  Graph^.SetViewPort(ARect);
  Paint(rect);
  EndDrawing;

  for index := 0 to Controls^.Count - 1 do begin
    control := Controls^.GetItem(index);
    control^.InternalPaintRegion(ARect, AExclude);
  end;
end;

function TControl.BorderWidth: byte;
begin
  BorderWidth := 0;
end;

function TControl.BevelWidth: byte;
begin
  BevelWidth := 0;
end;

function TControl.OuterWidth: byte;
begin
  OuterWidth := BorderWidth + BevelWidth;
end;

function TControl.SendToBack: boolean;
begin
  if coStayOnTop in ControlOptions then
    exit;
  SendToBack := false;
  if (Parent = nil) or (Parent^.Controls^.Count < 2) then
    exit;
  if Parent^.Controls^.IndexOf(@self) = 0 then
    exit;
  SendToBack := true;
  Parent^.Controls^.RemoveItem(@self);
  Parent^.Controls^.Insert(0, @self);
end;

function TControl.BringToFront: boolean;
var
  index: integer;
begin
  BringToFront := false;
  if (Parent = nil) or (Parent^.Controls^.Count < 2) then
    exit;
  index := Parent^.Controls^.IndexOf(@self);
  if index = Parent^.Controls^.Count - 1 then
    exit;
  BringToFront := true;
  Parent^.Controls^.RemoveItem(@self);
  Parent^.Controls^.Add(@self);
end;

procedure TControl.KeyPress(var AEvent: TKeyEvent);
begin
  Invoke(OnKeyPress, AEvent);
end;

procedure TControl.MouseDown(var AEvent: TMouseEvent);
begin
  Invoke(OnMouseDown, AEvent);
end;

procedure TControl.MouseUp(var AEvent: TMouseEvent);
begin
  Invoke(OnMouseUp,  AEvent);
end;

procedure TControl.MouseMove(var AEvent: TMouseEvent);
begin
  Invoke(OnMouseMove, AEvent);
end;

procedure TControl.MouseEnter(var AEvent: TMouseEvent);
begin
  Invoke(OnMouseEnter, AEvent);
end;

procedure TControl.MouseLeave(var AEvent: TMouseEvent);
begin
  Invoke(OnMouseLeave, AEvent);
end;

procedure TControl.MouseClick(var AEvent: TMouseEvent);
begin
  Invoke(OnMouseClick, AEvent);
end;

procedure TControl.MouseDoubleClick(var AEvent: TMouseEvent);
begin
  Invoke(OnMouseDoubleClick, AEvent);
end;

procedure TControl.MouseWheelChanged(var AEvent: TMouseEvent);
begin
  Invoke(OnMouseWheelChanged, AEvent);
end;

procedure TControl.DragStart(var AEvent: TDragEvent);
begin
  Invoke(OnDragStart, AEvent);
end;

procedure TControl.DragMove(var AEvent: TDragEvent);
begin
  Invoke(OnDragMove, AEvent);
end;

procedure TControl.DragEnd(var AEvent: TDragEvent);
begin
  Invoke(OnDragEnd, AEvent);
end;

procedure TControl.Run;
var
  event: TEvent;
begin
  event.Create;
  Invoke(OnRun, event);
end;

procedure TControl.SetEnabled(AEnabled: boolean);
begin
  Enabled := AEnabled;
  Draw;
end;

procedure TVisualControl.SetForeColor(AForeColor: byte);
begin
  ForeColor := AForeColor;
  Draw;
end;

procedure TVisualControl.SetBackColor(ABackColor: byte);
begin
  BackColor := ABackColor;
  Draw;
end;

procedure TVisualControl.SetFillPattern(AFillPattern: PFillPattern);
begin
  FillPattern := AFillPattern;
  Draw;
end;

destructor TControl.Free;
begin
  FreeAndNil(Controls);
  inherited Free;
end;

procedure TActionControl.Init;
begin
  inherited Init;
  Action := nil;
  ShowShortcut := true;
  ShortcutDisplayName := nil;
  Shortcut := 0;
  DisabledColor := VeridianApp^.Colors.ButtonDisabled;
  DisabledBackColor := VeridianApp^.Colors.ButtonDisabledBack;
  ShortcutColor := VeridianApp^.Colors.Shortcut;
  ShortcutSpacing := 10;
end;

procedure TContentControl.Init;
begin
  inherited Init;
  HorzAlign := haLeft;
  VertAlign := vaTop;
  AutoSize := false;
end;

procedure TContentControl.Layout;
begin
  if AutoSize then begin
    Width := ContentWidth;
    Height := ContentHeight;
  end;
  inherited Layout;
end;

procedure TContentControl.GetAlign(var ABounds: TRect; var ASize: TSize;
  var AResult: TPoint);
begin
  AResult.Create;
  case HorzAlign of
    haLeft: AResult.X := ABounds.X + Padding.Left;
    haRight: AResult.X := ABounds.Right - ASize.Width - Padding.Right;
    haCenter: AResult.X := ABounds.X + Round((ABounds.Width - ASize.Width) / 2);
  end;
  case VertAlign of
    vaTop: AResult.Y := ABounds.Y + Padding.Top;
    vaBottom: AResult.Y := ABounds.Bottom - ASize.Height - Padding.Bottom;
    vaCenter: AResult.Y := ABounds.Y + Round((ABounds.Height - ASize.Height) div 2);
  end;
end;

function TContentControl.IsContentControl: boolean;
begin
  IsContentControl := true;
end;

procedure TContentControl.SetHorzAlign(AHorzAlign: THorzAlign);
begin
  HorzAlign := AHorzAlign;
  Draw;
end;

procedure TContentControl.SetVertAlign(AVertAlign: TVertAlign);
begin
  VertAlign := AVertAlign;
  Draw;
end;

procedure TContentControl.SetXY(APX, APY: integer);
begin
  inherited SetXY(APX, APY);
end;

procedure TContentControl.SetAutoSize(AAutoSize: boolean);
begin
  AutoSize := AAutoSize;
  Draw;
end;

constructor TActionControl.CreateId(AId: string; AAction: PAction);
begin
  inherited Create(AId);
  Action := AAction;
end;

constructor TActionControl.CreateParent(AId: string; AAction: PAction; AParent: PControl);
begin
  inherited CreateParent(AId, AParent);
  Action := AAction;
end;

destructor TActionControl.Free;
begin
  if VeridianApp^.ActiveControl = @self then
    VeridianApp^.ActiveControl := nil;
  inherited Free;
end;

procedure TActionControl.Enable;
begin
  SetEnabled(true);
end;

procedure TActionControl.Disable;
begin
  SetEnabled(false);
end;

function TActionControl.IsActionControl: boolean;
begin
  IsActionControl := true;
end;

procedure TActionControl.SetAction(AAction: PAction);
begin
  Action := AAction;
  Draw;
end;

function TActionControl.GetCaption: string;
begin
  GetCaption := '';
  if Assigned(Action) then
    GetCaption := TString.GetString(Action^.Text)
  else if Assigned(Caption) then
    GetCaption := TString.GetString(Caption);
end;

function TActionControl.GetShortcutDesc: string;
begin
  GetShortcutDesc := '';
  if GetShortcut = 0 then
    exit;
  GetShortcutDesc := Keyboard.KeyToShortcut(GetShortcut);
end;

function TActionControl.GetShortcut: word;
begin
  GetShortcut := 0;
  if not ShowShortcut then
    exit;
  if Assigned(Action) then
    GetShortcut := Action^.Shortcut
  else
    GetShortcut := Shortcut;
end;

function TActionControl.GetAltHotKey: word;
var
  txt: string;
  index: integer;
begin
  txt := GetCaption;
  for index := 1 to Length(txt) do begin
    if (txt[index] = '&') and (length(txt) >= index + 1) then begin
      GetAltHotKey := Keyboard.CharToAltChar(txt[index + 1]);
      exit;
    end;
  end;
  GetAltHotKey := 0;
end;

function TActionControl.ContentWidth: integer;
begin
  ContentWidth := TcontentControl.ContentWidth;
end;

function TActionControl.ContentHeight: integer;
begin
  ContentHeight := TContentControl.ContentHeight;
end;

function TActionControl.GetHotKey;
var
  txt: string;
  index: integer;
  ch: char;
begin
  txt := GetCaption;
  for index := 1 to Length(txt) do begin
    if (txt[index] = '&') and (length(txt) >= index + 1) then begin
      GetHotKey := Ord(UpCase(txt[index + 1]));
      exit;
    end;
  end;
  GetHotKey := 0;
end;

procedure TActionControl.SetForeColorEnabled(AColor: byte);
begin
  if IsEnabled then
    Graph^.SetForeColor(AColor)
  else
    Graph^.SetForeColor(DisabledColor);
end;

procedure TActionControl.Paint(ARect: TRect);
var
  index: integer;
  txt: string;
  currentForeColor, currentBackColor: byte;
  desc: string;
  ch: char;
  charWidth: integer;
  pos: TPoint;
begin
  if Assigned(Action) then
    VeridianApp^.UpdateActionControl(@self);
  GetTextAlign(ARect, pos);
  currentForeColor := ForeColor;
  currentBackColor := BackColor;
  if not IsEnabled then begin
    currentForeColor := DisabledColor;
    currentBackColor := DisabledBackColor;
  end;
  index := 1;
  TPanel.Paint(ARect);
  Graph^.SetForeColor(currentForeColor);
  Graph^.SetBackColor(currentBackColor);
  txt := GetCaption;
  while index <= Length(txt) do begin
    ch := txt[index];
    Graph^.SetForeColor(currentForeColor);
    Graph^.SetBackColor(currentBackColor);
    if ch = '&' then begin
      Inc(index);
      if index > Length(txt) then
        break;
      ch := txt[index];
      if IsEnabled then begin
        Graph^.SetForeColor(ShortcutColor);
      end;
    end;
    charWidth := Font^.TextWidth(ch);
    Graph^.DrawText(pos.X, pos.Y, ch);
    Inc(pos.X, charWidth);
    Inc(index);
  end;
  Graph^.SetForeColor(currentForeColor);
  if GetShortcut > 0 then begin
    desc := GetShortcutDesc;
    pos.X := ARect.Right - TrueTextWidth(desc) - Margins.Right - OuterWidth;
    Graph^.DrawText(pos.X, pos.Y, desc);
  end;
end;

procedure TButton.Init;
begin
  inherited Init;
  HorzAlign := haCenter;
  VertAlign := vaCenter;
  ForeColor := VeridianApp^.Colors.Button;
  BackColor := VeridianApp^.Colors.ButtonBack;
  ShadowColor := VeridianApp^.Colors.ButtonShadow;
  LightColor := VeridianApp^.Colors.ButtonLight;
  DownBackColor := VeridianApp^.Colors.ButtonDownBack;
  DisabledColor := VeridianApp^.Colors.ButtonDisabled;
  HighlightColor := VeridianApp^.Colors.ButtonHighlight;
  BorderColor := VeridianApp^.Colors.ButtonBorder;
  Down := false;
  BorderStyle := bsSingle;
  BevelStyle := bvRaised;
  Toggle := false;
  Clickable := true;
  FocusRectWidth := 1;
end;

function TButton.IsButton: boolean;
begin
  IsButton := true;
end;

procedure TButton.Draw;
begin
  inherited Draw;
end;

procedure TButton.Paint(ARect: TRect);
var
  oldShadowColor, oldLightColor: byte;
  oldFocusColor, oldFocusedBackColor: byte;
  rect: TRect;
begin
  if not (IsVisible and VeridianApp^.State.DrawEnabled) then
    exit;
  oldShadowColor := ShadowColor;
  oldLightColor := LightColor;
  oldFocusColor := FocusedColor;
  oldFocusedBackColor := FocusedBackColor;
  FocusedColor := ForeColor;
  FocusedBackColor := BackColor;
  if Down then begin
    ShadowColor := oldLightColor;
    LightColor := oldShadowColor;
  end;
  inherited Paint(ARect);
  ShadowColor := oldShadowColor;
  LightColor := oldLightColor;
  FocusedColor := oldFocusColor;
  FocusedBackColor := oldFocusedBackColor;
  if not CanFocus then
    exit;
  if Focused then
    Graph^.SetForeColor(FocusedBackColor)
  else if Assigned(Parent) and Parent^.IsVisualControl then
    Graph^.SetForeColor(PVisualControl(Parent)^.BackColor);
  GetDrawRect(rect);
  rect.Grow(2, 2);
  rect.Translate(-1, -1);
  Graph^.State^.ViewPort := rect;
  Graph^.Rectangle(rect);
end;

procedure TButton.MouseDown(var AEvent: TMouseEvent);
var
  index: word;
  control: PControl;
  button: PButton;
begin
  if not IsVisibleAndEnabled then
    exit;
  if CanFocus then
    Focus;
  if not Clickable then
    exit;
  if bsLeft in AEvent.NewMouseState.ButtonState then
    VeridianApp^.LeftMouseDownControl := @self
  else if bsRight in AEvent.NewMouseState.ButtonState then
    VeridianApp^.RightMouseDownControl := @self;
  Down := true;
  Draw;
  inherited MouseDown(AEvent);
end;

procedure TButton.MouseClick(var AEvent: TMouseEvent);
begin
  if not IsVisibleAndEnabled then
    exit;
  if not Toggle then begin
    Down := false;
    Draw;
  end;
  inherited MouseClick(AEvent);
end;

procedure TButton.MouseEnter(var AEvent: TMouseEvent);
begin
  if not IsVisibleAndEnabled then
    exit;
  if (VeridianApp^.LeftMouseDownControl = @self) and Clickable then begin
    Down := true;
    DrawSelf;
  end;
end;

procedure TButton.MouseLeave(var AEvent: TMouseEvent);
begin
  if not IsVisibleAndEnabled then
    exit;
  if (VeridianApp^.LeftMouseDownControl = @self) and Clickable then begin
    Down := false;
    DrawSelf;
  end;
end;

procedure TLabel.Init;
begin
  inherited Init;
  TransparentBack := true;
  ForeColor := VeridianApp^.Colors.Window;
  BackColor := VeridianApp^.Colors.WindowBack;
  BorderStyle := bsNone;
  HorzAlign := haLeft;
  VertAlign := vaTop;
  AutoSize := true;
  Font := VeridianApp^.GetFont('editor');
end;

procedure TLabel.Paint(ARect: TRect);
begin
  inherited Paint(ARect);
end;

procedure TLabel.Clear;
begin
  SetCaption('');
end;

procedure TLabel.Layout;
begin
  inherited Layout;
end;

destructor TLabel.Free;
begin
  inherited Free;
end;

constructor TControlList.Create(AOwner: PControl);
begin
  inherited Create;
  Owner := AOwner;
end;

function TControlList.GetItemById(const AId: string): PControl;
begin
  GetItemById := PControl(inherited GetItemById(AId));
end;

function TControlList.GetItem(AIndex: integer): PControl;
begin
  GetItem := PControl(inherited GetItem(AIndex));
end;

procedure TControlList.SetItem(AIndex: integer; AItem: PControl);
begin
  inherited SetItem(AIndex, AItem);
end;

function TControlList.Add(AItem: PControl): integer;
begin
  Add := inherited Add(AItem);
  PControl(AItem)^.Parent := Owner;
end;

procedure TControlList.Insert(AIndex: integer; AItem: PControl);
begin
  inherited Insert(AIndex, AItem);
  PControl(AItem)^.Parent := Owner;
end;
procedure TControlList.Init;
begin
  inherited Init;
  Owner := nil;
end;

procedure TPanel.Init;
begin
  inherited Init;
  ForeColor := VeridianApp^.Colors.Window;
  BackColor := VeridianApp^.Colors.WindowBack;
  BorderColor := VeridianApp^.Colors.WindowBorder;
  BorderStyle := bsNone;
  BevelStyle := bvNone;
  ShadowColor := VeridianApp^.Colors.ButtonShadow;
  LightColor := VeridianApp^.Colors.ButtonLight;
  TransParentBack := false;
end;

procedure TPanel.SetBorderColor(AColor: byte);
begin
  BorderColor := AColor;
  Draw;
end;

procedure TPanel.SetBorderStyle(AStyle: TBorderStyle);
begin
  BorderStyle := AStyle;
  Draw;
end;

procedure TPanel.Paint(ARect: TRect);
var
  rect: TRect;
begin
  inherited Paint(ARect);
  rect.CreateRect(ARect);
  Graph^.SetForeColor(ForeColor);
  Graph^.SetBackColor(BackColor);
  Graph^.SetFillPattern(FillPattern);
  Graph^.SetLinePattern(LinePattern);
  if not TransparentBack then
    Graph^.FillRect(rect);
  rect.Translate(1, 1);
  rect.Grow(-2, -2);
  case BevelStyle of
    bvRaised: begin
      Graph^.SetForeColor(ShadowColor);
      Graph^.VLine(rect.Right, rect.Y, rect.Height);
      Graph^.HLine(rect.X, rect.Bottom, rect.Width);
      Graph^.SetForeColor(LightColor);
      Graph^.HLine(rect.X, rect.Y, rect.Width);
      Graph^.VLine(rect.X, rect.Y, rect.Height);
    end;
    bvLowered: begin
      Graph^.SetForeColor(LightColor);
      Graph^.VLine(rect.Right, rect.Y, rect.Height);
      Graph^.HLine(rect.X, rect.Bottom, rect.Width);
      Graph^.SetForeColor(ShadowColor);
      Graph^.HLine(rect.X, rect.Y, rect.Width);
      Graph^.VLine(rect.X, rect.Y, rect.Height);
    end;
  end;
  rect.Translate(-1, -1);
  rect.Grow(2, 2);
  case BorderStyle of
    bsSingle: begin
      Graph^.SetForeColor(BorderColor);
      Graph^.Rectangle(rect);
    end;
  end;
end;

function TPanel.BorderWidth: byte;
var
  result: byte;
begin
  result := 0;
  if BorderStyle <> bsNone then
    Inc(result);
  BorderWidth := result;
end;

function TPanel.BevelWidth: byte;
var
  result: byte;
begin
  result := 0;
  if BevelStyle <> bvNone then
    Inc(result, 1);
  BevelWidth := result;
end;

procedure TDesktop.Init;
begin
  inherited Init;
  Visible := true;
  BorderStyle := bsNone;
  BevelStyle := bvNone;
  ForeColor := VeridianApp^.Colors.Desktop;
  BackColor := VeridianApp^.Colors.DesktopBack;
  ActionList := New(PActionList, Create);
end;

function TDesktop.IsDesktop: boolean;
begin
  IsDesktop := true;
end;

function TDesktop.ContentX: integer;
begin
  ContentX := 0;
end;

function TDesktop.ContentY: integer;
var
  result: integer;
begin
  result := 0;
  if VeridianApp^.MenuBar^.Visible then
    Inc(result, VeridianApp^.MenuBar^.Height);
  ContentY := result;
end;

function TDesktop.ContentWidth: integer;
begin
  ContentWidth := 0;
end;

function TDesktop.ContentHeight: integer;
var
  result: integer;
begin
  result := 0;
  if VeridianApp^.MenuBar^.Visible then
    Dec(result, VeridianApp^.MenuBar^.Height);
  if VeridianApp^.TaskBar^.Visible then
    Dec(result, VeridianApp^.TaskBar^.Height);
  ContentHeight := result;
end;

function TDesktop.CreateControlList: PControlList;
begin
  CreateControlList := New(PDesktopControlList, Create(@self));
end;

procedure TDesktop.Layout;
begin
  inherited Layout;
  SetBounds(0, 0, Graph^.Mode^.Width, Graph^.Mode^.Height);
end;

destructor TDesktop.Free;
begin
  FreeAndNil(ActionList);
  inherited Free;
end;

constructor TCaptionControl.CreateCaption(const AId, ACaption: string; AParent: PControl);
begin
  inherited CreateParent(AId, AParent);
  Caption := TString.New(ACaption);
  Layout;
end;

procedure TCaptionControl.SetCaption(ACaption: string);
var
  wasVisible: boolean;
begin
  wasVisible := IsVisible;
  Hide;
  TString.AssignString(Caption, ACaption);
  if wasVisible then
    Show;
end;

procedure TCaptionControl.SetWrap(AWrap: boolean);
begin
  Wrap := AWrap;
  Draw;
end;

function TCaptionControl.ContentWidth: integer;
begin
  ContentWidth := inherited ContentWidth;
  if AutoSize then
    ContentWidth := Font^.TextWidth(GetCaption) + SpacingWidth;
end;

function TCaptionControl.ContentHeight: integer;
begin
  if AutoSize then
    ContentHeight := Font^.Height;
end;

function TCaptionControl.GetCaption: string;
begin
  GetCaption := '';
  if Assigned(Caption) then
    GetCaption := TString.GetString(Caption);
end;

function TCaptionControl.TrueTextWidth(const AText: string): integer;
var
  index: integer;
  len: word;
  ch: char;
  currentWidth: integer;
begin
  TrueTextWidth := 0;
  len := Length(AText);
  if len = 0 then
    exit;
  currentWidth := 0;
  index := 1;
  while index <= len do begin
    ch := AText[index];
    Inc(index);
    if (ch = '&') then
      continue;
    Inc(currentWidth, Font^.TextWidth(ch));
  end;
  TrueTextWidth := currentWidth;
end;

procedure TCaptionControl.GetTextAlign(var ABounds: TRect; var AResult: TPoint);
var
  textWidth: integer;
  txt: string;
  size: TSize;
begin
  txt := GetCaption;
  size.CreateDims(TrueTextWidth(txt) - Font^.Spacing, Font^.Height);
  GetAlign(ABounds, size, AResult);
end;

procedure TCaptionControl.Init;
begin
  inherited Init;
  Caption := nil;
  Wrap := false;
  VertSpacing := 2;
end;

procedure PaintWrappedLine(AControl: PContentControl; var ARect: TRect;
  const APos: TPoint; AText: PChar; ALength: word; var ACounter: word); far;
var
  pos: TPoint;
  size: TSize;
  index: integer;
begin
  size.CreateDims(0, AControl^.Font^.Height);
  for index := 0 to ALength - 1 do
    Inc(size.Width, AControl^.Font^.TextWidth(AText[index]));
  AControl^.GetAlign(ARect, size, pos);
  Graph^.RenderText(APos.X + pos.X, APos.Y + pos.Y, ALength, AText);
  Inc(ACounter);
end;

procedure CountWrappedLine(AControl: PContentControl; var ARect: TRect;
  const APos: TPoint; AText: PChar; ALength: word; var ACounter: word); far;
begin
  Inc(ACounter);
end;

procedure GetWrappedLineWidth(AControl: PContentControl; var ARect: TRect;
  const APos: TPoint; AText: PChar; ALength: word; var ACounter: word); far;
var
  width: word;
begin
  width := AControl^.Font^.TextWidthAny(AText, ALength);
  if width > ACounter then
    ACounter := width;
end;

function TCaptionControl.LineCount: word;
var
  result: word;
  rect: TRect;
begin
  result := 0;
  GetDrawRect(rect);
  RenderWrappedText(rect, Caption, result, CountWrappedLine);
  LineCount := result;
end;

function TCaptionControl.MaxLineWidth: word;
var
  result: word;
  rect: TRect;
begin
  result := 0;
  GetDrawRect(rect);
  RenderWrappedText(rect, Caption, result, GetWrappedLineWidth);
  MaxLineWidth := result;
end;

procedure TCaptionControl.RenderWrappedText(var ARect: TRect; AText: PChar;
  var ACounter: word; ARenderProc: TWrapRenderProc);
var
  tx, ty, tw: integer;
  ch: char;
  charPtr, startPtr, endPtr: PChar;
  pos: TPoint;
  rect: TRect;
begin
  Graph^.PushState;
  charPtr := Caption;
  startPtr := charPtr;
  endPtr := charPtr;
  Parent^.GetClipRect(rect);
  Graph^.SetViewPort(rect);
  tx := 0;
  ty := 0;
  pos.Create;
  rect.Create;
  repeat
    ch := charPtr^;
    if ch = #0 then
      break;
    if ch = #13 then
      continue;
    tw := Font^.TextWidth(ch);
    if ch = #10 then begin
      pos.SetCoords(0, ty);
      rect.SetRect(ARect);
      ARenderProc(@self, rect, pos, startPtr, endPtr - startPtr, ACounter);
      tx := 0;
      Inc(ty, Font^.Height + VertSpacing);
      startPtr := endPtr;
      charPtr := endPtr;
      Inc(startPtr);
    end;
    if Wrap then begin
      if (tx + tw > ARect.Width) and not (ch in WhiteSpaceChars) then begin
        while (endPtr > startPtr) and not (endPtr^ in WhiteSpaceChars) do
          Dec(endPtr);
        if endPtr = startPtr then
          endPtr := charPtr;
        pos.SetCoords(0, ty);
        rect.SetRect(ARect);
        ARenderProc(@self, rect, pos, startPtr, endPtr - startPtr, ACounter);
        tx := 0;
        Inc(ty, Font^.Height + VertSpacing);
        while (endPtr < charPtr) and (endPtr^ in WhiteSpaceChars) do
          Inc(endPtr);
        charPtr := endPtr;
        startPtr := endPtr;
      end;
    end;
    Inc(endPtr);
    Inc(tx, tw);
    Inc(charPtr);
  until false;
  if endPtr > startPtr then begin
    pos.SetCoords(0, ty);
    rect.SetRect(ARect);
    ARenderProc(@self, ARect, pos, startPtr, endPtr - startPtr, ACounter);
  end;
  Graph^.PopState;
end;

procedure TCaptionControl.Paint(ARect: TRect);
var
  tx, ty, tw: integer;
  ch: char;
  charPtr, startPtr, endPtr: PChar;
  pos: TPoint;
  lines, index: word;
begin
  if ARect.IsEmpty then
    exit;
  inherited Paint(ARect);
  if not Assigned(Caption) then
    exit;
  if TString.Length(Caption) = 0 then
    exit;
  lines := 0;
  pos.CreateCoords(0, 0);
  RenderWrappedText(ARect, Caption, lines, PaintWrappedLine);
end;

destructor TCaptionControl.Free;
begin
  TString.Free(Caption);
  inherited Free;
end;

procedure TPopUp.Init;
begin
  inherited Init;
  FBackBuffer := nil;
end;

procedure TPopUp.Show;
var
  rect: TRect;
  size: longint;
begin
  BeginDrawing;
  Layout;
  VeridianApp^.HideMouseCursor;
  size := longint(rect.Width) * rect.Height;
  GetDrawRect(rect);
  if Graph^.Mode^.PageCount > 1 then
    Graph^.CopyToOffScreen(rect, rect)
  else begin
    FreeAndNil(FBackBuffer);
    FBackBuffer := New(PMemoryStream, Create(size));
    if VeridianApp^.CheckNilPtr(FBackBuffer) then
      exit;
    Graph^.GetImageStreamRect(rect, FBackBuffer);
  end;
  Visible := true;
  EndDrawing;
  Draw;
end;

procedure TPopUp.Hide;
var
  rect: TRect;
begin
  GetScreenBounds(rect);
  BeginDrawing;
  VeridianApp^.HideMouseCursor;
  if Graph^.Mode^.PageCount > 1 then
    Graph^.CopyFromOffScreen(rect, rect)
  else begin
    if not Assigned(FBackBuffer) then
      exit;
    FBackBuffer^.Seek(0, soFromBeginning);
    Graph^.DrawImageStreamRect(rect, FBackBuffer);
    FreeAndNil(FBackBuffer);
  end;
  Visible := false;
  EndDrawing;
end;

destructor TPopUp.Free;
begin
  FreeAndNil(FBackBuffer);
  inherited Free;
end;

function TButtonList.GetItemById(const AId: string): PButton;
begin
  GetItemById := PButton(inherited GetItemById(AId));
end;

function TButtonList.GetItem(AIndex: integer): PButton;
begin
  GetItem := PButton(inherited GetItem(AIndex));
end;

function TButtonList.Add(AItem: PButton): integer;
begin
  Add := inherited Add(AItem);
end;

procedure TButtonList.SetItem(AIndex: integer; AItem: PButton);
begin
  inherited SetItem(AIndex, AItem);
end;

procedure TButtonList.Insert(AIndex: integer; AItem: PButton);
begin
  inherited Insert(AIndex, AItem);
end;

procedure TFocusControl.Focus;
begin
  if CanFocus then
    SetFocus(true, true);
end;

procedure TFocusControl.Paint(ARect: TRect);
var
  oldForeColor, oldBackColor: byte;
begin
  if Focused then begin
    oldForeColor := ForeColor;
    oldBackColor := BackColor;
    ForeColor := FocusedColor;
    BackColor := FocusedBackColor;
    inherited Paint(ARect);
    ForeColor := oldForeColor;
    BackColor := oldBackColor;
  end
  else
    inherited Paint(ARect);
end;

procedure TFocusControl.UnFocus;
begin
  if CanFocus then
    SetFocus(false, true);
end;

function TFocusControl.Focused: boolean;
begin
  Focused := VeridianApp^.ActiveControl = @Self;
end;

procedure TFocusControl.SetFocus(AFocus, ARedraw: boolean);
var
  event: TEvent;
begin
  if not IsVisibleAndEnabled then
    exit;
  if not CanFocus then
    exit;
  if Focused and AFocus then
    exit;
  if (not Focused) and (not AFocus) then
    exit;
  event.Create;
  if AFocus then begin
    if Assigned(VeridianApp^.ActiveControl)
      and (VeridianApp^.ActiveControl <> @self) then begin
      InvokeSender(VeridianApp^.ActiveControl^.OnExit, VeridianApp^.ActiveControl, event);
      VeridianApp^.ActiveControl^.UnFocus;
    end;
    VeridianApp^.ActiveControl := @self;
    if ARedraw then
      Draw;
    Invoke(OnEnter, event);
    if UsesCursor then begin
      VeridianApp^.CursorOn;
    end;
  end
  else begin
    VeridianApp^.ActiveControl := nil;
    if ARedraw then
      Draw;
    if UsesCursor then
      VeridianApp^.CursorOff;
  end;
end;

constructor TFocusControl.CreateId(AId: string);
begin
  inherited Create(AId);
end;

constructor TFocusControl.CreateParent(AId: string; AParent: PControl);
begin
  inherited CreateParent(AId, nil, AParent);
end;

procedure TFocusControl.Init;
begin
  inherited Init;
  AcceptsEnter := false;
  AcceptsTab := false;
  UsesCursor := false;
  FocusedColor := VeridianApp^.Colors.EditorFocused;
  FocusedBackColor := VeridianApp^.Colors.EditorFocusedBack;
  FCursorX := 0;
  FCursorY := 0;
  CanFocus := true;
  FocusRectWidth := 0;
  FocusRectColor := VeridianApp^.Colors.FocusRectColor;
end;

function TFocusControl.CursorX: integer;
begin
  CursorX := FCursorX;
end;

function TFocusControl.CursorY: integer;
begin
  CursorY := FCursorY;
end;

function TFocusControl.IsFocusControl: boolean;
begin
  IsFocusControl := true;
end;

procedure TFocusControl.MouseDown(var AEvent: TMouseEvent);
begin
  inherited MouseDown(AEvent);
  if not IsVisibleAndEnabled then
    exit;
  if not Focused then
    Focus;
  Invoke(OnMouseDown, AEvent);
end;

function CompareDesktopControls(AItem1, AItem2: pointer): integer; far;
var
  control1, control2: PControl;
begin
  control1 := PControl(AItem1);
  control2 := PControl(AItem2);
  if byte(coStayOnTop in control1^.ControlOptions) > byte(coStayOnTop in control2^.ControlOptions) then
    CompareDesktopControls := 1;
  if byte(coStayOnTop in control1^.ControlOptions) < byte(coStayOnTop in control2^.ControlOptions) then
    CompareDesktopControls := -1
  else
    CompareDesktopControls := 0;
end;

constructor TDesktopControlList.Create(AOwner: PControl);
begin
  inherited Create(AOwner);
  Owner := AOwner;
end;

constructor TTextControl.CreateText(const AId, AText: string; AParent: PControl);
begin
  CreateParent(AId, AParent);
  SetText(AText);
end;

destructor TTextControl.Free;
begin
  TString.Free(Text);
  inherited Free;
end;

procedure TTextControl.Init;
begin
  inherited Init;
  Text := nil;
  TextAlign := haLeft;
  VertAlign := vaCenter;
  TextOffsetX := 0;
  TextOffsetY := 0;
  HighlightColor := 0;
end;

procedure TTextControl.SetText(const AText: string);
begin
  TString.AssignString(Text, AText);
  Draw;
end;

function TTextControl.GetText: string;
begin
  GetText := '';
  if Assigned(Text) then
    GetText := TString.GetString(Text);
end;

procedure TTextControl.GetCursorRect(var ARect: TRect);
begin
  ARect.Create;
end;

function TTextControl.GetCursorForeColor: byte;
begin
  GetCursorForeColor := 0;
end;

function TTextControl.GetCursorBackColor: byte;
begin
  GetCursorBackColor := 15;
end;

procedure TTextControl.Paint(ARect: TRect);
var
  rect: TRect;
  txt: string;
  pos: TPoint;
begin
  TPanel.Paint(ARect);
  if not IsVisible then
    exit;
  GetDrawRect(rect);
  txt := GetText;
  if txt = '' then
    exit;
  GetTextAlign(rect, pos);
  SetForeColorEnabled(ForeColor);
  Graph^.DrawText(pos.X + TextOffsetX, pos.Y + TextOffsetY, txt);
end;

function TTextControl.IsTextControl: boolean;
begin
  IsTextControl := true;
end;

var
  previousExitProc: PProc;

procedure Finalize; far;
begin
  ExitProc := previousExitProc;
end;

begin
  Desktop := nil;
  previousExitProc := ExitProc;
  ExitProc := @Finalize;
end.