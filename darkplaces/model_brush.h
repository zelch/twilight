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

#ifndef MODEL_BRUSH_H
#define MODEL_BRUSH_H

/*
==============================================================================

BRUSH MODELS

==============================================================================
*/


//
// in memory representation
//
typedef struct
{
	vec3_t position;
}
mvertex_t;

#define SIDE_FRONT 0
#define SIDE_BACK 1
#define SIDE_ON 2


// plane_t structure
typedef struct mplane_s
{
	vec3_t normal;
	float dist;
	// for texture axis selection and fast side tests
	int type;
	int signbits;
}
mplane_t;

#define SHADERSTAGE_SKY 0
#define SHADERSTAGE_NORMAL 1
#define SHADERSTAGE_COUNT 2

#define SHADERFLAGS_NEEDLIGHTMAP 1

#define SURF_PLANEBACK 2
#define SURF_DRAWSKY 4
#define SURF_DRAWTURB 0x10
#define SURF_LIGHTMAP 0x20
#define SURF_DRAWNOALPHA 0x100
#define SURF_DRAWFULLBRIGHT 0x200
#define SURF_LIGHTBOTHSIDES 0x400
#define SURF_SHADOWCAST 0x1000 // this polygon can cast stencil shadows
#define SURF_SHADOWLIGHT 0x2000 // this polygon can be lit by stencil shadowing
#define SURF_WATERALPHA 0x4000 // this polygon's alpha is modulated by r_wateralpha
#define SURF_SOLIDCLIP 0x8000 // this polygon blocks movement

#define SURFRENDER_OPAQUE 0
#define SURFRENDER_ALPHA 1
#define SURFRENDER_ADD 2

struct entity_render_s;
struct texture_s;
struct msurface_s;
// change this stuff when real shaders are added
typedef struct Cshader_s
{
	void (*shaderfunc[SHADERSTAGE_COUNT])(const struct entity_render_s *ent, const struct texture_s *texture, struct msurface_s **surfchain);
	int flags;
}
Cshader_t;

extern Cshader_t Cshader_wall_lightmap;
extern Cshader_t Cshader_water;
extern Cshader_t Cshader_sky;

typedef struct texture_s
{
	// name
	char name[16];
	// size
	unsigned int width, height;
	// SURF_ flags
	unsigned int flags;

	// position in the model's textures array
	int number;

	// type of rendering (SURFRENDER_ value)
	int rendertype;

	// loaded the same as model skins
	skinframe_t skin;

	// shader to use for this texture
	Cshader_t *shader;

	// total frames in sequence and alternate sequence
	int anim_total[2];
	// direct pointers to each of the frames in the sequences
	// (indexed as [alternate][frame])
	struct texture_s *anim_frames[2][10];
	// set if animated or there is an alternate frame set
	// (this is an optimization in the renderer)
	int animated;
	// the current texture frame in animation
	struct texture_s *currentframe;
	// current alpha of the texture
	float currentalpha;
}
texture_t;

typedef struct
{
	unsigned short v[2];
}
medge_t;

typedef struct
{
	float vecs[2][4];
	texture_t *texture;
	int flags;
}
mtexinfo_t;

// LordHavoc: replaces glpoly, triangle mesh
typedef struct surfmesh_s
{
	// can be multiple meshs per surface
	struct surfmesh_s *chain;
	int numverts; // number of vertices in the mesh
	int numtriangles; // number of triangles in the mesh
	float *vertex3f; // float[verts*3] vertex locations
	float *svector3f; // float[verts*3] direction of 'S' (right) texture axis for each vertex
	float *tvector3f; // float[verts*3] direction of 'T' (down) texture axis for each vertex
	float *normal3f; // float[verts*3] direction of 'R' (out) texture axis for each vertex
	int *lightmapoffsets; // index into surface's lightmap samples for vertex lighting
	float *texcoordtexture2f; // float[verts*2] texcoords for surface texture
	float *texcoordlightmap2f; // float[verts*2] texcoords for lightmap texture
	float *texcoorddetail2f; // float[verts*2] texcoords for detail texture
	int *element3i; // int[tris*3] triangles of the mesh, 3 indices into vertex arrays for each
	int *neighbor3i; // int[tris*3] neighboring triangle on each edge (-1 if none)
}
surfmesh_t;

