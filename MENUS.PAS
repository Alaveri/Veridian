{$I COMPILER.INC}
unit Menus;

interface

uses
  AplObj,
  AplTypes,
  KeyDrv,
  Lists,
  Drawing,
  Actions,
  Controls;

type
  PMenuItem = ^TMenuItem;
  PMenu = ^TMenu;
  PMenuItemList = ^TMenuItemList;
  PMenuItemContainer = ^TMenuItemContainer;
  PMenubar = ^TMenuBar;
  PMenuItemContainerStack = ^TMenuItemContainerStack;

  TMenuLocation = (mlBelow, mlSide);

  TMenuItemList = object(TControlList)
  private
  public
    constructor Create(AOwner: PMenuItemContainer);
    function GetItemById(const AId: string): PMenuItem;
    function GetItem(AIndex: integer): PMenuItem;
    function Add(AItem: PMenuItem): integer; virtual;
    procedure SetItem(AIndex: integer; AItem: PMenuItem); virtual;
    procedure Insert(AIndex: integer; AItem: PMenuItem); virtual;
    procedure Init; virtual;
  end;

  TMenuItem = object(TActionControl)
  private
    FIsMainMenuItem: boolean;
  public
    IsSeparator: boolean;
    ParentContainer: PMenuItemContainer;
    Menu: PMenu;
    SelectedColor: byte;
    SelectedBackColor: byte;
    SelectedShortcutColor: byte;
    constructor Create(const AId: string; AActionId: integer; AParent: PMenuItemContainer);
    constructor CreateSeparator(AParent: PMenu);
    function NewMenu(const AId: string): PMenu;
    function Selected: boolean;
    function IsMainMenuItem: boolean;
    function CloseMenu: boolean;
    procedure Init; virtual;
    procedure Paint; virtual;
    procedure Layout; virtual;
    procedure Deselect;
    procedure Select;
    procedure OpenMenu;
    procedure KeyPress(var AEvent: TKeyEvent); virtual;
    procedure MouseEnter(var AEvent: TMouseEvent); virtual;
    procedure MouseLeave(var AEvent: TMouseEvent); virtual;
    procedure MouseDown(var AEvent: TMouseEvent); virtual;
    procedure MouseUp(var AEvent: TMouseEvent); virtual;
    procedure MouseClick(var AEvent: TMouseEvent); virtual;
    destructor Free; virtual;
  end;

  TMenuItemContainer = object(TPopUp)
  private
  public
    MenuItems: PMenuItemList;
    SelectedItem: PMenuItem;
    ParentMenuItem: PMenuItem;
    { true if parent item's container is open }
    destructor Free; virtual;
    procedure Init; virtual;
    procedure KeyPress(var AEvent: TKeyEvent); virtual;
    procedure Show; virtual;
    function NewMenuItem(const AId: string; AActionId: integer): PMenuItem; virtual;
    function NewSubMenuItem(const AId, ACaption: string): PMenuItem; virtual;
    function GetNextActiveMenuItem(AForward: boolean): PMenuItem;
  end;

  TMenu = object(TMenuItemContainer)
  private
  public
    MenuLocation: TMenuLocation;
    procedure Init; virtual;
    procedure Paint; virtual;
    procedure Layout; virtual;
    procedure KeyPress(var AEvent: TKeyEvent); virtual;
    procedure GetMenuDims(var ADims: TSize);
    function NewSeparator: PMenuItem;
    destructor Free; virtual;
  end;

  TMenuBar = object(TMenuItemContainer)
  private
  public
    constructor Create;
    procedure Init; virtual;
    procedure Layout; virtual;
    procedure Paint; virtual;
    procedure KeyPress(var AEvent: TKeyEvent); virtual;
    function NewMenu(const AId, ACaption: string): PMenu;
  end;

  TMenuItemContainerStack = object(TObjectStack)
  private
  public
    procedure Init; virtual;
    function Push(AObject: PMenuItemContainer): integer;
    function Pop: PMenuItemContainer;
    function Peek: PMenuItemContainer;
    function Add(AItem: PMenuItemContainer): integer;
    function GetItem(AIndex: integer): PMenuItemContainer;
    function IndexOf(AItem: PMenuItemContainer): integer;
    procedure SetItem(AIndex: integer; AItem: PMenuItemContainer);
    procedure Insert(AIndex: integer; AItem: PMenuItemContainer);
    procedure RemoveItem(AItem: PMenuItemContainer);
  end;

  TMenuManager = object(TObject)
  private
    FOpenMenus: PMenuItemContainerStack;
  public
    function MenuOpen(AMenu: PMenuItemContainer): boolean;
    function PopMenu: PMenuItemContainer;
    function PopAndCloseMenu: PMenuItemContainer;
    function PeekMenu: PMenuItemContainer;
    function OpenMenus: PMenuItemContainerStack;
    procedure Init; virtual;
    procedure OpenMenu(AMenu: PMenuItemContainer);
    procedure CloseMenu(AMenu: PMenuItemContainer);
    procedure PushMenu(AMenu: PMenuItemContainer);
    procedure CloseAllMenus;
    destructor Free; virtual;
  end;

var
  MenuManager: TMenuManager;

implementation

uses
  AplMath,
  VeriCons,
  Graphics,
  AplUtils,
  VeriType,
  Veridian;

procedure TMenu.Init;
begin
  inherited Init;
  Visible := false;
  MenuLocation := mlBelow;
  BorderStyle := bsSingle;
  ForeColor := VeridianApp^.Colors.Menu;
  BackColor := VeridianApp^.Colors.MenuBack;
  BorderColor := VeridianApp^.Colors.MenuBorder;
  Position := spAbsolute;
  Clip := false;
end;

procedure TMenu.Paint;
begin
  inherited Paint;
end;

procedure TMenu.GetMenuDims(var ADims: TSize);
var
  index: integer;
  item: PMenuItem;
  currentWidth, menuWidth: integer;
  full: string;
  itemHeight: integer;
begin
  ADims.CreateDims(0, 0);
  for index := 0 to MenuItems^.Count - 1 do begin
    item := MenuItems^.GetItem(index);
    if not item^.Visible then
      continue;
    itemHeight := item^.Font^.Height + item^.SpacingHeight;
    if item^.IsSeparator then
      itemHeight := itemHeight div 2;
    Inc(ADims.Height, itemHeight);
    full := Trim(item^.GetCaption + item^.GetShortcutDesc);
    currentWidth := item^.TrueTextWidth(full) + item^.ShortcutSpacing;
    menuWidth := currentWidth + item^.SpacingWidth;
    if menuWidth > ADims.Width then
      ADims.Width := menuWidth;
  end;
  ADims.Grow(2 * borderWidth, 2 * borderWidth);
end;

procedure TMenu.Layout;
var
  itemRect, menuRect, parentItemRect: TRect;
  menuDims: TSize;
  item: PMenuItem;
  itemHeight, index: integer;
  xPos, yPos: integer;
begin
  inherited Layout;
  GetMenuDims(menuDims);
  menuRect.CreateDims(0, 0, menuDims.Width, menuDims.Height);
  if Assigned(ParentMenuItem) then begin
    ParentMenuItem^.GetScreenBounds(parentItemRect);
    if MenuLocation = mlBelow then begin
      menuRect.X := parentItemRect.X;
      menuRect.Y := parentItemRect.Bottom + 1;
    end else begin
      menuRect.X := parentItemRect.X + parentItemRect.Width;
      menuRect.Y := parentItemRect.Y - BorderWidth;
      if menuRect.Right > Graph^.Mode^.Bounds.Right then
        menuRect.X := parentItemRect.X - menuDims.Width;
    end;
  end;
  itemRect.Create;
  yPos := 0;
  xPos := 0;
  for index := 0 to MenuItems^.Count - 1 do begin
    item := MenuItems^.GetItem(index);
    if not item^.Visible then
      continue;
    itemHeight := item^.Font^.Height + item^.SpacingHeight;
    if item^.IsSeparator then
      itemHeight := itemHeight div 2;
    itemRect.SetDims(xPos, yPos, menuDims.Width - 2 * OuterWidth, itemHeight);
    item^.SetBoundsRect(itemRect);
    Inc(yPos, itemHeight);
  end;
  SetBoundsRect(menuRect);
end;

procedure TMenu.KeyPress(var AEvent: TKeyEvent);
var
  menuItem: PMenuItem;
  index: integer;
  key, eventKey: word;
begin
  if not IsVisible then
    exit;
  case AEvent.Key of
    kyDown, kyUp: begin
      if MenuItems^.Count = 0 then
        exit;
      menuItem := GetNextActiveMenuItem(AEvent.Key = kyDown);
      if Assigned(menuItem) and menuItem^.IsEnabled
        and (menuItem <> SelectedItem) then
        menuItem^.Select;
      AEvent.Handled := true;
      exit;
    end;
    kyEnter: begin
      if not (Assigned(SelectedItem) and SelectedItem^.IsEnabled) then
        exit;
      if Assigned(SelectedItem^.Menu) then begin
        SelectedItem^.OpenMenu;
      end
      else if Assigned(SelectedItem^.Action) then begin
        menuItem := SelectedItem;
        MenuManager.CloseAllMenus;
        SelectedItem := nil;
        menuItem^.Action^.Execute(menuItem);
      end;
      AEvent.Handled := true;
    end;
  end;
  for index := 0 to MenuItems^.Count - 1 do begin
    menuItem := MenuItems^.GetItem(index);
    if not MenuItem^.IsVisibleAndEnabled then
      continue;
    key := menuItem^.GetHotKey;
    eventKey := Keyboard.UpCase(AEvent.Key);
    if eventKey = key then begin
      if Assigned(menuItem^.Menu) then begin
        menuItem^.OpenMenu;
      end
      else if Assigned(menuItem^.Action) then begin
        MenuManager.CloseAllMenus;
        SelectedItem := nil;
        menuItem^.Action^.Execute(menuItem);
      end;
      AEvent.Handled := true;
    end;
  end;
  if not AEvent.Handled then
    inherited KeyPress(AEvent);
end;

destructor TMenu.Free;
begin
  inherited Free;
end;

function TMenu.NewSeparator: PMenuItem;
var
  result: PMenuItem;
begin
  result := New(PMenuItem, CreateSeparator(@Self));
  result^.SetId('Separator' + IntToStr(MenuItems^.Count));
  MenuItems^.Add(result);
  NewSeparator := result;
end;

constructor TMenuItem.CreateSeparator(AParent: PMenu);
begin
  inherited CreateParent('', nil, AParent);
  ParentContainer := AParent;
  IsSeparator := true;
end;

function TMenuItem.NewMenu(const AId: string): PMenu;
begin
  Menu := New(PMenu, CreateParent(AId, @self));
  Menu^.ParentMenuItem := @self;
  Menu^.MenuLocation := mlSide;
  NewMenu := Menu;
end;

procedure TMenuItem.Init;
begin
  inherited Init;
  IsSeparator := false;
  Clip := false;
  Action := nil;
  ParentContainer := nil;
  Menu := nil;
  HorzAlign := haLeft;
  VertAlign := vaCenter;
  ForeColor := VeridianApp^.Colors.Menu;
  BackColor := VeridianApp^.Colors.MenuBack;
  BorderColor := VeridianApp^.Colors.MenuBorder;
  SelectedColor := VeridianApp^.Colors.MenuSelected;
  SelectedBackColor := VeridianApp^.Colors.MenuSelectedBack;
  SelectedShortcutColor := VeridianApp^.Colors.SelectedShortcut;
  BorderStyle := bsNone;
  FIsMainMenuItem := false;
  AutoSize := false;
  Padding.CreateAll(3, 2, 3, 1);
  Position := spClient;
end;

procedure TMenuItem.OpenMenu;
begin
  if not Assigned(Menu) then
    exit;
  MenuManager.OpenMenu(Menu);
end;

procedure TMenuItem.Deselect;
begin
  CloseMenu;
  if Assigned(ParentContainer) then begin
    ParentContainer^.SelectedItem := nil;
    DrawSelf;
  end;
end;
procedure TMenuItem.Select;
begin
  if not Assigned(ParentContainer) then
    exit;
  if Assigned(ParentContainer^.SelectedItem) then
    ParentContainer^.SelectedItem^.Deselect;
  ParentContainer^.SelectedItem := @self;
  DrawSelf;
end;

function TMenuItem.Selected: boolean;
begin
  Selected := false;
  if not Assigned(ParentContainer) then
    exit;
  Selected := ParentContainer^.SelectedItem = @self;
end;

procedure TMenuItem.Paint;
var
  oldForeColor: byte;
  oldBackColor: byte;
  oldShortcutColor: byte;
  rect, viewPort: TRect;
  bwidth: integer;
  pos: TPoint;
begin
  oldForeColor := ForeColor;
  oldBackColor := BackColor;
  oldShortcutColor := ShortcutColor;
  if Selected then begin
    ForeColor := SelectedColor;
    BackColor := SelectedBackColor;
    ShortcutColor := SelectedShortcutColor;
  end;
  GetScreenBounds(rect);
  if IsSeparator then begin
    Graph^.SetForeColor(BorderColor);
    Graph^.HLine(rect.X, rect.Y + rect.Height div 2, rect.Width);
    exit;
  end;
  inherited Paint;
  if Assigned(Menu) and not IsMainMenuItem then begin
    bwidth  := 0;
    if Assigned(Parent) then
      bwidth := Parent^.BorderWidth;
    GetTextAlign(rect, pos);
    pos.X := rect.Right - TrueTextWidth(#16) - Padding.Right;
    Graph^.DrawText(pos.X, pos.Y, #16);
  end;
  ForeColor := oldForeColor;
  BackColor := oldBackColor;
  ShortcutColor := oldShortcutColor;
end;

procedure TMenuItem.Layout;
begin
  inherited Layout;
end;

function TMenuItem.CloseMenu: boolean;
begin
  if IsMainMenuItem then
    MenuManager.CloseAllMenus
  else
    MenuManager.CloseMenu(Menu)
end;

procedure TMenuItem.KeyPress(var AEvent: TKeyEvent);
var
  hotKey: word;
begin
  inherited KeyPress(AEvent);
  hotKey := GetAltHotkey;
  if (AEvent.Key = hotKey) and IsMainMenuItem then begin
    Desktop^.BeginDrawing;
    MenuManager.CloseAllMenus;
    OpenMenu;
    AEvent.Handled := true;
    Desktop^.EndDrawing;
  end;
end;

procedure TMenuItem.MouseEnter(var AEvent: TMouseEvent);
var
  selectedItem: PMenuItem;
  showMenu: boolean;
begin
  inherited MouseEnter(AEvent);
  if not Assigned(ParentContainer) then
    exit;
  selectedItem := ParentContainer^.SelectedItem;
  showMenu := false;
  if Assigned(selectedItem) and (selectedItem <> @self) then begin
    showMenu := MenuManager.MenuOpen(selectedItem^.Menu);
    selectedItem^.CloseMenu;
    ParentContainer^.SelectedItem := nil;
    selectedItem^.DrawSelf;
  end;
  ParentContainer^.SelectedItem := @self;
  if showMenu then
    MenuManager.OpenMenu(Menu);
  DrawSelf;
end;

procedure TMenuItem.MouseLeave(var AEvent: TMouseEvent);
var
  selectedItem: PMenuItem;
begin
  inherited MouseLeave(AEvent);
  if not Assigned(ParentContainer) then
    exit;
  if MenuManager.MenuOpen(Menu) then
    exit;
  parentContainer^.SelectedItem := nil;
  DrawSelf;
end;

procedure TMenuItem.MouseDown(var AEvent: TMouseEvent);
var
  selectedItem: PMenuItem;
begin
  inherited MouseDown(AEvent);
  if not Assigned(ParentContainer) then
    exit;
  selectedItem := ParentContainer^.SelectedItem;
  if (selectedItem = @self) and MenuManager.MenuOpen(self.Menu) then begin
    CloseMenu;
    exit;
  end;
  MenuManager.OpenMenu(Menu);
  ParentContainer^.SelectedItem := @self;
end;

procedure TMenuItem.MouseUp(var AEvent: TMouseEvent);
begin
  inherited MouseUp(AEvent);
  if Assigned(Action) then begin
    MenuManager.CloseAllMenus;
    Action^.Execute(@self);
  end;
end;

procedure TMenuItem.MouseClick(var AEvent: TMouseEvent);
begin
  inherited MouseClick(AEvent);
end;

function TMenuItem.IsMainMenuItem: boolean;
begin
  IsMainMenuItem := FIsMainMenuItem;
end;

destructor TMenuItem.Free;
begin
  inherited Free;
end;

constructor TMenuItem.Create(const AId: string; AActionId: integer; AParent: PMenuItemContainer);
begin
  inherited CreateParent(AId, Desktop^.ActionList^.GetActionById(AActionId), AParent);
  ParentContainer := AParent;
end;

constructor TMenuBar.Create;
begin
  inherited CreateParent('MenuBar', Desktop);
end;

procedure TMenuBar.Init;
begin
  inherited Init;
  ForeColor := VeridianApp^.Colors.Menu;
  BackColor := VeridianApp^.Colors.MenuBack;
  BorderColor := VeridianApp^.Colors.MenuBorder;
  MenuItems := New(PMenuItemList, Create(@self));
  VeridianApp^.MenuBar := @self;
  StayOnTop := true;
  Padding.Left := 5;
  Position := spClient;
end;

procedure TMenuBar.Layout;
var
  txtWidth, xPos, currentHeight, maxHeight, index: integer;
  item: PMenuItem;
  itemRect: TRect;
  pos: TPoint;
  size: TSize;
  txt: string;
begin
  inherited Layout;
  itemRect.Create;
  xPos := Padding.Left;
  maxHeight := 0;
  currentHeight := 0;
  for index := 0 to MenuItems^.Count - 1 do begin
    item := MenuItems^.GetItem(index);
    currentHeight := item^.Font^.Height + item^.SpacingHeight;
    if currentHeight > maxHeight then
      maxHeight := currentHeight;
  end;
  Inc(maxHeight);
  for index := 0 to MenuItems^.Count - 1 do begin
    item := MenuItems^.GetItem(index);
    txt := item^.GetCaption;
    txtWidth := item^.TrueTextWidth(txt);
    if not item^.IsVisible then
      continue;
    itemRect.SetDims(xPos, 0, txtWidth + item^.SpacingWidth, maxHeight);
    size.CreateDims(txtWidth, maxHeight);
    item^.SetBoundsRect(itemRect);
    Inc(xPos, itemRect.Width);
  end;
  SetBounds(0, 0, Desktop^.Width, maxHeight + 1);
end;

procedure TMenuBar.KeyPress(var AEvent: TKeyEvent);
var
  menuItem: PMenuItem;
  menuOpen: boolean;
begin
  inherited KeyPress(AEvent);
  case AEvent.Key of
    kyLeft, kyRight: begin
      if not (Assigned(SelectedItem) and Assigned(SelectedItem^.Menu) and
        SelectedItem^.Menu^.IsVisible) then
        exit;
      if MenuItems^.Count = 0 then
        exit;
      menuItem := GetNextActiveMenuItem(AEvent.Key = kyRight);
      if not (Assigned(menuItem) and menuItem^.IsEnabled
        and (menuItem <> SelectedItem)) then
        exit;
      Desktop^.BeginDrawing;
      MenuManager.CloseAllMenus;
      menuItem^.Select;
      menuItem^.OpenMenu;
      Desktop^.EndDrawing;
      AEvent.Handled := true;
    end;
  end;
end;

procedure TMenuBar.Paint;
begin
  inherited Paint;
  Graph^.SetForeColor(BorderColor);
  Graph^.HLine(0, Height - 1, Width);
end;

function TMenuBar.NewMenu(const AId, ACaption: string): PMenu;
var
  menu: PMenu;
  item: PMenuItem;
begin
  item := New(PMenuItem, CreateCaption(AId + 'Item', ACaption, @self));
  menu := New(PMenu, CreateParent(AId, item));
  item^.FIsMainMenuItem := true;
  item^.ParentContainer := @self;
  item^.Menu := menu;
  menu^.ParentMenuItem := item;
  item^.ShowShortcut := false;
  MenuItems^.Add(item);
  NewMenu := menu;
end;

procedure TMenuItemContainer.Init;
begin
  inherited Init;
  ForeColor := VeridianApp^.Colors.Menu;
  BackColor := VeridianApp^.Colors.MenuBack;
  MenuItems := New(PMenuItemList, Create(@self));
  SelectedItem := nil;
  Position := spClient;
end;

procedure TMenuItemContainer.Show;
begin
  inherited Show;
  if Assigned(ParentMenuItem) then
    ParentMenuItem^.BringToFront;
  BringToFront;
end;

function TMenuItemContainer.NewMenuItem(const AId: string; AActionId: integer): PMenuItem;
var
  result: PMenuItem;
begin
  result := New(PMenuItem, Create(AId, AActionId, @self));
  result^.ParentContainer := @self;
  MenuItems^.Add(result);
  NewMenuItem := result;
end;

function TMenuItemContainer.NewSubMenuItem(const AId, ACaption: string): PMenuItem;
var
  result: PMenuItem;
begin
  result := New(PMenuItem, CreateCaption(AId, ACaption, @self));
  result^.ParentContainer := @self;
  MenuItems^.Add(result);
  NewSubMenuItem := result;
end;

function TMenuItemContainer.GetNextActiveMenuItem(AForward: boolean): PMenuItem;
var
  index : integer;
  menuItem: PMenuItem;
  totalItems: integer;
begin
  if not Assigned(SelectedItem) then
    index := -1
  else
    index := MenuItems^.IndexOf(SelectedItem);
  totalItems := 0;
  repeat
    if AForward then
      Inc(index)
    else
      Dec(index);
    Inc(totalItems);
    if (index >= MenuItems^.Count) and (AForward) then
      index := 0;
    if index < 0 then
      index := MenuItems^.Count - 1;
    menuItem := MenuItems^.GetItem(index);
    if not Assigned(menuItem) then
      continue;
    if (not menuItem^.IsSeparator) and (menuItem^.IsEnabled) then
      break;
  until (totalItems > MenuItems^.Count);
  GetNextActiveMenuItem := menuItem;
end;

procedure TMenuItemContainer.KeyPress(var AEvent: TKeyEvent);
begin
  inherited KeyPress(AEvent);
  if not IsVisible then
    exit;
end;

destructor TMenuItemContainer.Free;
begin
  FreeAndNil(MenuItems);
  inherited Free;
end;

constructor TMenuItemList.Create(AOwner: PMenuItemContainer);
begin
  inherited Create(AOwner);
end;

procedure TMenuItemList.Init;
begin
  inherited Init;
  DisposeObjects := false;
  Owner := nil;
end;

function TMenuItemList.GetItemById(const AId: string): PMenuItem;
begin
  GetItemById := PMenuItem(inherited GetItemById(AId));
end;

function TMenuItemList.GetItem(AIndex: integer): PMenuItem;
begin
  GetItem := PMenuItem(inherited GetItem(AIndex));
end;

function TMenuItemList.Add(AItem: PMenuItem): integer;
begin
  Add := inherited Add(AItem);
end;

procedure TMenuItemList.SetItem(AIndex: integer; AItem: PMenuItem);
begin
  inherited SetItem(AIndex, AItem);
end;

procedure TMenuItemList.Insert(AIndex: integer; AItem: PMenuItem);
begin
  inherited Insert(AIndex, AItem);
end;

procedure TMenuManager.Init;
begin
  inherited Init;
  FOpenMenus := New(PMenuItemContainerStack, Create);
end;

destructor TMenuManager.Free;
begin
  FreeAndNil(FOpenMenus);
  inherited Free;
end;

procedure TMenuItemContainerStack.Init;
begin
  inherited Init;
end;

function TMenuItemContainerStack.Push(AObject: PMenuItemContainer): integer;
begin
  Push := inherited Push(AObject);
end;

function TMenuItemContainerStack.Pop: PMenuItemContainer;
begin
  Pop := PMenuItemContainer(inherited Pop);
end;

function TMenuItemContainerStack.Peek: PMenuItemContainer;
begin
  Peek := PMenuItemContainer(inherited Peek);
end;

function TMenuItemContainerStack.Add(AItem: PMenuItemContainer): integer;
begin
  Add := inherited Add(AItem);
end;

function TMenuItemContainerStack.GetItem(AIndex: integer): PMenuItemContainer;
begin
  GetItem := PMenuItemContainer(inherited GetItem(AIndex));
end;

function TMenuItemContainerStack.IndexOf(AItem: PMenuItemContainer): integer;
begin
  IndexOf := inherited IndexOf(AItem);
end;

procedure TMenuItemContainerStack.SetItem(AIndex: integer; AItem: PMenuItemContainer);
begin
  inherited SetItem(AIndex, AItem);
end;

procedure TMenuItemContainerStack.Insert(AIndex: integer; AItem: PMenuItemContainer);
begin
  inherited Insert(AIndex, AItem);
end;

procedure TMenuItemContainerStack.RemoveItem(AItem: PMenuItemContainer);
begin
  inherited RemoveItem(AItem);
end;

function TMenuManager.MenuOpen(AMenu: PMenuItemContainer): boolean;
begin
  MenuOpen := FOpenMenus^.IndexOf(AMenu) >= 0;
end;

function TMenuManager.PopMenu: PMenuItemContainer;
begin
  PopMenu := FOpenMenus^.Pop;
end;

function TMenuManager.PopAndCloseMenu: PMenuItemContainer;
var
  menu: PMenuItemContainer;
begin
  PopAndCloseMenu := nil;
  if FOpenMenus^.Count = 0 then
    exit;
  menu := FOpenMenus^.Pop;
  PopAndCloseMenu := menu;
  CloseMenu(menu);
end;

procedure TMenuManager.CloseMenu(AMenu: PMenuItemContainer);
var
  parentMenuItem: PMenuItem;
  parentContainer: PMenuItemContainer;
  selectedItem: PMenuItem;
begin
  if not Assigned(AMenu) then
    exit;
  parentMenuItem := nil;
  parentContainer := nil;
  parentMenuItem := AMenu^.ParentMenuItem;
  if not Assigned(parentMenuItem) then
    exit;
  parentContainer := parentMenuItem^.ParentContainer;
  if not Assigned(parentContainer) then
    exit;
  if AMenu^.IsVisible then begin
    AMenu^.SelectedItem := nil;
    AMenu^.Hide;
    FOpenMenus^.RemoveItem(AMenu);
    if Assigned(parentMenuItem) and Assigned(parentContainer) then begin
      selectedItem := parentContainer^.SelectedItem;
      if parentMenuItem^.IsMainMenuItem or not Assigned(selectedItem^.Menu) then begin
        parentContainer^.SelectedItem := nil;
        parentMenuItem^.DrawSelf;
      end;
    end;
  end;
  if FOpenMenus^.Count = 0 then
    VeridianApp^.PopState;
end;

procedure TMenuManager.CloseAllMenus;
begin
  while FOpenMenus^.Count > 0 do
    PopAndCloseMenu;
end;

procedure TMenuManager.OpenMenu(AMenu: PMenuItemContainer);
var
  parentMenuItem: PMenuItem;
  parentContainer: PMenuItemContainer;
begin
  if FOpenMenus^.Count = 0 then begin
    VeridianApp^.PushState;
    VeridianApp^.CursorOff;
  end;
  if not Assigned(AMenu) then
    exit;
  if not AMenu^.IsVisible then begin
    parentContainer := nil;
    parentMenuItem := AMenu^.ParentMenuItem;
    parentContainer := parentMenuItem^.ParentContainer;
    if Assigned(parentMenuItem) and (parentContainer^.SelectedItem <> parentMenuItem) then begin
      parentContainer^.SelectedItem := parentMenuItem;
      parentMenuItem^.DrawSelf;
    end;
    if Assigned(parentContainer) then begin
      if not (Assigned(parentMenuItem) and Assigned(parentMenuItem^.Menu)) then
        CloseMenu(parentContainer);
    end;
    FOpenMenus^.Push(AMenu);
    AMenu^.Show;
  end;
end;

procedure TMenuManager.PushMenu(AMenu: PMenuItemContainer);
begin
  FOpenMenus^.Push(AMenu);
end;

function TMenuManager.PeekMenu: PMenuItemContainer;
begin
  PeekMenu := FOpenMenus^.Peek;
end;

function TMenuManager.OpenMenus: PMenuItemContainerStack;
begin
  OpenMenus := FOpenMenus;
end;

var
  PreviousExitProc: pointer;

procedure Finalize; far;
begin
  ExitProc := PreviousExitProc;
  MenuManager.Free;
end;

begin
  PreviousExitProc := ExitProc;
  ExitProc := @Finalize;
  MenuManager.Create;
end.