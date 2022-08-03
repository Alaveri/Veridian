unit GrTxtApp;

interface

uses
  Objects,
  MouseDrv,
  GraphDrv,
  TextDrv,
  Drawing,
  TextIni,
  TextApp;

type
  PGraphicTextApplication = ^TGraphicTextApplication;
  TGraphicTextApplication = object(TTextApplication)
  private
    _gOldMouseState: PMouseState;
  public
    procedure Init; virtual;
    procedure Run; virtual;
    procedure ProcessEvents; virtual;
    procedure InitTextDriver(driver: TTextDrivers; modeId: string); virtual;
    destructor Done; virtual;
  end;

implementation

procedure TGraphicTextApplication.Init;
begin
  _gOldMouseState := New(PMouseState, Create);
  TTextApplication.Init;
end;

procedure TGraphicTextApplication.InitTextDriver(driver: TTextDrivers; modeId: string);
begin
  TTextApplication.InitTextDriver(driver, modeId);
end;

procedure TGraphicTextApplication.ProcessEvents;
var
  mouseState: TMouseState;
begin
  MouseDriver^.GetMouseState(mouseState);
  if not mouseState.Equals(_gOldMouseState^) then begin
    TextDriver^.EraseMouseCursor(_gOldMouseState^);
    TextDriver^.DrawMouseCursor(mouseState);

    _gOldMouseState^ := mouseState;
    mouseState.X := mouseState.X div 8;
    mouseState.Y := mouseState.Y div 16;
    Desktop^.ProcessMouse(mouseState, OldMouseState^, MouseHandled);
    OldMouseState^ := mouseState;
  end;
end;

destructor TGraphicTextApplication.Done;
begin
  Dispose(_gOldMouseState, Done);
  TTextApplication.Done;
end;

procedure TGraphicTextApplication.Run;
begin
  MouseDriver^.ShowMouse;
  TTextApplication.Run;
end;

end.