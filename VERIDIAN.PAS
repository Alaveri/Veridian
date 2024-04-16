{$IFDEF debug}
  {$A-,B-,D+,F+,G-,I+,L+,N+,O-,P+,Q+,R+,S+,T-,V-,X+}
{$ELSE}
  {$A-,B-,D-,F+,G-,I+,L-,N+,O-,P+,Q+,R-,S-,T+,V-,X+}
{$ENDIF}
unit Veridian;

interface

uses
  GraphApp,
  AplTypes,
  Lists,
  DateTime,
  Drawing,
  Objects,

  GrDrv8,
  GraphDrv,
  GraphIni,
  MouseDrv,
  KeyDrv,

  Controls,
  Actions,
  Desk;

const
  mKeyDown = 1001;
  mKeyPressed = 1002;
  mKeyUp = 1003;

  DefaultDoubleClickDelay: double = 0.5;
  DefaultCursorBlinkRate = 0.4;

type
  PVeridianApp = ^TVeridianApp;
  PVeridianAppSettings = ^TVeridianAppSettings;
  PAppState = ^TAppState;
  PMessage = ^TMessage;

  TAppState = object(TObject)
  private
  public
    MouseCursor: PMouseCursor;
    CursorOn: boolean;
    procedure Init; virtual;
    procedure Assign(var ASource: TObject); virtual;
  end;

  TMessage = object(TObject)
  private
  public
    Sender: PObject;
    Code: integer;
    Key: word;
    ScanCode: byte;
    X: integer;
    Y: integer;
    ShiftState: TKeyboardFlags;
    procedure Init; virtual;
  end;

  TVeridianAppSettings = object(TObject)
  private
  public
    CursorBlinkRate: double;
    UpdateScrollContents: boolean;
    DoubleClickDelay: TTimeSpan;
    procedure Init; virtual;
    procedure Assign(var ASource: TObject); virtual;
  end;

  TVeridianApp = object(TGraphApp)
  private
    FMouseEvent: TMouseEvent;
    FKeyEvent: TKeyEvent;
    FMouseState: TMouseState;
    FOldMouseState: TMouseState;
    FCursorBlinkVisible: boolean;
    FCurrentTime: TDateTime;
    FBlinkElapsed: TTimeSpan;
    FMouseOverControl: PControl;
    FDragControl: PControl;
    FDoubleClickStart: TDateTime;
    FDoubleClickControl: PControl;
    FDoubleClickX: integer;
    FDoubleClickY: integer;
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
    procedure ProcessMessages;
    procedure LoadFonts;
    procedure CreateDesktop;
    procedure CreateObjects;
  public
    Settings: TVeridianAppSettings;
    CursorBlinkTime: TDateTime;
    State: TAppState;
    StateStack: TObjectStack;
    DrawEnabled: boolean;
    Fonts: PFontList;
    MouseCursors: PMouseCursorList;
    SelectingControl: PControl;
    LeftMouseDownControl: PControl;
    RightMouseDownControl: PControl;
    SystemFont: PFont;
    EditorFont: PFont;
    Parameters: PStringList;
    CurrentScrollSlider: PControl;
    constructor Create(ADriverId: TGraphDrivers; AModeId: string);
    function GetMouseControl(AControl: PControl; var AMouseState: TMouseState): PControl;
    function LoadFont(const AFilename: string): PFont; virtual;
    function HandleActionExecute(AAction: PAction; AActionId: integer): boolean; virtual;
    function ScaleX(AValue: real): integer; virtual;
    function ScaleY(AValue: real): integer; virtual;
    procedure RedrawMouseCursor(AViewPort: TRect);
    procedure Init; virtual;
    procedure ProcessEvents; virtual;
    procedure InitControls; virtual;
    procedure InitMouseCursors; virtual;
    procedure CursorOn;
    procedure CursorOff;
    procedure PushState;
    procedure PopState;
    procedure FocusNext;
    procedure FocusPrevious;
    procedure DeactivateActiveControl;
    procedure Run; virtual;
    {$IFDEF debug}
    procedure DrawDebugInfo;
    {$ENDIF}
    destructor Free; virtual;
  end;

