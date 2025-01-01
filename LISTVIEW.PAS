{$I COMPILER.INC}
unit ListView;

interface

uses
  AplTypes,
  AplObj,
  Drawing,
  Lists,
  AplMath,
  VeriType,
  Controls,
  Standard,
  Views;

type
  PListView = ^TListView;
  PListItem = ^TListItem;
  PCheckListItem = ^TCheckListItem;
  PListItems = ^TListItems;
  PCheckListItems = ^TCheckListItems;
  PIndexChangedProc = ^TIndexChangedProc;
  PDropDownList = ^TDropDownList;
  PDropDownButton = ^TDropDownButton;
  PIndexChangedEvent = ^TIndexChangedEvent;
  PDropDownListView = ^TDropDownListView;
  PCheckListView = ^TCheckListView;

  TIndexChangeTrigger = (ctMouse, ctKeyboard);

  TIndexChangedEvent = object(TEvent)
  private
  public
    OldIndex: integer;
    NewIndex: integer;
    Trigger: TIndexChangeTrigger;
    procedure Assign(var ASource: TObject); virtual;
    procedure Clear; virtual;
  end;

  TIndexChangedProc = procedure(var AEvent: TIndexChangedEvent);

  TListItem = object(TObject)
  private
  public
    Owner: PListView;
    Text: PChar;
    Value: pointer;
    Tag: longint;
    constructor CreateText(const AText: string);
    constructor CreateTextValue(const AText: string; AValue: pointer);
    constructor CreateAll(const AText: string; AValue: pointer; ATag: longint);
    procedure SetText(const AText: string);
    procedure Init; virtual;
    destructor Free; virtual;
  end;

  TCheckListItem = object(TListItem)
  private
  public
    CheckBox: PCheckBox;
    procedure Init; virtual;
    function Checked: boolean;
    procedure SetChecked(AValue: boolean);
  end;

  TListItems = object(TObjectList)
  private
  public
    Owner: PListView;
    constructor Create(AOwner: PListView);
    function GetItem(AIndex: integer): PListItem;
    function GetItemByValue(AValue: pointer): PListItem;
    function Add(AItem: PListItem): integer;
    function IndexOf(AItem: PListItem): integer;
    function IndexOfValue(AValue: pointer): integer;
    function IndexOfTag(ATag: longint): integer;
    procedure SetItem(AIndex: integer; AItem: PListItem);
    procedure Insert(AIndex: integer; AItem: PListItem);
    procedure RemoveItem(AItem: PListItem);
    procedure Delete(AIndex: integer); virtual;
  end;

  TCheckListItems = object(TListItems)
  private
  public
    function GetItem(AIndex: integer): PCheckListItem;
    function GetItemByValue(AValue: pointer): PCheckListItem;
    function Add(AItem: PCheckListItem): integer;
    function IndexOf(AItem: PCheckListItem): integer;
    function Checked(AIndex: integer): boolean;
    procedure Delete(AIndex: integer); virtual;
    procedure SetChecked(AIndex: integer; AChecked: boolean);
    procedure SetItem(AIndex: integer; AItem: PCheckListItem);
    procedure Insert(AIndex: integer; AItem: PCheckListItem);
    procedure RemoveItem(AItem: PCheckListItem);
  end;

  TListView = object(TView)
  private
  public
    Items: PListItems;
    SelectedIndex: integer;
    SelectedColor: byte;
    SelectedBackColor: byte;
    UnfocusedSelectForeColor: byte;
    UnfocusedSelectBackColor: byte;
    OnSelectedIndexChanged: PIndexChangedProc;
    ItemSpacing: integer;
    VisibleItems: integer;
    AutoHeight: boolean;
    TextOffsetX, TextOffsetY: integer;
    function SelectedItem: PListItem;
    function GetSelectedIndex(AEvent: TMouseEvent): integer;
    function ItemHeight: integer; virtual;
    function ContentWidth: integer; virtual;
    function ContentHeight: integer; virtual;
    function ContentX: integer; virtual;
    function ContentY: integer; virtual;
    function CreateItems: PListItems; virtual;
    function CreateItem: PListItem; virtual;
    function AddItem(const AText: string): PListItem;
    function AddItemValue(const AText: string; AValue: pointer): PListItem;
    function AddItemTag(const AText: string; ATag: longint): PListItem;
    function AddItemAll(const AText: string; AValue: pointer;
      ATag: longint): PListItem;
    function InsertItem(AIndex: integer; const AText: string): PListItem;
    function InsertItemValue(AIndex: integer; const AText: string;
      AValue: pointer): PListItem;
    function InsertItemTag(AIndex: integer; const AText: string;
      ATag: longint): PListItem;
    function InsertItemAll(AIndex: integer; const AText: string;
      AValue: pointer; ATag: longint): PListItem;
    procedure PaintItem(AIndex: integer); virtual;
    procedure GetContentExtent(var ASize: TSize); virtual;
    procedure Focus; virtual;
    procedure UnFocus; virtual;
    procedure Init; virtual;
    procedure Paint(ARect: TRect); virtual;
    procedure LayoutRect(ARect: TRect); virtual;
    procedure SetSelectedIndex(AIndex: integer);
    procedure KeyPress(var AEvent: TKeyEvent); virtual;
    procedure MouseDown(var AEvent: TMouseEvent); virtual;
    procedure MouseWheelChanged(var AEvent: TMouseEvent); virtual;
    procedure SelectedIndexChanged(var AEvent: TIndexChangedEvent); virtual;
    procedure GetItemRect(AIndex: integer; var ARect: TRect); virtual;
    procedure GetItemLayoutRect(AIndex: integer; var ARect: TRect); virtual;
    procedure ChangeSelect(ADelta: integer); virtual;
    procedure SetScrollBarBounds(AOrientation: TScrollOrientation); virtual;
    procedure Clear; virtual;
    procedure DrawControls; virtual;
    procedure Draw; virtual;
    destructor Free; virtual;
  end;

  TDropDownButton = object(TButton)
  private
  public
    procedure Init; virtual;
    procedure Paint(ARect: TRect); virtual;
    procedure MouseDown(var AEvent: TMouseEvent); virtual;
  end;

  TDropDownListView = object(TListView)
  private
  public
    procedure LayoutRect(ARect: TRect); virtual;
    procedure SelectedIndexChanged(var AEvent: TIndexChangedEvent); virtual;
  end;

  TDropDownList = object(TFocusControl)
  private
    FButton: PDropDownButton;
    FList: PDropDownListView;
    FButtonSize: integer;
    FOldIndex: integer;
  public
    MaxItems: integer;
    Text: PChar;
    OnSelectedIndexChanged: PIndexChangedProc;
    procedure ShowList;
    procedure HideList;
    procedure Paint(ARect: TRect); virtual;
    function Items: PListItems;
    function SelectedIndex: integer;
    function SelectedItem: PListItem;
    function GetText: string;
    function List: PListView;
    procedure SetSelectedIndex(AIndex: integer);
    procedure SelectedIndexChanged(var AEvent: TIndexChangedEvent);
    procedure MouseDown(var AEvent: TMouseEvent); virtual;
    procedure Unfocus; virtual;
    procedure KeyPress(var AEvent: TKeyEvent); virtual;
    procedure Init; virtual;
    procedure LayoutRect(ARect: TRect); virtual;
    procedure SetText(const AText: string); virtual;
    procedure AutoSizeControl; virtual;
    destructor Free; virtual;
  end;

  TCheckListView = object(TListView)
  private
  public
    procedure PaintItem(AIndex: integer); virtual;
    procedure Init; virtual;
    function CheckListItems: PCheckListItems; virtual;
    function CreateItems: PListItems; virtual;
    function CreateItem: PListItem; virtual;
    function Checked(AIndex: integer): boolean;
    function AddItem(const AText: string): PCheckListItem;
    function AddItemValue(const AText: string; AValue: pointer): PCheckListItem;
    function AddItemTag(const AText: string; ATag: longint): PCheckListItem;
    function AddItemAll(const AText: string; AValue: pointer;
      ATag: longint): PCheckListItem;
    function InsertItem(AIndex: integer; const AText: string): PCheckListItem;
    function InsertItemValue(AIndex: integer; const AText: string;
      AValue: pointer): PCheckListItem;
    function InsertItemTag(AIndex: integer; const AText: string;
      ATag: longint): PCheckListItem;
    function InsertItemAll(AIndex: integer; const AText: string;
      AValue: pointer; ATag: longint): PCheckListItem;
    function ItemHeight: integer; virtual;
    procedure SetChecked(AIndex: integer; AChecked: boolean);
    procedure LayoutRect(ARect: TRect); virtual;
  end;

