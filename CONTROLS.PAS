{$I COMPILER.INC}
unit Controls;

interface

uses
  {$IFDEF DOS}
  Strings,
  {$ENDIF}
  Objects,
  Lists,
  AplConst,
  Drawing,
  Streams,
  StrUtils,
  DateTime,
  Files,
  Common,
  Actions,
  MouseDrv,
  VeriType,
  KeyDrv,
  GraphDrv,
  GrDrv8;

type
  TBorderStyle =
  (
    bsNone,
    bsSingle,
    bsDouble
  );

  TScrollStyle =
  (
    ssVert,
    ssHorz
  );

  TScrollButtonStyle =
  (
    sbInc,
    sbDec,
    sbSlider
  );

  TTextAlign =
  (
    taLeft,
    taRight,
    taCenter
  );

  TVertAlign =
  (
    vaTop,
    vaBottom,
    vaCenter
  );

  TScreenPosition =
  (
    spAbsolute,
    spRelative
  );

  TBorderStyles = set of TBorderStyle;

  PActionControl = ^TActionControl;
  PButton = ^TButton;
  PButtonList = ^TButtonList;
  PControl = ^TControl;
  PControlList = ^TControlList;
  PPanel = ^TPanel;
  PPopUp = ^TPopUp;
  PLabel = ^TLabel;
  PHorzSeparator = ^THorzSeparator;
  PTextControl = ^TTextControl;
  PEventProc = ^TEventProc;
  PMouseEventProc = ^TMouseEventProc;
  PKeyEventProc = ^TKeyEventProc;
  PDragEventProc = ^TDragEventProc;
  PScrollEventProc = ^TScrollEventProc;

  TKeyEvent = object(TEvent)
  private
  public
    Key: word;
    procedure Init; virtual;
    procedure Clear; virtual;
  end;

  TMouseEvent = object(TEvent)
  private
  public
    X: integer;
    Y: integer;
    NewMouseState: TMouseState;
    OldMouseState: TMouseState;
    procedure Init; virtual;
    procedure Clear; virtual;
  end;

  TScrollEvent = object(TEvent)
  private
  public
    CurrentPos: longint;
  end;

  TDragEvent = object(TMouseEvent)
  private
  public
  end;

  TEventProc = procedure(ASender: PObject; var AEvent: TEvent);
  TMouseEventProc = procedure(ASender: PObject; var AEvent: TMouseEvent);
  TKeyEventProc = procedure(ASender: PObject; var AEvent: TKeyEvent);
  TDragEventProc = procedure(ASender: PObject; var AEvent: TDragEvent);
  TScrollEventProc = procedure(ASender: PObject; var AEvent: TScrollEvent);

  TControl = object(TIdentifiable)
  private
  public
    X, Y: integer;
    Width, Height: word;
    Visible: boolean;
    BorderColor: byte;
    ForeColor: byte;
    BackColor: byte;
    FocusedForeColor: byte;
    FocusedBackColor: byte;
    HoverForeColor: byte;
    HoverBackColor: byte;
    CanDrag: boolean;
    HoverHighlightColor: byte;
    OnMouseMove: PMouseEventProc;
    OnMouseUp: PMouseEventProc;
    OnMouseDown: PMouseEventProc;
    OnMouseClick: PMouseEventProc;
    OnMouseDblClick: PMouseEventProc;
    OnMouseEnter: PMouseEventProc;
    OnMouseLeave: PMouseEventProc;
    OnMouseWheelChanged: PMouseEventProc;
    OnKeyPress: PKeyEventProc;
    OnDragStart: PDragEventProc;
    OnDragEnd: PDragEventProc;
    Controls: PControlList;
    Parent: PControl;
    BorderStyle: TBorderStyle;
    Modal: boolean;
    IsLeftMouseDown: boolean;
    IsRightMouseDown: boolean;
    IsMouseOver: boolean;
    ShowToolTip: boolean;
    Position: TScreenPosition;
    MoveStartX, MoveStartY: longint;
    Grouped: boolean;
    TakesControl: boolean;
    TextX, TextY: integer;
    Enabled: boolean;
    Focused: boolean;
    CanFocus: boolean;
    UsesCursor: boolean;
    AcceptEnter: boolean;
    AcceptTab: boolean;
    Font: PFont;
    Tag: integer;
    MouseCursor: PMouseCursor;
    constructor Create(const AId: string);
    constructor CreateParent(const AId: string; AParent: PControl);
    destructor Free; virtual;
    function BorderWidth: integer; virtual;
    function IsActionControl: boolean; virtual;
    procedure Init; virtual;
    procedure Hide; virtual;
    procedure Show; virtual;
    procedure Draw; virtual;
    procedure DrawSelf; virtual;
    procedure Paint; virtual;
    procedure PaintRegion(AScreenRect: TRect); virtual;
    {Set bounds relative to parent client rect}
    procedure SetBounds(AX, AY, AWidth, AHeight: integer); virtual;
    {Set bounds rectangle relative to parent client rect}
    procedure SetBoundsRect(ARect: TRect); virtual;
    {Get bounds of this control relative to parent client rect}
    procedure GetBounds(var ARect: TRect); virtual;
    {Get bounds in absolute screen coordinates}
    procedure GetScreenBounds(var ARect : TRect); virtual;
    {Get client bounds relative to parent as defined by control
    (area within borders, or overriden by control)}
    procedure GetClientRect(var ARect: TRect); virtual;
    {Get client bounds as in GetClientRect, but in Screen coordinates}
    procedure GetClientScreenRect(var ARect: TRect); virtual;
    {Get editor cursor rect in absolute screen coordinates}
    procedure GetCursorRect(var ARect: TRect); virtual;
    procedure DrawControls; virtual;
    procedure SetupControls; virtual;
    procedure MouseMove(var AEvent: TMouseEvent); virtual;
    procedure MouseUp(var AEvent: TMouseEvent); virtual;
    procedure MouseDown(var AEvent: TMouseEvent); virtual;
    procedure MouseDblClick(var AEvent: TMouseEvent); virtual;
    procedure MouseClick(var AEvent: TMouseEvent); virtual;
    procedure MouseEnter(var AEvent: TMouseEvent); virtual;
    procedure MouseLeave(var AEvent: TMouseEvent); virtual;
    procedure MouseWheelChanged(var AEvent: TMouseEvent); virtual;
    procedure DragStart(var AEvent: TDragEvent); virtual;
    procedure DragEnd(var AEvent: TDragEvent); virtual;
    procedure Focus; virtual;
    procedure Unfocus; virtual;
    procedure SetFocus(AFocused, ARedraw: boolean);
    procedure KeyPress(var AEvent: TKeyEvent); virtual;
    procedure StartDrawing; virtual;
    procedure StartDrawingEx(ASetupControls: boolean); virtual;
    procedure EndDrawing; virtual;
    procedure BringToFront; virtual;
    procedure SendToBack; virtual;
    function CenterX: integer; virtual;
    function CenterY: integer; virtual;
    function TrueTextWidth(AText: string): integer;
    function GetVisible: boolean; virtual;
    function GetEnabled: boolean; virtual;
    function GetModal: boolean; virtual;
    function AddControl(AControl: PControl): PControl; virtual;
    function GetCursorForeColor: byte; virtual;
    function GetCursorBackColor: byte; virtual;
  end;

  TControlList = Object(TIdentifiableList)
  private
  public
    Parent: PControl;
    constructor CreateParent(AParent: PControl);
    function ToString: string; virtual;
    function GetItemById(AId: string): PControl;
    function GetItem(AIndex: integer): PControl;
    function IndexOf(AItem: PControl): integer;
    function Add(AItem: PControl): integer;
    procedure Init; virtual;
    procedure Insert(AIndex: integer; AItem: PControl);
    procedure Remove(AControl: PControl);
  end;

  TButtonList = Object(TIdentifiableList)
  public
    function ToString: string; virtual;
    function GetItem(AIndex: integer): PButton;
    function GetItemById(AId: string): PButton;
    function IndexOf(AItem: PButton): integer;
    function Add(AItem: PButton): integer;
    procedure Init; virtual;
    procedure Insert(AIndex: integer; AItem: PButton);
  end;

  THorzSeparator = object(TControl)
  private
  public
    procedure Init; virtual;
    procedure Paint; virtual;
  end;

  TPanel = object(TControl)
  private
    procedure SetForeColorEnabled(AColor: byte);
  public
    DrawBackground: boolean;
    DisabledColor: byte;
    procedure Init; virtual;
    procedure Paint; virtual;
    destructor Free; virtual;
  end;

  TTextControl = object(TPanel)
  private
  public
    Text: PChar;
    TextAlign: TTextAlign;
    VertAlign: TVertAlign;
    Margin: integer;
    HighlightColor: byte;
    TextOffsetX: shortint;
    TextOffsetY: shortint;
    constructor CreateText(const AId, AText: string; AParent: PControl);
    destructor Free; virtual;
    function GetText: string; virtual;
    procedure Init; virtual;
    procedure SetText(const AText: string); virtual;
    procedure Paint; virtual;
    procedure GetTextAlign(const ARect: TRect;var AXPos, AYPos: integer);
  end;

  TActionControl = object(TTextControl)
  private
  public
    ActionId: integer;
    Action: PAction;
    ShowShortcut: boolean;
    ShortcutDisplayName: PChar;
    Shortcut: word;
    DisabledForeColor: byte;
    constructor Create(const AId: string; AActionId: integer);
    constructor CreateParent(const AId: string; AActionId: integer; AParent: PControl);
    function IsActionControl: boolean; virtual;
    function GetText: string; virtual;
    function GetEnabled: boolean; virtual;
    function GetShortcut: word; virtual;
    function GetShortcutDisplayName: string; virtual;
    function GetAltHotKey: word; virtual;
    function GetHotKey: word; virtual;
    procedure Init; virtual;
    procedure Paint; virtual;
    procedure MouseClick(var AEvent: TMouseEvent); virtual;
    procedure KeyPress(var AEvent: TKeyEvent); virtual;
    destructor Free; virtual;
  end;

  TLabel = Object(TTextControl)
  private
  public
    Autosize: boolean;
    constructor CreateText(const AId, AText: string; AParent: PControl);
    procedure Init; virtual;
    procedure Paint; virtual;
    procedure Clear; virtual;
    procedure SetupControls; virtual;
    destructor Free; virtual;
  end;

  TButton = Object(TActionControl)
    Down: boolean;
    Toggle: boolean;
    Active: boolean;
    LightColor: byte;
    ShadowColor: byte;
    DownBackColor: byte;
    DownShadowColor: byte;
    DownLightColor: byte;
    Clickable: boolean;
    procedure MouseEnter(var AEvent: TMouseEvent); virtual;
    procedure MouseLeave(var AEvent: TMouseEvent); virtual;
    procedure MouseDown(var AEvent: TMouseEvent); virtual;
    procedure MouseClick(var AEvent: TMouseEvent); virtual;
    procedure Init; virtual;
    procedure Paint; virtual;
  end;

  TPopUp = object(TPanel)
  private
  public
    destructor Free; virtual;
    procedure Init; virtual;
    procedure Show; virtual;
    procedure Hide; virtual;
  end;

