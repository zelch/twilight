/*
	dpmaster.c

	A master server for DarkPlaces, Quake 3 Arena and QFusion

	Copyright (C) 2002-2005  Mathieu Olivier

	This program is free software; you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation; either version 2 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program; if not, write to the Free Software
	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/


#include <stdarg.h>

#ifndef WIN32
# include <pwd.h>
# include <unistd.h>
#endif

#include "common.h"
#include "messages.h"
#include "servers.h"


// ---------- Constants ---------- //

// Version of dpmaster
#define VERSION "1.6cvs"

// Default master port
#define DEFAULT_MASTER_PORT 27950

// Maximum and minimum sizes for a valid packet
#define MAX_PACKET_SIZE 2048
#define MIN_PACKET_SIZE 5

#ifndef WIN32
// Default path we use for chroot
# define DEFAULT_JAIL_PATH "/var/empty/"

// User we use by default for dropping super-user privileges
# define DEFAULT_LOW_PRIV_USER "nobody"
#endif


// ---------- Types ---------- //

#ifdef WIN32
typedef int socklen_t;
#endif


// ---------- Private variables ---------- //

// The port we use
static unsigned short master_port = DEFAULT_MASTER_PORT;

// Local address we listen on, if any
static const char* listen_name = NULL;
static struct in_addr listen_addr;

#ifndef WIN32
// On UNIX systems, we can run as a daemon
static qboolean daemon_mode = false;

// Path we use for chroot
static const char* jail_path = DEFAULT_JAIL_PATH;

// Low privileges user
static const char* low_priv_user = DEFAULT_LOW_PRIV_USER;
#endif


// ---------- Public variables ---------- //

// The master socket
int sock = -1;

// The current time (updated every time we receive a packet)
time_t crt_time;

// Maximum level for a message to be printed
msg_level_t max_msg_level = MSG_NORMAL;

// Peer address. We rebuild it every time we receive a new packet
char peer_address [128];


// ---------- Private functions ---------- //

/*
====================
PrintPacket

Print the contents of a packet on stdout
====================
*/
static void PrintPacket (const qbyte* packet, size_t length)
{
	size_t i;

	// Exceptionally, we use MSG_NOPRINT here because if the function is
	// called, the user probably wants this text to be displayed
	// whatever the maximum message level is.
	MsgPrint (MSG_NOPRINT, "\"");

	for (i = 0; i < length; i++)
	{
		qbyte c = packet[i];
		if (c == '\\')
			MsgPrint (MSG_NOPRINT, "\\\\");
		else if (c == '\"')
			MsgPrint (MSG_NOPRINT, "\"");
		else if (c >= 32 && c <= 127)
		 	MsgPrint (MSG_NOPRINT, "%c", c);
		else
			MsgPrint (MSG_NOPRINT, "\\x%02X", c);
	}

	MsgPrint (MSG_NOPRINT, "\" (%u bytes)\n", length);
}


/*
====================
SysInit

System dependent initializations
====================
*/
static qboolean SysInit (void)
{
#ifdef WIN32
	WSADATA winsockdata;

	if (WSAStartup (MAKEWORD (1, 1), &winsockdata))
	{
		MsgPrint (MSG_ERROR, "> ERROR: can't initialize winsocks\n");
		return false;
	}
#endif

	return true;
}


/*
====================
UnsecureInit

System independent initializations, called BEFORE the security initializations.
We need this intermediate step because DNS requests may not be able to resolve
after the security initializations, due to chroot.
====================
*/
static qboolean UnsecureInit (void)
{
	// Resolve the address mapping list
	if (! Sv_ResolveAddressMappings ())
		return false;

	// Resolve the listen address if one was specified
	if (listen_name != NULL)
	{
		struct hostent* itf;

		itf = gethostbyname (listen_name);
		if (itf == NULL)
		{
			MsgPrint (MSG_ERROR, "> ERROR: can't resolve %s\n", listen_name);
			return false;
		}
		if (itf->h_addrtype != AF_INET)
		{
			MsgPrint (MSG_ERROR, "> ERROR: %s is not an IPv4 address\n",
					  listen_name);
			return false;
		}

		memcpy (&listen_addr.s_addr, itf->h_addr,
				sizeof (listen_addr.s_addr));
	}

	return true;
}