implementation

uses
  AplStr,
  AplUtils,
  Graphics,
  KeyDrv,
  Strings,
  Veridian;

constructor TListItem.CreateText(const AText: string);
begin
  inherited Create;
  TString.AssignString(Text, AText);
end;

constructor TListItem.CreateTextValue(const AText: string; AValue: pointer);
begin
  CreateText(AText);
  Value := AValue;
end;

constructor TListItem.CreateAll(const AText: string; AValue: pointer; ATag: longint);
begin
  CreateTextValue(AText, AValue);
  Tag := ATag;
end;

procedure TListItem.SetText(const AText: string);
var
  index: integer;
begin
  TString.AssignString(Text, AText);
  index := Owner^.Items^.IndexOf(@self);
  Owner^.BeginDrawing;
  Owner^.PaintItem(index);
  Owner^.EndDrawing;
end;

procedure TListItem.Init;
begin
  inherited Init;
  Text := nil;
  Value := nil;
  Owner := nil;
  Tag := 0;
end;

destructor TListItem.Free;
begin
  TString.Free(Text);
  inherited Free;
end;

procedure TListView.GetContentExtent(var ASize: TSize);
var
  index: integer;
  item: PListItem;
begin
  ASize.Create;
  for index := 0 to Items^.Count - 1 do begin
    item := Items^.GetItem(index);
    ASize.Width := Max(ASize.Width, Font^.TextWidthLarge(item^.Text)
      + Padding.Width);
  end;
  ASize.Height := Items^.Count * ItemHeight;
end;

procedure TListView.Init;
begin
  inherited Init;
  TextOffsetX := 0;
  TextOffsetY := 0;
  TransparentBack := false;
  ScrollType := scAsNeeded;
  CanFocus := true;
  Items := CreateItems;
  OnSelectedIndexChanged := nil;
  SelectedIndex := -1;
  BorderStyle := bsSingle;
  BevelStyle := bvNone;
  VertScrollBar^.Position := rpParentRelative;
  HorzScrollBar^.Position := rpParentRelative;
  Font := VeridianApp^.GetFont('editor');
  SelectedColor := VeridianApp^.Colors.ListSelected;
  SelectedBackColor := VeridianApp^.Colors.ListSelectedBack;
  UnfocusedSelectForeColor := VeridianApp^.Colors.ListUnfocusedSelect;
  UnfocusedSelectBackColor := VeridianApp^.Colors.ListUnfocusedSelectBack;
  Padding.CreateAll(2, 0, 2, 0);
  ItemSpacing := 4;
  VisibleItems := 10;
  AutoHeight := false;
