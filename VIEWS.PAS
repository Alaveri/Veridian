unit Views;

interface

uses
  Objects,
  Collects,
  GraphApp,
  Drawing,
  Controls;

type
  PView = ^TView;
  PWindow = ^TWindow;
  PTabset = ^TTabset;
  PTab = ^TTab;
  PTabList = ^TTabList;

  TViewScrollType = (
    scNone,
    scVertical,
    scHorizontal,
    scBoth,
    scAsNeeded
  );

  TScrollbar = object(TPanel)
  private
  public
  end;

  TView = object(TPanel)
  private
  public
    ScrollType: TViewScrollType;
    procedure Init; virtual;
    procedure Maximize; virtual;
    destructor Free; virtual;
  end;

  TTab = object(TPanel)
  private
  public
    procedure Init; virtual;
    destructor Free; virtual;
  end;

  TTabList = Object(TIdentifiableList)
  private
    Parent: PControl;
  public
    function ToString: string; virtual;
    function GetItem(AIndex: integer): PTab;
    function GetItemById(AId: string): PTab;
    function IndexOf(AItem: PTab): integer;
    function Add(AItem: PTab): integer;
    procedure Init; virtual;
    procedure Insert(AIndex: integer; AItem: PTab);
  end;

  TTabButton = object(TButton)
  private
  public
    procedure Init; virtual;
    procedure Paint; virtual;
    destructor Free; virtual;
  end;

  TTabset = object(TPanel)
  private
  public
    Caption: PChar;
    Tabs: PTabList;
    destructor Free; virtual;
    function NewTab(const ACaption: string): PTab; virtual;
    procedure GetClientRect(var ARect: TRect); virtual;
    procedure Init; virtual;
    procedure SetupControls; virtual;
  end;

  TWindow = object(TView)
  private
  public
    procedure Init; virtual;
    destructor Free; virtual;
  end;

implementation

uses
  VeriApp,
  Desk;

procedure TView.Init;
begin
  inherited Init;
  ToolTip := nil;
  CanFocus := true;
  IsMouseOver := false;
  ForeColor := Desktop^.InterfaceColors^.Window;
  BackColor := Desktop^.InterfaceColors^.WindowBack;
  HighlightForeColor := Desktop^.InterfaceColors^.ButtonHighlight;
  BorderStyle := bsNone;
  Grouped := false;
end;

destructor TView.Free;
begin
  inherited Free;
end;

procedure TView.Maximize;
var
  viewRect: TRect;
begin
  viewRect.CreateDims(0, 0, Desktop^.Width, Desktop^.Height);
  if Desktop^.MenuBar^.GetVisible then begin
    Dec(viewRect.Height, Desktop^.Menubar^.Height);
    Inc(viewRect.Y, Desktop^.Menubar^.Height);
  end;
  if Desktop^.StatusBar^.GetVisible then
    Dec(viewRect.Height, Desktop^.Statusbar^.Height);
  SetBoundsRect(viewRect);
  Desktop^.Draw;
end;

procedure TWindow.Init;
begin
  inherited Init;
end;

destructor TWindow.Free;
begin
  inherited Free;
end;

procedure TTabset.Init;
begin
  inherited init;
  Tabs := New(PTabList, Create);
  ToolTip := nil;
  CanFocus := true;
  IsMouseOver := false;
  ForeColor := Desktop^.InterfaceColors^.Window;
  BackColor := Desktop^.InterfaceColors^.WindowBack;
  HighlightForeColor := Desktop^.InterfaceColors^.ButtonHighlight;
  BorderStyle := bsNone;
  Grouped := false;
  Caption := nil;
end;

procedure TTabset.GetClientRect(var ARect: TRect);
begin

end;

procedure TTabset.SetupControls;
begin
end;

function TTabset.NewTab(const ACaption: string): PTab;
var
  tab: PTab;
begin
  tab := New(PTab, CreateParent('', @self));
end;

destructor TTabset.Free;
begin
  Dispose(Tabs, Free);
  inherited Free;
end;

procedure TTab.Init;
begin
  inherited init;
  ToolTip := nil;
  CanFocus := true;
  IsMouseOver := false;
  ForeColor := Desktop^.InterfaceColors^.Window;
  BackColor := Desktop^.InterfaceColors^.WindowBack;
  HighlightForeColor := Desktop^.InterfaceColors^.ButtonHighlight;
  BorderStyle := bsNone;
  Grouped := false;
end;

destructor TTab.Free;
begin
  inherited Free;
end;

procedure TTabList.Init;
begin
  inherited Init;
  Parent := nil;
  DisposeObjects := false;
end;

function TTabList.ToString: string;
begin
  ToString := 'TTabPageList';
end;

function TTabList.GetItem(AIndex: integer): PTab;
begin
  GetItem := pointer(inherited GetItem(AIndex));
end;

function TTabList.IndexOf(AItem: PTab): integer;
begin
  IndexOf := inherited IndexOf(AItem);
end;

function TTabList.Add(AItem: PTab): integer;
begin
  Add := inherited Add(AItem);
  AItem^.Parent := Parent;
end;

procedure TTabList.Insert(AIndex: integer; AItem: PTab);
begin
  inherited Insert(AIndex, AItem);
  AItem^.Parent := Parent;
end;

function TTabList.GetItemById(AId: string): PTab;
begin
  GetItemById := PTab(inherited GetItemById(AId));
end;

procedure TTabButton.Init;
begin
  inherited Init;
  ToolTip := nil;
  CanFocus := true;
  Active := false;
  IsMouseOver := false;
  ForeColor := Desktop^.InterfaceColors^.Tab;
  BackColor := Desktop^.InterfaceColors^.TabBack;
  HighlightForeColor := Desktop^.InterfaceColors^.Tab;
  BorderStyle := bsNone;
  Pressed := false;
  Toggle := false;
  Grouped := false;
  DisabledForeColor := Desktop^.InterfaceColors^.TabDisabled;
  HoverForeColor := Desktop^.InterfaceColors^.TabHover;
  HoverBackColor := Desktop^.InterfaceColors^.TabHoverBack;
  HoverHighlightColor := Desktop^.InterfaceColors^.TabHover;
end;

procedure TTabButton.Paint;
var
  fore, back, highlight: byte;
begin
  fore := ForeColor;
  back := BackColor;
  if not GetEnabled then
    ForeColor := DisabledForeColor
  else if IsMouseOver then begin
    ForeColor := HoverForeColor;
    BackColor := HoverBackColor;
    HighlightForeColor := HoverHighlightColor;
  end;
  inherited Paint;
  ForeColor := fore;
  BackColor := back;
end;

destructor TTabButton.Free;
begin
  inherited Free;
end;

end.