/*
	$RCSfile$

	Copyright (C) 1996-1997  Id Software, Inc.

	This program is free software; you can redistribute it and/or
	modify it under the terms of the GNU General Public License
	as published by the Free Software Foundation; either version 2
	of the License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  

	See the GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program; if not, write to:
	
		Free Software Foundation, Inc.
		59 Temple Place - Suite 330
		Boston, MA  02111-1307, USA

*/
// console.c
static const char rcsid[] =
    "$Id$";

#ifdef HAVE_CONFIG_H
# include <config.h>
#else
# ifdef _WIN32
#  include <win32conf.h>
# endif
#endif

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

#include "client.h"
#include "cmd.h"
#include "console.h"
#include "cvar.h"
#include "draw.h"
#include "keys.h"
#include "screen.h"
#include "strlib.h"
#include "sys.h"


int         con_ormask;
console_t   con_main;
console_t   con_chat;
console_t  *con;						// point to either con_main or con_chat

int         con_linewidth;				// characters across screen
int         con_totallines;				// total lines in console scrollback

float       con_cursorspeed = 4;


cvar_t     *con_notifytime;

#define	NUM_CON_TIMES 4
float       con_times[NUM_CON_TIMES];	// realtime time the line was generated

								// for transparent notify lines

int         con_vislines;
int         con_notifylines;			// scan lines to clear for notify lines

qboolean    con_debuglog;

#define		MAXCMDLINE	256
extern char key_lines[32][MAXCMDLINE];
extern int  edit_line;
extern int  key_linepos;


qboolean    con_initialized;


void
Key_ClearTyping (void)
{
	key_lines[edit_line][1] = 0;		// clear any typing
	key_linepos = 1;
}

/*
================
Con_ToggleConsole_f
================
*/
void
Con_ToggleConsole_f (void)
{
	Key_ClearTyping ();

	if (key_dest == key_console) {
		if (cls.state == ca_active) {
			key_dest = key_game;
		}
	} else {
		key_dest = key_console;
	}

	Con_ClearNotify ();
}

/*
================
Con_Clear_f
================
*/
void
Con_Clear_f (void)
{
	Q_memset (con_main.text, ' ', CON_TEXTSIZE);
	Q_memset (con_chat.text, ' ', CON_TEXTSIZE);
}


/*
================
Con_ClearNotify
================
*/
void
Con_ClearNotify (void)
{
	int         i;

	for (i = 0; i < NUM_CON_TIMES; i++)
		con_times[i] = 0;
}


/*
================
Con_MessageMode_f
================
*/
void
Con_MessageMode_f (void)
{
	chat_team = false;
	key_dest = key_message;
}

/*
================
Con_MessageMode2_f
================
*/
void
Con_MessageMode2_f (void)
{
	chat_team = true;
	key_dest = key_message;
}

/*
================
Con_Resize

================
*/
void
Con_Resize (console_t *con)
{
	int         i, j, width, oldwidth, oldtotallines, numlines, numchars;
	char        tbuf[CON_TEXTSIZE];

	width = (vid.width >> 3) - 2;

	if (width == con_linewidth)
		return;

	if (width < 1)						// video hasn't been initialized yet
	{
		width = 38;
		con_linewidth = width;
		con_totallines = CON_TEXTSIZE / con_linewidth;
		Q_memset (con->text, ' ', CON_TEXTSIZE);
	} else {
		oldwidth = con_linewidth;
		con_linewidth = width;
		oldtotallines = con_totallines;
		con_totallines = CON_TEXTSIZE / con_linewidth;
		numlines = oldtotallines;

		if (con_totallines < numlines)
			numlines = con_totallines;

		numchars = oldwidth;

		if (con_linewidth < numchars)
			numchars = con_linewidth;

		Q_memcpy (tbuf, con->text, CON_TEXTSIZE);
		Q_memset (con->text, ' ', CON_TEXTSIZE);

		for (i = 0; i < numlines; i++) {
			for (j = 0; j < numchars; j++) {
				con->text[(con_totallines - 1 - i) * con_linewidth + j] =
					tbuf[((con->current - i + oldtotallines) %
						  oldtotallines) * oldwidth + j];
			}
		}

		Con_ClearNotify ();
	}

	con->current = con_totallines - 1;
	con->display = con->current;
}


/*
================
Con_CheckResize

If the line width has changed, reformat the buffer.
================
*/
void
Con_CheckResize (void)
{
	Con_Resize (&con_main);
	Con_Resize (&con_chat);
}


