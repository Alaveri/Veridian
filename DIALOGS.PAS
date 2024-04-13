{$IFDEF debug}
  {$A-,B-,D+,F+,G-,I+,L+,N+,O+,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,F+,G-,I+,L-,N+,O+,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}
unit Dialogs;

interface

uses
  Objects,
  AplTypes,
  Lists,
  Files,
  Common,
  Veridian,
  Controls,
  Views,
  Tables,
  Actions,
  Editors,
  ListBox;

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
    CurrentDir: PDirectory;
    procedure PopulateFileBox(const APath, AFilter: string);
  public
    FileBox: PListBox;
    FilenameEntry: PEdit;
    DirectoryLabel: PLabel;
    InitialDir: string;
    constructor Create(AInitialDir: string);
    procedure SetupControls; virtual;
    procedure BeforeShow; virtual;
    procedure Init; virtual;
    destructor Free; virtual;
  end;

implementation

uses
  {$IFDEF DOS}
  Strings,
  {$ENDIF}
  Drawing,
  StrUtils,
  GraphDrv,
  KeyDrv,
  Desk;

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

procedure SaveDialogSelectedIndexChanged(ASender: PObject; var AEvent: TSelectedIndexChangedEvent); far;
var
  list: PListBox;
  dialog: PSaveDialog;
  item: PListItem;
  filename: string;
  aFile: PFile;
begin
  list := PListBox(ASender);
  dialog := PSaveDialog(list^.Parent^.Parent);
  item := PListItem(list^.Items^.GetItem(AEvent.NewIndex));
  aFile := PFile(item^.Value);
  filename := StrPas(aFile^.Name);
  dialog^.FilenameEntry^.SetText(filename);
  dialog^.FilenameEntry^.Draw;
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
  ForeColor := Desktop^.Colors^.Dialog;
  BackColor := Desktop^.Colors^.DialogBack;
  BorderColor := Desktop^.Colors^.Border;
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
  inherited KeyPress(AEvent);
  if AEvent.Handled then
    exit;
  for index := 0 to FDialogButtons^.Count - 1 do begin
    button := PModalDialogButton(FDialogButtons^.GetItem(index));
    if ((AEvent.Key = kyEsc) and button^.Cancel) then
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

constructor TSaveDialog.Create(AInitialDir: string);
begin
  InitialDir := AInitialDir;
  inherited Create('SaveDialog', [mbOk, mbCancel]);
  X := CenterX;
  Y := CenterY;
end;

procedure TSaveDialog.PopulateFileBox(const APath, AFilter: string);
var
  index: integer;
  afile: PFile;
  item: PListItem;
  filename: string;
begin
  FreeAndNil(CurrentDir);
  CurrentDir^.Filter := AFilter;
  CurrentDir := Directory.GetDirectory(APath + AFilter);
  CurrentDir^.Sort(dsFilename, dsAsc, true);
  for index := 0 to CurrentDir^.Files^.Count - 1 do begin
    afile := CurrentDir^.Files^.Getitem(index);
    filename := StrPas(afile^.Name);
    if faDirectory in aFile^.Attr then
      filename := '<' + filename + '>';
    item := New(PListItem, CreateTextValue(filename, aFile));
    FileBox^.Items^.Add(item);
  end;
end;

procedure TSaveDialog.BeforeShow;
begin
  FileBox^.Focus;
end;

procedure TSaveDialog.Init;
begin
  inherited Init;
  Width := Application^.ScaleX(60);
  Height := Application^.ScaleY(23);
  SetTitle('Save As');
  ScrollType := scNone;
  ButtonAlign := taRight;
  CurrentDir := nil;
  FileBox := New(PListBox, CreateParent('FileListBox', Content));
  FileBox^.OnSelectedIndexChanged := @SaveDialogSelectedIndexChanged;
  FilenameEntry := New(PEdit, CreateParent('FilenameEntry', Content));
  FilenameEntry^.Font := Application^.Fonts^.GetItemById('System');
  PopulateFileBox(InitialDir, '*.*');
  DirectoryLabel := New(PLabel, CreateText('', StrPas(CurrentDir^.Name) + CurrentDir^.Filter, Content));
  DirectoryLabel^.AutoSize := false;
  if FileBox^.Items^.Count > 0 then
    FileBox^.SelectedIndex := 0;
end;

procedure TSaveDialog.SetupControls;
var
  items: integer;
begin
  inherited SetupControls;
  items := 14;
  FileBox^.SetBounds(-1, 50, self.Width, items * FileBox^.Font^.Height + 2 * FileBox^.BorderWidth);
  FilenameEntry^.SetBounds(4, FileBox^.Y + FileBox^.Height + Font^.Height div 2, self.Width - 10, 22);
  DirectoryLabel^.SetBounds(4, 4, self.Width - 10, 25);
end;

destructor TSaveDialog.Free;
begin
  FreeAndNil(CurrentDir);
  inherited Free;
end;

end.

