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

*/
// gl_warp.c -- sky and water polygons
static const char rcsid[] =
    "$Id$";

#ifdef HAVE_CONFIG_H
# include <config.h>
#else
# ifdef _WIN32
#  include <win32conf.h>
# endif
#endif

#include <stdio.h>
#include <stdlib.h>

#include "client.h"
#include "cvar.h"
#include "glquake.h"
#include "mathlib.h"
#include "tga.h"
#include "sys.h"

extern model_t *loadmodel;

int         skytexturenum;

int         solidskytexture;
int         alphaskytexture;
float       speedscale;					// for top sky and bottom sky

msurface_t *warpface;

extern cvar_t *gl_subdivide_size;

void
BoundPoly (int numverts, float *verts, vec3_t mins, vec3_t maxs)
{
	int         i, j;
	float      *v;

	mins[0] = mins[1] = mins[2] = 9999;
	maxs[0] = maxs[1] = maxs[2] = -9999;
	v = verts;
	for (i = 0; i < numverts; i++)
		for (j = 0; j < 3; j++, v++) {
			if (*v < mins[j])
				mins[j] = *v;
			if (*v > maxs[j])
				maxs[j] = *v;
		}
}

void
SubdividePolygon (int numverts, float *verts)
{
	int         i, j, k;
	vec3_t      mins, maxs;
	float       m;
	float      *v;
	vec3_t      front[64], back[64];
	int         f, b;
	float       dist[64];
	float       frac;
	glpoly_t   *poly;
	float       s, t;

	if (!numverts)
		Sys_Error ("numverts = 0!");
	if (numverts > 60)
		Sys_Error ("numverts = %i", numverts);

	BoundPoly (numverts, verts, mins, maxs);

	for (i = 0; i < 3; i++) {
		m = (mins[i] + maxs[i]) * 0.5;
		m = gl_subdivide_size->value
			* Q_floor (m / gl_subdivide_size->value + 0.5);
		if (maxs[i] - m < 8)
			continue;
		if (m - mins[i] < 8)
			continue;

		// cut it
		v = verts + i;
		for (j = 0; j < numverts; j++, v += 3)
			dist[j] = *v - m;

		// wrap cases
		dist[j] = dist[0];
		v -= i;
		VectorCopy (verts, v);

		f = b = 0;
		v = verts;
		for (j = 0; j < numverts; j++, v += 3) {
			if (dist[j] >= 0) {
				VectorCopy (v, front[f]);
				f++;
			}
			if (dist[j] <= 0) {
				VectorCopy (v, back[b]);
				b++;
			}
			if (dist[j] == 0 || dist[j + 1] == 0)
				continue;
			if ((dist[j] > 0) != (dist[j + 1] > 0)) {
				// clip point
				frac = dist[j] / (dist[j] - dist[j + 1]);
				for (k = 0; k < 3; k++)
					front[f][k] = back[b][k] = v[k] + frac * (v[3 + k] - v[k]);
				f++;
				b++;
			}
		}

		SubdividePolygon (f, front[0]);
		SubdividePolygon (b, back[0]);
		return;
	}

	poly =
		Hunk_Alloc (sizeof (glpoly_t) +
					(numverts - 4) * VERTEXSIZE * sizeof (float));
	poly->next = warpface->polys;
	warpface->polys = poly;
	poly->numverts = numverts;
	for (i = 0; i < numverts; i++, verts += 3) {
		VectorCopy (verts, poly->verts[i]);
		s = DotProduct (verts, warpface->texinfo->vecs[0]);
		t = DotProduct (verts, warpface->texinfo->vecs[1]);
		poly->verts[i][3] = s;
		poly->verts[i][4] = t;
	}
}

