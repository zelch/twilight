/*
Copyright (C) 1996-1997 Id Software, Inc.
Copyright (C) 2002 Mathieu Olivier
Copyright (C) 2003 Forest Hale

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*/

#include "quakedef.h"
#include "lhnet.h"

#define MASTER_PORT 27950

cvar_t sv_public = {0, "sv_public", "0"};
static cvar_t sv_heartbeatperiod = {CVAR_SAVE, "sv_heartbeatperiod", "180"};

// FIXME: resolve DNS on masters whenever their value changes and cache it (to avoid major delays in active servers when they heartbeat)
static cvar_t sv_masters [] =
{
	{CVAR_SAVE, "sv_master1", ""},
	{CVAR_SAVE, "sv_master2", ""},
	{CVAR_SAVE, "sv_master3", ""},
	{CVAR_SAVE, "sv_master4", ""},
	{0, "sv_masterextra1", "69.59.212.88"}, // ghdigital.com
	{0, "sv_masterextra2", "66.169.205.13"}, // dpmaster.deathmask.net
	{0, NULL, NULL}
};

static double nextheartbeattime = 0;

sizebuf_t net_message;

cvar_t net_messagetimeout = {0, "net_messagetimeout","300"};
cvar_t net_messagerejointimeout = {0, "net_messagerejointimeout","10"};
cvar_t net_connecttimeout = {0, "net_connecttimeout","10"};
cvar_t hostname = {CVAR_SAVE, "hostname", "UNNAMED"};
cvar_t developer_networking = {0, "developer_networking", "0"};

cvar_t cl_netlocalping = {0, "cl_netlocalping","0"};
static cvar_t cl_netpacketloss = {0, "cl_netpacketloss","0"};


/* statistic counters */
static int packetsSent = 0;
static int packetsReSent = 0;
static int packetsReceived = 0;
static int receivedDuplicateCount = 0;
static int droppedDatagrams = 0;

static int unreliableMessagesSent = 0;
static int unreliableMessagesReceived = 0;
static int reliableMessagesSent = 0;
static int reliableMessagesReceived = 0;

double masterquerytime = -1000;
int masterquerycount = 0;
int masterreplycount = 0;
int serverquerycount = 0;
int serverreplycount = 0;

static qbyte sendbuffer[NET_HEADERSIZE+NET_MAXMESSAGE];
static qbyte readbuffer[NET_HEADERSIZE+NET_MAXMESSAGE];

int cl_numsockets;
lhnetsocket_t *cl_sockets[16];
int sv_numsockets;
lhnetsocket_t *sv_sockets[16];

netconn_t *netconn_list = NULL;
mempool_t *netconn_mempool = NULL;

cvar_t cl_netport = {0, "cl_port", "0"};
cvar_t sv_netport = {0, "port", "26000"};
cvar_t net_address = {0, "net_address", "0.0.0.0"};
//cvar_t net_netaddress_ipv6 = {0, "net_address_ipv6", "[0:0:0:0:0:0:0:0]"};

// HostCache interface
hostcache_mask_t			hostcache_andmasks[HOSTCACHE_ANDMASKCOUNT];
hostcache_mask_t			hostcache_ormasks[HOSTCACHE_ORMASKCOUNT];

hostcache_infofield_t	hostcache_sortbyfield;
qboolean				hostcache_sortdescending;

int			hostcache_viewcount = 0;
hostcache_t	*hostcache_viewset[HOSTCACHE_VIEWCACHESIZE];

int			hostcache_cachecount;
hostcache_t hostcache_cache[HOSTCACHE_TOTALSIZE];

qboolean	hostcache_consoleoutput;

// helper function to insert a value into the viewset
// spare entries will be removed
static void _HostCache_ViewSet_InsertBefore( int index, hostcache_t *entry )
{
    int i;
	if( ++hostcache_viewcount > HOSTCACHE_VIEWCACHESIZE )
		hostcache_viewcount = HOSTCACHE_VIEWCACHESIZE;
	for( i = hostcache_viewcount - 1; i > index; i-- )
		hostcache_viewset[i] = hostcache_viewset[i - 1];
	hostcache_viewset[index] = entry;
}

// we suppose hostcache_viewcount to be valid, ie > 0
static void _HostCache_ViewSet_Remove( int index )
{
	for( --hostcache_viewcount; index < hostcache_viewcount; index++ )
		hostcache_viewset[index] = hostcache_viewset[index + 1];
}

// returns true if A should be inserted before B
static qboolean _HostCache_SortTest( hostcache_t *A, hostcache_t *B )
{
	int result = 0; // > 0 if for numbers A > B and for text if A < B 

	if( hostcache_sortbyfield == HCIF_PING )
		result = A->info.ping - B->info.ping;
	else if( hostcache_sortbyfield == HCIF_MAXPLAYERS )
		result = A->info.maxplayers - B->info.maxplayers;
	else if( hostcache_sortbyfield == HCIF_NUMPLAYERS )
		result = A->info.numplayers - B->info.numplayers;
	else if( hostcache_sortbyfield == HCIF_PROTOCOL )
		result = A->info.protocol - B->info.protocol;
	else if( hostcache_sortbyfield == HCIF_CNAME )
		result = strcmp( B->info.cname, A->info.cname );
	else if( hostcache_sortbyfield == HCIF_GAME )
		result = strcmp( B->info.game, A->info.game );
	else if( hostcache_sortbyfield == HCIF_MAP )
		result = strcmp( B->info.map, A->info.map );
	else if( hostcache_sortbyfield == HCIF_MOD )
		result = strcmp( B->info.mod, A->info.mod );
	else if( hostcache_sortbyfield == HCIF_NAME )
		result = strcmp( B->info.name, A->info.name );
	
	if( hostcache_sortdescending )
		return result > 0;
	return result < 0;
}

static qboolean _hc_testint( int A, hostcache_maskop_t op, int B )
{
	if( op == HCMO_LESS )
		return A < B;
	else if( op == HCMO_LESSEQUAL )
		return A <= B;
	else if( op == HCMO_EQUAL )
		return A == B;
	else if( op == HCMO_GREATER )
		return A > B;
	else if( op == HCMO_NOTEQUAL )
		return A != B;
	else // HCMO_GREATEREQUAL
		return A >= B;
}

static qboolean _hc_teststr( const char *A, hostcache_maskop_t op, const char *B )
{
	if( op == HCMO_CONTAINS ) // A info B mask
		return *B && !!strstr( A, B ); // we want a real bool
	else if( op == HCMO_NOTCONTAIN )
		return !*B || !strstr( A, B );
	else if( op == HCMO_LESS )
		return strcmp( A, B ) < 0;
	else if( op == HCMO_LESSEQUAL )
		return strcmp( A, B ) <= 0;
	else if( op == HCMO_EQUAL )
		return strcmp( A, B ) == 0;
	else if( op == HCMO_GREATER )
		return strcmp( A, B ) > 0;	
	else if( op == HCMO_NOTEQUAL )
		return strcmp( A, B ) != 0;
	else // HCMO_GREATEREQUAL
		return strcmp( A, B ) >= 0;
}

static qboolean _HostCache_TestMask( hostcache_mask_t *mask, hostcache_info_t *info )
{
	if( !_hc_testint( info->ping, mask->tests[HCIF_PING], mask->info.ping ) )
		return false;
	if( !_hc_testint( info->maxplayers, mask->tests[HCIF_MAXPLAYERS], mask->info.maxplayers ) )
		return false;
	if( !_hc_testint( info->numplayers, mask->tests[HCIF_NUMPLAYERS], mask->info.numplayers ) )
		return false;
	if( !_hc_testint( info->protocol, mask->tests[HCIF_PROTOCOL], mask->info.protocol ))
		return false;
	if( *mask->info.cname
		&& !_hc_teststr( info->cname, mask->tests[HCIF_CNAME], mask->info.cname ) )
		return false;
	if( *mask->info.game
		&& !_hc_teststr( info->game, mask->tests[HCIF_GAME], mask->info.game ) )
		return false;
	if( *mask->info.mod
		&& !_hc_teststr( info->mod, mask->tests[HCIF_MOD], mask->info.mod ) )
		return false;
	if( *mask->info.map
		&& !_hc_teststr( info->map, mask->tests[HCIF_MAP], mask->info.map ) )
		return false;
	if( *mask->info.name
		&& !_hc_teststr( info->name, mask->tests[HCIF_NAME], mask->info.name ) )
		return false;
	return true;
}