implementation

uses
  GraphApp,

  Veridian,
  Desk;

constructor TControlList.CreateParent(AParent: PControl);
begin
  inherited Create;
  Parent := AParent;
end;

procedure TControlList.Init;
begin
  inherited Init;
  Parent := nil;
end;

function TControlList.ToString: string;
begin
  ToString := 'TControlList';
end;

function TControlList.GetItem(AIndex: integer): PControl;
begin
  GetItem := PControl(inherited GetItem(AIndex));
end;

function TControlList.IndexOf(AItem: PControl): integer;
begin
  IndexOf := inherited IndexOf(AItem);
end;

function TControlList.Add(AItem: PControl): integer;
begin
  Add := inherited Add(AItem);
  AItem^.Parent := Parent;
end;

procedure TControlList.Insert(AIndex: integer; AItem: PControl);
begin
  if not Assigned(AItem) then
    exit;
  inherited Insert(AIndex, AItem);
  AItem^.Parent := Parent;
end;

function TControlList.GetItemById(AId: string): PControl;
begin
  GetItemById := PControl(inherited GetItemById(AId));
end;

procedure TControlList.Remove(AControl: PControl);
var
  index: integer;
  oldDisposeObjects: boolean;
begin
  index := IndexOf(AControl);
  if index < 0 then
    exit;
  oldDisposeObjects := DisposeObjects;
  DisposeObjects := false;
  Delete(index);
  DisposeObjects := oldDisposeObjects;
