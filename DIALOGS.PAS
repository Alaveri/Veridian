{$I COMPILER.INC}
unit Dialogs;

interface

uses
  AplObj,
  AplConst,
  AplTypes,
  AplMath,
  Actions,
  Lists,
  Drawing,
  Files,
  Graphics,
  MouseDrv,
  KeyDrv,
  VeriType,
  VeriCons,
  ListView,
  Controls,
  Editors,
  Views;

const
  acDialogYes = acVeridianDialog + 1;
  acDialogOk = acVeridianDialog + 2;
  acDialogAll = acVeridianDialog + 3;
  acDialogYesToAll = acVeridianDialog + 4;
  acDialogNo = acVeridianDialog + 5;
  acDialogNoToAll = acVeridianDialog + 6;
  acDialogContinue = acVeridianDialog + 7;
  acDialogRetry = acVeridianDialog + 8;
  acDialogAbort = acVeridianDialog + 9;
  acDialogIgnore = acVeridianDialog + 10;
  acDialogHelp = acVeridianDialog + 11;
  acDialogCancel = acVeridianDialog + 12;

type
  PDialog = ^TDialog;
  PDialogButton = ^TDialogButton;
  PFileDialog = ^TFileDialog;
  PFileNameEntry = ^TFileNameEntry;
  PFileListView = ^TFileListView;
  PShowMessageDialog = ^TShowMessageDialog;

  TDialogButtonType =
  (
    mbNone,
    mbYes,
    mbOk,
    mbAll,
    mbYesToAll,
    mbNo,
    mbNoToAll,
    mbContinue,
    mbRetry,
    mbAbort,
    mbIgnore,
    mbHelp,
    mbCancel
  );

  TDialogButtons = set of TDialogButtonType;

  TDialog = object(TWindow)
  private
    FDialogButtons: PButtonList;
    FOldMenuEnabled: boolean;
    FOldActionList: PActionList;
    function CreateAction(AButton: TDialogButtonType; AText: string;
      AShortCut: word): PAction;
    function CreateButton(AButton: TDialogButtonType): PDialogButton;
    procedure CreateButtons;
    procedure Prepare;
    procedure CleanUp;
    function IsDialogButton: boolean; virtual;
  public
    Buttons: TDialogButtons;
    ButtonAlign: THorzAlign;
    DefaultButton: TDialogButtonType;
    CancelButton: TDialogButtonType;
    ModalResult: TModalResult;
    ActionList: PActionList;
    constructor Create(const AId, ATitle: string; AButtons: TDialogButtons);
    destructor Free; virtual;
    function ShowDialog: TModalResult;
    function DialogButtons: PButtonList;
    function CanExecute(AActionId: word): boolean; virtual;
    procedure SetButtonTabOrders(AStartValue: integer); virtual;
    procedure ActionExecute(ASender: PActionControl; AAction: PAction); virtual;
    procedure Init; virtual;
    procedure BeforeShow; virtual;
    procedure AfterShow; virtual;
    procedure Layout; virtual;
    procedure CenterScreenX;
    procedure CenterScreenY;
    procedure Close(ASender: PControl); virtual;
    procedure KeyPress(var AEvent: TKeyEvent); virtual;
    procedure SetDefaultButton(AButton: TDialogButtonType);
    procedure SetCancelButton(AButton: TDialogButtonType);
    procedure GetButtonArea(var ARect: TRect);
  end;

  TDialogButton = object(TButton)
  private
  public
    Owner: PDialog;
    Default: boolean;
    Cancel: boolean;
    ModalResult: TModalResult;
    ButtonType: TDialogButtonType;
    procedure KeyPress(var AEvent: TKeyEvent); virtual;
    procedure Init; virtual;
  end;

  TFileDialogOption =
  (
    foFileMustExist,
    foOverwritePrompt
  );

  TFileDialogOptions = set of TFileDialogOption;

  TFileNameEntry = object(TEdit)
  private
  public
    procedure KeyPress(var AEvent: TKeyEvent); virtual;
  end;

  TFileListView = object(TListView)
  private
  public
    procedure KeyPress(var AEvent: TKeyEvent); virtual;
    procedure MouseDoubleClick(var AEvent: TMouseEvent); virtual;
    procedure SelectedIndexChanged(var AEvent: TIndexChangedEvent); virtual;
  end;

  TFileDialog = object(TDialog)
  private
    procedure PopulateFileView(const APath: string);
    procedure ReadPath(const APath: string);
    procedure Cancel;
    procedure CloseDialog(AModalResult: TModalResult; AFilename: string);
  public
    FileView: PFileListView;
    FilenameEntry: PFileNameEntry;
    DirectoryLabel: PLabel;
    InitialPath: PChar;
    DefaultExt: PChar;
    Filename: PChar;
    FilterList: PFileFilterList;
    DefaultFilter: PFileFilter;
    FileOptions: TFileDialogOptions;
    CurrentDir: PDirectoryContents;
    LastDir: PChar;
    constructor Create(const AId, ATitle: string);
    procedure SelectFile(AFile: PFile); virtual;
    procedure SelectText(AFilename: string); virtual;
    procedure ActionExecute(ASender: PActionControl; AAction: PAction); virtual;
    procedure Layout; virtual;
    procedure BeforeShow; virtual;
    procedure AfterShow; virtual;
    procedure Init; virtual;
    procedure SetInitialPath(const APath: string);
    procedure SetDefaultExt(const AExt: string);
    procedure SetFilename(const AFilename: string);
    function AddFilter(const ADescription, AFilter: string): PFileFilter;
    function GetInitialPath: string;
    function GetDefaultExt: string;
    function GetFilename: string;
    function MinHeight: integer; virtual;
    destructor Free; virtual;
  end;

  TShowMessageDialog = object(TDialog)
  private
  public
    Message: string;
    MessageLabel: PLabel;
    constructor Create(const ATitle, AMessage: string; AButtons: TDialogButtons);
    procedure Init; virtual;
    procedure Layout; virtual;
  end;

