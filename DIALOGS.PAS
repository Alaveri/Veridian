{$I COMPILER.INC}
unit Dialogs;

interface

uses
  {$IFDEF DOS}
  Dos,
  {$ENDIF}
  AplObj,
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
  PShowMessageDialog = ^TShowMessageDialog;

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
  private
    FDialogButtons: PButtonList;
    procedure CreateButtons;
    procedure CreateButton(AButton: TDialogButton);
  public
    ActionList: PActionList;
    Buttons: TDialogButtons;
    ButtonAlign: TTextAlign;
    DefaultButton: TDialogButton;
    CancelButton: TDialogButton;
    ModalResult: TModalResult;
    Closed: boolean;
    constructor Create(AId: string; AButtons: TDialogButtons);
    function ShowModal: TModalResult;
    procedure Init; virtual;
    procedure BeforeShow; virtual;
    procedure AfterShow; virtual;
    procedure SetupControls; virtual;
    procedure KeyPress(var AEvent: TKeyEvent); virtual;
    procedure HandleActionExecute(var AAction: PAction); virtual;
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

  TFileDialogOption =
  (
    doFileMustExist,
    doOverwritePrompt
  );

  TFileDialogOptions = set of TFileDialogOption;

  TFileDialog = object(TDialog)
  private
    CurrentDir: PDirectoryContents;
    LastDir: string;
    procedure PopulateFileBox(const APath: string);
    procedure ReadPath(const APath: string);
    procedure Cancel;
    procedure CloseDialog(AModalResult: TModalResult; AFilename: string);
  public
    FileBox: PListBox;
    FilenameEntry: PEdit;
    DirectoryLabel: PLabel;
    InitialPath: string;
    DefaultExt: string;
    Filename: string;
    Options: TFileDialogOptions;
    constructor Create(const ATitle, AInitialPath: string);
    constructor CreateOptions(const ATitle, AInitialPath: string; AOptions: TFileDialogOptions);
    procedure SelectFile(AFile: PFile); virtual;
    procedure SelectText(AFilename: string); virtual;
    procedure HandleActionExecute(var AAction: PAction); virtual;
    procedure SetupControls; virtual;
    procedure BeforeShow; virtual;
    procedure AfterShow; virtual;
    procedure Init; virtual;
    destructor Free; virtual;
  end;

  TShowMessageDialog = object(TDialog)
  private
    FLabel: PLabel;
  public
    Message: string;
    constructor Create(const ATitle, AMessage: string; AButtons: TDialogButtons);
    procedure Init; virtual;
    procedure SetupControls; virtual;
  end;

procedure ShowMessage(const ATitle, AMessage: string); far;
function MessageBox(
  const ATitle, AMessage: string;
  AButtons: TDialogButtons;
  ADefault: TDialogButton;
  ACancel: TDialogButton): TModalResult; far;

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
begin
  dialog := PDialog(AAction^.Owner);
  dialog^.HandleActionExecute(AAction);
end;

procedure FileDialogDblClick(ASender: PObject; var AEvent: TMouseEvent); far;
var
  list: PListBox;
  dialog: PFileDialog;
  item: PListItem;
  aFile: PFile;
begin
  list := PListBox(ASender);
  dialog := PFileDialog(list^.Parent);
  item := PListItem(list^.Items^.GetItem(list^.SelectedIndex));
  aFile := PFile(item^.Value);
  dialog^.SelectFile(aFile);
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
  dialog := PFileDialog(list^.Parent);
  aFile := dialog^.CurrentDir^.Files^.GetItem(AEvent.NewIndex);
  name := StrPas(aFile^.Name);
  if faDirectory in aFile^.Attr then
    name := IncludeBackslash(name);
  dialog^.FilenameEntry^.SetText(FirstUpper(name));
end;

procedure FileDialogListKeyPress(ASender: PObject; var AEvent: TKeyEvent); far;
var
  dialog: PFileDialog;
  list: PListBox;
  item: PListItem;
  aFile: PFile;
begin
  list := PListBox(ASender);
  dialog := PFileDialog(list^.Parent);
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
  dialog := PFileDialog(entry^.Parent);
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

procedure ShowMessage(const ATitle, AMessage: string);
var
  dialog: PShowMessageDialog;
begin
  dialog := New(PShowMessageDialog, Create(ATitle, AMessage, [mbOk]));
  dialog^.ShowModal;
  FreeAndNil(dialog);
