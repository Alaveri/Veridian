unit VeriApp;

interface

uses
  GraphApp,
  Graph8,
  GraphDrv,
  GraphIni,
  MouseDrv,
  KeyDrv,
  Objects,
  Controls,
  Desk;

type
  PVeridianApp = ^TVeridianApp;

  TVeridianApp = object(TGraphApp)
  private
    FEvent: TEvent;
    FMouseState, FOldMouseState: TMouseState;
  public
    constructor Create(ADriverId: TGraphDrivers; AModeId: string);
    procedure Init; virtual;
    procedure ProcessEvents; virtual;
    procedure InitControls; virtual;
    destructor Free; virtual;
  end;

var
  Application: PVeridianApp;

implementation

uses
  Common,
  MemDrv;

constructor TVeridianApp.Create(ADriverId: TGraphDrivers; AModeId: string);
begin
  inherited Create(ADriverId, AModeId);
end;

procedure TVeridianApp.Init;
begin
  inherited Init;
  Memory.Create;
  FEvent.Create;
  Desktop := nil;
  Desktop := New(PDesktop, CreateParent('Desktop', nil));
  Desktop^.MouseState.Visible := true;
  Desktop^.MouseStack.Create;
  Desktop^.MenuBar := New(PMenuBar, CreateParent('DesktopMenuBar', Desktop));
  Desktop^.StatusBar := New(PStatusBar, CreateParent('DesktopStatusBar', Desktop));
  FMouseState.Create;
  FOldMouseState.Create;
  InitControls;
  Desktop^.Draw;
  Mouse.SetMousePosition(Graph^.Mode^.Width div 2, Graph^.Mode^.Height div 2);
  Mouse.ShowMouse;
  Graph256^.ShowMouseCursor;
  Mouse.GetMouseState(FMouseState);
  FOldMouseState.Assign(FMouseState);
end;

destructor TVeridianApp.Free;
begin
  FMouseState.Free;
  FOldMouseState.Free;
  FreeAndNil(Desktop);
  Memory.Free;
  inherited Free;
end;

procedure TVeridianApp.InitControls;
begin
  Desktop^.SetBounds(0, 0, Graph^.Mode^.Width, Graph^.Mode^.Height);
  Desktop^.SetupControls;
end;

procedure TVeridianApp.ProcessEvents;
var
  key: word;
begin
  inherited ProcessEvents;
  FEvent.Clear;
  Mouse.GetMouseState(FMouseState);
  if not FMouseState.Equals(FOldMouseState) then begin
    while (Port[$3DA] and $08) <> $08 do;
    Graph256^.MoveMouseCursor(FMouseState, FOldMouseState);
    FEvent.OldMouseState.Assign(FOldMouseState);
    FEvent.NewMouseState.Assign(FMouseState);
    Desktop^.ProcessMouse(FEvent);
    FOldMouseState.Assign(FMouseState);
  end;
  if Keyboard.KeyPressed then begin
    FEvent.Key := Keyboard.GetKey;
    FEvent.NewMouseState.Assign(FMouseState);
    Desktop^.ProcessKeyboard(FEvent);
  end;
end;

end.