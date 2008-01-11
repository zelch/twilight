
#ifndef TGA_H
#define TGA_H

// see http://wikipedia.org/wiki/TGA for specifications

typedef struct _TargaHeader
{
	unsigned char 	id_length, colormap_type, image_type;
	unsigned short	colormap_index, colormap_length;
	unsigned char	colormap_size;
	unsigned short	x_origin, y_origin, width, height;
	unsigned char	pixel_size, attributes;
}
TargaHeader;

void PrintTargaHeader(TargaHeader *t);
unsigned char *LoadTGA (const char *filename, int *image_width, int *image_height);
void SaveTGA(const char *filename, int width, int height, const unsigned char *data);

#endif
