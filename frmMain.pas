unit frmMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IdSocketHandle, IdBaseComponent, IdComponent, IdUDPBase,
  IdUDPServer, StdCtrls, IdGlobal, IdContext, IdCustomTCPServer,
  IdTCPServer,shellapi,sys,IdBuffer, IdTCPConnection,
  IdTCPClient, IdHTTP, IdCustomHTTPServer, IdHTTPServer,IdThreadComponent,
  ExtCtrls, IdIntercept, IdServerInterceptLogBase, IdServerInterceptLogFile,
  ygo_server_userinfo,TLHelp32, IdDNSResolver,winsock,IdSync,
  IdMappedPortTCP, Crypt, StrUtils ,DateUtils;
const
  CVN_NewCopy = wm_user +200;
type
  TForm1 = class(TForm)
    IdTCPServer1: TIdTCPServer;
    Memo1: TMemo;
    IdHTTPServer1: TIdHTTPServer;
    Panel1: TPanel;
    breg: TButton;
    bserver: TButton;
    eserverpost: TEdit;
    bserverpost: TButton;
    barena: TButton;
    bmaskroom: TButton;
    Button1: TButton;
    Button2: TButton;
    ebroadcast: TEdit;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    procedure IdTCPServer1Execute(AContext: TIdContext);
    procedure IdTCPServer2Execute(AContext: TIdContext);
    procedure FormCreate(Sender: TObject);
    procedure IdTCPServer1Connect(AContext: TIdContext);
    procedure FormDestroy(Sender: TObject);
    procedure IdTCPServer1Disconnect(AContext: TIdContext);
    procedure IdTCPServer1Exception(AContext: TIdContext;
      AException: Exception);
    procedure IdHTTPServer1CommandGet(AContext: TIdContext;
      ARequestInfo: TIdHTTPRequestInfo;
      AResponseInfo: TIdHTTPResponseInfo);
    procedure bserverpostClick(Sender: TObject);
    procedure barenaClick(Sender: TObject);
    procedure refUI;
    procedure bmaskroomClick(Sender: TObject);
    procedure bregClick(Sender: TObject);
    procedure bserverClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
  private
    { Private declarations }
    function replacename(str:string):string;
  public
    { Public declarations }
    exepath:string;
    canregist:boolean;
    iskeepversion:boolean;
    lasthttpget:tdatetime;
    lastjsonget:tdatetime;
    lasthttpgetString,lastjsongetstring_delphi,lastjsongetString:string;
    needcache:boolean;
  end;

var
  Form1: TForm1;
  isSTART:boolean;
  serverpost:string;
  roomlists:tstringlist;

implementation
uses ygo_client_protocol,messageSend, messagePackage, IpRtrMib, IPFunctions, IniFiles;
{$R *.dfm}

//转换
function Str_Gb2UniCode(text: string;aw:boolean): String;
var
  i,len: Integer;
  cur: Integer;
  t: String;
  ws: WideString;
begin
  if not aw then
  begin
    Result:=text;
    exit;
  end;
  Result := '';
  ws := text;
  len := Length(ws);
  i := 1;
  while i <= len do
  begin
    cur := Ord(ws[i]);
    FmtStr(t,'%4.4X',[cur]);
    Result := Result + t;
    Inc(i);
  end;
end;





function showusername(user:tuserinfo):string;
begin
  if g_userlist.Count>0 then
  begin
    if user.isUserInList then
       result:='<font color="blue">'+user.username+'</font>'
    else
       result:='<font color="gray">'+user.username+'(未认证)</font>'
  end
  else
    result:=user.username;
end;

function getPort: integer;
var
  randomport:integer;
  retrycount:integer;
  function checkrandomport(ran:integer):boolean;
  var idtcpserver:tidtcpserver;
  begin
     idtcpserver:=tidtcpserver.Create(nil);
     try
      try
        idtcpserver.DefaultPort:=ran;
        idtcpserver.OnExecute:=Form1.IdTCPServer2Execute;
        idtcpserver.Active:=true;
        idtcpserver.Active:=false;
      except
        result:=false;
        exit;
      end;
      result:=true;
     finally
      idtcpserver.Free;
     end;
  end;
  const maxport=19000;
        minport=11000;
  function getarandomint():integer;
  begin
     Randomize;
     result:=0;
     while (result>maxport) or (result<minport) do
      result:=Random(maxport);
  end;
begin
  randomport:=getarandomint;
  retrycount:=0;
  while (not checkrandomport(randomport)) do
  begin
    inc(retrycount);
    if retrycount>100 then
    begin
      result:=0;
      exit;
    end;
    randomport:=getarandomint;
  end;
  result:=randomport;
end;

