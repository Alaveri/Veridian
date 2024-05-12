{$I COMPILER.INC}
unit Desk;

interface

uses
  {$IFDEF DOS}
  Strings,
  {$ENDIF}
  AplObj,
  AplTypes,
  Lists,
  Drawing,
  Common,
  StrUtils,
  AplApps,
  Errors,
  GraphDrv,
  MouseDrv,
  KeyDrv,
  Actions,
  Controls,
  Colors,
  Combos,
  Views;

type
  PDesktop = ^TDesktop;
  PMenu = ^TMenu;
  PMenuBar = ^TMenuBar;
  PMenuItem = ^TMenuItem;
  PMainMenuItem = ^TMainMenuItem;
  PStatusBar = ^TStatusBar;

  TMenuItem = object(TActionControl)
  private
  public
    Separator: boolean;
    ParentMenu: PMenu;
    Menu: PMenu;
    Active: boolean;
    ActiveForeColor: byte;
    ActiveBackColor: byte;
    ActiveHighlightColor: byte;
    constructor CreateSeparator;
    procedure KeyPress(var AEvent: TKeyEvent); virtual;
    procedure MouseEnter(var AEvent: TMouseEvent); virtual;
    procedure MouseLeave(var AEvent: TMouseEvent); virtual;
    procedure MouseDown(var AEvent: TMouseEvent); virtual;
    procedure MouseClick(var AEvent: TMouseEvent); virtual;
    procedure Paint; virtual;
    procedure Init; virtual;
    procedure ActivateMenu; virtual;
    procedure DeactivateMenu; virtual;
    procedure Activate; virtual;
    procedure Deactivate; virtual;
    function AddMenu(AMenu: PMenu): PMenu; virtual;
    function NewMenu(AId: string): PMenu; virtual;
    function IsMainMenuItem: boolean; virtual;
  end;

  TMainMenuItem = object(TMenuItem)
  private
  public
    procedure MouseEnter(var AEvent: TMouseEvent); virtual;
    procedure MouseLeave(var AEvent: TMouseEvent); virtual;
  end;

  TMenu = object(TPopUp)
  private
  public
    ActiveItem: PMenuItem;
    function NewMenuItem(AId: string; AActionId: integer): PMenuItem;
    function AddMenuItem(AItem: PMenuItem): PMenuItem; virtual;
    function NewSeparator: PMenuItem; virtual;
    procedure Activate; virtual;
    procedure Deactivate; virtual;
    procedure Init; virtual;
    procedure Show; virtual;
    procedure Hide; virtual;
    procedure SetupControls; virtual;
    procedure Paint; virtual;
    function ParentItem: PMenuItem; virtual;
  end;

  TMenuBar = object(TTextControl)
  private
  public
    procedure Init; virtual;
    procedure Paint; virtual;
    procedure SetupControls; virtual;
    procedure KeyPress(var AEvent: TKeyEvent); virtual;
    function GetActiveMenuItem: PMenuItem; virtual;
    function GetNextActiveMenuItem(AOldMenuItem: PMenuItem; AForward: boolean): PMenuItem; virtual;
    function AddMenuItem(AMenuItem: PMenuItem): PMenuItem; virtual;
    function NewMenu(AId, AText: string): PMenu; virtual;
  end;

  TDesktop = object(TPanel)
  private
  public
    MenuBar: PMenuBar;
    StatusBar: PStatusBar;
    ActiveControl: PControl;
    ActiveMenu: PMenu;
    ActiveView: PView;
    ActiveDropDown: PDropDownList;
    ActionList: PActionList;
    Colors: PColors;
    destructor Free; virtual;
    function AddMenuBar(AMenuBar: PMenuBar): PMenuBar; virtual;
    function FindNextControl(AControl: PControl): PControl; virtual;
    function FindPreviousControl(AControl: PControl): PControl; virtual;
    procedure Init; virtual;
    procedure Paint; virtual;
    procedure GetClientRect(var ARect: TRect); virtual;
    procedure SetColors(AColors: PColors); virtual;
    procedure SetupControls; virtual;
    procedure DeactivateCurrentMenu; virtual;
  end;

  TStatusBar = object(TPanel)
  private
  public
    CurrentAction: PAction;
    procedure Init; virtual;
    destructor Free; virtual;
    function NewHelpPanel: PTextControl;
    procedure MouseEnter(var AEvent: TMouseEvent); virtual;
    procedure MouseLeave(var AEvent: TMouseEvent); virtual;
    procedure SetupControls; virtual;
    procedure ClearText; virtual;
    procedure ShowActionHelp(AAction: PAction); virtual;
  end;

