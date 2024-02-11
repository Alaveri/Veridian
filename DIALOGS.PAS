{$IFDEF debug}
  {$A-,B-,D+,F+,G-,I+,L+,N+,O+,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,F+,G-,I+,L-,N+,O+,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}
unit Dialogs;

interface

uses
  Objects,
  Veridian,
  Controls,
  Views,
  Tables,
  Actions,
  Types,
  ListBox,
  Lists;

type
  PDialog = ^TDialog;
  PModalDialogButton = ^TModalDialogButton;
  PSaveDialog = ^TSaveDialog;

  TDialogButton =
  (
    mbNone,
    mbYes,
    mbNo,
    mbOk,
    mbCancel,
    mbHelp
  );

  TDialogButtons = set of TDialogButton;

  TDialog = object(TView)
  private
    FDialogButtons: PButtonList;
    FModalResult: TModalResult;
    procedure CreateButtons;
    procedure CreateButton(AButton: TDialogButton);
  public
    ActionList: PActionList;
    Buttons: TDialogButtons;
    ButtonAlign: TTextAlign;
    DefaultButton: TDialogButton;
    CancelButton: TDialogButton;
    constructor Create(AId: string; AButtons: TDialogButtons);
    function ShowModal: TModalResult;
    procedure Init; virtual;
    procedure BeforeShow; virtual;
    procedure SetupControls; virtual;
    procedure KeyPress(var AEvent: TKeyEvent); virtual;
    procedure Close; virtual;
    destructor Free; virtual;
  end;

  TModalDialogButton = object(TButton)
  private
  public
    Owner: PDialog;
    Default: boolean;
    Cancel: boolean;
    constructor CreateParent(const AId: string; AActionId: integer; AParent: PDialog);
    procedure Init; virtual;
  end;

  TSaveDialog = object(TDialog)
  private
    procedure PopulateFileBox(const APath: string);
  public
    FileBox: PListBox;
    constructor Create;
    procedure SetupControls; virtual;
    procedure BeforeShow; virtual;
    procedure Init; virtual;
    destructor Free; virtual;
  end;

implementation

uses
  Desk,
  Drawing,
  KeyDrv,
  StrUtils,
  Strings,
  FileUtil,
  GraphDrv;

const
  ActionIds: array [TDialogButton] of integer =
  (
    -1,
    1001,
    1002,
    1003,
    1004,
    1005
  );

  ActionTexts: array[TDialogButton] of string =
  (
    '',
    '&Yes',
    '&No',
    '&Ok',
    '&Cancel',
    '&Help'
  );

  ActionControlIds: array[TDialogButton] of string =
  (
    '',
    'YesButton',
    'NoButton',
    'OkButton',
    'CancelButton',
    'HelpButton'
  );

  ActionHotKeys: array[TDialogButton] of word =
  (
    0,
    kyAltY,
    kyAltN,
    kyAltO,
    kyAltC,
    kyAltH
  );

procedure DialogButtonActionExecute(ASender: PObject; AAction: PAction; AActionId: integer); far;
var
  dialog: PDialog;
begin
  dialog := PDialog(AAction^.Owner);
  dialog^.FModalResult := AAction^.ModalResult;
  dialog^.Close;
end;

procedure TDialog.CreateButton(AButton: TDialogButton);
var
  action: PAction;
  actionId: integer;
  button: PModalDialogButton;
begin
  actionId := ActionIds[AButton];
  action := New(PAction, Create(actionId, ActionTexts[AButton], ActionHotKeys[AButton]));
  action^.OnExecute := @DialogButtonActionExecute;
  action^.ModalResult := TModalResult(AButton);
  action^.Owner := @self;
  ActionList^.Add(action);
  button := New(PModalDialogButton, CreateParent(ActionControlIds[AButton], actionId, @self));
  if CancelButton = AButton then
    button^.Cancel := true;
  if DefaultButton = AButton then
    button^.Default := true;
  FDialogButtons^.Add(button);
end;

