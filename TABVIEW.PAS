{$I COMPILER.INC}
unit TabView;

interface

uses
  Objects,
  Drawing,
  Controls,
  Errors,
  Lists,
  Views;

type
  PTab = ^TTab;
  PTabView = ^TTabView;
  PTabList = ^TTabList;
  PTabButton = ^TTabButton;

  TTab = object(TTextControl)
  private
  public
    TabButton: PTabButton;
    Contents: PPanel;
    LeftScrollButton: PButton;
    RightScrollButton: PButton;
    Data: pointer;
    procedure Init; virtual;
    procedure SetupControls; virtual;
    procedure Paint; virtual;
    function TabHeight: integer; virtual;
    destructor Free; virtual;
  end;

  TTabButton = object(TTextControl)
  private
  public
    procedure Init; virtual;
    procedure Paint; virtual;
  end;

  TTabView = object(TPanel)
  private
  public
    TabIndex: integer;
    function CurrentTab: PTab;
    function GetTabIndex(ATab: PTab): integer;
    function NewTab(const AName: string): PTab;
    procedure Init; virtual;
    procedure SetupControls; virtual;
    procedure Paint; virtual;
    destructor Free; virtual;
  end;

  TTabList = object(TObjectList)
  private
  public
    function IndexOf(AItem: PTab): integer;
    function Add(AItem: PTab): integer;
    function GetItem(AIndex: integer): PTab;
    function SetItem(AIndex: integer; AItem: PTab): boolean;
    function GetNewObject: PObject; virtual;
    procedure Insert(AIndex: integer; AItem: PTab);
  end;

implementation

uses
  GraphDrv,
  Veridian,
  Desk;

procedure TTabButton.Init;
begin
  inherited Init;
end;

procedure TTabButton.Paint;
var
  rect: TRect;
  oldBorderStyle: TBorderStyle;
begin
  Graph^.SetForeColor(ForeColor);
  Graph^.SetBackColor(BackColor);
  oldBorderStyle := BorderStyle;
  BorderStyle := bsNone;
  inherited Paint;
  BorderStyle := oldBorderStyle;
  if not GetVisible then
    exit;
  GetScreenBounds(rect);
  if BorderStyle <> bsNone then begin
    Graph^.SetForeColor(ForeColor);
    Graph^.HLine(rect.X, rect.Y, rect.Width);
    Graph^.VLine(rect.X, rect.Y, rect.Height);
    Graph^.VLine(rect.Right, rect.Y, rect.Height);
  end;
end;

procedure TTab.Init;
begin
  inherited Init;
  Data := nil;
  TabButton := New(PTabButton, CreateParent('TabButton', @self));
  with TabButton^ do begin
    ForeColor := Desktop^.Colors^.Tab;
    BackColor := Desktop^.Colors^.TabBack;
  end;
  ForeColor := Desktop^.Colors^.Tab;
  BackColor := Desktop^.Colors^.TabBack;
  Contents := New(PPanel, CreateParent('Contents', @self));
  with Contents^ do begin
    ForeColor := ForeColor;
    BackColor := BackColor;
    BorderStyle := bsNone;
    DrawBackground := false;
  end;

  LeftScrollButton := New(PButton, CreateParent('LeftScroll', 0, @self));
  with LeftScrollButton^ do begin
    SetText(#16);
  end;
  RightScrollButton := New(PButton, CreateParent('RightScroll', 0, @self));
  with LeftScrollButton^ do begin
    SetText(#17);
  end;

end;

procedure TTab.SetupControls;
var
  tabWidth: integer;
begin
  inherited SetupControls;
  BorderStyle := Parent^.BorderStyle;
  with TabButton^ do begin
    Margin := VeridianApp^.Scale(0.20);
    TextAlign := taCenter;
    BorderStyle := self.BorderStyle;
    tabWidth := Font^.TextWidth(GetText) + 4 * Margin;
    SetBounds(0, 0, tabWidth, TabHeight);
    Contents^.SetBounds(
      0,
      TabHeight,
      Self.Parent^.Width,
      Self.Parent^.Height - TabHeight
    );
  end;
end;

procedure TTab.Paint;
var
  rect: TRect;
begin
  if not GetVisible then
    exit;
  GetScreenBounds(rect);
  Graph^.SetForeColor(ForeColor);
  Graph^.SetBackColor(BackColor);
  rect.Translate(0, TabHeight);
  rect.Grow(0, -TabHeight);
  if DrawBackground then
    Graph^.FillRect(rect);
  GetScreenBounds(rect);
  if BorderStyle <> bsNone then begin
    Graph^.SetForeColor(BorderColor);
    Graph^.Rectangle(rect);
  end;
end;

function TTab.TabHeight: integer;
begin
  TabHeight := Font^.Height + 2 * VeridianApp^.Scale(0.20);
end;

destructor TTab.Free;
begin
  inherited Free;
end;

procedure TTabView.Init;
begin
  inherited Init;
  DrawBackground := true;
  ForeColor := Desktop^.Colors^.TabView;
  BackColor := Desktop^.Colors^.TabViewBack;
end;

function TTabView.CurrentTab: PTab;
begin
  CurrentTab := PTab(Controls^.GetItem(TabIndex));
end;

function TTabView.GetTabIndex(ATab: PTab): integer;
begin
  GetTabIndex := Controls^.IndexOf(ATab);
end;

function TTabView.NewTab(const AName: string): PTab;
var
  rect: TRect;
begin
  NewTab := New(PTab, CreateParent('Tab', @self));
  NewTab^.TabButton^.SetText(AName);
  NewTab^.SetBounds(0, 0, Width, Height);
end;

procedure TTabView.Paint;
var
  tab: PTab;
  rect: TRect;
begin
  inherited Paint;
  if not GetVisible then
    exit;
  GetScreenBounds(rect);
  if Controls^.Count = 0 then
    exit;
  tab := PTab(Controls^.GetItem(0));
  if BorderStyle <> bsNone then begin
    Graph^.SetForeColor(BorderColor);
    Graph^.Rectangle(rect);
    Graph^.HLine(rect.X, rect.Y + Tab^.TabHeight - 1, Width - 1);
  end;
end;

destructor TTabView.Free;
begin
  inherited Free;
end;

procedure TTabView.SetupControls;
begin
  inherited SetupControls;
end;

function TTabList.IndexOf(AItem: PTab): integer;
begin
  IndexOf := inherited IndexOf(AItem);
end;

function TTabList.Add(AItem: PTab): integer;
begin
  Add := inherited Add(AItem);
end;

function TTabList.GetItem(AIndex: integer): PTab;
begin
  GetItem := PTab(inherited GetItem(AIndex));
end;

function TTabList.SetItem(AIndex: integer; AItem: PTab): boolean;
begin
  SetItem := inherited SetItem(AIndex, AItem);
end;

function TTabList.GetNewObject: PObject;
begin
  GetNewObject := New(PTab, Create(''));
end;

procedure TTabList.Insert(AIndex: integer; AItem: PTab);
begin
  inherited Insert(AIndex, AItem);
end;

end.