/*
====================
SecInit

Security initializations (system dependent)
====================
*/
static qboolean SecInit (void)
{
#ifndef WIN32
	// Should we run as a daemon?
	if (daemon_mode && daemon (0, 0))
	{
		MsgPrint (MSG_NOPRINT, "> ERROR: daemonization failed (%s)\n",
				  strerror (errno));
		return false;
	}

	// UNIX allows us to be completely paranoid, so let's go for it
	if (geteuid () == 0)
	{
		struct passwd* pw;

		MsgPrint (MSG_WARNING,
				  "> WARNING: running with super-user privileges\n");

		// We must get the account infos before the calls to chroot and chdir
		pw = getpwnam (low_priv_user);
		if (pw == NULL)
		{
			MsgPrint (MSG_ERROR, "> ERROR: can't get user \"%s\" properties\n",
					  low_priv_user);
			return false;
		}

		// Chroot ourself
		MsgPrint (MSG_NORMAL, "  - chrooting myself to %s... ", jail_path);
		if (chroot (jail_path) || chdir ("/"))
		{
			MsgPrint (MSG_ERROR, "FAILED (%s)\n", strerror (errno));
			return false;
		}
		MsgPrint (MSG_NORMAL, "succeeded\n");

		// Switch to lower privileges
		MsgPrint (MSG_NORMAL, "  - switching to user \"%s\" privileges... ",
				  low_priv_user);
		if (setgid (pw->pw_gid) || setuid (pw->pw_uid))
		{
			MsgPrint (MSG_ERROR, "FAILED (%s)\n", strerror (errno));
			return false;
		}
		MsgPrint (MSG_NORMAL, "succeeded (UID: %u, GID: %u)\n",
				  pw->pw_uid, pw->pw_gid);

		MsgPrint (MSG_NORMAL, "\n");
	}
#endif

	return true;
}


/*
====================
ParseCommandLine

Parse the options passed by the command line
====================
*/
static qboolean ParseCommandLine (int argc, const char* argv [])
{
	int ind = 1;
	unsigned int vlevel = max_msg_level;
	qboolean valid_options = true;

	while (ind < argc && valid_options)
	{
		// If it doesn't even look like an option, why bother?
		if (argv[ind][0] != '-')
			valid_options = false;

		else switch (argv[ind][1])
		{
#ifndef WIN32
			// Daemon mode
			case 'D':
				daemon_mode = true;
				break;
#endif

			// Help
			case 'h':
				valid_options = false;
				break;

			// Hash size
			case 'H':
				ind++;
				if (ind < argc)
					valid_options = Sv_SetHashSize (atoi (argv[ind]));
				else
					valid_options = false;
				break;

#ifndef WIN32
			// Jail path
			case 'j':
				ind++;
				if (ind < argc)
					jail_path = argv[ind];
				else
					valid_options = false;
				break;
#endif

			// Listen address
			case 'l':
				ind++;
				if (ind >= argc || argv[ind][0] == '\0')
					valid_options = false;
				else
					listen_name = argv[ind];
				break;

			// Address mapping
			case 'm':
				ind++;
				if (ind < argc)
					valid_options = Sv_AddAddressMapping (argv[ind]);
				else
					valid_options = false;
				break;

			// Maximum number of servers
			case 'n':
				ind++;
				if (ind < argc)
					valid_options = Sv_SetMaxNbServers (atoi (argv[ind]));
				else
					valid_options = false;
				break;

			// Port number
			case 'p':
			{
				unsigned short port_num = 0;
				ind++;
				if (ind < argc)
					port_num = atoi (argv[ind]);
				if (!port_num)
					valid_options = false;
				else
					master_port = port_num;
				break;
			}

#ifndef WIN32
			// Low privileges user
			case 'u':
				ind++;
				if (ind < argc)
					low_priv_user = argv[ind];
				else
					valid_options = false;
				break;
#endif

			// Verbose level
			case 'v':
				// If a verbose level has been specified
				if (ind + 1 < argc && argv[ind + 1][0] != '-')
				{
					ind++;
					vlevel = atoi (argv[ind]);
					if (vlevel > MSG_DEBUG)
						valid_options = false;
				}
				else
					vlevel = MSG_DEBUG;
				break;

			default:
				valid_options = false;
		}

		ind++;
	}

	// If the command line is OK, we can set the verbose level now
	if (valid_options)
	{
#ifndef WIN32
		// If we run as a daemon, don't bother printing anything
		if (daemon_mode)
			max_msg_level = MSG_NOPRINT;
		else
#endif
			max_msg_level = vlevel;
	}

	return valid_options;
}


