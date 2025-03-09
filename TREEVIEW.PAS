{$I COMPILER.INC}
unit TreeView;

interface

uses
  AplConst,
  AplObj,
  AplStr,
  AplTypes,
  Lists,
  Strings,
  Drawing,
  Graphics,

  Controls,
  ListView,
  VeriType,
  Views;

type
  PTreeView = ^TTreeView;
  PTreeNode = ^TTreeNode;
  PTreeNodes = ^TTreeNodes;
  PTreeListItem = ^TTreeListItem;
  PTreeListItems = ^TTreeListItems;

  TTreeNode = object(TObject)
  private
    FNodes: PTreeNodes;
    FParent: PTreeNode;
    FText: PChar;
    FValue: pointer;
    FExpanded: boolean;
    FOwner: PTreeView;
    FItem: PTreeListItem;
  public
    constructor Create(AOwner: PTreeView; AItem: PTreeListItem);
    destructor Free; virtual;
    function Nodes: PTreeNodes;
    function Level: integer;
    function Parent: PTreeNode;
    function NewNode(const AText: string; var AValue): PTreeNode; virtual;
    function Value: pointer;
    function Expanded: boolean;
    function Item: PTreeListItem;
    function Text: string;
    procedure SetItem(AItem: PTreeListItem);
    procedure SetExpanded(AValue: boolean);
    procedure SetValue(var AValue);
    procedure SetText(const AText: string);
    procedure Init; virtual;
  end;

  TTreeNodes = object(TObjectList)
  private
  public
    function Add(AItem: PTreeNode): integer;
    function GetItem(AIndex: integer): PTreeNode;
    function IndexOf(AItem: PTreeNode): integer;
    procedure SetItem(AIndex: integer; AItem: PTreeNode);
    procedure Insert(AIndex: integer; AItem: PTreeNode);
    procedure RemoveItem(AItem: PTreeNode);
  end;

  TTreeListItem = object(TListItem)
  private
    FArrowLabel: PLabel;
  public
    constructor Create(AOwner: PTreeView);
    destructor Free; virtual;
    function TextOffsetX: integer; virtual;
    function TextOffsetY: integer; virtual;
    function TreeNode: PTreeNode;
    procedure Init; virtual;
  end;

  TTreeListItems = object(TListItems)
  private
  public
    function GetItem(AIndex: integer): PTreeListItem;
    function GetItemByValue(var AValue): PTreeListItem;
    function Add(AItem: PTreeListItem): integer;
    function IndexOf(AItem: PTreeListItem): integer;
    procedure Delete(AIndex: integer); virtual;
    procedure SetItem(AIndex: integer; AItem: PTreeListItem);
    procedure Insert(AIndex: integer; AItem: PTreeListItem);
    procedure RemoveItem(AItem: PTreeListItem);
  end;

  TTreeView = object(TListView)
  private
    FRoot: PTreeNode;
    FDoubleClickItem: integer;
    procedure BuildTreeItems;
    procedure BuildTreeItem(ANode: PTreeNode);
  public
    function Root: PTreeNode;
    function CreateItems: PListItems; virtual;
    function CreateItem: PListItem; virtual;
    function TreeListItems: PTreeListItems;
    procedure SetRoot(ARoot: PTreeNode);
    procedure MouseDoubleClick(var AEvent: TMouseEvent); virtual;
    procedure MouseDown(var AEvent: TMouseEvent); virtual;
    procedure Refresh(ARedraw: boolean);
    procedure PaintItem(AIndex: integer); virtual;
    destructor Free; virtual;
    procedure Init; virtual;
    procedure Layout; virtual;
  end;

implementation

uses
  Veridian;

constructor TTreeNode.Create(AOwner: PTreeView; AItem: PTreeListItem);
begin
  inherited Create;
  FOwner := AOwner;
  FItem := AItem;
end;

procedure TTreeNode.Init;
begin
  FNodes := New(PTreeNodes, Create);
  FParent := nil;
  FText := nil;
  FValue := nil;
  FExpanded := false;
  FOwner := nil;
  FItem := nil;
  inherited Init;
end;

destructor TTreeNode.Free;
begin
  FreeAndNil(FNodes);
  inherited Free;
end;

procedure TTreeNode.SetText(const AText: string);
begin
  TString.AssignString(FText, AText);
  if Assigned(FItem) then
    FItem^.SetText(AText);
end;

function TTreeNode.Text: string;
begin
  Text := StrPas(FText);
end;

function TTreeNode.Value: pointer;
begin
  Value := FValue;
end;

procedure TTreeNode.SetValue(var AValue);
begin
  FValue := pointer(AValue);
end;

function TTreeNode.Level: integer;
var
  result: integer;
  node: PTreeNode;
begin
  result := 0;
  node := @self;
  while Assigned(node^.FParent) do begin
    node := node^.FParent;
    Inc(result);
  end;
  Level := result;