end;

constructor TControl.Create(const AId: string);
begin
  inherited CreateId(AId);
end;

constructor TControl.CreateParent(const AId: string; AParent: PControl);
begin
  inherited CreateId(AId);
  if Assigned(AParent) then
    AParent^.Controls^.Add(@self);
end;

procedure TControl.Init;
begin
  inherited Init;
  Controls := New(PControlList, CreateParent(@self));
  SetBounds(0, 0, 0, 0);
  Tag := 0;
  CanDrag := false;
  Visible := true;
  Position := spRelative;
  BorderStyle := bsNone;
  ForeColor := 0;
  BackColor := 0;
  HoverForeColor := 0;
  HoverBackColor := 0;
  HoverHighlightColor := 0;
  BorderColor := 0;
  FocusedForeColor := 0;
  FocusedBackColor := 0;
  OnMouseMove := nil;
  OnMouseWheelChanged := nil;
  OnMouseUp := nil;
  OnMouseDown := nil;
  OnMouseDblClick := nil;
  OnKeyPress := nil;
  OnMouseEnter := nil;
  OnMouseLeave := nil;
  OnMouseClick := nil;
  OnDragStart := nil;
  OnDragEnd := nil;
  Enabled := true;
  Modal := false;
  IsLeftMouseDown := false;
  IsRightMouseDown := false;
  IsMouseOver := false;
  ShowToolTip:= false;
  Grouped := false;
  TakesControl := false;
  TextX := 0;
  TextY := 0;
  Focused := false;
  CanFocus := false;
  UsesCursor := false;
  AcceptEnter := false;
  AcceptTab := false;
  Parent := nil;
  Font := Desktop^.Font;
  MouseCursor := VeridianApp^.MouseCursors^.GetItemById('Default');
end;

function TControl.IsActionControl: boolean;
begin
  IsActionControl := false;
end;

function TControl.CenterX: integer;
begin
  if not Assigned(Parent) then
    exit;
  CenterX := (integer(Parent^.Width) - Width) div 2;
end;

function TControl.CenterY: integer;
begin
  if not Assigned(Parent) then
    exit;
  CenterY := (Parent^.Height - Height) div 2;
end;

function TControl.GetCursorForeColor: byte;
begin
end;

function TControl.GetCursorBackColor: byte;
begin
end;

procedure TControl.GetCursorRect(var ARect: TRect);
begin
  ARect.Create;
end;

function TControl.AddControl(AControl: PControl): PControl;
begin
  Controls^.Add(AControl);
end;

procedure TControl.MouseWheelChanged(var AEvent: TMouseEvent);
begin
  if Assigned(OnMouseWheelChanged) then
    TMouseEventProc(OnMouseWheelChanged)(@self, AEvent);
end;

procedure TControl.MouseMove(var AEvent: TMouseEvent);
begin
  if Assigned(OnMouseMove) then
    TMouseEventProc(OnMouseMove)(@self, AEvent);
end;

procedure TControl.MouseUp(var AEvent: TMouseEvent);
begin
  if Assigned(OnMouseUp) then
    TMouseEventProc(OnMouseUp)(@self, AEvent);
end;

procedure TControl.MouseDown(var AEvent: TMouseEvent);
begin
  if Assigned(OnMouseDown) then
    TMouseEventProc(OnMouseDown)(@self, AEvent);
end;