var
  VeridianApp: PVeridianApp;
  AppDir: string;
  MessageQueue: TQueue;

procedure PostMessage(AMessage: PMessage);
procedure PostKeyboardMessage(ACode: integer; ASender: PObject; AKey: word; AScanCode: byte);
procedure PostMouseMessage(ACode: integer; ASender: PObject; X, Y: integer);

implementation

uses
  {$IFDEF DOS}
  Dos,
  {$ENDIF}
  Common,
  MemDrv,
  Views;

procedure PostMessage(AMessage: PMessage);
begin
  MessageQueue.Enqueue(AMessage);
end;

procedure PostKeyboardMessage(ACode: integer; ASender: PObject; AKey: word; AScanCode: byte);
var
  message: PMessage;
begin
  message := New(PMessage, Create);
  if not Assigned(message) then
    exit;
  message^.Code := ACode;
  message^.Sender := ASender;
  message^.Key := AKey;
  message^.ScanCode := AScanCode;
  MessageQueue.Enqueue(message);
end;

procedure PostMouseMessage(ACode: integer; ASender: PObject; X, Y: integer);
var
  message: PMessage;
begin
  message := New(PMessage, Create);
  if not Assigned(message) then
    exit;
  message^.Code := ACode;
  message^.Sender := ASender;
  message^.X := X;
  message^.Y := Y;
  MessageQueue.Enqueue(message);
end;

procedure OnAllocError(ASize: word); far;
begin
  with VeridianApp^ do begin
  end;
end;

constructor TVeridianApp.Create(ADriverId: TGraphDrivers; AModeId: string);
begin
  inherited Create(ADriverId, AModeId);
end;

procedure TVeridianApp.InitMouseCursors;
var
  cursor: PMouseCursor;
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
  end
  else begin
    font := LoadFont('system.fnt');
    SystemFont := font;
    font := LoadFont('editor.fnt');
    EditorFont := font;
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
  FCurrentTime.Create;
  FBlinkElapsed.Create;
  Settings.Create;

  State.Create;
  StateStack.Create;
  CursorBlinkTime.Create;
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
  DrawEnabled := false;
  FCursorBlinkVisible := false;
  Memory.OnAllocError := @OnAllocError;
  FMouseOverControl := nil;
  FDragControl := nil;
  LeftMouseDownControl := nil;
  RightMouseDownControl := nil;
  SelectingControl := nil;
  CurrentScrollSlider := nil;
  FDoubleClickControl := nil;
  FDoubleClickX := 0;
  FDoubleClickY := 0;

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

procedure TVeridianApp.InitControls;
begin
  Desktop^.SetBounds(0, 0, Graph^.Mode^.Width, Graph^.Mode^.Height);
  Desktop^.SetupControls;
end;

function TVeridianApp.ScaleX(AValue: real): integer;
begin
  ScaleX := Min(Graph^.Mode^.Width, Round(AValue * SystemFont^.AverageWidth));
end;

function TVeridianApp.ScaleY(AValue: real): integer;
begin
  ScaleY := Min(Graph^.Mode^.Height, Round(AValue * SystemFont^.Height));
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
  if not DrawEnabled then
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
    FCurrentTime.SetNow;
    FBlinkElapsed.Ticks := FCurrentTime.Ticks - CursorBlinkTime.Ticks;
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
begin
  while MessageQueue.Count > 0 do begin
    message := PMessage(MessageQueue.Dequeue);
    case message^.Code of
      mKeyDown:;
      mKeyUp:;
      mKeyPressed:;
    end;
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
      or (SelectingControl = AControl) or (rect.IntersectsCoords(AMouseState.X, AMouseState.Y)) then
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
  if rect.IntersectsCoords(AEvent.NewMouseState.X, AEvent.NewMouseState.Y) then begin
    AControl^.MouseWheelChanged(AEvent);
  end;
end;

procedure TVeridianApp.HandleMouseDown(AControl: PControl; var AEvent: TMouseEvent; AButton: TButtonState);
var
  rect: TRect;
  intersectsMenu: boolean;
  parentItem: PMenuItem;
