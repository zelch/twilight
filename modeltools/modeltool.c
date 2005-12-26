
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "file.h"

void printusage(void)
{
	fprintf(stderr,
"usage: modeltool [-options] <file>[ more files...]\n"
"options (note these can be specified in between files and will only affect files after them):\n"
"--help                       prints this message\n"
"--flags <number>             sets model flags number\n"
"--renametextures <old> <new> renames textures by replacing one string with another\n"
"example:\n"
"modeltool --flags 0 --renametextures \"c:/document and settings/morph/t:n/\" \"\" *.md3\n"
	);
	exit(1);
}

int read16(const unsigned char *a)
{
	return a[0] + a[1] * 256;
}

void write16(unsigned char *a, int b)
{
	a[0] = (unsigned char)(b);
	a[1] = (unsigned char)(b >> 8);
}

int read32(const unsigned char *a)
{
	return a[0] + a[1] * 256 + a[2] * 65536 + a[3] * 16777216;
}

void write32(unsigned char *a, int b)
{
	a[0] = (unsigned char)(b);
	a[1] = (unsigned char)(b >> 8);
	a[2] = (unsigned char)(b >> 16);
	a[3] = (unsigned char)(b >> 24);
}

int readfloat(const unsigned char *a)
{
	union
	{
		int i;
		float f;
	}
	u;
	u.i = read32(a);
	return u.f;
}

void writefloat(unsigned char *a, float f)
{
	union
	{
		int i;
		float f;
	}
	u;
	u.f = f;
	write32(a, u.i);
}

int stringreplace(char *in, int insize, char *out, int outsize, const char *search, const char *replace)
{
	int searchlength = strlen(search);
	char *inend = in + insize;
	char *outend = out + outsize;
	const char *b;
	while (in < inend-1 && *in)
	{
		if (out >= outend-1)
			return 0;
		if (in + searchlength < inend && !memcmp(in, search, searchlength))
		{
			in += searchlength;
			for (b = replace;*b;b++, out++)
			{
				if (out >= outend-1)
					return 0;
				*out = *b;
			}
		}
		else
			*out++ = *in++;
	}
	while (out < outend)
		*out++ = 0;
	return 1;
}

int modifymd3(unsigned char *data, int datasize, int flagsset, int flags, char *renametextures_old, char *renametextures_new)
{
	int i, nummeshes, numshaders, shaderindex, shaderoffset, lumpend;
	unsigned char *meshdata, *shaderdata;
	unsigned char temp[64];
	if (datasize < 108)
		return 0;
	if (memcmp(data, "IDP3", 4)) // identifier
		return 0;
	if (read32(data + 4) != 15) // version
		return 0;
	if (flagsset)
		write32(data + 72, flags);
	if (renametextures_old && renametextures_old[0])
	{
		if (!renametextures_new)
			renametextures_new = "";
		nummeshes = read32(data + 84);
		lumpend = read32(data + 100);
		for (i = 0;i < nummeshes;i++)
		{
			if (lumpend < 0 || lumpend + 108 > datasize)
				return 0;
			meshdata = data + lumpend;
			if (memcmp(meshdata, "IDP3", 4))
				return 0;
			numshaders = read32(meshdata + 76);
			for (shaderindex = 0;shaderindex < numshaders;shaderindex++)
			{
				shaderoffset = read32(meshdata + 92);
				if (shaderoffset < 0 || meshdata + shaderoffset + 64 > data + datasize)
					return 0;
				shaderdata = meshdata + shaderoffset;
				if (stringreplace((char *)shaderdata, 64, (char *)temp, 64, renametextures_old, renametextures_new))
					memcpy(shaderdata, temp, 64);
			}
			lumpend += read32(meshdata + 104);
		}
	}
	return 1;
}

int main(int argc, char **argv)
{
	int argindex;
	int dosomething = 0;
	int didsomething = 0;
	int flagsset = 0;
	int flags = 0;
	int datasize;
	char *renametextures_old = NULL;
	char *renametextures_new = NULL;
	char *filename;
	void *data;

	for (argindex = 1;argindex < argc;argindex++)
		if (!strcmp(argv[argindex], "--help"))
			printusage();

	for (argindex = 1;argindex < argc;argindex++)
	{
		if (!strncmp(argv[argindex], "--", 2))
		{
			if (!strcmp(argv[argindex], "--flags") && argindex + 1 < argc)
			{
				dosomething = 1;
				flagsset = 1;
				flags = atoi(argv[++argindex]);
			}
			else if (!strcmp(argv[argindex], "--renametextures") && argindex + 2 < argc)
			{
				dosomething = 1;
				renametextures_old = argv[++argindex];
				renametextures_new = argv[++argindex];
			}
			else
				printusage();
		}
		else
		{
			if (!dosomething)
				printusage();
			// filename
			filename = argv[argindex];
			fprintf(stderr, "reading \"%s\"", filename);
			if (readfile(filename, &data, &datasize))
			{
				fprintf(stderr, " - failed!\n");
				continue;
			}
			if (modifymd3(data, datasize, flagsset, flags, renametextures_old, renametextures_new))
			{
				fprintf(stderr, " - patched md3 model successfully\n");
				writefile(filename, data, datasize);
				didsomething = 1;
			}
			else
				fprintf(stderr, " - unknown format, leaving alone\n");
		}
	}

	if (!didsomething)
		printusage();
	return 0;
}
