unit Colors;

interface

uses
  Objects;

type
  PInterfaceColors = ^TInterfaceColors;

  TInterfaceColors = object(TObject)
  public
    Desktop: byte;
    DesktopBack: byte;
    Window: byte;
    WindowBack: byte;
    Border: byte;
    Button: byte;
    ButtonBack: byte;
    ButtonDown: byte;
    ButtonDownBack: byte;
    ButtonDownHighlight: byte;
    ButtonHover: byte;
    ButtonHoverBack: byte;
    ButtonHoverHighlight: byte;
    ButtonHighlight: byte;
    ButtonDisabled: byte;
    Tab: byte;
    TabBack: byte;
    TabHover: byte;
    TabHoverBack: byte;
    TabDisabled: byte;
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
    Cursor: byte;
    CursorBack: byte;
    EditorDisabled: byte;
    procedure Init; virtual;
  end;

implementation

uses
  GraphApp,
  Graph8;

procedure TInterfaceColors.Init;
begin
  inherited Init;
  Desktop := Graph256^.GetColor256(scWhite, MaxIntensity);
  DesktopBack := Graph256^.GetColor256(scBlue, Intensity50);
  Window := 0;
  WindowBack := Graph256^.GetColor256(scWhite, MaxIntensity);
  Border := 0;
  Button := 0;
  ButtonBack := Graph256^.GetColor256(scViolet, MaxIntensity);
  ButtonDown := Graph256^.GetColor256(scWhite, MaxIntensity);
  ButtonDownBack := Graph256^.GetColor256(scViolet, MaxIntensity);
  ButtonDisabled := Graph256^.GetColor256(scWhite, Intensity75);
  ButtonHighlight := Graph256^.GetColor256(scViolet, Intensity75);
  ButtonDownHighlight := Graph256^.GetColor256(scViolet, Intensity25);
  ButtonHover := Graph256^.GetColor256(scWhite, MaxIntensity);
  ButtonHoverBack := Graph256^.GetColor256(scViolet, MaxIntensity);
  ButtonHoverHighlight := Graph256^.GetColor256(scViolet, Intensity25);
  TabBack := Graph256^.GetColor256(scWhite, MaxIntensity);
  TabDisabled := Graph256^.GetColor256(scWhite, Intensity75);
  TabHover := Graph256^.GetColor256(scViolet, MaxIntensity);
  TabHoverBack := Graph256^.GetColor256(scWhite, MaxIntensity);
  WindowTitle := Graph256^.GetColor256(scWhite, MinIntensity);
  WindowTitleBack := Graph256^.GetColor256(scViolet, MaxIntensity);
  Menu := 0;
  MenuBack := Graph256^.GetColor256(scWhite, MaxIntensity);
  Shortcut := Graph256^.GetColor256(scViolet, Intensity25);
  Scroll := Graph256^.GetColor256(scBlack, MinIntensity);
  ScrollBack := Graph256^.GetColor256(scViolet, MaxIntensity);
  Editor := 0;
  EditorBack := Graph256^.GetColor256(scWhite, MaxIntensity);
  Dialog := 0;
  DialogBack := Graph256^.GetColor256(scWhite, MaxIntensity);
  Select := Graph256^.GetColor256(scWhite, Intensity50);
  SelectBack := Graph256^.GetColor256(scViolet, MaxIntensity);
  CursorBack := Graph256^.GetColor256(scBlack, MaxIntensity);
  Cursor := Graph256^.GetColor256(scWhite, MaxIntensity);
  Focused := Graph256^.GetColor256(scGreen, Intensity50);
  EditorDisabled := Graph256^.GetColor256(scWhite, Intensity50);
end;



end.