procedure JoinRoom(acontext:tuserinfo);
var tmproom:troom;
    i:integer;
    rule,mode:char;
    enable_priority,no_check_deck,no_shuffle_deck:string[1];
    start_lp,start_hand,draw_count:integer;
    tmpstr:string;
    strlist:tstringlist;
    exepath,exeparms,exedir:pchar;
    startupInfo :TStartupInfo;
    procedure analyzeRoom(tmproom:troom);
    begin
          rule:='0';
          mode:='0';
          enable_priority:='F';
          no_check_deck:='F';
          no_shuffle_deck:='F';
          start_lp:=8000;
          start_hand:=5;
          draw_count:=1;
          tmproom.isshow:=true;
          tmproom.ismarch:=false;
          //roomname:='00ttt5000,5,1,asd';
          //确定房间类型、模式、自定义
          if copy(acontext.roomname,0,2)='T#' then
          begin
             mode:='2';
          end;
          if copy(acontext.roomname,0,2)='M#' then
          begin
             mode:='1';
          end;
          if pos('$',acontext.roomname)>0 then
            tmproom.isprivate:=true
          else
            tmproom.isprivate:=false;
          if copy(acontext.roomname,0,2)='P#' then
          begin
             tmproom.ismarch:=true;
          end;
          if copy(acontext.roomname,0,3)='PM#' then
          begin
             tmproom.ismarch:=true;
             mode:='1';
          end;

         //确定房间的JSON名
          if tmproom.isprivate then
            tmproom.roomname_json:=copy(tmproom.roomname_real,0,pos('$',tmproom.roomname_real)-1)
          else
            tmproom.roomname_json:=tmproom.roomname_real;

        //显示
        if maskRoom then
        begin
          if length(tmproom.roomname_json)>6 then
            tmproom.roomname_html:=copy(tmproom.roomname_json,0,6)+'...(<font color="red" title="'+tmproom.roomname_real+'">详</font>)'
          else
            tmproom.roomname_html:=copy(tmproom.roomname_json,0,6);
        end
        else
          tmproom.roomname_html:=tmproom.roomname_json;
        //模式
        if tmproom.ismarch then
        begin
           tmproom.roomname_html:=tmproom.roomname_html+'<font color="d28311" title="竞技场模式">[竞]</font>'
        end;
        //私有
        if tmproom.isprivate then
        begin
           tmproom.roomname_html:=tmproom.roomname_html+'<font color="red" title="密码房间">[密]</font>'
        end;
        
         //自定义 
          if length(acontext.roomname)>13 then
          begin
             tmpstr:=copy(acontext.roomname,6,length(acontext.roomname));
             strlist:=tstringlist.Create;
             try
                try
                 strlist.DelimitedText:=tmpstr;
                 strlist.Delimiter:=',';
                 start_lp:=strtoint(strlist[0]);
                 start_hand:=strtoint(strlist[1]);
                 draw_count:=strtoint(strlist[2]);
                 rule:=acontext.roomname[1];
                 mode:=acontext.roomname[2];
                 enable_priority:=uppercase(acontext.roomname[3]);
                 no_check_deck:=uppercase(acontext.roomname[4]);
                 no_shuffle_deck:=uppercase(acontext.roomname[5]);
                except
                    rule:='0';
                    mode:='0';
                    enable_priority:='F';
                    no_check_deck:='F';
                    no_shuffle_deck:='F';
                    start_lp:=8000;
                    start_hand:=5;
                    draw_count:=1;
                end;
             finally
                strlist.Free;
             end;
          end;
    end;
begin
  if not tuserinfo(acontext).Connection.Connected then
     exit;

  if tuserinfo(acontext).isbaned then exit;

  EnterCriticalSection(sys_LOCKroom);
  try
    //找房间
    for i:=0 to HASH_ROOM.Count-1 do
    begin
        if troom(HASH_room[I]).roomname_real=acontext.roomname then
        begin
          //竞技场非注册不得进入
          if troom(HASH_room[I]).ismarch and (not tuserinfo(acontext).isUserInList) then
          begin
            tuserinfo(acontext).postandexit('竞技场非注册用户不能加入');
            exit;
          end;
          //如果决斗已经开始则退出
          if troom(HASH_room[I]).duelstart then
          begin
           tuserinfo(acontext).postandexit('决斗已开始，无法加入');
           exit;
          end;
          //否则添加用户信息
          tmproom:=HASH_room[I];
          tmproom.userlist.Add(acontext);
          acontext.room:=HASH_room[I];
          exit;
        end;
    end;

    if not tuserinfo(acontext).isUserInList and (g_userlist.Count>0) then
    begin
       tuserinfo(acontext).postandexit('非注册用户不能建房');
       exit;
    end;
    //找不到
    if acontext.room=nil then
    begin
        //建房间
        tmproom:=troom.Create(form1);
        try
          tmproom.roomname_real:=acontext.roomname;
          analyzeRoom(tmproom);
          tmproom.roomport:=getPort;
          if tmproom.roomport=0 then
          begin
            tmproom.free;
            exit;
          end;
          tmproom.creator:=acontext;
 
          //need
          tmpstr:= inttostr(tmproom.roomport)+' 0 '+rule+' '+mode+' '+enable_priority+' '
                          +no_check_deck+' '+no_shuffle_deck+' '+inttostr(start_lp)+' '+inttostr(start_hand)+' '+inttostr(draw_count);
          //roomlists.Add(tmpstr);
          //postmessage(form1.Handle,CVN_NewCopy,0,0);
          exepath:=pchar(ExtractFilePath(ParamStr(0))+'ygocore.exe');
          exeparms:=pchar(inttostr(tmproom.roomport)+' 0 '+rule+' '+mode+' '+enable_priority+' '
                          +no_check_deck+' '+no_shuffle_deck+' '+inttostr(start_lp)+' '+inttostr(start_hand)+' '+inttostr(draw_count));
          exedir:=pchar(ExtractFilePath(ParamStr(0)));

          FillChar(startupInfo,sizeof(StartupInfo),0);

          //创建一个YGOCORE副本
          if not CreateProcess(nil,pchar(exepath+' '+exeparms),Nil,Nil,True,CREATE_NO_WINDOW,Nil,exedir,startupInfo,tmproom.roomprocess) then
          begin
            tmproom.Free;
            form1.Memo1.Lines.Add('room create fail');
            acontext.room:=nil;
            exit;
          end;   
                     
          HASH_room.Add(tmproom);
          tmproom.userlist:=tlist.Create;
          tmproom.userlist.Add(acontext);
          acontext.room:=tmproom;
        except
          acontext.room:=nil;
          tmproom.Free;
        end;
    end;
  finally
    LeaveCriticalSection(sys_LOCKroom);
  end;
