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
    _mouseVisible: boolean;
    _driverId: TGraphDrivers;
    _modeId: string;
    _eventInfo: TEventInfo;
  public
    Desktop: PDesktop;
    OldMouseState: PMouseState;
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

  TInterfaceColors = record
    Desktop: byte;
    DesktopBack: byte;
    Window: byte;
    WindowBack: byte;
    Border: byte;
    Button: byte;
    ButtonBack: byte;
    ButtonDown: byte;
    ButtonDownBack: byte;
    ButtonHover: byte;
    ButtonHoverBack: byte;
    ButtonShortcut: byte;
    WindowTitle: byte;
    WindowTitleBack: byte;
    Menu: byte;
    MenuBack: byte;
    Shortcut: byte;
    Scroll: byte;
    ScrollBack: byte;
    Editor: byte;
    EditorBack: byte;
    Dialog: byte;
    DialogBack: byte;
    Select: byte;
    SelectBack: byte;
    Focused: byte;
    FocusedBack: byte;
  end;

var
  InterfaceColors: TInterfaceColors;
  FontList: PFontList;

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
  _eventInfo.Create;
  _eventInfo.Desktop := Desktop;
end;

procedure TGraphicApplication.InitControls;
begin
  with Desktop^ do begin
    SetBounds(0, 0, Graphics^.Mode^.Width, Graphics^.Mode^.Height);
    ForeColor := InterfaceColors.Desktop;
    BackColor := InterfaceColors.DesktopBack;
    SetupControls;
  end;
end;

procedure TGraphicApplication.InitDefaultColors;
begin
  InterfaceColors.Desktop := Graphics^.GetColor(scWhite, MaxIntensity);
  InterfaceColors.DesktopBack := Graphics^.GetColor(scGreen, MaxIntensity);
  InterfaceColors.Window := Graphics^.GetColor(scCyan, MaxIntensity);
  InterfaceColors.WindowBack := Graphics^.GetColor(scWhite, MaxIntensity);
  InterfaceColors.Border := Graphics^.GetColor(scBlack, MinIntensity);
  InterfaceColors.Button := Graphics^.GetColor(scBlack, MinIntensity);
  InterfaceColors.ButtonBack := Graphics^.GetColor(scCyan, MaxIntensity);
  InterfaceColors.ButtonDown := Graphics^.GetColor(scBlack, MaxIntensity);
  InterfaceColors.ButtonDownBack := Graphics^.GetColor(scGreen, MaxIntensity);
  InterfaceColors.ButtonShortcut := Graphics^.GetColor(scRed, MaxIntensity);
  InterfaceColors.ButtonHover := Graphics^.GetColor(scBlack, MaxIntensity);
  InterfaceColors.ButtonHoverBack := Graphics^.GetColor(scGreen, MaxIntensity);
  InterfaceColors.WindowTitle := Graphics^.GetColor(scBlack, MinIntensity);
  InterfaceColors.WindowTitleBack := Graphics^.GetColor(scCyan, MaxIntensity);
  InterfaceColors.Menu := Graphics^.GetColor(scBlack, MinIntensity);
  InterfaceColors.MenuBack := Graphics^.GetColor(scWhite, MaxIntensity);
  InterfaceColors.Shortcut := Graphics^.GetColor(scRed, MaxIntensity);
  InterfaceColors.Scroll := Graphics^.GetColor(scBlack, MinIntensity);
  InterfaceColors.ScrollBack := Graphics^.GetColor(scCyan, MaxIntensity);
  InterfaceColors.Editor := Graphics^.GetColor(scYellow, MaxIntensity);
  InterfaceColors.EditorBack := Graphics^.GetColor(scBlack, MinIntensity);
  InterfaceColors.Dialog := Graphics^.GetColor(scBlack, MinIntensity);
  InterfaceColors.DialogBack := Graphics^.GetColor(scCyan, MaxIntensity);
  InterfaceColors.Select := Graphics^.GetColor(scWhite, Intensity50);
  InterfaceColors.SelectBack := Graphics^.GetColor(scGreen, MaxIntensity);
  InterfaceColors.Focused := Graphics^.GetColor(scGreen, MaxIntensity);
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
  _eventInfo.Clear;

  MouseDriver^.GetMouseState(mouseState);
  if not mouseState.Equals(OldMouseState^) then begin
    Graphics^.MoveMouseCursor(mouseState, oldMouseState^);
    _eventInfo.OldMouseState.Assign(OldMouseState^);
    _eventInfo.NewMouseState.Assign(mouseState);
    Desktop^.ProcessMouse(_eventInfo);
    OldMouseState^ := mouseState;
  end;

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