static void _HostCache_Insert( hostcache_t *entry )
{
	int start, end, mid;
	if( hostcache_viewcount == HOSTCACHE_VIEWCACHESIZE )
		return;
	// now check whether it passes through the masks mask
	for( start = 0 ; hostcache_andmasks[start].active && start < HOSTCACHE_ANDMASKCOUNT ; start++ ) 
		if( !_HostCache_TestMask( &hostcache_andmasks[start], &entry->info ) )
			return;

	for( start = 0 ; hostcache_ormasks[start].active && start < HOSTCACHE_ORMASKCOUNT ; start++ )
		if( _HostCache_TestMask( &hostcache_ormasks[start], &entry->info ) )
			break;
	if( start == HOSTCACHE_ORMASKCOUNT || (start > 0 && !hostcache_ormasks[start].active) )
		return;

	if( !hostcache_viewcount ) {
		_HostCache_ViewSet_InsertBefore( 0, entry );
		return;
	}
	// ok, insert it, we just need to find out where exactly:

	// two special cases
	// check whether to insert it as new first item
	if( _HostCache_SortTest( entry, hostcache_viewset[0] ) ) {
		_HostCache_ViewSet_InsertBefore( 0, entry );
		return;
	} // check whether to insert it as new last item
	else if( !_HostCache_SortTest( entry, hostcache_viewset[hostcache_viewcount - 1] ) ) {
		_HostCache_ViewSet_InsertBefore( hostcache_viewcount, entry );
		return;
	}
	start = 0;
	end = hostcache_viewcount - 1;
	while( end > start + 1 )
	{
		mid = (start + end) / 2;
		// test the item that lies in the middle between start and end
		if( _HostCache_SortTest( entry, hostcache_viewset[mid] ) )
			// the item has to be in the upper half
			end = mid;
		else 
			// the item has to be in the lower half
			start = mid;
	}
	_HostCache_ViewSet_InsertBefore( start + 1, entry );
}

static void _HostCache_Remove( hostcache_t *entry )
{
	int i;
	for( i = 0; i < hostcache_viewcount; i++ )
	{
		if (hostcache_viewset[i] == entry)
		{
			_HostCache_ViewSet_Remove(i);
			break;
		}
	}
}

void HostCache_RebuildViewSet(void)
{
	int i;
	
	hostcache_viewcount = 0;
	for( i = 0 ; i < hostcache_cachecount ; i++ )
		if( hostcache_cache[i].finished )
			_HostCache_Insert( &hostcache_cache[i] );
}

void HostCache_ResetMasks(void)
{
	memset( &hostcache_andmasks, 0, sizeof( hostcache_andmasks ) );
	memset( &hostcache_ormasks, 0, sizeof( hostcache_ormasks ) );
}

#if 1
static void _HostCache_Test(void)
{
	int i;
	for( i = 0 ; i < 1024 ; i++ ) {
		memset( &hostcache_cache[hostcache_cachecount], 0, sizeof( hostcache_t ) );
		hostcache_cache[hostcache_cachecount].info.ping = rand() % 450 + 250;
		snprintf( hostcache_cache[hostcache_cachecount].info.name, 128, "Black's HostCache Test %i", i );
		hostcache_cache[hostcache_cachecount].finished = true;
		sprintf( hostcache_cache[hostcache_cachecount].line1, "%i %s", hostcache_cache[hostcache_cachecount].info.ping, hostcache_cache[hostcache_cachecount].info.name );
		_HostCache_Insert( &hostcache_cache[hostcache_cachecount] );
		hostcache_cachecount++;
	}
}
#endif

void HostCache_QueryList(void)
{
	masterquerytime = realtime;
	masterquerycount = 0;
	masterreplycount = 0;
	serverquerycount = 0;
	serverreplycount = 0;
	hostcache_cachecount = 0;
	hostcache_viewcount = 0;
	hostcache_consoleoutput = false;
	NetConn_QueryMasters();
	
	_HostCache_Test(); 
}

// rest

int NetConn_Read(lhnetsocket_t *mysocket, void *data, int maxlength, lhnetaddress_t *peeraddress)
{
	int length = LHNET_Read(mysocket, data, maxlength, peeraddress);
	int i;
	if (cl_netpacketloss.integer)
		for (i = 0;i < cl_numsockets;i++)
			if (cl_sockets[i] == mysocket && (rand() % 100) < cl_netpacketloss.integer)
				return 0;
	if (developer_networking.integer && length != 0)
	{
		char addressstring[128], addressstring2[128];
		LHNETADDRESS_ToString(LHNET_AddressFromSocket(mysocket), addressstring, sizeof(addressstring), true);
		if (length > 0)
		{
			LHNETADDRESS_ToString(peeraddress, addressstring2, sizeof(addressstring2), true);
			Con_Printf("LHNET_Read(%p (%s), %p, %i, %p) = %i from %s:\n", mysocket, addressstring, data, maxlength, peeraddress, length, addressstring2);
			Com_HexDumpToConsole(data, length);
		}
		else
			Con_Printf("LHNET_Read(%p (%s), %p, %i, %p) = %i\n", mysocket, addressstring, data, maxlength, peeraddress, length);
	}
	return length;
}

int NetConn_Write(lhnetsocket_t *mysocket, const void *data, int length, const lhnetaddress_t *peeraddress)
{
	int ret;
	int i;
	if (cl_netpacketloss.integer)
		for (i = 0;i < cl_numsockets;i++)
			if (cl_sockets[i] == mysocket && (rand() % 100) < cl_netpacketloss.integer)
				return length;
	ret = LHNET_Write(mysocket, data, length, peeraddress);
	if (developer_networking.integer)
	{
		char addressstring[128], addressstring2[128];
		LHNETADDRESS_ToString(LHNET_AddressFromSocket(mysocket), addressstring, sizeof(addressstring), true);
		LHNETADDRESS_ToString(peeraddress, addressstring2, sizeof(addressstring2), true);
		Con_Printf("LHNET_Write(%p (%s), %p, %i, %p (%s)) = %i%s\n", mysocket, addressstring, data, length, peeraddress, addressstring2, length, ret == length ? "" : " (ERROR)");
		Com_HexDumpToConsole(data, length);
	}
	return ret;
}

int NetConn_WriteString(lhnetsocket_t *mysocket, const char *string, const lhnetaddress_t *peeraddress)
{
	// note this does not include the trailing NULL because we add that in the parser
	return NetConn_Write(mysocket, string, strlen(string), peeraddress);
}

int NetConn_SendReliableMessage(netconn_t *conn, sizebuf_t *data)
{
	unsigned int packetLen;
	unsigned int dataLen;
	unsigned int eom;
	unsigned int *header;

//#ifdef DEBUG
	if (data->cursize == 0)
		Sys_Error("Datagram_SendMessage: zero length message\n");

	if (data->cursize > (int)sizeof(conn->sendMessage))
		Sys_Error("Datagram_SendMessage: message too big (%u > %u)\n", data->cursize, sizeof(conn->sendMessage));

	if (conn->canSend == false)
		Sys_Error("SendMessage: called with canSend == false\n");
//#endif

	memcpy(conn->sendMessage, data->data, data->cursize);
	conn->sendMessageLength = data->cursize;

	if (conn->sendMessageLength <= MAX_PACKETFRAGMENT)
	{
		dataLen = conn->sendMessageLength;
		eom = NETFLAG_EOM;
	}
	else
	{
		dataLen = MAX_PACKETFRAGMENT;
		eom = 0;
	}

	packetLen = NET_HEADERSIZE + dataLen;

	header = (void *)sendbuffer;
	header[0] = BigLong(packetLen | (NETFLAG_DATA | eom));
	header[1] = BigLong(conn->sendSequence);
	memcpy(sendbuffer + NET_HEADERSIZE, conn->sendMessage, dataLen);

	conn->sendSequence++;
	conn->canSend = false;

	if (NetConn_Write(conn->mysocket, (void *)&sendbuffer, packetLen, &conn->peeraddress) != (int)packetLen)
		return -1;

	conn->lastSendTime = realtime;
	packetsSent++;
	reliableMessagesSent++;
	return 1;
}

static void NetConn_SendMessageNext(netconn_t *conn)
{
	unsigned int packetLen;
	unsigned int dataLen;
	unsigned int eom;
	unsigned int *header;

	if (conn->sendMessageLength && !conn->canSend && conn->sendNext)
	{
		if (conn->sendMessageLength <= MAX_PACKETFRAGMENT)
		{
			dataLen = conn->sendMessageLength;
			eom = NETFLAG_EOM;
		}
		else
		{
			dataLen = MAX_PACKETFRAGMENT;
			eom = 0;
		}

		packetLen = NET_HEADERSIZE + dataLen;

		header = (void *)sendbuffer;
		header[0] = BigLong(packetLen | (NETFLAG_DATA | eom));
		header[1] = BigLong(conn->sendSequence);
		memcpy(sendbuffer + NET_HEADERSIZE, conn->sendMessage, dataLen);

		conn->sendSequence++;
		conn->sendNext = false;

		if (NetConn_Write(conn->mysocket, (void *)&sendbuffer, packetLen, &conn->peeraddress) != (int)packetLen)
			return;

		conn->lastSendTime = realtime;
		packetsSent++;
	}
}

