unit ygo_server_userinfo;

interface

uses Windows,IniFiles, IdContext, Classes,messagePackage,
     idTCPClient,IdThreadComponent,IdGlobal,IdBuffer,IdCustomTCPServer,
     SysUtils,ygo_client_protocol,sys, IdTCPConnection, forms, IdYarn;


 type tRoom = class(tcomponent)
  public
    roomname_real:string[20];
    roomname_html:string;
    roomname_json:string;
    
    isprivate:boolean;
    roomport:integer;
    duelstart:boolean;
    isshow:boolean;
    creator:tidcontext;
    userlist:tlist;
    player1:string;
    player1reg:boolean;
    player2:string;
    player2reg:boolean;
    winner:integer;
    wincause:integer;
    recorded:boolean;
    ismarch:boolean;  //竞技场
    roomprocess:TProcessInformation;//exe进程信息
  end;

  type TUserInfo = class(TIdContext)
    userlogininfo:array[0..40] of char;
    username:string;
    uerpass:string;
    isUserInList:boolean;
    roomname:string;
    room:Troom;
    peerTcpClient:tidTCPClient;
    IdThreadComponent: TIdThreadComponent;
    pos:integer;//0,1,2 2=observer
    connected:boolean;
    isbaned:boolean;
    sendlock:TRTLCriticalSection;

    public
      procedure IdThreadComponent1Run(Sender: TIdThreadComponent);
      procedure IdThreadOnException(Sender: TIdThreadComponent;AException: Exception);
      procedure IdThreadComponent1Terminate(Sender: TIdThreadComponent);
      procedure IdTCPClient1Disconnected(Sender: TObject);
      procedure IdTCPClient1connected(Sender: TObject);
      procedure CreateRoomClient;
      procedure postandexit(str:string);
      constructor Create(AConnection: TIdTCPConnection; AYarn: TIdYarn;
        AList: TThreadList = nil); override;
      destructor Destroy; override;

  end;
implementation
uses frmMain,messagesend;
{ TUserInfo }


procedure TUserInfo.CreateRoomClient;
begin
    if room<>nil then
      peerTcpClient.Connect('127.0.0.1',room.roomport);

    if assigned(peerTcpClient) then
    if peerTcpClient.Connected then
    begin
      //IdThreadComponent.Start;
      sendbuffer(peerTcpClient,userlogininfo,41, sendlock);
    end;
end;

 procedure peersendstream(context: tuserinfo;sender:TIdTCPClient; stream: tmemorystream);
    var buff:tidbytes;
    begin
         stream.Position:=0;
         buff:=ToBytes(word(stream.Size));
         if not assigned(context) then
         begin
            sender.Disconnect;
            exit;
         end;
         if not tuserinfo(context).connected then exit;
         context.Connection.IOHandler.Write(buff);
         context.Connection.IOHandler.Write(stream,stream.Size,false);
    end;


procedure TUserInfo.IdThreadComponent1Run(Sender: TIdThreadComponent);
var stream:tmemorystream;
      i:integer;
      buff:TIdBytes;
      recv:pointer;
      tmpstr:string;
      f:TFormatSettings;
