
// converter for .smd files (and a .txt script) to .zym
// written by Forest 'LordHavoc' Hale but placed into public domain
//
// disclaimer: Forest Hale is not not responsible if this code blinds you with
// its horrible design, sets your house on fire, makes you cry,
// or anything else - use at your own risk.
//
// Yes, this is some of my worst code ever, I wrote it in a hurry.
// For something marginally better which evolved from this horror, see dpmodel
// (but that writes a different format).

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>

#ifndef M_PI
#define M_PI 3.1415926535
#endif

#if _MSC_VER
#pragma warning (disable : 4244)
#endif

#define MAX_FILEPATH 1024
#define MAX_NAME 32
#define MAX_SCENES 256
#define MAX_FRAMES 65536
#define MAX_TRIS 65536
#define MAX_VERTS (MAX_TRIS * 3)
#define MAX_BONES 256
#define MAX_SHADERS 256
#define MAX_FILESIZE (64*1024*1024)

char output_name[MAX_FILEPATH];

float modelorigin[3] = {0, 0, 0}, modelrotate = 0, modelscale = 1;

// this makes it keep all bones, not removing unused ones (as they might be used for attachments)
int keepallbones = 1;

void cleancopyname(char *out, char *in, int size)
{
	char *end = out + size - 1;
	// cleanup name
	while (out < end)
	{
		*out = *in++;
		if (!*out)
			break;
		// force lowercase
		if (*out >= 'A' && *out <= 'Z')
			*out += 'a' - 'A';
		// convert backslash to slash
		if (*out == '\\')
			*out = '/';
		out++;
	}
	end++;
	while (out < end)
		*out++ = 0; // pad with nulls
}

void chopextension(char *text)
{
	char *temp;
	if (!*text)
		return;
	temp = text;
	while (*temp)
	{
		if (*temp == '\\')
			*temp = '/';
		temp++;
	}
	temp = text + strlen(text) - 1;
	while (temp >= text)
	{
		if (*temp == '.') // found an extension
		{
			// clear extension
			*temp++ = 0;
			while (*temp)
				*temp++ = 0;
			break;
		}
		if (*temp == '/') // no extension but hit path
			break;
		temp--;
	}
}

void makepath(char *text)
{
	char *temp;
	if (!*text)
		return;
	temp = text;
	while (*temp)
	{
		if (*temp == '\\')
			*temp = '/';
		temp++;
	}
	temp = text + strlen(text) - 1;
	while (temp >= text)
	{
		if (*temp == '/') // found path
		{
			// clear filename
			temp++;
			while (*temp)
				*temp++ = 0;
			break;
		}
		temp--;
	}
}

void *readfile(char *filename, int *filesize)
{
	FILE *file;
	void *mem;
	size_t size;
	if (!filename[0])
	{
		printf("readfile: tried to open empty filename\n");
		return NULL;
	}
	if (!(file = fopen(filename, "rb")))
		return NULL;
	fseek(file, 0, SEEK_END);
	if (!(size = ftell(file)))
	{
		fclose(file);
		return NULL;
	}
	if (!(mem = malloc(size + 1)))
	{
		fclose(file);
		return NULL;
	}
	((unsigned char *)mem)[size] = 0; // 0 byte added on the end
	fseek(file, 0, SEEK_SET);
	if (fread(mem, 1, size, file) < size)
	{
		fclose(file);
		free(mem);
		return NULL;
	}
	fclose(file);
	if (filesize) // can be passed NULL...
		*filesize = size;
	return mem;
}

void writefile(char *filename, void *buffer, int size)
{
	int size1;
	FILE *file;
	file = fopen(filename, "wb");
	if (!file)
	{
		printf("unable to open file \"%s\" for writing\n", filename);
		return;
	}
	size1 = fwrite(buffer, 1, size, file);
	fclose(file);
	if (size1 < size)
	{
		printf("unable to write file \"%s\"\n", filename);
		return;
	}
}

char *scriptbytes, *scriptend;
int scriptsize;

/*
int scriptfiles = 0;
char *scriptfile[256];

struct
{
	float framerate;
	int noloop;
	int skip;
}
scriptfileinfo[256];

int parsefilenames(void)
{
	char *in, *out, *name;
	scriptfiles = 0;
	in = scriptbytes;
	out = scriptfilebuffer;
	while (*in && *in <= ' ')
		in++;
	while (*in &&
	while (scriptfiles < 256)
	{
		scriptfile[scriptfiles++] = name;
		while (*in && *in != '\n' && *in != '\r')
			in++;
		if (!*in)
			break;

		while (*b > ' ')
			b++;
		while (*b && *b <= ' ')
			*b++ = 0;
		if (*b == 0)
			break;
	}
	return scriptfiles;
}
*/

char *tokenpos;

int getline(char *line)
{
	char *out = line;
	while (*tokenpos == '\r' || *tokenpos == '\n')
		tokenpos++;
	if (*tokenpos)
	{
		while (*tokenpos && *tokenpos != '\r' && *tokenpos != '\n')
			*out++ = *tokenpos++;
		*out++ = 0;
	}
	else
		*out = 0;
	return out - line;
}

typedef struct bonepose_s
{
	float m[3][4];
}
bonepose_t;

typedef struct bone_s
{
	char name[MAX_NAME];
	int num, parent;
	int defined;
}
bone_t;

bonepose_t pose[MAX_FRAMES][MAX_BONES];
unsigned char posedefined[MAX_FRAMES];

bonepose_t meshpose[MAX_BONES];

int numposes = 0;

bone_t bone[MAX_BONES]; // master bone list, translated from the scenes

int numbones = 0;

bone_t scenebone[MAX_BONES]; // separate bone list for the current scene

int sceneboneremap[MAX_BONES]; // mapping of bones in the scene, to the global bone list

typedef struct scene_s
{
	char name[MAX_NAME];
	float framerate;
	int noloop;
	int start, length;
	float mins[3], maxs[3], radius; // clipping
}
scene_t;

scene_t scene[MAX_SCENES];

int numscenes = 0;

float wrapangles(float f)
{
	while (f < M_PI)
		f += M_PI * 2;
	while (f >= M_PI)
		f -= M_PI * 2;
	return f;
}

void computebonematrix(float x, float y, float z, float a, float b, float c, bonepose_t *out)
{
	float		sr, sp, sy, cr, cp, cy;

	sy = sin(c);
	cy = cos(c);
	sp = sin(b);
	cp = cos(b);
	sr = sin(a);
	cr = cos(a);

	out->m[0][0] = cp*cy;
	out->m[1][0] = cp*sy;
	out->m[2][0] = -sp;
	out->m[0][1] = sr*sp*cy+cr*-sy;
	out->m[1][1] = sr*sp*sy+cr*cy;
	out->m[2][1] = sr*cp;
	out->m[0][2] = (cr*sp*cy+-sr*-sy);
	out->m[1][2] = (cr*sp*sy+-sr*cy);
	out->m[2][2] = cr*cp;
	out->m[0][3] = x;
	out->m[1][3] = y;
	out->m[2][3] = z;
}