static void NetConn_ReSendMessage(netconn_t *conn)
{
	unsigned int packetLen;
	unsigned int dataLen;
	unsigned int eom;
	unsigned int *header;

	if (conn->sendMessageLength && !conn->canSend && (realtime - conn->lastSendTime) > 1.0)
	{
		if (conn->sendMessageLength <= MAX_PACKETFRAGMENT)
		{
			dataLen = conn->sendMessageLength;
			eom = NETFLAG_EOM;
		}
		else
		{
			dataLen = MAX_PACKETFRAGMENT;
			eom = 0;
		}

		packetLen = NET_HEADERSIZE + dataLen;

		header = (void *)sendbuffer;
		header[0] = BigLong(packetLen | (NETFLAG_DATA | eom));
		header[1] = BigLong(conn->sendSequence - 1);
		memcpy(sendbuffer + NET_HEADERSIZE, conn->sendMessage, dataLen);

		conn->sendNext = false;

		if (NetConn_Write(conn->mysocket, (void *)&sendbuffer, packetLen, &conn->peeraddress) != (int)packetLen)
			return;

		conn->lastSendTime = realtime;
		packetsReSent++;
	}
}

qboolean NetConn_CanSendMessage(netconn_t *conn)
{
	return conn->canSend;
}

int NetConn_SendUnreliableMessage(netconn_t *conn, sizebuf_t *data)
{
	int packetLen;
	int *header;

	packetLen = NET_HEADERSIZE + data->cursize;

//#ifdef DEBUG
	if (data->cursize == 0)
		Sys_Error("Datagram_SendUnreliableMessage: zero length message\n");

	if (packetLen > (int)sizeof(sendbuffer))
		Sys_Error("Datagram_SendUnreliableMessage: message too big %u\n", data->cursize);
//#endif

	header = (void *)sendbuffer;
	header[0] = BigLong(packetLen | NETFLAG_UNRELIABLE);
	header[1] = BigLong(conn->unreliableSendSequence);
	memcpy(sendbuffer + NET_HEADERSIZE, data->data, data->cursize);

	conn->unreliableSendSequence++;

	if (NetConn_Write(conn->mysocket, (void *)&sendbuffer, packetLen, &conn->peeraddress) != (int)packetLen)
		return -1;

	packetsSent++;
	unreliableMessagesSent++;
	return 1;
}

void NetConn_CloseClientPorts(void)
{
	for (;cl_numsockets > 0;cl_numsockets--)
		if (cl_sockets[cl_numsockets - 1])
			LHNET_CloseSocket(cl_sockets[cl_numsockets - 1]);
}

void NetConn_OpenClientPort(const char *addressstring, int defaultport)
{
	lhnetaddress_t address;
	lhnetsocket_t *s;
	char addressstring2[1024];
	if (LHNETADDRESS_FromString(&address, addressstring, defaultport))
	{
		if ((s = LHNET_OpenSocket_Connectionless(&address)))
		{
			cl_sockets[cl_numsockets++] = s;
			LHNETADDRESS_ToString(LHNET_AddressFromSocket(s), addressstring2, sizeof(addressstring2), true);
			Con_Printf("Client opened a socket on address %s\n", addressstring2);
		}
		else
		{
			LHNETADDRESS_ToString(&address, addressstring2, sizeof(addressstring2), true);
			Con_Printf("Client failed to open a socket on address %s\n", addressstring2);
		}
	}
	else
		Con_Printf("Client unable to parse address %s\n", addressstring);
}

void NetConn_OpenClientPorts(void)
{
	int port;
	NetConn_CloseClientPorts();
	port = bound(0, cl_netport.integer, 65535);
	if (cl_netport.integer != port)
		Cvar_SetValueQuick(&cl_netport, port);
	Con_Printf("Client using port %i\n", port);
	NetConn_OpenClientPort("local:2", 0);
	NetConn_OpenClientPort(net_address.string, port);
	//NetConn_OpenClientPort(net_address_ipv6.string, port);
}

void NetConn_CloseServerPorts(void)
{
	for (;sv_numsockets > 0;sv_numsockets--)
		if (sv_sockets[sv_numsockets - 1])
			LHNET_CloseSocket(sv_sockets[sv_numsockets - 1]);
}

void NetConn_OpenServerPort(const char *addressstring, int defaultport)
{
	lhnetaddress_t address;
	lhnetsocket_t *s;
	char addressstring2[1024];
	if (LHNETADDRESS_FromString(&address, addressstring, defaultport))
	{
		if ((s = LHNET_OpenSocket_Connectionless(&address)))
		{
			sv_sockets[sv_numsockets++] = s;
			LHNETADDRESS_ToString(LHNET_AddressFromSocket(s), addressstring2, sizeof(addressstring2), true);
			Con_Printf("Server listening on address %s\n", addressstring2);
		}
		else
		{
			LHNETADDRESS_ToString(&address, addressstring2, sizeof(addressstring2), true);
			Con_Printf("Server failed to open socket on address %s\n", addressstring2);
		}
	}
	else
		Con_Printf("Server unable to parse address %s\n", addressstring);
}

void NetConn_OpenServerPorts(int opennetports)
{
	int port;
	NetConn_CloseServerPorts();
	port = bound(0, sv_netport.integer, 65535);
	if (port == 0)
		port = 26000;
	Con_Printf("Server using port %i\n", port);
	if (sv_netport.integer != port)
		Cvar_SetValueQuick(&sv_netport, port);
	if (cls.state != ca_dedicated)
		NetConn_OpenServerPort("local:1", 0);
	if (opennetports)
	{
		NetConn_OpenServerPort(net_address.string, port);
		//NetConn_OpenServerPort(net_address_ipv6.string, port);
	}
	if (sv_numsockets == 0)
		Host_Error("NetConn_OpenServerPorts: unable to open any ports!\n");
}

lhnetsocket_t *NetConn_ChooseClientSocketForAddress(lhnetaddress_t *address)
{
	int i, a = LHNETADDRESS_GetAddressType(address);
	for (i = 0;i < cl_numsockets;i++)
		if (cl_sockets[i] && LHNETADDRESS_GetAddressType(LHNET_AddressFromSocket(cl_sockets[i])) == a)
			return cl_sockets[i];
	return NULL;
}

lhnetsocket_t *NetConn_ChooseServerSocketForAddress(lhnetaddress_t *address)
{
	int i, a = LHNETADDRESS_GetAddressType(address);
	for (i = 0;i < sv_numsockets;i++)
		if (sv_sockets[i] && LHNETADDRESS_GetAddressType(LHNET_AddressFromSocket(sv_sockets[i])) == a)
			return sv_sockets[i];
	return NULL;
}

netconn_t *NetConn_Open(lhnetsocket_t *mysocket, lhnetaddress_t *peeraddress)
{
	netconn_t *conn;
	conn = Mem_Alloc(netconn_mempool, sizeof(*conn));
	conn->mysocket = mysocket;
	conn->peeraddress = *peeraddress;
	conn->canSend = true;
	conn->lastMessageTime = realtime;
	// LordHavoc: (inspired by ProQuake) use a short connect timeout to
	// reduce effectiveness of connection request floods
	conn->timeout = realtime + net_connecttimeout.value;
	LHNETADDRESS_ToString(&conn->peeraddress, conn->address, sizeof(conn->address), true);
	conn->next = netconn_list;
	netconn_list = conn;
	return conn;
}

void NetConn_Close(netconn_t *conn)
{
	netconn_t *c;
	// remove connection from list
	if (conn == netconn_list)
		netconn_list = conn->next;
	else
	{
		for (c = netconn_list;c;c = c->next)
		{
			if (c->next == conn)
			{
				c->next = conn->next;
				break;
			}
		}
		// not found in list, we'll avoid crashing here...
		if (!c)
			return;
	}
	// free connection
	Mem_Free(conn);
}

static int clientport = -1;
static int clientport2 = -1;
static int hostport = -1;
static void NetConn_UpdateServerStuff(void)
{
	if (cls.state != ca_dedicated)
	{
		if (clientport2 != cl_netport.integer)
		{
			clientport2 = cl_netport.integer;
			if (cls.state == ca_connected)
				Con_Print("Changing \"cl_port\" will not take effect until you reconnect.\n");
		}
		if (cls.state == ca_disconnected && clientport != clientport2)
		{
			clientport = clientport2;
			NetConn_CloseClientPorts();
		}
		if (cl_numsockets == 0)
			NetConn_OpenClientPorts();
	}

	if (hostport != sv_netport.integer)
	{
		hostport = sv_netport.integer;
		if (sv.active)
			Con_Print("Changing \"port\" will not take effect until \"map\" command is executed.\n");
	}
}

