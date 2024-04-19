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

  TTab = object(TPanel)
  private
  public
    TabButton: PTextControl;
    Contents: PPanel;
    procedure Init; virtual;
    destructor Free; virtual;
  end;

  TTabView = object(TPanel)
  private
  public
    Tabs: PTabList;
    procedure Init; virtual;
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

procedure TTab.Init;
begin
  inherited Init;
  TabButton := New(PTextControl, CreateParent('TabButton', @self));
  Contents := New(PPanel, CreateParent('Contents', @self));
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

destructor TTabView.Free;
begin
  FreeAndNil(Tabs);
  inherited Free;
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