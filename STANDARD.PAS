{$I COMPILER.INC}
unit Standard;

interface

uses
  AplObj,
  AplTypes,
  AplConst,
  VeriType,
  Drawing,
  Graphics,
  Palettes,
  Editors,
  Controls;

type
  PCheckBox = ^TCheckBox;
  PRadioButton = ^TRadioButton;
  PNumericUpDown = ^TNumericUpDown;

  TCheckBox = object(TFocusControl)
  private
  public
    Checked: boolean;
    BoxSize: integer;
    Spacing: integer;
    CheckFont: PFont;
    CheckChar: char;
    CheckOffset: TPoint;
    Down: boolean;
    TextOffsetY: integer;
    function IsCheckBox: boolean; virtual;
    procedure Init; virtual;
    procedure Layout; virtual;
    procedure Paint(ARect: TRect); virtual;
    procedure PaintGlyph; virtual;
    procedure DrawGlyph; virtual;
    procedure SetChecked(AValue: boolean);
    procedure SetBoxSize(AValue: integer);
    procedure MouseDown(var AEvent: TMouseEvent); virtual;
    procedure MouseClick(var AEvent: TMouseEvent); virtual;
    procedure MouseEnter(var AEvent: TMouseEvent); virtual;
    procedure MouseLeave(var AEvent: TMouseEvent); virtual;
    procedure KeyPress(var AEvent: TKeyEvent); virtual;
  end;

  TRadioButton = object(TCheckBox)
  private
    procedure DeactivateOthers;
  public
    function IsRadioButton: boolean; virtual;
    procedure Init; virtual;
    procedure MouseClick(var AEvent: TMouseEvent); virtual;
    procedure KeyPress(var AEvent: TKeyEvent); virtual;
  end;

  TNumericUpDown = object(TFocusControl)
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
    procedure SetBoundsRect(var ARect: TRect); virtual;
    procedure Paint(ARect: TRect); virtual;
    procedure Init; virtual;
    procedure Layout; virtual;
  end;

implementation

uses
  KeyDrv,
  AplUtils,
  AplMath,
  Veridian;

procedure TCheckBox.Init;
begin
  inherited Init;
  Checked := false;
  Font := VeridianApp^.GetFont('editor');
  CheckFont := VeridianApp^.GetFont('symbol');
  ForeColor := VeridianApp^.Colors.Button;
  BackColor := VeridianApp^.Colors.ButtonBack;
  FocusedColor := VeridianApp^.Colors.Focused;
  ShadowColor := VeridianApp^.Colors.ButtonShadow;
  LightColor := VeridianApp^.Colors.ButtonLight;
  DisabledColor := VeridianApp^.Colors.ButtonDisabled;
  BorderColor := VeridianApp^.Colors.ButtonBorder;
  CheckChar := #2;
  CheckOffset.CreateCoords(1, -2);
  Down := false;
  TextOffsetY := 3;
  FocusRectWidth := 1;
  BoxSize := Font^.Height + 2 * FocusRectWidth;
  Spacing := BoxSize div 2;
end;

function TCheckBox.IsCheckBox: boolean;
begin
  IsCheckBox := true;
end;

procedure TCheckBox.MouseDown(var AEvent: TMouseEvent);
var
  index: word;
  control: PControl;
  button: PButton;
begin
  if not IsVisibleAndEnabled then
    exit;
  if CanFocus then
    Focus;
  if bsLeft in AEvent.NewMouseState.ButtonState then
    VeridianApp^.LeftMouseDownControl := @self
  else if bsRight in AEvent.NewMouseState.ButtonState then
    VeridianApp^.RightMouseDownControl := @self;
  Down := true;
  Draw;
  inherited MouseDown(AEvent);
end;

procedure TCheckBox.MouseClick(var AEvent: TMouseEvent);
begin
  if not IsVisibleAndEnabled then
    exit;
  Down := false;
  Checked := not Checked;
  Draw;
  inherited MouseClick(AEvent);
end;

procedure TCheckBox.MouseEnter(var AEvent: TMouseEvent);
begin
  if not IsVisibleAndEnabled then
    exit;
  if VeridianApp^.LeftMouseDownControl = @self then begin
    Down := true;
    DrawSelf;
  end;
end;

procedure TCheckBox.MouseLeave(var AEvent: TMouseEvent);
begin
  if not IsVisibleAndEnabled then
    exit;
  if VeridianApp^.LeftMouseDownControl = @self then begin
    Down := false;
    DrawSelf;
  end;
end;

procedure TCheckBox.Layout;
begin
  inherited Layout;
  if AutoSize then begin
    Width := Font^.TextWidthLarge(Caption) + 2 * FocusRectWidth
      + BoxSize + Spacing + 1;
    Height := BoxSize + 2 * FocusRectWidth + 1;
  end;
