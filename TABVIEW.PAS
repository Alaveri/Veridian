{$I COMPILER.INC}
unit TabView;

interface

uses
  Objects,
  Controls,
  Errors,
  Lists,
  Views;

type
  PTab = ^TTab;
  PTabView = ^TTabView;
  PTabList = ^TTabList;

  TTab = object(TTextControl)
  private
  public
    TabButton: PTextControl;
    Contents: PPanel;
    Data: pointer;
    procedure Init; virtual;
    procedure SetupControls; virtual;
    procedure Paint; virtual;
    destructor Free; virtual;
  end;

  TTabView = object(TPanel)
  private
  public
    TabIndex: integer;
    function CurrentTab: PTab;
    function GetTabIndex(ATab: PTab): integer;
    function NewTab: PTab;
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
  Desk;

procedure TTab.Init;
begin
  inherited Init;
  Data := nil;
  TabButton := New(PTextControl, CreateParent('TabButton', @self));
  with TabButton^ do begin
    BorderStyle := bsNone;
    Margin := 4;
  end;
  BorderStyle := bsNone;
  ForeColor := Desktop^.Colors^.Tab;
  BackColor := Desktop^.Colors^.TabBack;
  Contents := New(PPanel, CreateParent('Contents', @self));
  Contents^.ForeColor := ForeColor;
  Contents^.BackColor := BackColor;
  with Contents^ do begin
    BorderStyle := bsNone;
  end;
end;

procedure TTab.SetupControls;
var
  tabHeight: integer;
begin
  inherited SetupControls;
  tabHeight := Font^.Height + 2 * Margin;
  TabButton^.SetBounds(0, 0, Parent^.Width, tabHeight);
  Contents^.SetBounds(0, tabHeight, Parent^.Width, Parent^.Height - tabHeight);
end;

procedure TTab.Paint;
begin
  inherited Paint;
end;

destructor TTab.Free;
begin
  inherited Free;
end;

procedure TTabView.Init;
begin
  inherited Init;
end;

function TTabView.CurrentTab: PTab;
begin
  CurrentTab := PTab(Controls^.GetItem(TabIndex));
end;

function TTabView.GetTabIndex(ATab: PTab): integer;
begin
  GetTabIndex := Controls^.IndexOf(ATab);
end;

function TTabView.NewTab: PTab;
begin
  NewTab := New(PTab, CreateParent('', @self));
end;

procedure TTabView.Paint;
begin
  inherited Paint;
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