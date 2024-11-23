{$I COMPILER.INC}
unit ListCont;

interface

uses
  AplObj,
  AplTypes,
  Controls,
  Views;

type
  PListView = ^TListView;
  PDropDownList = ^TDropDownList;

  TListView = object(TView)
  private
  public
  end;

  TDropDownList = object(TListView)
  private
  public
  end;

implementation

end.