end;

procedure TListView.SetSelectedIndex(AIndex: integer);
var
  index: integer;
  rect, itemRect: TRect;
  previousIndex: integer;
  event: TIndexChangedEvent;
  listHeight: integer;
begin
  index := Clamp(AIndex, 0, Items^.Count - 1);
  if index = SelectedIndex then
    exit;
  previousindex := SelectedIndex;
  SelectedIndex := index;
  GetContentDrawRect(rect);
  GetItemRect(SelectedIndex, itemRect);
  if itemRect.Y >= rect.Bottom then
    ScrollVert((SelectedIndex - previousIndex) * itemRect.Height);
  if itemRect.Y < rect.Y then
    ScrollVert((SelectedIndex - previousIndex) * itemRect.Height);
  BeginDrawing;
  GetClipRect(rect);
  rect.Intersect(Graph^.State^.ViewPort);
  Graph^.SetViewPort(rect);
  PaintItem(previousIndex);
  PaintItem(SelectedIndex);
  EndDrawing;
  event.Create;
  event.NewIndex := SelectedIndex;
  event.OldIndex := previousIndex;
  event.Trigger := ctKeyboard;
  SelectedIndexChanged(event);
end;

function TListView.SelectedItem: PListItem;
begin
  SelectedItem := nil;
  if (SelectedIndex < 0) or (SelectedIndex > Items^.Count - 1) then
    exit;
  SelectedItem := Items^.GetItem(SelectedIndex);
end;

destructor TListView.Free;
begin
  FreeAndNil(Items);
  inherited Free;
end;

procedure TListView.Focus;
begin
  BeginDrawing;
  SetFocus(true, false);
  PaintItem(SelectedIndex);
  EndDrawing;
end;

procedure TListView.Unfocus;
begin
  BeginDrawing;
  SetFocus(false, false);
  PaintItem(SelectedIndex);
  EndDrawing;
end;

function TListView.AddItem(const AText: string): PListItem;
var
  index: integer;
  result: PListItem;
begin
  result := CreateItem;
  TString.AssignString(result^.Text, AText);
  index := Items^.Add(result);
  AddItem := Items^.GetItem(index);
end;

function TListView.AddItemValue(const AText: string; AValue: pointer): PListItem;
var
  index: integer;
  result: PListItem;
begin
  result := CreateItem;
  TString.AssignString(result^.Text, AText);
  result^.Value := AValue;
  index := Items^.Add(result);
  AddItemValue := Items^.GetItem(index);
end;

function TListView.AddItemTag(const AText: string; ATag: longint): PListItem;
var
  index: integer;
  result: PListItem;
begin
  result := CreateItem;
  TString.AssignString(result^.Text, AText);
  result^.Tag := ATag;
  index := Items^.Add(result);
  AddItemTag := Items^.GetItem(index);
end;

function TListView.AddItemAll(const AText: string; AValue: pointer; ATag: longint): PListItem;
var
  index: integer;
  result: PListItem;
begin
  result := CreateItem;
  TString.AssignString(result^.Text, AText);
  result^.Value := AValue;
  result^.Tag := ATag;
  index := Items^.Add(result);
  AddItemAll := Items^.GetItem(index);
end;

function TListView.InsertItem(AIndex: integer; const AText: string): PListItem;
var
  result: PListItem;
begin
  result := CreateItem;
  TString.AssignString(result^.Text, AText);
  Items^.Insert(AIndex, result);
  InsertItem := result;
end;

function TListView.InsertItemValue(AIndex: integer; const AText: string;
  AValue: pointer): PListItem;
var
  result: PListItem;
begin
  result := CreateItem;
  TString.AssignString(result^.Text, AText);
  result^.Value := AValue;
  Items^.Insert(AIndex, result);
  InsertItemValue := result;
end;

function TListView.InsertItemTag(AIndex: integer; const AText: string;
  ATag: longint): PListItem;
var
  result: PListItem;
begin
  result := CreateItem;
  TString.AssignString(result^.Text, AText);
  result^.Tag := ATag;
  Items^.Insert(AIndex, result);
  InsertItemTag := result;
end;

function TListView.InsertItemAll(AIndex: integer; const AText: string;
  AValue: pointer; ATag: longint): PListItem;
var
  result: PListItem;
begin
  result := CreateItem;
  TString.AssignString(result^.Text, AText);
  result^.Value := AValue;
  result^.Tag := ATag;
  Items^.Insert(AIndex, result);
  InsertItemAll := result;
end;

function TListView.CreateItem: PListItem;
var
  result: PListItem;
begin
  result := New(PListItem, Create);
  result^.Owner := @self;
  CreateItem := result;
end;

procedure TListView.GetItemRect(AIndex: integer; var ARect: TRect);
var
  cx: integer;
  cy: integer;
  rect: TRect;
begin
  GetContentDrawRect(rect);
  rect.Translate(ContentOffsetX, ContentOffsetY);
  cy := rect.Y + AIndex * ItemHeight;
  ARect.CreateDims(rect.X, cy, rect.Width, ItemHeight);
end;

procedure TListView.GetItemLayoutRect(AIndex: integer; var ARect: TRect);
var
  cx: integer;
  cy: integer;
  rect: TRect;
