unit addon_serversetting;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls;

type
  TForm2 = class(TForm)
    ListView1: TListView;
    serverip: TEdit;
    serverhtmlport: TEdit;
    servergameport: TEdit;
    servermanagepass: TEdit;
    Button1: TButton;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Button2: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

implementation

{$R *.dfm}

procedure TForm2.Button1Click(Sender: TObject);
var item:tlistitem;
    i:integer;
begin
  try
    i:=strtoint(serverhtmlport.Text);
    i:=strtoint(servergameport.Text);
  except
    exit;
  end;
  item:=ListView1.Items.Add;
  item.Caption:=serverip.Text;
  item.SubItems.Add(serverhtmlport.Text);
  item.SubItems.Add(servergameport.Text);
  item.SubItems.Add(servermanagepass.Text);
  
end;

procedure TForm2.Button2Click(Sender: TObject);
begin
  if assigned(ListView1.Selected) then
      ListView1.DeleteSelected;
end;

end.
