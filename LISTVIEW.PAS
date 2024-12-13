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
  Views;

type
  PListView = ^TListView;
  PListItem = ^TListItem;
  PListItems = ^TListItems;
  PIndexChangedProc = ^TIndexChangedProc;
  PDropDownList = ^TDropDownList;
  PDropDownButton = ^TDropDownButton;
  PIndexChangedEvent = ^TIndexChangedEvent;
  PDropDownListView = ^TDropDownListView;

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
    ImageIndex: integer;
    Tag: integer;
    constructor CreateText(const AText: string);
    constructor CreateTextValue(const AText: string; AValue: pointer);
    procedure SetText(const AText: string);
    procedure Init; virtual;
    destructor Free; virtual;
  end;

  TListItems = object(TObjectList)
  private
  public
    Owner: PListView;
    constructor Create(AOwner: PListView);
    function GetItem(AIndex: integer): PListItem;
    function GetItemByValue(AValue: pointer): PListItem;
    function Add(AItem: PListItem): integer;
    function AddItem(const AText: string; AValue: pointer): integer;
    function AddText(const AText: string): integer;
    function AddTag(const AText: string; ATag: integer): integer;
    function IndexOf(AItem: PListItem): integer;
    function IndexOfValue(AValue: pointer): integer;
    function IndexOfTag(ATag: integer): integer;
    procedure SetItem(AIndex: integer; AItem: PListItem);
    procedure Insert(AIndex: integer; AItem: PListItem);
    procedure RemoveItem(AItem: PListItem);
    procedure InsertItem(AIndex: integer; const AText: string; AValue: pointer);
    procedure InsertText(AIndex: integer; const AText: string);
    procedure InsertTag(AIndex: integer; const AText: string; ATag: integer);
  end;

  TListView = object(TView)
  private
    procedure PaintItem(AIndex: integer);
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
    function SelectedItem: PListItem;
    function GetSelectedIndex(AEvent: TMouseEvent): integer;
    function ItemHeight: integer;
    procedure GetContentExtent(var ASize: TSize); virtual;
    procedure Focus; virtual;
    procedure UnFocus; virtual;
    procedure Init; virtual;
    procedure Paint(ARect: TRect); virtual;
    procedure Layout(ARect: TRect); virtual;
    procedure GetAdjustedDrawRect(var ARect: TRect); virtual;
    procedure GetAdjustedClipRect(var ARect: TRect); virtual;
    procedure SetSelectedIndex(AIndex: integer);
    procedure KeyPress(var AEvent: TKeyEvent); virtual;
    procedure MouseDown(var AEvent: TMouseEvent); virtual;
    procedure MouseWheelChanged(var AEvent: TMouseEvent); virtual;
    procedure SelectedIndexChanged(var AEvent: TIndexChangedEvent); virtual;
    procedure GetItemRect(AIndex: integer; var ARect: TRect); virtual;
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
    procedure Layout(ARect: TRect); virtual;
  end;

  TDropDownList = object(TFocusControl)
  private
    FButton: PDropDownButton;
    FList: PDropDownListView;
    FButtonSize: integer;
  public
    MaxItems: integer;
    Text: PChar;
    procedure ShowList;
    procedure HideList;
    procedure Paint(ARect: TRect); virtual;
    function Items: PListItems;
    function SelectedIndex: integer;
    function SelectedItem: PListItem;
    function GetText: string;
    procedure SetSelectedIndex(AIndex: integer);
    procedure SelectedIndexChanged(var AEvent: TIndexChangedEvent);
    procedure MouseDown(var AEvent: TMouseEvent); virtual;
    procedure Unfocus; virtual;
    procedure KeyPress(var AEvent: TKeyEvent); virtual;
    procedure Init; virtual;
    procedure Layout(ARect: TRect); virtual;
    procedure SetText(const AText: string); virtual;
    procedure AutoSizeControl; virtual;
    destructor Free; virtual;
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
  SetText(AText);
end;

constructor TListItem.CreateTextValue(const AText: string; AValue: pointer);
begin
  CreateText(AText);
  Value := AValue;
end;

procedure TListItem.SetText(const AText: string);
begin
  TString.AssignString(Text, AText);
end;

procedure TListItem.Init;
begin
  inherited Init;
  Text := nil;
  Value := nil;
  ImageIndex := -1;
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
  TransparentBack := false;
  ScrollType := scAsNeeded;
  CanFocus := true;
  Items := New(PListItems, Create(@self));
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

procedure TListView.GetAdjustedDrawRect(var ARect: TRect);
begin
  inherited GetAdjustedDrawRect(ARect);
  ARect.Grow(OuterWidth, 0);
end;

procedure TListView.GetAdjustedClipRect(var ARect: TRect);
begin
  inherited GetAdjustedClipRect(ARect);
  ARect.Grow(OuterWidth, 0);
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
  GetAdjustedDrawRect(rect);
  GetItemRect(SelectedIndex, itemRect);
  if itemRect.Y >= rect.Bottom + ScrollY then
    ScrollVert((SelectedIndex - previousIndex) * itemRect.Height);
  if itemRect.Y < rect.Y + ScrollY then
    ScrollVert((SelectedIndex - previousIndex) * itemRect.Height);
  BeginDrawing;
  GetAdjustedClipRect(rect);
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

procedure TListView.GetItemRect(AIndex: integer; var ARect: TRect);
var
  cx: integer;
  cy: integer;
  clipRect, rect: TRect;
