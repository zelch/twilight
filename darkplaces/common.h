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

#ifndef COMMON_H
#define COMMON_H

// MSVC has a different name for several standard functions
#ifdef WIN32
# define snprintf _snprintf
# define vsnprintf _vsnprintf
# define strcasecmp stricmp
# define strncasecmp strnicmp
#endif


//============================================================================

typedef struct sizebuf_s
{
	qboolean	allowoverflow;	// if false, do a Sys_Error
	qboolean	overflowed;		// set to true if the buffer size failed
	qbyte		*data;
	mempool_t	*mempool;
	int			maxsize;
	int			cursize;
} sizebuf_t;

void SZ_Alloc (sizebuf_t *buf, int startsize, const char *name);
void SZ_Free (sizebuf_t *buf);
void SZ_Clear (sizebuf_t *buf);
void *SZ_GetSpace (sizebuf_t *buf, int length);
void SZ_Write (sizebuf_t *buf, const void *data, int length);
void SZ_Print (sizebuf_t *buf, const char *data);	// strcats onto the sizebuf
void SZ_HexDumpToConsole(const sizebuf_t *buf);

void Com_HexDumpToConsole(const qbyte *data, int size);

//============================================================================
#if !defined(ENDIAN_LITTLE) && !defined(ENDIAN_BIG)
#if  defined(__i386__) || defined(__ia64__) || defined(WIN32) || (defined(__alpha__) || defined(__alpha)) || defined(__arm__) || (defined(__mips__) && defined(__MIPSEL__)) || defined(__LITTLE_ENDIAN__)
#define ENDIAN_LITTLE
#else
#define ENDIAN_BIG
#endif
#endif

short ShortSwap (short l);
int LongSwap (int l);
float FloatSwap (float f);

#ifdef ENDIAN_LITTLE
// little endian
#define BigShort(l) ShortSwap(l)
#define LittleShort(l) (l)
#define BigLong(l) LongSwap(l)
#define LittleLong(l) (l)
#define BigFloat(l) FloatSwap(l)
#define LittleFloat(l) (l)
#elif defined(ENDIAN_BIG)
// big endian
#define BigShort(l) (l)
#define LittleShort(l) ShortSwap(l)
#define BigLong(l) (l)
#define LittleLong(l) LongSwap(l)
#define BigFloat(l) (l)
#define LittleFloat(l) FloatSwap(l)
#else
// figure it out at runtime
extern short (*BigShort) (short l);
extern short (*LittleShort) (short l);
extern int (*BigLong) (int l);
extern int (*LittleLong) (int l);
extern float (*BigFloat) (float l);
extern float (*LittleFloat) (float l);
#endif

unsigned int BuffBigLong (const qbyte *buffer);
unsigned short BuffBigShort (const qbyte *buffer);
unsigned int BuffLittleLong (const qbyte *buffer);
unsigned short BuffLittleShort (const qbyte *buffer);


//============================================================================

void MSG_WriteChar (sizebuf_t *sb, int c);
void MSG_WriteByte (sizebuf_t *sb, int c);
void MSG_WriteShort (sizebuf_t *sb, int c);
void MSG_WriteLong (sizebuf_t *sb, int c);
void MSG_WriteFloat (sizebuf_t *sb, float f);
void MSG_WriteString (sizebuf_t *sb, const char *s);
void MSG_WriteCoord (sizebuf_t *sb, float f);
void MSG_WriteAngle (sizebuf_t *sb, float f);
void MSG_WritePreciseAngle (sizebuf_t *sb, float f);
void MSG_WriteDPCoord (sizebuf_t *sb, float f);

extern	int			msg_readcount;
extern	qboolean	msg_badread;		// set if a read goes beyond end of message

void MSG_BeginReading (void);
int MSG_ReadLittleShort (void);
int MSG_ReadBigShort (void);
int MSG_ReadLittleLong (void);
int MSG_ReadBigLong (void);
float MSG_ReadLittleFloat (void);
float MSG_ReadBigFloat (void);
char *MSG_ReadString (void);
int MSG_ReadBytes (int numbytes, unsigned char *out);

