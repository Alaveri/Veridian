{$I COMPILER.INC}
unit Veridian;

interface

uses
  GraphApp,
  AplApps,
  AplTypes,
  Lists,
  DateTime,
  Drawing,
  Streams,
  AplObj,
  GrDrv8,
  GraphDrv,
  GraphIni,
  MouseDrv,
  KeyDrv,
  Controls,
  Actions,
  Errors,
  Desk;

const
  vmVeridian = 1000;
  vmKeyDown = vmVeridian + 1;
  vmKeyPressed = vmVeridian + 2;
  vmKeyUp = vmVeridian + 3;

  DefaultDoubleClickDelay: double = 1;
  DefaultCursorBlinkRate = 0.4;
  DefaultMouseSensitivity = 2.0;

type
  PVeridianApp = ^TVeridianApp;
  PVeridianAppSettings = ^TVeridianAppSettings;
  PAppState = ^TAppState;

  TAppState = object(TObject)
  private
  public
    MouseCursor: PMouseCursor;
    CursorOn: boolean;
    DrawEnabled: boolean;
    procedure Init; virtual;
    procedure Assign(var ASource: TObject); virtual;
  end;

  TVeridianAppSettings = object(TObject)
  private
  public
    CursorBlinkRate: double;
    UpdateScrollContents: boolean;
    DoubleClickDelay: TTimeSpan;
    MouseSensitivity: real;
    procedure Init; virtual;
    procedure Assign(var ASource: TObject); virtual;
    procedure SaveToStream(AStream: PStream);
    procedure LoadFromStream(AStream: PStream);
  end;

  TVeridianApp = object(TGraphApp)
  private
    FMouseEvent: TMouseEvent;
    FKeyEvent: TKeyEvent;
    FMouseState: TMouseState;
    FOldMouseState: TMouseState;
    FCursorBlinkVisible: boolean;
    FBlinkCurrentTime: TDateTime;
    FBlinkElapsed: TTimeSpan;
    FMouseOverControl: PControl;
    FDragControl: PControl;
    FDoubleClickStart: TDateTime;
    FDoubleClickControl: PControl;
    {$IFDEF debug}
    FMemAvail: longint;
    FMaxAvail: longint;
    {$ENDIF}
    procedure ParseParameters;
    procedure DrawCursor;
    procedure HandleCursor;
    procedure InitMouseEvent(AControl: PControl; var AEvent: TMouseEvent);
    procedure HandleMouseEnter(AControl: PControl; var AEvent: TMouseEvent);
    procedure HandleMouseMove(AControl: PControl; var AEvent: TMouseEvent);
    procedure HandleMouseDown(AControl: PControl; var AEvent: TMouseEvent; AButton: TButtonState);
    procedure HandleMouseWheelChanged(AControl: PControl; AEvent: TMouseEvent);
    procedure HandleMouseUp(AControl: PControl; var AEvent: TMouseEvent; AButton: TButtonState);
    procedure HandleDblClick(ATime: TDateTime; AControl: PControl; var AEvent: TMouseEvent);
    procedure ProcessMouseEvents;
    procedure ProcessKeyEvents(AControl: PControl; var AEvent: TKeyEvent);
    procedure ProcessMessages; virtual;
    procedure LoadFonts;
    procedure CreateDesktop;
    procedure CreateObjects;
    procedure SetMouseSensitivity(ASens: real);
    procedure ApplySettings;
  public
    Settings: TVeridianAppSettings;
    CursorBlinkTime: TDateTime;
    State: TAppState;
    StateStack: TObjectStack;
    Fonts: PFontList;
    MouseCursors: PMouseCursorList;
    SelectingControl: PControl;
    LeftMouseDownControl: PControl;
    RightMouseDownControl: PControl;
    SystemFont: PFont;
    SymbolFont: PFont;
    EditorFont: PFont;
    Parameters: PStringList;
    CurrentScrollSlider: PControl;
    constructor Create(ADriverId: TGraphDrivers; AWidth, AHeight, ABpp: integer);
    function HandleActionExecute(ASender: PObject; AAction: PAction): boolean; virtual;
    function GetMouseControl(AControl: PControl; var AMouseState: TMouseState): PControl;
    function LoadFont(const AFilename: string): PFont; virtual;
    function Scale(AValue: real): integer; virtual;
    function MenuBar: PMenuBar;
    function StatusBar: PStatusBar;
    function CheckError(ASender: PStatusObject): boolean; virtual;
    function FocusNext(AControl: PControl; AReverse: boolean): boolean;
    procedure RedrawMouseCursor(AViewPort: TRect);
    procedure Init; virtual;
    procedure ProcessEvents; virtual;
    procedure InitControls; virtual;
    procedure InitActions; virtual;
    procedure InitMouseCursors; virtual;
    procedure CursorOn;
    procedure CursorOff;
    procedure PushState;
    procedure PopState;
    procedure DeactivateActiveControl;
    procedure UpdateActionControl(AControl: PActionControl); virtual;
    procedure ResetDoubleClick; virtual;
    procedure ClearMouseOver;
    procedure Run; virtual;
    {$IFDEF debug}
    procedure DrawDebugInfo;
    {$ENDIF}
    destructor Free; virtual;
  end;

