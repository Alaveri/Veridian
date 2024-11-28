{$I COMPILER.INC}
unit Veridian;

interface

uses
  AplObj,
  AplDos,
  AplTypes,
  AplConst,
  Drawing,
  Lists,
  Graphics,
  Gr8Drv,
  GraphIni,
  GraphApp,
  MouseDrv,
  MemDrv,
  DateTime,
  Streams,
  Actions,
  Colors,
  Controls,
  Views,
  Events,
  Menus;

const
  DefaultDoubleClickDelay: double = 1;
  DefaultCursorBlinkRate = 0.4;
  DefaultMouseSensitivity = 4;

type
  PVeridianApp = ^TVeridianApp;
  PVeridianAction = ^TVeridianAction;
  PVeridianAppSettings = ^TVeridianAppSettings;
  PAppState = ^TAppState;

  TVeridianAppSettings = object(TPersistent)
  private
  public
    CursorBlinkRate: double;
    UpdateScrollContents: boolean;
    DoubleClickDelay: TTimeSpan;
    MouseSensitivity: real;
    procedure Init; virtual;
    procedure Assign(var ASource: TObject); virtual;
    procedure SaveToStream(AStream: PStream); virtual;
    procedure LoadFromStream(AStream: PStream); virtual;
  end;

  TAppState = object(TObject)
  private
  public
    CursorOn: boolean;
    DrawEnabled: boolean;
    MouseVisible: boolean;
    procedure Init; virtual;
    procedure Assign(var ASource: TObject); virtual;
  end;

  TVeridianApp = object(TGraphApp)
  private
    {$IFDEF debug}
    FMemAvail: longint;
    FMemMaxAvail: longint;
    FMemLabel: PLabel;
    {$ENDIF}
    FKeyEvent: TKeyEvent;
    FMouseEvent: TMouseEvent;
    FMouseState, FOldMouseState: TMouseState;
    FCursorBlinkVisible: boolean;
    FBlinkCurrentTime: TDateTime;
    FBlinkElapsed: TTimeSpan;
    FDoubleClickStart: TDateTime;
    function LoadFont(const AFilename: string): PFont;
    function CreateDesktop: PDesktop; virtual;
    procedure CreateObjects;
    procedure LoadFonts;
    procedure HandleKeyEvent(AControl: PControl; var AEvent: TKeyEvent);
    procedure HandleSpecialKeys(AControl: PControl; var AEvent: TKeyEvent);
    procedure HandleActionKeys(AControl: PActionControl; var AEvent: TKeyEvent);
    procedure HandleMouseEvent(AControl: PControl; var AEvent: TMouseEvent);
    procedure HandleMouseMove(AControl: PControl;
      var AEvent: TMouseEvent); virtual;
    procedure HandleMouseEnter(AControl: PControl;
      var AEvent: TMouseEvent); virtual;
    procedure HandleMouseWheelChanged(AControl: PControl;
      var AEvent: TMouseEvent); virtual;
    procedure HandleMouseUp(AControl: PControl; var AEvent: TMouseEvent;
      AButton: TButtonState); virtual;
    procedure HandleMouseDown(AControl: PControl; var AEvent: TMouseEvent;
      AButton: TButtonState); virtual;
    procedure HandleMouseCursor;
    procedure HandleStayOnTopControls;
    procedure InitMouseEvent(AControl: PControl; var AEvent: TMouseEvent);
    procedure GetFocusList(AList: PObjectList; AControl: PControl);
    procedure DrawCursor;
    procedure HandleCursor;
    procedure ApplySettings;
    procedure SetMouseSensitivity(ASens: real);
    procedure ParseParameters;
    {$IFDEF debug}
    procedure UpdateDebugInfo;
    {$ENDIF}
  public
    State: TAppState;
    StateStack: TObjectStack;
    Colors: TColors;
    ActiveControl: PFocusControl;
    ActiveWindow: PWindow;
    DragRect, LastDragRect: TRect;
    DragRectVisible: boolean;
    MouseOverControl: PControl;
    LeftMouseDownControl: PControl;
    RightMouseDownControl: PControl;
    DragControl: PControl;
    DragInitialPos: TPoint;
    SelectingControl: PControl;
    MenuBar: PMenubar;
    Taskbar: PTaskbar;
    Fonts: PFontList;
    SystemFont: PFont;
    SymbolFont: PFont;
    EditorFont: PFont;
    Settings: TVeridianAppSettings;
    CursorBlinkTime: TDateTime;
    AppDir: string;
    Parameters: TStringList;
    constructor Create(ADriver: TGraphDrivers; AWidth: integer;
      AHeight: integer; ABpp: integer);
    destructor Free; virtual;
    function CheckNilPtr(APtr: pointer): boolean;
    procedure ProcessEvents; virtual;
    procedure Run; virtual;
    procedure Init; virtual;
    procedure CursorOn; virtual;
    procedure CursorOff; virtual;
    procedure PushState; virtual;
    procedure PopState; virtual;
    procedure SetColors(const AColors: TColors); virtual;
    procedure InitActions; virtual;
    procedure InitControls; virtual;
    procedure Initialized; virtual;
    procedure ActionExecute(ASender: PActionControl; AAction: PAction); virtual;
    procedure UpdateActionControl(AControl: PActionControl); virtual;
    procedure SetActiveControl(AControl: PFocusControl);
    procedure CloseAllMenus;
    function FocusNext(AControl: PControl; AReverse: boolean): boolean;
    function GetMouseControl(AControl: PControl; var AMouseState: TMouseState): PControl;
  end;

  TVeridianAction = object(TAction)
  private
  public
    procedure Execute(ASender: PObject); virtual;
  end;