void concattransform(bonepose_t *in1, bonepose_t *in2, bonepose_t *out)
{
	out->m[0][0] = in1->m[0][0] * in2->m[0][0] + in1->m[0][1] * in2->m[1][0] + in1->m[0][2] * in2->m[2][0];
	out->m[0][1] = in1->m[0][0] * in2->m[0][1] + in1->m[0][1] * in2->m[1][1] + in1->m[0][2] * in2->m[2][1];
	out->m[0][2] = in1->m[0][0] * in2->m[0][2] + in1->m[0][1] * in2->m[1][2] + in1->m[0][2] * in2->m[2][2];
	out->m[0][3] = in1->m[0][0] * in2->m[0][3] + in1->m[0][1] * in2->m[1][3] + in1->m[0][2] * in2->m[2][3] + in1->m[0][3];
	out->m[1][0] = in1->m[1][0] * in2->m[0][0] + in1->m[1][1] * in2->m[1][0] + in1->m[1][2] * in2->m[2][0];
	out->m[1][1] = in1->m[1][0] * in2->m[0][1] + in1->m[1][1] * in2->m[1][1] + in1->m[1][2] * in2->m[2][1];
	out->m[1][2] = in1->m[1][0] * in2->m[0][2] + in1->m[1][1] * in2->m[1][2] + in1->m[1][2] * in2->m[2][2];
	out->m[1][3] = in1->m[1][0] * in2->m[0][3] + in1->m[1][1] * in2->m[1][3] + in1->m[1][2] * in2->m[2][3] + in1->m[1][3];
	out->m[2][0] = in1->m[2][0] * in2->m[0][0] + in1->m[2][1] * in2->m[1][0] + in1->m[2][2] * in2->m[2][0];
	out->m[2][1] = in1->m[2][0] * in2->m[0][1] + in1->m[2][1] * in2->m[1][1] + in1->m[2][2] * in2->m[2][1];
	out->m[2][2] = in1->m[2][0] * in2->m[0][2] + in1->m[2][1] * in2->m[1][2] + in1->m[2][2] * in2->m[2][2];
	out->m[2][3] = in1->m[2][0] * in2->m[0][3] + in1->m[2][1] * in2->m[1][3] + in1->m[2][2] * in2->m[2][3] + in1->m[2][3];
}

void transpose(bonepose_t *in, bonepose_t *out)
{
	out->m[0][0] = in->m[0][0];
	out->m[0][1] = in->m[1][0];
	out->m[0][2] = in->m[2][0];
	out->m[1][0] = in->m[0][1];
	out->m[1][1] = in->m[1][1];
	out->m[1][2] = in->m[2][1];
	out->m[2][0] = in->m[0][2];
	out->m[2][1] = in->m[1][2];
	out->m[2][2] = in->m[2][2];
	out->m[0][3] = -in->m[0][3];
	out->m[1][3] = -in->m[1][3];
	out->m[2][3] = -in->m[2][3];
}

void matrixcopy(bonepose_t *in, bonepose_t *out)
{
	out->m[0][0] = in->m[0][0];
	out->m[0][1] = in->m[0][1];
	out->m[0][2] = in->m[0][2];
	out->m[0][3] = in->m[0][3];
	out->m[1][0] = in->m[1][0];
	out->m[1][1] = in->m[1][1];
	out->m[1][2] = in->m[1][2];
	out->m[1][3] = in->m[1][3];
	out->m[2][0] = in->m[2][0];
	out->m[2][1] = in->m[2][1];
	out->m[2][2] = in->m[2][2];
	out->m[2][3] = in->m[2][3];
}

void transform(float in[3], bonepose_t *matrix, float out[3])
{
	out[0] = in[0] * matrix->m[0][0] + in[1] * matrix->m[0][1] + in[2] * matrix->m[0][2] + matrix->m[0][3];
	out[1] = in[0] * matrix->m[1][0] + in[1] * matrix->m[1][1] + in[2] * matrix->m[1][2] + matrix->m[1][3];
	out[2] = in[0] * matrix->m[2][0] + in[1] * matrix->m[2][1] + in[2] * matrix->m[2][2] + matrix->m[2][3];
}

void inversetransform(float in[3], bonepose_t *matrix, float out[3])
{
	float temp[3];
	temp[0] = in[0] - matrix->m[0][3];
	temp[1] = in[1] - matrix->m[1][3];
	temp[2] = in[2] - matrix->m[2][3];
	out[0] = temp[0] * matrix->m[0][0] + temp[1] * matrix->m[1][0] + temp[2] * matrix->m[2][0];
	out[1] = temp[0] * matrix->m[0][1] + temp[1] * matrix->m[1][1] + temp[2] * matrix->m[2][1];
	out[2] = temp[0] * matrix->m[0][2] + temp[1] * matrix->m[1][2] + temp[2] * matrix->m[2][2];
}

void rotate(float in[3], bonepose_t *matrix, float out[3])
{
	out[0] = in[0] * matrix->m[0][0] + in[1] * matrix->m[0][1] + in[2] * matrix->m[0][2];
	out[1] = in[0] * matrix->m[1][0] + in[1] * matrix->m[1][1] + in[2] * matrix->m[1][2];
	out[2] = in[0] * matrix->m[2][0] + in[1] * matrix->m[2][1] + in[2] * matrix->m[2][2];
}

void inverserotate(float in[3], bonepose_t *matrix, float out[3])
{
	out[0] = in[0] * matrix->m[0][0] + in[1] * matrix->m[1][0] + in[2] * matrix->m[2][0];
	out[1] = in[0] * matrix->m[0][1] + in[1] * matrix->m[1][1] + in[2] * matrix->m[2][1];
	out[2] = in[0] * matrix->m[0][2] + in[1] * matrix->m[1][2] + in[2] * matrix->m[2][2];
}

int setbonepose(int frame, int num, float x, float y, float z, float a, float b, float c)
{
	if (num < 0 || num >= MAX_BONES)
	{
		printf("error: invalid bone number: %i\n", num);
		return 0;
	}
	if (!bone[num].defined)
	{
		printf("error: bone %i not defined\n", num);
		return 0;
	}
	// LordHavoc: compute matrix
	computebonematrix(x * modelscale, y * modelscale, z * modelscale, a, b, c, frame < 0 ? &meshpose[num] : &pose[frame][num]);
	return 1;
}

bonepose_t bonematrix[MAX_BONES];

int modelfilesize;
char *modelfile;

