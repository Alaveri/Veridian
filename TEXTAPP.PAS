{$I COMPILER.INC}
unit TextApp;

interface

uses
  Objects,
  Controls,
  Crt,
  Collects,
  Apps,
  TextDrv,
  TextIni,
  Drawing,
  MouseDrv,
  GraphDrv,
  MemDrv,
  KeyDrv,
  Utils;

type
  PTextApplication = ^TTextApplication;
  TTextApplication = object(TApplication)
  private
    _keyHandled: boolean;
    _mouseVisible: boolean;
  public
    Desktop: PDesktop;
    MenuBar: PMenuBar;
    OldMouseState: PMouseState;
    MouseHandled: boolean;
    procedure InitTextDriver(driver: TTextDrivers; modeId: string); virtual;
    procedure InitDefaultColors; virtual;
    procedure InitControls;
    procedure ProcessEvents; virtual;
    procedure Init; virtual;
    procedure Run; virtual;
    procedure MainLoop; virtual;
    destructor Done; virtual;
    procedure InitMemory; virtual;
    procedure FreeMemory; virtual;
  end;

implementation

procedure TTextApplication.InitDefaultColors;
begin
  TextDriver^.BppMode := 4;
  icDesktop := White;
  icDesktopBack := Green;
  icWindow := LightCyan;
  icWindowBack := Black;
  icBorder := Black;
  icButton := Black;
  icButtonBack := Cyan;
  icButtonDown := White;
  icButtonDownBack := LightGreen;
  icButtonHotKey := LightRed;
  icWindowTitle := Black;
  icWindowTitleBack := Cyan;
  icMenu := Black;
  icMenuBack := White;
  icHotKey := LightRed;
  icScroll := Black;
  icScrollBack := Cyan;
  icEditor := Yellow;
  icEditorBack := Black;
  icDialog := Black;
  icDialogBack := Cyan;
  icSelect := LightGray;
  icSelectBack := LightGreen;
  icFocused := LightGreen;
end;

procedure TTextApplication.InitControls;
begin
  with Desktop^ do begin
    SetBounds(0, 0, TextDriver^.Mode^.Width, TextDriver^.Mode^.Height);
    ForeColor := icDesktop;
    BackColor := icDesktopBack;
    SetupControls;
  end;
end;

procedure TTextApplication.InitMemory;
{$IFDEF debug}
var
    filename: string;
    debugFile: File;
    xmsHandle: word;
    xmsControl: pointer;
{$ENDIF}
begin
    {$IFDEF debug}
  { Deallocate the last used XMS handle if the program abnormally terminated}
  filename := 'XmsDebug.bin';
  if FileExists(FileName) then
  begin
    Assign(debugFile, filename);
    Reset(debugFile, 1);
    BlockRead(debugFile, xmsHandle, SizeOf(xmsHandle));
    System.Close(debugFile);
    asm
      push es
      mov  ax, 4310h
      int  2Fh
      mov  word ptr [xmsControl], bx
      mov  word ptr [xmsControl + 2], es
      pop  es
    end;
    asm
      mov  ah, 0Ah
      mov  dx, [xmsHandle]
      call [XmsControl]
    end;
  end;
  {$ENDIF}
  Memory := New(PMemDrv, Create(InterfaceMemory));
  WriteLn('Memory manager initialized.');
  if (Memory^.XmsEnabled) then
  begin
    WriteLn
    (
      'XMS memory enabled.',
      #10#13,
      longint(Memory^.LowerMemAvail),
      ' bytes lower memory available.',
      #10#13,
      longint(Memory^.XmsMemAvail),
      ' bytes XMS memory available.'
    );
  end;
end;

procedure TTextApplication.FreeMemory;
begin
  Dispose(Memory, Done);
end;

procedure TTextApplication.Init;
var
  mouseState: TMouseState;
begin
  TApplication.Init;
  TypeName := 'TTextApplication';
  MouseHandled := false;
  _keyHandled := false;
  InitDefaultColors;
  Desktop := New(PDesktop, CreateParent('Desktop', nil));
  Desktop^.MouseState.Visible := true;
  Desktop^.MouseStack.Create;
  InitControls;
end;

procedure TTextApplication.InitTextDriver(driver: TTextDrivers; modeId: string);
var
  factory: TTextDriverFactory;
  modeIndex: integer;
  mode: PTextMode;
  mouseState: TMouseState;
begin
  factory.CreateTextDriver(driver, TextDriver);
  modeIndex := TextDriver^.Modes^.IndexOfId(modeId);
  if (modeIndex < 0) then
  begin
    CreateError(TextDriver^.Error, ecTextModeNotFound, esError);
    exit;
  end;
  mode := TextDriver^.Modes^.GetItem(modeIndex);
  TextDriver^.SetMode(mode);
end;

procedure TTextApplication.ProcessEvents;
var
  ch: char;
  mouseState: TMouseState;
  rect: TRect;
begin
  MouseDriver^.GetMouseState(mouseState);
  if not mouseState.Equals(OldMouseState^) then begin
    OldMouseState^ := mouseState;
    Desktop^.ProcessMouse(mouseState, OldMouseState^, MouseHandled);
  end;
end;

procedure TTextApplication.Run;
var
  mouseState: TMouseState;
begin
  MouseDriver^.GetMouseState(mouseState);
  OldMouseState := New(PMouseState, Create);
  OldMouseState^ := mouseState;
  TApplication.Run;
end;

procedure TTextApplication.MainLoop;
begin
  MouseHandled := false;
  _keyHandled := false;
  TApplication.MainLoop;
end;

destructor TTextApplication.Done;
begin
  Dispose(Desktop, Done);
  Dispose(TextDriver, Done);
  TApplication.Done;
end;

end.