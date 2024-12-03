{$I COMPILER.INC}
unit Events;

interface

uses
  AplObj,
  AplTypes,
  Drawing;

type
  PMoveEvent = ^TMoveEvent;
  PMovingEvent = ^TMovingEvent;
  PSizeEvent = ^TSizeEvent;
  PScrollEvent = ^TScrollEvent;
  PClosingEvent = ^TClosingEvent;
  PDragEvent = ^TDragEvent;
  PSizingEvent = ^TSizingEvent;

  PClosingEventProc = ^TClosingEventProc;
  PMoveEventProc = ^TMoveEventProc;
  PSizeEventProc = ^TSizeEventProc;
  PScrollEventProc = ^TScrollEventProc;
  PKeyEventProc = ^TKeyEventProc;
  PMouseEventProc = ^TMouseEventProc;
  PDragEventProc = ^TDragEventProc;
  PMovingEventProc = ^TMovingEventProc;
  PSizingEventProc = ^TSizingEventProc;

  TClosingEvent = object(TEvent)
  private
  public
    CanClose: boolean;
    procedure Assign(var ASource: TObject); virtual;
    procedure Clear; virtual;
  end;

  TScrollEvent = object(TEvent)
  private
  public
    ScrollPosition: longint;
    procedure Assign(var ASource: TObject); virtual;
    procedure Clear; virtual;
  end;

  TMoveEvent = object(TEvent)
  private
  public
    OldPosition: TPoint;
    NewPosition: TPoint;
    procedure Assign(var ASource: TObject); virtual;
    procedure Clear; virtual;
  end;

  TMovingEvent = object(TMoveEvent)
  private
  public
    CanMove: boolean;
    procedure Assign(var ASource: TObject); virtual;
    procedure Clear; virtual;
  end;

  TSizeEvent = object(TEvent)
  private
  public
    OldSize: TSize;
    NewSize: TSize;
    procedure Assign(var ASource: TObject); virtual;
    procedure Clear; virtual;
  end;

  TSizingEvent = object(TSizeEvent)
  private
  public
    CanResize: boolean;
    procedure Assign(var ASource: TObject); virtual;
    procedure Clear; virtual;
  end;

  TDragEvent = object(TEvent)
  private
  public
    InitialX: integer;
    InitialY: integer;
    X: integer;
    Y: integer;
    procedure Assign(var ASource: TObject); virtual;
    procedure Clear; virtual;
  end;

  TClosingEventProc = procedure(var AEvent: TClosingEvent);
  TScrollEventProc = procedure(var AEvent: TScrollEvent);
  TMoveEventProc = procedure(var AEvent: TMoveEvent);
  TMovingEventProc = procedure(var AEvent: TMovingEvent);
  TSizeEventProc = procedure(var AEvent: TSizeEvent);
  TKeyEventProc = procedure(var AEvent: TKeyEvent);
  TMouseEventProc = procedure(var AEvent: TMouseEvent);
  TDragEventProc = procedure(var AEvent: TDragEvent);
  TSizingEventProc = procedure(var AEvent: TSizingEvent);

implementation

procedure TMoveEvent.Clear;
begin
  inherited Clear;
  OldPosition.Create;
  NewPosition.Create;
end;

procedure TMoveEvent.Assign(var ASource: TObject);
var
  source: PMoveEvent;
begin
  inherited Assign(ASource);
  source := PMoveEvent(@ASource);
  OldPosition.Assign(source^.OldPosition);
  NewPosition.Assign(source^.NewPosition);
end;

procedure TMovingEvent.Clear;
begin
  inherited Clear;
  CanMove := true;
end;

procedure TMovingEvent.Assign(var ASource: TObject);
var
  source: PMovingEvent;
begin
  inherited Assign(ASource);
  source := PMovingEvent(@ASource);
  CanMove := source^.CanMove;
end;

procedure TSizeEvent.Clear;
begin
  inherited Clear;
  OldSize.Create;
  NewSize.Create;
end;

procedure TSizeEvent.Assign(var ASource: TObject);
var
  source: PSizeEvent;
begin
  inherited Assign(ASource);
  source := PSizeEvent(@ASource);
  OldSize.Assign(source^.OldSize);
  NewSize.Assign(source^.NewSize);
end;

procedure TSizingEvent.Clear;
begin
  inherited Clear;
  CanResize := true;
end;

procedure TSizingEvent.Assign(var ASource: TObject);
var
  source: PSizingEvent;
begin
  inherited Assign(ASource);
  source := PSizingEvent(@ASource);
  CanResize := source^.CanResize;
end;

procedure TClosingEvent.Clear;
begin
  inherited Clear;
  CanClose := true;
end;

procedure TClosingEvent.Assign(var ASource: TObject);
var
  source: PClosingEvent;
begin
  inherited Assign(ASource);
  source := PClosingEvent(@ASource);
  CanClose := source^.CanClose;
end;

procedure TDragEvent.Clear;
begin
  inherited Clear;
  X := 0;
  Y := 0;
  InitialX := 0;
  InitialY := 0;
end;

procedure TDragEvent.Assign(var ASource: TObject);
var
  source: PDragEvent;
begin
  inherited Assign(ASource);
  source := PDragEvent(@ASource);
  X := source^.X;
  Y := source^.Y;
  InitialX := source^.InitialX;
  InitialY := source^.InitialY;
end;

procedure TScrollEvent.Clear;
begin
  inherited Clear;
  ScrollPosition := 0;
end;

procedure TScrollEvent.Assign(var ASource: TObject);
var
  source: PScrollEvent;
begin
  inherited Assign(ASource);
  source := PScrollEvent(@ASource);
  ScrollPosition := source^.ScrollPosition;
end;

end.