{$I COMPILER.INC}
unit Controls;

interface

uses
  Objects,
  Collects,
  Drawing,
  KeyDrv,
  WideStr,
  Utils,
  GraphDrv,
  MouseDrv;

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
  PControl = ^TControl;
  PControlList = ^TControlList;
  PStatusBar = ^TStatusBar;
  PMenuBar = ^TMenuBar;
  PDesktop = ^TDesktop;
  PButton = ^TButton;
  PMouseEvent = ^TMouseEvent;
  TMouseEvent = procedure(sender: PControl; var state: TMouseState);
  PKeyboardEvent = ^TKeyboardEvent;
  TKeyboardEvent = procedure(sender: PControl; var key: word; var handled: boolean);
  TControl = Object(TObject)
  private
  public
    DrawBackground: boolean;
    X, Y: integer;
    Width, Height: word;
    Visible: boolean;
    OnMouseMove: PMouseEvent;
    OnMouseUp: PMouseEvent;
    OnMouseDown: PMouseEvent;
    OnMouseClick: PMouseEvent;
    OnMouseEnter: PMouseEvent;
    OnMouseLeave: PMouseEvent;
    OnKeyPress: PKeyboardEvent;
    Controls: PControlList;
    Parent: PControl;
    BorderStyle: TBorderStyle;
    BorderColor: byte;
    ForeColor: byte;
    BackColor: byte;
    FocusedForeColor: byte;
    FocusedBackColor: byte;
    Modal: boolean;
    IsLeftMouseDown: boolean;
    IsRightMouseDown: boolean;
    IsMouseOver: boolean;
    ScrollX: longint;
    ScrollY: longint;
    ToolTip: string;
    ShowToolTip: boolean;
    Position: TScreenPosition;
    MoveStartX, MoveStartY: longint;
    Moving: boolean;
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
    Manipulating: boolean;
    Font: PFont;
    constructor Create(newId: string);
    constructor CreateParent(newId: string; newParent: PControl);
    procedure Init; virtual;
    destructor Done; virtual;
    procedure Hide; virtual;
    procedure Show; virtual;
    procedure Draw; virtual;
    procedure Paint; virtual;
    procedure SetParent(newParent: PControl); virtual;
    procedure GetBounds(var rect: TRect); virtual;
    procedure SetBounds(newX, newY, newWidth, newHeight: integer); virtual;
    procedure SetBounds2(rect: TRect); virtual;
    procedure GetScreenBounds(var rect : TRect); virtual;
    procedure GetClientScreenBounds(var rect: TRect); virtual;
    procedure GetClipRect(var rect: TRect); virtual;
    procedure GetClientRect(var rect: TRect); virtual;
    procedure DrawControls; virtual;
    procedure ProcessMouse(var state, oldState: TMouseState; var handled: boolean); virtual;
    procedure ProcessKeyPress(var key: word; var handled: boolean); virtual;
    procedure SetupControls; virtual;
    procedure MouseMove(var state: TMouseState); virtual;
    procedure MouseUp(var state: TMouseState); virtual;
    procedure MouseDown(var state: TMouseState); virtual;
    procedure MouseClick(var state: TMouseState); virtual;
    procedure MouseEnter(var state: TMouseState); virtual;
    procedure MouseLeave(var state: TMouseState); virtual;
    procedure Focus; virtual;
    procedure Unfocus; virtual;
    procedure KeyPress(var key: word; var handled: boolean); virtual;
    procedure FocusFirst(var handled: boolean); virtual;
    procedure StartDrawing; virtual;
    procedure EndDrawing; virtual;
    function GetStatusBar: PStatusBar; virtual;
    function GetVisible: boolean; virtual;
    function GetEnabled: boolean; virtual;
    function GetModal: boolean; virtual;
    function GetDesktop: PDesktop; virtual;
  end;
  TControlList = Object(TObjectList)
    function ToString: string; virtual;
    function GetItem(index: integer): PControl;
    function IndexOf(item: PControl): integer;
    function Add(item: PControl): integer;
    procedure Init; virtual;
    procedure Insert(index: integer; item: PControl);
  end;
  PButtonList = ^TButtonList;
  TButtonList = Object(TObjectList)
    function ToString: string; virtual;
    function GetItem(index: integer): PButton;
    function IndexOf(item: PButton): integer;
    function Add(item: PButton): integer;
    procedure Init; virtual;
    procedure Insert(index: integer; item: PButton);
  end;
  PPanel = ^TPanel;
  TPanel = Object(TControl)
  public
    Text: string;
    TextAlign: TTextAlign;
    VertAlign: TVertAlign;
    HighlightColor: byte;
    ShadowColor: byte;
    HotKeyColor: byte;
    HotKey: word;
    Margin: integer;
    function  TrueText(txt: string): string;
    procedure Init; virtual;
    procedure Paint; virtual;
  end;
  TButton = Object(TPanel)
    Pressed: boolean;
    Toggle: boolean;
    Active: boolean;
    PressedBackColor: byte;
    PressedForeColor: byte;
    constructor CreateText(newId, newText: string; newParent: PControl);
    procedure MouseEnter(var state: TMouseState); virtual;
    procedure MouseLeave(var state: TMouseState); virtual;
    procedure MouseDown(var state: TMouseState); virtual;
    procedure MouseClick(var state: TMouseState); virtual;
    procedure Init; virtual;
    procedure Paint; virtual;
  end;
  PPopUp = ^TPopUp;
  TPopUp = object(TPanel)
  private
  public
    {BackData: PByte;
    BackRect: TRect;
    constructor Create(newId: string);
    constructor CreateParent(newId: string; newParent: PControl);
    destructor Done; virtual;
    procedure Init; virtual;
    procedure Show; virtual;
    procedure Hide; virtual;}
  end;
  PMenu = ^TMenu;
  PMenuItem = ^TMenuItem;
  TMenuItem = object(TButton)
  private
  public
    Separator: boolean;
    ShowHotKey: boolean;
    ParentMenu: PMenu;
    Menu: PMenu;
    MenuBar: PMenuBar;
    constructor CreateMenuBar(newId, newText: string; newMenubar: PMenuBar;
      newMenu: PMenu; newHotKey: word; click: PMouseEvent);
    constructor CreateText(newId, newText: string; newParent: PControl; newHotKey: word; click: PMouseEvent);
    constructor CreateSeparator(newId: string; newParent: PControl);
    procedure KeyPress(var key: word; var handled: boolean); virtual;
    procedure MouseEnter(var state: TMouseState); virtual;
    procedure MouseLeave(var state: TMouseState); virtual;
    procedure MouseDown(var state: TMouseState); virtual;
    procedure MouseClick(var state: TMouseState); virtual;
    procedure Paint; virtual;
    procedure Init; virtual;
  end;
  TMenu = object(TPopUp)
  private
  public
    ActiveItem: PMenuItem;
    ParentItem: PMenuItem;
    constructor Create(newId: string);
    procedure KeyPress(var key: word; var handled: boolean); virtual;
    procedure Init; virtual;
    procedure Paint; virtual;
    procedure Show; virtual;
    procedure Hide; virtual;
    procedure SetupControls; virtual;
  end;
  TMenuBar = object(TPanel)
  private
  public
    procedure Init; virtual;
    procedure Paint; virtual;
    procedure SetupControls; virtual;
    {procedure KeyPress(var key: word; var handled: boolean); virtual;
    function ProcessHotKeys(control: PControl; key: word): boolean; virtual;
    function ProcessArrowKeys(key: word): boolean; virtual;}
  end;
  TStatusBar = object(TPanel)
  private
  public
    TextPanel: PPanel;
    procedure Init; virtual;
    procedure Paint; virtual;
    procedure SetupControls; virtual;
    procedure ClearText; virtual;
  end;
  TDesktop = object(TPanel)
  private
  public
    MenuBar: PMenuBar;
    StatusBar: PStatusBar;
    MouseOverControl: PControl;
    ActiveControl: PControl;
    ActiveMenu: PMenu;
    MouseState: TMouseState;
    OldMouseState: TMouseState;
    MouseStack: TStack;
    procedure Init; virtual;
    procedure Paint; virtual;
    procedure GetClientRect(var rect: TRect); virtual;
    procedure KeyPress(var key: word; var handled: boolean); virtual;
    procedure SetupControls; virtual;
    destructor Done; virtual;
    function FindNextControl(control: PControl): PControl; virtual;
    function FindPreviousControl(control: PControl): PControl; virtual;
  end;

