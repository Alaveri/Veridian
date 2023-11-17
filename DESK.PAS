{$IFDEF debug}
  {$A-,B-,D+,E+,F+,G-,I+,L+,N+,M 16384 0 655360,O-,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,E+,F+,G-,I+,L-,N+,M 16384 0 655360,O-,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}
unit Desk;

interface

uses
  Objects,
  Collects,
  Actions,
  Controls,
  Drawing,
  Common,
  StrUtils,
  Strings,
  Apps,
  KeyDrv,
  GraphDrv,
  Except,
  Colors,
  MouseDrv;

type
  PDesktop = ^TDesktop;
  PMenu = ^TMenu;
  PMenuBar = ^TMenuBar;
  PMenuItem = ^TMenuItem;
  PMainMenuItem = ^TMainMenuItem;
  PStatusBar = ^TStatusBar;

  TMenuItem = object(TButton)
  private
  public
    Separator: boolean;
    ParentMenu: PMenu;
    Menu: PMenu;
    MenuBar: PMenuBar;
    constructor CreateSeparator;
    procedure KeyPress(var AEvent: TEvent); virtual;
    procedure MouseEnter(var AEvent: TEvent); virtual;
    procedure MouseLeave(var AEvent: TEvent); virtual;
    procedure MouseDown(var AEvent: TEvent); virtual;
    procedure MouseClick(var AEvent: TEvent); virtual;
    procedure Paint; virtual;
    procedure Init; virtual;
    function GetAltHotKey: word; virtual;
    function GetHotKey: word; virtual;
    function AddMenu(AMenu: PMenu): PMenu; virtual;
    function NewMenu(AId: string): PMenu; virtual;
    function IsMainMenuItem: boolean; virtual;
  end;

  TMainMenuItem = object(TMenuItem)
  private
  public
    function IsMainMenuItem: boolean; virtual;
  end;

  TMenu = object(TPopUp)
  private
  public
    ActiveItem: PMenuItem;
    function NewMenuItem(AId: string; AActionId: integer): PMenuItem;
    function AddMenuItem(AItem: PMenuItem): PMenuItem; virtual;
    function NewSeparator: PMenuItem; virtual;
    procedure KeyPress(var AEvent: TEvent); virtual;
    procedure MouseEnter(var AEvent: TEvent); virtual;
    procedure MouseLeave(var AEvent: TEvent); virtual;
    procedure Init; virtual;
    procedure Show; virtual;
    procedure Hide; virtual;
    procedure SetupControls; virtual;
    function ParentItem: PMenuItem; virtual;
  end;

  TMenuBar = object(TPanel)
  private
  public
    procedure Init; virtual;
    procedure Paint; virtual;
    procedure SetupControls; virtual;
    procedure KeyPress(var AEvent: TEvent); virtual;
    procedure ActivateMenuItem(AMenuItem: PMenuItem); virtual;
    function GetActiveMenuItem: PMenuItem; virtual;
    function GetNextActiveMenuItem(AOldMenuItem: PMenuItem; AForward: boolean): PMenuItem; virtual;
    function AddMenuItem(AMenuItem: PMenuItem): PMenuItem; virtual;
    function NewMenu(AId, AText: string): PMenu; virtual;
  end;

  TDesktop = object(TPanel)
  private
  public
    FontList: PFontList;
    MenuBar: PMenuBar;
    StatusBar: PStatusBar;
    MouseOverControl: PControl;
    ActiveControl: PControl;
    ActiveMenu: PMenu;
    MouseState: TMouseState;
    OldMouseState: TMouseState;
    MouseStack: TStack;
    ActionList: PActionList;
    InterfaceColors: PInterfaceColors;
    destructor Free; virtual;
    function AddMenuBar(AMenuBar: PMenuBar): PMenuBar; virtual;
    function FindNextControl(AControl: PControl): PControl; virtual;
    function FindPreviousControl(AControl: PControl): PControl; virtual;
    procedure Init; virtual;
    procedure Paint; virtual;
    procedure GetClientRect(var ARect: TRect); virtual;
    procedure KeyPress(var AEvent: TEvent); virtual;
    procedure SetInterfaceColors(AColors: PInterfaceColors); virtual;
    procedure SetupControls; virtual;
    procedure DeactivateCurrentMenu; virtual;
    procedure DeactivateMenuItem(AMenuItem: PMenuItem); virtual;
  end;

  TStatusBar = object(TPanel)
  private
  public
    TextPanel: PPanel;
    CurrentAction: PAction;
    procedure Init; virtual;
    destructor Free; virtual;
    procedure Paint; virtual;
    procedure MouseEnter(var AEvent: TEvent); virtual;
    procedure MouseLeave(var AEvent: TEvent); virtual;
    procedure SetupControls; virtual;
    procedure ClearText; virtual;
    procedure ShowActionHelp(AAction: PAction); virtual;
  end;