var
  VeridianApp: PVeridianApp;
  AppDir: string;
  MessageQueue: TObjectQueue;

implementation

uses
  {$IFDEF DOS}
  Dos,
  {$ENDIF}
  Common,
  MemDrv,
  StrUtils,
  Views;

var
  PreviousExitProc: PProc;

procedure OnAllocError(ASize: word); far;
begin
  with VeridianApp^ do begin
  end;
end;

function TVeridianApp.CheckError(ASender: PStatusObject): boolean;
begin
  CheckError := true;
  if not ASender^.HasException then
    exit;
  CheckError := false;
  Error(ASender, ASender^.Exception^.Code);
  ASender^.ClearException;
end;


procedure TVeridianApp.UpdateActionControl(AControl: PActionControl);
begin
end;

procedure TVeridianApp.InitMouseCursors;
var
  cursor: PMouseCursor;
  sens: integer;
begin
  MouseCursors := New(PMouseCursorList, Create);
  cursor := New(PMouseCursor, Create('Default', 8, 15, @DefaultMouseCursor));
  MouseCursors^.Add(cursor);
  cursor := New(PMouseCursor, Create('Beam', 8, 15, @DefaultBeamMouseCursor));
  cursor^.OffsetX := 4;
  cursor^.OffsetY := 7;
  MouseCursors^.Add(cursor);
  Graph8^.MouseCursor := MouseCursors^.GetItemById('Default');
end;

procedure TVeridianApp.ParseParameters;
var
  index: integer;
  dir, name, ext: string;
begin
  Parameters := New(PStringList, Create);
  FSplit(ParamStr(0), dir, name, ext);
  AppDir := dir;
  for index := 1 to ParamCount do
    Parameters^.AddString(ParamStr(index));
end;

procedure TVeridianApp.LoadFonts;
var
  font: PFont;
begin
  Fonts := New(PFontList, Create);
  if Graph^.Mode^.Width <= 320 then begin
    font := LoadFont('syssmall.fnt');
    font^.SetId('system');
    SystemFont := font;
    font := LoadFont('syssmall.fnt');
    font^.SetId('editor');
    EditorFont := font;
    font := LoadFont('symbolsmall.fnt');
    font^.SetId('symbol');
    EditorFont := font;
  end
  else begin
    font := LoadFont('system.fnt');
    SystemFont := font;
    font := LoadFont('editor.fnt');
    EditorFont := font;
    font := LoadFont('symbol.fnt');
    SymbolFont := font;
    LoadFont('seattle.fnt');
  end;
end;

procedure TVeridianApp.CreateDesktop;
begin
  Desktop := New(PDesktop, CreateParent('Desktop', nil));
  Desktop^.MenuBar := New(PMenuBar, CreateParent('DesktopMenuBar', Desktop));
  Desktop^.StatusBar := New(PStatusBar, CreateParent('DesktopStatusBar', Desktop));
end;

