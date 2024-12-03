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

  TControl = object(TMessageObject)
  private
    FOverrideViewPort: boolean;
    procedure InternalPaintRegion(ARegion: PRegion; AScreenRect: TRect; AExclude: PControl);
  public
    X, Y: integer;
    Width, Height: integer;
    Font: PFont;
    MouseCursor: PMouseCursor;
    Parent: PControl;
    Controls: PControlList;
    Position: TScreenPosition;
    Visible: boolean;
    FocusRectWidth: integer;
    ForeColor, BackColor: byte;
    FillPattern: PFillPattern;
    LinePattern: PLinePattern;
    Modal: boolean;
    Align: TAlign;
    Tag: integer;
    CanDrag: boolean;
    CanUndo: boolean;
    StayOnTop: boolean;
    Margins: TSpacing;
    Padding: TSpacing;
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
    ScrollX, ScrollY: integer;
    Clip: boolean;
    constructor Create(AId: string);
    constructor CreateParent(AId: string; AParent: PControl);
    destructor Free; virtual;
    procedure Init; virtual;
    function IsVisible: boolean;
    function IsActionControl: boolean; virtual;
    function IsFocusControl: boolean; virtual;
    function IsMouseOver: boolean;
    function IsView: boolean; virtual;
    function IsWindow: boolean; virtual;
    function IsContentControl: boolean; virtual;
    function BorderWidth: byte; virtual;
    function BevelWidth: byte; virtual;
    function OuterWidth: byte;
    function SpacingWidth: integer;
    function SpacingHeight: integer;
    function BringToFront: boolean;
    function SendToBack: boolean;
    function CreateControlList: PControlList; virtual;
    function GetSize: word;
    procedure SetVisible(AVisible: boolean);
    procedure SetForeColor(AForeColor: byte);
    procedure SetBackColor(ABackColor: byte);
    procedure Layout; virtual;
    procedure SetWidthHeight(AWidth, AHeight: word); virtual;
    procedure SetWidth(AWidth: word); virtual;
    procedure SetHeight(AHeight: word); virtual;
    procedure SetStayOnTop(AStayOnTop: boolean);
    procedure GetBounds(var ARect: TRect); virtual;
    procedure GetClientBounds(var ARect: TRect); virtual;
    procedure GetClientOuterBounds(var ARect: TRect);
    procedure GetAbsoluteBounds(var ARect: TRect); virtual;
    procedure GetScreenBounds(var ARect: TRect); virtual;
    procedure GetClipRect(var ARect: TRect); virtual;
    procedure DrawControl(ADrawControls: boolean); virtual;
    procedure AlignControl;
    procedure Draw;
    procedure DrawSelf;
    procedure DrawControls; virtual;
    procedure Hide; virtual;
    procedure Show; virtual;
    procedure Run; virtual;
    procedure BeginDrawing; virtual;
    procedure EndDrawing; virtual;
    procedure SetBounds(APX, APY: integer; AWidth, AHeight: integer) ;
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
    procedure MouseDoubleClick(var AEvent: TMouseEvent); virtual;
    procedure MouseWheelChanged(var AEvent: TMouseEvent); virtual;
    procedure DragStart(var AEvent: TDragEvent); virtual;
    procedure DragMove(var AEvent: TDragEvent); virtual;
    procedure DragEnd(var AEvent: TDragEvent); virtual;
    procedure InvokeSender(AEventProc: pointer; ASender: PObject; var AEvent: TEvent);
    procedure Invoke(AEventProc: pointer; var AEvent: TEvent);
  end;

  TPanel = object(TControl)
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
    procedure Paint; virtual;
  end;

  TDesktop = object(TPanel)
  private
  public
    ActionList: PActionList;
    procedure Init; virtual;
    procedure Layout; virtual;
    procedure GetContentBounds(var ARect: TRect); virtual;
    function CreateControlList: PControlList; virtual;
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
    function IsContentControl: boolean; virtual;
    procedure GetContentBounds(var ARect: TRect); virtual;
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
    procedure Paint; virtual;
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
  Controls := CreateControlList;
  X := 0;
  Y := 0;
  Width := 0;
  Height := 0;
  ScrollX := 0;
  ScrollY := 0;
  Clip := true;
  FocusRectWidth := 1;
  Visible := true;
  Align := alNone;
  Position := spContent;
  ForeColor := VeridianApp^.Colors.Window;
  BackColor := VeridianApp^.Colors.WindowBack;
  FillPattern := nil;
  LinePattern := nil;
  Modal := false;
  Margins.Create;
  Padding.Create;
  FOverrideViewPort := false;
  Tag := 0;
  CanDrag := false;
  CanUndo := false;
  StayOnTop := false;
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
  Font := Desktop^.Font;
  MouseCursor := VeridianApp^.MouseCursors^.GetItemById('Default');
end;

