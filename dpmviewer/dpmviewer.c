
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include "dpmformat.h"
#include "SDL.h"
#include "SDL_main.h"

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

#if WIN32
#include <windows.h>
#endif
#ifndef APIENTRY
#define APIENTRY
#endif
#ifndef GLAPIENTRY
#define GLAPIENTRY APIENTRY
#endif

int glerrornum;
#define CHECKGLERROR if ((glerrornum = glGetError())) GL_PrintError(glerrornum, __FILE__, __LINE__);

typedef char GLcharARB;
typedef double GLclampd;
typedef double GLdouble;
typedef float GLclampf;
typedef float GLfloat;
typedef int GLhandleARB;
typedef int GLint;
typedef int GLsizei;
typedef short GLshort;
typedef signed char GLbyte;
typedef unsigned char GLboolean;
typedef unsigned char GLubyte;
typedef unsigned int GLbitfield;
typedef unsigned int GLenum;
typedef unsigned int GLuint;
typedef unsigned short GLushort;
typedef void GLvoid;

typedef size_t GLintptrARB;
typedef size_t GLsizeiptrARB;


static int quit;

#define GL_NO_ERROR 				0x0
#define GL_INVALID_VALUE			0x0501
#define GL_INVALID_ENUM				0x0500
#define GL_INVALID_OPERATION			0x0502
#define GL_STACK_OVERFLOW			0x0503
#define GL_STACK_UNDERFLOW			0x0504
#define GL_OUT_OF_MEMORY			0x0505

void GL_PrintError(int errornumber, char *filename, int linenumber)
{
	switch(errornumber)
	{
#ifdef GL_INVALID_ENUM
	case GL_INVALID_ENUM:
		printf("GL_INVALID_ENUM at %s:%i\n", filename, linenumber);
		break;
#endif
#ifdef GL_INVALID_VALUE
	case GL_INVALID_VALUE:
		printf("GL_INVALID_VALUE at %s:%i\n", filename, linenumber);
		break;
#endif
#ifdef GL_INVALID_OPERATION
	case GL_INVALID_OPERATION:
		printf("GL_INVALID_OPERATION at %s:%i\n", filename, linenumber);
		break;
#endif
#ifdef GL_STACK_OVERFLOW
	case GL_STACK_OVERFLOW:
		printf("GL_STACK_OVERFLOW at %s:%i\n", filename, linenumber);
		break;
#endif
#ifdef GL_STACK_UNDERFLOW
	case GL_STACK_UNDERFLOW:
		printf("GL_STACK_UNDERFLOW at %s:%i\n", filename, linenumber);
		break;
#endif
#ifdef GL_OUT_OF_MEMORY
	case GL_OUT_OF_MEMORY:
		printf("GL_OUT_OF_MEMORY at %s:%i\n", filename, linenumber);
		break;
#endif
#ifdef GL_TABLE_TOO_LARGE
    case GL_TABLE_TOO_LARGE:
		printf("GL_TABLE_TOO_LARGE at %s:%i\n", filename, linenumber);
		break;
#endif
	default:
		printf("GL UNKNOWN (%i) at %s:%i\n", errornumber, filename, linenumber);
		break;
	}
}

short (*BigShort) (short l);
short (*LittleShort) (short l);
int (*BigLong) (int l);
int (*LittleLong) (int l);
float (*BigFloat) (float l);
float (*LittleFloat) (float l);

short ShortSwap (short l)
{
	unsigned char b1,b2;

	b1 = l&255;
	b2 = (l>>8)&255;

	return (b1<<8) + b2;
}

short ShortNoSwap (short l)
{
	return l;
}

int LongSwap (int l)
{
	unsigned char b1,b2,b3,b4;

	b1 = l&255;
	b2 = (l>>8)&255;
	b3 = (l>>16)&255;
	b4 = (l>>24)&255;

	return ((int)b1<<24) + ((int)b2<<16) + ((int)b3<<8) + b4;
}

int LongNoSwap (int l)
{
	return l;
}

float FloatSwap (float f)
{
	union
	{
		float f;
		unsigned char b[4];
	} dat1, dat2;


	dat1.f = f;
	dat2.b[0] = dat1.b[3];
	dat2.b[1] = dat1.b[2];
	dat2.b[2] = dat1.b[1];
	dat2.b[3] = dat1.b[0];
	return dat2.f;
}

float FloatNoSwap (float f)
{
	return f;
}

void InitSwapFunctions (void)
{
	unsigned char swaptest[2] = {1,0};

// set the byte swapping variables in a portable manner
	if ( *(short *)swaptest == 1)
	{
		BigShort = ShortSwap;
		LittleShort = ShortNoSwap;
		BigLong = LongSwap;
		LittleLong = LongNoSwap;
		BigFloat = FloatSwap;
		LittleFloat = FloatNoSwap;
	}
	else
	{
		BigShort = ShortNoSwap;
		LittleShort = ShortSwap;
		BigLong = LongNoSwap;
		LittleLong = LongSwap;
		BigFloat = FloatNoSwap;
		LittleFloat = FloatSwap;
	}
}

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

