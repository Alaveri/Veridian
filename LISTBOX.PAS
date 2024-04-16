{$IFDEF debug}
  {$A-,B-,D+,F+,G-,I+,L+,N+,O-,P+,Q+,R+,S+,T-,V-,X+}
{$ELSE}
  {$A-,B-,D-,F+,G-,I+,L-,N+,O-,P+,Q+,R-,S-,T+,V-,X+}
{$ENDIF}
unit ListBox;

interface

uses
  Objects,
  Drawing,
  Images,
  Lists,
  Controls,
  Views;

type
  PListBox = ^TListBox;
  PListItem = ^TListItem;
  PListItems = ^TListItems;
  PSelectedIndexChangedProc = ^TSelectedIndexChangedProc;

  TSelectedIndexChangedEvent = object(TEvent)
  private
  public
    OldIndex: integer;
    NewIndex: integer;
  end;

  TSelectedIndexChangedProc = procedure(ASender: PObject; var AEvent: TSelectedIndexChangedEvent);

  TListItem = object(TObject)
  private
  public
    Text: PChar;
    Value: pointer;
    ImageIndex: integer;
    constructor CreateText(const AText: string);
    constructor CreateTextValue(const AText: string; AValue: pointer);
    constructor CreateAll(const AText: string; AValue: pointer; AImageIndex: integer);
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
    function IndexOf(AItem: PListItem): integer;
    function Add(AItem: PListItem): integer;
    procedure Insert(AIndex: integer; AItem: PListItem);
  end;

  TListBox = object(TView)
  private
    procedure DrawItem(AIndex: integer);
    procedure PaintItem(AIndex: integer);
  public
    Items: PListItems;
    ImageList: PImageList;
    Margin: integer;
    SelectedIndex: integer;
    UnfocusedSelectForeColor: byte;
    UnfocusedSelectBackColor: byte;
    OnSelectedIndexChanged: PSelectedIndexChangedProc;
    function GetAutoWidth: longint; virtual;
    function GetAutoHeight: longint; virtual;
    function SelectedItem: PListItem;
    function GetSelectedIndex(AEvent: TMouseEvent): integer;
    procedure Focus; virtual;
    procedure Unfocus; virtual;
    procedure Init; virtual;
    procedure Paint; virtual;
    procedure SetupControls; virtual;
    procedure KeyPress(var AEvent: TKeyEvent); virtual;
    procedure MouseDown(var AEvent: TMouseEvent); virtual;
    procedure MouseWheelChanged(var AEvent: TMouseEvent); virtual;
    procedure GetItemRect(AIndex: integer; var ARect: TRect); virtual;
    procedure ChangeSelect(ADelta: integer); virtual;
    procedure Clear; virtual;
    destructor Free; virtual;
  end;

implementation

uses
  StrUtils,
  Common,
  GraphDrv,
  KeyDrv,
  Veridian,
  Desk;

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

constructor TListItem.CreateAll(const AText: string; AValue: pointer; AImageIndex: integer);
begin
  CreateTextValue(AText, AValue);
  ImageIndex := AImageIndex;
end;

procedure TListItem.SetText(const AText: string);
begin
  TString.Assign(Text, AText);
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
  DrawBackground := false;
  Font := VeridianApp^.SystemFont;
  TitleBar^.Visible := false;
  ScrollType := scVertical;
  CanFocus := true;
  Items := New(PListItems, Create(@self));
  ImageList := new(PImageList, Create);
  OnSelectedIndexChanged := nil;
  SelectedIndex := -1;
  Margin := 3;
  UnfocusedSelectForeColor := Desktop^.Colors^.ListUnfocusedSelect;
  UnfocusedSelectBackColor := Desktop^.Colors^.ListUnfocusedSelectBack;
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
  FreeAndNil(ImageList);
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
  StartDrawingEx(false);
  PaintItem(AIndex);
  EndDrawing;
end;

procedure TListBox.GetItemRect(AIndex: integer; var ARect: TRect);
var
  cx: integer;
  cy: integer;
  rect: TRect;
begin
  Content^.GetScreenBounds(rect);
  cy := rect.Y + AIndex * Font^.Height - ScrollY;
  ARect.CreateDims(rect.X, cy, rect.Width, Font^.Height);
end;

procedure TListBox.PaintItem(AIndex: integer);
var
  itemRect: TRect;
  item: PListItem;
  rect: TRect;
begin
  if (AIndex < 0) or (AIndex > Items^.Count - 1) then
    exit;
  Graph^.State.Font := Font;
  Content^.GetScreenBounds(rect);
  Graph^.State.ViewPort := rect;
  item := Items^.GetItem(AIndex);
  GetItemRect(AIndex, itemRect);
  if not itemRect.IntersectsRect(rect) then
    exit;
  Graph^.SetForeColor(ForeColor);
  Graph^.SetBackColor(BackColor);
  if AIndex = SelectedIndex then begin
    if Focused then begin
      Graph^.SetForeColor(FocusedForeColor);
      Graph^.SetBackColor(FocusedBackColor);
    end
    else begin
      Graph^.SetForeColor(UnfocusedSelectForeColor);
      Graph^.SetBackColor(UnfocusedSelectBackColor);
    end;
  end;
  Graph^.FillRect(itemRect);
  Graph^.DrawTextLarge(itemRect.X + Margin, itemRect.Y, item^.Text);