var
  Desktop: PDesktop;

implementation

uses
  Veridian,
  GraphApp,
  GrDrv8;

procedure TDesktop.DeactivateCurrentMenu;
var
  parentItem: PMenuItem;
  activeItem: PMenuItem;
begin
  if not Assigned(ActiveMenu) then
    exit;
  parentItem := ActiveMenu^.ParentItem;
  parentItem^.IsMouseOver := false;
  parentItem^.IsLeftMouseDown := false;
  parentItem^.DrawSelf;
  ActiveMenu^.Deactivate;
  StatusBar^.ClearText;
end;

procedure TDesktop.SetColors(AColors: PColors);
begin
  FreeAndNil(Colors);
  Colors := AColors;
end;

procedure TDesktop.SetupControls;
begin
  SetBounds(0, 0, Graph^.Mode^.Width, Graph^.Mode^.Height);
  MenuBar^.SetupControls;
  StatusBar^.SetupControls;
end;

procedure TDesktop.Init;
begin
  inherited Init;
  Font := VeridianApp^.Fonts^.GetItemById('System');
  Colors := New(PColors, Create);
  Desktop := @self;
  DrawBackground := true;
  BorderStyle := bsNone;
  ActionList := New(PActionList, Create);
  ActiveControl := nil;
  ActiveMenu := nil;
  ActiveView := nil;
  ActiveDropDown := nil;
  ForeColor := Colors^.Desktop;
  BackColor := Colors^.DesktopBack;
end;

destructor TDesktop.Free;
begin
  FreeAndNil(ActionList);
  FreeAndNil(Colors);
  inherited Free;
end;

procedure TDesktop.Paint;
begin
  inherited Paint;
end;

procedure TDesktop.GetClientRect(var ARect: TRect);
begin
  ARect.CreateDims(0, 0, Graph^.Mode^.Width, Graph^.Mode^.Height);
end;

function TDesktop.FindNextControl(AControl: PControl): PControl;
begin
end;

function TDesktop.AddMenuBar(AMenuBar: PMenuBar): PMenuBar;
begin
  Controls^.Add(AMenuBar);
end;

function TDesktop.FindPreviousControl(AControl: PControl): PControl;
begin
end;

procedure TMenu.Show;
begin;
  inherited Show;
end;

procedure TMenu.Activate;
begin
  VeridianApp^.PushState;
  VeridianApp^.CursorOff;
  Desktop^.DeactivateCurrentMenu;
  Desktop^.ActiveMenu := @self;
  ActiveItem := nil;
  Show;
end;

procedure TMenu.Deactivate;
begin
  if Assigned(ActiveItem) then
    ActiveItem^.Deactivate;
  ActiveItem := nil;
  if Desktop^.ActiveMenu = @self then
    Desktop^.ActiveMenu := nil;
  Hide;
  if ParentItem <> nil then
    ParentItem^.Deactivate;
  VeridianApp^.PopState;
  if VeridianApp^.State.CursorOn then
    VeridianApp^.CursorOn;
end;

