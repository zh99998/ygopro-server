unit ygo_client_protocol;

interface
 
const NETWORK_SERVER_ID	= $7428;
const NETWORK_CLIENT_ID	= $def6;

const  NETPLAYER_TYPE_PLAYER1	=	0;
const  NETPLAYER_TYPE_PLAYER2	= 1;
const  NETPLAYER_TYPE_PLAYER3	= 2;
const  NETPLAYER_TYPE_PLAYER4	=	3;
const  NETPLAYER_TYPE_PLAYER5 =	4;
const  NETPLAYER_TYPE_PLAYER6	=	5;
const  NETPLAYER_TYPE_OBSERVER	=	7;

const  CTOS_RESPONSE		=  $1;
const  CTOS_UPDATE_DECK	=  $2;
const  CTOS_HAND_RESULT	=  $3;
const  CTOS_TP_RESULT		=  $4;
const  CTOS_PLAYER_INFO	=  $10;
const  CTOS_CREATE_GAME	=  $11;
const  CTOS_JOIN_GAME		=  $12;
const  CTOS_LEAVE_GAME		=  $13;
const  CTOS_HS_TODUELIST	=  $20;
const  CTOS_HS_TOOBSERVER	=  $21;
const  CTOS_HS_READY		=  $22;
const  CTOS_HS_NOTREADY	=  $23;
const  CTOS_HS_KICK		=  $24;
const  CTOS_HS_START		=  $25;

const  STOC_GAME_MSG		=  $1;
const  STOC_ERROR_MSG		=  $2;
const  STOC_SELECT_HAND	=  $3;
const  STOC_SELECT_TP		=  $4;
const  STOC_HAND_RESULT	=  $5;
const  STOC_TP_RESULT		=  $6;
const  STOC_CHANGE_SIDE	=  $7;
const  STOC_WAITING_SIDE	=  $8;
const  STOC_CREATE_GAME	=  $11;
const  STOC_JOIN_GAME		=  $12;
const  STOC_TYPE_CHANGE	=  $13;
const  STOC_LEAVE_GAME		=  $14;
const  STOC_DUEL_START		=  $15;
const  STOC_DUEL_END		=  $16;
const  STOC_REPLAY			=  $17;
const  STOC_CHAT			=   $19;
const  STOC_HS_PLAYER_ENTER	=  $20;
const  STOC_HS_PLAYER_CHANGE	=  $21;
const  STOC_HS_WATCH_CHANGE	=  $22;

const  PLAYERCHANGE_READY		=  $1;
const  PLAYERCHANGE_NOTREADY	=  $2;
const  PLAYERCHANGE_LEAVE		=  $3;
const  PLAYERCHANGE_OBSERVE	=  $4;

const  ERRMSG_JOINERROR	=  $1;
const  ERRMSG_DECKERROR	=  $2;
const  ERRMSG_SIDEERROR	=  $3;

const  MODE_SINGLE		=  $0;
const  MODE_MATCH		=  $1;



//Messages
const MSG_RETRY	=	1;
const MSG_HINT	=	2;
const MSG_LPUPDATE = 94;
const MSG_WIN =5;
  
implementation

end.