begin
  if not (AButton in AEvent.NewMouseState.ButtonState) then
    exit;
  if AButton in AEvent.OldMouseState.ButtonState then
    exit;

  if Assigned(Desktop^.ActiveMenu) then begin
    Desktop^.ActiveMenu^.GetScreenBounds(rect);
    intersectsMenu := rect.IntersectsCoords(AEvent.NewMouseState.X, AEvent.NewMouseState.Y);
    parentItem := Desktop^.ActiveMenu^.ParentItem;
    if Assigned(parentItem) then begin
      parentItem^.GetScreenBounds(rect);
      intersectsMenu := intersectsMenu or rect.IntersectsCoords(AEvent.NewMouseState.X, AEvent.NewMouseState.Y)
    end;
    if not intersectsMenu then begin
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
    FDoubleClickStart.SetNow;
    FDoubleClickControl := AControl;
    FDoubleClickX := AEvent.NewMouseState.X;
    FDoubleClickY := AEvent.NewMouseState.Y;
  end
  else begin
    if (ATime.Ticks <= FDoubleClickStart.Ticks + Settings.DoubleClickDelay.Ticks)
      and (FDoubleClickControl = AControl)
      and (FDoubleClickX = AEvent.NewMouseState.X)
      and (FDoubleClickY = AEvent.NewMouseState.Y) then begin
      AControl^.MouseDblClick(AEvent);
    end;
    FDoubleClickStart.Ticks := 0;
    FDoubleClickControl := nil;
    FDoubleClickX := 0;
    FDoubleClickY := 0;
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
  end;

  if AButton = bsLeft then
    HandleDblClick(now, AControl, AEvent);

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
begin
  if Desktop^.ActionList^.Count = 0 then
    exit;
  if AEvent.Handled then
    exit;
  if AEvent.Key = kyTab then begin
    if (not Assigned(Desktop^.ActiveControl)) or (not Desktop^.ActiveControl^.AcceptTab) then begin
      FocusNext;
      exit;
    end;
  end;
  if AEvent.Key = kyShiftTab then begin
    if (not Assigned(Desktop^.ActiveControl)) or (not Desktop^.ActiveControl^.AcceptTab) then begin
      FocusPrevious;
      exit;
    end;
  end;
  for index := 0 to Desktop^.ActionList^.Count - 1 do begin
    action := Desktop^.ActionList^.GetItem(index);
    if (action^.Shortcut <> AEvent.Key) or not action^.Enabled then
      continue;
    Desktop^.DeactivateCurrentMenu;
    HandleActionExecute(action, action^.ActionId);
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

function TVeridianApp.HandleActionExecute(AAction: PAction; AActionId: integer): boolean;
begin
  HandleActionExecute := false;
  if Assigned(AAction^.OnExecute) then begin
    TActionExecuteProc(AAction^.OnExecute)(AAction, AActionId);
    HandleActionExecute := true;
  end;
end;

procedure TVeridianApp.FocusNext;
var
  index, controlIndex: integer;
  parent: PControl;
  control: PControl;
  next: PControl;
  found: PControl;
begin
  if not Assigned(Desktop^.ActiveControl) then begin
    exit;
  end;
  control := Desktop^.ActiveControl;
  parent := control^.Parent;
  if not Assigned(Parent) then
    exit;
  controlIndex := parent^.Controls^.IndexOf(control);
  found := nil;
  for index := controlIndex + 1 to parent^.Controls^.Count - 1 do begin
    next := parent^.Controls^.GetItem(index);
    if next^.CanFocus and next^.GetEnabled and next^.GetVisible then begin
      found := next;
      break;
    end;
  end;
  if not Assigned(found) then begin
    for index := 0 to controlIndex - 1 do begin
      next := parent^.Controls^.GetItem(index);
      if next^.CanFocus and next^.GetEnabled and next^.GetVisible then begin
        found := next;
        break;
      end;
    end;
  end;
  if Assigned(found) then
    found^.Focus;
end;