procedure TMenu.Hide;
begin
  Graph^.PushState;
  if typeof(Parent^) = typeof(TMainMenuItem) then begin
    Graph^.State.ViewPort.Translate(0, 1);
     Graph^.State.ViewPort.Grow(0, -1);
  end;
  inherited Hide;
  Graph^.PopState;
end;

function TMenu.ParentItem: PMenuItem;
begin
  ParentItem := PMenuItem(Parent);
end;

procedure TMenu.SetupControls;
var
  index: word;
  itemWidth: integer;
  currentY: integer;
  item: PMenuItem;
  totalHeight: integer;
  shortcutDesc: string;
  parentRect: TRect;
begin
  currentY := Font^.Height div 2;
  totalHeight := 0;
  itemWidth := 0;
  if Controls^.Count > 0 then begin
    for index := 0 to Controls^.Count - 1 do begin
      item := PMenuItem(Controls^.GetItem(index));
      shortcutDesc := '';
      if item^.GetShortcut >= 0 then
        shortcutDesc := Keyboard.KeyToShortcut(item^.GetShortcut);
      if not item^.GetVisible then
        continue;
      item^.TextAlign := taLeft;
      item^.VertAlign := vaCenter;
      item^.X := BorderWidth;
      item^.Y := currentY;
      item^.Margin := 2 * item^.Font^.Spacing;
      itemWidth :=
        Max(TrueTextWidth(item^.GetText)
          + 2 * item^.Margin
          + Font^.TextWidth(shortcutDesc)
          + 8 * Font^.Spacing
          , itemWidth);
      item^.Height := Font^.Height + 1;
      Inc(currentY, item^.Height);
      Inc(totalHeight, item^.Height);
    end;
    for index := 0 to Controls^.Count - 1 do begin
      item := PMenuItem(Controls^.GetItem(index));
      item^.Width := itemWidth;
    end;
  end;
  Width := itemWidth + 2 * BorderWidth;
  Height := totalHeight + Font^.Height;
  if ParentItem <> nil then begin
    if typeof(ParentItem^) = typeof(TMainMenuItem) then begin
      X := ParentItem^.X;
      Y := Desktop^.MenuBar^.Height - 1;
    end
    else begin
{      ParentItem^.GetScreenBounds(parentRect);
      X := parentRect.X + ParentItem^.Width + parentRect.X - 1;
      Y := parentRect.Y - ParentItem^.Y;}
    end;
  end;
end;

function TMenu.AddMenuItem(AItem: PMenuItem): PMenuItem;
begin
  Controls^.Add(AItem);
  AItem^.ParentMenu := @Self;
  AddMenuItem := AItem;
end;

function TMenu.NewSeparator: PMenuItem;
var
  control: PMenuItem;
begin
  control := New(PMenuItem, CreateSeparator);
  control^.ParentMenu := @self;
  Controls^.Add(control);
  NewSeparator := control;
end;

procedure TMenu.Init;
begin
  inherited Init;
  Position := spAbsolute;
  Visible := false;
  ForeColor := Desktop^.Colors^.Menu;
  BackColor := Desktop^.Colors^.MenuBack;
  BorderStyle := bsSingle;
  ActiveItem := nil;
end;

procedure TMenu.Paint;
begin
  Graph^.PushState;
  if typeof(Parent^) = typeof(TMainMenuItem) then begin
    Graph^.State.ViewPort.Translate(0, 1);
    Graph^.State.ViewPort.Grow(0, -1);
  end;
  inherited Paint;
  Graph^.PopState;
end;

function TMenu.NewMenuItem(AId: string; AActionId: integer): PMenuItem;
var
  item: PMenuItem;
begin
  item := New(PMenuItem, CreateParent(AId, AActionId, @self));
  item^.ParentMenu := @self;
  NewMenuItem := item;
end;

constructor TMenuItem.CreateSeparator;
begin
  Init;
  ShowShortcut := false;
  Separator := true;
end;