end;

procedure TCheckBox.Paint(ARect: TRect);
var
  rect: TRect;
begin
  PaintGlyph;
  GetDrawRect(rect);
  Graph^.SetForeColor(ForeColor);
  Graph^.SetBackColor(BackColor);
  Graph^.State^.Font := Font;
  Graph^.DrawText(rect.X + BoxSize + Spacing, rect.Y + TextOffsetY, GetCaption);
end;

procedure TCheckBox.DrawGlyph;
begin
  BeginDrawing;
  PaintGlyph;
  EndDrawing;
end;

procedure TCheckBox.PaintGlyph;
var
  rect: TRect;
begin
  GetDrawRect(rect);
  rect.Width := BoxSize;
  rect.Height := BoxSize;
  rect.Translate(FocusRectWidth, FocusRectWidth);
  Graph^.SetBackColor(BackColor);
  Graph^.FillRect(rect);
  Graph^.SetBackColor(BorderColor);
  Graph^.Rectangle(rect);
  if Down then
    Graph^.SetForeColor(ShadowColor)
  else
    Graph^.SetForeColor(LightColor);
  Graph^.HLine(rect.X + 1, rect.Y + 1, BoxSize - 2);
  Graph^.VLine(rect.X + 1, rect.Y + 1, BoxSize - 2);
  if Down then
    Graph^.SetForeColor(LightColor)
  else
    Graph^.SetForeColor(ShadowColor);
  Graph^.HLine(rect.X + 1, rect.Y + BoxSize - 2, BoxSize - 2);
  Graph^.VLine(rect.X + BoxSize - 2, rect.Y + 1, BoxSize - 2);

  if Checked then begin
    Graph^.SetForeColor(ForeColor);
    Graph^.State^.Font := CheckFont;
    Graph^.DrawText(rect.X + CheckOffset.X, rect.Y + CheckOffset.Y, CheckChar);
  end;
  rect.Translate(-1, -1);
  rect.Grow(2, 2);
  if CanFocus then begin
    if Focused then
      Graph^.SetForeColor(FocusedBackColor)
    else begin
      if Assigned(Parent) and Parent^.IsVisualControl then
        Graph^.SetForeColor(PVisualControl(Parent)^.BackColor)
      else
        Graph^.SetForeColor(BackColor)
    end;
    Graph^.Rectangle(rect);
  end;
end;

procedure TCheckBox.SetChecked(AValue: boolean);
begin
  Checked := AValue;
  if IsVisible then
    DrawGlyph;
end;

procedure TCheckBox.SetBoxSize(AValue: integer);
begin
  Hide;
  BoxSize := AValue;
  Draw;
end;

procedure TCheckBox.KeyPress(var AEvent: TKeyEvent);
begin
  if not IsVisibleAndEnabled then
    exit;
  if not Focused then
    exit;
  if AEvent.Key = 32 then begin
    Checked := not Checked;
    Draw;
    AEvent.Handled := true;
  end;
  inherited KeyPress(AEvent);
end;

procedure TRadioButton.Init;
begin
  inherited Init;
  CheckChar := #3;
  CheckOffset.CreateCoords(3, -1);
end;

procedure TRadioButton.DeactivateOthers;
var
  index: word;
  control: PControl;
  button: PRadioButton;
begin
  if not Assigned(Parent) then
    exit;
  for index := 0 to Parent^.Controls^.Count - 1 do begin
    control := Parent^.Controls^.GetItem(index);
    if control = @self then
      continue;
    if control^.IsRadioButton then begin
      button := PRadioButton(control);
      button^.SetChecked(false);
    end;
  end;
end;

procedure TRadioButton.MouseClick(var AEvent: TMouseEvent);
var
  index: word;
  control: PControl;
  button: PButton;
begin
  if not IsVisibleAndEnabled then
    exit;
  DeactivateOthers;
  Down := false;
  Checked := true;
  DrawGlyph;
end;

procedure TRadioButton.KeyPress(var AEvent: TKeyEvent);
begin
  if not IsVisibleAndEnabled then
    exit;
  if not Focused then
    exit;
  if AEvent.Key = 32 then begin
    DeactivateOthers;
    Checked := true;
    DrawGlyph;
    AEvent.Handled := true;
  end;
  if not AEvent.Handled then
    inherited KeyPress(AEvent);
end;

function TRadioButton.IsRadioButton: boolean;
begin
  IsRadioButton := true;
end;

procedure NumericUpDownIncClick(var AEvent: TMouseEvent);
var
  numericUpDown: PNumericUpDown;