end;




procedure TForm1.IdTCPServer1Execute(AContext: TIdContext);
var i:integer;
    stream:tmemorystream;
    recv:pointer;
    buff:TIdBytes;
    name,pass:string;
    //maincardnum,sidebum:integer;
begin
    AContext.Connection.IOHandler.ReadBytes(buff,2,false);
    i:=BytesToWord(buff);
    stream:=tmemorystream.Create;
    try
        assert(i<2000);
        AContext.Connection.IOHandler.ReadStream(stream,i);
        recv:=stream.Memory;
        if tuserinfo(acontext).isbaned then exit;
        case ord(tpackage(recv^).protocolhead1) of
          CTOS_PLAYER_INFO://第一个包，用户信息
          begin
            tuserinfo(AContext).username:=tDuelPlayer(recv^).name;
            if g_userlist.Count>0 then//如果需要做实名认证
            begin
                //获取用户信息
                try
                  i:=pos('$',tuserinfo(AContext).username);
                  if i=0 then//找不到密码就不认证
                     tuserinfo(AContext).isUserInList:=false;
                  if i>0 then
                  begin
                      name:=copy(tuserinfo(AContext).username,0,i-1);
                      pass:=copy(tuserinfo(AContext).username,i+1,length(tuserinfo(AContext).username)-1);
                      tuserinfo(AContext).username:=replacename(name);
                      tuserinfo(AContext).uerpass:=encryptString(pass);
                      if  tuserinfo(AContext).uerpass='' then
                      begin
                        tuserinfo(acontext).postandexit('无法通过认证，请确认后重连');
                        exit;
                      end;

                      if g_userlist.values[tuserinfo(AContext).username]<>tuserinfo(AContext).uerpass then
                      begin
                         tuserinfo(acontext).postandexit('无法通过认证，请确认后重连');
                         exit;
                      end;
                      tuserinfo(AContext).isUserInList:=true;
                      StringToWideChar(tuserinfo(AContext).username,tDuelPlayer(recv^).name,19);
                  end;
                except
                  tuserinfo(AContext).isUserInList:=false;
                end;
            end;
            move(recv^,tuserinfo(AContext).userlogininfo,41);//记录下登录的包
          end;
          //加入一个游戏
          CTOS_JOIN_GAME://第二个包，加入游戏，使用密码作为房间名
          begin
            if not tuserinfo(acontext).connected then exit; 
            //Memo1.Lines.Add(tDuelRoom(recv^).password2name);
            //版本确认102C
            //showmessage(inttostr(ord(tDuelRoom(recv^).seed[0])));
            if not ((ord(tDuelRoom(recv^).seed[1])=18)
              and (ord(tDuelRoom(recv^).seed[0])=208)) then
            begin
              tuserinfo(acontext).postandexit('版本102D0，请确认');
              //memo1.Lines.Add(tuserinfo(AContext).username+'dissconnect 版本不正确');
             // acontext.Connection.Disconnect;
              exit;
            end;
            tuserinfo(AContext).roomname:= replacename(tDuelRoom(recv^).password2name);
            if tuserinfo(AContext).roomname='' then
            begin
              //memo1.Lines.Add(tuserinfo(AContext).username+'dissconnect cause noroomname');
              tuserinfo(acontext).postandexit('房间为空，请修改房间名');
              exit;
            end;
            //开始查找房间，如果找不到就创建一个
            JoinRoom(tuserinfo(AContext));
            sleep(500);
            //ygocore.exe 7933 0 0 t t t 1000 1 1
            if tuserinfo(AContext).room=nil then exit;
            //创建一个TCP客户端
            try
              tuserinfo(AContext).CreateRoomClient;
            except
              exit;
            end;
          end;
        end;
        //把当前的包发给副本服务器
        if assigned(tuserinfo(AContext).peerTcpClient) then
          if tuserinfo(AContext).peerTcpClient.Connected then
            sendstream(tuserinfo(AContext).peerTcpClient,tuserinfo(AContext).sendlock,stream);
    finally
      stream.Free;
    end;
end;

procedure TForm1.IdTCPServer2Execute(AContext: TIdContext);
begin
   AContext.Connection.Disconnect;
end;

function HostToIP(Name: string; var Ip: string): Boolean;   //hosttoip 函数作用是将域名解析成ip
var
wsdata : TWSAData;
hostName : array [0..255] of char;
hostEnt : PHostEnt;
addr : PChar;
begin
WSAStartup ($0101, wsdata);
try
    gethostname (hostName, sizeof (hostName));
    StrPCopy(hostName, Name);
    hostEnt := gethostbyname (hostName);
    if Assigned (hostEnt) then
      if Assigned (hostEnt^.h_addr_list) then begin
        addr := hostEnt^.h_addr_list^;
        if Assigned (addr) then begin
          IP := Format ('%d.%d.%d.%d', [byte (addr [0]),
          byte (addr [1]), byte (addr [2]), byte (addr [3])]);
          Result := True;
        end
        else
          Result := False;
      end
      else
        Result := False
    else begin
      Result := False;
    end;
finally
    WSACleanup;
end
end;