typedef struct msurface_s
{
	// bounding box for onscreen checks
	vec3_t poly_mins;
	vec3_t poly_maxs;

	// the node plane this is on, backwards if SURF_PLANEBACK flag set
	mplane_t *plane;
	// SURF_ flags
	int flags;
	// texture mapping properties used by this surface
	mtexinfo_t *texinfo;

	// the lightmap texture fragment to use on the rendering mesh
	rtexture_t *lightmaptexture;
	// mesh for rendering
	surfmesh_t *mesh;
	// if lightmap settings changed, this forces update
	int cached_dlight;

	// should be drawn if visframe == r_framecount (set by PrepareSurfaces)
	int visframe;
	// should be drawn if onscreen and not a backface (used for setting visframe)
	//int pvsframe;
	// chain of surfaces marked visible by pvs
	//struct msurface_s *pvschain;

	// surface number, to avoid having to do a divide to find the number of a surface from it's address
	int number;

	// center for sorting transparent meshes
	vec3_t poly_center;

	// index into d_lightstylevalue array, 255 means not used (black)
	qbyte styles[MAXLIGHTMAPS];
	// RGB lighting data [numstyles][height][width][3]
	qbyte *samples;
	// stain to apply on lightmap (soot/dirt/blood/whatever)
	qbyte *stainsamples;
	// the stride when building lightmaps to comply with fragment update
	int lightmaptexturestride;
	int texturemins[2];
	int extents[2];

	// if this == r_framecount there are dynamic lights on the surface
	int dlightframe;
	// which dynamic lights are touching this surface
	// (only access this if dlightframe is current)
	int dlightbits[8];
	// avoid redundent addition of dlights
	int lightframe;

	// avoid multiple collision traces with a surface polygon
	int colframe;

	// these are just 3D points defining the outline of the polygon,
	// no texcoord info (that can be generated from these)
	int poly_numverts;
	float *poly_verts;

	// neighboring surfaces (one per poly_numverts)
	//struct msurface_s **neighborsurfaces;
	// currently used only for generating static shadow volumes
	int castshadow;
}
msurface_t;

typedef struct mnode_s
{
// common with leaf
	// always 0 in nodes
	int contents;

	struct mnode_s *parent;
	struct mportal_s *portals;

	// for bounding box culling
	vec3_t mins;
	vec3_t maxs;

// node specific
	mplane_t *plane;
	struct mnode_s *children[2];

	unsigned short firstsurface;
	unsigned short numsurfaces;
}
mnode_t;

typedef struct mleaf_s
{
// common with node
	// always negative in leafs
	int contents;

	struct mnode_s *parent;
	struct mportal_s *portals;

	// for bounding box culling
	vec3_t mins;
	vec3_t maxs;

// leaf specific
	// next leaf in pvschain
	struct mleaf_s *pvschain;
	// potentially visible if current (model->pvsframecount)
	int pvsframe;
	// visible if marked current (r_framecount)
	int visframe;
	// used by certain worldnode variants to avoid processing the same leaf twice in a frame
	int worldnodeframe;
	// used by polygon-through-portals visibility checker
	int portalmarkid;

	qbyte *compressed_vis;

	int *firstmarksurface;
	int nummarksurfaces;
	qbyte ambient_sound_level[NUM_AMBIENTS];
}
mleaf_t;

typedef struct
{
	dclipnode_t *clipnodes;
	mplane_t *planes;
	int firstclipnode;
	int lastclipnode;
	vec3_t clip_mins;
	vec3_t clip_maxs;
	vec3_t clip_size;
}
hull_t;

