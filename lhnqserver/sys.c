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

#define WIN32_USETIMEGETTIME 1

#include "quakedef.h"
#include <errno.h>
#include <sys/types.h>
#include <time.h>
#include <limits.h>
#ifdef WIN32
#include <conio.h>
#else
#include <sys/time.h>
#include <unistd.h>
#endif

/*
===============================================================================

FILE IO

===============================================================================
*/

// LordHavoc: 256 pak files (was 10)
#define MAX_HANDLES             256
FILE	*sys_handles[MAX_HANDLES];

int		findhandle (void)
{
	int		i;
	
	for (i=1 ; i<MAX_HANDLES ; i++)
		if (!sys_handles[i])
			return i;
	Sys_Error ("out of handles");
	return -1;
}

/*
================
filelength
================
*/
int filelength (FILE *f)
{
	int		pos;
	int		end;

	pos = ftell (f);
	fseek (f, 0, SEEK_END);
	end = ftell (f);
	fseek (f, pos, SEEK_SET);

	return end;
}

int Sys_FileOpenRead (char *path, int *hndl)
{
	FILE	*f;
	int		i;
	
	i = findhandle ();

	f = fopen(path, "rb");
	if (!f)
	{
		*hndl = -1;
		return -1;
	}
	sys_handles[i] = f;
	*hndl = i;
	
	return filelength(f);
}

int Sys_FileOpenWrite (char *path)
{
	FILE	*f;
	int		i;
	
	i = findhandle ();

	f = fopen(path, "wb");
	if (!f)
		Sys_Error ("Error opening %s: %s", path,strerror(errno));
	sys_handles[i] = f;
	
	return i;
}

void Sys_FileClose (int handle)
{
	fclose (sys_handles[handle]);
	sys_handles[handle] = NULL;
}

void Sys_FileSeek (int handle, int position)
{
	fseek (sys_handles[handle], position, SEEK_SET);
}

int Sys_FileRead (int handle, void *dest, int count)
{
	return fread (dest, 1, count, sys_handles[handle]);
}

int Sys_FileWrite (int handle, void *data, int count)
{
	return fwrite (data, 1, count, sys_handles[handle]);
}

int	Sys_FileTime (char *path)
{
	FILE	*f;
	
	f = fopen(path, "rb");
	if (f)
	{
		fclose(f);
		return 1;
	}
	
	return -1;
}

void Sys_mkdir (char *path)
{
}


/*
===============================================================================

SYSTEM IO

===============================================================================
*/

void Sys_MakeCodeWriteable (unsigned long startaddr, unsigned long length)
{
}


void Sys_DebugLog(char *file, char *fmt, ...)
{
}

void Sys_Error (char *error, ...)
{
	va_list		argptr;
	char		text[1024];

	va_start (argptr,error);
	vsprintf (text, error,argptr);
	va_end (argptr);

	printf ("ERROR: %s\n", text);

	exit (1);
}

void Sys_Printf (char *fmt, ...)
{
	va_list		argptr;
	
	va_start (argptr,fmt);
	vprintf (fmt,argptr);
	va_end (argptr);
}

void Sys_Quit (void)
{
	exit (0);
}

