unit messagePackage;



interface
  uses ygo_client_protocol;

  type tpackage = object
      protocolhead1:Char;
  end;
  type tchatmessage = Packed record
//      protocolhead1:Char;
 //     usertype:Char;
      messages:array[0..254] of WideChar;
  end;

  type tDuelRoom =Packed record
      pkghead:tpackage;
      seed:array[0..7] of char;
      password2name:array[0..19] of WideChar;
  end;

  type tYgoMessage =record
      //pkghead:tpackage;
      msghead1:char;
      msghead2:char;
      msghead3:char;
      messages:array[0..19] of WideChar;
  end;


  type tDuelPlayer =Packed record
      pkghead:tpackage;
      name:array[0..19] of WideChar;
  end;

  type tplayerpostion= record
      pkghead:tpackage;
      pos:char;
  end;

  type tDuelGameInfo =Packed record //struct HostInfo
      {protocolhead1:Char;
      protocolhead2:Char;}
      protocolhead3:array[0..3] of Char;//lflist:Cardinal; °æ±¾µÄhashÖµ
      rule:Char;
      mode:Char;
      enable_priority,no_check_deck,no_shuffle_deck:Char;
      DuelGameInfosplit1:array[0..2] of Char;
      start_lp:Cardinal;
      //DuelGameInfosplit2:array[0..1] of char;
      start_hand:Char;
      draw_count:Char;
      time:cardinal;
  {
	unsigned int lflist;
	unsigned char rule;
	unsigned char mode;
	bool enable_priority;
	bool no_check_deck;
	bool no_shuffle_deck;
	unsigned int start_lp;
	unsigned char start_hand;
	unsigned char draw_count;
  }
  end;
  
      
  type tPlayerJoin =record    //STOC_HS_PlayerEnter
      name:array[0..37] of char;
      split:array[0..1] of Char;
      pos:Char;
  end;
    function consplayerjoin(str:string):tPlayerJoin;
    function consDuelGameInfo():tDuelGameInfo;
implementation

    function consplayerjoin(str:string):tPlayerJoin;
    var wstr:array[0..19] of WideChar;
    begin
        StringToWideChar(str,wstr,38);
        move(wstr,result.name[0],38);
        result.split[0]:=char(0);
        result.split[1]:=char(0);
        result.pos:=char(0);
    end;


    function consDuelGameInfo():tDuelGameInfo;
    begin
          //DuelGameInfo.protocolhead1:=char(0);
            //DuelGameInfo.protocolhead2:=char(STOC_JOIN_GAME);
            result.protocolhead3[0]:=char($1b);
            result.protocolhead3[1]:=char($0c);
            result.protocolhead3[2]:=char($e9);
            result.protocolhead3[3]:=char($25);

            // DuelGameInfo.lflist:=1;
            result.rule:=char(0);
            result.mode:=char(0);
            result.enable_priority:=char(0);
            result.no_check_deck:=char(0);
            result.no_shuffle_deck:=char(0);

            result.DuelGameInfosplit1:=char(0);

            result.start_lp:=8000;
            result.start_hand:=char(0);
            result.draw_count:=char(0);
            result.time:=0;
    end;

end.
