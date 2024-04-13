{$IFDEF debug}
  {$A-,B-,D+,F+,G-,I+,L+,N+,O+,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,F+,G-,I+,L-,N+,O+,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}
unit Actions;

interface

uses
  Objects,
  AplTypes,
  Common,
  Lists,
  StrUtils,

  MouseDrv,
  GraphDrv;

type
  PAction = ^TAction;
  PActionListUpdateEventProc = ^TActionListUpdateEventProc;
  PActionList = ^TActionList;
  PActionExecuteProc = ^TActionExecuteProc;

  TActionListUpdateEventProc = procedure(ASender: PActionList);

  TActionExecuteProc = procedure(AAction: PAction; AActionId: integer);

  TAction = object(TIdentifiable)
  private
  public
    ActionId: integer;
    Text: PChar;
    HelpText: PChar;
    ShortcutDisplayName: PChar;
    Shortcut: word;
    ParentList: PActionList;
    Enabled: boolean;
    OnExecute: PActionExecuteProc;
    ModalResult: TModalResult;
    Owner: PObject;
    constructor Create(AActionId: integer; AText: string; AShortcut: word);
    constructor CreateEmpty;
    procedure SetHelpText(AHelpText: string); virtual;
    procedure SetText(AText: string); virtual;
    destructor Free; virtual;
    procedure Init; virtual;
  end;

  TActionList = object(TIdentifiableList)
  public
    OnUpdate: PActionListUpdateEventProc;
    function IndexOf(AItem: PAction): integer;
    function NewAction(AActionId: integer; AText: string; AShortcut: word): PAction;
    function Add(AItem: PAction): integer;
    function GetItem(AIndex: integer): PAction;
    function GetItemById(AId: string): PAction;
    function GetActionById(AActionId: integer): PAction;
    function GetHelpMaxWidth(AControl: pointer): integer;
    procedure Init; virtual;
    procedure Insert(AIndex: integer; AItem: PAction);
    destructor Free; virtual;
  end;

implementation

uses
  {$IFDEF DOS}
  Strings,
  Dos,
  {$ENDIF}
  Controls;

constructor TAction.Create(AActionId: integer; AText: string; AShortcut: word);
begin
  inherited Create;
  Text := TString.New(AText);
  Shortcut := AShortcut;
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
  ParentList := nil;
  ActionId := -1;
  Enabled := true;
  OnExecute := nil;
  ModalResult := mrNone;
  Owner := nil;
end;

destructor TAction.Free;
begin
  TString.Dispose(Text);
  TString.Dispose(ShortcutDisplayName);
  TString.Dispose(HelpText);
  inherited Free;
end;

procedure TAction.SetHelpText(AHelpText: string);
begin
  TString.Assign(HelpText, AHelpText);
end;

procedure TAction.SetText(AText: string);
begin
  TString.Assign(Text, AText);
end;

function TActionList.NewAction(AActionId: integer; AText: string;
  AShortcut: word): PAction;
var
  action: PAction;
begin
  action := New(PAction, Create(AActionId, AText, AShortcut));
  action^.ParentList := @Self;
  action^.ActionId := AActionId;
  Add(action);
  NewAction := action;
end;

function TActionList.GetHelpMaxWidth(AControl: pointer): integer;
var
  index: integer;
  maxWidth: word;
  action: PAction;
  txt: string;
  control: PControl;
begin
  maxWidth := 0;
  for index := 0 to Count - 1 do begin
    action := GetItem(index);
    if not Assigned(action^.HelpText) then
      continue;
    txt := StrPas(action^.HelpText);
    control := PControl(AControl);
    maxWidth := MaxWord(control^.TrueTextWidth(txt), maxWidth);
  end;
  GetHelpMaxWidth := maxWidth;
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
  Add := inherited Add(AItem);
  AItem^.ParentList := @self;
end;

function TActionList.GetItemById(AId: string): PAction;
begin
  GetItemById := PAction(inherited GetItemById(AId));
end;

function TActionList.GetActionById(AActionId: integer): PAction;
var
  index: integer;
  action: PAction;
begin
  GetActionByid := nil;
  for index := 0 to Count - 1 do begin
    action := GetItem(index);
    if action^.ActionId = AActionId then begin
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