double Sys_FloatTime (void)
{
#ifdef WIN32
	// LordHavoc: note to people modifying the WIN32 code, DWORD is specifically defined as an unsigned 32bit number, therefore the 65536.0 * 65536.0 is fine.
#if WIN32_USETIMEGETTIME
	// timeGetTime
	// platform:
	// Windows 95/98/ME/NT/2000
	// features:
	// reasonable accuracy (millisecond)
	// issues:
	// none known
	static int first = true;
	static double oldtime = 0.0, basetime = 0.0, old = 0.0;
	double newtime, now;

	now = (double) timeGetTime () - basetime;

	if (first)
	{
		first = false;
		basetime = now;
		now = 0;
	}

	if (now < old)
	{
		// wrapped
		basetime -= (65536.0 * 65536.0);
		now += (65536.0 * 65536.0);
	}
	old = now;

	newtime = now / 1000.0;

	if (newtime < oldtime)
		Sys_Error("Sys_DoubleTime: time running backwards??\n");

	oldtime = newtime;

	return newtime;
#else
	// QueryPerformanceCounter
	// platform:
	// Windows 95/98/ME/NT/2000
	// features:
	// very accurate (CPU cycles)
	// known issues:
	// does not necessarily match realtime too well (tends to get faster and faster in win98)
	static int first = true;
	static double oldtime = 0.0, basetime = 0.0, timescale = 0.0;
	double newtime;
	LARGE_INTEGER PerformanceFreq;
	LARGE_INTEGER PerformanceCount;

	if (first)
	{
		if (!QueryPerformanceFrequency (&PerformanceFreq))
			Sys_Error ("No hardware timer available");

#ifdef __BORLANDC__
		timescale = 1.0 / ((double) PerformanceFreq.u.LowPart + (double) PerformanceFreq.u.HighPart * 65536.0 * 65536.0);
#else
		timescale = 1.0 / ((double) PerformanceFreq.LowPart + (double) PerformanceFreq.HighPart * 65536.0 * 65536.0);
#endif	
	}

	QueryPerformanceCounter (&PerformanceCount);

#ifdef __BORLANDC__
	newtime = ((double) PerformanceCount.u.LowPart + (double) PerformanceCount.u.HighPart * 65536.0 * 65536.0) * timescale - basetime;
#else
	newtime = ((double) PerformanceCount.LowPart + (double) PerformanceCount.HighPart * 65536.0 * 65536.0) * timescale - basetime;
#endif	

	if (first)
	{
		first = false;
		basetime = newtime;
		newtime = 0;
	}

	if (newtime < oldtime)
		Sys_Error("Sys_DoubleTime: time running backwards??\n");

	oldtime = newtime;

	return newtime;
#endif
#else
	// gettimeofday
	// platform:
	// BSD compatible UNIX
	// features:
	// good accuracy
	// isssues:
	// none known
	static int first = true;
	static double oldtime = 0.0, basetime = 0.0;
	double newtime;
	struct timeval tp;
	struct timezone tzp; 

	gettimeofday(&tp, &tzp);

	newtime = (double) ((unsigned long) tp.tv_sec) + tp.tv_usec/1000000.0 - basetime;

	if (first)
	{
		first = false;
		basetime = newtime;
		newtime = 0.0;
	}

	if (newtime < oldtime)
		Sys_Error("Sys_DoubleTime: time running backwards??\n");

	oldtime = newtime;

	return newtime;
#endif
}

void Sys_Sleep (void)
{
}


void Sys_SendKeyEvents (void)
{
}

char *Sys_ConsoleInput (void)
{
#ifdef WIN32
	static char text[256];
	static int  len;
	int         c;

	// read a line out
	while (kbhit ())
	{
		c = _getch ();
		putch (c);
		if (c == '\r')
		{
			text[len] = 0;
			putch ('\n');
			len = 0;
			return text;
		}
		if (c == 8)
		{
			if (len)
			{
				putch (' ');
				putch (c);
				len--;
				text[len] = 0;
			}
			continue;
		}
		text[len] = c;
		len++;
		text[len] = 0;
		if (len == sizeof (text))
			len = 0;
	}

	return NULL;
#else
    static char text[256];
    int     len;
	fd_set	fdset;
    struct timeval timeout;

	FD_ZERO(&fdset);
	FD_SET(0, &fdset); // stdin
	timeout.tv_sec = 0;
	timeout.tv_usec = 0;
	if (select (1, &fdset, NULL, NULL, &timeout) == -1 || !FD_ISSET(0, &fdset))
		return NULL;

	len = read (0, text, sizeof(text));
	if (len < 1)
		return NULL;
	text[len-1] = 0;    // rip off the \n and terminate

	return text;
#endif
}



/*
==================
main

==================
*/
char	*newargv[256];

int main (int argc, char **argv)
{
	int t;
	double time, oldtime;

	memset (&host_parms, 0, sizeof(host_parms));

	host_parms.memsize = DEFAULTMEM * 1048576;

	if ((t = COM_CheckParm("-heapsize")))
	{
		t++;
		if (t < com_argc)
			host_parms.memsize = atoi (com_argv[t]) * 1024;
	}
	else if ((t = COM_CheckParm("-mem")) || (t = COM_CheckParm("-winmem")))
	{
		t++;
		if (t < com_argc)
			host_parms.memsize = atoi (com_argv[t]) * 1048576;
	}

	host_parms.membase = qmalloc(host_parms.memsize);

	host_parms.basedir = ".";

	COM_InitArgv (argc, argv);

	host_parms.argc = argc;
	host_parms.argv = argv;


#if WIN32 && WIN32_USETIMEGETTIME
	// make sure the timer is high precision, otherwise NT gets 18ms resolution
	// LordHavoc:
	// Windows 2000 Advanced Server (and possibly other versions)
	// apparently have a broken timer, because it runs at more like 10x speed
	// if this isn't used, heh
	timeBeginPeriod (1);
#endif

	printf ("Host_Init\n");
	Host_Init ();

	oldtime = Sys_FloatTime ();

    /* main window message loop */
	while (1)
	{
		time = Sys_FloatTime();
		if (time - oldtime < sys_ticrate.value )
		{
#ifdef WIN32
			Sleep(1);
#else
			usleep(1);
#endif
			continue;
		}

		Host_Frame ( time - oldtime );
		oldtime = time;
	}

    /* return success of application */
    return TRUE;
}

