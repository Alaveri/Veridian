{$I COMPILER.INC}
unit Views;

interface

uses
  AplObj,
  AplTypes,
  Lists,
  Graphics,
  GraphApp,
  AplMath,
  Drawing,
  AplUtils,
  MouseDrv,
  Events,
  VeriType,
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
  PWindowGrip = ^TWindowGrip;
  PTaskbar = ^TTaskbar;
  PTaskButton = ^TTaskButton;

  TViewScrollType = (
    scNone,
    scVertical,
    scHorizontal,
    scBoth,
    scAsNeeded
  );

  TWindowState =
  (
    wsNormal,
    wsMaximized,
    wsMinimized
  );

  TWindowOption = (
    woTitleBar,
    woCloseButton,
    woMaximizeButton,
    woMinimizeButton,
    woResizeable,
    woMoveable,
    woShowInTaskBar,
    woShowGrip
  );

  TGripBorderType =
  (
    gbNone,
    gbTopLeft,
    gbTopRight,
    gbBottomLeft,
    gbBottomRight,
    gbTop,
    gbBottom,
    gbLeft,
    gbRight
  );

  TWindowLocation = (
    wpDefault,
    wpDesktopCenter,
    wpScreenCenter,
    wpDesigned,
    wpParentCenter
  );

  TWindowOptions = set of TWindowOption;

  TScrollButtonType = (btInc, btDec);

  TGripRects = array[TGripBorderType] of TRect;

  TTitleBar = object(TCaptionControl)
  private
  public
    ParentWindow: PWindow;
    ActiveForeColor: byte;
    ActiveBackColor: byte;
    MinimizeButton: PButton;
    MaximizeButton: PButton;
    CloseButton: PButton;
    ButtonWidth, ButtonHeight: integer;
    constructor Create(const AId, ACaption: string; AParentWindow: PWindow);
    function CanDrag(var AEvent: TMouseEvent): boolean; virtual;
    procedure GetButtonArea(var ARect: TRect);
    procedure Init; virtual;
    procedure Layout; virtual;
    procedure Paint(ARect: TRect); virtual;
    procedure Draw; virtual;
    procedure MouseDown(var AEvent: TMouseEvent); virtual;
    procedure DragStart(var AEvent: TDragEvent); virtual;
    procedure DragMove(var AEvent: TDragEvent); virtual;
    procedure DragEnd(var AEvent: TDragEvent); virtual;
    procedure MouseDoubleClick(var AEvent: TMouseEvent); virtual;
  end;

  TWindowGrip = object(TLabel)
  private
    ParentWindow: PWindow;
  public
    constructor Create(const AId: string; AParentWindow: PWindow);
    function CanDrag(var AEvent: TMouseEvent): boolean; virtual;
    procedure Init; virtual;
    procedure Paint(ARect: TRect); virtual;
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
    procedure MouseDown(var AEvent: TMouseEvent); virtual;
  end;

  TScrollSlider = object(TButton)
  private
    FDownX, FDownY: integer;
  public
    procedure Init; virtual;
    procedure MouseDown(var AEvent: TMouseEvent); virtual;
    procedure MouseMove(var AEvent: TMouseEvent); virtual;
    procedure MouseUp(var AEvent: TMouseEvent); virtual;
  end;

  TScrollBar = object(TPanel)
  private
    FPosition: real;
    function CoordFromPos: integer;
    function PosFromCoord: real;
    function ScrollSize: integer;
    procedure DrawSlider;
    procedure ScrollBySlider(ADelta: integer);
    procedure ScrollByAmount(ADelta: integer);
    procedure SetRealPosition(const APosition: real);
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
    OnPositionChanged: PScrollEventProc;
    Orientation: TScrollOrientation;
    constructor CreateParent(const AId: string; AParent: PControl;
      AOrientation: TScrollOrientation);
    function ScrollPosition: longint;
    procedure GetSliderRect(var ARect: TRect); virtual;
    procedure SetScrollPosition(const APosition: longint);
    procedure Init; virtual;
    procedure Paint(ARect: TRect); virtual;
    procedure Draw; virtual;
    procedure Layout; virtual;
    procedure SetMinMaxPos(const AMin, AMax, APosition: longint);
    procedure SetIncrement(const AIncrement: longint);
    procedure SetPageIncrement(const AIncrement: longint);
    procedure MouseDown(var AEvent: TMouseEvent); virtual;
    procedure PositionChanged(var AEvent: TScrollEvent); virtual;
  end;

  TView = object(TFocusControl)
  private
  public
    ScrollType: TViewScrollType;
    HorzScrollBar: PScrollBar;
    VertScrollBar: PScrollBar;
    function GetAutoWidth: longint; virtual;
    function GetAutoHeight: longint; virtual;
    function IsView: boolean; virtual;
    function ContentWidth: integer; virtual;
    function ContentHeight: integer; virtual;
    function ContentOffsetX: integer; virtual;
    function ContentOffsetY: integer; virtual;
    function ScrollX: longint; virtual;
    function ScrollY: longint; virtual;
    procedure Init; virtual;
    procedure Layout; virtual;
    procedure Paint(ARect: TRect); virtual;
    procedure Draw; virtual;
    procedure DrawControls; virtual;
    procedure SetScrollBarBounds(AOrientation: TScrollOrientation); virtual;
    procedure ScrollVert(ADelta: integer); virtual;
    procedure ScrollHorz(ADelta: integer); virtual;
    procedure GetContentExtent(var ASize: TSize); virtual;
    procedure ScrollPositionChanged(var AEvent: TScrollEvent);
    procedure MouseWheelChanged(var AEvent: TMouseEvent); virtual;
    destructor Free; virtual;
  end;

  TWindow = object(TView)
  private
    FGripBorders: TGripRects;
    FInitialLayout: boolean;
    FDragBorder: TGripBorderType;
    procedure Move;
    procedure Resize;
    procedure HandleDragCursors(var AEvent: TMouseEvent);
    function GetGripBorder(const APoint: TPoint): TGripBorderType;
  public
    TitleBar: PTitleBar;
    TaskButton: PTaskButton;
    Grip: PLabel;
    WindowOptions: TWindowOptions;
    Closed: boolean;
    WindowState: TWindowState;
    OnCreate: PEvent;
    OnFree: PEvent;
    OnClosing: PClosingEventProc;
    OnClosed: PEventProc;
    OnResizing: PSizeEventProc;
    OnResized: PSizeEventProc;
    OnMoving: PMoveEventProc;
    OnMoved: PMoveEventProc;
    OnMaximized: PEventProc;
    OnMinimized: PEventProc;
    OnRestored: PEventProc;
    RestoredBounds: TRect;
    RestoredState: TWindowState;
    InitialLocation: TWindowLocation;
    constructor CreateBackground(const AId, ATitle: string; AParent: PControl);
    constructor Create(const AId, ATitle: string; AParent: PControl);
    destructor Free; virtual;
    function IsWindowType(const AType: string): boolean;
    function WindowType: string; virtual;
    function TitleVisible: boolean;
    function Active: boolean;
    function CanDrag(var AEvent: TMouseEvent): boolean; virtual;
    function MinWidth: integer; virtual;
    function MinHeight: integer; virtual;
    function IsWindow: boolean; virtual;
    function ContentY: integer; virtual;
    function GetTitleHeight: integer; virtual;
    function ContentHeight: integer; virtual;
    function Title: string;
    procedure SetScrollBarBounds(AOrientation: TScrollOrientation); virtual;
    procedure SetTitle(const ATitle: string);
    procedure SetTitleVisible(AVisible: boolean);
    procedure SetMinimizeVisible(AVisible: boolean);
    procedure SetMaximizeVisible(AVisible: boolean);
    procedure SetCloseVisible(AVisible: boolean);
    procedure GetMaximizedBounds(var ARect: TRect); virtual;
    procedure Initialized; virtual;
    procedure Layout; virtual;
    procedure Draw; virtual;
    procedure Activate;
    procedure Deactivate;
    procedure Show; virtual;
    procedure Close(ASender: PControl); virtual;
    procedure Maximize; virtual;
    procedure Minimize; virtual;
    procedure Restore; virtual;
    procedure Init; virtual;
    procedure Paint(ARect: TRect); virtual;
    procedure MouseDown(var AEvent: TMouseEvent); virtual;
    procedure MouseUp(var AEvent: TMouseEvent); virtual;
    procedure MouseEnter(var AEvent: TMouseEvent); virtual;
    procedure MouseLeave(var AEvent: TMouseEvent); virtual;
    procedure MouseMove(var AEvent: TMouseEvent); virtual;
    procedure DragStart(var AEvent: TDragEvent); virtual;
    procedure DragMove(var AEvent: TDragEvent); virtual;
    procedure DragEnd(var AEvent: TDragEvent); virtual;
    procedure Moved(var AEvent: TMoveEvent); virtual;
    procedure Moving(var AEvent: TMovingEvent); virtual;
    procedure Resized(var AEvent: TSizeEvent); virtual;
    procedure Resizing(var AEvent: TSizingEvent); virtual;
    procedure Maximized(var AEvent: TEvent); virtual;
    procedure Minimized(var AEvent: TEvent); virtual;
    procedure Restored(var AEvent: TEvent); virtual;
    procedure WindowCreate(var AEvent: TEvent); virtual;
    procedure WindowClosed(var AEvent: TEvent); virtual;
    procedure WindowClosing(var AEvent: TClosingEvent); virtual;
    procedure WindowFree(var AEvent: TEvent); virtual;
    procedure CreateSizingEvent(var AEvent: TSizingEvent); virtual;
    procedure CreateMovingEvent(var AEvent: TMovingEvent); virtual;
    procedure CreateMovedEvent(var AEvent: TMoveEvent); virtual;
    procedure CreateSizedEvent(var AEvent: TSizeEvent); virtual;
    procedure AddToTaskBar; virtual;
    procedure ClearControlStates(ASender: PControl); virtual;
    procedure CenterDesktop;
    procedure CenterScreen;
    procedure CenterParent;
  end;

  TWindowList = object(TIdentifiableList)
  private
  public
    procedure Init; virtual;
    function Add(AItem: PWindow): integer;
    function GetItem(AIndex: integer): PWindow;
    function GetItemById(const AId: string): PWindow;
    function IndexOf(AItem: PWindow): integer;
    procedure SetItem(AIndex: integer; AItem: PWindow);
    procedure Insert(AIndex: integer; AItem: PWindow);
    procedure RemoveItem(AItem: PWindow);
  end;

  TTaskButton = object(TButton)
  private
  public
    Window: PWindow;
    ParentTaskbar: PTaskbar;
    constructor Create(const AId: string; AParentTaskbar: PTaskbar; AWindow: PWindow);
    function GetCaption: string; virtual;
    function IsTaskbutton: boolean; virtual;
    procedure Init; virtual;
    procedure Paint(ARect: TRect); virtual;
    procedure MouseClick(var AEvent: TMouseEvent); virtual;
  end;

  TTaskbar = object(TContentControl)
  private
  public
    Windows: TWindowList;
    MaxButtonWidth: integer;
    constructor Create;
    destructor Free; virtual;
    procedure Init; virtual;
    procedure Layout; virtual;
    procedure AddWindow(AWindow: PWindow);
    procedure RemoveWindow(AWindow: PWindow);
    procedure SetWindow(AIndex: integer; AWindow: PWindow);
    procedure Paint(ARect: TRect); virtual;
    procedure RemoveButton(AWindow: PWindow);
    function NewButton(AWindow: PWindow): PTaskButton;
    function IndexOfWindow(AWindow: PWindow): integer;
    function GetWindow(AIndex: integer): PWindow;
    function GetWindowById(const AId: string): PWindow;
  end;