/*
====================
PrintHelp

Print the command line syntax and the available options
====================
*/
static void PrintHelp (void)
{
	MsgPrint (MSG_ERROR,
			  "Syntax: dpmaster [options]\n"
			  "Available options are:\n"
#ifndef WIN32
			  "  -D               : run as a daemon\n"
#endif
			  "  -h               : this help\n"
			  "  -H <hash_size>   : hash size in bits, up to %u (default: %u)\n"
#ifndef WIN32
			  "  -j <jail_path>   : use <jail_path> as chroot path (default: %s)\n"
			  "                     only available when running with super-user privileges\n"
#endif
			  "  -l <address>     : listen on local address <address>\n"
			  "  -m <a1>=<a2>     : map address <a1> to <a2> when sending it to clients\n"
			  "                     addresses can contain a port number (ex: myaddr.net:1234)\n"
			  "  -n <max_servers> : maximum number of servers recorded (default: %u)\n"
			  "  -p <port_num>    : use port <port_num> (default: %u)\n"
#ifndef WIN32
			  "  -u <user>        : use <user> privileges (default: %s)\n"
			  "                     only available when running with super-user privileges\n"
#endif
			  "  -v [verbose_lvl] : verbose level, up to %u (default: %u; no value means max)\n"
			  "\n",
			  MAX_HASH_SIZE, DEFAULT_HASH_SIZE,
#ifndef WIN32
			  DEFAULT_JAIL_PATH,
#endif
			  DEFAULT_MAX_NB_SERVERS,
			  DEFAULT_MASTER_PORT,
#ifndef WIN32
			  DEFAULT_LOW_PRIV_USER,
#endif
			  MSG_DEBUG, MSG_NORMAL);
}


/*
====================
SecureInit

System independent initializations, called AFTER the security initializations
====================
*/
static qboolean SecureInit (void)
{
	struct sockaddr_in address;

	// Init the time and the random seed
	crt_time = time (NULL);
	srand (crt_time);

	// Initialize the server list and hash table
	if (!Sv_Init ())
		return false;

	// Open the socket
	sock = socket (PF_INET, SOCK_DGRAM, IPPROTO_UDP);
	if (sock < 0)
	{
		MsgPrint (MSG_ERROR, "> ERROR: socket creation failed (%s)\n",
				  strerror (errno));
		return false;
	}

	// Bind it to the master port
	memset (&address, 0, sizeof (address));
	address.sin_family = AF_INET;
	if (listen_name != NULL)
	{
		MsgPrint (MSG_NORMAL, "> Listening on address %s (%s)\n",
				  listen_name, inet_ntoa (listen_addr));
		address.sin_addr.s_addr = listen_addr.s_addr;
	}
	else
		address.sin_addr.s_addr = htonl (INADDR_ANY);
	address.sin_port = htons (master_port);
	if (bind (sock, (struct sockaddr*)&address, sizeof (address)) != 0)
	{
		MsgPrint (MSG_ERROR, "> ERROR: socket binding failed (%s)\n",
				  strerror (errno));
#ifdef WIN32
		closesocket (sock);
#else
		close (sock);
#endif
		return false;
	}
	MsgPrint (MSG_NORMAL, "> Listening on UDP port %hu\n",
			  ntohs (address.sin_port));

	return true;
}


