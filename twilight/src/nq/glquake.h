/*
	$RCSfile$

	Copyright (C) 1996-1997  Id Software, Inc.

	This program is free software; you can redistribute it and/or
	modify it under the terms of the GNU General Public License
	as published by the Free Software Foundation; either version 2
	of the License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  

	See the GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program; if not, write to:
	
		Free Software Foundation, Inc.
		59 Temple Place - Suite 330
		Boston, MA  02111-1307, USA

	$Id$
*/

#ifndef __GLQUAKE_H
#define __GLQUAKE_H

// disable data conversion warnings

#ifdef _WIN32
#if _MSC_VER >= 800	/* MSVC 4.0 */
// disable data conversion warnings
#pragma warning(disable : 4244)			// MIPS
#pragma warning(disable : 4136)			// X86
#pragma warning(disable : 4051)			// ALPHA
#endif

#include <windows.h>
#endif

#include "TGL_defines.h"
#include "TGL_types.h"
#include "TGL_funcs.h"

#include "client.h"
#include "mathlib.h"
#include "render.h"

void        GL_BeginRendering (int *x, int *y, int *width, int *height);
void        GL_EndRendering (void);

GLint APIENTRY gluScaleImage( GLenum format,
                              GLsizei widthin, GLsizei heightin,
                              GLenum typein, const void *datain,
                              GLsizei widthout, GLsizei heightout,
                              GLenum typeout, void *dataout );
int gluBuild2DMipmaps (GLenum target, GLint components, 
						GLint width, GLint height, 
						GLenum format, GLenum type, const void *data);

extern int  texture_extension_number;

extern float gldepthmin, gldepthmax;

void        GL_Upload32 (unsigned *data, int width, int height, qboolean mipmap,
						 int alpha);
void		GL_Upload8 (Uint8 *data, int width, int height, qboolean mipmap, 
						int alpha, unsigned *table);
int         GL_LoadTexture (char *identifier, int width, int height,
							Uint8 * data, qboolean mipmap, int alpha);
int         GL_FindTexture (char *identifier);

typedef struct {
	float       x, y, z;
	float       s, t;
	float       r, g, b;
} glvert_t;

extern glvert_t glv;

extern int  glx, gly, glwidth, glheight;

// r_local.h -- private refresh defs

#define ALIAS_BASE_SIZE_RATIO		(1.0 / 11.0)
					// normalizing factor so player model works out to about
					// 1 pixel per triangle
#define	MAX_LBM_HEIGHT		480

#define TILE_SIZE		128				// size of textures generated by
										// R_GenTiledSurf

#define SKYSHIFT		7
#define	SKYSIZE			(1 << SKYSHIFT)
#define SKYMASK			(SKYSIZE - 1)

#define BACKFACE_EPSILON	0.01

#define	MAX_GLTEXTURES	1024

void        R_ReadPointFile_f (void);
texture_t  *R_TextureAnimation (texture_t *base);

typedef struct surfcache_s {
	struct surfcache_s *next;
	struct surfcache_s **owner;			// NULL is an empty chunk of memory
	int         lightadj[MAXLIGHTMAPS];	// checked for strobe flush
	int         dlight;
	int         size;					// including header
	unsigned    width;
	unsigned    height;					// DEBUG only needed for debug
	float       mipscale;
	struct texture_s *texture;			// checked for animating textures
	Uint8       data[4];				// width*height elements
} surfcache_t;


typedef struct {
	pixel_t    *surfdat;				// destination for generated surface
	int         rowbytes;				// destination logical width in bytes
	msurface_t *surf;					// description for surface to generate
	fixed8_t    lightadj[MAXLIGHTMAPS];
	// adjust for lightmap levels for dynamic lighting
	texture_t  *texture;				// corrected for animating textures
	int         surfmip;				// mipmapped ratio of surface texels /
										// world pixels
	int         surfwidth;				// in mipmapped texels
	int         surfheight;				// in mipmapped texels
} drawsurf_t;


//====================================================


extern entity_t r_worldentity;
extern qboolean r_cache_thrash;			// compatability
extern vec3_t modelorg, r_entorigin;
extern entity_t *currententity;
extern int  r_visframecount;			// ??? what difs?
extern int  r_framecount;
extern int  c_brush_polys, c_alias_polys;


//
// view origin
//
extern vec3_t vup;
extern vec3_t vpn;
extern vec3_t vright;
extern vec3_t r_origin;