int NetConn_ReceivedMessage(netconn_t *conn, qbyte *data, int length)
{
	unsigned int count;
	unsigned int flags;
	unsigned int sequence;

	if (length >= 8)
	{
		length = BigLong(((int *)data)[0]);
		flags = length & ~NETFLAG_LENGTH_MASK;
		length &= NETFLAG_LENGTH_MASK;
		// control packets were already handled
		if (!(flags & NETFLAG_CTL))
		{
			sequence = BigLong(((int *)data)[1]);
			packetsReceived++;
			data += 8;
			length -= 8;
			if (flags & NETFLAG_UNRELIABLE)
			{
				if (sequence >= conn->unreliableReceiveSequence)
				{
					if (sequence > conn->unreliableReceiveSequence)
					{
						count = sequence - conn->unreliableReceiveSequence;
						droppedDatagrams += count;
						Con_DPrintf("Dropped %u datagram(s)\n", count);
					}
					conn->unreliableReceiveSequence = sequence + 1;
					conn->lastMessageTime = realtime;
					conn->timeout = realtime + net_messagetimeout.value;
					unreliableMessagesReceived++;
					if (length > 0)
					{
						SZ_Clear(&net_message);
						SZ_Write(&net_message, data, length);
						MSG_BeginReading();
						return 2;
					}
				}
				else
					Con_DPrint("Got a stale datagram\n");
				return 1;
			}
			else if (flags & NETFLAG_ACK)
			{
				if (sequence == (conn->sendSequence - 1))
				{
					if (sequence == conn->ackSequence)
					{
						conn->ackSequence++;
						if (conn->ackSequence != conn->sendSequence)
							Con_DPrint("ack sequencing error\n");
						conn->lastMessageTime = realtime;
						conn->timeout = realtime + net_messagetimeout.value;
						conn->sendMessageLength -= MAX_PACKETFRAGMENT;
						if (conn->sendMessageLength > 0)
						{
							memcpy(conn->sendMessage, conn->sendMessage+MAX_PACKETFRAGMENT, conn->sendMessageLength);
							conn->sendNext = true;
							NetConn_SendMessageNext(conn);
						}
						else
						{
							conn->sendMessageLength = 0;
							conn->canSend = true;
						}
					}
					else
						Con_DPrint("Duplicate ACK received\n");
				}
				else
					Con_DPrint("Stale ACK received\n");
				return 1;
			}
			else if (flags & NETFLAG_DATA)
			{
				unsigned int temppacket[2];
				temppacket[0] = BigLong(8 | NETFLAG_ACK);
				temppacket[1] = BigLong(sequence);
				NetConn_Write(conn->mysocket, (qbyte *)temppacket, 8, &conn->peeraddress);
				if (sequence == conn->receiveSequence)
				{
					conn->lastMessageTime = realtime;
					conn->timeout = realtime + net_messagetimeout.value;
					conn->receiveSequence++;
					memcpy(conn->receiveMessage + conn->receiveMessageLength, data, length);
					conn->receiveMessageLength += length;
					if (flags & NETFLAG_EOM)
					{
						reliableMessagesReceived++;
						length = conn->receiveMessageLength;
						conn->receiveMessageLength = 0;
						if (length > 0)
						{
							SZ_Clear(&net_message);
							SZ_Write(&net_message, conn->receiveMessage, length);
							MSG_BeginReading();
							return 2;
						}
					}
				}
				else
					receivedDuplicateCount++;
				return 1;
			}
		}
	}
	return 0;
}

void NetConn_ConnectionEstablished(lhnetsocket_t *mysocket, lhnetaddress_t *peeraddress)
{
	cls.connect_trying = false;
	M_Update_Return_Reason("");
	// the connection request succeeded, stop current connection and set up a new connection
	CL_Disconnect();
	cls.netcon = NetConn_Open(mysocket, peeraddress);
	Con_Printf("Connection accepted to %s\n", cls.netcon->address);
	key_dest = key_game;
	m_state = m_none;
	cls.demonum = -1;			// not in the demo loop now
	cls.state = ca_connected;
	cls.signon = 0;				// need all the signon messages before playing
	CL_ClearState();
	SCR_BeginLoadingPlaque();
}

int NetConn_IsLocalGame(void)
{
	if (cls.state == ca_connected && sv.active && cl.maxclients == 1)
		return true;
	return false;
}

