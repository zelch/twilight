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

/*
==============================================================================

BRUSH MODELS

==============================================================================
*/


//
// in memory representation
//
// !!! if this is changed, it must be changed in asm_draw.h too !!!
typedef struct
{
	vec3_t		position;
} mvertex_t;

#define	SIDE_FRONT	0
#define	SIDE_BACK	1
#define	SIDE_ON		2


// plane_t structure
typedef struct mplane_s
{
	vec3_t	normal;
	float	dist;
	byte	type;			// for texture axis selection and fast side tests
	byte	pad[3];
	int (*BoxOnPlaneSideFunc) (vec3_t emins, vec3_t emaxs, struct mplane_s *p);
} mplane_t;

/*
typedef struct texture_s
{
	char		name[16];
	unsigned	width, height;
	int			gl_texturenum;
	int			gl_glowtexturenum; // LordHavoc: fullbrights on walls
	struct msurface_s	*texturechain;	// for gl_texsort drawing
	int			anim_total;				// total tenths in sequence ( 0 = no)
	int			anim_min, anim_max;		// time for this frame min <=time< max
	struct texture_s *anim_next;		// in the animation sequence
	struct texture_s *alternate_anims;	// bmodels in frame 1 use these
	unsigned	offsets[MIPLEVELS];		// four mip maps stored
	int			transparent;	// LordHavoc: transparent texture support
} texture_t;
*/


#define	SURF_PLANEBACK		2

typedef struct
{
	unsigned short	v[2];
} medge_t;

typedef struct
{
	float		vecs[2][4];
	int			flags;
} mtexinfo_t;

typedef struct msurface_s
{
	mplane_t	*plane;
	int			flags;

//	int			firstedge;	// look up in model->surfedges[], negative numbers
//	int			numedges;	// are backwards edges
	
	short		texturemins[2];
	short		extents[2];

	mtexinfo_t	*texinfo;

	byte		styles[MAXLIGHTMAPS];
	byte		*samples;		// [numstyles*surfsize]
} msurface_t;

// warning: if this is changed, references must be updated in cpu_* assembly files
typedef struct mnode_s
{
// common with leaf
	int			contents;		// 0, to differentiate from leafs
	
//	float		minmaxs[6];		// for bounding box culling

	struct mnode_s	*parent;

// node specific
	mplane_t	*plane;
	struct mnode_s	*children[2];	

	unsigned short		firstsurface;
	unsigned short		numsurfaces;
} mnode_t;



typedef struct mleaf_s
{
// common with node
	int			contents;		// wil be a negative contents number

//	float		minmaxs[6];		// for bounding box culling

	struct mnode_s	*parent;

// leaf specific
	byte		*compressed_vis;
} mleaf_t;

typedef struct
{
	dclipnode_t	*clipnodes;
	mplane_t	*planes;
	int			firstclipnode;
	int			lastclipnode;
	vec3_t		clip_mins;
	vec3_t		clip_maxs;
} hull_t;
