{$IFDEF debug}
  {$A-,B-,D+,E+,F+,G-,I+,L+,N+,M 16384 0 655360,O-,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,E+,F+,G-,I+,L-,N+,M 16384 0 655360,O-,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}
unit Actions;

interface

uses
  Objects,
  MouseDrv,
  StrUtils,
  Apps,
  Collects;

type
  PAction = ^TAction;
  PActionListUpdateEventProc = ^TActionListUpdateEventProc;
  PActionList = ^TActionList;
  PActionEventProc = ^TActionEventProc;

  TActionListUpdateEventProc = procedure(ASender: PActionList);
  TActionEventProc = procedure(ASender: PObject);

  TAction = object(TIdentifiable)
  private
  public
    ActionId: integer;
    Text: PChar;
    HelpText: PChar;
    ShortcutDisplayName: PChar;
    Shortcut: word;
    OnExecute: PActionEventProc;
    ParentList: PActionList;
    Enabled: boolean;
    constructor Create(AActionId: integer; AText: string; AShortcut: word; AOnExecute: PActionEventProc);
    constructor CreateEmpty;
    procedure SetHelpText(AHelpText: string); virtual;
    procedure SetText(AText: string); virtual;
    destructor Free; virtual;
    procedure Init; virtual;
  end;

  TActionList = object(TObjectList)
  public
    OnUpdate: PActionListUpdateEventProc;
    function ToString: string; virtual;
    function GetItem(AIndex: integer): PAction;
    function IndexOf(AItem: PAction): integer;
    function NewAction(AActionId: integer; AText: string; AShortcut: word; AOnExecute: PActionEventProc): PAction;
    function Add(AItem: PAction): integer;
    function GetActionById(AId: integer): PAction;
    procedure Init; virtual;
    procedure Insert(AIndex: integer; AItem: PAction);
    destructor Free; virtual;
  end;

implementation

constructor TAction.Create(AActionId: integer; AText: string; AShortcut: word; AOnExecute: PActionEventProc);
begin
  inherited Create;
  Text := NewLargeString(AText);
  Shortcut := AShortcut;
  OnExecute := AOnExecute;
  ActionId := AActionId;
end;

constructor TAction.CreateEmpty;
begin
  inherited Create;
end;

procedure TAction.Init;
begin
  inherited Init;
  Text := nil;
  HelpText := nil;
  ShortcutDisplayName := nil;
  Shortcut := 0;
  OnExecute := nil;
  ParentList := nil;
  ActionId := -1;
  Enabled := true;
end;

destructor TAction.Free;
begin
  DisposeLargeString(Text);
  DisposeLargeString(ShortcutDisplayName);
  DisposeLargeString(HelpText);
  inherited Free;
end;

procedure TAction.SetHelpText(AHelpText: string);
begin
  DisposeLargeString(HelpText);
  HelpText := NewLargeString(AHelpText);
end;

procedure TAction.SetText(AText: string);
begin
  DisposeLargeString(Text);
  Text := NewLargeString(AText);
end;

function TActionList.NewAction(AActionId: integer; AText: string;
  AShortcut: word; AOnExecute: PActionEventProc): PAction;
var
  action: PAction;
begin
  action := New(PAction, Create(AActionId, AText, AShortcut, AOnExecute));
  action^.ParentList := @Self;
  action^.ActionId := AActionId;
  Add(action);
  NewAction := action;
end;

function TActionList.ToString: string;
begin
  ToString := 'TActionList';
end;

function TActionList.GetItem(AIndex: integer): PAction;
begin
  GetItem := PAction(inherited GetItem(AIndex));
end;

function TActionList.IndexOf(AItem: PAction): integer;
begin
  IndexOf := inherited IndexOf(AItem);
end;

function TActionList.Add(AItem: PAction): integer;
begin
  inherited Add(AItem);
  AItem^.ParentList := @self;
end;

function TActionList.GetActionById(AId: integer): PAction;
var
  index: integer;
  action: PAction;
begin
  GetActionById := nil;
  for index := 0 to Count - 1 do begin
    action := GetItem(index);
    if (Action^.ActionId = AId) then begin
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

procedure TActionList.Insert(AIndex: integer; AItem: PAction);
begin
  inherited Insert(AIndex, AItem);
end;

destructor TActionList.Free;
begin
  inherited Free;
end;

end.