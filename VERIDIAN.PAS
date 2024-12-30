{$I COMPILER.INC}
unit Veridian;

interface

uses
  AplObj,
  AplDos,
  AplTypes,
  AplConst,
  Drawing,
  Dialogs,
  Lists,
  AplStr,
  Graphics,
  Gr8Drv,
  GraphIni,
  GraphApp,
  Colors,
  MouseDrv,
  MemDrv,
  DateTime,
  Streams,
  Actions,
  Controls,
  Palettes,
  ListView,
  Views,
  Events,
  Menus;

const
  DefaultDoubleClickDelay = 1.0;
  DefaultCursorBlinkRate = 0.4;
  DefaultMouseSensitivity = 4;

type
  PVeridianApp = ^TVeridianApp;
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
    FOffScreen: PMemoryStream;
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
    FDoubleClickPos: TPoint;
    FSpecialControls: TObjectStack;
    FNewWindowX, FNewWindowY: integer;
    AltKeyDown: boolean;
    SwitchingWindows: boolean;
    ErrorDialog: PShowMessageDialog;
    function LoadFont(const AFilename: string): PFont;
    function CreateDesktop: PDesktop; virtual;
    function HandleWindowSwitch: boolean;
    procedure GetFocusList(AList: PObjectList; AControl: PControl);
    procedure CreateObjects;
    procedure LoadFonts;
    procedure BeginWindowSwitch;
    procedure EndWindowSwitch;
    procedure SwitchWindow;
    procedure HandleKeyEvent(AControl: PControl; var AEvent: TKeyEvent);
    procedure HandleSpecialKeys(AControl: PControl; var AEvent: TKeyEvent);
    procedure HandleActionKey(AControl: PActionControl; var AEvent: TKeyEvent);
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
    procedure HandleDoubleClick(ATime: TDateTime; AControl: PControl; var AEvent: TMouseEvent);
    procedure CleanupWindows;
    procedure InitMouseEvent(AControl: PControl; var AEvent: TMouseEvent);
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
    DragRect, LastDragRect: TRect;
    DragRectVisible: boolean;
    DragInitialPos: TPoint;
    DragInitialSize: TSize;
    MenuBar: PMenubar;
    Taskbar: PTaskbar;
    Fonts: PFontList;
    SystemFont: PFont;
    SymbolFont: PFont;
    EditorFont: PFont;
    Settings: TVeridianAppSettings;
    CursorBlinkTime: TDateTime;
    Parameters: TStringList;
    DoubleClickControl: PControl;
    MouseOverControl: PControl;
    LeftMouseDownControl: PControl;
    RightMouseDownControl: PControl;
    SelectingControl: PControl;
    ActiveControl: PFocusControl;
    ActiveWindow: PWindow;
    ActiveDropDown: PDropDownList;
    ActiveDialog: PDialog;
    DragControl: PControl;
    ScrollSlider: PControl;
    constructor Create(ADriver: TGraphDrivers; AWidth: integer;
      AHeight: integer; ABpp: integer);
    destructor Free; virtual;
    function CheckNilPtr(APtr: pointer): boolean;
    function GetFont(const AId: string): PFont;
    function DefaultWindowX: integer;
    function DefaultWindowY: integer;
    procedure Error(var ASender; ACode: word); virtual;
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
    procedure StoreSpecialControlState;
    procedure RestoreSpecialControlState;
    procedure ClearSpecialControlState;
    procedure EnableDrawing;
    procedure DisableDrawing;
    procedure GetMouseState(var AMouseState: TMouseState);
    procedure DrawDragRect(var ARect: TRect);
    function FocusNext(AControl: PControl; AReverse: boolean): boolean;
    function FocusFirst: boolean;
    function FocusLast: boolean;
    function GetMouseControl(AControl: PControl; var AMouseState: TMouseState): PControl;
    function TaskBarHeight: integer;
    function MenuBarHeight: integer;
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
    Error(VeridianApp, ecNotEnoughMemory);
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
  inherited Initialized;
  LoadFonts;
  FOffScreen := nil;
  Desktop := CreateDesktop;
  Desktop^.Font := SystemFont;
  InitActions;
  InitControls;
  Desktop^.Layout;
  MenuBar^.Layout;
  Keyboard.GetKey;
  FNewWindowX := 10;
  FNewWindowY := MenuBar^.Height + 10;
  ErrorDialog := New(PShowMessageDialog, Create('Error', '', [mbOk]));
  TString.Free(ErrorDialog^.MessageLabel^.Caption);
  GetMem(ErrorDialog^.MessageLabel^.Caption, 256);
  FillChar(ErrorDialog^.MessageLabel^.Caption^, 256, 0);
  if not (Assigned(ErrorDialog) and Assigned(ErrorDialog^.MessageLabel^.Caption)) then begin
    WriteLn(ErrorMessage(ecNotEnoughMemory));
    Halt(ecNotEnoughMemory);
  end;