var
  Desktop: PDesktop;

implementation

uses
  GraphApp,
  Graph8,
  VeriApp;

procedure TDesktop.DeactivateMenuItem(AMenuItem: PMenuItem);
begin
  if AMenuItem = nil then
    exit;
  AMenuItem^.IsMouseOver := false;
  AMenuItem^.IsLeftMouseDown := false;
  AMenuItem^.IsRightMouseDown := false;
  AMenuItem^.Pressed := false;
  AMenuItem^.Active := false;
  AMenuItem^.DrawSelf;
end;

procedure TDesktop.DeactivateCurrentMenu;
var
  parentItem: PMenuItem;
  activeItem: PMenuItem;
begin
  if ActiveMenu = nil then
    exit;
  DeactivateMenuItem(ActiveMenu^.ActiveItem);
  ActiveMenu^.ActiveItem := nil;
  parentItem := ActiveMenu^.ParentItem;
  parentItem^.Pressed := false;
  parentItem^.Active := false;
  parentItem^.IsMouseOver := false;
  parentItem^.IsLeftMouseDown := false;
  parentItem^.DrawSelf;
  ActiveMenu^.Hide;
  ActiveMenu := nil;
  StatusBar^.ClearText;
end;

procedure TDesktop.SetInterfaceColors(AColors: PInterfaceColors);
begin
  FreeAndNil(InterfaceColors);
  InterfaceColors := AColors;
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
  FontList := New(PFontList, Create);
  InterfaceColors := New(PInterfaceColors, Create);
  if FileExists('System.fnt') then begin
    Font := New(PProportionalFont, Create);
    Font^.LoadFromFile('System.fnt');
    if Font^.HasException then begin
      Font^.ClearException;
      FreeAndNil(Font);
      Font := New(PSystemFont, CreateId('System'));
    end;
  end
  else
    Font := New(PSystemFont, CreateId('System'));
  FontList^.Add(Font);
  Desktop := @self;
  DrawBackground := true;
  BorderStyle := bsNone;
  ActionList := New(PActionList, Create);
  ActiveControl := nil;
  ActiveMenu := nil;
  MouseOverControl := nil;
  ForeColor := InterfaceColors^.Desktop;
  BackColor := InterfaceColors^.DesktopBack;
  OldMouseState.Create;
end;

destructor TDesktop.Free;
begin
  MouseStack.Free;
  FreeAndNil(ActionList);
  FreeAndNil(FontList);
  FreeAndNil(InterfaceColors);
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
var
  index: integer;
  par: PControl;
  current: PControl;
begin
  {FindNextControl := nil;
  par := control^.Parent;
  if ((par = nil) or (not par^.GetVisible) or (not par^.GetEnabled)
    or (par^.Controls^.Count = 0)) then
    exit;
  index := par^.Controls^.IndexOf(control);
  Inc(index);
  if (index > par^.Controls^.Count - 1) then
  begin
    if par^.GetModal then
    begin
      index := 0;
      current := par^.Controls^.GetItem(index);
    end
    else
    begin
      par := par^.Parent;
      if (par = nil) or (par^.Controls^.Count = 0) then exit;
      current := par^.Controls^.GetItem(0);
    end;
  end
  else
    current := par^.Controls^.GetItem(index);
  if ((current <> nil) and current^.GetVisible and current^.GetEnabled and current^.CanFocus) then
  begin
    if (ActiveControl <> nil) then
    begin
     HideMouse;
     ActiveControl^.Unfocus;
     current^.Focus;
     ShowMouse;
    end;
  end
  else
  begin
    if (current <> nil) and (not current^.AcceptTab) then
      FindNextControl := FindNextControl(current);
  end;}