var
  icDesktop: byte;
  icDesktopBack: byte;
  icWindow: byte;
  icWindowBack: byte;
  icBorder: byte;
  icButton: byte;
  icButtonBack: byte;
  icButtonDown: byte;
  icButtonDownBack: byte;
  icButtonHotKey: byte;
  icButtonShadow: byte;
  icButtonHighLight: byte;
  icWindowTitle: byte;
  icWindowTitleBack: byte;
  icMenu: byte;
  icMenuBack: byte;
  icHotKey: byte;
  icScroll: byte;
  icScrollBack: byte;
  icEditor: byte;
  icEditorBack: byte;
  icDialog: byte;
  icDialogBack: byte;
  icSelect: byte;
  icSelectBack: byte;
  icFocused: byte;
  icFocusedBack: byte;

implementation

procedure TControlList.Init;
begin
  TObjectList.Init;
  TypeName := 'TControlList';
end;

function TControlList.ToString: string;
begin
  ToString := 'TControlList';
end;

function TControlList.GetItem(index: integer): PControl;
begin
  GetItem := pointer(TObjectList.GetItem(index));
end;

function TControlList.IndexOf(item: PControl): integer;
begin
  IndexOf := TObjectList.IndexOf(item);
end;

function TControlList.Add(item: PControl): integer;
begin
  Add := TObjectList.Add(item);
end;

procedure TControlList.Insert(index: integer; item: PControl);
begin
  TObjectList.Insert(index, item);
end;

constructor TControl.Create(newId: string);
begin
  Id := newId;
  Parent := nil;
  Init;
end;

procedure TControl.SetParent(newParent: PControl);
begin
  Parent := newParent;
  if (Parent <> nil) then
    Parent^.Controls^.Add(@self);
end;

constructor TControl.CreateParent(newId: string; newParent: PControl);
begin
  Id := newId;
  SetParent(newParent);
  Init;
end;

procedure TControl.Init;
begin
  TObject.Init;
  TypeName := 'TControl';
  Controls := New(PControlList, Create);
  SetBounds(0, 0, 0, 0);
  Visible := true;
  Moving := false;
  Position := spRelative;
  BorderStyle := bsNone;
  BorderColor := 0;
  ForeColor := 0;
  FocusedForeColor := 0;
  FocusedBackColor := 0;
  OnMouseMove := nil;
  OnMouseUp := nil;
  OnMouseDown := nil;
  OnKeyPress := nil;
  OnMouseEnter := nil;
  OnMouseLeave := nil;
  OnMouseClick := nil;
  Enabled := true;
  DrawBackground := true;
  Modal := false;
  IsLeftMouseDown := false;
  IsRightMouseDown := false;
  IsMouseOver := false;
  ShowToolTip:= false;
  Grouped := false;
  ScrollX := 0;
  ScrollY := 0;
  TakesControl := false;
  TextX := 0;
  TextY := 0;
  OldCursorOn := true;
  Focused := false;
  CanFocus := false;
  UsesCursor := false;
  AcceptEnter := false;
  AcceptTab := false;
  DrawEnabled := true;
  Manipulating := false;
  ToolTip := '';
  Font := Graphics^.SystemFont;
