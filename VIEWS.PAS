{$I COMPILER.INC}
unit Views;

interface

uses
  AplObj,
  AplTypes,
  Lists,
  Strings,
  Drawing,
  Controls;

type
  PScrollbar = ^TScrollbar;
  PView = ^TView;
  PWindow = ^TWindow;
  PScrollSlider = ^TScrollSlider;

  TTitleStyle = (
    tsAutoSize,
    tsStretch
  );

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

  TScrollSlider = object(TButton)
  private
    FDownX, FDownY: integer;
  public
    procedure Init; virtual;
    procedure Layout; virtual;
    procedure Paint; virtual;
    procedure DragEnd(var AEvent: TMouseEvent); virtual;
    procedure MouseDown(var AEvent: TMouseEvent); virtual;
  end;

  TScrollbar = object(TPanel)
  private
    procedure GetSliderRect(var ARect: TRect);
    procedure DrawSlider;
    procedure ScrollBySlider(ADelta: integer);
    procedure ScrollByPixels(ADelta: integer);
  public
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
    procedure Init; virtual;
    procedure Layout; virtual;
    procedure Paint; virtual;
    procedure MouseDown(var AEvent: TMouseEvent); virtual;
    procedure SetCurrentPos(const APos: word);
    procedure PositionChanged(var AEvent: TScrollEvent); virtual;
  end;

  TView = object(TPanel)
  private
  public
    ScrollType: TViewScrollType;
    VertScrollbar: PScrollbar;
    HorzScrollbar: PScrollbar;
    Active: boolean;
    TitleColor: byte;
    TitleBackColor: byte;
    TitleActiveColor: byte;
    TitleActiveBackColor: byte;
    TitleMargins: TSpacing;
    BorderActiveColor: byte;
    BorderActiveBackColor: byte;
    AutoSize: boolean;
    Title: PChar;
    TitleVisible: boolean;
    TitleAlign: THorzAlign;
    TitleStyle: TTitleStyle;
    ScrollX: integer;
    ScrollY: integer;
    function GetTitle: string;
    constructor CreateTitle(const AId, ATitle: string; AParent: PControl);
    procedure SetTitle(const ATitle: string);
    procedure SetTitleVisible(AVisible: boolean);
    procedure SetTitleAlign(AAlign: THorzAlign);
    procedure SetTitleStyle(AStyle: TTitleStyle);
    procedure SetActive(AActive: boolean);
    procedure Activate;
    procedure Deactivate;
    procedure PaintTitle; virtual;
    procedure DrawTitle; virtual;
    procedure GetClientBounds(var ARect: TRect); virtual;
    procedure GetClientScreenBounds(var ARect: TRect); virtual;
    procedure Init; virtual;
    procedure Layout; virtual;
    procedure Paint; virtual;
  end;

  TWindow = object(TView)
  private
  public
    procedure Init; virtual;
    procedure Layout; virtual;
    procedure Paint; virtual;
  end;

implementation

uses
  AplMath,
  AplStr,
  Veridian;

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

procedure TScrollSlider.Init;
begin
  inherited Init;
  FDownX := 0;
  FDownY := 0;
end;

procedure TScrollSlider.Layout;
begin
  inherited Layout;
end;

procedure TScrollSlider.Paint;
begin
  inherited Paint;
end;

procedure TScrollSlider.DragEnd(var AEvent: TMouseEvent);
var
  scrollEvent: TScrollEvent;
  parentScrollbar: PScrollbar;
begin
  if Assigned(parent) then begin
    parentScrollbar := PScrollbar(Parent);
    scrollEvent.Create;
    scrollEvent.CurrentPos := parentScrollbar^.CurrentPos;
    parentScrollBar^.PositionChanged(scrollEvent);
  end;
end;

procedure TScrollSlider.MouseDown(var AEvent: TMouseEvent);
begin
  VeridianApp^.DragControl := @self;
  FDownX := AEvent.X;
  FDownY := AEvent.Y;
end;

