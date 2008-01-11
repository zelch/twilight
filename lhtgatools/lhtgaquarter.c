
/*
Copyright (C) 2006 Forest Hale

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

#include <stdlib.h>
#include <stdio.h>
#include <strings.h>
#include <memory.h>
#include "tga.h"
#include "file.h"

int verbose = 0;
int nowrites = 0;

// in can be the same as out
void MipReduce(const unsigned char *in, unsigned char *out, int *width, int *height, int destwidth, int destheight)
{
	const unsigned char *inrow;
	int x, y, nextrow;
	// note: if given odd width/height this discards the last row/column of
	// pixels, rather than doing a box-filter scale down (which would be slow)
	inrow = in;
	nextrow = *width * 4;
	if (*width > destwidth && *height > destheight)
	{
		// reduce both
		*width >>= 1;
		*height >>= 1;
		for (y = 0;y < *height;y++, inrow += nextrow * 2)
		{
			for (in = inrow, x = 0;x < *width;x++)
			{
				out[0] = (unsigned char) ((in[0] + in[4] + in[nextrow  ] + in[nextrow+4]) >> 2);
				out[1] = (unsigned char) ((in[1] + in[5] + in[nextrow+1] + in[nextrow+5]) >> 2);
				out[2] = (unsigned char) ((in[2] + in[6] + in[nextrow+2] + in[nextrow+6]) >> 2);
				out[3] = (unsigned char) ((in[3] + in[7] + in[nextrow+3] + in[nextrow+7]) >> 2);
				out += 4;
				in += 8;
			}
		}
	}
	else if (*width > destwidth)
	{
		// reduce width
		*width >>= 1;
		for (y = 0;y < *height;y++, inrow += nextrow)
		{
			for (in = inrow, x = 0;x < *width;x++)
			{
				out[0] = (unsigned char) ((in[0] + in[4]) >> 1);
				out[1] = (unsigned char) ((in[1] + in[5]) >> 1);
				out[2] = (unsigned char) ((in[2] + in[6]) >> 1);
				out[3] = (unsigned char) ((in[3] + in[7]) >> 1);
				out += 4;
				in += 8;
			}
		}
	}
	else if (*height > destheight)
	{
		// reduce height
		*height >>= 1;
		for (y = 0;y < *height;y++, inrow += nextrow * 2)
		{
			for (in = inrow, x = 0;x < *width;x++)
			{
				out[0] = (unsigned char) ((in[0] + in[nextrow  ]) >> 1);
				out[1] = (unsigned char) ((in[1] + in[nextrow+1]) >> 1);
				out[2] = (unsigned char) ((in[2] + in[nextrow+2]) >> 1);
				out[3] = (unsigned char) ((in[3] + in[nextrow+3]) >> 1);
				out += 4;
				in += 4;
			}
		}
	}
}

int tgaquarter(const char *filename)
{
	unsigned char *pixels;
	int width, height;

	pixels = LoadTGA(filename, &width, &height);
	if (!pixels)
	{
		fprintf(stderr, "unable to decode image file %s as targa format\n", filename);
		return 10;
	}

	if (width == 1 && height == 1)
	{
		free(pixels);
		return 0;
	}
	
	if (verbose)
		fprintf(stderr, "%s reduced from %ix%i to", filename, width, height);

	MipReduce(pixels, pixels, &width, &height, 1, 1);

	if (!nowrites)
		SaveTGA(filename, width, height, pixels);

	if (verbose)
		fprintf(stderr, " %ix%i\n", width, height);

	free(pixels);

	return 0;
}

int main(int argc, char **argv)
{
	int c;
	int ignoreopts = 0;
	if (argc < 2)
		goto usage;
	verbose = 0;
	nowrites = 0;
	for (c = 1;c < argc;c++)
	{
		if (!argv[c])
			continue;
		if (ignoreopts || argv[c][0] != '-')
		{
			// filename
			tgaquarter(argv[c]);
			continue;
		}
		if (!strcmp(argv[c], "-v") || !strcmp(argv[c], "--verbose"))
		{
			// print out more verbose messages from now on
			verbose = 1;
			fprintf(stderr, "verbose mode\n");
		}
		else if (!strcmp(argv[c], "-d") || !strcmp(argv[c], "--dryrun"))
		{
			// do not write modifications to files, only report changes
			nowrites = 1;
			fprintf(stderr, "dryrun mode\n");
		}
		else if (!strcmp(argv[c], "--"))
		{
			// ignore options after this one (assume they are filenames)
			ignoreopts = 1;
		}
		else
		{
			// unknown option
			fprintf(stderr, "unknown option %s\n", argv[c]);
			goto usage;
		}
	}
	return 0;
usage:
	fprintf(stderr, "usage: %s [options] [filenames]\nReduces size of Targa(r) to one half width and one half height\noptions:\n-- = ignore later options (use for filenames starting with -)\n-v or --verbose = print messages stating the old and new size of each image\n-d or --dryrun = do not save output (for testing)\n", argv[0]);
	return 1;
}