end;

procedure TControl.MouseMove(var state: TMouseState);
begin
end;

procedure TControl.MouseUp(var state: TMouseState);
begin
end;

procedure TControl.MouseDown(var state: TMouseState);
begin
end;

procedure TControl.MouseClick(var state: TMouseState);
begin
end;

procedure TControl.MouseEnter(var state: TMouseState);
begin
end;

procedure TControl.MouseLeave(var state: TMouseState);
begin
end;

procedure TControl.Focus;
var
  desktop: PDesktop;
begin
  desktop := GetDesktop;
  if not (CanFocus and GetVisible and GetEnabled) then
    exit;
  Focused := true;
  desktop^.ActiveControl := @self;
{  Graphics^.CursorOff;
  Draw;
  Graphcis^.SetXY(TextX, TextY);
  if (UsesCursor) then
    GraphicsDriver^.CursorOn;}
end;

procedure TControl.Unfocus;
var
  desktop: PDesktop;
begin
  desktop := GetDesktop;
  if (not CanFocus) or (not Focused) then exit;
  Focused := false;
  Draw;
  desktop^.ActiveControl := nil;
end;

procedure TControl.FocusFirst(var handled: boolean);
var
  index: integer;
  control: PControl;
  found: boolean;
begin
  if (Controls^.Count <> 0) then
  begin
    for index := 0 to Controls^.Count - 1 do
    begin
      control := Controls^.GetItem(index);
      control^.FocusFirst(handled);
      if (handled) then exit;
    end;
  end;
  if (CanFocus and not Handled) then
  begin
    Focus;
    Handled := true;
{    if (UsesCursor) then
      TextDriver^.CursorOn;}
  end;
end;

procedure TControl.GetBounds(var rect: TRect);
begin
  rect.Create(X, Y, Width, Height);
end;

procedure TControl.SetBounds(newX, newY, newWidth, newHeight: integer);
begin;
  X := newX;
  Y := newY;
  Width := newWidth;
  Height := newHeight;
end;

procedure TControl.SetBounds2(rect: TRect);
begin
  SetBounds(rect.X, rect.Y, rect.Width, rect.Height);
end;

procedure TControl.GetClientScreenBounds(var rect: TRect);
var
  par: PControl;
  parRect, result: TRect;
begin
  GetClientRect(rect);
  rect.X := rect.X + X;
  rect.Y := rect.Y + Y;
  par := Parent;
  while par <> nil do begin
    par^.GetClientRect(parRect);
    rect.X := rect.X + par^.X + parRect.X;
    rect.Y := rect.Y + par^.Y + parRect.Y;
    par := par^.Parent;
  end;
end;

procedure TControl.GetScreenBounds(var rect: TRect);
var
  par: PControl;
  parRect: TRect;
begin
  GetBounds(rect);
  if (Position = spAbsolute) or (Parent = nil) then exit;
  par := Parent;
  repeat
    if (par^.Position = spAbsolute) then begin
      par^.GetBounds(parRect);
      rect.X := rect.X + parRect.X;
      rect.Y := rect.Y + parRect.Y;
      break;
    end
    else begin
      par^.GetClientRect(parRect);
      rect.X := rect.X + parRect.X + par^.X;
      rect.Y := rect.Y + parRect.Y + par^.Y;
    end;
    par := par^.Parent;
  until (par = nil);
end;

procedure TControl.GetClientRect(var rect: TRect);
var
  borderWidth: byte;
begin
  borderWidth := 0;
  if (BorderStyle <> bsNone) then
    borderWidth := 1;
  rect.Create(borderWidth, borderWidth, Width - borderWidth * 2, Height - borderWidth * 2);
end;

procedure TControl.GetClipRect(var rect: TRect);
var
  par: PControl;
  parRect, result: TRect;
begin
  GetScreenBounds(rect);
  if (Position = spAbsolute) or (Parent = nil) then
    exit;
  par := Parent;
  repeat
    if (par^.Position = spAbsolute) then begin
      par^.GetScreenBounds(parRect);
      rect.Intersection(ParRect, result);
      rect := result;
      break;
    end
    else begin
      par^.GetClientScreenBounds(parRect);
      rect.Intersection(ParRect, result);
      rect := result;
    end;
    par := par^.Parent;
  until (par = nil);
end;

procedure TControl.SetupControls;
begin
end;

destructor TControl.Done;
var
  index: word;
  item: PObject;
begin
  if (Controls^.Count > 0) then
  begin
    for index := 0 to Controls^.Count - 1 do begin
     item := Controls^.GetItem(index);
     Dispose(item, Done);
    end;
  end;
  if (Font <> nil) then
    Dispose(Font, Done);
  TObject.Done;
end;

function TControl.GetDesktop: PDesktop;
var
  par: PControl;
begin
  if (Parent = nil) then begin
    GetDesktop := @Self;
    exit;
  end;
  par := Parent;
  while (par^.Parent <> nil) do begin
    par := par^.Parent;
  end;
  GetDesktop := PDesktop(par);
end;

function TControl.GetStatusBar: PStatusBar;
begin
  GetStatusBar := GetDesktop^.StatusBar;
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
  desktop: PDesktop;
begin
  desktop := GetDesktop;
  for index := 0 to Controls^.Count - 1 do begin
    control := Controls^.GetItem(index);
    control^.IsMouseOver := false;
    control^.IsLeftMouseDown := false;
    control^.IsRightMouseDown := false;
    control^.Moving := false;
    if (desktop^.ActiveControl = control) then
      desktop^.ActiveControl := nil;
  end;
  Visible := false;
  Draw;