dpmheader_t *dpmload(char *filename)
{
	int bonenum, meshnum, framenum, vertnum, num, *index, filesize;
	dpmbone_t *bone;
	dpmbonepose_t *bonepose;
	dpmmesh_t *mesh;
	dpmbonevert_t *bonevert;
	dpmvertex_t *vert;
	dpmframe_t *frame;
	dpmheader_t *dpm;
	dpm = (void *)loadfile(filename, &filesize);
	if (!dpm)
		return NULL;
	InitSwapFunctions();
	if (memcmp(dpm->id, "DARKPLACESMODEL\0", 16))
	{
		free(dpm);
		return NULL;
	}
	dpm->type = BigLong(dpm->type);
	if (dpm->type != 2)
	{
		free(dpm);
		return NULL;
	}
	dpm->filesize = BigLong(dpm->filesize);
	dpm->mins[0] = BigFloat(dpm->mins[0]);
	dpm->mins[1] = BigFloat(dpm->mins[1]);
	dpm->mins[2] = BigFloat(dpm->mins[2]);
	dpm->maxs[0] = BigFloat(dpm->maxs[0]);
	dpm->maxs[1] = BigFloat(dpm->maxs[1]);
	dpm->maxs[2] = BigFloat(dpm->maxs[2]);
	dpm->yawradius = BigFloat(dpm->yawradius);
	dpm->allradius = BigFloat(dpm->allradius);
	dpm->num_bones = BigLong(dpm->num_bones);
	dpm->num_meshes = BigLong(dpm->num_meshes);
	dpm->num_frames = BigLong(dpm->num_frames);
	dpm->ofs_bones = BigLong(dpm->ofs_bones);
	dpm->ofs_meshes = BigLong(dpm->ofs_meshes);
	dpm->ofs_frames = BigLong(dpm->ofs_frames);
	for (bonenum = 0, bone = (void *)((unsigned char *)dpm + dpm->ofs_bones);bonenum < dpm->num_bones;bonenum++, bone++)
	{
		bone->parent = BigLong(bone->parent);
		bone->flags = BigLong(bone->flags);
	}
	for (meshnum = 0, mesh = (void *)((unsigned char *)dpm + dpm->ofs_meshes);meshnum < dpm->num_meshes;meshnum++, mesh++)
	{
		mesh->num_verts = BigLong(mesh->num_verts);
		mesh->num_tris = BigLong(mesh->num_tris);
		mesh->ofs_verts = BigLong(mesh->ofs_verts);
		mesh->ofs_texcoords = BigLong(mesh->ofs_texcoords);
		mesh->ofs_indices = BigLong(mesh->ofs_indices);
		mesh->ofs_groupids = BigLong(mesh->ofs_groupids);
		for (vertnum = 0, vert = (void *)((unsigned char *)dpm + mesh->ofs_verts);vertnum < mesh->num_verts;vertnum++)
		{
			vert->numbones = BigLong(vert->numbones);
			for (bonenum = 0, bonevert = (dpmbonevert_t *)(vert + 1);bonenum < vert->numbones;bonenum++, bonevert++)
			{
				bonevert->origin[0] = BigFloat(bonevert->origin[0]);
				bonevert->origin[1] = BigFloat(bonevert->origin[1]);
				bonevert->origin[2] = BigFloat(bonevert->origin[2]);
				bonevert->influence = BigFloat(bonevert->influence);
				bonevert->normal[0] = BigFloat(bonevert->normal[0]);
				bonevert->normal[1] = BigFloat(bonevert->normal[1]);
				bonevert->normal[2] = BigFloat(bonevert->normal[2]);
				bonevert->bonenum   = BigLong(bonevert->bonenum);
			}
			vert = (dpmvertex_t *)bonevert;
		}
		for (num = 0, index = (void *)((unsigned char *)dpm + mesh->ofs_texcoords);num < mesh->num_verts * 2;num++, index++)
			index[0] = BigLong(index[0]);
		for (num = 0, index = (void *)((unsigned char *)dpm + mesh->ofs_indices);num < mesh->num_tris * 3;num++, index++)
			index[0] = BigLong(index[0]);
		for (num = 0, index = (void *)((unsigned char *)dpm + mesh->ofs_groupids);num < mesh->num_tris;num++, index++)
			index[0] = BigLong(index[0]);
	}
	for (framenum = 0, frame = (void *)((unsigned char *)dpm + dpm->ofs_frames);framenum < dpm->num_frames;framenum++, frame++)
	{
		frame->mins[0] = BigFloat(frame->mins[0]);
		frame->mins[1] = BigFloat(frame->mins[1]);
		frame->mins[2] = BigFloat(frame->mins[2]);
		frame->maxs[0] = BigFloat(frame->maxs[0]);
		frame->maxs[1] = BigFloat(frame->maxs[1]);
		frame->maxs[2] = BigFloat(frame->maxs[2]);
		frame->yawradius = BigFloat(frame->yawradius);
		frame->allradius = BigFloat(frame->allradius);
		frame->ofs_bonepositions = BigLong(frame->ofs_bonepositions);
		for (bonenum = 0, bonepose = (void *)((unsigned char *)dpm + frame->ofs_bonepositions);bonenum < dpm->num_bones;bonenum++, bonepose++)
		{
			bonepose->matrix[0][0] = BigFloat(bonepose->matrix[0][0]);
			bonepose->matrix[0][1] = BigFloat(bonepose->matrix[0][1]);
			bonepose->matrix[0][2] = BigFloat(bonepose->matrix[0][2]);
			bonepose->matrix[0][3] = BigFloat(bonepose->matrix[0][3]);
			bonepose->matrix[1][0] = BigFloat(bonepose->matrix[1][0]);
			bonepose->matrix[1][1] = BigFloat(bonepose->matrix[1][1]);
			bonepose->matrix[1][2] = BigFloat(bonepose->matrix[1][2]);
			bonepose->matrix[1][3] = BigFloat(bonepose->matrix[1][3]);
			bonepose->matrix[2][0] = BigFloat(bonepose->matrix[2][0]);
			bonepose->matrix[2][1] = BigFloat(bonepose->matrix[2][1]);
			bonepose->matrix[2][2] = BigFloat(bonepose->matrix[2][2]);
			bonepose->matrix[2][3] = BigFloat(bonepose->matrix[2][3]);
		}
	}
	return dpm;
}

void freedpm(dpmheader_t *dpm)
{
	free(dpm);
}

void dpmscenenamefromframename(const char *framename, char *scenename)
{
	int n;
	strcpy(scenename, framename);
	for (n = strlen(scenename) - 1;n >= 0 && scenename[n] >= '0' && scenename[n] <= '9';n--);
	scenename[n + 1] = 0;
}

typedef struct scenerange_s
{
	char name[32];
	int firstframe, numframes;
}
scenerange_t;

typedef struct sceneranges_s
{
	int numscenes;
	scenerange_t *scenes;
}
sceneranges_t;

sceneranges_t *dpmbuildsceneranges(dpmheader_t *dpm)
{
	int framenum;
	dpmframe_t *frame;
	scenerange_t *scene;
	sceneranges_t *sceneranges;
	char scenename[32];
	// this is wasteful, but...
	sceneranges = malloc(sizeof(sceneranges_t) + dpm->num_frames * sizeof(scenerange_t));
	if (!sceneranges)
		return NULL;
	sceneranges->numscenes = 0;
	sceneranges->scenes = (void *)(sceneranges + 1);
	scene = NULL;
	for (framenum = 0;framenum < dpm->num_frames;framenum++)
	{
		frame = (dpmframe_t *)((unsigned char *)dpm + dpm->ofs_frames + framenum * sizeof(dpmframe_t));
		dpmscenenamefromframename(frame->name, scenename);
		if (!scene || strcmp(scene->name, scenename))
		{
			scene = sceneranges->scenes + sceneranges->numscenes;
			sceneranges->numscenes++;
			strcpy(scene->name, scenename);
			scene->firstframe = framenum;
			scene->numframes = 0;
		}
		scene->numframes++;
	}
	return sceneranges;
}

