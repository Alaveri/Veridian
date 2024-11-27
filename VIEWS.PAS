{$I COMPILER.INC}
unit Views;

interface

uses
  AplObj,
  AplTypes,
  Lists,
  Graphics,
  AplMath,
  Drawing,
  AplUtils,
  MouseDrv,
  Events,
  Controls;

const
  ScrollBarSize = 16;

type
  PView = ^TView;
  PWindow = ^TWindow;
  PScrollBar = ^TScrollBar;
  PTitleBar = ^TTitleBar;
  PScrollSlider = ^TScrollSlider;
  PScrollButton = ^TScrollButton;
  PVertScrollBar = ^TVertScrollBar;
  PHorzScrollBar = ^THorzScrollBar;
  PWindowGrip = ^TWindowGrip;

  TViewScrollType = (
    scNone,
    scVertical,
    scHorizontal,
    scBoth,
    scAsNeeded
  );

  TScrollOrientation =
  (
    soVertical,
    soHorizontal
  );

  TViewState =
  (
    vsNormal,
    vsMaximized,
    vsMinimized
  );

  TGripBorderType =
  (
    wpTopLeft,
    wpTopRight,
    wpBottomLeft,
    wpBottomRight,
    wbTop,
    wbBottom,
    wbLeft,
    wbRight
  );

  TScrollButtonType = (btInc, btDec);

  TTitleBar = object(TCaptionControl)
  private
  public
    ParentWindow: PWindow;
    ActiveForeColor: byte;
    ActiveBackColor: byte;
    constructor Create(const AId, ACaption: string; AParentWindow: PWindow);
    procedure Init; virtual;
    procedure Paint; virtual;
    procedure MouseDown(var AEvent: TMouseEvent); virtual;
    procedure DragStart(var AEvent: TDragEvent); virtual;
    procedure DragMove(var AEvent: TDragEvent); virtual;
    procedure DragEnd(var AEvent: TDragEvent); virtual;
  end;

  TWindowGrip = object(TLabel)
  private
    ParentWindow: PWindow;
  public
    constructor Create(const AId: string; AParentWindow: PWindow);
    procedure Init; virtual;
    procedure MouseDown(var AEvent: TMouseEvent); virtual;
    procedure DragStart(var AEvent: TDragEvent); virtual;
    procedure DragMove(var AEvent: TDragEvent); virtual;
    procedure DragEnd(var AEvent: TDragEvent); virtual;
  end;

  TScrollButton = object(TButton)
  private
    FType: TScrollButtonType;
  public
    constructor Create(const AId: string; AParent: PScrollBar; AType: TScrollButtonType);
    function ButtonType: TScrollButtonType;
    procedure Init; virtual;
    procedure MouseClick(var AEvent: TMouseEvent); virtual;
  end;

  TScrollSlider = object(TButton)
  private
  public
    procedure Init; virtual;
    procedure DragStart(var AEvent: TDragEvent); virtual;
    procedure DragMove(var AEvent: TDragEvent); virtual;
    procedure DragEnd(var AEvent: TDragEvent); virtual;
  end;

  TScrollBar = object(TPanel)
  private
    procedure DrawSlider;
    procedure ScrollBySlider(ADelta: integer);
    procedure ScrollByPixels(ADelta: integer);
  public
    Size: integer;
    IncButton: PButton;
    DecButton: PButton;
    Slider: PScrollSlider;
    UpdateScrollContents: boolean;
    Min: longint;
    Max: longint;
    Increment: longint;
    PageIncrement: longint;
    ScrollPosition: longint;
    OnPositionChanged: PScrollEventProc;
    constructor CreateParent(const AId: string; AParent: PControl);
    function Orientation: TScrollOrientation; virtual;
    procedure GetSliderRect(var ARect: TRect); virtual;
    procedure SetPosition(const APosition: longint);
    procedure Init; virtual;
    procedure Layout; virtual;
    procedure SetMinMaxPos(const AMin, AMax, APosition: longint);
    procedure SetIncrement(const AIncrement: longint);
    procedure SetPageIncrement(const AIncrement: longint);
    procedure MouseDown(var AEvent: TMouseEvent); virtual;
    procedure PositionChanged(var AEvent: TScrollEvent); virtual;
  end;

  THorzScrollBar = object(TScrollBar)
  private
  public
    function Orientation: TScrollOrientation; virtual;
    procedure GetSliderRect(var ARect: TRect); virtual;
    procedure Layout; virtual;
  end;

  TVertScrollBar = object(TScrollBar)
  private
  public
    function Orientation: TScrollOrientation; virtual;
    procedure GetSliderRect(var ARect: TRect); virtual;
    procedure Layout; virtual;
  end;

  TView = object(TPanel)
  private
    procedure GetContentRect(ABounds: TRect; AOX, AOY: integer; var ARect: TRect);
  public
    ScrollType: TViewScrollType;
    HorzScrollBar: PScrollBar;
    VertScrollBar: PScrollBar;
    AutoSize: boolean;
    ScrollX: longint;
    ScrollY: longint;
    ViewState: TViewState;
    function GetAutoWidth: longint; virtual;
    function GetAutoHeight: longint; virtual;
    procedure Init; virtual;
    procedure Maximize; virtual;
    procedure Layout; virtual;
    procedure GetContentScreenBounds(var ARect: TRect); virtual;
    procedure GetContentBounds(var ARect: TRect); virtual;
    procedure ScrollVert(ADelta: integer); virtual;
    procedure ScrollHorz(ADelta: integer); virtual;
    destructor Free; virtual;
  end;

  TWindow = object(TView)
  private
    FLastGripRect: TRect;
    FGripBorders: array[TGripBorderType] of PControl;
  public
    Title: PChar;
    TitleBar: PTitleBar;
    Grip: PLabel;
    OnClosing: PClosingEventProc;
    OnClosed: PEventProc;
    OnResizing: PSizeEventProc;
    OnResized: PSizeEventProc;
    OnMoving: PMoveEventProc;
    OnMoved: PMoveEventProc;
    constructor CreateTitle(const AId, ATitle: string; AParent: PControl);
    function TitleVisible: boolean;
    function Active: boolean;
    procedure GetContentScreenBounds(var ARect: TRect); virtual;
    procedure GetContentBounds(var ARect: TRect); virtual;
    procedure GetGripBounds(var ARect: TRect); virtual;
    procedure GetGripScreenBounds(var ARect: TRect); virtual;
    procedure SetTitle(const ATitle: string);
    procedure SetTitleVisible(AVisible: boolean);
    procedure Layout; virtual;
    procedure Activate;
    procedure Deactivate;
    procedure Close; virtual;
    procedure Init; virtual;
    procedure Paint; virtual;
    procedure MouseDown(var AEvent: TMouseEvent); virtual;
    procedure DragStart(var AEvent: TDragEvent); virtual;
    procedure DragMove(var AEvent: TDragEvent); virtual;
    procedure DragEnd(var AEvent: TDragEvent); virtual;
    destructor Free; virtual;
  end;

