{$I COMPILER.INC}
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
  VeriCons,
  Colors;

type
  PControl = ^TControl;
  PControlList = ^TControlList;
  PButtonList = ^TButtonList;
  PDesktop = ^TDesktop;
  PCaptionControl = ^TCaptionControl;
  PActionControl = ^TActionControl;
  PFocusControl = ^TFocusControl;
  PPopUp = ^TPopUp;
  PLabel = ^TLabel;
  PButton = ^TButton;

  TBorderStyle = (bsNone, bsSingle, bsRaised, bsLowered);

  THorzAlign =
  (
    haLeft,
    haRight,
    haCenter
  );

  TVertAlign =
  (
    vaTop,
    vaBottom,
    vaCenter
  );

  TAlign =
  (
    alNone,
    alLeft,
    alRight,
    alTop,
    alBottom,
    alClient
  );

  TSpacing = object(TObject)
  private
  public
    Left: integer;
    Top: integer;
    Right: integer;
    Bottom: integer;
    constructor CreateAll(ALeft, ATop, ARight, ABottom: integer);
    constructor CreateValue(AValue: integer);
    constructor CreateLeft(ALeft: integer);
    constructor CreateTop(ATop: integer);
    constructor CreateRight(ARight: integer);
    constructor CreateBottom(ABottom: integer);
    constructor CreateLeftRight(ALeft, ARight: integer);
    constructor CreateTopBottom(ATop, ABottom: integer);
    constructor CreateHorz(AValue: integer);
    constructor CreateVert(AValue: integer);
    function Width: integer;
    function Height: integer;
    procedure Init; virtual;
  end;

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

  TButtonList = object(TIdentifiableList)
  private
  public
    function GetItemById(const AId: string): PButton;
    function GetItem(AIndex: integer): PButton;
    function Add(AItem: PButton): integer;
    procedure SetItem(AIndex: integer; AItem: PButton);
    procedure Insert(AIndex: integer; AItem: PButton);
  end;

  TControl = object(TMessageObject)
  private
  public
    X, Y: integer;
    Width, Height: word;
    Font: PFont;
    MouseCursor: PMouseCursor;
    Parent: PControl;
    Controls: PControlList;
    Position: TScreenPosition;
    Visible: boolean;
    ForeColor, BackColor: byte;
    FillPattern: PFillPattern;
    LinePattern: PLinePattern;
    Modal: boolean;
    Align: TAlign;
    Tag: integer;
    CanDrag: boolean;
    CanUndo: boolean;
    Margins: TSpacing;
    Padding: TSpacing;
    OnKeyPress: PKeyEventProc;
    OnMouseDown: PMouseEventProc;
    OnMouseMove: PMouseEventProc;
    OnMouseUp: PMouseEventProc;
    OnMouseClick: PMouseEventProc;
    OnMouseDblClick: PMouseEventProc;
    OnMouseEnter: PMouseEventProc;
    OnMouseLeave: PMouseEventProc;
    OnMouseWheelChanged: PMouseEventProc;
    OnDragStart: PMouseEventProc;
    OnDragMove: PMouseEventProc;
    OnDragEnd: PMouseEventProc;
    OnEnter: PEventProc;
    OnExit: PEventProc;
    OnRun: PEventProc;
    constructor Create(AId: string);
    constructor CreateParent(AId: string; AParent: PControl);
    destructor Free; virtual;
    procedure Init; virtual;
    function IsVisible: boolean;
    function IsActionControl: boolean; virtual;
    function IsFocusControl: boolean; virtual;
    function IsMouseOver: boolean;
    function GetX: integer;
    function GetY: integer;
    function GetWidth: word;
    function GetHeight: word;
    function BorderWidth: byte; virtual;
    function SpacingWidth: integer;
    function SpacingHeight: integer;
    procedure GetXY(var APX, APY: integer);
    procedure SetVisible(AVisible: boolean);
    procedure SetForeColor(AForeColor: byte);
    procedure SetBackColor(ABackColor: byte);
    procedure Layout; virtual;
    procedure SetXY(AXPos, AYPos: integer); virtual;
    procedure SetX(APX: integer); virtual;
    procedure SetY(APY: integer); virtual;
    procedure SetWidthHeight(AWidth, AHeight: word); virtual;
    procedure SetWidth(AWidth: word); virtual;
    procedure SetHeight(AHeight: word); virtual;
    procedure GetBounds(var ARect: TRect);
    procedure GetScreenBounds(var ARect: TRect);
    procedure GetClientBounds(var ARect: TRect);
    procedure GetClientScreenBounds(var ARect: TRect);
    procedure DrawControl(ADrawControls: boolean); virtual;
    procedure AlignControl;
    procedure Draw;
    procedure DrawSelf;
    procedure DrawControls;
    procedure Hide; virtual;
    procedure Show; virtual;
    procedure BringToFront;
    procedure SendToBack;
    procedure Run; virtual;
    procedure BeginDrawing; virtual;
    procedure EndDrawing; virtual;
    procedure SetBounds(APX, APY: integer; AWidth, AHeight: word);
    procedure SetBoundsRect(const ARect: TRect);
    procedure Paint; virtual;
    procedure PaintRegion(const ARect: TRect; AExclude: PControl); virtual;
    procedure KeyPress(var AEvent: TKeyEvent); virtual;
    procedure MouseDown(var AEvent: TMouseEvent); virtual;
    procedure MouseUp(var AEvent: TMouseEvent); virtual;
    procedure MouseMove(var AEvent: TMouseEvent); virtual;
    procedure MouseEnter(var AEvent: TMouseEvent); virtual;
    procedure MouseLeave(var AEvent: TMouseEvent); virtual;
    procedure MouseClick(var AEvent: TMouseEvent); virtual;
    procedure MouseDblClick(var AEvent: TMouseEvent); virtual;
    procedure MouseWheelChanged(var AEvent: TMouseEvent); virtual;
    procedure DragStart(var AEvent: TMouseEvent); virtual;
    procedure DragMove(var AEvent: TMouseEvent); virtual;
    procedure DragEnd(var AEvent: TMouseEvent); virtual;
    procedure InvokeSender(AEventProc: pointer; ASender: PObject; var AEvent: TEvent);
    procedure Invoke(AEventProc: pointer; var AEvent: TEvent);
  end;

  TPanel = object(TControl)
  private
  public
    TransparentBack: boolean;
    BorderColor: byte;
    BorderStyle: TBorderStyle;
    ShadowColor: byte;
    LightColor: byte;
    function BorderWidth: byte; virtual;
    procedure Init; virtual;
    procedure SetBorderColor(AColor: byte);
    procedure SetBorderStyle(AStyle: TBorderStyle);
    procedure Paint; virtual;
  end;

  TDesktop = object(TPanel)
  private
  public
    ActionList: PActionList;
    procedure Init; virtual;
    procedure Layout; virtual;
    procedure GetClientBounds(var ARect: TRect); virtual;
    destructor Free; virtual;
  end;

  TContentControl = object(TPanel)
  private
  public
    HorzAlign: THorzAlign;
    VertAlign: TVertAlign;
    AutoSize: boolean;
    function ContentWidth: integer; virtual;
    function ContentHeight: integer; virtual;
    procedure GetAlign(const ABounds: TRect; const ASize: TSize;
      var AResult: TPoint);
    procedure Init; virtual;
    procedure Layout; virtual;
    procedure SetHorzAlign(AHorzAlign: THorzAlign);
    procedure SetVertAlign(AVertAlign: TVertAlign);
    procedure SetAutoSize(AAutoSize: boolean);
  end;

  TCaptionControl = object(TContentControl)
  private
  public
    Caption: PChar;
    Wrap: boolean;
    constructor CreateParent(const AId: string; AParent: PControl);
    constructor CreateCaption(const AId, ACaption: string; AParent: PControl);
    function ContentHeight: integer; virtual;
    function ContentWidth: integer; virtual;
    procedure Init; virtual;
    procedure Paint; virtual;
    procedure SetCaption(ACaption: string);
    procedure SetWrap(AWrap: boolean);
    procedure GetTextAlign(const ABounds: TRect; var AResult: TPoint);
    function TrueTextWidth(const AText: string): integer;
    function GetCaption: string; virtual;
    destructor Free; virtual;
  end;

  TActionControl = object(TCaptionControl)
  private
  public
    Enabled: boolean;
    Action: PAction;
    ShowShortcut: boolean;
    ShortcutDisplayName: PChar;
    Shortcut: word;
    ShortcutColor: byte;
    ShortcutSpacing: integer;
    DisabledColor, DisabledBackColor: byte;
    constructor CreateId(AId: string; AAction: PAction);
    constructor CreateParent(AId: string; AAction: PAction; AParent: PControl);
    constructor CreateAction(AId: string; AAction: PAction; AParent: PControl);
    procedure Init; virtual;
    procedure paint; virtual;
    procedure Enable;
    procedure Disable;
    function GetAltHotKey: word; virtual;
    function GetHotKey: word; virtual;
    function IsActionControl: boolean; virtual;
    function GetCaption: string; virtual;
    function GetShortcut: word; virtual;
    function GetShortcutDesc: string; virtual;
    function IsEnabled: boolean;
    function IsVisibleAndEnabled: boolean;
    procedure SetEnabled(AEnabled: boolean);
    procedure SetAction(AAction: PAction);
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
    CanFocus: boolean;
    constructor CreateId(AId: string);
    constructor CreateParent(AId: string; AParent: PControl);
    constructor CreateAction(AId: string; AAction: PAction; AParent: PControl);
    function CursorX: integer;
    function CursorY: integer;
    function Focused: boolean;
    function IsFocusControl: boolean; virtual;
    function GetCursorForeColor: byte;
    function GetCursorBackColor: byte;
    procedure GetCursorRect(var ARect: TRect);
    procedure SetXY(AXPos, AYPos: integer); virtual;
    procedure Init; virtual;
    procedure Focus; virtual;
    procedure UnFocus; virtual;
    procedure SetFocus(AFocus, ARedraw: boolean); virtual;
    procedure MouseDown(var AEvent: TMouseEvent); virtual;
    procedure Paint; virtual;
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
    procedure Paint; virtual;
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
    procedure Init; virtual;
    procedure Paint; virtual;
    procedure MouseDown(var AEvent: TMouseEvent); virtual;
    procedure MouseClick(var AEvent: TMouseEvent); virtual;
    procedure MouseEnter(var AEvent: TMouseEvent); virtual;
    procedure MouseLeave(var AEvent: TMouseEvent); virtual;
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