end;

function MessageBox(
  const ATitle, AMessage: string;
  AButtons: TDialogButtons;
  ADefault: TDialogButton;
  ACancel: TDialogButton): TModalResult;
var
  dialog: PShowMessageDialog;
begin
  dialog := New(PShowMessageDialog, Create(ATitle, AMessage, AButtons));
  dialog^.DefaultButton := ADefault;
  dialog^.CancelButton := ACancel;
  MessageBox := dialog^.ShowModal;
  FreeAndNil(dialog);
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

procedure TDialog.HandleActionExecute(var AAction: PAction);
var
  result: TModalResult;
begin
  result := AAction^.ModalResult;
  if result = mrNone then
    exit;
  ModalResult := result;
  Close;
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
  Closed := false;
  ActionList := New(PActionList, Create);
  Font := Desktop^.Font;
  CanFocus := false;
  ForeColor := Desktop^.Colors^.Dialog;
  BackColor := Desktop^.Colors^.DialogBack;
  BorderColor := Desktop^.Colors^.Border;
  BorderStyle := bsSingle;
  Modal := true;
  Closed := false;
  ButtonAlign := taCenter;
  FDialogButtons := New(PButtonList, Create);
  FDialogButtons^.DisposeObjects := false;
  ModalResult := mrNone;
  CancelButton := mbNone;
  DefaultButton := mbNone;
  CreateButtons;
  Visible := false;
end;

procedure TDialog.Close;
begin
  Closed := true;
end;

function TDialog.ShowModal: TModalResult;
var
  desktopActions: PActionList;
  index: integer;
  button: PModalDialogButton;
  found: boolean;
  oldActiveControl: PControl;
  oldActiveView: PView;
  oldMenuEnabled, oldDrawEnabled: boolean;
  rect: TRect;
begin
  oldActiveControl := Desktop^.ActiveControl;
  oldActiveView := Desktop^.ActiveView;
  if Assigned(oldActiveControl) then
    oldActiveControl^.Unfocus;
  oldMenuEnabled := Desktop^.MenuBar^.Enabled;
  Desktop^.MenuBar^.Enabled := false;
  Desktop^.MenuBar^.Draw;
  Modal := true;
  Activate;
  oldDrawEnabled := VeridianApp^.DrawEnabled;
  VeridianApp^.DrawEnabled := false;
  if (not found) and (FDialogButtons^.Count > 0) then
    FDialogButtons^.GetItem(0)^.Focus;
  BeforeShow;
  desktopActions := Desktop^.ActionList;
  Visible := true;
  for index := 0 to FDialogButtons^.Count - 1 do begin
    button := PModalDialogButton(FDialogButtons^.GetItem(index));
    if button^.Default then begin
      FDialogButtons^.GetItem(index)^.Focus;
      found := true;
      break;
    end;
  end;
  VeridianApp^.DrawEnabled := oldDrawEnabled;
  Show;
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
  Desktop^.MenuBar^.Enabled := oldMenuEnabled;
  Desktop^.MenuBar^.Draw;
  if Assigned(oldActiveView) then
    oldActiveView^.Activate;
  if Assigned(oldActiveControl) then
    oldActiveControl^.Focus;
  Desktop^.ActionList := desktopActions;
  GetScreenBounds(rect);
  Desktop^.StartDrawing;
  GetScreenBounds(rect);
  Graph^.State.ViewPort.Assign(rect);
  Desktop^.PaintRegion(rect, @self);
  Desktop^.EndDrawing;
  Desktop^.Controls^.Remove(@self);;
  ShowModal := ModalResult;
end;

procedure TDialog.SetupControls;
var
  rect: TRect;
  bx, by, bWidth, bHeight: integer;
  index: integer;
  control: PControl;
  button: PModalDialogButton;
  totalWidth: integer;
  lowRes: boolean;
  fontHeight: integer;
begin
  inherited SetupControls;
  lowRes := Graph^.Mode^.Height < 640;
  fontHeight := Font^.Height + 6;
  if lowRes then
    fontHeight := Font^.Height + 4;
  GetClientRect(rect);
  totalWidth := 0;
  bWidth := Font^.TextWidth('Cancel') + 12 * Font^.Spacing;
  bHeight := fontHeight;
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
    if AEvent.Handled then
      exit;
    button := PModalDialogButton(FDialogButtons^.GetItem(index));
    if not Assigned(button^.Action) then
      continue;
    if ((AEvent.Key = kyEsc) and button^.Cancel) then begin
      AEvent.Handled := true;
      VeridianApp^.HandleActionExecute(button, button^.Action);
    end;
    if AEvent.Key = kyEnter  then begin
      if Desktop^.ActiveControl = PControl(button) then begin
        AEvent.Handled := true;
        VeridianApp^.HandleActionExecute(button, button^.Action);
      end;
    end;
  end;
