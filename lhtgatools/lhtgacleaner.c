
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

int verbose = 0;
int nowrites = 0;

// see http://wikipedia.org/wiki/TGA for specifications
/* basic header definition:
typedef struct _TargaHeader
{
	unsigned char 	id_length, colormap_type, image_type;
	unsigned short	colormap_index, colormap_length;
	unsigned char	colormap_size;
	unsigned short	x_origin, y_origin, width, height;
	unsigned char	pixel_size, attributes;
}
TargaHeader;
*/

int fiximage(const char *filename)
{
	FILE *file;
	int imagetype, pixel_size, baseimagetype;
	unsigned char header[18+256], originalheader[18];
	char comment[256];
	file = fopen(filename, nowrites ? "rb" : "r+b");
	if (!file)
	{
		if (nowrites)
			fprintf(stderr, "could not open file %s for reading\n", filename);
		else
			fprintf(stderr, "could not open file %s for reading and writing\n", filename);
		return 10;
	}
	if (fread(header, 1, 18+256, file) < 18)
	{
		fprintf(stderr, "could not read tga header in %s\n", filename);
		fclose(file);
		return 10;
	}

	memcpy(originalheader, header, 18);

	// copy and terminate the comment for printing
	// (we know this can only be up to 256 characters due to the length data type being 8bit)
	memcpy(comment, header + 18, 256);
	comment[header[0]] = 0;

	if (verbose)
	{
		fprintf(stderr, "%s Targa(r) image header dump:\n", filename);
		if (header[0])
			fprintf(stderr, "id_length = %i (comment: %s)\n", header[0], comment);
		else
			fprintf(stderr, "id_length = %i\n", header[0]);
		fprintf(stderr, "colormap_type = %i (can be 0,1)\n", header[1]);
		fprintf(stderr, "image_type = %i (can be 1,2,3,9,10,11)\n", header[2]);
		fprintf(stderr, "colormap_index = %i (should be 0 if colormap_type is 0)\n", header[3] + header[4] * 256);
		fprintf(stderr, "colormap_length = %i (should be 0 if colormap_type is 0)\n", header[5] + header[6] * 256);
		fprintf(stderr, "colormap_size = %i (should be 0 if colormap_type is 0)\n", header[7]);
		fprintf(stderr, "origin = %i,%i (usually 0,0)\n", header[8] + header[9] * 256, header[10] + header[11] * 256);
		fprintf(stderr, "size = %ix%i\n", header[12] + header[13] * 256, header[14] + header[15] * 256);
		fprintf(stderr, "pixel_size = %i bits (should be 8, 16, 24, or 32bit)\n", header[16]);
		fprintf(stderr, "attributes = %i (%i alpha bits per pixel (should be 0 or 8), flags: %s%s%s%s)\n", header[17], header[17] & 0xF, header[17] & 16 ? " pixelorder:right-to-left" : "", header[17] & 32 ? " pixelorder:top-down" : "", header[17] & 64 ? " reserved6" : "", header[17] & 128 ? " reserved7" : "");
		fprintf(stderr, "\n");
	}

	// check image type
	imagetype = header[2];
	baseimagetype = imagetype & ~8;
	pixel_size = header[16];
	switch (baseimagetype)
	{
	case 1: // colormapped
		if (pixel_size != 8)
			fprintf(stderr, "warning: image is a Targa(r) Colormapped image but does not have 8bit pixels (instead %i bits)\n", pixel_size);
		break;
	case 2: // truecolor
		if (pixel_size != 16 && pixel_size != 24 && pixel_size != 32)
			fprintf(stderr, "warning: image is a Targa(r) Truecolor image but does not have 16bit, 24bit, or 32bit pixels (instead %i bits)\n", pixel_size);
		break;
	case 3: // greyscale
		if (pixel_size != 8)
			fprintf(stderr, "warning: image is a Targa(r) Greyscale image but does not have 8bit pixels (instead %i bits)\n", pixel_size);
		break;
	default:
		fprintf(stderr, "file is not a Targa(r) image file (%i is not one of the supported image types: 1,2,3,9,10,11\n", imagetype);
		fclose(file);
		return 10;
	}

	// now the actual header cleaning this function is designed to perform...
	if (!header[1]) // colormap_type
	{
		// PaintShop Pro(r) has garbage in these fields when colormap_type == 0
		header[3] = header[4] = 0; // colormap_index
		header[5] = header[6] = 0; // colormap_length;
		header[7] = 0; // colormap_size;
	}
	if (baseimagetype == 2 && pixel_size == 32)
		header[17] = (header[17] & 0xF0) | 0x08; // attributes flags, low 4 bits are attribute (alpha) bits per pixel
	else
		header[17] = (header[17] & 0xF0) | 0x00;

	if (memcmp(header + 3, originalheader + 3, 5))
		fprintf(stderr, "%s: colormap specification cleaned (cleared colormap information as image is not colormapped)\n", filename);
	if (header[17] != originalheader[17])
		fprintf(stderr, "%s: attributes corrected (%i -> %i)\n", filename, originalheader[17], header[17]);

	// only write out the new header if changes were made
	if (memcmp(header, originalheader, 18))
	{
		// we successfully cleaned the header, so save it back out
		if (nowrites)
			fprintf(stderr, "%s: not saving changes (dryrun mode active)\n", filename);
		else
		{
			fprintf(stderr, "%s: saving changes\n", filename);
			fseek(file, 0, SEEK_SET);
			if (fwrite(header, 1, 18, file) != 18)
				fprintf(stderr, "%s: write failed\n", filename);
		}
	}

	fclose(file);
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
			fiximage(argv[c]);
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
	fprintf(stderr, "usage: %s [options] [filenames]\nCleans up Targa(r) image headers (often set wrongly by PaintShop Pro(r) and other software)\noptions:\n-- = ignore later options (use for filenames starting with -)\n-v or --verbose = print image headers and more messages\n-d or --dryrun = report but do not modify files (for testing)\n", argv[0]);
	return 1;
}