procedure TControl.Init;
begin
  inherited Init;
  Parent := nil;
  Controls := New(PControlList, Create(@Self));
  X := 0;
  Y := 0;
  Width := 0;
  Height := 0;
  Visible := true;
  Align := alNone;
  Position := spRelative;
  ForeColor := VeridianApp^.Colors.Window;
  BackColor := VeridianApp^.Colors.WindowBack;
  FillPattern := nil;
  LinePattern := nil;
  Modal := false;
  Margins.Create;
  Padding.Create;
  Tag := 0;
  CanDrag := false;
  CanUndo := false;
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
  OnMouseDblClick := nil;
  OnMouseEnter := nil;
  OnMouseLeave := nil;
  OnMouseWheelChanged := nil;
  OnEnter := nil;
  OnExit := nil;
  OnRun := nil;
  Font := Desktop^.Font;
  MouseCursor := VeridianApp^.MouseCursors^.GetItemById('Default');
end;

procedure TControl.SetVisible(AVisible: boolean);
var
  rect: TRect;
begin
  GetScreenBounds(rect);
  if Visible and not AVisible then begin
    Visible := false;
    if not Assigned(Parent) then
      exit;
    Graph^.PushState;
    VeridianApp^.CursorOff;
    Graph^.State^.ViewPort := rect;
    Parent^.Paint;
    Graph^.PopState;
    exit;
  end;
  if AVisible and not Visible then begin
    Visible := true;
    Draw;
    exit;
  end;