function TMenuItem.AddMenu(aMenu: PMenu): PMenu;
begin
  Init;
  Controls^.Add(aMenu);
  aMenu^.Parent := @self;
  AddMenu := aMenu;
end;

function TMenuItem.NewMenu(AId: string): PMenu;
begin
  Menu := New(PMenu, CreateParent(AId, @self));
  Menu^.Parent := @self;
  NewMenu := Menu;
end;

function TMenuItem.IsMainMenuItem;
begin
  IsMainMenuItem := false;
end;

procedure TMenuItem.Init;
begin
  inherited Init;
  Parent := nil;
  Separator := false;
  Enabled := true;
  Shortcut := 0;
  ShowShortcut := true;
  ParentMenu := nil;
  Menu := nil;
  ForeColor := Desktop^.Colors^.Menu;
  BackColor := Desktop^.Colors^.MenuBack;
  HighlightColor := Desktop^.Colors^.MenuHighlight;
  ActiveForeColor := Desktop^.Colors^.MenuActive;
  ActiveBackColor := Desktop^.Colors^.MenuActiveBack;
  ActiveHighlightColor := Desktop^.Colors^.MenuActiveHighlight;
  BorderStyle := bsNone;
  VertAlign := vaCenter;
  TextAlign := taLeft;
  Active := false;
end;

procedure TMenuItem.Activate;
begin
  Active := true;
  if Assigned(ParentMenu) then begin
    if Assigned(ParentMenu^.ActiveItem) and (ParentMenu^.ActiveItem <> @self) then
      ParentMenu^.ActiveItem^.Deactivate;
    ParentMenu^.ActiveItem := @self;
  end;
  DrawSelf;
end;

procedure TMenuItem.Deactivate;
begin
  Active := false;
  if Assigned(ParentMenu) then
    ParentMenu^.ActiveItem := nil;
  IsMouseOver := false;
  IsLeftMouseDown := false;
  IsRightMouseDown := false;
  DrawSelf;
end;

procedure TMenuItem.KeyPress(var AEvent: TKeyEvent);
var
  hotKey: word;
begin
  hotKey := GetAltHotkey;
  if (AEvent.Key = hotKey) and (typeof(Parent^) = typeof(TMenuBar)) then begin
    Desktop^.DeactivateCurrentMenu;
    ActivateMenu;
    AEvent.Handled := true;
    exit;
  end;
end;

procedure TMainMenuItem.MouseEnter(var AEvent: TMouseEvent);
var
  activeMenu: PMenu;
  activeItem: PMenuItem;
  index: integer;
begin
  if not (GetVisible and GetEnabled) then
    exit;
  activeMenu := Desktop^.ActiveMenu;
  if Assigned(activeMenu) and (activeMenu <> Menu) then begin
    Desktop^.DeactivateCurrentMenu;
    Menu^.Activate;
  end;
  inherited MouseEnter(AEvent);
end;

procedure TMainMenuItem.MouseLeave(var AEvent: TMouseEvent);
begin
  if Assigned(Menu) and (Menu^.GetVisible) then
    exit;
  inherited MouseLeave(AEvent);
end;

procedure TMenuItem.MouseEnter(var AEvent: TMouseEvent);
begin
  if not (GetVisible and GetEnabled) then
    exit;
  if Assigned(Action) then
    Desktop^.StatusBar^.ShowActionHelp(Action);
  Activate;
  inherited MouseEnter(AEvent);
end;

procedure TMenuItem.MouseLeave(var AEvent: TMouseEvent);
begin
  IsMouseOver := false;
  IsLeftMouseDown := false;
  IsRightMouseDown := false;
  Desktop^.StatusBar^.ClearText;
  Deactivate;
  inherited MouseLeave(AEvent);
end;

procedure TMenuItem.MouseDown(var AEvent: TMouseEvent);
var
  parentItem: PMenuItem;
begin
  if not (GetEnabled and GetVisible) then
    exit;
  if Assigned(Menu) then
    ActivateMenu;
