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
    EditorBorder: byte;
    Dialog: byte;
    DialogBack: byte;
    Select: byte;
    SelectBack: byte;
    ListSelected: byte;
    ListSelectedBack: byte;
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
    Scrollbar: egaLightGray;
    ScrollbarBack: egaDarkGray;
    Editor: egaBlack;
    EditorBack: egaWhite;
    EditorDisabled: egaDarkGray;
    EditorDisabledBack: egaWhite;
    EditorFocused: egaWhite;
    EditorFocusedBack: egaBlue;
    EditorBorder: egaBlack;
    Dialog: egaWhite;
    DialogBack: egaDarkGray;
    Select: egaWhite;
    SelectBack: egaBlue;
    ListSelected: egaWhite;
    ListSelectedBack: egaBlue;
    ListUnfocusedSelect: egaLightGray;
    ListUnfocusedSelectBack: egaDarkGray;
    Focused: egaWhite;
    FocusedBack: egaBlue
  );

implementation

begin
end.