procedure TDialog.BeforeShow;
begin
end;

procedure TDialog.CreateButtons;
var
  index: TDialogButton;
begin
  if (CancelButton = mbNone) and (mbCancel in Buttons) then
    CancelButton := mbCancel;
  if DefaultButton = mbNone then begin
    if mbOk in Buttons then
      DefaultButton := mbOk;
    if mbYes in Buttons then
      DefaultButton := mbYes;
  end;
  for index := Low(TDialogButton) to High(TDialogButton) do begin
    if index = mbNone then
      continue;
    if index in Buttons then begin
      if DefaultButton = mbNone then
        DefaultButton := index;
      if CancelButton = mbNone then
        CancelButton := index;
      CreateButton(index);
    end;
  end;
end;

constructor TDialog.Create(AId: string; AButtons: TDialogButtons);
begin
  Application^.DrawEnabled := false;
  Buttons := AButtons;
  inherited CreateParent(AId, Desktop);
  Application^.DrawEnabled := true;
  BringToFront;
end;

procedure TDialog.Init;
begin
  inherited Init;
  ActionList := New(PActionList, Create);
  Font := Desktop^.Font;
  CanFocus := false;
  ForeColor := Desktop^.InterfaceColors^.Dialog;
  BackColor := Desktop^.InterfaceColors^.DialogBack;
  BorderColor := Desktop^.InterfaceColors^.Border;
  BorderStyle := bsSingle;
  Modal := true;
  Closed := false;
  Font := Desktop^.Font;
  ButtonAlign := taCenter;
  FDialogButtons := New(PButtonList, Create);
  FDialogButtons^.DisposeObjects := false;
  FModalResult := mrNone;
  CancelButton := mbNone;
  DefaultButton := mbNone;
  CreateButtons;
end;

procedure TDialog.Close;
begin
  inherited Close;
end;

function TDialog.ShowModal: TModalResult;
var
  desktopActions: PActionList;
  index: integer;
  button: PModalDialogButton;
  found: boolean;
  oldActiveControl: PControl;
  oldActiveView: PView;
begin
  oldActiveControl := Desktop^.ActiveControl;
  oldActiveView := Desktop^.ActiveView;
  if Assigned(oldActiveControl) then
    oldActiveControl^.Unfocus;
  Desktop^.MenuBar^.Enabled := false;
  Desktop^.MenuBar^.Draw;
  Modal := true;
  Activate;
  Application^.DrawEnabled := false;
  for index := 0 to FDialogButtons^.Count - 1 do begin
    button := PModalDialogButton(FDialogButtons^.GetItem(index));
    if button^.Default then begin
      FDialogButtons^.GetItem(index)^.Focus;
      found := true;
      break;
    end;
  end;
  if (not found) and (FDialogButtons^.Count > 0) then
    FDialogButtons^.GetItem(0)^.Focus;
  BeforeShow;
  Application^.DrawEnabled := true;
  Draw;
  desktopActions := Desktop^.ActionList;
  Desktop^.ActionList := ActionList;
  repeat
    Application^.ProcessEvents;
    if Closed then
      break;
    Application^.MainLoop;
  until Closed;

  if Desktop^.ActiveView = @self then
    Desktop^.ActiveView := nil;
  Application^.DeactivateActiveControl;
  Deactivate;
  Desktop^.ActionList := desktopActions;
  Desktop^.MenuBar^.Enabled := true;
  Desktop^.MenuBar^.Draw;
  if Assigned(oldActiveView) then
    oldActiveView^.Activate;
  if Assigned(oldActiveControl) then
    oldActiveControl^.Focus;

  ShowModal := FModalResult;
end;

procedure TDialog.SetupControls;
var
  rect: TRect;
  bx, by, bWidth, bHeight: integer;
  index: integer;
  control: PControl;
  button: PModalDialogButton;
  totalWidth: integer;