end;

destructor TVeridianApp.Free;
begin
  FreeMem(ErrorDialog^.MessageLabel^.Caption, 256);
  FreeAndNil(FOffScreen);
  StateStack.DisposeObjects := true;
  StateStack.Free;
  Parameters.Free;
  Settings.Free;
  FSpecialControls.Free;
  FreeAndNil(Fonts);
  inherited Free;
end;

procedure TVeridianApp.InitActions;
begin
end;

procedure TVeridianApp.InitControls;
begin
  MenuBar := New(PMenuBar, Create);
  Taskbar := New(PTaskbar, Create);
  {$IFDEF debug}
  FMemLabel := New(PLabel, CreateParent('MemLabel', MenuBar));
  FMemLabel^.TransparentBack := false;
  FMemLabel^.SetForeColor(MenuBar^.ForeColor);
  FMemLabel^.SetBackColor(MenuBar^.BackColor);
  FMemLabel^.Font := Fonts^.GetItemById('editor');
  FMemLabel^.AutoSize := true;
  FMemLabel^.Layout;
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

function TVeridianApp.GetFont(const AId: string): PFont;
var
  index: integer;
  font: PFont;
begin
  font := Fonts^.GetItemById(AId);
  if not Assigned(font) then
    font := SystemFont;
  GetFont := font;
end;

procedure TVeridianApp.LoadFonts;
var
  font: PFont;
begin
  Fonts := New(PFontList, Create);
  if Graph^.Mode^.Width <= 320 then begin
    font := LoadFont('portland.fnt');
    font^.SetId('system');
    SystemFont := font;
    font := LoadFont('fremont.fnt');
    font^.SetId('editor');
    EditorFont := font;
    font := LoadFont('symsmall.fnt');
    font^.SetId('symbol');
    SymbolFont := font;
  end
  else begin
    font := LoadFont('olympia.fnt');
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
  FSpecialControls.Create;
  FSpecialControls.DisposeObjects := false;
  CursorBlinkTime.Create;
  StateStack.Create;
  Settings.Create;
  DragRect.Create;
  LastDragRect.Create;
  Colors := LightColors;
  State.Create;
  DragInitialPos.Create;
  DragInitialSize.Create;
  Parameters.Create;
  FDoubleClickPos.Create;
  ParseParameters;
end;

procedure TVeridianApp.Init;
begin
  inherited Init;
  Memory.OnAllocError := @OnAllocError;
  FCursorBlinkVisible := false;
  CreateObjects;
  SwitchingWindows := false;
  MenuBar := nil;
  Mouse.UseSystemCursor := false;
  Mouse.HideMouse;
  DragRectVisible := false;
  ActiveControl := nil;
  ActiveWindow := nil;
  MouseOverControl := nil;
  LeftMouseDownControl := nil;
  RightMouseDownControl := nil;
  DoubleClickControl := nil;
  SelectingControl := nil;
  DragControl := nil;
  ScrollSlider := nil;
  ActiveDropDown := nil;
  ActiveDialog := nil;
  {$IFDEF debug}
  FMemAvail := MemAvail;
  FMemMaxAvail := MaxAvail;
  FMemLabel := nil;
  {$ENDIF}
end;

function TVeridianApp.CreateDesktop: PDesktop;
begin
  CreateDesktop := New(PDesktop, CreateParent('Desktop', nil, nil));
end;

procedure TVeridianApp.UpdateActionControl(AControl: PActionControl);
begin
end;

procedure TVeridianApp.ActionExecute(ASender: PActionControl; AAction: PAction);
var
  event: TActionEvent;