#define GL_PROJECTION				0x1701
#define GL_MODELVIEW				0x1700
#define GL_UNSIGNED_BYTE			0x1401
#define GL_MAX_TEXTURE_SIZE			0x0D33
#define GL_TEXTURE_2D				0x0DE1
#define GL_RGBA					0x1908
#define GL_QUADS				0x0007
#define GL_COLOR_BUFFER_BIT			0x00004000
#define GL_DEPTH_BUFFER_BIT			0x00000100
#define GL_UNSIGNED_SHORT			0x1403
#define GL_DEPTH_TEST				0x0B71
#define GL_CULL_FACE				0x0B44
#define GL_TEXTURE_MAG_FILTER			0x2800
#define GL_TEXTURE_MIN_FILTER			0x2801
#define GL_LINEAR				0x2601
#define GL_VERTEX_ARRAY				0x8074
#define GL_NORMAL_ARRAY				0x8075
#define GL_COLOR_ARRAY				0x8076
#define GL_TEXTURE_COORD_ARRAY			0x8078
#define GL_FLOAT				0x1406
#define GL_TRIANGLES				0x0004
#define GL_UNSIGNED_INT				0x1405

void (GLAPIENTRY *glEnable)(GLenum cap);
void (GLAPIENTRY *glDisable)(GLenum cap);
void (GLAPIENTRY *glGetIntegerv)(GLenum pname, GLint *params);
const GLubyte *(GLAPIENTRY *glGetString)(GLenum name);
void (GLAPIENTRY *glOrtho)(GLdouble left, GLdouble right, GLdouble bottom, GLdouble top, GLdouble near_val, GLdouble far_val);
void (GLAPIENTRY *glFrustum)(GLdouble left, GLdouble right, GLdouble bottom, GLdouble top, GLdouble near_val, GLdouble far_val);
void (GLAPIENTRY *glGenTextures)(GLsizei n, GLuint *textures);
void (GLAPIENTRY *glBindTexture)(GLenum target, GLuint texture);
void (GLAPIENTRY *glTexImage2D)(GLenum target, GLint level, GLint internalFormat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, const GLvoid *pixels );
void (GLAPIENTRY *glTexParameteri)(GLenum target, GLenum pname, GLint param);
void (GLAPIENTRY *glColor4f)(GLfloat r, GLfloat g, GLfloat b, GLfloat a);
void (GLAPIENTRY *glTexCoord2f)(GLfloat s, GLfloat t);
void (GLAPIENTRY *glVertex3f)(GLfloat x, GLfloat y, GLfloat z);
void (GLAPIENTRY *glBegin)(GLenum mode);
void (GLAPIENTRY *glEnd)(void);
GLenum (GLAPIENTRY *glGetError)(void);
void (GLAPIENTRY *glClearColor)(GLclampf red, GLclampf green, GLclampf blue, GLclampf alpha);
void (GLAPIENTRY *glClear)(GLbitfield mask);
void (GLAPIENTRY *glMatrixMode)(GLenum mode);
void (GLAPIENTRY *glLoadIdentity)(void);
void (GLAPIENTRY *glRotatef)(GLfloat angle, GLfloat x, GLfloat y, GLfloat z);
void (GLAPIENTRY *glTranslatef)(GLfloat x, GLfloat y, GLfloat z);
void (GLAPIENTRY *glVertexPointer)(GLint size, GLenum type, GLsizei stride, const GLvoid *ptr);
void (GLAPIENTRY *glNormalPointer)(GLenum type, GLsizei stride, const GLvoid *ptr);
void (GLAPIENTRY *glColorPointer)(GLint size, GLenum type, GLsizei stride, const GLvoid *ptr);
void (GLAPIENTRY *glTexCoordPointer)(GLint size, GLenum type, GLsizei stride, const GLvoid *ptr);
void (GLAPIENTRY *glDrawElements)(GLenum mode, GLsizei count, GLenum type, const GLvoid *indices);
void (GLAPIENTRY *glDrawRangeElements)(GLenum mode, GLuint start, GLuint end, GLsizei count, GLenum type, const GLvoid *indices);

void (GLAPIENTRY *glBindBufferARB) (GLenum target, GLuint buffer);
void (GLAPIENTRY *glDeleteBuffersARB) (GLsizei n, const GLuint *buffers);
void (GLAPIENTRY *glGenBuffersARB) (GLsizei n, GLuint *buffers);
GLboolean (GLAPIENTRY *glIsBufferARB) (GLuint buffer);
GLvoid* (GLAPIENTRY *glMapBufferARB) (GLenum target, GLenum access);
GLboolean (GLAPIENTRY *glUnmapBufferARB) (GLenum target);
void (GLAPIENTRY *glBufferDataARB) (GLenum target, GLsizeiptrARB size, const GLvoid *data, GLenum usage);
void (GLAPIENTRY *glBufferSubDataARB) (GLenum target, GLintptrARB offset, GLsizeiptrARB size, const GLvoid *data);


#define GL_EXTENSIONS                     0x1F03
#define GL_ARRAY_BUFFER_ARB               0x8892
#define GL_ELEMENT_ARRAY_BUFFER_ARB       0x8893
#define GL_ARRAY_BUFFER_BINDING_ARB       0x8894
#define GL_ELEMENT_ARRAY_BUFFER_BINDING_ARB 0x8895
#define GL_VERTEX_ARRAY_BUFFER_BINDING_ARB 0x8896
#define GL_NORMAL_ARRAY_BUFFER_BINDING_ARB 0x8897
#define GL_COLOR_ARRAY_BUFFER_BINDING_ARB 0x8898
#define GL_INDEX_ARRAY_BUFFER_BINDING_ARB 0x8899
#define GL_TEXTURE_COORD_ARRAY_BUFFER_BINDING_ARB 0x889A
#define GL_EDGE_FLAG_ARRAY_BUFFER_BINDING_ARB 0x889B
#define GL_SECONDARY_COLOR_ARRAY_BUFFER_BINDING_ARB 0x889C
#define GL_FOG_COORDINATE_ARRAY_BUFFER_BINDING_ARB 0x889D
#define GL_WEIGHT_ARRAY_BUFFER_BINDING_ARB 0x889E
#define GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING_ARB 0x889F
#define GL_STREAM_DRAW_ARB                0x88E0
#define GL_STREAM_READ_ARB                0x88E1
#define GL_STREAM_COPY_ARB                0x88E2
#define GL_STATIC_DRAW_ARB                0x88E4
#define GL_STATIC_READ_ARB                0x88E5
#define GL_STATIC_COPY_ARB                0x88E6
#define GL_DYNAMIC_DRAW_ARB               0x88E8
#define GL_DYNAMIC_READ_ARB               0x88E9
#define GL_DYNAMIC_COPY_ARB               0x88EA
#define GL_READ_ONLY_ARB                  0x88B8
#define GL_WRITE_ONLY_ARB                 0x88B9
#define GL_READ_WRITE_ARB                 0x88BA
#define GL_BUFFER_SIZE_ARB                0x8764
#define GL_BUFFER_USAGE_ARB               0x8765
#define GL_BUFFER_ACCESS_ARB              0x88BB
#define GL_BUFFER_MAPPED_ARB              0x88BC
#define GL_BUFFER_MAP_POINTER_ARB         0x88BD


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