int NetConn_ClientParsePacket(lhnetsocket_t *mysocket, qbyte *data, int length, lhnetaddress_t *peeraddress)
{
	int ret, c, control;
	lhnetaddress_t svaddress;
	const char *s;
	char *string, addressstring2[128], cname[128], ipstring[32];
	char stringbuf[16384];

	if (length >= 5 && data[0] == 255 && data[1] == 255 && data[2] == 255 && data[3] == 255)
	{
		// received a command string - strip off the packaging and put it
		// into our string buffer with NULL termination
		data += 4;
		length -= 4;
		length = min(length, (int)sizeof(stringbuf) - 1);
		memcpy(stringbuf, data, length);
		stringbuf[length] = 0;
		string = stringbuf;

		if (developer.integer)
		{
			LHNETADDRESS_ToString(peeraddress, addressstring2, sizeof(addressstring2), true);
			Con_Printf("NetConn_ClientParsePacket: %s sent us a command:\n", addressstring2);
			Com_HexDumpToConsole(data, length);
		}

		if (length > 10 && !memcmp(string, "challenge ", 10) && cls.connect_trying)
		{
			LHNETADDRESS_ToString(peeraddress, addressstring2, sizeof(addressstring2), true);
			Con_Printf("\"%s\" received, sending connect request back to %s\n", string, addressstring2);
			M_Update_Return_Reason("Got challenge response");
			NetConn_WriteString(mysocket, va("\377\377\377\377connect\\protocol\\darkplaces 3\\challenge\\%s", string + 10), peeraddress);
			return true;
		}
		if (length == 6 && !memcmp(string, "accept", 6) && cls.connect_trying)
		{
			M_Update_Return_Reason("Accepted");
			NetConn_ConnectionEstablished(mysocket, peeraddress);
			return true;
		}
		if (length > 7 && !memcmp(string, "reject ", 7) && cls.connect_trying)
		{
			char rejectreason[32];
			cls.connect_trying = false;
			string += 7;
			length = max(length - 7, (int)sizeof(rejectreason) - 1);
			memcpy(rejectreason, string, length);
			rejectreason[length] = 0;
			M_Update_Return_Reason(rejectreason);
			return true;
		}
		if (length >= 13 && !memcmp(string, "infoResponse\x0A", 13))
		{
			hostcache_info_t *info;
			int i, n;
			double pingtime;
	
			string += 13;
			// hostcache only uses text addresses
			LHNETADDRESS_ToString(peeraddress, cname, sizeof(cname), true);
			// search the cache for this server and update it
			for( n = 0; n < hostcache_cachecount; n++ )
				if( !strcmp( cname, hostcache_cache[n].info.cname ) )
					break;
			if( n == hostcache_cachecount )
				return true;

			info = &hostcache_cache[n].info;
			if ((s = SearchInfostring(string, "gamename"     )) != NULL) strlcpy(info->game, s, sizeof (info->game));else info->game[0] = 0;
			if ((s = SearchInfostring(string, "modname"      )) != NULL) strlcpy(info->mod , s, sizeof (info->mod ));else info->mod[0]  = 0;
			if ((s = SearchInfostring(string, "mapname"      )) != NULL) strlcpy(info->map , s, sizeof (info->map ));else info->map[0]  = 0;
			if ((s = SearchInfostring(string, "hostname"     )) != NULL) strlcpy(info->name, s, sizeof (info->name));else info->name[0] = 0;
			if ((s = SearchInfostring(string, "protocol"     )) != NULL) info->protocol = atoi(s);else info->protocol = -1;
			if ((s = SearchInfostring(string, "clients"      )) != NULL) info->numplayers = atoi(s);else info->numplayers = 0;
			if ((s = SearchInfostring(string, "sv_maxclients")) != NULL) info->maxplayers = atoi(s);else info->maxplayers  = 0;

			if (info->ping == 100000)
					serverreplycount++;

			pingtime = (int)((realtime - hostcache_cache[n].querytime) * 1000.0);
			pingtime = bound(0, pingtime, 9999);
			// update the ping
			info->ping = pingtime;

			// legacy/old stuff move it to the menu ASAP

			// build description strings for the things users care about
			snprintf(hostcache_cache[n].line1, sizeof(hostcache_cache[n].line1), "%5d%c%3u/%3u %-65.65s", (int)pingtime, info->protocol != NET_PROTOCOL_VERSION ? '*' : ' ', info->numplayers, info->maxplayers, info->name);
			snprintf(hostcache_cache[n].line2, sizeof(hostcache_cache[n].line2), "%-21.21s %-19.19s %-17.17s %-20.20s", info->cname, info->game, info->mod, info->map);
			// if ping is especially high, display it as such
			if (pingtime >= 300)
			{
				// orange numbers (lower block)
				for (i = 0;i < 5;i++)
					if (hostcache_cache[n].line1[i] != ' ')
						hostcache_cache[n].line1[i] += 128;
			}
			else if (pingtime >= 200)
			{
				// yellow numbers (in upper block)
				for (i = 0;i < 5;i++)
					if (hostcache_cache[n].line1[i] != ' ')
						hostcache_cache[n].line1[i] -= 30;
			}
			// if not in the slist menu we should print the server to console
			if( hostcache_consoleoutput )
				Con_Printf("%s\n%s\n", hostcache_cache[n].line1, hostcache_cache[n].line2);
			// and finally, update the view set
			if( hostcache_cache[n].finished )
                _HostCache_Remove( &hostcache_cache[n] );
			_HostCache_Insert( &hostcache_cache[n] );
			hostcache_cache[n].finished = true;

			return true;
		}
		if (!strncmp(string, "getserversResponse\\", 19) && hostcache_cachecount < HOSTCACHE_TOTALSIZE)
		{
			// Extract the IP addresses
			data += 18;
			length -= 18;
			masterreplycount++;
			if (hostcache_consoleoutput)
				Con_Print("received server list...\n");
			while (length >= 7 && data[0] == '\\' && (data[1] != 0xFF || data[2] != 0xFF || data[3] != 0xFF || data[4] != 0xFF) && data[5] * 256 + data[6] != 0)
			{
				serverquerycount++;
	
				snprintf (ipstring, sizeof (ipstring), "%u.%u.%u.%u:%u", data[1], data[2], data[3], data[4], (data[5] << 8) | data[6]);
				if (developer.integer)
					Con_Printf("Requesting info from server %s\n", ipstring);				
				// ignore the rest of the message if the hostcache is full
				if( hostcache_cachecount == HOSTCACHE_TOTALSIZE )
					break;

				LHNETADDRESS_FromString(&svaddress, ipstring, 0);
				NetConn_WriteString(mysocket, "\377\377\377\377getinfo", &svaddress);

				memset(&hostcache_cache[hostcache_cachecount], 0, sizeof(hostcache_cache[hostcache_cachecount]));
				// store the data the engine cares about (address and ping)
				strlcpy (hostcache_cache[hostcache_cachecount].info.cname, ipstring, sizeof (hostcache_cache[hostcache_cachecount].info.cname));
				hostcache_cache[hostcache_cachecount].info.ping = 100000;
				hostcache_cache[hostcache_cachecount].querytime = realtime;
				// if not in the slist menu we should print the server to console
				if (hostcache_consoleoutput)
					Con_Printf("querying %s\n", ipstring);

				++hostcache_cachecount;

				// move on to next address in packet
				data += 7;
				length -= 7;
			}
			return true;
		}
		/*
		if (!strncmp(string, "ping", 4))
		{
			if (developer.integer)
				Con_Printf("Received ping from %s, sending ack\n", UDP_AddrToString(readaddr));
			NetConn_WriteString(mysocket, "\377\377\377\377ack", peeraddress);
			return true;
		}
		if (!strncmp(string, "ack", 3))
			return true;
		*/
		// we may not have liked the packet, but it was a command packet, so
		// we're done processing this packet now
		return true;
	}
	// netquake control packets, supported for compatibility only
	if (length >= 5 && (control = BigLong(*((int *)data))) && (control & (~NETFLAG_LENGTH_MASK)) == (int)NETFLAG_CTL && (control & NETFLAG_LENGTH_MASK) == length)
	{
		c = data[4];
		data += 5;
		length -= 5;
		LHNETADDRESS_ToString(peeraddress, addressstring2, sizeof(addressstring2), true);
		switch (c)
		{
		case CCREP_ACCEPT:
			if (developer.integer)
				Con_Printf("Datagram_ParseConnectionless: received CCREP_ACCEPT from %s.\n", addressstring2);
			if (cls.connect_trying)
			{
				lhnetaddress_t clientportaddress;
				clientportaddress = *peeraddress;
				if (length >= 4)
				{
					unsigned int port = (data[0] << 0) | (data[1] << 8) | (data[2] << 16) | (data[3] << 24);
					data += 4;
					length -= 4;
					LHNETADDRESS_SetPort(&clientportaddress, port);
				}
				M_Update_Return_Reason("Accepted");
				NetConn_ConnectionEstablished(mysocket, &clientportaddress);
			}
			break;
		case CCREP_REJECT:
			if (developer.integer)
				Con_Printf("Datagram_ParseConnectionless: received CCREP_REJECT from %s.\n", addressstring2);
			cls.connect_trying = false;
			M_Update_Return_Reason(data);
			break;
#if 0
		case CCREP_SERVER_INFO:
			if (developer.integer)
				Con_Printf("Datagram_ParseConnectionless: received CCREP_SERVER_INFO from %s.\n", addressstring2);
			if (cls.state != ca_dedicated)
			{
				// LordHavoc: because the UDP driver reports 0.0.0.0:26000 as the address
				// string we just ignore it and keep the real address
				MSG_ReadString();
				// hostcache only uses text addresses
				cname = UDP_AddrToString(readaddr);
				// search the cache for this server
				for (n = 0; n < hostCacheCount; n++)
					if (!strcmp(cname, hostcache[n].cname))
						break;
				// add it
				if (n == hostCacheCount && hostCacheCount < HOSTCACHESIZE)
				{
					hostCacheCount++;
					memset(&hostcache[n], 0, sizeof(hostcache[n]));
					strlcpy (hostcache[n].name, MSG_ReadString(), sizeof (hostcache[n].name));
					strlcpy (hostcache[n].map, MSG_ReadString(), sizeof (hostcache[n].map));
					hostcache[n].users = MSG_ReadByte();
					hostcache[n].maxusers = MSG_ReadByte();
					c = MSG_ReadByte();
					if (c != NET_PROTOCOL_VERSION)
					{
						strlcpy (hostcache[n].cname, hostcache[n].name, sizeof (hostcache[n].cname));
						strcpy(hostcache[n].name, "*");
						strlcat (hostcache[n].name, hostcache[n].cname, sizeof(hostcache[n].name));
					}
					strlcpy (hostcache[n].cname, cname, sizeof (hostcache[n].cname));
				}
			}
			break;
		case CCREP_PLAYER_INFO:
			// we got a CCREP_PLAYER_INFO??
			//if (developer.integer)
				Con_Printf("Datagram_ParseConnectionless: received CCREP_PLAYER_INFO from %s.\n", addressstring2);
			break;
		case CCREP_RULE_INFO:
			// we got a CCREP_RULE_INFO??
			//if (developer.integer)
				Con_Printf("Datagram_ParseConnectionless: received CCREP_RULE_INFO from %s.\n", addressstring2);
			break;
#endif
		default:
			break;
		}
		// we may not have liked the packet, but it was a valid control
		// packet, so we're done processing this packet now
		return true;
	}
	ret = 0;
	if (length >= (int)NET_HEADERSIZE && cls.netcon && mysocket == cls.netcon->mysocket && !LHNETADDRESS_Compare(&cls.netcon->peeraddress, peeraddress) && (ret = NetConn_ReceivedMessage(cls.netcon, data, length)) == 2)
		CL_ParseServerMessage();
	return ret;
}

void NetConn_ClientFrame(void)
{
	int i, length;
	lhnetaddress_t peeraddress;
	netconn_t *conn;
	NetConn_UpdateServerStuff();
	if (cls.connect_trying && cls.connect_nextsendtime < realtime)
	{
		if (cls.connect_remainingtries == 0)
		{
			cls.connect_trying = false;
			M_Update_Return_Reason("Connect: Failed");
			return;
		}
		cls.connect_nextsendtime = realtime + 1;
		cls.connect_remainingtries--;
		// try challenge first (newer server)
		NetConn_WriteString(cls.connect_mysocket, "\377\377\377\377getchallenge", &cls.connect_address);
		// then try netquake as a fallback (old server, or netquake)
		SZ_Clear(&net_message);
		// save space for the header, filled in later
		MSG_WriteLong(&net_message, 0);
		MSG_WriteByte(&net_message, CCREQ_CONNECT);
		MSG_WriteString(&net_message, "QUAKE");
		MSG_WriteByte(&net_message, NET_PROTOCOL_VERSION);
		*((int *)net_message.data) = BigLong(NETFLAG_CTL | (net_message.cursize & NETFLAG_LENGTH_MASK));
		NetConn_Write(cls.connect_mysocket, net_message.data, net_message.cursize, &cls.connect_address);
		SZ_Clear(&net_message);
	}
	for (i = 0;i < cl_numsockets;i++)
		while (cl_sockets[i] && (length = NetConn_Read(cl_sockets[i], readbuffer, sizeof(readbuffer), &peeraddress)) > 0)
			NetConn_ClientParsePacket(cl_sockets[i], readbuffer, length, &peeraddress);
	if (cls.netcon && realtime > cls.netcon->timeout)
	{
		Con_Print("Connection timed out\n");
		CL_Disconnect();
		Host_ShutdownServer (false);
	}
	for (conn = netconn_list;conn;conn = conn->next)
		NetConn_ReSendMessage(conn);
}

#define MAX_CHALLENGES 128
struct
{
	lhnetaddress_t address;
	double time;
	char string[12];
}
challenge[MAX_CHALLENGES];