procedure TControl.MouseDblClick(var AEvent: TMouseEvent);
begin
  if Assigned(OnMouseDblClick) then
    TMouseEventProc(OnMouseDblClick)(@self, AEvent);
end;

procedure TControl.MouseEnter(var AEvent: TMouseEvent);
begin
  if Assigned(OnMouseEnter) then
    TMouseEventProc(OnMouseEnter)(@self, AEvent);
end;

procedure TControl.MouseLeave(var AEvent: TMouseEvent);
begin;
  if Assigned(OnMouseLeave) then
    TMouseEventProc(OnMouseLeave)(@self, AEvent);
end;

procedure TControl.MouseClick(var AEvent: TMouseEvent);
begin
  if Assigned(OnMouseClick) then
    TMouseEventProc(OnMouseClick)(@self, AEvent);
end;

procedure TControl.DragStart(var AEvent: TDragEvent);
begin
  if Assigned(OnDragStart) then
    TDragEventProc(OnDragStart)(@self, AEvent);
end;

procedure TControl.DragEnd(var AEvent: TDragEvent);
begin
  if Assigned(OnDragEnd) then
    TDragEventProc(OnDragEnd)(@self, AEvent);
end;

procedure TControl.Focus;
begin
  SetFocus(true, true);
end;

procedure TControl.SetFocus(AFocused, ARedraw: boolean);
begin
  if not (CanFocus and GetVisible and GetEnabled) then
    exit;
  Focused := AFocused;
  if AFocused then begin
    if Desktop^.ActiveControl = @self then
      exit;
    if Assigned(Desktop^.ActiveControl) and Desktop^.ActiveControl^.Focused then
      Desktop^.ActiveControl^.Unfocus;
    Desktop^.ActiveControl := @self;
    if ARedraw then
      Draw;
    if UsesCursor then begin
      VeridianApp^.CursorOn;
    end;
  end
  else begin
    Desktop^.ActiveControl := nil;
    if ARedraw then
      Draw;
    if UsesCursor then
      VeridianApp^.CursorOff;
  end;
end;

procedure TControl.Unfocus;
begin
  SetFocus(false, true);
end;

procedure TControl.GetBounds(var ARect: TRect);
begin
  ARect.CreateDims(X, Y, Width, Height);
end;

procedure TControl.SetBounds(AX, AY, AWidth, AHeight: integer);
begin;
  X := AX;
  Y := AY;
  Width := AWidth;
  Height := AHeight;
end;

procedure TControl.SetBoundsRect(ARect: TRect);
begin
  SetBounds(ARect.X, ARect.Y, ARect.Width, ARect.Height);
end;

procedure TControl.GetScreenBounds(var ARect: TRect);
var
  parentRect: TRect;
begin
  GetBounds(ARect);
  if (Position = spAbsolute) or not Assigned(Parent) then
    exit;
  Parent^.GetScreenBounds(parentRect);
  ARect.Translate(parentRect.X, parentRect.Y);
end;

procedure TControl.GetClientRect(var ARect: TRect);
begin
  ARect.CreateDims(BorderWidth, BorderWidth, Width - BorderWidth * 2, Height - BorderWidth * 2);
end;

{Get client bounds as in GetClientRect, but in Screen coordinates}
procedure TControl.GetClientScreenRect(var ARect: TRect);
var
  parentRect: TRect;
begin
  GetClientRect(ARect);
  if (Position = spAbsolute) or not Assigned(Parent) then
    exit;
{    do this}
  Parent^.GetScreenBounds(parentRect);
  ARect.Translate(parentRect.X, parentRect.Y);
end;

procedure TControl.SendToBack;
begin
  if (Parent = nil) or (Parent^.Controls^.Count < 2) then
    exit;
  if Parent^.Controls^.IndexOf(@self) = 0 then
    exit;
  Parent^.Controls^.Remove(@self);
  Parent^.Controls^.Insert(0, @self);
end;

procedure TControl.BringToFront;
begin
  if (Parent = nil) or (Parent^.Controls^.Count < 2) then
    exit;
  if Parent^.Controls^.IndexOf(@self) = Parent^.Controls^.Count - 1 then
    exit;
  Parent^.Controls^.Remove(@self);
  Parent^.Controls^.Add(@self);
end;

procedure TControl.SetupControls;
begin
end;

destructor TControl.Free;
begin
  FreeAndNil(Controls);
  inherited Free;
end;

function TControl.GetVisible: boolean;
var
  par: PControl;
begin
  GetVisible := false;
  if not Visible then
    exit;
  par := Parent;
  while Assigned(par) do begin
    if not par^.Visible then
      exit;
    par := par^.Parent;
  end;
  GetVisible := true;
end;

function TControl.BorderWidth: integer;
begin
  BorderWidth := 0;
  if (BorderStyle <> bsNone) then
    BorderWidth := 1;
end;

function TControl.GetEnabled: boolean;
var
  par: PControl;
begin
  GetEnabled := false;
  if not Enabled then
    exit;
  par := Parent;
  while Assigned(par) do begin
    if not par^.Enabled then
      exit;
    par := par^.Parent;
  end;
  GetEnabled := true;
end;

function TControl.GetModal: boolean;
var
  par: PControl;
begin
  GetModal := true;
  if (Modal) then
    exit;
  par := Parent;
  while Assigned(par) do begin
    if (par^.Modal) then exit;
    par := par^.Parent;
  end;
  GetModal := false;