procedure TVeridianApp.CreateObjects;
begin
  FMouseState.Create;
  FOldMouseState.Create;
  MessageQueue.Create;
  FMouseEvent.Create;
  FKeyEvent.Create;
  FDoubleClickStart.Create;
  FBlinkCurrentTime.Create;
  FBlinkElapsed.Create;
  Settings.Create;
  State.Create;
  StateStack.Create;
  CursorBlinkTime.Create;
end;

procedure TVeridianApp.ApplySettings;
begin
  SetMouseSensitivity(Settings.MouseSensitivity);
end;

procedure TVeridianApp.Init;
begin
  inherited Init;
  {$IFDEF debug}
  FMemAvail := 0;
  FMaxAvail := 0;
  {$ENDIF}
  ParseParameters;
  CreateObjects;
  VeridianApp := @self;
  FCursorBlinkVisible := false;
  Memory.OnAllocError := @OnAllocError;
  FMouseOverControl := nil;
  FDragControl := nil;
  LeftMouseDownControl := nil;
  RightMouseDownControl := nil;
  SelectingControl := nil;
  CurrentScrollSlider := nil;
  FDoubleClickControl := nil;
  InitMouseCursors;
  LoadFonts;
  CreateDesktop;
  InitControls;
end;

destructor TVeridianApp.Free;
begin
  StateStack.DisposeObjects := true;
  StateStack.Free;
  MessageQueue.DisposeObjects := true;
  MessageQueue.Free;
  FreeAndNil(Desktop);
  FreeAndNil(Fonts);
  FreeAndNil(MouseCursors);
  FreeAndNil(Parameters);
  State.Free;
  inherited Free;
end;

constructor TVeridianApp.Create(ADriverId: TGraphDrivers; AWidth, AHeight, ABpp: integer);
var
  id: integer;
begin
  InitGraphics(ADriverId);
  id := GetGraphicsModeId(AWidth, AHeight, ABpp);
  if id = -1 then begin
    WriteLn('Mode not found');
    exit;
  end;
  if not SetMode(id) then begin
    WriteLn('Could not set graphics mode.');
    exit;
  end;
  inherited Create;
end;

procedure TVeridianApp.InitControls;
begin
  InitActions;
  Desktop^.SetBounds(0, 0, Graph^.Mode^.Width, Graph^.Mode^.Height);
  Desktop^.SetupControls;
end;

procedure TVeridianApp.InitActions;
begin
end;

function TVeridianApp.Scale(AValue: real): integer;
begin
  Scale := Round(AValue * SystemFont^.Height);
end;

procedure TVeridianApp.ResetDoubleClick;
begin
  FDoubleClickStart.Ticks := 0;
  FDoubleClickControl := nil;
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

procedure TVeridianApp.RedrawMouseCursor(AViewPort: TRect);
var
  oldViewPort: TRect;
  drawRect: TRect;
begin
  if not Graph8^.MouseCursor^.Visible then
    exit;
  drawRect.CreateDims(FMouseState.X, FMouseState.Y, Graph8^.MouseCursor^.Width, Graph8^.MouseCursor^.Height);
  drawRect.Translate(-Graph8^.MouseCursor^.OffsetX, -Graph8^.MouseCursor^.OffsetY);
  drawRect.Intersect(AViewPort);
  if drawRect.IsEmpty then
    exit;
  Graph^.WaitForVSync;
  Graph8^.MouseCursor^.Draw;
end;

procedure TVeridianApp.DrawCursor;
var
  rect: TRect;
  mouseRect: TRect;
  cursorColor: byte;
  activeControl: PControl;
begin
  if not State.DrawEnabled then
    exit;
  activeControl := Desktop^.ActiveControl;
  if not Assigned(activeControl) then
    exit;
  if not activeControl^.Focused then
    exit;
  activeControl^.GetCursorRect(rect);
  rect.Intersect(Graph^.State.ViewPort);
  if rect.IsEmpty then
    exit;
  if FCursorBlinkVisible then
    cursorColor := activeControl^.GetCursorForeColor
  else
    cursorColor := activeControl^.GetCursorBackColor;

  Graph^.SetBackColor(cursorColor);
  Graph^.FillRect(rect);
  RedrawMouseCursor(rect);
