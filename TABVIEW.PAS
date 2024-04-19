{$I COMPILER.INC}
unit TabView;

interface

uses
  Objects,
  Controls,
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
    procedure Init; virtual;
    procedure SetupControls; virtual;
    procedure Paint; virtual;
    destructor Free; virtual;
  end;

  TTabView = object(TPanel)
  private
  public
    Tabs: PTabList;
    procedure Init; virtual;
    procedure SetupControls; virtual;
    procedure Paint; virtual;
    destructor Free; virtual;
  end;

  TTabList = object(TObjectList)
  {$IFDEF VER70}private{$ENDIF}
  {$IFDEF VER70}public{$ENDIF}
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
  TabButton := New(PTextControl, CreateParent('TabButton', @self));
  with TabButton^ do begin
    BorderStyle := bsNone;
    Margin := 4;
  end;
  ForeColor := Desktop^.Colors^.Window;
  BackColor := Desktop^.Colors^.WindowBack;
  Contents := New(PPanel, CreateParent('Contents', @self));
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
  Tabs := New(PTabList, Create);
end;

procedure TTabView.Paint;
begin
  inherited Paint;
end;

destructor TTabView.Free;
begin
  FreeAndNil(Tabs);
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