begin
  GetAdjustedDrawRect(rect);
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
  GetAdjustedClipRect(clipRect);
  Graph^.SetViewPort(clipRect);
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
  GetItemRect(AIndex, itemRect);
  itemRect.Translate(-ScrollX, -ScrollY);
  Graph^.FillRect(itemRect);
  Graph^.DrawTextLarge(itemRect.X + Padding.Left,
    itemRect.Y + ItemSpacing div 2, item^.Text);
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
  GetAdjustedClipRect(rect);
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
  GetAdjustedDrawRect(rect);
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

procedure TListView.Layout(ARect: TRect);
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
  inherited Layout(ARect);
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
  ScrollY := 0;
  VertScrollbar^.SetScrollPosition(0);
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
  GetAdjustedClipRect(clipRect);
  Graph^.SetViewPort(clipRect);
  for index := 0 to Items^.Count - 1 do
    PaintItem(index);
  Graph^.SetBackColor(BackColor);
  if Items^.Count * ItemHeight < ARect.Height then begin
    yPos := ARect.Y + Items^.Count * ItemHeight;
    ARect.CreateDims(ARect.X, yPos, ARect.Width, ARect.Bottom - yPos);
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

function TListItems.AddItem(const AText: string; AValue: pointer): integer;
var
  item: PListItem;
begin
  item := New(PListItem, Create);
  item^.Text := TString.New(AText);
  item^.Value := AValue;
  AddItem := inherited Add(item);
end;

function TListItems.AddText(const AText: string): integer;
begin
  AddText := AddItem(AText, nil);
end;

function TListItems.AddTag(const AText: string; ATag: integer): integer;
var
  item: PListItem;
begin
  item := New(PListItem, Create);
  item^.Text := TString.New(AText);
  item^.Tag := ATag;
  AddTag := inherited Add(item);
end;

procedure TListItems.InsertItem(AIndex: integer; const AText: string; AValue: pointer);
var
  item: PListItem;
begin
  item := New(PListItem, Create);
  item^.Text := TString.New(AText);
  item^.Value := AValue;
  inherited Insert(AIndex, item);
end;

procedure TListItems.InsertText(AIndex: integer; const AText: string);
begin
  InsertItem(AIndex, AText, nil);
end;

procedure TListItems.InsertTag(AIndex: integer; const AText: string; ATag: integer);
var
  item: PListItem;
begin
  item := New(PListItem, Create);
  item^.Text := TString.New(AText);
  item^.Tag := ATag;
  inherited Insert(AIndex, item);
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

function TListItems.IndexOfTag(ATag: integer): integer;
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
  SetText(StrPas(item^.Text));
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

procedure TDropDownListView.Layout(ARect: TRect);
var
  max: longint;
  rect: TRect;
  size: integer;
begin
  GetClientRect(rect);
  VertScrollbar^.Increment := ItemHeight;
  VertScrollbar^.PageIncrement := Round(rect.Height / ItemHeight) * ItemHeight;
  max := Items^.Count * ItemHeight;
  Dec(max, rect.Height);
  VertScrollBar^.Max := AplMath.MaxL(0, max);
end;

procedure ListKeyPress(var AEvent: TKeyEvent); far;
var
  dropDown: PDropDownList;
  self: PListView;
begin
  self := PListView(AEvent.Sender);
  if AEvent.Handled then
    exit;
  dropDown := PDropDownList(self^.Parent);
  case AEvent.Key of
    kyEnter: begin
      dropDown^.HideList;
      dropDown^.SetText(StrPas(self^.Items^.GetItem(self^.SelectedIndex)^.Text));
      AEvent.Handled := true;
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
  if not (CanFocus and Focused) then
    exit;
  case AEvent.Key of
    kyDown, kyEnter: begin
      if FList^.IsVisible then
        exit;
      AEvent.Handled := true;
      UnFocus;
      ShowList;
      exit;
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
  GetPaintRect(rect);
  Layout(rect);
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
  BorderStyle := bsSingle;
  Padding.CreateValue(2);
  Font := VeridianApp^.Fonts^.GetItemById('editor');
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

procedure TDropDownList.Layout(ARect: TRect);
var
  listBounds: TRect;
  listHeight, itemCount: integer;
begin
  inherited Layout(ARect);
  FButtonSize := 17;
  if Graph^.Mode^.Width <= 320 then
    FButtonSize := 11;

  AutoSizeControl;
  itemCount := Min(FList^.Items^.Count, MaxItems);
  listHeight := itemCount * FList^.ItemHeight + 2 * OuterWidth;
  listBounds.CreateDims(ARect.X, ARect.Bottom, ARect.Width, listHeight);
  FList^.SetBoundsRect(listBounds);
  FList^.VertScrollBar^.Visible := FList^.Items^.Count > MaxItems;
  FList^.BringToFront;

  FButton^.CanFocus := false;
  FButton^.SetBounds(
    ARect.Width - FButtonSize,
    0,
    FButtonSize,
    FButtonSize
  );
end;

function TDropDownList.GetText: string;
begin
  GetText := '';
  if Assigned(Text) then
    GetText := StrPas(Text);
end;

procedure TDropDownList.SetText(const AText: string);
begin
  TString.AssignString(Text, AText);
  Draw;
end;

destructor TDropDownList.Free;
begin
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
  FList^.SelectedIndex := AIndex;
  item := FList^.Items^.GetItem(AIndex);
  if Assigned(item) then
    txt := StrPas(item^.Text)
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

end.