unit EtiquetaML;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  Winapi.WinSpool,
  System.SysUtils,
  System.Variants,
  System.Classes,
  System.Math,
  System.StrUtils,
  System.IOUtils,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.Printers, Vcl.ExtCtrls;

type
  TForm1 = class(TForm)
    lblArquivo: TLabel;
    edtArquivo: TEdit;
    btnArquivo: TButton;
    lblImpressora: TLabel;
    cbImpressora: TComboBox;
    btnAtualizar: TButton;
    chkNormalizar: TCheckBox;
    lblDpi: TLabel;
    edtDpi: TEdit;
    btnImprimirPpla: TButton;
    lblRange: TLabel;
    edtFrom: TEdit;
    edtTo: TEdit;
    OpenDialog1: TOpenDialog;
    Panel1: TPanel;
    MemoLog: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure btnAtualizarClick(Sender: TObject);
    procedure btnArquivoClick(Sender: TObject);
    procedure btnImprimirPplaClick(Sender: TObject);

  private
    procedure Log(const S: string);
    procedure LoadPrinters;
    function SelectedPrinter: string;
    function ReadDpi: Integer;
    procedure ReadLabelRange(out FromIndex, ToIndex: Integer);
    function EnsureLabelSizePerFormat(const ZplText: string; const WidthDots, HeightDots: Integer): string;
    procedure SendRawToPrinter(const PrinterName: string; const Data: TBytes; const DocName: string);
    function GetZplFromSelectedFile: string;
    function DecodeZplFieldHex(const S: string): string;
    function ZplToPplaOneFormat(const ZplFormat: string; const LabelWidthDots, LabelHeightDots: Integer;
      out Copies: Integer): string;
    procedure PrintZplAsPplaToSelectedPrinter(const PrinterName, ZplText: string; const FromIndex, ToIndex: Integer);
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.Log(const S: string);
begin
  MemoLog.Lines.Add(FormatDateTime('hh:nn:ss', Now) + '  ' + S);
end;

procedure TForm1.LoadPrinters;
var
  i: Integer;
  Prev: string;
begin
  Prev := cbImpressora.Text;
  cbImpressora.Items.BeginUpdate;
  try
    cbImpressora.Items.Clear;
    for i := 0 to Vcl.Printers.Printer.Printers.Count - 1 do
      cbImpressora.Items.Add(Vcl.Printers.Printer.Printers[i]);
  finally
    cbImpressora.Items.EndUpdate;
  end;

  if cbImpressora.Items.Count > 0 then
  begin
    if Prev <> '' then
      cbImpressora.ItemIndex := cbImpressora.Items.IndexOf(Prev);
    if cbImpressora.ItemIndex < 0 then
      cbImpressora.ItemIndex := 0;
  end;
end;

function TForm1.SelectedPrinter: string;
begin
  if cbImpressora.ItemIndex >= 0 then
    Result := cbImpressora.Items[cbImpressora.ItemIndex]
  else
    Result := cbImpressora.Text;
end;

function TForm1.ReadDpi: Integer;
begin
  Result := StrToIntDef(Trim(edtDpi.Text), 203);
  if Result <= 0 then
    Result := 203;
end;

procedure TForm1.ReadLabelRange(out FromIndex, ToIndex: Integer);
var
  SFrom, STo: string;
  Tmp: Integer;
begin
  // Range 1-based. Em branco = sem filtro.
  SFrom := Trim(edtFrom.Text);
  STo := Trim(edtTo.Text);

  FromIndex := StrToIntDef(SFrom, 0);
  ToIndex := StrToIntDef(STo, 0);

  if FromIndex < 0 then FromIndex := 0;
  if ToIndex < 0 then ToIndex := 0;

  // Se informar só "até", assume "de 1".
  if (FromIndex = 0) and (ToIndex > 0) then
    FromIndex := 1;

  // Se invertido, corrige.
  if (FromIndex > 0) and (ToIndex > 0) and (FromIndex > ToIndex) then
  begin
    Tmp := FromIndex;
    FromIndex := ToIndex;
    ToIndex := Tmp;
  end;
