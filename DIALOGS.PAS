{$I COMPILER.INC}
unit Dialogs;

interface

uses
  AplObj,
  AplConst,
  AplTypes,
  Actions,
  Lists,
  Drawing,
  Graphics,
  MouseDrv,
  KeyDrv,
  VeriType,
  VeriCons,
  Controls,
  Views;

const
  acYes = acVeridianDialog + 1;
  acOk = acVeridianDialog + 2;
  acAll = acVeridianDialog + 3;
  acYesToAll = acVeridianDialog + 4;
  acNo = acVeridianDialog + 5;
  acNoToAll = acVeridianDialog + 6;
  acContinue = acVeridianDialog + 7;
  acRetry = acVeridianDialog + 8;
  acAbort = acVeridianDialog + 9;
  acIgnore = acVeridianDialog + 10;
  acHelp = acVeridianDialog + 11;
  acCancel = acVeridianDialog + 12;

type
  PDialog = ^TDialog;
  PDialogButton = ^TDialogButton;
{  PFileDialog = ^TFileDialog;}
{  PShowMessageDialog = ^TShowMessageDialog;}

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
    procedure CreateButtons;
    procedure CreateButton(AButton: TDialogButtonType);
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
    procedure ActionExecute(ASender: PActionControl; AAction: PAction); virtual;
    procedure Init; virtual;
    procedure BeforeShow; virtual;
    procedure AfterShow; virtual;
    procedure Layout; virtual;
    procedure Close(ASender: PControl); virtual;
    procedure KeyPress(var AEvent: TKeyEvent); virtual;
  end;

  TDialogButton = object(TButton)
  private
  public
    Owner: PDialog;
    Default: boolean;
    Cancel: boolean;
    ModalResult: TModalResult;
    procedure KeyPress(var AEvent: TKeyEvent); virtual;
    procedure Init; virtual;
  end;

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
  Veridian;

constructor TDialog.Create(const AId, ATitle: string; AButtons: TDialogButtons);
begin
  inherited CreateTitle(AId, ATitle, Desktop);
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

procedure TDialog.CreateButton(AButton: TDialogButtonType);
var
  button: PDialogButton;
  newId: string;
  newAction: PAction;
begin
  newId := DialogButtonIds[AButton];
  button := New(PDialogButton, CreateParent(newId + 'Button', @self));
  button^.Owner := @self;
  button^.ShowShortCut := false;
  button^.Position := spClient;
  if CancelButton = AButton then
    button^.Cancel := true;
  if DefaultButton = AButton then
    button^.Default := true;
  button^.Action := CreateAction(AButton, DialogButtonCaptions[AButton], 0);
  button^.Action^.ShortCut := button^.GetAltHotKey;
  FDialogButtons^.Insert(0, button);
end;

procedure TDialog.CreateButtons;
var
  index: TDialogButtonType;
begin
  if (CancelButton = mbNone) and (mbCancel in Buttons) then
    CancelButton := mbCancel;
  for index := High(TDialogButtonType) downto Succ(mbNone) do begin
    if index in Buttons then
      CreateButton(index);
  end;
end;

procedure TDialog.Init;
begin
  inherited Init;
  FDialogButtons := New(PButtonList, Create);
  FDialogButtons^.DisposeObjects := false;
  FOldMenuEnabled := VeridianApp^.MenuBar^.IsEnabled;
  Buttons := [];
  ButtonAlign := haRight;
  DefaultButton := mbNone;
  CancelButton := mbNone;
  ModalResult := mrNone;
  Options := [
    woTitleBar,
    woCloseButton,
    woMoveable
  ];
  ScrollType := scNone;
  Grip^.Visible := false;
  TitleBar^.MinimizeButton^.Visible := false;
  TitleBar^.MaximizeButton^.Visible := false;
  Position := spAbsolute;
  ActionList := New(PActionList, Create);
  ActionList^.DisposeObjects := true;
end;

procedure TDialog.BeforeShow;
begin
end;

procedure TDialog.AfterShow;
begin
end;

procedure TDialog.Layout;
var
  rect: TRect;
  bx, by, bWidth, bHeight: integer;
  index: integer;
  control: PControl;
  button: PDialogButton;
  totalWidth: integer;
  lowRes: boolean;
  fontHeight: integer;
begin
  inherited Layout;
  lowRes := Graph^.Mode^.Height < 640;
  fontHeight := Font^.Height;
  if lowRes then
    fontHeight := Font^.Height;
  GetClientOuterBounds(rect);
  totalWidth := 0;
  bWidth := Font^.TextWidth('Cancel') + 12 * Font^.Spacing;
  bHeight := fontHeight + FDialogButtons^.GetItem(0)^.Padding.Height;
  by := rect.Height - bHeight - fontHeight div 2;
  for index := 0 to FDialogButtons^.Count - 1 do begin
    button := PDialogButton(FDialogButtons^.GetItem(index));
    Inc(totalWidth, bWidth);
    if index <> 0 then
      Inc(totalWidth, 2);
  end;
  case ButtonAlign of
    haLeft: bx := rect.X + fontHeight div 2 + OuterWidth;
    haRight: bx := rect.Right - totalWidth - fontHeight div 2 - OuterWidth;
    haCenter: bx := rect.X + (rect.Width - totalWidth) div 2;
  end;
  for index := 0 to FDialogButtons^.Count - 1 do begin
    button := PDialogButton(FDialogButtons^.GetItem(index));
    button^.SetBounds(bx, by, bWidth, bHeight);
    Inc(bx, bWidth + 4);
  end;
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
  Owner^.KeyPress(AEvent);
end;

procedure TDialog.ActionExecute(ASender: PActionControl; AAction: PAction);
begin
  ModalResult := AAction^.ModalResult;
  Close(ASender);
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
  found := false;
  for index := 0 to FDialogButtons^.Count - 1 do begin
    button := PDialogButton(FDialogButtons^.GetItem(index));
    if button^.Default then begin
      FDialogButtons^.GetItem(index)^.Focus;
      found := true;
      break;
    end;
  end;
  if (not found) and (FDialogButtons^.Count > 0) then
    FDialogButtons^.GetItem(0)^.Focus;
  VeridianApp^.PopState;

  Visible := false;
  BringToFront;
  VeridianApp^.ClearSpecialControlState;
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
  if Assigned(VeridianApp^.ActiveWindow) then
    VeridianApp^.ActiveWindow^.Activate;
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
  Padding.CreateAll(10, 2, 10, 2);
end;

end.