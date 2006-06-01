
#include <stdio.h>
#include <stdlib.h>
#include "file.h"

void *loadfile(const char *filename, int *size)
{
	FILE *file;
	void *filedata;
	size_t filesize;
	*size = 0;
	file = fopen(filename, "rb");
	if (!file)
		return NULL;
	fseek(file, 0, SEEK_END);
	filesize = ftell(file);
	fseek(file, 0, SEEK_SET);
	filedata = malloc(filesize);
	if (fread(filedata, 1, filesize, file) < filesize)
	{
		free(filedata);
		fclose(file);
		return NULL;
	}
	fclose(file);
	*size = filesize;
	return filedata;
}