static void NetConn_BuildChallengeString(char *buffer, int bufferlength)
{
	int i;
	char c;
	for (i = 0;i < bufferlength - 1;i++)
	{
		do
		{
			c = rand () % (127 - 33) + 33;
		} while (c == '\\' || c == ';' || c == '"' || c == '%' || c == '/');
		buffer[i] = c;
	}
	buffer[i] = 0;
}

int NetConn_ServerParsePacket(lhnetsocket_t *mysocket, qbyte *data, int length, lhnetaddress_t *peeraddress)
{
	int i, n, ret, clientnum, responselength, best;
	double besttime;
	client_t *client;
	netconn_t *conn;
	char *s, *string, response[512], addressstring2[128], stringbuf[16384];

	if (sv.active)
	{
		if (length >= 5 && data[0] == 255 && data[1] == 255 && data[2] == 255 && data[3] == 255)
		{
			// received a command string - strip off the packaging and put it
			// into our string buffer with NULL termination
			data += 4;
			length -= 4;
			length = min(length, (int)sizeof(stringbuf) - 1);
			memcpy(stringbuf, data, length);
			stringbuf[length] = 0;
			string = stringbuf;

			if (developer.integer)
			{
				LHNETADDRESS_ToString(peeraddress, addressstring2, sizeof(addressstring2), true);
				Con_Printf("NetConn_ServerParsePacket: %s sent us a command:\n", addressstring2);
				Com_HexDumpToConsole(data, length);
			}

			if (length >= 12 && !memcmp(string, "getchallenge", 12))
			{
				for (i = 0, best = 0, besttime = realtime;i < MAX_CHALLENGES;i++)
				{
					if (!LHNETADDRESS_Compare(peeraddress, &challenge[i].address))
						break;
					if (besttime > challenge[i].time)
						besttime = challenge[best = i].time;
				}
				// if we did not find an exact match, choose the oldest and
				// update address and string
				if (i == MAX_CHALLENGES)
				{
					i = best;
					challenge[i].address = *peeraddress;
					NetConn_BuildChallengeString(challenge[i].string, sizeof(challenge[i].string));
				}
				challenge[i].time = realtime;
				// send the challenge
				NetConn_WriteString(mysocket, va("\377\377\377\377challenge %s", challenge[i].string), peeraddress);
				return true;
			}
			if (length > 8 && !memcmp(string, "connect\\", 8))
			{
				string += 7;
				length -= 7;
				if ((s = SearchInfostring(string, "challenge")))
				{
					// validate the challenge
					for (i = 0;i < MAX_CHALLENGES;i++)
						if (!LHNETADDRESS_Compare(peeraddress, &challenge[i].address) && !strcmp(challenge[i].string, s))
							break;
					if (i < MAX_CHALLENGES)
					{
						// check engine protocol
						if (strcmp(SearchInfostring(string, "protocol"), "darkplaces 3"))
						{
							if (developer.integer)
								Con_Printf("Datagram_ParseConnectionless: sending \"reject Wrong game protocol.\" to %s.\n", addressstring2);
							NetConn_WriteString(mysocket, "\377\377\377\377reject Wrong game protocol.", peeraddress);
						}
						else
						{
							// see if this is a duplicate connection request
							for (clientnum = 0, client = svs.clients;clientnum < svs.maxclients;clientnum++, client++)
								if (client->netconnection && LHNETADDRESS_Compare(peeraddress, &client->netconnection->peeraddress) == 0)
									break;
							if (clientnum < svs.maxclients)
							{
								// duplicate connection request
								if (realtime - client->connecttime < 2.0)
								{
									// client is still trying to connect,
									// so we send a duplicate reply
									if (developer.integer)
										Con_Printf("Datagram_ParseConnectionless: sending duplicate accept to %s.\n", addressstring2);
									NetConn_WriteString(mysocket, "\377\377\377\377accept", peeraddress);
								}
								// only kick if old connection seems dead
								if (realtime - client->netconnection->lastMessageTime >= net_messagerejointimeout.value)
								{
									// kick off connection and await retry
									client->deadsocket = true;
								}
							}
							else
							{
								// this is a new client, find a slot
								for (clientnum = 0, client = svs.clients;clientnum < svs.maxclients;clientnum++, client++)
									if (!client->active)
										break;
								if (clientnum < svs.maxclients)
								{
									// prepare the client struct
									if ((conn = NetConn_Open(mysocket, peeraddress)))
									{
										// allocated connection
										LHNETADDRESS_ToString(peeraddress, conn->address, sizeof(conn->address), true);
										if (developer.integer)
											Con_Printf("Datagram_ParseConnectionless: sending \"accept\" to %s.\n", conn->address);
										NetConn_WriteString(mysocket, "\377\377\377\377accept", peeraddress);
										// now set up the client
										SV_ConnectClient(clientnum, conn);
										NetConn_Heartbeat(1);
									}
								}
								else
								{
									// server is full
									if (developer.integer)
										Con_Printf("Datagram_ParseConnectionless: sending \"reject Server is full.\" to %s.\n", addressstring2);
									NetConn_WriteString(mysocket, "\377\377\377\377reject Server is full.", peeraddress);
								}
							}
						}
					}
				}
				return true;
			}
			if (length >= 7 && !memcmp(string, "getinfo", 7))
			{
				const char *challenge = NULL;
				// If there was a challenge in the getinfo message
				if (length > 8 && string[7] == ' ')
					challenge = string + 8;
				for (i = 0, n = 0;i < svs.maxclients;i++)
					if (svs.clients[i].active)
						n++;
				responselength = snprintf(response, sizeof(response), "\377\377\377\377infoResponse\x0A"
							"\\gamename\\%s\\modname\\%s\\sv_maxclients\\%d"
							"\\clients\\%d\\mapname\\%s\\hostname\\%s\\protocol\\%d%s%s",
							gamename, com_modname, svs.maxclients, n,
							sv.name, hostname.string, NET_PROTOCOL_VERSION, challenge ? "\\challenge\\" : "", challenge ? challenge : "");
				// does it fit in the buffer?
				if (responselength < (int)sizeof(response))
				{
					if (developer.integer)
						Con_Printf("Sending reply to master %s - %s\n", addressstring2, response);
					NetConn_WriteString(mysocket, response, peeraddress);
				}
				return true;
			}
			/*
			if (!strncmp(string, "ping", 4))
			{
				if (developer.integer)
					Con_Printf("Received ping from %s, sending ack\n", UDP_AddrToString(readaddr));
				NetConn_WriteString(mysocket, "\377\377\377\377ack", peeraddress);
				return true;
			}
			if (!strncmp(string, "ack", 3))
				return true;
			*/
			// we may not have liked the packet, but it was a command packet, so
			// we're done processing this packet now
			return true;
		}
		// LordHavoc: disabled netquake control packet support in server
#if 0
		{
			int c, control;
			// netquake control packets, supported for compatibility only
			if (length >= 5 && (control = BigLong(*((int *)data))) && (control & (~NETFLAG_LENGTH_MASK)) == (int)NETFLAG_CTL && (control & NETFLAG_LENGTH_MASK) == length)
			{
				c = data[4];
				data += 5;
				length -= 5;
				LHNETADDRESS_ToString(peeraddress, addressstring2, sizeof(addressstring2), true);
				switch (c)
				{
				case CCREQ_CONNECT:
					//if (developer.integer)
						Con_Printf("Datagram_ParseConnectionless: received CCREQ_CONNECT from %s.\n", addressstring2);
					if (length >= (int)strlen("QUAKE") + 1 + 1)
					{
						if (memcmp(data, "QUAKE", strlen("QUAKE") + 1) != 0 || (int)data[strlen("QUAKE") + 1] != NET_PROTOCOL_VERSION)
						{
							if (developer.integer)
								Con_Printf("Datagram_ParseConnectionless: sending CCREP_REJECT \"Incompatible version.\" to %s.\n", addressstring2);
							SZ_Clear(&net_message);
							// save space for the header, filled in later
							MSG_WriteLong(&net_message, 0);
							MSG_WriteByte(&net_message, CCREP_REJECT);
							MSG_WriteString(&net_message, "Incompatible version.\n");
							*((int *)net_message.data) = BigLong(NETFLAG_CTL | (net_message.cursize & NETFLAG_LENGTH_MASK));
							NetConn_Write(mysocket, net_message.data, net_message.cursize, peeraddress);
							SZ_Clear(&net_message);
						}
						else
						{
							// see if this is a duplicate connection request
							for (clientnum = 0, client = svs.clients;clientnum < svs.maxclients;clientnum++, client++)
								if (client->netconnection && LHNETADDRESS_Compare(peeraddress, &client->netconnection->peeraddress) == 0)
									break;
							if (clientnum < svs.maxclients)
							{
								// duplicate connection request
								if (realtime - client->connecttime < 2.0)
								{
									// client is still trying to connect,
									// so we send a duplicate reply
									if (developer.integer)
										Con_Printf("Datagram_ParseConnectionless: sending duplicate CCREP_ACCEPT to %s.\n", addressstring2);
									SZ_Clear(&net_message);
									// save space for the header, filled in later
									MSG_WriteLong(&net_message, 0);
									MSG_WriteByte(&net_message, CCREP_ACCEPT);
									MSG_WriteLong(&net_message, LHNETADDRESS_GetPort(LHNET_AddressFromSocket(client->netconnection->mysocket)));
									*((int *)net_message.data) = BigLong(NETFLAG_CTL | (net_message.cursize & NETFLAG_LENGTH_MASK));
									NetConn_Write(mysocket, net_message.data, net_message.cursize, peeraddress);
									SZ_Clear(&net_message);
								}
								else if (realtime - client->netconnection->lastMessageTime >= net_messagerejointimeout.value)
								{
									// the old client hasn't sent us anything
									// in quite a while, so kick off and let
									// the retry take care of it...
									client->deadsocket = true;
								}
							}
							else
							{
								// this is a new client, find a slot
								for (clientnum = 0, client = svs.clients;clientnum < svs.maxclients;clientnum++, client++)
									if (!client->active)
										break;
								if (clientnum < svs.maxclients && (client->netconnection = conn = NetConn_Open(mysocket, peeraddress)) != NULL)
								{
									// connect to the client
									// everything is allocated, just fill in the details
									strlcpy (conn->address, addressstring2, sizeof (conn->address));
									if (developer.integer)
										Con_Printf("Datagram_ParseConnectionless: sending CCREP_ACCEPT to %s.\n", addressstring2);
									// send back the info about the server connection
									SZ_Clear(&net_message);
									// save space for the header, filled in later
									MSG_WriteLong(&net_message, 0);
									MSG_WriteByte(&net_message, CCREP_ACCEPT);
									MSG_WriteLong(&net_message, LHNETADDRESS_GetPort(LHNET_AddressFromSocket(conn->mysocket)));
									*((int *)net_message.data) = BigLong(NETFLAG_CTL | (net_message.cursize & NETFLAG_LENGTH_MASK));
									NetConn_Write(mysocket, net_message.data, net_message.cursize, peeraddress);
									SZ_Clear(&net_message);
									// now set up the client struct
									SV_ConnectClient(clientnum, conn);
									NetConn_Heartbeat(1);
								}
								else
								{
									//if (developer.integer)
										Con_Printf("Datagram_ParseConnectionless: sending CCREP_REJECT \"Server is full.\" to %s.\n", addressstring2);
									// no room; try to let player know
									SZ_Clear(&net_message);
									// save space for the header, filled in later
									MSG_WriteLong(&net_message, 0);
									MSG_WriteByte(&net_message, CCREP_REJECT);
									MSG_WriteString(&net_message, "Server is full.\n");
									*((int *)net_message.data) = BigLong(NETFLAG_CTL | (net_message.cursize & NETFLAG_LENGTH_MASK));
									NetConn_Write(mysocket, net_message.data, net_message.cursize, peeraddress);
									SZ_Clear(&net_message);
								}
							}
						}
					}
					break;
#if 0
				case CCREQ_SERVER_INFO:
					if (developer.integer)
						Con_Printf("Datagram_ParseConnectionless: received CCREQ_SERVER_INFO from %s.\n", addressstring2);
					if (sv.active && !strcmp(MSG_ReadString(), "QUAKE"))
					{
						if (developer.integer)
							Con_Printf("Datagram_ParseConnectionless: sending CCREP_SERVER_INFO to %s.\n", addressstring2);
						SZ_Clear(&net_message);
						// save space for the header, filled in later
						MSG_WriteLong(&net_message, 0);
						MSG_WriteByte(&net_message, CCREP_SERVER_INFO);
						UDP_GetSocketAddr(UDP_acceptSock, &newaddr);
						MSG_WriteString(&net_message, UDP_AddrToString(&newaddr));
						MSG_WriteString(&net_message, hostname.string);
						MSG_WriteString(&net_message, sv.name);
						MSG_WriteByte(&net_message, net_activeconnections);
						MSG_WriteByte(&net_message, svs.maxclients);
						MSG_WriteByte(&net_message, NET_PROTOCOL_VERSION);
						*((int *)net_message.data) = BigLong(NETFLAG_CTL | (net_message.cursize & NETFLAG_LENGTH_MASK));
						NetConn_Write(mysocket, net_message.data, net_message.cursize, peeraddress);
						SZ_Clear(&net_message);
					}
					break;
				case CCREQ_PLAYER_INFO:
					if (developer.integer)
						Con_Printf("Datagram_ParseConnectionless: received CCREQ_PLAYER_INFO from %s.\n", addressstring2);
					if (sv.active)
					{
						int playerNumber, activeNumber, clientNumber;
						client_t *client;

						playerNumber = MSG_ReadByte();
						activeNumber = -1;
						for (clientNumber = 0, client = svs.clients; clientNumber < svs.maxclients; clientNumber++, client++)
							if (client->active && ++activeNumber == playerNumber)
								break;
						if (clientNumber != svs.maxclients)
						{
							SZ_Clear(&net_message);
							// save space for the header, filled in later
							MSG_WriteLong(&net_message, 0);
							MSG_WriteByte(&net_message, CCREP_PLAYER_INFO);
							MSG_WriteByte(&net_message, playerNumber);
							MSG_WriteString(&net_message, client->name);
							MSG_WriteLong(&net_message, client->colors);
							MSG_WriteLong(&net_message, (int)client->edict->v->frags);
							MSG_WriteLong(&net_message, (int)(realtime - client->connecttime));
							MSG_WriteString(&net_message, client->netconnection ? client->netconnection->address : "botclient");
							*((int *)net_message.data) = BigLong(NETFLAG_CTL | (net_message.cursize & NETFLAG_LENGTH_MASK));
							NetConn_Write(mysocket, net_message.data, net_message.cursize, peeraddress);
							SZ_Clear(&net_message);
						}
					}
					break;
				case CCREQ_RULE_INFO:
					if (developer.integer)
						Con_Printf("Datagram_ParseConnectionless: received CCREQ_RULE_INFO from %s.\n", addressstring2);
					if (sv.active)
					{
						char *prevCvarName;
						cvar_t *var;

						// find the search start location
						prevCvarName = MSG_ReadString();
						var = Cvar_FindVarAfter(prevCvarName, CVAR_NOTIFY);

						// send the response
						SZ_Clear(&net_message);
						// save space for the header, filled in later
						MSG_WriteLong(&net_message, 0);
						MSG_WriteByte(&net_message, CCREP_RULE_INFO);
						if (var)
						{
							MSG_WriteString(&net_message, var->name);
							MSG_WriteString(&net_message, var->string);
						}
						*((int *)net_message.data) = BigLong(NETFLAG_CTL | (net_message.cursize & NETFLAG_LENGTH_MASK));
						NetConn_Write(mysocket, net_message.data, net_message.cursize, peeraddress);
						SZ_Clear(&net_message);
					}
					break;
#endif
				default:
					break;
				}
				// we may not have liked the packet, but it was a valid control
				// packet, so we're done processing this packet now
				return true;
			}
		}
#endif
		for (i = 0, host_client = svs.clients;i < svs.maxclients;i++, host_client++)
		{
			if (host_client->netconnection && host_client->netconnection->mysocket == mysocket && !LHNETADDRESS_Compare(&host_client->netconnection->peeraddress, peeraddress))
			{
				if ((ret = NetConn_ReceivedMessage(host_client->netconnection, data, length)) == 2)
					SV_ReadClientMessage();
				return ret;
			}
		}
	}
	return 0;
}