end;

function CmToDots(const Cm: Double; const Dpi: Integer): Integer;
const
  CmPerInch = 2.54;
begin
  Result := Round((Cm / CmPerInch) * Dpi);
end;

function HasCmd(const BlockUpper, Cmd: string): Boolean;
begin
  Result := BlockUpper.Contains(Cmd);
end;

function IsHexByteAt(const S: string; const Index1Based: Integer): Boolean;
begin
  Result := (Index1Based >= 1) and (Index1Based + 2 <= Length(S)) and
    (S[Index1Based] = '_') and
    CharInSet(S[Index1Based + 1], ['0'..'9', 'A'..'F', 'a'..'f']) and
    CharInSet(S[Index1Based + 2], ['0'..'9', 'A'..'F', 'a'..'f']);
end;

function HexPairToByte(const C1, C2: Char): Byte;
  function HexVal(const C: Char): Integer;
  begin
    if CharInSet(C, ['0'..'9']) then Exit(Ord(C) - Ord('0'));
    if CharInSet(C, ['a'..'f']) then Exit(10 + Ord(C) - Ord('a'));
    if CharInSet(C, ['A'..'F']) then Exit(10 + Ord(C) - Ord('A'));
    Result := 0;
  end;
begin
  Result := Byte((HexVal(C1) shl 4) or HexVal(C2));
end;

function HasAnyFW(const BlockUpper: string): Boolean;
begin
  Result := BlockUpper.Contains('^FW');
end;

function InjectAfterXA(const Block, Insert: string): string;
var
  P: Integer;
begin
  P := Pos('^XA', Block);
  if P = 0 then
    Exit(Block);
  Result := Copy(Block, 1, P + 2) + Insert + Copy(Block, P + 3, MaxInt);
end;

function TForm1.EnsureLabelSizePerFormat(const ZplText: string; const WidthDots, HeightDots: Integer): string;
var
  i, StartPos, EndPos: Integer;
  OutText, Block, BlockUpper, Insert: string;
begin
  OutText := '';
  i := 1;
  while i <= Length(ZplText) do
  begin
    StartPos := PosEx('^XA', ZplText, i);
    if StartPos = 0 then
    begin
      OutText := OutText + Copy(ZplText, i, MaxInt);
      Break;
    end;

    OutText := OutText + Copy(ZplText, i, StartPos - i);
    EndPos := PosEx('^XZ', ZplText, StartPos);
    if EndPos = 0 then
    begin
      OutText := OutText + Copy(ZplText, StartPos, MaxInt);
      Break;
    end;

    Block := Copy(ZplText, StartPos, (EndPos - StartPos) + 3);
    BlockUpper := UpperCase(Block);

    // Garanta tamanho e orientação "normal" (^FWN) para evitar que a impressora
    // herde rotação de trabalhos anteriores.
    if (not HasCmd(BlockUpper, '^PW')) or (not HasCmd(BlockUpper, '^LL')) or (not HasAnyFW(BlockUpper)) then
    begin
      Insert := '';
      if not HasCmd(BlockUpper, '^PW') then
        Insert := Insert + Format('^PW%d', [WidthDots]);
      if not HasCmd(BlockUpper, '^LL') then
        Insert := Insert + Format('^LL%d', [HeightDots]);
      if not HasAnyFW(BlockUpper) then
        Insert := Insert + '^FWN';
      Block := InjectAfterXA(Block, Insert);
    end;

    OutText := OutText + Block;
    i := EndPos + 3;
  end;

  Result := OutText;
end;

procedure RaiseLastOSErrorAs(const Msg: string);
begin
  raise Exception.CreateFmt('%s (Win32=%d)', [Msg, GetLastError]);
end;

procedure TForm1.SendRawToPrinter(const PrinterName: string; const Data: TBytes; const DocName: string);
var
  hPrinter: THandle;
  DocInfo: DOC_INFO_1;
  BytesWritten: DWORD;
  Ok: BOOL;
  Payload: TBytes;