end;

procedure TMenuItem.MouseClick(var AEvent: TMouseEvent);
begin
  if not GetEnabled then
    exit;
  if Assigned(Action) and (Action^.Enabled) then
    Desktop^.DeactivateCurrentMenu;
  inherited MouseClick(AEvent);
end;

procedure TMenuItem.Paint;
var
  rect: TRect;
  desc: string;
  fore, back, highlight: byte;
begin
  if not GetVisible then
    exit;
  if Separator then begin
    GetScreenBounds(rect);
    Graph^.SetForeColor(BorderColor);
    Graph^.HLine(rect.X, rect.Y + (rect.Height div 2), rect.Width);
    exit;
  end;
  fore := ForeColor;
  back := BackColor;
  highlight := HighlightColor;
  if Active or IsMouseOver then begin
    ForeColor := ActiveForeColor;
    BackColor := ActiveBackColor;
    HighlightColor := ActiveHighlightColor;
  end;
  inherited Paint;
  ForeColor := fore;
  BackColor := back;
  HighlightColor := highlight;
end;

procedure TMenuBar.SetupControls;
var
  index: word;
  currentX: word;
  control: PMenuItem;
  spaceWidth: integer;
begin
  currentX := Font^.TextWidth(' ') + BorderWidth;
  SetBounds(0, 0, Desktop^.Width, Font^.Height + 3);
  if Controls^.Count = 0 then exit;
  spaceWidth := Font^.TextWidth(' ');
  for index := 0 to Controls^.Count - 1 do begin
    control := PMenuItem(Controls^.GetItem(index));
    with control^ do begin
      X := currentX;
      Y := 0;
      Height := Font^.Height + 2;
      Width := TrueTextWidth(GetText) + 2 * spaceWidth;
      Margin := spaceWidth;
      Inc(currentX, Width);
    end;
  end;
end;

procedure TMenuBar.Paint;
var
  rect: TRect;
begin
  inherited Paint;
  GetScreenBounds(rect);
  Graph^.SetForeColor(BorderColor);
  Graph^.HLine(rect.X, rect.Bottom, rect.Width);
end;

function TMenuBar.GetActiveMenuItem: PMenuItem;
var
  index: integer;
  menuItem: PMenuItem;
  activeMenu : PMenu;
begin
  GetActiveMenuItem := nil;
  activeMenu := Desktop^.ActiveMenu;
  if not Assigned(activeMenu) or (not Assigned(activeMenu^.ActiveItem)) then
    exit;
  GetActiveMenuItem := activeMenu^.ActiveItem;
end;

function TMenuBar.GetNextActiveMenuItem(AOldMenuItem: PMenuItem; AForward: boolean): PMenuItem;
var
  index : integer;
  activeItem: PList;
  menuItem: PMenuItem;
  totalItems: integer;
begin
  if not Assigned(Desktop^.ActiveMenu) then begin
    GetNextActiveMenuItem := nil;
    exit;
  end;
  menuItem := GetActiveMenuItem;
  if not Assigned(menuItem) then
    index := -1
  else
    index := Desktop^.ActiveMenu^.Controls^.IndexOf(menuItem);
  totalItems := 0;
  repeat
    if AForward then
      Inc(index)
    else
      Dec(index);
    Inc(totalItems);
    if (index > Desktop^.ActiveMenu^.Controls^.Count) and (AForward) then
      index := 0;
    if index < 0 then
      index := Desktop^.ActiveMenu^.Controls^.Count - 1;
    menuItem := PMenuItem(Desktop^.ActiveMenu^.Controls^.GetItem(index));
    if not Assigned(menuItem) then
      continue;
    if (not menuItem^.Separator) and (menuItem^.GetEnabled) then begin
      break;
    end;
  until (totalItems > Desktop^.ActiveMenu^.Controls^.Count);

  GetNextActiveMenuItem := menuItem;
  if Assigned(AOldMenuItem) then begin
    AOldMenuItem^.IsLeftMouseDown := false;
    AOldMenuItem^.DrawSelf;
  end;