int parsenodes(void)
{
	int num, parent, i;
	char line[1024], name[1024];
	memset(scenebone, 0, sizeof(scenebone));
	memset(sceneboneremap, 0xFF, sizeof(sceneboneremap));
	while (getline(line))
	{
		if (!strcmp(line, "end"))
			break;
		if (sscanf(line, "%i \"%[^\"]\" %i", &num, name, &parent) != 3)
		{
			printf("error in nodes data");
			return 0;
		}
		if (num < 0 || num >= MAX_BONES)
		{
			printf("invalid bone number %i\n", num);
			return 0;
		}
		if (parent >= num)
		{
			printf("bone's parent >= bone's number\n");
			return 0;
		}
		if (parent < -1)
		{
			printf("bone's parent < -1\n");
			return 0;
		}
		cleancopyname(name, name, MAX_NAME);
		// LordHavoc: this kept happening in the test model I used, and figured out it should use the latest definition
		/*
		if (scenebone[num].defined)
		{
			if (scenebone[num].parent != parent)
				printf("warning: duplicate scene bone definition (%i %s) with different parent (existing %i != new %i)\n", num, name, scenebone[num].parent, parent);
			if (strcmp(scenebone[num].name, name))
				printf("warning: duplicate scene bone definition (%i) with different name (existing %s != new %s)\n", num, scenebone[num].name, name);
		}
		*/
		memcpy(scenebone[num].name, name, MAX_NAME);
		scenebone[num].defined = 1;
		scenebone[num].parent = parent;
	}
	// LordHavoc: because a bone can be defined multiple times, this has to be done after all definitions have been parsed
	for (num = 0;num < MAX_BONES;num++)
	{
		if (!scenebone[num].defined)
			continue;
		// remap to global bone list
		parent = scenebone[num].parent;
		if (parent >= 0)
		{
			if (!scenebone[parent].defined)
			{
				printf("bone's parent was not defined\n");
				return 0;
			}
			parent = sceneboneremap[parent];
		}
		// add bone to global bone list if not yet encountered
		for (i = 0;i < numbones;i++)
		{
			if (!memcmp(bone[i].name, scenebone[num].name, MAX_NAME))
			{
				if (bone[i].parent != parent)
					printf("warning: duplicate global bone definition (%s) with different parent (existing %i != new %i)\n", name, bone[i].parent, parent);
				goto foundbone;
			}
		}
		numbones++;
foundbone:
		memcpy(bone[i].name, scenebone[num].name, MAX_NAME);
		bone[i].parent = parent;
		bone[i].defined = 1;
		sceneboneremap[num] = i;
	}
	return 1;
}

int parseskeleton(void)
{
	char line[1024], command[256];
	int i, frame, num, highest;
	float x, y, z, a, b, c;
	int baseframe;
	baseframe = numposes;
	frame = baseframe;
	highest = -1;
	while (getline(line))
	{
		sscanf(line, "%s %i", command, &i);
		if (!strcmp(command, "end"))
			break;
		if (!strcmp(command, "time"))
		{
			if (i < 0)
			{
				printf("invalid time %i\n", i);
				return 0;
			}
			frame = baseframe + i;
			if (posedefined[frame])
				printf("warning: duplicate pose\n");
			posedefined[frame] = 1;
			if (frame >= MAX_FRAMES)
			{
				printf("only %i frames supported currently\n", MAX_FRAMES);
				return 0;
			}
			if (i > highest)
				highest = i;
		}
		else
		{
			if (sscanf(line, "%i %f %f %f %f %f %f", &num, &x, &y, &z, &a, &b, &c) != 7)
			{
				printf("invalid bone pose \"%s\"\n", line);
				return 0;
			}
			if (!scenebone[num].defined)
			{
				printf("bone %i in scene not defined\n", num);
				return 0;
			}
			if (!setbonepose(frame, sceneboneremap[num], x, y, z, a, b, c))
				return 0;
		}
	}

	for (frame = 0;frame <= highest;frame++)
	{
		if (!posedefined[frame+baseframe])
		{
			printf("warning: missing pose, compacting pose list\n");
			memcpy(&pose[frame+baseframe][0], &pose[frame+baseframe+1][0], (unsigned char *) (&pose[highest+baseframe][0]) - (unsigned char *) (&pose[frame+baseframe][0]));
			memcpy(&posedefined[frame+baseframe], &posedefined[frame+baseframe+1], (unsigned char *) (&posedefined[highest+baseframe]) - (unsigned char *) (&posedefined[frame+baseframe]));
			memset(&pose[highest+baseframe][0], 0, (unsigned char *) &pose[highest+baseframe+1][0] - (unsigned char *) &pose[highest+baseframe][0]);
			posedefined[highest+baseframe] = 0;
			highest--;
			frame--; // recheck this frame
		}
	}

	numposes += highest + 1;
	return 1;
}

int parsemeshskeleton(void)
{
	char line[1024], command[256];
	int i, num;
	float x, y, z, a, b, c;
	while (getline(line))
	{
		sscanf(line, "%s %i", command, &i);
		if (!strcmp(command, "end"))
			break;
		if (!strcmp(command, "time"))
			continue;
		if (sscanf(line, "%i %f %f %f %f %f %f", &num, &x, &y, &z, &a, &b, &c) != 7)
		{
			printf("invalid bone pose \"%s\"\n", line);
			return 0;
		}
		if (!scenebone[num].defined)
		{
			printf("bone %i in mesh not defined\n", num);
			return 0;
		}
		if (!setbonepose(-1, sceneboneremap[num], x, y, z, a, b, c))
			return 0;
	}
	return 1;
}

typedef struct tripoint_s
{
	char bonename[MAX_NAME];
	float texcoord[2];
	float origin[3];
	float normal[3];
}
tripoint;

typedef struct triangle_s
{
	char texture[MAX_NAME];
	tripoint point[3];
}
triangle;

int numtriangles;
triangle triangles[MAX_TRIS];

int parsemeshtriangles(void)
{
	char line[1024];
	int current = 0, bonenum, i;
	float org[3], normal[3];
	float d;
	tripoint *p;
	for (i = 0;i < numbones;i++)
	{
		if (bone[i].parent >= 0)
			concattransform(&bonematrix[bone[i].parent], &meshpose[i], &bonematrix[i]);
		else
			matrixcopy(&meshpose[i], &bonematrix[i]);
	}
	while (getline(line))
	{
		if (!strcmp(line, "end"))
			break;
		if (current == 0)
		{
			strcpy(triangles[numtriangles].texture, line);
			current++;
		}
		else
		{
			p = &triangles[numtriangles].point[current - 1];
			if (sscanf(line, "%i %f %f %f %f %f %f %f %f", &bonenum, &org[0], &org[1], &org[2], &normal[0], &normal[1], &normal[2], &p->texcoord[0], &p->texcoord[1]) < 9)
			{
				printf("invalid vertex \"%s\"\n", line);
				return 0;
			}
			if (bonenum < 0 || bonenum >= MAX_BONES)
			{
				printf("invalid bone number %i in triangle data\n", bonenum);
				return 0;
			}
			if (!scenebone[bonenum].defined)
			{
				printf("bone %i in triangle data is not defined\n", bonenum);
				return 0;
			}
			org[0] *= modelscale;
			org[1] *= modelscale;
			org[2] *= modelscale;
			memcpy(p->bonename, scenebone[bonenum].name, MAX_NAME);
			// untransform the origin and normal
			inversetransform(org, &bonematrix[sceneboneremap[bonenum]], p->origin);
			inverserotate(normal, &bonematrix[sceneboneremap[bonenum]], p->normal);
			d = 1 / sqrt(p->normal[0] * p->normal[0] + p->normal[1] * p->normal[1] + p->normal[2] * p->normal[2]);
			p->normal[0] *= d;
			p->normal[1] *= d;
			p->normal[2] *= d;

			current++;
			if (current >= 4)
			{
				current = 0;
				numtriangles++;
			}
		}
	}
	return 1;
}

