unit Actions;

interface

uses
  Objects,
  MouseDrv,
  StrUtils,
  Collects;

type
  PAction = ^TAction;
  PActionList = ^TActionList;
  PActionEvent = ^TActionEvent;
  PActionListUpdateEvent = ^TActionListUpdateEvent;

  TActionEvent = procedure(sender: PObject; var key: word; var mouseState: TMouseState);
  TActionListUpdateEvent = procedure(sender: PActionList);

  TAction = object(TObject)
  private
  public
    ActionId: integer;
    Text: PChar;
    ShortcutDisplayName: PChar;
    Shortcut: word;
    OnExecute: PActionEvent;
    ParentList: PActionList;
    constructor Create(newActionId: integer; newText: string; newShortcut: word; newOnExecute: PActionEvent);
    constructor CreateEmpty;
    destructor Done; virtual;
    procedure Init; virtual;
  end;

  TActionList = object(TObjectList)
  public
    OnUpdate: PActionListUpdateEvent;
    function ToString: string; virtual;
    function GetItem(index: integer): PAction;
    function IndexOf(item: PAction): integer;
    function NewAction(newActionId: integer; newText: string; newShortcut: word; newOnExecute: PActionEvent): PAction;
    function Add(item: PAction): integer;
    function GetActionById(idToFind: integer): PAction;
    procedure Init; virtual;
    procedure Insert(index: integer; item: PAction);
    destructor Done; virtual;
  end;

implementation

constructor TAction.Create(newActionId: integer; newText: string; newShortcut: word; newOnExecute: PActionEvent);
begin
  Init;
  Text := NewLargeString(newText);
  Shortcut := newShortcut;
  OnExecute := newOnExecute;
  ParentList := parentList;
  ActionId := newActionId;
end;

constructor TAction.CreateEmpty;
begin
  Init;
end;

procedure TAction.Init;
begin
  inherited Init;
  Id := nil;
  Text := nil;
  ShortcutDisplayName := nil;
  Shortcut := 0;
  OnExecute := nil;
  ParentList := nil;
  ActionId := -1;
end;

destructor TAction.Done;
begin
  DisposeLargeString(Text);
  DisposeLargeString(ShortcutDisplayName);
  inherited Done;
end;

function TActionList.NewAction(newActionId: integer; newText: string; newShortcut: word; newOnExecute: PActionEvent): PAction;
var
  action: PAction;
begin
  action := New(PAction, Create(newActionId, newText, newShortcut, newOnExecute));
  action^.ParentList := @Self;
  action^.ActionId := newActionId;
  Add(action);
  NewAction := action;
end;

function TActionList.ToString: string;
begin
  ToString := 'TActionList';
end;

function TActionList.GetItem(index: integer): PAction;
begin
  GetItem := PAction(inherited GetItem(Index));
end;

function TActionList.IndexOf(item: PAction): integer;
begin
  IndexOf := inherited IndexOf(item);
end;

function TActionList.Add(item: PAction): integer;
begin
  inherited Add(item);
  item^.ParentList := @self;
end;

function TActionList.GetActionById(idToFind: integer): PAction;
var
  index: integer;
  action: PAction;
begin
  GetActionById := nil;
  for index := 0 to Count - 1 do begin
    action := GetItem(index);
    if (Action^.ActionId = idToFind) then begin
      GetActionById := action;
      exit;
    end;
  end;
end;

procedure TActionList.Init;
begin
  inherited Init;
  OnUpdate := nil;
end;

procedure TActionList.Insert(index: integer; item: PAction);
begin
  inherited Insert(index, item);
end;

destructor TActionList.Done;
begin
  inherited Done;
end;

end.