/*
================
GL_SubdivideSurface

Breaks a polygon up along axial 64 unit
boundaries so that turbulent and sky warps
can be done reasonably.
================
*/
void
GL_SubdivideSurface (msurface_t *fa)
{
	vec3_t      verts[64];
	int         numverts;
	int         i;
	int         lindex;
	float      *vec;

	warpface = fa;

	// 
	// convert edges back to a normal polygon
	// 
	numverts = 0;
	for (i = 0; i < fa->numedges; i++) {
		lindex = loadmodel->surfedges[fa->firstedge + i];

		if (lindex > 0)
			vec = loadmodel->vertexes[loadmodel->edges[lindex].v[0]].position;
		else
			vec = loadmodel->vertexes[loadmodel->edges[-lindex].v[1]].position;
		VectorCopy (vec, verts[numverts]);
		numverts++;
	}

	SubdividePolygon (numverts, verts[0]);
}

//=========================================================



// speed up sin calculations - Ed
float       turbsin[] = {
#include "gl_warp_sin.h"
};

#define TURBSCALE (256.0 / (2 * M_PI))

/*
=============
EmitWaterPolys

Does a water warp on the pre-fragmented glpoly_t chain
=============
*/
void
EmitWaterPolys (msurface_t *fa)
{
	glpoly_t   *p;
	float      *v;
	int         i;
	float       s, t, os, ot;


	for (p = fa->polys; p; p = p->next) {
		qglBegin (GL_POLYGON);
		for (i = 0, v = p->verts[0]; i < p->numverts; i++, v += VERTEXSIZE) {
			os = v[3];
			ot = v[4];

			s = os + turbsin[(int) ((ot * 0.125 + realtime) * TURBSCALE) & 255];
			s *= (1.0 / 64);

			t = ot + turbsin[(int) ((os * 0.125 + realtime) * TURBSCALE) & 255];
			t *= (1.0 / 64);

			qglTexCoord2f (s, t);
			qglVertex3fv (v);
		}
		qglEnd ();
	}
}




/*
=============
EmitSkyPolys
=============
*/
void
EmitSkyPolys (msurface_t *fa)
{
	glpoly_t   *p;
	float      *v;
	int         i;
	float       s, t;
	vec3_t      dir;
	float       length;

	for (p = fa->polys; p; p = p->next) {
		qglBegin (GL_POLYGON);
		for (i = 0, v = p->verts[0]; i < p->numverts; i++, v += VERTEXSIZE) {
			VectorSubtract (v, r_origin, dir);
			dir[2] *= 3;				// flatten the sphere

			length = 6 * 63 / VectorLength(dir);

			dir[0] *= length;
			dir[1] *= length;

			s = (speedscale + dir[0]) * (1.0 / 128);
			t = (speedscale + dir[1]) * (1.0 / 128);

			qglTexCoord2f (s, t);
			qglVertex3fv (v);
		}
		qglEnd ();
	}
}

/*
===============
EmitBothSkyLayers

Does a sky warp on the pre-fragmented glpoly_t chain
This will be called for brushmodels, the world
will have them chained together.
===============
*/
void
EmitBothSkyLayers (msurface_t *fa)
{
	qglBindTexture (GL_TEXTURE_2D, solidskytexture);
	speedscale = realtime * 8;
	speedscale -= (int) speedscale & ~127;

	EmitSkyPolys (fa);

	qglEnable (GL_BLEND);
	qglBindTexture (GL_TEXTURE_2D, alphaskytexture);
	speedscale = realtime * 16;
	speedscale -= (int) speedscale & ~127;

	EmitSkyPolys (fa);

	qglDisable (GL_BLEND);
}

#ifndef QUAKE2
/*
=================
R_DrawSkyChain
=================
*/
void
R_DrawSkyChain (msurface_t *s)
{
	msurface_t *fa;

	// used when gl_texsort is on
	qglBindTexture (GL_TEXTURE_2D, solidskytexture);
	speedscale = realtime * 8;
	speedscale -= (int) speedscale & ~127;

	for (fa = s; fa; fa = fa->texturechain)
		EmitSkyPolys (fa);

	qglEnable (GL_BLEND);
	qglBindTexture (GL_TEXTURE_2D, alphaskytexture);
	speedscale = realtime * 16;
	speedscale -= (int) speedscale & ~127;

	for (fa = s; fa; fa = fa->texturechain)
		EmitSkyPolys (fa);

	qglDisable (GL_BLEND);
}

#endif

