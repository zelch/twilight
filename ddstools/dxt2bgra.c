/*
Copyright (c) 2012 Forest 'LordHavoc' Wroncy-Hale

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

// This tool converts dds files containing DXT1, DXT1A, DXT2, DXT3, DXT4, DXT5 formats to BGRA (uncompressed) dds files.

// WARNING: binaries compiled from this code may be covered by patents in the USA and elsewhere, collectively known as "S3TC patents".
// It is inadvisable to distribute binaries produced from this code unless your organization has licensed these patents or the patents are deemed invalid.

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <memory.h>

unsigned char *loadfile(const char *filename, size_t *sizeptr)
{
	unsigned char *data = NULL;
	size_t size = 0;
	FILE *file = fopen(filename, "rb");
	if (file)
	{
		fseek(file, 0, SEEK_END);
		size = ftell(file);
		fseek(file, 0, SEEK_SET);
		if (size > 0)
		{
			// place a nul byte at the end in case the caller is planning to do text processing
			data = calloc(1, size + 1);
			if (fread(data, 1, size, file) != size)
			{
				fprintf(stderr, "loadfile failed (READ ERROR): %s\n", filename);
				size = 0;
				free(data);
				data = NULL;
			}
		}
		else
			fprintf(stderr, "loadfile failed (EMPTY): %s\n", filename);
		fclose(file);
	}
	else
		fprintf(stderr, "loadfile failed (OPEN FAILED): %s\n", filename);
	if (sizeptr)
		*sizeptr = size;
	return data;
}

int savefile(const char *filename, size_t size, const unsigned char *data)
{
	int result = 1;
	FILE *file = fopen(filename, "wb");
	if (file)
	{
		result = 2;
		if (fwrite(data, 1, size, file) == size)
			result = 0;
		else
			fprintf(stderr, "savefile failed (WRITE ERROR): %s\n", filename);
		fclose(file);
	}
	else
		fprintf(stderr, "savefile failed (OPEN FAILED): %s\n", filename);
	return result;
}

#define BuffLittleLong(d) ((d)[0] + (d)[1] * 256 + (d)[2] * 65536 + (d)[3] * 16777216)
#define StoreLittleLong(d,n) ((d)[0] = (n), (d)[1] = (n) >> 8, (d)[2] = (n) >> 16, (d)[3] = (n) >> 24)

void bgraheader(unsigned char *outdata, int dds_width, int dds_height, int dds_miplevels, int written)
{
	unsigned int outdata_caps1;
	unsigned int outdata_caps2;
	unsigned int outdata_flags;
	unsigned int outdata_format_flags;
	int i;
	int hasalpha;
	// determine if the resulting image has alpha
	for (i = 128 + 3;i < (int)written;i++)
		if (outdata[i] < 255)
			break;
	hasalpha = i < (int)written;
	outdata_caps1 = 0x1000; // DDSCAPS_TEXTURE
	outdata_caps2 = 0;
	outdata_flags = 0x100F; // DDSD_CAPS | DDSD_PIXELFORMAT | DDSD_WIDTH | DDSD_HEIGHT | DDSD_PITCH
	outdata_format_flags = 0x40; // DDPF_RGB
	if (dds_miplevels > 1)
	{
		outdata_flags |= 0x20000; // DDSD_MIPMAPCOUNT
		outdata_caps1 |= 0x400008; // DDSCAPS_MIPMAP | DDSCAPS_COMPLEX
	}
	if(hasalpha)
		outdata_format_flags |= 0x1; // DDPF_ALPHAPIXELS
	memcpy(outdata, "DDS ", 4);
	StoreLittleLong(outdata+4, 124); // http://msdn.microsoft.com/en-us/library/bb943982%28v=vs.85%29.aspx says so
	StoreLittleLong(outdata+8, outdata_flags);
	StoreLittleLong(outdata+12, dds_height); // height
	StoreLittleLong(outdata+16, dds_width); // width
	StoreLittleLong(outdata+24, 0); // depth
	StoreLittleLong(outdata+28, dds_miplevels > 1 ? dds_miplevels : 0); // mipmaps
	StoreLittleLong(outdata+76, 32); // format size
	StoreLittleLong(outdata+80, outdata_format_flags);
	StoreLittleLong(outdata+108, outdata_caps1);
	StoreLittleLong(outdata+112, outdata_caps2);
	StoreLittleLong(outdata+20, dds_width*4); // pitch
	StoreLittleLong(outdata+88, 32); // bits per pixel
	outdata[94] = outdata[97] = outdata[100] = outdata[107] = 255; // bgra byte order masks
}

size_t dxt2bgra(const char *infilename, size_t insize, const unsigned char *indata, size_t maxsize, unsigned char *outdata)
{
	unsigned int dds_format_flags;
	int dds_miplevels;
	int dds_width;
	int dds_height;
	int mip;
	int w;
	int h;
	int i;
	int c;
	int n;
	int x;
	int y;
	int b1;
	int b2;
	int bits;
	int code0;
	int code1;
	int alpha;
	int premultiplied;
	int dxt3;
	int dxt5;
	size_t written = 0;
	size_t bgrasize = 0;
	unsigned char *row0;
	unsigned char *row1;
	unsigned char *row2;
	unsigned char *row3;
	union
	{
		int i[4];
		unsigned char color[4][4];
	}
	u;
	int a[8];
	const unsigned char *ddspixels;
	if (insize < 128 || memcmp(indata, "DDS ", 4) || BuffLittleLong(indata+76) != 32)
	{
		fprintf(stdout, "%s unrecognized format\n", infilename);
		return written; // not a DX9 dds file
	}
	dds_format_flags = BuffLittleLong(indata+80);
	dds_miplevels = (BuffLittleLong(indata+108) & 0x400000) ? BuffLittleLong(indata+28) : 1;
	if (dds_miplevels < 1)
		dds_miplevels = 1;
	dds_width = BuffLittleLong(indata+16);
	dds_height = BuffLittleLong(indata+12);
	for (mip = 0, w = dds_width, h = dds_height;mip < dds_miplevels;mip++)
	{
		bgrasize += 4 * w * h;
		if (w > 1)
			w >>= 1;
		if (h > 1)
			h >>= 1;
	}
	if (maxsize < 128 + bgrasize)
		return written; // failed, not enough space
	// reserve space for the header
	written = 128;
	// skip the header on the input
	ddspixels = indata + 128;
	// figure out which kind of dds the input is
	if ((dds_format_flags & 0x40) && BuffLittleLong(indata+88) == 32)
	{
		// very sloppy BGRA 32bit identification
		// looks like we already have a BGRA file, so just copy it in
		for (mip = 0, w = dds_width, h = dds_height;mip < dds_miplevels;mip++)
		{
			memcpy(outdata + written, ddspixels, 4 * w * h);
			ddspixels += 4 * w * h;
			written += 4 * w * h;
			if (w > 1)
				w >>= 1;
			if (h > 1)
				h >>= 1;
		}
		goto save;
	}
	else if (!memcmp(indata+84, "DXT1", 4))
	{
		// either DXT1 or DXT1A, we'll find out as we go...
		premultiplied = 0;
		dxt3 = 0;
		dxt5 = 0;
	}
	else if (!memcmp(indata+84, "DXT2", 4))
	{
		// DXT2 - the premultiplied alpha version of DXT3, so we'll need to renormalize the colors
		premultiplied = 1;
		dxt3 = 1;
		dxt5 = 0;
	}
	else if (!memcmp(indata+84, "DXT3", 4))
	{
		// DXT3
		premultiplied = 0;
		dxt3 = 1;
		dxt5 = 0;
	}
	else if (!memcmp(indata+84, "DXT4", 4))
	{
		// DXT4 - the premultiplied alpha version of DXT5, so we'll need to renormalize the colors
		premultiplied = 1;
		dxt3 = 0;
		dxt5 = 1;
	}
	else if (!memcmp(indata+84, "DXT5", 4))
	{
		// DXT5
		premultiplied = 0;
		dxt3 = 0;
		dxt5 = 1;
	}
	else
	{
		fprintf(stdout, "%s unrecognized fourcc %4s\n", infilename, indata + 84);
		return 0; // unrecognized
	}
	for (mip = 0, w = dds_width, h = dds_height;mip < dds_miplevels;mip++)
	{
		for (y = 0;y < h;y += 4)
		{
			// don't overflow
			if (written + ((w+3)&~3) * 4 * 4 > maxsize)
				return 0;
			// pixel writes can go up to 3 pixels past the end of the row, and
			// up to 3 rows past the end, but this is just trailing garbage
			// which the caller should not care about
			row0 = outdata + written;
			row1 = row0 + w * 4;
			row2 = row1 + w * 4;
			row3 = row2 + w * 4;
			// be exact on how much data we actually count...
			written += w * 4 * (y+4 <= h ? 4 : h - y);
			for (x = 0;x < w;x += 4)
			{
				if (dxt3 | dxt5)
					ddspixels += 8;
				// decode a color block
				b1 = ddspixels[0] + ddspixels[1] * 256;
				b2 = ddspixels[2] + ddspixels[3] * 256;
				bits = ddspixels[4] + ddspixels[5] * 256 + ddspixels[6] * 65536 + ddspixels[7] * 16777216;
				u.color[0][0] = ((b1 << 3) & 0xF8) | ((b1 >>  2) & 0x7);
				u.color[0][1] = ((b1 >> 3) & 0xFC) | ((b1 >>  7) & 0x3);
				u.color[0][2] = ((b1 >> 8) & 0xF8) | ((b1 >> 13)      );
				u.color[0][3] = 255;
				u.color[1][0] = ((b2 << 3) & 0xF8) | ((b2 >>  2) & 0x7);
				u.color[1][1] = ((b2 >> 3) & 0xFC) | ((b2 >>  7) & 0x3);
				u.color[1][2] = ((b2 >> 8) & 0xF8) | ((b2 >> 13)      );
				u.color[1][3] = 255;
				if (b1 <= b2)
				{
					// DXT1A color block: c1, c2, c1*0.5+c2*0.5, transparent black
					// note this does not itself indicate the use of alpha, as this block type is sometimes used for a 50% color mix intentionally
					u.color[2][0] = (u.color[0][0] + u.color[1][0]) >> 1;
					u.color[2][1] = (u.color[0][1] + u.color[1][1]) >> 1;
					u.color[2][2] = (u.color[0][2] + u.color[1][2]) >> 1;
					u.color[2][3] = (u.color[0][3] + u.color[1][3]) >> 1;
					u.color[3][0] = 0;
					u.color[3][1] = 0;
					u.color[3][2] = 0;
					u.color[3][3] = 0;
				}
				else
				{
					u.color[2][0] = (u.color[1][0] * 85 + u.color[0][0] * 171) >> 8;
					u.color[2][1] = (u.color[1][1] * 85 + u.color[0][1] * 171) >> 8;
					u.color[2][2] = (u.color[1][2] * 85 + u.color[0][2] * 171) >> 8;
					u.color[2][3] = (u.color[1][3] * 85 + u.color[0][3] * 171) >> 8;
					u.color[3][0] = (u.color[0][0] * 85 + u.color[1][0] * 171) >> 8;
					u.color[3][1] = (u.color[0][1] * 85 + u.color[1][1] * 171) >> 8;
					u.color[3][2] = (u.color[0][2] * 85 + u.color[1][2] * 171) >> 8;
					u.color[3][3] = (u.color[0][3] * 85 + u.color[1][3] * 171) >> 8;
				}
				((int *)row0)[0] = u.i[(bits>>  0)&3];
				((int *)row0)[1] = u.i[(bits>>  2)&3];
				((int *)row0)[2] = u.i[(bits>>  4)&3];
				((int *)row0)[3] = u.i[(bits>>  6)&3];
				((int *)row1)[0] = u.i[(bits>>  8)&3];
				((int *)row1)[1] = u.i[(bits>> 10)&3];
				((int *)row1)[2] = u.i[(bits>> 12)&3];
				((int *)row1)[3] = u.i[(bits>> 14)&3];
				((int *)row2)[0] = u.i[(bits>> 16)&3];
				((int *)row2)[1] = u.i[(bits>> 18)&3];
				((int *)row2)[2] = u.i[(bits>> 20)&3];
				((int *)row2)[3] = u.i[(bits>> 22)&3];
				((int *)row3)[0] = u.i[(bits>> 24)&3];
				((int *)row3)[1] = u.i[(bits>> 26)&3];
				((int *)row3)[2] = u.i[(bits>> 28)&3];
				((int *)row3)[3] = u.i[(bits>> 30)&3];
				ddspixels += 8;
				// now we read in the alpha block (if any)
				if (dxt3)
				{
					row0[ 3] =  ddspixels[-16]    *17;
					row0[ 7] = (ddspixels[-16]>>4)*17;
					row0[11] =  ddspixels[-15]    *17;
					row0[15] = (ddspixels[-15]>>4)*17;
					row1[ 3] =  ddspixels[-14]    *17;
					row1[ 7] = (ddspixels[-14]>>4)*17;
					row1[11] =  ddspixels[-13]    *17;
					row1[15] = (ddspixels[-13]>>4)*17;
					row2[ 3] =  ddspixels[-12]    *17;
					row2[ 7] = (ddspixels[-12]>>4)*17;
					row2[11] =  ddspixels[-11]    *17;
					row2[15] = (ddspixels[-11]>>4)*17;
					row3[ 3] =  ddspixels[-10]    *17;
					row3[ 7] = (ddspixels[-10]>>4)*17;
					row3[11] =  ddspixels[ -9]    *17;
					row3[15] = (ddspixels[ -9]>>4)*17;
				}
				else if (dxt5)
				{
					a[0] = ddspixels[-16];
					a[1] = ddspixels[-15];
					if (a[0] <= a[1])
					{
						a[2] = (a[0] * 205 + a[1] *  51) >> 8;
						a[3] = (a[0] * 154 + a[1] * 102) >> 8;
						a[4] = (a[0] * 102 + a[1] * 154) >> 8;
						a[5] = (a[0] *  51 + a[1] * 205) >> 8;
						a[6] = 0;
						a[7] = 255;
					}
					else
					{
						a[2] = (a[0] * 219 + a[1] *  37) >> 8;
						a[3] = (a[0] * 183 + a[1] *  73) >> 8;
						a[4] = (a[0] * 146 + a[1] * 110) >> 8;
						a[5] = (a[0] * 110 + a[1] * 146) >> 8;
						a[6] = (a[0] *  73 + a[1] * 183) >> 8;
						a[7] = (a[0] *  37 + a[1] * 219) >> 8;
					}
					code0 = ddspixels[-14] + ddspixels[-13] * 256 + ddspixels[-12] * 65536;
					code1 = ddspixels[-11] + ddspixels[-10] * 256 + ddspixels[ -9] * 65536;
					row0[ 3] = a[(code0>> 0) & 7];
					row0[ 7] = a[(code0>> 3) & 7];
					row0[11] = a[(code0>> 6) & 7];
					row0[15] = a[(code0>> 9) & 7];
					row1[ 3] = a[(code0>>12) & 7];
					row1[ 7] = a[(code0>>15) & 7];
					row1[11] = a[(code0>>18) & 7];
					row1[15] = a[(code0>>21) & 7];
					row2[ 3] = a[(code1>> 0) & 7];
					row2[ 7] = a[(code1>> 3) & 7];
					row2[11] = a[(code1>> 6) & 7];
					row2[15] = a[(code1>> 9) & 7];
					row3[ 3] = a[(code1>>12) & 7];
					row3[ 7] = a[(code1>>15) & 7];
					row3[11] = a[(code1>>18) & 7];
					row3[15] = a[(code1>>21) & 7];
				}
				row0 += 16;
				row1 += 16;
				row2 += 16;
				row3 += 16;
			}
		}
		if (w > 1)
			w >>= 1;
		if (h > 1)
			h >>= 1;
	}
	// DXT2 and DXT4 have fixup for premultiplied alpha before we save as BGRA
	// we do this by dividing color by the (fractional) pixel alpha, so if the color is 0.5 and the alpha is 0.5, the result is 1.0, this can overflow so we have to clamp
	if (premultiplied)
	{
		for (i = 128;i < (int)written;i++)
		{
			alpha = outdata[i+3];
			if (alpha > 0 && alpha < 255)
			{
				n = (255*256) / alpha;
				c = (outdata[i+0] * n) >> 8;
				outdata[i+0] = c <= 255 ? c : 255;
				c = (outdata[i+1] * n) >> 8;
				outdata[i+1] = c <= 255 ? c : 255;
				c = (outdata[i+2] * n) >> 8;
				outdata[i+2] = c <= 255 ? c : 255;
			}
		}
	}
save:
	// write the output header
	bgraheader(outdata, dds_width, dds_height, dds_miplevels, written);
	fprintf(stdout, "%s converted (%ix%i with %i mipmaps)\n", infilename, dds_width, dds_height, dds_miplevels);
#if 0
	// debugging
	{
		size_t tgasize = 18 + dds_width*dds_height*4;
		unsigned char *buffer;
		char tganame[4096];
		buffer = calloc(1, tgasize);
		buffer[2] = 2;		// uncompressed truecolor
		buffer[12] = (dds_width >> 0) & 0xFF;
		buffer[13] = (dds_width >> 8) & 0xFF;
		buffer[14] = (dds_height >> 0) & 0xFF;
		buffer[15] = (dds_height >> 8) & 0xFF;
		buffer[16] = 32;	// pixel size
		buffer[17] = 0x28; // top to bottom, has 8 alpha bits
		memcpy(buffer + 18, outdata + 128, dds_width * dds_height * 4);
		for (i = 0;i < 4096-5 && infilename[i];i++)
			tganame[i] = infilename[i];
		memcpy(tganame + i, ".tga", 5);
		savefile(tganame, tgasize, buffer);
		free(buffer);
	}
#endif
	return written;
}

int main(int argc, char **argv)
{
	int i;
	char *dirname;
	char *inname;
	static char outname[4096];
	size_t insize;
	size_t outsize;
	unsigned char *indata;
	unsigned char *outdata;
	fprintf(stderr, "%s: This tool converts dds files containing DXT1, DXT1A, DXT2, DXT3, DXT4, DXT5 formats to BGRA (uncompressed) dds files, this process may be covered by \"S3TC\" patents in the USA and elsewhere, do not use this tool if you are uncertain of the consequences.\n", argv[0]);
	if (argc < 3)
	{
	usage:
		fprintf(stderr, "Usage: %s dir/ file[ files ...]\nExample: %s bgra/ *.dds\nAll files listed on the commandline will be converted, with the output being in a directory prefix of your choice which must end in / to make sure you know what you are doing, you may use \"\" as the directory name to overwrite the original files in place.", argv[0], argv[0]);
		return 1;
	}
	dirname = argv[1];
	if (!dirname)
		dirname = "";
	if (dirname[0] && dirname[strlen(dirname)-1] != '/')
		goto usage;
	for (i = 2;i < argc;i++)
	{
		inname = argv[i];
		indata = loadfile(inname, &insize);
		outdata = calloc(1, insize * 9);
		if (outdata)
		{
			outsize = dxt2bgra(inname, insize, indata, insize * 9, outdata);
			if (outsize)
			{
				snprintf(outname, sizeof(outname), "%s%s", dirname, inname);
				if (outname[0])
					savefile(outname, outsize, outdata);
			}
			free(outdata);
		}
		outdata = NULL;
	}
	return 0;
}
