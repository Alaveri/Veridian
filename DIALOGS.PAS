{$I COMPILER.INC}
unit Dialogs;

interface

uses
  {$IFDEF DOS}
  Dos,
  {$ENDIF}
  Objects,
  AplTypes,
  Lists,
  Files,
  Errors,
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
  PFileDialog = ^TFileDialog;
  PDialogActionExecuteProc = ^TDialogActionExecuteProc;

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
  TDialogActionExecuteProc = procedure(ASender: PObject; var AModalResult: TModalResult);

  TDialog = object(TView)
  {$IFDEF VER70}private{$ENDIF}
    FDialogButtons: PButtonList;
    FModalResult: TModalResult;
    procedure CreateButtons;
    procedure CreateButton(AButton: TDialogButton);
  {$IFDEF VER70}public{$ENDIF}
    ActionList: PActionList;
    Buttons: TDialogButtons;
    ButtonAlign: TTextAlign;
    DefaultButton: TDialogButton;
    CancelButton: TDialogButton;
    OnActionExecute: PDialogActionExecuteProc;
    constructor Create(AId: string; AButtons: TDialogButtons);
    function ShowModal: TModalResult;
    procedure Init; virtual;
    procedure BeforeShow; virtual;
    procedure AfterShow; virtual;
    procedure SetupControls; virtual;
    procedure KeyPress(var AEvent: TKeyEvent); virtual;
    procedure Close; virtual;
    destructor Free; virtual;
  end;

  TModalDialogButton = object(TButton)
  {$IFDEF VER70}private{$ENDIF}
  {$IFDEF VER70}public{$ENDIF}
    Owner: PDialog;
    Default: boolean;
    Cancel: boolean;
    constructor CreateParent(const AId: string; AActionId: integer; AParent: PDialog);
    procedure Init; virtual;
  end;

  TFileDialogOption =
  (
    foFileMustExist
  );

  TFileDialogOptions = set of TFileDialogOption;

  TFileDialog = object(TDialog)
  {$IFDEF VER70}private{$ENDIF}
    CurrentDir: PDirectoryContents;
    LastDir: string;
    procedure PopulateFileBox(const APath: string);
    procedure ReadPath(const APath: string);
    procedure Ok;
    procedure Cancel;
  {$IFDEF VER70}public{$ENDIF}
    FileBox: PListBox;
    FilenameEntry: PEdit;
    DirectoryLabel: PLabel;
    InitialPath: string;
    Filename: string;
    Options: TFileDialogOptions;
    constructor Create(const ATitle, AInitialPath: string);
    constructor CreateOptions(const ATitle, AInitialPath: string; AOptions: TFileDialogOptions);
    procedure SelectFile(AFile: PFile); virtual;
    procedure SelectText(const AFilename: string); virtual;
    procedure SetupControls; virtual;
    procedure BeforeShow; virtual;
    procedure AfterShow; virtual;
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
    10001,
    10002,
    10003,
    10004,
    10005
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

procedure DialogButtonActionExecute(ASender: PObject; AAction: PAction); far;
var
  dialog: PDialog;
  result: TModalResult;
begin
  dialog := PDialog(AAction^.Owner);
  result := AAction^.ModalResult;
  if Assigned(dialog^.OnActionExecute) then
    TDialogActionExecuteProc(dialog^.OnActionExecute)(dialog, result);
  if result = mrNone then
    exit;
  dialog^.FModalResult := result;
  dialog^.Close;
end;

procedure FileDialogDblClick(ASender: PObject; var AEvent: TMouseEvent); far;
var
  list: PListBox;
  dialog: PFileDialog;
  item: PListItem;
  aFile: PFile;
begin
  list := PListBox(ASender);
  dialog := PFileDialog(list^.Parent^.Parent);
  item := PListItem(list^.Items^.GetItem(list^.SelectedIndex));
  aFile := PFile(item^.Value);
  dialog^.SelectFile(aFile);
end;

procedure FileDialogActionExecute(ASender: PObject; var AModalResult: TModalResult); far;
var
  dialog: PFileDialog;
  item: PListItem;
  list: PListBox;
  aFile: PFile;
begin
  dialog := PFileDialog(ASender);
  list := PListBox(dialog^.FileBox);
  if AModalResult = mrOk then begin
    item := PListItem(list^.Items^.GetItem(list^.SelectedIndex));
    aFile := PFile(item^.Value);
    dialog^.SelectText(dialog^.FileNameEntry^.GetText);
    AModalResult := mrNone;
  end;
end;

procedure FileDialogIndexChanged(ASender: PObject; var AEvent: TIndexChangedEvent); far;
var
  list: PListBox;
  dialog: PFileDialog;
  aFile: PFile;
  index: integer;
  name: string;
