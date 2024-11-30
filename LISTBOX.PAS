{$I COMPILER.INC}
unit ListBox;

interface

uses
  AplTypes,
  AplObj,
  Drawing,
  Lists,
  AplMath,
  Controls,
  Views;

type
  PListBox = ^TListBox;
  PListItem = ^TListItem;
  PListItems = ^TListItems;
  PIndexChangedProc = ^TIndexChangedProc;

  TIndexChangeTrigger = (ctMouse, ctKeyboard);

  TIndexChangedEvent = object(TEvent)
  private
  public
    OldIndex: integer;
    NewIndex: integer;
    Trigger: TIndexChangeTrigger;
  end;

  TIndexChangedProc = procedure(ASender: PObject; var AEvent: TIndexChangedEvent);

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
    function IndexOf(AItem: PListItem): integer;
    function IndexOfValue(AValue: pointer): integer;
    procedure SetItem(AIndex: integer; AItem: PListItem);
    procedure Insert(AIndex: integer; AItem: PListItem);
    procedure RemoveItem(AItem: PListItem);
    procedure InsertItem(AIndex: integer; const AText: string; AValue: pointer);
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
    function SelectedItem: PListItem;
    function GetSelectedIndex(AEvent: TMouseEvent): integer;
    function ItemHeight: integer;
    procedure Focus; virtual;
    procedure Unfocus; virtual;
    procedure Init; virtual;
    procedure Paint; virtual;
    procedure Layout; virtual;
    procedure KeyPress(var AEvent: TKeyEvent); virtual;
    procedure MouseDown(var AEvent: TMouseEvent); virtual;
    procedure MouseWheelChanged(var AEvent: TMouseEvent); virtual;
    procedure SelectedIndexChanged(var AEvent: TIndexChangedEvent); virtual;
    procedure GetItemRect(AIndex: integer; var ARect: TRect); virtual;
    procedure ChangeSelect(ADelta: integer); virtual;
    procedure Clear; virtual;
    destructor Free; virtual;
  end;

implementation

uses
  AplStr,
  AplUtils,
  Graphics,
  KeyDrv,
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
end;

destructor TListItem.Free;
begin
  TString.Free(Text);
  inherited Free;
end;

procedure TListBox.Init;
begin
  inherited Init;
  TransparentBack := false;
  Font := VeridianApp^.SystemFont;
  ScrollType := scVertical;
  CanFocus := true;
  Items := New(PListItems, Create(@self));
  OnSelectedIndexChanged := nil;
  SelectedIndex := -1;
  BorderStyle := bsSingle;
  BevelStyle := bvNone;
  Font := VeridianApp^.Fonts^.GetItemById('editor');
  SelectedColor := VeridianApp^.Colors.ListSelected;
  SelectedBackColor := VeridianApp^.Colors.ListSelectedBack;
  UnfocusedSelectForeColor := VeridianApp^.Colors.ListUnfocusedSelect;
  UnfocusedSelectBackColor := VeridianApp^.Colors.ListUnfocusedSelectBack;
  Padding.CreateValue(2);
  ItemSpacing := 1;
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
  rect: TRect;
begin
  GetContentScreenBounds(rect);
  cy := rect.Y + AIndex * ItemHeight - ScrollY;
  ARect.CreateDims(rect.X, cy, rect.Width, itemHeight);
end;

function TListBox.ItemHeight: integer;
begin
  ItemHeight := Font^.Height + 2 * ItemSpacing;
end;

procedure TListBox.PaintItem(AIndex: integer);
var
  itemRect: TRect;
  item: PListItem;
  rect: TRect;
begin
  if not IsVisible then
    exit;
  if (AIndex < 0) or (AIndex > Items^.Count - 1) then
    exit;
  Graph^.State^.Font := Font;
  GetContentScreenBounds(rect);
  item := Items^.GetItem(AIndex);
  GetItemRect(AIndex, itemRect);
  if not itemRect.IntersectsRect(rect) then
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
    itemRect.Y + Padding.Top, item^.Text);
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
  if Assigned(OnSelectedIndexChanged) then
    TIndexChangedProc(OnSelectedIndexChanged)(@self, AEvent);
end;

procedure TListBox.MouseWheelChanged(var AEvent: TMouseEvent);
var
  amount: integer;
begin
  inherited MouseWheelChanged(AEvent);
  if not VertScrollBar^.Visible then
    exit;
  amount := AEvent.NewMouseState.WheelCounter * Font^.Height;
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
    SelectedIndexChanged(event);
  end;
  inherited MouseDown(AEvent);
end;

procedure TListBox.ChangeSelect(ADelta: integer);
var
  index: integer;
  rect, itemRect: TRect;
  previousIndex: integer;
  event: TIndexChangedEvent;
begin
  index := Clamp(SelectedIndex + ADelta, 0, Items^.Count - 1);
  if index = SelectedIndex then
    exit;
  previousindex := SelectedIndex;
  SelectedIndex := index;
  GetContentScreenBounds(rect);
  GetItemRect(SelectedIndex, itemRect);
  if itemRect.Y > rect.Bottom then
    ScrollVert(itemRect.Y - rect.Bottom + Font^.Height - 1);
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

procedure TListBox.KeyPress(var AEvent: TKeyEvent);
var
  rect: TRect;
begin
  if not IsVisibleAndEnabled then
    exit;
  if not Focused then
    exit;
  AEvent.Handled := true;
  GetContentScreenBounds(rect);
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

procedure TListBox.Layout;
var
  max: longint;
  rect: TRect;
begin
  inherited Layout;
  GetContentBounds(rect);
  VertScrollbar^.Increment := Font^.Height;
  VertScrollbar^.PageIncrement := Round(rect.Height / Font^.Height) * Font^.Height;
  max := Items^.Count * Font^.Height + 1;
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
    PaintItem(index);
  Graph^.SetBackColor(BackColor);
  GetContentScreenBounds(rect);
  if Items^.Count * ItemHeight < rect.Height then begin
    yPos := rect.Y + Items^.Count * ItemHeight;
    rect.CreateDims(rect.X, yPos, rect.Width, rect.Bottom - yPos);
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

procedure TListItems.InsertItem(AIndex: integer; const AText: string; AValue: pointer);
var
  item: PListItem;
begin
  item := New(PListItem, Create);
  item^.Text := TString.New(AText);
  item^.Value := AValue;
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

end.