var
  VeridianApp: PVeridianApp;

implementation

uses
  AplUtils,
  Dos,
  KeyDrv;

var
  PreviousExitProc: PProc;

procedure OnAllocError(ASize: word); far;
begin
  with VeridianApp^ do begin
  end;
end;

constructor TVeridianApp.Create(ADriver: TGraphDrivers; AWidth: integer;
  AHeight: integer; ABpp: integer);
var
  modeId: integer;
begin
  VeridianApp := @self;
  inherited Create(ADriver);
  if CheckReRaise(Graph) then begin
    VeridianApp := nil;
    exit;
  end;
  modeId := GetGraphicsModeId(AWidth, AHeight, ABpp);
  if not SetMode(modeId) then begin
    VeridianApp := nil;
    Raise(ecGraphicsModeNotFound);
    exit;
  end;
  Initialized;
end;

procedure TVeridianApp.Initialized;
begin
  LoadFonts;
  Desktop := CreateDesktop;
  Desktop^.Font := SystemFont;
  InitActions;
  InitControls;
  Desktop^.Layout;
  MenuBar^.Layout;
end;

destructor TVeridianApp.Free;
begin
  StateStack.DisposeObjects := true;
  StateStack.Free;
  Parameters.Free;
  inherited Free;
end;

procedure TVeridianApp.InitActions;
begin
end;

procedure TVeridianApp.InitControls;
var
  rect: TRect;
begin
  MenuBar := New(PMenuBar, Create);
  Taskbar := New(PTaskbar, Create);
  {$IFDEF debug}
  FMemLabel := New(PLabel, CreateParent('MemLabel', MenuBar));
  FMemLabel^.TransparentBack := false;
  FMemLabel^.SetForeColor(MenuBar^.ForeColor);
  FMemLabel^.SetBackColor(MenuBar^.BackColor);
  FMemLabel^.Font := Fonts^.GetItemById('editor');
  {$ENDIF}
end;

function TVeridianApp.LoadFont(const AFilename: string): PFont;
var
  newFont: PFont;
begin
  if FileExists(AFilename) then begin
    newFont := New(PProportionalFont, Create);
    newFont^.LoadFromFile(AFilename);
    if newFont^.HasException then begin
      newFont^.ClearException;
      newFont := New(PSystemFont, CreateId('System'));
    end;
  end
  else
    newFont := New(PSystemFont, CreateId('System'));
  LoadFont := newFont;
  Fonts^.Add(newFont);
end;

procedure TVeridianApp.LoadFonts;
var
  font: PFont;
