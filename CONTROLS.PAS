{TODO: check errors}
{$IFDEF debug}
  {$A-,B-,D+,E+,F+,G-,I+,L+,N+,M 16384 0 655360,O-,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,E+,F+,G-,I+,L-,N+,M 16384 0 655360,O-,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}
unit Controls;

interface

uses
  Objects,
  Collects,
  Consts,
  Drawing,
  GraphDrv,
  MouseDrv,
  Streams,
  Strings,
  StrUtils,
  KeyDrv,
  Actions,
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
  PEventProc = ^TEventProc;

  TEvent = object(TObject)
  public
    Handled: boolean;
    Intersects: boolean;
    NewMouseState: TMouseState;
    OldMouseState: TMouseState;
    MouseState: TMouseState;
    Key: word;
    procedure Init; virtual;
    procedure Clear; virtual;
  end;

  TEventProc = procedure(ASender: PObject; var AEvent: TEvent);

  TControl = Object(TIdentifiable)
  private
    FMoving: boolean;
    procedure HandleMouseDown(var AEvent: TEvent; AButton: TButtonState); virtual;
    procedure HandleMouseUp(var AEvent: TEvent; AButton: TButtonState); virtual;
    procedure HandleMouseMove(var AEvent: TEvent); virtual;
    procedure HandleMenus(var AEvent: TEvent);
  public
    X, Y: integer;
    Width, Height: word;
    Visible: boolean;
    BorderColor: byte;
    ForeColor: byte;
    BackColor: byte;
    FocusedColor: byte;
    HoverForeColor: byte;
    HoverBackColor: byte;
    HoverHighlightColor: byte;
    OnMouseMove: PEventProc;
    OnMouseUp: PEventProc;
    OnMouseDown: PEventProc;
    OnMouseClick: PEventProc;
    OnMouseEnter: PEventProc;
    OnMouseLeave: PEventProc;
    OnKeyPress: PEventProc;
    Controls: PControlList;
    Parent: PControl;
    BorderStyle: TBorderStyle;
    Modal: boolean;
    IsLeftMouseDown: boolean;
    IsRightMouseDown: boolean;
    IsMouseOver: boolean;
    ToolTip: PChar;
    ShowToolTip: boolean;
    Position: TScreenPosition;
    MoveStartX, MoveStartY: longint;
    Grouped: boolean;
    TakesControl: boolean;
    TextX, TextY: integer;
    OldCursorOn: boolean;
    Enabled: boolean;
    Focused: boolean;
    CanFocus: boolean;
    UsesCursor: boolean;
    AcceptEnter: boolean;
    AcceptTab: boolean;
    DrawEnabled: boolean;
    Font: PFont;
    Tag: integer;
    constructor Create(AId: string);
    constructor CreateParent(AId: string; AParent: PControl);
    procedure Init; virtual;
    destructor Free; virtual;
    procedure Hide; virtual;
    procedure Show; virtual;
    procedure Draw; virtual;
    procedure DrawSelf; virtual;
    procedure Paint; virtual;
    procedure PaintRegion(AScreenRect: TRect; AExclude: PControl); virtual;
    procedure GetBounds(var ARect: TRect); virtual;
    procedure SetBounds(AX, AY, AWidth, AHeight: integer); virtual;
    procedure SetBoundsRect(ARect: TRect); virtual;
    procedure GetScreenBounds(var ARect : TRect); virtual;
    procedure GetClientScreenBounds(var ARect: TRect); virtual;
    procedure GetClipRect(var ARect: TRect); virtual;
    procedure GetClientRect(var ARect: TRect); virtual;
    procedure DrawControls; virtual;
    procedure ProcessMouse(var AEvent: TEvent); virtual;
    procedure ProcessKeyboard(var AEvent: TEvent); virtual;
    procedure SetupControls; virtual;
    procedure MouseMove(var AEvent: TEvent); virtual;
    procedure MouseUp(var AEvent: TEvent); virtual;
    procedure MouseDown(var AEvent: TEvent); virtual;
    procedure MouseClick(var AEvent: TEvent); virtual;
    procedure MouseEnter(var AEvent: TEvent); virtual;
    procedure MouseLeave(var AEvent: TEvent); virtual;
    procedure Focus; virtual;
    procedure Unfocus; virtual;
    procedure KeyPress(var AEvent: TEvent); virtual;
    procedure StartDrawing; virtual;
    procedure EndDrawing; virtual;
    function TrueTextWidth(AText: string): integer;
    function GetVisible: boolean; virtual;
    function GetEnabled: boolean; virtual;
    function GetModal: boolean; virtual;
    function AddControl(AControl: PControl): PControl; virtual;
  end;

  TActionControl = Object(TControl)
  private
  public
    ActionId: integer;
    Action: PAction;
    Text: PChar;
    TextAlign: TTextAlign;
    VertAlign: TVertAlign;
    ShowShortcut: boolean;
    ShortcutDisplayName: PChar;
    Shortcut: word;
    HighlightForeColor: byte;
    Margin: integer;
    constructor CreateEmpty;
    constructor Create(AId: string; AActionId: integer);
    function GetEnabled: boolean; virtual;
    function GetShortcut: word; virtual;
    function GetText: string; virtual;
    function GetShortcutDisplayName: string; virtual;
    procedure SetText(const AText: string); virtual;
    procedure Init; virtual;
    destructor Free; virtual;
  end;

  TControlList = Object(TIdentifiableList)
  private
    Parent: PControl;
  public
    constructor CreateParent(AParent: PControl);
    function ToString: string; virtual;
    function GetItem(index: integer): PControl;
    function GetItemById(AId: string): PControl;
    function IndexOf(AItem: PControl): integer;
    function Add(AItem: PControl): integer;
    procedure Init; virtual;
    procedure Insert(AIndex: integer; AItem: PControl);
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

  TPanel = Object(TActionControl)
  private
  public
    DrawBackground: boolean;
    function BorderWidth: integer; virtual;
    procedure Init; virtual;
    procedure Paint; virtual;
    procedure PaintRegion(AScreenRect: TRect; AExclude: PControl); virtual;
    destructor Free; virtual;
  end;

  TLabel = Object(TPanel)
  private
  public
    Autosize: boolean;
    procedure Init; virtual;
    procedure Paint; virtual;
    procedure SetupControls; virtual;
    destructor Free; virtual;
  end;

  TButton = Object(TPanel)
    Pressed: boolean;
    Toggle: boolean;
    Active: boolean;
    PressedBackColor: byte;
    PressedForeColor: byte;
    PressedHighlightForeColor: byte;
    DisabledForeColor: byte;
    procedure MouseEnter(var AEvent: TEvent); virtual;
    procedure MouseLeave(var AEvent: TEvent); virtual;
    procedure MouseDown(var AEvent: TEvent); virtual;
    procedure MouseClick(var AEvent: TEvent); virtual;
    procedure Init; virtual;
    procedure Paint; virtual;
  end;

  TPopUp = object(TPanel)
  private
  public
    BackData: PMemoryStream;
    BackRect: TRect;
    destructor Free; virtual;
    procedure Init; virtual;
    procedure Show; virtual;
    procedure Hide; virtual;
  end;