end;

function TTreeNode.Parent: PTreeNode;
begin
  Parent := FParent;
end;

function TTreeNode.NewNode(const AText: string; var AValue): PTreeNode;
var
  result: PTreeNode;
begin
  result := New(PTreeNode, Create(FOwner, nil));
  result^.FParent := @self;
  result^.SetText(AText);
  result^.SetValue(AValue);
  Nodes^.Add(result);
  NewNode := result;
end;

function TTreeNode.Expanded: boolean;
begin
  Expanded := FExpanded;
end;

procedure TTreeNode.SetExpanded(AValue: boolean);
begin
  FExpanded := AValue;
  FOwner^.BuildTreeItems;
  FOwner^.Draw;
end;

function TTreeNode.Item: PTreeListItem;
begin
  Item := FItem;
end;

procedure TTreeNode.SetItem(AItem: PTreeListItem);
begin
  FItem := AItem;
end;

function TTreeNode.Nodes: PTreeNodes;
begin
  Nodes := FNodes;
end;

function TTreeNodes.Add(AItem: PTreeNode): integer;
begin
  Add := inherited Add(AItem);
end;

function TTreeNodes.GetItem(AIndex: integer): PTreeNode;
begin
  GetItem := PTreeNode(inherited GetItem(AIndex));
end;

function TTreeNodes.IndexOf(AItem: PTreeNode): integer;
begin
  IndexOf := inherited IndexOf(AItem);
end;

procedure TTreeNodes.SetItem(AIndex: integer; AItem: PTreeNode);
begin
  inherited SetItem(AIndex, AItem);
end;

procedure TTreeNodes.Insert(AIndex: integer; AItem: PTreeNode);
begin
  inherited Insert(AIndex, AItem);
end;

procedure TTreeNodes.RemoveItem(AItem: PTreeNode);
begin
  inherited RemoveItem(AItem);
end;

destructor TTreeListItem.Free;
begin
  Owner^.Controls^.DeleteItem(FArrowLabel);
  inherited Free;
end;

function TTreeListItem.TextOffsetX: integer;
var
  charWidth: integer;
begin
  charWidth := TreeNode^.FOwner^.Font^.TextWidth('W');
  TextOffsetX := TreeNode^.Level * charWidth + charWidth;
end;

function TTreeListItem.TextOffsetY: integer;
begin
  TextOffsetY := 0;
end;

constructor TTreeListItem.Create(AOwner: PTreeView);
begin
  inherited Create;
  SetOwner(AOwner);
end;

procedure TTreeListItem.Init;
begin
  inherited Init;
  FArrowLabel := nil;
end;

function TTreeListItem.TreeNode: PTreeNode;
begin
  TreeNode := PTreeNode(Value);
end;

function TTreeListItems.GetItem(AIndex: integer): PTreeListItem;
begin
  GetItem := PTreeListItem(inherited GetItem(AIndex));
end;

function TTreeListItems.GetItemByValue(var AValue): PTreeListItem;
begin
  GetItemByValue := PTreeListItem(inherited GetItemByValue(AValue));
end;

function TTreeListItems.Add(AItem: PTreeListItem): integer;
begin
  Add := inherited Add(AItem);
end;

function TTreeListItems.IndexOf(AItem: PTreeListItem): integer;
begin
  IndexOf := inherited IndexOf(AItem);
end;

procedure TTreeListItems.Delete(AIndex: integer);
begin
  inherited Delete(AIndex);
end;

procedure TTreeListItems.SetItem(AIndex: integer; AItem: PTreeListItem);
begin
  inherited SetItem(AIndex, AItem);
end;

procedure TTreeListItems.Insert(AIndex: integer; AItem: PTreeListItem);
begin
  inherited Insert(AIndex, AItem);
end;

procedure TTreeListItems.RemoveItem(AItem: PTreeListItem);
begin
  inherited RemoveItem(AItem);
end;

function TTreeView.Root: PTreeNode;
begin
  Root := FRoot;
end;

procedure TTreeView.SetRoot(ARoot: PTreeNode);
begin
  FRoot := ARoot;
end;

procedure TTreeView.BuildTreeItems;
begin
  VeridianApp^.DisableDrawing;
  Items^.Clear;
  BuildTreeItem(FRoot);
  VeridianApp^.EnableDrawing;
end;

procedure TTreeView.BuildTreeItem(ANode: PTreeNode);
var
  index: integer;
  item: PTreeListItem;
  node: PTreeNode;
begin
  item := PTreeListItem(CreateItem);
  Items^.Add(item);
  item^.SetValue(ANode);
  item^.SetText(ANode^.Text);
  if ANode^.Expanded then begin
    for index := 0 to ANode^.Nodes^.Count - 1 do begin
      node := ANode^.Nodes^.GetItem(index);
      BuildTreeItem(node);
    end;
  end;
end;