end;

function TDesktop.AddMenuBar(AMenuBar: PMenuBar): PMenuBar;
begin
  Controls^.Add(AMenuBar);
end;

function TDesktop.FindPreviousControl(AControl: PControl): PControl;
begin
end;

procedure TDesktop.KeyPress(var AEvent: TEvent);
begin
  if AEvent.Handled then
    exit;
  inherited KeyPress(AEvent);
end;

procedure TMenu.Show;
begin;
  inherited Show;
end;

procedure TMenu.Hide;
begin
  inherited Hide;
end;

procedure TMenu.MouseEnter(var AEvent: TEvent);
begin
  inherited MouseEnter(AEvent);
end;

procedure TMenu.MouseLeave(var AEvent: TEvent);
begin
  inherited MouseLeave(AEvent);
end;

function TMenu.ParentItem: PMenuItem;
begin
  ParentItem := PMenuItem(Parent);
end;

procedure TMenu.SetupControls;
var
  maxWidth: byte;
  index: word;
  item: PMenuItem;
  itemWidth: integer;
  currentY: integer;
  control: PMenuItem;
  totalHeight: integer;
  shortcutDesc: string;
  parentRect: TRect;
begin
  if (ParentItem <> nil) then begin
    if (ParentItem^.IsMainMenuItem) then begin
      X := ParentItem^.X - 1;
      Y := ParentItem^.Height;
    end
    else begin
      ParentItem^.GetScreenBounds(parentRect);
      X := ParentItem^.X + ParentItem^.Width + parentRect.X - 1;
      Y := parentRect.Y - ParentItem^.Y;
    end;
  end;
  maxWidth := 0;
  currentY := Font^.Height div 2;
  totalHeight := 0;
  if Controls^.Count > 0 then begin
    for index := 0 to Controls^.Count - 1 do begin
      control := PMenuItem(Controls^.GetItem(index));
      with control^ do begin
        shortcutDesc := '';
        if GetShortcut >= 0 then
          shortcutDesc := Keyboard.KeyToShortcut(GetShortcut);
        if not GetVisible then
          continue;
        TextAlign := taLeft;
        X := Self.BorderWidth;
        Y := currentY;
        Margin := Font^.TextWidth(' ');
        Width := Margin
          + TrueTextWidth(GetText)
          + Font^.TextWidth(shortcutDesc)
          + Font^.TextWidth(' ') * 4;
        Height := Font^.Height;
        if Width > maxWidth then begin
          maxWidth := Width;
        end;
        Inc(currentY, Height);
        Inc(totalHeight, Height);
      end;
    end;
    for index := 0 to Controls^.Count - 1 do begin
      control := PMenuItem(Controls^.GetItem(index));
      control^.Width := maxWidth;
    end;
  end;
  Width := maxWidth + 2;
  Height := totalHeight + Font^.Height;
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
  ForeColor := Desktop^.InterfaceColors^.Menu;
  BackColor := Desktop^.InterfaceColors^.MenuBack;
  BorderStyle := bsSingle;
  ActiveItem := nil;
end;

function TMenu.NewMenuItem(AId: string; AActionId: integer): PMenuItem;
var
  item: PMenuItem;
begin
  item := New(PMenuItem, CreateParent(AId, @self));
  item^.ActionId := AActionId;
  item^.Action := Desktop^.ActionList^.GetActionById(AActionId);
  item^.ParentMenu := @self;
  NewMenuItem := item;
end;

procedure TMenu.KeyPress(var AEvent: TEvent);
begin
  inherited KeyPress(AEvent);