begin
  GetContentRect(rect);
  rect.Translate(ContentOffsetX, ContentOffsetY);
  cy := rect.Y + AIndex * ItemHeight;
  ARect.CreateDims(rect.X, cy, rect.Width, ItemHeight);
end;

function TListView.ItemHeight: integer;
var
  result: integer;
begin
  result := Font^.Height + ItemSpacing;
  ItemHeight := result;
end;

procedure TListView.PaintItem(AIndex: integer);
var
  rect, itemRect: TRect;
  item: PListItem;
  clipRect, viewRect: TRect;
begin
  if not VeridianApp^.State.DrawEnabled then
    exit;
  if not IsVisible then
    exit;
  if (AIndex < 0) or (AIndex > Items^.Count - 1) then
    exit;
  item := Items^.GetItem(AIndex);
  Graph^.SetForeColor(ForeColor);
  Graph^.SetBackColor(BackColor);
  if AIndex = SelectedIndex then begin
    if Focused then begin
      Graph^.SetForeColor(SelectedColor);
      Graph^.SetBackColor(SelectedBackColor);
    end
    else begin
      Graph^.SetForeColor(UnfocusedSelectForeColor);
      Graph^.SetBackColor(UnfocusedSelectBackColor);
    end;
  end;
  Graph^.PushState;
  GetItemRect(AIndex, itemRect);
  GetClipRect(clipRect);
  clipRect.Translate(OuterWidth, OuterWidth);
  clipRect.Grow(-2 * OuterWidth, -2 * OuterWidth);
  clipRect.Intersect(Graph^.State^.ViewPort);
  Graph^.SetViewPort(clipRect);
  Graph^.FillRect(itemRect);
  Graph^.DrawTextLarge(itemRect.X + Padding.Left + TextOffsetX,
    itemRect.Y + TextOffsetY + ItemSpacing div 2, item^.Text);
  Graph^.PopState;
end;

function TListView.ContentX: integer;
var
  result: integer;
begin
  result := inherited ContentX;
  Dec(result, Padding.Left);
  ContentX := result;
end;

function TListView.ContentY: integer;
var
  result: integer;
begin
  result := inherited ContentY;
  Dec(result, Padding.Top);
  ContentY := result;
end;

function TListView.ContentWidth: integer;
var
  result: integer;
begin
  result := inherited ContentWidth;
  Inc(result, Padding.Width);
  ContentWidth := result;
end;

function TListView.ContentHeight: integer;
var
  result: integer;
begin
  result := inherited ContentHeight;
  Inc(result, Padding.Height);
  ContentHeight := result;
end;

function TListView.CreateItems: PListItems;
begin
  CreateItems := New(PListItems, Create(@self));
end;

function TListView.GetSelectedIndex(AEvent: TMouseEvent): integer;
begin
  Inc(AEvent.Y, ScrollY);
  GetSelectedIndex := AEvent.Y div ItemHeight;
end;

procedure TListView.SelectedIndexChanged(var AEvent: TIndexChangedEvent);
begin
  if AEvent.OldIndex = AEvent.NewIndex then
    exit;
  Invoke(OnSelectedIndexChanged, AEvent);
end;

procedure TListView.MouseWheelChanged(var AEvent: TMouseEvent);
var
  amount: integer;
begin
  inherited MouseWheelChanged(AEvent);
  if not VertScrollBar^.Visible then
    exit;
  amount := AEvent.NewMouseState.WheelCounter * ItemHeight;
  if AEvent.NewMouseState.WheelCounter > 0 then
    ScrollVert(amount)
  else if AEvent.NewMouseState.WheelCounter < 0 then
    ScrollVert(amount);
end;

procedure TListView.MouseDown(var AEvent: TMouseEvent);
var
  index: integer;
  previousIndex: integer;
  event: TIndexChangedEvent;
  rect: TRect;
begin
  if not IsVisibleAndEnabled then
    exit;
  if CanFocus and not Focused then
    Focus;
  previousindex := SelectedIndex;
  SelectedIndex := GetSelectedIndex(AEvent);
  SelectedIndex := Clamp(SelectedIndex, 0, Items^.Count - 1);
  GetClipRect(rect);
  BeginDrawing;
  PaintItem(previousIndex);
  PaintItem(SelectedIndex);
  EndDrawing;
  event.Create;
  event.NewIndex := SelectedIndex;
  event.OldIndex := previousIndex;
  event.Trigger := ctMouse;
  event.Sender := @self;
  SelectedIndexChanged(event);
  inherited MouseDown(AEvent);
end;

procedure TListView.ChangeSelect(ADelta: integer);
begin
  SetSelectedIndex(SelectedIndex + ADelta);
end;

procedure TListView.KeyPress(var AEvent: TKeyEvent);
var
  rect: TRect;
begin
  if not IsVisibleAndEnabled then
    exit;
  if not Focused then
    exit;
  AEvent.Handled := true;
  GetDrawRect(rect);
  case AEvent.Key of
    kyDown: ChangeSelect(1);
    kyUp: ChangeSelect(-1);
    kyPageDown: ChangeSelect(rect.Height div ItemHeight);
    kyPageUp: ChangeSelect(-rect.Height div ItemHeight );
    kyEnd: ChangeSelect(Items^.Count - 1);
    kyHome: ChangeSelect(-Items^.Count - 1);
    else AEvent.Handled := false;
  end;
  if not AEvent.Handled then
    inherited KeyPress(AEvent);
end;

