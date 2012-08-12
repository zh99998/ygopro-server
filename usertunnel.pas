unit usertunnel;

interface

uses
  SysUtils, Classes, IdBaseComponent, IdComponent, IdTCPConnection,
  IdTCPClient, IdThreadComponent, idcontext, messageSend,IdGlobal,
  IdBuffer, messagePackage, ygo_client_protocol;

type
  pidcontext = ^tidcontext;
  pdUserTunnel = ^TdUserTunnel;
  TdUserTunnel = class(TDataModule)
    IdTCPClient1: TIdTCPClient;
    IdThreadComponent1: TIdThreadComponent;
    procedure IdThreadComponent1Run(Sender: TIdThreadComponent);
    procedure IdTCPClient1Connected(Sender: TObject);
    procedure IdTCPClient1Disconnected(Sender: TObject);
    procedure IdTCPClient1Status(ASender: TObject;
      const AStatus: TIdStatus; const AStatusText: String);
  private
    { Private declarations }

  public
    { Public declarations }
    roomport:integer;
    peercontext:Tidcontext;
    Connected:boolean;
    function connectserver:boolean;
    procedure whendisconnect;
  end;


implementation
uses Dialogs, sys;

{$R *.dfm}

{ TdUserTunnel }

function TdUserTunnel.connectserver:boolean;
begin
   IdTCPClient1.Connect('127.0.0.1',roomport);
   IdTCPClient1.IOHandler.ReadTimeout:=300000;
   if IdTCPClient1.Connected then
   begin
       Connected:=true;
       result:=true;
   end;
end;

procedure TdUserTunnel.IdThreadComponent1Run(Sender: TIdThreadComponent);
  var stream:tmemorystream;
      i:integer;
      buff:TIdBytes;
      recv:pointer;
      tmproom:troom;
      procedure roomlistrefresh(room:troom;context:tidcontext);
      var j:integer;
      begin
        if not assigned(room.userlist) then
          room.userlist:=tlist.Create;
        for j:=0 to room.userlist.Count-1 do
        begin
            if room.userlist[j]=context then exit;
        end;
        room.userlist.Add(context);
      end;
begin
  try
    IdTCPClient1.IOHandler.ReadBytes(buff,2,false);
  except
    exit;
  end;
  i:=BytesToWord(buff);
  stream:=tmemorystream.Create;
  try
     IdTCPClient1.IOHandler.ReadStream(stream,i);
     recv:=stream.Memory;
        case ord(tpackage(recv^).protocolhead1) of
          STOC_TYPE_CHANGE:
          begin
            Tuserinfo(peercontext).pos:=ord(tplayerpostion(recv^).pos);
            tmproom:=Tuserinfo(peercontext).room;
            roomlistrefresh(tmproom,peercontext);
          end;
          STOC_DUEL_START:
          begin
            tmproom:=Tuserinfo(peercontext).room;
            tmproom.duelstart:=true;
          end;
          STOC_GAME_MSG:
          begin

          end;
        end;
     peersendstream(peercontext,stream);
  finally
    stream.Free;
  end;
end;

procedure TdUserTunnel.IdTCPClient1Connected(Sender: TObject);
begin
   Connected:=true;
   IdThreadComponent1.Start;
end;


procedure TdUserTunnel.IdTCPClient1Disconnected(Sender: TObject);
begin
    whendisconnect;
end;

procedure TdUserTunnel.IdTCPClient1Status(ASender: TObject;
  const AStatus: TIdStatus; const AStatusText: String);
begin
  if AStatus=hsDisconnected then
  begin
    Connected:=false;  //TCP断开
    whendisconnect;
  end;
end;


procedure TdUserTunnel.whendisconnect;
var i:integer;
begin
  Connected:=false;
  try
    if assigned(peercontext) then
      peercontext.Connection.Disconnect
    else
      exit;
  except
  end;

  if (tuserinfo(peercontext).pos=16) or ((tuserinfo(peercontext).pos=1)
      and tuserinfo(peercontext).room.duelstart) then
  begin
    if not assigned(tuserinfo(peercontext).room.userlist) then exit;
    //通知同一个房间的所有客户端掉线
    for i:=0 to tuserinfo(peercontext).room.userlist.count-1 do
    begin
      try
        if assigned(tuserinfo(tuserinfo(peercontext).room.userlist[i]).dm_usertl) then
          tuserinfo(tuserinfo(peercontext).room.userlist[i]).dm_usertl.IdTCPClient1.Disconnect;
      except
      end;
    end;
  end;
end;

end.
