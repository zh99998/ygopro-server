unit uCrypt;
interface
uses
  Windows, SysUtils;
const
  C1        = 52845;
  C2        = 22719;
  CryptKey  = 72957;
  function  Encrypt(Source: array of Byte; var Dest: array of Byte; Len: Cardinal): BOOL; overload;
  function  Decrypt(Source: array of Byte; var Dest: array of Byte; Len: Cardinal): BOOL; overload;
  function  Encrypt(Source: String; var Dest: string): BOOL; overload;
  function  Decrypt(Source: String; var Dest: string): BOOL; overload;
  function  Encrypt(Source: Pchar; Dest: PChar; Len: Cardinal): BOOL; overload;
  function  Decrypt(Source: Pchar; Dest: PChar; Len: Cardinal): BOOL; overload;

implementation
function  Encrypt(Source: Pchar; Dest: PChar; Len: Cardinal): BOOL; overload;
var
  i: Integer;
  Key: Integer;
begin
  Key:=CryptKey;
  //判断数据是否正常
  if (not Assigned(Source)) or (not Assigned(Dest)) or (Len <=0) then
  begin
    Result:=False;
    Exit;
  end;
  //循环加密每一个字节
  for i:=0 to Len - 1 do
  begin
    Dest[i]:=Char(Byte(Source[i]) xor (Key shr 8));
    Key:=(Byte(Dest[i]) + Key) * C1 + C2;
  end;
  Result:=True;
end;
function  Decrypt(Source: Pchar; Dest: PChar; Len: Cardinal): BOOL; overload;
var
  i: Integer;
  Key: Integer;
  PrevBlock: Byte;
begin
  Key:=CryptKey;
  //判断数据是否正常
  if (not Assigned(Source)) or (not Assigned(Dest)) or (Len <=0) then
  begin
    Result:=False;
    Exit;
  end;
  //循环加密每一个字节
  for i:=0 to Len - 1 do
  begin
    PrevBlock:=Byte(Source[i]);
    Dest[i]:=Char(Byte(Source[i]) xor (Key shr 8));
    Key:=(Byte(PrevBlock) + Key) * C1 + C2;
  end;
  Result:=True;
end;
function  Encrypt(Source: String; var Dest: string): BOOL;
begin
  Result:=False;
  if Length(Source) > 0 then
  begin
    SetLength(Dest, Length(Source));
    Encrypt(PChar(Source), PChar(Dest), Length(Source));
    Result:=True;
  end;
end;
function  Decrypt(Source: String; var Dest: string): BOOL;
begin
  Result:=False;
  if Length(Source) > 0 then
  begin
    SetLength(Dest, Length(Source));
    Decrypt(PChar(Source), PChar(Dest), Length(Source));
    Result:=True;
  end;
end;
function  Encrypt(Source: array of Byte; var Dest: array of Byte; Len: Cardinal): BOOL;
var
  i: Integer;
  Key: Integer;
begin
  Key:=CryptKey;
  //判断数据是否正常
  if Len <= 0 then
  begin
    Result:=False;
    Exit;
  end;
  //循环加密每一个字节
  for i:=0 to Len - 1 do
  begin
    Dest[i]:=Source[i] xor (Key shr 8);
    Key:=(Dest[i] + Key) * C1 + C2;
  end;
  Result:=True;
end;
function  Decrypt(Source: array of Byte; var Dest: array of Byte; Len: Cardinal): BOOL;
var
  i: Integer;
  PrevBlock: Byte;
  Key: Integer;
begin
  Key:=CryptKey;
  //判断数据是否正常
  if (Len <= 0) then
  begin
    Result:=False;
    Exit;
  end;
  //循环解密每一个字节
  for i:=0 to Len - 1 do
  begin
    PrevBlock:=Source[i];
    Dest[i]:=Source[i] xor (Key shr 8);
    Key:=(PrevBlock + Key) * C1 + C2;
  end;
  Result:=True;
end;

end.