procedure ShowMessage(const ATitle, AMessage: string);

function MessageBox(const ATitle, AMessage: string; AButtons: TDialogButtons;
  ADefault: TDialogButtonType; ACancel: TDialogButtonType): TModalResult;

const
  DialogButtonIds: array[TDialogButtonType] of string = (
    'None',
    'Yes',
    'Ok',
    'All',
    'YesToAll',
    'No',
    'NoToAll',
    'Continue',
    'Retry',
    'Abort',
    'Ignore',
    'Help',
    'Cancel'
  );

  DialogButtonCaptions: array[TDialogButtonType] of string = (
    '',
    '&Yes',
    '&Ok',
    'A&ll',
    'Y&es to all',
    '&No',
    'No &to all',
    'C&ontinue',
    '&Retry',
    '&Abort',
    '&Ignore',
    '&Help',
    '&Cancel'
  );

implementation

uses
  Strings,
  Dos,
  AplStr,
  AplUtils,
  Veridian;

procedure ShowMessage(const ATitle, AMessage: string);
var
  dialog: PShowMessageDialog;
begin
  dialog := New(PShowMessageDialog, Create(ATitle, AMessage, [mbOk]));
  dialog^.ShowDialog;
  FreeAndNil(dialog);
end;

function MessageBox(const ATitle, AMessage: string; AButtons: TDialogButtons;
  ADefault: TDialogButtonType; ACancel: TDialogButtonType): TModalResult;
var
  dialog: PShowMessageDialog;
begin
  dialog := New(PShowMessageDialog, Create(ATitle, AMessage, AButtons));
  dialog^.SetDefaultButton(ADefault);
  dialog^.SetCancelButton(ACancel);
  MessageBox := dialog^.ShowDialog;
  FreeAndNil(dialog);
end;

constructor TDialog.Create(const AId, ATitle: string; AButtons: TDialogButtons);
begin
  VeridianApp^.PushState;
  VeridianApp^.State.DrawEnabled := false;
  inherited Create(AId, ATitle, Desktop);
  VeridianApp^.PopState;
  Buttons := AButtons;
  CreateButtons;
end;

function TDialog.CreateAction(AButton: TDialogButtonType; AText: string;
  AShortCut: word): PAction;
var
  newAction: PAction;
  newId: word;
