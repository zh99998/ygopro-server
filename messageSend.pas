unit messageSend;

interface
uses IdContext,Classes,IdTCPClient, IdGlobal,windows;
  type
  tprotocolpackage =packed record
    protocolhead1:Char;
    protocolhead2:Char;
    body:array[0..2048] of char;
  end;

  procedure sendbuffer(context: TIdTCPClient;  buffer: pchar;size: integer;  lock:TRTLCriticalSection );
  procedure sendstream(context: TIdTCPClient; lock:TRTLCriticalSection;  stream: tmemorystream);
  
    procedure ssendto(AContext:tIdContext;protocol:char;messages:pointer;size:integer);
    procedure sendchat(AContext:tIdContext;protocol:char;messages:pointer;size:integer);
implementation
uses sys,ygo_server_userinfo;

    procedure ssendto(AContext:tIdContext;protocol:char;messages:pointer;size:integer);
    var stream:tmemorystream;
        protocolpackage:tprotocolpackage;
    begin
        stream:=tmemorystream.Create;
        try
          protocolpackage.protocolhead1:=char(0);
          protocolpackage.protocolhead2:=protocol;
          move(messages^,protocolpackage.body[0],size);
          stream.write(protocolpackage,size+2);
          stream.Position:=0;
          AContext.Connection.IOHandler.Write(byte(stream.size-1));
          AContext.Connection.IOHandler.Write(stream,stream.size,false);
        finally
          stream.Free;
        end;
    end;

    //重复函数
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

    //发送聊天
    procedure sendchat(AContext:tIdContext;protocol:char;messages:pointer;size:integer);
    var stream:tmemorystream;
        protocolpackage:tprotocolpackage;
    begin
        stream:=tmemorystream.Create;
        try
          protocolpackage.protocolhead1:=protocol;
          protocolpackage.protocolhead2:=char(8);
          protocolpackage.body[0]:=char(0);
          move(messages^,protocolpackage.body[1],size);
          stream.write(protocolpackage,size+3);
          stream.Position:=0;
          peersendstream(tuserinfo(acontext),nil,stream);
        finally
          stream.Free;
        end;
    end;

   procedure sendstream(context: TIdTCPClient; lock:TRTLCriticalSection; stream: tmemorystream);
   var buff:tidbytes;
   begin
       stream.Position:=0;
       buff:=ToBytes(word(stream.Size));
       if assigned(context) and context.Connected then
       begin
         context.IOHandler.Write(buff);
         context.IOHandler.Write(stream,stream.Size,false);
       end;
   end;

   procedure sendbuffer(context:TIdTCPClient;buffer:pchar;size:integer;lock:TRTLCriticalSection);
     var stream:tmemorystream;
   begin
      stream:=tmemorystream.Create;
      try
          stream.write(buffer[0],size);
          stream.Position:=0;
          if assigned(context) and context.Connected then
          sendstream(context,lock,stream);
      finally
        stream.Free;
      end;
   end;


end.