function TControl.CreateControlList: PControlList;
begin
  CreateControlList := New(PControlList, Create(@Self));
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
    Desktop^.BeginDrawing;
    VeridianApp^.CursorOff;
    Parent^.PaintRegion(rect, @self);
    Desktop^.EndDrawing;
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

function TControl.IsView: boolean;
begin
  IsView := false;
end;

function TControl.IsWindow: boolean;
begin
  IsWindow := false;
end;

function TControl.IsContentControl: boolean;
begin
  IsContentControl := false;
end;

procedure TControl.InvokeSender(AEventProc: pointer; ASender: PObject; var AEvent: TEvent);
begin
  AEvent.Sender := ASender;
  if Assigned(AEventProc) then
    TEventProc(AEventProc)(AEvent);
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
  Parent^.GetBounds(rect);
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
begin
  VeridianApp^.PushState;
  Mouse.PushState;
  Graph^.PushState;
  Layout;
  VeridianApp^.HideMouseCursor;
  Graph^.SetForeColor(ForeColor);
  Graph^.SetBackColor(BackColor);
  Graph^.State^.Font := Font;
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
  if StayOnTop then
    exit;
  GetAbsoluteBounds(rect);
  for index := 0 to Desktop^.Controls^.Count - 1 do begin
    item := Desktop^.Controls^.GetItem(index);
    if item = @self then
      continue;
    if not (item^.IsVisible and item^.StayOnTop) then
      continue;
    item^.GetAbsoluteBounds(desktopItemRect);
    if desktopItemRect.IntersectsRect(rect) then begin
      item^.Draw;
    end;
  end;
end;

procedure TControl.SetStayOnTop(AStayOnTop: boolean);
begin
  if StayOnTop = AStayOnTop then
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

procedure TControl.GetBounds(var ARect: TRect);
begin
  ARect.CreateDims(X, Y, Width, Height);
end;

procedure TControl.GetClientOuterBounds(var ARect: TRect);
begin
  { Client area without margins, padding, or borders. }
  GetBounds(ARect);
  ARect.TranslateToOrigin;
end;

procedure TControl.GetClientBounds(var ARect: TRect);
begin
  { Client area with margins, borders, and padding. }
  GetBounds(ARect);
  ARect.TranslateToOrigin;
  ARect.Translate(OuterWidth, OuterWidth);
  ARect.Grow(-2 * OuterWidth, -2 * OuterWidth);
  ARect.Translate(Margins.Left, Margins.Top);
  ARect.Grow(-Margins.Width, -Margins.Height);
end;

procedure TControl.GetAbsoluteBounds(var ARect: TRect);
var
  parentRect: TRect;
begin
  GetBounds(ARect);
  if not (Assigned(Parent) and (Position <> spAbsolute)) then
    exit;
  Parent^.GetAbsoluteBounds(parentRect);
  ARect.Translate(parentRect.X, parentRect.Y);
end;

procedure TControl.GetScreenBounds(var ARect: TRect);
var
  parentRect: TRect;
begin
  {Relative to desktop adjusted for Position value if
   parent is assigned.}
  case Position of
    spAbsolute: GetBounds(ARect);
    spContent: begin
      GetBounds(ARect);
      if not Assigned(Parent) then
        exit;
      if Parent^.IsContentControl then
        PContentControl(Parent)^.GetContentBounds(parentRect)
      else
        Parent^.GetClientBounds(parentRect);
      ARect.Translate(parentRect.X, parentRect.Y);
      Parent^.GetScreenBounds(parentRect);
      ARect.Translate(parentRect.X, parentRect.Y);
    end;
    spClient: begin
      GetBounds(ARect);
      if not Assigned(Parent) then
        exit;
      Parent^.GetClientBounds(parentRect);
      ARect.Translate(parentRect.X, parentRect.Y);
      Parent^.GetScreenBounds(parentRect);
      ARect.Translate(parentRect.X, parentRect.Y);
    end;
    spRelative: begin
      GetBounds(ARect);
      if not Assigned(Parent) then
        exit;
      Parent^.GetClientOuterBounds(parentRect);
      ARect.Translate(parentRect.X, parentRect.Y);
      Parent^.GetScreenBounds(parentRect);
      ARect.Translate(parentRect.X, parentRect.Y);
    end;
  end;
end;

procedure TControl.GetClipRect(var ARect: TRect);
var
  screenRect, parentRect: TRect;
  par: PControl;
begin
  GetScreenBounds(ARect);

  if not Assigned(Parent) then
    exit;
  case Position of
    spAbsolute: GetAbsoluteBounds(screenRect);
    spContent: begin
      if Parent^.IsContentControl and (Position = spContent) then begin
        PContentControl(Parent)^.GetContentBounds(parentRect);
      end
      else
        Parent^.GetClientBounds(parentRect);
    end;
    spClient: Parent^.GetClientBounds(parentRect);
    spRelative: parent^.GetClientOuterBounds(parentRect);
  end;
  Parent^.GetScreenBounds(screenRect);
  parentRect.Translate(screenRect.X, screenRect.Y);
  ARect.Intersect(parentRect);
  par := Parent;
  while Assigned(par) do begin
    par^.GetClipRect(parentRect);
    ARect.Intersect(parentRect);
    par := par^.Parent;
  end;
