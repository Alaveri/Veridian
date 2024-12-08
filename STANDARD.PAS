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
  Controls;

type
  PCheckBox = ^TCheckBox;

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
    procedure Init; virtual;
    procedure Layout; virtual;
    procedure Paint; virtual;
    procedure PaintCheckbox; virtual;
    procedure SetChecked(AValue: boolean);
    procedure SetBoxSize(AValue: integer);
    procedure MouseDown(var AEvent: TMouseEvent); virtual;
    procedure MouseClick(var AEvent: TMouseEvent); virtual;
    procedure MouseEnter(var AEvent: TMouseEvent); virtual;
    procedure MouseLeave(var AEvent: TMouseEvent); virtual;
    procedure KeyPress(var AEvent: TKeyEvent); virtual;
  end;

implementation

uses
  KeyDrv,
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
  TextOffsetY := 3;
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
    Width := ContentWidth + Padding.Width + OuterWidth + 2;
    Height := ContentHeight + Padding.Height + OuterWidth + 2;
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
  PaintCheckbox;
end;

procedure TCheckBox.PaintCheckbox;
var
  focusRect, rect: TRect;
begin
  GetScreenBounds(rect);
  rect.Width := BoxSize;
  rect.Height := BoxSize;
  rect.Translate(1, 1);
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
  if Focused then begin
    Graph^.SetForeColor(FocusedBackColor);
    Graph^.Rectangle(focusRect);
  end;
  if Checked then begin
    Graph^.PushState;
    Graph^.SetForeColor(ForeColor);
    Graph^.State^.Font := CheckFont;
    Graph^.DrawText(rect.X + CheckOffset.X, rect.Y + CheckOffset.Y, CheckChar);
    Graph^.PopState;
  end;
end;

procedure TCheckBox.SetChecked(AValue: boolean);
begin
  Checked := AValue;
  PaintCheckbox;
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

end.