begin
  newId := acVeridianDialog + word(AButton);
  newAction := New(PAction, Create(newId, AText, AShortCut));
  newAction^.ModalResult := TModalResult(AButton);
  ActionList^.Add(newAction);
  CreateAction := newAction;
end;

function TDialog.CreateButton(AButton: TDialogButtonType): PDialogButton;
var
  button: PDialogButton;
  newId: string;
  newAction: PAction;
begin
  newId := DialogButtonIds[AButton];
  button := New(PDialogButton, CreateParent(newId + 'Button', @self));
  button^.Owner := @self;
  button^.ShowShortCut := false;
  button^.Position := rpParentRelative;
  if CancelButton = AButton then
    button^.Cancel := true;
  if DefaultButton = AButton then
    button^.Default := true;
  button^.Action := CreateAction(AButton, DialogButtonCaptions[AButton], 0);
  button^.Action^.ShortCut := button^.GetAltHotKey;
  button^.ButtonType := AButton;
  FDialogButtons^.Insert(0, button);
  CreateButton := button;
end;

procedure TDialog.CreateButtons;
var
  index: TDialogButtonType;
  tabOrderValue, tabOrderIndex: integer;
  button: PButton;
begin
  if (CancelButton = mbNone) and (mbCancel in Buttons) then
    CancelButton := mbCancel;
  tabOrderValue := 0;
  for index := High(TDialogButtonType) downto Succ(mbNone) do begin
    if index in Buttons then
      button := CreateButton(index);
  end;
  tabOrderValue := 0;
  for tabOrderIndex := 0 to FDialogButtons^.Count - 1 do begin
    button := FDialogButtons^.GetItem(tabOrderIndex);
    button^.TabOrder := tabOrderValue;
    Inc(tabOrderValue);
  end;
end;

procedure TDialog.SetDefaultButton(AButton: TDialogButtonType);
var
  index: integer;
  button: PDialogButton;
begin
  for index := 0 to FDialogButtons^.Count - 1 do begin
    button := PDialogButton(FDialogButtons^.GetItem(index));
    button^.Default := false;
  end;
  for index := 0 to FDialogButtons^.Count - 1 do begin
    button := PDialogButton(FDialogButtons^.GetItem(index));
    if button^.ButtonType = AButton then
      button^.Default := true;
  end;
end;

procedure TDialog.SetCancelButton(AButton: TDialogButtonType);
var
  index: integer;
  button: PDialogButton;
begin
  for index := 0 to FDialogButtons^.Count - 1 do begin
    button := PDialogButton(FDialogButtons^.GetItem(index));
    button^.Cancel := false;
  end;
  for index := 0 to FDialogButtons^.Count - 1 do begin
    button := PDialogButton(FDialogButtons^.GetItem(index));
    if button^.ButtonType = AButton then
      button^.Cancel := true;
  end;
end;

procedure TDialog.Init;
begin
  VeridianApp^.PushState;
  VeridianApp^.State.DrawEnabled := false;
  inherited Init;
  FDialogButtons := New(PButtonList, Create);
  FDialogButtons^.DisposeObjects := false;
  FOldMenuEnabled := VeridianApp^.MenuBar^.IsEnabled;
  Buttons := [];
  ButtonAlign := haRight;
  DefaultButton := mbNone;
  CancelButton := mbNone;
  ModalResult := mrNone;
  WindowOptions := [
    woTitleBar,
    woCloseButton,
    woMoveable
  ];
  ScrollType := scNone;
  Grip^.Visible := false;
  TitleBar^.MinimizeButton^.Visible := false;
  TitleBar^.MaximizeButton^.Visible := false;
  ActionList := New(PActionList, Create);
  ActionList^.DisposeObjects := true;
  VeridianApp^.PopState;
  Padding.CreateValue(2);
  Visible := false;
end;

procedure TDialog.CenterScreenX;
begin
  X := (Graph^.Mode^.Width - Width) div 2;
end;

procedure TDialog.CenterScreenY;
begin
  Y := (Graph^.Mode^.Height - Height) div 2;
end;

procedure TDialog.BeforeShow;
begin
end;

procedure TDialog.AfterShow;
begin
end;

procedure TDialog.Layout;
var
  min, bx, by, buttonWidth, buttonHeight: integer;
  index: integer;
  control: PControl;
  button: PDialogButton;
  lowRes: boolean;
  fontHeight: integer;
  totalWidth: integer;
  rect: TRect;
