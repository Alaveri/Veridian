{$I COMPILER.INC}
unit ListBox;

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
  PListBox = ^TListBox;
  PListItem = ^TListItem;
  PListItems = ^TListItems;
  PIndexChangedProc = ^TIndexChangedProc;
  PDropDownList = ^TDropDownList;
  PDropDownButton = ^TDropDownButton;
  PIndexChangedEvent = ^TIndexChangedEvent;
  PDropDownListBox = ^TDropDownListBox;

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
    Owner: PListBox;
    Text: PChar;
    Value: pointer;
    ImageIndex: integer;
    constructor CreateText(const AText: string);
    constructor CreateTextValue(const AText: string; AValue: pointer);
    procedure SetText(const AText: string);
    procedure Init; virtual;
    destructor Free; virtual;
  end;

  TListItems = object(TObjectList)
  private
  public
    Owner: PListBox;
    constructor Create(AOwner: PListBox);
    function GetItem(AIndex: integer): PListItem;
    function GetItemByValue(AValue: pointer): PListItem;
    function Add(AItem: PListItem): integer;
    function AddItem(const AText: string; AValue: pointer): integer;
    function AddText(const AText: string): integer;
    function IndexOf(AItem: PListItem): integer;
    function IndexOfValue(AValue: pointer): integer;
    procedure SetItem(AIndex: integer; AItem: PListItem);
    procedure Insert(AIndex: integer; AItem: PListItem);
    procedure RemoveItem(AItem: PListItem);
    procedure InsertItem(AIndex: integer; const AText: string; AValue: pointer);
    procedure InsertText(AIndex: integer; const AText: string);
  end;

  TListBox = object(TView)
  private
    procedure DrawItem(AIndex: integer);
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
    procedure Paint; virtual;
    procedure Layout; virtual;
    procedure SetSelectedIndex(AIndex: integer);
    procedure KeyPress(var AEvent: TKeyEvent); virtual;
    procedure MouseDown(var AEvent: TMouseEvent); virtual;
    procedure MouseWheelChanged(var AEvent: TMouseEvent); virtual;
    procedure SelectedIndexChanged(var AEvent: TIndexChangedEvent); virtual;
    procedure GetItemRect(AIndex: integer; var ARect: TRect); virtual;
    procedure ChangeSelect(ADelta: integer); virtual;
    procedure Clear; virtual;
    procedure DrawControls; virtual;
    procedure Draw; virtual;
    destructor Free; virtual;
  end;

  TDropDownButton = object(TButton)
  private
  public
    procedure Init; virtual;
    procedure Paint; virtual;
    procedure MouseDown(var AEvent: TMouseEvent); virtual;
  end;

  TDropDownListBox = object(TListBox)
  private
  public
    procedure Layout; virtual;
  end;

  TDropDownList = object(TFocusControl)
  private
    FButton: PDropDownButton;
    FList: PDropDownListBox;
    FButtonSize: integer;
  public
    MaxItems: integer;
    Text: PChar;
    procedure ShowList;
    procedure HideList;
    procedure Paint; virtual;
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
    procedure Layout; virtual;
    procedure SetText(const AText: string); virtual;
    procedure GetListBounds(var ARect: TRect); virtual;
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
end;

destructor TListItem.Free;
begin
  TString.Free(Text);
  inherited Free;
end;

procedure TListBox.GetContentExtent(var ASize: TSize);
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

procedure TListBox.Init;
begin
  inherited Init;
  TransparentBack := false;
  Font := VeridianApp^.SystemFont;
  ScrollType := scAsNeeded;
  HorzScrollBar^.Visible := false;
  CanFocus := true;
  Items := New(PListItems, Create(@self));
  OnSelectedIndexChanged := nil;
  SelectedIndex := -1;
  BorderStyle := bsSingle;
  BevelStyle := bvNone;
  VertScrollBar^.Position := spRelative;
  HorzScrollBar^.Position := spRelative;
  Font := VeridianApp^.Fonts^.GetItemById('editor');
  SelectedColor := VeridianApp^.Colors.ListSelected;
  SelectedBackColor := VeridianApp^.Colors.ListSelectedBack;
  UnfocusedSelectForeColor := VeridianApp^.Colors.ListUnfocusedSelect;
  UnfocusedSelectBackColor := VeridianApp^.Colors.ListUnfocusedSelectBack;
  Padding.CreateAll(2, 0, 2, 0);
  ItemSpacing := 4;
  VisibleItems := 10;
  AutoHeight := false;