procedure TListView.SetScrollBarBounds(AOrientation: TScrollOrientation);
begin
  inherited SetScrollBarBounds(AOrientation);
  if AOrientation = soHorizontal then begin
    Dec(HorzScrollBar^.X, OuterWidth);
    Inc(HorzScrollBar^.X, OuterWidth);
    Inc(HorzScrollBar^.Width, 2 * OuterWidth);
  end
  else begin
    Dec(VertScrollBar^.Y, OuterWidth);
    Inc(VertScrollBar^.X, OuterWidth);
    Inc(VertScrollBar^.Height, 2 * OuterWidth);
  end;
end;

procedure TListView.Draw;
begin
  inherited Draw;
end;

procedure TListView.DrawControls;
begin
  inherited DrawControls;
end;

procedure TListView.LayoutRect(ARect: TRect);
var
  max: longint;
  rect: TRect;
  size: integer;
begin
  if AutoHeight then begin
    size := VisibleItems * ItemHeight + 2 * OuterWidth
      + Padding.Height;
    SetBounds(X, Y, Width, Size);
  end;
  inherited LayoutRect(ARect);
  GetBounds(rect);
  VertScrollbar^.Increment := ItemHeight;
  VertScrollbar^.PageIncrement := Round(rect.Height / ItemHeight) * ItemHeight;
  max := Items^.Count * ItemHeight + 2 * OuterWidth;
  Dec(max, rect.Height);
  VertScrollBar^.Max := AplMath.MaxL(0, max);
end;

procedure TListView.Clear;
begin
  Items^.Clear;
  SelectedIndex := 0;
  VertScrollbar^.SetScrollPosition(0);
  HorzScrollbar^.SetScrollPosition(0);
end;

procedure TListView.Paint(ARect: TRect);
var
  index: integer;
  oldFocusedColor: longint;
  oldFocusedBackColor: longint;
  yPos: integer;
  clipRect: TRect;
begin
  if not IsVisible then
    exit;
  oldFocusedColor := FocusedColor;
  oldFocusedBackColor := FocusedBackColor;
  FocusedColor := ForeColor;
  FocusedBackColor := BackColor;
  inherited Paint(ARect);
  FocusedColor := oldFocusedColor;
  FocusedBackColor := oldFocusedBackColor;

  for index := 0 to Items^.Count - 1 do
    PaintItem(index);
  Graph^.SetBackColor(BackColor);
  if Items^.Count * ItemHeight < ARect.Height then begin
    yPos := ARect.Y + Items^.Count * ItemHeight + OuterWidth;
    ARect.CreateDims(ARect.X + OuterWidth, yPos, ARect.Width - 2 * OuterWidth, ARect.Bottom - yPos);
    Graph^.FillRect(ARect);
  end;
end;

constructor TListItems.Create(AOwner: PListView);
begin
  inherited Create;
  Owner := AOwner;
end;

function TListItems.GetItem(AIndex: integer): PListItem;
begin
  GetItem := PListItem(inherited GetItem(AIndex));
end;

function TListItems.Add(AItem: PListItem): integer;
begin
  Add := inherited Add(AItem);
end;

function TListItems.IndexOf(AItem: PListItem): integer;
begin
  IndexOf := inherited IndexOf(AItem);
end;

function TListItems.IndexOfValue(AValue: pointer): integer;
var
  index: integer;
begin
  IndexOfValue := -1;
  for index := 0 to Count - 1 do begin
    if GetItem(index)^.Value = AValue then begin
      IndexOfValue := index;
      break;
    end;
  end;
end;

function TListItems.IndexOfTag(ATag: longint): integer;
var
  index: integer;
begin
  IndexOfTag := -1;
  for index := 0 to Count - 1 do begin
    if GetItem(index)^.Tag = ATag then begin
      IndexOfTag := index;
      break;
    end;
  end;
end;

procedure TListItems.SetItem(AIndex: integer; AItem: PListItem);
begin
  inherited SetItem(AIndex, AItem);
end;

procedure TListItems.Delete(AIndex: integer);
begin
  inherited Delete(AIndex);
end;

procedure TListItems.Insert(AIndex: integer; AItem: PListItem);
begin
  inherited Insert(AIndex, AItem);
end;

procedure TListItems.RemoveItem(AItem: PListItem);
var
  index: integer;
begin
  index := IndexOf(AItem);
  if index = -1 then
    exit;
  inherited Remove(index);
end;

function TListItems.GetItemByValue(AValue: pointer): PListItem;
var
  index: integer;
begin
  GetItemByValue := nil;
  for index := 0 to Count - 1 do begin
    if GetItem(index)^.Value = AValue then begin
      GetItemByValue := GetItem(index);
      break;
    end;
  end;
end;

procedure TDropDownList.SelectedIndexChanged(var AEvent: TIndexChangedEvent);
var
  item: PListItem;
begin
  if AEvent.Trigger = ctKeyboard then
    exit;
  item := FList^.Items^.GetItem(AEvent.NewIndex);
  HideList;
  SetText(TString.GetString(item^.Text));
  Invoke(OnSelectedIndexChanged, AEvent);
end;

procedure TDropDownButton.Init;
begin
  inherited Init;
  Position := rpParentRelative;
end;

procedure TDropDownButton.Paint(ARect: TRect);
begin
  inherited Paint(ARect);
end;

procedure TDropDownButton.MouseDown(var AEvent: TMouseEvent);
var
  dropDown: PDropDownList;
begin
  Inherited MouseDown(AEvent);
  dropDown := PDropDownList(Parent);
  if not dropDown^.FList^.IsVisible then begin
    dropDown^.ShowList;
  end
  else begin
    dropDown^.HideList;
  end;