/*
====================
main

Main function
====================
*/
int main (int argc, const char* argv [])
{
	struct sockaddr_in address;
	socklen_t addrlen;
	int nb_bytes;
	qbyte packet [MAX_PACKET_SIZE + 1];  // "+ 1" because we append a '\0'
	qboolean valid_options;

	// Get the options from the command line
	valid_options = ParseCommandLine (argc, argv);

	MsgPrint (MSG_NORMAL,
			  "\n"
			  "dpmaster, a master server for DarkPlaces, Quake III Arena and QFusion\n"
			  "(version " VERSION ", compiled the " __DATE__ " at " __TIME__ ")\n"
			  "\n");

	// If there was a mistake in the command line, print the help and exit
	if (!valid_options)
	{
		PrintHelp ();
		return EXIT_FAILURE;
	}

	// Initializations
	if (!SysInit () || !UnsecureInit () || !SecInit () || !SecureInit ())
		return EXIT_FAILURE;
	MsgPrint (MSG_NORMAL, "\n");

	// Until the end of times...
	for (;;)
	{
		// Get the next valid message
		addrlen = sizeof (address);
		nb_bytes = recvfrom (sock, packet, sizeof (packet) - 1, 0,
							 (struct sockaddr*)&address, &addrlen);
		if (nb_bytes <= 0)
		{
			MsgPrint (MSG_WARNING,
					  "> WARNING: \"recvfrom\" returned %d\n", nb_bytes);
			continue;
		}

		// If we may have to print something, rebuild the peer address buffer
		if (max_msg_level != MSG_NOPRINT)
			snprintf (peer_address, sizeof (peer_address), "%s:%hu",
					  inet_ntoa (address.sin_addr), ntohs (address.sin_port));

		// We print the packet contents if necessary
		// TODO: print the current time here
		if (max_msg_level >= MSG_DEBUG)
		{
			MsgPrint (MSG_DEBUG, "> New packet received from %s: ",
					  peer_address);
			PrintPacket (packet, nb_bytes);
		}

		// A few sanity checks
		if (nb_bytes < MIN_PACKET_SIZE)
		{
			MsgPrint (MSG_WARNING,
					  "> WARNING: rejected packet from %s (size = %d bytes)\n",
					  peer_address, nb_bytes);
			continue;
		}
		if (*((unsigned int*)packet) != 0xFFFFFFFF)
		{
			MsgPrint (MSG_WARNING,
					  "> WARNING: rejected packet from %s (invalid header)\n",
					  peer_address);
			continue;
		}
		if (! ntohs (address.sin_port))
		{
			MsgPrint (MSG_WARNING,
					  "> WARNING: rejected packet from %s (source port = 0)\n",
					  peer_address);
			continue;
		}

		// Append a '\0' to make the parsing easier and update the current time
		packet[nb_bytes] = '\0';
		crt_time = time (NULL);

		// Call HandleMessage with the remaining contents
		HandleMessage (packet + 4, nb_bytes - 4, &address);
	}
}


// ---------- Public functions ---------- //

/*
====================
MsgPrint

Print a message to screen, depending on its verbose level
====================
*/
int MsgPrint (msg_level_t msg_level, const char* format, ...)
{
	va_list args;
	int result;

	// If the message level is above the maximum level, don't print it
	if (msg_level > max_msg_level)
		return 0;

	va_start (args, format);
	result = vprintf (format, args);
	va_end (args);

	fflush (stdout);

	return result;
}