end;

procedure TControl.SetBounds(APX, APY: integer; AWidth, AHeight: integer);
var
  rect: TRect;
begin
  rect.CreateDims(APX, APY, AWidth, AHeight);
  SetBoundsRect(rect);
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
  if Clip and not FOverrideViewPort then
    GetClipRect(Graph^.State^.ViewPort);
  FOverrideViewPort := false;
end;

procedure TControl.InternalPaintRegion(ARegion: PRegion; AScreenRect: TRect; AExclude: PControl);
var
  index: integer;
  par, control: PControl;
  rect: TRect;
  controlRect: TRect;
  regionRect: PRect;
  ptr: pointer;
begin
  if AExclude = @self then
    exit;
  if not IsVisible then
    exit;
  GetScreenBounds(rect);
  if rect.IsEmpty then
    exit;
  VeridianApp^.PushState;
  VeridianApp^.CursorOff;
  rect.Intersect(AScreenRect);
  Graph^.PushState;
  FOverrideViewPort := true;
  Graph^.SetViewPort(rect);
  Paint;
  Graph^.PopState;

  VeridianApp^.PopState;
  for index := Controls^.Count - 1 downto 0 do begin
    control := Controls^.Items^[index];
    if control = AExclude then
      continue;
    if not control^.IsVisible then
      continue;

    control^.GetScreenBounds(controlRect);
    controlRect.Intersect(rect);
    if controlRect.IsEmpty then
      continue;
    control^.PaintRegion(controlRect, nil);
  end;
end;

procedure TControl.PaintRegion(const ARect: TRect; AExclude: PControl);
begin
  InternalPaintRegion(nil, ARect, AExclude);
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
  if StayOnTop then
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
    Width := ContentWidth + Padding.Width + OuterWidth;
    Height := ContentHeight + Padding.Height + OuterWidth;
  end;
end;

procedure TContentControl.GetAlign(const ABounds: TRect; const ASize: TSize;
  var AResult: TPoint);
begin
  AResult.Create;
  case HorzAlign of
    haLeft: AResult.X := ABounds.X + Padding.Left;
    haRight: AResult.X := ABounds.Right - ASize.Width - Padding.Right;
    haCenter: AResult.X := ABounds.X + Round(ABounds.Width - ASize.Width) div 2;
  end;
  case VertAlign of
    vaTop: AResult.Y := ABounds.Y + Padding.Top;
    vaBottom: AResult.Y := ABounds.Bottom - ASize.Height - Padding.Bottom;
    vaCenter: AResult.Y := ABounds.Y + (ABounds.Height - ASize.Height) div 2;
  end;
end;

procedure TContentControl.GetContentBounds(var ARect: TRect);
begin
  { If overridden by parent, gets the content bounds as defined
    by the parent, otherwise returns client area of parent. If no
    parent, returns the bounds of the desktop. }
  GetClientBounds(ARect);
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
    pos.X := rect.Right - TrueTextWidth(desc) - Margins.Right - OuterWidth;
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
      rect.Translate(1, 1);
      rect.Grow(-2, -2);
    end;
  end;
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

function TDesktop.CreateControlList: PControlList;
begin
  CreateControlList := New(PDesktopControlList, Create(@self));
end;

procedure TDesktop.Layout;
begin
  inherited Layout;
  SetBounds(0, 0, Graph^.Mode^.Width, Graph^.Mode^.Height);
end;

procedure TDesktop.GetContentBounds(var ARect: TRect);
begin
  GetBounds(ARect);
  if Assigned(VeridianApp^.MenuBar) then begin
    ARect.Translate(0, VeridianApp^.MenuBar^.Height);
    ARect.Grow(0, -VeridianApp^.MenuBar^.Height);
  end;
  if Assigned(VeridianApp^.TaskBar) then
    ARect.Grow(0, -VeridianApp^.TaskBar^.Height);
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
  size.CreateDims(TrueTextWidth(txt) - Font^.Spacing, Font^.Height);
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
  Graph^.State^.ViewPort := rect;
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
begin
  if not IsVisibleAndEnabled then
    exit;
  if Focused or not CanFocus then
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
  if byte(control1^.StayOnTop) > byte(control2^.StayOnTop) then
    CompareDesktopControls := 1
  else if byte(control1^.StayOnTop) < byte(control2^.StayOnTop) then
    CompareDesktopControls := -1
  else
    CompareDesktopControls := 0;
end;

constructor TDesktopControlList.Create(AOwner: PControl);
begin
  inherited CreateSorted(CompareDesktopControls);
  Owner := AOwner;
end;

begin
  Desktop := nil;

end.