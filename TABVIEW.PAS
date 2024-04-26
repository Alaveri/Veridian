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
    InactiveColor: byte;
    procedure Init; virtual;
    procedure Paint; virtual;
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

  TTabView = object(TPanel)
  private
  public
    TabIndex: integer;
    Tabs: TTabList;
    ScrollPos: integer;
    function CurrentTab: PTab;
    function GetTabIndex(ATab: PTab): integer;
    function NewTab(const AName: string): PTab;
    function TotalTabButtonWidth: integer;
    procedure RemoveTab(ATab: PTab);
    procedure Init; virtual;
    procedure SetupControls; virtual;
    procedure Paint; virtual;
    destructor Free; virtual;
  end;

implementation

uses
  GraphDrv,
  Veridian,
  Desk;

procedure TTabButton.Init;
begin
  inherited Init;
  InactiveColor := Desktop^.Colors^.TabInactive;
end;

procedure TTabButton.Paint;
var
  rect: TRect;
  view: PTabView;
  oldBackColor: byte;
  oldBorderStyle: TBorderStyle;
begin
  Graph^.SetForeColor(ForeColor);
  Graph^.SetBackColor(BackColor);
  view := PTabView(Parent^.Parent);
  oldBackColor := BackColor;
  oldBorderStyle := BorderStyle;
  BorderStyle := bsNone;
  if view^.CurrentTab <> PTab(Parent) then
    BackColor := InactiveColor;
  inherited Paint;
  BorderStyle := oldBorderStyle;
  BackColor := oldBackColor;
  if not GetVisible then
    exit;
  GetScreenBounds(rect);
  if BorderStyle <> bsNone then begin
    Graph^.SetForeColor(ForeColor);
    Graph^.HLine(rect.X, rect.Y, rect.Width);
    Graph^.VLine(rect.X, rect.Y, rect.Height);
    Graph^.VLine(rect.Right, rect.Y, rect.Height);
    if View^.TabIndex <> view^.Tabs.IndexOf(PTab(Parent)) then
      Graph^.HLine(rect.X, rect.Bottom, rect.Width);
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
    SetText(#17);
    Margin := 0;
    CanFocus := false;
    Visible := false;
  end;
  RightScrollButton := New(PButton, CreateParent('RightScroll', 0, @self));
  with RightScrollButton^ do begin
    SetText(#16);
    Margin := 0;
    CanFocus := false;
    Visible := false;
  end;
end;

procedure TTab.SetupControls;
var
  tabWidth: integer;
  xPos: integer;
  index: integer;
  view: PTabView;
  tab: PTab;
begin
  inherited SetupControls;
  BorderStyle := Parent^.BorderStyle;
  view := PTabView(parent);
  xPos := 0;
  for index := 0 to view^.Tabs.Count - 1 do begin
    tab := PTab(view^.Tabs.GetItem(index));
    if index < view^.Tabs.IndexOf(@self) then
      Inc(xPos, tab^.TabButton^.Width - 1);
  end;
  with LeftScrollButton^ do begin
    SetBounds(0, 0, VeridianApp^.Scale(0.85), TabHeight);
    Visible := view^.ScrollPos > 0;
    if Visible then
      Inc(xPos, Width - 1);
  end;
  with RightScrollButton^ do begin
    Visible := view^.TotalTabButtonWidth > view^.Width;
    SetBounds(Parent^.Width - LeftScrollButton^.Width, 0, VeridianApp^.Scale(0.85), TabHeight);
  end;

  with TabButton^ do begin
    Margin := VeridianApp^.Scale(0.20);
    TextAlign := taCenter;
    BorderStyle := self.BorderStyle;
    tabWidth := Font^.TextWidth(GetText) + 4 * Margin;
    SetBounds(xPos - view^.ScrollPos, 0, tabWidth, TabHeight);
    Contents^.SetBounds(
      -view^.ScrollPos,
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
  Tabs.Create;
  Tabs.DisposeObjects := false;
  ScrollPos := 0;
  TabIndex := -1;
end;

function TTabView.TotalTabButtonWidth: integer;
var
  index: integer;
  tab: PTab;
  total: integer;
begin
  total := 0;
  for index := 0 to Tabs.Count - 1 do begin
    tab := Tabs.GetItem(index);
    Inc(total, tab^.TabButton^.Width);
  end;
  TotalTabButtonWidth := total;
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
  tab: PTab;
  total: integer;
begin
  tab := New(PTab, CreateParent('Tab', @self));
  VeridianApp^.DrawEnabled := false;
  tab^.TabButton^.SetText(AName);
  VeridianApp^.DrawEnabled := true;
  tab^.SetBounds(0, 0, Width, Height);
  TabIndex := Tabs.Add(tab);
  NewTab := tab;
  total := TotalTabButtonWidth - tab^.RightScrollButton^.Width;
  if total > Width then
    ScrollPos := TotalTabButtonWidth - tab^.TabButton^.Width - tab^.RightScrollButton^.Width;
end;

procedure TTabView.RemoveTab(ATab: PTab);
var
  controlIndex, index: integer;
begin
  index := Tabs.IndexOf(ATab);
  if index < 0 then
    exit;
  controlIndex := Controls^.IndexOf(ATab);
  if controlIndex < 0 then
    exit;
  Controls^.Delete(controlIndex);
  Tabs.Delete(index);
  if TabIndex = index then begin
    if index < Tabs.Count - 1 then
      TabIndex := index
    else
      TabIndex := index - 1;
    if Tabs.Count = 0 then
      TabIndex := -1;
  end;
  Draw;
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
  DrawBackground := Tabs.Count = 0;
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