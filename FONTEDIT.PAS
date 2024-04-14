{$IFDEF debug}
  {$A-,B-,D+,F+,G-,I+,L+,N+,O-,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,F+,G-,I+,L-,N+,O-,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}
unit FontEdit;

interface

uses
  Objects,
  Collects,
  Controls,
  Common,
  VeriApp;

type
  PCharacterMap = ^TCharacterMap;
  PFontEditor = ^TFontEditor;

  TCharacterMap = object(TPanel)
  private
  public
    CharsPerRow: integer;
    procedure PaintChar(AChar: byte);
    procedure DrawChar(AChar: byte);
    procedure Init; virtual;
    destructor Free; virtual;
    procedure Paint; virtual;
  end;

  TFontEditor = object(TPanel)
  private
    FPixelOn: boolean;
    procedure SetPixel(var AEvent: TEvent; AToggle: boolean);
  public
    CurrentChar: byte;
    procedure Init; virtual;
    procedure Paint; virtual;
    procedure PaintPixel(AX, AY: integer);
    procedure DrawPixel(AX, AY: integer);
    procedure SetupControls; virtual;
    procedure MouseDown(var AEvent: TEvent); virtual;
    procedure MouseMove(var AEvent: TEvent); virtual;
  end;

implementation

uses
  GraphDrv,
  Drawing,
  Desk,
  Graph8;

procedure TFontEditor.Init;
begin
  inherited Init;
  FPixelOn := false;
  CurrentChar := 0;
  DrawBackground := true;
end;

procedure TFontEditor.PaintPixel(AX, AY: integer);
var
  linePtr: PByte;
  controlRect, drawRect: TRect;
begin
  GetClientScreenBounds(controlRect);
  drawRect.Create;
  linePtr := Font^.FontData;
  Inc(linePtr, CurrentChar * Font^.Height + AY);
  if (linePtr^ and (128 shr AX)) > 0 then
    Graph^.SetBackColor(ForeColor)
  else
    Graph^.SetBackColor(BackColor);
  drawRect.SetDims(controlRect.X + AX * 8, controlRect.Y + AY * 8, 8, 8);
  Graph^.FillRect(drawRect);
end;

procedure TFontEditor.DrawPixel(AX, AY: integer);
begin
  StartDrawing;
  PaintPixel(AX, AY);
  EndDrawing;
  Graph^.WaitForVSync;
end;

procedure TFontEditor.Paint;
var
  xIndex, yIndex: integer;
begin
  inherited Paint;
  Graph^.SetBackColor(ForeColor);
  for yIndex := 0 to Font^.Height - 1 do
    for xIndex := 0 to Font^.MaxWidth - 1 do
      PaintPixel(xIndex, yIndex);
end;

procedure TFontEditor.SetupControls;
begin
end;

procedure TFontEditor.SetPixel(var AEvent: TEvent; AToggle: boolean);
var
  row, column: integer;
  pixelIndex: integer;
  linePtr: PByte;
  mx, my: integer;
begin
  mx := AEvent.MouseState.X;
  my := AEvent.MouseState.Y;
  if BorderStyle <> bsNone then begin
    Dec(mx);
    Dec(my);
  end;
  row := my div 8;
  column := mx div 8;
  pixelIndex := row * Font^.Height + column;
  linePtr := Font^.FontData;
  Inc(linePtr, CurrentChar * Font^.Height + row);
  if AToggle then begin
    linePtr^ := linePtr^ xor (128 shr column);
    FPixelOn := linePtr^ and (128 shr column) > 0;
  end
  else begin
    if FPixelOn then
      linePtr^ := linePtr^ or (128 shr column)
    else
      linePtr^ := linePtr^ and not (128 shr column);
  end;
  DrawPixel(column, row);
end;

procedure TFontEditor.MouseMove(var AEvent: TEvent);
begin
  if not (AEvent.Intersects and IsLeftMouseDown) then
    exit;
  SetPixel(AEvent, false);
  if Assigned(OnMouseMove) then
    TMouseEventProc(OnMouseMove)(@self, AEvent);
  inherited MouseMove(AEvent);
end;

procedure TFontEditor.MouseDown(var AEvent: TEvent);
begin
  if not AEvent.Intersects then
    exit;
  SetPixel(AEvent, true);
  inherited MouseMove(AEvent);
end;

procedure TCharacterMap.Init;
begin
  inherited Init;
  CharsPerRow := 32;
  ForeColor := Desktop^.Colors^.ButtonDown;
  BackColor := Desktop^.Colors^.ButtonDownBack;
  DrawBackground := false;
end;

destructor TCharacterMap.Free;
begin
  inherited Free;
end;

procedure TCharacterMap.DrawChar(AChar: byte);
begin
  StartDrawing;
  PaintChar(AChar);
  EndDrawing;
  Graph^.WaitForVSync;
end;

procedure TCharacterMap.PaintChar(AChar: byte);
var
  rect: TRect;
  charRect: TRect;
  sx, sy: integer;
  column: integer;
  row: integer;
begin
  Graph^.State^.Font := Font;
  Graph^.SetForeColor(ForeColor);
  Graph^.SetBackColor(BackColor);
  row := Ord(AChar) div CharsPerRow;
  column := Ord(AChar) mod CharsPerRow;
  sy := row * (Font^.Height + 1);
  sx := column * (Font^.MaxWidth + 1);
  GetClientScreenBounds(rect);
  charRect.CreateDims(rect.X + sx, rect.Y + sy, Font^.MaxWidth, Font^.Height);
  Graph^.FillRect(charRect);
  Graph^.DrawText(rect.X + sx, rect.Y + sy, Chr(AChar));
end;

procedure TCharacterMap.Paint;
var
  character: byte;
  sx, sy: integer;
  column: integer;
begin
  inherited Paint;
  sx := 0;
  sy := 0;
  for character := 0 to High(byte) do
    PaintChar(character);
end;

end.