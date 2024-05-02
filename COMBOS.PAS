{$I COMPILER.INC}
unit Combos;

interface

uses
  Objects,
  Lists,
  ListBox,
  Drawing,
  Controls;

type
  PDropDownList = ^TDropDownList;

  TDropDownList = object(TActionControl)
  private
    FButton: PButton;
    FList: PListBox;
    FButtonSize: integer;
  public
    MaxItems: integer;
    AutoSize: boolean;
    procedure ShowList;
    procedure HideList;
    function Items: PListItems;
    function SelectedIndex: integer;
    procedure SetSelectedIndex(AIndex: integer);
    procedure MouseDown(var AEvent: TMouseEvent); virtual;
    procedure KeyPress(var AEvent: TKeyEvent); virtual;
    procedure Init; virtual;
    procedure Paint; virtual;
    procedure SetupControls; virtual;
    destructor Free; virtual;
  end;

implementation

uses
  Common,
  GraphApp,
  Veridian,
  KeyDrv,
  MouseDrv,
  Desk,
  Strings,
  GraphDrv;

procedure SelectedIndexChanged(ASender: PObject; var AEvent: TIndexChangedEvent); far;
var
  list: PListBox;
  dropDown: PDropDownList;
  item: PListItem;
begin
  list := PListBox(ASender);
  item := list^.Items^.GetItem(AEvent.NewIndex);
  dropDown := PDropDownList(list^.Parent);
  dropDown^.HideList;
  dropDown^.SetText(StrPas(item^.Text));
end;

procedure ButtonMouseDown(ASender: PObject; var AEvent: TMouseEvent); far;
var
  dropDown: PDropDownList;
  self: PButton;
begin
  self := PButton(ASender);
  dropDown := PDropDownList(self^.Parent);
  if not dropDown^.FList^.GetVisible then begin
    dropDown^.ShowList;
  end
  else begin
    dropDown^.HideList;
  end;
end;

procedure ListKeyPress(ASender: PObject; var AEvent: TKeyEvent); far;
var
  dropDown: PDropDownList;
  self: PListBox;
begin
  self := PListBox(ASender);
  dropDown := PDropDownList(self^.Parent);
  if not self^.GetVisible then begin
    case AEvent.Key of
      kyEsc: begin
        AEvent.Handled := true;
        dropDown^.HideList;
      end;
      kyTab: begin
        AEvent.Handled := true;
        dropDown^.HideList;
        VeridianApp^.FocusNext;
      end;
      kyShiftTab: begin
        AEvent.Handled := true;
        dropDown^.HideList;
        VeridianApp^.FocusPrevious;
      end;
    end;
  end
  else begin
  end;
end;

procedure TDropDownList.KeyPress(var AEvent: TKeyEvent);
begin
  case AEvent.Key of
    kyDown: begin
      if FList^.GetVisible then begin
        AEvent.Handled := true;
        ShowList;
        exit;
      end;
    end;
  end;
  inherited KeyPress(AEvent);
end;

procedure TDropDownList.Paint;
var
  rect: TRect;
  xPos, yPos: integer;
  txt: string;
begin
  if not GetVisible then
    exit;
  GetScreenBounds(rect);
  Graph^.State.Font := Font;
  Graph^.SetForeColor(ForeColor);
  Graph^.SetBackColor(BackColor);
  txt := GetText;
  if CanFocus and Focused then
    Graph^.SetBackColor(FocusedBackColor);
  if DrawBackground then
    Graph^.FillRect(rect);
  GetTextAlign(rect, xPos, yPos);
  Graph^.SetForeColor(ForeColor);
  Graph^.SetBackColor(BackColor);
  SetForeColorEnabled(ForeColor);
  if CanFocus and Focused then begin
    Graph^.SetForeColor(FocusedForeColor);
    Graph^.SetBackColor(FocusedBackColor);
  end;
  GetTextAlign(rect, xPos, yPos);
  Graph^.DrawText(xPos, yPos, txt);
  Graph^.SetForeColor(BorderColor);
  if BorderStyle <> bsNone then
    Graph^.Rectangle(rect);
end;

procedure TDropDownList.ShowList;
begin
  if FList^.GetVisible then
    exit;
  Inc(Height, FList^.Height);
  Desktop^.ActiveDropDown := @self;
  FList^.Visible := true;
  FList^.SetFocus(true, true);
end;

procedure TDropDownList.HideList;
var
  rect: TRect;
begin
  if not FList^.GetVisible then
    exit;
  FList^.GetScreenBounds(rect);
  rect.Translate(0, 1);
  rect.Grow(0, -1);
  Dec(Height, FList^.Height);
  FList^.Visible := false;
  Parent^.StartDrawingEx(false);
  Graph^.State.ViewPort.Assign(rect);
  Parent^.PaintRegion(rect);
  Parent^.EndDrawing;
  Desktop^.ActiveDropDown := nil;
  SetFocus(true, true);
end;

procedure TDropDownList.MouseDown(var AEvent: TMouseEvent);
begin
  TMouseEventProc(FButton^.OnMouseDown)(FButton, AEvent);
  inherited MouseDown(AEvent);
end;

procedure TDropDownList.Init;
begin
  inherited Init;
  CanFocus := true;
  FButton := New(PButton, CreateParent('Button', 0, @self));
  FButton^.SetText(#31);
  FButton^.OnMouseDown := @ButtonMouseDown;
  FList := New(PListBox, CreateParent('List', @self));
  FList^.BorderStyle := bsSingle;
  FList^.OnSelectedIndexChanged := @SelectedIndexChanged;
  FList^.OnKeyPress := @ListKeyPress;
  TextAlign := taLeft;
  ForeColor := Desktop^.Colors^.Editor;
  BackColor := Desktop^.Colors^.EditorBack;
  DisabledForeColor := Desktop^.Colors^.EditorDisabled;
  FocusedForeColor := Desktop^.Colors^.Focused;
  FocusedBackColor := Desktop^.Colors^.FocusedBack;
  VertAlign := vaCenter;
  MaxItems := -1;
  AutoSize := true;
  Margin := VeridianApp^.Scale(0.25);
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
  listHeight := itemCount * Font^.Height + 2 * FList^.BorderWidth;

  if AutoSize then begin
    maxWidth := 0;
    for index := 0 to FList^.Items^.Count - 1 do begin
      item := FList^.Items^.GetItem(index);
      maxWidth := Max(FList^.Font^.TextWidthLarge(item^.Text), maxWidth);
    end;
    Width := maxWidth + 2 * (BorderWidth + Margin) + FButtonSize;
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

  FList^.SetBounds(
    0,
    Height - 1,
    listWidth,
    listHeight
  );
  FList^.BringToFront;
end;

destructor TDropDownList.Free;
begin
  inherited Free;
end;

function TDropDownList.SelectedIndex: integer;
begin
  SelectedIndex := FList^.SelectedIndex;
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

end.