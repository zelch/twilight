
#include <stdlib.h>
#include <stdio.h>
#include "file.h"
#include "image.h"

typedef struct _TargaHeader
{
	unsigned char 	id_length, colormap_type, image_type;
	unsigned short	colormap_index, colormap_length;
	unsigned char	colormap_size;
	unsigned short	x_origin, y_origin, width, height;
	unsigned char	pixel_size, attributes;
}
TargaHeader;

unsigned char *LoadTGA (const char *filename, int *imagewidth, int *imageheight)
{
	int x, y, row_inc, image_width, image_height, red, green, blue, alpha, run, runlen, loadsize;
	unsigned char *pixbuf, *image_rgba, *f;
	const unsigned char *fin, *enddata;
	TargaHeader targa_header;

	*imagewidth = 0;
	*imageheight = 0;

	f = loadfile(filename, &loadsize);
	if (!f)
		return NULL;
	if (loadsize < 18+3)
	{
		free(f);
		printf("%s is too small to be valid\n", filename);
		return NULL;
	}
	targa_header.id_length = f[0];
	targa_header.colormap_type = f[1];
	targa_header.image_type = f[2];

	targa_header.colormap_index = f[3] + f[4] * 256;
	targa_header.colormap_length = f[5] + f[6] * 256;
	targa_header.colormap_size = f[7];
	targa_header.x_origin = f[8] + f[9] * 256;
	targa_header.y_origin = f[10] + f[11] * 256;
	targa_header.width = f[12] + f[13] * 256;
	targa_header.height = f[14] + f[15] * 256;
	targa_header.pixel_size = f[16];
	targa_header.attributes = f[17];

	if (targa_header.image_type != 2 && targa_header.image_type != 10)
	{
		free(f);
		printf("%s is is not type 2 or 10\n", filename);
		return NULL;
	}

	if (targa_header.colormap_type != 0	|| (targa_header.pixel_size != 32 && targa_header.pixel_size != 24))
	{
		free(f);
		printf("%s is not 24bit BGR or 32bit BGRA\n", filename);
		return NULL;
	}

	enddata = f + loadsize;

	image_width = targa_header.width;
	image_height = targa_header.height;

	image_rgba = malloc(image_width * image_height * 4);
	if (!image_rgba)
	{
		free(f);
		printf("failed to allocate memory for decoding %s\n", filename);
		return NULL;
	}

	*imagewidth = image_width;
	*imageheight = image_height;

	fin = f + 18;
	if (targa_header.id_length != 0)
		fin += targa_header.id_length;  // skip TARGA image comment

	// If bit 5 of attributes isn't set, the image has been stored from bottom to top
	if ((targa_header.attributes & 0x20) == 0)
	{
		pixbuf = image_rgba + (image_height - 1)*image_width*4;
		row_inc = -image_width*4*2;
	}
	else
	{
		pixbuf = image_rgba;
		row_inc = 0;
	}

	if (targa_header.image_type == 2)
	{
		// Uncompressed, RGB images
		if (targa_header.pixel_size == 24)
		{
			if (fin + image_width * image_height * 3 <= enddata)
			{
				for(y = 0;y < image_height;y++)
				{
					for(x = 0;x < image_width;x++)
					{
						*pixbuf++ = fin[2];
						*pixbuf++ = fin[1];
						*pixbuf++ = fin[0];
						*pixbuf++ = 255;
						fin += 3;
					}
					pixbuf += row_inc;
				}
			}
		}
		else
		{
			if (fin + image_width * image_height * 4 <= enddata)
			{
				for(y = 0;y < image_height;y++)
				{
					for(x = 0;x < image_width;x++)
					{
						*pixbuf++ = fin[2];
						*pixbuf++ = fin[1];
						*pixbuf++ = fin[0];
						*pixbuf++ = fin[3];
						fin += 4;
					}
					pixbuf += row_inc;
				}
			}
		}
	}
	else if (targa_header.image_type==10)
	{
		// Runlength encoded RGB images
		x = 0;
		y = 0;
		while (y < image_height && fin < enddata)
		{
			runlen = *fin++;
			if (runlen & 0x80)
			{
				// RLE compressed run
				runlen = 1 + (runlen & 0x7f);
				if (targa_header.pixel_size == 24)
				{
					if (fin + 3 > enddata)
						break;
					blue = *fin++;
					green = *fin++;
					red = *fin++;
					alpha = 255;
				}
				else
				{
					if (fin + 4 > enddata)
						break;
					blue = *fin++;
					green = *fin++;
					red = *fin++;
					alpha = *fin++;
				}

				while (runlen && y < image_height)
				{
					run = runlen;
					if (run > image_width - x)
						run = image_width - x;
					x += run;
					runlen -= run;
					while(run--)
					{
						*pixbuf++ = red;
						*pixbuf++ = green;
						*pixbuf++ = blue;
						*pixbuf++ = alpha;
					}
					if (x == image_width)
					{
						// end of line, advance to next
						x = 0;
						y++;
						pixbuf += row_inc;
					}
				}
			}
			else
			{
				// RLE uncompressed run
				runlen = 1 + (runlen & 0x7f);
				while (runlen && y < image_height)
				{
					run = runlen;
					if (run > image_width - x)
						run = image_width - x;
					x += run;
					runlen -= run;
					if (targa_header.pixel_size == 24)
					{
						if (fin + run * 3 > enddata)
							break;
						while(run--)
						{
							*pixbuf++ = fin[2];
							*pixbuf++ = fin[1];
							*pixbuf++ = fin[0];
							*pixbuf++ = 255;
							fin += 3;
						}
					}
					else
					{
						if (fin + run * 4 > enddata)
							break;
						while(run--)
						{
							*pixbuf++ = fin[2];
							*pixbuf++ = fin[1];
							*pixbuf++ = fin[0];
							*pixbuf++ = fin[3];
							fin += 4;
						}
					}
					if (x == image_width)
					{
						// end of line, advance to next
						x = 0;
						y++;
						pixbuf += row_inc;
					}
				}
			}
		}
	}
	free(f);
	return image_rgba;
}

void resampleimage(unsigned char *inpixels, int inwidth, int inheight, unsigned char *outpixels, int outwidth, int outheight)
{
	unsigned char *inrow, *inpix;
	int x, y, xf, xfstep;
	xfstep = (int) (inwidth * 65536.0f / outwidth);
	for (y = 0;y < outheight;y++)
	{
		inrow = inpixels + ((y * inheight / outheight) * inwidth * 4);
		for (x = 0, xf = 0;x < outwidth;x++, xf += xfstep)
		{
			inpix = inrow + (xf >> 16) * 4;
			outpixels[0] = inpix[0];
			outpixels[1] = inpix[1];
			outpixels[2] = inpix[2];
			outpixels[3] = inpix[3];
			outpixels += 4;
		}
	}
}

