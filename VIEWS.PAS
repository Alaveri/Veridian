{$IFDEF debug}
  {$A-,B-,D+,F+,G-,I+,L+,N+,O+,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,F+,G-,I+,L-,N+,O+,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}
unit Views;

interface

uses
  Objects,
  Lists,
  GraphApp,
  Drawing,
  Controls;

const
  ScrollbarSize = 16;

type
  PView = ^TView;
  PWindow = ^TWindow;
  PScrollBar = ^TScrollbar;
  PTitlebar = ^TTitlebar;
  PViewContent = ^TViewContent;

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

  TViewContent = object(TPanel)
  private
  public
    procedure Init; virtual;
    procedure Paint; virtual;
  end;

  TScrollbar = object(TPanel)
  private
    MovePos: integer;
    procedure GetSliderRect(var ARect: TRect);
  public
    Size: integer;
    IncButton: PButton;
    DecButton: PButton;
    Slider: PButton;
    Min: longint;
    Max: longint;
    Pos: longint;
    Orientation: TScrollOrientation;
    constructor CreateParent(const AId: string; AParent: PControl; AOrientation: TScrollOrientation);
    procedure Init; virtual;
    procedure SetupControls; virtual;
  end;

  TView = object(TPanel)
  private
  public
    Title: PChar;
    Active: boolean;
    Titlebar: PTitlebar;
    Content: PViewContent;
    Closed: boolean;
    ScrollType: TViewScrollType;
    HorzScrollBar: PScrollbar;
    VertScrollBar: PScrollbar;
    procedure Activate;
    procedure Deactivate;
    procedure Init; virtual;
    procedure Close; virtual;
    procedure Maximize; virtual;
    procedure SetupControls; virtual;
    procedure SetTitle(const ATitle: string);
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
  GraphDrv,
  GrDrv8,
  StrUtils,
  Strings,
  Desk;

procedure ScrollSliderMouseDown(ASender: PObject; var AEvent: TMouseEvent); far;
var
  self: PButton;
begin
  self := PButton(ASender);
  with self^ do begin
{    Moving := true;}
  end;
end;

procedure ScrollSliderMouseUp(ASender: PObject; var AEvent: TMouseEvent); far;
var
  self: PButton;
begin
  self := PButton(ASender);
  with self^ do begin
{    Moving := false;}
  end;
end;

procedure ScrollSliderMouseMove(ASender: PObject; var AEvent: TMouseEvent); far;
var
  self: PButton;
  bar: PScrollbar;
  rect: TRect;
begin
  self := PButton(ASender);
  with self^ do begin
{    if not Moving then
      exit;}
    bar := PScrollbar(Parent);
    GetScreenBounds(rect);
    if bar^.Orientation = soHorizontal then begin
      X := AEvent.NewMouseState.X;
      DrawSelf;
    end
    else begin
    end;
  end;
end;

procedure ScrollButtonClick(ASender: PObject; var AEvent: TMouseEvent); far;
var
  button: PButton;
  scrollbar: PScrollbar;
begin
  button := PButton(ASender);
  scrollbar := PScrollbar(button^.Parent);
end;

constructor TScrollbar.CreateParent(const AId: string; AParent: PControl; AOrientation: TScrollOrientation);
begin
  inherited CreateParent(AId, AParent);
  Orientation := AOrientation;
end;

procedure TScrollbar.Init;
begin
  inherited Init;
  MovePos := -1;
  Min := 0;
  Max := 0;
  Pos := 0;
  BorderStyle := bsSingle;
  BackColor := Desktop^.InterfaceColors^.ScrollBack;
  IncButton := New(PButton, CreateParent('IncButton', -1, @self));
  with IncButton^ do begin
    TextAlign := taCenter;
    VertAlign := vaCenter;
    CanFocus := false;
    OnMouseClick := @ScrollButtonClick;
  end;
  DecButton := New(PButton, CreateParent('DecButton', -1, @self));
  with DecButton^ do begin
    TextAlign := taCenter;
    VertAlign := vaCenter;
    CanFocus := false;
    OnMouseClick := @ScrollButtonClick;
  end;
  Slider := New(PButton, CreateParent('Slider', -1, @self));
  with Slider^ do begin
    CanFocus := false;
    Clickable := false;
    CanDrag := true;
{    OnMouseMove := @ScrollSliderMouseMove;
    OnMouseDown := @ScrollSliderMouseDown;
    OnMouseUp := @ScrollSliderMouseUp;}
  end;
  Size := 16;
  if Graph^.Mode^.Width <= 320 then
    Size := 11;
end;

procedure TScrollbar.GetSliderRect(var ARect: TRect);
var
  sliderSize: integer;