begin
  inherited Layout;
  rect.CreateDims(0, 0, Width, Height);
  if FDialogButtons^.Count = 0 then
    exit;
  lowRes := Graph^.Mode^.Height < 512;
  button := PDialogButton(FDialogButtons^.GetItem(0));
  fontHeight := button^.Font^.Height;
  buttonHeight := fontHeight + button^.Padding.Height + 2 * button^.OuterWidth;
  by := Height - Padding.Bottom - buttonHeight - OuterWidth;
  min := 65;
  if Graph^.Mode^.Width < 512 then
    min := 35;
  bx := 0;
  totalWidth := 0;
  for index := FDialogButtons^.Count - 1 downto 0 do begin
    button := PDialogButton(FDialogButtons^.GetItem(index));
    buttonWidth := Max(min, button^.TrueTextWidth(button^.GetCaption) + button^.Padding.Width);
    Inc(totalWidth, buttonWidth + 3);
  end;
  case ButtonAlign of
    haLeft: bx := rect.X;
    haRight: bx := rect.Right - outerWidth - Padding.Right;
    haCenter: bx := rect.Right - (rect.Width - totalWidth) div 2;
  end;
  for index := FDialogButtons^.Count - 1 downto 0 do begin
    button := PDialogButton(FDialogButtons^.GetItem(index));
    buttonWidth := Max(min, button^.TrueTextWidth(button^.GetCaption) + button^.Padding.Width);
    Dec(bx, buttonWidth);
    button^.SetBounds(bx, by, buttonWidth, buttonHeight);
    Dec(bx, 3);
  end;
end;

procedure TDialog.SetButtonTabOrders(AStartValue: integer);
var
  button: PButton;
  index: integer;
begin
  for index := 0 to FDialogButtons^.Count - 1 do begin
    button := DialogButtons^.GetItem(index);
    button^.TabOrder := AStartValue;
    Inc(AStartValue);
  end;
end;

procedure TDialog.GetButtonArea(var ARect: TRect);
var
  button: PButton;
  areaHeight: integer;
begin
  areaHeight := 0;
  if FDialogButtons^.Count > 0 then begin
    button := PDialogButton(FDialogButtons^.GetItem(0));
    areaHeight := button^.Height + Padding.Bottom + OuterWidth;
  end;
  ARect.CreateDims(0, ClientHeight - areaHeight ,ClientWidth, areaHeight);
end;

procedure TDialog.KeyPress(var AEvent: TKeyEvent);
var
  hotKey: word;
  event: TActionEvent;
  index: integer;
  button: PDialogButton;
begin
  inherited KeyPress(AEvent);
  for index := 0 to FDialogButtons^.Count - 1 do begin
    if AEvent.Handled then
      exit;
    button := PDialogButton(FDialogButtons^.GetItem(index));
    event.Create;
    event.Action := button^.Action;
    if not Assigned(button^.Action) then
      continue;
    if not button^.IsVisibleAndEnabled then
      continue;
    hotKey := button^.GetAltHotKey;
    if AEvent.Key = hotKey then begin
      AEvent.Handled := true;
      ActionExecute(button, button^.Action);
    end;
    case AEvent.Key of
      kyEsc: begin
        AEvent.Handled := true;
        ModalResult := mrCancel;
        Close(nil);
      end;
      kyEnter: begin
        if button^.Focused  then begin
          AEvent.Handled := true;
          ActionExecute(button, button^.Action);
        end;
      end;
    end;
  end;
end;

procedure TDialogButton.KeyPress(var AEvent: TKeyEvent);
begin
  inherited KeyPress(AEvent);
  if AEvent.Handled then
    exit;
  if not Focused then
    exit;
  if AEvent.Key = kyLeft then
    AEvent.Key := kyShiftTab;
  if AEvent.Key = kyRight then
    AEvent.Key := kyTab;
  Owner^.KeyPress(AEvent);
end;

procedure TDialog.ActionExecute(ASender: PActionControl; AAction: PAction);
begin
  if not CanExecute(AAction^.ActionId) then
    exit;
  ModalResult := AAction^.ModalResult;
  Close(ASender);
end;

