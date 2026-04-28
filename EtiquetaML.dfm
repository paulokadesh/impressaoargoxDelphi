object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Impress'#195#163'o ZPL (Argox)'
  ClientHeight = 441
  ClientWidth = 624
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  TextHeight = 15
  object lblArquivo: TLabel
    Left = 16
    Top = 16
    Width = 42
    Height = 15
    Caption = 'Arquivo'
  end
  object lblImpressora: TLabel
    Left = 16
    Top = 76
    Width = 58
    Height = 15
    Caption = 'Impressora'
  end
  object lblDpi: TLabel
    Left = 312
    Top = 136
    Width = 18
    Height = 15
    Caption = 'DPI'
  end
  object edtArquivo: TEdit
    Left = 16
    Top = 36
    Width = 513
    Height = 23
    TabOrder = 0
  end
  object btnArquivo: TButton
    Left = 536
    Top = 35
    Width = 75
    Height = 25
    Caption = 'Procurar...'
    TabOrder = 1
    OnClick = btnArquivoClick
  end
  object cbImpressora: TComboBox
    Left = 16
    Top = 96
    Width = 513
    Height = 23
    Style = csDropDownList
    TabOrder = 2
  end
  object btnAtualizar: TButton
    Left = 536
    Top = 95
    Width = 75
    Height = 25
    Caption = 'Atualizar'
    TabOrder = 3
    OnClick = btnAtualizarClick
  end
  object chkNormalizar: TCheckBox
    Left = 16
    Top = 136
    Width = 273
    Height = 17
    Caption = 'For'#195#167'ar tamanho 10cm x 5cm (injeta ^PW/^LL)'
    Checked = True
    State = cbChecked
    TabOrder = 4
  end
  object edtDpi: TEdit
    Left = 344
    Top = 132
    Width = 57
    Height = 23
    TabOrder = 5
    Text = '203'
  end
  object btnImprimir: TButton
    Left = 454
    Top = 159
    Width = 75
    Height = 25
    Caption = 'Imprimir'
    TabOrder = 6
    OnClick = btnImprimirClick
  end
  object btnImprimirPpla: TButton
    Left = 352
    Top = 161
    Width = 75
    Height = 25
    Caption = 'PPLA'
    TabOrder = 10
    OnClick = btnImprimirPplaClick
  end
  object btnPreview: TButton
    Left = 129
    Top = 159
    Width = 89
    Height = 25
    Caption = 'Preview (PDF)'
    TabOrder = 8
    OnClick = btnPreviewClick
  end
  object btnSalvarZpl: TButton
    Left = 16
    Top = 159
    Width = 89
    Height = 25
    Caption = 'Salvar ZPL'
    TabOrder = 9
    OnClick = btnSalvarZplClick
  end
  object btnTeste: TButton
    Left = 241
    Top = 159
    Width = 89
    Height = 25
    Caption = 'Teste ZPL'
    TabOrder = 7
    OnClick = btnTesteClick
  end
  object Panel1: TPanel
    Left = 0
    Top = 208
    Width = 624
    Height = 233
    Align = alBottom
    Caption = 'Panel1'
    TabOrder = 11
    object MemoLog: TMemo
      Left = 1
      Top = 1
      Width = 622
      Height = 231
      Align = alClient
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 0
      ExplicitLeft = 0
      ExplicitTop = -48
      ExplicitWidth = 611
      ExplicitHeight = 209
    end
  end
  object OpenDialog1: TOpenDialog
    Filter = 'Arquivos texto (*.txt)|*.txt|Todos (*.*)|*.*'
    Left = 560
    Top = 176
  end
  object SaveDialog1: TSaveDialog
    DefaultExt = 'pdf'
    Filter = 'PDF (*.pdf)|*.pdf'
    Options = [ofOverwritePrompt, ofPathMustExist, ofEnableSizing]
    Left = 560
    Top = 224
  end
  object SaveDialog2: TSaveDialog
    DefaultExt = 'zpl'
    Filter = 'ZPL (*.zpl)|*.zpl|Texto (*.txt)|*.txt|Todos (*.*)|*.*'
    Options = [ofOverwritePrompt, ofPathMustExist, ofEnableSizing]
    Left = 560
    Top = 272
  end
end
