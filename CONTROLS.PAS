{$IFDEF debug}
  {$A-,B-,D+,F+,G-,I+,L+,N+,O+,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,F+,G-,I+,L-,N+,O+,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}
unit Controls;

interface

uses
  Objects,
  Lists,
  Consts,
  Drawing,
  GraphDrv,
  GrDrv8,
  MouseDrv,
  Streams,
  Strings,
  StrUtils,
  KeyDrv,
  Actions,
  DateTime,
  FileUtil,
  Common;

type
  TBorderStyle =
  (
    bsNone,
    bsSingle
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
  PTMouseEventProc = ^TMouseEventProc;
  PKeyEventProc = ^TKeyEventProc;
  PDragEventProc = ^TDragEventProc;

  TEvent = object(TObject)
  private
  public
    Handled: boolean;
    procedure Init; virtual;
    procedure Clear; virtual;
  end;

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

  TDragEvent = object(TMouseEvent)
  private
  public
  end;

  TEventProc = procedure(ASender: PObject; var AEvent: TEvent);
  TMouseEventProc = procedure(ASender: PObject; var AMouseEvent: TEvent);
  TKeyEventProc = procedure(ASender: PObject; var AKeyEvent: TEvent);
  TDragEventProc = procedure(ASender: PObject; var ADragEvent: TEvent);

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
    OnMouseMove: PEventProc;
    OnMouseUp: PEventProc;
    OnMouseDown: PEventProc;
    OnMouseClick: PEventProc;
    OnMouseEnter: PEventProc;
    OnMouseLeave: PEventProc;
    OnKeyPress: PEventProc;
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
    Draggable: boolean;
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
    procedure Init; virtual;
    procedure Hide; virtual;
    procedure Show; virtual;
    procedure Draw; virtual;
    procedure DrawSelf; virtual;
    procedure Paint; virtual;
    procedure PaintRegion(AScreenRect: TRect; AExclude: PControl); virtual;
    procedure PaintOccludingControls(AControl: PControl); virtual;
    {Get bounds of this control relative to parent client rect}
    procedure GetBounds(var ARect: TRect); virtual;
    {Set bounds relative to parent client rect}
    procedure SetBounds(AX, AY, AWidth, AHeight: integer); virtual;
    {Set bounds rectangle relative to parent client rect}
    procedure SetBoundsRect(ARect: TRect); virtual;
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
    procedure MouseClick(var AEvent: TMouseEvent); virtual;
    procedure MouseEnter(var AEvent: TMouseEvent); virtual;
    procedure MouseLeave(var AEvent: TMouseEvent); virtual;
    procedure DragStart(var AEvent: TDragEvent); virtual;
    procedure DragEnd(var AEvent: TDragEvent); virtual;
    procedure Focus; virtual;
    procedure Unfocus; virtual;
    procedure SetFocus(AFocused, ARedraw: boolean);
    procedure KeyPress(var AEvent: TKeyEvent); virtual;
    procedure StartDrawing; virtual;
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
  public
    DrawBackground: boolean;
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
    TextOffsetX: byte;
    TextOffsetY: byte;
    destructor Free; virtual;
    function GetText: string; virtual;
    procedure Init; virtual;
    procedure SetText(const AText: string); virtual;
    procedure Paint; virtual;
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
    procedure Init; virtual;
    procedure Paint; virtual;
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
    DisabledColor: byte;
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
    BackRect: TRect;
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
begin
  index := IndexOf(AControl);
  if index < 0 then
    exit;
  Delete(index);
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
  OnMouseUp := nil;
  OnMouseDown := nil;
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
  Draggable := false;
  Parent := nil;
  Font := Desktop^.Font;
  MouseCursor := Application^.MouseCursors^.GetItemById('Default');
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

procedure TControl.MouseMove(var AEvent: TMouseEvent);
begin
  if Assigned(OnMouseMove) then
    TEventProc(OnMouseMove)(@self, AEvent);
end;

procedure TControl.MouseUp(var AEvent: TMouseEvent);
begin
  if Assigned(OnMouseUp) then
    TEventProc(OnMouseUp)(@self, AEvent);
end;

procedure TControl.MouseDown(var AEvent: TMouseEvent);
begin
  if Assigned(OnMouseDown) then
    TEventProc(OnMouseDown)(@self, AEvent);
end;

procedure TControl.MouseEnter(var AEvent: TMouseEvent);
begin
  if Assigned(OnMouseEnter) then
    TEventProc(OnMouseEnter)(@self, AEvent);
end;

procedure TControl.MouseLeave(var AEvent: TMouseEvent);
begin;
  if Assigned(OnMouseLeave) then
    TEventProc(OnMouseLeave)(@self, AEvent);
end;

procedure TControl.MouseClick(var AEvent: TMouseEvent);
begin
  if Assigned(OnMouseClick) then
    TEventProc(OnMouseClick)(@self, AEvent);
end;

procedure TControl.DragStart(var AEvent: TDragEvent);
begin
  if Assigned(OnDragStart) then
    TEventProc(OnDragStart)(@self, AEvent);
end;

procedure TControl.DragEnd(var AEvent: TDragEvent);
begin
  if Assigned(OnDragEnd) then
    TEventProc(OnDragEnd)(@self, AEvent);
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
      Application^.CursorBlinkTime.SetNow;
      Application^.CursorOn;
    end
  end
  else begin
    Desktop^.ActiveControl := nil;
    if ARedraw then
      Draw;
    if UsesCursor then
      Application^.CursorOff;
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

procedure TControl.BringToFront;
var
  index: integer;
  last: integer;
begin
  if (Parent = nil) or (Parent^.Controls^.Count < 2) then
    exit;
  last := Parent^.Controls^.Count - 1;
  index := Parent^.Controls^.IndexOf(@self);
  if index = last then
    exit;
  Parent^.Controls^.Swap(index, last);
end;

procedure TControl.SendToBack;
var
  index: integer;
begin
  if (Parent = nil) or (Parent^.Controls^.Count < 2) then
    exit;
  index := Parent^.Controls^.IndexOf(@self);
  if index = 0 then
    exit;
  Parent^.Controls^.Swap(0, index);
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
  if (not Visible) then exit;
  par := Parent;
  while Assigned(par) do begin
    if (not par^.Visible) then exit;
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
  if (not Enabled) then exit;
  par := Parent;
  while Assigned(par) do begin
    if (not par^.Enabled) then exit;
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
  Desktop^.PaintRegion(rect, @self);
end;

procedure TControl.Show;
begin
  Visible := true;
  Draw;
end;

procedure TControl.PaintOccludingControls(AControl: PControl);
var
  rect, drawRect, controlRect: TRect;
  controlParent: PControl;
  control: PControl;
  index, controlIndex: integer;
begin
  if not Assigned(AControl) then
    exit;
  controlParent := AControl^.Parent;
  if Assigned(controlParent) then begin
    controlIndex := controlParent^.Controls^.IndexOf(AControl);
    if controlIndex >= controlParent^.Controls^.Count - 1 then begin
      PaintOccludingControls(controlParent^.Parent);
      exit;
    end;
    for index := controlIndex + 1 to controlParent^.Controls^.Count - 1 do begin
      control := controlParent^.Controls^.GetItem(index);
      AControl^.GetScreenBounds(rect);
      control^.GetScreenBounds(controlRect);
      rect.GetIntersection(controlRect, drawRect);
      if drawRect.IsEmpty then
        continue;
      control^.PaintRegion(drawRect, control);
    end;
    PaintOccludingControls(controlParent^.Controls^.GetItem(controlIndex + 1));
  end;
end;

procedure TControl.Paint;
begin
  Graph^.State.Font := Font;
end;

procedure TControl.PaintRegion(AScreenRect: TRect; AExclude: PControl);
var
  index: integer;
  control: PControl;
  rect, controlRect: TRect;
begin
  Application^.PushState;
  Application^.CursorOff;
  Graph^.PushState;
  GetScreenBounds(rect);
  rect.Intersect(AScreenRect);
  Graph^.State.ViewPort := rect;
  Paint;
  if Controls^.Count > 0 then begin
    for index := 0 to Controls^.Count - 1 do begin
      control := Controls^.GetItem(index);
      control^.GetScreenBounds(controlRect);
      controlRect.Intersect(AScreenRect);
      if (control = AExclude)
        or controlRect.IsEmpty
        or (not control^.GetVisible) then
        continue;
      control^.PaintRegion(controlRect, control);
    end;
  end;
  Graph^.PopState;
  Application^.PopState;
end;

procedure TControl.DrawSelf;
begin
  if not Application^.DrawEnabled then
    exit;
  if not GetVisible then
    exit;
  StartDrawing;
  Paint;
  PaintOccludingControls(@self);
  EndDrawing;
end;

procedure TControl.Draw;
begin
  if not Application^.DrawEnabled then
    exit;
  if not GetVisible then
    exit;
  StartDrawing;
  Paint;
{  PaintOccludingControls(@self);}
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
var
  rect, mouseRect: TRect;
begin
  Mouse.PushState;
  Graph^.PushState;
  SetupControls;
  GetScreenBounds(rect);
  MouseRect.CreateDims(Graph8^.MouseCursor^.X, Graph8^.MouseCursor^.Y,
    Graph8^.MouseCursor^.Width, Graph8^.MouseCursor^.Height);
  if rect.IntersectsRect(mouseRect) then
    Graph8^.HideMouseCursor;
  Graph^.SetForeColor(ForeColor);
  Graph^.SetBackColor(BackColor);
  GetScreenBounds(rect);
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
  if Controls^.Count = 0 then
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
    Application^.HandleActionExecute(Action, Action^.ActionId);
  end;
  if AEvent.Handled then
    exit;
  inherited MouseClick(AEvent);
end;

destructor TActionControl.Free;
begin
  TString.Dispose(ShortcutDisplayName);
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
  DisabledForeColor := Desktop^.InterfaceColors^.ButtonDisabled;
end;

procedure TActionControl.Paint;
var
  textXPos, textYPos: integer;
  shortcutDesc: string;
  rect: TRect;
begin
  inherited Paint;
  GetScreenBounds(rect);
  Graph^.SetForeColor(ForeColor);
  if (GetShortcut >= 0) and ShowShortcut then begin
    case VertAlign of
      vaTop: textYPos := rect.Y + BorderWidth;
      vaBottom: textYPos := rect.Y + rect.Height - Font^.Height - BorderWidth;
      vaCenter: textYPos := rect.Y + (rect.Height - Font^.Height) div 2 + 1;
    end;
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
  if not Enabled then
    exit;
  if (ActionId >= 0) and (not Action^.Enabled) then
    exit;
  par := Parent;
  while Assigned(par) do begin
    if (not par^.Enabled) then exit;
    par := par^.Parent;
  end;
  GetEnabled := true;
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
  ForeColor := Desktop^.InterfaceColors^.Border;
end;

procedure THorzSeparator.Paint;
var
  rect: TRect;
begin
  inherited Paint;
  GetScreenBounds(rect);
  Graph^.SetForeColor(ForeColor);
  Graph^.HLine(rect.X, rect.Y, rect.Width);
end;

procedure TPanel.Init;
begin
  inherited Init;
  ForeColor := Desktop^.InterfaceColors^.Window;
  BackColor := Desktop^.InterfaceColors^.WindowBack;
  BorderColor := Desktop^.InterfaceColors^.Border;
  BorderStyle := bsSingle;
  FocusedForeColor := Desktop^.InterfaceColors^.Focused;
  FocusedBackColor := Desktop^.InterfaceColors^.FocusedBack;
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
  end;
  if DrawBackground then begin
    if BorderStyle <> bsNone then begin
      Graph^.FillRect(rect);
      Graph^.SetForeColor(BorderColor);
      Graph^.Rectangle(rect);
    end
    else
      Graph^.FillRect(rect);
  end;
end;

destructor TTextControl.Free;
begin
  TString.Dispose(Text);
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
  textIndex: integer;
  ch: char;
  textWidth: integer;
  txt: string;
begin
  inherited Paint;
  if not GetVisible then
    exit;
  GetScreenBounds(rect);
  txt := GetText;
  if txt = '' then
    exit;
  textWidth := TrueTextWidth(GetText);
  case TextAlign of
    taLeft: textXPos := rect.X + Margin;
    taRight: textXPos := rect.X + rect.Width - textWidth - Margin;
    taCenter: textXPos := rect.X + (rect.Width - textWidth) div 2 + 1;
  end;
  case VertAlign of
    vaTop: textYPos := rect.Y + Margin;
    vaBottom: textYPos := rect.Y + rect.Height - Font^.Height - Margin;
    vaCenter: textYPos := rect.Y + (rect.Height - Font^.Height) div 2 + 1;
  end;
  textIndex := 1;
  while textIndex <= Length(txt) do begin
    Graph^.SetForeColor(ForeColor);
    if txt[textIndex] = '&' then begin
      if GetEnabled then
        Graph^.SetForeColor(HighlightColor);
      Inc(textIndex);
    end;
    ch := txt[textIndex];
    Graph^.DrawText(textXPos + TextOffsetX, textYPos + TextOffsetY, ch);
    Inc(textXPos, Font^.TextWidth(ch));
    Inc(textIndex);
  end;
end;

procedure TButton.Init;
begin
  inherited Init;
  Clickable := true;
  CanFocus := true;
  Active := false;
  ShowShortcut := false;
  IsMouseOver := false;
  ForeColor := Desktop^.InterfaceColors^.Button;
  BackColor := Desktop^.InterfaceColors^.ButtonBack;
  LightColor := Desktop^.InterfaceColors^.ButtonLight;
  BorderStyle := bsNone;
  Down := false;
  Toggle := false;
  Grouped := false;
  TextAlign := taCenter;
  BorderStyle := bsSingle;
  ForeColor := Desktop^.InterfaceColors^.Button;
  BackColor := Desktop^.InterfaceColors^.ButtonBack;
  ShadowColor := Desktop^.InterfaceColors^.ButtonShadow;
  HighlightColor := Desktop^.InterfaceColors^.ButtonHighlight;
  DownBackColor := Desktop^.InterfaceColors^.ButtonDownBack;
  DownShadowColor := Desktop^.InterfaceColors^.ButtonDownShadow;
  DownLightColor := Desktop^.InterfaceColors^.ButtonDownLight;
  DisabledColor := Desktop^.InterfaceColors^.ButtonDisabled;
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
  oldOffsetX: byte;
  oldOffsetY: byte;
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
  if Application^.LeftMouseDownControl = @self then begin
    Down := true;
    DrawSelf;
  end;
  Desktop^.StatusBar^.ShowActionHelp(Action);
end;

procedure TButton.MouseLeave(var AEvent: TMouseEvent);
begin
  if not (GetEnabled and GetVisible) then
    exit;
  if Application^.LeftMouseDownControl = @self then begin
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
var
  rect: TRect;
begin
  StartDrawing;
  GetScreenBounds(rect);
  Desktop^.PaintRegion(rect, @self);
  Visible := false;
  EndDrawing;
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

procedure TLabel.Init;
begin
  inherited Init;
  Drawbackground := false;
  Autosize := true;
  ForeColor := Desktop^.InterfaceColors^.Window;
  BackColor := Desktop^.InterfaceColors^.WindowBack;
  BorderColor := Desktop^.InterfaceColors^.Border;
  BorderStyle := bsNone;
  TextAlign := taLeft;
  Margin := 0;
  HighlightColor := Desktop^.InterfaceColors^.ButtonHighlight;
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
  OldMouseState.Create;
  NewMouseState.Create;
  X := 0;
  Y := 0;
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

procedure TEvent.Clear;
begin
  Handled := false;
end;

procedure TEvent.Init;
begin
  inherited Init;
  Handled := false;
end;

end.