end;

procedure TControl.Show;
begin
  Visible := true;
  Draw;
end;

procedure TControl.Paint;
begin
end;

procedure TControl.Draw;
begin
  if not GetVisible then exit;
  SetupControls;
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
  if (Controls^.Count = 0) then exit;
  for index := Controls^.Count - 1 downto 0 do begin
    control := Controls^.GetItem(Index);
    control^.Draw;
  end;
end;

procedure TControl.StartDrawing;
begin
  MouseDriver^.PushState;
  Graphics^.PushState;
  if (MouseDriver^.State^.Visible) then
    Graphics^.EraseMouseCursor(MouseDriver^.State^);
{  Graphics^.CursorOff;}
  MouseDriver^.HideMouse;
  Graphics^.SetForeColor(ForeColor);
  Graphics^.SetBackColor(BackColor);
  SetupControls;
end;

procedure TControl.EndDrawing;
var
  mouseState: TMouseState;
begin
  Graphics^.PopState;
  MouseDriver^.PopState;
  if (MouseDriver^.State^.Visible) then begin
    Graphics^.DrawMouseCursor(mouseState);
  end;
{  if (Graphics^.State^.IsCursorOn) then begin
    Graphics^.CursorOn;
  end;}
end;

procedure TControl.KeyPress(var key: word; var handled: boolean);
begin
end;

procedure TControl.ProcessMouse(var state, oldState: TMouseState; var handled: boolean);
var
  Index: word;
  rect: TRect;
  clientRect: TRect;
  intersects: boolean;
  newState: TMouseState;
  desktop: PDesktop;
  control: PControl;
begin
  if not (GetVisible and GetEnabled) then Exit;

  GetClipRect(rect);
  intersects := rect.IntersectPoint(state.X, state.Y);
  desktop := GetDesktop;

  if Controls^.Count > 0 then
  begin
    for index := 0 to Controls^.Count - 1 do
    begin
      control := Controls^.GetItem(index);
      control^.ProcessMouse(state, oldState, handled);
    end;
  end;

  if (oldState.X <> state.X) or (oldState.Y <> state.Y) then
  begin
    if IsMouseOver and (not intersects) then
    begin
      MouseLeave(state);
      if (OnMouseLeave <> nil) then
        TMouseEvent(OnMouseLeave)(@self, state);
      IsMouseOver := false;
      desktop^.MouseOverControl := nil;
    end;
    if (intersects and (not handled)) or Moving or Manipulating then
    begin
      newState.Create;
      newState := state;
      Dec(newState.X, rect.X);
      Dec(newState.Y, rect.Y);
      if (not IsMouseOver) then
      begin
        if (desktop^.MouseOverControl <> nil)
          and (desktop^.MouseOverControl <> @Self)
          then
          desktop^.MouseOverControl^.MouseLeave(state);
        desktop^.MouseOverControl := @self;
        MouseEnter(state);
        if (OnMouseEnter <> nil) then
          TMouseEvent(OnMouseEnter)(@self, state);
        IsMouseOver := true;
      end;
      OldState := state;
      IsLeftMouseDown := (bsLeft in state.ButtonState);
      IsRightMouseDown := (bsRight in state.ButtonState);
      MouseMove(newState);
      if (OnMouseMove <> nil) then
        TMouseEvent(OnMouseMove)(@self, newState);
      handled := true;
    end;
  end;

  if handled then exit;

  if (bsLeft in state.ButtonState) and (not (bsLeft in oldState.ButtonState)) then
  begin
    if (Desktop^.ActiveMenu <> nil) then
    begin
      Desktop^.ActiveMenu^.GetScreenBounds(rect);
      if (not rect.IntersectPoint(state.X, state.Y)) then
      begin
        Desktop^.ActiveMenu^.Hide;
        if (Desktop^.ActiveMenu^.Parent <> nil) and
           (TypeOf(Desktop^.ActiveMenu^.Parent^) = TypeOf(TMenuItem)) then
        begin
          PMenuItem(Desktop^.ActiveMenu^.Parent)^.Pressed := false;
          PMenuItem(Desktop^.ActiveMenu^.Parent)^.Active := false;
          PMenuItem(Desktop^.ActiveMenu^.Parent)^.Draw;
        end;
        Desktop^.ActiveMenu := nil;
      end;
    end;
    if intersects or Modal then
    begin
      Handled := true;
      newState.Create;
      newState := state;
      Dec(newState.X, rect.X);
      Dec(newState.Y, rect.Y);
      IsLeftMouseDown := true;
      OldState := state;
      MouseDown(newState);
      if (OnMouseDown <> nil) then
        TMouseEvent(OnMouseDown)(@self, newState);
    end;
  end;

  if (bsRight in state.ButtonState) and (not (bsRight in oldState.ButtonState)) then
  begin
    if Intersects or Modal then
    begin
      Handled := true;
      newState := state;
      Dec(newState.X, rect.X);
      Dec(newState.Y, rect.Y);
      IsRightMouseDown := true;
      OldState := state;
      MouseDown(newState);
      if (OnMouseDown <> nil) then
        TMouseEvent(OnMouseDown)(@self, newState);
    end;
  end;

  if (not (bsLeft in state.ButtonState)) and (bsLeft in oldState.ButtonState) then
  begin
    if Intersects or Modal or Moving or Manipulating then
    begin
      Handled := true;
      newState.Create;
      newState := state;
      Dec(newState.X, rect.X);
      Dec(newState.Y, rect.Y);
      OldState := state;
      Include(newState.ButtonState, bsLeft);
      if (IsLeftMouseDown) then
      begin
        MouseUp(newState);
        MouseClick(newState);
        if (OnMouseUp <> nil) then
          TMouseEvent(OnMouseUp)(@Self, newState);
        if (OnMouseClick <> nil) then
          TMouseEvent(OnMouseClick)(@self, newState);
      end;
      IsLeftMouseDown := false;
    end;
  end;

  if (not (bsRight in state.ButtonState)) and (bsRight in oldState.ButtonState) then
  begin
    if Intersects or Modal or Moving or Manipulating then
    begin
      Handled := true;
      newState.Create;
      newState := state;
      Dec(newState.X, rect.X);
      Dec(newState.Y, rect.Y);
      OldState := state;
      Include(newState.ButtonState, bsRight);
      if (IsRightMouseDown) then
      begin
        MouseUp(newState);
        MouseClick(newState);
        if (OnMouseUp <> nil) then
          TMouseEvent(OnMouseUp)(@self, newState);
        if (OnMouseClick <> nil) then
          TMouseEvent(OnMouseClick)(@self, newState);
      end;
      IsRightMouseDown := false;
    end;
  end;
