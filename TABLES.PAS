{$I COMPILER.INC}
unit Tables;

interface

uses
  Objects,
  Lists,
  {$IFDEF DOS}
  Strings,
  {$ENDIF}
  Views,
  Controls;

type
  PTable = ^TTable;
  PTableColumn = ^TTableColumn;
  PTableColumnList = ^TTableColumnList;
  PRowDataBindProc = ^TRowDataBindProc;
  PTableGetDataFunc = ^TTableGetDataFunc;

  TTableRowType = (trHeader, trData, trFooter);
  TTableRowInfo = record
    RowType: TTableRowType;
    RowIndex: integer;
    RowData: PObject;
    RowVisible: boolean;
    RowForeColor: byte;
    RowBackColor: byte;
  end;

  TRowDataBindProc = procedure(ASender: PTable; var ARowInfo: TTableRowInfo);
  TTableGetDataFunc = function(var AData: PObject; AColumn: PTableColumn): string;

  TTableColumn = object(TIdentifiable)
  {$IFDEF VER70}private{$ENDIF}
    FHeader: PChar;
    FBinding: PChar;
  {$IFDEF VER70}public{$ENDIF}
    Width: integer;
    Align: TTextAlign;
    VertAlign: TVertAlign;
    Index: integer;
    Visible: boolean;
    function Header: string;
    function Binding: string;
    procedure Init; virtual;
    procedure SetHeader(const AHeader: string);
    procedure SetBinding(const ABinding: string);
    destructor Free; virtual;
  end;

  TTable = object(TView)
  {$IFDEF VER70}private{$ENDIF}
    FColumns: PTableColumnList;
    procedure DrawRow(var ARowInfo: TTableRowInfo);
    procedure RowDataBind(var ARowInfo: TTableRowInfo); virtual;
  {$IFDEF VER70}public{$ENDIF}
    DataSource: PObjectList;
    OnRowDataBind: PRowDataBindProc;
    OnGetData: PTableGetDataFunc;
    function Columns: PTableColumnList;
    function NewColumn(const AId, AHeader: string): PTableColumn;
    procedure Paint; virtual;
    procedure Init; virtual;
    destructor Free; virtual;
  end;

  TTableColumnList = object(TObjectList)
  {$IFDEF VER70}private{$ENDIF}
  {$IFDEF VER70}public{$ENDIF}
    procedure Init; virtual;
    destructor Free; virtual;
    function Add(AItem: PTableColumn): integer;
    function GetItem(AIndex: integer): PTableColumn;
    function SetItem(AIndex: integer; AItem: PTableColumn): boolean;
    function IndexOf(AItem: PTableColumn): integer;
    procedure Insert(AIndex: integer; AItem: PTableColumn);
  end;

implementation

uses
  Drawing,
  StrUtils,
  GraphDrv,
  GrDrv8;

function TTableColumn.Header: string;
begin
  Header := StrPas(FHeader);
end;

procedure TTableColumn.Init;
begin
  inherited Init;
  FHeader := nil;
  Align := taCenter;
  VertAlign := vaCenter;
  FBinding := nil;
  Index := -1;
  Visible := true;
end;

procedure TTableColumn.SetHeader(const AHeader: string);
begin
  TString.Assign(FHeader, AHeader);
end;

procedure TTableColumn.SetBinding(const ABinding: string);
begin
  TString.Assign(FBinding, ABinding);
end;

function TTableColumn.Binding: string;
begin
  Binding := StrPas(FBinding);
end;

destructor TTableColumn.Free;
begin
  TString.Free(FHeader);
  inherited Free;
end;

procedure TTable.Init;
begin
  inherited Init;
  FColumns := New(PTableColumnList, Create);
  OnRowDataBind := nil;
  DataSource := nil;
  OnGetData := nil;
end;

function TTable.Columns: PTableColumnList;
begin
  Columns := FColumns;
end;

function TTable.NewColumn(const AId, AHeader: string): PTableColumn;
var
  column: PTableColumn;
begin
  column := New(PTableColumn, CreateId(AId));
  column^.SetHeader(AHeader);
  NewColumn := column;
end;

procedure TTable.RowDataBind(var ARowInfo: TTableRowInfo);
begin
  if Assigned(OnRowDataBind) then
    TRowDataBindProc(OnRowDataBind)(@self, ARowInfo);
end;

procedure TTable.DrawRow(var ARowInfo: TTableRowInfo);
var
  index: integer;
  column: PTableColumn;
  data: string;
  cx, cy: integer;
  rect: TRect;
begin

  for index := 0 to Columns^.Count - 1 do begin
    column := Columns^.GetItem(index);
    if not column^.Visible then
      continue;
    if Assigned(OnGetData) then
      data := TTableGetDataFunc(OnGetData)(ARowInfo.RowData, column);
  end;
end;

procedure TTable.Paint;
var
  rect, drawRect: TRect;
  index: integer;
  info: TTableRowInfo;
begin
  inherited Paint;
  if not Assigned(DataSource) then
    exit;
  Graph^.State.ForeColor := ForeColor;
  Graph^.State.BackColor := BackColor;
  FillChar(info, SizeOf(info), 0);
  with info do begin
    RowType := trHeader;
    RowIndex := -1;
    RowData := nil;
    RowVisible := true;
    RowForeColor := ForeColor;
    RowBackColor := BackColor;
  end;
  RowDataBind(info);
  if not info.RowVisible then
    exit;
  DrawRow(info);

  for index := 0 to DataSource^.Count - 1 do begin
    FillChar(info, SizeOf(info), 0);
    with info do begin
      RowType := trData;
      RowIndex := index;
      RowData := DataSource^.GetItem(index);
      RowVisible := true;
      RowForeColor := ForeColor;
      RowBackColor := BackColor;
    end;
    RowDataBind(info);
    if not info.RowVisible then
      continue;
    DrawRow(info);
  end;

  FillChar(info, SizeOf(info), 0);
  with info do begin
    RowType := trFooter;
    RowIndex := -1;
    RowData := nil;
    RowVisible := true;
    RowForeColor := ForeColor;
    RowBackColor := BackColor;
  end;
  RowDataBind(info);
  if not info.RowVisible then
    exit;
  DrawRow(info);
end;

destructor TTable.Free;
begin
  FColumns^.Free;
  inherited Free;
end;

procedure TTableColumnList.Init;
begin
  inherited Init;
end;

destructor TTableColumnList.Free;
begin
  inherited Free;
end;

function TTableColumnList.Add(AItem: PTableColumn): integer;
begin
  Add := inherited Add(AItem);
end;

function TTableColumnList.GetItem(AIndex: integer): PTableColumn;
begin
  GetItem := PTableColumn(inherited GetItem(AIndex));
end;

function TTableColumnList.SetItem(AIndex: integer; AItem: PTableColumn): boolean;
begin
  SetItem := inherited SetItem(AIndex, AItem);
end;

function TTableColumnList.IndexOf(AItem: PTableColumn): integer;
begin
  IndexOf := inherited IndexOf(AItem);
end;

procedure TTableColumnList.Insert(AIndex: integer; AItem: PTableColumn);
begin
  inherited Insert(AIndex, AItem);
end;

end.