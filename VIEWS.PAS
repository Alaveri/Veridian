{$I COMPILER.INC}
unit Views;

interface

uses
  AplObj,
  AplTypes,
  Lists,
  Errors,
  GraphApp,
  Drawing,
  Common,
  MouseDrv,
  Controls;

const
  ScrollbarSize = 16;

type
  PView = ^TView;
  PWindow = ^TWindow;
  PScrollBar = ^TScrollbar;
  PTitlebar = ^TTitlebar;
  PScrollSlider = ^TScrollSlider;

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

  TTitlebar = object(TTextControl)
  private
  public
    ParentView: PView;
    ActiveForeColor: byte;
    ActiveBackColor: byte;
    procedure Init; virtual;
    procedure Paint; virtual;
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

  TScrollbar = object(TPanel)
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
    procedure SetupControls; virtual;
    procedure MouseDown(var AEvent: TMouseEvent); virtual;
  end;

  TView = object(TPanel)
  private
  public
    Title: PChar;
    Active: boolean;
    Titlebar: PTitlebar;
    ScrollType: TViewScrollType;
    HorzScrollBar: PScrollbar;
    VertScrollBar: PScrollbar;
    AutoSize: boolean;
    ScrollX: longint;
    ScrollY: longint;
    procedure Activate;
    procedure Deactivate;
    procedure Init; virtual;
    procedure Maximize; virtual;
    procedure SetupControls; virtual;
    procedure SetTitle(const ATitle: string);
    procedure GetContentScreenBounds(var ARect: TRect);
    procedure GetContentBounds(var ARect: TRect);
    function GetAutoWidth: longint; virtual;
    function GetAutoHeight: longint; virtual;
    procedure ScrollVert(ADelta: integer); virtual;
    procedure ScrollHorz(ADelta: integer); virtual;
    destructor Free; virtual;
  end;

  TWindow = object(TView)
  private
  public
    procedure Init; virtual;
    destructor Free; virtual;
  end;

implementation

uses
  Veridian,
  StrUtils,
  GraphDrv,
  GrDrv8,
  Desk;

procedure ScrollButtonClick(ASender: PObject; var AEvent: TMouseEvent); far;
var
  parentView: PView;
  scrollBar: PScrollbar;
  rect: TRect;
  newPos: longint;
begin
  with PButton(ASender)^ do begin
    scrollBar := PScrollbar(Parent);
    if tag = 0 then
      scrollBar^.ScrollByPixels(-scrollbar^.Increment)
    else
      scrollBar^.ScrollByPixels(scrollbar^.Increment);
  end;
end;

procedure ViewVertScrollbarChanged(ASender: PObject; AEvent: TScrollEvent); far;
var
  par: PView;
  rect: TRect;
begin
  if VeridianApp^.Settings.UpdateScrollContents then
    exit;
  with PScrollBar(ASender)^ do begin
    par := PView(Parent);
    par^.ScrollY := AEvent.CurrentPos;
    par^.StartDrawing;
    par^.GetScreenBounds(rect);
    par^.PaintRegion(rect, PScrollBar(ASender));
    par^.EndDrawing;
  end;
end;

procedure ViewHorzScrollbarChanged(ASender: PObject; AEvent: TScrollEvent); far;
var
  par: PView;
begin
  with PScrollBar(ASender)^ do begin
  end;
end;

procedure TScrollSlider.Init;
begin
  inherited Init;
  CanFocus := false;
  Clickable := false;
  DownX := 0;
  DownY := 0;
end;

constructor TScrollbar.CreateParent(const AId: string; AParent: PControl; AOrientation: TScrollOrientation);
begin
  inherited CreateParent(AId, AParent);
  Orientation := AOrientation;
end;

procedure TScrollbar.Init;
begin
  inherited Init;
  Min := 0;
  Max := 0;
  OnCurrentPosChanged := nil;
  CurrentPos := 0;
  BorderStyle := bsSingle;
  BackColor := Desktop^.Colors^.ScrollBack;
  IncButton := New(PButton, CreateParent('IncButton', -1, @self));
  with IncButton^ do begin
    TextAlign := haCenter;
    VertAlign := vaCenter;
    CanFocus := false;
    Tag := 1;
    OnMouseClick := @ScrollButtonClick;
  end;
  DecButton := New(PButton, CreateParent('DecButton', -1, @self));
  with DecButton^ do begin
    TextAlign := haCenter;
    VertAlign := vaCenter;
    CanFocus := false;
    Tag := 0;
    OnMouseClick := @ScrollButtonClick;
  end;
  Slider := New(PScrollSlider, CreateParent('Slider', -1, @self));
  with Slider^ do begin
    CanFocus := false;
  end;
  Size := 16;
  Increment := 10;
  PageIncrement := 100;
  if Graph^.Mode^.Width <= 320 then
    Size := 11;
