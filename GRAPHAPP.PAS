unit GraphApp;

interface

uses
  Crt,
  Objects,
  MouseDrv,
  MemDrv,
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
    _modeId: string;
  public
    Desktop: PDesktop;
    OldMouseState: PMouseState;
    MouseHandled: boolean;
    procedure Init; virtual;
    procedure Run; virtual;
    procedure ProcessEvents; virtual;
    procedure InitGraphicsDriver(driver: TGraphDrivers; modeId: string); virtual;
    procedure InitDefaultColors; virtual;
    procedure InitControls; virtual;
    procedure MainLoop; virtual;
    constructor Create(const newId: string; interfaceMem: longint; driver: TGraphDrivers; modeId: string);
    destructor Done; virtual;
  end;

implementation

constructor TGraphicApplication.Create(const newId: string; interfaceMem: longint; driver: TGraphDrivers; modeId: string);
begin
  _driverId := driver;
  _modeId := modeId;
  TApplication.Create(newId, interfaceMem);
end;

procedure TGraphicApplication.Init;
var
  mouseState: TMouseState;
begin
  inherited Init;
  InitGraphicsDriver(_driverId, _modeId);
  Memory := new(PMemDrv, CreateReserved(InterfaceMemory));
  FontList := New(PFontList, Create);
  FontList^.Add(New(PSystemFont, CreateId('SystemFont')));
  MouseHandled := false;
  _keyHandled := false;
  InitDefaultColors;
  Desktop := New(PDesktop, CreateParent('Desktop', nil));
  Desktop^.MouseState.Visible := true;
  Desktop^.MouseStack.Create;
  OldMouseState := New(PMouseState, Create);
  _modeId := '';
  InitControls;
  MouseDriver^.SetMousePosition(Desktop^.Width div 2, Desktop^.Height div 2);
  MouseDriver^.GetMouseState(mouseState);
  Desktop^.Draw;
  Graphics^.MouseCursor^.StoreBackground(mouseState.X, mouseState.Y);
  Graphics^.ShowMouseCursor;
  MouseDriver^.ShowMouse;
  MouseDriver^.GetMouseState(mouseState);
  OldMouseState^.Assign(mouseState);
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

procedure TGraphicApplication.InitGraphicsDriver(driver: TGraphDrivers; modeId: string);
var
  factory: TGraphicsFactory;
  modeIndex: integer;
  mode: PGraphicsMode;
  mouseState: TMouseState;
begin
  factory.CreateGraphicsDriver(driver, Graphics);
  factory.Done;
  modeIndex := Graphics^.Modes^.IndexOfId(modeId);
  if (modeIndex < 0) then
  begin
    CreateError(Graphics^.Error, ecGraphicsModeNotFound, esError);
    halt;
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
    Graphics^.MoveMouseCursor(mouseState, oldMouseState^);
    Desktop^.ProcessMouse(mouseState, OldMouseState^, MouseHandled);
    OldMouseState^ := mouseState;
  end;
  mouseState.Done;
  MouseHandled := false;
  _keyHandled := false;
  if (KeyPressed) then
  begin
    ch := ReadKey;
    if (ch = #27) then
      Close;
  end;
end;

destructor TGraphicApplication.Done;
begin
  Dispose(FontList, Done);
  Dispose(Desktop, Done);
  Dispose(OldMouseState, Done);
  Dispose(Graphics, Done);
  Dispose(Memory, Done);
  TApplication.Done;
end;

procedure TGraphicApplication.Run;
begin
  TApplication.Run;
end;

procedure TGraphicApplication.MainLoop;
begin
  TApplication.MainLoop;
end;

end.