end;

procedure TVeridianApp.HandleCursor;
var
  seconds: Double;
begin
  if not Assigned(Desktop^.ActiveControl) then
    exit;
  if not (Desktop^.ActiveControl^.CanFocus and Desktop^.ActiveControl^.Focused) then
    exit;
  if State.CursorOn and Desktop^.ActiveControl^.Focused
    and Desktop^.ActiveControl^.UsesCursor then begin
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

procedure TVeridianApp.ProcessMessages;
var
  message: PMessage;
  procedure Process(AControl: PControl; AMessage: PMessage);
  var
    index: integer;
    control: PControl;
  begin
    for index := 0 to AControl^.Controls^.Count - 1 do begin
      control := AControl^.Controls^.GetItem(index);
      if pointer(control) <> AMessage^.Target then
        continue;
      Process(control, message);
      if message^.Processed then
        exit;
    end;
    AControl^.ProcessMessage(message);
  end;
begin
  while MessageQueue.Count > 0 do begin
    message := MessageQueue.Deq;
    Process(Desktop, message);
    FreeAndNil(message);
  end;
end;

procedure TVeridianApp.DeactivateActiveControl;
begin
  Desktop^.ActiveControl := nil;
  FMouseOverControl := nil;
end;

procedure TVeridianApp.InitMouseEvent(AControl: PControl; var AEvent: TMouseEvent);
var
  rect: TRect;
