
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "system.h"
#include "image.h"
#include "texture.h"

#define IMAGETEXTURE_HASHINDICES 1024
typedef struct imagetexture_s
{
	struct imagetexture_s *next;
	char *name;
	GLuint texnum;
}
imagetexture_t;

imagetexture_t *imagetexturehash[IMAGETEXTURE_HASHINDICES];

void initimagetextures(void)
{
	int i;
	for (i = 0;i < IMAGETEXTURE_HASHINDICES;i++)
		imagetexturehash[i] = NULL;
}

int textureforimage(const char *name)
{
	int i, hashindex, pixels_width, pixels_height, width, height, alpha;
	unsigned char *pixels, *texturepixels;
	imagetexture_t *image;
	char nametga[1024];
	hashindex = 0;
	for (i = 0;name[i];i++)
		hashindex += name[i];
	hashindex = (hashindex + i) % IMAGETEXTURE_HASHINDICES;
	for (image = imagetexturehash[hashindex];image;image = image->next)
		if (!strcmp(image->name, name))
			return image->texnum;
	image = malloc(sizeof(imagetexture_t));
	image->name = malloc(strlen(name) + 1);
	strcpy(image->name, name);
	image->texnum = 0;
	image->next = imagetexturehash[hashindex];
	imagetexturehash[hashindex] = image;

	pixels = LoadTGA(name, &pixels_width, &pixels_height);
	if (!pixels)
	{
		sprintf(nametga, "%s.tga", name);
		pixels = LoadTGA(nametga, &pixels_width, &pixels_height);
		if (!pixels)
			printf("failed both %s and %s\n", name, nametga);
	}
	if (pixels)
	{
		for (width = 1;width < pixels_width && width < gl_maxtexturesize;width *= 2);
		for (height = 1;height < pixels_height && height < gl_maxtexturesize;height *= 2);
		texturepixels = malloc(width * height * 4);
		resampleimage(pixels, pixels_width, pixels_height, texturepixels, width, height);
		alpha = 0;
		for (i = 3;i < width * height * 4;i += 4)
			if (texturepixels[i] < 255)
				alpha = 1;
		CHECKGLERROR
		glGenTextures(1, &image->texnum);CHECKGLERROR
		glBindTexture(GL_TEXTURE_2D, image->texnum);CHECKGLERROR
		glTexImage2D(GL_TEXTURE_2D, 0, alpha ? 4 : 3, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, texturepixels);CHECKGLERROR
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);CHECKGLERROR
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);CHECKGLERROR
		free(texturepixels);
		free(pixels);
	}
	return image->texnum;
}

void bindimagetexture(const char *name)
{
	CHECKGLERROR
	glBindTexture(GL_TEXTURE_2D, textureforimage(name));
	CHECKGLERROR
}