function TDialog.CanExecute(AActionId: word): boolean;
begin
  CanExecute := true;
end;

function TDialog.IsDialogButton: boolean;
begin
  IsDialogButton := true;
end;

procedure TDialog.Close(ASender: PControl);
begin
  inherited Close(ASender);
end;

{
 All this preparation is a bit complex.  In order to run the dialog within a
 function while still processing the event loop, the dialog basically needs to
 take over from TVeridianApp.Run.
 To Prepare:
  - All the states of the special controls are stored, the desktop is disabled,
    and the active control and window are unfocused and deactivated.
  - The Desktop's ActionList is reassigned to the dialog's ActionList.

 The event loop is then run in the dialog's ShowDialog function rather than
  TVeridianApp.Run loop, until the dialog is closed.

 To clean up after:
  - Special controls are popped back to their original states.
  - The dialog is hidden, the desktop is reenabled, and the previous active
    control and window are reactivated.
  - The ActionList is restored to the Desktop's ActionList.
}
procedure TDialog.Prepare;
var
  index: integer;
  button: PDialogButton;
  found: boolean;
  rect: TRect;
begin
  VeridianApp^.StoreSpecialControlState;
  if Assigned(VeridianApp^.ActiveControl) then
    VeridianApp^.ActiveControl^.Unfocus;
  if Assigned(VeridianApp^.ActiveWindow) then
    VeridianApp^.ActiveWindow^.Deactivate;

  FOldMenuEnabled := VeridianApp^.MenuBar^.IsEnabled;
  Enabled := true;

  VeridianApp^.PushState;
  VeridianApp^.State.DrawEnabled := false;
  Desktop^.SetEnabled(false);
  FOldActionList := Desktop^.ActionList;
  VeridianApp^.ClearSpecialControlState;
  found := false;
  for index := 0 to FDialogButtons^.Count - 1 do begin
    button := PDialogButton(FDialogButtons^.GetItem(index));
    if button^.Default then begin
      VeridianApp^.ActiveControl := FDialogButtons^.GetItem(index);
      found := true;
      break;
    end;
  end;
  if (not found) and (FDialogButtons^.Count > 0) then
    VeridianApp^.ActiveControl := FDialogButtons^.GetItem(0);
  VeridianApp^.PopState;

  Visible := false;
  BringToFront;
  VeridianApp^.ActiveWindow := @self;
  VeridianApp^.ActiveDialog := @self;
  VeridianApp^.PushState;
  Desktop^.ActionList := ActionList;
  VeridianApp^.MenuBar^.SetEnabled(false);
  VeridianApp^.MenuBar^.Draw;
end;

procedure TDialog.CleanUp;
var
  activeControl: PFocusControl;
  activeWindow: PWindow;
begin
  Desktop^.ActionList := FOldActionList;
  VeridianApp^.RestoreSpecialControlState;
  VeridianApp^.PopState;
  if VeridianApp^.ActiveWindow = @self then
    VeridianApp^.ActiveWindow := nil;
  Deactivate;
  VeridianApp^.PushState;
  VeridianApp^.State.DrawEnabled := false;
  VeridianApp^.MenuBar^.SetEnabled(FOldMenuEnabled);
  Desktop^.Controls^.RemoveItem(@self);
  Desktop^.SetEnabled(true);
  VeridianApp^.PopState;
  VeridianApp^.MenuBar^.Draw;
  if Assigned(VeridianApp^.ActiveWindow) then begin
    activeWindow := VeridianApp^.ActiveWindow;
    VeridianApp^.ActiveWindow := nil;
    activeWindow^.Activate;
  end;
  if Assigned(VeridianApp^.ActiveControl) then begin
    activeControl := VeridianApp^.ActiveControl;
    VeridianApp^.ActiveControl := nil;
    activeControl^.Focus;
  end;
end;

function TDialog.ShowDialog: TModalResult;
begin
  Prepare;
  BeforeShow;
  Show;
  AfterShow;
  repeat
    VeridianApp^.ProcessEvents;
    if Closed or VeridianApp^.Closed then
      break;
  until Closed;
  Hide;
  CleanUp;
  ShowDialog := ModalResult;
end;

function TDialog.DialogButtons: PButtonList;
begin
  DialogButtons := FDialogButtons;
