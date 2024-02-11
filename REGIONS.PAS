unit Regions;

interface

uses
  Drawing,
  Objects,
  Lists;

type
  PRegion = ^TRegion;

  TRegion = object(TObjectList)
  private
  public
    function IntersectsPoint(APoint: TPoint): boolean;
    function IntersectsCoords(AX, AY: longint): boolean;
    function IntersectsRect(ARect: TRect): boolean;
    function Intersects(ARegion: PRegion): boolean;
    function Intersection(ARegion: PRegion): PRegion;
    function Add(AItem: PRect): integer;
    function GetItem(AIndex: integer): PRect;
    procedure Init; virtual;
    procedure Insert(AIndex: integer; AItem: PRect);
    destructor Free; virtual;
  end;

implementation

function TRegion.Add(AItem: PRect): integer;
begin
  Add := inherited Add(AItem);
end;

function TRegion.GetItem(AIndex: integer): PRect;
begin
  GetItem := PRect(inherited GetItem(AIndex));
end;

procedure TRegion.Init;
begin
  inherited Init;
end;

procedure TRegion.Insert(AIndex: integer; AItem: PRect);
begin
  inherited Insert(AIndex, AItem);
end;

function TRegion.IntersectsPoint(APoint: TPoint): boolean;
var
  index: integer;
  rect: PRect;
begin
  IntersectsPoint := false;
  if Count = 0 then
    exit;
  for index := 0 to Count - 1 do begin
    rect := GetItem(index);
    if rect^.IntersectsPoint(APoint) then begin
      IntersectsPoint := true;
      exit;
    end;
  end;
end;

function TRegion.IntersectsCoords(AX, AY: longint): boolean;
var
  index: integer;
  rect: PRect;
begin
{  IntersectsCoords := true;
  if Count = 0 then
    exit;
  for index := 0 to Count - 1 do begin
{    rect := GetItem(index);
    if rect^.IntersectsCoords(AX, AY) then begin
      IntersectsCoords := true;
      exit;
    end;
  end;}
end;

function TRegion.IntersectsRect(ARect: TRect): boolean;
var
  index: integer;
  rect: PRect;
begin
  IntersectsRect := false;
  if Count = 0 then
    exit;
  for index := 0 to Count - 1 do begin
    rect := GetItem(index);
    if rect^.IntersectsRect(ARect) then begin
      IntersectsRect := true;
      exit;
    end;
  end;
end;

function TRegion.Intersects(ARegion: PRegion): boolean;
var
  selfIndex, regionIndex: integer;
begin
  Intersects := false;
  if (Count = 0) or (ARegion^.Count = 0) then
    exit;
  for selfIndex := 0 to Count - 1 do begin
    for regionIndex := 0 to ARegion^.Count - 1 do begin
      if GetItem(selfIndex)^.IntersectsRect(ARegion^.GetItem(regionIndex)^) then begin
        Intersects := true;
        exit;
      end;
    end;
  end;
end;

function TRegion.Intersection(ARegion: PRegion): PRegion;
var
  selfIndex, regionIndex: integer;
  result: PRegion;
  selfRect, regionRect: PRect;
begin
  result := New(PRegion, Create);
  if (Count = 0) or (ARegion^.Count = 0) then
    exit;
  for selfIndex := 0 to Count - 1 do begin
    for regionIndex := 0 to ARegion^.Count - 1 do begin
      selfRect := GetItem(selfIndex);
      regionRect := ARegion^.GetItem(regionIndex);
      if selfRect^.IntersectsRect(regionRect^) then begin
        selfRect^.Intersect(regionRect^);
        result^.Add(selfRect);
      end;
    end;
  end;
end;

destructor TRegion.Free;
begin
  inherited Free;
end;

end.