implementation

uses
  GraphApp,
  VeriApp,
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

function TControlList.GetItem(index: integer): PControl;
begin
  GetItem := pointer(inherited GetItem(index));
end;

function TControlList.IndexOf(AItem: PControl): integer;
begin
  IndexOf := inherited IndexOf(AItem);
end;

function TControlList.Add(AItem: PControl): integer;
begin
  Add := -1;
  if AItem = nil then
    exit;
  Add := inherited Add(AItem);
  AItem^.Parent := Parent;
end;

procedure TControlList.Insert(AIndex: integer; AItem: PControl);
begin
  if AItem = nil then
    exit;
  inherited Insert(AIndex, AItem);
  AItem^.Parent := Parent;
end;

function TControlList.GetItemById(AId: string): PControl;
begin
  GetItemById := PControl(inherited GetItemById(AId));
end;

constructor TControl.Create(AId: string);
begin
  inherited CreateId(AId);
end;

constructor TControl.CreateParent(AId: string; AParent: PControl);
begin
  inherited CreateId(AId);
  if AParent <> nil then
    AParent^.Controls^.Add(@self);
end;

procedure TControl.Init;
begin
  inherited Init;
  Controls := New(PControlList, CreateParent(@self));
  SetBounds(0, 0, 0, 0);
  Tag := 0;
  FMoving := false;
  Visible := true;
  Position := spRelative;
  BorderStyle := bsNone;
  ForeColor := 0;
  BackColor := 0;
  HoverForeColor := 0;
  HoverBackColor := 0;
  HoverHighlightColor := 0;
  BorderColor := 0;
  FocusedColor := 0;
  OnMouseMove := nil;
  OnMouseUp := nil;
  OnMouseDown := nil;
  OnKeyPress := nil;
  OnMouseEnter := nil;
  OnMouseLeave := nil;
  OnMouseClick := nil;
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
  OldCursorOn := false;
  Focused := false;
  CanFocus := false;
  UsesCursor := false;
  AcceptEnter := false;
  AcceptTab := false;
  DrawEnabled := true;
  ToolTip := nil;
  Parent := nil;
  Font := Desktop^.Font;
