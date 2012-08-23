object Form2: TForm2
  Left = 244
  Top = 136
  Width = 528
  Height = 290
  Caption = #36741#21161#26381#21153#22120#35774#32622
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 6
    Top = 175
    Width = 99
    Height = 13
    AutoSize = False
    Caption = #26381#21153#22120#22320#22336
  end
  object Label2: TLabel
    Left = 264
    Top = 176
    Width = 65
    Height = 13
    AutoSize = False
    Caption = #32593#39029#31471#21475
  end
  object Label3: TLabel
    Left = 5
    Top = 203
    Width = 113
    Height = 13
    AutoSize = False
    Caption = #23458#25143#31471#36830#25509#31471#21475
  end
  object Label4: TLabel
    Left = 264
    Top = 200
    Width = 81
    Height = 13
    AutoSize = False
    Caption = #31649#29702#23494#30721
  end
  object ListView1: TListView
    Left = 0
    Top = 0
    Width = 520
    Height = 161
    Align = alTop
    Columns = <
      item
        Caption = #26381#21153#22120#22320#22336
        Width = 150
      end
      item
        Caption = #32593#39029#31471#21475
        Width = 90
      end
      item
        Caption = #36830#25509#31471#21475
        Width = 90
      end
      item
        Caption = #31649#29702#23494#30721
        Width = 90
      end>
    TabOrder = 0
    ViewStyle = vsReport
  end
  object serverip: TEdit
    Left = 120
    Top = 171
    Width = 121
    Height = 21
    TabOrder = 1
  end
  object serverhtmlport: TEdit
    Left = 344
    Top = 169
    Width = 121
    Height = 21
    TabOrder = 2
  end
  object servergameport: TEdit
    Left = 121
    Top = 197
    Width = 121
    Height = 21
    TabOrder = 3
  end
  object servermanagepass: TEdit
    Left = 343
    Top = 195
    Width = 121
    Height = 21
    TabOrder = 4
  end
  object Button1: TButton
    Left = 136
    Top = 224
    Width = 97
    Height = 19
    Caption = #28155#21152
    TabOrder = 5
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 240
    Top = 224
    Width = 88
    Height = 19
    Caption = #21024#38500#36873#20013
    TabOrder = 6
    OnClick = Button2Click
  end
end
