{$I COMPILER.INC}
unit TabView;

interface

uses
  AplObj,
  AplTypes,
  Drawing,
  Controls,
  VeriType,
  Errors,
  Lists,
  Views;

type
  PTab = ^TTab;
  PTabView = ^TTabView;
  PTabList = ^TTabList;
  PTabButton = ^TTabButton;
  PTabButtonContainer = ^TTabButtonContainer;
  PTabClosingEventProc = ^TTabClosingEventProc;
  PTabClosedEventProc = ^TTabClosedEventProc;

  TTab = object(TPanel)
  private
  public
    Button: PTabButton;
    Content: PPanel;
    Data: pointer;
    View: PTabView;
    function TabIndex: integer;
    procedure Init; virtual;
    procedure SetupControls; virtual;
    procedure Paint; virtual;
    destructor Free; virtual;
  end;

  TTabButtonContainer = object(TPanel)
  private
  public
    View: PTabView;
    procedure Paint; virtual;
  end;

  TTabButton = object(TTextControl)
  private
  public
    CloseButton: PTextControl;
    InactiveColor: byte;
    Tab: PTab;
    View: PTabView;
    function TabIndex: integer;
    procedure Init; virtual;
    procedure Paint; virtual;
    procedure MouseDown(var AEvent: TMouseEvent); virtual;
  end;

  TTabList = object(TObjectList)
  private
  public
    function IndexOf(AItem: PTab): integer;
    function Add(AItem: PTab): integer;
    function GetItem(AIndex: integer): PTab;
    function SetItem(AIndex: integer; AItem: PTab): boolean;
    procedure Insert(AIndex: integer; AItem: PTab);
  end;

  TTabClosedEvent = object(TEvent)
  private
  public
    TabIndex: integer;
    procedure Init; virtual;
  end;

  TTabClosingEvent = object(TTabClosedEvent)
  private
  public
    Tab: PTab;
    CanClose: boolean;
    procedure Init; virtual;
  end;

  TTabClosingEventProc = procedure(ASender: PObject; var AEvent: TTabClosingEvent);
  TTabClosedEventProc = procedure(ASender: PObject; var AEvent: TTabClosedEvent);

  TTabView = object(TPanel)
  private
    FTabs: TTabList;
    procedure ScrollVisible; virtual;
    procedure GetContainerBounds(var ARect: TRect);
  public
    TabIndex: integer;
    ButtonContainer: PTabButtonContainer;
    ScrollPos: integer;
    LeftButton: PButton;
    RightButton: PButton;
    OnTabClosing: PTabClosingEventProc;
    OnTabClosed: PTabClosedEventProc;
    function Count: integer; virtual;
    function GetTab(AIndex: integer): PTab; virtual;
    function IndexOf(ATab: PTab): integer; virtual;
    function TabHeight: integer; virtual;
    function CurrentTab: PTab;
    function GetTabIndex(ATab: PTab): integer;
    function NewTab(const AName: string): PTab;
    function TotalButtonWidth(AIndex: integer): integer;
    procedure ActivateTab(AIndex: integer);
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
  StrUtils,
  Desk;

procedure CloseClick(ASender: PObject; var AEvent: TMouseEvent); far;
var
  button: PButton;
  view: PTabView;
  tabIndex, index: integer;
  tabButton: PTabButton;
  event: TTabClosingEvent;
  closedevent: TTabClosedEvent;
  tab: PTab;
begin
  button := PButton(ASender);
  tabButton := PTabButton(button^.Parent);
  tab := tabButton^.Tab;
  view := PTabView(tabButton^.View);

  event.Create;
  event.Tab := tab;
  event.CanClose := true;
  event.TabIndex := tab^.TabIndex;
  if Assigned(view^.OnTabClosing) then
    TTabClosingEventProc(view^.OnTabClosing)(view, event);
  if not event.CanClose then
    exit;
  index := view^.ButtonContainer^.Controls^.IndexOf(tabButton);
  view^.ButtonContainer^.Controls^.Delete(index);
  tabIndex := tab^.TabIndex;
  view^.FTabs.Delete(tabIndex);
  closedEvent.Create;
  closedEvent.TabIndex := tabIndex;
  index := view^.Controls^.IndexOf(tab);
  VeridianApp^.ClearMouseOver;
  view^.Controls^.Delete(index);
  if view^.FTabs.Count = 0 then begin
    view^.TabIndex := -1;
  end
  else if tabIndex = view^.TabIndex then begin
    if tabIndex > view^.FTabs.Count - 1 then
      tabIndex := view^.FTabs.Count - 1;
    view^.ActivateTab(tabIndex);
  end
  else
    Dec(view^.TabIndex);
  view^.Draw;
  if Assigned(view^.OnTabClosed) then
    TTabClosedEventProc(view^.OnTabClosed)(view, closedEvent);
