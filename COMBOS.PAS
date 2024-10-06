{$I COMPILER.INC}
unit Combos;

interface

uses
  AplTypes,
  AplObj,
  Lists,
  ListBox,
  Drawing,
  Editors,
  Controls;

type
  PDropDownList = ^TDropDownList;
  PNumericUpDown = ^TNumericUpDown;

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
    function SelectedItem: PListItem;
    procedure SetSelectedIndex(AIndex: integer);
    procedure MouseDown(var AEvent: TMouseEvent); virtual;
    procedure KeyPress(var AEvent: TKeyEvent); virtual;
    procedure Init; virtual;
    procedure Paint; virtual;
    procedure SetupControls; virtual;
    destructor Free; virtual;
  end;

  TNumericUpDown = object(TPanel)
  private
    FValue: longint;
    FMinValue: longint;
    FMaxValue: longint;
    FIncButton: PButton;
    FDecButton: PButton;
    FEntry: PEdit;
    FIncrement: longint;
    FEditable: boolean;
  public
    function Value: longint;
    function MinValue: longint;
    function MaxValue: longint;
    function Increment: longint;
    function Editable: boolean;
    procedure SetValue(AValue: longint);
    procedure SetMaxValue(AValue: longint);
    procedure SetMinValue(AValue: longint);
    procedure SetIncrement(AValue: longint);
    procedure SetEditable(AValue: boolean);
    procedure Init; virtual;
    procedure SetupControls; virtual;
  end;

implementation

uses
  Common,
  GraphApp,
  Veridian,
  KeyDrv,
  MouseDrv,
  Views,
  Desk,
  Strings,
  StrUtils,
  GraphDrv;

procedure SelectedIndexChanged(ASender: PObject; var AEvent: TIndexChangedEvent); far;
var
  list: PListBox;
  dropDown: PDropDownList;
  item: PListItem;
begin
  if AEvent.Trigger = ctKeyboard then
    exit;
  list := PListBox(ASender);
  item := list^.Items^.GetItem(AEvent.NewIndex);
  dropDown := PDropDownList(list^.Parent);
  Graph8^.HideMouseCursor;
  dropDown^.HideList;
  dropDown^.SetText(StrPas(item^.Text));
  Graph8^.ShowMouseCursor;
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
  case AEvent.Key of
    kyEnter: begin
      Graph8^.HideMouseCursor;
      dropDown^.HideList;
      dropDown^.SetText(StrPas(self^.Items^.GetItem(self^.SelectedIndex)^.Text));
      Graph8^.ShowMouseCursor;
    end;
    kyTab: begin
      AEvent.Handled := true;
      dropDown^.HideList;
      VeridianApp^.FocusNext(@self, false);
    end;
    kyShiftTab: begin
      AEvent.Handled := true;
      dropDown^.HideList;
      VeridianApp^.FocusNext(@self, true);
      end;
  end;
end;

procedure TDropDownList.KeyPress(var AEvent: TKeyEvent);
begin
  if CanFocus and Focused then begin
    case AEvent.Key of
      kyDown, kyEnter: begin
        if not FList^.GetVisible then begin
          AEvent.Handled := true;
          UnFocus;
          ShowList;
          exit;
        end;
      end;
    end;
  end;
 if not AEvent.Handled then
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
  if Assigned(Desktop^.ActiveControl) and (Desktop^.ActiveControl <> @self) then begin
    Desktop^.ActiveControl^.Focused := false;
    Desktop^.ActiveControl^.Draw;
  end;
  Desktop^.ActiveControl := nil;
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
  Parent^.PaintRegion(rect, @self);
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
  TextAlign := haLeft;
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
  if FList^.VertScrollBar^.Visible then
    FList^.ScrollType := scVertical
  else
    FList^.ScrollType := scNone;

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

procedure NumericUpDownIncClick(ASender: PObject; var AEvent: TMouseEvent);
var
  numericUpDown: PNumericUpDown;
begin
  numericUpDown := PNumericUpDown(PControl(ASender)^.Parent);
  numericUpDown^.FEntry^.Focus;
  numericUpDown^.SetValue(numericUpDown^.Value + numericUpDown^.Increment);
end;

procedure NumericUpDownDecClick(ASender: PObject; var AEvent: TMouseEvent);
var
  numericUpDown: PNumericUpDown;
begin
  numericUpDown := PNumericUpDown(PControl(ASender)^.Parent);
  numericUpDown^.FEntry^.Focus;
  numericUpDown^.SetValue(numericUpDown^.Value - numericUpDown^.Increment);
