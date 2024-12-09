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
    procedure Paint; virtual;
    procedure PaintGlyph; virtual;
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
    procedure PaintGlyph; virtual;
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
  BoxSize := Font^.Height + 2;
  Spacing := BoxSize div 2;
  CheckChar := #2;
  CheckOffset.CreateCoords(1, -2);
  Down := false;
  TextOffsetY := 2;
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
  Padding.CreateAll(Font^.Height + Spacing, TextOffsetY, 0, 0);
  if AutoSize then begin
    Width := ContentWidth + Padding.Width + 2 * OuterWidth;
    Height := ContentHeight + Padding.Height + 2 * OuterWidth;
  end;
end;

procedure TCheckBox.Paint;
var
  rect: TRect;
  oldFocusBackColor: byte;
  oldFocusColor: byte;
begin
  oldFocusColor := FocusedColor;
  oldFocusBackColor := FocusedBackColor;
  FocusedBackColor := BackColor;
  FocusedColor := ForeColor;
  inherited Paint;
  FocusedBackColor := oldFocusBackColor;
  FocusedColor := oldFocusColor;
  PaintGlyph;
end;

procedure TCheckBox.PaintGlyph;
var
  focusRect, rect: TRect;
begin
  GetScreenBounds(rect);
  rect.Width := BoxSize;
  rect.Height := BoxSize;
  focusRect.CreateRect(rect);
  focusRect.Translate(-1, -1);
  focusRect.Grow(2, 2);
  Graph^.SetForeColor(BorderColor);
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
    Graph^.PushState;
    Graph^.SetForeColor(ForeColor);
    Graph^.State^.Font := CheckFont;
    Graph^.DrawText(rect.X + CheckOffset.X, rect.Y + CheckOffset.Y, CheckChar);
    Graph^.PopState;
  end;
  if CanFocus then begin
    Graph^.PushState;
    Graph^.State^.ViewPort := focusRect;
    if Focused then
      Graph^.SetForeColor(FocusedBackColor)
    else
      Graph^.SetForeColor(BackColor);
    Graph^.Rectangle(focusRect);
    Graph^.PopState;
  end;
end;

procedure TCheckBox.SetChecked(AValue: boolean);
begin
  Checked := AValue;
  if IsVisible then
    PaintGlyph;
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

procedure TRadioButton.PaintGlyph;
var
  focusRect, rect: TRect;
begin
  GetScreenBounds(rect);
  rect.Width := BoxSize;
  rect.Height := BoxSize;
  focusRect.CreateRect(rect);
  focusRect.Translate(-1, -1);
  focusRect.Grow(2, 2);
  Graph^.SetForeColor(BorderColor);
  Graph^.SetBackColor(BackColor);
  Graph^.FillRect(rect);
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
    Graph^.PushState;
    Graph^.SetForeColor(ForeColor);
    Graph^.State^.Font := CheckFont;
    Graph^.DrawText(rect.X + CheckOffset.X, rect.Y + CheckOffset.Y, CheckChar);
    Graph^.PopState;
  end;
  if CanFocus then begin
    Graph^.PushState;
    Graph^.State^.ViewPort := focusRect;
    if Focused then
      Graph^.SetForeColor(FocusedBackColor)
    else
      Graph^.SetForeColor(BackColor);
    Graph^.Rectangle(focusRect);
    Graph^.PopState;
  end;
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
  PaintGlyph;
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
    PaintGlyph;
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
end;

procedure NumericUpDownDecClick(var AEvent: TMouseEvent);
var
  numericUpDown: PNumericUpDown;
begin
  numericUpDown := PNumericUpDown(PControl(AEvent.Sender)^.Parent);
  numericUpDown^.SetValue(numericUpDown^.Value - numericUpDown^.Increment);
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

procedure TNumericUpDown.Init;
begin
  inherited Init;
  Font := VeridianApp^.GetFont('editor');
  ForeColor := VeridianApp^.Colors.Editor;
  BackColor := VeridianApp^.Colors.EditorBack;
  DisabledColor := VeridianApp^.Colors.EditorDisabled;
  FocusedColor := VeridianApp^.Colors.Focused;
  FocusedBackColor := VeridianApp^.Colors.FocusedBack;
  CanFocus := false;
  FEntry := New(PEdit, CreateParent('Entry', @self));
  FEntry^.Font := Font;
  FEntry^.MaxLength := 9;
  FEntry^.CanFocus := true;
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
  FEntry^.Padding.CreateAll(2, 0, 2, 0);
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
  rect: TRect;
  minWidth, maxWidth: integer;
begin
  inherited Layout;
  FEntry^.SetBounds(17 - FDecButton^.BorderWidth, 0, Width - 32
    + 2 * FDecButton^.BorderWidth, Height);
  minWidth := Length(IntToStr(FMinValue));
  maxWidth := Length(IntToStr(FMaxValue));
  FEntry^.MaxLength := Max(minWidth, maxWidth);
  FIncButton^.SetBounds(0, 0, 17, Height);
  FDecButton^.SetBounds(Width - 17, 0, 17, Height);
end;

end.