end;

procedure LeftScrollClick(ASender: PObject; var AEvent: TMouseEvent); far;
var
  button: PButton;
  view: PTabView;
  tabButton: PTabButton;
begin
  button := PButton(ASender);
  view := PTabView(button^.Parent);
  if view^.FTabs.Count = 0 then
    exit;
  tabButton := view^.FTabs.GetItem(view^.FTabs.Count - 1)^.Button;
  Dec(view^.ScrollPos, tabButton^.Width);
  if view^.ScrollPos < 0 then
    view^.ScrollPos := 0;
  view^.SetupControls;
  view^.ButtonContainer^.Draw;
  if view^.LeftButton^.Visible then
    view^.LeftButton^.Draw;
  if view^.RightButton^.Visible then
    view^.RightButton^.Draw;
end;

procedure RightScrollClick(ASender: PObject; var AEvent: TMouseEvent); far;
var
  button: PButton;
  view: PTabView;
  tabButton: PTabButton;
  max, last: integer;
begin
  button := PButton(ASender);
  view := PTabView(button^.Parent);
  if view^.FTabs.Count = 0 then
    exit;
  tabButton := view^.FTabs.GetItem(0)^.Button;
  Inc(view^.ScrollPos, tabButton^.Width);
  last := view^.FTabs.Count - 1;
  max := view^.TotalButtonWidth(last)
   - view^.ButtonContainer^.Width + view^.FTabs.GetItem(last)^.Width;
  if view^.ScrollPos > max then
    view^.ScrollPos := max;
  view^.SetupControls;
  view^.ButtonContainer^.Draw;
  if view^.LeftButton^.Visible then
    view^.LeftButton^.Draw;
  if view^.RightButton^.Visible then
    view^.RightButton^.Draw;
end;

procedure TTabButtonContainer.Paint;
var
  tab: PTab;
  button: PTabButton;
  rect: TRect;
begin
  inherited Paint;
  if View^.FTabs.Count = 0 then
    exit;
  tab := View^.FTabs.GetItem(View^.FTabs.Count - 1);
  button := tab^.Button;
  GetScreenBounds(rect);
  Graph^.SetForeColor(BorderColor);
  button^.GetScreenBounds(rect);
  Graph^.HLine(rect.Right, rect.Bottom, Width);
end;

procedure TTabButton.Init;
begin
  inherited Init;
  CloseButton := New(PTextControl, CreateParent('CloseButton', @self));
  CloseButton^.Text := TString.New('x');
  CloseButton^.VertAlign := vaTop;
  CloseButton^.TextAlign := taCenter;
  CloseButton^.TextOffsetY := -1;
  CloseButton^.CanFocus := false;
  CloseButton^.OnMouseClick := @CloseClick;
  CloseButton^.BorderStyle := bsNone;
  CloseButton^.DrawBackground := false;
  InactiveColor := Desktop^.Colors^.TabInactive;
  ForeColor := Desktop^.Colors^.Tab;
  BackColor := Desktop^.Colors^.TabBack;
  View := nil;
  Tab := nil;
end;

procedure TTabButton.Paint;
var
  fillRect, rect: TRect;
  textXPos, textYPos: integer;
  parentRect: TRect;
begin
  if not GetVisible then
    exit;
  Graph^.SetForeColor(ForeColor);
  Graph^.SetBackColor(BackColor);
  if View^.CurrentTab <> Tab then
    Graph^.SetBackColor(InactiveColor);

  GetScreenBounds(rect);
  fillRect.CreateRect(rect);
  fillRect.Translate(1, 1);
  fillRect.Grow(-2, -1);
  Graph^.FillRect(fillRect);

  GetTextAlign(rect, textXPos, textYPos);
  Graph^.State.Font := Font;
  Graph^.DrawTextLarge(textXPos, textYPos, Text);

  if BorderStyle <> bsNone then begin
    Graph^.SetForeColor(BorderColor);
    Graph^.HLine(rect.X, rect.Y, rect.Width);
    Graph^.VLine(rect.X, rect.Y, rect.Height);
    Graph^.VLine(rect.Right, rect.Y, rect.Height);
    if View^.TabIndex <> TabIndex then
      Graph^.HLine(rect.X, rect.Bottom, rect.Width);
  end;
end;

procedure TTabView.ActivateTab(AIndex: integer);
var
  oldTab: PTab;
  index: integer;
  aTab: PTab;
begin
  SetupControls;
  if TabIndex >= 0 then begin
    oldTab := CurrentTab;
    if Assigned(oldTab) then begin
      oldTab^.Content^.Visible := false;
      TabIndex := -1;
      oldTab^.Button^.Draw;
    end;
  end;
  TabIndex := AIndex;
  aTab := CurrentTab;
  ScrollVisible;
  aTab^.Content^.Visible := true;
  aTab^.Content^.Draw;
  aTab^.Button^.Draw;
