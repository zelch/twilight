/*
Copyright (C) 1996-1997 Id Software, Inc.

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
// console.c

#ifdef NeXT
#include <libc.h>
#endif
#ifndef _MSC_VER
#ifndef __BORLANDC__
#include <unistd.h>
#endif
#endif
#ifdef WIN32
#include <io.h>
#endif
#include <fcntl.h>
#include "quakedef.h"

cvar_t		logfile = {"logfile","0"};

qboolean	con_debuglog;

#define MAXCMDLINE 256

qboolean	con_initialized;


/*
================
Con_Init
================
*/
void Con_Init (void)
{
	Cvar_RegisterVariable(&logfile);
	con_debuglog = COM_CheckParm("-condebug");

	if (con_debuglog)
	{
		unlink (va("%s/qconsole.log", com_gamedir));
		Cvar_Set("logfile", "1");
	}
}


/*
================
Con_DebugLog
================
*/
void Con_DebugLog(char *file, char *fmt, ...)
{
    va_list argptr; 
    static char data[1024];
    int fd;
    
    va_start(argptr, fmt);
    vsprintf(data, fmt, argptr);
    va_end(argptr);
    fd = open(file, O_WRONLY | O_CREAT | O_APPEND, 0666);
    write(fd, data, strlen(data));
    close(fd);
}


/*
================
Con_Printf

Handles cursor positioning, line wrapping, etc
================
*/
// LordHavoc: increased from 4096 to 16384
#define	MAXPRINTMSG	16384
// FIXME: make a buffer size safe vsprintf?
void Con_Printf (char *fmt, ...)
{
	va_list		argptr;
	char		msg[MAXPRINTMSG];
	
	va_start (argptr,fmt);
	vsprintf (msg,fmt,argptr);
	va_end (argptr);
	
// also echo to debugging console
	Sys_Printf ("%s", msg);	// also echo to debugging console

// log all messages to file
	if (con_debuglog)
		Con_DebugLog(va("%s/qconsole.log",com_gamedir), "%s", msg);
}

/*
================
Con_DPrintf

A Con_Printf that only shows up if the "developer" cvar is set
================
*/
void Con_DPrintf (char *fmt, ...)
{
	va_list		argptr;
	char		msg[MAXPRINTMSG];
		
	if (!developer.value)
		return;			// don't confuse non-developers with techie stuff...

	va_start (argptr,fmt);
	vsprintf (msg,fmt,argptr);
	va_end (argptr);
	
	Con_Printf ("%s", msg);
}


/*
==================
Con_SafePrintf

Okay to call even when the screen can't be updated
==================
*/
void Con_SafePrintf (char *fmt, ...)
{
	va_list		argptr;
	char		msg[1024];
		
	va_start (argptr,fmt);
	vsprintf (msg,fmt,argptr);
	va_end (argptr);

	Con_Printf ("%s", msg);
}