#define MSG_ReadChar() (msg_readcount >= net_message.cursize ? (msg_badread = true, -1) : (signed char)net_message.data[msg_readcount++])
#define MSG_ReadByte() (msg_readcount >= net_message.cursize ? (msg_badread = true, -1) : (unsigned char)net_message.data[msg_readcount++])
#define MSG_ReadShort MSG_ReadLittleShort
#define MSG_ReadLong MSG_ReadLittleLong
#define MSG_ReadFloat MSG_ReadLittleFloat

float MSG_ReadCoord (void);

#define MSG_ReadAngle() (MSG_ReadByte() * (360.0f / 256.0f))
#define MSG_ReadPreciseAngle() (MSG_ReadShort() * (360.0f / 65536.0f))

#define MSG_ReadVector(v) ((v)[0] = MSG_ReadCoord(), (v)[1] = MSG_ReadCoord(), (v)[2] = MSG_ReadCoord())

//============================================================================

extern char com_token[1024];

int COM_ParseToken(const char **datapointer, int returnnewline);
int COM_ParseTokenConsole(const char **datapointer);

extern int com_argc;
extern const char **com_argv;

int COM_CheckParm (const char *parm);
void COM_Init (void);
void COM_InitArgv (void);
void COM_InitGameType (void);

char	*va(const char *format, ...);
// does a varargs printf into a temp buffer


//============================================================================

extern	struct cvar_s	registered;

#define GAME_NORMAL 0
#define GAME_HIPNOTIC 1
#define GAME_ROGUE 2
#define GAME_NEHAHRA 3
#define GAME_NEXUIZ 4
#define GAME_TRANSFUSION 5
#define GAME_GOODVSBAD2 6
#define GAME_TEU 7
#define GAME_BATTLEMECH 8
#define GAME_ZYMOTIC 9
#define GAME_FNIGGIUM 10
#define GAME_SETHERAL 11
#define GAME_SOM 12
#define GAME_TENEBRAE 13 // full of evil hackery

extern int gamemode;
extern char *gamename;
extern char *gamedirname;
extern char com_modname[MAX_OSPATH];

void COM_ToLowerString (const char *in, char *out, size_t size_out);
void COM_ToUpperString (const char *in, char *out, size_t size_out);
int COM_StringBeginsWith(const char *s, const char *match);

int COM_ReadAndTokenizeLine(const char **text, char **argv, int maxargc, char *tokenbuf, int tokenbufsize, const char *commentprefix);

typedef struct stringlist_s
{
	struct stringlist_s *next;
	char *text;
} stringlist_t;

int matchpattern(char *in, char *pattern, int caseinsensitive);
stringlist_t *stringlistappend(stringlist_t *current, char *text);
void stringlistfree(stringlist_t *current);
stringlist_t *stringlistsort(stringlist_t *start);
stringlist_t *listdirectory(char *path);
void freedirectory(stringlist_t *list);

char *SearchInfostring(const char *infostring, const char *key);


// strlcat and strlcpy, from OpenBSD
// Most (all?) BSDs already have them
#if defined(__OpenBSD__) || defined(__NetBSD__) || defined(__FreeBSD__) || (defined(__APPLE__) && defined(__MACH__))
# define HAVE_STRLCAT 1
# define HAVE_STRLCPY 1
#endif

#ifndef HAVE_STRLCAT
/*
 * Appends src to string dst of size siz (unlike strncat, siz is the
 * full size of dst, not space left).  At most siz-1 characters
 * will be copied.  Always NUL terminates (unless siz <= strlen(dst)).
 * Returns strlen(src) + MIN(siz, strlen(initial dst)).
 * If retval >= siz, truncation occurred.
 */
size_t strlcat(char *dst, const char *src, size_t siz);
#endif  // #ifndef HAVE_STRLCAT

#ifndef HAVE_STRLCPY
/*
 * Copy src to string dst of size siz.  At most siz-1 characters
 * will be copied.  Always NUL terminates (unless siz == 0).
 * Returns strlen(src); if retval >= siz, truncation occurred.
 */
size_t strlcpy(char *dst, const char *src, size_t siz);

#endif  // #ifndef HAVE_STRLCPY

#endif