const
  GripCursors: array[TGripBorderType] of string =
  (
    'NWSE',
    'NESW',
    'NESW',
    'NWSE',
    'EW',
    'EW',
    'NS',
    'NS'
  );

implementation

uses
  Veridian,
  AplStr,
  Gr8Drv;

type
  PWindowGripBorder = ^TGripBorder;

  TGripBorder = object(TControl)
  private
  public
    ParentWindow: PWindow;
    BorderType: TGripBorderType;
    constructor Create(const AId: string; AParentWindow: PWindow;
      ABorderType: TGripBorderType);
    procedure Init; virtual;
    procedure DragStart(var AEvent: TDragEvent); virtual;
    procedure DragMove(var AEvent: TDragEvent); virtual;
    procedure DragEnd(var AEvent: TDragEvent); virtual;
    procedure MouseDown(var AEvent: TMouseEvent); virtual;
  end;

constructor TScrollButton.Create(const AId: string; AParent: PScrollBar; AType: TScrollButtonType);
begin
  inherited CreateParent(AId, AParent);
  FType := AType;
end;

function TScrollButton.ButtonType: TScrollButtonType;
begin
  ButtonType := FType;
end;

procedure TScrollButton.Init;
begin
  inherited Init;
  FType := btInc;
end;

procedure TScrollButton.MouseClick(var AEvent: TMouseEvent);
var
  scrollBar: PScrollBar;
begin
  scrollBar := PScrollBar(Parent);
  if FType = btDec then
    scrollBar^.ScrollByPixels(-scrollbar^.Increment)
  else
    scrollBar^.ScrollByPixels(scrollbar^.Increment);
  inherited MouseClick(AEvent);
end;

procedure TScrollSlider.Init;
begin
  inherited Init;
  Clickable := false;
end;

constructor TScrollBar.CreateParent(const AId: string; AParent: PControl);
begin
  inherited CreateParent(AId, AParent);
end;

procedure TScrollBar.Init;
begin
  inherited Init;
  Min := 0;
  Max := 0;
  OnPositionChanged := nil;
  ScrollPosition := 0;
  UpdateScrollContents := VeridianApp^.Settings.UpdateScrollContents;
  ForeColor := VeridianApp^.Colors.ScrollBar;
  BackColor := VeridianApp^.Colors.ScrollBarBack;
  FillPattern := @CheckerFillPattern;
  IncButton := New(PScrollButton, Create('IncButton', @self, btInc));
  with IncButton^ do begin
    HorzAlign := haCenter;
    VertAlign := vaCenter;
    CanFocus := false;
  end;
  DecButton := New(PScrollButton, Create('DecButton', @self, btDec));
  with DecButton^ do begin
    HorzAlign := haCenter;
    VertAlign := vaCenter;
    CanFocus := false;
  end;
  Slider := New(PScrollSlider, CreateParent('Slider', @self));
  with Slider^ do begin
    CanFocus := false;
    Clickable := false;
  end;
  Size := 17;
  Increment := 10;
  PageIncrement := 100;
  if Graph^.Mode^.Width <= 320 then
    Size := 11;
end;

procedure TScrollBar.GetSliderRect(var ARect: TRect);
begin
end;

procedure TScrollBar.Layout;
begin
end;

procedure TScrollBar.PositionChanged(var AEvent: TScrollEvent);
begin
end;

function TScrollBar.Orientation: TScrollOrientation;
begin
end;

procedure TScrollBar.SetMinMaxPos(const AMin, AMax, APosition: longint);
begin
  Min := AMin;
  Max := AMax;
  ScrollPosition := ClampL(APosition, Min, Max);
  Draw;