end;

procedure TDropDownListView.LayoutRect(ARect: TRect);
var
  max: longint;
  maxItems, itemCount, listHeight, size: integer;
begin
  inherited LayoutRect(ARect);
  maxItems := PDropDownList(Parent)^.MaxItems;
  itemCount := Min(Items^.Count, maxItems);
  listHeight := itemCount * ItemHeight + 2 * Parent^.OuterWidth;
  VertScrollBar^.Height := listHeight;
  Height := listHeight;
  VertScrollBar^.Visible := Items^.Count > maxItems;
  VertScrollbar^.Increment := ItemHeight;
  VertScrollbar^.PageIncrement := Round(ARect.Height / ItemHeight) * ItemHeight;

  max := Items^.Count * ItemHeight;
  Dec(max, Height);
  VertScrollBar^.Max := AplMath.MaxL(0, max);
end;

procedure TDropDownListView.SelectedIndexChanged(var AEvent: TIndexChangedEvent);
begin
  inherited SelectedIndexChanged(AEvent);
  PDropDownList(Parent)^.SelectedIndexChanged(AEvent);
end;

procedure ListKeyPress(var AEvent: TKeyEvent); far;
var
  dropDown: PDropDownList;
  self: PListView;
  event: TIndexChangedEvent;
begin
  self := PListView(AEvent.Sender);
  if AEvent.Handled then
    exit;
  dropDown := PDropDownList(self^.Parent);
  case AEvent.Key of
    kyEnter: begin
      dropDown^.HideList;
      dropDown^.SetText(TString.GetString(self^.Items^.GetItem(self^.SelectedIndex)^.Text));
      AEvent.Handled := true;
      event.Create;
      event.OldIndex := dropDown^.FOldIndex;
      event.NewIndex := dropDown^.SelectedIndex;
      dropDown^.SelectedIndexChanged(event);
    end;
  end;
end;

procedure TDropDownList.Unfocus;
begin
  if FList^.IsVisible then
    HideList;
  inherited Unfocus;
end;

procedure TDropDownList.KeyPress(var AEvent: TKeyEvent);
begin
  if (not FList^.IsVisible) and not (CanFocus and Focused) then
    exit;
  if FList^.IsVisible and not (FList^.CanFocus and FList^.Focused) then
    exit;
  case AEvent.Key of
    kyDown: begin
      if FList^.IsVisible then
        exit;
      AEvent.Handled := true;
      UnFocus;
      ShowList;
      exit;
    end;
    kyEnter: begin
      if not FList^.IsVisible then begin
        AEvent.Handled := true;
        UnFocus;
        ShowList;
        exit;
      end
      else begin

      end;
    end;
    kyEsc: begin
      if FList^.IsVisible then
        HideList;
      AEvent.Handled := true;
      FList^.SelectedIndex := FOldIndex;
    end;
  end;
 if not AEvent.Handled then
    inherited KeyPress(AEvent);
end;

procedure TDropDownList.Paint(ARect: TRect);
var
  pos: TPoint;
  txt: string;
begin
  if not IsVisible then
    exit;
  Graph^.State^.Font := Font;
  Graph^.SetForeColor(ForeColor);
  Graph^.SetBackColor(BackColor);
  txt := GetText;
  TControl.Paint(ARect);
  if CanFocus and Focused then
    Graph^.SetBackColor(FocusedBackColor);
  if not TransparentBack then
    Graph^.FillRect(ARect);
  GetTextAlign(ARect, pos);
  Graph^.SetForeColor(ForeColor);
  Graph^.SetBackColor(BackColor);
  if not IsEnabled then begin
    Graph^.SetForeColor(DisabledColor);
    Graph^.SetBackColor(DisabledBackColor);
  end;
  if CanFocus and Focused then begin
    Graph^.SetForeColor(FocusedColor);
    Graph^.SetBackColor(FocusedBackColor);
  end;
  Graph^.DrawText(pos.X + BorderWidth, pos.Y, txt);
  Graph^.SetForeColor(BorderColor);
  if BorderStyle <> bsNone then
    Graph^.Rectangle(ARect);
end;

procedure TDropDownList.ShowList;
var
  activeControl: PFocusControl;
  rect: TRect;
begin
  if FList^.IsVisible then
    exit;
  FOldIndex := SelectedIndex;
  BringToFront;
  Layout;
  FList^.Layout;
  Inc(Height, FList^.Height);
  VeridianApp^.ActiveDropDown := @self;
  VeridianApp^.ActiveControl := nil;
  FList^.Visible := true;
  FList^.SetFocus(true, true);
end;

procedure TDropDownList.HideList;
var
  rect: TRect;
begin
  if not FList^.IsVisible then
    exit;
  FList^.GetClipRect(rect);
  Dec(Height, FList^.Height);
  FList^.Visible := false;
  BeginDrawing;
  Parent^.PaintRegion(rect, @self);
  Parent^.EndDrawing;
  VeridianApp^.ActiveDropDown := nil;
  SetFocus(true, true);
end;

procedure TDropDownList.MouseDown(var AEvent: TMouseEvent);
begin
  if not IsEnabled then
    exit;
  if not FList^.IsVisible then begin
    ShowList;
  end
  else begin
    HideList;
  end;
end;

procedure DropDownIndexChanged(var AEvent: TIndexChangedEvent); far;
var
  list: PListView;
  dropDown: PDropDownList;