end;

constructor TMenuItem.CreateSeparator;
begin
  Init;
  Enabled := false;
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
  MenuBar := nil;
  Enabled := true;
  Shortcut := 0;
  ShowShortcut := true;
  OnMouseClick := nil;
  ParentMenu := nil;
  Menu := nil;
  ForeColor := Desktop^.InterfaceColors^.Menu;
  BackColor := Desktop^.InterfaceColors^.MenuBack;
  BorderStyle := bsNone;
{  Grouped := true;
  Toggle := true;}
  VertAlign := vaCenter;
  TextAlign := taLeft;
end;

procedure TMenuItem.KeyPress(var AEvent: TEvent);
var
  state: TMouseState;
  hotKey : word;
  mouseState: TMouseState;
begin
  if AEvent.Handled then
    exit;

  if (AEvent.Key = GetAltHotKey) and (TypeOf(Parent^) = TypeOf(TMenuBar)) then begin
    Desktop^.DeactivateCurrentMenu;
    Desktop^.ActiveMenu := Menu;
    Pressed := true;
    Active := true;
    Desktop^.ActiveMenu^.Show;
    DrawSelf;
    AEvent.Handled := true;
    exit;
  end;

  inherited KeyPress(AEvent);
end;

procedure TMenuItem.MouseEnter(var AEvent: TEvent);
begin
  if not (GetVisible and GetEnabled) then
    exit;

  if typeof(self) = typeof(TMainMenuItem) then begin
    if (Desktop^.ActiveMenu <> nil) and (Desktop^.ActiveMenu <> Menu) then begin
      Desktop^.DeactivateCurrentMenu;
      Desktop^.ActiveMenu := Menu;
      Menu^.ActiveItem := @self;
      Pressed := true;
      Active := true;
      Menu^.Show;
    end;
  end;
  inherited MouseEnter(AEvent);
end;

procedure TMenuItem.MouseLeave(var AEvent: TEvent);
begin
  inherited MouseLeave(AEvent);
end;

procedure TMenuItem.MouseDown(var AEvent: TEvent);
var
  parentItem: PMenuItem;
begin
  if not GetEnabled then
    exit;

  if AEvent.Handled then
    exit;

  if typeof(self) = typeof(TMainMenuItem) then begin
    Desktop^.DeactivateCurrentMenu;
    Desktop^.ActiveMenu := Menu;
    Pressed := true;
    Active := true;
    Desktop^.ActiveMenu^.Show;
    DrawSelf;
    AEvent.Handled := true;
  end;
end;

procedure TMenuItem.MouseClick(var AEvent: TEvent);
var
  act: PAction;
  key: word;
  parentItem: PMenuItem;
begin
  if not GetEnabled then
    exit;

  if (Action <> nil) and (Action^.Enabled) and (Action^.OnExecute <> nil) then begin
    Desktop^.DeactivateMenuItem(@self);
    Desktop^.DeactivateCurrentMenu;
    AEvent.Handled := true;
    TActionEventProc(Action^.OnExecute)(@self);
  end;
  if AEvent.Handled then
    exit;
  if OnMouseClick <> nil then
    TEventProc(OnMouseClick)(@self, AEvent);
end;

function TMenuItem.GetAltHotKey;
var
  caption: string;
  index: integer;
  ch: char;
begin
  caption := StrPas(Text);
  for index := 1 to Length(caption) do begin
    if (caption[index] = '&') and (length(caption) >= index + 1) then begin
      GetAltHotKey := Keyboard.CharToAltChar(caption[index + 1]);
      exit;
    end;
  end;
  GetAltHotKey := 0;
end;

function TMenuItem.GetHotKey;
var
  caption: string;
  index: integer;
  ch: char;
begin
  if (Action <> nil) then
    caption := StrPas(Action^.Text)
  else
    caption := StrPas(Text);
  for index := 1 to Length(caption) do begin
    if (caption[index] = '&') and (length(caption) >= index + 1) then begin
      GetHotKey := Ord(UpCase(caption[index + 1]));
      exit;
    end;
  end;
  GetHotKey := 0;
