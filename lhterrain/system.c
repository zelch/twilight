
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <SDL.h>
#include <SDL_main.h>
#include "system.h"
#include "texture.h"
#include "endian.h"

GLint gl_textureunits = 1;
GLint gl_maxtexturesize = 2048;

const char *gl_ext_string = "";
int gl_ext_drawrangeelements = 0;
int gl_ext_vbo = 0;

int system_width, system_height;

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



int glerrornum;
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
#define CHECKGLERROR if ((glerrornum = glGetError())) GL_PrintError(glerrornum, __FILE__, __LINE__);



typedef struct glfunc_s
{
	const char *name;
	void **var;
}
glfunc_t;

glfunc_t glfunctions[] =
{
	{"glEnable", (void **)&glEnable},
	{"glDisable", (void **)&glDisable},
	{"glGetIntegerv", (void **)&glGetIntegerv},
	{"glGetString", (void **)&glGetString},
	{"glOrtho", (void **)&glOrtho},
	{"glFrustum", (void **)&glFrustum},
	{"glGenTextures", (void **)&glGenTextures},
	{"glBindTexture", (void **)&glBindTexture},
	{"glTexImage2D", (void **)&glTexImage2D},
	{"glTexParameteri", (void **)&glTexParameteri},
	{"glColor4f", (void **)&glColor4f},
	{"glTexCoord2f", (void **)&glTexCoord2f},
	{"glVertex3f", (void **)&glVertex3f},
	{"glBegin", (void **)&glBegin},
	{"glEnd", (void **)&glEnd},
	{"glGetError", (void **)&glGetError},
	{"glClearColor", (void **)&glClearColor},
	{"glClear", (void **)&glClear},
	{"glMatrixMode", (void **)&glMatrixMode},
	{"glLoadIdentity", (void **)&glLoadIdentity},
	{"glRotatef", (void **)&glRotatef},
	{"glTranslatef", (void **)&glTranslatef},
	{"glVertexPointer", (void **)&glVertexPointer},
	{"glNormalPointer", (void **)&glNormalPointer},
	{"glColorPointer", (void **)&glColorPointer},
	{"glTexCoordPointer", (void **)&glTexCoordPointer},
	{"glDrawElements", (void **)&glDrawElements},
	{"glDrawRangeElements", (void **)&glDrawRangeElements},

	{"glBindBufferARB", (void **)&glBindBufferARB},
	{"glDeleteBuffersARB", (void **)&glDeleteBuffersARB},
	{"glGenBuffersARB", (void **)&glGenBuffersARB},
	{"glIsBufferARB", (void **)&glIsBufferARB},
	{"glMapBufferARB", (void **)&glMapBufferARB},
	{"glUnmapBufferARB", (void **)&glUnmapBufferARB},
	{"glBufferDataARB", (void **)&glBufferDataARB},
	{"glBufferSubDataARB", (void **)&glBufferSubDataARB},

	{NULL, NULL},
};

SDL_Surface *initvideo(int width, int height, int bpp, int fullscreen)
{
	int i;
	SDL_Surface *surface;
	if (SDL_GL_LoadLibrary (NULL))
	{
		printf("Unable to load GL library\n");
		SDL_Quit();
		exit(1);
	}
	SDL_GL_SetAttribute (SDL_GL_DOUBLEBUFFER, 1);
	surface = SDL_SetVideoMode(640, 480, 16, SDL_OPENGL | (fullscreen ? (SDL_FULLSCREEN | SDL_DOUBLEBUF) : 0));
	if (!surface)
		return NULL;

	for (i = 0;glfunctions[i].name;i++)
		*(glfunctions[i].var) = (void *)SDL_GL_GetProcAddress(glfunctions[i].name);

	gl_ext_string = (const char *)glGetString(GL_EXTENSIONS);
	gl_ext_drawrangeelements = strstr(gl_ext_string, "GL_EXT_draw_range_elements") != NULL;
	gl_ext_vbo = strstr(gl_ext_string, "GL_ARB_vertex_buffer_object") != NULL;

	glGetIntegerv(GL_MAX_TEXTURE_SIZE, &gl_maxtexturesize);
	glGetIntegerv(GL_MAX_TEXTURE_UNITS, &gl_textureunits);
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

int main(int argc, char **argv)
{
	SDL_Surface *surface;
	char caption[1024];
	if (argc != 2)
	{
		printf("usage: %s <filename>\n", argv[0]);
		return 1;
	}

	printf("Initializing SDL.\n");

	/* Initialize defaults, Video and Audio */
	if ((SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER) == -1))
	{
		printf("Could not initialize SDL: %s.\n", SDL_GetError());
		SDL_Quit();
		exit(-1);
	}

	glerrornum = 0;
	surface = initvideo(800, 600, 32, 0);
	if (!surface)
	{
		SDL_Quit();
		return -1;
	}
	system_width = surface->w;
	system_height = surface->h;

	printf("SDL initialized.\n");

	printf("using an SDL opengl %dx%dx%dbpp surface.\n", surface->w, surface->h, surface->format->BitsPerPixel);

	SDL_EnableUNICODE(1);
	initimagetextures();
	InitSwapFunctions();
	sprintf(caption, "%s: %s", argv[0], argv[1]);
	SDL_WM_SetCaption(caption, NULL);
	application(argv[1]);

	printf("Quiting SDL.\n");

	/* Shutdown all subsystems */
	SDL_Quit();

	printf("Quiting....\n");
	return 0;
}
