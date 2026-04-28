object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Impress'#195#163'o ZPL (Argox)'
  ClientHeight = 508
  ClientWidth = 699
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
  object lblRange: TLabel
    Left = 16
    Top = 168
    Width = 93
    Height = 15
    Caption = 'Etiquetas (de-at'#233')'
  end
  object edtArquivo: TEdit
    Left = 16
    Top = 36
    Width = 513
    Height = 23
    TabOrder = 0
  end
  object btnArquivo: TButton
    Left = 535
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
    Caption = 'Formatar tamanho 10cm x 5cm (injeta ^PW/^LL)'
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
  object btnImprimirPpla: TButton
    Left = 281
    Top = 161
    Width = 88
    Height = 25
    Caption = 'Imprimir'
    TabOrder = 6
    OnClick = btnImprimirPplaClick
  end
  object edtFrom: TEdit
    Left = 121
    Top = 165
    Width = 57
    Height = 23
    TabOrder = 8
  end
  object edtTo: TEdit
    Left = 184
    Top = 165
    Width = 57
    Height = 23
    TabOrder = 9
  end
  object Panel1: TPanel
    Left = 0
    Top = 224
    Width = 699
    Height = 284
    Align = alBottom
    Caption = 'Panel1'
    TabOrder = 7
    object MemoLog: TMemo
      Left = 1
      Top = 1
      Width = 697
      Height = 282
      Align = alClient
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 0
    end
  end
  object OpenDialog1: TOpenDialog
    Filter = 'Arquivos texto (*.txt)|*.txt|Todos (*.*)|*.*'
    Left = 536
    Top = 360
  end
end
