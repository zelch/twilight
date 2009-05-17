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

#ifndef CONSOLE_H
#define CONSOLE_H

//
// console
//
extern int con_totallines;
extern int con_backscroll;
extern qboolean con_initialized;

void Con_Rcon_Redirect_Init(lhnetsocket_t *sock, lhnetaddress_t *dest);
void Con_Rcon_Redirect_End();
void Con_Rcon_Redirect_Abort();

void Con_CheckResize (void);
void Con_Init (void);
void Con_Init_Commands (void);
void Con_DrawConsole (int lines);
void Con_Print(const char *txt);
void Con_PrintNotToHistory(const char *txt);
void Con_Printf(const char *fmt, ...) DP_FUNC_PRINTF(1);
void Con_DPrint(const char *msg);
void Con_DPrintf(const char *fmt, ...) DP_FUNC_PRINTF(1);
void Con_Clear_f (void);
void Con_DrawNotify (void);
void Con_ClearNotify (void);
void Con_ToggleConsole_f (void);

qboolean GetMapList (const char *s, char *completedname, int completednamebufferlength);

// wrapper function to attempt to either complete the command line
// or to list possible matches grouped by type
// (i.e. will display possible variables, aliases, commands
// that match what they've typed so far)
void Con_CompleteCommandLine(void);

// Generic libs/util/console.c function to display a list
// formatted in columns on the console
void Con_DisplayList(const char **list);


//
// log
//
void Log_Init (void);
void Log_Close (void);
void Log_Start (void);
void Log_DestBuffer_Flush (void); // call this once per frame to send out replies to rcon streaming clients

void Log_Printf(const char *logfilename, const char *fmt, ...) DP_FUNC_PRINTF(2);

#define CON_MASK_HIDENOTIFY 128
#define CON_MASK_CHAT 1
#define CON_MASK_INPUT 2
#define CON_MASK_LOADEDHISTORY 4

void Con_AddLine(const char *line, int len, int mask);
int Con_FindPrevLine(int mask_must, int mask_mustnot, int start);
int Con_FindNextLine(int mask_must, int mask_mustnot, int start);
const char *Con_GetLine(int i);
int Con_GetLineID(int i);
int Con_GetLineByID(int i);

#endif

