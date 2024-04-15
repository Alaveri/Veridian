{$IFDEF debug}
  {$A-,B-,D+,F+,G-,I+,L+,N+,O-,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,F+,G-,I+,L-,N+,O-,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}
unit ListBox;

interface

uses
  Objects,
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
    procedure SelectDown;
    procedure SelectUp;
    procedure SelectPageDown;
    procedure SelectPageUp;
    procedure SelectDownLines(ALines: shortint);
    procedure SelectUpLines(ALines: shortint);
    destructor Free; virtual;
  end;

implementation

uses
  Drawing,
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

procedure TListBox.PaintItem(AIndex: integer);
var
  rect, itemRect: TRect;
  cx, cy: integer;
  item: PListItem;
begin
  if (AIndex < 0) or (AIndex > Items^.Count - 1) then
    exit;
  Content^.GetScreenBounds(rect);
  Graph^.State.Font := Font;
  Graph^.State.ViewPort := rect;
  item := Items^.GetItem(AIndex);
  cx := rect.X + Margin + BorderWidth;
  cy := rect.Y + AIndex * Font^.Height - ScrollY;
  itemRect.CreateDims(rect.X, cy, rect.Width, Font^.Height);
  if cy > rect.Bottom then
    exit;
  if cy + Font^.Height < rect.Y then
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
  Graph^.DrawTextLarge(cx, cy, item^.Text);
  Inc(cy, Font^.Height);
end;

function TListBox.GetAutoWidth: longint;
begin
  GetAutoWidth := Width;
end;

function TListBox.GetAutoHeight: longint;
begin
  GetAutoHeight := Items^.Count * Font^.Height;
end;

procedure TListBox.SelectDown;
var
  previousIndex: integer;
  amount: integer;
  event: TSelectedIndexChangedEvent;
begin
  if SelectedIndex + 1 >= Items^.Count then
    exit;
  if (SelectedIndex + 2) * Font^.Height > Height + ScrollY then begin
    amount := EnsureRange(VertScrollBar^.CurrentPos + VertScrollbar^.Increment,
      VertScrollBar^.Min, VertScrollBar^.Max);
    Inc(SelectedIndex);
    VertScrollBar^.SetCurrentPos(amount);
    if Assigned(OnSelectedIndexChanged) then begin
      event.NewIndex := SelectedIndex;
      event.OldIndex := previousIndex;
      TSelectedIndexChangedProc(OnSelectedIndexChanged)(@self, event);
    end;
    exit;
  end;
  previousindex := SelectedIndex;
  Inc(SelectedIndex);
  DrawItem(previousIndex);
  DrawItem(SelectedIndex);
  if Assigned(OnSelectedIndexChanged) then begin
    event.NewIndex := SelectedIndex;
    event.OldIndex := previousIndex;
    TSelectedIndexChangedProc(OnSelectedIndexChanged)(@self, event);
  end;
end;

procedure TListBox.SelectUp;
var
  previousIndex: integer;
  amount: integer;
  event: TSelectedIndexChangedEvent;
begin
  if SelectedIndex - 1 < 0 then
    exit;
  if (SelectedIndex - 1) * Font^.Height < ScrollY then begin
    amount := EnsureRange(VertScrollBar^.CurrentPos - VertScrollBar^.Increment,
      VertScrollBar^.Min, VertScrollBar^.Max);
    Dec(SelectedIndex);
    VertScrollBar^.SetCurrentPos(amount);
    if Assigned(OnSelectedIndexChanged) then begin
      event.NewIndex := SelectedIndex;
      event.OldIndex := previousIndex;
      TSelectedIndexChangedProc(OnSelectedIndexChanged)(@self, event);
    end;
    exit;
  end;
  previousindex := SelectedIndex;
  Dec(SelectedIndex);
  DrawItem(previousIndex);
  DrawItem(SelectedIndex);
  if Assigned(OnSelectedIndexChanged) then begin
    event.NewIndex := SelectedIndex;
    event.OldIndex := previousIndex;
    TSelectedIndexChangedProc(OnSelectedIndexChanged)(@self, event);
  end;
end;

procedure TListBox.SelectPageDown;
var
  previousIndex: integer;
  amount: integer;
  event: TSelectedIndexChangedEvent;
begin
  if VertScrollbar^.CurrentPos >= VertScrollbar^.Max then begin
    previousindex := SelectedIndex;
    SelectedIndex := Items^.Count - 1;
    DrawItem(previousIndex);
    DrawItem(SelectedIndex);
    if Assigned(OnSelectedIndexChanged) then begin
      event.NewIndex := SelectedIndex;
      event.OldIndex := previousIndex;
      TSelectedIndexChangedProc(OnSelectedIndexChanged)(@self, event);
    end;
    exit;
  end;
  amount := EnsureRange(VertScrollBar^.CurrentPos + VertScrollbar^.PageIncrement,
    VertScrollBar^.Min, VertScrollBar^.Max);
  VertScrollBar^.SetCurrentPos(amount);
  if SelectedIndex * Font^.Height < ScrollY then begin
    previousindex := SelectedIndex;
    SelectedIndex := Round(ScrollY / Font^.Height);
    DrawItem(previousIndex);
    DrawItem(SelectedIndex);
    if Assigned(OnSelectedIndexChanged) then begin
      event.NewIndex := SelectedIndex;
      event.OldIndex := previousIndex;
      TSelectedIndexChangedProc(OnSelectedIndexChanged)(@self, event);
    end;
  end;