/*
=================================================================

  Quake 2 environment sky

=================================================================
*/

#ifdef QUAKE2

/*
==================
R_LoadSkys
==================
*/
char       *suf[6] = { "rt", "bk", "lf", "ft", "up", "dn" };
R_LoadSkys (void)
{
	int   i, w, h;
	char  name[64];
	byte  *image_rgba;

	for (i = 0; i < 6; i++) {

		snprintf (name, sizeof (name), "gfx/env/bkgtst%s.tga", suf[i]);

		TGA_Load (name, &w, &h);

		if (!image_rgba || (w != 256) || (h != 256))
			continue;

		qglBindTexture (GL_TEXTURE_2D, SKYTEX + i);

		qglTexImage2D (GL_TEXTURE_2D, 0, gl_solid_format, 256, 256, 0, GL_RGBA,
					  GL_UNSIGNED_BYTE, image_rgba);

		free (image_rgba);

		qglTexParameterf (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		qglTexParameterf (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	}
}


vec3_t      skyclip[6] = {
	{1, 1, 0},
	{1, -1, 0},
	{0, -1, 1},
	{0, 1, 1},
	{1, 0, 1},
	{-1, 0, 1}
};
int         c_sky;

// 1 = s, 2 = t, 3 = 2048
int         st_to_vec[6][3] = {
	{3, -1, 2},
	{-3, 1, 2},

	{1, 3, 2},
	{-1, -3, 2},

	{-2, -1, 3},						// 0 degrees yaw, look straight up
	{2, -1, -3}							// look straight down

//  {-1,2,3},
//  {1,2,-3}
};

// s = [0]/[2], t = [1]/[2]
int         vec_to_st[6][3] = {
	{-2, 3, 1},
	{2, 3, -1},

	{1, 3, 2},
	{-1, 3, -2},

	{-2, -1, 3},
	{-2, 1, -3}

//  {-1,2,3},
//  {1,2,-3}
};

float       skymins[2][6], skymaxs[2][6];

void
DrawSkyPolygon (int nump, vec3_t vecs)
{
	int         i, j;
	vec3_t      v, av;
	float       s, t, dv;
	int         axis;
	float      *vp;

	c_sky++;
#if 0
	qglBegin (GL_POLYGON);
	for (i = 0; i < nump; i++, vecs += 3) {
		VectorAdd (vecs, r_origin, v);
		qglVertex3fv (v);
	}
	qglEnd ();
	return;
#endif
	// decide which face it maps to
	VectorClear (v);
	for (i = 0, vp = vecs; i < nump; i++, vp += 3) {
		VectorAdd (vp, v, v);
	}
	av[0] = Q_fabs (v[0]);
	av[1] = Q_fabs (v[1]);
	av[2] = Q_fabs (v[2]);
	if (av[0] > av[1] && av[0] > av[2]) {
		if (v[0] < 0)
			axis = 1;
		else
			axis = 0;
	} else if (av[1] > av[2] && av[1] > av[0]) {
		if (v[1] < 0)
			axis = 3;
		else
			axis = 2;
	} else {
		if (v[2] < 0)
			axis = 5;
		else
			axis = 4;
	}

	// project new texture coords
	for (i = 0; i < nump; i++, vecs += 3) {
		j = vec_to_st[axis][2];
		if (j > 0)
			dv = vecs[j - 1];
		else
			dv = -vecs[-j - 1];

		j = vec_to_st[axis][0];
		if (j < 0)
			s = -vecs[-j - 1] / dv;
		else
			s = vecs[j - 1] / dv;
		j = vec_to_st[axis][1];
		if (j < 0)
			t = -vecs[-j - 1] / dv;
		else
			t = vecs[j - 1] / dv;

		if (s < skymins[0][axis])
			skymins[0][axis] = s;
		if (t < skymins[1][axis])
			skymins[1][axis] = t;
		if (s > skymaxs[0][axis])
			skymaxs[0][axis] = s;
		if (t > skymaxs[1][axis])
			skymaxs[1][axis] = t;
	}
}

#define	MAX_CLIP_VERTS	64
void
ClipSkyPolygon (int nump, vec3_t vecs, int stage)
{
	float      *norm;
	float      *v;
	qboolean    front, back;
	float       d, e;
	float       dists[MAX_CLIP_VERTS];
	int         sides[MAX_CLIP_VERTS];
	vec3_t      newv[2][MAX_CLIP_VERTS];
	int         newc[2];
	int         i, j;

	if (nump > MAX_CLIP_VERTS - 2)
		Sys_Error ("ClipSkyPolygon: MAX_CLIP_VERTS");
	if (stage == 6) {					// fully clipped, so draw it
		DrawSkyPolygon (nump, vecs);
		return;
	}

	front = back = false;
	norm = skyclip[stage];
	for (i = 0, v = vecs; i < nump; i++, v += 3) {
		d = DotProduct (v, norm);
		if (d > ON_EPSILON) {
			front = true;
			sides[i] = SIDE_FRONT;
		} else if (d < ON_EPSILON) {
			back = true;
			sides[i] = SIDE_BACK;
		} else
			sides[i] = SIDE_ON;
		dists[i] = d;
	}

	if (!front || !back) {				// not clipped
		ClipSkyPolygon (nump, vecs, stage + 1);
		return;
	}
	// clip it
	sides[i] = sides[0];
	dists[i] = dists[0];
	VectorCopy (vecs, (vecs + (i * 3)));
	newc[0] = newc[1] = 0;

	for (i = 0, v = vecs; i < nump; i++, v += 3) {
		switch (sides[i]) {
			case SIDE_FRONT:
				VectorCopy (v, newv[0][newc[0]]);
				newc[0]++;
				break;
			case SIDE_BACK:
				VectorCopy (v, newv[1][newc[1]]);
				newc[1]++;
				break;
			case SIDE_ON:
				VectorCopy (v, newv[0][newc[0]]);
				newc[0]++;
				VectorCopy (v, newv[1][newc[1]]);
				newc[1]++;
				break;
		}

		if (sides[i] == SIDE_ON || sides[i + 1] == SIDE_ON
			|| sides[i + 1] == sides[i])
			continue;

		d = dists[i] / (dists[i] - dists[i + 1]);
		for (j = 0; j < 3; j++) {
			e = v[j] + d * (v[j + 3] - v[j]);
			newv[0][newc[0]][j] = e;
			newv[1][newc[1]][j] = e;
		}
		newc[0]++;
		newc[1]++;
	}

	// continue
	ClipSkyPolygon (newc[0], newv[0][0], stage + 1);
	ClipSkyPolygon (newc[1], newv[1][0], stage + 1);
}

/*
=================
R_DrawSkyChain
=================
*/
void
R_DrawSkyChain (msurface_t *s)
{
	msurface_t *fa;

	int         i;
	vec3_t      verts[MAX_CLIP_VERTS];
	glpoly_t   *p;

	c_sky = 0;
	qglBindTexture (GL_TEXTURE_2D, solidskytexture);

	// calculate vertex values for sky box

	for (fa = s; fa; fa = fa->texturechain) {
		for (p = fa->polys; p; p = p->next) {
			for (i = 0; i < p->numverts; i++) {
				VectorSubtract (p->verts[i], r_origin, verts[i]);
			}
			ClipSkyPolygon (p->numverts, verts[0], 0);
		}
	}
}


/*
==============
R_ClearSkyBox
==============
*/
void
R_ClearSkyBox (void)
{
	int         i;

	for (i = 0; i < 6; i++) {
		skymins[0][i] = skymins[1][i] = 9999;
		skymaxs[0][i] = skymaxs[1][i] = -9999;
	}
}


void
MakeSkyVec (float s, float t, int axis)
{
	vec3_t      v, b;
	int         j, k;

	b[0] = s * 2048;
	b[1] = t * 2048;
	b[2] = 2048;

	for (j = 0; j < 3; j++) {
		k = st_to_vec[axis][j];
		if (k < 0)
			v[j] = -b[-k - 1];
		else
			v[j] = b[k - 1];
		v[j] += r_origin[j];
	}

	// avoid bilerp seam
	s = (s + 1) * 0.5;
	t = (t + 1) * 0.5;

	if (s < 1.0 / 512)
		s = 1.0 / 512;
	else if (s > 511.0 / 512)
		s = 511.0 / 512;
	if (t < 1.0 / 512)
		t = 1.0 / 512;
	else if (t > 511.0 / 512)
		t = 511.0 / 512;

	t = 1.0 - t;
	qglTexCoord2f (s, t);
	qglVertex3fv (v);
}

/*
==============
R_DrawSkyBox
==============
*/
int         skytexorder[6] = { 0, 2, 1, 3, 4, 5 };
void
R_DrawSkyBox (void)
{
	int         i, j, k;
	vec3_t      v;
	float       s, t;

#if 0
	qglEnable (GL_BLEND);
	qglTexEnvf (GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
	qglColor4f (1, 1, 1, 0.5);
	qglDisable (GL_DEPTH_TEST);
#endif
	for (i = 0; i < 6; i++) {
		if (skymins[0][i] >= skymaxs[0][i]
			|| skymins[1][i] >= skymaxs[1][i])
			continue;

		qglBindTexture (GL_TEXTURE_2D, SKY_TEX + skytexorder[i]);
#if 0
		skymins[0][i] = -1;
		skymins[1][i] = -1;
		skymaxs[0][i] = 1;
		skymaxs[1][i] = 1;
#endif
		qglBegin (GL_QUADS);
		MakeSkyVec (skymins[0][i], skymins[1][i], i);
		MakeSkyVec (skymins[0][i], skymaxs[1][i], i);
		MakeSkyVec (skymaxs[0][i], skymaxs[1][i], i);
		MakeSkyVec (skymaxs[0][i], skymins[1][i], i);
		qglEnd ();
	}
#if 0
	qglDisable (GL_BLEND);
	qglColor4f (1, 1, 1, 0.5);
	qglEnable (GL_DEPTH_TEST);
#endif
}


#endif

//===============================================================

/*
=============
R_InitSky

A sky texture is 256*128, with the right side being a masked overlay
==============
*/
void
R_InitSky (texture_t *mt)
{
	int         i, j, p;
	byte       *src;
	unsigned    trans[128 * 128];
	unsigned    transpix;
	int         r, g, b;
	unsigned   *rgba;

	src = (byte *) mt + mt->offsets[0];

	// make an average value for the back to avoid
	// a fringe on the top level

	r = g = b = 0;
	for (i = 0; i < 128; i++)
		for (j = 0; j < 128; j++) {
			p = src[i * 256 + j + 128];
			rgba = &d_8to24table[p];
			trans[(i * 128) + j] = *rgba;
			r += ((byte *) rgba)[0];
			g += ((byte *) rgba)[1];
			b += ((byte *) rgba)[2];
		}

	((byte *) & transpix)[0] = r / (128 * 128);
	((byte *) & transpix)[1] = g / (128 * 128);
	((byte *) & transpix)[2] = b / (128 * 128);
	((byte *) & transpix)[3] = 0;


	if (!solidskytexture)
		solidskytexture = texture_extension_number++;
	qglBindTexture (GL_TEXTURE_2D, solidskytexture);
	qglTexImage2D (GL_TEXTURE_2D, 0, gl_solid_format, 128, 128, 0, GL_RGBA,
				  GL_UNSIGNED_BYTE, trans);
	qglTexParameterf (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	qglTexParameterf (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);


	for (i = 0; i < 128; i++)
		for (j = 0; j < 128; j++) {
			p = src[i * 256 + j];
			if (p == 0)
				trans[(i * 128) + j] = transpix;
			else
				trans[(i * 128) + j] = d_8to24table[p];
		}

	if (!alphaskytexture)
		alphaskytexture = texture_extension_number++;
	qglBindTexture (GL_TEXTURE_2D, alphaskytexture);
	qglTexImage2D (GL_TEXTURE_2D, 0, gl_alpha_format, 128, 128, 0, GL_RGBA,
				  GL_UNSIGNED_BYTE, trans);
	qglTexParameterf (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	qglTexParameterf (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
}
