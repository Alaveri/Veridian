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

  TDropDownList = object(TPanel)
  private
    FButton: PButton;
    FList: PListBox;
    FButtonSize: integer;
  public
    MaxItems: integer;
    Margin: integer;
    AutoSize: boolean;
    procedure Init; virtual;
    procedure SetupControls; virtual;
  end;

implementation

uses
  Common,
  GraphDrv;

procedure TDropDownList.Init;
begin
  inherited Init;
  CanFocus := true;
  FButton := New(PButton, CreateParent('Button', 0, @self));
  FList := New(PListBox, CreateParent('List', @self));
  MaxItems := -1;
  AutoSize := true;
  Margin := VeridianApp^.Scale(0.8);
end;

procedure TDropDownList.SetupControls;
var
  bounds: TRect;
  listWidth, listHeight: integer;
  index: integer;
  item: PListItem;
  itemCount: integer;
  maxWidth: integer;
begin
  inherited SetupControls;
  FButtonSize := 16;
  if Graph^.Mode^.Width <= 320 then
    FButtonSize := 11;

  GetBounds(bounds);
  FButton^.SetBounds(
    bounds.Right - FButtonSize + BorderWidth,
    0,
    FButtonSize,
    FButtonSize
  );

  itemCount := FList^.Items^.Count;
  if MaxItems > 0 then
    itemCount := MaxItems;
  listHeight := itemCount * Font^.Height + 2 * FList^.BorderWidth;

  if AutoSize then begin
    maxWidth := 0;
    for index := 0 to FList^.Items^.Count - 1 do begin
      item := FList^.Items^.GetItem(index);
      maxWidth := Max(FList^.Font^.TextWidthLarge(item^.Text), maxWidth);
    end;
    Width := maxWidth + FButtonSize + BorderWidth + 2 * Margin;
  end;
  listWidth := Width;
  FList^.VertScrollBar^.Visible := FList^.Items^.Count > itemCount;

  FList^.SetBounds(
    0,
    bounds.Bottom,
    listWidth,
    listHeight
  );
end;

end.