end;

procedure TMenuItem.ActivateMenu;
begin
  Active := true;
  if Assigned(Menu) then begin
    Menu^.Activate;
    DrawSelf;
  end;
end;

procedure TMenuItem.DeactivateMenu;
begin
  IsMouseOver := false;
  IsLeftMouseDown := false;
  IsRightMouseDown := false;
  Active := false;
  if Assigned(Menu) then
   Menu^.Deactivate;
end;

procedure TMenuBar.KeyPress(var AEvent: TKeyEvent);
var
  menuItem, activeItem: PMenuItem;
  index: integer;
  action: PAction;
  activeMenu: PMenu;
begin
  inherited KeyPress(AEvent);
  activeMenu := Desktop^.ActiveMenu;
  if AEvent.Handled then
    exit;
  if not Assigned(activeMenu) then
    exit;

  if AEvent.Key = kyEsc then begin
    if Assigned(activeMenu^.activeItem) then begin
      activeMenu^.activeItem^.Active := false;
      activeMenu^.activeItem^.Draw;
    end;
    Desktop^.DeactivateCurrentMenu;
    VeridianApp^.PopState;
    if VeridianApp^.State.CursorOn then
      VeridianApp^.CursorOn;
    AEvent.Handled := true;
    exit;
  end;

  case AEvent.Key of
    kyLeft: begin
      menuItem := Desktop^.ActiveMenu^.ParentItem;
      index := Controls^.IndexOf(menuItem);
      Dec(index);
      if (index < 0) then
        index := Controls^.Count - 1;
      activeItem := GetActiveMenuItem;
      if Assigned(activeItem) then
        activeItem^.Deactivate;
      menuItem := PMenuItem(Controls^.GetItem(index));
      menuItem^.ActivateMenu;
      menuItem^.Activate;
      AEvent.Handled := true;
      exit;
    end;

    kyRight: begin
      menuItem := Desktop^.ActiveMenu^.ParentItem;
      index := Controls^.IndexOf(menuItem);
      Inc(index);
      if (index > Controls^.Count - 1) then
        index := 0;
      activeItem := GetActiveMenuItem;
      if Assigned(activeItem) then
        activeItem^.Deactivate;
      menuItem := PMenuItem(Controls^.GetItem(index));
      menuItem^.ActivateMenu;
      menuItem^.Activate;
      AEvent.Handled := true;
      exit;
    end;

    kyUp, kyDown: begin
      activeItem := GetActiveMenuItem;
      menuItem := GetNextActiveMenuItem(activeItem, AEvent.Key = kyDown);
      if Assigned(activeItem) then
        activeItem^.Deactivate;
      if Assigned(menuItem) then begin
        menuItem^.Activate;
        menuItem^.DrawSelf;
        Desktop^.StatusBar^.ShowActionHelp(menuItem^.Action);
        Desktop^.ActiveMenu^.ActiveItem := menuItem;
        menuItem^.DrawSelf;
        AEvent.Handled := true;
        exit;
      end;
    end;

    kyEnter: begin
      activeItem := GetActiveMenuItem;
      if not Assigned(activeItem) then
        exit;
      Desktop^.DeactivateCurrentMenu;
      if Assigned(activeItem) then
        activeItem^.Deactivate;
      AEvent.Handled := true;
      action := activeItem^.Action;
      if not Assigned(action) then
        exit;
      VeridianApp^.HandleActionExecute(activeItem, action);
      exit;
    end;
  end;

  if (not Assigned(Desktop^.ActiveMenu)) or (Desktop^.ActiveMenu^.Controls^.Count = 0) then
    exit;
  for index := 0 to Desktop^.ActiveMenu^.Controls^.Count - 1 do begin
    menuItem := PMenuItem(Desktop^.ActiveMenu^.Controls^.GetItem(index));
    AEvent.Key := Keyboard.UpCase(AEvent.Key);
    if not (Assigned(menuItem^.Action) and (menuItem^.Action^.Enabled)) then
      continue;
    if not menuItem^.Action^.Enabled then
      continue;
    if AEvent.Key <> menuItem^.GetHotKey then
      continue;
    activeItem := GetActiveMenuItem;
    if Assigned(activeItem) then
      activeItem^.Deactivate;
    Desktop^.DeactivateCurrentMenu;
    VeridianApp^.HandleActionExecute(menuItem, menuItem^.Action);
    break;
  end;
  AEvent.Handled := true;
