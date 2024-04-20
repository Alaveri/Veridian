unit Trees;

interface

uses
  Objects,
  Views,
  Controls;

type
  PTree = ^TTree;
  PTreeNode = ^TTreeNode;

  TTreeNode = object(TTextControl)
  private
  public
    Data: PObject;
    DisposeData: boolean;
{    function NewNode: PTreeNode; virtual;
    procedure DeleteNode(ANode: PTreeNode); virtual;
    procedure DeleteNodeAt(AIndex: integer); virtual;
    procedure Clear; virtual;}
    constructor CreateData(AData: pointer);
    procedure Init; virtual;
    destructor Free; virtual;
  end;

  TTree = object(TView)
  private
  public
{    function NewNode(AParent: TTreeNode): PTreeNode; virtual;
    procedure DeleteNode(ANode: PTreeNode); virtual;
    procedure ClearNodes; virtual;}
    procedure Init; virtual;
    procedure SetupControls; virtual;
    destructor Free; virtual;
  end;

implementation

uses
  Desk;

constructor TTreeNode.CreateData(AData: pointer);
begin
  inherited Create('');
  Data := AData;
end;

procedure TTreeNode.Init;
begin
  inherited Init;
  Data := nil;
  DisposeData := true;
end;

destructor TTreeNode.Free;
begin
  FreeAndNil(Data);
  inherited Free;
end;

procedure TTree.Init;
begin
  inherited Init;
  ForeColor := Desktop^.Colors^.Dialog;
  BackColor := Desktop^.Colors^.DialogBack;
  BorderColor := Desktop^.Colors^.Border;
  Titlebar^.Visible := false;
  ScrollType := scAsNeeded;
end;

procedure TTree.SetupControls;
begin
  inherited SetupControls;
end;

destructor TTree.Free;
begin
  inherited Free;
end;

end.