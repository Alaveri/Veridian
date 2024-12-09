{$I COMPILER.INC}
unit VeriType;

interface

uses
  AplObj;

type
  PSpacing = ^TSpacing;

  TScreenPosition = (spAbsolute, spClient, spContent, spRelative);
  TBorderStyle = (bsNone, bsSingle);
  TBevelStyle = (bvNone, bvLowered, bvRaised);
  THorzAlign = (haLeft, haRight, haCenter);
  TVertAlign = (vaTop, vaBottom, vaCenter);

  TAlign =
  (
    alNone,
    alLeft,
    alRight,
    alTop,
    alBottom,
    alClient
  );

  TScrollOrientation =
  (
    soVertical,
    soHorizontal
  );

  TSpacing = object(TObject)
  private
  public
    Left: integer;
    Top: integer;
    Right: integer;
    Bottom: integer;
    constructor CreateAll(ALeft, ATop, ARight, ABottom: integer);
    constructor CreateValue(AValue: integer);
    constructor CreateLeft(ALeft: integer);
    constructor CreateTop(ATop: integer);
    constructor CreateRight(ARight: integer);
    constructor CreateBottom(ABottom: integer);
    constructor CreateLeftRight(ALeft, ARight: integer);
    constructor CreateTopBottom(ATop, ABottom: integer);
    constructor CreateHorz(AValue: integer);
    constructor CreateVert(AValue: integer);
    function Width: integer;
    function Height: integer;
    procedure Init; virtual;
  end;

implementation

constructor TSpacing.CreateAll(ALeft, ATop, ARight, ABottom: integer);
begin
  inherited Create;
  Left := ALeft;
  Top := ATop;
  Right := ARight;
  Bottom := ABottom;
end;

constructor TSpacing.CreateValue(AValue: integer);
begin
  inherited Create;
  Left := AValue;
  Top := AValue;
  Right := AValue;
  Bottom := AValue;
end;

constructor TSpacing.CreateLeft(ALeft: integer);
begin
  inherited Create;
  Left := ALeft;
end;

constructor TSpacing.CreateTop(ATop: integer);
begin
  inherited Create;
  Top := ATop;
end;

constructor TSpacing.CreateRight(ARight: integer);
begin
  inherited Create;
  Right := ARight;
end;

constructor TSpacing.CreateBottom(ABottom: integer);
begin
  inherited Create;
  Bottom := ABottom;
end;

constructor TSpacing.CreateLeftRight(ALeft, ARight: integer);
begin
  inherited Create;
  Left := ALeft;
  Right := ARight;
end;

constructor TSpacing.CreateTopBottom(ATop, ABottom: integer);
begin
  inherited Create;
  Top := ATop;
  Bottom := ABottom;
end;

constructor TSpacing.CreateHorz(AValue: integer);
begin
  inherited Create;
  Left := AValue;
  Right := AValue;
end;

constructor TSpacing.CreateVert(AValue: integer);
begin
  inherited Create;
  Top := AValue;
  Bottom := AValue;
end;

function TSpacing.Width: integer;
begin
  Width := Left + Right;
end;

function TSpacing.Height: integer;
begin
  Height := Top + Bottom;
end;

procedure TSpacing.Init;
begin
  Left := 0;
  Top := 0;
  Right := 0;
  Bottom := 0;
end;

end.