begin
  if Orientation = soHorizontal then
    ARect.CreateDims(Size - 2, 0, Size, Size)
  else
    ARect.CreateDims(0, Size - 2, Size, Size);
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
  BorderColor := Desktop^.InterfaceColors^.Border;
  BorderStyle := bsNone;
  ForeColor := Desktop^.InterfaceColors^.WindowTitle;
  BackColor := Desktop^.InterfaceColors^.WindowTitleBack;
  ActiveForeColor := Desktop^.InterfaceColors^.WindowActiveTitle;
  ActiveBackColor := Desktop^.InterfaceColors^.WindowActiveTitleBack;
  BorderStyle := bsNone;
  VertAlign := vaCenter;
  TextAlign := taCenter;
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
  Graph^.State.ViewPort := rect;
  Graph^.SetForeColor(BorderColor);
  Graph^.HLine(rect.X, rect.Bottom, rect.Width);
end;

procedure TView.Init;
begin
  inherited Init;
  CanFocus := false;
  IsMouseOver := false;
  ForeColor := Desktop^.InterfaceColors^.Window;
  BackColor := Desktop^.InterfaceColors^.WindowBack;
  BorderStyle := bsSingle;
  Grouped := false;
  Content := New(PViewContent, CreateParent('Content', @self));
  Font := Desktop^.Font;
  Content^.Font := Font;
  Title := nil;
  Titlebar := New(PTitlebar, CreateParent('Titlebar', @self));
  Titlebar^.ParentView := @self;
  Active := false;
  Closed := false;
  HorzScrollbar := New(PScrollbar, CreateParent('HorzScrollBar', @self, soHorizontal));
  VertScrollbar := New(PScrollbar, CreateParent('VertScrollBar', @self, soVertical));
  ScrollType := scNone;
end;

procedure TView.Close;
var
  rect: TRect;
begin
  GetScreenBounds(rect);
  StartDrawing;
  Desktop^.PaintRegion(rect, @self);
  EndDrawing;
  Application^.DeactivateActiveControl;
  if Desktop^.ActiveView = @self then
    Desktop^.ActiveView^.Deactivate;
  Closed := true;
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
  Draw;
end;

procedure TView.Deactivate;
begin
  Active := false;
  if Desktop^.ActiveView = @self then
    Desktop^.ActiveView := nil;
end;

destructor TView.Free;
begin
  TString.Dispose(Title);
  inherited Free;
end;

procedure TView.Maximize;
var
  viewRect: TRect;
begin
  viewRect.CreateDims(-1, -1, Desktop^.Width + 2, Desktop^.Height + 3);
  if Desktop^.MenuBar^.GetVisible then begin
    Dec(viewRect.Height, Desktop^.Menubar^.Height);
    Inc(viewRect.Y, Desktop^.Menubar^.Height);
  end;
  if Desktop^.StatusBar^.GetVisible then
    Dec(viewRect.Height, Desktop^.Statusbar^.Height);
  SetBoundsRect(viewRect);
  Draw;
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
  if not Assigned(Titlebar^.Text) then
    Titlebar^.Text := TString.Copy(Title);
  Titlebar^.VertAlign := vaCenter;
  titleHeight := Font^.Height + 2 * Titlebar^.Margin + 1;
  if not Titlebar^.Visible then
    titleHeight := 0;
  Titlebar^.SetBounds(rect.X, rect.Y, rect.Width, titleHeight);
  case ScrollType of
    scNone: begin
      VertScrollBar^.Visible := false;
      HorzScrollBar^.Visible := false;
      Content^.SetBounds(rect.X, rect.Y + titleHeight, rect.Width, rect.Height - titleHeight);
    end;
    scVertical: begin
      VertScrollBar^.Visible := true;
      HorzScrollBar^.Visible := false;
      Content^.SetBounds(rect.X, rect.Y + titleHeight, rect.Width - VertScrollbar^.Size + 1,
        rect.Height - titleHeight);
    end;
    scHorizontal: begin
      VertScrollBar^.Visible := false;
      HorzScrollBar^.Visible := true;
      Content^.SetBounds(rect.X, rect.Y + titleHeight, rect.Width, rect.Height - titleHeight
        - HorzScrollbar^.Size + 1);
    end;
    scBoth: begin
      VertScrollBar^.Visible := true;
      HorzScrollBar^.Visible := true;
      Content^.SetBounds(rect.X, rect.Y + titleHeight, rect.Width - VertScrollbar^.Size + 1,
        rect.Height - titleHeight - HorzScrollbar^.Size + 1);
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

procedure TViewContent.Init;
begin
  inherited Init;
  BorderStyle := bsNone;
  DrawBackground := false;
end;

procedure TViewContent.Paint;
begin
  inherited Paint;
end;

procedure TWindow.Init;
begin
  inherited Init;
end;

destructor TWindow.Free;
begin
  inherited Free;
end;

end.