begin
  if not (Assigned(ASender) and Assigned(AAction)) then
    exit;
  UpdateActionControl(ASender);
  if not (ASender^.IsVisibleAndEnabled) then
    exit;
  if Assigned(AAction^.OnExecute) then begin
    event.Create;
    event.Action := AAction;
    event.Sender := ASender;
    TActionExecuteEventProc(AAction^.OnExecute)(event);
  end;
end;

procedure TVeridianApp.HandleMouseEnter(AControl: PControl; var AEvent: TMouseEvent);
var
  index: integer;
  control: PControl;
begin
  if Assigned(DragControl) then
    exit;
  if Assigned(MouseOverControl) and (MouseOverControl <> AControl)
    and (MouseOverControl^.IsVisibleAndEnabled) then begin
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
  if AControl^.IsVisibleAndEnabled then
    AControl^.MouseEnter(AEvent);
end;

procedure TVeridianApp.HandleMouseMove(AControl: PControl; var AEvent: TMouseEvent);
begin
  AControl^.MouseMove(AEvent);
end;

procedure TVeridianApp.HandleMouseWheelChanged(AControl: PControl; var AEvent: TMouseEvent);
var
  clipRect, rect: TRect;
begin
  if not AControl^.IsVisibleAndEnabled then
    exit;
  AControl^.GetDrawRect(rect);
  AControl^.GetClipRect(clipRect);
  rect.Intersect(clipRect);
  if rect.Contains(AEvent.NewMouseState.X, AEvent.NewMouseState.Y) then begin
    AControl^.MouseWheelChanged(AEvent);
  end;
end;

procedure TVeridianApp.HandleMouseUp(AControl: PControl; var AEvent: TMouseEvent;
  AButton: TButtonState);
var
  selecting: boolean;
  dragEvent: TDragEvent;
  now: TDateTime;
  scrollParent: PScrollBar;
  scrollEvent: TScrollEvent;
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
  if Assigned(ScrollSlider) and Assigned(ScrollSlider^.Parent) then begin
    scrollParent := PScrollBar(ScrollSlider^.Parent);
    scrollEvent.Create;
    scrollEvent.ScrollPosition := scrollParent^.ScrollPosition;
    scrollEvent.Orientation := scrollParent^.Orientation;
    scrollParent^.PositionChanged(scrollEvent);
  end;
  ScrollSlider := nil;
  now.CreateNow;
  if ((LeftMouseDownControl = AControl) and (AButton = bsLeft))
      or ((RightMouseDownControl = AControl) and (AButton = bsRight)) or selecting then begin
    AControl^.MouseUp(AEvent);
    AControl^.MouseClick(AEvent);
    HandleDoubleClick(now, AControl, AEvent);
  end;

  if AButton = bsLeft then
    LeftMouseDownControl := nil
  else
    RightMouseDownControl := nil;

  if AEvent.Handled then
    exit;

  if AControl^.IsActionControl and Assigned(PActionControl(AControl)^.Action) then begin
    if Assigned(ActiveDialog) then begin
      ActiveDialog^.ActionExecute(PActionControl(AControl), PActionControl(AControl)^.Action);
      exit;
    end;
    ActionExecute(PActionControl(AControl), PActionControl(AControl)^.Action);
  end;
end;

procedure TVeridianApp.HandleMouseDown(AControl: PControl; var AEvent: TMouseEvent;
  AButton: TButtonState);
var
  rect: TRect;
  intersects: boolean;
  container: PMenuItemContainer;
  index: integer;
  parent: PControl;
  window: PWindow;
  event: TKeyEvent;
begin
  if not (AButton in AEvent.NewMouseState.ButtonState) then
    exit;
  if AButton in AEvent.OldMouseState.ButtonState then
    exit;
  if not AControl^.IsVisibleAndEnabled then
    exit;
  if Assigned(ActiveDropDown) then begin
     ActiveDropDown^.GetDrawRect(rect);
    intersects := rect.Contains(AEvent.NewMouseState.X, AEvent.NewMouseState.Y);
    if not intersects then begin
      event.Create;
      event.Key := kyEsc;
      ActiveDropDown^.KeyPress(event);
      ActiveDropDown := nil;
    end;
  end;

  intersects := false;
  for index := 0 to MenuManager.OpenMenus^.Count - 1 do begin
    container := MenuManager.OpenMenus^.GetItem(index);
    container^.GetDrawRect(rect);
    if rect.Contains(AEvent.NewMouseState.X, AEvent.NewMouseState.Y) then
      intersects := true;
    if Assigned(container^.ParentMenuItem) then begin
      container^.ParentMenuItem^.GetDrawRect(rect);
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

  parent := AControl^.Parent;
  window := nil;
  while Assigned(parent) do begin
    if parent^.IsWindow then
      window := PWindow(parent);
    parent := parent^.Parent;
  end;
  if Assigned(window) and (ActiveWindow <> window)
    and window^.IsVisibleAndEnabled then
    window^.Activate;

  if Assigned(ActiveControl) and (AControl^.IsFocusControl)
    and (AControl <> PControl(ActiveControl)) then begin
    PFocusControl(AControl)^.Focus;
  end;
  AControl^.MouseDown(AEvent);