end;

function TControl.AddControl(AControl: PControl): PControl;
begin
  Controls^.Add(AControl);
end;

procedure TControl.HandleMouseMove(var AEvent: TEvent);
begin
  if AEvent.Handled then
    exit;
  if (AEvent.OldMouseState.X = AEvent.NewMouseState.X) and
     (AEvent.OldMouseState.Y = AEvent.NewMouseState.Y) then
    exit;
  if AEvent.Intersects or FMoving then begin
    MouseMove(AEvent);
    if IsMouseOver then
      exit;
    IsMouseOver := true;
    IsLeftMouseDown := bsLeft in AEvent.NewMouseState.ButtonState;
    IsRightMouseDown := bsRight in AEvent.NewMouseState.ButtonState;
    MouseEnter(AEvent);
    if OnMouseEnter <> nil then
      TEventProc(OnMouseEnter)(@self, AEvent);
    exit;
  end;
  if IsMouseOver then begin
    IsMouseOver := false;
    IsLeftMouseDown := false;
    IsRightMouseDown := false;
    MouseLeave(AEvent);
    if OnMouseLeave <> nil then
      TEventProc(OnMouseLeave)(@self, AEvent);
  end;
end;

procedure TControl.MouseMove(var AEvent: TEvent);
begin
end;

procedure TControl.MouseUp(var AEvent: TEvent);
begin
end;

procedure TControl.MouseDown(var AEvent: TEvent);
begin
end;

procedure TControl.MouseClick(var AEvent: TEvent);
begin
end;

procedure TControl.MouseEnter(var AEvent: TEvent);
begin
end;

procedure TControl.MouseLeave(var AEvent: TEvent);
begin
end;

procedure TControl.Focus;
begin
  if not (CanFocus and GetVisible and GetEnabled) then
    exit;
  Focused := true;
  Desktop^.ActiveControl := @self;
  DrawSelf;
end;

procedure TControl.Unfocus;
begin
  if (not CanFocus) or (not Focused) then exit;
  Focused := false;
  Draw;
  Desktop^.ActiveControl := nil;
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

procedure TControl.GetClientScreenBounds(var ARect: TRect);
var
  par: PControl;
  parRect, result: TRect;
begin
  GetClientRect(ARect);
  ARect.X := ARect.X + X;
  ARect.Y := ARect.Y + Y;
  par := Parent;
  while par <> nil do begin
    par^.GetClientRect(parRect);
    ARect.X := ARect.X + par^.X + parRect.X;
    ARect.Y := ARect.Y + par^.Y + parRect.Y;
    par := par^.Parent;
  end;