const
  GripCursors: array[TGripBorderType] of string =
  (
    '',
    'NWSE',
    'NESW',
    'NESW',
    'NWSE',
    'NS',
    'NS',
    'EW',
    'EW'
  );

implementation

uses
  Veridian,
  AplStr,
  VeriCons,
  Gr8Drv;

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

procedure TScrollButton.MouseDown(var AEvent: TMouseEvent);
var
  scrollBar: PScrollBar;
  control: PFocusControl;
begin
  if Assigned(Parent) then begin
    scrollBar := PScrollBar(Parent);
    if Assigned(scrollBar^.Parent) and scrollBar^.Parent^.IsFocusControl then begin
      control := PFocusControl(scrollBar^.Parent);
      if not control^.Focused then
        control^.Focus;
    end;
  end;
  inherited MouseDown(AEvent);
end;

procedure TScrollButton.MouseClick(var AEvent: TMouseEvent);
var
  scrollBar: PScrollBar;
begin
  scrollBar := PScrollBar(Parent);
  if FType = btDec then
    scrollBar^.ScrollByAmount(-scrollbar^.Increment)
  else
    scrollBar^.ScrollByAmount(scrollbar^.Increment);
  inherited MouseClick(AEvent);
end;

procedure TScrollSlider.Init;
begin
  inherited Init;
  Clickable := false;
  FDownX := 0;
  FDownY := 0;
end;

procedure TScrollSlider.MouseUp(var AEvent: TMouseEvent);
begin
end;

procedure TScrollSlider.MouseDown(var AEvent: TMouseEvent);
var
  scrollBar: PScrollBar;
  control: PFocusControl;
begin
  VeridianApp^.ScrollSlider := @self;
  if Assigned(Parent) then begin
    scrollBar := PScrollBar(Parent);
    if Assigned(scrollBar^.Parent) and scrollBar^.Parent^.IsFocusControl then begin
      control := PFocusControl(scrollBar^.Parent);
      if not control^.Focused then
        control^.Focus;
    end;
  end;
  FDownX := AEvent.X;
  FDownY := AEvent.Y;
end;

procedure TScrollSlider.MouseMove(var AEvent: TMouseEvent);
var
  delta: integer;
  par: PScrollBar;
  rect: TRect;
begin
  par := PScrollbar(Parent);
  if VeridianApp^.ScrollSlider <> @self then
    exit;
  if par^.Max - par^.Min <= 0 then
    exit;
  GetDrawRect(rect);
  if par^.Orientation = soHorizontal then
    delta := AEvent.NewMouseState.X - rect.X - FDownX
  else
    delta := AEvent.NewMouseState.Y - rect.Y - FDownY;
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
    SetScrollPosition(newPos);
  end
  else if mouseCoord > sliderCoord + Slider^.Height  then begin
    newPos := ScrollPosition + PageIncrement;
    newPos := ClampL(newPos, Min, Max);
    SetScrollPosition(newPos);
  end;
end;

constructor TScrollBar.CreateParent(const AId: string; AParent: PControl;
  AOrientation: TScrollOrientation);
var
  incChar, decChar: char;
begin
  inherited CreateParent(AId, AParent);
  Orientation := AOrientation;
  if Orientation = soHorizontal then begin
    incChar := #16;
    decChar := #17;
  end
  else begin
    incChar := #31;
    decChar := #30;
  end;
  IncButton^.SetCaption(incChar);
  DecButton^.SetCaption(decChar);
end;

procedure TScrollBar.Init;
begin
  inherited Init;
  Min := 0;
  Max := 0;
  Tag := 5;
  OnPositionChanged := nil;
  FPosition := 0;
  UpdateScrollContents := VeridianApp^.Settings.UpdateScrollContents;
  ForeColor := VeridianApp^.Colors.ScrollBar;
  BackColor := VeridianApp^.Colors.ScrollBarBack;
  FillPattern := @CheckerFillPattern;
  IncButton := New(PScrollButton, Create('IncButton', @self, btInc));
  with IncButton^ do begin
    HorzAlign := haCenter;
    VertAlign := vaCenter;
    CanFocus := false;
    Position := rpParentRelative;
  end;
  DecButton := New(PScrollButton, Create('DecButton', @self, btDec));
  with DecButton^ do begin
    HorzAlign := haCenter;
    VertAlign := vaCenter;
    CanFocus := false;
    Position := rpParentRelative;
  end;
  Slider := New(PScrollSlider, CreateParent('Slider', @self));
  with Slider^ do begin
    CanFocus := false;
    Clickable := false;
    Position := rpParentRelative;
  end;
  Size := 17;
  Increment := 10;
  PageIncrement := 100;
  if Graph^.Mode^.Width <= 320 then
    Size := 11;
  BorderStyle := bsNone;
  Position := rpParentRelative;
  Orientation := soVertical;
end;

procedure TScrollBar.Paint(ARect: TRect);
begin
  inherited Paint(ARect);
end;

procedure TScrollBar.PositionChanged(var AEvent: TScrollEvent);
var
  parentView: PView;
  screenRect, rect: TRect;
  pos: real;
begin
  parentView := PView(Parent);
  if not VeridianApp^.Settings.UpdateScrollContents then begin
    pos := PosFromCoord;
    SetRealPosition(pos);
  end;
  Invoke(OnPositionChanged, AEvent);
end;

procedure TView.MouseWheelChanged(var AEvent: TMouseEvent);
var
  amount: integer;
begin
  inherited MouseWheelChanged(AEvent);
  if not VertScrollBar^.Visible then
    exit;
  amount := VertScrollBar^.Increment * AEvent.NewMouseState.WheelCounter;
  if AEvent.NewMouseState.WheelCounter > 0 then
    ScrollVert(amount)
  else if AEvent.NewMouseState.WheelCounter < 0 then
    ScrollVert(amount);
  AEvent.Handled := true;
end;

procedure TScrollBar.SetMinMaxPos(const AMin, AMax, APosition: longint);
begin
  Min := AMin;
  Max := AMax;
  FPosition := ClampL(APosition, Min, Max);
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

procedure TScrollBar.Layout;
var
  rect: TRect;
begin
  inherited Layout;
  DecButton^.SetBounds(0, 0, Size, Size);
  GetClientRect(rect);
  if Orientation = soHorizontal then begin
    IncButton^.SetBounds(rect.Right - Size + 1, 0, Size, Size);
  end
  else begin
    IncButton^.SetBounds(0, rect.Bottom - Size + 1, Size, Size);
  end;
  GetSliderRect(rect);
  Slider^.SetBoundsRect(rect);
end;

procedure TScrollBar.GetSliderRect(var ARect: TRect);
var
  pos: real;
begin
  if Max = 0 then
    pos := 0
  else
    pos := CoordFromPos;
  if Orientation = soVertical then
    ARect.CreateDims(0, Round(pos), Size, Size)
  else
    ARect.CreateDims(Round(pos), 0, Size, Size)
end;

constructor TTitleBar.Create(const AId, ACaption: string; AParentWindow: PWindow);
begin
  inherited CreateCaption(AId, ACaption, AParentWindow);
  ParentWindow := AParentWindow;
end;

procedure CloseButtonClick(var AEvent: TMouseEvent);
var
  window: PWindow;
  parent: PTitleBar;
  button: PButton;
begin
  if AEvent.Handled then
    exit;
  button := PButton(AEvent.Sender);
  parent := PTitleBar(button^.Parent);
  window := PWindow(parent^.ParentWindow);
  window^.Close(button);
  if Assigned(window^.TaskButton) and Assigned(VeridianApp^.TaskBar) then begin
    VeridianApp^.TaskBar^.RemoveWindow(window);
    VeridianApp^.TaskBar^.Draw;
  end;
  if VeridianApp^.ActiveWindow = window then
    VeridianApp^.ActiveWindow := nil;
  AEvent.Handled := true;
end;