end;

procedure TListBox.SetSelectedIndex(AIndex: integer);
var
  index: integer;
  rect, itemRect: TRect;
  previousIndex: integer;
  event: TIndexChangedEvent;
begin
  index := Clamp(AIndex, 0, Items^.Count - 1);
  if index = SelectedIndex then
    exit;
  previousindex := SelectedIndex;
  SelectedIndex := index;
  GetScreenBounds(rect);
  GetItemRect(SelectedIndex, itemRect);
  if itemRect.Y >= rect.Bottom then
    ScrollVert(itemRect.Y - rect.Bottom + ItemHeight);
  if itemRect.Y < rect.Y then
    ScrollVert(-(rect.Y - itemRect.Y));
  DrawItem(previousIndex);
  DrawItem(SelectedIndex);
  event.Create;
  event.NewIndex := SelectedIndex;
  event.OldIndex := previousIndex;
  event.Trigger := ctKeyboard;
  SelectedIndexChanged(event);
end;

function TListBox.SelectedItem: PListItem;
begin
  SelectedItem := nil;
  if (SelectedIndex < 0) or (SelectedIndex > Items^.Count - 1) then
    exit;
  SelectedItem := Items^.GetItem(SelectedIndex);
end;

destructor TListBox.Free;
begin
  FreeAndNil(Items);
  inherited Free;
end;

procedure TListBox.Focus;
begin
  SetFocus(true, false);
  DrawItem(SelectedIndex);
end;

procedure TListBox.Unfocus;
begin
  SetFocus(false, false);
  DrawItem(SelectedIndex);
end;

procedure TListBox.DrawItem(AIndex: integer);
begin
  BeginDrawing;
  PaintItem(AIndex);
  EndDrawing;
end;

procedure TListBox.GetItemRect(AIndex: integer; var ARect: TRect);
var
  cx: integer;
  cy: integer;
  itemWidth: integer;
  rect: TRect;
begin
  GetScreenBounds(rect);
  cy := rect.Y + AIndex * ItemHeight;
  itemWidth := rect.Width - BorderWidth;
  if VertScrollBar^.Visible then
    Dec(itemWidth, VertScrollBar^.Width);
  ARect.CreateDims(rect.X, cy, itemWidth, ItemHeight);
  ARect.Translate(BorderWidth, BorderWidth);
end;

function TListBox.ItemHeight: integer;
var
  result: integer;
begin
  result := Font^.Height + ItemSpacing;
  ItemHeight := result;
end;

procedure TListBox.PaintItem(AIndex: integer);
var
  rect, itemRect: TRect;
  item: PListItem;
  viewRect: TRect;
  clipRect: TRect;
begin
  if not IsVisible then
    exit;
  if (AIndex < 0) or (AIndex > Items^.Count - 1) then
    exit;
  Graph^.State^.Font := Font;
  item := Items^.GetItem(AIndex);
  GetClipRect(clipRect);
  GetItemRect(AIndex, itemRect);
  GetClientInnerBounds(viewRect);
  GetScreenBounds(rect);
  viewRect.Translate(rect.X, rect.Y);
  viewRect.Intersect(clipRect);
  itemRect.Translate(-ScrollX, -ScrollY);
  Graph^.State^.ViewPort := viewRect;
  if not itemRect.IntersectsRect(viewRect) then
    exit;

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
  Graph^.FillRect(itemRect);
  Graph^.DrawTextLarge(itemRect.X + Padding.Left,
    itemRect.Y + ItemSpacing div 2, item^.Text);
end;

function TListBox.GetSelectedIndex(AEvent: TMouseEvent): integer;
begin
  Inc(AEvent.Y, ScrollY);
  GetSelectedIndex := AEvent.Y div ItemHeight;
end;

procedure TListBox.SelectedIndexChanged(var AEvent: TIndexChangedEvent);
begin
  if AEvent.OldIndex = AEvent.NewIndex then
    exit;
  Invoke(OnSelectedIndexChanged, AEvent);
end;

procedure TListBox.MouseWheelChanged(var AEvent: TMouseEvent);
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