begin
  AEvent.Clear;
  AEvent.NewMouseState.Assign(FMouseState);
  AEvent.OldMouseState.Assign(FOldMouseState);
  AEvent.X := FMouseEvent.NewMouseState.X;
  AEvent.Y := FMouseEvent.NewMouseState.Y;

  AControl^.GetScreenBounds(rect);
  AEvent.X := AEvent.NewMouseState.X;
  AEvent.Y := AEvent.NewMouseState.Y;

  { Get the state in relation to the control's coordinates }
  Dec(AEvent.X, rect.X);
  Dec(AEvent.Y, rect.Y);
end;

function TVeridianApp.GetMouseControl(AControl: PControl; var AMouseState: TMouseState): PControl;
var
  index: integer;
  rect: TRect;
  result: PControl;
  control: PControl;
begin
  result := nil;

  if AControl^.Controls^.Count > 0 then begin
    for index := AControl^.Controls^.Count - 1 downto 0 do begin
      control := AControl^.Controls^.GetItem(index);
      if not (control^.GetVisible) then
        continue;
      control := GetMouseControl(control, AMouseState);
      if control <> nil then begin
        result := control;
        break;
      end;
    end;
  end;

  if result = nil then begin
    AControl^.GetScreenBounds(rect);
    if (AControl^.Modal and (PControl(Desktop^.ActiveView) = AControl))
      or (SelectingControl = AControl) or (rect.Contains(AMouseState.X, AMouseState.Y)) then
      result := AControl;
  end;

  GetMouseControl := result;
end;

procedure TVeridianApp.ProcessMouseEvents;
var
  control, oldControl: PControl;
begin
  control := GetMouseControl(Desktop, FMouseState);
  if control = nil then
    exit;

  InitMouseEvent(control, FMouseEvent);
  if (FMouseState.X <> FOldMouseState.X) or (FMouseState.Y <> FOldMouseState.Y) then begin
    if Assigned(CurrentScrollSlider) then
      PScrollSlider(CurrentScrollSlider)^.ProcessMouseMove(FMouseEvent);
    HandleMouseEnter(control, FMouseEvent);
    HandleMouseMove(control, FMouseEvent);
  end;
  InitMouseEvent(control, FMouseEvent);
  if (FMouseState.WheelCounter <> FOldMouseState.WheelCounter) then
    HandleMouseWheelChanged(control, FMouseEvent);
  if (FMouseState.ButtonState <> FOldMouseState.ButtonState) then begin
    HandleMouseDown(control, FMouseEvent, bsLeft);
    HandleMouseDown(control, FMouseEvent, bsRight);
    HandleMouseUp(control, FMouseEvent, bsLeft);
    HandleMouseUp(control, FMouseEvent, bsRight);
  end;
end;

procedure TVeridianApp.HandleMouseMove(AControl: PControl; var AEvent: TMouseEvent);
begin
  AControl^.MouseMove(AEvent);
end;

procedure TVeridianApp.HandleMouseEnter(AControl: PControl; var AEvent: TMouseEvent);
var
  index: integer;
  control: PControl;
begin
  if Assigned(FMouseOverControl) and (FMouseOverControl <> AControl) then begin
    FMouseOverControl^.MouseLeave(AEvent);
    FMouseOverControl^.IsMouseOver := false;
    FMouseOverControl := nil;
  end;

  if AControl^.IsMouseOver then
    exit;

  FMouseOverControl := AControl;
  AControl^.IsMouseOver := true;
  if Graph8^.MouseCursor <> AControl^.MouseCursor then begin
    Graph8^.EraseMouseCursor(AEvent.NewMouseState);
    Graph8^.MouseCursor := AControl^.MouseCursor;
    Graph8^.DrawMouseCursor(AEvent.NewMouseState);
  end;
  AControl^.MouseEnter(AEvent);
end;

procedure TVeridianApp.HandleMouseWheelChanged(AControl: PControl; AEvent: TMouseEvent);
var
  rect: TRect;
begin
  AControl^.GetScreenBounds(rect);
  if rect.Contains(AEvent.NewMouseState.X, AEvent.NewMouseState.Y) then begin
    AControl^.MouseWheelChanged(AEvent);
  end;
end;

procedure TVeridianApp.HandleMouseDown(AControl: PControl; var AEvent: TMouseEvent; AButton: TButtonState);
var
  rect: TRect;
  intersects: boolean;
  parentItem: PMenuItem;
begin
  if not (AButton in AEvent.NewMouseState.ButtonState) then
    exit;
  if AButton in AEvent.OldMouseState.ButtonState then
    exit;

  if Assigned(Desktop^.ActiveDropDown) then begin
    Desktop^.ActiveDropDown^.GetScreenBounds(rect);
    intersects := rect.Contains(AEvent.NewMouseState.X, AEvent.NewMouseState.Y);
    if not intersects then begin
      Desktop^.ActiveDropDown^.HideList;
      Desktop^.ActiveDropDown := nil;
    end;
  end;
  if Assigned(Desktop^.ActiveMenu) then begin
    Desktop^.ActiveMenu^.GetScreenBounds(rect);
    intersects := rect.Contains(AEvent.NewMouseState.X, AEvent.NewMouseState.Y);
    parentItem := Desktop^.ActiveMenu^.ParentItem;
    if Assigned(parentItem) then begin
      parentItem^.GetScreenBounds(rect);
      intersects := intersects or rect.Contains(AEvent.NewMouseState.X, AEvent.NewMouseState.Y)
    end;
    if not intersects then begin
      Desktop^.DeactivateCurrentMenu;
      PopState;
      if State.CursorOn then
        CursorOn;
    end;
  end;

  if AButton = bsLeft then
    LeftMouseDownControl := AControl
  else
    RightMouseDownControl := AControl;

  AControl^.MouseDown(AEvent);
end;

procedure TVeridianApp.HandleDblClick(ATime: TDateTime; AControl: PControl; var AEvent: TMouseEvent);
begin
  if FDoubleClickStart.Ticks = 0 then begin
    FDoubleClickStart.Ticks := ATime.Ticks;
    FDoubleClickControl := AControl;
  end
  else begin
    if (ATime.Ticks <= FDoubleClickStart.Ticks + Settings.DoubleClickDelay.Ticks)
      and (FDoubleClickControl = AControl) then begin
      AControl^.MouseDblClick(AEvent);
    end;
    FDoubleClickStart.Ticks := 0;
    FDoubleClickControl := nil;
  end;
end;

procedure TVeridianApp.HandleMouseUp(AControl: PControl; var AEvent: TMouseEvent; AButton: TButtonState);
var
  selecting: boolean;
  scrollParent: PScrollBar;
  scrollEvent: TScrollEvent;
  now: TDateTime;
begin
  if AButton in AEvent.NewMouseState.ButtonState then
    exit;
  if not (AButton in AEvent.OldMouseState.ButtonState) then
    exit;

  now.CreateNow;
  selecting := SelectingControl = AControl;
  if Assigned(CurrentScrollSlider) and Assigned(CurrentScrollSlider^.Parent) then begin
    scrollParent := PScrollBar(CurrentScrollSlider^.Parent);
    if Assigned(scrollParent^.OnCurrentPosChanged) then begin
      scrollEvent.Create;
      scrollEvent.CurrentPos := scrollParent^.CurrentPos;
      TScrollEventProc(scrollParent^.OnCurrentPosChanged)(scrollParent, scrollEvent);
    end;
  end;
  CurrentScrollSlider := nil;
  if Assigned(Desktop^.ActiveMenu) and (AControl = PControl(Desktop^.ActiveMenu^.ActiveItem)) then
    selecting := true;
  if (LeftMouseDownControl = AControl) or selecting then begin
    AControl^.MouseUp(AEvent);
    AControl^.MouseClick(AEvent);
    HandleDblClick(now, AControl, AEvent);
  end;

  SelectingControl := nil;
  if AButton = bsLeft then
    LeftMouseDownControl := nil
  else
    RightMouseDownControl := nil;
end;

procedure TVeridianApp.ProcessKeyEvents(AControl: PControl; var AEvent: TKeyEvent);
var
  index: integer;
  action: PAction;
  intersects: boolean;
  rect: TRect;
begin
  if AEvent.Key = kyAlt0 then begin
    Close;
    exit;
  end;
  if AEvent.Handled then
    exit;
  if AEvent.Key = kyTab then begin
    if (Assigned(Desktop^.ActiveControl) and Desktop^.ActiveControl^.AcceptTab) then begin
      if Desktop^.ActiveControl^.Parent = PControl(Desktop^.ActiveDropDown) then begin
        Desktop^.ActiveDropDown^.HideList;
        Desktop^.ActiveDropDown := nil;
      end;
      FocusNext(Desktop^.ActiveControl, false);
      AControl^.KeyPress(AEvent);
      AEvent.Handled := true;
      exit;
    end;
  end;
  if AEvent.Key = kyShiftTab then begin
    if (Assigned(AControl) and AControl^.AcceptTab) then begin
      FocusNext(Desktop^.ActiveControl, true);
      AControl^.KeyPress(AEvent);
      AEvent.Handled := true;
      exit;
    end;
  end;
  if (AEvent.Key = kyEsc) and Assigned(Desktop^.ActiveDropDown) then begin
    Desktop^.ActiveDropDown^.GetScreenBounds(rect);
    Desktop^.ActiveDropDown^.HideList;
    Desktop^.ActiveDropDown := nil;
    AEvent.Handled := true;
    exit;
  end;
  for index := 0 to Desktop^.ActionList^.Count - 1 do begin
    action := Desktop^.ActionList^.GetItem(index);
    if (action^.Shortcut <> AEvent.Key) or not action^.Enabled then
      continue;
    Desktop^.DeactivateCurrentMenu;
    HandleActionExecute(AControl, action);
    AEvent.Handled := true;
    break;
  end;
  if not AEvent.Handled then
    AControl^.KeyPress(AEvent);
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

function TVeridianApp.HandleActionExecute(ASender: PObject; AAction: PAction): boolean;
begin
  HandleActionExecute := false;
  if Assigned(AAction) and Assigned(AAction^.OnExecute) then begin
    if Assigned(ASender) and PControl(ASender)^.IsActionControl then
      UpdateActionControl(PActionControl(ASender));
    TActionExecuteProc(AAction^.OnExecute)(ASender, AAction);
    HandleActionExecute := true;
  end;
end;

function TVeridianApp.FocusNext(AControl: PControl; AReverse: boolean): boolean;
var
  parent: PControl;
  current: PControl;
  next: PControl;
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
  Desktop^.GetFocusList(focusList, Desktop);
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
    next := PControl(focusList^.GetItem(currentIndex));
    next^.Focus;
  end;
  FreeAndNil(focusList);
end;

function TVeridianApp.MenuBar: PMenuBar;
begin
  MenuBar := Desktop^.MenuBar;
end;

function TVeridianApp.StatusBar: PStatusBar;
begin
  StatusBar := Desktop^.StatusBar;
end;

{$IFDEF debug}
procedure TVeridianApp.DrawDebugInfo;
var
  txt: string;
  rect: TRect;
  max, mem: longint;
  yPos: integer;
  xPos: integer;
begin
  max := MaxAvail;
  mem := MemAvail;
  Graph^.PushState;
  Graph^.SetForeColor(Desktop^.ForeColor);
  Graph^.SetBackColor(Desktop^.BackColor);
  Graph^.State.Font := SystemFont;
  yPos := Desktop^.Height - Desktop^.StatusBar^.Height - 2 * Desktop^.Font^.Height + 3;
  xPos := 2;
  txt := 'MemAvail: ' + FormatLong(FMemAvail);
  if mem <> FMemAvail then begin
    rect.SetDims(xPos, yPos, 150, SystemFont^.Height);
    Graph^.FillRect(rect);
    txt := 'MemAvail: ' + FormatLong(mem);
    FMemAvail := mem;
    Graph^.DrawText(rect.X, rect.Y, txt);
  end;
  Inc(yPos, SystemFont^.Height);
  if max <> FMaxAvail then begin
    txt := 'MaxAvail: ' + FormatLong(FMaxAvail);
    rect.SetDims(xPos, yPos, 150, SystemFont^.Height);
    Graph^.FillRect(rect);
    txt := 'MaxAvail: ' + FormatLong(max);
    FMaxAvail := max;
    Graph^.DrawText(rect.X, rect.Y, txt);
  end;

  Graph^.PopState;
end;
{$ENDIF}

procedure TVeridianApp.SetMouseSensitivity(ASens: real);
var
  aspectRatio: real;
begin
  aspectRatio := Graph^.Mode^.Height / Graph^.Mode^.Width;
  Mouse.SetSensitivity(ASens, aspectRatio *ASens);
end;

procedure TVeridianApp.ClearMouseOver;
begin
  if not Assigned(FMouseOverControl) then
    exit;
  FMouseOverControl^.IsMouseOver := false;
  FMouseOverControl := nil;
end;

procedure TVeridianApp.ProcessEvents;
begin
  Desktop^.MenuBar^.BringToFront;
  Desktop^.StatusBar^.BringToFront;
  Mouse.UpdateState;
  FMouseState.Assign(Mouse.State);
  HandleCursor;
  ProcessMessages;
  {$IFDEF debug}
  DrawDebugInfo;
  {$ENDIF}
  if not FMouseState.Equals(FOldMouseState) then begin
    Graph8^.MoveMouseCursor(FMouseState, FOldMouseState);
    if State.CursorOn then
      DrawCursor;
    ProcessMouseEvents;
    FOldMouseState.Assign(FMouseState);
  end;
  if Keyboard.KeyPressed then begin
    FKeyEvent.Clear;
    FKeyEvent.Key := Keyboard.GetKey;
    ProcessKeyEvents(Desktop, FKeyEvent);
  end;
end;

procedure TVeridianApp.Run;
begin
  ApplySettings;
  State.DrawEnabled := true;
  Desktop^.Draw;
  Mouse.SetMousePosition(Graph^.Mode^.Width div 2, Graph^.Mode^.Height div 2);
  Mouse.ShowMouse;
  Graph8^.ShowMouseCursor;
  FMouseState.Assign(Mouse.State);
  FOldMouseState.Assign(FMouseState);
  inherited Run;
end;

procedure TAppState.Init;
begin
  inherited Init;
  CursorOn := false;
  MouseCursor := nil;
  DrawEnabled := false;
end;

procedure TAppState.Assign(var ASource: TObject);
var
  source: PAppState;
begin
  inherited Assign(ASource);
  source := PAppState(@ASource);
  CursorOn := source^.CursorOn;
  MouseCursor := source^.MouseCursor;
  DrawEnabled := source^.DrawEnabled;
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