void NetConn_ServerFrame(void)
{
	int i, length;
	lhnetaddress_t peeraddress;
	netconn_t *conn;
	NetConn_UpdateServerStuff();
	for (i = 0;i < sv_numsockets;i++)
		while (sv_sockets[i] && (length = NetConn_Read(sv_sockets[i], readbuffer, sizeof(readbuffer), &peeraddress)) > 0)
			NetConn_ServerParsePacket(sv_sockets[i], readbuffer, length, &peeraddress);
	for (i = 0, host_client = svs.clients;i < svs.maxclients;i++, host_client++)
	{
		// never timeout loopback connections
		if (host_client->netconnection && realtime > host_client->netconnection->timeout && LHNETADDRESS_GetAddressType(&host_client->netconnection->peeraddress) != LHNETADDRESSTYPE_LOOP)
		{
			Con_Printf("Client \"%s\" connection timed out\n", host_client->name);
			SV_DropClient(false);
		}
	}
	for (conn = netconn_list;conn;conn = conn->next)
		NetConn_ReSendMessage(conn);
}

void NetConn_QueryMasters(void)
{
	int i;
	int masternum;
	lhnetaddress_t masteraddress;
	char request[256];

	if (hostcache_cachecount >= HOSTCACHE_TOTALSIZE)
		return;

	for (i = 0;i < cl_numsockets;i++)
	{
		if (cl_sockets[i])
		{
#if 0
			// search LAN
#if 1
			UDP_Broadcast(UDP_controlSock, "\377\377\377\377getinfo", 11);
#else
			SZ_Clear(&net_message);
			// save space for the header, filled in later
			MSG_WriteLong(&net_message, 0);
			MSG_WriteByte(&net_message, CCREQ_SERVER_INFO);
			MSG_WriteString(&net_message, "QUAKE");
			MSG_WriteByte(&net_message, NET_PROTOCOL_VERSION);
			*((int *)net_message.data) = BigLong(NETFLAG_CTL | (net_message.cursize & NETFLAG_LENGTH_MASK));
			UDP_Broadcast(UDP_controlSock, net_message.data, net_message.cursize);
			SZ_Clear(&net_message);
#endif
#endif

			// build the getservers
			snprintf(request, sizeof(request), "\377\377\377\377getservers %s %u empty full\x0A", gamename, NET_PROTOCOL_VERSION);

			// search internet
			for (masternum = 0;sv_masters[masternum].name;masternum++)
			{
				if (sv_masters[masternum].string && LHNETADDRESS_FromString(&masteraddress, sv_masters[masternum].string, MASTER_PORT) && LHNETADDRESS_GetAddressType(&masteraddress) == LHNETADDRESS_GetAddressType(LHNET_AddressFromSocket(cl_sockets[i])))
				{
					masterquerycount++;
					NetConn_WriteString(cl_sockets[i], request, &masteraddress);
				}
			}
		}
	}
	if (!masterquerycount)
	{
		Con_Print("Unable to query master servers, no suitable network sockets active.\n");
		M_Update_Return_Reason("No network");
	}
}