/*
================
Con_Init_Cvars
================
*/
void
Con_Init_Cvars (void)
{
	con_notifytime = Cvar_Get ("con_notifytime", "3", CVAR_NONE, NULL);
}

/*
================
Con_Init
================
*/
void
Con_Init (void)
{
	con_debuglog = COM_CheckParm ("-condebug");

	con = &con_main;
	con_linewidth = -1;
	Con_CheckResize ();

	Con_Printf ("Console initialized.\n");

	Cmd_AddCommand ("toggleconsole", Con_ToggleConsole_f);
	Cmd_AddCommand ("messagemode", Con_MessageMode_f);
	Cmd_AddCommand ("messagemode2", Con_MessageMode2_f);
	Cmd_AddCommand ("clear", Con_Clear_f);
	con_initialized = true;
}


/*
===============
Con_Linefeed
===============
*/
void
Con_Linefeed (void)
{
	con->x = 0;
	if (con->display == con->current)
		con->display++;
	con->current++;
	Q_memset (&con->text[(con->current % con_totallines) * con_linewidth]
			  , ' ', con_linewidth);
}

/*
================
Con_Print

Handles cursor positioning, line wrapping, etc
All console printing must go through this in order to be logged to disk
If no console is visible, the notify window will pop up.
================
*/
void
Con_Print (char *txt)
{
	int         y;
	int         c, l;
	static int  cr;
	int         mask;

	if (txt[0] == 1 || txt[0] == 2) {
		mask = 128;						// go to colored text
		txt++;
	} else
		mask = 0;


	while ((c = *txt)) {
		// count word length
		for (l = 0; l < con_linewidth; l++)
			if (txt[l] <= ' ')
				break;

		// word wrap
		if (l != con_linewidth && (con->x + l > con_linewidth))
			con->x = 0;

		txt++;

		if (cr) {
			con->current--;
			cr = false;
		}


		if (!con->x) {
			Con_Linefeed ();
			// mark time for transparent overlay
			if (con->current >= 0)
				con_times[con->current % NUM_CON_TIMES] = realtime;
		}

		switch (c) {
			case '\n':
				con->x = 0;
				break;

			case '\r':
				con->x = 0;
				cr = 1;
				break;

			default:					// display character and advance
				y = con->current % con_totallines;
				con->text[y * con_linewidth + con->x] = c | mask | con_ormask;
				con->x++;
				if (con->x >= con_linewidth)
					con->x = 0;
				break;
		}

	}
}


/*
================
Con_Printf

Handles cursor positioning, line wrapping, etc
================
*/
#define	MAXPRINTMSG	4096
void
Con_Printf (char *fmt, ...)
{
	va_list     argptr;
	char        msg[MAXPRINTMSG];

	va_start (argptr, fmt);
	vsnprintf (msg, sizeof (msg), fmt, argptr);
	va_end (argptr);

// also echo to debugging console
	Sys_Printf ("%s", msg);				// also echo to debugging console

// log all messages to file
	if (con_debuglog) {
		char        msg2[MAX_OSPATH + 32];

		// LordHavoc: this used to use va(), but that was too dangerous,
		// as Con_Printf and va() calls are often mixed.
		snprintf (msg2, sizeof (msg2), "%s/qconsole.log", com_gamedir);
		Sys_DebugLog (msg2, "%s", msg);
	}

	if (!con_initialized)
		return;

// write it to the scrollable buffer
	Con_Print (msg);

#if 0
// update the screen immediately if the console is displayed
	if (cls.state != ca_active) {
		// protect against infinite loop if something in SCR_UpdateScreen calls
		// Con_Printd
		if (!inupdate) {
			inupdate = true;
			SCR_UpdateScreen ();
			inupdate = false;
		}
	}
#endif
}

/*
================
Con_DPrintf

A Con_Printf that only shows up if the "developer" cvar is set
================
*/
void
Con_DPrintf (char *fmt, ...)
{
	va_list     argptr;
	char        msg[MAXPRINTMSG];

	if (!developer->value)
		return;							// don't confuse non-developers with
	// techie stuff...

	va_start (argptr, fmt);
	vsnprintf (msg, sizeof (msg), fmt, argptr);
	va_end (argptr);

	Con_Printf ("%s", msg);
}

/*
==============================================================================

DRAWING

==============================================================================
*/