end;

procedure TScrollBar.SetIncrement(const AIncrement: longint);
begin
  Increment := AIncrement;
end;

procedure TScrollBar.SetPageIncrement(const AIncrement: longint);
begin
  PageIncrement := AIncrement;
end;

procedure TVertScrollBar.Layout;
var
  rect: TRect;
begin
  inherited Layout;
  DecButton^.SetBounds(0, 0, Size, Size);
  IncButton^.SetBounds(0, Height - Size, Size, Size);
  if not Assigned(IncButton^.Caption) then
    IncButton^.SetCaption(#31);
  if not Assigned(DecButton^.Caption) then
    DecButton^.SetCaption(#30);
  GetSliderRect(rect);
  Slider^.SetBoundsRect(rect);
end;

function TVertScrollBar.Orientation: TScrollOrientation;
begin
  Orientation := soVertical;
end;

procedure THorzScrollBar.Layout;
var
  rect: TRect;
begin
  inherited Layout;
  DecButton^.SetBounds(0, 0, Size, Size);
  IncButton^.SetBounds(Width - Size, 0, Size, Size);
  if not Assigned(IncButton^.Caption) then
    IncButton^.SetCaption(#16);
  if not Assigned(DecButton^.Caption) then
    DecButton^.SetCaption(#17);
  GetSliderRect(rect);
  Slider^.SetBoundsRect(rect);
end;

function THorzScrollBar.Orientation: TScrollOrientation;
begin
  Orientation := soHorizontal;
end;

procedure TVertScrollBar.GetSliderRect(var ARect: TRect);
var
  pos: longint;
  scrollSize, posOffset, sizeAdjust: integer;
begin
  sizeAdjust := 3 * Size + 2 * BorderWidth;
  posOffset := Size - Slider^.BorderWidth;
  scrollSize := Height - sizeAdjust;
  if Max = 0 then
    pos := posOffset
  else
    pos := Round((ScrollPosition / Max) * scrollSize) + posOffset;
  ARect.CreateDims(0, pos, Size, Size)
end;

procedure THorzScrollBar.GetSliderRect(var ARect: TRect);
var
  pos: longint;
  scrollSize, posOffset, sizeAdjust: integer;
begin
  sizeAdjust := 3 * Size + 2 * BorderWidth;
  posOffset := Size - Slider^.BorderWidth;
  scrollSize := Width - sizeAdjust;
  if Max = 0 then
    pos := posOffset
  else
    pos := Round((ScrollPosition / Max) * scrollSize) + posOffset;
  ARect.CreateDims(pos, 0, Size, Size)
end;

constructor TTitleBar.Create(const AId, ACaption: string; AParentWindow: PWindow);
begin
  inherited CreateCaption(AId, ACaption, AParentWindow);
  ParentWindow := AParentWindow;
end;

procedure TTitleBar.Init;
begin
  inherited Init;
  BorderColor := VeridianApp^.Colors.ButtonBorder;
  BorderStyle := bsNone;
  ForeColor := VeridianApp^.Colors.WindowTitle;
  BackColor := VeridianApp^.Colors.WindowTitleBack;
  ActiveForeColor := VeridianApp^.Colors.WindowTitleActive;
  ActiveBackColor := VeridianApp^.Colors.WindowTitleActiveBack;
  VertAlign := vaCenter;
  HorzAlign := haCenter;
  CanDrag := true;
  ParentWindow := nil;
  Font := Desktop^.Font;
end;

procedure TTitleBar.Paint;
var
  rect: TRect;
  fore, back: longint;
begin
  if not Assigned(ParentWindow) then
    exit;
  if not IsVisible then
    exit;
  fore := ForeColor;
  back := BackColor;
  if ParentWindow^.Active then begin
    ForeColor := ActiveForeColor;
    BackColor := ActiveBackColor;
  end;
  inherited Paint;
  ForeColor := fore;
  BackColor := back;
  GetScreenBounds(rect);
end;

procedure TTitleBar.MouseDown(var AEvent: TMouseEvent);
begin
  inherited MouseDown(AEvent);
  if AEvent.NewMouseState.ButtonState = [bsLeft] then begin
    if not ParentWindow^.Active then begin
      ParentWindow^.BringToFront;
      ParentWindow^.Activate;
    end;
  end;
end;

procedure TView.Init;
begin
  inherited Init;
  ForeColor := VeridianApp^.Colors.View;
  BackColor := VeridianApp^.Colors.ViewBack;
  BorderStyle := bsNone;
  Font := Desktop^.Font;
  HorzScrollBar := New(PHorzScrollBar, CreateParent('HorzScrollBar', @self));
  VertScrollBar := New(PVertScrollBar, CreateParent('VertScrollBar', @self));
  ScrollType := scNone;
  AutoSize := false;
  ScrollX := 0;
  ScrollY := 0;
end;

function TView.GetAutoWidth: longint;
begin
end;

function TView.GetAutoHeight: longint;
begin
end;

destructor TView.Free;
begin
  inherited Free;
end;

procedure TView.Maximize;
var
  viewRect: TRect;
begin
  ViewState := vsMaximized;
  SetBounds(0, 0, Desktop^.Width, Desktop^.Height);
  GetBounds(viewRect);
  if Assigned(VeridianApp^.MenuBar) and (VeridianApp^.MenuBar^.IsVisible) then begin
    viewRect.Translate(-BorderWidth, VeridianApp^.MenuBar^.Height - BorderWidth);
    viewRect.Grow(2 * BorderWidth, -VeridianApp^.MenuBar^.Height + 2 * BorderWidth);
  end;
  SetBoundsRect(viewRect);
  Draw;
end;

procedure TView.GetContentRect(ABounds: TRect; AOX, AOY: integer; var ARect: TRect);
var
  hs, vs: integer;
begin
  ARect.SetRect(ABounds);
  ARect.Translate(AOX, AOY);
  ARect.Grow(-AOX, -AOY);
  if ScrollType = scNone then
    exit;
  hs := HorzScrollBar^.Size + 1;
  vs := VertScrollBar^.Size + 1;
  case ScrollType of
    scVertical: Dec(ARect.Height, hs);
    scHorizontal: Dec(ARect.Width, vs);
    scBoth: begin
      Dec(ARect.Width, vs);
      Dec(ARect.Height, hs);
    end;
  end;
end;

procedure TView.GetContentScreenBounds(var ARect: TRect);
var
  rect: TRect;
begin
  GetScreenBounds(rect);
  GetContentRect(rect, 0, 0, ARect);
end;

procedure TView.GetContentBounds(var ARect: TRect);
var
  rect: TRect;
begin
  GetClientBounds(rect);
  GetContentRect(rect, 0, 0, ARect);
end;

procedure TView.Layout;
var
  rect: TRect;
  bw, bh, bbs: integer;
begin
  inherited Layout;
  GetClientBounds(rect);
  case ScrollType of
    scNone: begin
      VertScrollBar^.Visible := false;
      HorzScrollBar^.Visible := false;
    end;
    scVertical: begin
      VertScrollBar^.Visible := true;
      HorzScrollBar^.Visible := false;
    end;
    scHorizontal: begin
      VertScrollBar^.Visible := false;
      HorzScrollBar^.Visible := true;
    end;
    scBoth: begin
      VertScrollBar^.Visible := true;
      HorzScrollBar^.Visible := true;
    end;
    scAsNeeded: begin
    end;
  end;

  bw := VertScrollBar^.Size;
  bh := rect.Height;
  bbs := VertScrollBar^.BorderWidth;
  if HorzScrollBar^.Visible then
    Dec(bh, HorzScrollBar^.Size);
  VertScrollBar^.SetBounds(rect.Right - bw - bbs, rect.Y + 1, bw, bh - bbs - BorderWidth);
  bw := rect.Width;
  bh := HorzScrollBar^.Size;
  bbs := HorzScrollBar^.BorderWidth;
  if VertScrollBar^.Visible then
    Dec(bw, VertScrollBar^.Size);
  HorzScrollBar^.SetBounds(rect.X + 1, rect.Height - bh - bbs + 1, bw - bbs - BorderWidth, bh);
end;

constructor TWindow.CreateTitle(const AId, ATitle: string; AParent: PControl);
begin
  inherited CreateParent(AId, AParent);
  SetTitle(ATitle);
end;

constructor TWindowGrip.Create(const AId: string; AParentWindow: PWindow);
begin
  inherited CreateCaption(AId, #5, AParentWindow);
  ParentWindow := AParentWindow;
end;

procedure TWindowGrip.Init;
begin
  inherited Init;
  HorzAlign := haCenter;
  VertAlign := vaCenter;
  ForeColor := ShadowColor;
  BackColor := BackColor;
  AutoSize := false;
  Font := VeridianApp^.Fonts^.GetItemById('Symbol');
  CanDrag := true;
  MouseCursor := VeridianApp^.MouseCursors^.GetItemById('NWSE');
end;

procedure TWindowGrip.MouseDown(var AEvent: TMouseEvent);
begin
  if AEvent.Handled then
    exit;
  if not ParentWindow^.Active then begin
    ParentWindow^.BringToFront;
    ParentWindow^.Activate;
  end;
  AEvent.Handled := true;
  inherited MouseDown(AEvent);
end;

procedure TWindowGrip.DragStart(var AEvent: TDragEvent);
var
  rect: TRect;
begin
  if AEvent.Handled then
    exit;
  AEvent.Handled := true;
  ParentWindow^.GetScreenBounds(rect);
  desktop^.BeginDrawing;
  Graph^.InverseRectangle(rect);
  ParentWindow^.FLastGripRect := rect;
  desktop^.MouseCursor := VeridianApp^.MouseCursors^.GetItemById('NWSE');
  desktop^.EndDrawing;
end;

procedure TWindowGrip.DragMove(var AEvent: TDragEvent);
var
  rect: TRect;
  dx, dy: integer;
  minSize: integer;
  horzBar, vertBar: PScrollBar;
begin
  if AEvent.Handled then
    exit;
  ParentWindow^.GetScreenBounds(rect);
  dx := AEvent.X - AEvent.InitialX;
  dy := AEvent.Y - AEvent.InitialY;
  if (dx = 0) and (dy = 0) then
    exit;
  desktop^.BeginDrawing;
  Graph^.State^.ViewPort := Graph^.Mode^.Bounds;
  Graph^.InverseRectangle(ParentWindow^.FLastGripRect);
  rect.Grow(dx, dy);
  horzBar := ParentWindow^.HorzScrollBar;
  minSize :=
    4 * (horzBar^.Size + 2 * horzBar^.OuterWidth + 2 * horzBar^.SpacingWidth)
    + ParentWindow^.OuterWidth;
  if rect.Width < minSize then
    rect.Width := minSize;
  vertBar := ParentWindow^.VertScrollBar;
  minSize :=
    4 * (vertBar^.Size + 2 * vertBar^.OuterWidth  + 2 * vertBar^.SpacingWidth)
    + ParentWindow^.OuterWidth
    + ParentWindow^.TitleBar^.Height;
  if rect.Height < minSize then
    rect.Height := minSize;
  ParentWindow^.FLastGripRect := rect;
  Graph^.InverseRectangle(rect);
  desktop^.EndDrawing;
  AEvent.Handled := true;
end;

procedure TWindowGrip.DragEnd(var AEvent: TDragEvent);
var
  rect: TRect;
begin
  if AEvent.Handled then
    exit;
  desktop^.BeginDrawing;
  ParentWindow^.Hide;
  ParentWindow^.SetBoundsRect(ParentWindow^.FLastGripRect);
  ParentWindow^.Show;
  desktop^.MouseCursor := VeridianApp^.MouseCursors^.GetItemById('default');
  desktop^.EndDrawing;
  AEvent.Handled := true;
end;

procedure TTitleBar.DragStart(var AEvent: TDragEvent);
  var
  rect: TRect;
begin
  if AEvent.Handled then
    exit;
  AEvent.Handled := true;
  ParentWindow^.GetScreenBounds(rect);
  desktop^.BeginDrawing;
  Graph^.InverseRectangle(rect);
  ParentWindow^.FLastGripRect := rect;
  desktop^.EndDrawing;
end;

procedure TTitleBar.DragMove(var AEvent: TDragEvent);
var
  rect: TRect;
  dx, dy: integer;
  minSize: integer;
  horzBar, vertBar: PScrollBar;
begin
  if AEvent.Handled then
    exit;
  ParentWindow^.GetScreenBounds(rect);
  dx := AEvent.X - AEvent.InitialX;
  dy := AEvent.Y - AEvent.InitialY;
  if (dx = 0) and (dy = 0) then
    exit;
  if Assigned(VeridianApp^.MenuBar) and (VeridianApp^.MenuBar^.IsVisible) and
    (rect.Y + dy < Height) then
    dy := VeridianApp^.MenuBar^.Height - rect.Y;
  desktop^.BeginDrawing;
  Graph^.State^.ViewPort := Graph^.Mode^.Bounds;
  Graph^.InverseRectangle(ParentWindow^.FLastGripRect);
  rect.Translate(dx, dy);
  ParentWindow^.FLastGripRect := rect;
  Graph^.InverseRectangle(rect);
  desktop^.EndDrawing;
  AEvent.Handled := true;
end;

procedure TTitleBar.DragEnd(var AEvent: TDragEvent);
var
  rect: TRect;
begin
  if AEvent.Handled then
    exit;
  desktop^.BeginDrawing;
  ParentWindow^.Hide;
  ParentWindow^.SetBoundsRect(ParentWindow^.FLastGripRect);
  ParentWindow^.Show;
  desktop^.EndDrawing;
  AEvent.Handled := true;
end;

procedure TWindow.Init;
var
  gripBorderIndex: TGripBorderType;
begin
  inherited Init;
  BorderStyle := bsSingle;
  BevelStyle := bvRaised;
  BackColor := VeridianApp^.Colors.WindowBack;
  ForeColor := VeridianApp^.Colors.Window;
  BorderColor := VeridianApp^.Colors.WindowBorder;
  ShadowColor := VeridianApp^.Colors.WindowShadow;
  LightColor := VeridianApp^.Colors.WindowLight;
  CanDrag := true;
  FLastGripRect.Create;
  TitleBar := New(PTitleBar, Create('TitleBar', '', @self));
  Grip := New(PWindowGrip, Create('Grip', @self));
  for gripBorderIndex := Low(TGripBorderType) to High(TGripBorderType) do begin
    FGripBorders[gripBorderIndex] :=
      New(PWindowGripBorder, Create('', @self, gripBorderIndex));
  end;
  OnClosing := nil;
  OnClosed := nil;
  OnResizing := nil;
  OnResized := nil;
  OnMoving := nil;
  OnMoved := nil;
  Title := nil;
  ViewState := vsNormal;
end;

function TWindow.Active: boolean;
begin
  Active := VeridianApp^.ActiveWindow = @self;
end;

procedure TWindow.Paint;
var
  oldBorderColor: byte;
  oldBorderStyle: TBorderStyle;
  rect: TRect;
  pos: TPoint;
  size: TSize;
begin
  oldBorderColor := BorderColor;
  oldBorderStyle := BorderStyle;
  if ViewState = vsMaximized then begin
    BorderColor := VeridianApp^.Colors.WindowBorderActive;
    BorderStyle := bsSingle;
  end;
  inherited Paint;
  BorderColor := oldBorderColor;
  BorderStyle := oldBorderStyle;
end;

function TWindow.TitleVisible: boolean;
begin
  TitleVisible := TitleBar^.Visible;
end;

procedure TWindow.SetTitleVisible(AVisible: boolean);
begin
  TitleBar^.Visible := AVisible;
  Draw;
end;

procedure TWindow.Layout;
var
  rect: TRect;
  barWidth: integer;
  barHeight: integer;
  barBorderSize: integer;
  titleHeight: integer;
  index: TGripBorderType;
begin
  inherited Layout;
  GetGripBounds(rect);
  Grip^.SetBoundsRect(rect);
  GetClientBounds(rect);
  titleHeight := Font^.Height + 2 * TitleBar^.Margins.Height + 2 * BorderWidth;
  if not TitleBar^.Visible then
    titleHeight := 0
  else begin
    Inc(VertScrollBar^.Y, titleHeight);
    Dec(VertScrollBar^.Height, titleHeight);
  end;
  if not HorzScrollBar^.Visible then
    Dec(VertScrollBar^.Height, Grip^.Height);
  if not VertScrollBar^.Visible then
    Dec(HorzScrollBar^.Width, Grip^.Width);
  TitleBar^.SetBounds(rect.X, rect.Y, rect.Width, titleHeight);
  FGripBorders[wbTop]^.SetBounds(3, 0, Width - 6, 3);
  FGripBorders[wbBottom]^.SetBounds(3, Height - 3, Width - 6, 3);
  FGripBorders[wbLeft]^.SetBounds(0, 3, 3, Height - 6);
  FGripBorders[wbRight]^.SetBounds(Width - 3, 3, 3, Height - 6);
  FGripBorders[wpTopLeft]^.SetBounds(0, 0, 3, 3);
  FGripBorders[wpTopRight]^.SetBounds(Width - 3, 0, 3, 3);
  FGripBorders[wpBottomLeft]^.SetBounds(0, Height - 3, 3, 3);
  FGripBorders[wpBottomRight]^.SetBounds(Width - 3, Height - 3, 3, 3);
end;

procedure TWindow.Close;
var
  closingEvent: TClosingEvent;
  closedEvent: TEvent;
begin
  closingEvent.Create;
  Invoke(OnClosing, closingEvent);
  if not closingEvent.CanClose then
    exit;
  closedEvent.Create;
  Invoke(OnClosed, closedEvent);
end;

procedure TWindow.Activate;
var
  activeWindow: PWindow;
begin
  activeWindow := VeridianApp^.ActiveWindow;
  if Assigned(activeWindow) then begin
    VeridianApp^.ActiveWindow := nil;
    activeWindow^.TitleBar^.Draw;
  end;
  VeridianApp^.ActiveWindow := @self;
  BringToFront;
  VeridianApp^.ActiveWindow^.TitleBar^.Draw;
end;

procedure TWindow.SetTitle(const ATitle: string);
begin
  TString.AssignString(TitleBar^.Caption, ATitle);
  TitleBar^.Draw;
end;

procedure TWindow.Deactivate;
begin
  if VeridianApp^.ActiveWindow = @self then begin
    VeridianApp^.ActiveWindow := nil;
    Draw;
  end;
end;

procedure TWindow.GetGripBounds(var ARect: TRect);
var
  rect: TRect;
  barSize: integer;
begin
  GetClientBounds(rect);
  barSize := 16;
  if Graph^.Mode^.Width <= 320 then
    barSize := 10;
  ARect.CreateDims(rect.Right - barSize, rect.Bottom - barSize, barSize, barSize);
end;

procedure TWindow.GetGripScreenBounds(var ARect: TRect);
var
  rect: TRect;
  barSize: integer;
begin
  GetClientScreenBounds(rect);
  barSize := 16;
  if Graph^.Mode^.Width <= 320 then
    barSize := 10;
  ARect.CreateDims(rect.Right - barSize, rect.Bottom - barSize, barSize, barSize);
end;

procedure TWindow.GetContentScreenBounds(var ARect: TRect);
var
  rect: TRect;
  th: integer;
begin
  GetClientScreenBounds(rect);
  th := Font^.Height + 2 * TitleBar^.Margins.Height + BorderWidth;
  GetContentRect(rect, 0, th, ARect);
end;

procedure TWindow.GetContentBounds(var ARect: TRect);
var
  rect: TRect;
  th: integer;
begin
  GetClientBounds(rect);
  th := Font^.Height + 2 * TitleBar^.Margins.Height + BorderWidth;
  GetContentRect(rect, 0, th, ARect);
end;

procedure TWindow.MouseDown(var AEvent: TMouseEvent);
begin
  inherited MouseDown(AEvent);
  if AEvent.Handled or Active then
    exit;
  if AEvent.NewMouseState.ButtonState = [bsLeft] then begin
    BringToFront;
    Activate;
  end;
end;

procedure TWindow.DragStart(var AEvent: TDragEvent);
begin
  inherited DragStart(AEvent);
end;

procedure TWindow.DragMove(var AEvent: TDragEvent);
begin
  inherited DragMove(AEvent);
end;

procedure TWindow.DragEnd(var AEvent: TDragEvent);
begin
  inherited DragEnd(AEvent);
end;

destructor TWindow.Free;
begin
  TString.Free(Title);
  inherited Free;
end;

procedure TScrollSlider.DragStart(var AEvent: TDragEvent);
begin
end;

procedure TScrollSlider.DragEnd(var AEvent: TDragEvent);
var
  event: TScrollEvent;
  scrollBar: PScrollBar;
begin
  if Assigned(Parent) then begin
    scrollBar := PScrollBar(Parent);
    if scrollBar^.UpdateScrollContents then
      scrollBar^.SetPosition(scrollBar^.ScrollPosition);
    event.Create;
    event.Position := scrollBar^.ScrollPosition;
    Invoke(scrollBar^.OnPositionChanged, AEvent);
  end;
end;

procedure TScrollSlider.DragMove(var AEvent: TDragEvent);
var
  delta: integer;
  par: PScrollBar;
  rect: TRect;
begin
  par := PScrollBar(Parent);
  if par^.Max - par^.Min <= 0 then
    exit;
  GetScreenBounds(rect);
  if par^.Orientation = soHorizontal then
    delta := AEvent.X - rect.X - AEvent.InitialX
  else
    delta := AEvent.Y - rect.Y - AEvent.InitialY;
  par^.ScrollBySlider(delta);
end;

procedure TScrollBar.MouseDown(var AEvent: TMouseEvent);
var
  mouseCoord, sliderCoord: integer;
  parentView: PView;
  rect: TRect;
  newPos: longint;
begin
  inherited MouseDown(AEvent);
  if Orientation = soHorizontal then begin
    mouseCoord := AEvent.X;
    sliderCoord := Slider^.X;
  end
  else begin
    mouseCoord := AEvent.Y;
    sliderCoord := Slider^.Y;
  end;
  parentView := PView(Parent);
  if mouseCoord < sliderCoord then begin
    newPos := ScrollPosition - PageIncrement;
    newPos := ClampL(newPos, Min, Max);
    SetPosition(newPos);
  end
  else if mouseCoord > sliderCoord + Slider^.Height  then begin
    newPos := ScrollPosition + PageIncrement;
    newPos := ClampL(newPos, Min, Max);
    SetPosition(newPos);
  end;
end;

procedure TScrollBar.SetPosition(const APosition: longint);
var
  sizeAdjust: integer;
  scrollSize: integer;
  parentView: PView;
  rect: TRect;
  newCoord: integer;
begin
  if ScrollPosition = APosition then
    exit;
  parentView := PView(Parent);
  ScrollPosition := APosition;
  parentView^.ScrollY := APosition;
  parentView^.BeginDrawing;
  parentView^.GetContentScreenBounds(rect);
  parentView^.PaintRegion(rect, @self);
  parentView^.EndDrawing;

  sizeAdjust := 3 * Size - 3 * BorderWidth;
  if Orientation = soHorizontal then begin
    scrollSize := Width - sizeAdjust;
    newCoord := Round(ScrollPosition / Max * scrollSize) - 2 * BorderWidth + Size;
    Slider^.X := newCoord;
    DrawSlider;
  end
  else begin
    scrollSize := Height - sizeAdjust;
    newCoord := Round(ScrollPosition / Max * scrollSize) - 2 * BorderWidth + Size;
    Slider^.Y := newCoord;
    DrawSlider;
  end;
end;

procedure TScrollBar.DrawSlider;
var
  mouseRect,rect: TRect;
  value: integer;
begin
  GetScreenBounds(rect);
  BeginDrawing;
  Graph^.SetBackColor(BackColor);
  if Orientation = soHorizontal then begin
    value := slider^.X;
    rect.Height := Slider^.X - Size + 1;
    rect.Translate(Size - 1, BorderWidth);
    rect.Grow(0, -2 * BorderWidth);
    Graph^.FillRect(rect);
    GetScreenBounds(rect);
    rect.Translate(BorderWidth, value + Size);
    rect.Grow(0, -2 * BorderWidth);
    rect.Width := rect.Width - value - 2 * Size;
    Graph^.FillRect(rect);
  end
  else begin
    value := slider^.Y;
    GetScreenBounds(rect);
    rect.Height := Slider^.Y - Size + 1;
    rect.Translate(BorderWidth, Size - 1);
    rect.Grow(-2 * BorderWidth, 0);
    Graph^.FillRect(rect);
    GetScreenBounds(rect);
    rect.Translate(BorderWidth, value + Size);
    rect.Grow(-2 * BorderWidth, 0);
    rect.Height := rect.Height - value - 2 * Size;
    Graph^.FillRect(rect);
  end;
  Slider^.DrawSelf;
  EndDrawing;
end;

procedure TScrollBar.ScrollByPixels(ADelta: integer);
var
  pos: longint;
begin
  pos := ClampL(ScrollPosition + ADelta, Min, Max);
  SetPosition(pos);
end;

procedure TScrollBar.ScrollBySlider(ADelta: integer);
var
  scrollSize: integer;
  minCoord, maxCoord: integer;
  pos: integer;
begin
  minCoord := Size - 2 * BorderWidth;
  if Orientation = soHorizontal then begin
    maxCoord := Width - 2 * Size + BorderWidth;
    slider^.X := Clamp(slider^.X + ADelta, minCoord, maxCoord);
    scrollSize := Width - 3 * Size + 3 * BorderWidth;
    pos := Round(((slider^.X - Size + 2 * BorderWidth) / scrollSize) * Max);
  end
  else begin
    maxCoord := Height - 2 * Size + BorderWidth;
    slider^.Y := Clamp(slider^.Y + ADelta, minCoord, maxCoord);
    scrollSize := Height - 3 * Size + 3 * BorderWidth;
    pos := Round(((slider^.Y - Size + 2 * BorderWidth) / scrollSize) * Max);
  end;
  if VeridianApp^.Settings.UpdateScrollContents then
    SetPosition(pos)
  else begin
    ScrollPosition := pos;
    DrawSlider;
  end;
end;

procedure TView.ScrollVert(ADelta: integer);
begin
  VertScrollBar^.ScrollByPixels(ADelta);
end;

procedure TView.ScrollHorz(ADelta: integer);
begin
  HorzScrollBar^.ScrollByPixels(ADelta);
end;

constructor TGripBorder.Create(const AId: string; AParentWindow: PWindow;
  ABorderType: TGripBorderType);
begin
  inherited CreateParent(AId, AParentWindow);
  ParentWindow := AParentWindow;
  BorderType := ABorderType;
  MouseCursor := VeridianApp^.MouseCursors^.GetItemById(GripCursors[BorderType]);
end;

procedure TGripBorder.Init;
begin
  inherited Init;
  BorderType := wbTop;
  CanDrag := true;
end;

procedure TGripBorder.DragStart(var AEvent: TDragEvent);
var
  rect: TRect;
begin
  if AEvent.Handled then
    exit;
  AEvent.Handled := true;
  ParentWindow^.GetScreenBounds(rect);
  desktop^.BeginDrawing;
  Graph^.InverseRectangle(rect);
  ParentWindow^.FLastGripRect := rect;
  desktop^.MouseCursor := MouseCursor;
  desktop^.EndDrawing;
end;

procedure TGripBorder.DragMove(var AEvent: TDragEvent);
var
  rect, originalRect: TRect;
  dx, dy: integer;
  minSize: integer;
  horzBar, vertBar: PScrollBar;
begin
  if AEvent.Handled then
    exit;
  ParentWindow^.GetScreenBounds(rect);
  originalRect.CreateRect(rect);
  dx := AEvent.X - AEvent.InitialX;
  dy := AEvent.Y - AEvent.InitialY;
  if (dx = 0) and (dy = 0) then
    exit;
  desktop^.BeginDrawing;
  Graph^.State^.ViewPort := Graph^.Mode^.Bounds;
  Graph^.InverseRectangle(ParentWindow^.FLastGripRect);

  case BorderType of
    wbTop: begin
      rect.Translate(0, dy);
      rect.Grow(0, -dy);
    end;
    wbBottom: begin
      rect.Grow(0, dy);
    end;
    wbLeft: begin
      rect.Translate(dx, 0);
      rect.Grow(-dx, 0);
    end;
    wbRight: begin
      rect.Grow(dx, 0);
    end;
    wpTopLeft: begin
      rect.Translate(dx, dy);
      rect.Grow(-dx, -dy);
    end;
    wpTopRight: begin
      rect.Translate(0, dy);
      rect.Grow(dx, -dy);
    end;
    wpBottomLeft: begin
      rect.Translate(dx, 0);
      rect.Grow(-dx, dy);
    end;
    wpBottomRight: begin
      rect.Grow(dx, dy);
    end;
  end;
  horzBar := ParentWindow^.HorzScrollBar;
  minSize :=
    4 * (horzBar^.Size + 2 * horzBar^.OuterWidth + 2 * horzBar^.SpacingWidth)
    + ParentWindow^.OuterWidth;
  if rect.Width < minSize then begin
    rect.Width := minSize;
    if BorderType in [wbLeft, wpTopLeft, wpBottomLeft] then
      rect.X := originalRect.Right - minSize;
  end;
  vertBar := ParentWindow^.VertScrollBar;
  minSize :=
    4 * (vertBar^.Size + 2 * vertBar^.OuterWidth  + 2 * vertBar^.SpacingWidth)
    + ParentWindow^.OuterWidth
    + ParentWindow^.TitleBar^.Height;
  if rect.Height < minSize then begin
    rect.Height := minSize;
    if BorderType in [wbTop, wpTopLeft, wpTopRight] then
      rect.Y := originalRect.Bottom - minSize;
  end;
  ParentWindow^.FLastGripRect := rect;
  Graph^.InverseRectangle(rect);
  desktop^.EndDrawing;
  AEvent.Handled := true;
end;

procedure TGripBorder.DragEnd(var AEvent: TDragEvent);
var
  rect: TRect;
begin
  if AEvent.Handled then
    exit;
  desktop^.BeginDrawing;
  ParentWindow^.Hide;
  ParentWindow^.SetBoundsRect(ParentWindow^.FLastGripRect);
  ParentWindow^.Show;
  desktop^.MouseCursor := VeridianApp^.MouseCursors^.GetItemById('default');
  desktop^.EndDrawing;
  AEvent.Handled := true;
end;

procedure TGripBorder.MouseDown(var AEvent: TMouseEvent);
begin
  inherited MouseDown(AEvent);
  if AEvent.NewMouseState.ButtonState = [bsLeft] then begin
    if not ParentWindow^.Active then begin
      ParentWindow^.BringToFront;
      ParentWindow^.Activate;
    end;
  end;
end;

end.