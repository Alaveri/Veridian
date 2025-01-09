{$I COMPILER.INC}
unit VeriType;

interface

uses
  AplObj;

type
  PSpacing = ^TSpacing;

  TRelativePosition = (rpAbsolute, rpParentClient, rpParentContent, rpParentRelative);
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
    procedure SetAll(ALeft, ATop, ARight, ABottom: integer);
    procedure SetLeft(ALeft: integer);
    procedure SetTop(ATop: integer);
    procedure SetRight(ARight: integer);
    procedure SetBottom(ABottom: integer);
    procedure SetLeftRight(ALeft, ARight: integer);
    procedure SetTopBottom(ATop, ABottom: integer);
    procedure SetHorz(AValue: integer);
    procedure SetVert(AValue: integer);
    procedure SetValue(AValue: integer);
    procedure Init; virtual;
  end;

implementation

constructor TSpacing.CreateAll(ALeft, ATop, ARight, ABottom: integer);
begin
  inherited Create;
  SetAll(ALeft, ATop, ARight, ABottom);
end;

constructor TSpacing.CreateLeft(ALeft: integer);
begin
  inherited Create;
  SetLeft(ALeft);
end;

constructor TSpacing.CreateTop(ATop: integer);
begin
  inherited Create;
  SetTop(ATop);
end;

constructor TSpacing.CreateRight(ARight: integer);
begin
  inherited Create;
  SetRight(ARight);
end;

constructor TSpacing.CreateBottom(ABottom: integer);
begin
  inherited Create;
  SetBottom(ABottom);
end;

constructor TSpacing.CreateLeftRight(ALeft, ARight: integer);
begin
  inherited Create;
  SetLeftRight(ALeft, ARight);
end;

constructor TSpacing.CreateTopBottom(ATop, ABottom: integer);
begin
  inherited Create;
  SetTopBottom(ATop, ABottom);
end;

constructor TSpacing.CreateHorz(AValue: integer);
begin
  inherited Create;
  SetHorz(AValue);
end;

constructor TSpacing.CreateVert(AValue: integer);
begin
  inherited Create;
  SetVert(AValue);
end;

constructor TSpacing.CreateValue(AValue: integer);
begin
  inherited Create;
  SetValue(AValue);
end;

procedure TSpacing.SetAll(ALeft, ATop, ARight, ABottom: integer);
begin
  Left := ALeft;
  Top := ATop;
  Right := ARight;
  Bottom := ABottom;
end;

procedure TSpacing.SetValue(AValue: integer);
begin
  SetAll(AValue, AValue, AValue, AValue);
end;

procedure TSpacing.SetLeft(ALeft: integer);
begin
  Left := ALeft;
end;

procedure TSpacing.SetTop(ATop: integer);
begin
  Top := ATop;
end;

procedure TSpacing.SetRight(ARight: integer);
begin
  Right := ARight;
end;

procedure TSpacing.SetBottom(ABottom: integer);
begin
  Bottom := ABottom;
end;

procedure TSpacing.SetLeftRight(ALeft, ARight: integer);
begin
  Left := ALeft;
  Right := ARight;
end;

procedure TSpacing.SetTopBottom(ATop, ABottom: integer);
begin
  Top := ATop;
  Bottom := ABottom;
end;

procedure TSpacing.SetHorz(AValue: integer);
begin
  Left := AValue;
  Right := AValue;
end;

procedure TSpacing.SetVert(AValue: integer);
begin
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