end;

function TMenuBar.AddMenuItem(AMenuItem: PMenuItem): PMenuItem;
begin
  Controls^.Add(AMenuItem);
  AddMenuItem := AMenuItem;
end;

function TMenuBar.NewMenu(AId, AText: string): PMenu;
var
  item: PMainMenuItem;
  menu: PMenu;
begin
  item := New(PMainMenuItem, CreateParent(AId + 'Item', -1, @self));
  item^.Text := TString.New(AText);
  menu := New(PMenu, CreateParent(AId, item));
  item^.Menu := menu;
  NewMenu := menu;
end;

procedure TMenuBar.Init;
var
  rect: TRect;
begin
  inherited Init;
  Position := spAbsolute;
  ForeColor := Desktop^.Colors^.Menu;
  BackColor := Desktop^.Colors^.MenuBack;
  BorderStyle := bsNone;
end;

function TStatusBar.NewHelpPanel: PTextControl;
var
  result: PTextControl;
begin
  result := New(PTextControl, CreateParent('HelpPanel', @self));
  result^.BackColor := ForeColor;
  result^.BackColor := BackColor;
  result^.Margin := 4;
  result^.TextOffsetX := 2;
  with result^ do begin
    SetBounds(
      -BorderWidth,
      0,
      Desktop^.ActionList^.GetHelpMaxWidth(result) + 2 * Margin + BorderWidth,
      Desktop^.Font^.Height + Margin
    );
  end;
  NewHelpPanel := result;
end;

procedure TStatusBar.Init;
begin
  inherited Init;
  Position := spAbsolute;
  ForeColor := Desktop^.Colors^.Menu;
  BackColor := Desktop^.Colors^.MenuBack;
  CurrentAction := nil;
end;

destructor TStatusBar.Free;
begin
  inherited Free;
end;

procedure TStatusBar.MouseEnter(var AEvent: TMouseEvent);
begin
end;

procedure TStatusBar.MouseLeave(var AEvent: TMouseEvent);
begin
end;

procedure TStatusBar.SetupControls;
var
  rect: TRect;
begin
  Desktop^.GetBounds(rect);
  SetBounds(-BorderWidth, rect.Height - Font^.Height - 3,
  rect.Width + 2 * BorderWidth, Font^.Height + 6);
end;

procedure TStatusBar.ShowActionHelp(AAction: PAction);
var
  helpPanel: PTextControl;
begin
  if not Assigned(AAction) then
    exit;
  CurrentAction := AAction;
  if AAction^.HelpText = nil then
    exit;
  helpPanel := PTextControl(Controls^.GetItemById('HelpPanel'));
  if Assigned(helpPanel) then
    helpPanel^.SetText(StrPas(AAction^.HelpText));
end;

procedure TStatusBar.ClearText;
var
  helpPanel: PTextControl;
begin
  if not Assigned(CurrentAction) then
    exit;
  CurrentAction := nil;
  helpPanel := PTextControl(Controls^.GetItemById('HelpPanel'));
  if Assigned(helpPanel) then begin
    TString.Free(HelpPanel^.Text);
    helpPanel^.SetText('');
  end;
end;

end.