end;

procedure TControl.ProcessKeyPress(var key: word; var handled: boolean);
begin
end;

procedure TPanel.Init;
begin
  TControl.Init;
  TypeName := 'TPanel';
  ForeColor := icWindow;
  BackColor := icWindowBack;
  BorderColor := icBorder;
  BorderStyle := bsSingle;
  HighlightColor := icButtonHighlight;
  FocusedForeColor := icFocusedBack;
  FocusedBackColor := icFocused;
  DrawBackground := true;
  Text := '';
  TextAlign := taCenter;
  VertAlign := vaCenter;
  HotKey := 0;
  Margin := 0;
  HotKeyColor := icButtonHotKey;
end;

function TPanel.TrueText(txt: string): string;
var
  index: integer;
  textIndex: integer;
  result: string;
begin
  result := '';
  for index := 1 to Length(txt) do begin
    if (txt[index] <> '&') then result := result + txt[index];
  end;
  TrueText := result;
end;

procedure TPanel.Paint;
var
  textXPos, textYPos: integer;
  desktop: PDesktop;
  clipRect: TRect;
  index, currentX: integer;
  isHotKey: boolean;
  textIndex: integer;
  ch: char;
  txt: string;
  mouseState: TMouseState;
begin
  TControl.Paint;
  if (not GetVisible) then exit;
  desktop := GetDesktop;
  GetClipRect(clipRect);
  Graphics^.SetForeColor(BackColor);
  if (DrawBackground) then
    Graphics^.FillRect(clipRect);
  Graphics^.PushState;
  Graphics^.SetForeColor(BorderColor);
  Graphics^.SetBackColor(BackColor);
  if (BorderStyle <> bsNone) then begin
    Graphics^.Rectangle(clipRect.X, clipRect.Y, ClipRect.Right, ClipRect.Bottom);
  end;
  txt := TrueText(text);
  case TextAlign of
    taLeft: textXPos := clipRect.X;
    taRight: textXPos := clipRect.X + clipRect.Width - Font^.TextWidth(txt);
    taCenter: textXPos := ClipRect.X + (ClipRect.Width - Font^.TextWidth(txt)) div 2;
  end;
  case VertAlign of
    vaTop: textYPos := clipRect.Y;
    vaBottom: textYPos := clipRect.Y + clipRect.Height - Font^.Height - 1;
    vaCenter: textYPos := clipRect.Y + (clipRect.Height - Font^.Height) div 2;
  end;
  index := 0;
  textIndex := 1;
  isHotKey := false;
  currentX := Margin;
  while textIndex <= Length(Text) do
  begin
    if (Text[textIndex] = '&') then begin
      isHotKey := true;
      Inc(textIndex);
    end;
    if (isHotKey) then begin
      isHotKey := false;
      Graphics^.SetForeColor(HotKeyColor);
    end
    else
      Graphics^.SetForeColor(ForeColor);
    ch := Text[textIndex];
    Graphics^.DrawText(textXPos + currentX, TextYPos, ch);
    Inc(textXPos, Font^.TextWidth(ch));
    Inc(index);
    Inc(textIndex);
  end;
end;

constructor TButton.CreateText(newId, newText: string; newParent: PControl);
begin
  SetParent(newParent);
  Id := newId;
  Enabled := true;
  OnMouseClick := nil;
  Text := newText;
  Init;
end;

procedure TButton.Init;
begin
  TPanel.Init;
  TypeName := 'TButton';
  ToolTip := '';
  CanFocus := true;
  Active := false;
  IsMouseOver := false;
  ForeColor := icButton;
  BackColor := icButtonBack;
  HotKeyColor := icButtonHotKey;
  BorderStyle := bsNone;
  Pressed := false;
  Toggle := false;
  Grouped := false;
  PressedBackColor := icButtonDownBack;
  PressedForeColor := icButtonDown;
end;

function TButtonList.ToString: string;
begin
  ToString := TypeName;
end;

function TButtonList.GetItem(index: integer): PButton;
begin
  GetItem := pointer(TObjectList.GetItem(index));
end;

function TButtonList.IndexOf(item: PButton): integer;
begin
  IndexOf := TObjectList.IndexOf(item);
end;

function TButtonList.Add(item: PButton): integer;
begin
  Add := TObjectList.Add(item);
end;

procedure TButtonList.Init;
begin
  TObjectList.Init;
  TypeName := 'TButtonList';
end;

procedure TButtonList.Insert(index: integer; item: PButton);
begin
  TObjectList.Insert(index, item);
end;

procedure TButton.Paint;
begin
  if (Pressed or Active) then begin
    Graphics^.SetForeColor(PressedForeColor);
    Graphics^.SetBackColor(PressedBackColor);
  end;
  TPanel.Paint;
