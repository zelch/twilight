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

#ifndef SYNCTYPE_T
#define SYNCTYPE_T
typedef enum {ST_SYNC=0, ST_RAND } synctype_t;
#endif

/*

d*_t structures are on-disk representations
m*_t structures are in-memory

*/

typedef enum {mod_invalid, mod_brush, mod_sprite, mod_alias} modtype_t;

typedef struct animscene_s
{
	char name[32]; // for viewthing support
	int firstframe;
	int framecount;
	int loop; // true or false
	float framerate;
}
animscene_t;

typedef struct skinframe_s
{
	rtexture_t *base; // original texture minus pants/shirt/glow
	rtexture_t *pants; // pants only (in greyscale)
	rtexture_t *shirt; // shirt only (in greyscale)
	rtexture_t *glow; // glow only
	rtexture_t *merged; // original texture minus glow
	rtexture_t *fog; // white texture with alpha of the base texture, NULL if not transparent
}
skinframe_t;

#define MAX_SKINS 256


#include "model_brush.h"
#include "model_sprite.h"
#include "model_alias.h"

typedef struct model_s
{
	char			name[MAX_QPATH];
	// model needs to be loaded if this is true
	qboolean		needload;
	// set if the model is used in current map, models which are not, are purged
	qboolean		used;
	// CRC of the file this model was loaded from, to reload if changed
	qboolean		crc;
	// true if this is the world model (I.E. defines what sky to use, and may contain submodels)
	qboolean		isworldmodel;
	// true if this model is a HalfLife .bsp file
	qboolean		ishlbsp;

	// mod_brush, mod_alias, mod_sprite
	modtype_t		type;
	// LordHavoc: Q2/ZYM model support
	int				aliastype;
	// LordHavoc: if true (normally only for sprites) the model/sprite/bmodel is always rendered fullbright
	int				fullbright;
	// number of QC accessable frame(group)s in the model
	int				numframes;
	// whether to randomize animated framegroups
	synctype_t		synctype;

	// used for sprites and models
	int				numtris;
	// used for models
	int				numskins;
	// used by models
	int				numverts;

	// flags from the model file
	int				flags;
	// engine calculated flags, ones that can not be set in the file
	int				flags2;

	// all models use textures...
	rtexturepool_t	*texturepool;

	// volume occupied by the model
	// bounding box at angles '0 0 0'
	vec3_t			normalmins, normalmaxs;
	// bounding box if yaw angle is not 0, but pitch and roll are
	vec3_t			yawmins, yawmaxs;
	// bounding box if pitch or roll are used
	vec3_t			rotatedmins, rotatedmaxs;
	// usable at any angles
//	float			modelradius;

	// brush model specific
	int				firstmodelsurface, nummodelsurfaces;
	// LordHavoc: sorted surface pointer array, sorted by shader type and then by texture
	msurface_t		**modelsortedsurfaces; // [nummodelsurfaces]

	// used for surfaces without a valid texture
	texture_t		notexture;

	// lightmap format, set to r_lightmaprgba when model is loaded
	int				lightmaprgba;

	int				numsubmodels;
	dmodel_t		*submodels;

	int				numplanes;
	mplane_t		*planes;

	// number of visible leafs, not counting 0 (solid)
	int				numleafs;
	mleaf_t			*leafs;

	int				numvertexes;
	mvertex_t		*vertexes;

	int				numedges;
	medge_t			*edges;

	int				numnodes;
	mnode_t			*nodes;

	int				numtexinfo;
	mtexinfo_t		*texinfo;

	int				numsurfaces;
	msurface_t		*surfaces;

	int				numsurfedges;
	int				*surfedges;

	int				numclipnodes;
	dclipnode_t		*clipnodes;

	int				nummarksurfaces;
	msurface_t		**marksurfaces;

	hull_t			hulls[MAX_MAP_HULLS];

	int				numtextures;
	texture_t		**textures;

	byte			*visdata;
	byte			*lightdata;
	char			*entities;

	int				numportals;
	mportal_t		*portals;

	int				numportalpoints;
	mvertex_t		*portalpoints;

	// skin animation info
	animscene_t		*skinscenes; // [numskins]
	// skin frame info
	skinframe_t		*skinframes;

	animscene_t		*animscenes; // [numframes]

	// Q2 model information
//	md2triangle_t	*md2data_tris;
	// FIXME: redesign to use triangle mesh
	int				*md2data_glcmds;

	float			*mdldata_texcoords;
	int				*mdldata_indices;

	md2frame_t		*mdlmd2data_frames;
	trivertx_t		*mdlmd2data_pose;

	// for Zymotic models
	void			*zymdata_header;

	int				sprnum_type;
	mspriteframe_t	*sprdata_frames;

	// adds a box (or individual polygons) to the clipping engine,
	// which will mark the entity visible if seen
	void(*SERAddEntity)(void);
	// draw the model
	void(*Draw)(void);
	// draw the model's sky polygons (only used by brush models)
	void(*DrawSky)(void);
	// draw the model's shadows
	void(*DrawShadow)(void);

	// memory pool for allocations
	mempool_t		*mempool;
}
model_t;

//============================================================================

// model loading
extern model_t *loadmodel;
extern byte	*mod_base;
// sky/water subdivision
extern cvar_t gl_subdivide_size;
// texture fullbrights
extern cvar_t r_fullbrights;

void Mod_Init (void);
void Mod_CheckLoaded (model_t *mod);
void Mod_ClearAll (void);
model_t *Mod_ForName (char *name, qboolean crash, qboolean checkdisk, qboolean isworldmodel);
void Mod_TouchModel (char *name);
void Mod_UnloadModel (model_t *mod);

mleaf_t *Mod_PointInLeaf (float *p, model_t *model);
byte *Mod_LeafPVS (mleaf_t *leaf, model_t *model);

void Mod_ClearUsed(void);
void Mod_PurgeUnused(void);

extern model_t *loadmodel;
extern char loadname[32];	// for hunk tags

//extern model_t *Mod_LoadModel (model_t *mod, qboolean crash);

//extern float RadiusFromBounds (vec3_t mins, vec3_t maxs);
extern model_t *Mod_FindName (char *name);

#endif	// __MODEL__