procedure TForm1.FormCreate(Sender: TObject);
var strlist:tstringlist;
begin
  iskeepversion:=false;
  canregist:=false;
  isarena:=false;
  exepath:= ExtractFilePath(Application.ExeName);
  Idtcpserver1.ContextClass:=tuserinfo;
  InitializeCriticalSection(sys_LOCKroom);
  InitializeCriticalSection(sys_LOCKFile);
  g_userlist:=tstringlist.Create;
  if fileexists(exepath+'userlist.conf') then
  g_userlist.LoadFromFile(exepath+'userlist.conf');
  lasthttpget:=now();
  lastjsonget:=now();
  needcache:=true;
  

  HASH_ROOM:=tlist.Create;
  isSTART:=true;
  if fileexists(exepath+'server.conf') then
  begin
    try
       strlist:=tstringlist.Create;
       try
           strlist.LoadFromFile(exepath+'server.conf');
           if strlist.Values['canRegist']<>'' then
           canregist:=strtobool(strlist.Values['canRegist']);
           serverPort:=strtoint(strlist.Values['serverPort']);
           serverHTTPPort:=strtoint(strlist.Values['serverHTTPPort']);
           serverDisplayIP:=strlist.Values['serverDisplayIP'];
           historyPublicURL:=strlist.Values['historyPublicURL'];
           serverLogo :=strlist.Values['serverLogo'];
           managepass:=strlist.Values['managepass'];
           maxuser:=strtoint(strlist.Values['maxuser']);
           serverURL:=strlist.Values['serverURL'];
           needcache:=strtobool(strlist.Values['needHttpCache']);
           if managepass='' then managepass:='showme';
         
           if uppercase(strlist.Values['maskRoom'])='TRUE' then
              maskRoom:=true
           else
              maskRoom:=false;
              
           if uppercase(strlist.Values['recordReplay'])='TRUE' then
              needrecordReplay:=true
           else
              needrecordReplay:=false;
       finally
          strlist.Free;
       end;
    except
      showmessage('配置文件存在错误');
      exit;
    end;
  end;
  if serverDisplayIP='' then
    HostToIP(serverURL,serverDisplayIP);

  Idtcpserver1.DefaultPort:=serverPort;
  IdHTTPServer1.DefaultPort:=serverHTTPPort;
  Idtcpserver1.Active:=true;
  IdHTTPServer1.Active:=true;
  refui;
  memo1.Lines.Add('对战服务启动于:'+inttostr(serverport));
  memo1.Lines.Add('WEB服务启动于:'+inttostr(serverHTTPport));
  memo1.Lines.Add('队标等信息在配置文件:server.conf修改相应配置');
  memo1.Lines.Add('第一个用户注册后场地|公会服务生效');
  memo1.Lines.Add('注册页面模板为:regist.html，请另找空间安置');
  memo1.Lines.Add('修改其中的: var serverurl=''http://127.0.0.1:7922/''为本队服务器对应的HTTP服务');
  memo1.Lines.add('其他配置请先详细阅读帮助文档，有任何不清楚的地方请GOOGLE，不解释');
end;

procedure TForm1.IdTCPServer1Connect(AContext: TIdContext);
begin
  tuserinfo(acontext).connected:=false;
  if sys_LOCKroom.LockCount>4 then
  begin
    tuserinfo(acontext).postandexit('服务器正忙，请稍后重连');
    exit;
  end;
  
  tuserinfo(acontext).connected:=true;

  if not isSTART then
  begin
    tuserinfo(acontext).postandexit('服务器暂停建房');
    sleep(3000);
    tuserinfo(acontext).Connection.Disconnect;
    exit;
  end;

  if HASH_ROOM.Count>maxuser then
  begin
    tuserinfo(acontext).postandexit('服务器超负');
    exit;
  end;
  tuserinfo(acontext).Connection.Socket.ReadTimeout:=1800000;
  tuserinfo(acontext).Connection.Socket.UseNagle:=false;
end;