typedef struct mportal_s
{
	struct mportal_s *next; // the next portal on this leaf
	mleaf_t *here; // the leaf this portal is on
	mleaf_t *past; // the leaf through this portal (infront)
	mvertex_t *points;
	int numpoints;
	mplane_t plane;
	int visframe; // is this portal visible this frame?
}
mportal_t;

typedef struct svbspmesh_s
{
	struct svbspmesh_s *next;
	int numverts, maxverts;
	int numtriangles, maxtriangles;
	float *verts;
	int *elements;
}
svbspmesh_t;

typedef struct mlight_s
{
	// location of light
	vec3_t origin;
	// distance attenuation scale (smaller is a larger light)
	float falloff;
	// color and brightness combined
	vec3_t light;
	// brightness bias, used for limiting radius without a hard edge
	float subtract;
	// spotlight direction
	vec3_t spotdir;
	// cosine of spotlight cone angle (or 0 if not a spotlight)
	float spotcone;
	// distance bias (larger value is softer and darker)
	float distbias;
	// light style controlling this light
	int style;
	// maximum extent of the light for shading purposes
	float lightradius;
	// maximum extent of the light for culling purposes
	float cullradius;
	float cullradius2;
	/*
	// surfaces this shines on
	int numsurfaces;
	msurface_t **surfaces;
	// lit area
	vec3_t mins, maxs;
	// precomputed shadow volume meshs
	//svbspmesh_t *shadowvolume;
	//vec3_t shadowvolumemins, shadowvolumemaxs;
	shadowmesh_t *shadowvolume;
	*/
}
mlight_t;

extern rtexture_t *r_notexture;
extern texture_t r_notexture_mip;

struct model_s;
void Mod_Q1BSP_Load(struct model_s *mod, void *buffer);
void Mod_IBSP_Load(struct model_s *mod, void *buffer);
void Mod_MAP_Load(struct model_s *mod, void *buffer);
void Mod_BrushInit(void);

// Q2 bsp stuff

#define Q2BSPVERSION	38

// leaffaces, leafbrushes, planes, and verts are still bounded by
// 16 bit short limits

//=============================================================================

#define	Q2LUMP_ENTITIES		0
#define	Q2LUMP_PLANES			1
#define	Q2LUMP_VERTEXES		2
#define	Q2LUMP_VISIBILITY		3
#define	Q2LUMP_NODES			4
#define	Q2LUMP_TEXINFO		5
#define	Q2LUMP_FACES			6
#define	Q2LUMP_LIGHTING		7
#define	Q2LUMP_LEAFS			8
#define	Q2LUMP_LEAFFACES		9
#define	Q2LUMP_LEAFBRUSHES	10
#define	Q2LUMP_EDGES			11
#define	Q2LUMP_SURFEDGES		12
#define	Q2LUMP_MODELS			13
#define	Q2LUMP_BRUSHES		14
#define	Q2LUMP_BRUSHSIDES		15
#define	Q2LUMP_POP			16
#define	Q2LUMP_AREAS			17
#define	Q2LUMP_AREAPORTALS	18
#define	Q2HEADER_LUMPS		19

typedef struct
{
	int			ident;
	int			version;
	lump_t		lumps[HEADER_LUMPS];
} q2dheader_t;

typedef struct
{
	float		mins[3], maxs[3];
	float		origin[3];		// for sounds or lights
	int			headnode;
	int			firstface, numfaces;	// submodels just draw faces
										// without walking the bsp tree
} q2dmodel_t;

// planes (x&~1) and (x&~1)+1 are always opposites

// contents flags are seperate bits
// a given brush can contribute multiple content bits
// multiple brushes can be in a single leaf

// these definitions also need to be in q_shared.h!