end;

function TControl.IsActionControl: boolean;
begin
  IsActionControl := false;
end;

function TControl.IsFocusControl: boolean;
begin
  IsFocusControl := false;
end;

function TControl.GetX: integer;
var
  rect: TRect;
begin
  GetClientBounds(rect);
  GetX := X - rect.X;
end;

function TControl.GetY: integer;
var
  rect: TRect;
begin
  GetClientBounds(rect);
  GetY := Y - rect.Y;
end;

procedure TControl.GetXY(var APX, APY: integer);
var
  rect: TRect;
begin
  GetClientBounds(rect);
  APX := X - rect.X;
  APY := Y - rect.Y;
end;

function TControl.GetWidth: word;
var
  rect: TRect;
begin
  GetClientBounds(rect);
  GetWidth := rect.Width;
end;

function TControl.GetHeight: word;
var
  rect: TRect;
begin
  GetClientBounds(rect);
  GetHeight := rect.Height;
end;

procedure TControl.SetXY(AXPos, AYPos: integer);
var
  rect: TRect;
begin
  GetClientBounds(rect);
  X := rect.X + AXPos;
  Y := rect.Y + AYPos;
  Draw;
end;

procedure TControl.SetX(APX: integer);
var
  rect: TRect;
begin
  GetClientBounds(rect);
  X := rect.X + APX;
  Draw;