end;

procedure NumericUpDownKeyPress(ASender: PObject; var AEvent: TKeyEvent);
var
  numericUpDown: PNumericUpDown;
begin
  numericUpDown := PNumericUpDown(PControl(ASender)^.Parent);
  case AEvent.Key of
    kyUp: begin
      numericUpDown^.SetValue(numericUpDown^.Value + numericUpDown^.Increment);
      AEvent.Handled := true;
    end;
    kyDown: begin
      numericUpDown^.SetValue(numericUpDown^.Value - numericUpDown^.Increment);
      AEvent.Handled := true;
    end;
  end;
end;


procedure NumericUpDownExit(ASender: PObject; var AEvent: TEvent);
var
  numericUpDown: PNumericUpDown;
  value: longint;
begin
  numericUpDown := PNumericUpDown(PControl(ASender)^.Parent);
  value := StrToLong(numericUpDown^.FEntry^.GetText, -1);
  if (value = numericUpDown^.FValue) and not (value = -1) then
    exit;
  numericUpDown^.SetValue(value);
end;

procedure TNumericUpDown.Init;
begin
  inherited Init;
  CanFocus := false;
  FEntry := New(PEdit, CreateParent('Entry', @self));
  FEntry^.Font := Font;
  FEntry^.MaxLength := 9;
  FEntry^.CanFocus := true;
  FEntry^.ValidChars := Numeric;
  FEntry^.OnKeyPress := @NumericUpDownKeyPress;
  FEntry^.OnExit := @NumericUpDownExit;
  FIncButton := New(PButton, CreateParent('IncButton', 0, @self));
  FIncButton^.SetText(#24);
  FIncButton^.CanFocus := false;
  FIncButton^.OnMouseClick := @NumericUpDownIncClick;
  FDecButton := New(PButton, CreateParent('DecButton', 0, @self));
  FDecButton^.SetText(#25);
  FDecButton^.OnMouseClick := @NumericUpDownDecClick;
  FDecButton^.CanFocus := false;
  Width := 32 + Font^.TextWidth('9999');
  Height := Font^.Height + 2 * BorderWidth + 2;
  FMinValue := 0;
  FMaxValue := 100;
  FIncrement := 1;
  FEditable := true;
  FValue := 0;
end;

function TNumericUpDown.Value: longint;
begin
  Value := FValue;
end;

function TNumericUpDown.MinValue: longint;
begin
  MinValue := FMinValue;
end;

function TNumericUpDown.MaxValue: longint;
begin
  MaxValue := FMaxValue;
end;

function TNumericUpDown.Increment: longint;
begin
  Increment := FIncrement;
end;

function TNumericUpDown.Editable: boolean;
begin
  Editable := FEditable;
end;

procedure TNumericUpDown.SetValue(AValue: longint);
begin
  FValue := EnsureRange(AValue, FMinValue, FMaxValue);
  FEntry^.SetText(IntToStr(FValue));
end;

procedure TNumericUpDown.SetMaxValue(AValue: longint);
var
  oldValue: longint;
begin
  oldValue := FValue;
  FMaxValue := AValue;
  AValue := EnsureRange(FValue, FMinValue, FMaxValue);
  if oldValue <> AValue then
    FEntry^.SetText(IntToStr(AValue));
end;

procedure TNumericUpDown.SetMinValue(AValue: longint);
var
  oldValue: longint;
begin
  oldValue := FValue;
  FMinValue := AValue;
  AValue := EnsureRange(FValue, FMinValue, FMaxValue);
  if oldValue <> AValue then
    FEntry^.SetText(IntToStr(AValue));
end;

procedure TNumericUpDown.SetIncrement(AValue: longint);
begin
  FIncrement := AValue;
end;

procedure TNumericUpDown.SetEditable(AValue: boolean);
begin
  FEditable := AValue;
  FEntry^.CanEdit := FEditable;
  if FEntry^.Focused and not FEditable then
    FEntry^.UnFocus;
end;

procedure TNumericUpDown.SetupControls;
var
  rect: TRect;
  minWidth, maxWidth: integer;
begin
  inherited SetupControls;
  FIncButton^.SetBounds(0, 0, 16, Height);
  FDecButton^.SetBounds(Width - 16, 0, 16, Height);
  FEntry^.SetBounds(15, 0, Width - 30, Height);
  minWidth := Length(IntToStr(FMinValue));
  maxWidth := Length(IntToStr(FMaxValue));
  FEntry^.MaxLength := Max(minWidth, maxWidth);
end;

end.