end;

procedure TButton.MouseEnter(var state: TMouseState);
begin
  if not (Enabled and Visible) then exit;
  GetStatusBar^.Text := ToolTip;
  if (state.ButtonState = [bsLeft]) then Pressed := true;
  Draw;
  GetStatusBar^.Draw;
end;

procedure TButton.MouseLeave(var state: TMouseState);
begin
  if not (Enabled and Visible) then exit;
  GetStatusBar^.Text := '';
  if (state.ButtonState = [bsLeft]) then Pressed := false;
  Draw;
  GetStatusBar^.Draw;
end;

procedure TMenuBar.SetupControls;
var
  index: word;
  currentX: word;
  control: PMenuItem;
begin
  currentX := 0;
  SetBounds(0, 0, GetDesktop^.Width, Font^.Height + 4);
  if Controls^.Count = 0 then exit;
  for index := 0 to Controls^.Count - 1 do
  begin
    control := PMenuItem(Controls^.GetItem(index));
    with control^ do
    begin
      X := currentX;
      Y := 0;
      Height := Font^.Height + 3;
      Width := Font^.TextWidth(TrueText(Text + '  '));
      Margin := 1;
      Inc(currentX, Width);
    end;
  end;
end;

procedure TMenuBar.Paint;
var
  rect: TRect;
begin
  TPanel.Paint;
  GetScreenBounds(rect);
  Graphics^.SetForeColor(BorderColor);
  Graphics^.HLine(rect.X, rect.Bottom, rect.Width);
end;

procedure TMenuBar.Init;
var
  rect: TRect;
begin
  TPanel.Init;
  TypeName := 'TMenuBar';
  ForeColor := icMenu;
  BackColor := icMenuBack;
  BorderStyle := bsNone;
end;

constructor TMenu.Create(newId: string);
begin
  Id := newId;
  Enabled := true;
  OnMouseClick := nil;
  ParentItem := nil;
  Init;
end;


procedure TMenu.Paint;
begin
  TPanel.Paint;
end;

procedure TMenu.Show;
begin;
  TPopUp.Show;
end;

procedure TMenu.Hide;
begin
  TPopUp.Hide;
end;

procedure TMenu.SetupControls;
var
  maxWidth: byte;
  index: word;
  item: PMenuItem;
  borderWidth: byte;
  itemWidth: integer;
begin
  X := 0;
  Y := 0;
  maxWidth := Font^.TextWidth('w') * 4;
  borderWidth := 1;
  if (BorderStyle = bsNone) then
    borderWidth := 0;
  if (Parent <> nil) and (TypeOf(Parent^) = TypeOf(TMenuItem)) then begin
    X := Parent^.X;
    Y := Parent^.Height + 1;
  end;
  if (Controls^.Count > 0) then begin;
    for index := 0 to Controls^.Count - 1 do begin
      item := PMenuItem(Controls^.GetItem(index));
      itemWidth := Font^.TextWidth(TrueText(item^.Text + '  '));
      if (itemWidth > maxWidth) then
        maxWidth := itemWidth;
    end;
    for index := 0 to Controls^.Count - 1 do begin
      item := PMenuItem(Controls^.GetItem(index));
      with item^ do
      begin
        TextAlign := taLeft;
        Margin := Font^.TextWidth('W');
        X := 0;
        Y := index * (Font^.Height) + 4;
        Width := MaxWidth;
        Height := Font^.Height + 1;
      end;
    end;
  end;
  Width := maxWidth * borderWidth;
  Height := Controls^.Count * (Font^.Height + 1) + 2 * borderWidth;
end;

procedure TMenu.Init;
begin
  TPopUp.Init;
  TypeName := 'TMenu';
  ParentItem := nil;
  Position := spAbsolute;
  Visible := false;
  ForeColor := icMenu;
  BackColor := icMenuBack;
  BorderStyle := bsSingle;
  ActiveItem := nil;
end;

procedure TMenu.KeyPress(var key: word; var handled: boolean);
var
  desktop: PDesktop;
  index: integer;
  newItem: PMenuItem;
begin
  if not (GetEnabled and GetVisible) then exit;
  desktop := GetDesktop;
  if (handled) then exit;
  if (desktop^.ActiveMenu = @self) then
  begin
    if (ActiveItem <> nil) then begin
      if (key = kDown) or (key = kUp) then
      begin
        handled := true;
        index := Controls^.IndexOf(ActiveItem);
        ActiveItem^.Pressed := false;
        ActiveItem^.Active := false;
        ActiveItem^.Draw;
        if (key = kDown) then begin
          Inc(index);
          if (index > Controls^.Count - 1) then
            index := 0;
          newItem := PMenuItem(Controls^.GetItem(index));
          while (newItem^.Separator) and (index + 1 < Controls^.Count) do begin
            Inc(index);
            newItem := PMenuItem(Controls^.GetItem(index));
          end;
        end
        else
        begin
          Dec(index);
          if (index < 0) then
            index := Controls^.Count - 1;
          newItem := PMenuItem(Controls^.GetItem(index));
          while (newItem^.Separator) and (index - 1 >= 0) do begin
            Dec(index);
            newItem := PMenuItem(Controls^.GetItem(index));
          end;
        end;
        ActiveItem := newItem;
        newItem^.Active := true;
        newItem^.Pressed := true;
        newItem^.Draw;
      end
    end;
    if (key = 27) then begin
      if (ParentItem = nil) then exit;
      ParentItem^.Pressed := false;
      ParentItem^.Active := false;
      ParentItem^.Draw;
      ActiveItem^.Pressed := false;
      ActiveItem^.Active := false;
      ActiveItem := nil;
      desktop^.ActiveMenu := nil;
      Hide;
      handled := true;
    end;
  end;
