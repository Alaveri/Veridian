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
  Controls;

const
  ScrollBarSize = 16;

type
  PView = ^TView;
  PWindow = ^TWindow;
  PScrollBar = ^TScrollBar;
  PTitleBar = ^TTitleBar;
  PScrollSlider = ^TScrollSlider;
  PViewClosingEventProc = ^TViewClosingEventProc;

  TViewClosingEvent = object(TEvent)
  private
  public
    CanClose: boolean;
    procedure Init; virtual;
  end;

  TViewClosingEventProc = procedure(ASender: PObject; var AEvent: TViewClosingEvent);

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

  TTitleBar = object(TCaptionControl)
  private
  public
    ParentView: PView;
    ActiveForeColor: byte;
    ActiveBackColor: byte;
    procedure Init; virtual;
    procedure Paint; virtual;
    procedure MouseDown(var AEvent: TMouseEvent); virtual;
  end;

  TScrollSlider = object(TButton)
  private
    DownX, DownY: integer;
  public
    procedure Init; virtual;
    procedure MouseDown(var AEvent: TMouseEvent); virtual;
    procedure MouseUp(var AEvent: TMouseEvent); virtual;
    procedure MouseMove(var AEvent: TMouseEvent); virtual;
    procedure ProcessMouseMove(var AEvent: TMouseEvent); virtual;
  end;

  TScrollBar = object(TPanel)
  private
    procedure GetSliderRect(var ARect: TRect);
    procedure DrawSlider;
    procedure ScrollBySlider(ADelta: integer);
    procedure ScrollByPixels(ADelta: integer);
  public
    Size: integer;
    IncButton: PButton;
    DecButton: PButton;
    Slider: PScrollSlider;
    Min: longint;
    Max: longint;
    Increment: longint;
    PageIncrement: longint;
    CurrentPos: longint;
    Orientation: TScrollOrientation;
    OnCurrentPosChanged: PEventProc;
    constructor CreateParent(const AId: string; AParent: PControl; AOrientation: TScrollOrientation);
    procedure SetCurrentPos(const APos: longint);
    procedure Init; virtual;
    procedure Layout; virtual;
    procedure MouseDown(var AEvent: TMouseEvent); virtual;
  end;

  TView = object(TPanel)
  private
  public
    Title: PChar;
    TitleBar: PTitleBar;
    ScrollType: TViewScrollType;
    HorzScrollBar: PScrollBar;
    VertScrollBar: PScrollBar;
    AutoSize: boolean;
    ScrollX: longint;
    ScrollY: longint;
    OnClosing: PViewClosingEventProc;
    OnClosed: PEventProc;
    ViewState: TViewState;
    constructor CreateTitle(const AId, ATitle: string; AParent: PControl);
    function Active: boolean;
    function GetAutoWidth: longint; virtual;
    function GetAutoHeight: longint; virtual;
    function TitleVisible: boolean;
    procedure Close; virtual;
    procedure SetTitleVisible(AVisible: boolean);
    procedure Activate;
    procedure Deactivate;
    procedure Init; virtual;
    procedure Maximize; virtual;
    procedure Layout; virtual;
    procedure SetTitle(const ATitle: string);
    procedure GetContentScreenBounds(var ARect: TRect);
    procedure GetContentBounds(var ARect: TRect);
    procedure ScrollVert(ADelta: integer); virtual;
    procedure ScrollHorz(ADelta: integer); virtual;
    destructor Free; virtual;
  end;

  TWindow = object(TView)
  private
  public
    procedure Init; virtual;
    procedure Paint; virtual;
    procedure MouseDown(var AEvent: TMouseEvent); virtual;
    destructor Free; virtual;
  end;

implementation

uses
  Veridian,
  AplStr,
  GrDrv8;

procedure ScrollButtonClick(ASender: PObject; var AEvent: TMouseEvent); far;
var
  parentView: PView;
  scrollBar: PScrollBar;
  rect: TRect;
  newPos: longint;
