unit VeriType;

interface

uses
  Objects;

type
  TEvent = object(TObject)
  {$IFDEF VER70}private{$ENDIF}
  {$IFDEF VER70}public{$ENDIF}
    Handled: boolean;
    procedure Init; virtual;
    procedure Clear; virtual;
  end;

implementation

procedure TEvent.Clear;
begin
  Handled := false;
end;

procedure TEvent.Init;
begin
  inherited Init;
  Handled := false;
end;


end.