end;

function TListBox.GetAutoWidth: longint;
begin
  GetAutoWidth := Width;
end;

function TListBox.GetAutoHeight: longint;
begin
  GetAutoHeight := Items^.Count * Font^.Height;
end;

function TListBox.GetSelectedIndex(AEvent: TMouseEvent): integer;
begin
  Inc(AEvent.Y, ScrollY);
  GetSelectedIndex := AEvent.Y div Font^.Height;
end;

procedure TListBox.MouseWheelChanged(var AEvent: TMouseEvent);
var
  amount: integer;
begin
  inherited MouseWheelChanged(AEvent);
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
  event: TSelectedIndexChangedEvent;
begin
  if not (GetEnabled and GetVisible) then
    exit;
  with AEvent do begin
    if CanFocus and not Focused then
      Focus;
    previousindex := SelectedIndex;
    SelectedIndex := GetSelectedIndex(AEvent);
    SelectedIndex := EnsureRange(SelectedIndex, 0, Items^.Count - 1);

    DrawItem(previousIndex);
    DrawItem(SelectedIndex);
    event.Create;
    if Assigned(OnSelectedIndexChanged) then begin
      event.NewIndex := SelectedIndex;
      event.OldIndex := previousIndex;
      TSelectedIndexChangedProc(OnSelectedIndexChanged)(@self, event);
    end;
  end;
  inherited MouseDown(AEvent);
end;

procedure TListBox.ChangeSelect(ADelta: integer);
var
  index: integer;
  rect, itemRect: TRect;
  previousIndex: integer;
  event: TSelectedIndexChangedEvent;
begin
  index := EnsureRange(SelectedIndex + ADelta, 0, Items^.Count - 1);
  if index = SelectedIndex then
    exit;
  previousindex := SelectedIndex;
  SelectedIndex := index;
  Content^.GetScreenBounds(rect);
  GetItemRect(SelectedIndex, itemRect);
  if itemRect.Y > rect.Bottom then
    ScrollVert(itemRect.Y - rect.Bottom + Font^.Height - 1);
  if itemRect.Y < rect.Y then
    ScrollVert(-(rect.Y - itemRect.Y));
  DrawItem(previousIndex);
  DrawItem(SelectedIndex);
  event.Create;
  if Assigned(OnSelectedIndexChanged) then begin
    event.NewIndex := SelectedIndex;
    event.OldIndex := previousIndex;
    TSelectedIndexChangedProc(OnSelectedIndexChanged)(@self, event);
  end;
end;

procedure TListBox.KeyPress(var AEvent: TKeyEvent);
begin
  if not Focused then
    exit;
  AEvent.Handled := true;
  case AEvent.Key of
    kyDown: ChangeSelect(1);
    kyUp: ChangeSelect(-1);
    kyPageDown: ChangeSelect(Content^.Height div Font^.Height - 1);
    kyPageUp: ChangeSelect(-Content^.Height div Font^.Height + 1);
    else AEvent.Handled := false;
  end;
  if not AEvent.Handled then
    inherited KeyPress(AEvent);
end;

procedure TListBox.SetupControls;
var
  max: longint;
begin
  inherited SetupControls;
  VertScrollbar^.Increment := Font^.Height;
  VertScrollbar^.PageIncrement := Round(Content^.Height / Font^.Height) * Font^.Height;
  max := GetAutoHeight;
  Dec(max, Content^.Height);
  VertScrollBar^.Max := max;
end;

procedure TListBox.Clear;
begin
  Items^.Clear;
  SelectedIndex := 0;
  ScrollY := 0;
  VertScrollbar^.CurrentPos := 0;
end;

procedure TListBox.Paint;
var
  index: integer;
  oldFocusedForeColor: longint;
  oldFocusedBackColor: longint;
  rect: TRect;
  yPos: integer;
begin
  oldFocusedForeColor := FocusedForeColor;
  oldFocusedBackColor := FocusedBackColor;
  FocusedForeColor := ForeColor;
  FocusedBackColor := BackColor;
  inherited Paint;
  FocusedForeColor := oldFocusedForeColor;
  FocusedBackColor := oldFocusedBackColor;
  for index := 0 to Items^.Count - 1 do
    PaintItem(index);
  Graph^.SetBackColor(BackColor);
  Content^.GetScreenBounds(rect);
  if Items^.Count * Font^.Height < Content^.Height then begin
    yPos := rect.Y + Items^.Count * Font^.Height;
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

function TListItems.IndexOf(AItem: PListItem): integer;
begin
  IndexOf := inherited IndexOf(AItem);
end;

function TListItems.Add(AItem: PListItem): integer;
begin
  Add := inherited Add(AItem);
end;

procedure TListItems.Insert(AIndex: integer; AItem: PListItem);
begin
  inherited Insert(AIndex, AItem);
end;

end.