end;

destructor TDialog.Free;
begin
  FreeAndNil(ActionList);
  FreeAndNil(FDialogButtons);
  if Assigned(Parent) then
    PControl(Parent)^.Controls^.Remove(@self);
  inherited Free;
end;

constructor TModalDialogButton.CreateParent(const AId: string; AActionId: integer; AParent: PDialog);
begin
  inherited CreateParent(AId, AActionId, AParent);
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
  SetTitle(ATitle);
end;

constructor TFileDialog.CreateOptions(const ATitle, AInitialPath: string; AOptions: TFileDialogOptions);
begin
  Create(ATitle, AInitialPath);
  Options := AOptions;
end;

procedure TFileDialog.CloseDialog(AModalResult: TModalResult; AFilename: string);
var
  result: TModalResult;
  path: PathStr;
  name: NameStr;
  ext: NameStr;
  exists: boolean;
begin
  result := AModalResult;
  exists := true;
  if not FileExists(AFilename) then begin
    exists := false;
    FSplit(CurrentDir^.Filter, path, name, ext);
    if not HasWildCard(ext) then begin
      AFilename := AFilename + ext;
      if FileExists(AFilename) then
        exists := true;
    end;
  end;
  if not exists and (doFileMustExist in Options) then begin
    ShowMessage('Error', 'File ' + ExtractFullName(AFilename) + ' does not exist.');
    exit;
  end
  else if exists and (doOverwritePrompt in Options) then begin
    result := MessageBox(
      'Warning',
      'File ' + ExtractFullName(AFilename) + ' already exists.  Overwrite?',
      [mbYes, mbNo, mbCancel], mbYes, mbCancel);
  end;
  case result of
    mrYes, mrOk: begin
      ModalResult := mrOk;
      Filename := AFilename;
      Close;
    end;
    mrNo: begin
      ModalResult := mrNo;
      Close;
    end;
  end;
end;

procedure TFileDialog.HandleActionExecute(var AAction: PAction);
var
  aFile: PFile;
begin
  case AAction^.ModalResult of
    mrCancel: Close;
    mrOk: begin
      SelectText(FileNameEntry^.GetText);
    end;
  end;
end;

procedure TFileDialog.Cancel;
begin
end;

procedure TFileDialog.SelectText(AFilename: string);
var
 isDir: boolean;
 name: string;
 current: string;
begin
  AFilename := Trim(AFilename);
  current := GetCurrentDirectory;
  if Length(AFilename) = 0 then
    exit;
  AFilename := FExpand(AFilename);
  if DirectoryExists(AFilename) then begin
    AFilename := FExpand(AFilename);
    if not ChangeDirectory(AFilename) then
      exit;
    ReadPath(IncludeBackSlash(AFilename) + CurrentDir^.Filter);
    FilenameEntry^.SetText('');
    exit;
  end;
  if HasWildcard(AFilename) then begin
    ReadPath(AFilename);
    FilenameEntry^.SetText('');
    exit;
  end;
  CloseDialog(mrOk, AFilename);
end;

procedure TFileDialog.SelectFile(AFile: PFile);
var
  txt: string;
  attributes: word;
  error: integer;
  tempFile: File;
  dir: string;
begin
  dir := StrPas(CurrentDir^.Name);
  if StrPas(AFile^.Name) = '..' then
    txt := '..'
  else
    txt := dir + StrPas(AFile^.Name);
  System.Assign(tempFile, txt);
  GetFAttr(tempFile, attributes);
  error := DosError;
  if error = 0 then begin
    if faDirectory in TFileAttributes(byte(attributes)) then begin
      if not ChangeDirectory(txt) then
        exit;
      txt := GetCurrentDirectory;
      ReadPath(IncludeBackslash(txt) + CurrentDir^.Filter);
      FilenameEntry^.SetText('');
      FilenameEntry^.Draw;
    end else begin
      CloseDialog(mrOk, txt);
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
    afilename := FirstUpper(StrPas(afile^.Name));
    if faDirectory in aFile^.Attr then
      afilename := '[ ' + afilename + ' ]';
    FileBox^.Items^.AddItem(afilename, aFile);
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
var
  lowRes: boolean;
