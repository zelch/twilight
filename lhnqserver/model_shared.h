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

#ifndef __MODEL__
#define __MODEL__

/*

d*_t structures are on-disk representations
m*_t structures are in-memory

*/

typedef enum {mod_brush, mod_sprite, mod_alias} modtype_t;

#include "model_brush.h"

typedef struct model_s
{
	char		name[MAX_QPATH];
	qboolean	needload;		// bmodels and sprites don't cache normally

	modtype_t	type;
	int			flags;
	int			numframes;
	
// volume occupied by the model graphics
	vec3_t		mins, maxs;
	float		radius;

// solid volume for clipping 
	qboolean	clipbox;
	vec3_t		clipmins, clipmaxs;

// brush model
	int			firstmodelsurface, nummodelsurfaces;

	int			numsubmodels;
	dmodel_t	*submodels;

	int			numplanes;
	mplane_t	*planes;

	int			numleafs;		// number of visible leafs, not counting 0
	mleaf_t		*leafs;

	int			numvertexes;
	mvertex_t	*vertexes;

//	int			numedges;
//	medge_t		*edges;

	int			numnodes;
	mnode_t		*nodes;

	int			numtexinfo;
	mtexinfo_t	*texinfo;

	int			numsurfaces;
	msurface_t	*surfaces;

//	int			numsurfedges;
//	int			*surfedges;

	int			numclipnodes;
	dclipnode_t	*clipnodes;

	hull_t		hulls[MAX_MAP_HULLS];

//	int			numtextures;
//	texture_t	**textures;

	byte		*visdata;
	byte		*lightdata;
	char		*entities;
} model_t;

//============================================================================

void	Mod_Init (void);
void	Mod_ClearAll (void);
model_t *Mod_ForName (char *name, qboolean crash);

mleaf_t *Mod_PointInLeaf (float *p, model_t *model);
byte	*Mod_LeafPVS (mleaf_t *leaf, model_t *model);

extern model_t	*loadmodel;
extern char	loadname[32];	// for hunk tags

extern model_t *Mod_LoadModel (model_t *mod, qboolean crash);

extern float RadiusFromBounds (vec3_t mins, vec3_t maxs);
extern model_t *Mod_FindName (char *name);
#endif	// __MODEL__