/*
================
Con_DrawInput

The input line scrolls horizontally if typing goes beyond the right edge
================
*/
void
Con_DrawInput (void)
{
	int         y;
	int         i;
	char       *text;

	if (key_dest != key_console && cls.state == ca_active)
		return;							// don't draw anything (always draw if 
	// not active)

	text = key_lines[edit_line];

// add the cursor frame
	text[key_linepos] = 10 + ((int) (realtime * con_cursorspeed) & 1);

// fill out remainder with spaces
	for (i = key_linepos + 1; i < con_linewidth; i++)
		text[i] = ' ';

//  prestep if horizontally scrolling
	if (key_linepos >= con_linewidth)
		text += 1 + key_linepos - con_linewidth;

// draw it
	y = con_vislines - 22;

	for (i = 0; i < con_linewidth; i++)
		Draw_Character ((i + 1) << 3, con_vislines - 22, text[i]);

// remove cursor
	key_lines[edit_line][key_linepos] = 0;
}


/*
================
Con_DrawNotify

Draws the last few lines of output transparently over the game top
================
*/
void
Con_DrawNotify (void)
{
	int         x, v;
	char       *text;
	int         i;
	float       time;
	char       *s;
	int         skip;

	v = 0;
	for (i = con->current - NUM_CON_TIMES + 1; i <= con->current; i++) {
		if (i < 0)
			continue;
		time = con_times[i % NUM_CON_TIMES];
		if (time == 0)
			continue;
		time = realtime - time;
		if (time > con_notifytime->value)
			continue;
		text = con->text + (i % con_totallines) * con_linewidth;

		clearnotify = 0;
		scr_copytop = 1;

		for (x = 0; x < con_linewidth; x++)
			Draw_Character ((x + 1) << 3, v, text[x]);

		v += 8;
	}


	if (key_dest == key_message) {
		clearnotify = 0;
		scr_copytop = 1;

		if (chat_team) {
			Draw_String (8, v, "say_team:");
			skip = 11;
		} else {
			Draw_String (8, v, "say:");
			skip = 5;
		}

		s = chat_buffer;
		if (chat_bufferlen > (vid.width >> 3) - (skip + 1))
			s += chat_bufferlen - ((vid.width >> 3) - (skip + 1));

		Draw_String (skip << 3, v, s);

		Draw_Character ((Q_strlen(s) + skip) << 3, v,
						10 + ((int) (realtime * con_cursorspeed) & 1));
		v += 8;
	}

	if (v > con_notifylines)
		con_notifylines = v;
}

/*
================
Con_DrawConsole

Draws the console with the solid background
================
*/
void
Con_DrawConsole (int lines)
{
	int         i, j, x, y, n;
	int         rows;
	char       *text;
	int         row;
	char        dlbar[1024];

	if (lines <= 0)
		return;

// draw the background
	Draw_ConsoleBackground (lines);

// draw the text
	con_vislines = lines;

// changed to line things up better
	rows = (lines - 22) >> 3;			// rows of text to draw

	y = lines - 30;

// draw from the bottom up
	if (con->display != con->current) {
		// draw arrows to show the buffer is backscrolled
		for (x = 0; x < con_linewidth; x += 4)
			Draw_Character ((x + 1) << 3, y, '^');

		y -= 8;
		rows--;
	}

	row = con->display;
	for (i = 0; i < rows; i++, y -= 8, row--) {
		if (row < 0)
			break;
		if (con->current - row >= con_totallines)
			break;						// past scrollback wrap point

		text = con->text + (row % con_totallines) * con_linewidth;

		for (x = 0; x < con_linewidth; x++)
			Draw_Character ((x + 1) << 3, y, text[x]);
	}

	// draw the download bar
	// figure out width
	if (cls.download) {
		if ((text = Q_strrchr (cls.downloadname, '/')) != NULL)
			text++;
		else
			text = cls.downloadname;

		x = con_linewidth - ((con_linewidth * 7) / 40);
		y = x - Q_strlen (text) - 8;
		i = con_linewidth / 3;
		if (Q_strlen (text) > i) {
			y = x - i - 11;
			Q_strncpy (dlbar, text, i);
			dlbar[i] = 0;
			Q_strcat (dlbar, "...");
		} else
			Q_strcpy (dlbar, text);
		Q_strcat (dlbar, ": ");
		i = Q_strlen (dlbar);
		dlbar[i++] = '\x80';
		// where's the dot go?
		if (cls.downloadpercent == 0)
			n = 0;
		else
			n = y * cls.downloadpercent / 100;

		for (j = 0; j < y; j++)
			if (j == n)
				dlbar[i++] = '\x83';
			else
				dlbar[i++] = '\x81';
		dlbar[i++] = '\x82';
		dlbar[i] = 0;

		snprintf (dlbar + Q_strlen (dlbar), sizeof (dlbar) - Q_strlen (dlbar),
				  " %02d%%", cls.downloadpercent);

		// draw it
		y = con_vislines - 22 + 8;
		for (i = 0; i < Q_strlen (dlbar); i++)
			Draw_Character ((i + 1) << 3, y, dlbar[i]);
	}
// draw the input prompt, user text, and cursor if desired
	Con_DrawInput ();
}