void NetConn_Heartbeat(int priority)
{
	lhnetaddress_t masteraddress;
	int masternum;
	lhnetsocket_t *mysocket;

	// if it's a state change (client connected), limit next heartbeat to no
	// more than 30 sec in the future
	if (priority == 1 && nextheartbeattime > realtime + 30.0)
		nextheartbeattime = realtime + 30.0;

	// limit heartbeatperiod to 30 to 270 second range,
	// lower limit is to avoid abusing master servers with excess traffic,
	// upper limit is to avoid timing out on the master server (which uses
	// 300 sec timeout)
	if (sv_heartbeatperiod.value < 30)
		Cvar_SetValueQuick(&sv_heartbeatperiod, 30);
	if (sv_heartbeatperiod.value > 270)
		Cvar_SetValueQuick(&sv_heartbeatperiod, 270);

	// make advertising optional and don't advertise singleplayer games, and
	// only send a heartbeat as often as the admin wants
	if (sv.active && sv_public.integer && svs.maxclients >= 2 && (priority > 1 || realtime > nextheartbeattime))
	{
		nextheartbeattime = realtime + sv_heartbeatperiod.value;
		for (masternum = 0;sv_masters[masternum].name;masternum++)
			if (sv_masters[masternum].string && LHNETADDRESS_FromString(&masteraddress, sv_masters[masternum].string, MASTER_PORT) && (mysocket = NetConn_ChooseServerSocketForAddress(&masteraddress)))
				NetConn_WriteString(mysocket, "\377\377\377\377heartbeat DarkPlaces\x0A", &masteraddress);
	}
}

int NetConn_SendToAll(sizebuf_t *data, double blocktime)
{
	int i, count = 0;
	qbyte sent[MAX_SCOREBOARD];

	memset(sent, 0, sizeof(sent));

	// simultaneously wait for the first CanSendMessage and send the message,
	// then wait for a second CanSendMessage (verifying it was received), or
	// the client drops and is no longer counted
	// the loop aborts when either it runs out of clients to send to, or a
	// timeout expires
	blocktime += Sys_DoubleTime();
	do
	{
		count = 0;
		NetConn_ClientFrame();
		NetConn_ServerFrame();
		for (i = 0, host_client = svs.clients;i < svs.maxclients;i++, host_client++)
		{
			if (host_client->netconnection)
			{
				if (NetConn_CanSendMessage(host_client->netconnection))
				{
					if (!sent[i])
						NetConn_SendReliableMessage(host_client->netconnection, data);
					sent[i] = true;
				}
				if (!NetConn_CanSendMessage(host_client->netconnection))
					count++;
			}
		}
	}
	while (count && Sys_DoubleTime() < blocktime);
	return count;
}

static void Net_Heartbeat_f(void)
{
	if (sv.active)
		NetConn_Heartbeat(2);
	else
		Con_Print("No server running, can not heartbeat to master server.\n");
}

void PrintStats(netconn_t *conn)
{
	Con_Printf("address=%21s canSend=%u sendSeq=%6u recvSeq=%6u\n", conn->address, conn->canSend, conn->sendSequence, conn->receiveSequence);
}

void Net_Stats_f(void)
{
	netconn_t *conn;
	Con_Printf("unreliable messages sent   = %i\n", unreliableMessagesSent);
	Con_Printf("unreliable messages recv   = %i\n", unreliableMessagesReceived);
	Con_Printf("reliable messages sent     = %i\n", reliableMessagesSent);
	Con_Printf("reliable messages received = %i\n", reliableMessagesReceived);
	Con_Printf("packetsSent                = %i\n", packetsSent);
	Con_Printf("packetsReSent              = %i\n", packetsReSent);
	Con_Printf("packetsReceived            = %i\n", packetsReceived);
	Con_Printf("receivedDuplicateCount     = %i\n", receivedDuplicateCount);
	Con_Printf("droppedDatagrams           = %i\n", droppedDatagrams);
	Con_Print("connections                =\n");
	for (conn = netconn_list;conn;conn = conn->next)
		PrintStats(conn);
}

void Net_Slist_f(void)
{
	HostCache_ResetMasks();
	hostcache_sortbyfield = HCIF_PING;
	hostcache_sortdescending = false;
    if (m_state != m_slist) {
		Con_Print("Sending requests to master servers\n");
		HostCache_QueryList();
		hostcache_consoleoutput = true;
		Con_Print("Listening for replies...\n");
	} else
		HostCache_QueryList();
}

void NetConn_Init(void)
{
	int i;
	lhnetaddress_t tempaddress;
	netconn_mempool = Mem_AllocPool("Networking", 0, NULL);
	Cmd_AddCommand("net_stats", Net_Stats_f);
	Cmd_AddCommand("net_slist", Net_Slist_f);
	Cmd_AddCommand("heartbeat", Net_Heartbeat_f);
	Cvar_RegisterVariable(&net_messagetimeout);
	Cvar_RegisterVariable(&net_messagerejointimeout);
	Cvar_RegisterVariable(&net_connecttimeout);
	Cvar_RegisterVariable(&cl_netlocalping);
	Cvar_RegisterVariable(&cl_netpacketloss);
	Cvar_RegisterVariable(&hostname);
	Cvar_RegisterVariable(&developer_networking);
	Cvar_RegisterVariable(&cl_netport);
	Cvar_RegisterVariable(&sv_netport);
	Cvar_RegisterVariable(&net_address);
	//Cvar_RegisterVariable(&net_address_ipv6);
	Cvar_RegisterVariable(&sv_public);
	Cvar_RegisterVariable(&sv_heartbeatperiod);
	for (i = 0;sv_masters[i].name;i++)
		Cvar_RegisterVariable(&sv_masters[i]);
// COMMANDLINEOPTION: Server: -ip <ipaddress> sets the ip address of this machine for purposes of networking (default 0.0.0.0 also known as INADDR_ANY), use only if you have multiple network adapters and need to choose one specifically.
	if ((i = COM_CheckParm("-ip")) && i + 1 < com_argc)
	{
		if (LHNETADDRESS_FromString(&tempaddress, com_argv[i + 1], 0) == 1)
		{
			Con_Printf("-ip option used, setting net_address to \"%s\"\n");
			Cvar_SetQuick(&net_address, com_argv[i + 1]);
		}
		else
			Con_Printf("-ip option used, but unable to parse the address \"%s\"\n", com_argv[i + 1]);
	}
// COMMANDLINEOPTION: Server: -port <portnumber> sets the port to use for a server (default 26000, the same port as QUAKE itself), useful if you host multiple servers on your machine
	if (((i = COM_CheckParm("-port")) || (i = COM_CheckParm("-ipport")) || (i = COM_CheckParm("-udpport"))) && i + 1 < com_argc)
	{
		i = atoi(com_argv[i + 1]);
		if (i >= 0 && i < 65536)
		{
			Con_Printf("-port option used, setting port cvar to %i\n", i);
			Cvar_SetValueQuick(&sv_netport, i);
		}
		else
			Con_Printf("-port option used, but %i is not a valid port number\n", i);
	}
	cl_numsockets = 0;
	sv_numsockets = 0;
	SZ_Alloc(&net_message, NET_MAXMESSAGE, "net_message");
	LHNET_Init();
}

void NetConn_Shutdown(void)
{
	NetConn_CloseClientPorts();
	NetConn_CloseServerPorts();
	LHNET_Shutdown();
}