begin
  inherited SetupControls;
  Content^.GetBounds(rect);
  totalWidth := 0;
  bWidth := Font^.TextWidth('Cancel') + 12 * Font^.Spacing;
  bHeight := Font^.Height + 6;
  by := rect.Height - bHeight - Font^.Height div 2;
  for index := 0 to FDialogButtons^.Count - 1 do begin
    button := PModalDialogButton(FDialogButtons^.GetItem(index));
    Inc(totalWidth, bWidth);
    if index <> 0 then
      Inc(totalWidth, 4);
  end;
  case ButtonAlign of
    taLeft: bx := rect.X + 4;
    taRight: bx := rect.Right - totalWidth - 4;
    taCenter: bx := rect.X + (rect.Width - totalWidth) div 2;
  end;
  for index := 0 to FDialogButtons^.Count - 1 do begin
    button := PModalDialogButton(FDialogButtons^.GetItem(index));
    button^.SetBounds(bx, by, bWidth, bHeight);
    Inc(bx, bWidth + 4);
  end;
end;

procedure TDialog.KeyPress(var AEvent: TKeyEvent);
var
  index: integer;
  button: PModalDialogButton;
begin
  for index := 0 to FDialogButtons^.Count - 1 do begin
    button := PModalDialogButton(FDialogButtons^.GetItem(index));
    if ((Keyboard.UpCase(AEvent.Key) = button^.GetHotKey)
      or (AEvent.Key = kyEsc)) and button^.Cancel then
      Application^.HandleActionExecute(button^.Action, button^.ActionId);
    if AEvent.Key = kyEnter then begin
      if Desktop^.ActiveControl = PControl(button) then
        Application^.HandleActionExecute(button^.Action, button^.ActionId)
    end;
  end;
  AEvent.Handled := true;
end;

destructor TDialog.Free;
begin
  FreeAndNil(ActionList);
  FreeAndNil(FDialogButtons);
  inherited Free;
end;

constructor TModalDialogButton.CreateParent(const AId: string; AActionId: integer; AParent: PDialog);
begin
  inherited CreateParent(AId, AActionId, AParent^.Content);
  Owner := PDialog(AParent);
  Action := Owner^.ActionList^.GetActionById(AActionId);
end;

procedure TModalDialogButton.Init;
begin

  inherited Init;
  Font := Desktop^.Font;
  Default := false;
  Cancel := false;
  Owner := nil;
end;

constructor TSaveDialog.Create;
begin
  inherited Create('SaveDialog', [mbOk, mbCancel]);
  X := CenterX;
  Y := CenterY;
end;

procedure TSaveDialog.PopulateFileBox(const APath: string);
var
  dir: PDirectory;
  index: integer;
  afile: PFile;
  item: PListItem;
begin
  dir := Directory.GetDirectory(APath);
  dir^.Sort(dsFilename, dsAsc, true);
  for index := 0 to dir^.Files^.Count - 1 do begin
    afile := dir^.Files^.Getitem(index);
    item := New(PListItem, CreateTextValue(StrPas(afile^.Name), nil));
    FileBox^.Items^.Add(item);
  end;
  FreeAndNil(dir);
end;

procedure TSaveDialog.BeforeShow;
begin
  FileBox^.Focus;
end;

procedure TSaveDialog.Init;
begin
  inherited Init;
  Width := Application^.ScaleX(60);
  Height := Application^.ScaleY(20);
  SetTitle('Save As');
  ScrollType := scNone;
  ButtonAlign := taRight;
  FileBox := New(PListBox, CreateParent('FileListBox', Content));
  PopulateFileBox('c:\*.*');
  if FileBox^.Items^.Count > 0 then
    FileBox^.SelectedIndex := 0;
end;

procedure TSaveDialog.SetupControls;
var
  bHeight: integer;
begin
  inherited SetupControls;
  bHeight := Font^.Height + 6;
  FileBox^.SetBounds(-1, -1, self.Width, self.Content^.Height - 3 * bHeight);
end;

destructor TSaveDialog.Free;
begin
  inherited Free;
end;

end.