procedure TScrollbar.Init;
begin
  inherited Init;
  IncButton := New(PButton, CreateAction('', nil, @self));
  DecButton := New(PButton, CreateAction('', nil, @self));
  Slider := New(PScrollSlider, CreateAction('', nil, @self));
  with IncButton^ do begin
    HorzAlign := haCenter;
    VertAlign := vaCenter;
    Tag := 1;
    OnMouseClick := @ScrollButtonClick;
  end;
  with DecButton^ do begin
    HorzAlign := haCenter;
    VertAlign := vaCenter;
    Tag := 0;
    OnMouseClick := @ScrollButtonClick;
  end;
  Min := 0;
  Max := 0;
  Increment := 1;
  PageIncrement := 10;
  CurrentPos := 0;
  Orientation := soVertical;
  OnCurrentPosChanged := nil;
end;

procedure TScrollbar.Layout;
var
  rect: TRect;
begin
  inherited Layout;
  case Orientation of
    soVertical: begin
      DecButton^.SetBounds(0, 0, 1, 1);
      IncButton^.SetBounds(0, Height - 1, 1, 1);
      if not Assigned(IncButton^.Caption) then
        IncButton^.SetCaption(#31);
      if not Assigned(DecButton^.Caption) then
        DecButton^.SetCaption(#30);
    end;
    soHorizontal: begin
      DecButton^.SetBounds(0, 0, 1, 1);
      IncButton^.SetBounds(Width - 1, 0, 1, 1);
      if not Assigned(IncButton^.Caption) then
        IncButton^.SetCaption(#16);
      if not Assigned(DecButton^.Caption) then
        DecButton^.SetCaption(#17);
    end;
  end;
  GetSliderRect(rect);
  Slider^.SetBoundsRect(rect);
end;

procedure TScrollbar.GetSliderRect(var ARect: TRect);
var
  pos: integer;
  scrollSize, posOffset, sizeAdjust: integer;
begin
  sizeAdjust := 3;
  posOffset := 1;
  if Orientation = soHorizontal then begin
    scrollSize := Width - sizeAdjust;
    if Max = 0 then
      pos := posOffset
    else
      pos := Round((CurrentPos / Max) * scrollSize) + posOffset;
    ARect.CreateDims(pos, 0, 1, 1)
  end
  else begin
    scrollSize := Height - sizeAdjust;
    if Max = 0 then
      pos := posOffset
    else
      pos := Round((CurrentPos / Max) * scrollSize) + posOffset;
    ARect.CreateDims(0, pos, 1, 1)
  end;
end;

procedure TScrollbar.DrawSlider;
{var
  mouseRect,rect: TRect;
  value: integer;}
begin
{  GetScreenBounds(rect);
  BeginDrawing;
  Text^.SetBackColor(BackColor);
  if Orientation = soHorizontal then begin
    value := slider^.X;
    rect.Height := Slider^.X - 1;
    Text^.FillRect(rect, ' ');
    GetScreenBounds(rect);
    rect.Width := rect.Width - value - 2;
    Text^.FillRect(rect, ' ');
  end
  else begin
    value := slider^.Y;
    GetScreenBounds(rect);
    rect.Height := Slider^.Y - 1;
    Text^.FillRect(rect, ' ');
    GetScreenBounds(rect);
    rect.Height := rect.Height - value - 2;
    Text^.FillRect(rect, ' ');
  end;
  Slider^.DrawSelf;
  EndDrawing;}
end;

procedure TScrollBar.ScrollBySlider(ADelta: integer);
var
  scrollSize: integer;
  minCoord, maxCoord: integer;
  pos: integer;
begin
  minCoord := 1;
  if Orientation = soHorizontal then begin
    maxCoord := Width - 1;
    slider^.X := Clamp(slider^.X + ADelta, minCoord, maxCoord);
    scrollSize := Width - 3;
    pos := Round(((slider^.X - 1) / scrollSize) * Max);
  end
  else begin
    maxCoord := Height - 1;
    slider^.Y := Clamp(slider^.Y + ADelta, minCoord, maxCoord);
    scrollSize := Height - 3;
    pos := Round(((slider^.Y - 1) / scrollSize) * Max);
  end;
  SetCurrentPos(pos);
end;

procedure TScrollBar.SetCurrentPos(const APos: word);
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
  parentView^.GetClientScreenBounds(rect);
  parentView^.PaintRegion(rect, @self);
  parentView^.EndDrawing;

  sizeAdjust := 3;
  if Orientation = soHorizontal then begin
    scrollSize := Width - sizeAdjust;
    newCoord := Round(CurrentPos / Max * scrollSize) + 1;
    Slider^.X := newCoord;
    DrawSlider;
  end
  else begin
    scrollSize := Height - sizeAdjust;
    newCoord := Round(CurrentPos / Max * scrollSize) - 1;
    Slider^.Y := newCoord;
    DrawSlider;
  end;
end;

procedure TScrollbar.MouseDown(var AEvent: TMouseEvent);
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

procedure TScrollbar.PositionChanged(var AEvent: TScrollEvent);
var
  parentView: PView;
  rect: TRect;
begin
  if Assigned(Parent) then begin
    parentView := PView(Parent);
    parentView^.ScrollY := CurrentPos;
    parentView^.BeginDrawing;
    parentView^.GetScreenBounds(rect);
    parentView^.PaintRegion(rect, @self);
    parentView^.EndDrawing;
  end;
  if Assigned(OnCurrentPosChanged) then
    TEventProc(OnCurrentPosChanged)(@self, AEvent);
end;

procedure TScrollbar.ScrollByPixels(ADelta: integer);
var
  pos: integer;
begin
  pos := ClampL(CurrentPos + ADelta, Min, Max);
  SetCurrentPos(pos);
end;

procedure TScrollbar.Paint;
begin
  inherited Paint;
end;

constructor TView.CreateTitle(const AId, ATitle: string; AParent: PControl);
begin
  inherited CreateParent(AId, AParent);
  TString.AssignString(Title, ATitle);
end;

procedure TView.Init;
begin
  inherited Init;
  VertScrollbar := New(PScrollbar, CreateParent('', @self));
  HorzScrollbar := New(PScrollbar, CreateParent('', @self));
  HorzScrollbar^.Visible := false;
  VertScrollbar^.Visible := false;
  ForeColor := VeridianApp^.Colors.Window;
  BackColor := VeridianApp^.Colors.WindowBack;
  BorderColor := VeridianApp^.Colors.WindowBorder;
  TitleColor := VeridianApp^.Colors.WindowTitle;
  TitleBackColor := VeridianApp^.Colors.WindowTitleBack;
  TitleActiveColor := VeridianApp^.Colors.WindowTitleActive;
  TitleActiveBackColor := VeridianApp^.Colors.WindowTitleActiveBack;
  BorderActiveColor := VeridianApp^.Colors.WindowBorderActive;
  Active := false;
  Title := nil;
  TitleVisible := true;
  TitleAlign := haLeft;
  TitleStyle := tsAutoSize;
  TitleMargins.CreateLeftRight(1, 1);
  AutoSize := false;
  BorderStyle := bsSingle;
  ScrollX := 0;
  ScrollY := 0;
end;

procedure TView.SetActive(AActive: boolean);
begin
  Active := AActive;
  DrawTitle;
end;

procedure TView.Activate;
begin
  SetActive(true);
  BringToFront;
end;

procedure TView.Deactivate;
begin
  SetActive(false);
end;

procedure TView.DrawTitle;
begin
  BeginDrawing;
  PaintTitle;
  EndDrawing;
end;

procedure TView.PaintTitle;
{var
  drawRect: TRect;
  rect: TRect;
  offset: byte;
  len: integer;
  lineStyle: TLineStyle;}
begin
{  if not Assigned(Title) then
    exit;
  if not TitleVisible then
    exit;
  drawRect.Create;
  GetScreenBounds(rect);
  Text^.SetBackColor(TitleBackColor);
  Text^.SetForeColor(TitleColor);
  if Active then begin
    Text^.SetBackColor(TitleActiveBackColor);
    Text^.SetForeColor(TitleActiveColor);
  end;
  len := StrLen(Title);
  case TitleStyle of
    tsAutoSize: begin
      drawRect.SetDims(rect.X + BorderWidth, rect.Y, len + TitleMargins.Left + TitleMargins.Right, 1);
      drawRect.Grow(2 * BorderWidth, 0);
    end;
    tsStretch: drawRect.CreateDims(rect.X + BorderWidth, rect.Y, rect.Width - 2 * BorderWidth, 1);
  end;

  case TitleAlign of
    haLeft: offset := 0;
    haCenter: offset := (Width - drawRect.Width) div 2;
    haRight: offset := drawRect.Width - len;
  end;

  drawRect.Translate(offset, 0);
  Text^.FillRect(drawRect, ' ');
  Text^.DrawText(drawRect.X + BorderWidth + TitleMargins.Left, drawRect.Y, StrPas(Title));
  Text^.SetForeColor(BorderColor);
  Text^.SetBackColor(BorderBackColor);
  if Active then begin
    Text^.SetForeColor(BorderActiveColor);
    Text^.SetBackColor(BorderActiveBackColor);
  end;
  if BorderStyle <> bsNone then begin
    lineStyle := lsSingle;
    if BorderStyle = bsDouble then
      lineStyle := lsDouble;
    Text^.DrawText(drawRect.X, drawRect.Y, LineChars[loHorizontal, lineStyle, lcEnd]);
    if TitleStyle = tsAutoSize then
      Inc(drawRect.X, len + TitleMargins.Right + TitleMargins.Left + 1)
    else
      drawRect.X := drawRect.Width;
    Text^.DrawText(drawRect.X, drawRect.Y, LineChars[loHorizontal, lineStyle, lcStart]);
  end;}
end;

procedure TView.SetTitle(const ATitle: string);
begin
  TString.AssignString(Title, ATitle);
  DrawTitle;
end;

function TView.GetTitle: string;
begin
  GetTitle := StrPas(Title);
end;

procedure TView.SetTitleVisible(AVisible: boolean);
begin
  TitleVisible := AVisible;
  DrawTitle;
end;

procedure TView.SetTitleAlign(AAlign: THorzAlign);
begin
  TitleAlign := AAlign;
  DrawTitle;
end;

procedure TView.SetTitleStyle(AStyle: TTitleStyle);
begin
  TitleStyle := AStyle;
end;

procedure TView.Layout;
begin
  inherited Layout;
end;

procedure TView.GetClientScreenBounds(var ARect: TRect);
var
  parentRect: TRect;
begin
  GetClientBounds(ARect);
  if not Assigned(Parent) then
    exit;
  Parent^.GetScreenBounds(parentRect);
  ARect.Translate(parentRect.X, parentRect.Y);
end;

procedure TView.GetClientBounds(var ARect: TRect);
begin
  inherited GetClientBounds(ARect);
end;

procedure TView.Paint;
{var
  rect: TRect;}
begin
{  GetScreenBounds(rect);
  Text^.SetForeColor(ForeColor);
  Text^.SetBackColor(BackColor);
  if DrawBackground then
    Text^.FillRect(rect, ' ');
  if BorderStyle <> bsNone then begin
    if Active then begin
      Text^.SetForeColor(BorderActiveColor);
      Text^.SetBackColor(BorderActiveBackColor);
    end
    else begin
      Text^.SetForeColor(BorderColor);
      Text^.SetBackColor(BorderBackColor);
    end;
    Text^.Rectangle(rect, BorderStyle);
  end;
  if Assigned(Title) and TitleVisible then
    PaintTitle;}
end;

procedure TWindow.Init;
begin
  inherited Init;
end;

procedure TWindow.Layout;
begin
  inherited Layout;
end;

procedure TWindow.Paint;
begin
  inherited Paint;
end;

end.