bone_t tbone[MAX_BONES];
int boneusage[MAX_BONES], boneremap[MAX_BONES], boneunmap[MAX_BONES];

int numtbones;

typedef struct tvert_s
{
	int bonenum;
	float texcoord[2];
	float origin[3];
	float normal[3];
}
tvert_t;

tvert_t tvert[MAX_VERTS];
int tvertusage[MAX_VERTS];
int tvertremap[MAX_VERTS];
int tvertunmap[MAX_VERTS];

int numtverts;

int ttris[MAX_TRIS][4]; // 0, 1, 2 are vertex indices, 3 is shader number

char shader[MAX_SHADERS][MAX_NAME];

int numshaders;

int shaderusage[MAX_SHADERS];
int shadertrisstart[MAX_SHADERS];
int shadertriscurrent[MAX_SHADERS];
int shadertris[MAX_TRIS];

unsigned char *output;
unsigned char outputbuffer[MAX_FILESIZE];

int bufferused;

void putstring(char *in, int length)
{
	while (*in && length)
	{
		*output++ = *in++;
		length--;
	}
	// pad with nulls
	while (length--)
		*output++ = 0;
}

void putnulls(int num)
{
	while (num--)
		*output++ = 0;
}

void putlong(int num)
{
	*output++ = ((num >> 24) & 0xFF);
	*output++ = ((num >> 16) & 0xFF);
	*output++ = ((num >>  8) & 0xFF);
	*output++ = ((num >>  0) & 0xFF);
}

void putfloat(float num)
{
	union
	{
		float f;
		int i;
	}
	n;
	n.f = num;
	putlong(n.i);
}

void putinit(void)
{
	output = outputbuffer;
}

int putgetposition(void)
{
	return (int)(output - outputbuffer);
}

void putsetposition(int n)
{
	output = outputbuffer + n;
}

typedef struct lump_s
{
	int start, length;
}
lump_t;

float posemins[MAX_FRAMES][3], posemaxs[MAX_FRAMES][3], poseradius[MAX_FRAMES];

void fixrootbones(void)
{
	int i, j;
	float cy, sy;
	bonepose_t rootpose, temp;
	cy = cos(modelrotate * M_PI / 180.0);
	sy = sin(modelrotate * M_PI / 180.0);
	rootpose.m[0][0] = cy;
	rootpose.m[1][0] = sy;
	rootpose.m[2][0] = 0;
	rootpose.m[0][1] = -sy;
	rootpose.m[1][1] = cy;
	rootpose.m[2][1] = 0;
	rootpose.m[0][2] = 0;
	rootpose.m[1][2] = 0;
	rootpose.m[2][2] = 1;
	// origin is PRE-SCALE origin...
	rootpose.m[0][3] = (-modelorigin[0] * rootpose.m[0][0] + -modelorigin[1] * rootpose.m[1][0] + -modelorigin[2] * rootpose.m[2][0]) * modelscale;
	rootpose.m[1][3] = (-modelorigin[0] * rootpose.m[0][1] + -modelorigin[1] * rootpose.m[1][1] + -modelorigin[2] * rootpose.m[2][1]) * modelscale;
	rootpose.m[2][3] = (-modelorigin[0] * rootpose.m[0][2] + -modelorigin[1] * rootpose.m[1][2] + -modelorigin[2] * rootpose.m[2][2]) * modelscale;
	for (j = 0;j < numbones;j++)
	{
		if (bone[j].parent < 0)
		{
			// a root bone
			for (i = 0;i < numposes;i++)
			{
				matrixcopy(&pose[i][j], &temp);
				concattransform(&rootpose, &temp, &pose[i][j]);
			}
		}
	}
}

