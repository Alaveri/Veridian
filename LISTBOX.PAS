unit ListBox;

interface

uses
  Objects,
  Images,
  Controls,
  Views,
  Lists;

type
  PListBox = ^TListBox;
  PListItem = ^TListItem;
  PListItems = ^TListItems;

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
  public
    Items: PListItems;
    ImageList: PImageList;
    Margin: integer;
    SelectedIndex: integer;
    UnfocusedSelectForeColor: byte;
    UnfocusedSelectBackColor: byte;
    function SelectedItem: PListItem;
    procedure Focus; virtual;
    procedure Unfocus; virtual;
    procedure Init; virtual;
    procedure Paint; virtual;
    destructor Free; virtual;
  end;

implementation

uses
  StrUtils,
  GraphDrv,
  Veridian,
  Desk,
  Drawing;

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
  TString.Dispose(Text);
  inherited Free;
end;

procedure TListBox.Init;
begin
  inherited Init;
  Font := Application^.SystemFont;
  TitleBar^.Visible := false;
  ScrollType := scVertical;
  CanFocus := true;
  Items := New(PListItems, Create(@self));
  ImageList := new(PImageList, Create);
  SelectedIndex := -1;
  Margin := 3;
  UnfocusedSelectForeColor := Desktop^.InterfaceColors^.ListUnfocusedSelect;
  UnfocusedSelectBackColor := Desktop^.InterfaceColors^.ListUnfocusedSelectBack;
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
  Graph^.PushState;
  SetFocus(true, false);
  DrawItem(SelectedIndex);
  Graph^.PopState;
end;

procedure TListBox.Unfocus;
begin
  Graph^.PushState;
  SetFocus(false, false);
  DrawItem(SelectedIndex);
  Graph^.PopState;
end;

procedure TListBox.DrawItem(AIndex: integer);
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
  cy := rect.Y + AIndex * Font^.Height;
  itemRect.CreateDims(rect.X, cy, rect.Width, Font^.Height);
  if cy > rect.Bottom then
    exit;
  if cy + Graph^.State.Font^.Height < rect.Y then
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
    DrawItem(index);
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