begin
  numericUpDown := PNumericUpDown(PControl(AEvent.Sender)^.Parent);
  numericUpDown^.SetValue(numericUpDown^.Value + numericUpDown^.Increment);
  if not numericUpDown^.FEntry^.Focused then
    numericupDown^.FEntry^.Focus;
end;

procedure NumericUpDownDecClick(var AEvent: TMouseEvent);
var
  numericUpDown: PNumericUpDown;
begin
  numericUpDown := PNumericUpDown(PControl(AEvent.Sender)^.Parent);
  numericUpDown^.SetValue(numericUpDown^.Value - numericUpDown^.Increment);
  if not numericupDown^.FEntry^.Focused then
    numericupDown^.FEntry^.Focus;
end;

procedure NumericUpDownKeyPress(var AEvent: TKeyEvent);
var
  numericUpDown: PNumericUpDown;
begin
  numericUpDown := PNumericUpDown(PControl(AEvent.Sender)^.Parent);
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

procedure NumericUpDownExit(var AEvent: TEvent);
var
  numericUpDown: PNumericUpDown;
  value: longint;
begin
  numericUpDown := PNumericUpDown(PControl(AEvent.Sender)^.Parent);
  value := StrToLong(numericUpDown^.FEntry^.GetText, -1);
  if (value = numericUpDown^.FValue) and not (value = -1) then
    exit;
  numericUpDown^.SetValue(value);
end;

procedure TNumericUpDown.SetBoundsRect(var ARect: TRect);
begin
  inherited SetBoundsRect(ARect);
  FEntry^.SetBounds(ARect.X + 16, 0, ARect.Width - 32, ARect.Height);
  FEntry^.MoveEnd;
end;

procedure TNumericUpDown.Init;
begin
  inherited Init;
  VeridianApp^.PushState;
  VeridianApp^.State.DrawEnabled := false;
  Font := VeridianApp^.GetFont('editor');
  CanFocus := false;
  FEntry := New(PEdit, CreateParent('Entry', @self));
  FEntry^.Font := Font;
  FEntry^.MaxLength := 9;
  FEntry^.CanFocus := true;
  FEntry^.Padding.CreateAll(2, 6, 2, 2);
  FEntry^.ValidChars := Numeric;
  FEntry^.OnKeyPress := @NumericUpDownKeyPress;
  FEntry^.OnExit := @NumericUpDownExit;

  FIncButton := New(PButton, CreateParent('IncButton', @self));
  FIncButton^.SetCaption(#30);
  FIncButton^.CanFocus := false;
  FIncButton^.OnMouseClick := @NumericUpDownIncClick;
  FDecButton := New(PButton, CreateParent('DecButton', @self));
  FDecButton^.SetCaption(#31);
  FDecButton^.OnMouseClick := @NumericUpDownDecClick;
  FDecButton^.CanFocus := false;
  FMinValue := 0;
  FMaxValue := 100;
  FIncrement := 1;
  FEditable := true;
  FValue := 0;
  FEntry^.VertAlign := vaCenter;
  FEntry^.Padding.CreateAll(3, 0, 2, 0);
  VeridianApp^.PopState;
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

procedure TNumericUpDown.Paint(ARect: TRect);
begin
  inherited Paint(ARect);
end;

procedure TNumericUpDown.SetValue(AValue: longint);
begin
  FValue := ClampL(AValue, FMinValue, FMaxValue);
  FEntry^.SetText(IntToStr(FValue));
end;

procedure TNumericUpDown.SetMaxValue(AValue: longint);
var
  oldValue: longint;
begin
  oldValue := FValue;
  FMaxValue := AValue;
  AValue := ClampL(FValue, FMinValue, FMaxValue);
  if oldValue <> AValue then
    FEntry^.SetText(IntToStr(AValue));
end;

procedure TNumericUpDown.SetMinValue(AValue: longint);
var
  oldValue: longint;
begin
  oldValue := FValue;
  FMinValue := AValue;
  AValue := ClampL(FValue, FMinValue, FMaxValue);
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

procedure TNumericUpDown.Layout;
var
  minWidth, maxWidth: integer;
  size: integer;
begin
  size := 17;
  if Graph^.Mode^.Width < 512 then
    size := 11;
  FEntry^.SetBounds(size - 1, 0, Width - 2 * (size - 1), Height);
  minWidth := Length(IntToStr(FMinValue));
  maxWidth := Length(IntToStr(FMaxValue));
  FEntry^.MaxLength := Max(minWidth, maxWidth);
  FDecButton^.SetBounds(0, 0, size, Height);
  FIncButton^.SetBounds(Width - size, 0, size, Height);
  inherited Layout;
end;

end.