int convertmodel(void)
{
	tripoint *p;
	tvert_t *tv;
	int lumps, i, j, k, bonenum, filesizeposition;
	lump_t lump[9];
	char name[MAX_NAME + 1];
	float mins[3], maxs[3], radius, tmins[3], tmaxs[3], tradius, org[3], dist;

	// merge duplicate verts while building triangle list
	for (i = 0;i < numtriangles;i++)
	{
		for (j = 0;j < 3;j++)
		{
			p = &triangles[i].point[j];
			for (bonenum = 0;bonenum < numbones;bonenum++)
				if (!strcmp(bone[bonenum].name, p->bonename))
					break;
			for (k = 0, tv = tvert;k < numtverts;k++, tv++)
				if (tv->bonenum == bonenum
				 && tv->texcoord[0] == p->texcoord[0] && tv->texcoord[1] == p->texcoord[1]
				 && tv->origin[0] == p->origin[0] && tv->origin[1] == p->origin[1] && tv->origin[2] == p->origin[2]
//				 && tv->normal[0] == p->normal[0] && tv->normal[1] == p->normal[1] && tv->normal[2] == p->normal[2]
				 )
					goto foundtvert;
			if (k >= MAX_VERTS)
			{
				printf("ran out of all %i vertex slots\n", MAX_VERTS);
				return 0;
			}
			tv->bonenum = bonenum;
			tv->texcoord[0] = p->texcoord[0];
			tv->texcoord[1] = p->texcoord[1];
			tv->origin[0] = p->origin[0];
			tv->origin[1] = p->origin[1];
			tv->origin[2] = p->origin[2];
			tv->normal[0] = p->normal[0];
			tv->normal[1] = p->normal[1];
			tv->normal[2] = p->normal[2];
			numtverts++;
foundtvert:
			ttris[i][j] = k;
		}

		cleancopyname(name, triangles[i].texture, MAX_NAME);
		for (k = 0;k < numshaders;k++)
		{
			if (!memcmp(shader[k], name, MAX_NAME))
				goto foundshader;
		}
		if (k >= MAX_SHADERS)
		{
			printf("ran out of all %i shader slots\n", MAX_SHADERS);
			return 0;
		}
		cleancopyname(shader[k], name, MAX_NAME);
		numshaders++;
foundshader:
		ttris[i][3] = k;
	}

	// remove unused bones
	memset(boneusage, 0, sizeof(boneusage));
	memset(boneremap, 0, sizeof(boneremap));
	for (i = 0;i < numtverts;i++)
		boneusage[tvert[i].bonenum]++;
	// count bones that are referenced as a parent
	for (i = 0;i < numbones;i++)
		if (boneusage[i])
			if (bone[i].parent >= 0)
				boneusage[bone[i].parent]++;
	numtbones = 0;
	for (i = 0;i < numbones;i++)
	{
		if (keepallbones)
			boneusage[i] = 1;
		if (boneusage[i])
		{
			boneremap[i] = numtbones;
			boneunmap[numtbones] = i;
			cleancopyname(tbone[numtbones].name, bone[i].name, MAX_NAME);
			if (bone[i].parent >= i)
			{
				printf("bone %i's parent (%i) is >= %i\n", i, bone[i].parent, i);
				return 0;
			}
			if (bone[i].parent >= 0)
				tbone[numtbones].parent = boneremap[bone[i].parent];
			else
				tbone[numtbones].parent = -1;
			numtbones++;
		}
		else
			boneremap[i] = -1;
	}
	for (i = 0;i < numtverts;i++)
		tvert[i].bonenum = boneremap[tvert[i].bonenum];

	// build render list
	memset(shaderusage, 0, sizeof(shaderusage));
	memset(shadertris, 0, sizeof(shadertris));
	memset(shadertrisstart, 0, sizeof(shadertrisstart));
	// count shader use
	for (i = 0;i < numtriangles;i++)
		shaderusage[ttris[i][3]]++;
	// prepare lists for triangles
	j = 0;
	for (i = 0;i < numshaders;i++)
	{
		shadertrisstart[i] = j;
		j += shaderusage[i];
	}
	// store triangles into the lists
	for (i = 0;i < numtriangles;i++)
		shadertris[shadertrisstart[ttris[i][3]]++] = i;
	// reset pointers to the start of their lists
	for (i = 0;i < numshaders;i++)
		shadertrisstart[i] -= shaderusage[i];

	mins[0] = mins[1] = mins[2] =  1000000000;
	maxs[0] = maxs[1] = maxs[2] = -1000000000;
	radius = 0;
	for (i = 0;i < numposes;i++)
	{
		int j;
		for (j = 0;j < numtbones;j++)
		{
			if (tbone[j].parent >= 0)
				concattransform(&bonematrix[tbone[j].parent], &pose[i][j], &bonematrix[j]);
			else
				matrixcopy(&pose[i][j], &bonematrix[j]);
		}
		tmins[0] = tmins[1] = tmins[2] =  1000000000;
		tmaxs[0] = tmaxs[1] = tmaxs[2] = -1000000000;
		tradius = 0;
		for (j = 0;j < numtverts;j++)
		{
			transform(tvert[j].origin, &bonematrix[tvert[j].bonenum], org);
			if (tmins[0] > org[0]) tmins[0] = org[0];if (tmaxs[0] < org[0]) tmaxs[0] = org[0];
			if (tmins[1] > org[1]) tmins[1] = org[1];if (tmaxs[1] < org[1]) tmaxs[1] = org[1];
			if (tmins[2] > org[2]) tmins[2] = org[2];if (tmaxs[2] < org[2]) tmaxs[2] = org[2];
			dist = org[0]*org[0]+org[1]*org[1]+org[2]*org[2];
			if (dist > tradius)
				tradius = dist;
		}
		posemins[i][0] = tmins[0];posemaxs[i][0] = tmaxs[0];
		posemins[i][1] = tmins[1];posemaxs[i][1] = tmaxs[1];
		posemins[i][2] = tmins[2];posemaxs[i][2] = tmaxs[2];
		poseradius[i] = tradius;
		if (mins[0] > tmins[0]) mins[0] = tmins[0];if (maxs[0] < tmaxs[0]) maxs[0] = tmaxs[0];
		if (mins[1] > tmins[1]) mins[1] = tmins[1];if (maxs[1] < tmaxs[1]) maxs[1] = tmaxs[1];
		if (mins[2] > tmins[2]) mins[2] = tmins[2];if (maxs[2] < tmaxs[2]) maxs[2] = tmaxs[2];
		if (radius < tradius) radius = tradius;
	}
	k = 0;
	for (i = 0;i < numscenes;i++)
	{
		tmins[0] = tmins[1] = tmins[2] =  1000000000;
		tmaxs[0] = tmaxs[1] = tmaxs[2] = -1000000000;
		tradius = 0;
		for (j = 0;j < scene[i].length;j++, k++)
		{
			if (tmins[0] > posemins[k][0]) tmins[0] = posemins[k][0];if (tmaxs[0] < posemaxs[k][0]) tmaxs[0] = posemaxs[k][0];
			if (tmins[1] > posemins[k][1]) tmins[1] = posemins[k][1];if (tmaxs[1] < posemaxs[k][1]) tmaxs[1] = posemaxs[k][1];
			if (tmins[2] > posemins[k][2]) tmins[2] = posemins[k][2];if (tmaxs[2] < posemaxs[k][2]) tmaxs[2] = posemaxs[k][2];
			if (tradius < poseradius[k]) tradius = poseradius[k];
		}
		scene[i].mins[0] = tmins[0];scene[i].maxs[0] = tmaxs[0];
		scene[i].mins[1] = tmins[1];scene[i].maxs[1] = tmaxs[1];
		scene[i].mins[2] = tmins[2];scene[i].maxs[2] = tmaxs[2];
		scene[i].radius = tradius;
	}

	putinit();
	putstring("ZYMOTICMODEL", 12);
	putlong(1); // version
	filesizeposition = putgetposition();
	putlong(0); // filesize, will be filled in later
	putfloat(mins[0]);
	putfloat(mins[1]);
	putfloat(mins[2]);
	putfloat(maxs[0]);
	putfloat(maxs[1]);
	putfloat(maxs[2]);
	putfloat(radius);
	putlong(numtverts);
	putlong(numtriangles);
	putlong(numshaders);
	putlong(numtbones);
	putlong(numscenes);
	lumps = putgetposition();
	putnulls(9 * 8); // make room for lumps to be filled in later
	// scenes
	lump[0].start = putgetposition();
	for (i = 0;i < numscenes;i++)
	{
		chopextension(scene[i].name);
		cleancopyname(name, scene[i].name, MAX_NAME);
		putstring(name, MAX_NAME);
		putfloat(scene[i].mins[0]);
		putfloat(scene[i].mins[1]);
		putfloat(scene[i].mins[2]);
		putfloat(scene[i].maxs[0]);
		putfloat(scene[i].maxs[1]);
		putfloat(scene[i].maxs[2]);
		putfloat(scene[i].radius);
		putfloat(scene[i].framerate);
		j = 0;

// normally the scene will loop, if this is set it will stay on the final frame
#define ZYMSCENEFLAG_NOLOOP 1

		if (scene[i].noloop)
			j |= ZYMSCENEFLAG_NOLOOP;
		putlong(j);
		putlong(scene[i].start);
		putlong(scene[i].length);
	}
	lump[0].length = putgetposition() - lump[0].start;
	// poses
	lump[1].start = putgetposition();
	for (i = 0;i < numposes;i++)
	{
		for (j = 0;j < numtbones;j++)
		{
			k = boneunmap[j];
			putfloat(pose[i][k].m[0][0]);
			putfloat(pose[i][k].m[0][1]);
			putfloat(pose[i][k].m[0][2]);
			putfloat(pose[i][k].m[0][3]);
			putfloat(pose[i][k].m[1][0]);
			putfloat(pose[i][k].m[1][1]);
			putfloat(pose[i][k].m[1][2]);
			putfloat(pose[i][k].m[1][3]);
			putfloat(pose[i][k].m[2][0]);
			putfloat(pose[i][k].m[2][1]);
			putfloat(pose[i][k].m[2][2]);
			putfloat(pose[i][k].m[2][3]);
		}
	}
	lump[1].length = putgetposition() - lump[1].start;
	// bones
	lump[2].start = putgetposition();
	for (i = 0;i < numtbones;i++)
	{
		cleancopyname(name, tbone[i].name, MAX_NAME);
		putstring(name, MAX_NAME);
		putlong(0); // bone flags must be set by other utilities
		putlong(tbone[i].parent);
	}
	lump[2].length = putgetposition() - lump[2].start;
	// vertex bone counts
	lump[3].start = putgetposition();
	for (i = 0;i < numtverts;i++)
		putlong(1); // number of bones, always 1 in smd
	lump[3].length = putgetposition() - lump[3].start;
	// vertices
	lump[4].start = putgetposition();
	for (i = 0;i < numtverts;i++)
	{
		// this would be a loop (bonenum origin) if there were more than one bone per vertex (smd file limitation)
		putlong(tvert[i].bonenum);
		// the origin is relative to the bone and scaled by percentage of influence (in smd there is only one bone per vertex, so that would be 1.0)
		putfloat(tvert[i].origin[0]);
		putfloat(tvert[i].origin[1]);
		putfloat(tvert[i].origin[2]);
	}
	lump[4].length = putgetposition() - lump[4].start;
	// texture coordinates for the vertices, separated only for reasons of OpenGL array processing
	lump[5].start = putgetposition();
	for (i = 0;i < numtverts;i++)
	{
		putfloat(tvert[i].texcoord[0]); // s
		putfloat(tvert[i].texcoord[1]); // t
	}
	lump[5].length = putgetposition() - lump[5].start;
	// render list
	lump[6].start = putgetposition();
	// shader numbers are implicit in this list (always sequential), so they are not stored
	for (i = 0;i < numshaders;i++)
	{
		putlong(shaderusage[i]); // how many triangles to follow
		for (j = 0;j < shaderusage[i];j++)
		{
			putlong(ttris[shadertris[shadertrisstart[i]+j]][0]);
			putlong(ttris[shadertris[shadertrisstart[i]+j]][1]);
			putlong(ttris[shadertris[shadertrisstart[i]+j]][2]);
		}
	}
	lump[6].length = putgetposition() - lump[6].start;
	// shader names
	lump[7].start = putgetposition();
	for (i = 0;i < numshaders;i++)
	{
		chopextension(shader[i]);
		cleancopyname(name, shader[i], MAX_NAME);
		putstring(name, MAX_NAME);
	}
	lump[7].length = putgetposition() - lump[7].start;
	// trizone (triangle zone numbers, these must be filled in later by other utilities)
	lump[8].start = putgetposition();
	putnulls(numtriangles);
	lump[8].length = putgetposition() - lump[8].start;
	bufferused = putgetposition();
	putsetposition(lumps);
	for (i = 0;i < 9;i++) // number of lumps
	{
		putlong(lump[i].start);
		putlong(lump[i].length);
	}
	putsetposition(filesizeposition);
	putlong(bufferused);

	// print model stats
	printf("model stats:\n");
	printf("%i vertices %i triangles %i bones %i shaders %i scenes %i poses\n", numtverts, numtriangles, numtbones, numshaders, numscenes, numposes);
	printf("renderlist:\n");
	for (i = 0;i < numshaders;i++)
	{
		for (j = 0;j < MAX_NAME && shader[i][j];j++)
			name[j] = shader[i][j];
		for (;j < MAX_NAME;j++)
			name[j] = ' ';
		name[MAX_NAME] = 0;
		printf("%5i triangles       : %s\n", shaderusage[i], name);
	}
	printf("scenes:\n");
	for (i = 0;i < numscenes;i++)
	{
		for (j = 0;j < MAX_NAME && scene[i].name[j];j++)
			name[j] = scene[i].name[j];
		for (;j < MAX_NAME;j++)
			name[j] = ' ';
		name[MAX_NAME] = 0;
		printf("%5i frames % 3.0f fps %s : %s\n", scene[i].length, scene[i].framerate, scene[i].noloop ? "noloop" : "", name);
	}
	printf("file size: %5ik\n", (bufferused + 512) >> 10);
	writefile(output_name, outputbuffer, bufferused);
//	printf("writing shader and textures\n");
	return 1;
}

