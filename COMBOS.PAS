{$I COMPILER.INC}
unit Combos;

interface

uses
  Objects,
  Lists,
  ListBox,
  Drawing,
  Veridian,
  Controls;

type
  PDropDownList = ^TDropDownList;

  TDropDownList = object(TTextControl)
  private
    FButton: PButton;
    FList: PListBox;
    FButtonSize: integer;
  public
    MaxItems: integer;
    AutoSize: boolean;
    function Items: PListItems;
    function SelectedIndex: integer;
    procedure SetSelectedIndex(AIndex: integer);
    procedure Init; virtual;
    procedure SetupControls; virtual;
    destructor Free; virtual;
  end;

implementation

uses
  Common,
  Desk,
  GraphDrv;

procedure ButtonMouseDown(ASender: PObject; var AEvent: TMouseEvent); far;
var
  dropDown: PDropDownList;
  self: PButton;
  list: PListBox;
begin
  self := PButton(ASender);
  dropDown := PDropDownList(self^.Parent);
  list := dropDown^.FList;
  list^.Show;
  List^.Focus;
end;

procedure TDropDownList.Init;
begin
  inherited Init;
  CanFocus := true;
  FButton := New(PButton, CreateParent('Button', 0, @self));
  FButton^.SetText(#31);
  FButton^.OnMouseDown := @ButtonMouseDown;
  FList := New(PListBox, CreateParent('List', Desktop));
  FList^.BorderStyle := bsSingle;
  MaxItems := -1;
  AutoSize := true;
  Margin := VeridianApp^.Scale(0.8);
end;

function TDropDownList.Items: PListItems;
begin
  Items := FList^.Items;
end;

procedure TDropDownList.SetupControls;
var
  listWidth, listHeight: integer;
  index: integer;
  item: PListItem;
  itemCount: integer;
  maxWidth: integer;
  rect: TRect;
begin
  inherited SetupControls;
  FButtonSize := 16;
  if Graph^.Mode^.Width <= 320 then
    FButtonSize := 11;

  itemCount := Items^.Count;
  if MaxItems > 0 then
    itemCount := MaxItems;
  listHeight := itemCount * Font^.Height + FList^.BorderWidth;

  if AutoSize then begin
    maxWidth := 0;
    for index := 0 to FList^.Items^.Count - 1 do begin
      item := FList^.Items^.GetItem(index);
      maxWidth := Max(FList^.Font^.TextWidthLarge(item^.Text), maxWidth);
    end;
    Width := maxWidth + 2 * (BorderWidth + Margin);
    Height := Font^.Height + 2 * BorderWidth;
  end;

  FButton^.CanFocus := false;
  FButton^.SetBounds(
    Width - FButtonSize,
    0,
    FButtonSize,
    Font^.Height + 2 * BorderWidth
  );

  listWidth := Width;
  FList^.VertScrollBar^.Visible := FList^.Items^.Count > itemCount;
  FList^.Visible := false;

  GetScreenBounds(rect);
  FList^.SetBounds(
    rect.X,
    rect.Y + Height - 1,
    listWidth,
    listHeight
  );
end;

destructor TDropDownList.Free;
begin
  Desktop^.Controls^.Remove(FList);
  FreeAndNil(FList);
  inherited Free;
end;

function TDropDownList.SelectedIndex: integer;
begin
  SelectedIndex := FList^.SelectedIndex;
end;

procedure TDropDownList.SetSelectedIndex(AIndex: integer);
begin
  FList^.SelectedIndex := AIndex;
end;

end.