end;

procedure TTabButton.MouseDown(var AEvent: TMouseEvent);
begin
  View^.ActivateTab(TabIndex);
  inherited MouseDown(AEvent);
end;

function TTabButton.TabIndex: integer;
begin
  TabIndex := View^.FTabs.IndexOf(Tab);
end;

procedure TTab.Init;
begin
  inherited Init;
  Data := nil;
  with Button^ do begin
    ForeColor := Desktop^.Colors^.Tab;
    BackColor := Desktop^.Colors^.TabBack;
  end;
  ForeColor := Desktop^.Colors^.Tab;
  BackColor := Desktop^.Colors^.TabBack;
  Content := New(PPanel, CreateParent('Content', @self));
  with Content^ do begin
    ForeColor := ForeColor;
    BackColor := BackColor;
    BorderStyle := bsNone;
    DrawBackground := false;
  end;
end;

procedure TTab.SetupControls;
begin
  inherited SetupControls;
end;

function TTab.TabIndex: integer;
begin
  TabIndex := View^.FTabs.IndexOf(@self);
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
  if DrawBackground then
    Graph^.FillRect(rect);
  GetScreenBounds(rect);
  if BorderStyle <> bsNone then begin
    Graph^.SetForeColor(BorderColor);
    Graph^.Rectangle(rect);
  end;
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
  ButtonContainer := New(PTabButtonContainer, CreateParent('ButtonContainer', @self));
  ButtonContainer^.BorderStyle := bsNone;
  ButtonContainer^.View := @self;
  FTabs.Create;
  FTabs.DisposeObjects := false;
  ScrollPos := 0;
  TabIndex := -1;
  OnTabClosing := nil;
  OnTabClosed := nil;

  LeftButton := New(PButton, CreateParent('LeftScroll', 0, @self));
  with LeftButton^ do begin
    SetText(#17);
    Margin := 0;
    CanFocus := false;
    Visible := false;
    OnMouseClick := @LeftScrollClick;
  end;

  RightButton := New(PButton, CreateParent('RightScroll', 0, @self));
  with RightButton^ do begin
    SetText(#16);
    Margin := 0;
    CanFocus := false;
    Visible := false;
    OnMouseClick := @RightScrollClick;
  end;
end;

function TTabView.TotalButtonWidth(AIndex: integer): integer;
var
  index: integer;
  tab: PTab;
  total: integer;
begin
  total := BorderWidth;
  for index := 0 to AIndex - 1 do begin
    tab := FTabs.GetItem(index);
    Inc(total, tab^.Button^.Width - 1);
  end;
  TotalButtonWidth := total;
end;

function TTabView.CurrentTab: PTab;
begin
  CurrentTab := PTab(FTabs.GetItem(TabIndex));
end;

function TTabView.GetTabIndex(ATab: PTab): integer;
begin
  GetTabIndex := FTabs.IndexOf(ATab);
end;

function TTabView.TabHeight: integer;
begin
  TabHeight := Font^.Height + 2 * VeridianApp^.Scale(0.20);
end;

function TTabView.Count: integer;
begin
  Count := FTabs.Count;
end;

function TTabView.GetTab(AIndex: integer): PTab;
begin
  GetTab := FTabs.GetItem(AIndex);
end;

function TTabView.IndexOf(ATab: PTab): integer;
begin
  IndexOf := FTabs.IndexOf(ATab);
end;

function TTabView.NewTab(const AName: string): PTab;
var
  aTab: PTab;
begin
  aTab := New(PTab, CreateParent('Tab', @self));
  with aTab^ do begin
    View := @self;
    Button := New(PTabButton, CreateParent('TabButton', ButtonContainer));
    Button^.Text := TString.New(AName);
    Button^.View := @self;
    Button^.Tab := aTab;
    View := @self;
    BorderStyle := bsNone;
  end;
  SetupControls;
  ActivateTab(FTabs.Add(aTab));
  NewTab := aTab;
end;

procedure TTabView.RemoveTab(ATab: PTab);
var
  index: integer;
begin
  index := FTabs.IndexOf(ATab);
  if index < 0 then
    exit;
  FTabs.Delete(index);
  index := Controls^.IndexOf(ATab);
  Controls^.Delete(index);
  if TabIndex = index then begin
    if index < FTabs.Count - 1 then
      TabIndex := index
    else
      TabIndex := index - 1;
    if FTabs.Count = 0 then
      TabIndex := -1;
  end;
  Draw;
end;

procedure TTabView.Paint;
var
  rect: TRect;
begin
  if not GetVisible then
    exit;
  inherited Paint;
  GetScreenBounds(rect);
  if Controls^.Count = 0 then
    exit;
  if TabIndex < 0 then
    exit;
  if BorderStyle <> bsNone then begin
    Graph^.SetForeColor(BorderColor);
    Graph^.Rectangle(rect);
  end;
end;

destructor TTabView.Free;
begin
  FTabs.Free;
  inherited Free;
end;

procedure TTabView.ScrollVisible;
var
  tab: PTab;
  xPos: integer;
begin
  if FTabs.Count = 0 then
    exit;
  if TabIndex < 0 then
    exit;
  tab := CurrentTab;
  xPos := TotalButtonWidth(TabIndex);
  if xPos - ScrollPos + tab^.Button^.Width - 1 > ButtonContainer^.Width then
    ScrollPos := xPos - ButtonContainer^.Width + tab^.Button^.Width;
end;

procedure TTabView.GetContainerBounds(var ARect: TRect);
begin
  ARect.CreateDims(0, 0, Width, TabHeight);
  if LeftButton^.Visible then begin
    ARect.Translate(LeftButton^.Width, 0);
    ARect.Grow(-LeftButton^.Width, 0);
  end;
  if RightButton^.Visible then
    ARect.Grow(-RightButton^.Width, 0);
end;

procedure TTabView.SetupControls;
var
  tabWidth: integer;
  xPos: integer;
  index: integer;
  tab: PTab;
  button: PTabButton;
  closeRect, rect: TRect;
  closeWidth, closeHeight: integer;
  scrollButtonWidth: integer;
  offset: integer;
  buttonMargin: integer;
  buttonAdjust: integer;
  total: integer;
begin
  inherited SetupControls;
  DrawBackground := FTabs.Count = 0;
  closeWidth := VeridianApp^.Scale(0.75);
  closeHeight := Font^.Height - 2;
  if Graph^.Mode^.Width < 640 then
    scrollButtonWidth := VeridianApp^.Scale(1.5)
  else
    scrollButtonWidth := VeridianApp^.Scale(0.75);
  buttonMargin := VeridianApp^.Scale(0.3);
  buttonAdjust := 3 * buttonMargin + closeWidth;
  ButtonContainer^.Visible := FTabs.Count > 0;

  for index := 0 to FTabs.Count - 1 do begin
    tab := FTabs.GetItem(index);
    tab^.SetBounds(
      -tab^.BorderWidth,
      TabHeight - tab^.BorderWidth - 1,
      Width,
      Height - TabHeight + 2 * tab^.BorderWidth + 1
    );
    button := tab^.Button;
    button^.Margin := buttonMargin;
    button^.SetBounds(0, 0,
      Font^.TextWidthLarge(button^.Text) + buttonAdjust,
      TabHeight
    );
    button^.CloseButton^.SetBounds(
      button^.Width - closeWidth - buttonMargin,
      (button^.Height - closeHeight) div 2,
      closeWidth,
      closeHeight);
  end;

  total := TotalButtonWidth(FTabs.Count);
  LeftButton^.Visible := (FTabs.Count > 0) and (ScrollPos > 0);
  offset := 0;
  if LeftButton^.Visible then
    Inc(offset, scrollButtonWidth - 1);
  LeftButton^.SetBounds(-1, -1, scrollButtonWidth, TabHeight);
  RightButton^.SetBounds(Width - scrollButtonWidth - 2, -1, scrollButtonWidth, TabHeight);
  RightButton^.Visible := (total > Width - offset) and
    (ScrollPos < total - Width + offset);

  with ButtonContainer^ do begin
    rect.SetDims(-1, 0, self.Width - 1, TabHeight - 1);
    rect.Translate(offset, 0);
    BorderStyle := bsNone;
    rect.Grow(-offset, 0);
    if RightButton^.Visible then
      rect.Grow(-scrollButtonWidth + 1, 0);
    SetBoundsRect(rect);
    ForeColor := Desktop^.Colors^.Tab;
    BackColor := Desktop^.Colors^.TabViewBack;
  end;

  xPos := -ScrollPos;
  for index := 0 to FTabs.Count - 1 do begin
    tab := FTabs.GetItem(index);
    button := tab^.Button;
    button^.X := xPos;
    button^.Y := -1;
    Inc(xPos, Font^.TextWidthLarge(button^.Text) + buttonAdjust - 1);
  end;
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

procedure TTabList.Insert(AIndex: integer; AItem: PTab);
begin
  inherited Insert(AIndex, AItem);
end;

procedure TTabClosingEvent.Init;
begin
  inherited Init;
  CanClose := true;
  Tab := nil;
end;

procedure TTabClosedEvent.Init;
begin
  inherited Init;
  TabIndex := 0;
end;

end.