procedure MinimizeButtonClick(var AEvent: TMouseEvent);
var
  window: PWindow;
  parent: PTitleBar;
  button: PButton;
begin
  if AEvent.Handled then
    exit;
  button := PButton(AEvent.Sender);
  parent := PTitleBar(button^.Parent);
  window := PWindow(parent^.ParentWindow);
  if not window^.Active then begin
    window^.BringToFront;
    window^.Activate;
  end;
  if Assigned(window) then
    window^.Minimize;
  AEvent.Handled := true;
end;

procedure MaximizeButtonClick(var AEvent: TMouseEvent);
var
  window: PWindow;
  parent: PTitleBar;
  button: PButton;
begin
  if AEvent.Handled then
    exit;
  button := PButton(AEvent.Sender);
  parent := PTitleBar(button^.Parent);
  window := PWindow(parent^.ParentWindow);
  if not window^.Active then begin
    window^.BringToFront;
    window^.Activate;
  end;
  if Assigned(window) then
    window^.Maximize;
  AEvent.Handled := true;
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
  HorzAlign := haLeft;
  ButtonWidth := 16;
  ButtonHeight := 16;
  Padding.CreateAll(4, 0, 0, 0);
  if Graph^.Mode^.Width < 512 then begin
    ButtonWidth := 9;
    ButtonHeight := 9;
    Padding.CreateAll(1, 0, 0, 0);
  end;
  ParentWindow := nil;
  Font := Desktop^.Font;
  MinimizeButton := New(PButton, CreateCaption('MinButton', #6, @self));
  with MinimizeButton^ do begin
    Font := VeridianApp^.Fonts^.GetItemById('Symbol');
    SetCaption(#6);
    HorzAlign := haCenter;
    VertAlign := vaCenter;
    AutoSize := false;
    CanFocus := false;
    Position := rpParentClient;
    OnMouseClick := @MinimizeButtonClick;
  end;
  MaximizeButton := New(PButton, CreateCaption('MaxButton', #7, @self));
  with MaximizeButton^ do begin
    Font := VeridianApp^.Fonts^.GetItemById('Symbol');
    SetCaption(#7);
    HorzAlign := haCenter;
    VertAlign := vaCenter;
    AutoSize := false;
    CanFocus := false;
    Position := rpParentClient;
    OnMouseClick := @MaximizeButtonClick;
  end;
  CloseButton := New(PButton, CreateCaption('CloseButton', #8, @self));
  with CloseButton^ do begin
    Font := VeridianApp^.Fonts^.GetItemById('Symbol');
    SetCaption(#8);
    HorzAlign := haCenter;
    VertAlign := vaCenter;
    AutoSize := false;
    CanFocus := false;
    Position := rpParentClient;
    OnMouseClick := @CloseButtonClick;
  end;
  Position := rpParentClient;
end;

function TTitleBar.CanDrag(var AEvent: TMouseEvent): boolean;
begin
  CanDrag := true;
end;

procedure TTitleBar.Layout;
var
  xPos: integer;
  totalWidth: integer;
  pos: TPoint;
  size: TSize;
  rect: TRect;
begin
  inherited Layout;
  Width := Parent^.Width - Parent^.OuterWidth * 2;
  xPos := Width - Parent^.OuterWidth - 1;
  totalWidth := 0;
  size.CreateDims(ButtonWidth, ButtonHeight);
  rect.CreateDims(0, 0, Width, Height);
  GetAlign(rect, size, pos);
  if CloseButton^.IsVisible then  begin
    Dec(xPos, buttonWidth);
    CloseButton^.SetBounds(
      xPos,
      pos.Y,
      buttonWidth,
      buttonHeight
    );
    Inc(totalWidth, CloseButton^.Width);
  end;
  if MaximizeButton^.IsVisible then begin
    Dec(xPos, buttonWidth + 1);
    MaximizeButton^.SetBounds(
      xPos,
      pos.Y,
      buttonWidth,
      buttonHeight
    );
    Inc(totalWidth, CloseButton^.Width + 1);
  end;
  if MinimizeButton^.IsVisible then begin
    Dec(xPos, buttonWidth + 1);
    MinimizeButton^.SetBounds(
      xPos,
      pos.Y,
      buttonWidth,
      buttonHeight
    );
    Inc(totalWidth, MinimizeButton^.Width + 1);
  end;
end;

procedure TTitleBar.GetButtonArea(var ARect: TRect);
var
  rect: TRect;
  totalWidth: integer;
begin
  totalWidth := 4;
  GetBounds(ARect);
  if MinimizeButton^.IsVisible then
    Inc(totalWidth, MinimizeButton^.Width + 1);
  if MaximizeButton^.IsVisible then
    Inc(totalWidth, MaximizeButton^.Width + 1);
  if CloseButton^.IsVisible then
    Inc(totalWidth, CloseButton^.Width + 1);
  ARect.X := ARect.Right - totalWidth;
  ARect.Width := totalWidth;
end;

procedure TTitleBar.Draw;
begin
  inherited Draw;
end;

procedure TTitleBar.Paint(ARect: TRect);
var
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
  inherited Paint(ARect);
  ForeColor := fore;
  BackColor := back;
end;

procedure TTitleBar.MouseDown(var AEvent: TMouseEvent);
begin
  inherited MouseDown(AEvent);
  if AEvent.Handled then
    exit;
  if not IsVisibleAndEnabled then
    exit;
  if AEvent.NewMouseState.ButtonState = [bsLeft] then begin
    if not ParentWindow^.Active then begin
      ParentWindow^.BringToFront;
      ParentWindow^.Activate;
    end;
  end;
end;

procedure TTitleBar.MouseDoubleClick(var AEvent: TMouseEvent);
begin
  if AEvent.Handled then
    exit;
  if not IsVisibleAndEnabled then
    exit;
  if AEvent.OldMouseState.ButtonState = [bsLeft] then begin
    if ParentWindow^.WindowState = wsMaximized then
      ParentWindow^.Restore
    else
      ParentWindow^.Maximize;
    AEvent.Handled := true;
  end;
end;

procedure TView.Init;
begin
  inherited Init;
  ForeColor := VeridianApp^.Colors.View;
  BackColor := VeridianApp^.Colors.ViewBack;
  FocusedColor := VeridianApp^.Colors.View;
  FocusedBackColor := VeridianApp^.Colors.ViewBack;
  BorderStyle := bsNone;
  Font := VeridianApp^.GetFont('system');
  CanFocus := true;
  HorzScrollBar := New(PScrollBar, CreateParent('HorzScrollBar', @self, soHorizontal));
  VertScrollBar := New(PScrollBar, CreateParent('VertScrollBar', @self, soVertical));
  ScrollType := scNone;
  AutoSize := false;
end;

function TView.ContentOffsetX: integer;
begin
  ContentOffsetX := -ScrollX;
end;

function TView.ContentOffsetY: integer;
begin
  ContentOffsetY := -ScrollY;
end;

function TView.ScrollX: longint;
begin
  ScrollX := Round(HorzScrollBar^.FPosition);
end;

function TView.ScrollY: longint;
begin
  ScrollY := Round(VertScrollBar^.FPosition);
end;

procedure TView.GetContentExtent(var ASize: TSize);
var
  index: integer;
  control: PControl;
begin
  ASize.CreateDims(0, 0);
  for index := 0 to Controls^.Count - 1 do begin
    control := Controls^.GetItem(index);
    if not (control^.IsVisible and (control^.Position = rpParentContent)) then
      continue;
    if control^.X + control^.Width - 1 > ASize.Width then
      ASize.Width := control^.X + control^.Width - 1;
    if control^.Y + control^.Height - 1 > ASize.Height then
      ASize.Height := control^.Y + control^.Height - 1;
  end;
end;

function TView.IsView: boolean;
begin
  IsView := true;
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

procedure TView.ScrollPositionChanged(var AEvent: TScrollEvent);
begin
end;

procedure TView.SetScrollBarBounds(AOrientation: TScrollOrientation);
var
  barSize: integer;
  bounds: TRect;
begin
  bounds.CreateDims(0, 0, Width, Height);
  if AOrientation = soVertical then begin
    barSize := VertScrollBar^.Size;
    VertScrollBar^.SetBounds(
      bounds.Right - BarSize - OuterWidth + 1,
      bounds.Y + OuterWidth,
      BarSize,
      bounds.Height - OuterWidth - 1
    );
    if HorzScrollBar^.IsVisible then
      Dec(VertScrollBar^.Height, BarSize + OuterWidth - 1)
  end
  else if AOrientation = soHorizontal then begin
    barSize := HorzScrollBar^.Size;
    HorzScrollBar^.SetBounds(
      bounds.X + OuterWidth,
      bounds.Bottom - BarSize - OuterWidth + 1,
      bounds.Width - OuterWidth - 1,
      BarSize
    );
    if VertScrollBar^.IsVisible then
      Dec(HorzScrollBar^.Width, BarSize + OuterWidth - 1);
  end;
end;

function TView.ContentWidth: integer;
var
  rect: TRect;
  result: integer;
begin
  result := inherited ContentWidth;
  if VertScrollBar^.IsVisible then
    Dec(result, VertScrollBar^.Width - 1);
  ContentWidth := result;
end;

function TView.ContentHeight: integer;
var
  rect: TRect;
  result: integer;
begin
  result := inherited ContentHeight;
  if HorzScrollBar^.IsVisible then
    Dec(result, HorzScrollBar^.Height);
  ContentHeight := result;
end;

procedure TView.Draw;
begin
  inherited Draw;
end;

procedure TView.DrawControls;
var
  index: integer;
  control: PControl;
begin
  BeginDrawing;
  for index := 0 to Controls^.Count - 1 do begin
    control := Controls^.GetItem(index);
    control^.Draw;
  end;
  EndDrawing;
end;

procedure TView.Layout;
var
  extent: TSize;
begin
  inherited Layout;
  VertScrollBar^.BringToFront;
  HorzScrollBar^.BringToFront;
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
      GetContentExtent(extent);
      HorzScrollBar^.Max := extent.Width + Padding.Width
        - ContentWidth +  HorzScrollBar^.Size + 1;
      VertScrollBar^.Max := extent.Height + Padding.Height
        - ContentHeight + VertScrollBar^.Size + 1;
      HorzScrollBar^.FPosition := ClampR(HorzScrollBar^.FPosition, 0,
        HorzScrollBar^.Max);
      VertScrollBar^.FPosition := ClampR(VertScrollBar^.FPosition, 0,
        VertScrollBar^.Max);

      VertScrollBar^.Visible := extent.Height > ContentHeight - Padding.Height;
      HorzScrollBar^.Visible := extent.Width > ContentWidth - Padding.Width;

      if not VertScrollbar^.Visible then
        VertScrollBar^.FPosition := 0;
      if not HorzScrollbar^.Visible then
        HorzScrollBar^.FPosition := 0;
    end;
  end;
  SetScrollBarBounds(soVertical);
  SetScrollBarBounds(soHorizontal);
  VertScrollBar^.Increment := Font^.Height + 6;
  VertScrollBar^.PageIncrement := ContentHeight - VertScrollBar^.Increment;
  HorzScrollBar^.Increment := VertScrollBar^.Increment;
  HorzScrollBar^.PageIncrement := ContentWidth - HorzScrollBar^.Increment;
end;

procedure TView.Paint(ARect: TRect);
begin
  TPanel.Paint(ARect);
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
  MouseCursor := VeridianApp^.MouseCursors^.GetItemById('NWSE');
  Position := rpParentClient;
end;

function TWindowGrip.CanDrag(var AEvent: TMouseEvent): boolean;
begin
  CanDrag := true;
end;

procedure TWindowGrip.Paint(ARect: TRect);
begin
  inherited Paint(ARect);
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
  if not (woResizeable in PWindow(Parent)^.WindowOptions) then
    exit;
  ParentWindow^.GetDrawRect(rect);
  desktop^.BeginDrawing;
  VeridianApp^.DragRect := rect;
  desktop^.MouseCursor := VeridianApp^.MouseCursors^.GetItemById('NWSE');
  desktop^.EndDrawing;
end;

procedure TWindowGrip.DragMove(var AEvent: TDragEvent);
var
  rect: TRect;
  dx, dy: integer;
  minSize: integer;
begin
  if AEvent.Handled then
    exit;
  ParentWindow^.GetDrawRect(rect);
  dx := AEvent.X - AEvent.InitialX;
  dy := AEvent.Y - AEvent.InitialY;
  if (dx = 0) and (dy = 0) then
    exit;
  rect.Grow(dx, dy);
  minSize := ParentWindow^.MinWidth;
  if rect.Width < minSize then
    rect.Width := minSize;
  minSize := ParentWindow^.MinHeight;
  if rect.Height < minSize then
    rect.Height := minSize;
  VeridianApp^.DragRect := rect;
  AEvent.Handled := true;
end;

procedure TWindow.CreateSizingEvent(var AEvent: TSizingEvent);
begin
  AEvent.Create;
  CreateSizedEvent(AEvent);
end;

procedure TWindow.CreateSizedEvent(var AEvent: TSizeEvent);
begin
  AEvent.Create;
  AEvent.OldSize.CreateDims(VeridianApp^.DragInitialSize.Width,
    VeridianApp^.DragInitialSize.Height);
  AEvent.NewSize.CreateDims(VeridianApp^.DragRect.Width,
    VeridianApp^.DragRect.Height);
end;

procedure TWindow.CreateMovingEvent(var AEvent: TMovingEvent);
begin
  AEvent.Create;
  CreateMovedEvent(AEvent);
end;

procedure TWindow.CreateMovedEvent(var AEvent: TMoveEvent);
begin
  AEvent.Create;
  AEvent.OldPosition.CreateCoords(VeridianApp^.DragInitialPos.X,
    VeridianApp^.DragInitialPos.Y);
  AEvent.NewPosition.CreateCoords(VeridianApp^.DragRect.X,
    VeridianApp^.DragRect.Y);
end;

procedure TWindow.Resize;
var
  rect: TRect;
begin
  GetDrawRect(rect);
  Graph^.PushState;
  Graph^.SetDrawPage(Graph^.OffScreenPage);
  SetBoundsRect(VeridianApp^.DragRect);
  Show;
  Graph^.CopyFromOffScreen(VeridianApp^.DragRect, VeridianApp^.DragRect);
  Graph^.PopState;
  HideEx(rect, VeridianApp^.DragRect);
  Visible := true;
end;

procedure TWindow.Move;
var
  taskRect, source, dest: TRect;
begin
  GetDrawRect(source);
  dest.CreateRect(VeridianApp^.DragRect);
  Graph^.InverseRectangle(dest);
  source.Width := dest.Width;
  source.Height := dest.Height;
  BeginDrawing;
  Graph^.PushState;
  Graph^.SetDrawPage(Graph^.OffScreenPage);
  if Assigned(VeridianApp^.TaskBar) then begin
    VeridianApp^.TaskBar^.GetDrawRect(taskRect);
    if taskRect.IntersectsRect(source) then
      VeridianApp^.TaskBar^.Hide;
  end;
  Graph^.CopyToOffScreen(source, dest);
  Graph^.CopyFromOffScreen(dest, dest);
  if Assigned(VeridianApp^.TaskBar) then
    VeridianApp^.TaskBar^.Draw;
  Graph^.PopState;
  GetDrawRect(source);
  HideEx(source, dest);
  EndDrawing;
  SetBoundsRect(dest);
  Visible := true;
end;

procedure TWindowGrip.DragEnd(var AEvent: TDragEvent);
var
  sizingEvent: TSizingEvent;
  sizedEvent: TSizeEvent;
begin
  if AEvent.Handled then
    exit;
  ParentWindow^.CreateSizingEvent(sizingEvent);
  ParentWindow^.CreateSizedEvent(sizedEvent);
  ParentWindow^.Resizing(sizingEvent);
  desktop^.BeginDrawing;
  if sizingEvent.CanResize then
    ParentWindow^.Resize;
  desktop^.MouseCursor := VeridianApp^.MouseCursors^.GetItemById('default');
  desktop^.EndDrawing;
  AEvent.Handled := true;
  if sizingEvent.CanResize then
    ParentWindow^.Resized(sizedEvent);
end;

procedure TTitleBar.DragStart(var AEvent: TDragEvent);
  var
  rect: TRect;
begin
  if AEvent.Handled then
    exit;
  AEvent.Handled := true;
  if not (woMoveable in PWindow(Parent)^.WindowOptions) then
    exit;
  ParentWindow^.GetDrawRect(rect);
  if ParentWindow^.WindowState = wsMaximized then begin
    rect.Width := ParentWindow^.RestoredBounds.Width;
    rect.Height := ParentWindow^.RestoredBounds.Height;
    rect.X := AEvent.X - (rect.Width div 2);
    rect.Width := ParentWindow^.RestoredBounds.Width;
    rect.Height := ParentWindow^.RestoredBounds.Height;
    ParentWindow^.WindowState := wsNormal;
    TString.Assign(MaximizeButton^.Caption, #7);
  end;
  desktop^.BeginDrawing;
  VeridianApp^.DragRect := rect;
  desktop^.EndDrawing;
end;

procedure TTitleBar.DragMove(var AEvent: TDragEvent);
var
  rect: TRect;
  dx, dy: integer;
begin
  if not (woMoveable in PWindow(Parent)^.WindowOptions) then
    exit;
  if AEvent.Handled then
    exit;
  ParentWindow^.GetDrawRect(rect);
  rect.Width := VeridianApp^.DragRect.Width;
  rect.Height := VeridianApp^.DragRect.Height;
  dx := AEvent.X - AEvent.InitialX;
  dy := AEvent.Y - AEvent.InitialY;
  if (dx = 0) and (dy = 0) then
    exit;
  if Assigned(VeridianApp^.MenuBar) and (VeridianApp^.MenuBar^.IsVisible) and
    (rect.Y + dy - ParentWindow^.OuterWidth < Height) then
    dy := VeridianApp^.MenuBar^.Height - rect.Y;
  rect.Translate(dx, dy);
  VeridianApp^.DragRect := rect;
  AEvent.Handled := true;
end;

procedure TTitleBar.DragEnd(var AEvent: TDragEvent);
var
  rect: TRect;
  movedEvent: TMoveEvent;
  movingEvent: TMovingEvent;
begin
  if AEvent.Handled then
    exit;
  ParentWindow^.GetDrawRect(rect);
  if rect.Equals(VeridianApp^.DragRect) then
    exit;
  ParentWindow^.CreateMovingEvent(movingEvent);
  ParentWindow^.CreateMovedEvent(movedEvent);
  if movingEvent.CanMove then begin
    ParentWindow^.Resize;
    ParentWindow^.Visible := true;
    ParentWindow^.Moved(movedEvent);
  end;
  AEvent.Handled := true;
end;

procedure TWindow.Initialized;
begin
  AddToTaskBar;
end;

procedure TWindow.Init;
var
  gripBorderIndex: TGripBorderType;
begin
  inherited Init;
  VeridianApp^.PushState;
  VeridianApp^.State.DrawEnabled := false;
  Closed := false;
  BorderStyle := bsSingle;
  BevelStyle := bvRaised;
  BackColor := VeridianApp^.Colors.WindowBack;
  ForeColor := VeridianApp^.Colors.Window;
  BorderColor := VeridianApp^.Colors.WindowBorder;
  ShadowColor := VeridianApp^.Colors.WindowShadow;
  LightColor := VeridianApp^.Colors.WindowLight;
  RestoredBounds.Create;
  RestoredState := wsNormal;
  CanFocus := false;
  Position := rpParentClient;
  WindowOptions := [Low(TWindowOption)..High(TWindowOption)];
  TitleBar := New(PTitleBar, Create('TitleBar', '', @self));
  TitleBar^.Visible := woTitleBar in WindowOptions;
  TitleBar^.Position := rpParentRelative;
  Grip := New(PWindowGrip, Create('Grip', @self));
  Grip^.TransparentBack := true;
  Grip^.Visible := woResizeable in WindowOptions;
  Grip^.VertAlign := vaCenter;
  Grip^.HorzAlign := haCenter;
  Grip^.Position := rpParentRelative;
  for gripBorderIndex := Low(TGripBorderType) to High(TGripBorderType) do begin
    FGripBorders[gripBorderIndex].Create;
  end;
  OnClosing := nil;
  OnClosed := nil;
  OnResizing := nil;
  OnResized := nil;
  OnMoving := nil;
  OnMoved := nil;
  OnMaximized := nil;
  OnMinimized := nil;
  OnRestored := nil;
  OnFree := nil;
  OnCreate := nil;
  WindowState := wsNormal;
  TaskButton := nil;
  ScrollType := scAsNeeded;
  InitialLocation := wpScreenCenter;
  FInitialLayout := true;
  FDragBorder := gbNone;
  VeridianApp^.PopState;
end;

function TWindow.CanDrag(var AEvent: TMouseEvent): boolean;
begin
  CanDrag := FDragBorder <> gbNone;
end;

function TWindow.WindowType: string;
begin
  WindowType := 'Window';
end;

function TWindow.IsWindowType(const AType: string): boolean;
begin
  IsWindowType := LowerCase(AType) = LowerCase(WindowType);
end;

procedure TWindow.CenterDesktop;
var
  rect: TRect;
begin
  Desktop^.GetDrawRect(rect);
  X := (Desktop^.Width - rect.Width) div 2;
  Y := (Desktop^.Height - rect.Height) div 2;
end;

procedure TWindow.CenterParent;
var
  parentRect, rect: TRect;
begin
  if not Assigned(Parent) then
    exit;
  X := (Parent^.Width - Width) div 2;
  Y := (Parent^.Height - Height) div 2;
end;

procedure TWindow.CenterScreen;
begin
  X := (Graph^.Mode^.Width - Width) div 2;
  Y := (Graph^.Mode^.Height - Height) div 2;
end;

destructor TWindow.Free;
var
  event: TEvent;
begin
  event.Create;
  WindowFree(event);
  inherited Free;
end;

procedure TWindow.GetMaximizedBounds(var ARect: TRect);
begin
  ARect.CreateDims(0, 0, Desktop^.Width, Desktop^.Height);
  if Assigned(VeridianApp^.MenuBar) and (VeridianApp^.MenuBar^.IsVisible) then begin
    ARect.Translate(-BorderWidth, VeridianApp^.MenuBar^.Height - BorderWidth);
    ARect.Grow(2 * BorderWidth, -VeridianApp^.MenuBar^.Height + 2 * BorderWidth);
  end;
  if Assigned(VeridianApp^.TaskBar) and (VeridianApp^.TaskBar^.IsVisible) then
    ARect.Grow(0, -VeridianApp^.TaskBar^.Height + OuterWidth);
end;

procedure TWindow.Maximize;
var
  maxRect: TRect;
  rect: TRect;
  sizingEvent: TSizingEvent;
  sizedEvent: TSizeEvent;
  movedEvent: TMoveEvent;
  movingEvent: TMovingEvent;
  maximizedEvent: TEvent;
begin
  if not (woResizeable in WindowOptions) then
    exit;
  sizingEvent.Create;
  movingEvent.Create;
  GetMaximizedBounds(maxRect);
  GetBounds(rect);
  sizedEvent.OldSize.CreateDims(Width, Height);
  sizingEvent.OldSize.CreateDims(Width, Height);
  movedEvent.OldPosition.CreateCoords(X, Y);
  movingEvent.OldPosition.CreateCoords(X, Y);
  maximizedEvent.Create;
  if WindowState = wsMaximized then begin
    sizingEvent.NewSize.CreateDims(rect.Width, rect.Height);
    sizedEvent.NewSize.CreateSize(sizingEvent.NewSize);
    Resizing(sizingEvent);
    if not sizingEvent.CanResize then
      exit;
    movingEvent.NewPosition.CreateCoords(rect.X, rect.Y);
    movedEvent.NewPosition.CreatePoint(movingEvent.NewPosition);
    Moving(movingEvent);
    if not movingEvent.CanMove then
      exit;
    WindowState := wsNormal;
    Hide;
    SetBoundsRect(RestoredBounds);
    RestoredState := wsNormal;
    TitleBar^.MaximizeButton^.SetCaption(#7);
    Show;
    Resized(sizedEvent);
    exit;
  end;
  GetBounds(rect);
  sizingEvent.NewSize.CreateDims(MaxRect.Width, maxRect.Height);
  sizedEvent.NewSize.CreateSize(sizingEvent.NewSize);
  TitleBar^.MaximizeButton^.SetCaption(#9);
  Resizing(sizingEvent);
  if not sizingEvent.CanResize then
    exit;
  Moving(movingEvent);
  if not movingEvent.CanMove then
    exit;
  RestoredBounds := rect;
  RestoredState := WindowState;
  WindowState := wsMaximized;
  Hide;
  SetBoundsRect(maxRect);
  Show;
  Resized(sizedEvent);
  Moved(movedEvent);
  Maximized(maximizedEvent);
end;

procedure TWindow.Restore;
var
  sizingEvent: TSizingEvent;
  sizedEvent: TSizeEvent;
  movedEvent: TMoveEvent;
  movingEvent: TMovingEvent;
  restoredEvent: TEvent;
begin
  case WindowState of
    wsNormal: exit;
    wsMaximized: begin
      restoredEvent.Create;
      sizedEvent.OldSize.CreateDims(Width, Height);
      sizingEvent.OldSize.CreateDims(Width, Height);
      movedEvent.OldPosition.CreateCoords(X, Y);
      movingEvent.OldPosition.CreateCoords(X, Y);
      sizingEvent.NewSize.CreateDims(RestoredBounds.Width, RestoredBounds.Height);
      movingEvent.NewPosition.CreateCoords(RestoredBounds.X, RestoredBounds.Y);
      Resizing(sizingEvent);
      if not sizingEvent.CanResize then
        exit;
      Moving(movingEvent);
      if not movingEvent.CanMove then
        exit;
      Hide;
      WindowState := wsNormal;
      RestoredState := wsNormal;
      SetBoundsRect(RestoredBounds);
      TitleBar^.MaximizeButton^.SetCaption(#7);
      Activate;
      Show;
      Resized(sizedEvent);
      Moved(movedEvent);
      Restored(restoredEvent);
    end;
    wsMinimized: begin
      WindowState := RestoredState;
      Activate;
      Show;
    end;
  end;
end;

procedure TWindow.SetMaximizeVisible(AVisible: boolean);
begin
  if not Assigned(TitleBar) then
    exit;
  TitleBar^.Draw;
end;

procedure TWindow.SetMinimizeVisible(AVisible: boolean);
begin
  if not Assigned(TitleBar) then
    exit;
  TitleBar^.Draw;
end;

procedure TWindow.SetCloseVisible(AVisible: boolean);
begin
  if not Assigned(TitleBar) then
    exit;
  TitleBar^.CloseButton^.Visible := AVisible;
  TitleBar^.Draw;
end;

procedure TWindow.AddToTaskBar;
begin
  if not (woShowInTaskBar in WindowOptions)  then
    exit;
  if not Assigned(VeridianApp^.TaskBar) then
    exit;
  VeridianApp^.TaskBar^.AddWindow(@self);
end;

function TWindow.Active: boolean;
begin
  Active := VeridianApp^.ActiveWindow = @self;
end;

function TWindow.IsWindow: boolean;
begin
  IsWindow := true;
end;

constructor TWindow.Create(const AId, ATitle: string; AParent: PControl);
var
  event: TEvent;
begin
  inherited CreateParent(AId, AParent);
  event.Create;
  TString.AssignString(TitleBar^.Caption, ATitle);
  Initialized;
  WindowCreate(event);
end;

constructor TWindow.CreateBackground(const AId, ATitle: string; AParent: PControl);
var
 event: TEvent;
begin
  inherited CreateParent(AId, AParent);
  Exclude(WindowOptions, woShowInTaskBar);
  TString.AssignString(TitleBar^.Caption, ATitle);
  event.Create;
  Initialized;
  WindowCreate(event);
end;

function TWindow.MinWidth: integer;
var
  minW: integer;
  minTW: integer;
  buttonSize: integer;
  rect: TRect;
begin
  buttonSize := HorzScrollBar^.Size
    + 2 * HorzScrollBar^.OuterWidth
    + 2 * HorzScrollBar^.SpacingWidth;
  minW := 4 * buttonSize + OuterWidth;
  if VertScrollBar^.Visible and not HorzScrollBar^.Visible then
    Inc(minW, VertScrollBar^.Size + 2 * VertScrollBar^.OuterWidth);
  TitleBar^.GetButtonArea(rect);
  minTW := 2 * OuterWidth + rect.Width;
  MinWidth := Max(minW, minTW);
end;

function TWindow.MinHeight: integer;
var
  minH: integer;
  buttonSize: integer;
begin
  buttonSize := VertScrollBar^.Size
    + 2 * VertScrollBar^.OuterWidth
    + 2 * VertScrollBar^.SpacingWidth;
  if not VertScrollBar^.Visible then
    buttonSize := 0;
  minH := 4 * buttonSize + OuterWidth;
  if TitleBar^.Visible then
    Inc(minH, TitleBar^.Height + 2 * TitleBar^.OuterWidth + OuterWidth);
  if HorzScrollBar^.Visible and not VertScrollBar^.Visible then
    Inc(minH, HorzScrollBar^.Size + 2 * HorzScrollBar^.OuterWidth + OuterWidth - 1);
  if VertScrollBar^.Visible then
    Dec(minH, OuterWidth);
  MinHeight := minH;
end;

function TWindow.Title: string;
begin
  Title := TitleBar^.GetCaption;
end;

procedure TWindow.SetTitle(const ATitle: string);
begin
  TitleBar^.SetCaption(ATitle);
  if Assigned(VeridianApp^.TaskBar) then begin
    TString.AssignString(TaskButton^.Caption, ATitle);
    VeridianApp^.TaskBar^.Layout;
    TaskButton^.Draw;
  end;
end;

procedure TWindow.Draw;
var
  rect: TRect;
begin
  if FInitialLayout then begin
    FInitialLayout := false;
    case InitialLocation of
      wpScreenCenter: CenterScreen;
      wpDefault: begin
        X := VeridianApp^.DefaultWindowX;
        Y := VeridianApp^.DefaultWindowY;
      end;
      wpDesktopCenter: CenterDesktop;
      wpParentCenter: CenterParent;
    end;
  end;
  Graph^.PushState;
  inherited Draw;
  Graph^.PopState;
end;


procedure TWindow.Paint(ARect: TRect);
var
  oldBorderColor: byte;
  oldBorderStyle: TBorderStyle;
  rect: TRect;
  pos: TPoint;
  size: TSize;
begin
  oldBorderColor := BorderColor;
  oldBorderStyle := BorderStyle;
  if WindowState = wsMaximized then begin
    BorderColor := VeridianApp^.Colors.WindowBorderActive;
    BorderStyle := bsSingle;
  end;
  inherited Paint(ARect);
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
  barWidth: integer;
  barHeight: integer;
  barSize, barBorderSize: integer;
  titleHeight: integer;
  index: TGripBorderType;
  extent: TSize;
  rect: TRect;
begin
  inherited Layout;
  titleHeight := GetTitleHeight;
  TitleBar^.SetBounds(OuterWidth, OuterWidth, Width - 2 * OuterWidth, titleHeight);
  barSize := VertScrollBar^.Size;
  TitleBar^.Visible := woTitleBar in WindowOptions;
  GetClientRect(rect);
  Grip^.Autosize := false;
  Grip^.SetBounds(
    rect.Right - barSize + 1,
    rect.Bottom - barSize + 2,
    barSize - 1,
    barSize - 1);

  FGripBorders[gbTop].SetDims(0, 0, Width - 4, 2);
  FGripBorders[gbBottom].SetDims(0, Height - 2, Width - 4, 2);
  FGripBorders[gbLeft].SetDims(0, 0, 2, Height - 6);
  FGripBorders[gbRight].SetDims(Width - 2, 0, 2, Height - 4);
  FGripBorders[gbTopLeft].SetDims(0, 0, 2, 2);
  FGripBorders[gbTopRight].SetDims(Width - 2, 0, 2, 2);
  FGripBorders[gbBottomLeft].SetDims(0, Height - 2, 2, 2);
  FGripBorders[gbBottomRight].SetDims(Width - 2, Height - 2, 2, 2);
  TitleBar^.BringToFront;
  if WindowState <> wsMaximized then
    GetBounds(RestoredBounds);

  Grip^.BringToFront;
end;

procedure TWindow.ClearControlStates(ASender: PControl);
begin
  if VeridianApp^.ActiveWindow = @self then
    VeridianApp^.ActiveWindow := nil;
  if VeridianApp^.DragControl = ASender then
    VeridianApp^.DragControl := nil;
  if VeridianApp^.MouseOverControl = ASender then
    VeridianApp^.MouseOverControl := nil;
  if VeridianApp^.DoubleClickControl = ASender then
    VeridianApp^.DoubleClickControl := nil;
  if VeridianApp^.LeftMouseDownControl = ASender then
    VeridianApp^.LeftMouseDownControl := nil;
  if VeridianApp^.RightMouseDownControl = ASender then
    VeridianApp^.RightMouseDownControl := nil;
  if PControl(VeridianApp^.SelectingControl) = ASender then
    VeridianApp^.SelectingControl := nil;
  if PControl(VeridianApp^.ActiveControl) = ASender then
    VeridianApp^.ActiveControl := nil;
end;

procedure TWindow.Close(ASender: PControl);
var
  closingEvent: TClosingEvent;
  closedEvent: TEvent;
begin
  closingEvent.Create;
  WindowClosing(closingEvent);
  if not closingEvent.CanClose then
    exit;
  Hide;
  closedEvent.Create;
  WindowClosed(closedEvent);
  Closed := true;
end;

procedure TWindow.Moved(var AEvent: TMoveEvent);
begin
  Invoke(OnMoved, AEvent);
end;

procedure TWindow.Moving(var AEvent: TMovingEvent);
begin
  Invoke(OnMoving, AEvent);
end;

procedure TWindow.Resized(var AEvent: TSizeEvent);
begin
  Invoke(OnResized, AEvent);
end;

procedure TWindow.Resizing(var AEvent: TSizingEvent);
begin
  Invoke(OnResizing, AEvent);
end;

procedure TWindow.WindowClosing(var AEvent: TClosingEvent);
begin
  Invoke(OnClosing, AEvent);
end;

procedure TWindow.WindowClosed(var AEvent: TEvent);
begin
  Invoke(OnClosed, AEvent);
end;

procedure TWindow.WindowCreate(var AEvent: TEvent);
begin
  Invoke(OnCreate, AEvent);
end;

procedure TWindow.WindowFree(var AEvent: TEvent);
begin
  Invoke(OnFree, AEvent);
end;

procedure TWindow.Minimize;
var
  event: TEvent;
begin
  if WindowState = wsMinimized then
    exit;
  RestoredState := WindowState;
  WindowState := wsMinimized;
  VeridianApp^.ActiveWindow := nil;
  if VeridianApp^.State.CursorOn
    and Assigned(VeridianApp^.ActiveControl)
    and (VeridianApp^.ActiveControl^.IsFocusControl)
    and ContainsControl(VeridianApp^.ActiveControl) then begin
    PFocusControl(VeridianApp^.ActiveControl)^.UnFocus;
  end;
  Hide;
  if Assigned(TaskButton) then begin
    TaskButton^.Down := false;
    TaskButton^.DrawSelf;
  end;
  event.Create;
  Minimized(event);
end;

procedure TWindow.Maximized(var AEvent: TEvent);
begin
  Invoke(OnMaximized, AEvent);
end;

procedure TWindow.Minimized(var AEvent: TEvent);
begin
  Invoke(OnMinimized, AEvent);
end;

procedure TWindow.Restored(var AEvent: TEvent);
begin
  Invoke(OnRestored, AEvent);
end;

procedure TWindow.Activate;
var
  activeWindow: PWindow;
  rect: TRect;
begin
  activeWindow := VeridianApp^.ActiveWindow;
  if VeridianApp^.ActiveWindow = @self then
    exit;
  if Assigned(VeridianApp^.ActiveControl) then
    VeridianApp^.ActiveControl^.UnFocus;
  if Assigned(activeWindow) then
    activeWindow^.Deactivate;
  VeridianApp^.ActiveWindow := @self;

  if BringToFront then begin
    BeginDrawing;
    GetDrawRect(rect);
    Graph^.SetViewPort(rect);
    rect.Intersect(Graph^.Mode^.Bounds);
    Graph^.SetDrawPage(Graph^.OffScreenPage);
    Draw;
    Graph^.SetDrawPage(0);
    Graph^.CopyFromOffScreen(rect, rect);
    EndDrawing;
  end
  else if Assigned(TitleBar) then
    TitleBar^.Draw;
  if Assigned(TaskButton) then begin
    TaskButton^.Down := true;
    TaskButton^.DrawSelf;
  end;
end;

procedure TWindow.Deactivate;
var
  activeWindow: PWindow;
begin
  activeWindow := VeridianApp^.ActiveWindow;
  if activeWindow <> @self then
    exit;
  if Assigned(TaskButton) then begin
    TaskButton^.Down := false;
    TaskButton^.DrawSelf;
  end;
  VeridianApp^.ActiveWindow := nil;
  TitleBar^.Draw;
end;

function TWindow.GetTitleHeight: integer;
var
  result: integer;
  min: integer;
begin
  GetTitleHeight := 0;
  if not TitleBar^.IsVisible then
    exit;
  result := Font^.Height + 2 * TitleBar^.Margins.Height
    + TitleBar^.Padding.Height;
  min := 16;
  if Graph^.Mode^.Width < 512 then
    min := 9;
  result := Max(result, min);
  GetTitleHeight := result;
end;

function TWindow.ContentY: integer;
var
  result: integer;
begin
  result := inherited ContentY;
  if TitleBar^.IsVisible then
    Inc(result, TitleBar^.Height);
  ContentY := result;
end;

function TWindow.ContentHeight: integer;
var
  result: integer;
begin
  result := inherited ContentHeight;
  if TitleBar^.IsVisible then
    Dec(result, GetTitleHeight);
  ContentHeight := result;
end;

procedure TWindow.Show;
var
  rect: TRect;
begin
  Visible := true;
  Layout;
  Visible := false;
  inherited Show;
end;

procedure TWindow.SetScrollBarBounds(AOrientation: TScrollOrientation);
begin
  inherited SetScrollBarBounds(AOrientation);
  Grip^.Visible := [woShowGrip, woResizeable] * WindowOptions = [woShowGrip, woResizeable];
  if AOrientation = soVertical then begin
    if Grip^.Visible and not HorzScrollBar^.Visible then
      Dec(VertScrollBar^.Height, HorzScrollBar^.Size);
    Dec(VertScrollBar^.Height, GetTitleHeight);
    Inc(VertScrollBar^.Y, GetTitleHeight);
  end
  else begin
    if Grip^.Visible and not VertScrollBar^.Visible then
      Dec(HorzScrollBar^.Width, VertScrollBar^.Size);
  end;
end;

function TWindow.GetGripBorder(const APoint: TPoint): TGripBorderType;
var
  index: TGripBorderType;
  rect, screenRect: TRect;
begin
  GetGripBorder := gbNone;
  for index := Low(TGripBorderType) to High(TGripBorderType) do begin
    rect.CreateRect(FGripBorders[index]);
    rect.Translate(ScreenX, ScreenY);
    if rect.ContainsPoint(APoint) then begin
      GetGripBorder := index;
      exit;
    end;
  end;
end;

procedure TWindow.MouseDown(var AEvent: TMouseEvent);
var
  point: TPoint;
begin
  inherited MouseDown(AEvent);
  if AEvent.Handled then
    exit;
  if (not Active) and (AEvent.NewMouseState.ButtonState = [bsLeft]) then begin
    Activate;
  end;
  if not (woResizeable in WindowOptions) then
    exit;
  point.CreateCoords(AEvent.NewMouseState.X, AEvent.NewMouseState.Y);
  FDragBorder := GetGripBorder(point);
end;

procedure TWindow.HandleDragCursors(var AEvent: TMouseEvent);
var
  point: TPoint;
  cursor: PMouseCursor;
  gripBorder: TGripBorderType;
begin
  if not (woResizeable in WindowOptions) then
    exit;
  if (FDragBorder = gbNone) and not Assigned(VeridianApp^.DragControl) then begin
    point.CreateCoords(AEvent.X, AEvent.Y);
    point.Translate(ScreenX, ScreenY);
    gripBorder := GetGripBorder(point);
    if gripBorder = gbNone then
      cursor := VeridianApp^.MouseCursors^.GetItemById('default')
    else
      cursor := VeridianApp^.MouseCursors^.GetItemById(GripCursors[gripBorder]);
    if cursor <> VeridianApp^.MouseCursor then begin
      VeridianApp^.EraseMouseCursor(AEvent.NewMouseState);
      VeridianApp^.MouseCursor := cursor;
      VeridianApp^.DrawMouseCursor(AEvent.NewMouseState);
    end;
  end;
end;

procedure TWindow.DragMove(var AEvent: TDragEvent);
var
  rect, originalRect: TRect;
  dx, dy: integer;
  minSize: integer;
  horzBar, vertBar: PScrollBar;
begin
  inherited DragMove(AEvent);
  if AEvent.Handled or (FDragBorder = gbNone) then
    exit;
  GetDrawRect(rect);
  originalRect.CreateRect(rect);
  dx := AEvent.X - AEvent.InitialX;
  dy := AEvent.Y - AEvent.InitialY;
  if (dx = 0) and (dy = 0) then
    exit;
  case FDragBorder of
    gbTop: begin
      rect.Translate(0, dy);
      rect.Grow(0, -dy);
    end;
    gbBottom: begin
      rect.Grow(0, dy);
    end;
    gbLeft: begin
      rect.Translate(dx, 0);
      rect.Grow(-dx, 0);
    end;
    gbRight: begin
      rect.Grow(dx, 0);
    end;
    gbTopLeft: begin
      rect.Translate(dx, dy);
      rect.Grow(-dx, -dy);
    end;
    gbTopRight: begin
      rect.Translate(0, dy);
      rect.Grow(dx, -dy);
    end;
    gbBottomLeft: begin
      rect.Translate(dx, 0);
      rect.Grow(-dx, dy);
    end;
    gbBottomRight: begin
      rect.Grow(dx, dy);
    end;
  end;
  minSize := MinWidth;
  if rect.Width < minSize then begin
    rect.Width := minSize;
    if FDragBorder in [gbLeft, gbTopLeft, gbBottomLeft] then
      rect.X := originalRect.Right - minSize;
  end;
  minSize := MinHeight;
  if rect.Height < minSize then begin
    rect.Height := minSize;
    if FDragBorder in [gbTop, gbTopLeft, gbTopRight] then
      rect.Y := originalRect.Bottom - minSize;
  end;
  VeridianApp^.DragRect := rect;
  AEvent.Handled := true;
end;

procedure TWindow.MouseEnter(var AEvent: TMouseEvent);
begin
  inherited MouseEnter(AEvent);
  HandleDragCursors(AEvent);
end;

procedure TWindow.MouseLeave(var AEvent: TMouseEvent);
begin
  inherited MouseLeave(AEvent);
  HandleDragCursors(AEvent);
end;

procedure TWindow.MouseMove(var AEvent: TMouseEvent);
begin
  inherited MouseMove(AEvent);
  HandleDragCursors(AEvent);
end;

procedure TWindow.MouseUp(var AEvent: TMouseEvent);
begin
  inherited MouseUp(AEvent);
  FDragBorder := gbNone;
end;

procedure TWindow.DragStart(var AEvent: TDragEvent);
var
  rect: TRect;
  point: TPoint;
begin
  inherited DragStart(AEvent);
  if AEvent.Handled then
    exit;
  if not (woResizeable in WindowOptions) then
    exit;
  AEvent.Handled := true;
  if FDragBorder = gbNone then
    exit;
  GetDrawRect(rect);
  desktop^.BeginDrawing;
  VeridianApp^.DragRect := rect;
  desktop^.MouseCursor := MouseCursor;
  desktop^.EndDrawing;
end;

procedure TWindow.DragEnd(var AEvent: TDragEvent);
var
  rect: TRect;
  sizingEvent: TSizingEvent;
  sizedEvent: TSizeEvent;
begin
  inherited DragEnd(AEvent);
  if AEvent.Handled then
    exit;
  if FDragBorder = gbNone then
    exit;
  desktop^.BeginDrawing;
  CreateSizingEvent(sizingEvent);
  CreateSizedEvent(sizedEvent);
  Resizing(sizingEvent);
  if sizingEvent.CanResize then begin
    Resize;
  end;
  desktop^.MouseCursor := VeridianApp^.MouseCursors^.GetItemById('default');
  desktop^.EndDrawing;
  AEvent.Handled := true;
  if sizingEvent.CanResize then
    Resized(sizedEvent);
  FDragBorder := gbNone;
end;

function TScrollBar.ScrollPosition: longint;
begin
  ScrollPosition := Round(FPosition);
end;

procedure TScrollBar.SetScrollPosition(const APosition: longint);
begin
  SetRealPosition(APosition);
end;

procedure TScrollBar.SetRealPosition(const APosition: real);
var
  parentView: PView;
  contentRect, clipRect, drawRect: TRect;
  newCoord: integer;
begin
  if (Max = 0) or (Round(APosition) = Round(FPosition)) then
    exit;
  parentView := PView(Parent);
  FPosition := APosition;

  with parentView^ do begin
    BeginDrawing;
    GetContentDrawRect(drawRect);
    GetClipRect(clipRect);
    clipRect.Intersect(Graph^.State^.ViewPort);
    drawRect.Intersect(clipRect);
    PaintRegion(drawRect, nil);
    EndDrawing;
  end;
  newCoord := CoordFromPos;

  if Orientation = soHorizontal then
    Slider^.X := newCoord
  else
    Slider^.Y := newCoord;
  DrawSlider;
end;

function TScrollBar.CoordFromPos: integer;
begin
  CoordFromPos := Round(FPosition / Max * ScrollSize) + Size - Slider^.BorderWidth;
end;

function TScrollBar.PosFromCoord: real;
var
  coord: integer;
begin
  if Orientation = soHorizontal then
    coord := Slider^.X
  else
    coord := Slider^.Y;
  PosFromCoord := (coord - Size + Slider^.BorderWidth) / ScrollSize * Max;
end;

function TScrollBar.ScrollSize: integer;
var
  sizeAdjust: integer;
begin
  sizeAdjust := 3 * Size - 2 * Slider^.BorderWidth - 2 * OuterWidth;
  if Orientation = soHorizontal then
    ScrollSize := Width - sizeAdjust
  else
    ScrollSize := Height - sizeAdjust;
end;

procedure TScrollBar.Draw;
begin
  inherited Draw;
end;

procedure TScrollBar.DrawSlider;
var
  clipRect, rect, scrollRect: TRect;
  value: integer;
begin
  if not IsVisible then
    exit;
  Graph^.PushState;
  Graph^.SetDrawPage(Graph^.OffscreenPage);
  BeginDrawing;
  Graph^.SetBackColor(BackColor);
  GetDrawRect(scrollRect);
  Graph^.State^.FillPattern := @CheckerFillPattern;
  GetClipRect(clipRect);
  scrollRect.Intersect(clipRect);
  Graph^.SetViewPort(clipRect);
  if Orientation = soHorizontal then begin
    scrollRect.Translate(DecButton^.Width, 0);
    scrollRect.Grow(-2 * DecButton^.Width, 0);
    rect.CreateRect(scrollRect);
    rect.Width := Slider^.X - DecButton^.Width + 1;
    Graph^.FillRect(rect);
    rect.X := scrollRect.X + Slider^.X;
    rect.Width := scrollRect.Width - Slider^.X;
    Graph^.FillRect(rect);
  end
  else begin
    scrollRect.Translate(0, DecButton^.Height);
    scrollRect.Grow(0, -2 * DecButton^.Height);
    rect.CreateRect(scrollRect);
    rect.Height := Slider^.Y - DecButton^.Height + 1;
    Graph^.FillRect(rect);
    rect.Y := scrollRect.Y + Slider^.Y;
    rect.Height := scrollRect.Height - Slider^.Y;
    Graph^.FillRect(rect);
  end;
  DrawControls;
  EndDrawing;
  Graph^.CopyFromOffScreen(clipRect, clipRect);
  Graph^.PopState;
end;

procedure TScrollBar.ScrollByAmount(ADelta: integer);
var
  pos: real;
begin
  pos := ClampR(FPosition + ADelta, Min, Max);
  SetRealPosition(pos);
  DrawSlider;
end;

procedure TScrollBar.ScrollBySlider(ADelta: integer);
var
  minCoord, maxCoord: integer;
  pos: real;
  rect: TRect;
begin
  minCoord := Size - Slider^.BorderWidth;
  if Orientation = soHorizontal then begin
    maxCoord := Width - 2 * Size + Slider^.BorderWidth;
    slider^.X := Clamp(slider^.X + ADelta, minCoord, maxCoord);
    pos := PosFromCoord;
  end
  else begin
    maxCoord := Height - 2 * Size + Slider^.BorderWidth;
    slider^.Y := Clamp(slider^.Y + ADelta, minCoord, maxCoord);
    pos := PosFromCoord;
  end;
  if VeridianApp^.Settings.UpdateScrollContents then
    SetRealPosition(pos)
  else begin
    DrawSlider;
  end;
end;

procedure TView.ScrollVert(ADelta: integer);
begin
  if ADelta = 0 then
    exit;
  VertScrollBar^.ScrollByAmount(ADelta);
end;

procedure TView.ScrollHorz(ADelta: integer);
begin
  if ADelta = 0 then
    exit;
  HorzScrollBar^.ScrollByAmount(ADelta);
end;

constructor TTaskButton.Create(const AId: string; AParentTaskBar: PTaskBar; AWindow: PWindow);
begin
  inherited CreateParent(AId, AParentTaskBar);
  ParentTaskBar := AParentTaskBar;
  Window := AWindow;
end;

procedure TTaskButton.Init;
begin
  inherited Init;
  CanFocus := false;
  HorzAlign := haCenter;
  VertAlign := vaCenter;
  Padding.CreateAll(4, 4, 4, 4);
  Margins.CreateAll(2, 0, 0, 0);
  if Graph^.Mode^.Width < 512 then begin
  Padding.CreateAll(1, 1, 1, 1);
  Margins.CreateAll(1, 0, 0, 0);
  end;
  Font := VeridianApp^.GetFont('editor');
end;

function TTaskButton.IsTaskButton: boolean;
begin
  IsTaskButton := true;
end;

function TTaskButton.GetCaption: string;
begin
  GetCaption := Window^.TitleBar^.GetCaption;
end;

procedure TTaskButton.Paint(ARect: TRect);
begin
  inherited Paint(ARect);
end;

function CanActivate(AItem: pointer; var AValue): boolean;
var
  control: PControl;
  window: PWindow;
begin
  CanActivate := false;
  control := PControl(AItem);
  if not control^.IsWindow then
    exit;
  window := PWindow(control);
  CanActivate := window^.IsVisibleAndEnabled
    and not window^.Active
    and not (window^.WindowState = wsMinimized);
end;

procedure TTaskButton.MouseClick(var AEvent: TMouseEvent);
var
  last: PControl;
begin
  AEvent.Handled := true;
  if Window^.Active and (Window^.WindowState <> wsMinimized) then begin
    Window^.Minimize;
    last := Desktop^.Controls^.LastThat(CanActivate, Nothing);
    if Assigned(last) then begin
      last^.BringToFront;
      if last^.IsWindow then begin
        PWindow(last)^.Activate;
      end
      else
        last^.Draw;
    end
  end
  else if (not Window^.Active) and (Window^.WindowState <> wsMinimized) then begin
    Window^.Activate;
  end
  else if Window^.WindowState = wsMinimized then begin
    if Assigned(VeridianApp^.ActiveWindow) then
      VeridianApp^.ActiveWindow^.Deactivate;
    Window^.BringToFront;
    Window^.Restore;
  end;
end;

constructor TTaskBar.Create;
begin
  inherited CreateParent('TaskBar', Desktop);
end;

procedure TTaskBar.Paint(ARect: TRect);
begin
  inherited Paint(ARect);
end;

procedure TTaskbar.Init;
begin
  inherited Init;
  Windows.Create;
  Padding.CreateAll(0, 0, 0, 0);
  Margins.CreateValue(0);
  BorderStyle := bsSingle;
  BevelStyle := bvRaised;
  BorderColor := VeridianApp^.Colors.ButtonBorder;
  BackColor := VeridianApp^.Colors.ButtonBack;
  ForeColor := VeridianApp^.Colors.Button;
  Include(ControlOptions, coStayOnTop);
  MaxButtonWidth := 150;
  Font := VeridianApp^.Fonts^.GetItemById('editor');
  Position := rpParentClient;
end;

function TTaskBar.NewButton(AWindow: PWindow): PTaskButton;
var
  button: PTaskButton;
begin
  button := New(PTaskButton, Create('Button' + IntToStr(Controls^.Count), @self, AWindow));
  NewButton := button;
end;

procedure TTaskBar.RemoveButton(AWindow: PWindow);
var
  index: integer;
begin
  index := IndexOfWindow(AWindow);
  if index >= 0 then
    Windows.Delete(index);
  index := Controls^.IndexOf(AWindow^.TaskButton);
  if index >= 0 then
    Controls^.Delete(index);
end;

procedure TTaskBar.AddWindow(AWindow: PWindow);
var
  button: PTaskButton;
begin
  if (woShowInTaskBar in AWindow^.WindowOptions) and Assigned(VeridianApp^.TaskBar) then begin
    Windows.Add(AWindow);
    button := NewButton(AWindow);
    button^.Caption := TString.New(AWindow^.TitleBar^.GetCaption);
    AWindow^.TaskButton := button;
    Draw;
  end;
end;

procedure TTaskBar.RemoveWindow(AWindow: PWindow);
begin
  Windows.RemoveItem(AWindow);
  if Assigned(VeridianApp^.TaskBar) then begin
    RemoveButton(AWindow);
    AWindow^.TaskButton := nil;
    Draw;
  end;
end;

function TTaskBar.IndexOfWindow(AWindow: PWindow): integer;
begin
  IndexOfWindow := Windows.IndexOf(AWindow);
end;

function TTaskBar.GetWindow(AIndex: integer): PWindow;
begin
  GetWindow := Windows.GetItem(AIndex);
end;

function TTaskBar.GetWindowById(const AId: string): PWindow;
begin
  GetWindowById := Windows.GetItemById(AId);
end;

procedure TTaskBar.SetWindow(AIndex: integer; AWindow: PWindow);
begin
  Windows.SetItem(AIndex, AWindow);
  if (woShowInTaskBar in AWindow^.WindowOptions) and Assigned(VeridianApp^.TaskBar) then begin
    Draw;
  end;
end;

procedure TTaskBar.Layout;
var
  rect: TRect;
  index, xPos: integer;
  control: PContentControl;
  controlWidth: integer;
  taskButton: PTaskButton;
  controlHeight, barHeight: integer;
  maxHeight: integer;
  size: TSize;
begin
  inherited Layout;
  Desktop^.GetBounds(rect);
  Width := rect.Width + 2 * OuterWidth;
  X := -OuterWidth;
  xPos := 0;
  maxHeight := 0;
  for index := 0 to Controls^.Count - 1 do begin
    control := PContentControl(Controls^.GetItem(index));
    controlWidth := control^.Font^.TextWidth(PTaskButton(control)^.GetCaption)
      + 2 * control^.OuterWidth + control^.Padding.Width;
    control^.Width := Min(controlWidth, MaxButtonWidth);
    controlHeight := control^.Font^.Height + control^.Padding.Height + control^.OuterWidth;
    if control^.IsFocusControl then begin
      Inc(controlWidth, 2 * PFocusControl(control)^.FocusRectWidth);
      Inc(controlHeight, 2 * PFocusControl(control)^.FocusRectWidth);
    end;
    barHeight := controlHeight + 2 * OuterWidth + Margins.Height;
    if barHeight > maxHeight then
      maxHeight := barHeight;
    Inc(xPos, control^.Margins.Left);
    control^.X := xPos;
    size.CreateDims(control^.Width, control^.Height);
    rect.SetDims(0, 0, controlWidth, barHeight);
    control^.Y := 0;
    control^.Height := controlHeight;
    Inc(xPos, control^.Width + control^.Margins.Right);
  end;
  if maxHeight > 0 then
    Height := maxHeight + 1;
  Desktop^.GetBounds(rect);
  Y := rect.Bottom - Height + OuterWidth + 1;
end;

destructor TTaskBar.Free;
begin
  Windows.Free;
  inherited Free;
end;

procedure TWindowList.Init;
begin
  inherited Init;
  DisposeObjects := false;
end;

procedure TWindowList.Insert(AIndex: integer; AItem: PWindow);
begin
  inherited Insert(AIndex, AItem);
end;

function TWindowList.Add(AItem: PWindow): integer;
begin
  Add := inherited Add(AItem);
end;

procedure TWindowList.RemoveItem(AItem: PWindow);
begin
  inherited RemoveItem(AItem);
end;

function TWindowList.IndexOf(AItem: PWindow): integer;
begin
  IndexOf := inherited IndexOf(AItem);
end;

function TWindowList.GetItemById(const AId: string): PWindow;
begin
  GetItemById := PWindow(inherited GetItemById(AId));
end;

function TWindowList.GetItem(AIndex: integer): PWindow;
begin
  GetItem := PWindow(inherited GetItem(AIndex));
end;

procedure TWindowList.SetItem(AIndex: integer; AItem: PWindow);
begin
  inherited SetItem(AIndex, AItem);
end;

end.