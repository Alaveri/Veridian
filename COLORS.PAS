{$I COMPILER.INC}
unit Colors;

interface

uses
  Objects;

type
  PColors = ^TColors;

  TColors = object(TObject)
  public
    Desktop: byte;
    DesktopBack: byte;
    Window: byte;
    WindowBack: byte;
    Border: byte;
    Button: byte;
    ButtonBack: byte;
    ButtonShadow: byte;
    ButtonLight: byte;
    ButtonDownBack: byte;
    ButtonDownShadow: byte;
    ButtonDownLight: byte;
    ButtonDisabled: byte;
    ButtonHighlight: byte;
    Tab: byte;
    TabBack: byte;
    TabHover: byte;
    TabHoverBack: byte;
    TabDisabled: byte;
    TabView: byte;
    TabViewBack: byte;
    WindowTitle: byte;
    WindowTitleBack: byte;
    WindowActiveTitle: byte;
    WindowActiveTitleBack: byte;
    Menu: byte;
    MenuBack: byte;
    MenuActive: byte;
    MenuHighlight: byte;
    MenuActiveBack: byte;
    MenuActiveHighlight: byte;
    Shortcut: byte;
    ScrollBack: byte;
    Editor: byte;
    EditorBack: byte;
    Dialog: byte;
    DialogBack: byte;
    Select: byte;
    SelectBack: byte;
    ListUnfocusedSelect: byte;
    ListUnfocusedSelectBack: byte;
    Focused: byte;
    FocusedBack: byte;
    Cursor: byte;
    CursorBack: byte;
    EditorDisabled: byte;
    procedure Init; virtual;
  end;

implementation

uses
  GraphApp,
  GrDrv8;

procedure TColors.Init;
var
  intensity: byte;
begin
  inherited Init;
  Desktop := Graph8^.GetColor8(scWhite, MaxIntensity);
  DesktopBack := Graph8^.GetColor8(scCyan, Intensity50);
  Window := 0;
  WindowBack := Graph8^.GetColor8(scWhite, MaxIntensity);
  Border := 0;
  Button := 0;
  intensity := 12;
  ButtonBack := Graph8^.GetColor8(scWhite, intensity);
  ButtonShadow := Graph8^.GetColor8(scWhite, intensity - 2);
  ButtonLight := Graph8^.GetColor8(scWhite, intensity + 3);
  ButtonDownBack := Graph8^.GetColor8(scWhite, intensity - 1);
  ButtonDownShadow := Graph8^.GetColor8(scWhite, intensity + 2);
  ButtonDownLight := Graph8^.GetColor8(scWhite, intensity - 2);
  ButtonDisabled := Graph8^.GetColor8(scWhite, Intensity50);
  ButtonHighlight := Graph8^.GetColor8(scBlue, Intensity75);
  TabBack := Graph8^.GetColor8(scWhite, Intensity75);
  TabDisabled := Graph8^.GetColor8(scWhite, Intensity75);
  TabHover := Graph8^.GetColor8(scCyan, MaxIntensity);
  TabHoverBack := Graph8^.GetColor8(scWhite, MaxIntensity);
  WindowTitle := 0;
  WindowTitleBack := Graph8^.GetColor8(scWhite, Intensity75);
  WindowActiveTitle := Graph8^.GetColor8(scWhite, MaxIntensity);
  WindowActiveTitleBack := Graph8^.GetColor8(scBlue, Intensity75);
  Menu := 0;
  MenuBack := Graph8^.GetColor8(scWhite, MaxIntensity);
  MenuActive := Graph8^.GetColor8(scWhite, MaxIntensity);
  MenuHighlight := Graph8^.GetColor8(scBlue, Intensity75);
  MenuActiveBack := Graph8^.GetColor8(scBlue, Intensity75);
  MenuActiveHighLight := Graph8^.GetColor8(scWhite, MaxIntensity);
  Shortcut := Graph8^.GetColor8(scRed, MaxIntensity);
  ScrollBack := Graph8^.GetColor8(scWhite, Intensity75);
  Editor := 0;
  EditorBack := Graph8^.GetColor8(scWhite, MaxIntensity);
  Dialog := 0;
  DialogBack := Graph8^.GetColor8(scWhite, MaxIntensity);
  Select := Graph8^.GetColor8(scBlack, MaxIntensity);
  SelectBack := Graph8^.GetColor8(scWhite, MaxIntensity);
  CursorBack := Graph8^.GetColor8(scBlack, MaxIntensity);
  Cursor := Graph8^.GetColor8(scWhite, MaxIntensity);
  Focused := Graph8^.GetColor8(scWhite, MaxIntensity);
  FocusedBack := Graph8^.GetColor8(scBlue, Intensity75);
  EditorDisabled := Graph8^.GetColor8(scWhite, Intensity50);
  ListUnfocusedSelect := 0;
  ListUnfocusedSelectBack := Graph8^.GetColor8(scWhite, Intensity75);
end;

end.