end;

procedure TListBox.SelectPageUp;
var
  previousIndex: integer;
  amount: integer;
  event: TSelectedIndexChangedEvent;
begin
  if VertScrollbar^.CurrentPos <= 0 then begin
    previousindex := SelectedIndex;
    SelectedIndex := 0;
    DrawItem(previousIndex);
    DrawItem(SelectedIndex);
    if Assigned(OnSelectedIndexChanged) then begin
      event.NewIndex := SelectedIndex;
      event.OldIndex := previousIndex;
      TSelectedIndexChangedProc(OnSelectedIndexChanged)(@self, event);
    end;
    exit;
  end;
  amount := EnsureRange(VertScrollBar^.CurrentPos - VertScrollbar^.PageIncrement,
    VertScrollBar^.Min, VertScrollBar^.Max);
  VertScrollBar^.SetCurrentPos(amount);

  if SelectedIndex * Font^.Height - ScrollY > Content^.Height - Font^.Height then begin
    previousindex := SelectedIndex;
    SelectedIndex := Round((Content^.Height + ScrollY) / Font^.Height) - 1;
    DrawItem(previousIndex);
    DrawItem(SelectedIndex);
    if Assigned(OnSelectedIndexChanged) then begin
      event.NewIndex := SelectedIndex;
      event.OldIndex := previousIndex;
      TSelectedIndexChangedProc(OnSelectedIndexChanged)(@self, event);
    end;
  end;
end;

procedure TListBox.SelectDownLines(ALines: shortint);
var
  previousIndex: integer;
  amount: integer;
  event: TSelectedIndexChangedEvent;
begin
  if VertScrollbar^.CurrentPos >= VertScrollbar^.Max then begin
    previousindex := SelectedIndex;
    SelectedIndex := Items^.Count - 1;
    DrawItem(previousIndex);
    DrawItem(SelectedIndex);
    if Assigned(OnSelectedIndexChanged) then begin
      event.NewIndex := SelectedIndex;
      event.OldIndex := previousIndex;
      TSelectedIndexChangedProc(OnSelectedIndexChanged)(@self, event);
    end;
    exit;
  end;
  amount := EnsureRange(VertScrollBar^.CurrentPos + ALines * Font^.Height,
    VertScrollBar^.Min, VertScrollBar^.Max);
  VertScrollBar^.SetCurrentPos(amount);
  if SelectedIndex * Font^.Height < ScrollY then begin
    previousindex := SelectedIndex;
    SelectedIndex := Round(ScrollY / Font^.Height);
    DrawItem(previousIndex);
    DrawItem(SelectedIndex);
    if Assigned(OnSelectedIndexChanged) then begin
      event.NewIndex := SelectedIndex;
      event.OldIndex := previousIndex;
      TSelectedIndexChangedProc(OnSelectedIndexChanged)(@self, event);
    end;
  end;
end;

procedure TListBox.SelectUpLines(ALines: shortint);
var
  previousIndex: integer;
  amount: integer;
  event: TSelectedIndexChangedEvent;
begin
  if VertScrollbar^.CurrentPos <= 0 then begin
    previousindex := SelectedIndex;
    SelectedIndex := 0;
    DrawItem(previousIndex);
    DrawItem(SelectedIndex);
    if Assigned(OnSelectedIndexChanged) then begin
      event.NewIndex := SelectedIndex;
      event.OldIndex := previousIndex;
      TSelectedIndexChangedProc(OnSelectedIndexChanged)(@self, event);
    end;
    exit;
  end;
  amount := EnsureRange(VertScrollBar^.CurrentPos + ALines * Font^.Height,
    VertScrollBar^.Min, VertScrollBar^.Max);
  VertScrollBar^.SetCurrentPos(amount);

  if SelectedIndex * Font^.Height - ScrollY > Content^.Height - Font^.Height then begin
    previousindex := SelectedIndex;
    SelectedIndex := Round((Content^.Height + ScrollY) / Font^.Height) - 1;
    DrawItem(previousIndex);
    DrawItem(SelectedIndex);
    if Assigned(OnSelectedIndexChanged) then begin
      event.NewIndex := SelectedIndex;
      event.OldIndex := previousIndex;
      TSelectedIndexChangedProc(OnSelectedIndexChanged)(@self, event);
    end;
  end;
end;

function TListBox.GetSelectedIndex(AEvent: TMouseEvent): integer;
begin
  Inc(AEvent.Y, ScrollY);
  GetSelectedIndex := AEvent.Y div Font^.Height;
end;

procedure TListBox.MouseWheelChanged(var AEvent: TMouseEvent);
begin
  inherited MouseWheelChanged(AEvent);
  if AEvent.NewMouseState.WheelCounter > 0 then
    SelectDownLines(AEvent.NewMouseState.WheelCounter)
  else if AEvent.NewMouseState.WheelCounter < 0 then
    SelectUpLines(AEvent.NewMouseState.WheelCounter)
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

procedure TListBox.KeyPress(var AEvent: TKeyEvent);
begin
  if not Focused then
    exit;
  AEvent.Handled := true;
  case AEvent.Key of
    kyDown: SelectDown;
    kyUp: SelectUp;
    kyPageDown: SelectPageDown;
    kyPageUp: SelectPageUp;
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

procedure TListBox.Paint;
var
  index: integer;
  oldFocusedForeColor: longint;
  oldFocusedBackColor: longint;
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