program ygoServer;

uses
  Forms,
  frmMain in 'frmMain.pas' {Form1},
  ygo_client_protocol in 'ygo_client_protocol.pas',
  messageSend in 'messageSend.pas',
  messagePackage in 'messagePackage.pas',
  sys in 'sys.pas',
  ygo_server_userinfo in 'ygo_server_userinfo.pas',
  uCrypt in 'uCrypt.pas',
  addon_serversetting in 'addon_serversetting.pas' {Form2};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TForm2, Form2);
  Application.Run;
end.