end;

procedure TControl.SetY(APY: integer);
var
  rect: TRect;
begin
  GetClientBounds(rect);
  Y := rect.Y + APY;
  Draw;
end;

procedure TControl.InvokeSender(AEventProc: pointer; ASender: PObject;
  var AEvent: TEvent);
begin
  if Assigned(AEventProc) then
    TEventProc(AEventProc)(ASender, AEvent);
end;

procedure TControl.Invoke(AEventProc: pointer; var AEvent: TEvent);
begin
  InvokeSender(AEventProc, @self, AEvent);
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
begin
  SetVisible(false);
end;

procedure TControl.Show;
begin
  SetVisible(true);
end;

procedure TControl.DragStart(var AEvent: TMouseEvent);
begin
  Invoke(OnDragStart, AEvent);
end;

procedure TControl.DragMove(var AEvent: TMouseEvent);
begin
  Invoke(OnDragMove, AEvent);
end;

procedure TControl.DragEnd(var AEvent: TMouseEvent);
begin
  Invoke(OnDragEnd,  AEvent);
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

function TControl.IsMouseOver: boolean;
begin
  IsMouseOver := VeridianApp^.MouseOverControl = @self;
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
  Parent^.GetClientBounds(rect);
  selfIndex := Parent^.Controls^.IndexOf(@self);
  offsetX := 0;
  offsetY := 0;
  for index := 0 to selfIndex - 1 do begin
    control := Parent^.Controls^.GetItem(index);
    if control = @self then
      continue;
    if (Align <> alClient) and (control^.Align <> Align) then
      continue;
    case control^.Align of
      alLeft: Inc(offsetX, control^.Width);
      alRight: Dec(offsetX, control^.Width);
      alTop: Inc(offsetY, control^.Height);
      alBottom: Dec(offsetY, control^.Height);
    end;
  end;
  case Align of
    alLeft: SetBounds(rect.X + offsetX, rect.Y + offsetY,
      Width, rect.Height);
    alRight: SetBounds(rect.Right - Width + offsetX, rect.Y + offsetY,
      Width, rect.Height);
    alTop: SetBounds(rect.X + offsetX, rect.Y + offsetY,
      rect.Width, Height);
    alBottom: SetBounds(rect.X + offsetX, rect.Bottom - Height + offsetY,
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

procedure TControl.GetClientBounds(var ARect: TRect);
begin
  ARect.CreateDims(0, 0, Width, Height);
  ARect.Grow(-2 * BorderWidth, -2 * BorderWidth);
  ARect.Translate(BorderWidth, BorderWidth);
end;

procedure TControl.GetClientScreenBounds(var ARect: TRect);
begin
  GetScreenBounds(ARect);
  ARect.Grow(-2 * BorderWidth, -2 * BorderWidth);
  ARect.Translate(BorderWidth, BorderWidth);
end;

procedure TControl.DrawControl(ADrawControls: boolean);
begin
  if not IsVisible then
    exit;
  if not VeridianApp^.State.DrawEnabled then
    exit;
  BeginDrawing;
  Paint;
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
  parentRect, rect, mouseRect: TRect;
  par: PControl;
begin
  VeridianApp^.PushState;
  Mouse.PushState;
  Graph^.PushState;
  Layout;
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
  MouseCursor^.GetBounds(mouseRect);
  VeridianApp^.HideMouseCursor;
  Graph^.SetForeColor(ForeColor);
  Graph^.SetBackColor(BackColor);
  Graph^.State^.Font := Font;
  Graph^.State^.ViewPort := rect;
end;

procedure TControl.EndDrawing;
var
  rect, mouseRect: TRect;
  cursor: PMouseCursor;
begin
  Graph^.PopState;
  Mouse.PopState;
  VeridianApp^.PopState;
  cursor := VeridianApp^.MouseCursor;
  cursor^.X := Mouse.State.X;
  cursor^.Y := Mouse.State.Y;
  GetScreenBounds(rect);
  cursor^.GetBounds(mouseRect);
  if Mouse.State.Visible then begin
    cursor^.Visible := Mouse.State.Visible;
    VeridianApp^.DrawMouseCursor(Mouse.State);
  end else begin
    cursor^.Visible := false;
  end;
end;

procedure TControl.SetForeColor(AForeColor: byte);
begin
  ForeColor := AForeColor;
  Draw;
end;

procedure TControl.SetBackColor(ABackColor: byte);
begin
  BackColor := ABackColor;
  Draw;
end;

procedure TControl.GetBounds(var ARect: TRect);
begin
   ARect.CreateDims(X, Y, Width, Height);
end;

procedure TControl.GetScreenBounds(var ARect: TRect);
var
  parentRect: TRect;
begin
  GetBounds(ARect);
  if (Position = spAbsolute) or not Assigned(Parent) then
    exit;
  if Assigned(Parent) then begin
    Parent^.GetScreenBounds(parentRect);
    ARect.Translate(parentRect.X, parentRect.Y);
    ARect.Translate(Margins.Left, Margins.Top);
  end;
end;

procedure TControl.SetBounds(APX, APY: integer; AWidth, AHeight: word);
begin
  X := APX;
  Y := APY;
  Width := AWidth;
  Height := AHeight;
end;

procedure TControl.SetBoundsRect(const ARect: TRect);
begin
  X := ARect.X;
  Y := ARect.Y;
  Width := ARect.Width;
  Height := ARect.Height;
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
end;

procedure TControl.PaintRegion(const ARect: TRect; AExclude: PControl);
{var
  index: integer;
  control: PControl;}
begin
{  BeginDrawing;
  Text^.State^.ViewPort := ARect;
  Paint;
  for index := 0 to Controls^.Count - 1 do begin
    control := Controls^.GetItem(index);
    if control = AExclude then
      continue;
    control^.PaintRegion(ARect, AExclude);
  end;
  EndDrawing;}
end;

function TControl.BorderWidth: byte;
begin
  BorderWidth := 0;
end;

procedure TControl.SendToBack;
begin
  if (Parent = nil) or (Parent^.Controls^.Count < 2) then
    exit;
  if Parent^.Controls^.IndexOf(@self) = 0 then
    exit;
  Parent^.Controls^.RemoveItem(@self);
  Parent^.Controls^.Insert(0, @self);
end;

procedure TControl.BringToFront;
begin
  if (Parent = nil) or (Parent^.Controls^.Count < 2) then
    exit;
  if Parent^.Controls^.IndexOf(@self) = Parent^.Controls^.Count - 1 then
    exit;
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

procedure TControl.MouseDblClick(var AEvent: TMouseEvent);
begin
  Invoke(OnMouseDblClick, AEvent);
end;

procedure TControl.MouseWheelChanged(var AEvent: TMouseEvent);
begin
  Invoke(OnMouseWheelChanged, AEvent);
end;

procedure TControl.Run;
var
  event: TEvent;
begin
  event.Create;
  Invoke(OnRun, event);
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
  Enabled := true;
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
  inherited Layout;
  if AutoSize then begin
    Width := ContentWidth + Padding.Width;
    Height := ContentHeight + Padding.Height;
  end;
end;

procedure TContentControl.GetAlign(const ABounds: TRect; const ASize: TSize;
  var AResult: TPoint);
begin
  AResult.Create;
  case HorzAlign of
    haLeft: AResult.X := ABounds.X + BorderWidth + Padding.Left;
    haRight: AResult.X := ABounds.Right - ASize.Width - BorderWidth - Padding.Right;
    haCenter: AResult.X := ABounds.X + (ABounds.Width - ASize.Width) div 2 + BorderWidth;
  end;
  case VertAlign of
    vaTop: AResult.Y := ABounds.Y + BorderWidth + Padding.Top;
    vaBottom: AResult.Y := ABounds.Bottom - ASize.Height - BorderWidth - Padding.Bottom;
    vaCenter: AResult.Y := ABounds.Y + (ABounds.Height - ASize.Height) div 2 + BorderWidth;
  end;
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

procedure TContentControl.SetAutoSize(AAutoSize: boolean);
begin
  AutoSize := AAutoSize;
  Draw;
end;

function TContentControl.ContentWidth: integer;
begin
  ContentWidth := 0;
end;

function TContentControl.ContentHeight: integer;
begin
  ContentHeight := 0;
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

constructor TActionControl.CreateAction(AId: string; AAction: PAction; AParent: PControl);
begin
  CreateParent(AId, Action, AParent);
end;

procedure TActionControl.SetEnabled(AEnabled: boolean);
begin
  Enabled := AEnabled;
  Draw;
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

function TActionControl.IsEnabled: boolean;
var
  parentControl: PControl;
  result: boolean;
  function ControlEnabled(AControl: PControl): boolean;
  var
    actionControl: PActionControl;
  begin
    ControlEnabled := true;
    if not AControl^.IsActionControl then
      exit;
    actionControl := PActionControl(AControl);
    ControlEnabled := actionControl^.Enabled;
    if Assigned(actionControl^.Action) then
      ControlEnabled := actionControl^.Action^.Enabled;
  end;
begin
  result := ControlEnabled(@self);
  parentControl := Parent;
  while Assigned(parentControl) do begin
    if not ControlEnabled(parentControl) then begin
      result := false;
      break;
    end;
    parentControl := parentControl^.Parent;
  end;
  IsEnabled := result;
end;

function TActionControl.IsVisibleAndEnabled: boolean;
begin
  IsVisibleAndEnabled := IsVisible and IsEnabled;
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
    GetCaption := StrPas(Action^.Text)
  else if Assigned(Caption) then
    GetCaption := StrPas(Caption);
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
  txt := StrPas(Caption);
  for index := 1 to Length(txt) do begin
    if (txt[index] = '&') and (length(txt) >= index + 1) then begin
      GetAltHotKey := Keyboard.CharToAltChar(txt[index + 1]);
      exit;
    end;
  end;
  GetAltHotKey := 0;
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

procedure TActionControl.Paint;
var
  rect: TRect;
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
  GetScreenBounds(rect);
  GetTextAlign(rect, pos);
  currentForeColor := ForeColor;
  currentBackColor := BackColor;
  if not IsEnabled then begin
    currentForeColor := DisabledColor;
    currentBackColor := DisabledBackColor;
  end;
  index := 1;
  TPanel.Paint;
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
  if GetShortcut > 0 then begin
    desc := GetShortcutDesc;
    pos.X := rect.Right - TrueTextWidth(desc) - Margins.Right - BorderWidth;
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
  Down := false;
  BorderStyle := bsRaised;
  Toggle := false;
  Clickable := true;
end;

procedure TButton.Paint;
var
  oldShadowColor, oldLightColor: byte;
begin
  if not (IsVisible and VeridianApp^.State.DrawEnabled) then
    exit;
  oldShadowColor := ShadowColor;
  oldLightColor := LightColor;
  if Down then begin
    ShadowColor := oldLightColor;
    LightColor := oldShadowColor;
  end;
  inherited Paint;
  ShadowColor := oldShadowColor;
  LightColor := oldLightColor;
end;

procedure TButton.MouseDown(var AEvent: TMouseEvent);
var
  index: word;
  control: PControl;
  button: PButton;
begin
  if not IsVisibleAndEnabled then
    exit;
  if not Clickable then
    exit;
  if CanFocus then
    Focus;
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
  if VeridianApp^.LeftMouseDownControl = @self then begin
    Down := true;
    DrawSelf;
  end;
end;

procedure TButton.MouseLeave(var AEvent: TMouseEvent);
begin
  if not IsVisibleAndEnabled then
    exit;
  if VeridianApp^.LeftMouseDownControl = @self then begin
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
end;

procedure TLabel.Paint;
begin
  inherited Paint;
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

procedure TPanel.Paint;
var
  rect: TRect;
begin
  inherited Paint;
  GetScreenBounds(rect);
  Graph^.SetForeColor(ForeColor);
  Graph^.SetBackColor(BackColor);
  Graph^.SetFillPattern(FillPattern);
  Graph^.SetLinePattern(LinePattern);
  if not TransparentBack then
    Graph^.FillRect(rect);
  case BorderStyle of
    bsSingle: begin
      Graph^.SetForeColor(BorderColor);
      Graph^.Rectangle(rect);
    end;
    bsRaised: begin
      Graph^.SetForeColor(ShadowColor);
      Graph^.VLine(rect.Right, rect.Y, rect.Height);
      Graph^.HLine(rect.X, rect.Bottom, rect.Width);
      Graph^.SetForeColor(LightColor);
      Graph^.HLine(rect.X, rect.Y, rect.Width);
      Graph^.VLine(rect.X, rect.Y, rect.Height);
    end;
    bsLowered: begin
      Graph^.SetForeColor(LightColor);
      Graph^.VLine(rect.Right, rect.Y, rect.Height);
      Graph^.HLine(rect.X, rect.Bottom, rect.Width);
      Graph^.SetForeColor(ShadowColor);
      Graph^.HLine(rect.X, rect.Y, rect.Width);
      Graph^.VLine(rect.X, rect.Y, rect.Height);
    end;
  end;
end;

function TPanel.BorderWidth: byte;
begin
  if BorderStyle = bsNone then
    BorderWidth := 0
  else
    BorderWidth := 1;
end;

procedure TDesktop.Init;
begin
  inherited Init;
  Visible := true;
  BorderStyle := bsNone;
  ForeColor := VeridianApp^.Colors.Desktop;
  BackColor := VeridianApp^.Colors.DesktopBack;
  ActionList := New(PActionList, Create);
end;

procedure TDesktop.Layout;
begin
  inherited Layout;
  SetBounds(0, 0, Graph^.Mode^.Width, Graph^.Mode^.Height);
end;

procedure TDesktop.GetClientBounds(var ARect: TRect);
begin
  GetBounds(ARect);
  if VeridianApp^.MenuBar <> nil then begin
    ARect.Translate(0, VeridianApp^.MenuBar^.Height);
    ARect.Grow(0, -VeridianApp^.MenuBar^.Height);
  end;
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
end;

constructor TCaptionControl.CreateParent(const AId: string; AParent: PControl);
begin
  inherited Create(AId);
  Parent := AParent;
  if Assigned(Parent) then
    AParent^.Controls^.Add(@self);
end;

procedure TCaptionControl.SetCaption(ACaption: string);
begin
  TString.AssignString(Caption, ACaption);
  Draw;
end;

procedure TCaptionControl.SetWrap(AWrap: boolean);
begin
  Wrap := AWrap;
  Draw;
end;

function TCaptionControl.ContentWidth: integer;
begin
  ContentWidth := TrueTextWidth(GetCaption);
end;

function TCaptionControl.ContentHeight: integer;
begin
  ContentHeight := Font^.Height;
end;

function TCaptionControl.GetCaption: string;
begin
  GetCaption := '';
  if Assigned(Caption) then
    GetCaption := StrPas(Caption);
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

procedure TCaptionControl.GetTextAlign(const ABounds: TRect; var AResult: TPoint);
var
  textWidth: integer;
  txt: string;
  size: TSize;
begin
  txt := GetCaption;
  size.CreateDims(TrueTextWidth(txt), Font^.Height);
  GetAlign(ABounds, size, AResult);
end;

procedure TCaptionControl.Init;
begin
  inherited Init;
  Caption := nil;
  Wrap := false;
end;

procedure TCaptionControl.Paint;
var
  rect: TRect;
  next, index: word;
  left, right: integer;
  pos: TPoint;
  current, cw, tw: word;
  ch: char;
  { Returns the index of the next break in the caption }
  { for the current line, High(word) if no break is }
  { found, or High(word) - 1 if the end of the string }
  { is reached before a break }
  function GetLineBreakIndex: word;
  var
    currentChar: char;
    current: word;
    breakIndex: word;
    lineWidth: integer;
    charWidth, totalWidth: integer;
  begin
    lineWidth := right - left;
    current := index + lineWidth + 1; { Default to end of line }
    totalWidth := 0;
    for breakIndex := 0 to lineWidth - 1 do begin
      currentChar := Caption[index + breakIndex];
      charWidth := Font^.TextWidth(currentChar);
      Inc(totalWidth);
      if (currentChar = #0) or (currentChar = #13) then begin
        { End of string reached before break }
        GetLineBreakIndex := index + breakIndex;
        exit;
      end;
      if currentChar in WhiteSpaceChars then begin
        { Found a break }
        { Break is after the end of the line, return previous }
        if totalWidth >= (right - left) then
          break;
        { Set current break index }
        current := index + breakIndex;
      end;
    end;
    GetLineBreakIndex := current;
  end;
begin
  inherited Paint;
  if not Assigned(Caption) then
    exit;
  GetScreenBounds(rect);
  if rect.IsEmpty then
    exit;
  right := rect.Right;
  Graph^.SetForeColor(ForeColor);
  Graph^.SetBackColor(BackColor);
  GetTextAlign(rect, pos);
  left := pos.X;
  index := 0;
  ch := Caption^;
  tw := 0;
  while true do begin
    ch := Caption[index];
    cw := Font^.TextWidth(ch);
    Inc(tw, cw);
    if (ch = #0) or (index > MaxVarSize) then
      exit;
    if not Wrap then begin
      Graph^.DrawText(pos.X, pos.Y, ch);
      Inc(index);
      Inc(pos.X, cw);
      continue;
    end;
    next := GetLineBreakIndex;
    while tw < next do begin
      Graph^.DrawText(pos.X, pos.Y, ch);
      Inc(index);
      Inc(pos.X, cw);
      ch := Caption[index];
    end;
    while (ch in WhiteSpaceChars) and (ch <> #0) do begin
      Inc(index);
      ch := Caption[index];
    end;
    pos.X := left;
    tw := 0;
    Inc(pos.Y);
  end;
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
  GetScreenBounds(rect);
  FreeAndNil(FBackBuffer);
  VeridianApp^.HideMouseCursor;
  size := longint(rect.Width) * rect.Height;
  FBackBuffer := New(PMemoryStream, Create(size));
  if VeridianApp^.CheckNilPtr(FBackBuffer) then
    exit;
  Graph^.GetImageStreamRect(rect, FBackBuffer);
  Visible := true;
  EndDrawing;
  Draw;
end;

procedure TPopUp.Hide;
var
  rect: TRect;
begin
  GetScreenBounds(rect);
  if not Assigned(FBackBuffer) then
    exit;
  BeginDrawing;
  VeridianApp^.HideMouseCursor;
  FBackBuffer^.Seek(0, soFromBeginning);
  Graph^.DrawImageStreamRect(rect, FBackBuffer);
  FreeAndNil(FBackBuffer);
  Visible := false;
  EndDrawing;
end;

destructor TPopUp.Free;
begin
  FreeAndNil(FBackBuffer);
  inherited Free;
end;

constructor TSpacing.CreateAll(ALeft, ATop, ARight, ABottom: integer);
begin
  inherited Create;
  Left := ALeft;
  Top := ATop;
  Right := ARight;
  Bottom := ABottom;
end;

constructor TSpacing.CreateValue(AValue: integer);
begin
  inherited Create;
  Left := AValue;
  Top := AValue;
  Right := AValue;
  Bottom := AValue;
end;

constructor TSpacing.CreateLeft(ALeft: integer);
begin
  inherited Create;
  Left := ALeft;
end;

constructor TSpacing.CreateTop(ATop: integer);
begin
  inherited Create;
  Top := ATop;
end;

constructor TSpacing.CreateRight(ARight: integer);
begin
  inherited Create;
  Right := ARight;
end;

constructor TSpacing.CreateBottom(ABottom: integer);
begin
  inherited Create;
  Bottom := ABottom;
end;

constructor TSpacing.CreateLeftRight(ALeft, ARight: integer);
begin
  inherited Create;
  Left := ALeft;
  Right := ARight;
end;

constructor TSpacing.CreateTopBottom(ATop, ABottom: integer);
begin
  inherited Create;
  Top := ATop;
  Bottom := ABottom;
end;

constructor TSpacing.CreateHorz(AValue: integer);
begin
  inherited Create;
  Left := AValue;
  Right := AValue;
end;

constructor TSpacing.CreateVert(AValue: integer);
begin
  inherited Create;
  Top := AValue;
  Bottom := AValue;
end;

function TSpacing.Width: integer;
begin
  Width := Left + Right;
end;

function TSpacing.Height: integer;
begin
  Height := Top + Bottom;
end;

procedure TSpacing.Init;
begin
  Left := 0;
  Top := 0;
  Right := 0;
  Bottom := 0;
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

procedure TFocusControl.Paint;
var
  oldForeColor, oldBackColor: byte;
begin
  if Focused then begin
    oldForeColor := ForeColor;
    oldBackColor := BackColor;
    ForeColor := FocusedColor;
    BackColor := FocusedBackColor;
    inherited Paint;
    ForeColor := oldForeColor;
    BackColor := oldBackColor;
  end
  else
    inherited Paint;
end;

procedure TFocusControl.GetCursorRect(var ARect: TRect);
begin
  ARect.Create;
end;

function TFocusControl.GetCursorForeColor: byte;
begin
  GetCursorForeColor := 0;
end;

function TFocusControl.GetCursorBackColor: byte;
begin
  GetCursorBackColor := 0;
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
  rect: TRect;
begin
  if not IsVisibleAndEnabled then
    exit;
  if Focused or not CanFocus then
    exit;
  GetScreenBounds(rect);
  event.Create;
  if AFocus then begin
    if Assigned(VeridianApp^.ActiveControl) then begin
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

constructor TFocusControl.CreateAction(AId: string; AAction: PAction; AParent: PControl);
begin
  inherited CreateAction(AId, AAction, AParent);
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
end;

function TFocusControl.CursorX: integer;
begin
  CursorX := FCursorX;
end;

function TFocusControl.CursorY: integer;
begin
  CursorY := FCursorY;
end;

procedure TFocusControl.SetXY(AXPos, AYPos: integer);
begin
  FCursorX := AXPos;
  FCursorY := AYPos;
  inherited SetXY(AXPos, AYPos);
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

begin
  Desktop := nil;

end.