begin
  inherited Init;
  lowRes := Graph^.Mode^.Width < 640;
  if lowRes then begin
    Width := VeridianApp^.Scale(15);
    Height := VeridianApp^.Scale(20);
  end
  else begin
    Width := VeridianApp^.Scale(20);
    Height := VeridianApp^.Scale(20);
  end;
  LastDir := GetCurrentDirectory;
  Options := [];
  Title := nil;
  ScrollType := scNone;
  ButtonAlign := taRight;
  CurrentDir := nil;
  Filename := '';
  DefaultExt := '';
  FileBox := New(PListBox, CreateParent('FileListBox', @self));
  FileBox^.OnMouseDblClick := @FileDialogDblClick;
  FileBox^.OnSelectedIndexChanged := @FileDialogIndexChanged;
  FileBox^.OnKeyPress := @FileDialogListKeyPress;
  FileBox^.Font := VeridianApp^.Fonts^.GetItemById('Seattle');
  FilenameEntry := New(PEdit, CreateParent('FilenameEntry', @self));
  FilenameEntry^.ValidChars := ValidDosChars + ['\', ':', #9];
  FilenameEntry^.MaxLength := 255;
  FilenameEntry^.OnKeyPress := @FilenameKeyPress;

  DirectoryLabel := New(PLabel, CreateText('DirLabel', InitialPath, @self));
  DirectoryLabel^.AutoSize := false;
  ReadPath(InitialPath);
end;

procedure TFileDialog.SetupControls;
var
  items: integer;
  lowRes: boolean;
  dirHeight: integer;
  entryHeight, entryWidth: integer;
  margin: integer;
  xPos: integer;
  rect: TRect;
begin
  inherited SetupControls;
  X := CenterX;
  Y := CenterY;
  GetContentBounds(rect);

  lowRes := Graph^.Mode^.Width < 640;
  if lowRes then begin
    items := 12;
    dirHeight := Font^.Height + 3;
    entryHeight := Font^.Height + 4;
    margin := 2;
  end
  else begin
    items := 17;
    dirHeight := Font^.Height + 4;
    entryHeight := Font^.Height + 6;
    margin := 4;
  end;

  xPos := rect.X + Margin;
  entryWidth := self.Width - 2 * Margin - 2 * BorderWidth;

  DirectoryLabel^.SetBounds(
    xPos,
    rect.Y,
    entryWidth,
    dirHeight);
  DirectoryLabel^.VertAlign := vaCenter;

  FileBox^.SetBounds(
    xPos,
    rect.Y + DirectoryLabel^.Height,
    entryWidth,
    items * FileBox^.Font^.Height + 2 * FileBox^.BorderWidth
  );

  FilenameEntry^.SetBounds(
    xPos,
    FileBox^.Y + FileBox^.Height + Font^.Height div 2,
    entryWidth,
    entryHeight
  );
end;

destructor TFileDialog.Free;
begin
  FreeAndNil(CurrentDir);
  ChangeDirectory(LastDir);
  inherited Free;
end;

constructor TShowMessageDialog.Create(const ATitle, AMessage: string; AButtons: TDialogButtons);
begin
  Message := AMessage;
  inherited Create('ShowMessageDialog', AButtons);
  X := CenterX;
  Y := CenterY;
  SetTitle(ATitle);
end;

procedure TShowMessageDialog.Init;
var
  labelWidth: integer;
begin
  inherited Init;
  DefaultButton := mbOk;
  CancelButton := mbOk;
  ScrollType := scNone;
  ButtonAlign := taCenter;
  FLabel := New(PLabel, CreateParent(Message, @self));
  FLabel^.Text := TString.New(Message);
  labelWidth := Font^.TextWidth(Message);
  Width := labelWidth + VeridianApp^.Scale(4);
  Height := VeridianApp^.Scale(6);
end;

procedure TShowMessageDialog.SetupControls;
var
  labelWidth: integer;
begin
  inherited SetupControls;
  labelWidth := Font^.TextWidthLarge(FLabel^.Text);
  FLabel^.SetBounds((Width - labelWidth) div 2, Titlebar^.Height + Font^.Height, labelWidth, Font^.Height);
end;

end.