end;

destructor TDialog.Free;
begin
  FreeAndNil(FDialogButtons);
  FreeAndNil(ActionList);
  if Assigned(Parent) then
    PControl(Parent)^.Controls^.RemoveItem(@self);
  inherited Free;
end;

procedure TDialogButton.Init;
begin
  inherited Init;
  Default := false;
  Cancel := false;
  ModalResult := mrNone;
  Padding.CreateAll(4, 1, 3, 1);
end;

constructor TFileDialog.Create(const AId, ATitle: string);
begin
  inherited Create(AId, ATitle, [mbOk, mbCancel]);
end;

function TFileDialog.AddFilter(const ADescription, AFilter: string): PFileFilter;
var
  result: PFileFilter;
begin
  result := New(PFileFilter, CreateFilter(ADescription, AFilter));
  FilterList^.Add(result);
  AddFilter := result;
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
      AFilename := UpperCase(AFilename + ext);
      if FileExists(AFilename) then
        exists := true;
    end;
  end;
  if not exists and (foFileMustExist in FileOptions) then begin
    ShowMessage('Error', 'File ' + ExtractFullName(AFilename) + ' does not exist.');
    exit;
  end
  else if exists and (foOverwritePrompt in FileOptions) then begin
    result := MessageBox(
      'Warning',
      'File ' + ExtractFullName(AFilename) + ' already exists.  Overwrite?',
      [mbYes, mbNo, mbCancel], mbYes, mbCancel);
  end;
  case result of
    mrYes, mrOk: begin
      ModalResult := mrOk;
      SetFilename(AFilename);
      Close(nil);
    end;
    mrNo: begin
      ModalResult := mrNo;
      Close(nil);
    end;
  end;
end;

procedure TFileDialog.ActionExecute(ASender: PActionControl; AAction: PAction);
var
  aFile: PFile;
begin
  case AAction^.ModalResult of
    mrCancel: Close(ASender);
    mrOk: begin
      SelectText(FileNameEntry^.GetText);
    end;
  end;
end;

function TFileDialog.GetInitialPath: string;
begin
  GetInitialPath := TString.GetString(InitialPath);
end;

function TFileDialog.GetDefaultExt: string;
begin
  GetDefaultExt := TString.GetString(DefaultExt);
end;

function TFileDialog.GetFilename: string;
begin
  GetFilename := TString.GetString(Filename);
end;

procedure TFileDialog.SetInitialPath(const APath: string);
begin
  TString.AssignString(InitialPath, APath);
end;

procedure TFileDialog.SetDefaultExt(const AExt: string);
begin
  TString.AssignString(DefaultExt, AExt);
end;

procedure TFileDialog.SetFilename(const AFilename: string);
begin
  TString.AssignString(Filename, AFilename);
end;

procedure TFileDialog.Cancel;
begin
  Close(@self);
end;

procedure TFileDialog.SelectText(AFilename: string);
var
 isDir: boolean;
 name: string;
 current: string;
 ext: string;
begin
  AFilename := Trim(AFilename);
  current := GetCurrentDirectory;
  if Length(AFilename) = 0 then
    exit;
  AFilename := FExpand(AFilename);
  if (ExtractExtension(AFilename) = '') and
    FileExists(AFilename + GetDefaultExt) then
    AFilename := UpperCase(AFilename + GetDefaultExt);
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
  dir := TString.GetString(CurrentDir^.Name);
  if TString.GetString(AFile^.Name) = '..' then
    txt := '..'
  else
    txt := dir + TString.GetString(AFile^.Name);
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

procedure TFileDialog.PopulateFileView(const APath: string);
var
  index: integer;
  newFile: PFile;
  item: PListItem;
  name: string;
  path: string;
begin
  FreeAndNil(CurrentDir);
  FileView^.Clear;
  path := FExpand(Trim(APath));
  CurrentDir := TDirectory.GetDirectory(path);
  CurrentDir^.Sort(dsFilename, dsAsc, true);
  for index := 0 to CurrentDir^.Files^.Count - 1 do begin
    newFile := CurrentDir^.Files^.Getitem(index);
    name := FirstUpper(TString.GetString(newFile^.Name));
    if faDirectory in newFile^.Attr then
      name := '[ ' + name + ' ]';
    FileView^.AddItemValue(name, newFile);
  end;