GLuint maxtexturesize;

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
		for (width = 1;width < pixels_width && width < maxtexturesize;width *= 2);
		for (height = 1;height < pixels_height && height < maxtexturesize;height *= 2);
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

void dpmprecacheimages(dpmheader_t *dpm)
{
	int i;
	dpmmesh_t *mesh;
	for (i = 0, mesh = (void *)((unsigned char *)dpm + dpm->ofs_meshes);i < dpm->num_meshes;i++, mesh++)
		textureforimage(mesh->shadername);
}

void dpmlerpbones(dpmheader_t *dpm, int lerpframe1, int lerpframe2, float lerp, dpmbonepose_t *out)
{
	int i;
	float ilerp;
	dpmbonepose_t *pose1, *pose2, *parent, *baseout, m;
	dpmbone_t *bone;
	pose1 = (dpmbonepose_t *)((unsigned char *)dpm + ((dpmframe_t *)((unsigned char *)dpm + dpm->ofs_frames) + lerpframe1)->ofs_bonepositions);
	pose2 = (dpmbonepose_t *)((unsigned char *)dpm + ((dpmframe_t *)((unsigned char *)dpm + dpm->ofs_frames) + lerpframe2)->ofs_bonepositions);
	bone = (dpmbone_t *)((unsigned char *)dpm + dpm->ofs_bones);
	baseout = out;
	ilerp = 1 - lerp;
	for (i = 0;i < dpm->num_bones;i++, bone++, pose1++, pose2++, out++)
	{
		if (lerp)
		{
			m.matrix[0][0] = pose1->matrix[0][0] * ilerp + pose2->matrix[0][0] * lerp;
			m.matrix[0][1] = pose1->matrix[0][1] * ilerp + pose2->matrix[0][1] * lerp;
			m.matrix[0][2] = pose1->matrix[0][2] * ilerp + pose2->matrix[0][2] * lerp;
			m.matrix[0][3] = pose1->matrix[0][3] * ilerp + pose2->matrix[0][3] * lerp;
			m.matrix[1][0] = pose1->matrix[1][0] * ilerp + pose2->matrix[1][0] * lerp;
			m.matrix[1][1] = pose1->matrix[1][1] * ilerp + pose2->matrix[1][1] * lerp;
			m.matrix[1][2] = pose1->matrix[1][2] * ilerp + pose2->matrix[1][2] * lerp;
			m.matrix[1][3] = pose1->matrix[1][3] * ilerp + pose2->matrix[1][3] * lerp;
			m.matrix[2][0] = pose1->matrix[2][0] * ilerp + pose2->matrix[2][0] * lerp;
			m.matrix[2][1] = pose1->matrix[2][1] * ilerp + pose2->matrix[2][1] * lerp;
			m.matrix[2][2] = pose1->matrix[2][2] * ilerp + pose2->matrix[2][2] * lerp;
			m.matrix[2][3] = pose1->matrix[2][3] * ilerp + pose2->matrix[2][3] * lerp;
		}
		else
			m = *pose1;
		if (bone->parent >= 0)
		{
			parent = baseout + bone->parent;
			out->matrix[0][0] = parent->matrix[0][0] * m.matrix[0][0] + parent->matrix[0][1] * m.matrix[1][0] + parent->matrix[0][2] * m.matrix[2][0];
			out->matrix[0][1] = parent->matrix[0][0] * m.matrix[0][1] + parent->matrix[0][1] * m.matrix[1][1] + parent->matrix[0][2] * m.matrix[2][1];
			out->matrix[0][2] = parent->matrix[0][0] * m.matrix[0][2] + parent->matrix[0][1] * m.matrix[1][2] + parent->matrix[0][2] * m.matrix[2][2];
			out->matrix[0][3] = parent->matrix[0][0] * m.matrix[0][3] + parent->matrix[0][1] * m.matrix[1][3] + parent->matrix[0][2] * m.matrix[2][3] + parent->matrix[0][3];
			out->matrix[1][0] = parent->matrix[1][0] * m.matrix[0][0] + parent->matrix[1][1] * m.matrix[1][0] + parent->matrix[1][2] * m.matrix[2][0];
			out->matrix[1][1] = parent->matrix[1][0] * m.matrix[0][1] + parent->matrix[1][1] * m.matrix[1][1] + parent->matrix[1][2] * m.matrix[2][1];
			out->matrix[1][2] = parent->matrix[1][0] * m.matrix[0][2] + parent->matrix[1][1] * m.matrix[1][2] + parent->matrix[1][2] * m.matrix[2][2];
			out->matrix[1][3] = parent->matrix[1][0] * m.matrix[0][3] + parent->matrix[1][1] * m.matrix[1][3] + parent->matrix[1][2] * m.matrix[2][3] + parent->matrix[1][3];
			out->matrix[2][0] = parent->matrix[2][0] * m.matrix[0][0] + parent->matrix[2][1] * m.matrix[1][0] + parent->matrix[2][2] * m.matrix[2][0];
			out->matrix[2][1] = parent->matrix[2][0] * m.matrix[0][1] + parent->matrix[2][1] * m.matrix[1][1] + parent->matrix[2][2] * m.matrix[2][1];
			out->matrix[2][2] = parent->matrix[2][0] * m.matrix[0][2] + parent->matrix[2][1] * m.matrix[1][2] + parent->matrix[2][2] * m.matrix[2][2];
			out->matrix[2][3] = parent->matrix[2][0] * m.matrix[0][3] + parent->matrix[2][1] * m.matrix[1][3] + parent->matrix[2][2] * m.matrix[2][3] + parent->matrix[2][3];
		}
		else
			*out = m;
	}
}

#define MAX_TEXTUREUNITS 8

int textureunits = 1;

int vbo_enable = 0;
int vbo_subdata = 1;
int vbo_ext = 0;
const char *ext_string = NULL;
int ext_vbo = 0;
int ext_drawrangeelements = 0;
int use_shortindices = 1;

#define MAX_MESHES 256

typedef struct meshrenderinfo_s
{
	int num_texture;

	int num_vertices;
	float *data_vertex3f;
	float *data_normal3f;
	float *data_texcoord2f;
	GLuint vbo_vertex3f;
	GLuint vbo_normal3f;
	GLuint vbo_texcoord2f;

	int num_triangles;
	GLuint *data_element3i;
	GLushort *data_element3s;
	GLuint ebo_element3i;
	GLuint ebo_element3s;
}
meshrenderinfo_t;