end;


constructor TMenuItem.CreateText(newId, newText: string; newParent: PControl; newHotKey: word; click: PMouseEvent);
begin
  SetParent(newParent);
  Init;
  Id := newId;
  Text := newText;
  Separator := false;
  MenuBar := nil;
  Enabled := true;
  HotKey := newHotKey;
  ShowHotKey := true;
  OnMouseClick := click;
  ParentMenu := nil;
  if (TypeOf(newParent^) = TypeOf(TMenu)) then
    ParentMenu := PMenu(newParent);
  Menu := nil;
end;

constructor TMenuItem.CreateSeparator(newId: string; newParent: PControl);
begin
  SetParent(newParent);
  menu := nil;
  Init;
  Id := 'MenuSeparator';
  Enabled := false;
  Text := '-';
  MenuBar := nil;
  ShowHotKey := false;
  Separator := true;
  ParentMenu := nil;
  if (TypeOf(newParent^) = TypeOf(TMenu)) then
    ParentMenu := PMenu(newParent);
end;

constructor TMenuItem.CreateMenuBar
(
  newId,
  newText: string;
  newMenubar: PMenuBar;
  newMenu: PMenu;
  newHotKey: word;
  click: PMouseEvent
);
begin
  SetParent(newMenuBar);
  MenuBar := newMenuBar;
  Init;
  Id := newId;
  Text := newText;
  Separator := false;
  Enabled := true;
  HotKey := newHotKey;
  ShowHotKey := false;
  OnMouseClick := click;
  ParentMenu := nil;
  Menu := newMenu;
  newMenu^.SetParent(@self);
  newMenu^.ParentItem := @self;
end;

procedure TMenuItem.Init;
begin
  TButton.Init;
  TypeName := 'TMenuItem';
  ForeColor := icMenu;
  BackColor := icMenuBack;
  BorderStyle := bsNone;
  Grouped := true;
  Toggle := true;
  VertAlign := vaCenter;
  TextAlign := taCenter;
end;

procedure TMenuItem.KeyPress(var key: word; var handled: boolean);
var
  state: TMouseState;
begin
  if (Menu <> nil) then
    Menu^.KeyPress(key, handled);
  if (handled) then exit;
  FillChar(state, SizeOf(State), 0);
  if (key = 13) and GetVisible and GetEnabled and Active then begin
    if (ParentMenu <> nil) then begin
      ParentMenu^.ActiveItem^.Pressed := false;
      ParentMenu^.ActiveItem^.Active := false;
      handled := true;
    end;
    state.ButtonState := [bsLeft];
    MouseClick(state);
  end;
end;

procedure TMenuItem.MouseEnter(var state: TMouseState);
var
  desktop: PDesktop;
begin
  if not (GetVisible and GetEnabled and not IsMouseOver) then exit;
  if (Separator) then exit;
  GetStatusBar^.Text := ToolTip;
  GetStatusBar^.Draw;
  if (Parent <> nil) then begin
    if (ParentMenu <> nil) then begin
      if (ParentMenu^.ActiveItem <> nil) and (ParentMenu^.ActiveItem^.Active) then begin
        ParentMenu^.ActiveItem^.Active := false;
        ParentMenu^.ActiveItem^.Pressed := false;
        ParentMenu^.ActiveItem^.Draw;
      end;
    end;
  end;
  Pressed := true;
  Draw;
end;

procedure TMenuItem.MouseLeave(var state: TMouseState);
begin
  if not (GetVisible and GetEnabled) then exit;
  if (Separator) then exit;
  Pressed := false;
  GetStatusBar^.Text := '';
  GetStatusBar^.Draw;
  Draw;
end;

procedure TMenuItem.MouseDown(var state: TMouseState);
var
  desktop: PDesktop;
  parentItem: PMenuItem;
begin
  TControl.MouseDown(state);
  if (not GetEnabled) then exit;
  desktop := GetDesktop;
  if (desktop^.ActiveMenu <> nil) and (desktop^.ActiveMenu <> ParentMenu) then begin
    desktop^.ActiveMenu^.Hide;
    parentItem := PMenuItem(desktop^.ActiveMenu^.ParentItem);
    if (parentItem <> nil) then begin
      parentItem^.Pressed := false;
      parentItem^.Active := false;
      parentItem^.Draw;
    end;
  end;
  if (Menu <> nil) then begin
    desktop^.ActiveMenu := Menu;
    Pressed := true;
    if (not Active) then
    begin
      Active := true;
      Menu^.ActiveItem := PMenuItem(Menu^.Controls^.GetItem(0));
      Menu^.ActiveItem^.Pressed := true;
      Menu^.ActiveItem^.Active := true;
      Menu^.Visible := true;
      Draw;
    end;
  end;
end;

procedure TMenuItem.MouseClick(var state: TMouseState);
var
  menuItem: PMenuItem;
  desktop: PDesktop;
begin
  if not (GetEnabled) then exit;
  if (ParentMenu <> nil) then
  begin
    ParentMenu^.ActiveItem := nil;
    Pressed := false;
    Active := false;
    IsMouseOver := false;
    if (ParentMenu^.ParentItem <> nil) then begin
      menuItem := PMenuItem(ParentMenu^.ParentItem);
      menuItem^.Pressed := false;
      menuItem^.Active := false;
      menuItem^.Draw;
      ParentMenu^.Hide;
    end;
    desktop := GetDesktop;
    desktop^.ActiveMenu := nil;
  end;

  if (OnMouseClick <> nil) then
    TMouseEvent(OnMouseClick)(@self, state);
end;

procedure TMenuItem.Paint;
var
  rect: TRect;
  desc: string;