procedure TVeridianApp.FocusPrevious;
var
  index, controlIndex: integer;
  parent: PControl;
  control: PControl;
  next: PControl;
  found: PControl;
begin
  if not Assigned(Desktop^.ActiveControl) then begin
    exit;
  end;
  control := Desktop^.ActiveControl;
  parent := control^.Parent;
  if not Assigned(Parent) then
    exit;
  controlIndex := parent^.Controls^.IndexOf(control);
  found := nil;
  for index := controlIndex - 1 downto 0 do begin
    next := parent^.Controls^.GetItem(index);
    if next^.CanFocus and next^.GetEnabled and next^.GetVisible then begin
      found := next;
      break;
    end;
  end;
  if not Assigned(found) then begin
    for index := parent^.Controls^.Count - 1 downto controlIndex + 1 do begin
      next := parent^.Controls^.GetItem(index);
      if next^.CanFocus and next^.GetEnabled and next^.GetVisible then begin
        found := next;
        break;
      end;
    end;
  end;
  if Assigned(found) then
    found^.Focus;
end;

{$IFDEF debug}
procedure TVeridianApp.DrawDebugInfo;
var
  txt: string;
  rect: TRect;
begin
  Graph^.PushState;
  Graph^.SetForeColor(Desktop^.ForeColor);
  Graph^.SetBackColor(Desktop^.BackColor);
  Graph^.State.Font := SystemFont;
  if MemAvail <> FMemAvail then begin
    txt := 'MemAvail: ' + FormatLong(FMemAvail);
    rect.SetDims(Graph^.Mode^.Width - 130, 20, SystemFont^.TextWidth(txt), SystemFont^.Height);
    Graph^.FillRect(rect);
    txt := 'MemAvail: ' + FormatLong(MemAvail);
    FMemAvail := MemAvail;
    rect.SetDims(Graph^.Mode^.Width - 130, 20, SystemFont^.TextWidth(txt), SystemFont^.Height);
    Graph^.DrawText(rect.X, rect.Y, txt);
  end;
  if MaxAvail <> FMaxAvail then begin
    txt := 'MaxAvail: ' + FormatLong(FMaxAvail);
    rect.SetDims(Graph^.Mode^.Width - 130, 38, SystemFont^.TextWidth(txt), SystemFont^.Height);
    Graph^.FillRect(rect);
    txt := 'MaxAvail: ' + FormatLong(MaxAvail);
    FMaxAvail := MaxAvail;
    rect.SetDims(Graph^.Mode^.Width - 130, 38, SystemFont^.TextWidth(txt), SystemFont^.Height);
    Graph^.DrawText(rect.X, rect.Y, txt);
  end;

  Graph^.PopState;
end;
{$ENDIF}

procedure TVeridianApp.ProcessEvents;
begin
  inherited ProcessEvents;
  Desktop^.MenuBar^.BringToFront;
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
  DrawEnabled := true;
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
end;

procedure TAppState.Assign(var ASource: TObject);
var
  source: PAppState;
begin
  inherited Assign(ASource);
  source := PAppState(@ASource);
  CursorOn := source^.CursorOn;
  MouseCursor := source^.MouseCursor;
end;

procedure TMessage.Init;
begin
  inherited Init;
  Sender := nil;
  Code := 0;
  Key := 0;
  ScanCode := 0;
  X := 0;
  Y := 0;
  ShiftState := [];
end;

procedure TVeridianAppSettings.Init;
begin
  inherited Init;
  CursorBlinkRate := DefaultCursorBlinkRate;
  DoubleClickDelay.CreateSeconds(DefaultDoubleClickDelay);
  UpdateScrollContents := true;
end;

procedure TVeridianAppSettings.Assign(var ASource: TObject);
var
  source: PVeridianAppSettings;
begin
  inherited Assign(ASource);
  source := PVeridianAppSettings(@source);
  CursorBlinkRate := source^.CursorBlinkRate;
  DoubleClickDelay := source^.DoubleClickDelay;
  UpdateScrollContents := source^.UpdateScrollContents;
  DoubleClickDelay.Assign(source^.DoubleClickDelay);
end;

end.