/*
==================
Con_SafePrintf

Okay to call even when the screen can't be updated
==================
*/
void
Con_SafePrintf (char *fmt, ...)
{
	va_list     argptr;
	char        msg[1024];
	int         temp;

	va_start (argptr, fmt);
	vsnprintf (msg, sizeof (msg), fmt, argptr);
	va_end (argptr);

	temp = scr_disabled_for_loading;
	scr_disabled_for_loading = true;
	Con_Printf ("%s", msg);
	scr_disabled_for_loading = temp;
}

/*
	Con_DisplayList

	New function for tab-completion system
	Added by EvilTypeGuy
	MEGA Thanks to Taniwha

*/
void
Con_DisplayList(char **list)
{
	int	i = 0;
	int	pos = 0;
	int	len = 0;
	int	maxlen = 0;
	int	width = (con_linewidth - 4);
	char	**walk = list;

	while (*walk) {
		len = strlen(*walk);
		if (len > maxlen)
			maxlen = len;
		walk++;
	}
	maxlen += 1;

	while (*list) {
		len = strlen(*list);
		if (pos + maxlen >= width) {
			Con_Printf("\n");
			pos = 0;
		}

		Con_Printf("%s", *list);
		for (i = 0; i < (maxlen - len); i++)
			Con_Printf(" ");

		pos += maxlen;
		list++;
	}

	if (pos)
		Con_Printf("\n\n");
}

/*
	Con_CompleteCommandLine

	New function for tab-completion system
	Added by EvilTypeGuy
	Thanks to Fett erich@heintz.com
	Thanks to taniwha

*/
void
Con_CompleteCommandLine (void)
{
	char	*cmd = "";
	char	*s;
	int		c, v, a, i;
	int		cmd_len;
	char	**list[3] = {0, 0, 0};

	s = key_lines[edit_line] + 1;
	// Count number of possible matches
	c = Cmd_CompleteCountPossible(s);
	v = Cvar_CompleteCountPossible(s);
	a = Cmd_CompleteAliasCountPossible(s);
	
	if (!(c + v + a)) {	// No possible matches, let the user know they're insane
		Con_Printf("\n\nNo matching aliases, commands, or cvars were found.\n\n");
		return;
	}
	
	if (c + v + a == 1) {
		if (c)
			list[0] = Cmd_CompleteBuildList(s);
		else if (v)
			list[0] = Cvar_CompleteBuildList(s);
		else
			list[0] = Cmd_CompleteAliasBuildList(s);
		cmd = *list[0];
		cmd_len = strlen (cmd);
	} else {
		if (c)
			cmd = *(list[0] = Cmd_CompleteBuildList(s));
		if (v)
			cmd = *(list[1] = Cvar_CompleteBuildList(s));
		if (a)
			cmd = *(list[2] = Cmd_CompleteAliasBuildList(s));

		cmd_len = Q_strlen (s);
		do {
			for (i = 0; i < 3; i++) {
				char ch = cmd[cmd_len];
				char **l = list[i];
				if (l) {
					while (*l && (*l)[cmd_len] == ch)
						l++;
					if (*l)
						break;
				}
			}
			if (i == 3)
				cmd_len++;
		} while (i == 3);
		// 'quakebar'
		Con_Printf("\n\35");
		for (i = 0; i < con_linewidth - 4; i++)
			Con_Printf("\36");
		Con_Printf("\37\n");

		// Print Possible Commands
		if (c) {
			Con_Printf("%i possible command%s\n", c, (c > 1) ? "s: " : ":");
			Con_DisplayList(list[0]);
		}
		
		if (v) {
			Con_Printf("%i possible variable%s\n", v, (v > 1) ? "s: " : ":");
			Con_DisplayList(list[1]);
		}
		
		if (a) {
			Con_Printf("%i possible aliases%s\n", a, (a > 1) ? "s: " : ":");
			Con_DisplayList(list[2]);
		}
		return;
	}
	
	if (cmd) {
		Q_strncpy(key_lines[edit_line] + 1, cmd, cmd_len);
		key_linepos = cmd_len + 1;
		if (c + v + a == 1) {
			key_lines[edit_line][key_linepos] = ' ';
			key_linepos++;
		}
		key_lines[edit_line][key_linepos] = 0;
	}
	for (i = 0; i < 3; i++)
		if (list[i])
			free (list[i]);
}