//
// screen size info
//
extern refdef_t r_refdef;
extern mleaf_t *r_viewleaf, *r_oldviewleaf;
extern texture_t *r_notexture_mip;
extern int  d_lightstylevalue[256];		// 8.8 fraction of base light value

extern int  currenttexture;
extern int  cnttextures[2];
extern int  particletexture;
extern int  playertextures;

extern int  skytexturenum;				// index in cl.loadmodel, not gl
										// texture object

extern int  skyboxtexnum;

extern struct cvar_s *r_norefresh;
extern struct cvar_s *r_drawentities;
extern struct cvar_s *r_drawworld;
extern struct cvar_s *r_drawviewmodel;
extern struct cvar_s *r_speeds;
extern struct cvar_s *r_waterwarp;
extern struct cvar_s *r_fullbright;
extern struct cvar_s *r_lightmap;
extern struct cvar_s *r_shadows;
extern struct cvar_s *r_wateralpha;
extern struct cvar_s *r_dynamic;
extern struct cvar_s *r_novis;
extern struct cvar_s *r_skybox;
extern struct cvar_s *r_fastsky;
extern struct cvar_s *r_lightlerp;

extern struct cvar_s *gl_clear;
extern struct cvar_s *gl_cull;
extern struct cvar_s *gl_poly;
extern struct cvar_s *gl_texsort;
extern struct cvar_s *gl_affinemodels;
extern struct cvar_s *gl_polyblend;
extern struct cvar_s *gl_keeptjunctions;
extern struct cvar_s *gl_reporttjunctions;
extern struct cvar_s *gl_flashblend;
extern struct cvar_s *gl_nocolors;
extern struct cvar_s *gl_doubleeyes;
extern struct cvar_s *gl_im_animation;
extern struct cvar_s *gl_im_transform;
extern struct cvar_s *gl_fb_models;
extern struct cvar_s *gl_fb_bmodels;
extern struct cvar_s *gl_oldlights;
extern struct cvar_s *gl_colorlights;

extern int  gl_lightmap_format;
extern int  gl_solid_format;
extern int  gl_alpha_format;
extern qboolean colorlights;

extern struct cvar_s *gl_max_size;
extern struct cvar_s *gl_playermip;

extern float r_world_matrix[16];

extern const char *gl_vendor;
extern const char *gl_renderer;
extern const char *gl_version;
extern const char *gl_extensions;

void        R_TranslatePlayerSkin (int playernum);

// Multitexture
#define    TEXTURE0_SGIS				0x835E
#define    TEXTURE1_SGIS				0x835F

#ifndef GL_ACTIVE_TEXTURE_ARB
// multitexture
#define GL_ACTIVE_TEXTURE_ARB			0x84E0
#define GL_CLIENT_ACTIVE_TEXTURE_ARB	0x84E1
#define GL_MAX_TEXTURES_UNITS_ARB		0x84E2
#define GL_TEXTURE0_ARB					0x84C0
#define GL_TEXTURE1_ARB					0x84C1
#define GL_TEXTURE2_ARB					0x84C2
#define GL_TEXTURE3_ARB					0x84C3
// note: ARB supports up to 32 units, but only 2 are currently used in this engine
#endif

typedef void (APIENTRY * lpMTexFUNC) (GLenum, GLfloat, GLfloat);
typedef void (APIENTRY * lpSelTexFUNC) (GLenum);
extern lpMTexFUNC qglMTexCoord2f;
extern lpSelTexFUNC qglSelectTexture;

extern qboolean gl_mtexable;

void        R_DrawWorld (void);
void        R_RenderBrushPoly (msurface_t *fa);
void        R_DrawWaterSurfaces (void);
void        R_DrawParticles (void);
void        V_CalcBlend (void);
void        R_DrawBrushModel (entity_t *e);
void        GL_BuildLightmaps (void);
void        R_ClearParticles (void);
void        R_InitParticles (void);
void        R_StoreEfrags (efrag_t **ppefrag);
qboolean    R_CullBox (vec3_t mins, vec3_t maxs);
void        R_DrawSkyChain (msurface_t *s);
void        EmitBothSkyLayers (msurface_t *fa);
void        EmitWaterPolys (msurface_t *fa);
void        EmitSkyPolys (msurface_t *fa);

#endif // __GLQUAKE_H