begin
  list := PListBox(ASender);
  dialog := PFileDialog(list^.Parent^.Parent);
  aFile := dialog^.CurrentDir^.Files^.GetItem(AEvent.NewIndex);
  name := StrPas(aFile^.Name);
  if faDirectory in aFile^.Attr then
    name := IncludeBackslash(name);
  dialog^.FilenameEntry^.SetText(name);
end;

procedure FileDialogListKeyPress(ASender: PObject; var AEvent: TKeyEvent); far;
var
  dialog: PFileDialog;
  list: PListBox;
  item: PListItem;
  aFile: PFile;
begin
  list := PListBox(ASender);
  dialog := PFileDialog(list^.Parent^.Parent);
  case AEvent.Key of
    kyEnter: begin
      item := PListItem(list^.Items^.GetItem(list^.SelectedIndex));
      aFile := PFile(item^.Value);
      dialog^.SelectFile(aFile);
    end;
  end;
end;

procedure FilenameKeyPress(ASender: PObject; var AEvent: TKeyEvent); far;
var
  entry: PEdit;
  txt: string;
  dir: PDirectoryContents;
  dialog: PFileDialog;
  result: integer;
begin
  entry := PEdit(ASender);
  dialog := PFileDialog(entry^.Parent^.Parent);
  case AEvent.Key of
    kyEnter: begin
      dialog^.SelectText(dialog^.FileNameEntry^.GetText);
    end;
    kyPageUp, kyPageDown, kyUp, kyDown: begin
      dialog^.FileBox^.Focus;
      dialog^.FileBox^.KeyPress(AEvent);
    end
  end;
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

procedure TDialog.AfterShow;
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
  VeridianApp^.DrawEnabled := false;
  Buttons := AButtons;
  inherited CreateParent(AId, Desktop);
  VeridianApp^.DrawEnabled := true;
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
  OnActionExecute := nil;
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
  VeridianApp^.DrawEnabled := false;
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
  desktopActions := Desktop^.ActionList;
  VeridianApp^.DrawEnabled := true;
  Draw;
  AfterShow;
  Desktop^.ActionList := ActionList;
  repeat
    VeridianApp^.ProcessEvents;
    if Closed then
      break;
  until Closed;
  Desktop^.ActionList := desktopActions;
  if Desktop^.ActiveView = @self then
    Desktop^.ActiveView := nil;
  VeridianApp^.DeactivateActiveControl;
  Deactivate;
  Desktop^.MenuBar^.Enabled := true;
  Desktop^.MenuBar^.Draw;
  if Assigned(oldActiveView) then
    oldActiveView^.Activate;
  if Assigned(oldActiveControl) then
    oldActiveControl^.Focus;
  Desktop^.ActionList := desktopActions;
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
    if not Assigned(button^.Action) then
      continue;
    if ((AEvent.Key = kyEsc) and button^.Cancel) then begin
      VeridianApp^.HandleActionExecute(button, button^.Action);
    end;
    if AEvent.Key = kyEnter then begin
      if Desktop^.ActiveControl = PControl(button) then
        VeridianApp^.HandleActionExecute(button, button^.Action);
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

constructor TFileDialog.Create(const ATitle, AInitialPath: string);
begin
  InitialPath := FExpand(AInitialPath);
  inherited Create('FileDialog', [mbOk, mbCancel]);
  X := CenterX;
  Y := CenterY;
  SetTitle(ATitle);
end;

constructor TFileDialog.CreateOptions(const ATitle, AInitialPath: string; AOptions: TFileDialogOptions);
begin
  Create(ATitle, AInitialPath);
  Options := AOptions;
end;

procedure TFileDialog.Ok;
var
  txt: string;
  aFile: File;
  attributes: word;
  error: integer;
begin
  txt := Trim(FilenameEntry^.GetText);
  if txt = '' then
    exit;
  txt := FExpand(txt);
  System.Assign(aFile, txt);
  GetFAttr(aFile, attributes);
  error := DosError;
  if error = 0 then begin
    if faDirectory in TFileAttributes(byte(attributes)) then begin
      if not ChangeDirectory(ExtractDirectory(txt)) then
        exit;
      ReadPath(IncludeBackslash(txt) + CurrentDir^.Filter);
      FilenameEntry^.SetText('');
    end else begin
      Filename := txt;
      FModalResult := mrOk;
      Close;
    end;
  end else begin
    if HasWildCard(txt) then begin
      if not ChangeDirectory(ExtractDirectory(txt)) then
        exit;
      ReadPath(txt);
      FilenameEntry^.SetText('');
    end;
    if not (foFileMustExist in Options) then begin
    end;
  end;
end;

procedure TFileDialog.Cancel;
begin
end;

procedure TFileDialog.SelectText(const AFilename: string);
var
 txt: string;
 isDir: boolean;
