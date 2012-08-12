unit sys;

interface

uses Windows,IniFiles, IdContext, Classes,messagePackage,messageSend,
     SyncObjs,idTCPClient,IdThreadComponent,IdGlobal,IdBuffer,
     SysUtils;

var
  sys_LOCKroom:TRTLCriticalSection;
  sys_LOCKFile:TRTLCriticalSection;
  HASH_ROOM:tlist;
  serverPort:integer;
  serverHTTPPort:integer;
  historyPublicURL:string;
  serverDisplayIP :string;
  serverURL:string;
  serverLogo :string;
  managepass:string;
  maxuser:integer;
  needRecordReplay,maskRoom:boolean;
  g_userlist:tstringlist;
  isarena:boolean;

implementation

end.