procedure TListBox.MouseDown(var AEvent: TMouseEvent);
var
  index: integer;
  previousIndex: integer;
  event: TIndexChangedEvent;
begin
  if not IsVisibleAndEnabled then
    exit;
  with AEvent do begin
    if CanFocus and not Focused then
      Focus;
    previousindex := SelectedIndex;
    SelectedIndex := GetSelectedIndex(AEvent);
    SelectedIndex := Clamp(SelectedIndex, 0, Items^.Count - 1);

    DrawItem(previousIndex);
    DrawItem(SelectedIndex);
    event.Create;
    event.NewIndex := SelectedIndex;
    event.OldIndex := previousIndex;
    event.Trigger := ctMouse;
    event.Sender := @self;
    SelectedIndexChanged(event);
  end;
  inherited MouseDown(AEvent);
end;

procedure TListBox.ChangeSelect(ADelta: integer);
begin
  SetSelectedIndex(SelectedIndex + ADelta);
end;

procedure TListBox.KeyPress(var AEvent: TKeyEvent);
var
  rect: TRect;
begin
  if not IsVisibleAndEnabled then
    exit;
  if not Focused then
    exit;
  AEvent.Handled := true;
  GetScreenBounds(rect);
  case AEvent.Key of
    kyDown: ChangeSelect(1);
    kyUp: ChangeSelect(-1);
    kyPageDown: ChangeSelect(rect.Height div Font^.Height - 1);
    kyPageUp: ChangeSelect(-rect.Height div Font^.Height + 1);
    kyEnd: ChangeSelect(Items^.Count - 1);
    kyHome: ChangeSelect(-Items^.Count - 1);
    else AEvent.Handled := false;
  end;
  if not AEvent.Handled then
    inherited KeyPress(AEvent);
end;

procedure TListBox.Draw;
begin
  inherited Draw;
end;

procedure TListBox.DrawControls;
begin
  inherited DrawControls;
end;

procedure TListBox.Layout;
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
  inherited Layout;
  GetClientInnerBounds(rect);
  VertScrollbar^.Increment := ItemHeight;
  VertScrollbar^.PageIncrement := Round(rect.Height / ItemHeight) * ItemHeight;
  max := Items^.Count * ItemHeight;
  Dec(max, rect.Height);
  VertScrollBar^.Max := AplMath.MaxL(0, max);
end;

procedure TListBox.Clear;
begin
  Items^.Clear;
  SelectedIndex := 0;
  ScrollY := 0;
  VertScrollbar^.ScrollPosition := 0;
end;

procedure TListBox.Paint;
var
  index: integer;
  oldFocusedColor: longint;
  oldFocusedBackColor: longint;
  rect: TRect;
  yPos: integer;
begin
  if not IsVisible then
    exit;
  oldFocusedColor := FocusedColor;
  oldFocusedBackColor := FocusedBackColor;
  FocusedColor := ForeColor;
  FocusedBackColor := BackColor;
  inherited Paint;
  FocusedColor := oldFocusedColor;
  FocusedBackColor := oldFocusedBackColor;
  for index := 0 to Items^.Count - 1 do
    DrawItem(index);
  Graph^.SetBackColor(BackColor);
  GetScreenBounds(rect);
  if Items^.Count * ItemHeight < rect.Height then begin
    yPos := rect.Y + Items^.Count * ItemHeight;
    rect.CreateDims(rect.X + OuterWidth, yPos, rect.Width - 2 * OuterWidth, rect.Bottom - yPos);
    Graph^.FillRect(rect);
  end;
end;

constructor TListItems.Create(AOwner: PListBox);
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
  Position := spClient;
end;

procedure TDropDownButton.Paint;
begin
  inherited Paint;
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

procedure TDropDownListBox.Layout;
var
  max: longint;
  rect: TRect;
  size: integer;
begin
  GetClientInnerBounds(rect);
  VertScrollbar^.Increment := ItemHeight;
  VertScrollbar^.PageIncrement := Round(rect.Height / ItemHeight) * ItemHeight;
  max := Items^.Count * ItemHeight;
  Dec(max, rect.Height);
  VertScrollBar^.Max := AplMath.MaxL(0, max);
  VertScrollBar^.X := Width - VertScrollBar^.Width;
  VertScrollBar^.Y := 0;
  VertScrollBar^.Width := VertScrollBar^.Size;
  VertScrollBar^.Height := Height;
