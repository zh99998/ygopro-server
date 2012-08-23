object Form1: TForm1
  Left = 31
  Top = 146
  Width = 770
  Height = 383
  Caption = 'FH'#23545#25112#26381#21153#22120#65288'102D'#65289' v2 '#25112#38431#32423#26381#21153#22120
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Memo1: TMemo
    Left = 0
    Top = 105
    Width = 762
    Height = 251
    Align = alClient
    ImeName = #35895#27468#25340#38899#36755#20837#27861' 2'
    Lines.Strings = (
      '102D'#26381#21153#22120#65292#35831#35299#21387#21040#28216#25103#26681#30446#24405#36816#34892)
    TabOrder = 0
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 762
    Height = 105
    Align = alTop
    BorderStyle = bsSingle
    Ctl3D = True
    ParentCtl3D = False
    TabOrder = 1
    object breg: TButton
      Left = 331
      Top = 9
      Width = 102
      Height = 22
      Caption = #21551#29992#27880#20876
      TabOrder = 1
      OnClick = bregClick
    end
    object bserver: TButton
      Left = 7
      Top = 9
      Width = 102
      Height = 22
      Caption = #21551#21160#26381#21153
      TabOrder = 0
      OnClick = bserverClick
    end
    object eserverpost: TEdit
      Left = 7
      Top = 39
      Width = 324
      Height = 21
      ImeName = #35895#27468#25340#38899#36755#20837#27861' 2'
      TabOrder = 4
    end
    object bserverpost: TButton
      Left = 330
      Top = 39
      Width = 102
      Height = 22
      Caption = #20844#21578
      TabOrder = 5
      OnClick = bserverpostClick
    end
    object barena: TButton
      Left = 434
      Top = 39
      Width = 102
      Height = 22
      Caption = #31454#25216#22330
      TabOrder = 3
      Visible = False
      OnClick = barenaClick
    end
    object bmaskroom: TButton
      Left = 109
      Top = 9
      Width = 116
      Height = 22
      Caption = #21629#21517#31649#21046
      TabOrder = 2
      OnClick = bmaskroomClick
    end
    object Button1: TButton
      Left = 435
      Top = 9
      Width = 100
      Height = 22
      Caption = #20445#23384#29992#25143#25991#20214
      TabOrder = 6
      OnClick = Button1Click
    end
    object Button2: TButton
      Left = 226
      Top = 9
      Width = 105
      Height = 22
      Caption = #25171#24320'WEB'
      TabOrder = 7
      OnClick = Button2Click
    end
    object ebroadcast: TEdit
      Left = 7
      Top = 66
      Width = 324
      Height = 21
      ImeName = #35895#27468#25340#38899#36755#20837#27861' 2'
      TabOrder = 8
    end
    object Button3: TButton
      Left = 330
      Top = 67
      Width = 102
      Height = 22
      Caption = #24191#25773
      TabOrder = 9
      OnClick = Button3Click
    end
    object Button4: TButton
      Left = 539
      Top = 9
      Width = 100
      Height = 22
      Caption = #37325#36733#29992#25143#25991#20214
      TabOrder = 10
      OnClick = Button4Click
    end
    object Button5: TButton
      Left = 435
      Top = 66
      Width = 102
      Height = 23
      Caption = #38656#35201#32531#20914
      TabOrder = 11
      OnClick = Button5Click
    end
  end
  object IdTCPServer1: TIdTCPServer
    Bindings = <>
    DefaultPort = 7911
    ListenQueue = 0
    OnConnect = IdTCPServer1Connect
    OnDisconnect = IdTCPServer1Disconnect
    OnException = IdTCPServer1Exception
    OnExecute = IdTCPServer1Execute
    Left = 80
    Top = 168
  end
  object IdHTTPServer1: TIdHTTPServer
    Bindings = <>
    DefaultPort = 7922
    OnCommandGet = IdHTTPServer1CommandGet
    Left = 120
    Top = 168
  end
end