meshrenderinfo_t meshrenderinfo[MAX_MESHES];

void R_Mesh_CreateRenderInfo(meshrenderinfo_t *info, int texture, int numverts, int numtriangles, float *vertex3f, float *normal3f, float *texcoord2f, int *element3i)
{
	int j;
	if (info->data_vertex3f)
		free(info->data_vertex3f);
	memset(info, 0, sizeof(*info));
	info->num_texture = texture;
	info->num_vertices = numverts;
	info->num_triangles = numtriangles;
	info->data_vertex3f = malloc(info->num_vertices * sizeof(float[3]) + info->num_vertices * sizeof(float[3]) + info->num_vertices * sizeof(float[2]) + info->num_triangles * sizeof(int[3]) + (info->num_vertices <= 65536 ? (info->num_triangles * sizeof(unsigned short[3])) : 0));
	info->data_normal3f = info->data_vertex3f + info->num_vertices * 3;
	info->data_texcoord2f = info->data_normal3f + info->num_vertices * 3;
	info->data_element3i = (GLuint *)(info->data_texcoord2f + info->num_vertices * 2);
	if (info->num_vertices <= 65536)
		info->data_element3s = (unsigned short *)(info->data_element3i + info->num_triangles * 3);

	if (vertex3f)
		memcpy(info->data_vertex3f, vertex3f, info->num_vertices * sizeof(float[3]));
	if (normal3f)
		memcpy(info->data_normal3f, normal3f, info->num_vertices * sizeof(float[3]));
	if (texcoord2f)
		memcpy(info->data_texcoord2f, texcoord2f, info->num_vertices * sizeof(float[2]));
	if (element3i)
	{
		memcpy(info->data_element3i, element3i, info->num_triangles * sizeof(int[3]));
		if (info->data_element3s)
			for (j = 0;j < info->num_triangles * 3;j++)
				info->data_element3s[j] = info->data_element3i[j];
	}
}