begin
  list := PListView(AEvent.Sender);
  dropDown := PDropDownList(list^.Parent);
  dropDown^.SelectedIndexChanged(AEvent);
end;

procedure TDropDownList.Init;
begin
  inherited Init;
  CanFocus := true;
  FButton := New(PDropDownButton, CreateParent('Button', @self));
  FButton^.SetCaption(#31);
  FList := New(PDropDownListView, CreateParent('List', @self));
  FList^.BorderStyle := bsSingle;
  FList^.OnKeyPress := @ListKeyPress;
  FList^.OnSelectedIndexChanged := @DropDownIndexChanged;
  FList^.AutoHeight := true;
  FList^.Visible := false;
  FList^.HorzScrollBar^.Position := rpParentRelative;
  FList^.VertScrollBar^.Position := rpParentRelative;
  FList^.Position := rpParentRelative;
  HorzAlign := haLeft;
  ForeColor := VeridianApp^.Colors.Editor;
  BackColor := VeridianApp^.Colors.EditorBack;
  DisabledColor := VeridianApp^.Colors.EditorDisabled;
  FocusedColor := VeridianApp^.Colors.Focused;
  FocusedBackColor := VeridianApp^.Colors.EditorFocusedBack;
  BorderColor := VeridianApp^.Colors.EditorBorder;
  VertAlign := vaCenter;
  Text := nil;
  MaxItems := MaxInt;
  AutoSize := true;
  FOldIndex := -1;
  BorderStyle := bsSingle;
  Padding.CreateValue(2);
  Font := VeridianApp^.Fonts^.GetItemById('editor');
  OnSelectedIndexChanged := nil;
end;

function TDropDownList.Items: PListItems;
begin
  Items := FList^.Items;
end;

procedure TDropDownList.AutoSizeControl;
var
  index, maxWidth: integer;
  listWidth: integer;
  itemWidth: integer;
  item: PListItem;
begin
  if AutoSize then begin
    maxWidth := 0;
    for index := 0 to FList^.Items^.Count - 1 do begin
      item := FList^.Items^.GetItem(index);
      itemWidth := FList^.Font^.TextWidthLarge(item^.Text);
      if itemWidth > maxWidth then
        maxWidth := itemWidth;
    end;
    listWidth := FButtonSize + maxWidth + 2 * OuterWidth
      + 2 * Padding.Width;
    Width := listWidth;
    Height := FButtonSize;
  end;
end;

procedure TDropDownList.LayoutRect(ARect: TRect);
var
  rect, listBounds: TRect;
  listHeight, itemCount: integer;
begin
  inherited LayoutRect(ARect);
  FButtonSize := 17;
  if Graph^.Mode^.Width <= 320 then
    FButtonSize := 11;

  AutoSizeControl;
  itemCount := Min(FList^.Items^.Count, MaxItems);
  listHeight := itemCount * FList^.ItemHeight + 2 * OuterWidth;
  listBounds.CreateDims(ARect.X, ARect.Bottom, ARect.Width, listHeight);
  FList^.SetBoundsRect(listBounds);
  FList^.BringToFront;

  FButton^.CanFocus := false;
  FButton^.SetBounds(
    Width - FButtonSize,
    0,
    FButtonSize,
    FButtonSize
  );
end;

function TDropDownList.GetText: string;
begin
  GetText := '';
  if Assigned(Text) then
    GetText := TString.GetString(Text);
end;

procedure TDropDownList.SetText(const AText: string);
begin
  TString.AssignString(Text, AText);
  Draw;
end;

function TDropDownList.List: PListView;
begin
  List := FList;
end;

destructor TDropDownList.Free;
begin
  TString.Free(Text);
  inherited Free;
end;

function TDropDownList.SelectedIndex: integer;
begin
  SelectedIndex := FList^.SelectedIndex;
end;

function TDropDownList.SelectedItem: PListItem;
begin
  SelectedItem := nil;
  if (SelectedIndex < 0) or (SelectedIndex > FList^.Items^.Count - 1) then
    exit;
  SelectedItem := FList^.Items^.GetItem(FList^.SelectedIndex);
end;

procedure TDropDownList.SetSelectedIndex(AIndex: integer);
var
  item: PListItem;
  txt: string;
begin
  FList^.SetSelectedIndex(AIndex);
  item := FList^.Items^.GetItem(AIndex);
  if Assigned(item) then
    txt := TString.GetString(item^.Text)
  else
    txt := '';
  SetText(txt);
end;

procedure TIndexChangedEvent.Assign(var ASource: TObject);
var
  source: PIndexChangedEvent;
begin
  inherited Assign(ASource);
  source := PIndexChangedEvent(@ASource);
  OldIndex := source^.OldIndex;
  NewIndex := source^.NewIndex;
  Trigger := source^.Trigger;
end;

procedure TIndexChangedEvent.Clear;
begin
  inherited Clear;
  OldIndex := -1;
  NewIndex := -1;
  Trigger := ctMouse;
end;

procedure TCheckListView.Init;
begin
  inherited Init;
end;

function TCheckListView.AddItem(const AText: string): PCheckListItem;
begin
  AddItem := PCheckListItem(inherited AddItem(AText));
end;

function TCheckListView.AddItemValue(const AText: string; AValue: pointer): PCheckListItem;
begin
  AddItemValue := PCheckListItem(inherited AddItemValue(AText, AValue));
end;

function TCheckListView.AddItemTag(const AText: string; ATag: longint): PCheckListItem;
begin
  AddItemTag := PCheckListItem(inherited AddItemTag(AText, ATag));
end;

function TCheckListView.AddItemAll(const AText: string; AValue: pointer;
  ATag: longint): PCheckListItem;
begin
  AddItemAll := PCheckListItem(inherited AddItemAll(AText, AValue, ATag));
end;

function TCheckListView.InsertItem(AIndex: integer; const AText: string): PCheckListItem;
begin
  InsertItem := PCheckListItem(inherited InsertItem(AIndex, AText));
end;

function TCheckListView.InsertItemValue(AIndex: integer; const AText: string;
  AValue: pointer): PCheckListItem;
begin
  InsertItemValue := PCheckListItem(inherited InsertItemValue(AIndex, AText, AValue));
end;

function TCheckListView.InsertItemTag(AIndex: integer; const AText: string; ATag: longint): PCheckListItem;
begin
  InsertItemTag := PCheckListItem(inherited InsertItemTag(AIndex, AText, ATag));
end;

function TCheckListView.InsertItemAll(AIndex: integer; const AText: string;
  AValue: pointer; ATag: longint): PCheckListItem;
begin
  InsertItemAll := PCheckListItem(inherited InsertItemAll(AIndex, AText, AValue, ATag));
end;

function TCheckListView.ItemHeight: integer;
var
  result: integer;
begin
  result := Max(Font^.Height + ItemSpacing, 17);
  ItemHeight := result;
end;

procedure TCheckListView.PaintItem(AIndex: integer);
var
  item: PCheckListItem;
begin
  inherited PaintItem(AIndex);
  item := CheckListItems^.GetItem(AIndex);
  if item^.CheckBox^.IsVisible then
    item^.CheckBox^.DrawSelf;
end;

procedure TCheckListView.LayoutRect(ARect: TRect);
var
  index: integer;
  item: PCheckListItem;
  itemRect: TRect;
begin
  inherited LayoutRect(ARect);
  for index := 0 to Items^.Count - 1 do begin
    item := CheckListItems^.GetItem(index);
    GetItemLayoutRect(index, itemRect);
    item^.CheckBox^.SetXY(itemRect.X, itemRect.Y);
    item^.CheckBox^.Layout;
    TextOffsetX := item^.CheckBox^.Width + 2;
    TextOffsetY := item^.CheckBox^.Height div 2 - item^.CheckBox^.Font^.Height div 2;
  end;
end;

function TCheckListView.CheckListItems: PCheckListItems;
begin
  CheckListItems := PCheckListItems(Items);
end;

function TCheckListView.Checked(AIndex: integer): boolean;
begin
  Checked := CheckListItems^.Checked(AIndex);
end;

procedure TCheckListView.SetChecked(AIndex: integer; AChecked: boolean);
begin
  CheckListItems^.SetChecked(AIndex, AChecked);
end;

function TCheckListView.CreateItems: PListItems;
begin
  CreateItems := New(PCheckListItems, Create(@self));
end;

function TCheckListView.CreateItem: PListItem;
var
  result: PCheckListItem;
begin
  result := New(PCheckListItem, Create);
  result^.Owner := @self;
  result^.CheckBox := New(PCheckBox, CreateParent('', @self));
  result^.CheckBox^.AutoSize := false;
  result^.CheckBox^.Width := 15;
  result^.CheckBox^.Height := 15;
  result^.CheckBox^.CanFocus := true;
  result^.CheckBox^.Checked := false;
  CreateItem := result;
end;

procedure TCheckListItem.Init;
begin
  inherited Init;
end;

procedure TCheckListItem.SetChecked(AValue: boolean);
begin
  CheckBox^.Checked := AValue;
  CheckBox^.Draw;
end;

function TCheckListItem.Checked: boolean;
begin
  Checked := CheckBox^.Checked;
end;

procedure TCheckListItems.Insert(AIndex: integer; AItem: PCheckListItem);
begin
  inherited Insert(AIndex, AItem);
end;

procedure TCheckListItems.RemoveItem(AItem: PCheckListItem);
begin
  inherited RemoveItem(AItem);
end;

function TCheckListItems.GetItem(AIndex: integer): PCheckListItem;
begin
  GetItem := PCheckListItem(inherited GetItem(AIndex));
end;

function TCheckListItems.GetItemByValue(AValue: pointer): PCheckListItem;
begin
  GetItemByValue := PCheckListItem(inherited GetItemByValue(AValue));
end;

function TCheckListItems.Add(AItem: PCheckListItem): integer;
begin
  Add := inherited Add(AItem);
end;

function TCheckListItems.IndexOf(AItem: PCheckListItem): integer;
begin
  IndexOf := inherited IndexOf(AItem);
end;

procedure TCheckListItems.SetItem(AIndex: integer; AItem: PCheckListItem);
begin
  inherited SetItem(AIndex, AItem);
end;

function TCheckListItems.Checked(AIndex: integer): boolean;
begin
  Checked := GetItem(AIndex)^.Checked;
end;

procedure TCheckListItems.Delete(AIndex: integer);
var
  index: integer;
  item: PCheckListItem;
  check: PCheckBox;
begin
  item := GetItem(AIndex);
  check := item^.CheckBox;
  index := Owner^.Controls^.IndexOf(check);
  Owner^.Controls^.Delete(index);
  Owner^.Draw;
  inherited Delete(AIndex);
end;

procedure TCheckListItems.SetChecked(AIndex: integer; AChecked: boolean);
var
  check: PCheckBox;
begin
  check := GetItem(AIndex)^.CheckBox;
  check^.SetChecked(AChecked);
end;

end.