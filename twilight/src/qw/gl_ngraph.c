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
// gl_ngraph.c
static const char rcsid[] =
    "$Id$";

#ifdef HAVE_CONFIG_H
# include <config.h>
#else
# ifdef _WIN32
#  include <win32conf.h>
# endif
#endif

#include "client.h"
#include "draw.h"
#include "glquake.h"
#include "menu.h"
#include "sbar.h"

extern Uint8 *draw_chars;				// 8*8 graphic characters

int         netgraphtexture;			// netgraph texture

#define NET_GRAPHHEIGHT 32

static Uint8 ngraph_texels[NET_GRAPHHEIGHT][NET_TIMINGS];

static void
R_LineGraph (int x, int h)
{
	int         i;
	int         s;
	int         color;

	s = NET_GRAPHHEIGHT;

	if (h == 10000)
		color = 0x6f;					// yellow
	else if (h == 9999)
		color = 0x4f;					// red
	else if (h == 9998)
		color = 0xd0;					// blue
	else
		color = 0xfe;					// white

	if (h > s)
		h = s;

	for (i = 0; i < h; i++)
		if (i & 1)
			ngraph_texels[NET_GRAPHHEIGHT - i - 1][x] = 0xff;
		else
			ngraph_texels[NET_GRAPHHEIGHT - i - 1][x] = (Uint8) color;

	for (; i < s; i++)
		ngraph_texels[NET_GRAPHHEIGHT - i - 1][x] = (Uint8) 0xff;
}

void
Draw_CharToNetGraph (int x, int y, int num)
{
	int         row, col;
	Uint8      *source;
	int         drawline;
	int         nx;

	row = num >> 4;
	col = num & 15;
	source = draw_chars + (row << 10) + (col << 3);

	for (drawline = 8; drawline; drawline--, y++) {
		for (nx = 0; nx < 8; nx++)
			if (source[nx] != 255)
				ngraph_texels[y][nx + x] = 0x60 + source[nx];
		source += 128;
	}
}


/*
==============
R_NetGraph
==============
*/
void
R_NetGraph (void)
{
	int         a, x, i, y;
	int         lost;
	char        st[80];
	unsigned    ngraph_pixels[NET_GRAPHHEIGHT][NET_TIMINGS];

	x = 0;
	lost = CL_CalcNet ();
	for (a = 0; a < NET_TIMINGS; a++) {
		i = (cls.netchan.outgoing_sequence - a) & NET_TIMINGSMASK;
		R_LineGraph (NET_TIMINGS - 1 - a, packet_latency[i]);
	}

	// now load the netgraph texture into gl and draw it
	for (y = 0; y < NET_GRAPHHEIGHT; y++)
		for (x = 0; x < NET_TIMINGS; x++)
			ngraph_pixels[y][x] = d_8to32table[ngraph_texels[y][x]];

	x = -(((int)vid.width - 320) >> 1);
	y = vid.height - sb_lines - 24 - NET_GRAPHHEIGHT - 1;

	M_DrawTextBox (x, y, NET_TIMINGS / 8, NET_GRAPHHEIGHT / 8 + 1);
	y += 8;

	snprintf (st, sizeof (st), "%3i%% packet loss", lost);
	Draw_String (8, y, st);
	y += 8;

	qglBindTexture (GL_TEXTURE_2D, netgraphtexture);

	qglTexImage2D (GL_TEXTURE_2D, 0, gl_alpha_format,
				  NET_TIMINGS, NET_GRAPHHEIGHT, 0, GL_RGBA,
				  GL_UNSIGNED_BYTE, ngraph_pixels);

	qglTexParameterf (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, gl_filter_max);
	qglTexParameterf (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, gl_filter_max);

	x = 8;
	qglBegin (GL_QUADS);
	qglTexCoord2f (0, 0);
	qglVertex2f (x, y);
	qglTexCoord2f (1, 0);
	qglVertex2f (x + NET_TIMINGS, y);
	qglTexCoord2f (1, 1);
	qglVertex2f (x + NET_TIMINGS, y + NET_GRAPHHEIGHT);
	qglTexCoord2f (0, 1);
	qglVertex2f (x, y + NET_GRAPHHEIGHT);
	qglEnd ();
}