begin
  if Length(Data) = 0 then
    raise Exception.Create('Nada para imprimir (arquivo vazio).');

  // Muitas impressoras/firmwares ficam mais estáveis com finalização CRLF.
  Payload := Copy(Data);
  if (Length(Payload) < 2) or (Payload[High(Payload) - 1] <> 13) or (Payload[High(Payload)] <> 10) then
  begin
    SetLength(Payload, Length(Payload) + 2);
    Payload[High(Payload) - 1] := 13;
    Payload[High(Payload)] := 10;
  end;

  hPrinter := 0;
  if not OpenPrinter(PChar(PrinterName), hPrinter, nil) then
    RaiseLastOSErrorAs(Format('Falha ao abrir impressora "%s"', [PrinterName]));
  try
    DocInfo.pDocName := PChar(DocName);
    DocInfo.pOutputFile := nil;
    DocInfo.pDatatype := 'RAW';

    if StartDocPrinter(hPrinter, 1, @DocInfo) = 0 then
      RaiseLastOSErrorAs('Falha no StartDocPrinter');
    try
      if not StartPagePrinter(hPrinter) then
        RaiseLastOSErrorAs('Falha no StartPagePrinter');
      try
        BytesWritten := 0;
        Ok := WritePrinter(hPrinter, @Payload[0], Length(Payload), BytesWritten);
        if (not Ok) or (BytesWritten <> DWORD(Length(Payload))) then
          RaiseLastOSErrorAs(Format('Falha no WritePrinter (enviado=%d, escrito=%d)',
            [Length(Payload), BytesWritten]));
      finally
        if not EndPagePrinter(hPrinter) then
          RaiseLastOSErrorAs('Falha no EndPagePrinter');
      end;
    finally
      if not EndDocPrinter(hPrinter) then
        RaiseLastOSErrorAs('Falha no EndDocPrinter');
    end;
  finally
    ClosePrinter(hPrinter);
  end;
end;

function TForm1.DecodeZplFieldHex(const S: string): string;
var
  i: Integer;
  Bytes: TBytes;
  B: Byte;
  Ch: Char;
  Utf8: TBytes;
begin
  // ZPL com ^FH usa "_" seguido de 2 hex para bytes (geralmente UTF-8).
  SetLength(Bytes, 0);
  i := 1;
  while i <= Length(S) do
  begin
    if IsHexByteAt(S, i) then
    begin
      B := HexPairToByte(S[i + 1], S[i + 2]);
      SetLength(Bytes, Length(Bytes) + 1);
      Bytes[High(Bytes)] := B;
      Inc(i, 3);
      Continue;
    end;

    Ch := S[i];
    Utf8 := TEncoding.UTF8.GetBytes(Ch);
    if Length(Utf8) > 0 then
    begin
      SetLength(Bytes, Length(Bytes) + Length(Utf8));
      Move(Utf8[0], Bytes[Length(Bytes) - Length(Utf8)], Length(Utf8));
    end;
    Inc(i);
  end;

  Result := TEncoding.UTF8.GetString(Bytes);
end;

function ClampInt(const V, MinV, MaxV: Integer): Integer;
begin
  Result := V;
  if Result < MinV then Result := MinV;
  if Result > MaxV then Result := MaxV;
end;

function PplaCharToInt(const C: Char): Integer;
begin
  if CharInSet(C, ['0'..'9']) then
    Exit(Ord(C) - Ord('0'));
  if CharInSet(C, ['A'..'O']) then
    Exit(10 + Ord(C) - Ord('A'));
  Result := 1;
end;

function ScaleToPplaChar(const Scale: Integer): Char;
// '0'..'9' e 'A'..'O' representam 0..24 (aqui usamos 1..9)
begin
  if Scale <= 9 then
    Result := Char(Ord('0') + Scale)
  else
    Result := Char(Ord('A') + (Scale - 10));