end;

procedure TFileDialog.BeforeShow;
begin
  TString.AssignString(InitialPath, FExpand(GetInitialPath));
  VeridianApp^.PushState;
  VeridianApp^.State.DrawEnabled := false;
  ReadPath(GetInitialPath);
  VeridianApp^.PopState;
end;

procedure TFileDialog.AfterShow;
begin
  FilenameEntry^.SetText(GetFilename);
  FileView^.Focus;
end;

procedure TFileDialog.ReadPath(const APath: string);
var
  path: string;
begin
  path := FExpand(APath);
  PopulateFileView(APath);
  FileView^.SelectedIndex := 0;
  FileView^.Draw;
  DirectoryLabel^.Clear;
  DirectoryLabel^.SetCaption(APath);
end;

procedure TFileDialog.Init;
var
  lowRes: boolean;
  rect: TRect;
  button: PButton;
begin
  inherited Init;
  LastDir := nil;
  TString.AssignString(LastDir, GetCurrentDirectory);
  FileOptions := [];
  Buttons := [mbOk, mbCancel];
  Include(WindowOptions, woResizeable);
  ScrollType := scNone;
  ButtonAlign := haRight;
  CurrentDir := nil;
  FilterList := New(PFileFilterList, Create);
  DefaultFilter := New(PFileFilter, CreateFilter('All Files', '*.*'));
  FilterList^.Add(DefaultFilter);

  Filename := nil;
  DefaultExt := nil;
  InitialPath := nil;
  FilenameEntry := New(PFileNameEntry, CreateParent('FilenameEntry', @self));
  FilenameEntry^.ValidChars := ValidDosChars + ['\', ':', #9];
  FilenameEntry^.MaxLength := 255;

  FileView := New(PFileListView, CreateParent('FileListView', @self));
  FileView^.AutoHeight := false;

  DirectoryLabel := New(PLabel, CreateCaption('DirLabel', GetInitialPath, @self));
  DirectoryLabel^.AutoSize := false;
  DirectoryLabel^.TransparentBack := false;
  DirectoryLabel^.Font := VeridianApp^.GetFont('editor');

  Width := 300;
  Height := 350;
  if Graph^.Mode^.Width < 512 then begin
    Width := 150;
    Height := 150;
  end;
  CenterScreen;
  Padding.CreateValue(2);
end;

function TFileDialog.MinHeight: integer;
begin
  MinHeight := 142;
end;

procedure TFileDialog.Layout;
var
  items: integer;
  lowRes: boolean;
  dirHeight: integer;
  entryHeight, entryWidth: integer;
  xPos: integer;
  index: integer;
  buttonRect, rect: TRect;
begin
  inherited Layout;
  FileView^.TabOrder := 0;
  FileNameEntry^.TabOrder := 1;
  for index := FDialogButtons^.Count - 1 downto 0 do begin
    PButtonList(FDialogButtons)^.GetItem(index)^.TabOrder := index + 2;
  end;
  Grip^.Visible := false;

  dirHeight := DirectoryLabel^.Font^.Height + 2;
  lowRes := Graph^.Mode^.Width < 512;
  if lowRes then begin
    items := 12;
    entryHeight := Font^.Height + 4;
  end
  else begin
    items := 17;
    entryHeight := FilenameEntry^.Font^.Height + 6;
  end;

  xPos := 0;
  entryWidth := ContentWidth;

  DirectoryLabel^.SetBounds(
    xPos,
    0,
    entryWidth,
    dirHeight);
  DirectoryLabel^.VertAlign := vaCenter;

  GetButtonArea(buttonRect);
  FileView^.SetBounds(
    xPos,
    DirectoryLabel^.Height,
    entryWidth,
    Height - TitleBar^.Height - dirHeight - entryHeight - 3 * Padding.Height
      - buttonRect.Height
  );

  FilenameEntry^.SetBounds(
    xPos,
    FileView^.Y + FileView^.Height + 4,
    entryWidth,
    entryHeight
  );
end;

destructor TFileDialog.Free;
begin
  ChangeDirectory(TString.GetString(LastDir));
  FreeAndNil(CurrentDir);
  FreeAndNil(FilterList);
  TString.Free(LastDir);
  TString.Free(InitialPath);
  TString.Free(DefaultExt);
  TString.Free(Filename);
  inherited Free;
end;

constructor TShowMessageDialog.Create(const ATitle, AMessage: string; AButtons: TDialogButtons);
begin
  Message := AMessage;
  inherited Create('ShowMessageDialog', ATitle, AButtons);
end;

procedure TShowMessageDialog.Init;
var
  lines: integer;
begin
  inherited Init;
  DefaultButton := mbOk;
  CancelButton := mbOk;
  ScrollType := scNone;
  ButtonAlign := haCenter;
  MessageLabel := New(PLabel, CreateParent(Message, @self));
  MessageLabel^.Caption := TString.New(Message);
  MessageLabel^.AutoSize := false;
  MessageLabel^.HorzAlign := haCenter;
  VertAlign := vaCenter;
  Padding.CreateAll(5, 2, 5, 2);
end;

procedure TShowMessageDialog.Layout;
var
  labelWidth: integer;
  button: PDialogButton;
  lines: word;
  size: TSize;
  pos: TPoint;
  rect: TRect;
begin
  lines := MessageLabel^.LineCount;
  labelWidth := MessageLabel^.MaxLineWidth;
  Width := labelWidth + OuterWidth + Padding.Width + 8;
  button := PDialogButton(FDialogButtons^.GetItem(0));
  Height :=
    (MessageLabel^.Font^.Height + MessageLabel^.VertSpacing) * (lines + 3)
    + Padding.Height
    + button^.Height
    + GetTitleHeight;
  inherited Layout;
  rect.CreateDims(0, 0, ContentWidth, ContentHeight - button^.Height);
  size.CreateDims(labelWidth, (MessageLabel^.Font^.Height + MessageLabel^.Font^.Spacing) * lines);
  GetAlign(rect, size, pos);
  MessageLabel^.SetBounds(
    pos.X,
    pos.Y,
    labelWidth,
    Font^.Height * lines
  );
end;

procedure TFileListView.KeyPress(var AEvent: TKeyEvent);
var
  dialog: PFileDialog;
  item: PListItem;
  aFile: PFile;
begin
  dialog := PFileDialog(Parent);
  if Focused then begin
    case AEvent.Key of
      kyEnter: begin
        item := PListItem(Items^.GetItem(SelectedIndex));
        aFile := PFile(item^.Value);
        dialog^.SelectFile(aFile);
      end;
    end;
  end;
  inherited KeyPress(AEvent);
end;

procedure TFileListView.MouseDoubleClick(var AEvent: TMouseEvent);
var
  dialog: PFileDialog;
  item: PListItem;
  aFile: PFile;
begin
  dialog := PFileDialog(Parent);
  item := PListItem(Items^.GetItem(SelectedIndex));
  aFile := PFile(item^.Value);
  dialog^.SelectFile(aFile);
  inherited MouseDoubleClick(AEvent);
end;

procedure TFileListView.SelectedIndexChanged(var AEvent: TIndexChangedEvent);
var
  dialog: PFileDialog;
  item: PListItem;
  aFile: PFile;
  name: string;
begin
  dialog := PFileDialog(Parent);
  item := PListItem(Items^.GetItem(AEvent.NewIndex));
  aFile := PFile(item^.Value);
  name := TString.GetString(aFile^.Name);
  if faDirectory in aFile^.Attr then
    name := IncludeBackslash(name);
  dialog^.FilenameEntry^.SetText(FirstUpper(name));
  inherited SelectedIndexChanged(AEvent);
end;

procedure TFileNameEntry.KeyPress(var AEvent: TKeyEvent);
var
  txt: string;
  dir: PDirectoryContents;
  dialog: PFileDialog;
  result: integer;
begin
  dialog := PFileDialog(Parent);
  case AEvent.Key of
    kyEnter: begin
      dialog^.SelectText(GetText);
    end;
    kyPageUp, kyPageDown, kyUp, kyDown: begin
      dialog^.FileView^.Focus;
      dialog^.FileView^.KeyPress(AEvent);
    end
  end;
  inherited KeyPress(AEvent);
end;

end.