begin
  if (not GetVisible) then exit;
  if Separator then
  begin
    GetScreenBounds(rect);
    Graphics^.SetForeColor(BorderColor);
    Graphics^.HLine(rect.X, Rect.Y + (rect.Height div 2), rect.Width);
  end
  else
    TButton.Paint;
  if (ShowHotKey and (HotKey <> 0)) then
  begin
    if (Pressed or Active) then
    begin
      Graphics^.SetForeColor(PressedForeColor);
      Graphics^.SetBackColor(PressedBackColor);
    end;
    GetClipRect(rect);
    desc := '';{GetKeyDesc(HotKey);}
    Graphics^.DrawText(rect.X + rect.Width - Font^.TextWidth(desc), rect.Y, desc);
  end;
end;

procedure TButton.MouseDown(var state: TMouseState);
var
  index: word;
  control: PControl;
  button: PButton;
begin
  if not (GetVisible and GetEnabled) then exit;
  if CanFocus then
    Focus;
  if Toggle and Grouped and (Parent <> nil) then begin
    for index := 0 to Parent^.Controls^.Count - 1 do
    begin
      control := Parent^.Controls^.GetItem(index);
      if (control^.Grouped) then begin
        button := pointer(control);
        button^.Pressed := false;
        control^.Draw;
      end;
    end;
  end;
  Pressed := true;
  Draw;
end;

procedure TButton.MouseClick(var state: TMouseState);
begin
  if (not Toggle) then begin
    Pressed := false;
    Draw;
  end;
  TPanel.MouseClick(state);
end;

procedure TStatusBar.Init;
begin
  TPanel.Init;
  TypeName := 'TStatusBar';
  ForeColor := icMenu;
  BackColor := icMenuBack;
  BorderStyle := bsNone;
  TextPanel := New(PPanel, CreateParent('~TextPanel', @self));
  TextPanel^.TextAlign := taleft;
  TextPanel^.Margin := 1;
end;

procedure TStatusBar.SetupControls;
var
  rect: TRect;
begin
  GetDesktop^.GetBounds(rect);
  SetBounds(0, rect.Height - Font^.Height - 3, rect.Width, Font^.Height + 3);
  with TextPanel^ do
  begin
    BorderStyle := bsNone;
    ForeColor := icMenu;
    BackColor := icMenuBack;
    SetBounds(0, rect.Y + 1, rect.Width, rect.Height);
  end;
end;

procedure TStatusBar.ClearText;
var
  rect: TRect;
begin
end;

procedure TStatusBar.Paint;
var
  rect: TRect;
begin
  TPanel.Paint;
  GetClipRect(rect);
  Graphics^.SetForeColor(BorderColor);
  Graphics^.HLine(rect.X, rect.Y, rect.Width);
  ClearText;
  Graphics^.DrawText(rect.X, rect.Y, Text);
end;

procedure TDesktop.SetupControls;
begin
  SetBounds(0, 0, Graphics^.Mode^.Width, Graphics^.Mode^.Height);
end;

procedure TDesktop.Init;
begin
  TPanel.Init;
  TypeName := 'TDesktop';
  DrawBackground := true;
  BorderStyle := bsNone;
  ActiveControl := nil;
  ActiveMenu := nil;
  MouseOverControl := nil;
  ForeColor := icDesktop;
  BackColor := icDesktopBack;
  MenuBar := New(PMenuBar, CreateParent('DesktopMenuBar', @self));
  StatusBar := New(PStatusBar, CreateParent('DesktopStatusBar', @self));
  OldMouseState.Create;
end;

destructor TDesktop.Done;
begin
  TPanel.Done;
end;

procedure TDesktop.Paint;
begin
  TPanel.Paint;
end;

procedure TDesktop.GetClientRect(var rect: TRect);
begin
  rect.Create(0, 0, Graphics^.Mode^.Width, Graphics^.Mode^.Height);
end;

function TDesktop.FindNextControl(control: PControl): PControl;
var
  index: integer;
  par: PControl;
  current: PControl;
begin
  {FindNextControl := nil;
  par := control^.Parent;
  if ((par = nil) or (not par^.GetVisible) or (not par^.GetEnabled)
    or (par^.Controls^.Count = 0)) then
    exit;
  index := par^.Controls^.IndexOf(control);
  Inc(index);
  if (index > par^.Controls^.Count - 1) then
  begin
    if par^.GetModal then
    begin
      index := 0;
      current := par^.Controls^.GetItem(index);
    end
    else
    begin
      par := par^.Parent;
      if (par = nil) or (par^.Controls^.Count = 0) then exit;
      current := par^.Controls^.GetItem(0);
    end;
  end
  else
    current := par^.Controls^.GetItem(index);
  if ((current <> nil) and current^.GetVisible and current^.GetEnabled and current^.CanFocus) then
  begin
    if (ActiveControl <> nil) then
    begin
     HideMouse;
     ActiveControl^.Unfocus;
     current^.Focus;
     ShowMouse;
    end;
  end
  else
  begin
    if (current <> nil) and (not current^.AcceptTab) then
      FindNextControl := FindNextControl(current);
  end;}
end;

function TDesktop.FindPreviousControl(control: PControl): PControl;
begin

end;

procedure TDesktop.KeyPress(var key: word; var handled: boolean);
var
  control: PControl;
  stop: boolean;
begin
  {if (key = 9) then
  begin
    handled := true;
    if (Controls^.Count = 0) then exit;
    control := ActiveControl;
    if (control = nil) then
      control := Controls^.GetItem(0);
    if (control^.GetVisible and control^.GetEnabled and (control = ActiveControl))
      and (control^.AcceptTab) then
      exit;
    stop := false;
    control := FindNextControl(control);
    if (control <> nil) then
      handled := true;
  end;}
end;

end.