end;

procedure TMenuItem.Paint;
var
  rect: TRect;
  desc: string;
begin
  if not GetVisible then
    exit;
  if Separator then begin
    GetScreenBounds(rect);
    Graph^.SetForeColor(BorderColor);
    Graph^.HLine(rect.X, Rect.Y + (rect.Height div 2), Parent^.Width - 1);
  end
  else
    inherited Paint;
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

function TMainMenuItem.IsMainMenuItem;
begin
  IsMainMenuItem := true;
end;

procedure TMenuBar.Paint;
var
  rect: TRect;
begin
  TPanel.Paint;
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
  activeMenu := Desktop^.ActiveMenu;
  if (activeMenu = nil) or (activeMenu^.Controls^.Count = 0) then begin
    GetActiveMenuItem := nil;
    exit;
  end;
  for index := 0 to activeMenu^.Controls^.Count - 1 do begin
    menuItem := PMenuItem(activeMenu^.Controls^.GetItem(index));
    if (menuItem^.Active) then begin
      GetActiveMenuItem := menuItem;
      exit;
    end;
  end;
  GetActiveMenuItem := nil;
end;

function TMenuBar.GetNextActiveMenuItem(AOldMenuItem: PMenuItem; AForward: boolean): PMenuItem;
var
  index : integer;
  activeItem: PList;
  menuItem: PMenuItem;
  totalItems: integer;
begin
  if Desktop^.ActiveMenu = nil then begin
    GetNextActiveMenuItem := nil;
    exit;
  end;
  menuItem := GetActiveMenuItem;
  if menuItem = nil then
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
    if menuItem = nil then
      continue;
    if (not menuItem^.Separator) and (menuItem^.GetEnabled) then begin
      break;
    end;
  until (totalItems > Desktop^.ActiveMenu^.Controls^.Count);

  GetNextActiveMenuItem := menuItem;
  if AOldMenuItem <> nil then begin
    AOldMenuItem^.Active := false;
    AOldMenuItem^.Pressed := false;
    AOldMenuItem^.IsLeftMouseDown := false;
    AOldMenuItem^.DrawSelf;
  end;
end;

procedure TMenuBar.ActivateMenuItem(AMenuItem: PMenuItem);
begin
  Desktop^.DeactivateCurrentMenu;
  Desktop^.ActiveMenu := AMenuItem^.Menu;
  Desktop^.ActiveMenu^.ActiveItem := nil;
  AMenuItem^.Pressed := true;
  AMenuItem^.Active := true;
  Desktop^.ActiveMenu^.Show;
  AMenuItem^.DrawSelf;
end;

procedure TMenuBar.KeyPress(var AEvent: TEvent);
var
  menuItem: PMenuItem;
  index: integer;
