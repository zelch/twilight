
#include "quakedef.h"
#include <time.h>

extern cvar_t	timestamps;
extern cvar_t	timeformat;

static int sys_nostdout = false;

/* The translation table between the graphical font and plain ASCII  --KB */
static char qfont_table[256] = {
	'\0', '#',  '#',  '#',  '#',  '.',  '#',  '#',
	'#',  9,    10,   '#',  ' ',  13,   '.',  '.',
	'[',  ']',  '0',  '1',  '2',  '3',  '4',  '5',
	'6',  '7',  '8',  '9',  '.',  '<',  '=',  '>',
	' ',  '!',  '"',  '#',  '$',  '%',  '&',  '\'',
	'(',  ')',  '*',  '+',  ',',  '-',  '.',  '/',
	'0',  '1',  '2',  '3',  '4',  '5',  '6',  '7',
	'8',  '9',  ':',  ';',  '<',  '=',  '>',  '?',
	'@',  'A',  'B',  'C',  'D',  'E',  'F',  'G',
	'H',  'I',  'J',  'K',  'L',  'M',  'N',  'O',
	'P',  'Q',  'R',  'S',  'T',  'U',  'V',  'W',
	'X',  'Y',  'Z',  '[',  '\\', ']',  '^',  '_',
	'`',  'a',  'b',  'c',  'd',  'e',  'f',  'g',
	'h',  'i',  'j',  'k',  'l',  'm',  'n',  'o',
	'p',  'q',  'r',  's',  't',  'u',  'v',  'w',
	'x',  'y',  'z',  '{',  '|',  '}',  '~',  '<',

	'<',  '=',  '>',  '#',  '#',  '.',  '#',  '#',
	'#',  '#',  ' ',  '#',  ' ',  '>',  '.',  '.',
	'[',  ']',  '0',  '1',  '2',  '3',  '4',  '5',
	'6',  '7',  '8',  '9',  '.',  '<',  '=',  '>',
	' ',  '!',  '"',  '#',  '$',  '%',  '&',  '\'',
	'(',  ')',  '*',  '+',  ',',  '-',  '.',  '/',
	'0',  '1',  '2',  '3',  '4',  '5',  '6',  '7',
	'8',  '9',  ':',  ';',  '<',  '=',  '>',  '?',
	'@',  'A',  'B',  'C',  'D',  'E',  'F',  'G',
	'H',  'I',  'J',  'K',  'L',  'M',  'N',  'O',
	'P',  'Q',  'R',  'S',  'T',  'U',  'V',  'W',
	'X',  'Y',  'Z',  '[',  '\\', ']',  '^',  '_',
	'`',  'a',  'b',  'c',  'd',  'e',  'f',  'g',
	'h',  'i',  'j',  'k',  'l',  'm',  'n',  'o', 
	'p',  'q',  'r',  's',  't',  'u',  'v',  'w',
	'x',  'y',  'z',  '{',  '|',  '}',  '~',  '<'
};

#ifdef WIN32
extern HANDLE hinput, houtput;
#endif

#define MAX_PRINT_MSG	16384
void Sys_Printf (char *fmt, ...)
{
	va_list		argptr;
	char		start[MAX_PRINT_MSG];	// String we started with
	char		stamp[MAX_PRINT_MSG];	// Time stamp
	char		final[MAX_PRINT_MSG];	// String we print

	time_t		mytime = 0;
	struct tm	*local = NULL;

	unsigned char		*p;
#ifdef WIN32
	DWORD		dummy;
#endif

	va_start (argptr, fmt);
#ifdef HAVE_VSNPRINTF
	vsnprintf (start, sizeof(start), fmt, argptr);
#else
	vsprintf (start, fmt, argptr);
#endif
	va_end (argptr);

	if (sys_nostdout)
		return;

	if (timestamps.value)
	{
		mytime = time (NULL);
		local = localtime (&mytime);
		strftime (stamp, sizeof (stamp), timeformat.string, local);
		
		snprintf (final, sizeof (final), "%s%s", stamp, start);
	}
	else
		snprintf (final, sizeof (final), "%s", start);

	for (p = (unsigned char *) final; *p; p++)
		*p = qfont_table[*p];
#ifdef WIN32
	if (cls.state == ca_dedicated)
		WriteFile(houtput, final, strlen (final), &dummy, NULL);	
#else
	puts(final);
#endif
//	for (p = (unsigned char *) final; *p; p++)
//		putc (qfont_table[*p], stdout);
#ifndef WIN32
	fflush (stdout);
#endif
}

void Sys_Shared_Init(void)
{
	if (COM_CheckParm("-nostdout"))
		sys_nostdout = 1;
	else
	{
#if defined(__linux__)
		fcntl(0, F_SETFL, fcntl (0, F_GETFL, 0) | FNDELAY);
		printf ("DarkPlaces Linux   GL %.2f build %3i", (float) VERSION, buildnumber);
#elif defined(WIN32)
		printf ("DarkPlaces Windows GL %.2f build %3i", (float) VERSION, buildnumber);
#else
		printf ("DarkPlaces Unknown GL %.2f build %3i", (float) VERSION, buildnumber);
#endif
	}
}