end;

procedure TVeridianApp.HandleCursor;
var
  seconds: Double;
begin
  if not (Assigned(ActiveControl)
    and ActiveControl^.Focused
    and ActiveControl^.UsesCursor
    and ActiveControl^.IsVisibleAndEnabled) then
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
  AControl^.GetDrawRect(rect);
  Dec(AEvent.X, rect.X);
  Dec(AEvent.Y, rect.Y);
end;

procedure TVeridianApp.GetMouseState(var AMouseState: TMouseState);
begin
  AMouseState.Create;
  AMouseState.Assign(FMouseState);
end;

function TVeridianApp.GetMouseControl(AControl: PControl; var AMouseState: TMouseState): PControl;
var
  index: integer;
  clipRect, drawRect: TRect;
  control: PControl;
begin
  GetMouseControl := nil;
  if not AControl^.IsVisible then
    exit;

  if AControl^.Controls^.Count > 0 then begin
    for index := AControl^.Controls^.Count - 1 downto 0 do begin
      control := AControl^.Controls^.GetItem(index);
      control := GetMouseControl(control, AMouseState);
      if Assigned(control) then begin
        GetMouseControl := control;
        exit;
      end;
    end;
  end;

  AControl^.GetClipRect(drawRect);
  if drawRect.Contains(AMouseState.X, AMouseState.Y) then
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

  AEvent.Sender := control;
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
    if Assigned(ScrollSlider) then
      PScrollSlider(ScrollSlider)^.MouseMove(FMouseEvent);
    HandleMouseMove(control, FMouseEvent);
    if Assigned(DragControl) then begin
      dragEvent.Create;
      dragEvent.InitialX := DragInitialPos.X;
      dragEvent.InitialY := DragInitialPos.Y;
      dragEvent.X := AEvent.NewMouseState.X;
      dragEvent.Y := AEvent.NewMouseState.Y;
      DragControl^.DragMove(dragEvent);
    end;
    if Assigned(LeftMouseDownControl)
      and (LeftMouseDownControl^.CanDrag(AEvent))
      and not Assigned(DragControl) then begin
      if not LeftMouseDownControl^.IsVisibleAndEnabled then
        exit;
      DragControl := LeftMouseDownControl;
      DragInitialPos.SetCoords(AEvent.NewMouseState.X, AEvent.NewMouseState.Y);
      dragEvent.Create;
      dragEvent.InitialX := DragInitialPos.X;
      dragEvent.InitialY := DragInitialPos.Y;
      dragEvent.X := DragInitialPos.X;
      dragEvent.Y := DragInitialPos.Y;
      DragInitialSize.CreateDims(DragControl^.Width, DragControl^.Height);
      LeftMouseDownControl^.DragStart(dragEvent);
    end;
    HandleMouseEnter(control, FMouseEvent);
  end;
end;

procedure TVeridianApp.HandleActionKey(AControl: PActionControl; var AEvent: TKeyEvent);
var
  index: integer;
  action: PAction;
begin
  for index := 0 to Desktop^.ActionList^.Count - 1 do begin
    action := Desktop^.ActionList^.GetItem(index);
    if (action^.Shortcut <> AEvent.Key) or not action^.Enabled then
      continue;
    if Assigned(ActiveDialog) then
      ActiveDialog^.ActionExecute(PActionControl(AControl), action)
    else
      ActionExecute(PActionControl(AControl), action);
    AEvent.Handled := true;
    break;
  end;
end;

function TabOrderCompare(AItem1, AItem2: pointer): integer;
var
  control1, control2: PControl;
  focusControl1, focusControl2: PFocusControl;
  parent1, parent2: PControl;
