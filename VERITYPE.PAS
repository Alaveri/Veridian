unit VeriType;

interface

uses
  Objects;

type
  TEvent = object(TObject)
  private
  public
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