end;

procedure TControl.Hide;
var
  index: integer;
  control: PControl;
  rect: TRect;
begin
  StartDrawing;
  for index := 0 to Controls^.Count - 1 do begin
    control := Controls^.GetItem(index);
    control^.IsMouseOver := false;
    control^.IsLeftMouseDown := false;
    control^.IsRightMouseDown := false;
    if Desktop^.ActiveControl = control then
      Desktop^.ActiveControl := nil;
  end;
  Visible := false;
  GetScreenBounds(rect);
  Desktop^.PaintRegion(rect);
  EndDrawing;
end;

procedure TControl.Show;
begin
  Visible := true;
  Draw;
end;

procedure TControl.Paint;
begin
  Graph^.State.Font := Font;
end;

procedure TControl.PaintRegion(AScreenRect: TRect);
var
  index: integer;
  control: PControl;
  rect: TRect;
  controlRect: TRect;
begin
  if not GetVisible then
    exit;
  GetScreenBounds(rect);
  if rect.IsEmpty then
    exit;
  VeridianApp^.PushState;
  VeridianApp^.CursorOff;
  Graph^.PushState;
  rect.Intersect(AScreenRect);
  Graph^.State.ViewPort := rect;
  { TODO: replace this with full region inversion point handling }
  Paint;
  if Controls^.Count > 0 then begin
    for index := Controls^.Count - 1 downto 0 do begin
      control := Controls^.GetItem(index);
      if not control^.GetVisible then
        continue;
      control^.GetScreenBounds(controlRect);
      controlRect.Intersect(AScreenRect);
      if not controlRect.IsEmpty then
        control^.PaintRegion(controlRect);
    end;
  end;
  Graph^.PopState;
  VeridianApp^.PopState;
end;

procedure TControl.DrawSelf;
begin
  if not VeridianApp^.DrawEnabled then
    exit;
  if not GetVisible then
    exit;
  StartDrawing;
  Paint;
  EndDrawing;
end;

procedure TControl.Draw;
begin
  if not VeridianApp^.DrawEnabled then
    exit;
  if not GetVisible then
    exit;
  StartDrawing;
  Paint;
  DrawControls;
  EndDrawing;
end;

procedure TControl.DrawControls;
var
  index: integer;
  control: PControl;
begin
  if Controls^.Count = 0 then
    exit;
  for index := Controls^.Count - 1 downto 0 do begin
    control := Controls^.GetItem(index);
    control^.Draw;
  end;
end;

procedure TControl.StartDrawing;
begin
  StartDrawingEx(true);
end;

procedure TControl.StartDrawingEx(ASetupControls: boolean);
var
  parentRect, rect, mouseRect: TRect;
  par: PControl;
begin
  Mouse.PushState;
  Graph^.PushState;
  if ASetupControls then
    SetupControls;
  GetScreenBounds(rect);
  if Position <> spAbsolute then begin
    par := Parent;
    while Assigned(par) do begin
      if par^.Position = spAbsolute then
        break;
      par^.GetScreenBounds(parentRect);
      rect.Intersect(parentRect);
      par := par^.Parent;
    end;
  end;
  mouseRect.CreateDims(Graph8^.MouseCursor^.X, Graph8^.MouseCursor^.Y,
    Graph8^.MouseCursor^.Width, Graph8^.MouseCursor^.Height);
  if rect.IntersectsRect(mouseRect) then
    Graph8^.HideMouseCursor;
  Graph^.SetForeColor(ForeColor);
  Graph^.SetBackColor(BackColor);
  Graph^.State.ViewPort := rect;
end;

procedure TControl.EndDrawing;
var
  rect, mouseRect: TRect;
begin
  Graph^.PopState;
  Mouse.PopState;
  Graph8^.MouseCursor^.X := Mouse.State.X;
  Graph8^.MouseCursor^.Y := Mouse.State.Y;
  GetScreenBounds(rect);
  MouseRect.CreateDims(Graph8^.MouseCursor^.X, Graph8^.MouseCursor^.Y,
    Graph8^.MouseCursor^.Width, Graph8^.MouseCursor^.Height);
  if Mouse.State.Visible then begin
    Graph8^.MouseCursor^.Visible := Mouse.State.Visible;
    if rect.IntersectsRect(mouseRect) then
      Graph8^.DrawMouseCursor(Mouse.State);
  end else begin
    Graph8^.MouseCursor^.Visible := false;
  end;
end;

procedure TControl.KeyPress(var AEvent: TKeyEvent);
var
  index: integer;
  control: PControl;
begin
  if AEvent.Handled then
    exit;
  for index := Controls^.Count - 1 downto 0 do begin
    if AEvent.Handled then
      exit;
    control := PControl(Controls^.GetItem(index));
    if not control^.GetEnabled then
      continue;
    if not control^.GetVisible then
      continue;
    control^.KeyPress(AEvent);
  end;
  if AEvent.Handled then
    exit;
  if Assigned(OnKeyPress) then
    TKeyEventProc(OnKeyPress)(@self, AEvent);
end;

function TControl.TrueTextWidth(AText: string): integer;
var
  index: integer;
  len: word;
  ch: char;
  ptr: PChar;
  currentWidth: integer;