begin
  focusControl1 := nil;
  control1 := PControl(AItem1);
  control2 := PControl(AItem2);
  parent1 := control1^.Parent;
  parent2 := control2^.Parent;
  while Assigned(parent1) and not (parent1^.IsWindow or parent1^.IsDesktop) do begin
    control1 := parent1;
    parent1 := parent1^.Parent;
  end;
  while Assigned(parent2) and not (parent2^.IsWindow or parent2^.IsDesktop) do begin
    control2 := parent2;
    parent2 := parent2^.Parent;
  end;
  if control1^.IsFocusControl then
    focusControl1 := PFocusControl(control1);
  if control2^.IsFocusControl then
    focusControl2 := PFocusControl(control2);

  if parent1 = parent2 then begin
    if Assigned(focusControl1) and Assigned(focusControl2) then begin
      if focusControl1^.TabOrder > focusControl2^.TabOrder then
        TabOrderCompare := -1
      else if focusControl1^.TabOrder < focusControl2^.TabOrder then
        TabOrderCompare := 1
      else
        TabOrderCompare := 0;
    end
    else if Assigned(focusControl1) then
      TabOrderCompare := -1
    else if Assigned(focusControl2) then
      TabOrderCompare := 1
    else
      TabOrderCompare := 0;
  end
  else
    TabOrderCompare := 0;
end;

procedure TVeridianApp.GetFocusList(AList: PObjectList; AControl: PControl);
var
  control: PControl;
  focusControl: PFocusControl;
  index: integer;
  result: PObjectList;
begin
  if not Assigned(AList) then
    AList := New(PObjectList, CreateSorted(TabOrderCompare));
  for index := 0 to AControl^.Controls^.Count - 1 do begin
    control := AControl^.Controls^.GetItem(index);
    GetFocusList(AList, control);
    if not control^.IsFocusControl then
      continue;
    focusControl := PFocusControl(control);
    if focusControl^.IsVisibleAndEnabled and focusControl^.CanFocus then
      AList^.Add(focusControl);
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
  if not Assigned(ActiveControl) then
    exit;
  parent := AControl^.Parent;
  current := parent;
  while Assigned(current^.Parent) do
    current := current^.Parent;
  if not Assigned(current) then
    exit;
  focusList := New(PObjectList, CreateSorted(TabOrderCompare));
  focusList^.DisposeObjects := false;
  if Assigned(ActiveWindow) then
    GetFocusList(focusList, ActiveWindow)
  else
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

function TVeridianApp.FocusFirst: boolean;
var
  focusList: PControlList;
  control: PControl;
begin
  focusList := New(PControlList, CreateSorted(TabOrderCompare));
  focusList^.DisposeObjects := false;
  GetFocusList(focusList, Desktop);
  if focusList^.Count >= 0 then begin
    control := PControl(focusList^.GetItem(focusList^.Count - 1));
    if Assigned(control) then
      PFocusControl(control)^.Focus;
  end;
  FreeAndNil(focusList);
end;

function TVeridianApp.FocusLast: boolean;
var
  focusList: PControlList;
  control: PControl;
begin
  focusList := New(PControlList, CreateSorted(TabOrderCompare));
  focusList^.DisposeObjects := false;
  GetFocusList(focusList, Desktop);
  if focusList^.Count >= 0 then begin
    control := PControl(focusList^.GetItem(0));
    if Assigned(control) then
      PFocusControl(control)^.Focus;
  end;
  FreeAndNil(focusList);
end;

procedure TVeridianApp.HandleSpecialKeys(AControl: PControl; var AEvent: TKeyEvent);
var
  container: PMenuItemContainer;
begin
  case AEvent.Key of
    kyTab: begin
      MenuManager.CloseAllMenus;
      if Assigned(ActiveDropDown) then
        ActiveDropDown^.HideList;
      if Assigned(ActiveControl) then begin
        if ActiveControl^.AcceptsTab or not ActiveControl^.CanFocus then
          exit;
        FocusNext(ActiveControl, true);
      end
      else begin
        FocusFirst;
      end;
      AEvent.Handled := true;
      exit;
    end;
    kyShiftTab: begin
      MenuManager.CloseAllMenus;
      if Assigned(ActiveDropDown) then
        ActiveDropDown^.HideList;
      if Assigned(ActiveControl) then begin
        if ActiveControl^.AcceptsTab or not ActiveControl^.CanFocus then
          exit;
        FocusNext(ActiveControl, false);
      end
      else begin
        FocusLast;
      end;
      AEvent.Handled := true;
      exit;
    end;
    kyEsc: begin
      Desktop^.BeginDrawing;
      container := MenuManager.PopAndCloseMenu;
      if Assigned(ActiveDropDown) then
        ActiveDropDown^.HideList;
      Desktop^.EndDrawing;
    end;
  end;
  if AEvent.Handled then
    exit;
  if AControl^.IsActionControl then
    HandleActionKey(PActionControl(AControl), AEvent);