void dpmdraw(dpmheader_t *dpm, dpmbonepose_t *bonepose)
{
	int meshnum, vertnum, i, v;
	float vertex[3], normal[3];
	dpmbonepose_t *m;
	dpmvertex_t *vert;
	dpmbonevert_t *bonevert;
	dpmmesh_t *mesh;
	meshrenderinfo_t *info;
	float *vertex3f;
	float *normal3f;

	if (vbo_enable && !meshrenderinfo[0].vbo_vertex3f)
	{
		for (meshnum = 0, mesh = (dpmmesh_t *)((unsigned char *)dpm + dpm->ofs_meshes), info = meshrenderinfo;meshnum < dpm->num_meshes;meshnum++, mesh++, info++)
		{
			if (info->vbo_vertex3f)
				continue;
			printf("creating vbos for mesh #%i (%i vertices %i triangles)\n", meshnum, info->num_vertices, info->num_triangles);
			glGenBuffersARB(1, &info->vbo_vertex3f);
			glGenBuffersARB(1, &info->vbo_normal3f);
			glGenBuffersARB(1, &info->vbo_texcoord2f);
			glGenBuffersARB(1, &info->ebo_element3i);
			if (info->data_element3s)
				glGenBuffersARB(1, &info->ebo_element3s);
			if (info->vbo_vertex3f)
			{
				glBindBufferARB(GL_ARRAY_BUFFER_ARB, info->vbo_vertex3f);
				glBufferDataARB(GL_ARRAY_BUFFER_ARB, sizeof(float[3]) * info->num_vertices, info->data_vertex3f, GL_STREAM_DRAW_ARB);
			}
			if (info->vbo_normal3f)
			{
				glBindBufferARB(GL_ARRAY_BUFFER_ARB, info->vbo_normal3f);
				glBufferDataARB(GL_ARRAY_BUFFER_ARB, sizeof(float[3]) * info->num_vertices, info->data_normal3f, GL_STREAM_DRAW_ARB);
			}
			if (info->vbo_texcoord2f)
			{
				glBindBufferARB(GL_ARRAY_BUFFER_ARB, info->vbo_texcoord2f);
				glBufferDataARB(GL_ARRAY_BUFFER_ARB, sizeof(float[3]) * info->num_vertices, info->data_texcoord2f, GL_STATIC_DRAW_ARB);
			}
			if (info->ebo_element3i)
			{
				glBindBufferARB(GL_ELEMENT_ARRAY_BUFFER_ARB, info->ebo_element3i);
				glBufferDataARB(GL_ELEMENT_ARRAY_BUFFER_ARB, sizeof(int[3]) * info->num_triangles, info->data_element3i, GL_STATIC_DRAW_ARB);
			}
			if (info->ebo_element3s)
			{
				glBindBufferARB(GL_ELEMENT_ARRAY_BUFFER_ARB, info->ebo_element3s);
				glBufferDataARB(GL_ELEMENT_ARRAY_BUFFER_ARB, sizeof(unsigned short[3]) * info->num_triangles, info->data_element3s, GL_STATIC_DRAW_ARB);
			}
			glBindBufferARB(GL_ARRAY_BUFFER_ARB, 0);
			glBindBufferARB(GL_ELEMENT_ARRAY_BUFFER_ARB, 0);
			CHECKGLERROR
		}
	}

	for (meshnum = 0, mesh = (dpmmesh_t *)((unsigned char *)dpm + dpm->ofs_meshes), info = meshrenderinfo;meshnum < dpm->num_meshes;meshnum++, mesh++, info++)
	{
		for (vertnum = 0, vert = (dpmvertex_t *)((unsigned char *)dpm + mesh->ofs_verts), vertex3f = info->data_vertex3f, normal3f = info->data_normal3f; vertnum < info->num_vertices; vertnum++, vertex3f += 3, normal3f += 3)
		{
			bonevert = (dpmbonevert_t *)(vert + 1);
			m = bonepose + bonevert->bonenum;
			for (v = 0; v < 3; v++)
			{
				vertex[v] = bonevert->origin[0] * m->matrix[v][0] + bonevert->origin[1] * m->matrix[v][1] + bonevert->origin[2] * m->matrix[v][2] + bonevert->influence * m->matrix[v][3];
				normal[v] = bonevert->normal[0] * m->matrix[v][0] + bonevert->normal[1] * m->matrix[v][1] + bonevert->normal[2] * m->matrix[v][2];
			}
			bonevert++;
			for (i = 1;i < vert->numbones;i++, bonevert++)
			{
				m = bonepose + bonevert->bonenum;
				for (v = 0; v < 3; v++)
				{
					vertex[v] += bonevert->origin[0] * m->matrix[v][0] + bonevert->origin[1] * m->matrix[v][1] + bonevert->origin[2] * m->matrix[v][2] + bonevert->influence * m->matrix[v][3];
					normal[v] += bonevert->normal[0] * m->matrix[v][0] + bonevert->normal[1] * m->matrix[v][1] + bonevert->normal[2] * m->matrix[v][2];
				}
			}
			vertex3f[0] = vertex[0];
			vertex3f[1] = vertex[1];
			vertex3f[2] = vertex[2];
			normal3f[0] = normal[0];
			normal3f[1] = normal[1];
			normal3f[2] = normal[2];
			vert = (dpmvertex_t *)bonevert;
		}
		glColor4f(1,1,1,1);
		glBindTexture(GL_TEXTURE_2D, info->num_texture);
		if (vbo_enable)
		{
			glBindBufferARB(GL_ARRAY_BUFFER_ARB, info->vbo_vertex3f);
			if (vbo_subdata)
				glBufferSubDataARB(GL_ARRAY_BUFFER_ARB, 0, sizeof(float[3]) * info->num_vertices, info->data_vertex3f);
			else
				glBufferDataARB(GL_ARRAY_BUFFER_ARB, sizeof(float[3]) * info->num_vertices, info->data_vertex3f, GL_STREAM_DRAW_ARB);
			glVertexPointer(3, GL_FLOAT, sizeof(float[3]), 0);
			CHECKGLERROR

			glBindBufferARB(GL_ARRAY_BUFFER_ARB, info->vbo_normal3f);
			if (vbo_subdata)
				glBufferSubDataARB(GL_ARRAY_BUFFER_ARB, 0, sizeof(float[3]) * info->num_vertices, info->data_normal3f);
			else
				glBufferDataARB(GL_ARRAY_BUFFER_ARB, sizeof(float[3]) * info->num_vertices, info->data_normal3f, GL_STREAM_DRAW_ARB);
			glNormalPointer(GL_FLOAT, sizeof(float[3]), 0);
			CHECKGLERROR

			glBindBufferARB(GL_ARRAY_BUFFER_ARB, info->vbo_texcoord2f);
			glTexCoordPointer(2, GL_FLOAT, sizeof(float[2]), 0);
			CHECKGLERROR

			glBindBufferARB(GL_ARRAY_BUFFER_ARB, 0);
			CHECKGLERROR

			if (info->ebo_element3s && use_shortindices)
			{
				glBindBufferARB(GL_ELEMENT_ARRAY_BUFFER_ARB, info->ebo_element3s);
				if (ext_drawrangeelements)
					glDrawRangeElements(GL_TRIANGLES, 0, info->num_vertices, info->num_triangles * 3, GL_UNSIGNED_SHORT, 0);
				else
					glDrawElements(GL_TRIANGLES, info->num_triangles * 3, GL_UNSIGNED_SHORT, 0);
				glBindBufferARB(GL_ELEMENT_ARRAY_BUFFER_ARB, 0);
			}
			else
			{
				glBindBufferARB(GL_ELEMENT_ARRAY_BUFFER_ARB, info->ebo_element3i);
				if (ext_drawrangeelements)
					glDrawRangeElements(GL_TRIANGLES, 0, info->num_vertices, info->num_triangles * 3, GL_UNSIGNED_INT, 0);
				else
					glDrawElements(GL_TRIANGLES, info->num_triangles * 3, GL_UNSIGNED_INT, 0);
				glBindBufferARB(GL_ELEMENT_ARRAY_BUFFER_ARB, 0);
			}
			CHECKGLERROR
		}
		else
		{
			glVertexPointer(3, GL_FLOAT, sizeof(float[3]), info->data_vertex3f);
			glNormalPointer(GL_FLOAT, sizeof(float[3]), info->data_normal3f);
			glTexCoordPointer(2, GL_FLOAT, sizeof(float[2]), info->data_texcoord2f);
			if (info->data_element3s && use_shortindices)
			{
				if (ext_drawrangeelements)
					glDrawRangeElements(GL_TRIANGLES, 0, info->num_vertices, info->num_triangles * 3, GL_UNSIGNED_SHORT, info->data_element3s);
				else
					glDrawElements(GL_TRIANGLES, info->num_triangles * 3, GL_UNSIGNED_SHORT, info->data_element3s);
			}
			else
			{
				if (ext_drawrangeelements)
					glDrawRangeElements(GL_TRIANGLES, 0, info->num_vertices, info->num_triangles * 3, GL_UNSIGNED_INT, info->data_element3i);
				else
					glDrawElements(GL_TRIANGLES, info->num_triangles * 3, GL_UNSIGNED_INT, info->data_element3i);
			}
			CHECKGLERROR
		}
	}
}

SDL_Surface *initvideo(int width, int height, int bpp, int fullscreen)
{
	SDL_Surface *surface;
	if (SDL_GL_LoadLibrary (NULL))
	{
		printf("Unable to load GL library\n");
		SDL_Quit();
		exit(1);
	}
	SDL_GL_SetAttribute (SDL_GL_DOUBLEBUFFER, 1);
	surface = SDL_SetVideoMode(width, height, bpp, SDL_OPENGL | (fullscreen ? (SDL_FULLSCREEN | SDL_DOUBLEBUF) : 0));
	if (!surface)
		return NULL;

	glEnable = SDL_GL_GetProcAddress("glEnable");
	glDisable = SDL_GL_GetProcAddress("glDisable");
	glGetIntegerv = SDL_GL_GetProcAddress("glGetIntegerv");
	glGetString = SDL_GL_GetProcAddress("glGetString");
	glOrtho = SDL_GL_GetProcAddress("glOrtho");
	glFrustum = SDL_GL_GetProcAddress("glFrustum");
	glGenTextures = SDL_GL_GetProcAddress("glGenTextures");
	glBindTexture = SDL_GL_GetProcAddress("glBindTexture");
	glTexImage2D = SDL_GL_GetProcAddress("glTexImage2D");
	glTexParameteri = SDL_GL_GetProcAddress("glTexParameteri");
	glColor4f = SDL_GL_GetProcAddress("glColor4f");
	glTexCoord2f = SDL_GL_GetProcAddress("glTexCoord2f");
	glVertex3f = SDL_GL_GetProcAddress("glVertex3f");
	glBegin = SDL_GL_GetProcAddress("glBegin");
	glEnd = SDL_GL_GetProcAddress("glEnd");
	glGetError = SDL_GL_GetProcAddress("glGetError");
	glClearColor = SDL_GL_GetProcAddress("glClearColor");
	glClear = SDL_GL_GetProcAddress("glClear");
	glMatrixMode = SDL_GL_GetProcAddress("glMatrixMode");
	glLoadIdentity = SDL_GL_GetProcAddress("glLoadIdentity");
	glRotatef = SDL_GL_GetProcAddress("glRotatef");
	glTranslatef = SDL_GL_GetProcAddress("glTranslatef");
	glVertexPointer = SDL_GL_GetProcAddress("glVertexPointer");
	glNormalPointer = SDL_GL_GetProcAddress("glNormalPointer");
	glColorPointer = SDL_GL_GetProcAddress("glColorPointer");
	glTexCoordPointer = SDL_GL_GetProcAddress("glTexCoordPointer");
	glDrawElements = SDL_GL_GetProcAddress("glDrawElements");
	glDrawRangeElements = SDL_GL_GetProcAddress("glDrawRangeElements");

	glBindBufferARB = SDL_GL_GetProcAddress("glBindBufferARB");
	glDeleteBuffersARB = SDL_GL_GetProcAddress("glDeleteBuffersARB");
	glGenBuffersARB = SDL_GL_GetProcAddress("glGenBuffersARB");
	glIsBufferARB = SDL_GL_GetProcAddress("glIsBufferARB");
	glMapBufferARB = SDL_GL_GetProcAddress("glMapBufferARB");
	glUnmapBufferARB = SDL_GL_GetProcAddress("glUnmapBufferARB");
	glBufferDataARB = SDL_GL_GetProcAddress("glBufferDataARB");
	glBufferSubDataARB = SDL_GL_GetProcAddress("glBufferSubDataARB");

	ext_string = (const char *)glGetString(GL_EXTENSIONS);
	ext_drawrangeelements = strstr(ext_string, "GL_EXT_draw_range_elements") != NULL;
	ext_vbo = strstr(ext_string, "GL_ARB_vertex_buffer_object") != NULL;

	glGetIntegerv(GL_MAX_TEXTURE_SIZE, (GLint *)&maxtexturesize);
	return surface;
}

