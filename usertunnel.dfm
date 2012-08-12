object dUserTunnel: TdUserTunnel
  OldCreateOrder = False
  Left = 227
  Top = 135
  Height = 150
  Width = 215
  object IdTCPClient1: TIdTCPClient
    OnStatus = IdTCPClient1Status
    OnDisconnected = IdTCPClient1Disconnected
    OnConnected = IdTCPClient1Connected
    ConnectTimeout = 0
    IPVersion = Id_IPv4
    Port = 0
    ReadTimeout = -1
    Left = 40
    Top = 32
  end
  object IdThreadComponent1: TIdThreadComponent
    Active = False
    Loop = False
    Priority = tpNormal
    StopMode = smTerminate
    OnRun = IdThreadComponent1Run
    Left = 112
    Top = 32
  end
end