// lower bits are stronger, and will eat weaker brushes completely
#define	Q2CONTENTS_SOLID			1		// an eye is never valid in a solid
#define	Q2CONTENTS_WINDOW			2		// translucent, but not watery
#define	Q2CONTENTS_AUX			4
#define	Q2CONTENTS_LAVA			8
#define	Q2CONTENTS_SLIME			16
#define	Q2CONTENTS_WATER			32
#define	Q2CONTENTS_MIST			64
#define	Q2LAST_VISIBLE_CONTENTS	64

// remaining contents are non-visible, and don't eat brushes

#define	Q2CONTENTS_AREAPORTAL		0x8000

#define	Q2CONTENTS_PLAYERCLIP		0x10000
#define	Q2CONTENTS_MONSTERCLIP	0x20000

// currents can be added to any other contents, and may be mixed
#define	Q2CONTENTS_CURRENT_0		0x40000
#define	Q2CONTENTS_CURRENT_90		0x80000
#define	Q2CONTENTS_CURRENT_180	0x100000
#define	Q2CONTENTS_CURRENT_270	0x200000
#define	Q2CONTENTS_CURRENT_UP		0x400000
#define	Q2CONTENTS_CURRENT_DOWN	0x800000

#define	Q2CONTENTS_ORIGIN			0x1000000	// removed before bsping an entity

#define	Q2CONTENTS_MONSTER		0x2000000	// should never be on a brush, only in game
#define	Q2CONTENTS_DEADMONSTER	0x4000000
#define	Q2CONTENTS_DETAIL			0x8000000	// brushes to be added after vis leafs
#define	Q2CONTENTS_TRANSLUCENT	0x10000000	// auto set if any surface has trans
#define	Q2CONTENTS_LADDER			0x20000000



#define	Q2SURF_LIGHT		0x1		// value will hold the light strength

#define	Q2SURF_SLICK		0x2		// effects game physics

#define	Q2SURF_SKY		0x4		// don't draw, but add to skybox
#define	Q2SURF_WARP		0x8		// turbulent water warp
#define	Q2SURF_TRANS33	0x10
#define	Q2SURF_TRANS66	0x20
#define	Q2SURF_FLOWING	0x40	// scroll towards angle
#define	Q2SURF_NODRAW		0x80	// don't bother referencing the texture




typedef struct
{
	int			planenum;
	int			children[2];	// negative numbers are -(leafs+1), not nodes
	short		mins[3];		// for frustom culling
	short		maxs[3];
	unsigned short	firstface;
	unsigned short	numfaces;	// counting both sides
} q2dnode_t;


typedef struct
{
	float		vecs[2][4];		// [s/t][xyz offset]
	int			flags;			// miptex flags + overrides
	int			value;			// light emission, etc
	char		texture[32];	// texture name (textures/*.wal)
	int			nexttexinfo;	// for animations, -1 = end of chain
} q2texinfo_t;

typedef struct
{
	int				contents;			// OR of all brushes (not needed?)

	short			cluster;
	short			area;

	short			mins[3];			// for frustum culling
	short			maxs[3];

	unsigned short	firstleafface;
	unsigned short	numleaffaces;

	unsigned short	firstleafbrush;
	unsigned short	numleafbrushes;
} q2dleaf_t;

typedef struct
{
	unsigned short	planenum;		// facing out of the leaf
	short	texinfo;
} q2dbrushside_t;

typedef struct
{
	int			firstside;
	int			numsides;
	int			contents;
} q2dbrush_t;


// the visibility lump consists of a header with a count, then
// byte offsets for the PVS and PHS of each cluster, then the raw
// compressed bit vectors
#define	Q2DVIS_PVS	0
#define	Q2DVIS_PHS	1
typedef struct
{
	int			numclusters;
	int			bitofs[8][2];	// bitofs[numclusters][2]
} q2dvis_t;

// each area has a list of portals that lead into other areas
// when portals are closed, other areas may not be visible or
// hearable even if the vis info says that it should be
typedef struct
{
	int		portalnum;
	int		otherarea;
} q2dareaportal_t;

typedef struct
{
	int		numareaportals;
	int		firstareaportal;
} q2darea_t;

#endif