end;

procedure TControl.GetScreenBounds(var ARect: TRect);
var
  par: PControl;
  parRect: TRect;
begin
  GetBounds(ARect);
  if (Position = spAbsolute) or (Parent = nil) then exit;
  par := Parent;
  repeat
    if par^.Position = spAbsolute then begin
      par^.GetBounds(parRect);
      ARect.X := ARect.X + parRect.X;
      ARect.Y := ARect.Y + parRect.Y;
      break;
    end
    else begin
      par^.GetClientRect(parRect);
      ARect.X := ARect.X + parRect.X + par^.X;
      ARect.Y := ARect.Y + parRect.Y + par^.Y;
    end;
    par := par^.Parent;
  until (par = nil);
end;

procedure TControl.GetClientRect(var ARect: TRect);
var
  borderWidth: byte;
begin
  borderWidth := 0;
  if BorderStyle <> bsNone then
    borderWidth := 1;
  ARect.CreateDims(borderWidth, borderWidth, Width - borderWidth * 2, Height - borderWidth * 2);
end;

procedure TControl.GetClipRect(var ARect: TRect);
var
  par: PControl;
  parRect, result: TRect;
begin
  GetScreenBounds(ARect);
  if (Position = spAbsolute) or (Parent = nil) then
    exit;
  par := Parent;
  repeat
    if par^.Position = spAbsolute then begin
      par^.GetScreenBounds(parRect);
      ARect.Intersection(ParRect, result);
      ARect := result;
      break;
    end
    else begin
      par^.GetClientScreenBounds(parRect);
      ARect.Intersection(ParRect, result);
      ARect := result;
    end;
    par := par^.Parent;
  until (par = nil);
end;

procedure TControl.SetupControls;
begin
end;

destructor TControl.Free;
begin
  Dispose(controls, Free);
  inherited Free;
end;

function TControl.GetVisible: boolean;
var
  par: PControl;
begin
  GetVisible := false;
  if (not Visible) then exit;
  par := Parent;
  while (par <> nil) do begin
    if (not par^.Visible) then exit;
    par := par^.Parent;
  end;
  GetVisible := true;
end;

function TControl.GetEnabled: boolean;
var
  par: PControl;
begin
  GetEnabled := false;
  if (not Enabled) then exit;
  par := Parent;
  while (par <> nil) do begin
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
  while (par <> nil) do begin
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
    control^.FMoving := false;
    if Desktop^.ActiveControl = control then
      Desktop^.ActiveControl := nil;
  end;
  Visible := false;
  if Parent <> nil then begin
    GetScreenBounds(rect);
    Parent^.PaintRegion(rect, @self);
  end;
end;

procedure TControl.Show;
begin
  Visible := true;
  Draw;
end;

procedure TControl.Paint;
begin
  Graph^.State^.Font := Font;
end;

procedure TControl.PaintRegion(AScreenRect: TRect; AExclude: PControl);
var
  index: integer;
  control: PControl;
  controlRect: TRect;
begin
  Graph^.PushState;
  if Controls^.Count = 0 then
    exit;
  for index := Controls^.Count - 1 downto 0 do begin
    control := Controls^.GetItem(Index);
    control^.GetScreenBounds(controlRect);
    if not controlRect.IntersectRect(AScreenRect) then
      continue;
    if control = AExclude then
      continue;
    control^.Paint;
  end;
  Graph^.PopState;
end;

procedure TControl.DrawSelf;
begin
  if not GetVisible then
    exit;
  StartDrawing;
  Paint;
  EndDrawing;
end;

procedure TControl.Draw;
begin
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
    control := Controls^.GetItem(Index);
    control^.Draw;
  end;
end;

procedure TControl.StartDrawing;
var
  rect: TRect;