begin
  txt := Trim(AFilename);
  if txt = '' then
    exit;
  isDir := EndsWith(txt, '\')
    or (txt = '..')
    or (txt = '.')
    or ((Length(txt) = 2) and (txt[2] = ':'));
  txt := FExpand(txt);
  if isDir and DirectoryExists(txt) then begin
    if not ChangeDirectory(ExtractDirectory(txt)) then
      exit;
    ReadPath(IncludeBackslash(txt) + CurrentDir^.Filter);
    FilenameEntry^.SetText('');
    exit;
  end;
  if HasWildcard(txt) then begin
    ReadPath(txt);
    FilenameEntry^.SetText('');
    exit;
  end;
  if not FileExists(txt) and (foFileMustExist in Options) then
    exit;
  if EndsWith(txt, '\') then
    exit;
  Filename := txt;
  FModalResult := mrOk;
  Close;
end;

procedure TFileDialog.SelectFile(AFile: PFile);
var
  txt: string;
  attributes: word;
  error: integer;
  tempFile: File;
  dir: string;
begin
  dir := IncludeBackSlash(StrPas(CurrentDir^.Name));
  txt := dir + StrPas(AFile^.Name);
  System.Assign(tempFile, txt);
  GetFAttr(tempFile, attributes);
  error := DosError;
  if error = 0 then begin
    if faDirectory in TFileAttributes(byte(attributes)) then begin
      if not ChangeDirectory(IncludeBackslash(txt)) then
        exit;
      txt := FExpand(txt);
      ReadPath(IncludeBackslash(txt) + CurrentDir^.Filter);
      FilenameEntry^.SetText('');
    end else begin
      Filename := txt;
      FModalResult := mrOk;
      Close;
    end;
  end;
end;

procedure TFileDialog.PopulateFileBox(const APath: string);
var
  index: integer;
  afile: PFile;
  item: PListItem;
  afilename: string;
  path: string;
begin
  FreeAndNil(CurrentDir);
  FileBox^.Clear;
  path := FExpand(Trim(APath));
  CurrentDir := TDirectory.GetDirectory(path);
  CurrentDir^.Sort(dsFilename, dsAsc, true);
  for index := 0 to CurrentDir^.Files^.Count - 1 do begin
    afile := CurrentDir^.Files^.Getitem(index);
    afilename := StrPas(afile^.Name);
    if faDirectory in aFile^.Attr then
      afilename := '<' + afilename + '>';
    item := New(PListItem, CreateTextValue(afilename, aFile));
    FileBox^.Items^.Add(item);
  end;
end;

procedure TFileDialog.BeforeShow;
begin
end;

procedure TFileDialog.AfterShow;
begin
  FilenameEntry^.SetText(Filename);
  FileBox^.Focus;
end;

procedure TFileDialog.ReadPath(const APath: string);
var
  path: string;
begin
  path := FExpand(APath);
  PopulateFileBox(APath);
  FileBox^.SelectedIndex := 0;
  FileBox^.Draw;
  DirectoryLabel^.Clear;
  DirectoryLabel^.SetText(APath);
end;

procedure TFileDialog.Init;
begin
  inherited Init;
  Width := VeridianApp^.ScaleX(60);
  Height := VeridianApp^.ScaleY(23);
  LastDir := GetCurrentDirectory;
  Options := [];
  Title := nil;
  ScrollType := scNone;
  ButtonAlign := taRight;
  CurrentDir := nil;
  Filename := '';
  FileBox := New(PListBox, CreateParent('FileListBox', Content));
  OnActionExecute := @FileDialogActionExecute;
  FileBox^.OnMouseDblClick := @FileDialogDblClick;
  FileBox^.OnSelectedIndexChanged := @FileDialogIndexChanged;
  FileBox^.OnKeyPress := @FileDialogListKeyPress;
  FilenameEntry := New(PEdit, CreateParent('FilenameEntry', Content));
  FilenameEntry^.ValidChars := ValidDosChars + ['\', ':', #9];
  FilenameEntry^.MaxLength := 255;
  FilenameEntry^.OnKeyPress := @FilenameKeyPress;
  FilenameEntry^.Font := VeridianApp^.Fonts^.GetItemById('System');
  DirectoryLabel := New(PLabel, CreateText('', InitialPath, Content));
  DirectoryLabel^.AutoSize := false;
  ReadPath(InitialPath);
end;

procedure TFileDialog.SetupControls;
var
  items: integer;
begin
  inherited SetupControls;
  items := 15;
  FileBox^.SetBounds(-1, 28, self.Width, items * FileBox^.Font^.Height + 2 * FileBox^.BorderWidth);
  FilenameEntry^.SetBounds(4, FileBox^.Y + FileBox^.Height + Font^.Height div 2, self.Width - 10, 22);
  DirectoryLabel^.SetBounds(4, 2, self.Width - 10, 25);
end;

destructor TFileDialog.Free;
begin
  FreeAndNil(CurrentDir);
  ChangeDirectory(LastDir);
  inherited Free;
end;

end.

