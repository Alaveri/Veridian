unit GraphApp;

interface

uses
  Crt,
  Objects,
  MouseDrv,
  GraphDrv,
  Drawing,
  Apps,
  Utils,
  Controls,
  StrUtils,
  GraphIni;

type
  PGraphicApplication = ^TGraphicApplication;
  TGraphicApplication = object(TApplication)
  private
    _keyHandled: boolean;
    _mouseVisible: boolean;
    _driverId: TGraphDrivers;
    _modeId: PChar;
  public
    Desktop: PDesktop;
    MenuBar: PMenuBar;
    OldMouseState: PMouseState;
    MouseHandled: boolean;
    procedure Init; virtual;
    procedure Run; virtual;
    procedure ProcessEvents; virtual;
    procedure InitGraphicsDriver(driver: TGraphDrivers; modeId: PChar); virtual;
    procedure InitDefaultColors; virtual;
    procedure InitControls; virtual;
    procedure MainLoop; virtual;
    constructor Create(const newId: string; interfaceMem: longint; driver: TGraphDrivers; modeId: PChar);
    destructor Done; virtual;
  end;

implementation

constructor TGraphicApplication.Create(const newId: string; interfaceMem: longint; driver: TGraphDrivers; modeId: PChar);
begin
  _driverId := driver;
  _modeId := modeId;
  TApplication.Create(newId, interfaceMem);
end;

procedure TGraphicApplication.Init;
begin
  TApplication.Init;
  InitGraphicsDriver(_driverId, _modeId);
  MouseHandled := false;
  _keyHandled := false;
  InitDefaultColors;
  Desktop := New(PDesktop, CreateParent('Desktop', nil));
  Desktop^.MouseState.Visible := true;
  Desktop^.MouseStack.Create;
  OldMouseState := New(PMouseState, Create);
  _modeId := nil;
  InitControls;
end;

procedure TGraphicApplication.InitControls;
begin
  with Desktop^ do begin
    SetBounds(0, 0, Graphics^.Mode^.Width, Graphics^.Mode^.Height);
    ForeColor := icDesktop;
    BackColor := icDesktopBack;
    SetupControls;
  end;
end;

procedure TGraphicApplication.InitDefaultColors;
begin
  icDesktop := Graphics^.GetColor(scWhite, MaxIntensity);
  icDesktopBack := Graphics^.GetColor(scGreen, MaxIntensity);
  icWindow := Graphics^.GetColor(scCyan, MaxIntensity);
  icWindowBack := Graphics^.GetColor(scWhite, MaxIntensity);
  icBorder := Graphics^.GetColor(scBlack, MinIntensity);
  icButton := Graphics^.GetColor(scBlack, MinIntensity);
  icButtonBack := Graphics^.GetColor(scCyan, MaxIntensity);
  icButtonDown := Graphics^.GetColor(scWhite, MaxIntensity);
  icButtonDownBack := Graphics^.GetColor(scGreen, Intensity75);
  icButtonHotKey := Graphics^.GetColor(scRed, MaxIntensity);
  icWindowTitle := Graphics^.GetColor(scBlack, MinIntensity);
  icWindowTitleBack := Graphics^.GetColor(scCyan, MaxIntensity);
  icMenu := Graphics^.GetColor(scBlack, MinIntensity);
  icMenuBack := Graphics^.GetColor(scWhite, MaxIntensity);
  icHotKey := Graphics^.GetColor(scRed, MaxIntensity);
  icScroll := Graphics^.GetColor(scBlack, MinIntensity);
  icScrollBack := Graphics^.GetColor(scCyan, MaxIntensity);
  icEditor := Graphics^.GetColor(scYellow, MaxIntensity);
  icEditorBack := Graphics^.GetColor(scBlack, MinIntensity);
  icDialog := Graphics^.GetColor(scBlack, MinIntensity);
  icDialogBack := Graphics^.GetColor(scCyan, MaxIntensity);
  icSelect := Graphics^.GetColor(scWhite, Intensity50);
  icSelectBack := Graphics^.GetColor(scGreen, MaxIntensity);
  icFocused := Graphics^.GetColor(scGreen, MaxIntensity);
end;

procedure TGraphicApplication.InitGraphicsDriver(driver: TGraphDrivers; modeId: PChar);
var
  factory: TGraphicsFactory;
  modeIndex: integer;
  mode: PGraphicsMode;
  mouseState: TMouseState;
begin
  factory.CreateGraphicsDriver(driver, Graphics);
  modeIndex := Graphics^.Modes^.IndexOfId(modeId);
  if (modeIndex < 0) then
  begin
    CreateError(Graphics^.Error, ecGraphicsModeNotFound, esError);
    exit;
  end;
  mode := Graphics^.Modes^.GetItem(modeIndex);
  Graphics^.SetMode(mode);
end;

procedure TGraphicApplication.ProcessEvents;
var
  mouseState: TMouseState;
  ch: char;
begin
  MouseDriver^.GetMouseState(mouseState);
  if not mouseState.Equals(OldMouseState^) then begin
    Graphics^.EraseMouseCursor(mouseState, OldMouseState^);
    Graphics^.DrawMouseCursor(mouseState);
    Desktop^.ProcessMouse(mouseState, OldMouseState^, MouseHandled);
    OldMouseState^ := mouseState;
  end;
  mouseState.Done;
  MouseHandled := false;
  _keyHandled := false;
  if (KeyPressed) then
  begin
    ch := ReadKey;
    if (ch = #27) then Close;
  end;  
end;

destructor TGraphicApplication.Done;
begin
  Dispose(OldMouseState, Done);
  DisposeLargeString(_modeId);
  Dispose(Graphics, Done);
  TApplication.Done;
end;

procedure TGraphicApplication.Run;
begin
  MouseDriver^.ShowMouse;
  TApplication.Run;
end;

procedure TGraphicApplication.MainLoop;
begin
  TApplication.MainLoop;
end;

end.