begin
  TrueTextWidth := 0;
  len := Length(AText);
  if (len = 0) or not Assigned(font) then
    exit;
  currentWidth := 0;
  for index := 1 to len do begin
    ch := AText[index];
    if (ch = '&') then
      continue;
    Inc(currentWidth, Font^.TextWidth(ch));
  end;
  TrueTextWidth := currentWidth;
end;

constructor TActionControl.CreateParent(const AId: string; AActionId: integer; AParent: PControl);
begin
  inherited CreateParent(AId, AParent);
  ActionId := AActionId;
  Action := Desktop^.ActionList^.GetActionById(AActionId);
end;

constructor TActionControl.Create(const AId: string; AActionId: integer);
begin
  inherited CreateId(AId);
  ActionId := AActionId;
  Action := Desktop^.ActionList^.GetActionById(AActionId);
end;

function TActionControl.GetText;
begin
  if (not Assigned(Text)) and Assigned(Action) and Assigned(Action^.Text) then
    GetText := StrPas(Action^.Text)
  else
    GetText := inherited GetText;
end;

function TActionControl.IsActionControl: boolean;
begin
  IsActionControl := true;
end;

function TActionControl.GetAltHotKey;
var
  caption: string;
  index: integer;
  ch: char;
begin
  caption := StrPas(Text);
  for index := 1 to Length(caption) do begin
    if (caption[index] = '&') and (length(caption) >= index + 1) then begin
      GetAltHotKey := Keyboard.CharToAltChar(caption[index + 1]);
      exit;
    end;
  end;
  GetAltHotKey := 0;
end;

function TActionControl.GetHotKey;
var
  caption: string;
  index: integer;
  ch: char;
begin
  if Assigned(Action) then
    caption := StrPas(Action^.Text)
  else
    caption := StrPas(Text);
  for index := 1 to Length(caption) do begin
    if (caption[index] = '&') and (length(caption) >= index + 1) then begin
      GetHotKey := Ord(UpCase(caption[index + 1]));
      exit;
    end;
  end;
  GetHotKey := 0;
end;

procedure TActionControl.KeyPress(var AEvent: TKeyEvent);
begin
  inherited KeyPress(AEvent);
end;

procedure TActionControl.MouseClick(var AEvent: TMouseEvent);
begin
  if not GetEnabled then
    exit;

  if Assigned(Action) and (Action^.Enabled) then begin
    AEvent.Handled := true;
    VeridianApp^.HandleActionExecute(@self, Action);
  end;
  if AEvent.Handled then
    exit;
  inherited MouseClick(AEvent);
end;

destructor TActionControl.Free;
begin
  TString.Free(ShortcutDisplayName);
  inherited Free;
end;

procedure TActionControl.Init;
begin
  inherited Init;
  Action := nil;
  ShortcutDisplayName := nil;
  ShowShortcut := true;
  Shortcut := 0;
  ActionId := -1;
  DisabledForeColor := Desktop^.Colors^.ButtonDisabled;
end;

procedure TActionControl.Paint;
var
  textXPos, textYPos: integer;
  shortcutDesc: string;
  rect: TRect;
  txt: string;
  textIndex: integer;
  ch: char;
begin
  if Assigned(Action) then
    VeridianApp^.UpdateActionControl(@self);
  GetScreenBounds(rect);
  rect.Intersect(Graph^.State.ViewPort);
  TPanel.Paint;
  txt := GetText;
  GetTextAlign(rect, textXPos, textYPos);
  textIndex := 1;
  while textIndex <= Length(txt) do begin
    SetForeColorEnabled(ForeColor);
    if (txt[textIndex] = '&') then begin
      SetForeColorEnabled(HighlightColor);
      Inc(textIndex);
    end;
    ch := txt[textIndex];
    Graph^.DrawText(textXPos + TextOffsetX, textYPos + TextOffsetY, ch);
    Inc(textXPos, Font^.TextWidth(ch));
    Inc(textIndex);
  end;
  SetForeColorEnabled(ForeColor);

  if (GetShortcut >= 0) and ShowShortcut then begin
    shortcutDesc := Keyboard.KeyToShortcut(GetShortcut);
    textXPos := rect.Right - Font^.TextWidth(shortcutDesc) - Font^.Spacing + 1;
    Graph^.DrawText(textXPos, textYPos, shortcutDesc);
  end;
end;

function TActionControl.GetEnabled: boolean;
var
  par: PControl;
begin
  GetEnabled := false;
  if Assigned(Action) then begin
    if not Action^.Enabled then
      exit;
  end;
  par := Parent;
  while Assigned(par) do begin
    if not par^.GetEnabled then
      exit;
    par := par^.Parent;
  end;
  GetEnabled := Enabled;
end;

function TActionControl.GetShortcut: word;
begin
  if (Shortcut = 0) then begin
    if (ActionId >= 0) then
      GetShortcut := Action^.Shortcut
    else
      GetShortcut := 0;
  end else
    GetShortcut := Shortcut;
end;

function TActionControl.GetShortcutDisplayName: string;
begin
  if not Assigned(ShortcutDisplayName) then begin
    if (ActionId >= 0) then
      GetShortcutDisplayName := StrPas(Action^.ShortcutDisplayName)
    else
      GetShortcutDisplayName := '';
  end else
    GetShortcutDisplayName := StrPas(ShortcutDisplayName);
end;

procedure THorzSeparator.Init;
begin
  inherited Init;
  BorderStyle := bsNone;
  ForeColor := Desktop^.Colors^.Border;
end;