begin
  try
    peerTcpClient.IOHandler.ReadBytes(buff,2,false);
  except
    Sender.Terminate;
    exit;
  end;

  i:=BytesToWord(buff);
  stream:=tmemorystream.Create;
  try
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
            pos:=ord(tplayerpostion(recv^).pos);
            if (pos=0) or (pos=16) then
            begin
              room.player1:=username;
              room.player1reg:=isUserInList;
            end;
            if (pos=1) or (pos=17) then
            begin
              room.player2:=username;
              room.player2reg:=isUserInList;
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
                  f.ShortDateFormat:='yyyy-MM-dd';
                  f.LongTimeFormat:='hh-mm-ss-ZZZ';
                  //使用当前时间（精确到毫秒）作为录像的唯一ID
                  tmpstr:= datetimetostr(now(),f);
                  //战斗结束，记录录像
                  if room.ismarch then//P#开头的房间
                  begin
                    if fileexists(ExtractFilePath(ParamStr(0))+'replay\'+inttostr(room.roomport)+'Replay.yrp') then
                    begin
                        copyfile(pchar(ExtractFilePath(ParamStr(0))+'replay\'+inttostr(room.roomport)+'Replay.yrp'),
                        pchar(ExtractFilePath(ParamStr(0))+'replay_cached\'+tmpstr+'='+room.player1+'='+room.player2+'='+booltostr(room.player1reg)+'='+booltostr(room.player2reg)+'='+inttostr(room.winner)+'='+inttostr(room.wincause)+'.yrp'),false);
                    end;
                  end
                  else
                  begin
                    if DirectoryExists(ExtractFilePath(ParamStr(0))+'replay_all\') then
                    begin
                       if fileexists(ExtractFilePath(ParamStr(0))+'replay\'+inttostr(room.roomport)+'Replay.yrp') then
                          copyfile(pchar(ExtractFilePath(ParamStr(0))+'replay\'+inttostr(room.roomport)+'Replay.yrp'),
                       pchar(ExtractFilePath(ParamStr(0))+'replay_all\'+tmpstr+'='+room.player1+'='+room.player2+'='+booltostr(room.player1reg)+'='+booltostr(room.player2reg)+'='+inttostr(room.winner)+'='+inttostr(room.wincause)+'.yrp'),false);
                    end;
                  end;
                  room.recorded:=true;
              end;
            finally
               LeaveCriticalSection(sys_LOCKFile);
            end;  
          end; //case STOC_DUEL_END
        end;  //case
        if room<>nil then
          peersendstream(tuserinfo(self),peerTcpClient,stream);
     except
     end;
  finally
    stream.Free;
  end;
end;

procedure TUserInfo.IdTCPClient1Disconnected(Sender: TObject);
begin
 // self.Connection.Disconnect;
end;

procedure TUserInfo.postandexit(str: string);
var tmpjoin:tplayerjoin;
    tmpgame:tduelGameInfo;
begin
 tmpgame:=consDuelGameInfo;
 ssendto(self,char(STOC_JOIN_GAME),@tmpgame,sizeof(tDuelGameInfo));
 tmpjoin:=consplayerjoin('提示：'+str);
 ssendto(self,char(STOC_HS_PLAYER_ENTER),@tmpjoin,sizeof(tplayerjoin));
 connected:=false;
 isbaned:=true;
end;

procedure TUserInfo.IdThreadComponent1Terminate(
  Sender: TIdThreadComponent);
begin
{if assigned(peertcpclient) then
   freeandnil(peerTcpClient);}
end;


procedure TUserInfo.IdTCPClient1connected(Sender: TObject);
begin
  IdThreadComponent.Start;
end;

procedure TUserInfo.IdThreadOnException(Sender: TIdThreadComponent;
  AException: Exception);
begin
 //Application.ProcessMessages;
end;

constructor TUserInfo.Create(AConnection: TIdTCPConnection; AYarn: TIdYarn;
  AList: TThreadList);
begin
   inherited Create(AConnection, AYarn, AList);
  InitializeCriticalSection(sendlock);
  peerTcpClient:=tidtcpclient.Create(nil);
  peerTcpClient.OnDisconnected:=IdTCPClient1Disconnected;
  peerTcpClient.OnConnected:=IdTCPClient1connected;
  IdThreadComponent:=tIdThreadComponent.Create(nil);
  peerTcpClient.ReadTimeout:=1800000;
  peerTcpClient.ConnectTimeout:=1000;
  IdThreadComponent.OnRun:= IdThreadComponent1Run;
  IdThreadComponent.OnException:=IdThreadOnException;
  IdThreadComponent.FreeOnRelease;
end;

destructor TUserInfo.Destroy;
begin
      try
        DeleteCriticalSection(sendlock);
        IdThreadComponent.Terminate;
        peerTcpClient.Disconnect;
      except
      end;
      IdThreadComponent.free;
      peerTcpClient.Free;
  inherited;
end;

end.
