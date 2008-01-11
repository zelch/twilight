
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "tga.h"
#include "file.h"

void PrintTargaHeader(TargaHeader *t)
{
	fprintf(stderr, "TargaHeader:\nuint8 id_length = %i;\nuint8 colormap_type = %i;\nuint8 image_type = %i;\nuint16 colormap_index = %i;\nuint16 colormap_length = %i;\nuint8 colormap_size = %i;\nuint16 x_origin = %i;\nuint16 y_origin = %i;\nuint16 width = %i;\nuint16 height = %i;\nuint8 pixel_size = %i;\nuint8 attributes = %i;\n", t->id_length, t->colormap_type, t->image_type, t->colormap_index, t->colormap_length, t->colormap_size, t->x_origin, t->y_origin, t->width, t->height, t->pixel_size, t->attributes);
}

unsigned char *LoadTGA (const char *filename, int *image_width, int *image_height)
{
	int x, y, pix_inc, row_inc, red, green, blue, alpha, runlen, alphabits, width, height;
	unsigned char *pixbuf, *image_rgba;
	unsigned char *f, *filedata;
	size_t filesize;
	const unsigned char *fin, *enddata;
	unsigned char *p;
	TargaHeader targa_header;
	unsigned char palette[256*4];
	
	if (image_width)
		*image_width = 0;
	if (image_height)
		*image_height = 0;

	filedata = f = loadfile(filename, &filesize);

	if (!filedata)
	{
		fprintf(stderr, "LoadTGA: %s: unable to open file\n", filename);
		free(filedata);
		return NULL;
	}

	if (filesize < 19)
	{
		fprintf(stderr, "LoadTGA: %s: file too small to be Targa format\n", filename);
		free(filedata);
		return NULL;
	}

	enddata = f + filesize;

	targa_header.id_length = f[0];
	targa_header.colormap_type = f[1];
	targa_header.image_type = f[2];

	targa_header.colormap_index = f[3] + f[4] * 256;
	targa_header.colormap_length = f[5] + f[6] * 256;
	targa_header.colormap_size = f[7];
	targa_header.x_origin = f[8] + f[9] * 256;
	targa_header.y_origin = f[10] + f[11] * 256;
	targa_header.width = width = f[12] + f[13] * 256;
	targa_header.height = height = f[14] + f[15] * 256;
	if (width <= 0 || height <= 0)
	{
		fprintf(stderr, "LoadTGA: %s: width and height must be at least 1\n", filename);
		PrintTargaHeader(&targa_header);
		free(filedata);
		return NULL;
	}
	targa_header.pixel_size = f[16];
	targa_header.attributes = f[17];

	// advance to end of header
	fin = f + 18;

	// skip TARGA image comment (usually 0 bytes)
	fin += targa_header.id_length;

	// read/skip the colormap if present (note: according to the TARGA spec it
	// can be present even on truecolor or greyscale images, just not used by
	// the image data)
	if (targa_header.colormap_type)
	{
		if (targa_header.colormap_length > 256)
		{
			fprintf(stderr, "LoadTGA: %s: only up to 256 colormap_length supported\n", filename);
			PrintTargaHeader(&targa_header);
			free(filedata);
			return NULL;
		}
		if (targa_header.colormap_index)
		{
			fprintf(stderr, "LoadTGA: %s: colormap_index not supported\n", filename);
			PrintTargaHeader(&targa_header);
			free(filedata);
			return NULL;
		}
		if (targa_header.colormap_size == 24)
		{
			for (x = 0;x < targa_header.colormap_length;x++)
			{
				palette[x*4+2] = *fin++;
				palette[x*4+1] = *fin++;
				palette[x*4+0] = *fin++;
				palette[x*4+3] = 255;
			}
		}
		else if (targa_header.colormap_size == 32)
		{
			for (x = 0;x < targa_header.colormap_length;x++)
			{
				palette[x*4+2] = *fin++;
				palette[x*4+1] = *fin++;
				palette[x*4+0] = *fin++;
				palette[x*4+3] = *fin++;
			}
		}
		else
		{
			fprintf(stderr, "LoadTGA: %s: Only 32 and 24 bit colormap_size supported\n", filename);
			PrintTargaHeader(&targa_header);
			free(filedata);
			return NULL;
		}
	}

	// check our pixel_size restrictions according to image_type
	switch (targa_header.image_type & ~8)
	{
	case 2:
		if (targa_header.pixel_size != 24 && targa_header.pixel_size != 32)
		{
			fprintf(stderr, "LoadTGA: %s: only 24bit and 32bit pixel sizes supported for type 2 and type 10 images\n", filename);
			PrintTargaHeader(&targa_header);
			free(filedata);
			return NULL;
		}
		break;
	case 3:
		// set up a palette to make the loader easier
		for (x = 0;x < 256;x++)
		{
			palette[x*4+2] = x;
			palette[x*4+1] = x;
			palette[x*4+0] = x;
			palette[x*4+3] = 255;
		}
		// fall through to colormap case
	case 1:
		if (targa_header.pixel_size != 8)
		{
			fprintf(stderr, "LoadTGA: %s: only 8bit pixel size for type 1, 3, 9, and 11 images supported\n", filename);
			PrintTargaHeader(&targa_header);
			free(filedata);
			return NULL;
		}
		break;
	default:
		fprintf(stderr, "LoadTGA: %s: Only type 1, 2, 3, 9, 10, and 11 targa RGB images supported\n", filename);
		PrintTargaHeader(&targa_header);
		free(filedata);
		return NULL;
	}

	if (targa_header.attributes & 0x10)
	{
		fprintf(stderr, "LoadTGA: %s: origin must be in top left or bottom left, top right and bottom right are not supported\n", filename);
		free(filedata);
		return NULL;
	}

	// number of attribute bits per pixel, we only support 0 or 8
	alphabits = targa_header.attributes & 0x0F;
	if (alphabits != 8 && alphabits != 0)
	{
		fprintf(stderr, "LoadTGA: %s: only 0 or 8 attribute (alpha) bits supported\n", filename);
		free(filedata);
		return NULL;
	}

	image_rgba = (unsigned char *)malloc(width * height * 4);
	if (!image_rgba)
	{
		fprintf(stderr, "LoadTGA: %s: not enough memory for %i by %i image\n", filename, width, height);
		free(filedata);
		return NULL;
	}

	// If bit 5 of attributes isn't set, the image has been stored from bottom to top
	if ((targa_header.attributes & 0x20) == 0)
	{
		pixbuf = image_rgba + (height - 1)*width*4;
		row_inc = -width*4*2;
	}
	else
	{
		pixbuf = image_rgba;
		row_inc = 0;
	}

	x = 0;
	y = 0;
	red = green = blue = alpha = 255;
	pix_inc = 1;
	if ((targa_header.image_type & ~8) == 2)
		pix_inc = targa_header.pixel_size / 8;
	switch (targa_header.image_type)
	{
	case 1: // colormapped, uncompressed
	case 3: // greyscale, uncompressed
		if (fin + width * height * pix_inc > enddata)
			break;
		for (y = 0;y < height;y++, pixbuf += row_inc)
		{
			for (x = 0;x < width;x++)
			{
				p = palette + *fin++ * 4;
				*pixbuf++ = p[0];
				*pixbuf++ = p[1];
				*pixbuf++ = p[2];
				*pixbuf++ = p[3];
			}
		}
		break;
	case 2:
		// BGR or BGRA, uncompressed
		if (fin + width * height * pix_inc > enddata)
			break;
		if (targa_header.pixel_size == 32 && alphabits)
		{
			for (y = 0;y < height;y++, pixbuf += row_inc)
			{
				for (x = 0;x < width;x++, fin += pix_inc)
				{
					*pixbuf++ = fin[2];
					*pixbuf++ = fin[1];
					*pixbuf++ = fin[0];
					*pixbuf++ = fin[3];
				}
			}
		}
		else
		{
			for (y = 0;y < height;y++, pixbuf += row_inc)
			{
				for (x = 0;x < width;x++, fin += pix_inc)
				{
					*pixbuf++ = fin[2];
					*pixbuf++ = fin[1];
					*pixbuf++ = fin[0];
					*pixbuf++ = 255;
				}
			}
		}
		break;
	case 9: // colormapped, RLE
	case 11: // greyscale, RLE
		for (y = 0;y < height;y++, pixbuf += row_inc)
		{
			for (x = 0;x < width;)
			{
				if (fin >= enddata)
					break; // error - truncated file
				runlen = *fin++;
				if (runlen & 0x80)
				{
					// RLE - all pixels the same color
					runlen += 1 - 0x80;
					if (fin + pix_inc > enddata)
						break; // error - truncated file
					if (x + runlen > width)
						break; // error - line exceeds width
					p = palette + *fin++ * 4;
					red = p[0];
					green = p[1];
					blue = p[2];
					alpha = p[3];
					for (;runlen--;x++)
					{
						*pixbuf++ = red;
						*pixbuf++ = green;
						*pixbuf++ = blue;
						*pixbuf++ = alpha;
					}
				}
				else
				{
					// uncompressed - all pixels different color
					runlen++;
					if (fin + pix_inc * runlen > enddata)
						break; // error - truncated file
					if (x + runlen > width)
						break; // error - line exceeds width
					for (;runlen--;x++)
					{
						p = palette + *fin++ * 4;
						*pixbuf++ = p[0];
						*pixbuf++ = p[1];
						*pixbuf++ = p[2];
						*pixbuf++ = p[3];
					}
				}
			}
		}
		break;
	case 10:
		// BGR or BGRA, RLE
		if (targa_header.pixel_size == 32 && alphabits)
		{
			for (y = 0;y < height;y++, pixbuf += row_inc)
			{
				for (x = 0;x < width;)
				{
					if (fin >= enddata)
						break; // error - truncated file
					runlen = *fin++;
					if (runlen & 0x80)
					{
						// RLE - all pixels the same color
						runlen += 1 - 0x80;
						if (fin + pix_inc > enddata)
							break; // error - truncated file
						if (x + runlen > width)
							break; // error - line exceeds width
						red = fin[2];
						green = fin[1];
						blue = fin[0];
						alpha = fin[3];
						fin += pix_inc;
						for (;runlen--;x++)
						{
							*pixbuf++ = red;
							*pixbuf++ = green;
							*pixbuf++ = blue;
							*pixbuf++ = alpha;
						}
					}
					else
					{
						// uncompressed - all pixels different color
						runlen++;
						if (fin + pix_inc * runlen > enddata)
							break; // error - truncated file
						if (x + runlen > width)
							break; // error - line exceeds width
						for (;runlen--;x++, fin += pix_inc)
						{
							*pixbuf++ = fin[2];
							*pixbuf++ = fin[1];
							*pixbuf++ = fin[0];
							*pixbuf++ = fin[3];
						}
					}
				}
			}
		}
		else
		{
			for (y = 0;y < height;y++, pixbuf += row_inc)
			{
				for (x = 0;x < width;)
				{
					if (fin >= enddata)
						break; // error - truncated file
					runlen = *fin++;
					if (runlen & 0x80)
					{
						// RLE - all pixels the same color
						runlen += 1 - 0x80;
						if (fin + pix_inc > enddata)
							break; // error - truncated file
						if (x + runlen > width)
							break; // error - line exceeds width
						red = fin[2];
						green = fin[1];
						blue = fin[0];
						alpha = 255;
						fin += pix_inc;
						for (;runlen--;x++)
						{
							*pixbuf++ = red;
							*pixbuf++ = green;
							*pixbuf++ = blue;
							*pixbuf++ = alpha;
						}
					}
					else
					{
						// uncompressed - all pixels different color
						runlen++;
						if (fin + pix_inc * runlen > enddata)
							break; // error - truncated file
						if (x + runlen > width)
							break; // error - line exceeds width
						for (;runlen--;x++, fin += pix_inc)
						{
							*pixbuf++ = fin[2];
							*pixbuf++ = fin[1];
							*pixbuf++ = fin[0];
							*pixbuf++ = 255;
						}
					}
				}
			}
		}
		break;
	default:
		// unknown image_type
		break;
	}

	if (image_width)
		*image_width = width;
	if (image_height)
		*image_height = height;

	return image_rgba;
}