procedure THorzSeparator.Paint;
var
  rect: TRect;
begin
  inherited Paint;
  if not GetVisible then
    exit;
  GetScreenBounds(rect);
  Graph^.SetForeColor(ForeColor);
  Graph^.HLine(rect.X, rect.Y, rect.Width);
end;

procedure TPanel.Init;
begin
  inherited Init;
  ForeColor := Desktop^.Colors^.Window;
  BackColor := Desktop^.Colors^.WindowBack;
  BorderColor := Desktop^.Colors^.Border;
  BorderStyle := bsSingle;
  FocusedForeColor := Desktop^.Colors^.Focused;
  FocusedBackColor := Desktop^.Colors^.FocusedBack;
  DisabledColor := Desktop^.Colors^.ButtonDisabled;
  DrawBackground := true;
end;

destructor TPanel.Free;
begin
  inherited Free;
end;

procedure TPanel.Paint;
var
  rect: TRect;
  innerRect: TRect;
begin
  inherited Paint;
  if not GetVisible then
    exit;
  GetScreenBounds(rect);
  Graph^.SetForeColor(ForeColor);
  Graph^.SetBackColor(BackColor);
  if CanFocus and Focused then begin
    Graph^.SetForeColor(FocusedForeColor);
    Graph^.SetBackColor(FocusedBackColor);
  end
  else if not GetEnabled then begin
    Graph^.SetForeColor(DisabledColor);
  end;
  if DrawBackground then
    Graph^.FillRect(rect);
  if BorderStyle <> bsNone then begin
    Graph^.SetForeColor(BorderColor);
    Graph^.Rectangle(rect);
  end;
end;

procedure TPanel.SetForeColorEnabled(AColor: byte);
begin
  if GetEnabled then
    Graph^.SetForeColor(AColor)
  else
    Graph^.SetForeColor(DisabledColor);
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
  TextAlign := taLeft;
  VertAlign := vaCenter;
  Margin := 0;
  TextOffsetX := 0;
  TextOffsetY := 0;
  HighlightColor := 0;
end;

procedure TTextControl.GetTextAlign(const ARect: TRect;var AXPos, AYPos: integer);
var
  textWidth: integer;
  txt: string;
begin
  txt := GetText;
  textWidth := TrueTextWidth(txt);
  case TextAlign of
    taLeft: AXPos := ARect.X + Margin + BorderWidth;
    taRight: AXPos := ARect.X + ARect.Width - textWidth - Margin - BorderWidth;
    taCenter: AXPos := ARect.X + (ARect.Width - textWidth) div 2 + 1;
  end;
  case VertAlign of
    vaTop: AYPos := ARect.Y + Margin;
    vaBottom: AYPos := ARect.Y + ARect.Height - Font^.Height - Margin;
    vaCenter: AYPos := ARect.Y + (ARect.Height - Font^.Height) div 2 + 1;
  end;
end;

procedure TTextControl.SetText(const AText: string);
begin
  TString.Assign(Text, AText);
  Draw;
end;

function TTextControl.GetText: string;
begin
  GetText := '';
  if Assigned(Text) then
    GetText := StrPas(Text);
end;

procedure TTextControl.Paint;
var
  textXPos, textYPos: integer;
  rect: TRect;
  txt: string;
begin
  inherited Paint;
  if not GetVisible then
    exit;
  GetScreenBounds(rect);
  txt := GetText;
  if txt = '' then
    exit;
  GetTextAlign(rect, textXPos, textYPos);
  SetForeColorEnabled(ForeColor);
  Graph^.DrawText(textXPos + TextOffsetX, textYPos + TextOffsetY, txt);
end;

procedure TButton.Init;
begin
  inherited Init;
  Clickable := true;
  CanFocus := true;
  Active := false;
  ShowShortcut := false;
  IsMouseOver := false;
  ForeColor := Desktop^.Colors^.Button;
  BackColor := Desktop^.Colors^.ButtonBack;
  LightColor := Desktop^.Colors^.ButtonLight;
  BorderStyle := bsNone;
  Down := false;
  Toggle := false;
  Grouped := false;
  TextAlign := taCenter;
  BorderStyle := bsSingle;
  ForeColor := Desktop^.Colors^.Button;
  BackColor := Desktop^.Colors^.ButtonBack;
  ShadowColor := Desktop^.Colors^.ButtonShadow;
  HighlightColor := Desktop^.Colors^.ButtonHighlight;
  DownBackColor := Desktop^.Colors^.ButtonDownBack;
  DownShadowColor := Desktop^.Colors^.ButtonDownShadow;
  DownLightColor := Desktop^.Colors^.ButtonDownLight;
  FocusedForeColor := ForeColor;
  FocusedBackColor := FocusedBackColor;
end;

function TButtonList.ToString: string;
begin
  ToString := 'TButtonList';
end;

function TButtonList.GetItem(AIndex: integer): PButton;
begin
  GetItem := PButton(inherited GetItem(AIndex));
end;

function TButtonList.GetItemById(AId: string): PButton;
begin
  GetItemById := PButton(inherited GetItemById(AId));
end;

function TButtonList.IndexOf(AItem: PButton): integer;
begin
  IndexOf := inherited IndexOf(AItem);
end;

function TButtonList.Add(AItem: PButton): integer;
begin
  Add := inherited Add(AItem);
end;

procedure TButtonList.Init;
begin
  inherited Init;