begin
  Fonts := New(PFontList, Create);
  if Graph^.Mode^.Width <= 320 then begin
  end
  else begin
    font := LoadFont('system.fnt');
    font^.SetId('system');
    SystemFont := font;
    font := LoadFont('seattle.fnt');
    font^.SetId('editor');
    EditorFont := font;
    font := LoadFont('symbol.fnt');
    font^.SetId('symbol');
    SymbolFont := font;
  end;
end;

procedure TVeridianApp.CreateObjects;
begin
  FKeyEvent.Create;
  FMouseEvent.Create;
  FMouseState.Create;
  FOldMouseState.Create;
  FBlinkElapsed.Create;
  FDoubleClickStart.Create;
  FBlinkCurrentTime.Create;
  CursorBlinkTime.Create;
  StateStack.Create;
  Settings.Create;
  DragRect.Create;
  LastDragRect.Create;
  Colors := LightColors;
  State.Create;
  DragInitialPos.Create;
  Parameters.Create;
  ParseParameters;
end;

procedure TVeridianApp.Init;
begin
  inherited Init;
  Memory.OnAllocError := @OnAllocError;
  FCursorBlinkVisible := false;
  CreateObjects;
  MenuBar := nil;
  ActiveControl := nil;
  ActiveWindow := nil;
  MouseOverControl := nil;
  LeftMouseDownControl := nil;
  RightMouseDownControl := nil;
  SelectingControl := nil;
  DragControl := nil;
  Mouse.UseSystemCursor := false;
  Mouse.HideMouse;
  DragRectVisible := false;
  {$IFDEF debug}
  FMemAvail := MemAvail;
  FMemMaxAvail := MaxAvail;
  FMemLabel := nil;
  {$ENDIF}
end;

function TVeridianApp.CreateDesktop: PDesktop;
begin
  CreateDesktop := New(PDesktop, CreateParent('Desktop', nil));
end;

procedure TVeridianApp.UpdateActionControl(AControl: PActionControl);
begin
end;

procedure TVeridianApp.ActionExecute(ASender: PActionControl; AAction: PAction);
begin
  if not (Assigned(AAction) and Assigned(ASender)) then
    exit;
  UpdateActionControl(ASender);
  if not (ASender^.IsVisibleAndEnabled and AAction^.Enabled) then
    exit;
  if Assigned(AAction^.OnExecute) then begin
    TActionExecuteProc(AAction^.OnExecute)(ASender, AAction);
  end;
end;

procedure TVeridianApp.HandleMouseEnter(AControl: PControl; var AEvent: TMouseEvent);
var
  index: integer;
  control: PControl;
begin
  if Assigned(DragControl) then
    exit;
  if Assigned(MouseOverControl) and (MouseOverControl <> AControl) then begin
    MouseOverControl^.MouseLeave(AEvent);
    MouseOverControl := nil;
  end;
  if AControl^.IsMouseOver then
    exit;
  MouseOverControl := AControl;
  if (MouseCursor <> AControl^.MouseCursor) then begin
    EraseMouseCursor(AEvent.NewMouseState);
    MouseCursor := AControl^.MouseCursor;
    DrawMouseCursor(AEvent.NewMouseState);
  end;
  AControl^.MouseEnter(AEvent);
end;

procedure TVeridianApp.HandleMouseMove(AControl: PControl; var AEvent: TMouseEvent);
begin
  AControl^.MouseMove(AEvent);
end;

procedure TVeridianApp.HandleMouseWheelChanged(AControl: PControl; var AEvent: TMouseEvent);
var
  rect: TRect;
begin
  AControl^.GetScreenBounds(rect);
  if rect.Contains(AEvent.NewMouseState.X, AEvent.NewMouseState.Y) then begin
    AControl^.MouseWheelChanged(AEvent);
  end;
end;

procedure TVeridianApp.HandleMouseUp(AControl: PControl; var AEvent: TMouseEvent;
  AButton: TButtonState);
var
  selecting: boolean;
  dragEvent: TDragEvent;
