{$I COMPILER.INC}
unit Colors;

interface

uses
  AplObj;

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
  AplGraph,
  AplPal,
  AplGrap8;

procedure TColors.Init;
begin
  inherited Init;
  with Graph8^ do begin
    Desktop := egaWhite;
    DesktopBack := egaCyan;
    Window := 0;
    WindowBack := egaWhite;
    Border := 0;
    Button := 0;
    ButtonBack := egaLightGray;
    ButtonShadow := egaDarkGray;
    ButtonLight := egaWhite;
    ButtonDownBack := egaDarkGray;
    ButtonDownShadow := egaWhite;
    ButtonDownLight := egaDarkGray;
    ButtonDisabled := egaDarkGray;
    ButtonHighlight := egaBlue;
    Tab := 0;
    TabBack := egaWhite;
    TabDisabled := egaDarkGray;
    TabInactive := egaLightGray;
    TabView := 0;
    TabViewBack := egaLightGray;
    WindowTitle := 0;
    WindowTitleBack := egaWhite;
    WindowActiveTitle := egaWhite;
    WindowActiveTitleBack := egaBlue;
    Menu := 0;
    MenuBack := egaWhite;
    MenuActive := egaWhite;
    MenuHighlight := egaBlue;
    MenuActiveBack := egaBlue;
    MenuActiveHighLight := egaWhite;
    Shortcut := egaRed;
    ScrollBack := egaLightGray;
    Editor := 0;
    EditorBack := egaWhite;
    Dialog := 0;
    DialogBack := egaWhite;
    Select := 0;
    SelectBack := egaWhite;
    CursorBack := 0;
    Cursor := egaWhite;
    Focused := egaWhite;
    FocusedBack := egaBlue;
    EditorDisabled := egaWhite;
    ListUnfocusedSelect := 0;
    ListUnfocusedSelectBack := egaWhite;
  end;
end;

end.