begin
  inherited KeyPress(AEvent);
  if AEvent.Handled then
    exit;

  if (Desktop^.ActiveMenu <> nil) and (AEvent.Key = kyEsc) then begin
    Desktop^.DeactivateCurrentMenu;
    AEvent.Handled := true;
    exit;
  end;

  if Desktop^.ActiveMenu = nil then
    exit;

  case AEvent.Key of
    kyLeft: begin
      menuItem := Desktop^.ActiveMenu^.ParentItem;
      index := Controls^.IndexOf(menuItem);
      Dec(index);
      if (index < 0) then
        index := Controls^.Count - 1;
      menuItem := PMenuItem(Controls^.GetItem(index));
      ActivateMenuItem(menuItem);
      AEvent.Handled := true;
      exit;
    end;

    kyRight: begin
      menuItem := Desktop^.ActiveMenu^.ParentItem;
      index := Controls^.IndexOf(menuItem);
      Inc(index);
      if (index > Controls^.Count - 1) then
        index := 0;
      menuItem := PMenuItem(Controls^.GetItem(index));
      ActivateMenuItem(menuItem);
      AEvent.Handled := true;
      exit;
    end;

    kyUp, kyDown: begin
      menuItem := GetActiveMenuItem;
      menuItem := GetNextActiveMenuItem(menuItem, AEvent.Key = kyDown);
      if menuItem <> nil then begin
        Desktop^.StatusBar^.ShowActionHelp(menuItem^.Action);
        Desktop^.ActiveMenu^.ActiveItem := menuItem;
        menuItem^.Active := true;
        menuItem^.Pressed := true;
        menuItem^.IsLeftMouseDown := true;
        menuItem^.DrawSelf;
        AEvent.Handled := true;
        exit;
      end;
    end;

    kyEnter: begin
      menuItem := GetActiveMenuItem;
      if (menuItem = nil) then exit;
      Desktop^.DeactivateCurrentMenu;
      AEvent.Handled := true;
      action := menuItem^.Action;
      if (action = nil) or (action^.OnExecute = nil) then
        exit;
      TActionEventProc(action^.OnExecute)(@self);
      exit;
    end;
  end;

  if Desktop^.ActiveMenu^.Controls^.Count = 0 then
    exit;
  for index := 0 to Desktop^.ActiveMenu^.Controls^.Count - 1 do begin
    menuItem := PMenuItem(Desktop^.ActiveMenu^.Controls^.GetItem(index));
    with menuItem^ do begin
      AEvent.Key := Keyboard.UpCase(AEvent.Key);
      if (Action = nil) or (not Action^.Enabled) or (Action^.OnExecute = nil) then
        continue;
      if AEvent.Key <> GetHotKey then
        continue;
      Desktop^.DeactivateCurrentMenu;
      AEvent.Handled := true;
      TActionEventProc(action^.OnExecute)(@self);
      AEvent.Handled := true;
      exit;
    end;
  end;
end;

function TMenuBar.AddMenuItem(AMenuItem: PMenuItem): PMenuItem;
begin
  Controls^.Add(AMenuItem);
  AddMenuItem := AMenuItem;
end;

function TMenuBar.NewMenu(AId, AText: string): PMenu;
var
  item: PMenuItem;
  menu: PMenu;
begin
  item := New(PMainMenuItem, CreateParent(AId + 'Item', @self));
  item^.Text := NewLargeString(AText);
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
  ForeColor := Desktop^.InterfaceColors^.Menu;
  BackColor := Desktop^.InterfaceColors^.MenuBack;
  BorderStyle := bsNone;
end;

procedure TStatusBar.Init;
begin
  inherited Init;
  Position := spAbsolute;
  ForeColor := Desktop^.InterfaceColors^.Menu;
  BackColor := Desktop^.InterfaceColors^.MenuBack;
  BorderStyle := bsNone;
  CurrentAction := nil;
end;

destructor TStatusBar.Free;
begin
  inherited Free;
end;

procedure TStatusBar.MouseEnter(var AEvent: TEvent);
begin
end;

procedure TStatusBar.MouseLeave(var AEvent: TEvent);
begin
end;

procedure TStatusBar.SetupControls;
var
  rect: TRect;
begin
  Desktop^.GetBounds(rect);
  SetBounds(0, rect.Height - Font^.Height - 4, rect.Width, Font^.Height + 4);
end;

procedure TStatusBar.ShowActionHelp(AAction: PAction);
begin
  if AAction = nil then
    exit;
  CurrentAction := AAction;
  DrawSelf;
end;

procedure TStatusBar.ClearText;
begin
  CurrentAction := nil;
  DrawSelf;
end;

procedure TStatusBar.Paint;
var
  rect: TRect;
begin
  inherited Paint;
  if not GetVisible then
    exit;
  GetScreenBounds(rect);
  if (CurrentAction <> nil) and (CurrentAction^.HelpText <> nil) then begin
    Graph^.SetForeColor(ForeColor);
    Graph^.DrawTextLarge(rect.X + 6, rect.Y + 2, CurrentAction^.HelpText);
  end;
  Graph^.SetForeColor(BorderColor);
  Graph^.HLine(rect.X, rect.Y, rect.Width);
end;

end.