begin
  if AButton in AEvent.NewMouseState.ButtonState then
    exit;
  if not (AButton in AEvent.OldMouseState.ButtonState) then
    exit;

  if Assigned(DragControl) then begin
    dragEvent.Create;
    dragEvent.InitialX := DragInitialPos.X;
    dragEvent.InitialY := DragInitialPos.Y;
    dragEvent.X := AEvent.NewMouseState.X;
    dragEvent.Y := AEvent.NewMouseState.Y;
    DragControl^.DragEnd(dragEvent);
  end;
  DragControl := nil;

  selecting := false;
{  selecting := SelectingControl = AControl;
  SelectingControl := nil;}
  if ((LeftMouseDownControl = AControl) and (AButton = bsLeft))
      or ((RightMouseDownControl = AControl) and (AButton = bsRight)) or selecting then begin
    AControl^.MouseUp(AEvent);
    AControl^.MouseClick(AEvent);
    {HandleDblClick(now, AControl, AEvent);}
  end;

  if AButton = bsLeft then
    LeftMouseDownControl := nil
  else
    RightMouseDownControl := nil;
end;

procedure TVeridianApp.HandleMouseDown(AControl: PControl; var AEvent: TMouseEvent;
  AButton: TButtonState);
var
  rect: TRect;
  intersects: boolean;
  container: PMenuItemContainer;
  index: integer;
begin
  if not (AButton in AEvent.NewMouseState.ButtonState) then
    exit;
  if AButton in AEvent.OldMouseState.ButtonState then
    exit;

  intersects := false;
  for index := 0 to MenuManager.OpenMenus^.Count - 1 do begin
    container := MenuManager.OpenMenus^.GetItem(index);
    container^.GetScreenBounds(rect);
    if rect.Contains(AEvent.NewMouseState.X, AEvent.NewMouseState.Y) then
      intersects := true;
    if Assigned(container^.ParentMenuItem) then begin
      container^.ParentMenuItem^.GetScreenBounds(rect);
      if rect.Contains(AEvent.NewMouseState.X, AEvent.NewMouseState.Y) then
        intersects := true;
    end;
  end;
  if not intersects then
    MenuManager.CloseAllMenus;

  if AButton = bsLeft then
    LeftMouseDownControl := AControl
  else
    RightMouseDownControl := AControl;

  AControl^.MouseDown(AEvent);
end;

procedure TVeridianApp.HandleCursor;
var
  seconds: Double;
begin
  if not Assigned(ActiveControl) then
    exit;
  if not ActiveControl^.Focused then
    exit;
  if not ActiveControl^.UsesCursor then
    exit;
  if State.CursorOn then begin
    FBlinkCurrentTime.SetNow;
    FBlinkElapsed.Ticks := FBlinkCurrentTime.Ticks - CursorBlinkTime.Ticks;
    seconds := FBlinkElapsed.TotalSeconds;
    if seconds > Settings.CursorBlinkRate then begin
      FCursorBlinkVisible := not FCursorBlinkVisible;
      CursorBlinkTime.SetNow;
      DrawCursor;
    end;
  end;
end;

procedure TVeridianApp.InitMouseEvent(AControl: PControl; var AEvent: TMouseEvent);
var
  rect: TRect;
