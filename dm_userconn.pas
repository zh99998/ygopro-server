unit dm_userconn;

interface

uses
  SysUtils, Classes, IdThreadComponent, IdBaseComponent, IdComponent,
  IdTCPConnection, IdTCPClient,IdGlobal,IdBuffer, sys,windows,Dialogs,
  messagePackage, ygo_client_protocol, ygo_server_userinfo,messageSend;

type
  Tdmuserconn = class(TDataModule)
    peerTcpClient: TIdTCPClient;
    IdThreadComponent1: TIdThreadComponent;
    procedure IdThreadComponent1Run(Sender: TIdThreadComponent);
  private
    { Private declarations }
  public
   room:proom;
   userinfo:puserinfo;
   procedure ConnectRoom;
    { Public declarations }
  end;

implementation

{$R *.dfm}

procedure Tdmuserconn.ConnectRoom;
begin
  peerTcpClient.Connect('127.0.0.1',room.roomport);
  if peerTcpClient.Connected then
    IdThreadComponent1.Start;
  sendbuffer(peerTcpClient,tuserinfo(userinfo^).userlogininfo,41);
end;

procedure Tdmuserconn.IdThreadComponent1Run(Sender: TIdThreadComponent);
var stream:tmemorystream;
      i:integer;
      buff:TIdBytes;
      recv:pointer;
      tmpstr:string;
      f:TFormatSettings;
begin
   try
    if peerTcpClient.IOHandler.Connected then
    peerTcpClient.IOHandler.ReadBytes(buff,2,false)
  except
    sender.Terminate;
    exit;
  end;

  i:=BytesToWord(buff);
  stream:=tmemorystream.Create;
  try
     if room=nil then
     begin
      peerTcpClient.Disconnect;
      exit;
     end;
     peerTcpClient.IOHandler.ReadStream(stream,i);
     recv:=stream.Memory;
        case ord(tpackage(recv^).protocolhead1) of
          STOC_TYPE_CHANGE:
          begin
            userinfo.postion:=ord(tplayerpostion(recv^).pos);
            if (userinfo.postion=0) or (userinfo.postion=16) then
            begin
              room.player1:=userinfo.username;
              room.player1reg:=userinfo.isUserInList;
            end;
            if (userinfo.postion=1) or (userinfo.postion=17) then
            begin
              room.player2:=userinfo.username;
              room.player2reg:=userinfo.isUserInList;
            end;
          end;
          STOC_DUEL_START:
          begin
            room.duelstart:=true;
            room.recorded:=false;
          end;

          STOC_GAME_MSG:
          begin
            buff:=ToBytes(recv,i-1,1);
            case buff[0] of
              MSG_WIN:
              begin
                room.winner:=buff[1];
                room.wincause:=buff[2];
              end;
            end;
          end;

          STOC_REPLAY:
          begin
              //竞技场下的M#不发回录像
              if isarena then exit;
          end;

          STOC_CHANGE_SIDE,  //更换SIDE
          STOC_DUEL_END:      //决斗完成
          begin//记录战斗信息
             //手卡记录
            EnterCriticalSection(sys_LOCKFile);
            try
              if (not room.recorded) and needRecordReplay then
              begin
                  randomize;
                  f.ShortDateFormat:='yyyy-MM-dd';
                  f.LongTimeFormat:='hh-mm-ss-ZZZ';
                  //使用当前时间（精确到毫秒）作为录像的唯一ID
                  tmpstr:= datetimetostr(now(),f);
                  //战斗结束，记录录像
                  if room.ismarch then
                  begin
                    if fileexists(ExtractFilePath(ParamStr(0))+'replay\'+inttostr(room.roomport)+'Replay.yrp') then
                    begin
                        copyfile(pchar(ExtractFilePath(ParamStr(0))+'replay\'+inttostr(room.roomport)+'Replay.yrp'),
                          pchar(ExtractFilePath(ParamStr(0))+'replay_cached\'+tmpstr+' '+room.player1+' VS '+room.player2+' '+inttostr(room.winner)+' '+inttostr(room.wincause)+'.yrp'),false);
                    end;
                  end
                  else
                  begin
                    if DirectoryExists(ExtractFilePath(ParamStr(0))+'replay_all\') then
                    begin
                       if fileexists(ExtractFilePath(ParamStr(0))+'replay\'+inttostr(room.roomport)+'Replay.yrp') then
                        copyfile(pchar(ExtractFilePath(ParamStr(0))+'replay\'+inttostr(room.roomport)+'Replay.yrp'),
                        pchar(ExtractFilePath(ParamStr(0))+'replay_all\'+tmpstr+' '+room.player1+' VS '+room.player2+' '+inttostr(room.winner)+' '+inttostr(room.wincause)+'.yrp'),false);
                    end;
                  end;
                  room.recorded:=true;
              end;
            finally
               LeaveCriticalSection(sys_LOCKFile);
            end;  
          end;
        end;
        if room<>nil then
          peersendstream(userinfo,peerTcpClient,stream);

  finally
    stream.Free;
  end;
end;

end.
