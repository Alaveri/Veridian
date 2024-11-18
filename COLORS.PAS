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
    ButtonShadow: byte;
    ButtonLight: byte;
    ButtonDownBack: byte;
    ButtonDownShadow: byte;
    ButtonDownLight: byte;
    ButtonDisabled: byte;
    ButtonHighlight: byte;
    Window: byte;
    WindowBack: byte;
    WindowTitle: byte;
    WindowTitleBack: byte;
    WindowBorder: byte;
    WindowTitleActive: byte;
    WindowTitleActiveBack: byte;
    WindowBorderActive: byte;
    Shortcut: byte;
    Menu: byte;
    MenuBack: byte;
    MenuBorder: byte;
    MenuSelected: byte;
    MenuSelectedBack: byte;
    MenuSelectedShortcut: byte;
    MenuSelectedShortcutBack: byte;
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
    ButtonShadow: egaDarkGray;
    ButtonLight: egaWhite;
    ButtonDownBack: egaDarkGray;
    ButtonDownShadow: egaWhite;
    ButtonDownLight: egaDarkGray;
    ButtonDisabled: egaDarkGray;
    ButtonHighlight: egaBlue;
    Window: egaBlack;
    WindowBack: egaWhite;
    WindowTitle: egaBlack;
    WindowTitleBack: egaLightGray;
    WindowBorder: egaLightGray;
    WindowTitleActive: egaWhite;
    WindowTitleActiveBack: egaBlue;
    WindowBorderActive: egaBlack;
    Shortcut: egaLightBlue;
    Menu: egaBlack;
    MenuBack: egaWhite;
    MenuBorder: egaBlack;
    MenuSelected: egaWhite;
    MenuSelectedBack: egaBlue;
    MenuSelectedShortcut: egaLightBlue;
    MenuSelectedShortcutBack: egaWhite;
    MenuDisabled: egaDarkGray;
    MenuDisabledBack: egaWhite;
    Scrollbar: egaBlack;
    ScrollbarBack: egaLightGray;
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

implementation

begin
end.