end;

procedure TScrollbar.GetSliderRect(var ARect: TRect);
var
  pos: longint;
  scrollSize, posOffset, sizeAdjust: integer;
begin
  sizeAdjust := 3 * Size + 3 * BorderWidth;
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
    ARect.CreateDims(0, pos, Size, Size)
  end;
end;

procedure TScrollbar.SetupControls;
var
  rect: TRect;
begin
  inherited SetupControls;
  case Orientation of
    soVertical: begin
      DecButton^.SetBounds(0, -1, Size, Size);
      IncButton^.SetBounds(0, Height - Size, Size, Size);
      if not Assigned(IncButton^.Text) then
        IncButton^.SetText(#31);
      if not Assigned(DecButton^.Text) then
        DecButton^.SetText(#30);
    end;
    soHorizontal: begin
      DecButton^.SetBounds(-1, 0, Size, Size);
      IncButton^.SetBounds(Width - Size, 0, Size, Size);
      if not Assigned(IncButton^.Text) then
        IncButton^.SetText(#16);
      if not Assigned(DecButton^.Text) then
        DecButton^.SetText(#17);
    end;
  end;
  GetSliderRect(rect);
  Slider^.SetBoundsRect(rect);
end;

procedure TTitlebar.Init;
begin
  inherited Init;
  BorderColor := Desktop^.Colors^.Border;
  BorderStyle := bsNone;
  ForeColor := Desktop^.Colors^.WindowTitle;
  BackColor := Desktop^.Colors^.WindowTitleBack;
  ActiveForeColor := Desktop^.Colors^.WindowActiveTitle;
  ActiveBackColor := Desktop^.Colors^.WindowActiveTitleBack;
  BorderStyle := bsNone;
  VertAlign := vaCenter;
  TextAlign := haCenter;
  ParentView := nil;
  Font := Desktop^.Font;
  Margin := 1;
end;

procedure TTitlebar.Paint;
var
  rect: TRect;
  fore, back: longint;
begin
  if ParentView = nil then
    exit;
  if not GetVisible then
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
  Graph^.SetForeColor(BorderColor);
  Graph^.HLine(rect.X, rect.Bottom, rect.Width);
end;

procedure TView.Init;
begin
  inherited Init;
  CanFocus := false;
  IsMouseOver := false;
  ForeColor := Desktop^.Colors^.Window;
  BackColor := Desktop^.Colors^.WindowBack;
  BorderStyle := bsSingle;
  Grouped := false;
  Font := Desktop^.Font;
  Title := nil;
  Titlebar := New(PTitlebar, CreateParent('Titlebar', @self));
  Titlebar^.ParentView := @self;
  Active := false;
  HorzScrollbar := New(PScrollbar, CreateParent('HorzScrollBar', @self, soHorizontal));
  VertScrollbar := New(PScrollbar, CreateParent('VertScrollBar', @self, soVertical));
  VertScrollBar^.OnCurrentPosChanged := @ViewVertScrollbarChanged;
  HorzScrollBar^.OnCurrentPosChanged := @ViewHorzScrollbarChanged;
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

procedure TView.Activate;
begin
  Active := true;
  if Assigned(Desktop^.ActiveView) then begin
    Desktop^.ActiveView^.Active := false;
    Desktop^.ActiveView^.Titlebar^.Draw;
  end;
  Desktop^.ActiveView := @self;
  Desktop^.ActiveView^.Titlebar^.Draw;
end;

procedure TView.SetTitle(const ATitle: string);
begin
  TString.Assign(Title, ATitle);
  TitleBar^.Draw;
end;

procedure TView.Deactivate;
begin
  Active := false;
  if Desktop^.ActiveView = @self then
    Desktop^.ActiveView := nil;
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
  viewRect.CreateDims(0, 0, Desktop^.Width, Desktop^.Height);
  if Desktop^.MenuBar^.GetVisible then begin
    Dec(viewRect.Height, Desktop^.Menubar^.Height);
    Inc(viewRect.Y, Desktop^.Menubar^.Height);
  end;
  if Desktop^.StatusBar^.GetVisible then
    Dec(viewRect.Height, Desktop^.Statusbar^.Height - 3);
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
  titleHeight := Font^.Height + 2 * Titlebar^.Margin + 1;
  if not Titlebar^.Visible then
    titleHeight := 0;
  case ScrollType of
    scNone:
      ARect.CreateDims(rect.X, rect.Y + titleHeight, rect.Width, rect.Height - titleHeight);
    scVertical:
      ARect.CreateDims(rect.X, rect.Y + titleHeight, rect.Width - VertScrollbar^.Size + 1,
        rect.Height - titleHeight);
    scHorizontal:
      ARect.CreateDims(rect.X, rect.Y + titleHeight, rect.Width, rect.Height - titleHeight - HorzScrollbar^.Size + 1);
    scBoth:
      ARect.CreateDims(rect.X, rect.Y + titleHeight, rect.Width - VertScrollbar^.Size + 1,
        rect.Height - titleHeight - HorzScrollbar^.Size + 1);
  end;
end;

procedure TView.GetContentBounds(var ARect: TRect);
var
  rect: TRect;
  titleHeight: integer;
begin
  GetClientRect(rect);
  titleHeight := Font^.Height + 2 * Titlebar^.Margin + 1;
  if not Titlebar^.Visible then
    titleHeight := 0;
  case ScrollType of
    scNone:
      ARect.CreateDims(rect.X, rect.Y + titleHeight, rect.Width, rect.Height - titleHeight);
    scVertical:
      ARect.CreateDims(rect.X, rect.Y + titleHeight, rect.Width - VertScrollbar^.Size + 1,
        rect.Height - titleHeight);
    scHorizontal:
      ARect.CreateDims(rect.X, rect.Y + titleHeight, rect.Width, rect.Height - titleHeight - HorzScrollbar^.Size + 1);
    scBoth:
      ARect.CreateDims(rect.X, rect.Y + titleHeight, rect.Width - VertScrollbar^.Size + 1,
        rect.Height - titleHeight - HorzScrollbar^.Size + 1);
  end;
end;

procedure TView.SetupControls;
var
  rect: TRect;
  barWidth: integer;
  barHeight: integer;
  titleHeight: integer;
begin
  inherited SetupControls;
  GetClientRect(rect);
  titleHeight := Font^.Height + 2 * Titlebar^.Margin + 1;
  if not Titlebar^.Visible then
    titleHeight := 0;
  Titlebar^.SetBounds(rect.X, rect.Y, rect.Width, titleHeight);
  if not Assigned(Titlebar^.Text) then
    Titlebar^.Text := TString.Copy(Title);
  Titlebar^.VertAlign := vaCenter;
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
  titleHeight := Titlebar^.Height;
  if not TitleBar^.GetVisible then
    titleHeight := 0;
  barWidth := VertScrollbar^.Size;
  barHeight := rect.Height - titleHeight - 1;
  if HorzScrollbar^.Visible then
    Dec(barHeight, HorzScrollbar^.Size);
  VertScrollBar^.SetBounds(rect.Width - barWidth, titleHeight + 1, barWidth, barHeight);
  barWidth := rect.Width - 1;
  barHeight := HorzScrollbar^.Size;
  if VertScrollbar^.Visible then
    Dec(barWidth, VertScrollbar^.Size);
  HorzScrollBar^.SetBounds(1, Height - barHeight, barWidth, barHeight);
end;

procedure TWindow.Init;
begin
  inherited Init;
end;

destructor TWindow.Free;
begin
  inherited Free;
end;

procedure TScrollSlider.MouseDown(var AEvent: TMouseEvent);
begin
  VeridianApp^.CurrentScrollSlider := @self;
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
    newPos := EnsureLongRange(newPos, Min, Max);
    SetCurrentPos(newPos);
  end
  else if mouseCoord > sliderCoord + Slider^.Height  then begin
    newPos := CurrentPos + PageIncrement;
    newPos := EnsureLongRange(newPos, Min, Max);
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
  parentView^.StartDrawing;
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
  StartDrawingEx(false);
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

procedure TScrollbar.ScrollByPixels(ADelta: integer);
var
  pos: longint;
begin
  pos := EnsureLongRange(CurrentPos + ADelta, Min, Max);
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
    slider^.X := EnsureRange(slider^.X + ADelta, minCoord, maxCoord);
    scrollSize := Width - 3 * Size + 3 * BorderWidth;
    pos := Round(((slider^.X - Size + 2 * BorderWidth) / scrollSize) * Max);
  end
  else begin
    maxCoord := Height - 2 * Size + BorderWidth;
    slider^.Y := EnsureRange(slider^.Y + ADelta, minCoord, maxCoord);
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
  par := PScrollbar(Parent);
  if VeridianApp^.CurrentScrollSlider <> @self then
    exit;
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