procedure TForm1.IdTCPServer1Disconnect(AContext: TIdContext);
var i:integer;
f:TFormatSettings;
begin
      if not tuserinfo(acontext).connected then exit;
      tuserinfo(AContext).connected:=false;
      tuserinfo(AContext).isbaned:=true;

      EnterCriticalSection(sys_LOCKroom);
      try
         if assigned(tuserinfo(Acontext).room) then
         if tuserinfo(AContext).room<>nil then  //删除房间的用户列表中对应的用户信息
         begin
           if tuserinfo(AContext).room.userlist<>nil then
           begin
            //删除房间的本用户信息
            tuserinfo(AContext).room.userlist.Remove(Acontext);
            tuserinfo(AContext).room.userlist.pack;
           end;
          if tuserinfo(acontext).room.creator = acontext then   //房间的创建者，则释放所有的房间资源
          begin
              //杀掉进程
              TerminateProcess(tuserinfo(AContext).room.roomprocess.hProcess,0);

              //总表中移除本房间
              HASH_ROOM.Remove(tuserinfo(AContext).room);
              HASH_ROOM.Pack;

              //释放ROOM资源
              for i:=0 to tuserinfo(AContext).room.userlist.Count-1 do
              begin//所有用户房间置空
                 if tuserinfo(tuserinfo(AContext).room.userlist[i]).Connection.Connected then
                    tuserinfo(tuserinfo(AContext).room.userlist[i]).Connection.Disconnect;
                 tuserinfo(tuserinfo(AContext).room.userlist[i]).room:=nil;
              end;
              //删除临时replay
             if tuserinfo(AContext).room.duelstart then
              if not tuserinfo(AContext).room.recorded then
                if DirectoryExists(ExtractFilePath(ParamStr(0))+'replay_error\') then
                   if fileexists(ExtractFilePath(ParamStr(0))+'replay\'+inttostr(tuserinfo(AContext).room.roomport)+'Replay.yrp') then
                   begin
                      f.ShortDateFormat:='yyyy-MM-dd';
                      f.LongTimeFormat:='hh-mm-ss-ZZZ';
                      copyfile(pchar(ExtractFilePath(ParamStr(0))+'replay\'+inttostr(tuserinfo(AContext).room.roomport)+'Replay.yrp'),
                      pchar(ExtractFilePath(ParamStr(0))+'replay_error\'+datetimetostr(now(),f)+'='
                      +tuserinfo(AContext).room.player1+'='+tuserinfo(AContext).room.player2
                      +'='+booltostr(tuserinfo(AContext).room.player1reg)+'='+booltostr(tuserinfo(AContext).room.player2reg)
                      +'='+inttostr(tuserinfo(AContext).room.winner)+'='+inttostr(tuserinfo(AContext).room.wincause)+'.yrp'),false);
                   end;
                                                          
              if fileexists(ExtractFilePath(ParamStr(0))+'replay\'+inttostr(tuserinfo(AContext).room.roomport)+'Replay.yrp') then
                  deletefile(ExtractFilePath(ParamStr(0))+'replay\'+inttostr(tuserinfo(AContext).room.roomport)+'Replay.yrp');
              //释放用户列表
              freeandnil(tuserinfo(AContext).room.userlist);
              //释放本房间
              freeandnil(tuserinfo(AContext).room);
          end;
         end;
      finally
         leaveCriticalSection(sys_LOCKroom);
      end;
end;

procedure TForm1.IdTCPServer1Exception(AContext: TIdContext;
  AException: Exception);
begin
  //memo1.Lines.Add(datetimetostr(now())+tuserinfo(AContext).username+'error diss:'+AException.Message);
  AContext.Connection.Disconnect;
end;

procedure TForm1.IdHTTPServer1CommandGet(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
  var i,j,hiddennum:integer;
      transcode:boolean;
begin
      hiddennum:=0;//需要隐藏的房间号
      //解析
      AResponseInfo.ContentType:='text/html';
      if ARequestInfo.Params.Values['operation']='passcheck' then
      begin
         if g_userlist.Values[utf8toansi(ARequestInfo.Params.Values['username'])]=EncryptString(ARequestInfo.Params.Values['pass']) then
              AResponseInfo.ContentText:='true'
         else
              AResponseInfo.ContentText:='false';
         exit;
      end;

      if (ARequestInfo.Params.Values['operation']='getroomjson') or (ARequestInfo.Params.Values['operation']='getroomjsondelphi') then
      begin
         if ARequestInfo.Params.Values['operation']='getroomjsondelphi' then
             transcode:=true;

         if (SecondsBetween(now,lastjsonget)<2) and needcache then
         begin
            if transcode then
              AResponseInfo.ContentText:=lastjsongetstring
            else
              AResponseInfo.ContentText:=lastjsongetstring_delphi;
            exit;
         end;
         
         if tryEnterCriticalSection(sys_LOCKroom) then
         begin
             try
                AResponseInfo.ContentText:='{"rooms":[';
                for i:= hash_room.Count-1 downto 0 do
                begin
                    //是否显示房间的处理
                    if troom(HASH_room[I]).roomport=hiddennum then troom(HASH_room[I]).isshow:=false;
                    if not troom(HASH_room[I]).isshow then continue;
                    if i<hash_room.Count-1 then AResponseInfo.ContentText:=AResponseInfo.ContentText+',';
                    AResponseInfo.ContentText:=AResponseInfo.ContentText+'{"roomid":"'+inttostr(troom(HASH_room[I]).roomport)
                            +'","roomname":"'+Str_Gb2UniCode(troom(HASH_room[I]).roomname_json,transcode)+'"';
                    if troom(HASH_room[I]).isprivate then
                      AResponseInfo.ContentText:=AResponseInfo.ContentText+',"needpass":"true"'
                    else
                      AResponseInfo.ContentText:=AResponseInfo.ContentText+',"needpass":"false"';
                      
                    AResponseInfo.ContentText:=AResponseInfo.ContentText+',"users":[';
                    for j:=0 to troom(HASH_room[I]).userlist.Count-1 do
                    begin
                      if j>0 then AResponseInfo.ContentText:=AResponseInfo.ContentText+',';
                      
                       AResponseInfo.ContentText:=AResponseInfo.ContentText+'{"id":"'+booltostr(tuserinfo(troom(HASH_room[I]).userlist[j]).isUserInList);
                       AResponseInfo.ContentText:=AResponseInfo.ContentText+'","name":"'+Str_Gb2UniCode(tuserinfo(troom(HASH_room[I]).userlist[j]).username,transcode);
                       AResponseInfo.ContentText:=AResponseInfo.ContentText+'","pos":"'+inttostr(tuserinfo(troom(HASH_room[I]).userlist[j]).pos)+'"}';
                    end;
                    AResponseInfo.ContentText:=AResponseInfo.ContentText+']';

                    if troom(HASH_room[I]).duelstart then
                       AResponseInfo.ContentText:=AResponseInfo.ContentText+',"istart":"start"}'
                    else
                       AResponseInfo.ContentText:=AResponseInfo.ContentText+',"istart":"wait"}';
                end;
                AResponseInfo.ContentText:=AResponseInfo.ContentText+']}';
                if transcode then
                  lastjsongetstring:=AResponseInfo.ContentText
                else
                  lastjsongetstring_delphi:=AResponseInfo.ContentText;
                lastjsonget:=now();
               // AResponseInfo.ContentText:=UnicodeEncode(AResponseInfo.ContentText,CP_OEMCP);
             finally
                 leaveCriticalSection(sys_LOCKroom);
             end;
         end
         else
           AResponseInfo.ContentText:='[server busy]';
         exit;
      end;

      //管理段
      if ARequestInfo.Params.Values['pass']=managepass then
      begin
        if ARequestInfo.Params.Values['operation']='close' then
        begin
           isSTART:=false;
           AResponseInfo.ContentText:='服务器建房关闭';
           exit;
        end;

        if ARequestInfo.Params.Values['operation']='forceuserpass' then
        begin
           ARequestInfo.Params.Values['username']:=replaceName(ARequestInfo.Params.Values['username']);

           g_userlist.Values[utf8toansi(ARequestInfo.Params.Values['username'])]:=EncryptString(ARequestInfo.Params.Values['password']);
            caption:=g_userlist.Values[utf8toansi(ARequestInfo.Params.Values['username'])];
           AResponseInfo.ContentText:='ok';
           exit;
        end;

        if ARequestInfo.Params.Values['operation']='serverpost' then
        begin
          serverpost:=utf8toansi(ARequestInfo.Params.Values['serverpost']);   
        end;

        if ARequestInfo.Params.Values['operation']='start' then
        begin
           isSTART:=true;
           AResponseInfo.ContentText:='服务器建房开启';
           exit;
        end;

        if ARequestInfo.Params.Values['operation']='maskroom' then
        begin
           maskRoom:=true;
           AResponseInfo.ContentText:='命名管制开启';
           exit;
        end;

        if ARequestInfo.Params.Values['operation']='unmuskroom' then
        begin
           maskRoom:=false;
           AResponseInfo.ContentText:='命名管制关闭';
           exit;
        end;

        if ARequestInfo.Params.Values['operation']='reloaduser' then
        begin
           g_userlist.Clear;
           if fileexists(exepath+'userlist.conf') then
              g_userlist.LoadFromFile(exepath+'userlist.conf');
           AResponseInfo.ContentText:='用户重载完成';
           exit;
        end;

        if ARequestInfo.Params.Values['operation']='saveuser' then
        begin
           if iskeepversion then exit;
           g_userlist.SaveToFile(exepath+'userlist.conf');
           AResponseInfo.ContentText:='用户保存完成';
           exit;
        end;
        
        if ARequestInfo.Params.Values['operation']='openreg' then
        begin
           if iskeepversion then exit;
           canregist:=true;
           AResponseInfo.ContentText:='服务器注册开启';
           exit;
        end;

        if ARequestInfo.Params.Values['operation']='arenastart' then
        begin
            if iskeepversion then exit;
            isarena:=true;
            AResponseInfo.ContentText:='场地|竞技场效果发动';
            exit;
        end;

        if ARequestInfo.Params.Values['operation']='arenastop' then
        begin
            if iskeepversion then exit;
            isarena:=false;
            AResponseInfo.ContentText:='场地|竞技场效果关闭';
            exit;
        end;

        if ARequestInfo.Params.Values['operation']='closereg' then
        begin
           if iskeepversion then exit;
           canregist:=false;
           AResponseInfo.ContentText:='服务器注册关闭';
           exit;
        end;

        if ARequestInfo.Params.Values['operation']='hiddenroom' then
        begin
           if ARequestInfo.Params.Values['roomid']<>'' then
           begin
               try
                  hiddennum:=strtoint(ARequestInfo.Params.Values['roomid']);
               except
               end;
           end;
        end;
      end;
      if ARequestInfo.Params.Values['pass']<>'' then
        if ARequestInfo.Params.Values['pass']<>managepass then
        begin
           AResponseInfo.ContentText:='密码错误';
           exit;
        end;
  //注册段
       if ARequestInfo.Params.Values['userregist']<>'' then
       begin
          if not canregist then
          begin
              AResponseInfo.ContentText:='用户注册禁止';
              exit;
          end;
          
          if uppercase(ARequestInfo.Params.Values['userregist'])='NEW' then
          begin
              if g_userlist.Values[utf8toansi(ARequestInfo.Params.Values['username'])]<>'' then
              begin
                  AResponseInfo.ContentText:='用户已存在';
                  exit;
              end;
              if (ARequestInfo.Params.Values['username']<>'') and (ARequestInfo.Params.Values['password']<>'') then
              begin
                ARequestInfo.Params.Values['username']:=replaceName(ARequestInfo.Params.Values['username']);
                g_userlist.Values[utf8toansi(ARequestInfo.Params.Values['username'])]:=EncryptString(ARequestInfo.Params.Values['password']);
                AResponseInfo.ContentText:=ARequestInfo.Params.Values['username']+'注册成功';
                g_userlist.SaveToFile(exepath+'userlist.conf');
                exit;
              end
              else
              begin
                AResponseInfo.ContentText:='注册失败';
                exit;
              end;
          end;
          if uppercase(ARequestInfo.Params.Values['userregist'])='CHANGEPASS' then
          begin
             if g_userlist.Values[utf8toansi(ARequestInfo.Params.Values['username'])]<>EncryptString(ARequestInfo.Params.Values['oldpass']) then
             begin
                  AResponseInfo.ContentText:='用户名密码不匹配';
                  exit;
             end
             else
             begin
                g_userlist.Values[utf8toansi(ARequestInfo.Params.Values['username'])]:=EncryptString(ARequestInfo.Params.Values['password']);
                AResponseInfo.ContentText:='修改成功';
                exit;
             end;
          end;
       end;
  if ARequestInfo.Params.Values['adv']<>'' then
  begin
     AResponseInfo.ContentText:='<head>'+#10#13
          +'<meta http-equiv="Content-Type" content="text/html; charset=gb2312" />'+#10#13
          +'<meta name ="keywords" content="游戏王,自动化对战,服务器,公会对战平台,游戏,卡牌游戏,卡组分析"> '+#10#13
          +'<title>DUEL SERVER</title>'+#10#13
          +'</head>'+#10#13;
     AResponseInfo.ContentText:=AResponseInfo.ContentText+'<div style="width:468px;position:absolute; left:0px; top:0px; height:100px;">'+#10#13;
      AResponseInfo.ContentText:=AResponseInfo.ContentText+'<script type="text/javascript"><!--'+#10#13
          +'google_ad_client = "ca-pub-9520543693264555";'+#10#13
          +'/* YGOad */'+#10#13
          +'google_ad_slot = "2745459735";'+#10#13 
          +'google_ad_width = 468;'+#10#13
          +'google_ad_height = 60;'+#10#13
          +'//-->'+#10#13
          +'</script>'+#10#13
          +'<script type="text/javascript" src="http://pagead2.googlesyndication.com/pagead/show_ads.js">'+#10#13
          +'</script></div>'+#10#13;
      exit;
  end;

   if (SecondsBetween(now,lasthttpget)<2) and needcache then
   begin
      AResponseInfo.ContentText:=lasthttpgetstring;
      exit;
   end;

  //服务器状态显示
  if tryEnterCriticalSection(sys_LOCKroom) then
  begin
       try
        AResponseInfo.ContentText:='<head>'+#10#13
          +'<meta http-equiv="Content-Type" content="text/html; charset=gb2312" />'+#10#13
          +'<meta name ="keywords" content="游戏王,自动化对战,服务器,公会对战平台,游戏,卡牌游戏,卡组分析"> '+#10#13
          +'<title>DUEL SERVER</title>'+#10#13
          +'</head>'+#10#13;
        AResponseInfo.ContentText:=AResponseInfo.ContentText+'<div align="center"><img src="'+serverLogo+' "></img></div><div style="width:468px;position:absolute; right:10px; top:137px; height:100px;">'+#10#13;
        AResponseInfo.ContentText:=AResponseInfo.ContentText+'<script type="text/javascript"><!--'+#10#13
          +'google_ad_client = "ca-pub-9520543693264555";'+#10#13
          +'/* YGOad */'+#10#13
          +'google_ad_slot = "2745459735";'+#10#13 
          +'google_ad_width = 468;'+#10#13
          +'google_ad_height = 60;'+#10#13
          +'//-->'+#10#13
          +'</script>'+#10#13
          +'<script type="text/javascript" src="http://pagead2.googlesyndication.com/pagead/show_ads.js">'+#10#13
          +'</script></div>'+#10#13;
        AResponseInfo.ContentText:=AResponseInfo.ContentText+'<br/>当前房间数量:'+inttostr(HASH_ROOM.Count)+'/'+inttostr(maxuser)+'　　服务器地址：'+serverDisplayIP;



        if needrecordReplay then
            AResponseInfo.ContentText:=AResponseInfo.ContentText+'　　　<a href="'+historyPublicURL+'" target="_blank" style="color:red">历史对战记录</a>';

        if maskRoom then
            AResponseInfo.ContentText:=AResponseInfo.ContentText+'　　　<div style="color:red" title="命名管制模式下只显示房间和用户ID的前5位">命名管制模式</div>';

        if g_userlist.Count>0 then
            AResponseInfo.ContentText:=AResponseInfo.ContentText+'　　　<div style="color:green; float:left" title="叠放场地|公会服务：只允许通过实名认证的用户建立房间，允许和叠放场地|竞技场一起发动">[叠放场地|公会服务]</div>';

        if isarena then
            AResponseInfo.ContentText:=AResponseInfo.ContentText+'　　　<div style="color:red; float:left" title="叠放场地|竞技场：本模式下M#房间不允许录像，允许和叠放场地|公会服务一起发动">[叠放场地|竞技场]</div>';

        AResponseInfo.ContentText:=AResponseInfo.ContentText+'<br/>';

        if serverpost<>'' then
        AResponseInfo.ContentText:=AResponseInfo.ContentText+'<div style="color:red" >公告：'+serverpost+'</div>';

        if isSTART then
          AResponseInfo.ContentText:=AResponseInfo.ContentText+'服务器状态：启动'
        else
          AResponseInfo.ContentText:=AResponseInfo.ContentText+'服务器状态：关闭';
        AResponseInfo.ContentText:=AResponseInfo.ContentText+'</br>';
        AResponseInfo.ContentText:=AResponseInfo.ContentText+'<hr/>';
        for i:= hash_room.Count-1 downto 0 do
        begin
            //是否显示房间的处理
            if troom(HASH_room[I]).roomport=hiddennum then troom(HASH_room[I]).isshow:=false;
            if not troom(HASH_room[I]).isshow then continue;

            if troom(HASH_room[I]).duelstart then
                AResponseInfo.ContentText:=AResponseInfo.ContentText+'<div style="width:300px; height:150px; border:1px #ececec solid; float:left;padding:5px; margin:5px;">房间名称：'+troom(HASH_room[I]).roomname_html+' <font color=red>决斗已开始!</font>'
            else
                AResponseInfo.ContentText:=AResponseInfo.ContentText+'<div style="width:300px; height:150px; border:1px #ececec solid; float:left;padding:5px; margin:5px;">房间名称：'+troom(HASH_room[I]).roomname_html+' <font color=blue>等待</font>';
            AResponseInfo.ContentText:=AResponseInfo.ContentText+'<font size="1">(ID：'+inttostr(troom(HASH_room[I]).roomport)+')</font>';

            if assigned(troom(HASH_room[I]).userlist) then
            for j:=0 to troom(HASH_room[I]).userlist.Count -1 do
            begin
              if assigned(tuserinfo(troom(HASH_room[I]).userlist[j])) then
              begin
                  case tuserinfo(troom(HASH_room[I]).userlist[j]).pos of
                  0,16:
                     AResponseInfo.ContentText:=AResponseInfo.ContentText+'<li>===决斗1='
                    +showusername(tuserinfo(troom(HASH_room[I]).userlist[j]))+';</li>';
                  1,17:
                     AResponseInfo.ContentText:=AResponseInfo.ContentText+'<li>===决斗2='
                    +showusername(tuserinfo(troom(HASH_room[I]).userlist[j]))+';</li>';
                  else
                   AResponseInfo.ContentText:=AResponseInfo.ContentText+'<li>：：：观战：'
                    +showusername(tuserinfo(troom(HASH_room[I]).userlist[j]))+';</li>';
                   end;
              end;
            end;
            AResponseInfo.ContentText:=AResponseInfo.ContentText+'</div>';
        end;
        lasthttpgetstring:=AResponseInfo.ContentText;
        lasthttpget:=now;
      finally
         leaveCriticalSection(sys_LOCKroom);
      end;
  end
  else
    AResponseInfo.ContentText:='服务器忙，请稍侯重新刷新;';
end;


procedure TForm1.bserverpostClick(Sender: TObject);
begin
   serverpost:=eserverpost.Text;
   refui;
end;

procedure TForm1.barenaClick(Sender: TObject);
begin
  isarena:=not isarena;
  refui;
end;

procedure TForm1.refUI;
begin
  if iskeepversion then
  begin
     // breg.Visible:=false;
      Button1.Visible:=false;
      barena.Visible:=false;
  end;

  if isarena then
    barena.Caption:='竞技场已启动'
  else
    barena.Caption:='竞技场已关闭';

  if maskRoom then
    bmaskRoom.Caption:='命名管制已启动'
  else
    bmaskRoom.Caption:='命名管制已关闭';

  if canregist then
    breg.Caption:='已启用注册'
  else
    breg.Caption:='已关闭注册';

  if isSTART then
    bserver.Caption:='已启动服务'
  else
    bserver.Caption:='服务暂停';

  if needcache then
    button5.Caption:='已启用缓冲'
  else
    button5.Caption:='未启用缓冲';

  eserverpost.Text:=serverpost;
end;

procedure TForm1.bmaskroomClick(Sender: TObject);
begin
   maskRoom:=not maskRoom;
   refui;
end;

procedure TForm1.bregClick(Sender: TObject);
begin
  canregist:=not canregist;
  refui;
end;

procedure TForm1.bserverClick(Sender: TObject);
begin
  isSTART:=not isSTART;
  refui;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  if g_userlist.Count>0 then
   g_userlist.SaveToFile(exepath+'userlist.conf');
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  shellexecute(form1.Handle,'open',pchar('http://127.0.0.1:'+inttostr(serverHTTPPort)),'',nil,0);
end;
procedure TForm1.FormDestroy(Sender: TObject);
begin
  if g_userlist.Count>0 then
   g_userlist.SaveToFile(exepath+'userlist.conf');
   g_userlist.Free;
   //DeleteCriticalSection(sys_LOCKroom);
   //DeleteCriticalSection(sys_LOCKFile);
end;
function TForm1.replacename(str: string):string;
begin
  result:=str;
  result:=AnsiReplaceText(result,'"','');
  result:=AnsiReplaceText(result,'<','');
  result:=AnsiReplaceText(result,'>','');
  result:=AnsiReplaceText(result,'/','');
  result:=AnsiReplaceText(result,'\','');
  result:=AnsiReplaceText(result,' ','');
end;

procedure TForm1.Button3Click(Sender: TObject);
var i,j:integer;
    stream:tmemorystream;
    charinfo:array[0..254] of WideChar;
begin
    //charinfo.protocolhead1:=char(STOC_CHAT);

    StringToWideChar(ebroadcast.Text,@charinfo[0],250);
    EnterCriticalSection(sys_LOCKroom);
    
    try
    for i:= hash_room.Count-1 downto 0 do
        begin
            //是否显示房间的处理
            if assigned(troom(HASH_room[I]).userlist) then
            for j:=0 to troom(HASH_room[I]).userlist.Count -1 do
            begin
              if assigned(tuserinfo(troom(HASH_room[I]).userlist[j])) then
              begin
                  sendchat(tuserinfo(troom(HASH_room[I]).userlist[j]),char(STOC_CHAT),@charinfo,250);
//                sendstream(tuserinfo(troom(HASH_room[I]).userlist[j]).peerTcpClient,tuserinfo(troom(HASH_room[I]).userlist[j]).sendlock,stream);
              end;
            end;
        end;
      finally
         leaveCriticalSection(sys_LOCKroom);
      end;

end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  g_userlist.LoadFromFile(exepath+'userlist.conf');
end;

procedure TForm1.Button5Click(Sender: TObject);
begin
  needcache:=not needcache;
  refui;
end;

end.
