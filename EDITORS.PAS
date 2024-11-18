{$I COMPILER.INC}
unit Editors;

interface

uses
  AplObj,
  AplTypes,
  TextType,
  TextDrv,
  VarStr,
  Controls;

type
  PEdit = ^TEdit;

  TEditorStyle = (esSingleLine, esMultiLine);

  TEdit = object(TFocusControl)
  private
    FLines: PVarStringList;
  public
    Style: TEditorStyle;
    constructor CreateText(const AId: string; AText: PChar; AParent: PControl);
    constructor CreateTextString(const AId, AText: string; AParent: PControl);
    destructor Free; virtual;
    procedure Init; virtual;
    procedure Paint; virtual;
    procedure SetStyle(AStyle: TEditorStyle);
  end;

implementation

uses
  Drawing,
  Veridian;

constructor TEdit.CreateText(const AId: string; AText: PChar; AParent: PControl);
var
  line: PVarString;
begin
  inherited CreateParent(AId, AParent);
  FLines := New(PVarStringList, Create);
  line := New(PVarString, CreateString(AText));
  FLines^.Add(line);
end;

constructor TEdit.CreateTextString(const AId, AText: string; AParent: PControl);
var
  line: PVarString;
begin
  inherited CreateParent(AId, AParent);
  FLines := New(PVarStringList, Create);
  line := New(PVarString, CreateShort(AText));
  FLines^.Add(line);
end;

destructor TEdit.Free;
begin
  FreeAndNil(FLines);
  inherited Free;
end;

procedure TEdit.Init;
begin
  inherited Init;
  FLines := nil;
  ForeColor := VeridianApp^.Colors.Editor;
  BackColor := VeridianApp^.Colors.EditorBack;
  UsesCursor := true;
  Style := esSingleLine;
  AcceptsEnter := false;
  AcceptsTab := false;
end;

procedure TEdit.Paint;
begin
  inherited Paint;
end;

procedure TEdit.SetStyle(AStyle: TEditorStyle);
begin
  Style := AStyle;
  AcceptsEnter := Style = esMultiLine;
  AcceptsTab := Style = esMultiLine;
end;

end.