begin
  Mouse.PushState;
  Graph^.PushState;
  SetupControls;
  Graph256^.HideMouseCursor;
  Graph^.SetForeColor(ForeColor);
  Graph^.SetBackColor(BackColor);
  GetScreenBounds(rect);
  Graph^.State^.ViewPort.SetRect(rect);
end;

procedure TControl.EndDrawing;
begin
  Graph^.PopState;
  Mouse.PopState;
  Graph256^.MouseCursor^.X := Mouse.State^.X;
  Graph256^.MouseCursor^.Y := Mouse.State^.Y;
  if Mouse.State^.Visible then begin
    Graph256^.MouseCursor^.Visible := Mouse.State^.Visible;
    Graph256^.DrawMouseCursor(Mouse.State^);
  end else begin
    Graph256^.MouseCursor^.Visible := false;
  end;
end;

procedure TControl.KeyPress(var AEvent: TEvent);
var
  index: integer;
  control: PControl;
begin
  if AEvent.Handled then
    exit;
  if Controls^.Count = 0 then
    exit;
  for index := 0 to Controls^.Count - 1 do begin
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

procedure TControl.HandleMouseUp(var AEvent: TEvent; AButton: TButtonState);
begin
  if AEvent.Handled then
    exit;
  if AButton in AEvent.NewMouseState.ButtonState then
    exit;
  if not (AButton in AEvent.OldMouseState.ButtonState) then
    exit;

  if AEvent.Intersects or Modal or FMoving then begin
    if AButton = bsLeft then begin
      AEvent.Handled := true;
      if IsLeftMouseDown then begin
        MouseUp(AEvent);
        if (OnMouseUp <> nil) then
          TEventProc(OnMouseUp)(@Self, AEvent);
      end;
      IsLeftMouseDown := false;
    end else begin
      AEvent.Handled := true;
      if IsRightMouseDown then begin
        MouseDown(AEvent);
        if (OnMouseDown <> nil) then
          TEventProc(OnMouseDown)(@self, AEvent);
      end;
      IsRightMouseDown := false;
    end;
    MouseClick(AEvent);
    if OnMouseClick <> nil then
      TEventProc(OnMouseClick)(@self, AEvent);
  end;
end;

procedure TControl.HandleMenus;
var
  parentItem: PMenuItem;
  rect: TRect;
begin
  if Desktop^.ActiveMenu = nil then
    exit;
  Desktop^.ActiveMenu^.GetScreenBounds(rect);
  if (not AEvent.Intersects) and (not rect.IntersectCoords(AEvent.NewMouseState.X, AEvent.NewMouseState.Y)) then begin
    Desktop^.DeactivateCurrentMenu;
    AEvent.Handled := true;
  end;
end;

procedure TControl.HandleMouseDown(var AEvent: TEvent; AButton: TButtonState);
var
  rect: TRect;
begin
  if not (AButton in AEvent.NewMouseState.ButtonState) then
    exit;
  if AButton in AEvent.OldMouseState.ButtonState then
    exit;
  HandleMenus(AEvent);
  if AEvent.Handled then
    exit;

  if not AEvent.Intersects then
    exit;

  AEvent.NewMouseState.Create;
  if AButton = bsLeft then
    IsLeftMouseDown := true
  else
    IsRightMouseDown := true;
  MouseDown(AEvent);
  if OnMouseDown <> nil then
    TEventProc(OnMouseDown)(@self, AEvent);
end;

procedure TControl.ProcessMouse(var AEvent: TEvent);
var
  index: word;
  rect: TRect;
  control: PControl;
