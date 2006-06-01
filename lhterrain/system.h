
#ifndef SYSTEM_H
#define SYSTEM_H

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

#define GL_NO_ERROR 				0x0
#define GL_INVALID_VALUE			0x0501
#define GL_INVALID_ENUM				0x0500
#define GL_INVALID_OPERATION			0x0502
#define GL_STACK_OVERFLOW			0x0503
#define GL_STACK_UNDERFLOW			0x0504
#define GL_OUT_OF_MEMORY			0x0505

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

#define GL_MAX_TEXTURE_UNITS              0x84E2


extern void (GLAPIENTRY *glEnable)(GLenum cap);
extern void (GLAPIENTRY *glDisable)(GLenum cap);
extern void (GLAPIENTRY *glGetIntegerv)(GLenum pname, GLint *params);
extern const GLubyte *(GLAPIENTRY *glGetString)(GLenum name);
extern void (GLAPIENTRY *glOrtho)(GLdouble left, GLdouble right, GLdouble bottom, GLdouble top, GLdouble near_val, GLdouble far_val);
extern void (GLAPIENTRY *glFrustum)(GLdouble left, GLdouble right, GLdouble bottom, GLdouble top, GLdouble near_val, GLdouble far_val);
extern void (GLAPIENTRY *glGenTextures)(GLsizei n, GLuint *textures);
extern void (GLAPIENTRY *glBindTexture)(GLenum target, GLuint texture);
extern void (GLAPIENTRY *glTexImage2D)(GLenum target, GLint level, GLint internalFormat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, const GLvoid *pixels );
extern void (GLAPIENTRY *glTexParameteri)(GLenum target, GLenum pname, GLint param);
extern void (GLAPIENTRY *glColor4f)(GLfloat r, GLfloat g, GLfloat b, GLfloat a);
extern void (GLAPIENTRY *glTexCoord2f)(GLfloat s, GLfloat t);
extern void (GLAPIENTRY *glVertex3f)(GLfloat x, GLfloat y, GLfloat z);
extern void (GLAPIENTRY *glBegin)(GLenum mode);
extern void (GLAPIENTRY *glEnd)(void);
extern GLenum (GLAPIENTRY *glGetError)(void);
extern void (GLAPIENTRY *glClearColor)(GLclampf red, GLclampf green, GLclampf blue, GLclampf alpha);
extern void (GLAPIENTRY *glClear)(GLbitfield mask);
extern void (GLAPIENTRY *glMatrixMode)(GLenum mode);
extern void (GLAPIENTRY *glLoadIdentity)(void);
extern void (GLAPIENTRY *glRotatef)(GLfloat angle, GLfloat x, GLfloat y, GLfloat z);
extern void (GLAPIENTRY *glTranslatef)(GLfloat x, GLfloat y, GLfloat z);
extern void (GLAPIENTRY *glVertexPointer)(GLint size, GLenum type, GLsizei stride, const GLvoid *ptr);
extern void (GLAPIENTRY *glNormalPointer)(GLenum type, GLsizei stride, const GLvoid *ptr);
extern void (GLAPIENTRY *glColorPointer)(GLint size, GLenum type, GLsizei stride, const GLvoid *ptr);
extern void (GLAPIENTRY *glTexCoordPointer)(GLint size, GLenum type, GLsizei stride, const GLvoid *ptr);
extern void (GLAPIENTRY *glDrawElements)(GLenum mode, GLsizei count, GLenum type, const GLvoid *indices);
extern void (GLAPIENTRY *glDrawRangeElements)(GLenum mode, GLuint start, GLuint end, GLsizei count, GLenum type, const GLvoid *indices);

extern void (GLAPIENTRY *glBindBufferARB) (GLenum target, GLuint buffer);
extern void (GLAPIENTRY *glDeleteBuffersARB) (GLsizei n, const GLuint *buffers);
extern void (GLAPIENTRY *glGenBuffersARB) (GLsizei n, GLuint *buffers);
extern GLboolean (GLAPIENTRY *glIsBufferARB) (GLuint buffer);
extern GLvoid* (GLAPIENTRY *glMapBufferARB) (GLenum target, GLenum access);
extern GLboolean (GLAPIENTRY *glUnmapBufferARB) (GLenum target);
extern void (GLAPIENTRY *glBufferDataARB) (GLenum target, GLsizeiptrARB size, const GLvoid *data, GLenum usage);
extern void (GLAPIENTRY *glBufferSubDataARB) (GLenum target, GLintptrARB offset, GLsizeiptrARB size, const GLvoid *data);



extern int glerrornum;
void GL_PrintError(int errornumber, char *filename, int linenumber);
#define CHECKGLERROR if ((glerrornum = glGetError())) GL_PrintError(glerrornum, __FILE__, __LINE__);

#define MAX_TEXTUREUNITS 8
extern GLint gl_textureunits;
extern GLint gl_maxtexturesize;
extern const char *gl_ext_string;
extern int gl_ext_drawrangeelements;
extern int gl_ext_vbo;

extern int system_width, system_height;

void drawstring(const char *string, float x, float y, float scalex, float scaley);
void application(char *filename);

#endif