end;

procedure TVeridianApp.HandleKeyEvent(AControl: PControl; var AEvent: TKeyEvent);
var
  index: integer;
  control: PControl;
  controlEnabled: boolean;
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

  if (AEvent.Key = kyAltF1) and not SwitchingWindows then begin
    SwitchingWindows := true;
    AEvent.Handled := true;
  end;

  if AEvent.Handled then
    exit;
  HandleSpecialKeys(AControl, AEvent);
  if AEvent.Handled then
    exit;
  for index := AControl^.Controls^.Count - 1 downto 0 do begin
    control := AControl^.Controls^.GetItem(index);
    if not control^.IsVisible then
      continue;
    controlEnabled := control^.IsEnabled;
    if controlEnabled then
      HandleKeyEvent(control, AEvent);
    if AEvent.Handled then
      exit;
  end;
  if AEvent.Handled then
    exit;
  AEvent.Sender := AControl;
  AControl^.KeyPress(AEvent);
end;

function TVeridianApp.DefaultWindowX: integer;
begin
  FNewWindowX := FNewWindowX + 10;
  if FNewWindowX > Graph^.Mode^.Width div 2 then
    FNewWindowX := 10;
  DefaultWindowX := FNewWindowX;
end;

function TVeridianApp.DefaultWindowY: integer;
begin
  FNewWindowY := FNewWindowY + 10;
  if FNewWindowY > Graph^.Mode^.Height div 2 then
    FNewWindowY := 10;
  DefaultWindowY := FNewWindowY;
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

function TVeridianApp.MenuBarHeight: integer;
begin
  if Assigned(MenuBar) then
    MenuBarHeight := MenuBar^.Height
  else
    MenuBarHeight := 0;
end;

function TVeridianApp.TaskBarHeight: integer;
begin
  if Assigned(Taskbar) then
    TaskBarHeight := Taskbar^.Height
  else
    TaskBarHeight := 0;
end;

procedure TVeridianApp.DrawCursor;
var
  rect: TRect;
  mouseRect: TRect;
  cursorColor: byte;
  control: PTextControl;
  clipRect: TRect;
begin
  if not State.DrawEnabled then
    exit;
  if not Assigned(ActiveControl) then
    exit;
  if not ActiveControl^.IsTextControl then
    exit;
  control := PTextControl(ActiveControl);
  control^.GetCursorRect(rect);
  control^.GetClipRect(clipRect);
  rect.Intersect(clipRect);
  if rect.IsEmpty then
    exit;
  if FCursorBlinkVisible then
    cursorColor := control^.GetCursorForeColor
  else
    cursorColor := control^.GetCursorBackColor;

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
    ((FMemAvail <> MemAvail) or (FMemMaxAvail <> MaxAvail))
    and State.DrawEnabled then begin
    MenuBar^.GetLayoutRect(rect);
    txt := 'MemAvail: ' + FormatLong(MemAvail) + ' MaxAvail: ' + FormatLong(MaxAvail);
    width := FMemLabel^.Font^.TextWidth('MemAvail: 555,555  MaxAvail: 555,555     ');
    rect.X := rect.Right - width;
    rect.Y := rect.Y + (MenuBar^.Height - FMemLabel^.Height) div 2 + 1;
    FMemLabel^.X := rect.X;
    FMemLabel^.Y := rect.Y;
    FMemLabel^.GetDrawRect(rect);
    FMemAvail := MemAvail;
    FMemMaxAvail := MaxAvail;
    Graph^.SetBackColor(MenuBar^.BackColor);
    Graph^.FillRect(rect);
    FMemLabel^.SetCaption(txt);
  end;
end;
{$ENDIF}

