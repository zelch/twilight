/*
Copyright (C) 1996-1997 Id Software, Inc.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*/

#ifndef RENDER_H
#define RENDER_H

// 1.0f / N table
extern float ixtable[4096];

// far clip distance for scene
extern float r_farclip;

// fog stuff
extern void FOG_clear(void);
extern float fog_density, fog_red, fog_green, fog_blue;

// sky stuff
extern int R_SetSkyBox(char* sky);
extern cvar_t r_sky;
// these are exposed because surface rendering uses them
extern rtexture_t *solidskytexture;
extern rtexture_t *alphaskytexture;
extern int skyrendernow, skyrendermasked;
extern void R_SkyStartFrame(void);
extern void R_Sky(void);

// SHOWLMP stuff (Nehahra)
extern void SHOWLMP_decodehide(void);
extern void SHOWLMP_decodeshow(void);
extern void SHOWLMP_drawall(void);
extern void SHOWLMP_clear(void);

// render profiling stuff
extern qboolean intimerefresh;
extern char r_speeds_string[1024];

// lighting stuff
extern vec3_t lightspot;
extern cvar_t r_ambient;
extern int lightscalebit;
extern float lightscale;

// model rendering stuff
extern float *aliasvert;
extern float *aliasvertnorm;
extern float *aliasvertcolor;

// vis stuff
extern cvar_t r_novis;

#define	TOP_RANGE		16			// soldier uniform colors
#define	BOTTOM_RANGE	96

//=============================================================================

extern	entity_render_t	*currentrenderentity;
extern	int			r_framecount;
extern	mplane_t	frustum[4];
extern	int		c_brush_polys, c_alias_polys, c_light_polys, c_faces, c_nodes, c_leafs, c_models, c_bmodels, c_sprites, c_particles, c_dlights;


//
// view origin
//
extern	vec3_t	vup;
extern	vec3_t	vpn;
extern	vec3_t	vright;
extern	vec3_t	r_origin;

extern	mleaf_t		*r_viewleaf, *r_oldviewleaf;
extern	unsigned short	d_lightstylevalue[256];	// 8.8 fraction of base light value

extern	qboolean	envmap;

extern	cvar_t	r_drawentities;
extern	cvar_t	r_drawviewmodel;
extern	cvar_t	r_speeds;
extern	cvar_t	r_fullbright;
extern	cvar_t	r_wateralpha;
extern	cvar_t	r_dynamic;

void R_Init (void);
void R_RenderView (void); // must set r_refdef first


void R_InitSky (qbyte *src, int bytesperpixel); // called at level load

void R_NewMap (void);

void R_DrawWorld(void);
void R_SetupForWorldRendering(void);
void R_MarkWorldLights(void);
void R_PrepareSurfaces(void);
void R_DrawSurfaces(int type);
void R_DrawPortals(void);
void R_DrawParticles(void);
void R_DrawExplosions(void);

// LordHavoc: vertex transform
#include "transform.h"

#define gl_solid_format 3
#define gl_alpha_format 4

//#define PARANOID 1

// LordHavoc: was a major time waster
#define R_CullBox(mins,maxs) (frustum[0].BoxOnPlaneSideFunc(mins, maxs, &frustum[0]) == 2 || frustum[1].BoxOnPlaneSideFunc(mins, maxs, &frustum[1]) == 2 || frustum[2].BoxOnPlaneSideFunc(mins, maxs, &frustum[2]) == 2 || frustum[3].BoxOnPlaneSideFunc(mins, maxs, &frustum[3]) == 2)
#define R_NotCulledBox(mins,maxs) (frustum[0].BoxOnPlaneSideFunc(mins, maxs, &frustum[0]) != 2 && frustum[1].BoxOnPlaneSideFunc(mins, maxs, &frustum[1]) != 2 && frustum[2].BoxOnPlaneSideFunc(mins, maxs, &frustum[2]) != 2 && frustum[3].BoxOnPlaneSideFunc(mins, maxs, &frustum[3]) != 2)

extern qboolean fogenabled;
extern vec3_t fogcolor;
extern vec_t fogdensity;
#define calcfog(v) (exp(-(fogdensity*fogdensity*(((v)[0] - r_origin[0])*((v)[0] - r_origin[0])+((v)[1] - r_origin[1])*((v)[1] - r_origin[1])+((v)[2] - r_origin[2])*((v)[2] - r_origin[2])))))
#define calcfogbyte(v) ((qbyte) (bound(0, ((int) ((float) (calcfog((v)) * 255.0f))), 255)))

// start a farclip measuring session
void R_FarClip_Start(vec3_t origin, vec3_t direction, vec_t startfarclip);
// enlarge farclip to accomodate box
void R_FarClip_Box(vec3_t mins, vec3_t maxs);
// return farclip value
float R_FarClip_Finish(void);

// updates farclip distance so it is large enough for the specified box
// (*important*)
void R_Mesh_EnlargeFarClipBBox(vec3_t mins, vec3_t maxs);

#include "r_modules.h"

extern float overbrightscale;

#include "r_lerpanim.h"

void R_DrawBrushModelSky (void);
void R_DrawBrushModelNormal (void);
void R_DrawAliasModel (void);
void R_DrawSpriteModel (void);

extern cvar_t r_render;
#include "image.h"

extern cvar_t r_multitexture;
extern cvar_t gl_dither;

// FIXME: this should live in the backend only
void GL_LockArray(int first, int count);
void GL_UnlockArray(void);

#include "gl_backend.h"

#include "r_light.h"

void R_TimeReport(char *name);
void R_TimeReport_Start(void);
void R_TimeReport_End(void);

// r_stain
void R_Stain (vec3_t origin, float radius, int cr1, int cg1, int cb1, int ca1, int cr2, int cg2, int cb2, int ca2);

void R_DrawCrosshair(void);

#endif