procedure TTreeView.Refresh(ARedraw: boolean);
begin
  BuildTreeItems;
  if ARedraw then
    Draw;
end;

procedure TTreeView.MouseDown(var AEvent: TMouseEvent);
begin
  if not Assigned(VeridianApp^.DoubleClickControl) then
    FDoubleClickItem := -1
  else if FDoubleClickItem < 0 then
    FDoubleClickItem := GetSelectedIndex(AEvent);
  inherited MouseDown(AEvent);
end;

procedure TTreeView.MouseDoubleClick(var AEvent: TMouseEvent);
var
  index: integer;
  item: PTreeListItem;
  node: PTreeNode;
begin
  index := GetSelectedIndex(AEvent);
  if (index < 0) or (index > Items^.Count - 1) then
    exit;
  if index <> FDoubleClickItem then
    exit;
  FDoubleClickItem := -1;
  item := PTreeListItem(Items^.GetItem(index));
  node := item^.TreeNode;

  if node^.FNodes^.Count > 0 then begin
    node^.FExpanded := not node^.FExpanded;
    node^.FOwner^.BuildTreeItems;
    node^.FOwner^.Draw;
  end;
end;

destructor TTreeView.Free;
begin
  FreeAndNil(FRoot);
  inherited Free;
end;

procedure TTreeView.Init;
begin
  inherited Init;
  FRoot := New(PTreeNode, Create(@self, nil));
  FRoot^.FExpanded := true;
  FDoubleClickItem := -1;
end;

procedure TTreeView.Layout;
var
  index: integer;
  item: PTreeListItem;
  itemRect: TRect;
  txt: string;
  ch: char;
  arrowPos: TPoint;
begin
  inherited Layout;
  for index := 0 to Items^.Count - 1 do begin
    item := TreeListItems^.GetItem(index);
    GetItemLayout(index, itemRect);
    GetTextAlign(itemRect, arrowPos);
    item^.FArrowLabel^.VertAlign := vaCenter;
    item^.FArrowLabel^.SetXY(
      Padding.Left + item^.TextOffsetX + itemRect.X - Font^.TextWidth('W'),
      arrowPos.Y + 1
    );
    item^.FArrowLabel^.Layout;
    item^.FArrowLabel^.Width := Font^.TextWidth('W');
    item^.FArrowLabel^.Height := Font^.Height;
    txt := item^.TreeNode^.Text;
    item^.SetText(txt);
    ch := #32;
    if item^.TreeNode^.FNodes^.Count > 0 then begin
      ch := #16;
      if item^.TreeNode^.FExpanded then
        ch := #31;
    end;
    item^.FArrowLabel^.SetCaption(ch);
  end;
end;

function TTreeView.CreateItems: PListItems;
begin
  CreateItems := New(PTreeListItems, Create(@self));
end;

function TTreeView.TreeListItems: PTreeListItems;
begin
  TreeListItems := PTreeListItems(Items);
end;

procedure ArrowLabelMouseDown(var AEvent: TMouseEvent); far;
var
  lab: PLabel;
  treeView: PTreeView;
  item: PTreeListItem;
  index: integer;
  node: PTreeNode;
begin
  lab := PLabel(AEvent.Sender);
  Inc(AEvent.X, lab^.X);
  Inc(AEvent.Y, lab^.Y);
  treeView := PTreeView(lab^.Parent);
  item := pointer(lab^.Tag);
  node := item^.TreeNode;
  if node^.FNodes^.Count > 0 then begin
    node^.FExpanded := not node^.FExpanded;
    node^.FOwner^.BuildTreeItems;
    node^.FOwner^.Draw;
  end;
  treeView^.MouseDown(AEvent);
end;

function TTreeView.CreateItem: PListItem;
var
  result: PTreeListItem;
begin
  result := New(PTreeListItem, Create(@self));
  result^.FArrowLabel := New(PLabel, CreateParent('', @self));
  result^.FArrowLabel^.OnMouseDown := @ArrowLabelMouseDown;
  result^.FArrowLabel^.AutoSize := false;
  result^.FArrowLabel^.Tag := longint(result);
  CreateItem := result;
end;

procedure TTreeView.PaintItem(AIndex: integer);
var
  item: PTreeListItem;
  fore, back: byte;
begin
  if (AIndex < 0) or (AIndex > Items^.Count - 1) then
    exit;
  item := TreeListItems^.GetItem(AIndex);
  GetColors(AIndex, fore, back);
  item^.FArrowLabel^.ForeColor := fore;
  item^.FArrowLabel^.BackColor := back;
  inherited PaintItem(AIndex);
  item^.FArrowLabel^.Draw;
end;

var
  PreviousExitProc: PProc;

procedure Finalize;
begin
  ExitProc := PreviousExitProc;
end;

begin
  PreviousExitProc := ExitProc;
  ExitProc := @Finalize;
end.