{$I COMPILER.INC}
unit VTypes;

interface

uses
  AplObj,
  AplTypes,
  Lists;

type
  PDragEventProc = ^TDragEventProc;
  PScrollEventProc = ^TScrollEventProc;

  TBorderStyle =
  (
    bsNone,
    bsSingle,
    bsDouble
  );

  TScrollStyle =
  (
    ssVert,
    ssHorz
  );

  TScrollButtonStyle =
  (
    sbInc,
    sbDec,
    sbSlider
  );

  THorzAlign =
  (
    haLeft,
    haRight,
    haCenter
  );

  TVertAlign =
  (
    vaTop,
    vaBottom,
    vaCenter
  );

  TScreenPosition =
  (
    spAbsolute,
    spRelative
  );


  TScrollEvent = object(TEvent)
  private
  public
    CurrentPos: longint;
  end;

  TDragEvent = object(TMouseEvent)
  private
  public
  end;

  TDragEventProc = procedure(ASender: PObject; var AEvent: TDragEvent);
  TScrollEventProc = procedure(ASender: PObject; var AEvent: TScrollEvent);

implementation

end.