end;

procedure TButtonList.Insert(AIndex: integer; AItem: PButton);
begin
  inherited Insert(AIndex, AItem);
end;

procedure TButton.Paint;
var
  rect: TRect;
  oldOffsetX: shortint;
  oldOffsetY: shortint;
  oldFocusedColor: byte;
begin
  if not GetVisible then
    exit;
  oldOffsetX := TextOffsetX;
  oldOffsetY := TextOffsetY;
  if Down then begin
    Inc(TextOffsetX);
    Inc(TextOffsetY);
  end;
  oldFocusedColor := FocusedBackColor;
  FocusedBackColor := BackColor;
  inherited Paint;
  FocusedBackColor := oldFocusedColor;
  TextOffsetX := oldOffsetX;
  TextOffsetY := oldOffsetY;
  GetScreenBounds(rect);
  rect.Translate(BorderWidth, BorderWidth);
  rect.Grow(-2 * BorderWidth, -2 * BorderWidth);
  if Down and Clickable then
    Graph^.SetForeColor(DownLightColor)
  else
    Graph^.SetForeColor(LightColor);
  Graph^.HLine(rect.X, rect.Y, rect.Width);
  Graph^.VLine(rect.X, rect.Y, rect.Height);
  if Down and Clickable then
    Graph^.SetForeColor(DownShadowColor)
  else
    Graph^.SetForeColor(ShadowColor);
  Graph^.HLine(rect.X, rect.Bottom, rect.Width);
  Graph^.VLine(rect.Right, rect.Y + 1, rect.Height - 1);
  GetScreenBounds(rect);
  if not CanFocus then
    exit;
  if Focused then
    Graph^.SetForeColor(FocusedBackColor)
  else if Assigned(Parent) then
    Graph^.SetForeColor(Parent^.BackColor);
  rect.Grow(2, 2);
  rect.Translate(-1, -1);
  Graph^.State.ViewPort := rect;
  Graph^.Rectangle(rect);
end;

procedure TButton.MouseEnter(var AEvent: TMouseEvent);
begin
  if not (GetEnabled and GetVisible) then
    exit;
  if VeridianApp^.LeftMouseDownControl = @self then begin
    Down := true;
    DrawSelf;
  end;
  Desktop^.StatusBar^.ShowActionHelp(Action);
end;

procedure TButton.MouseLeave(var AEvent: TMouseEvent);
begin
  if not (GetEnabled and GetVisible) then
    exit;
  if VeridianApp^.LeftMouseDownControl = @self then begin
    Down := false;
    DrawSelf;
  end;
  Desktop^.StatusBar^.ClearText;
end;

procedure TPopUp.Init;
begin
  inherited Init;
end;

destructor TPopUp.Free;
var
  rect: TRect;
begin
  GetBounds(rect);
  inherited Free;
end;

procedure TPopUp.Show;
var
  rect: TRect;
begin
  Visible := true;
  Draw;
end;

procedure TPopUp.Hide;
begin
  inherited Hide;
end;

procedure TButton.MouseDown(var AEvent: TMouseEvent);
var
  index: word;
  control: PControl;
  button: PButton;
begin
  if not (GetVisible and GetEnabled) then
    exit;
  if CanFocus then
    Focus;
  IsLeftMouseDown := bsLeft in AEvent.NewMouseState.ButtonState;
  IsRightMouseDown := bsRight in AEvent.NewMouseState.ButtonState;
  Down := true;
  Draw;
end;

procedure TButton.MouseClick(var AEvent: TMouseEvent);
begin
  if not Toggle then begin
    Down := false;
    Draw;
  end;
  inherited MouseClick(AEvent);
end;

constructor TLabel.CreateText(const AId, AText: string; AParent: PControl);
begin
  inherited CreateParent(AId, AParent);
  SetText(AText);
end;

procedure TLabel.Clear;
var
  rect: TRect;
begin
  StartDrawing;
  GetScreenBounds(rect);
  Graph^.SetForeColor(ForeColor);
  Graph^.SetBackColor(BackColor);
  Graph^.FillRect(rect);
  SetText('');
  EndDrawing;
end;

procedure TLabel.Init;
begin
  inherited Init;
  Drawbackground := false;
  Autosize := true;
  ForeColor := Desktop^.Colors^.Window;
  BackColor := Desktop^.Colors^.WindowBack;
  BorderColor := Desktop^.Colors^.Border;
  BorderStyle := bsNone;
  TextAlign := taLeft;
  Margin := 0;
  HighlightColor := Desktop^.Colors^.ButtonHighlight;
end;

procedure TLabel.Paint;
begin
  inherited Paint;
end;

procedure TLabel.SetupControls;
begin
  if AutoSize then begin
    Width := Font^.TextWidthLarge(Text);
    Height := Font^.Height;
  end;
end;

destructor TLabel.Free;
begin
  inherited Free;
end;

procedure TMouseEvent.Init;
begin
  inherited Init;
  NewMouseState.Create;
  OldMouseState.Create;
  Clear;
end;

procedure TMouseEvent.Clear;
begin
  inherited Clear;
  OldMouseState.Clear;
  NewMouseState.Clear;
  X := 0;
  Y := 0;
end;

procedure TKeyEvent.Init;
begin
  inherited Init;
  Key := 0;
end;

procedure TKeyEvent.Clear;
begin
  inherited Clear;
  Key := 0;
end;

end.