int parsemodelfile(void)
{
	int i;
	char line[1024], command[256];
	tokenpos = modelfile;
	while (getline(line))
	{
		sscanf(line, "%s %i", command, &i);
		if (!strcmp(command, "version"))
		{
			if (i != 1)
			{
				printf("file is version %d, only version 1 is supported\n", i);
				return 0;
			}
		}
		else if (!strcmp(command, "nodes"))
		{
			if (!parsenodes())
				return 0;
		}
		else if (!strcmp(command, "skeleton"))
		{
			if (!parseskeleton())
				return 0;
		}
		else if (!strcmp(command, "triangles"))
		{
			do
				getline(line);
			while(strcmp(line, "end"));
		}
		else
		{
			printf("unknown command \"%s\" in smd file\n", line);
			return 0;
		}
	}
	return 1;
}

int parsemeshmodelfile(void)
{
	int i;
	char line[1024], command[256];
	tokenpos = modelfile;
	while (getline(line))
	{
		sscanf(line, "%s %i", command, &i);
		if (!strcmp(command, "version"))
		{
			if (i != 1)
			{
				printf("file is version %d, only version 1 is supported\n", i);
				return 0;
			}
		}
		else if (!strcmp(command, "nodes"))
		{
			if (!parsenodes())
				return 0;
		}
		else if (!strcmp(command, "skeleton"))
		{
			if (!parsemeshskeleton())
				return 0;
		}
		else if (!strcmp(command, "triangles"))
		{
			if (!parsemeshtriangles())
				return 0;
		}
		else
		{
			printf("unknown command \"%s\" in smd file\n", line);
			return 0;
		}
	}
	return 1;
}

