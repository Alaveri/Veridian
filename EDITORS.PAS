{$IFDEF debug}
  {$A-,B-,D+,F+,G-,I+,L+,N+,O-,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,F+,G-,I+,L-,N+,O-,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}
unit Editors;

interface

uses
  Objects,
  Lists,
  Drawing,
  Common,

  GrDrv8,

  Views,
  Controls;

const
  DefaultWordDelimiters = [
    ' ', '.', '(', ')', '[', ']', '{', '}', ',','/','<', '>','?', '/', ':',
    '"', '''', ';', '-', '+', '-', '|', '\', '!'
  ];

type
  PEdit = ^TEdit;
  PEditable = ^TEditable;

  TEditable = object(TTextControl)
  private
  public
    procedure Delete; virtual;
  end;

  TEdit = object(TEditable)
  private
    FBuffer: PChar;
    FCapacity: word;
    FCursorPos: word;
    FCursorX: longint;
    function SetCapacity(ACapacity: word): boolean;
    function CheckSize(ALength: word): word;
    function CheckSelection: boolean;
    function GetWordLeft: word;
    function GetWordRight: word;
    procedure SetTextData(AText: PChar; ALength: word);
    procedure ChangeSelect(APosition: word);
    procedure ResetCursor;
  public
    DisabledForeColor: byte;
    SelectForeColor: byte;
    SelectBackColor: byte;
    MaxLength: word;
    Length: word;
    ScrollPos: longint;
    SelectStart: word;
    SelectEnd: word;
    WordDelimiters: set of char;
    function CursorPos: word;
    function SetCursorPos(APos: word): boolean; virtual;
    function GetCursorForeColor: byte; virtual;
    function GetCursorBackColor: byte; virtual;
    function ClearText: boolean; virtual;
    function GetIndexAt(AX, AY: integer): longint;
    procedure Init; virtual;
    procedure Paint; virtual;
    procedure Draw; virtual;
    procedure MouseDown(var AEvent: TMouseEvent); virtual;
    procedure MouseUp(var AEvent: TMouseEvent); virtual;
    procedure MouseMove(var AEvent: TMouseEvent); virtual;
    procedure SetText(const AText: string); virtual;
    procedure SetTextLarge(AText: PChar); virtual;
    procedure AddInsertChar(AChar: char); virtual;
    procedure AddChar(AChar: char); virtual;
    procedure InsertChar(AIndex: word; AChar: char); virtual;
    procedure Delete; virtual;
    procedure BackSpace; virtual;
    procedure MoveEnd; virtual;
    procedure MoveHome; virtual;
    procedure MoveLeft; virtual;
    procedure MoveRight; virtual;
    procedure WordRight; virtual;
    procedure WordLeft; virtual;
    procedure SelectWordRight; virtual;
    procedure SelectWordLeft; virtual;
    procedure SelectRight; virtual;
    procedure SelectLeft; virtual;
    procedure SelectHome; virtual;
    procedure SelectToEnd; virtual;
    procedure SelectAll; virtual;
    procedure SelectNone; virtual;
    procedure KeyPress(var AEvent: TKeyEvent); virtual;
    procedure GetCursorRect(var ARect: TRect); virtual;
    destructor Free; virtual;
  end;

implementation

uses
  StrUtils,
  GraphApp,
  Errors,
  {$IFDEF DOS}
  Strings,
  {$ENDIF}
  KeyDrv,
  MouseDrv,
  GraphDrv,
  MemDrv,
  Desk,
  Veridian;

const
  DefaultEditorSize = 8;

procedure TEditable.Delete;
begin
end;

function TEdit.SetCapacity(ACapacity: word): boolean;
var
  newBuffer: PChar;
begin
  SetCapacity := false;
  if ACapacity = FCapacity then
    exit;
  if not Assigned(FBuffer) then begin
    GetMem(FBuffer, ACapacity);
    if not Assigned(FBuffer) then begin
      VeridianApp^.Error(@self, ecNotEnoughMemory);
      exit;
    end;
    SetCapacity := true;
    FillChar(FBuffer^, ACapacity, 0);
    FCapacity := ACapacity;
    Length := 0;
    exit;
  end;
  GetMem(newBuffer, ACapacity);
  if not Assigned(newBuffer) then begin
    VeridianApp^.Error(@self, ecNotEnoughMemory);
    exit;
  end;
  FillChar(newBuffer^, ACapacity, 0);
  if ACapacity > FCapacity then
    Move(FBuffer^, newBuffer^, FCapacity)
  else
    Move(FBuffer^, newBuffer^, ACapacity);
  FreeMem(FBuffer, FCapacity);
  FBuffer := newBuffer;
  FCapacity := ACapacity;
  SetCapacity := true;
end;

function TEdit.GetCursorForeColor: byte;
begin
  GetCursorForeColor := ForeColor;
  if CanFocus and Focused then
    GetCursorForeColor := FocusedForeColor;
  if not CheckSelection then
    exit;
  if (longint(FCursorPos) - 1 < SelectStart) or (longint(FCursorPos) - 1 > SelectEnd + 1) then
    exit;
  GetCursorForeColor := Desktop^.Colors^.Select;
end;

function TEdit.GetCursorBackColor: byte;
begin
  GetCursorBackColor := BackColor;
  if CanFocus and Focused then
    GetCursorBackColor := FocusedBackColor;
  if not CheckSelection then
    exit;
  if (longint(FCursorPos) - 1 < SelectStart) or (longint(FCursorPos) - 1 > SelectEnd) then
    exit;
  GetCursorBackColor := Desktop^.Colors^.SelectBack;
end;

procedure TEdit.GetCursorRect(var ARect: TRect);
var
  clipRect: TRect;
  yPos: integer;
begin
  inherited GetCursorRect(ARect);
  GetScreenBounds(clipRect);
  case VertAlign of
    vaTop: yPos := clipRect.Y - 1;
    vaBottom: yPos := clipRect.Y + clipRect.Height - Font^.Height;
    vaCenter: yPos := clipRect.Y + (clipRect.Height - Font^.Height) div 2;
  end;
  ARect.SetDims(clipRect.X + FCursorX - ScrollPos + Margin, yPos, 1, Font^.Height + 1);
end;

function TEdit.GetIndexAt(AX, AY: integer): longint;
var
  index: word;
  pos: longint;
begin
  Inc(AX, ScrollPos - Margin - 1);
  index := 0;
  pos := 0;
  while index < Length do begin
    Inc(pos, Font^.TextWidth(FBuffer[index]));
    if pos > AX then
      break;
    Inc(index);
  end;
  GetIndexAt := index;
end;

function TEdit.CheckSize(ALength: word): word;
var
  capacity: longint;
begin
  Inc(ALength);
  CheckSize := 0;
  capacity := MaxWord(FCapacity, DefaultEditorSize);
  while capacity < ALength do begin
    if ALength >= 64 then
      capacity := capacity * 3 div 2
    else if ALength >= 8 then
      capacity := capacity + 16
    else
      capacity := 4;
    if capacity > MaxVarSize then begin
      capacity := MaxVarSize;
      break;
    end;
  end;
  if FCapacity >= capacity then begin
    CheckSize := capacity;
    exit;
  end;
  if SetCapacity(capacity) then
    CheckSize := capacity;
end;

procedure TEdit.Init;
begin
  inherited Init;
  Font := VeridianApp^.Fonts^.GetItemById('Editor');
  UsesCursor := true;
  ForeColor := Desktop^.Colors^.Editor;
  BackColor := Desktop^.Colors^.EditorBack;
  DisabledForeColor := Desktop^.Colors^.EditorDisabled;
  FocusedForeColor := Desktop^.Colors^.Focused;
  FocusedBackColor := Desktop^.Colors^.FocusedBack;
  SelectForeColor := Desktop^.Colors^.Select;
  SelectBackColor := Desktop^.Colors^.SelectBack;
  TextAlign := taLeft;
  VertAlign := vaCenter;
  Margin := 3;
  CanFocus := true;
  BorderStyle := bsSingle;
  MouseCursor := VeridianApp^.MouseCursors^.GetItemById('Beam');
  DrawBackground := true;
  FCursorX := 0;
  ScrollPos := 0;
  SelectStart := 0;
  SelectEnd := 0;
  MaxLength := 255;
  Length := 0;
  FBuffer := nil;
  FCapacity := 0;
  FCursorPos := 0;
  WordDelimiters := DefaultWordDelimiters;
end;

procedure TEdit.SelectNone;
begin
  SelectStart := 0;
  SelectEnd := 0;
  Draw;
  ResetCursor;
end;

procedure TEdit.SelectAll;
begin
  SetCursorPos(Length);
  SelectStart := 0;
  SelectEnd := Length;
  Draw;
  ResetCursor;
end;

procedure TEdit.Draw;
begin
  if not VeridianApp^.DrawEnabled then
    exit;
  VeridianApp^.PushState;
  inherited Draw;
  VeridianApp^.PopState;
end;

procedure TEdit.Paint;
var
  drawRect, bounds, charRect: TRect;
  buffer: PByte;
  index: integer;
  xPos, yPos: integer;
  charWidth: integer;
  ch: char;
  selected: boolean;
begin
  if not GetVisible then
    exit;

  selected := CheckSelection;
  GetScreenBounds(bounds);
  drawRect.CreateRect(bounds);

  Graph^.PushState;
  buffer := Graph^.BeginDrawBuffer(drawRect, buffer);
  Graph^.State.Font := Font;
  Graph^.SetForeColor(ForeColor);
  Graph^.SetBackColor(BackColor);
  if CanFocus and Focused then
    Graph^.SetBackColor(FocusedBackColor);
  if DrawBackground then
    Graph^.FillRect(drawRect);
  xPos := drawRect.X + Margin - ScrollPos + BorderWidth;
  case VertAlign of
    vaTop: yPos := drawRect.Y + BorderWidth;
    vaBottom: yPos := drawRect.Y + drawRect.Height - Font^.Height - BorderWidth;
    vaCenter: yPos := drawRect.Y + (drawRect.Height - Font^.Height) div 2;
  end;
  charRect.Create;

  index := 0;
  while index < Length do begin
    Graph^.SetForeColor(ForeColor);
    Graph^.SetBackColor(BackColor);
    if CanFocus and Focused then begin
      Graph^.SetForeColor(FocusedForeColor);
      Graph^.SetBackColor(FocusedBackColor);
    end;
    ch := FBuffer[index];
    charWidth := Font^.TextWidth(ch);
    if xPos > drawRect.Right then
      break;
    charRect.SetDims(xPos, yPos, charWidth, Font^.Height + 1);
    charRect.Intersect(Graph^.State.ViewPort);
    if selected and (index >= SelectStart) and (index < SelectEnd) then begin
      Graph^.SetForeColor(SelectForeColor);
      Graph^.SetBackColor(SelectBackColor);
      Graph^.FillRect(charRect);
    end;
    if xPos + charWidth > drawRect.X then
      Graph^.DrawText(xPos, yPos, ch);
    Inc(index);
    Inc(xPos, charWidth);
  end;
  Graph^.SetForeColor(BorderColor);
  Graph^.Rectangle(drawRect);
  Graph^.PopState;

  Graph^.DrawImageRect(bounds, buffer);
  Graph^.EndDrawBuffer;
end;

function TEdit.SetCursorPos(APos: word): boolean;
var
  drawRect: TRect;
  index: word;
  needsDraw: boolean;
  charWidth: integer;
begin
  needsDraw := false;
  GetClientRect(drawRect);
  NeedsDraw := false;
  CheckWordRange(APos, 0, Length);
  FCursorPos := APos;
  FCursorX := Font^.TextWidthAny(FBuffer, APos);
  charWidth := Font^.TextWidth(FBuffer[APos]);

  if SelectStart <> SelectEnd then begin
    SelectStart := 0;
    SelectEnd := 0;
    needsDraw := true;
  end;

  if FCursorX + drawRect.X + charWidth - ScrollPos + 1 > drawRect.Right then begin
    ScrollPos := FCursorX - (drawRect.Width - drawRect.Width div 4);
    needsDraw := true;
  end
  else if FCursorX + drawRect.X - ScrollPos < drawRect.X then begin
    ScrollPos := MaxLong(0, FCursorX - drawRect.Width div 2);
    needsDraw := true;
  end;

  SetCursorPos := needsDraw;
end;

function TEdit.CheckSelection: boolean;
begin
  CheckWordRange(SelectStart, 0, Length);
  CheckWordRange(SelectEnd, 0, Length);
  if SelectStart > SelectEnd then
    SwapWord(SelectStart, SelectEnd);
  CheckSelection := SelectStart <> SelectEnd;
end;

function TEdit.ClearText: boolean;
var
  size: word;
begin
  ClearText := false;
  if not CheckSelection then
    exit;
  size := SelectEnd - SelectStart;
  if Length - size <= 0 then begin
    FreeMem(FBuffer, FCapacity);
    FCapacity := 0;
    FBuffer := nil;
    FCursorPos := 0;
    FCursorX := 0;
    Length := 0;
    ScrollPos := 0;
    if CheckSize(DefaultEditorSize) = 0 then
      VeridianApp^.Error(@self, ecNotEnoughMemory);
  end
  else begin
    Move(FBuffer[SelectEnd], FBuffer[SelectStart], Length - SelectStart);
    Dec(Length, size);
    FBuffer[Length] := #0;
  end;
  if SelectStart <> FCursorPos then begin
    SelectEnd := SelectStart;
    SetCursorPos(SelectStart);
    ClearText := true;
  end;
  SelectStart := 0;
  SelectEnd := 0;
end;

procedure TEdit.AddChar(AChar: char);
begin
  if Length >= MaxLength then
    exit;
  ClearText;
  if CheckSize(Length + 1) < 0 then
    exit;
  FBuffer[Length] := AChar;
  Inc(Length);
  FBuffer[Length] := #0;
  MoveEnd;
end;

procedure TEdit.InsertChar(AIndex: word; AChar: char);
begin
  if Length >= MaxLength then
    exit;
  if AIndex >= Length then begin
    AddChar(AChar);
    exit;
  end;
  if CheckSize(Length + 1) < 0 then
    exit;
  CheckWordRange(AIndex, 0, Length);
  if ClearText then
    AIndex := FCursorPos;
  Move(FBuffer[AIndex], FBuffer[AIndex + 1], Length - AIndex);
  FBuffer[AIndex] := AChar;
  Inc(Length);
  FBuffer[Length] := #0;
  SetCursorPos(AIndex + 1);
  Draw;
  ResetCursor;
end;

procedure TEdit.AddInsertChar(AChar: char);
begin
  if FCursorPos < Length then
    InsertChar(FCursorPos, AChar)
  else
    AddChar(AChar);
end;

procedure TEdit.Delete;
begin
  if FCursorPos >= Length then
    exit;
  if SelectStart <> SelectEnd then begin
    ClearText;
  end
  else begin
    Move(FBuffer[FCursorPos + 1], FBuffer[FCursorPos], Length - FCursorPos);
    Dec(Length);
  end;
  Draw;
  ResetCursor;
end;

procedure TEdit.BackSpace;
begin
  if (FCursorPos = 0) or (Length = 0) then
    exit;

  if SelectStart <> SelectEnd then begin
    ClearText;
    SetCursorPos(FCursorPos);
  end
  else begin
    Move(FBuffer[FCursorPos], FBuffer[FCursorPos - 1], Length - FCursorPos);
    Dec(Length);
    FBuffer[Length] := #0;
    SetCursorPos(FCursorPos - 1);
  end;
  Draw;
  ResetCursor;
end;

function TEdit.CursorPos: word;
begin
  CursorPos := FCursorPos;
end;

procedure TEdit.ResetCursor;
begin
  if VeridianApp^.State.CursorOn then begin
    VeridianApp^.State.CursorOn := false;
    VeridianApp^.CursorOn;
  end;
end;

procedure TEdit.MoveLeft;
begin
  if FCursorPos = 0 then
    exit;
  VeridianApp^.PushState;
  VeridianApp^.CursorOff;
  if SetCursorPos(FCursorPos - 1) then
    Draw;
  VeridianApp^.PopState;
  ResetCursor;
end;

procedure TEdit.MoveRight;
begin
  VeridianApp^.PushState;
  VeridianApp^.CursorOff;
  if SetCursorPos(MaxWord(MinWord(FCursorPos + 1, Length), 0)) then
    Draw;
  VeridianApp^.PopState;
  ResetCursor;
end;

function TEdit.GetWordLeft: word;
var
  current: word;
begin
  GetWordLeft := 0;
  if FCursorPos = 0 then
    exit;
  current := FCursorPos - 1;
  while (current > 0) and (FBuffer[current] in WordDelimiters) do begin
    Dec(current);
  end;
  while (current > 0) and not (FBuffer[current - 1] in WordDelimiters) do begin
    Dec(current);
  end;
  GetWordLeft := MaxWord(0, current);
end;

function TEdit.GetWordRight: word;
var
  current: integer;
begin
  current := FCursorPos;
  while (current < Length) and not (FBuffer[current] in WordDelimiters) do begin
    if FBuffer[current] = #0 then
      break;
    Inc(current);
  end;
  while (current < Length) and (FBuffer[current] in WordDelimiters) do begin
    if FBuffer[current] = #0 then
      break;
    Inc(current);
  end;
  GetWordRight := current;
end;

procedure TEdit.WordRight;
var
  pos: integer;
  start: integer;
begin
  start := FCursorPos;
  pos := GetWordRight;
  if pos = start then
    exit;
  VeridianApp^.PushState;
  VeridianApp^.CursorOff;
  if SetCursorPos(pos) then
    inherited Draw;
  VeridianApp^.PopState;
  ResetCursor;
end;

procedure TEdit.WordLeft;
var
  pos: integer;
  start: integer;
begin
  start := FCursorPos;
  pos := GetWordLeft;
  if pos = start then
    exit;
  VeridianApp^.PushState;
  VeridianApp^.CursorOff;
  if SetCursorPos(pos) then
    inherited Draw;
  VeridianApp^.PopState;
  ResetCursor;
end;

procedure TEdit.ChangeSelect(APosition: word);
var
  startPos, endPos: word;
begin
  if (APosition > Length) then
    exit;
  if SelectEnd > SelectStart then begin
    if FCursorPos = SelectEnd then begin
      startPos := SelectStart;
      endPos := APosition;
    end
    else begin
      startPos := APosition;
      endPos := SelectEnd;
    end;
  end
  else begin
    startPos := APosition;
    endPos := FCursorPos;
  end;
  SetCursorPos(APosition);
  SelectStart := startPos;
  SelectEnd := endPos;
  Draw;
  ResetCursor;
end;

procedure TEdit.SelectRight;
begin
  if FCursorPos = Length then
    exit;
  ChangeSelect(FCursorPos + 1);
end;

procedure TEdit.SelectLeft;
begin
  if FCursorPos = 0 then
    exit;
  ChangeSelect(FCursorPos - 1);
end;

procedure TEdit.SelectWordRight;
begin
  ChangeSelect(GetWordRight);
end;

procedure TEdit.SelectWordLeft;
begin
  ChangeSelect(GetWordLeft);
end;

procedure TEdit.SelectHome;
begin
  ChangeSelect(0);
end;

procedure TEdit.SelectToEnd;
begin
  ChangeSelect(Length);
end;

procedure TEdit.MoveEnd;
begin
  SetCursorPos(Length);
  Draw;
  ResetCursor;
end;

procedure TEdit.MoveHome;
begin
  SetCursorPos(0);
  Draw;
  ResetCursor;
end;

procedure TEdit.SetTextData(AText: PChar; ALength: word);
begin
  if not Assigned(AText) then begin
    FreeMem(FBuffer, FCapacity);
    if CheckSize(DefaultEditorSize + 1) = 0 then
      VeridianApp^.Error(@self, ecNotEnoughMemory);
    Length := 0;
    exit;
  end;
  if CheckSize(ALength) = 0 then
    exit;
  Move(AText^, FBuffer^, ALength);
  Length := ALength;
  FBuffer[Length] := #0;
  MoveEnd;
end;

procedure TEdit.SetText(const AText: string);
var
  txt: PChar;
begin
  txt := @AText[1];
  SetTextData(txt, System.Length(AText));
end;

procedure TEdit.SetTextLarge(AText: PChar);
begin
  SetTextData(AText, StrLen(AText));
end;

procedure TEdit.KeyPress(var AEvent: TKeyEvent);
var
  key: word;
begin
  if not (CanFocus and Focused) then
    exit;
  if AEvent.Handled then
    exit;
  key := AEvent.Key;
  case key of
    32..127: AddInsertChar(Chr(key));
    kyLeft: MoveLeft;
    kyRight: MoveRight;
    kyEnd, kyCtrlEnd: MoveEnd;
    kyHome, kyCtrlHome: MoveHome;
    kyDel: Delete;
    kyBackSpace: BackSpace;
    kyPageUp, kyCtrlPageUp: MoveHome;
    kyPageDown, kyCtrlPageDown: MoveEnd;
    kyCtrlRight: WordRight;
    kyCtrlLeft: WordLeft;
    kyShiftCtrlRight: SelectWordRight;
    kyShiftCtrlLeft: SelectWordLeft;
    kyShiftRight: SelectRight;
    kyShiftLeft: SelectLeft;
    kyShiftPageUp, kyShiftCtrlPageUp, kyShiftHome, kyShiftCtrlHome: SelectHome;
    kyShiftPageDown, kyShiftCtrlPageDown, kyShiftEnd, kyShiftCtrlEnd: SelectToEnd;
    kyCtrlA: SelectAll;
    kyEsc: SelectNone;
  end;
  inherited KeyPress(AEvent);
end;

procedure TEdit.MouseDown(var AEvent: TMouseEvent);
var
  index: longint;
begin
  if Desktop^.ActiveControl <> @self then begin
    SelectStart := 0;
    SelectEnd := 0;
    Focus;
  end;
  if not (GetVisible and GetEnabled) then
    exit;
  if not (CanFocus and Focused) then
    exit;
  index := GetIndexAt(AEvent.X, AEvent.Y);
  if index < 0 then
    exit;
  VeridianApp^.SelectingControl := @self;
  SelectStart := index;
  SelectEnd := index;
  StartDrawing;
  VeridianApp^.CursorOff;
  SetCursorPos(index);
  Draw;
  EndDrawing;
  VeridianApp^.CursorOn;
end;

procedure TEdit.MouseMove(var AEvent: TMouseEvent);
var
  index: longint;
  rect: TRect;
begin
  if VeridianApp^.SelectingControl = @self then begin
    GetScreenBounds(rect);
    if not rect.IntersectsCoords(AEvent.NewMouseState.X, AEvent.NewMouseState.Y) then begin

    end;
    index := GetIndexAt(AEvent.X, AEvent.Y);
    CheckLongRange(index, 0, Length);
    if index = FCursorPos then
      exit;
    ChangeSelect(index);

    Draw;
    ResetCursor;
  end;
  inherited MouseMove(AEvent);
end;

procedure TEdit.MouseUp(var AEvent: TMouseEvent);
var
  mouseControl: PControl;
  selecting: boolean;
begin
  selecting := VeridianApp^.SelectingControl = @self;
  VeridianApp^.SelectingControl := nil;
  mouseControl := VeridianApp^.GetMouseControl(Desktop, AEvent.NewMouseState);
  if not Assigned(mouseControl) then
    mouseControl := @self;
  if selecting then begin
    Graph8^.EraseMouseCursor(AEvent.NewMouseState);
    Graph8^.MouseCursor := mouseControl^.MouseCursor;
    Graph8^.DrawMouseCursor(AEvent.NewMouseState);
  end;
end;

destructor TEdit.Free;
begin
  if Assigned(FBuffer) then
    FreeMem(FBuffer, Length);
  inherited Free;
end;

end.