void SaveTGA(const char *filename, int width, int height, const unsigned char *data)
{
	int y;
	unsigned char *buffer, *out;
	const unsigned char *in, *end;

	buffer = (unsigned char *)malloc(width*height*4 + 18);

	memset (buffer, 0, 18);
	buffer[2] = 2;		// uncompressed type
	buffer[12] = (width >> 0) & 0xFF;
	buffer[13] = (width >> 8) & 0xFF;
	buffer[14] = (height >> 0) & 0xFF;
	buffer[15] = (height >> 8) & 0xFF;

	for (y = 3;y < width*height*4;y += 4)
		if (data[y] < 255)
			break;

	if (y < width*height*4)
	{
		// save the alpha channel
		buffer[16] = 32;	// pixel size
		buffer[17] = 8; // 8 bits of alpha

		// swap rgba to bgra and flip upside down
		out = buffer + 18;
		for (y = height - 1;y >= 0;y--)
		{
			in = data + y * width * 4;
			end = in + width * 4;
			for (;in < end;in += 4)
			{
				*out++ = in[2];
				*out++ = in[1];
				*out++ = in[0];
				*out++ = in[3];
			}
		}
		savefile(filename, buffer, width*height*4 + 18);
	}
	else
	{
		// save only the color channels
		buffer[16] = 24;	// pixel size
		buffer[17] = 0; // 8 bits of alpha

		// swap rgba to bgr and flip upside down
		out = buffer + 18;
		for (y = height - 1;y >= 0;y--)
		{
			in = data + y * width * 4;
			end = in + width * 4;
			for (;in < end;in += 4)
			{
				*out++ = in[2];
				*out++ = in[1];
				*out++ = in[0];
			}
		}
		savefile(filename, buffer, width*height*3 + 18);
	}

	free(buffer);
}