/*
void inittokens(char *script)
{
	token = script;
}

char tokenbuffer[1024];

char *gettoken(void)
{
	char *out;
	out = tokenbuffer;
	while (*token && *token <= ' ')
		token++;
	if (!*token)
		return NULL;
	switch (*token)
	{
	case '\"':
		token++;
		while (*token && *token != '\r' && *token != '\n' && *token != '\"')
			*out++ = *token++;
		*out++ = 0;
		token++;
		return tokenbuffer;
	case '(':
	case ')':
	case '{':
	case '}':
	case '[':
	case ']':
		tokenbuffer[0] = *token++;
		tokenbuffer[1] = 0;
		return tokenbuffer;
	default:
		while (*token && *token > ' ' && *token != '(' && *token != ')' && *token != '{' && *token != '}' && *token != '[' && *token != ']' && *token != '\"')
			*out++ = *token++;
		*out++ = 0;
		return tokenbuffer;
	}
}

typedef struct sccommand_s
{
	char *name;
	int (*code)(void);
}
sccommand;

int isfloat(char *c)
{
	while (*c)
	{
		switch (*c)
		{
		case '0':
		case '1':
		case '2':
		case '3':
		case '4':
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
		case '.':
		case 'e':
		case '-':
		case '+':
			break;
		default:
			return 0;
		}
		c++;
	}
	return 1;
}

char modelname[256], cddir[256], cdtexturedir[256];

int sc_modelname(void)
{
	char *c = gettoken();
	if (!c)
		return 0;
	strcpy(modelname, gettoken());
	return 1;
}

int sc_cd(void)
{
	char *c = gettoken();
	if (!c)
		return 0;
	strcpy(cddir, gettoken());
	return 1;
}

int sc_cdtexture(void)
{
	char *c = gettoken();
	if (!c)
		return 0;
	strcpy(cdtexturedir, gettoken());
	return 1;
}

int sc_origin(void)
{
	int i;
	char *c;
	for (i = 0;i < 3;i++)
	{
		c = gettoken();
		if (!c)
			return 0;
		if (!isfloat(c))
			return 0;
		modelorigin[i] = atof(c);
	}
	return 1;
}

int sc_scale(void)
{
	char *c = gettoken();
	if (!c)
		return 0;
	if (!isfloat(c))
		return 0;
	modelscale = atof(c);
	return 1;
}

int sc_attachment(void)
{
	char *c;
	int i;
	for (i = 0;i < 5;i++)
	{
		c = gettoken();
		if (!c)
			return 0;
	}
	return 1;
}

int sc_body(void)
{
	char *c;
	int i;
	for (i = 0;i < 5;i++)
	{
		c = gettoken();
		if (!c)
			return 0;
	}
	return 1;
}

sc_commands[] =
{
	{"$modelname", sc_modelname},
	{"$cd", sc_cd},
	{"$cdtexture", sc_cdtexture},
	{"$scale", sc_scale},
	{"$attachment", sc_attachment},
	{"$body", sc_body},
	{"$origin", sc_origin},
//	{"$sequence", sc_sequence},
	{"", NULL}
};
*/

/*
$modelname c:\model/ak47/v_ak47.mdl
$cd c:\model/ak47
$cdtexture c:\model/ak47
$scale 1

$attachment 0 "Bone01" 0 -19.5 -0.5

$body studio "ref1"

$origin 2 12 4

$sequence idle1 "idle2" fps 10
$sequence idle2 "idle1" fps 10
$sequence fire1 "fire1" fps 30 {
{ event 5001 0 "21" }
}
$sequence fire1 "fire1" fps 25 {
{ event 5001 0 "21" }
}
$sequence stab "stab" fps 30
$sequence reload "reload" fps 30 {
{ event 5004 10 "weapons/rifle_clipout.wav" }
{ event 5004 53 "weapons/rifle_clipin.wav" }
}
$sequence reload_last "reload_last" fps 30 {
{ event 5004 10 "weapons/rifle_clipout.wav" }
{ event 5004 52 "weapons/rifle_clipin.wav" }
{ event 5004 81 "weapons/rifle_boltcock.wav" }
}
$sequence deploy "deploy" fps 20 {
{ event 5004 6 "weapons/knife_draw.wav" }
{ event 5004 15 "weapons/m60_open.wav" }
}
$sequence holster "holster" fps 15 {
{ event 5004 4 "weapons/m60_open.wav" }
{ event 5004 13 "weapons/knife_draw.wav" }
}
*/

/*
int processcommand(char *command)
{
	sccommand *c;
	c = sccommands;
	while (c->name[0])
	{
		if (!strcmp(c->name, command))
			return c->code();
		c++;
	}
	return 0;
}

void processscript(void)
{
	int i;
	char *c;
	inittokens(scriptbytes);
	baseframe = 0;
	numscenes = 0;
	while (c = gettoken())
	{
		if (!processcommand(c))
		{
			printf("error processing script\n");
			return;
		}
	}
	for (i = 0;i < scriptfiles;i++)
	{
		printf("smd file: %s\n", scriptfile[i]);
		cleancopyname(scene[numscenes].name, scriptfile[i], MAX_NAME);
		scene[numscenes].start = numposes;
		// these should be read from the script
		scene[numscenes].framerate = scriptfileinfo[i].framerate;
		scene[numscenes].noloop = 0 scriptfileinfo[i].noloop;
		modelfile = readfile(scriptfile[i], &modelfilesize);
		if (!modelfile)
			return -1;
		if (!parsemodelfile())
			return -1;
		scene[numscenes].length = numposes - scene[numscenes].start;
		if (scene[numscenes].length > 0 && !scriptfileinfo[i].skip) // only increase if frames were added and not marked as skip
			numscenes++;
	}
	convertmodel();
}
*/

char *token;

void inittokens(char *script)
{
	token = script;
}

char tokenbuffer[1024];

char *gettoken(void)
{
	char *out;
	out = tokenbuffer;
	while (*token && *token <= ' ' && *token != '\n')
		token++;
	if (!*token)
		return NULL;
	switch (*token)
	{
	case '\"':
		token++;
		while (*token && *token != '\r' && *token != '\n' && *token != '\"')
			*out++ = *token++;
		*out++ = 0;
		if (*token == '\"')
			token++;
		else
			printf("warning: unterminated quoted string\n");
		return tokenbuffer;
	case '(':
	case ')':
	case '{':
	case '}':
	case '[':
	case ']':
	case '\n':
		tokenbuffer[0] = *token++;
		tokenbuffer[1] = 0;
		return tokenbuffer;
	default:
		while (*token && *token > ' ' && *token != '(' && *token != ')' && *token != '{' && *token != '}' && *token != '[' && *token != ']' && *token != '\"')
			*out++ = *token++;
		*out++ = 0;
		return tokenbuffer;
	}
}

