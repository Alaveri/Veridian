{$I COMPILER.INC}
unit Events;

interface

uses
  AplObj,
  AplTypes,
  Drawing;

type
  PMoveEvent = ^TMoveEvent;
  PSizeEvent = ^TSizeEvent;
  PScrollEvent = ^TScrollEvent;
  PClosingEvent = ^TClosingEvent;

  PClosingEventProc = ^TClosingEventProc;
  PMoveEventProc = ^TMoveEventProc;
  PSizeEventProc = ^TSizeEventProc;
  PScrollEventProc = ^TScrollEventProc;
  PKeyEventProc = ^TKeyEventProc;
  PMouseEventProc = ^TMouseEventProc;

  TClosingEvent = object(TEvent)
  private
  public
    CanClose: boolean;
    procedure Init; virtual;
  end;

  TScrollEvent = object(TEvent)
  private
  public
    Position: longint;
  end;

  TMoveEvent = object(TEvent)
  private
  public
    OldPosition: TPoint;
    NewPosition: TPoint;
    procedure Init; virtual;
  end;

  TSizeEvent = object(TEvent)
  private
  public
    OldSize: TSize;
    NewSize: TSize;
    procedure Init; virtual;
  end;

  TClosingEventProc = procedure(ASender: PObject; var AEvent: TClosingEvent);
  TScrollEventProc = procedure(ASender: PObject; var AEvent: TScrollEvent);
  TMoveEventProc = procedure(ASender: PObject; var AEvent: TMoveEvent);
  TSizeEventProc = procedure(ASender: PObject; var AEvent: TSizeEvent);
  TKeyEventProc = procedure(ASender: PObject; var AEvent: TKeyEvent);
  TMouseEventProc = procedure(ASender: PObject; var AEvent: TMouseEvent);

implementation

procedure TMoveEvent.Init;
begin
  inherited Init;
  OldPosition.Create;
  NewPosition.Create;
end;

procedure TSizeEvent.Init;
begin
  inherited Init;
  OldSize.Create;
  NewSize.Create;
end;

procedure TClosingEvent.Init;
begin
  inherited Init;
  CanClose := true;
end;

end.