function TVeridianApp.HandleWindowSwitch: boolean;
begin
  HandleWindowSwitch := false;
  if AltkeyDown and SwitchingWindows then begin
    if Keyboard.KeyPressed then begin
      if Keyboard.GetKey = kyAltF1 then
        SwitchWindow
      else
        BeginWindowSwitch;
    end;
  end;
  if not AltKeyDown and SwitchingWindows then
     EndWindowSwitch;
end;

procedure TVeridianApp.DrawDragRect(var ARect: TRect);
  procedure DrawRect;
  begin
    Graph^.HLine(ARect.X, ARect.Y, ARect.Width);
    Graph^.HLine(ARect.X, ARect.Bottom, ARect.Width);
    Graph^.VLine(ARect.X, ARect.Y, ARect.Height);
    Graph^.VLine(ARect.Right, ARect.Y, ARect.Height);
  end;
begin
  Graph^.PushState;
  Graph^.State^.Inverse := true;
  Graph^.SetBackColor(TransparentColor);
  Graph^.State^.LinePattern := @CheckerLinePattern;
  DrawRect;
  Graph^.PopState;
end;

procedure TVeridianApp.HandleMouseCursor;
var
  newRect, oldRect: TRect;
begin
  if not Assigned(DragControl) then
    DragRectVisible := false;
  if Assigned(DragControl) and not DragRectVisible then begin
    DragRectVisible := true;
    MoveMouseCursor(FMouseState, FOldMouseState, false);
    DrawDragRect(DragRect);
    LastDragRect.Assign(DragRect);
  end
  else if Assigned(DragControl) and DragRectVisible then begin
    newRect.CreateRect(DragRect);
    oldRect.CreateRect(LastDragRect);
    DrawDragRect(oldRect);
    MoveMouseCursor(FMouseState, FOldMouseState, false);
    DrawDragRect(newRect);
    MouseCursor^.Draw;
    LastDragRect.Assign(DragRect);
  end
  else
    MoveMouseCursor(FMouseState, FOldMouseState, false);
end;

procedure TVeridianApp.HandleDoubleClick(ATime: TDateTime; AControl: PControl; var AEvent: TMouseEvent);
var
  elapsed: TTimeSpan;
begin
  if not Assigned(AControl) then begin
    FDoubleClickStart.Ticks := 0;
    exit;
  end;
  if (FDoubleClickStart.Ticks = 0) or (AControl <> DoubleClickControl) then begin
    FDoubleClickStart.SetNow;
    FDoubleClickPos.X := AEvent.NewMouseState.X;
    FDoubleClickPos.Y := AEvent.NewMouseState.Y;
    DoubleClickControl := AControl;
    exit;
  end;
  elapsed.CreateTicks(ATime.Ticks - FDoubleClickStart.Ticks);
  if elapsed.Ticks < Settings.DoubleClickDelay.Ticks then begin
    if (AEvent.NewMouseState.X = FDoubleClickPos.X)
      and (AEvent.NewMouseState.Y = FDoubleClickPos.Y) then
      AControl^.MouseDoubleClick(AEvent);
    FDoubleClickStart.Ticks := 0;
    DoubleClickControl := nil;
    exit;
  end;
  FDoubleClickStart.SetNow;
  DoubleClickControl := AControl;
end;

procedure TVeridianApp.BeginWindowSwitch;
begin
  SwitchingWindows := true;
end;

procedure TVeridianApp.EndWindowSwitch;
begin
  SwitchingWindows := false;
end;

procedure TVeridianApp.SwitchWindow;
begin
end;

procedure TVeridianApp.StoreSpecialControlState;
begin
  FSpecialControls.Clear;
  FSpecialControls.Push(DoubleClickControl);
  FSpecialControls.Push(MouseOverControl);
  FSpecialControls.Push(LeftMouseDownControl);
  FSpecialControls.Push(RightMouseDownControl);
  FSpecialControls.Push(SelectingControl);
  FSpecialControls.Push(ActiveDialog);
  FSpecialControls.Push(ActiveControl);
  FSpecialControls.Push(ActiveWindow);
  FSpecialControls.Push(ActiveDropDown);
  FSpecialControls.Push(DragControl);
  FSpecialControls.Push(ScrollSlider);
end;

procedure TVeridianApp.ClearSpecialControlState;
begin
  DoubleClickControl := nil;
  MouseOverControl := nil;
  LeftMouseDownControl := nil;
  RightMouseDownControl := nil;
  SelectingControl := nil;
  ActiveControl := nil;
  ActiveWindow := nil;
  ActiveDropDown := nil;
  DragControl := nil;
  ActiveDialog := nil;
  ScrollSlider := nil;