typedef struct sccommand_s
{
	char *name;
	int (*code)(void);
}
sccommand;

int isfloat(char *c)
{
	while (*c)
	{
		switch (*c)
		{
		case '0':
		case '1':
		case '2':
		case '3':
		case '4':
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
		case '.':
		case 'e':
		case 'E':
		case '-':
		case '+':
			break;
		default:
			return 0;
		}
		c++;
	}
	return 1;
}

int isfilename(char *c)
{
	while (*c)
	{
		if (*c < ' ')
			return 0;
		c++;
	}
	return 1;
}

int sc_output(void)
{
	char *c = gettoken();
	if (!c)
		return 0;
	if (!isfilename(c))
		return 0;
	strcpy(output_name, c);
	chopextension(output_name);
	strcat(output_name, ".zym");
	return 1;
}

int sc_origin(void)
{
	int i;
	char *c;
	for (i = 0;i < 3;i++)
	{
		c = gettoken();
		if (!c)
			return 0;
		if (!isfloat(c))
			return 0;
		modelorigin[i] = atof(c);
	}
	return 1;
}

int sc_rotate(void)
{
	char *c = gettoken();
	if (!c)
		return 0;
	if (!isfloat(c))
		return 0;
	modelrotate = atof(c);
	return 1;
}

int sc_scale(void)
{
	char *c = gettoken();
	if (!c)
		return 0;
	if (!isfloat(c))
		return 0;
	modelscale = atof(c);
	return 1;
}

int meshset;

int sc_mesh(void)
{
	char *c;
	if (meshset)
	{
		printf("only one mesh command allowed\n");
		return 0;
	}
	meshset = 1;
	numscenes = 0;
	numposes = 0;
	c = gettoken();
	if (!c)
	{
		printf("no file specified\n");
		return 0;
	}
	if (!isfilename(c))
	{
		printf("%s is not a filename\n", c);
		return 0;
	}
	modelfile = readfile(c, NULL);
	if (!modelfile)
	{
		printf("unable to load file %s\n", c);
		return 0;
	}
	printf("parsing mesh %s\n", c);
#if 1
	if (!parsemeshmodelfile())
		return 0;
	free(modelfile);
	numscenes = 0;
	numposes = 0;
#else
	cleancopyname(scene[0].name, "basepose", MAX_NAME);
	scene[0].start = 0;
	scene[0].framerate = 10; // can be overridden later by fps
	scene[0].noloop = 0; // can be overridden later by noloop
	scene[0].length = 1;
	printf("parsing mesh %s\n", c);
	if (!parsemodelfile())
		return 0;
	free(modelfile);
	numscenes = 1;
	numposes = 1;
#endif
	return 1;
}

int sc_scene(void)
{
	char *c;
	if (!meshset)
	{
		printf("must use mesh command before scene\n");
		return 0;
	}
	c = gettoken();
	if (!c)
	{
		printf("no file specified\n");
		return 0;
	}
	if (!isfilename(c))
	{
		printf("%s is not a filename\n", c);
		return 0;
	}
	modelfile = readfile(c, NULL);
	if (!modelfile)
	{
		printf("unable to load file %s\n", c);
		return 0;
	}
	printf("parsing scene %s\n", c);
	cleancopyname(scene[numscenes].name, c, MAX_NAME);
	scene[numscenes].start = numposes;
	scene[numscenes].framerate = 10; // can be overridden later by fps
	scene[numscenes].noloop = 0; // can be overridden later by noloop
	if (!parsemodelfile())
		return 0;
	free(modelfile);
	scene[numscenes].length = numposes - scene[numscenes].start;
	if (scene[numscenes].length > 0) // only increase if frames were added
		numscenes++;
	return 1;
}

int sc_fps(void)
{
	char *c;
	if (numscenes < 1)
	{
		printf("fps must follow a scene command\n");
		return 0;
	}
	c = gettoken();
	if (!c)
		return 0;
	if (!isfloat(c))
		return 0;
	scene[numscenes-1].framerate = atof(c);
	return 1;
}

int sc_noloop(void)
{
	if (numscenes < 1)
	{
		printf("noloop must follow a scene command\n");
		return 0;
	}
	scene[numscenes-1].noloop = 1;
	return 1;
}

int sc_comment(void)
{
	while (gettoken()[0] != '\n');
	return 1;
}

int sc_nothing(void)
{
	return 1;
}

sccommand sc_commands[] =
{
	{"output", sc_output},
	{"origin", sc_origin},
	{"rotate", sc_rotate},
	{"scale", sc_scale},
	{"mesh", sc_mesh},
	{"scene", sc_scene},
	{"fps", sc_fps},
	{"noloop", sc_noloop},
	{"#", sc_comment},
	{"\n", sc_nothing},
	{"", NULL}
};

int processcommand(char *command)
{
	int r;
	sccommand *c;
	c = sc_commands;
	while (c->name[0])
	{
		if (!strcmp(c->name, command))
		{
			printf("executing command %s\n", command);
			r = c->code();
			if (!r)
				printf("error processing script\n");
			return r;
		}
		c++;
	}
	printf("command %s not recognized\n", command);
	return 0;
}

void processscript(void)
{
//	int i;
	char *c;
	inittokens(scriptbytes);
	numscenes = 0;
	while ((c = gettoken()))
	{
		if (c[0] > ' ')
		{
			if (!processcommand(c))
				return;
		}
	}
	/*
	for (i = 0;i < scriptfiles;i++)
	{
		printf("smd file: %s\n", scriptfile[i]);
		cleancopyname(scene[numscenes].name, scriptfile[i], MAX_NAME);
		scene[numscenes].start = numposes;
		// these should be read from the script
		scene[numscenes].framerate = scriptfileinfo[i].framerate;
		scene[numscenes].noloop = 0 scriptfileinfo[i].noloop;
		modelfile = readfile(scriptfile[i], &modelfilesize);
		if (!modelfile)
			return -1;
		if (!parsemodelfile())
			return -1;
		scene[numscenes].length = numposes - scene[numscenes].start;
		if (scene[numscenes].length > 0 && !scriptfileinfo[i].skip) // only increase if frames were added and not marked as skip
			numscenes++;
	}
	*/
	fixrootbones();
	convertmodel();
}

int main(int argc, char **argv)
{
	if (argc != 2)
	{
		printf("usage: scriptname.txt\n");
		return 0;
	}
	scriptbytes = readfile(argv[1], &scriptsize);
	if (!scriptbytes)
	{
		printf("unable to read script file\n");
		return 0;
	}
	scriptend = scriptbytes + scriptsize;
	processscript();
#if (_MSC_VER && _DEBUG)
	printf("destroy any key\n");
	getchar();
#endif
	return 0;
}
