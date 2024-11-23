{$I COMPILER.INC}
unit Colors;

interface

uses
  AplObj,
  Palettes;

type
  PColors = ^TColors;

  TColors = record
    Desktop: byte;
    DesktopBack: byte;
    Button: byte;
    ButtonBack: byte;
    ButtonBorder: byte;
    ButtonShadow: byte;
    ButtonLight: byte;
    ButtonDownBack: byte;
    ButtonDisabled: byte;
    ButtonDisabledBack: byte;
    ButtonHighlight: byte;
    View: byte;
    ViewBack: byte;
    Window: byte;
    WindowBorder: byte;
    WindowBack: byte;
    WindowTitle: byte;
    WindowTitleBack: byte;
    WindowShadow: byte;
    WindowLight: byte;
    WindowTitleActive: byte;
    WindowTitleActiveBack: byte;
    WindowBorderActive: byte;
    Shortcut: byte;
    SelectedShortcut: byte;
    Menu: byte;
    MenuBack: byte;
    MenuBorder: byte;
    MenuSelected: byte;
    MenuSelectedBack: byte;
    MenuDisabled: byte;
    MenuDisabledBack: byte;
    Scrollbar: byte;
    ScrollbarBack: byte;
    Editor: byte;
    EditorBack: byte;
    EditorDisabled: byte;
    EditorDisabledBack: byte;
    EditorFocused: byte;
    EditorFocusedBack: byte;
    Dialog: byte;
    DialogBack: byte;
    Select: byte;
    SelectBack: byte;
    ListUnfocusedSelect: byte;
    ListUnfocusedSelectBack: byte;
    Focused: byte;
    FocusedBack: byte;
  end;

const
  LightColors: TColors =
  (
    Desktop: egaWhite;
    DesktopBack: egaCyan;
    Button: egaBlack;
    ButtonBack: egaLightGray;
    ButtonBorder: egaBlack;
    ButtonShadow: egaDarkGray;
    ButtonLight: egaWhite;
    ButtonDownBack: egaDarkGray;
    ButtonDisabled: egaDarkGray;
    ButtonDisabledBack: egaLightGray;
    ButtonHighlight: egaBlue;
    View: egaBlack;
    ViewBack: egaWhite;
    Window: egaBlack;
    WindowBorder: egaBlack;
    WindowBack: egaLightGray;
    WindowTitle: egaBlack;
    WindowTitleBack: egaDarkGray;
    WindowShadow: egaDarkGray;
    WindowLight: egaWhite;
    WindowTitleActive: egaWhite;
    WindowTitleActiveBack: egaBlue;
    WindowBorderActive: egaBlack;
    Shortcut: egaLightBlue;
    SelectedShortcut: egaLightBlue;
    Menu: egaBlack;
    MenuBack: egaWhite;
    MenuBorder: egaBlack;
    MenuSelected: egaWhite;
    MenuSelectedBack: egaBlue;
    MenuDisabled: egaDarkGray;
    MenuDisabledBack: egaWhite;
    Scrollbar: egaBlack;
    ScrollbarBack: egaWhite;
    Editor: egaBlack;
    EditorBack: egaLightGray;
    EditorDisabled: egaDarkGray;
    EditorDisabledBack: egaLightGray;
    EditorFocused: egaWhite;
    EditorFocusedBack: egaCyan;
    Dialog: egaWhite;
    DialogBack: egaDarkGray;
    Select: egaWhite;
    SelectBack: egaBlue;
    ListUnfocusedSelect: egaLightGray;
    ListUnfocusedSelectBack: egaDarkGray;
    Focused: egaBlack;
    FocusedBack: egaLightGray
  );

  GreenColors: TColors =
  (
    Desktop: egaLightGreen;
    DesktopBack: egaBlack;
    Button: egaLightGreen;
    ButtonBack: egaBlack;
    ButtonBorder: egaLightGreen;
    ButtonShadow: egaLightGreen;
    ButtonLight: egaLightGreen;
    ButtonDownBack: egaBlack;
    ButtonDisabled: egaGreen;
    ButtonDisabledBack: egaBlack;
    ButtonHighlight: egaLightGreen;
    View: egaBlack;
    ViewBack: egaWhite;
    Window: egaLightGreen;
    WindowBorder: egaGreen;
    WindowBack: egaBlack;
    WindowTitle: egaBlack;
    WindowTitleBack: egaGreen;
    WindowShadow: egaGreen;
    WindowLight: egaGreen;
    WindowTitleActive: egaBlack;
    WindowTitleActiveBack: egaLightGreen;
    WindowBorderActive: egaLightGreen;
    Shortcut: egaLightGreen;
    SelectedShortcut: egaGreen;
    Menu: egaGreen;
    MenuBack: egaBlack;
    MenuBorder: egaLightGreen;
    MenuSelected: egaBlack;
    MenuSelectedBack: egaLightGreen;
    MenuDisabled: egaGreen;
    MenuDisabledBack: egaBlack;
    Scrollbar: egaBlack;
    ScrollbarBack: egaGreen;
    Editor: egaLightGreen;
    EditorBack: egaBlack;
    EditorDisabled: egaGreen;
    EditorDisabledBack: egaBlack;
    EditorFocused: egaWhite;
    EditorFocusedBack: egaLightGreen;
    Dialog: egaWhite;
    DialogBack: egaDarkGray;
    Select: egaWhite;
    SelectBack: egaBlue;
    ListUnfocusedSelect: egaLightGray;
    ListUnfocusedSelectBack: egaDarkGray;
    Focused: egaBlack;
    FocusedBack: egaLightGray
  );

implementation

begin
end.