end;

function WrapTextApprox(const Text: string; const MaxWidthDots, FontHeightDots: Integer; const MaxLines: Integer): TArray<string>;
var
  Words: TArray<string>;
  Line, W: string;
  i, LineCount: Integer;
  AvgCharDots: Integer;
  MaxChars: Integer;
  OutLines: TArray<string>;
begin
  // Heurística: largura média ~ 0.6 * altura da fonte (em dots)
  AvgCharDots := Max(1, Round(FontHeightDots * 0.6));
  MaxChars := Max(1, MaxWidthDots div AvgCharDots);

  Words := Text.Split([' ']);
  SetLength(OutLines, 0);
  Line := '';
  LineCount := 0;

  for i := 0 to High(Words) do
  begin
    W := Words[i];
    if Line = '' then
    begin
      Line := W;
      Continue;
    end;
    if Length(Line) + 1 + Length(W) <= MaxChars then
      Line := Line + ' ' + W
    else
    begin
      SetLength(OutLines, Length(OutLines) + 1);
      OutLines[High(OutLines)] := Line;
      Inc(LineCount);
      if (MaxLines > 0) and (LineCount >= MaxLines) then
      begin
        Result := OutLines;
        Exit;
      end;
      Line := W;
    end;
  end;

  if (Line <> '') and ((MaxLines = 0) or (LineCount < MaxLines)) then
  begin
    SetLength(OutLines, Length(OutLines) + 1);
    OutLines[High(OutLines)] := Line;
  end;
  Result := OutLines;
end;

function GetCmdParam(const Line, Cmd: string): string;
var
  P: Integer;
begin
  P := Pos(Cmd, Line);
  if P = 0 then Exit('');
  Result := Copy(Line, P + Length(Cmd), MaxInt);
end;

function TForm1.ZplToPplaOneFormat(const ZplFormat: string; const LabelWidthDots, LabelHeightDots: Integer;
  out Copies: Integer): string;
const
  STX = #2;
  CR = #13;
var
  Lines: TArray<string>;
  i: Integer;
  L, U: string;
  CurX, CurY: Integer;
  FontH, FontW: Integer;
  HasFH: Boolean;
  FbWidth, FbMaxLines: Integer;
  PendingBarcode: Boolean;
  BarcodeHeight: Integer;
  BarcodeWide, BarcodeNarrow: Char;
  Cmds: TStringBuilder;
  FieldData: string;
  Yppla: Integer;
  TextLines: TArray<string>;
  k: Integer;
  ScaleH, ScaleV: Integer;
  Dir: Char;
  Pq: string;
  PqParts: TArray<string>;
  Tmp: Integer;
  GlobalXShift: Integer;
  CurXShifted: Integer;
  CenteredBarcodeX: Integer;
  NarrowDots, WideDots, ApproxBarcodeDots: Integer;