end;

procedure ListKeyPress(var AEvent: TKeyEvent); far;
var
  dropDown: PDropDownList;
  self: PListBox;
begin
  self := PListBox(AEvent.Sender);
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

procedure TDropDownList.Paint;
var
  rect: TRect;
  pos: TPoint;
  txt: string;
begin
  if not IsVisible then
    exit;
  GetScreenBounds(rect);
  Graph^.State^.Font := Font;
  Graph^.SetForeColor(ForeColor);
  Graph^.SetBackColor(BackColor);
  txt := GetText;
  TControl.Paint;
  if CanFocus and Focused then
    Graph^.SetBackColor(FocusedBackColor);
  if not TransparentBack then
    Graph^.FillRect(rect);
  GetTextAlign(rect, pos);
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
    Graph^.Rectangle(rect);
end;

procedure TDropDownList.ShowList;
var
  activeControl: PFocusControl;
begin
  if FList^.IsVisible then
    exit;
  Layout;
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
  list: PListBox;
  dropDown: PDropDownList;
begin
  list := PListBox(AEvent.Sender);
  dropDown := PDropDownList(list^.Parent);
  dropDown^.SelectedIndexChanged(AEvent);
end;

procedure TDropDownList.Init;
begin
  inherited Init;
  CanFocus := true;
  FButton := New(PDropDownButton, CreateParent('Button', @self));
  FButton^.SetCaption(#31);
  FList := New(PDropDownListBox, CreateParent('List', @self));
  FList^.BorderStyle := bsSingle;
  FList^.OnKeyPress := @ListKeyPress;
  FList^.OnSelectedIndexChanged := @DropDownIndexChanged;
  FList^.AutoHeight := true;
  FList^.Visible := false;
  FList^.HorzScrollBar^.Position := spRelative;
  FList^.VertScrollBar^.Position := spRelative;
  FList^.Position := spRelative;
  HorzAlign := haLeft;
  ForeColor := VeridianApp^.Colors.Editor;
  BackColor := VeridianApp^.Colors.EditorBack;
  DisabledColor := VeridianApp^.Colors.EditorDisabled;
  FocusedColor := VeridianApp^.Colors.Focused;
  FocusedBackColor := VeridianApp^.Colors.EditorFocusedBack;
  BorderColor := VeridianApp^.Colors.EditorBorder;
  VertAlign := vaCenter;
  MaxItems := -1;
  AutoSize := true;
  BorderStyle := bsSingle;
  Padding.CreateValue(2);
  Font := VeridianApp^.Fonts^.GetItemById('editor');
end;

function TDropDownList.Items: PListItems;
begin
  Items := FList^.Items;
end;

procedure TDropDownList.GetListBounds(var ARect: TRect);
var
  index, maxWidth, listWidth, listHeight, itemWidth, itemCount: integer;
  item: PListItem;
begin
  itemCount := Min(FList^.Items^.Count, MaxItems);
  listHeight := itemCount * FList^.ItemHeight + 2 * OuterWidth;
  if AutoSize then begin
    maxWidth := 0;
    for index := 0 to FList^.Items^.Count - 1 do begin
      item := FList^.Items^.GetItem(index);
      itemWidth := FList^.Font^.TextWidthLarge(item^.Text);
      if itemWidth > maxWidth then
        maxWidth := itemWidth;
    end;
  end;
  itemWidth := maxWidth + 2 * Padding.Width + FButtonSize;
  listWidth := FButtonSize + itemWidth + 2 * OuterWidth;
  ARect.CreateDims(0, Height, listWidth, listHeight);
end;

procedure TDropDownList.Layout;
var
  listBounds: TRect;
begin
  inherited Layout;
  FButtonSize := 17;
  if Graph^.Mode^.Width <= 320 then
    FButtonSize := 11;

  GetListBounds(listBounds);
  FList^.SetBoundsRect(listBounds);
  FList^.VertScrollBar^.Visible := FList^.Items^.Count > MaxItems;
  FList^.BringToFront;
  Width := listBounds.Width;
  Height := FButtonSize;

  FButton^.CanFocus := false;
  FButton^.SetBounds(
    Width - FButtonSize - 1,
    -BorderWidth,
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