begin
  AEvent.Clear;
  AEvent.NewMouseState.Assign(FMouseState);
  AEvent.OldMouseState.Assign(FOldMouseState);
  AEvent.X := AEvent.NewMouseState.X;
  AEvent.Y := AEvent.NewMouseState.Y;

  { Get the state in relation to the control's coordinates }
  AControl^.GetScreenBounds(rect);
  Dec(AEvent.X, rect.X);
  Dec(AEvent.Y, rect.Y);
end;

function TVeridianApp.GetMouseControl(AControl: PControl; var AMouseState: TMouseState): PControl;
var
  index: integer;
  rect: TRect;
  result: PControl;
  control: PControl;
  intersects: boolean;
begin
  GetMouseControl := nil;
  for index := AControl^.Controls^.Count - 1 downto 0 do begin
    control := AControl^.Controls^.GetItem(index);
    if not control^.IsVisible then
      continue;
    control := GetMouseControl(control, AMouseState);
    if Assigned(control) then begin
      GetMouseControl := control;
      exit;
    end;
  end;
  AControl^.GetScreenBounds(rect);
  if (AControl^.Modal and (PControl(VeridianApp^.ActiveWindow) = AControl))
    or (VeridianApp^.SelectingControl = AControl)
    or (rect.Contains(AMouseState.X, AMouseState.Y)) then
    GetMouseControl := AControl;
end;

procedure TVeridianApp.HandleMouseEvent(AControl: PControl;  var AEvent: TMouseEvent);
var
  index: integer;
  control: PControl;
  dragEvent: TDragEvent;
begin
  if AEvent.Handled then
    exit;
  control := GetMouseControl(Desktop, AEvent.NewMouseState);

  InitMouseEvent(control, FMouseEvent);
  InitMouseEvent(control, FMouseEvent);
  if (FMouseState.WheelCounter <> FOldMouseState.WheelCounter) then
    HandleMouseWheelChanged(control, FMouseEvent);
  if (FMouseState.ButtonState <> FOldMouseState.ButtonState) then begin
    HandleMouseDown(control, FMouseEvent, bsLeft);
    HandleMouseDown(control, FMouseEvent, bsRight);
    HandleMouseUp(control, FMouseEvent, bsLeft);
    HandleMouseUp(control, FMouseEvent, bsRight);
  end;
  if (FMouseState.X <> FOldMouseState.X) or (FMouseState.Y <> FOldMouseState.Y) then begin
{    if Assigned(CurrentScrollSlider) then
      PScrollSlider(CurrentScrollSlider)^.ProcessMouseMove(FMouseEvent);}
    HandleMouseMove(control, FMouseEvent);
    if Assigned(DragControl) then begin
      dragEvent.Create;
      dragEvent.InitialX := DragInitialPos.X;
      dragEvent.InitialY := DragInitialPos.Y;
      dragEvent.X := AEvent.NewMouseState.X;
      dragEvent.Y := AEvent.NewMouseState.Y;
      DragControl^.DragMove(dragEvent);
    end;
    if Assigned(LeftMouseDownControl) and LeftMouseDownControl^.CanDrag
      and not Assigned(DragControl) then begin
      DragControl := LeftMouseDownControl;
      DragInitialPos.SetCoords(AEvent.NewMouseState.X, AEvent.NewMouseState.Y);
      dragEvent.Create;
      dragEvent.InitialX := DragInitialPos.X;
      dragEvent.InitialY := DragInitialPos.Y;
      dragEvent.X := DragInitialPos.X;
      dragEvent.Y := DragInitialPos.Y;
      LeftMouseDownControl^.DragStart(dragEvent);
    end;
    HandleMouseEnter(control, FMouseEvent);
  end;
end;

procedure TVeridianApp.HandleActionKeys(AControl: PActionControl; var AEvent: TKeyEvent);
var
  index: integer;
  action: PAction;
begin
  for index := 0 to Desktop^.ActionList^.Count - 1 do begin
    action := Desktop^.ActionList^.GetItem(index);
    if (action^.Shortcut <> AEvent.Key) or not action^.Enabled then
      continue;
    ActionExecute(AControl, action);
    AEvent.Handled := true;
    break;
  end;
end;

procedure TVeridianApp.GetFocusList(AList: PObjectList; AControl: PControl);
var
  control: PControl;
  focusControl: PFocusControl;
  index: integer;
begin
  for index := 0 to AControl^.Controls^.Count - 1 do begin
    control := AControl^.Controls^.GetItem(index);
    GetFocusList(AList, control);
    if control^.IsFocusControl then begin
      focusControl := PFocusControl(control);
      if focusControl^.IsVisibleAndEnabled then
        AList^.Add(control);
    end;
  end;
end;

function TVeridianApp.FocusNext(AControl: PControl; AReverse: boolean): boolean;
var
  parent: PControl;
  current: PControl;
  next: PFocusControl;
  focusList: PObjectList;
  controlIndex: integer;
  currentIndex: integer;
begin
  parent := AControl^.Parent;
  current := parent;
  while Assigned(current^.Parent) do
    current := current^.Parent;
  if not Assigned(current) then
    exit;
  focusList := New(PObjectList, Create);
  focusList^.DisposeObjects := false;
  GetFocusList(focusList, Desktop);
  controlIndex := focusList^.IndexOf(AControl);
  if AReverse then begin
    currentIndex := controlIndex - 1;
    if currentIndex < 0 then
      currentIndex := focusList^.Count - 1;
  end
  else begin
    currentIndex := controlIndex + 1;
    if currentIndex > focusList^.Count - 1 then
      currentIndex := 0;
  end;
  if currentIndex <> controlIndex then begin
    next := PFocusControl(focusList^.GetItem(currentIndex));
    next^.Focus;
  end;
  FreeAndNil(focusList);
end;

procedure TVeridianApp.HandleSpecialKeys(AControl: PControl; var AEvent: TKeyEvent);
var
  container: PMenuItemContainer;
begin
  case AEvent.Key of
    kyTab: begin
      if not (Assigned(ActiveControl) or ActiveControl^.AcceptsTab) then
        exit;
      if not ActiveControl^.CanFocus then
        exit;
      MenuManager.CloseAllMenus;
      FocusNext(ActiveControl, false);
      AEvent.Handled := true;
      exit;
    end;
    kyShiftTab: begin
      if not (Assigned(ActiveControl) or ActiveControl^.AcceptsTab) then
        exit;
      if not ActiveControl^.CanFocus then
        exit;
      MenuManager.CloseAllMenus;
      FocusNext(ActiveControl, true);
      AEvent.Handled := true;
      exit;
    end;
    kyEsc: begin
      container := MenuManager.PopAndCloseMenu;
      AEvent.Handled := true;
    end;
  end;
  if AEvent.Handled then
    exit;
  if AControl^.IsActionControl then
    HandleActionKeys(PActionControl(AControl), AEvent);
end;

procedure TVeridianApp.HandleKeyEvent(AControl: PControl; var AEvent: TKeyEvent);
var
  index: integer;
  control: PControl;
  actionControl: PActionControl;
begin
  {$IFDEF debug}
  if AEvent.Key = kyAltZ then begin
    Close;
    exit;
  end;
  {$ENDIF}
  if Assigned(DragControl) then
    exit;
  if not Assigned(Desktop) then
    exit;
  if AEvent.Handled then
    exit;
  HandleSpecialKeys(AControl, AEvent);
  if AEvent.Handled then
    exit;
  for index := 0 to AControl^.Controls^.Count - 1 do begin
    control := AControl^.Controls^.GetItem(index);
    if not control^.IsVisible then
      continue;
    if control^.IsActionControl then begin
      actionControl := PActionControl(control);
      if actionControl^.IsEnabled then
        HandleKeyEvent(actionControl, AEvent);
    end
    else
      HandleKeyEvent(control, AEvent);
    if AEvent.Handled then
      exit;
  end;
  if AEvent.Handled then
    exit;
  AControl^.KeyPress(AEvent);
  if AEvent.Handled then
    exit;
  if Assigned(AControl^.OnKeyPress) then
    TKeyEventProc(AControl^.OnKeyPress)(AControl, AEvent);
end;

procedure TVeridianApp.CursorOn;
begin
  if State.CursorOn then
    exit;
  State.CursorOn := true;
  FCursorBlinkVisible := true;
  CursorBlinkTime.SetNow;
  DrawCursor;
end;

procedure TVeridianApp.CursorOff;
begin
  if not State.CursorOn then
    exit;
  State.CursorOn := false;
  FCursorBlinkVisible := false;
  DrawCursor;
end;

procedure TVeridianApp.DrawCursor;
var
  rect: TRect;
  mouseRect: TRect;
  cursorColor: byte;
begin
  if not State.DrawEnabled then
    exit;
  activeControl := ActiveControl;
  if not Assigned(ActiveControl) then
    exit;
  ActiveControl^.GetCursorRect(rect);
  rect.Intersect(Graph^.State^.ViewPort);
  if rect.IsEmpty then
    exit;
  if FCursorBlinkVisible then
    cursorColor := activeControl^.GetCursorForeColor
  else
    cursorColor := activeControl^.GetCursorBackColor;

  Graph^.SetBackColor(cursorColor);
  Graph^.FillRect(rect);
  RedrawMouseCursor(rect, FMouseState);
end;

procedure TVeridianApp.CloseAllMenus;
begin
  MenuManager.CloseAllMenus;
end;

{$IFDEF debug}
procedure TVeridianApp.UpdateDebugInfo;
var
  txt: string;
  width: word;
  rect: TRect;
begin
  if Assigned(FMemLabel) and Assigned(MenuBar) and
    ((FMemAvail <> MemAvail) or (FMemMaxAvail <> MaxAvail)) then begin
    MenuBar^.GetScreenBounds(rect);
    txt := 'MemAvail: ' + FormatLong(MemAvail) + ' MaxAvail: ' + FormatLong(MaxAvail);
    width := desktop^.Font^.AverageWidth * Length(txt);
    rect.Height := Menubar^.Font^.Height;
    rect.X := rect.Right - width;
    rect.Y := rect.Y + (MenuBar^.Height - MenuBar^.Font^.Height) div 2 + 1;
    FMemLabel^.SetBoundsRect(rect);
    FMemAvail := MemAvail;
    FMemMaxAvail := MaxAvail;
    FMemLabel^.SetCaption(txt);
  end;
end;
{$ENDIF}

procedure TVeridianApp.HandleMouseCursor;
var
  newRect, oldRect: TRect;
begin
  if not Assigned(DragControl) then
    DragRectVisible := false;
  if Assigned(DragControl) and not DragRectVisible then begin
    DragRectVisible := true;
    Graph^.WaitForVSync;
    MoveMouseCursor(FMouseState, FOldMouseState, false);
    Graph^.InverseRectangle(DragRect);
    LastDragRect.Assign(DragRect);
  end
  else if Assigned(DragControl) then begin
    newRect.CreateRect(DragRect);
    oldRect.CreateRect(LastDragRect);
    Graph^.WaitForVSync;
    Graph^.InverseRectangle(oldRect);
    MoveMouseCursor(FMouseState, FOldMouseState, false);
    Graph^.InverseRectangle(newRect);
    MouseCursor^.Draw;
    LastDragRect.Assign(DragRect);
  end
  else
    MoveMouseCursor(FMouseState, FOldMouseState, true);
end;

procedure TVeridianApp.HandleStayOnTopControls;
var
  index: integer;
  control: PControl;
begin
  for index := 0 to Desktop^.Controls^.Count - 1 do begin
    control := Desktop^.Controls^.GetItem(index);
    if not control^.StayOnTop then begin
    end;
  end;
end;

procedure TVeridianApp.ProcessEvents;
var
  ch: word;
begin
  Mouse.UpdateState;
  FMouseState.Assign(Mouse.State);
  HandleCursor;
  if not FMouseState.Equals(FOldMouseState) then begin
    HandleMouseCursor;
    if State.CursorOn then
      DrawCursor;
    FMouseEvent.NewMouseState.Assign(FMouseState);
    FMouseEvent.OldMouseState.Assign(FOldMouseState);
    FMouseEvent.Handled := false;
    HandleMouseEvent(Desktop, FMouseEvent);
    FOldMouseState.Assign(FMouseState);
  end;
  if Keyboard.KeyPressed then begin
    ch := Keyboard.GetKey;
    FKeyEvent.Key := ch;
    FKeyEvent.Handled := false;
    HandleKeyEvent(Desktop, FKeyEvent);
  end;
  {$IFDEF debug}
  UpdateDebugInfo;
  {$ENDIF}
end;

procedure TVeridianApp.PushState;
var
  newState: PAppState;
begin
  newState := New(PAppState, Create);
  newState^.Assign(State);
  StateStack.Push(newState);
end;

procedure TVeridianApp.PopState;
var
  oldState: PAppState;
begin
  oldState := PAppState(StateStack.Pop);
  if not Assigned(oldState) then
    exit;
  State.Assign(oldState^);
  if State.CursorOn then
    CursorOn
  else
    CursorOff;
  FreeAndNil(oldState);
end;

procedure TVeridianApp.ParseParameters;
var
  index: integer;
  dir, name, ext: string;
begin
  FSplit(ParamStr(0), dir, name, ext);
  AppDir := dir;
  for index := 1 to ParamCount do
    Parameters.AddString(ParamStr(index));
end;

function TVeridianApp.CheckNilPtr(APtr: pointer): boolean;
begin
  CheckNilPtr := false;
  if Assigned(APtr) then
    exit;
  CheckNilPtr := true;
  VeridianApp^.Error(self, ecNotEnoughMemory);
end;

procedure TVeridianApp.SetColors(const AColors: TColors);
begin
  Colors := AColors;
  Desktop^.Draw;
end;

procedure TVeridianApp.SetActiveControl(AControl: PFocusControl);
begin
  if not Assigned(AControl) then
    exit;
  if AControl = ActiveControl then
    exit;
  AControl^.Focus;
end;

procedure TVeridianApp.SetMouseSensitivity(ASens: real);
var
  aspectRatio: real;
begin
  aspectRatio := Graph^.Mode^.Height / Graph^.Mode^.Width;
  Mouse.SetSensitivity(ASens, aspectRatio * ASens);
end;

procedure TVeridianApp.ApplySettings;
begin
  SetMouseSensitivity(Settings.MouseSensitivity);
end;

procedure TVeridianApp.Run;
  procedure DoRun(AControl: PControl);
  var
    index: integer;
    control: PControl;
  begin
    for index := 0 to AControl^.Controls^.Count - 1 do begin
      control := AControl^.Controls^.GetItem(index);
      DoRun(control);
    end;
    AControl^.Run;
  end;
begin
  ApplySettings;
  State.DrawEnabled := true;
  {$IFDEF debug}
  UpdateDebugInfo;
  {$ENDIF}
  Desktop^.Draw;
  Mouse.SetMousePosition(Graph^.Mode^.Width div 2, Graph^.Mode^.Height div 2);
  Mouse.ShowMouse;
  ShowMouseCursor;
  FMouseState.Assign(Mouse.State);
  FOldMouseState.Assign(FMouseState);
  DoRun(Desktop);
  if State.CursorOn then
    CursorOn;
  inherited Run;
end;

procedure TAppState.Init;
begin
  inherited Init;
  CursorOn := false;
  MouseVisible := false;
  DrawEnabled := false;
end;

procedure TAppState.Assign(var ASource: TObject);
var
  source: PAppState;
begin
  inherited Assign(ASource);
  source := PAppState(@ASource);
  CursorOn := source^.CursorOn;
  DrawEnabled := source^.DrawEnabled;
  MouseVisible := source^.MouseVisible;
end;

procedure TVeridianAction.Execute(ASender: PObject);
begin
  VeridianApp^.ActionExecute(PActionControl(ASender), @Self);
  inherited Execute(ASender);
end;

procedure TVeridianAppSettings.Init;
begin
  inherited Init;
  CursorBlinkRate := DefaultCursorBlinkRate;
  DoubleClickDelay.CreateSeconds(DefaultDoubleClickDelay);
  MouseSensitivity := DefaultMouseSensitivity;
  UpdateScrollContents := true;
end;

procedure TVeridianAppSettings.Assign(var ASource: TObject);
var
  source: PVeridianAppSettings;
begin
  inherited Assign(ASource);
  source := PVeridianAppSettings(@source);
  CursorBlinkRate := source^.CursorBlinkRate;
  UpdateScrollContents := source^.UpdateScrollContents;
  DoubleClickDelay.Assign(source^.DoubleClickDelay);
  MouseSensitivity := source^.MouseSensitivity;
end;

procedure TVeridianAppSettings.SaveToStream(AStream: PStream);
begin
  AStream^.WriteDouble(CursorBlinkRate);
  AStream^.WriteBool(UpdateScrollContents);
  AStream^.WriteDouble(DoubleClickDelay.Ticks);
  AStream^.WriteDouble(MouseSensitivity);
end;

procedure TVeridianAppSettings.LoadFromStream(AStream: PStream);
begin
  CursorBlinkRate :=  AStream^.ReadDouble;
  UpdateScrollContents := AStream^.ReadBool;
  DoubleClickDelay.CreateTicks(AStream^.ReadDouble);
  MouseSensitivity := AStream^.ReadReal;
end;

begin
end.