void drawstring(const char *string, float x, float y, float scalex, float scaley)
{
	int num;
	float bases, baset, scales, scalet;
	scales = 1.0f / 16.0f;
	scalet = 1.0f / 16.0f;
	glBegin(GL_QUADS);
	while (*string)
	{
		num = *string++;
		if (num != ' ')
		{
			bases = ((num & 15) * scales);
			baset = ((num >> 4) * scalet);
			glTexCoord2f(bases         , baset         );glVertex3f(x         , y         , 10);
			glTexCoord2f(bases         , baset + scalet);glVertex3f(x         , y + scaley, 10);
			glTexCoord2f(bases + scales, baset + scalet);glVertex3f(x + scalex, y + scaley, 10);
			glTexCoord2f(bases + scales, baset         );glVertex3f(x + scalex, y         , 10);
		}
		x += scalex;
	}
	glEnd();
}

dpmbonepose_t bonepose[256];
void dpmviewer(char *filename, int width, int height, int bpp, int fullscreen)
{
	char caption[1024];
	float xmax, ymax, zNear, zFar;
	int i;
	int num_fonttexture;
	int oldtime, currenttime;
	int playback;
	double timedifference;
	SDL_Event event;
	SDL_Surface *surface;
	double playedtime;
	int playedframes;
	dpmheader_t *dpm;
	dpmmesh_t *dpmmeshes;
	int scenenum, scenefirstframe, scenenumframes, sceneframerate;
	float sceneframe;
	float origin[3], angles[3];
	sceneranges_t *sceneranges;
	char tempstring[256];
	int fps = 0, fpsframecount = 0;
	double fpsbasetime = 0;


	glerrornum = 0;
	quit = 0;

	if (!(dpm = dpmload(filename)))
	{
		printf("unable to load %s\n", filename);
		return;
	}
	printf("Initializing SDL.\n");

	/* Initialize defaults, Video and Audio */
	if ((SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER) == -1))
	{
		printf("Could not initialize SDL: %s.\n", SDL_GetError());
		SDL_Quit();
		exit(-1);
	}

	surface = initvideo(width, height, bpp, fullscreen);

	initimagetextures();
	dpmprecacheimages(dpm);

	num_fonttexture = textureforimage("lhfont.tga");

	//glClearColor(0,0,0,0);

	origin[0] = 0;
	origin[1] = 0;
	origin[2] = -floor(dpm->allradius * 1 + 1);

	printf("SDL initialized.\n");

	printf("using an SDL opengl %dx%dx%dbpp surface.\n", surface->w, surface->h, surface->format->BitsPerPixel);

	sprintf(caption, "dpmviewer: %s", filename);
	SDL_WM_SetCaption(caption, NULL);

	SDL_EnableUNICODE(1);

	sceneranges = dpmbuildsceneranges(dpm);

	dpmmeshes = (dpmmesh_t *)((unsigned char *)dpm + dpm->ofs_meshes);
	for (i = 0;i < dpm->num_meshes;i++)
		R_Mesh_CreateRenderInfo(meshrenderinfo + i, textureforimage(dpmmeshes[i].shadername), dpmmeshes[i].num_verts, dpmmeshes[i].num_tris, NULL, NULL, (float *)((unsigned char *)dpm + dpmmeshes[i].ofs_texcoords), (int *)((unsigned char *)dpm + dpmmeshes[i].ofs_indices));

	glEnable(GL_VERTEX_ARRAY);
	glEnable(GL_NORMAL_ARRAY);
	glEnable(GL_TEXTURE_COORD_ARRAY);
	glDisable(GL_COLOR_ARRAY);

	playedtime = 0;
	playedframes = 0;
	playback = 1;
	oldtime = currenttime = SDL_GetTicks();
	scenenum = 0;
	sceneframe = 0;
	sceneframerate = 10;
	scenefirstframe = 0;
	scenenumframes = 1;
	angles[0] = 0;
	angles[1] = 0;
	angles[2] = 0;
	while (!quit)
	{
		while (SDL_PollEvent(&event))
		{
			switch (event.type)
			{
			case SDL_KEYDOWN:
				switch (event.key.keysym.sym)
				{
				case SDLK_LEFT:
					angles[2] -= 15;
					break;
				case SDLK_RIGHT:
					angles[2] += 15;
					break;
				case SDLK_UP:
					angles[1] -= 15;
					break;
				case SDLK_DOWN:
					angles[1] += 15;
					break;
				case SDLK_PAGEUP:
					angles[0] -= 15;
					break;
				case SDLK_PAGEDOWN:
					angles[0] += 15;
					break;
				case SDLK_COMMA:
					scenenum--;
					sceneframe = 0;
					break;
				case SDLK_PERIOD:
					scenenum++;
					sceneframe = 0;
					break;
				case SDLK_LEFTBRACKET:
					origin[2]++;
					break;
				case SDLK_RIGHTBRACKET:
					origin[2]--;
					break;
				case SDLK_0:
				case SDLK_1:
				case SDLK_2:
				case SDLK_3:
				case SDLK_4:
				case SDLK_5:
				case SDLK_6:
				case SDLK_7:
				case SDLK_8:
				case SDLK_9:
					// keep last two characters
					sceneframerate = (sceneframerate % 10) * 10 + (event.key.keysym.sym - SDLK_0);
					break;
				case SDLK_SPACE:
					playback = !playback;
					break;
				case SDLK_ESCAPE:
					quit = 1;
					break;
				default:
					if (event.key.keysym.unicode == 'v')
					{
						if (ext_vbo)
						{
							vbo_enable = !vbo_enable;
							if (vbo_enable)
								printf("vbo enabled\n");
							else
								printf("vbo disabled\n");
						}
						else
							printf("vbo toggle needs GL_ARB_vertex_buffer_object extension\n");
					}
					if (event.key.keysym.unicode == 'd')
					{
						if (ext_vbo)
						{
							vbo_subdata = !vbo_subdata;
							if (vbo_subdata)
								printf("vbo subdata enabled\n");
							else
								printf("vbo subdata disabled\n");
						}
						else
							printf("vbo toggle needs GL_ARB_vertex_buffer_object extension\n");
					}
					if (event.key.keysym.unicode == 's')
					{
						use_shortindices = !use_shortindices;
						if (use_shortindices)
							printf("short indices enabled\n");
						else
							printf("short indices disabled\n");
					}
					break;
				}
				break;
			case SDL_KEYUP:
				break;
			case SDL_QUIT:
				quit = 1;
				break;
			default:
				break;
			}
		}
		if (quit)
			break;
		oldtime = currenttime;
		currenttime = SDL_GetTicks();
		timedifference = (currenttime - oldtime) * (1.0 / 1000.0);
		if (timedifference < 0)
			timedifference = 0;
		if (playback)
			sceneframe += timedifference * sceneframerate;
		if (scenenum < 0)
			scenenum = sceneranges->numscenes - 1;
		if (scenenum >= sceneranges->numscenes)
			scenenum = 0;
		scenefirstframe = sceneranges->scenes[scenenum].firstframe;
		scenenumframes = sceneranges->scenes[scenenum].numframes;
		while (sceneframe >= scenenumframes)
			sceneframe -= scenenumframes;

		while (angles[0] < 0) angles[0] += 360;while (angles[0] >= 360) angles[0] -= 360;
		while (angles[1] < 0) angles[1] += 360;while (angles[1] >= 360) angles[1] -= 360;
		while (angles[2] < 0) angles[2] += 360;while (angles[2] >= 360) angles[2] -= 360;

		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		zNear = 1;
		zFar = 1 + dpm->allradius * 2;
		xmax = zNear;
		ymax = xmax * (double) height / (double) width;
		glMatrixMode(GL_PROJECTION);CHECKGLERROR
		glLoadIdentity();CHECKGLERROR
		glFrustum(-xmax, xmax, -ymax, ymax, zNear, zFar);CHECKGLERROR
		glMatrixMode(GL_MODELVIEW);CHECKGLERROR
		glLoadIdentity();
		glTranslatef(origin[0], origin[1], origin[2]);
		//glRotatef(270, 1, 0, 0);
		//glRotatef(90, 0, 0, 1);
		glRotatef(angles[0], 1, 0, 0);
		glRotatef(angles[1], 0, 1, 0);
		glRotatef(angles[2], 0, 0, 1);
		glEnable(GL_TEXTURE_2D);
		glEnable(GL_DEPTH_TEST);
		glEnable(GL_CULL_FACE);
		dpmlerpbones(dpm, scenefirstframe + ((int) sceneframe) % scenenumframes, scenefirstframe + ((int) sceneframe + 1) % scenenumframes, sceneframe - (int) sceneframe, bonepose);
		dpmdraw(dpm, bonepose);

		playedtime += timedifference;
		playedframes++;
		//i = SDL_GetTicks();
		//printf("%dms per frame\n", i - currenttime);

		glMatrixMode(GL_PROJECTION);CHECKGLERROR
		glLoadIdentity();CHECKGLERROR
		glOrtho(0, width, height, 0, -100, 100);CHECKGLERROR
		glMatrixMode(GL_MODELVIEW);CHECKGLERROR
		glLoadIdentity();
		glEnable(GL_TEXTURE_2D);
		glDisable(GL_DEPTH_TEST);
		//glDisable(GL_CULL_FACE);
		glBindTexture(GL_TEXTURE_2D, num_fonttexture);
		glColor4f(1,1,1,1);
		fpsframecount++;
		if (currenttime >= fpsbasetime + 1000)
		{
			fps = (int) ((double) fpsframecount * 1000.0 / ((double) currenttime - (double) fpsbasetime));
			fpsbasetime = currenttime;
			fpsframecount = 0;
		}
		sprintf(tempstring, "V: VBO %s %s arrows/pgup/pgdn: rotate   [/]: viewdistance", vbo_enable ? (vbo_subdata ? "subdata " : "enabled ") : "disabled", use_shortindices ? "Short" : "Int  ");
		drawstring(tempstring, 0, 0, 8, 8);
		sprintf(tempstring, "0-9: type in framerate    space: pause    escape: quit");
		drawstring(tempstring, 0, 8, 8, 8);
		sprintf(tempstring, "fps%5i angles %3.0f %3.0f %3.0f viewdistance %3.0f playrate %02d frame %s", fps, angles[0], angles[1], angles[2], origin[2], sceneframerate, ((dpmframe_t *)((unsigned char *)dpm + dpm->ofs_frames))[scenefirstframe + ((int) sceneframe) % scenenumframes].name);
		drawstring(tempstring, 0, height - 8, 8, 8);
		// note: SDL_GL_SwapBuffers does a glFinish for us
		SDL_GL_SwapBuffers();

		//SDL_Delay(1);
	}

	printf("%d frames rendered in %f seconds, %f average frames per second\n", playedframes, playedtime, playedframes / playedtime);

	free(sceneranges);
	freedpm(dpm);

	// close the screen surface
	SDL_QuitSubSystem (SDL_INIT_VIDEO);

	printf("Quiting SDL.\n");

	/* Shutdown all subsystems */
	SDL_Quit();

	printf("Quiting....\n");
}

int main(int argc, char **argv)
{
	if (argc != 2)
	{
		printf("usage: dpmviewer <filename.dpm>\n");
		return 1;
	}
	dpmviewer(argv[1], 800, 600, 16, 0);
	return 0;
}