begin
  Copies := 1;
  CurX := 0;
  CurY := 0;
  FontH := 24;
  FontW := 24;
  HasFH := False;
  FbWidth := 0;
  FbMaxLines := 0;
  PendingBarcode := False;
  BarcodeHeight := 80;
  BarcodeWide := '2';
  BarcodeNarrow := '1';
  Dir := '1'; // Portrait
  GlobalXShift := 30; // ajuste fino: empurra tudo para a direita (dots @203dpi)

  Lines := ZplFormat.Replace(#13, '').Split([#10], TStringSplitOptions.ExcludeEmpty);
  Cmds := TStringBuilder.Create;
  try
    for i := 0 to High(Lines) do
    begin
      L := Trim(Lines[i]);
      if L = '' then
        Continue;
      U := UpperCase(L);

      if U.Contains('^PQ') then
      begin
        Pq := GetCmdParam(U, '^PQ');
        PqParts := Pq.Split([',']);
        if Length(PqParts) > 0 then
        begin
          Tmp := StrToIntDef(PqParts[0], 1);
          if Tmp > 0 then Copies := Tmp;
        end;
        Continue;
      end;

      // No ZPL real, vários comandos vêm na mesma linha (^FO...^BY...^BC...^FD...).
      // Então precisamos processar TODOS os comandos presentes, não apenas o primeiro.
      if U.Contains('^FO') then
      begin
        // ^FOx,y
        Pq := GetCmdParam(U, '^FO');
        PqParts := Pq.Split([',', '^']);
        if Length(PqParts) >= 2 then
        begin
          CurX := StrToIntDef(PqParts[0], CurX);
          CurY := StrToIntDef(PqParts[1], CurY);
        end;
      end;

      if U.Contains('^FT') then
      begin
        // ^FTx,y
        Pq := GetCmdParam(U, '^FT');
        PqParts := Pq.Split([',', '^']);
        if Length(PqParts) >= 2 then
        begin
          CurX := StrToIntDef(PqParts[0], CurX);
          CurY := StrToIntDef(PqParts[1], CurY);
        end;
      end;

      if U.Contains('^BY') then
      begin
        // ^BY3,,0 => módulo estreito ~3; wide ~ narrow+1 (heurística)
        Pq := GetCmdParam(U, '^BY');
        PqParts := Pq.Split([',', '^']);
        if Length(PqParts) >= 1 then
        begin
          Tmp := StrToIntDef(PqParts[0], 2);
          Tmp := ClampInt(Tmp, 1, 9);
          BarcodeNarrow := Char(Ord('0') + Tmp);
          BarcodeWide := Char(Ord('0') + ClampInt(Tmp + 1, 1, 9));
        end;
      end;

      if U.Contains('^BC') then
      begin
        // ^BCN,80,... => Code128
        PendingBarcode := True;
        Pq := GetCmdParam(U, '^BC');
        PqParts := Pq.Split([',', '^']);
        if Length(PqParts) >= 2 then
          BarcodeHeight := StrToIntDef(PqParts[1], BarcodeHeight);
      end;

      if U.Contains('^A0') then
      begin
        // ^A0N,32,32
        Pq := GetCmdParam(U, '^A0');
        PqParts := Pq.Split([',', '^']);
        if Length(PqParts) >= 3 then
        begin
          FontH := StrToIntDef(PqParts[1], FontH);
          FontW := StrToIntDef(PqParts[2], FontW);
        end;
      end;

      if U.Contains('^FB') then
      begin
        // ^FB540,2,2,L
        Pq := GetCmdParam(U, '^FB');
        PqParts := Pq.Split([',', '^']);
        if Length(PqParts) >= 2 then
        begin
          FbWidth := StrToIntDef(PqParts[0], 0);
          FbMaxLines := StrToIntDef(PqParts[1], 0);
        end;
      end;

      if U.Contains('^FH') then
        HasFH := True;

      if U.Contains('^FD') then
      begin
        // extrair entre ^FD e ^FS (pode estar na mesma linha)
        FieldData := '';
        Tmp := Pos('^FD', U);
        if Tmp > 0 then
          FieldData := Copy(L, Tmp + 3, MaxInt);
        Tmp := Pos('^FS', UpperCase(FieldData));
        if Tmp > 0 then
          FieldData := Copy(FieldData, 1, Tmp - 1);

        if HasFH then
          FieldData := DecodeZplFieldHex(FieldData);

        FieldData := FieldData.Replace(#13, '').Replace(#10, '');
        if Trim(FieldData) = '' then
        begin
          // reset flags de campo
          HasFH := False;
          FbWidth := 0;
          FbMaxLines := 0;
          PendingBarcode := False;
          Continue;
        end;

        CurXShifted := ClampInt(CurX + GlobalXShift, 0, LabelWidthDots);

        if PendingBarcode then
        begin
          // Barcode: usar y ajustado (ZPL usa topo; PPLA usa baseline inferior)
          Yppla := LabelHeightDots - CurY - BarcodeHeight;
          Yppla := ClampInt(Yppla, 0, LabelHeightDots);

          // Centralizar o Code128 no rótulo (heurística de largura).
          NarrowDots := Max(1, PplaCharToInt(BarcodeNarrow));
          WideDots := Max(NarrowDots + 1, PplaCharToInt(BarcodeWide));
          // Code128 usa módulos fixos; aproximamos largura em dots:
          // (len * 11 + ~35 de start/stop/quiet) * narrow + quiet zones.
          ApproxBarcodeDots := ((Length(FieldData) * 11) + 35) * NarrowDots + (10 * NarrowDots);
          CenteredBarcodeX := (LabelWidthDots - ApproxBarcodeDots) div 2;
          CenteredBarcodeX := ClampInt(CenteredBarcodeX, 0, LabelWidthDots);

          Cmds.Append(Dir);
          Cmds.Append('E'); // Bar code E = Code 128 subset A/B/C (PPLA Argox)
          Cmds.Append(BarcodeWide);
          Cmds.Append(BarcodeNarrow);
          Cmds.Append(Format('%.3d', [ClampInt(BarcodeHeight, 1, 999)]));
          Cmds.Append(Format('%.4d', [ClampInt(Yppla, 0, 9999)]));
          Cmds.Append(Format('%.4d', [ClampInt(CenteredBarcodeX, 0, 9999)]));
          Cmds.Append(FieldData);
          Cmds.Append(CR);
        end
        else
        begin
          // Texto
          ScaleH := ClampInt(Round(FontW / 16), 1, 9);
          ScaleV := ClampInt(Round(FontH / 16), 1, 9);

          if (FbWidth > 0) and (FbMaxLines > 0) then
            TextLines := WrapTextApprox(FieldData, FbWidth, FontH, FbMaxLines)
          else
          begin
            SetLength(TextLines, 1);
            TextLines[0] := FieldData;
          end;

          for k := 0 to High(TextLines) do
          begin
            Yppla := LabelHeightDots - CurY - (k * (FontH + 2));
            Yppla := ClampInt(Yppla, 0, LabelHeightDots);

            Cmds.Append(Dir);
            Cmds.Append('2'); // font 2 (alfa-numérico comum)
            Cmds.Append(ScaleToPplaChar(ScaleH));
            Cmds.Append(ScaleToPplaChar(ScaleV));
            Cmds.Append('000'); // subfont
            Cmds.Append(Format('%.4d', [Yppla]));
            Cmds.Append(Format('%.4d', [ClampInt(CurXShifted, 0, 9999)]));
            Cmds.Append(TextLines[k]);
            Cmds.Append(CR);
          end;
        end;

        // reset flags de campo após imprimir
        HasFH := False;
        FbWidth := 0;
        FbMaxLines := 0;
        PendingBarcode := False;
      end;
    end;

    // Montar job PPLA (um formato por job)
    Result :=
      STX + 'm' + CR +
      STX + 'KI71' + CR + // transfer type (1 padrão)
      STX + 'O0220' + CR + // start position padrão
      STX + 'V0' + CR +
      STX + 'f298' + CR +
      STX + 'c0000' + CR +
      STX + 'L' + CR +
      'D11' + CR + // 0.125mm/pixel (casar com ZPL 203dpi)
      'H06' + CR + // heat/darkness: reduzir para evitar "ghosting"/borrado
      Cmds.ToString +
      Format('Q%.4d', [ClampInt(Copies, 1, 9999)]) + CR +
      'E' + CR;
  finally
    Cmds.Free;
  end;
end;

procedure TForm1.PrintZplAsPplaToSelectedPrinter(const PrinterName, ZplText: string; const FromIndex, ToIndex: Integer);
var
  i, StartPos, EndPos: Integer;
  Block: string;
  Copies: Integer;
  Ppla: string;
  Bytes: TBytes;
  CurIndex, TotalFormats, SelectedFormats, EffectiveTo: Integer;
const
  LabelW = 800; // 10cm @203dpi
  LabelH = 400; // 5cm @203dpi
begin
  CurIndex := 0;
  TotalFormats := 0;
  SelectedFormats := 0;
  EffectiveTo := ToIndex;
  if (FromIndex = 0) and (ToIndex = 0) then
    EffectiveTo := 0;

  i := 1;
  while i <= Length(ZplText) do
  begin
    StartPos := PosEx('^XA', ZplText, i);
    if StartPos = 0 then
      Break;
    EndPos := PosEx('^XZ', ZplText, StartPos);
    if EndPos = 0 then
      Break;

    Inc(CurIndex);
    TotalFormats := CurIndex;
    Block := Copy(ZplText, StartPos, (EndPos - StartPos) + 3);
    if ((FromIndex = 0) or (CurIndex >= FromIndex)) and
       ((EffectiveTo = 0) or (CurIndex <= EffectiveTo)) then
    begin
      Ppla := ZplToPplaOneFormat(Block, LabelW, LabelH, Copies);
      Bytes := TEncoding.UTF8.GetBytes(Ppla);
      SendRawToPrinter(PrinterName, Bytes, 'PPLA (convertido)');
      Inc(SelectedFormats);
      Log(Format('Formato #%d convertido e enviado em PPLA (cópias=%d).', [CurIndex, Copies]));
    end;
    i := EndPos + 3;
    if (EffectiveTo > 0) and (CurIndex >= EffectiveTo) then
      Break;
  end;

  if (FromIndex > 0) or (ToIndex > 0) then
    Log(Format('Filtro aplicado no PPLA: total=%d, selecionadas=%d (de=%d até=%d).',
      [TotalFormats, SelectedFormats, FromIndex, ToIndex]));
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  LoadPrinters;
  Log('Pronto.');
end;

procedure TForm1.btnAtualizarClick(Sender: TObject);
begin
  LoadPrinters;
  Log('Lista de impressoras atualizada.');
end;

procedure TForm1.btnArquivoClick(Sender: TObject);
begin
  OpenDialog1.FileName := edtArquivo.Text;
  if OpenDialog1.Execute then
  begin
    edtArquivo.Text := OpenDialog1.FileName;
    Log('Arquivo selecionado: ' + edtArquivo.Text);
  end;
end;


procedure TForm1.btnImprimirPplaClick(Sender: TObject);
var
  PrinterName, FileName: string;
  ZplText, FinalZpl: string;
  Dpi: Integer;
  W, H: Integer;
  FromIndex, ToIndex: Integer;
begin
  PrinterName := SelectedPrinter;
  if PrinterName = '' then
    raise Exception.Create('Selecione uma impressora.');

  FileName := Trim(edtArquivo.Text);
  if (FileName = '') or (not TFile.Exists(FileName)) then
    raise Exception.Create('Selecione um arquivo TXT válido.');

  ZplText := GetZplFromSelectedFile;
  FinalZpl := ZplText;
  if chkNormalizar.Checked then
  begin
    Dpi := ReadDpi;
    W := CmToDots(10, Dpi);
    H := CmToDots(5, Dpi);
    FinalZpl := EnsureLabelSizePerFormat(FinalZpl, W, H);
    Log(Format('Normalizado para 10x5cm (%ddpi): ^PW=%d ^LL=%d', [Dpi, W, H]));
  end;

  Log('Convertendo ZPL -> PPLA e enviando em RAW...');
  ReadLabelRange(FromIndex, ToIndex);
  PrintZplAsPplaToSelectedPrinter(PrinterName, FinalZpl, FromIndex, ToIndex);
  Log('Concluído.');
end;

function TForm1.GetZplFromSelectedFile: string;
var
  FileName: string;
  Bytes: TBytes;
begin
  FileName := Trim(edtArquivo.Text);
  if (FileName = '') or (not TFile.Exists(FileName)) then
    raise Exception.Create('Selecione um arquivo TXT válido.');
  Bytes := TFile.ReadAllBytes(FileName);
  Result := TEncoding.UTF8.GetString(Bytes);
end;





end.
