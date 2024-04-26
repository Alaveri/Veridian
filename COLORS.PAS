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
    TabDisabled: byte;
    TabView: byte;
    TabViewBack: byte;
    TabInactive: byte;
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
  with Graph8^ do begin
    Desktop := GetColor8(scWhite, MaxIntensity);
    DesktopBack := GetColor8(scCyan, Intensity50);
    Window := 0;
    WindowBack := GetColor8(scWhite, MaxIntensity);
    Border := 0;
    Button := 0;
    intensity := 12;
    ButtonBack := GetColor8(scWhite, intensity);
    ButtonShadow := GetColor8(scWhite, intensity - 2);
    ButtonLight := GetColor8(scWhite, intensity + 3);
    ButtonDownBack := GetColor8(scWhite, intensity - 1);
    ButtonDownShadow := GetColor8(scWhite, intensity + 2);
    ButtonDownLight := GetColor8(scWhite, intensity - 2);
    ButtonDisabled := GetColor8(scWhite, Intensity50);
    ButtonHighlight := GetColor8(scBlue, Intensity75);
    Tab := 0;
    TabBack := GetColor8(scWhite, MaxIntensity);
    TabDisabled := GetColor8(scWhite, Intensity75);
    TabInactive := GetColor8(scWhite, Intensity75);
    TabView := 0;
    TabViewBack := GetColor8(scWhite, Intensity75);
    WindowTitle := 0;
    WindowTitleBack := GetColor8(scWhite, Intensity75);
    WindowActiveTitle := GetColor8(scWhite, MaxIntensity);
    WindowActiveTitleBack := GetColor8(scBlue, Intensity75);
    Menu := 0;
    MenuBack := GetColor8(scWhite, MaxIntensity);
    MenuActive := GetColor8(scWhite, MaxIntensity);
    MenuHighlight := GetColor8(scBlue, Intensity75);
    MenuActiveBack := GetColor8(scBlue, Intensity75);
    MenuActiveHighLight := GetColor8(scWhite, MaxIntensity);
    Shortcut := GetColor8(scRed, MaxIntensity);
    ScrollBack := GetColor8(scWhite, Intensity75);
    Editor := 0;
    EditorBack := GetColor8(scWhite, MaxIntensity);
    Dialog := 0;
    DialogBack := GetColor8(scWhite, MaxIntensity);
    Select := GetColor8(scBlack, MaxIntensity);
    SelectBack := GetColor8(scWhite, MaxIntensity);
    CursorBack := GetColor8(scBlack, MaxIntensity);
    Cursor := GetColor8(scWhite, MaxIntensity);
    Focused := GetColor8(scWhite, MaxIntensity);
    FocusedBack := GetColor8(scBlue, Intensity75);
    EditorDisabled := GetColor8(scWhite, Intensity50);
    ListUnfocusedSelect := 0;
    ListUnfocusedSelectBack := GetColor8(scWhite, Intensity75);
  end;
end;

end.