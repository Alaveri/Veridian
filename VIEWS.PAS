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
  PVertScrollBar = ^TVertScrollBar;
  PHorzScrollBar = ^THorzScrollBar;
  PWindowGrip = ^TWindowGrip;
  PTaskbar = ^TTaskbar;
  PTaskbarButton = ^TTaskbarButton;

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

  TWindowState =
  (
    wsNormal,
    wsMaximized,
    wsMinimized
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
    MinimizeLabel: PLabel;
    MaximizeLabel: PLabel;
    ButtonBox: PPanel;
    CloseLabel: PLabel;
    constructor Create(const AId, ACaption: string; AParentWindow: PWindow);
    procedure Init; virtual;
    procedure Layout; virtual;
    procedure Paint; virtual;
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
    procedure Init; virtual;
    procedure Paint; virtual;
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
    FDownX, FDownY: integer;
  public
    procedure Init; virtual;
    procedure MouseDown(var AEvent: TMouseEvent); virtual;
    procedure MouseMove(var AEvent: TMouseEvent); virtual;
    procedure MouseUp(var AEvent: TMouseEvent); virtual;
  end;

  TScrollBar = object(TPanel)
  private
    procedure DrawSlider;
    procedure ScrollBySlider(ADelta: integer);
    procedure ScrollByPixels(ADelta: integer);
    procedure SetScrollPos(const APos: longint);
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
    procedure Paint; virtual;
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

  TView = object(TFocusControl)
  private
  public
    ScrollType: TViewScrollType;
    HorzScrollBar: PScrollBar;
    VertScrollBar: PScrollBar;
    function GetAutoWidth: longint; virtual;
    function GetAutoHeight: longint; virtual;
    function IsView: boolean; virtual;
    procedure Init; virtual;
    procedure Layout; virtual;
    procedure Paint; virtual;
    procedure DrawControls; virtual;
    procedure GetContentBounds(var ARect: TRect); virtual;
    procedure GetScrollBarBounds(AOrientation: TScrollOrientation;
      var ARect: TRect); virtual;
    procedure ScrollVert(ADelta: integer); virtual;
    procedure ScrollHorz(ADelta: integer); virtual;
    destructor Free; virtual;
  end;

  TWindow = object(TView)
  private
    FGripBorders: array[TGripBorderType] of PControl;
  public
    Title: PChar;
    TitleBar: PTitleBar;
    TaskButton: PTaskbarButton;
    ShowInTaskBar: boolean;
    Grip: PLabel;
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
    constructor CreateBackground(const AId, ATitle: string; AParent: PControl);
    constructor CreateTitle(const AId, ATitle: string; AParent: PControl);
    destructor Free; virtual;
    function TitleVisible: boolean;
    function Active: boolean;
    function MinWidth: integer; virtual;
    function MinHeight: integer; virtual;
    function IsWindow: boolean; virtual;
    function GetTitleHeight: integer; virtual;
    procedure GetGripBounds(var ARect: TRect); virtual;
    procedure GetGripScreenBounds(var ARect: TRect); virtual;
    procedure GetContentBounds(var ARect: TRect); virtual;
    procedure GetClientBounds(var ARect: TRect); virtual;
    procedure GetScrollBarBounds(AOrientation: TScrollOrientation;
      var ARect: TRect); virtual;
    procedure SetTitle(const ATitle: string);
    procedure SetTitleVisible(AVisible: boolean);
    procedure SetMinimizeVisible(AVisible: boolean);
    procedure SetMaximizeVisible(AVisible: boolean);
    procedure SetCloseVisible(AVisible: boolean);
    procedure GetMaximizedBounds(var ARect: TRect); virtual;
    procedure Layout; virtual;
    procedure Activate;
    procedure Deactivate;
    procedure Close(ASender: PControl); virtual;
    procedure Maximize; virtual;
    procedure Minimize; virtual;
    procedure Restore; virtual;
    procedure Init; virtual;
    procedure Paint; virtual;
    procedure MouseDown(var AEvent: TMouseEvent); virtual;
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

  TTaskbarButton = object(TButton)
  private
  public
    Window: PWindow;
    ParentTaskbar: PTaskbar;
    constructor Create(const AId: string; AParentTaskbar: PTaskbar; AWindow: PWindow);
    function GetCaption: string; virtual;
    procedure Init; virtual;
    procedure Paint; virtual;
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
    procedure Paint; virtual;
    procedure RemoveButton(AWindow: PWindow);
    function NewButton(AWindow: PWindow): PTaskBarButton;
    function IndexOfWindow(AWindow: PWindow): integer;
    function GetWindow(AIndex: integer): PWindow;
    function GetWindowById(const AId: string): PWindow;
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
  VeriCons,
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
  FDownX := 0;
  FDownY := 0;
end;

procedure TScrollSlider.MouseUp(var AEvent: TMouseEvent);
begin
end;

procedure TScrollSlider.MouseDown(var AEvent: TMouseEvent);
begin
  VeridianApp^.ScrollSlider := @self;
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
  GetScreenBounds(rect);
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
    SetScrollPos(newPos);
  end
  else if mouseCoord > sliderCoord + Slider^.Height  then begin
    newPos := ScrollPosition + PageIncrement;
    newPos := ClampL(newPos, Min, Max);
    SetScrollPos(newPos);
  end;
end;

procedure TScrollBar.SetScrollPos(const APos: longint);
var
  sizeAdjust: integer;
  scrollSize: integer;
  parentView: PView;
  screenRect, rect: TRect;
  newCoord: integer;
begin
  parentView := PView(Parent);
  ScrollPosition := APos;
  parentView^.ScrollY := APos;
  parentView^.BeginDrawing;
  parentView^.GetScreenBounds(screenRect);
  parentView^.GetContentBounds(rect);
  rect.Intersect(screenRect);
  Graph^.State^.ViewPort := rect;
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
  BorderStyle := bsNone;
  Position := spClient;
end;

procedure TScrollBar.Paint;
begin
  inherited Paint;
end;

procedure TScrollBar.GetSliderRect(var ARect: TRect);
begin
end;

procedure TScrollBar.Layout;
begin
end;

procedure TScrollBar.PositionChanged(var AEvent: TScrollEvent);
var
  parentView: PView;
  screenRect, rect: TRect;
begin
  if not VeridianApp^.Settings.UpdateScrollContents then begin
    SetScrollPos(AEvent.ScrollPosition);
  end;
  Invoke(OnPositionChanged, AEvent);
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
  sizeAdjust := 3 * Size + 3 * BorderWidth;
  posOffset := Size - Slider^.BorderWidth;
  scrollSize := Height - sizeAdjust + 2 * Slider^.BorderWidth;
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

procedure CloseButtonClick(var AEvent: TMouseEvent);
var
  window: PWindow;
  parent: PTitleBar;
  button: PLabel;
begin
  if AEvent.Handled then
    exit;
  button := PLabel(AEvent.Sender);
  parent := PTitleBar(button^.Parent);
  window := PWindow(parent^.ParentWindow);
  if not window^.Active then begin
    window^.BringToFront;
    window^.Activate;
  end;
  window^.Close(button);
  if Assigned(window^.TaskButton) and Assigned(VeridianApp^.TaskBar) then begin
    VeridianApp^.TaskBar^.RemoveButton(window);
    VeridianApp^.TaskBar^.Draw;
  end;
  AEvent.Handled := true;
end;

procedure MinimizeButtonClick(var AEvent: TMouseEvent);
var
  window: PWindow;
  parent: PTitleBar;
  button: PLabel;
begin
  if AEvent.Handled then
    exit;
  button := PLabel(AEvent.Sender);
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
  button: PLabel;
begin
  if AEvent.Handled then
    exit;
  button := PLabel(AEvent.Sender);
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
  Padding.CreateAll(3, 2, 3, 2);
  CanDrag := true;
  ParentWindow := nil;
  Font := Desktop^.Font;
  ButtonBox := New(PPanel, CreateParent('ButtonBox', @self));
  MinimizeLabel := New(PLabel, CreateCaption('MinLabel', #6, @self));
  with MinimizeLabel^ do begin
    Font := VeridianApp^.Fonts^.GetItemById('Symbol');
    SetCaption(#6);
    HorzAlign := haCenter;
    VertAlign := vaCenter;
    AutoSize := true;
    OnMouseClick := @MinimizeButtonClick;
  end;
  MaximizeLabel := New(PLabel, CreateCaption('MaxLabel', #7, @self));
  with MaximizeLabel^ do begin
    Font := VeridianApp^.Fonts^.GetItemById('Symbol');
    SetCaption(#7);
    HorzAlign := haCenter;
    VertAlign := vaCenter;
    AutoSize := true;
    OnMouseClick := @MaximizeButtonClick;
  end;
  CloseLabel := New(PLabel, CreateCaption('CloseLabel', #8, @self));
  with CloseLabel^ do begin
    Font := VeridianApp^.Fonts^.GetItemById('Symbol');
    SetCaption(#8);
    HorzAlign := haCenter;
    VertAlign := vaCenter;
    AutoSize := true;
    OnMouseClick := @CloseButtonClick;
  end;
  Position := spClient;
end;

procedure TTitleBar.Layout;
var
  rect: TRect;
  xPos: integer;
  totalWidth: integer;
  pos: TPoint;
begin
  inherited Layout;
  GetClientBounds(rect);
  CloseLabel^.Layout;
  MaximizeLabel^.Layout;
  MinimizeLabel^.Layout;
  xPos := rect.Right;
  totalWidth := 0;
  if CloseLabel^.IsVisible then  begin
    Dec(xPos, CloseLabel^.Width + Padding.Right);
    Inc(totalWidth, CloseLabel^.Width);
    CloseLabel^.SetBounds(
      xPos,
      rect.Y,
      CloseLabel^.Width,
      CloseLabel^.Height
    );
  end;
  if MaximizeLabel^.IsVisible then begin
    Dec(xPos, CloseLabel^.Width + 5);
    Inc(totalWidth, CloseLabel^.Width + 5);

    MaximizeLabel^.SetBounds(
      xPos,
      rect.Y,
      MaximizeLabel^.Width,
      MaximizeLabel^.Height
    );
  end;
  if MinimizeLabel^.IsVisible then begin
    Dec(xPos, MinimizeLabel^.Width + 5);
    Inc(totalWidth, MinimizeLabel^.Width + 5);
    MinimizeLabel^.SetBounds(
      xPos,
      rect.Y,
      MinimizeLabel^.Width,
      MinimizeLabel^.Height
    );
  end;
  GetBounds(rect);
  if MinimizeLabel^.IsVisible
    or MaximizeLabel^.IsVisible
    or CloseLabel^.IsVisible then begin
    Inc(totalWidth, 5);
    Dec(xPos, 5);
  end;
  ButtonBox^.SetBounds(xPos, 0, totalWidth, rect.Height);
end;

procedure TTitleBar.Paint;
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
  CloseLabel^.ForeColor := ForeColor;
  MaximizeLabel^.ForeColor := ForeColor;
  MinimizeLabel^.ForeColor := ForeColor;
  CloseLabel^.BackColor := BackColor;
  MaximizeLabel^.BackColor := BackColor;
  MinimizeLabel^.BackColor := BackColor;
  ButtonBox^.ForeColor := ForeColor;
  ButtonBox^.BackColor := BackColor;
  inherited Paint;
  ForeColor := fore;
  BackColor := back;
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

procedure TTitleBar.MouseDoubleClick(var AEvent: TMouseEvent);
begin
  if AEvent.Handled then
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
  Font := Desktop^.Font;
  CanFocus := true;
  HorzScrollBar := New(PHorzScrollBar, CreateParent('HorzScrollBar', @self));
  VertScrollBar := New(PVertScrollBar, CreateParent('VertScrollBar', @self));
  ScrollType := scNone;
  AutoSize := false;
  ScrollX := 0;
  ScrollY := 0;
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

procedure TView.GetScrollBarBounds(AOrientation: TScrollOrientation; var ARect: TRect);
var
  rect: TRect;
  barSize: integer;
  barLength: integer;
begin
  GetClientBounds(rect);
  if AOrientation = soVertical then begin
    barSize := VertScrollBar^.Size;
    barLength := rect.Height;
    if HorzScrollBar^.Visible then
      Dec(barLength, HorzScrollBar^.Size);
    ARect.CreateDims(rect.Width - barSize, 0, BarSize, barLength);
  end
  else if AOrientation = soHorizontal then begin
    barSize := HorzScrollBar^.Size;
    barLength := rect.Width;
    if VertScrollBar^.Visible then
      Dec(barLength, VertScrollBar^.Size);
    ARect.CreateDims(0, rect.Height - barSize, BarLength, barSize);
  end;
end;

procedure TView.GetContentBounds(var ARect: TRect);
var
  hRect, vRect: TRect;
begin
  inherited GetContentBounds(ARect);
  if ScrollType = scNone then
    exit;
  GetScrollBarBounds(soHorizontal, hRect);
  GetScrollBarBounds(soVertical, vRect);
  case ScrollType of
    scVertical: begin
      if VertScrollBar^.Visible then
        Dec(ARect.Width, vRect.Width - 1);
    end;
    scHorizontal: begin
      if HorzScrollBar^.Visible then
        Dec(ARect.Height, hRect.Height - 1 + BevelWidth);
    end;
    scBoth: begin
      if HorzScrollBar^.Visible then
        Dec(ARect.Width, vRect.Width - 1 + BevelWidth);
      if VertScrollBar^.Visible then
        Dec(ARect.Height, hRect.Height - 1 + BevelWidth);
    end;
  end;
end;

procedure TView.DrawControls;
var
  rect: TRect;
  index: integer;
  control: PControl;
  viewPort: TRect;
begin
  GetScreenBounds(rect);
  BeginDrawing;
  viewPort.CreateRect(Graph^.State^.ViewPort);
  for index := 0 to Controls^.Count - 1 do begin
    control := Controls^.GetItem(index);
    control^.Draw;
  end;
  EndDrawing;
end;

procedure TView.Layout;
var
  rect: TRect;
begin
  inherited Layout;
  GetBounds(rect);
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

  GetScrollBarBounds(soVertical, rect);
  VertScrollBar^.SetBoundsRect(rect);
  GetScrollBarBounds(soHorizontal, rect);
  HorzScrollBar^.SetBoundsRect(rect);
end;

procedure TView.Paint;
begin
  TPanel.Paint;
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
  Position := spClient;
end;

procedure TWindowGrip.Paint;
begin
  inherited Paint;
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
  ParentWindow^.GetScreenBounds(rect);
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

procedure TWindowGrip.DragEnd(var AEvent: TDragEvent);
var
  rect: TRect;
  sizingEvent: TSizingEvent;
  sizedEvent: TSizeEvent;
begin
  if AEvent.Handled then
    exit;
  ParentWindow^.CreateSizingEvent(sizingEvent);
  ParentWindow^.CreateSizedEvent(sizedEvent);
  ParentWindow^.Resizing(sizingEvent);
  desktop^.BeginDrawing;
  if sizingEvent.CanResize then begin
    ParentWindow^.Hide;
    ParentWindow^.SetBoundsRect(VeridianApp^.DragRect);
    ParentWindow^.Show;
  end;
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
  ParentWindow^.GetScreenBounds(rect);
  if ParentWindow^.WindowState = wsMaximized then begin
    rect.Width := ParentWindow^.RestoredBounds.Width;
    rect.Height := ParentWindow^.RestoredBounds.Height;
    rect.X := AEvent.X - (rect.Width div 2);
    rect.Width := ParentWindow^.RestoredBounds.Width;
    rect.Height := ParentWindow^.RestoredBounds.Height;
    ParentWindow^.WindowState := wsNormal;
    TString.Reassign(MaximizeLabel^.Caption, #7);
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
  if AEvent.Handled then
    exit;
  ParentWindow^.GetScreenBounds(rect);
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
  ParentWindow^.CreateMovingEvent(movingEvent);
  ParentWindow^.CreateMovedEvent(movedEvent);
  if movingEvent.CanMove then begin
    desktop^.BeginDrawing;
    ParentWindow^.Hide;
    ParentWindow^.SetBoundsRect(VeridianApp^.DragRect);
    ParentWindow^.WindowState := wsNormal;
    ParentWindow^.Show;
    desktop^.EndDrawing;
    ParentWindow^.Moved(movedEvent);
  end;
  AEvent.Handled := true;
end;

procedure TWindow.Init;
var
  gripBorderIndex: TGripBorderType;
begin
  inherited Init;
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
  CanDrag := false;
  CanFocus := false;
  ShowInTaskBar := true;
  TitleBar := New(PTitleBar, Create('TitleBar', '', @self));
  Grip := New(PWindowGrip, Create('Grip', @self));
  Grip^.TransparentBack := false;
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
  OnMaximized := nil;
  OnMinimized := nil;
  OnRestored := nil;
  Title := nil;
  WindowState := wsNormal;
  TaskButton := nil;
  AddToTaskBar;
end;

destructor TWindow.Free;
var
  event: TEvent;
begin
  event.Create;
  WindowFree(event);
  TString.Free(Title);
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
    TitleBar^.MaximizeLabel^.SetCaption(#7);
    Show;
    Resized(sizedEvent);
    exit;
  end;
  GetBounds(rect);
  sizingEvent.NewSize.CreateDims(MaxRect.Width, maxRect.Height);
  sizedEvent.NewSize.CreateSize(sizingEvent.NewSize);
  TitleBar^.MaximizeLabel^.SetCaption(#9);
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
      TitleBar^.MaximizeLabel^.SetCaption(#7);
      Activate;
      Resized(sizedEvent);
      Moved(movedEvent);
      Restored(restoredEvent);
    end;
    wsMinimized: begin
      WindowState := RestoredState;
      Activate;
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
  TitleBar^.CloseLabel^.Visible := AVisible;
  TitleBar^.Draw;
end;

procedure TWindow.AddToTaskBar;
begin
  if not ShowInTaskBar then
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

constructor TWindow.CreateTitle(const AId, ATitle: string; AParent: PControl);
begin
  ShowInTaskBar := true;
  inherited CreateParent(AId, AParent);
  SetTitle(ATitle);
end;

constructor TWindow.CreateBackground(const AId, ATitle: string; AParent: PControl);
begin
  ShowInTaskBar := false;
  inherited CreateParent(AId, AParent);
  SetTitle(ATitle);
end;

function TWindow.MinWidth: integer;
var
  minW: integer;
  minTW: integer;
  buttonSize: integer;
begin
  buttonSize := HorzScrollBar^.Size
    + 2 * HorzScrollBar^.OuterWidth
    + 2 * HorzScrollBar^.SpacingWidth;
  if not HorzScrollBar^.Visible then
    buttonSize := 0;
  minW := 4 * buttonSize + OuterWidth;
  if VertScrollBar^.Visible and not HorzScrollBar^.Visible then
    Inc(minW, VertScrollBar^.Size + 2 * VertScrollBar^.OuterWidth);
  minTW := 2 * OuterWidth + (Width - TitleBar^.ButtonBox^.X - 1);
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
  if WindowState = wsMaximized then begin
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
  titleHeight := GetTitleHeight;
  TitleBar^.SetBounds(0, 0, rect.Width, titleHeight);
  for index := Low(TGripBorderType) to High(TGripBorderType) do begin
    FGripBorders[index]^.BringToFront;
  end;
  FGripBorders[wbTop]^.SetBounds(3, 0, Width - 6, 3);
  FGripBorders[wbBottom]^.SetBounds(3, Height - 3, Width - 6, 3);
  FGripBorders[wbLeft]^.SetBounds(0, 3, 3, Height - 6);
  FGripBorders[wbRight]^.SetBounds(Width - 3, 3, 3, Height - 6);
  FGripBorders[wpTopLeft]^.SetBounds(0, 0, 3, 3);
  FGripBorders[wpTopRight]^.SetBounds(Width - 3, 0, 3, 3);
  FGripBorders[wpBottomLeft]^.SetBounds(0, Height - 3, 3, 3);
  FGripBorders[wpBottomRight]^.SetBounds(Width - 3, Height - 3, 3, 3);
  Grip^.BringToFront;
  if WindowState <> wsMaximized then
    GetBounds(RestoredBounds);
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
  if VeridianApp^.SelectingControl = ASender then
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
  ClearControlStates(ASender);
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
begin
  activeWindow := VeridianApp^.ActiveWindow;
  if Assigned(activeWindow) then begin
    activeWindow^.Deactivate;
    VeridianApp^.ActiveWindow := nil;
    activeWindow^.TitleBar^.Draw;
  end;
  VeridianApp^.ActiveWindow := @self;
  BringToFront;
  if Visible then begin
    if Assigned(TitleBar) then
      TitleBar^.Draw;
  end
  else
    Show;
  if Assigned(TaskButton) then begin
    TaskButton^.Down := true;
    TaskButton^.DrawSelf;
  end;
end;

procedure TWindow.SetTitle(const ATitle: string);
begin
  TString.AssignString(TitleBar^.Caption, ATitle);
  TitleBar^.Draw;
end;

procedure TWindow.Deactivate;
var
  activeWindow: PWindow;
begin
  activeWindow := VeridianApp^.ActiveWindow;
  if activeWindow = @self then begin
    if Assigned(activeWindow^.TaskButton) then begin
      activeWindow^.TaskButton^.Down := false;
      activeWindow^.TaskButton^.DrawSelf;
    end;
    VeridianApp^.ActiveWindow := nil;
    Draw;
  end;
end;

function TWindow.GetTitleHeight: integer;
begin
  GetTitleHeight := 0;
  if not TitleBar^.IsVisible then
    exit;
  GetTitleHeight := Font^.Height + 2 * TitleBar^.Margins.Height;
end;

procedure TWindow.GetGripBounds(var ARect: TRect);
var
  rect: TRect;
  barSize: integer;
begin
  GetClientBounds(rect);
  barSize := 17;
  if Graph^.Mode^.Width <= 320 then
    barSize := 11;
  ARect.CreateDims(rect.Right - barSize - 1, rect.Bottom - barSize - 1,
    barSize, barSize);
end;

procedure TWindow.GetGripScreenBounds(var ARect: TRect);
var
  rect: TRect;
  barSize: integer;
begin
  GetScreenBounds(rect);
  barSize := 16;
  if Graph^.Mode^.Width <= 320 then
    barSize := 10;
  ARect.CreateDims(rect.Right - barSize, rect.Bottom - barSize, barSize, barSize);
end;

procedure TWindow.GetContentBounds(var ARect: TRect);
var
  titleHeight: integer;
begin
  inherited GetContentBounds(ARect);
  if TitleBar^.IsVisible then begin
    titleHeight := GetTitleHeight;
    ARect.Translate(0, titleHeight);
    ARect.Grow(0, -titleHeight);
  end;
end;

procedure TWindow.GetClientBounds(var ARect: TRect);
var
  titleHeight: integer;
begin
  inherited GetClientBounds(ARect);
end;

procedure TWindow.GetScrollBarBounds(AOrientation: TScrollOrientation; var ARect: TRect);
begin
  inherited GetScrollBarBounds(AOrientation, ARect);
  if AOrientation = soVertical then begin
    ARect.Translate(0, GetTitleHeight);
    ARect.Grow(0, -GetTitleHeight);
  end;
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

procedure TScrollBar.SetPosition(const APosition: longint);
var
  sizeAdjust: integer;
  scrollSize: integer;
  parentView: PView;
  rect: TRect;
  newCoord: integer;
  parentRect: TRect;
begin
  if ScrollPosition = APosition then
    exit;
  parentView := PView(Parent);
  ScrollPosition := APosition;
  parentView^.ScrollY := APosition;
  parentView^.BeginDrawing;
  parentView^.GetContentBounds(rect);
  parentView^.GetScreenBounds(parentRect);
  rect.Translate(parentRect.X, parentRect.Y);
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
    Inc(Slider^.Y, 2);
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
    Graph^.State^.FillPattern := @CheckerFillPattern;
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
    rect.Translate(BorderWidth, Size);
    rect.Grow(-2 * BorderWidth, 0);
    Graph^.State^.FillPattern := @CheckerFillPattern;
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
    maxCoord := Height - 2 * Size;
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
  Position := spClient;
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
  VeridianApp^.DragRect := rect;
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
  minSize := ParentWindow^.MinWidth;
  if rect.Width < minSize then begin
    rect.Width := minSize;
    if BorderType in [wbLeft, wpTopLeft, wpBottomLeft] then
      rect.X := originalRect.Right - minSize;
  end;
  minSize := ParentWindow^.MinHeight;
  if rect.Height < minSize then begin
    rect.Height := minSize;
    if BorderType in [wbTop, wpTopLeft, wpTopRight] then
      rect.Y := originalRect.Bottom - minSize;
  end;
  VeridianApp^.DragRect := rect;
  AEvent.Handled := true;
end;

procedure TGripBorder.DragEnd(var AEvent: TDragEvent);
var
  rect: TRect;
  sizingEvent: TSizingEvent;
  sizedEvent: TSizeEvent;
begin
  if AEvent.Handled then
    exit;
  desktop^.BeginDrawing;
  ParentWindow^.CreateSizingEvent(sizingEvent);
  ParentWindow^.CreateSizedEvent(sizedEvent);
  ParentWindow^.Resizing(sizingEvent);
  if sizingEvent.CanResize then begin
    ParentWindow^.Hide;
    ParentWindow^.SetBoundsRect(VeridianApp^.DragRect);
    ParentWindow^.Show;
  end;
  desktop^.MouseCursor := VeridianApp^.MouseCursors^.GetItemById('default');
  desktop^.EndDrawing;
  AEvent.Handled := true;
  if sizingEvent.CanResize then
    ParentWindow^.Resized(sizedEvent);
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

constructor TTaskBarButton.Create(const AId: string; AParentTaskBar: PTaskBar; AWindow: PWindow);
begin
  inherited CreateParent(AId, AParentTaskBar);
  ParentTaskBar := AParentTaskBar;
  Window := AWindow;
end;

procedure TTaskBarButton.Init;
begin
  inherited Init;
  CanFocus := false;
  CanDrag := true;
  HorzAlign := haLeft;
  VertAlign := vaCenter;
  Margins.CreateAll(4, 2, 4, 2);
  Padding.CreateAll(4, 2, 4, 2);
  AutoSize := true;
end;

function TTaskBarButton.GetCaption: string;
begin
  GetCaption := Window^.TitleBar^.GetCaption;
end;

procedure TTaskBarButton.Paint;
begin
  inherited Paint;
end;

function IsActive(AItem: pointer): boolean;
begin
  IsActive := PWindow(AItem)^.Active;
end;

procedure TTaskBarButton.MouseClick(var AEvent: TMouseEvent);
var
  last: PControl;
begin
  AEvent.Handled := true;
  if Window^.WindowState <> wsMinimized then begin
    Window^.Minimize;
    last := Desktop^.Controls^.LastThat(IsActive);
    if Assigned(last) then begin
      last^.BringToFront;
      if last^.IsWindow then begin
        PWindow(last)^.Activate;
      end
      else
        last^.Draw;
    end;
    exit;
  end;
  if Assigned(VeridianApp^.ActiveWindow) then
    VeridianApp^.ActiveWindow^.Deactivate;
  Window^.BringToFront;
  Window^.Restore;
end;

constructor TTaskBar.Create;
begin
  inherited CreateParent('TaskBar', Desktop);
end;

procedure TTaskBar.Paint;
begin
  inherited Paint;
end;

procedure TTaskbar.Init;
begin
  inherited Init;
  Windows.Create;
  Padding.CreateValue(2);
  Margins.CreateValue(1);
  BorderStyle := bsSingle;
  BevelStyle := bvRaised;
  BorderColor := VeridianApp^.Colors.ButtonBorder;
  BackColor := VeridianApp^.Colors.ButtonBack;
  ForeColor := VeridianApp^.Colors.Button;
  StayOnTop := true;
  MaxButtonWidth := 120;
  Font := VeridianApp^.Fonts^.GetItemById('editor');
  Position := spClient;
end;

function TTaskBar.NewButton(AWindow: PWindow): PTaskBarButton;
var
  button: PTaskBarButton;
begin
  button := New(PTaskBarButton, Create('Button' + IntToStr(Controls^.Count), @self, AWindow));
  NewButton := button;
end;

procedure TTaskBar.RemoveButton(AWindow: PWindow);
var
  index: integer;
begin
  index := IndexOfWindow(AWindow);
  if index >= 0 then
    Controls^.Delete(index);
end;

procedure TTaskBar.AddWindow(AWindow: PWindow);
var
  button: PTaskBarButton;
begin
  if AWindow^.ShowInTaskBar and Assigned(VeridianApp^.TaskBar) then begin
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
  if AWindow^.ShowInTaskBar and Assigned(VeridianApp^.TaskBar) then begin
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
  if AWindow^.ShowInTaskBar and Assigned(VeridianApp^.TaskBar) then begin
    Draw;
  end;
end;

procedure TTaskBar.Layout;
var
  rect: TRect;
  index, xPos: integer;
  control: PContentControl;
  controlWidth: integer;
  controlHeight, barHeight: integer;
  maxHeight: integer;
  pos: TPoint;
  size: TSize;
begin
  inherited Layout;
  Desktop^.GetBounds(rect);
  Width := rect.Width + 2 * OuterWidth;
  X := -OuterWidth;
  xPos := -X + Padding.Left;
  Height := 0;
  maxHeight := 0;
  for index := 0 to Controls^.Count - 1 do begin
    control := PContentControl(Controls^.GetItem(index));
    control^.Layout;
    controlWidth := Min(control^.Width, MaxButtonWidth) + 2 * control^.FocusRectWidth;
    controlHeight := 2 * control^.OuterWidth + control^.Font^.Height
      + 2 * FocusRectWidth + control^.Padding.Height;
    barHeight := controlHeight + OuterWidth + Margins.Height + 2 * control^.FocusRectWidth;
    if barHeight > maxHeight then
      maxHeight := barHeight;
    control^.Width := controlWidth;
    control^.X := xPos;
    Inc(xPos, Width + Padding.Width);
    size.CreateDims(controlWidth, controlHeight);
    rect.SetDims(0, 0, control^.Width, barHeight - OuterWidth);
    control^.GetAlign(rect, size, pos);
    control^.Y := pos.Y;
  end;
  Height := maxHeight;
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