end;

procedure TVeridianApp.RestoreSpecialControlState;
begin
  ScrollSlider := PControl(FSpecialControls.Pop);
  DragControl := PControl(FSpecialControls.Pop);
  ActiveDropDown := PDropDownList(FSpecialControls.Pop);
  ActiveWindow := PWindow(FSpecialControls.Pop);
  ActiveControl := PFocusControl(FSpecialControls.Pop);
  ActiveDialog := PDialog(FSpecialControls.Pop);
  SelectingControl := PControl(FSpecialControls.Pop);
  RightMouseDownControl := PControl(FSpecialControls.Pop);
  LeftMouseDownControl := PControl(FSpecialControls.Pop);
  MouseOverControl := PControl(FSpecialControls.Pop);
  DoubleClickControl := PControl(FSpecialControls.Pop);
  FSpecialControls.Clear;
end;

function IsClosed(AItem: PControl): boolean; far;
begin
  IsClosed := Assigned(AItem) and AItem^.IsWindow and PWindow(AItem)^.Closed;
end;

procedure TVeridianApp.CleanupWindows;
var
  index: integer;
  control: PControl;
  window: PWindow;
begin
  control := Desktop^.FindControlThat(IsClosed);
  if not Assigned(control) then
    exit;
  while Assigned(control) and Assigned(control^.Parent) do begin
    window := PWindow(control);
    if ActiveWindow = window then
      ActiveWindow := nil;
    if window^.ContainsControl(ActiveControl) then
      ActiveControl := nil;
    if window^.ContainsControl(LeftMouseDownControl) then
      LeftMouseDownControl := nil;
    if window^.ContainsControl(RightMouseDownControl) then
      RightMouseDownControl := nil;
    if window^.ContainsControl(MouseOverControl) then
      MouseOverControl := nil;
    if window^.ContainsControl(SelectingControl) then
      SelectingControl := nil;
    if window^.ContainsControl(DragControl) then
      DragControl := nil;
    if window^.ContainsControl(ActiveDropDown) then
      ActiveDropDown := nil;
    if window^.ContainsControl(ActiveDialog) then
      ActiveDialog := nil;
    if Assigned(TaskBar) then
      TaskBar^.RemoveWindow(window);
    window^.Parent^.Controls^.DeleteItem(window);
    control := Desktop^.FindControlThat(IsClosed);
  end;
end;

procedure TVeridianApp.Error(var ASender; ACode: word);
var
  message: string;
begin
  case ACode of
    ecNotEnoughMemory: message := 'Not enough memory to complete the last operation.'
    else
      message := ErrorMessage(ACode) + '.';
  end;
  FillChar(ErrorDialog^.Caption, 256, 0);
  Move(message[1], ErrorDialog^.Caption^, Length(message));
  ErrorDialog^.ShowDialog;
end;

procedure TVeridianApp.ProcessEvents;
var
  ch: word;
  flags: TKeyboardFlags;
begin
  CleanupWindows;
  Mouse.UpdateState;
  Keyboard.GetFlags(flags);
  AltKeyDown := kfAlt in flags;
  if Assigned(MenuBar) then
    MenuBar^.BringToFront;

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

  if (not HandleWindowSwitch) and Keyboard.KeyPressed then begin
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
begin
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

procedure TVeridianApp.EnableDrawing;
begin
  VeridianApp^.PopState;
end;

procedure TVeridianApp.DisableDrawing;
begin
  VeridianApp^.PushState;
  State.DrawEnabled := false;
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
var
  mx, my: integer;
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
  Desktop^.Draw;
  mx := Graph^.Mode^.Width div 2;
  my := Graph^.Mode^.Height div 2;
  if Graph^.Mode^.Width < 640 then
    Mouse.SetMousePosition(mx * 2, my)
  else
    Mouse.SetMousePosition(mx, my);
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

procedure TVeridianAppSettings.Init;
begin
  inherited Init;
  CursorBlinkRate := DefaultCursorBlinkRate;
  DoubleClickDelay.CreateSeconds(DefaultDoubleClickDelay);
  MouseSensitivity := DefaultMouseSensitivity;
  UpdateScrollContents := false;
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