begin
  with PButton(ASender)^ do begin
    scrollBar := PScrollBar(Parent);
    if tag = 0 then
      scrollBar^.ScrollByPixels(-scrollbar^.Increment)
    else
      scrollBar^.ScrollByPixels(scrollbar^.Increment);
  end;
end;

procedure ViewVertScrollBarChanged(ASender: PObject; AEvent: TScrollEvent); far;
var
  par: PView;
  rect: TRect;
begin
  if not VeridianApp^.Settings.UpdateScrollContents then
    exit;
  with PScrollBar(ASender)^ do begin
    par := PView(Parent);
    par^.ScrollY := AEvent.CurrentPos;
    par^.BeginDrawing;
    par^.GetScreenBounds(rect);
    par^.PaintRegion(rect, PScrollBar(ASender));
    par^.EndDrawing;
  end;
end;

procedure ViewHorzScrollBarChanged(ASender: PObject; AEvent: TScrollEvent); far;
var
  par: PView;
begin
  with PScrollBar(ASender)^ do begin
  end;
end;

procedure TViewClosingEvent.Init;
begin
  inherited Init;
  CanClose := true;
end;

procedure TScrollSlider.Init;
begin
  inherited Init;
  Clickable := false;
  DownX := 0;
  DownY := 0;
end;

constructor TScrollBar.CreateParent(const AId: string; AParent: PControl; AOrientation: TScrollOrientation);
begin
  inherited CreateParent(AId, AParent);
  Orientation := AOrientation;
end;

procedure TScrollBar.Init;
begin
  inherited Init;
  Min := 0;
  Max := 0;
  OnCurrentPosChanged := nil;
  CurrentPos := 0;
  BorderStyle := bsNone;
  BackColor := VeridianApp^.Colors.ScrollBarBack;
  IncButton := New(PButton, CreateParent('IncButton', @self));
  with IncButton^ do begin
    HorzAlign := haCenter;
    VertAlign := vaCenter;
    CanFocus := false;
    Tag := 1;
    BorderStyle := bsRaised;
    OnMouseClick := @ScrollButtonClick;
  end;
  DecButton := New(PButton, CreateParent('DecButton', @self));
  with DecButton^ do begin
    HorzAlign := haCenter;
    VertAlign := vaCenter;
    CanFocus := false;
    Tag := 0;
    BorderStyle := bsRaised;
    OnMouseClick := @ScrollButtonClick;
  end;
  Slider := New(PScrollSlider, CreateParent('Slider', @self));
  with Slider^ do begin
    CanFocus := false;
  end;
  Size := 16;
  Increment := 10;
  PageIncrement := 100;
  if Graph^.Mode^.Width <= 320 then
    Size := 11;
end;

procedure TScrollBar.GetSliderRect(var ARect: TRect);
var
  pos: longint;
  scrollSize, posOffset, sizeAdjust: integer;
begin
  sizeAdjust := 3 * Size + 2 * BorderWidth;
  posOffset := Size - 2 * BorderWidth;
  if Orientation = soHorizontal then begin
    scrollSize := Width - sizeAdjust;
    if Max = 0 then
      pos := posOffset
    else
      pos := Round((CurrentPos / Max) * scrollSize) + posOffset;
    ARect.CreateDims(pos, 0, Size, Size)
  end
  else begin
    scrollSize := Height - sizeAdjust;
    if Max = 0 then
      pos := posOffset
    else
      pos := Round((CurrentPos / Max) * scrollSize) + posOffset;
    ARect.CreateDims(BorderWidth, pos, Size, Size)
  end;
end;

procedure TScrollBar.Layout;
var
  rect: TRect;
