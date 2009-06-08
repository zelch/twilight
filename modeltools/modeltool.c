
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "file.h"
#include "util.h"

int modifymd3(unsigned char *data, int datasize, int flagsset, int flags, char *renametextures_old, char *renametextures_new, float shift[3], int flipnormals)
{
	int i, j, nummeshes, numshaders, shaderindex, shaderoffset, vertexoffset, lumpend, num;
	unsigned char *meshdata, *shaderdata, *framedata;
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
	if(shift[0] != 0 || shift[1] != 0 || shift[2] != 0 || flipnormals)
	{
		// fix bounds in frames
		num = read32(data + 76);
		lumpend = read32(data + 92);
		for(i = 0; i < num; i++)
		{
			unsigned char *v;
			if(lumpend < 0 || lumpend + 56 > datasize)
				return 0;
			v = data + lumpend;
			writefloat(v+0, readfloat(v+0) + shift[0]);
			writefloat(v+1, readfloat(v+1) + shift[1]);
			writefloat(v+2, readfloat(v+2) + shift[2]);
			writefloat(v+3, readfloat(v+3) + shift[0]);
			writefloat(v+4, readfloat(v+4) + shift[1]);
			writefloat(v+5, readfloat(v+5) + shift[2]);
			lumpend += 56;
		}
		// fix tags
		num = read32(data + 80);
		lumpend = read32(data + 96);
		for(i = 0; i < num; i++)
		{
			unsigned char *v;
			if(lumpend < 0 || lumpend + 80 > datasize)
				return 0;
			v = data + lumpend + 64;
			writefloat(v+0, readfloat(v+0) + shift[0]);
			writefloat(v+1, readfloat(v+1) + shift[1]);
			writefloat(v+2, readfloat(v+2) + shift[2]);
			lumpend += 80;
		}
		// fix vertices
		nummeshes = read32(data + 84);
		lumpend = read32(data + 100);
		for (i = 0;i < nummeshes;i++)
		{
			if (lumpend < 0 || lumpend + 108 > datasize)
				return 0;
			meshdata = data + lumpend;
			if (memcmp(meshdata, "IDP3", 4))
				return 0;
			num = read32(meshdata + 80) * read32(meshdata + 72);
			vertexoffset = read32(meshdata + 100);
			for (j = 0;j < num;j++)
			{
				unsigned char *v;
				v = (short *) (meshdata + vertexoffset + j * 8);
				write16(v+0, read16(v+0) + shift[0] * 64);
				write16(v+2, read16(v+2) + shift[1] * 64);
				write16(v+4, read16(v+4) + shift[2] * 64);
				if(flipnormals)
					write16(v+6, read16(v+6) ^ 0x8000);
			}
			lumpend += read32(meshdata + 104);
		}
	}
	return 1;
}

void printusage(void)
{
	fprintf(stderr,
"usage: modeltool [-options] <file>[ more files...]\n"
"options (note these can be specified in between files and will only affect files after them):\n"
"--help                       prints this message\n"
"--flags <number>             sets model flags number\n"
"--renametextures <old> <new> renames textures by replacing one string with another\n"
"--shift <x> <y> <z>          shift the model\n"
"--flipnormals                flip model normals\n"
"example:\n"
"modeltool --flags 0 --renametextures \"c:/document and settings/morph/t:n/\" \"\" *.md3\n"
	);
	exit(1);
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
	float shift[3] = {0, 0, 0};
	int flipnormals = 0;

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
			else if (!strcmp(argv[argindex], "--flipnormals"))
			{
				dosomething = 1;
				flipnormals = !flipnormals;
			}
			else if (!strcmp(argv[argindex], "--shift") && argindex + 3 < argc)
			{
				dosomething = 1;
				shift[0] = atof(argv[++argindex]);
				shift[1] = atof(argv[++argindex]);
				shift[2] = atof(argv[++argindex]);
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
			if (modifymd3(data, datasize, flagsset, flags, renametextures_old, renametextures_new, shift, flipnormals))
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