begin
  if not (GetVisible and GetEnabled) then
    exit;
  if AEvent.Handled then
    exit;

  GetScreenBounds(rect);
  AEvent.Intersects := rect.IntersectCoords(AEvent.NewMouseState.X, AEvent.NewMouseState.Y);

  { Get the state in relation to the control's coordinates }
  AEvent.MouseState.Assign(AEvent.NewMouseState);
  Dec(AEvent.MouseState.X, rect.X);
  Dec(AEvent.MouseState.Y, rect.Y);

  { Process child controls }
  if Controls^.Count > 0 then begin
    for index := 0 to Controls^.Count - 1 do begin
      if AEvent.Handled then
        exit;
      control := Controls^.GetItem(index);
      control^.ProcessMouse(AEvent);
    end;
  end;

  if AEvent.Handled then
    exit;

  HandleMouseMove(AEvent);
  if AEvent.Handled then
    exit;
  HandleMouseDown(AEvent, bsLeft);
  if AEvent.Handled then
    exit;
  HandleMouseDown(AEvent, bsRight);
  if AEvent.Handled then
    exit;
  HandleMouseUp(AEvent, bsLeft);
  if AEvent.Handled then
    exit;
  HandleMouseUp(AEvent, bsRight);
end;

procedure TControl.ProcessKeyboard(var AEvent: TEvent);
var
  index: integer;
  action: PAction;
begin
  if Desktop^.ActionList^.Count = 0 then
    exit;
  if AEvent.Handled then
    exit;
  for index := 0 to Desktop^.ActionList^.Count - 1 do begin
    action := Desktop^.ActionList^.GetItem(index);
    if action^.Shortcut <> AEvent.Key then
      continue;
    if not action^.Enabled then
      continue;
    if action^.OnExecute = nil then
      continue;
    TActionEventProc(action^.OnExecute)(@self);
    AEvent.Handled := true;
    exit;
  end;
  KeyPress(AEvent);
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
  if (font = nil) or (len = 0) then
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

constructor TActionControl.Create(AId: string; AActionId: integer);
begin
  inherited CreateId(AId);
  ActionId := AActionId;
  Action := Desktop^.ActionList^.GetActionById(ActionId);
end;

constructor TActionControl.CreateEmpty;
begin
  inherited Create('');
end;

destructor TActionControl.Free;
begin
  DisposeLargeString(Text);
  DisposeLargeString(ShortcutDisplayName);
  inherited Free;
end;

procedure TActionControl.Init;
begin
  inherited Init;
  Text := nil;
  Action := nil;
  TextAlign := taCenter;
  VertAlign := vaCenter;
  Margin := 0;
  ShortcutDisplayName := nil;
  ShowShortcut := true;
  Shortcut := 0;
  HighlightForeColor := 0;
  ActionId := -1;
  Id := nil;
end;

function TActionControl.GetText: string;
begin
  GetText := '';
  if Text = nil then begin
    if (Action <> nil) and (Action^.Text <> nil) then
      GetText := StrPas(Action^.Text)
  end
  else
    GetText := StrPas(Text);
end;

function TActionControl.GetEnabled: boolean;
var
  par: PControl;
begin
  GetEnabled := false;
  if (not Enabled) then exit;
  if (ActionId >= 0) and (not Action^.Enabled) then exit;
  par := Parent;
  while (par <> nil) do begin
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

procedure TActionControl.SetText(const AText: string);
begin
  DisposeLargeString(Text);
  Text := NewLargeString(AText);
end;

function TActionControl.GetShortcutDisplayName: string;
begin
  if (ShortcutDisplayName = nil) then begin
    if (ActionId >= 0) then
      GetShortcutDisplayName := StrPas(Action^.ShortcutDisplayName)
    else
      GetShortcutDisplayName := '';
  end else
    GetShortcutDisplayName := StrPas(ShortcutDisplayName);
end;

procedure TPanel.Init;
begin
  inherited Init;
  ForeColor := Desktop^.InterfaceColors^.Window;
  BackColor := Desktop^.InterfaceColors^.WindowBack;
  BorderColor := Desktop^.InterfaceColors^.Border;
  BorderStyle := bsSingle;
  FocusedColor := Desktop^.InterfaceColors^.Focused;
  DrawBackground := true;
  Margin := 0;
  HighlightForeColor := Desktop^.InterfaceColors^.ButtonHighlight;
end;

destructor TPanel.Free;
begin
  inherited Free;
end;

function TPanel.BorderWidth: integer;
begin
  BorderWidth := 0;
  if (BorderStyle <> bsNone) then
    BorderWidth := 1;
end;

procedure TPanel.PaintRegion(AScreenRect: TRect; AExclude: PControl);
var
  drawRect, controlRect: TRect;
begin
  Graph^.PushState;
  GetScreenBounds(controlRect);
  controlRect.Intersection(AScreenRect, drawRect);
  Graph^.SetForeColor(BorderColor);
  Graph^.SetBackColor(BackColor);
  if DrawBackground then
    Graph^.FillRect(drawRect);
  if BorderStyle <> bsNone then begin
    Graph^.Rectangle(drawRect);
  end;
  Graph^.PopState;
  inherited PaintRegion(AScreenRect, AExclude);
end;

procedure TPanel.Paint;
var
  textXPos, textYPos: integer;
  rect: TRect;
  innerRect: TRect;
  index, currentX: integer;
  textIndex: integer;
  ch: char;
  textWidth: integer;
  mouseState: TMouseState;
  txt, shortcutDesc: string;
begin
  inherited Paint;
  if not GetVisible then
    exit;
  GetScreenBounds(rect);
  Graph^.SetForeColor(BorderColor);
  Graph^.SetBackColor(BackColor);
  if DrawBackground then begin
    if BorderStyle <> bsNone then begin
      innerRect.CreateRect(rect);
      innerRect.Translate(1, 1);
      innerRect.Grow(-2, -2);
    end
    else
      Graph^.FillRect(rect);
  end;
  if BorderStyle <> bsNone then begin
    Graph^.FillRect(innerRect);
    Graph^.Rectangle(rect);
  end;

  textWidth := TrueTextWidth(GetText);
  case TextAlign of
    taLeft: textXPos := rect.X;
    taRight: textXPos := rect.X + rect.Width - textWidth;
    taCenter: textXPos := rect.X + (rect.Width - textWidth) div 2;
  end;
  case VertAlign of
    vaTop: textYPos := rect.Y;
    vaBottom: textYPos := rect.Y + rect.Height - Font^.Height - 1;
    vaCenter: textYPos := rect.Y + (rect.Height - Font^.Height) div 2;
  end;
  index := 0;
  textIndex := 1;
  currentX := Margin;
  txt := GetText;
  if txt = '' then
    exit;
  while textIndex <= Length(txt) do begin
    Graph^.SetForeColor(ForeColor);
    if txt[textIndex] = '&' then begin
      if GetEnabled then
        Graph^.SetForeColor(HighlightForeColor);
      Inc(textIndex);
    end;
    ch := txt[textIndex];
    Graph^.DrawText(textXPos + currentX, TextYPos, ch);
    Inc(textXPos, Font^.TextWidth(ch));
    Inc(index);
    Inc(textIndex);
  end;
  if (GetShortcut >= 0) and ShowShortcut then begin
    shortcutDesc := Keyboard.KeyToShortcut(GetShortcut);
    textXPos := rect.X + rect.Width - Font^.TextWidth(shortcutDesc + '  ');
    Graph^.DrawText(textXPos + currentX, TextYPos, shortcutDesc);
  end;
end;

procedure TButton.Init;
begin
  inherited Init;
  ToolTip := nil;
  CanFocus := true;
  Active := false;
  IsMouseOver := false;
  ForeColor := Desktop^.InterfaceColors^.Button;
  BackColor := Desktop^.InterfaceColors^.ButtonBack;
  HighlightForeColor := Desktop^.InterfaceColors^.ButtonHighlight;
  BorderStyle := bsNone;
  Pressed := false;
  Toggle := false;
  Grouped := false;
  PressedBackColor := Desktop^.InterfaceColors^.ButtonDownBack;
  PressedForeColor := Desktop^.InterfaceColors^.ButtonDown;
  PressedHighlightForeColor := Desktop^.InterfaceColors^.ButtonDownHighlight;
  DisabledForeColor := Desktop^.InterfaceColors^.ButtonDisabled;
  HoverForeColor := Desktop^.InterfaceColors^.ButtonHover;
  HoverBackColor := Desktop^.InterfaceColors^.ButtonHoverBack;
  HoverHighlightColor := Desktop^.InterfaceColors^.ButtonHoverHighlight;
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
  fore, back, highlight: byte;
begin
  fore := ForeColor;
  back := BackColor;
  highlight := HighlightForeColor;
  if not GetEnabled then
    ForeColor := DisabledForeColor
  else if Pressed or Active then begin
    ForeColor := PressedForeColor;
    BackColor := PressedBackColor;
    HighlightForeColor := PressedHighlightForeColor;
  end
  else if IsMouseOver then begin
    ForeColor := HoverForeColor;
    BackColor := HoverBackColor;
    HighlightForeColor := HoverHighlightColor;
  end;
  inherited Paint;
  HighlightForeColor := highlight;
  ForeColor := fore;
  BackColor := back;
end;

procedure TButton.MouseEnter(var AEvent: TEvent);
begin
  if not (GetEnabled and GetVisible) then exit;
  Desktop^.StatusBar^.ShowActionHelp(Action);
  DrawSelf;
end;

procedure TButton.MouseLeave(var AEvent: TEvent);
begin
  if not (GetEnabled and GetVisible) then
    exit;
  Desktop^.StatusBar^.ClearText;
  DrawSelf;
end;

procedure TPopUp.Init;
begin
  inherited Init;
  BackData := nil;
end;

destructor TPopUp.Free;
var
  rect: TRect;
begin
  GetBounds(rect);
  FreeAndNil(BackData);
  inherited Free;
end;

procedure TPopUp.Show;
var
  rect: TRect;
begin
  Visible := true;
  StartDrawing;
  GetScreenBounds(rect);
  if BackData <> nil then
    FreeAndNil(BackData);
  BackData := New(PMemoryStream, Create(rect.Width * rect.Height));
  Graph^.GetImageStreamRect(rect, BackData);
  GetScreenBounds(rect);
  Graph^.State^.ViewPort.SetRect(rect);
  Draw;
  EndDrawing;
end;

procedure TPopUp.Hide;
var
  rect: TRect;
begin
  StartDrawing;
  GetScreenBounds(rect);
  Visible := false;
  if BackData <> nil then begin
    BackData^.Seek(0, soFromBeginning);
    Graph^.DrawImageStream(rect.X, rect.Y, rect.Width, rect.Height, BackData);
    Dispose(BackData, Free);
    BackData := nil;
  end;
  EndDrawing;
end;

procedure TButton.MouseDown(var AEvent: TEvent);
var
  index: word;
  control: PControl;
  button: PButton;
begin
  if not (GetVisible and GetEnabled) then
    exit;
  if CanFocus then
    Focus;
  if Toggle and Grouped and (Parent <> nil) then begin
    for index := 0 to Parent^.Controls^.Count - 1 do begin
      control := Parent^.Controls^.GetItem(index);
      if control^.Grouped then begin
        button := pointer(control);
        button^.Pressed := false;
        control^.Draw;
      end;
    end;
  end;
  Pressed := true;
  Draw;
end;

procedure TButton.MouseClick(var AEvent: TEvent);
begin
  if not Toggle then begin
    Pressed := false;
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
  HighlightForeColor := Desktop^.InterfaceColors^.ButtonHighlight;
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

procedure TEvent.Clear;
begin
  Handled := false;
  Intersects := false;
  Key := 0;
  OldMouseState.Init;
  NewMouseState.Init;
end;

procedure TEvent.Init;
begin
  inherited Init;
  NewMouseState.Create;
  OldMouseState.Create;
  MouseState.Create;
  Clear;
end;


end.