begin
  inherited Layout;
  case Orientation of
    soVertical: begin
      DecButton^.SetBounds(0, 0, Size, Size);
      IncButton^.SetBounds(0, Height - Size, Size, Size);
      if not Assigned(IncButton^.Caption) then
        IncButton^.SetCaption(#31);
      if not Assigned(DecButton^.Caption) then
        DecButton^.SetCaption(#30);
    end;
    soHorizontal: begin
      DecButton^.SetBounds(0, 0, Size, Size);
      IncButton^.SetBounds(Width - Size, 0, Size, Size);
      if not Assigned(IncButton^.Caption) then
        IncButton^.SetCaption(#16);
      if not Assigned(DecButton^.Caption) then
        DecButton^.SetCaption(#17);
    end;
  end;
  GetSliderRect(rect);
  Slider^.SetBoundsRect(rect);
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
  ParentView := nil;
  Font := Desktop^.Font;
end;

procedure TTitleBar.Paint;
var
  rect: TRect;
  fore, back: longint;
begin
  if not Assigned(ParentView) then
    exit;
  if not IsVisible then
    exit;
  fore := ForeColor;
  back := BackColor;
  if ParentView^.Active then begin
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
  if AEvent.NewMouseState.ButtonState = [bsLeft] then begin
    ParentView^.BringToFront;
    ParentView^.Activate;
  end;
end;

constructor TView.CreateTitle(const AId, ATitle: string; AParent: PControl);
begin
  inherited CreateParent(AId, AParent);
  SetTitle(ATitle);
end;

procedure TView.Init;
begin
  inherited Init;
  ForeColor := VeridianApp^.Colors.View;
  BackColor := VeridianApp^.Colors.ViewBack;
  BorderStyle := bsNone;
  Font := Desktop^.Font;
  Title := nil;
  TitleBar := New(PTitleBar, CreateParent('TitleBar', @self));
  TitleBar^.ParentView := @self;
  ViewState := vsNormal;
  HorzScrollBar := New(PScrollBar, CreateParent('HorzScrollBar', @self, soHorizontal));
  VertScrollBar := New(PScrollBar, CreateParent('VertScrollBar', @self, soVertical));
  VertScrollBar^.OnCurrentPosChanged := @ViewVertScrollBarChanged;
  HorzScrollBar^.OnCurrentPosChanged := @ViewHorzScrollBarChanged;
  ScrollType := scNone;
  AutoSize := false;
  ScrollX := 0;
  ScrollY := 0;
  OnClosing := nil;
  OnClosed := nil;
end;

function TView.GetAutoWidth: longint;
begin
end;

function TView.GetAutoHeight: longint;
begin
end;

function TView.TitleVisible: boolean;
begin
  TitleVisible := TitleBar^.Visible;
end;

procedure TView.SetTitleVisible(AVisible: boolean);
begin
  TitleBar^.Visible := AVisible;
  Draw;
end;

procedure TView.Close;
var
  closingEvent: TViewClosingEvent;
  closedEvent: TEvent;
begin
  closingEvent.Init;
  Invoke(OnClosing, closingEvent);
  if not closingEvent.CanClose then
    exit;
  closedEvent.Init;
  Invoke(OnClosed, closedEvent);
end;

procedure TView.Activate;
var
  activeView: PView;
begin
  activeView := VeridianApp^.ActiveView;
  if Assigned(activeView) then begin
    VeridianApp^.ActiveView := nil;
    activeView^.TitleBar^.Draw;
  end;
  VeridianApp^.ActiveView := @self;
  BringToFront;
  VeridianApp^.ActiveView^.TitleBar^.Draw;
end;

procedure TView.SetTitle(const ATitle: string);
begin
  TString.AssignString(Title, ATitle);
  TitleBar^.Draw;
end;

procedure TView.Deactivate;
begin
  if VeridianApp^.ActiveView = @self then begin
    VeridianApp^.ActiveView := nil;
    Draw;
  end;
end;

destructor TView.Free;
begin
  TString.Free(Title);
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

procedure TView.GetContentScreenBounds(var ARect: TRect);
var
  rect: TRect;
  titleHeight: integer;
begin
  GetScreenBounds(rect);
  rect.Translate(BorderWidth, BorderWidth);
  rect.Grow(-2 * BorderWidth, -2 * BorderWidth);
  titleHeight := Font^.Height + 2 * TitleBar^.Margins.Height + BorderWidth;
  if not TitleBar^.Visible then
    titleHeight := 0;
  case ScrollType of
    scNone:
      ARect.CreateDims(rect.X, rect.Y + titleHeight, rect.Width, rect.Height - titleHeight);
    scVertical:
      ARect.CreateDims(rect.X, rect.Y + titleHeight, rect.Width - VertScrollBar^.Size + 1,
        rect.Height - titleHeight);
    scHorizontal:
      ARect.CreateDims(rect.X, rect.Y + titleHeight, rect.Width, rect.Height - titleHeight - HorzScrollBar^.Size + 1);
    scBoth:
      ARect.CreateDims(rect.X, rect.Y + titleHeight, rect.Width - VertScrollBar^.Size + 1,
        rect.Height - titleHeight - HorzScrollBar^.Size + 1);
  end;
end;

function TView.Active: boolean;
begin
  Active := VeridianApp^.ActiveView = @self;
end;

procedure TView.GetContentBounds(var ARect: TRect);
var
  rect: TRect;
  titleHeight: integer;
begin
  GetClientBounds(rect);
  titleHeight := Font^.Height + 2 * TitleBar^.Margins.Height + BorderWidth;
  if not TitleBar^.Visible then
    titleHeight := 0;
  case ScrollType of
    scNone:
      ARect.CreateDims(rect.X, rect.Y + titleHeight, rect.Width, rect.Height - titleHeight);
    scVertical:
      ARect.CreateDims(rect.X, rect.Y + titleHeight, rect.Width - VertScrollBar^.Size + 1,
        rect.Height - titleHeight);
    scHorizontal:
      ARect.CreateDims(rect.X, rect.Y + titleHeight, rect.Width, rect.Height - titleHeight - HorzScrollBar^.Size + 1);
    scBoth:
      ARect.CreateDims(rect.X, rect.Y + titleHeight, rect.Width - VertScrollBar^.Size + 1,
        rect.Height - titleHeight - HorzScrollBar^.Size + 1);
  end;
end;

procedure TView.Layout;
var
  rect: TRect;
  barWidth: integer;
  barHeight: integer;
  titleHeight: integer;
begin
  inherited Layout;
  GetClientBounds(rect);
  titleHeight := Font^.Height + 2 * TitleBar^.Margins.Height + 2 * BorderWidth;
  if not TitleBar^.Visible then
    titleHeight := 0;
  TitleBar^.SetBounds(rect.X, rect.Y, rect.Width, titleHeight);
  if not Assigned(TitleBar^.Caption) then
    TitleBar^.Caption := TString.Copy(Title);
  TitleBar^.VertAlign := vaCenter;
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
  GetBounds(rect);
  if not TitleBar^.IsVisible then
   titleHeight := 0;
  barWidth := VertScrollBar^.Size;
  barHeight := rect.Height - titleHeight;
  if HorzScrollBar^.Visible then
    Dec(barHeight, HorzScrollBar^.Size);
  VertScrollBar^.SetBounds(rect.Width - barWidth - BorderWidth, titleHeight + BorderWidth,
    barWidth, barHeight - BorderWidth);
  barWidth := rect.Width;
  barHeight := HorzScrollBar^.Size;
  if VertScrollBar^.Visible then
    Dec(barWidth, VertScrollBar^.Size);
  HorzScrollBar^.SetBounds(BorderWidth, Height - barHeight - BorderWidth, barWidth - BorderWidth, barHeight);
end;

procedure TWindow.Init;
begin
  inherited Init;
  BorderStyle := bsRaised;
  BackColor := VeridianApp^.Colors.WindowBack;
  ForeColor := VeridianApp^.Colors.Window;
end;

procedure TWindow.Paint;
var
  oldBorderColor: byte;
  oldBorderStyle: TBorderStyle;
  rect: TRect;
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
  GetScreenBounds(rect);
  Graph^.SetForeColor(ShadowColor);
  Graph^.State^.Font := VeridianApp^.Fonts^.GetItemById('Symbol');
  Graph^.DrawText(rect.Right - Font^.TextWidth(#5) - 4,
    rect.Bottom - Font^.TextWidth(#5) - 6, #5);
end;

procedure TWindow.MouseDown(var AEvent: TMouseEvent);
begin
  inherited MouseDown(AEvent);
  if AEvent.NewMouseState.ButtonState = [bsLeft] then begin
    BringToFront;
    Activate;
  end;
end;

destructor TWindow.Free;
begin
  inherited Free;
end;

procedure TScrollSlider.MouseDown(var AEvent: TMouseEvent);
begin
{  VeridianApp^.CurrentScrollSlider := @self;}
  DownX := AEvent.X;
  DownY := AEvent.Y;
end;

procedure TScrollSlider.MouseUp(var AEvent: TMouseEvent);
begin
end;

procedure TScrollSlider.MouseMove(var AEvent: TMouseEvent);
begin
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
    newPos := CurrentPos - PageIncrement;
    newPos := ClampL(newPos, Min, Max);
    SetCurrentPos(newPos);
  end
  else if mouseCoord > sliderCoord + Slider^.Height  then begin
    newPos := CurrentPos + PageIncrement;
    newPos := ClampL(newPos, Min, Max);
    SetCurrentPos(newPos);
  end;
end;

procedure TScrollBar.SetCurrentPos(const APos: longint);
var
  sizeAdjust: integer;
  scrollSize: integer;
  parentView: PView;
  rect: TRect;
  newCoord: integer;
begin
  if CurrentPos = APos then
    exit;
  parentView := PView(Parent);
  CurrentPos := APos;
  parentView^.ScrollY := APos;
  parentView^.BeginDrawing;
  parentView^.GetContentScreenBounds(rect);
  parentView^.PaintRegion(rect, @self);
  parentView^.EndDrawing;

  sizeAdjust := 3 * Size - 3 * BorderWidth;
  if Orientation = soHorizontal then begin
    scrollSize := Width - sizeAdjust;
    newCoord := Round(CurrentPos / Max * scrollSize) - 2 * BorderWidth + Size;
    Slider^.X := newCoord;
    DrawSlider;
  end
  else begin
    scrollSize := Height - sizeAdjust;
    newCoord := Round(CurrentPos / Max * scrollSize) - 2 * BorderWidth + Size;
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
  pos := ClampL(CurrentPos + ADelta, Min, Max);
  SetCurrentPos(pos);
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
    SetCurrentPos(pos)
  else begin
    CurrentPos := pos;
    DrawSlider;
  end;
end;

procedure TScrollSlider.ProcessMouseMove(var AEvent: TMouseEvent);
var
  delta: integer;
  par: PScrollBar;
  rect: TRect;
begin
  par := PScrollBar(Parent);
{  if VeridianApp^.CurrentScrollSlider <> @self then
    exit;}
  if par^.Max - par^.Min <= 0 then
    exit;
  GetScreenBounds(rect);
  if par^.Orientation = soHorizontal then
    delta := AEvent.NewMouseState.X - rect.X - DownX
  else
    delta := AEvent.NewMouseState.Y - rect.Y - DownY;
  par^.ScrollBySlider(delta);
end;

procedure TView.ScrollVert(ADelta: integer);
begin
  VertScrollBar^.ScrollByPixels(ADelta);
end;

procedure TView.ScrollHorz(ADelta: integer);
begin
  HorzScrollBar^.ScrollByPixels(ADelta);
end;

end.