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

#include "quakedef.h"

byte	mod_novis[MAX_MAP_LEAFS/8];

int *surfedges;
medge_t *edges;

/*
===============
Mod_BrushInit
===============
*/
void Mod_BrushInit (void)
{
	memset (mod_novis, 0xff, sizeof(mod_novis));
}

// Mod_PointInLeaf moved to cpu_noasm.c

/*
===================
Mod_DecompressVis
===================
*/
byte *Mod_DecompressVis (byte *in, model_t *model)
{
	static byte	decompressed[MAX_MAP_LEAFS/8];
	int		c;
	byte	*out;
	int		row;

	row = (model->numleafs+7)>>3;	
	out = decompressed;

	if (!in)
	{	// no vis info, so make all visible
		while (row)
		{
			*out++ = 0xff;
			row--;
		}
		return decompressed;		
	}

	do
	{
		if (*in)
		{
			*out++ = *in++;
			continue;
		}
	
		c = in[1];
		in += 2;
		while (c)
		{
			*out++ = 0;
			c--;
		}
	} while (out - decompressed < row);
	
	return decompressed;
}

byte *Mod_LeafPVS (mleaf_t *leaf, model_t *model)
{
	if (leaf == model->leafs)
		return mod_novis;
	return Mod_DecompressVis (leaf->compressed_vis, model);
}

extern byte	*mod_base;

extern cvar_t r_fullbrights;

/*
=================
Mod_LoadLighting
=================
*/
void Mod_LoadLighting (lump_t *l)
{
	loadmodel->lightdata = NULL;
	if (!l->filelen)
		return;
	loadmodel->lightdata = Hunk_AllocName ( l->filelen, va("%s lightmaps", loadname));
	memcpy (loadmodel->lightdata, mod_base + l->fileofs, l->filelen);
}


/*
=================
Mod_LoadVisibility
=================
*/
void Mod_LoadVisibility (lump_t *l)
{
	if (!l->filelen)
	{
		loadmodel->visdata = NULL;
		return;
	}
	loadmodel->visdata = Hunk_AllocName ( l->filelen, va("%s visdata", loadname));
	memcpy (loadmodel->visdata, mod_base + l->fileofs, l->filelen);
}

extern qboolean isworldmodel;

/*
=================
Mod_LoadEntities
=================
*/
void Mod_LoadEntities (lump_t *l)
{
	if (!l->filelen)
	{
		loadmodel->entities = NULL;
		return;
	}
	loadmodel->entities = Hunk_AllocName ( l->filelen, va("%s entities", loadname));
	memcpy (loadmodel->entities, mod_base + l->fileofs, l->filelen);
}


/*
=================
Mod_LoadVertexes
=================
*/
void Mod_LoadVertexes (lump_t *l)
{
	dvertex_t	*in;
	mvertex_t	*out;
	int			i, count;

	in = (void *)(mod_base + l->fileofs);
	if (l->filelen % sizeof(*in))
		Host_Error ("MOD_LoadBmodel: funny lump size in %s",loadmodel->name);
	count = l->filelen / sizeof(*in);
	out = Hunk_AllocName ( count*sizeof(*out), va("%s vertices", loadname));

	loadmodel->vertexes = out;
	loadmodel->numvertexes = count;

	for ( i=0 ; i<count ; i++, in++, out++)
	{
		out->position[0] = LittleFloat (in->point[0]);
		out->position[1] = LittleFloat (in->point[1]);
		out->position[2] = LittleFloat (in->point[2]);
	}
}

/*
=================
Mod_LoadSubmodels
=================
*/
void Mod_LoadSubmodels (lump_t *l)
{
	dmodel_t	*in;
	dmodel_t	*out;
	int			i, j, count;

	in = (void *)(mod_base + l->fileofs);
	if (l->filelen % sizeof(*in))
		Host_Error ("MOD_LoadBmodel: funny lump size in %s",loadmodel->name);
	count = l->filelen / sizeof(*in);
	out = Hunk_AllocName ( count*sizeof(*out), va("%s submodels", loadname));

	loadmodel->submodels = out;
	loadmodel->numsubmodels = count;

	for ( i=0 ; i<count ; i++, in++, out++)
	{
		for (j=0 ; j<3 ; j++)
		{	// spread the mins / maxs by a pixel
			out->mins[j] = LittleFloat (in->mins[j]) - 1;
			out->maxs[j] = LittleFloat (in->maxs[j]) + 1;
			out->origin[j] = LittleFloat (in->origin[j]);
		}
		for (j=0 ; j<MAX_MAP_HULLS ; j++)
			out->headnode[j] = LittleLong (in->headnode[j]);
		out->visleafs = LittleLong (in->visleafs);
		out->firstface = LittleLong (in->firstface);
		out->numfaces = LittleLong (in->numfaces);
	}
}

/*
=================
Mod_LoadEdges
=================
*/
void Mod_LoadEdges (lump_t *l)
{
	dedge_t *in;
	medge_t *out;
	int 	i, count;

	in = (void *)(mod_base + l->fileofs);
	if (l->filelen % sizeof(*in))
		Host_Error ("MOD_LoadBmodel: funny lump size in %s",loadmodel->name);
	count = l->filelen / sizeof(*in);
//	out = Hunk_AllocName ( (count + 1) * sizeof(*out), va("%s edges", loadname));
	out = edges = qmalloc((count + 1) * sizeof(*out));

//	loadmodel->edges = out;
//	loadmodel->numedges = count;

	for ( i=0 ; i<count ; i++, in++, out++)
	{
		out->v[0] = (unsigned short)LittleShort(in->v[0]);
		out->v[1] = (unsigned short)LittleShort(in->v[1]);
	}
}

/*
=================
Mod_LoadTexinfo
=================
*/
void Mod_LoadTexinfo (lump_t *l)
{
	texinfo_t *in;
	mtexinfo_t *out;
	int 	i, j, k, count;

	in = (void *)(mod_base + l->fileofs);
	if (l->filelen % sizeof(*in))
		Host_Error ("MOD_LoadBmodel: funny lump size in %s",loadmodel->name);
	count = l->filelen / sizeof(*in);
	out = Hunk_AllocName ( count*sizeof(*out), va("%s texinfo", loadname));

	loadmodel->texinfo = out;
	loadmodel->numtexinfo = count;

	for ( i=0 ; i<count ; i++, in++, out++)
	{
		for (k=0 ; k<2 ; k++)
			for (j=0 ; j<4 ; j++)
				out->vecs[k][j] = LittleFloat (in->vecs[k][j]);
		out->flags = LittleLong (in->flags);
	}
}

/*
================
CalcSurfaceExtents

Fills in s->texturemins[] and s->extents[]
================
*/
void CalcSurfaceExtents (msurface_t *s, int firstedge, int numedges)
{
	float	mins[2], maxs[2], val;
	int		i,j, e;
	mvertex_t	*v;
	mtexinfo_t	*tex;
	int		bmins[2], bmaxs[2];

	mins[0] = mins[1] = 999999;
	maxs[0] = maxs[1] = -99999;

	tex = s->texinfo;
	
	for (i=0 ; i<numedges ; i++)
	{
//		e = loadmodel->surfedges[firstedge+i];
		e = surfedges[firstedge+i];
		if (e >= 0)
			v = &loadmodel->vertexes[edges[e].v[0]];
		else
			v = &loadmodel->vertexes[edges[-e].v[1]];
		
		for (j=0 ; j<2 ; j++)
		{
			val = v->position[0] * tex->vecs[j][0] + 
				v->position[1] * tex->vecs[j][1] +
				v->position[2] * tex->vecs[j][2] +
				tex->vecs[j][3];
			if (val < mins[j])
				mins[j] = val;
			if (val > maxs[j])
				maxs[j] = val;
		}
	}

	for (i=0 ; i<2 ; i++)
	{	
		bmins[i] = floor(mins[i]/16);
		bmaxs[i] = ceil(maxs[i]/16);

		s->texturemins[i] = bmins[i] * 16;
		s->extents[i] = (bmaxs[i] - bmins[i]) * 16;
		if ( !(tex->flags & TEX_SPECIAL) && s->extents[i] > 512 /* 256 */ )
			Host_Error ("Bad surface extents");
	}
}

extern char skyname[];

/*
=================
Mod_LoadFaces
=================
*/
void Mod_LoadFaces (lump_t *l)
{
	dface_t		*in;
	msurface_t 	*out;
	int			i, count, surfnum;
	int			planenum, side;
	int			firstedge, numedges;

	in = (void *)(mod_base + l->fileofs);
	if (l->filelen % sizeof(*in))
		Host_Error ("MOD_LoadBmodel: funny lump size in %s",loadmodel->name);
	count = l->filelen / sizeof(*in);
	out = Hunk_AllocName ( count*sizeof(*out), va("%s faces", loadname));

	loadmodel->surfaces = out;
	loadmodel->numsurfaces = count;

	for ( surfnum=0 ; surfnum<count ; surfnum++, in++, out++)
	{
//		out->firstedge = LittleLong(in->firstedge);
//		out->numedges = LittleShort(in->numedges);		
		firstedge = LittleLong(in->firstedge);
		numedges = LittleShort(in->numedges);		
		out->flags = 0;

		planenum = LittleShort(in->planenum);
		side = LittleShort(in->side);
		if (side)
			out->flags |= SURF_PLANEBACK;			

		out->plane = loadmodel->planes + planenum;

		out->texinfo = loadmodel->texinfo + LittleShort (in->texinfo);

		CalcSurfaceExtents (out, firstedge, numedges);
				
	// lighting info

		for (i=0 ; i<MAXLIGHTMAPS ; i++)
			out->styles[i] = in->styles[i];
		i = LittleLong(in->lightofs);
		if (i == -1)
			out->samples = NULL;
		else
			out->samples = loadmodel->lightdata + i;
	}
}


/*
=================
Mod_SetParent
=================
*/
void Mod_SetParent (mnode_t *node, mnode_t *parent)
{
	node->parent = parent;
	if (node->contents < 0)
		return;
	Mod_SetParent (node->children[0], node);
	Mod_SetParent (node->children[1], node);
}

/*
=================
Mod_LoadNodes
=================
*/
void Mod_LoadNodes (lump_t *l)
{
	int			i, j, count, p;
	dnode_t		*in;
	mnode_t 	*out;

	in = (void *)(mod_base + l->fileofs);
	if (l->filelen % sizeof(*in))
		Host_Error ("MOD_LoadBmodel: funny lump size in %s",loadmodel->name);
	count = l->filelen / sizeof(*in);
	out = Hunk_AllocName ( count*sizeof(*out), va("%s nodes", loadname));

	loadmodel->nodes = out;
	loadmodel->numnodes = count;

	for ( i=0 ; i<count ; i++, in++, out++)
	{
//		for (j=0 ; j<3 ; j++)
//		{
//			out->minmaxs[j] = LittleShort (in->mins[j]);
//			out->minmaxs[3+j] = LittleShort (in->maxs[j]);
//		}
	
		p = LittleLong(in->planenum);
		out->plane = loadmodel->planes + p;

		out->firstsurface = LittleShort (in->firstface);
		out->numsurfaces = LittleShort (in->numfaces);
		
		for (j=0 ; j<2 ; j++)
		{
			p = LittleShort (in->children[j]);
			if (p >= 0)
				out->children[j] = loadmodel->nodes + p;
			else
				out->children[j] = (mnode_t *)(loadmodel->leafs + (-1 - p));
		}
	}
	
	Mod_SetParent (loadmodel->nodes, NULL);	// sets nodes and leafs
}

/*
=================
Mod_LoadLeafs
=================
*/
void Mod_LoadLeafs (lump_t *l)
{
	dleaf_t 	*in;
	mleaf_t 	*out;
	int			i;
//	int			j;
	int			count;
	int			p;

	in = (void *)(mod_base + l->fileofs);
	if (l->filelen % sizeof(*in))
		Host_Error ("MOD_LoadBmodel: funny lump size in %s",loadmodel->name);
	count = l->filelen / sizeof(*in);
	out = Hunk_AllocName ( count*sizeof(*out), va("%s leafs", loadname));

	loadmodel->leafs = out;
	loadmodel->numleafs = count;

	for ( i=0 ; i<count ; i++, in++, out++)
	{
//		for (j=0 ; j<3 ; j++)
//		{
//			out->minmaxs[j] = LittleShort (in->mins[j]);
//			out->minmaxs[3+j] = LittleShort (in->maxs[j]);
//		}

		p = LittleLong(in->contents);
		out->contents = p;

		p = LittleLong(in->visofs);
		if (p == -1)
			out->compressed_vis = NULL;
		else
			out->compressed_vis = loadmodel->visdata + p;
	}	
}

/*
=================
Mod_LoadClipnodes
=================
*/
void Mod_LoadClipnodes (lump_t *l)
{
	dclipnode_t *in, *out;
	int			i, count;
	hull_t		*hull;

	in = (void *)(mod_base + l->fileofs);
	if (l->filelen % sizeof(*in))
		Host_Error ("MOD_LoadBmodel: funny lump size in %s",loadmodel->name);
	count = l->filelen / sizeof(*in);
	out = Hunk_AllocName ( count*sizeof(*out), va("%s clipnodes", loadname));

	loadmodel->clipnodes = out;
	loadmodel->numclipnodes = count;

	hull = &loadmodel->hulls[1];
	hull->clipnodes = out;
	hull->firstclipnode = 0;
	hull->lastclipnode = count-1;
	hull->planes = loadmodel->planes;
	hull->clip_mins[0] = -16;
	hull->clip_mins[1] = -16;
	hull->clip_mins[2] = -24;
	hull->clip_maxs[0] = 16;
	hull->clip_maxs[1] = 16;
	hull->clip_maxs[2] = 32;

	hull = &loadmodel->hulls[2];
	hull->clipnodes = out;
	hull->firstclipnode = 0;
	hull->lastclipnode = count-1;
	hull->planes = loadmodel->planes;
	hull->clip_mins[0] = -32;
	hull->clip_mins[1] = -32;
	hull->clip_mins[2] = -24;
	hull->clip_maxs[0] = 32;
	hull->clip_maxs[1] = 32;
	hull->clip_maxs[2] = 64;

	for (i=0 ; i<count ; i++, out++, in++)
	{
		out->planenum = LittleLong(in->planenum);
		out->children[0] = LittleShort(in->children[0]);
		out->children[1] = LittleShort(in->children[1]);
		if (out->children[0] >= count || out->children[1] >= count)
			Host_Error("Corrupt clipping hull (out of range child)\n");
	}
}

/*
=================
Mod_MakeHull0

Duplicate the drawing hull structure as a clipping hull
=================
*/
void Mod_MakeHull0 (void)
{
	mnode_t		*in, *child;
	dclipnode_t *out;
	int			i, j, count;
	hull_t		*hull;
	
	hull = &loadmodel->hulls[0];	
	
	in = loadmodel->nodes;
	count = loadmodel->numnodes;
	out = Hunk_AllocName ( count*sizeof(*out), va("%s hull0", loadname));

	hull->clipnodes = out;
	hull->firstclipnode = 0;
	hull->lastclipnode = count-1;
	hull->planes = loadmodel->planes;

	for (i=0 ; i<count ; i++, out++, in++)
	{
		out->planenum = in->plane - loadmodel->planes;
		for (j=0 ; j<2 ; j++)
		{
			child = in->children[j];
			if (child->contents < 0)
				out->children[j] = child->contents;
			else
				out->children[j] = child - loadmodel->nodes;
		}
	}
}

/*
=================
Mod_LoadSurfedges
=================
*/
void Mod_LoadSurfedges (lump_t *l)
{	
	int		i, count;
	int		*in, *out;
	
	in = (void *)(mod_base + l->fileofs);
	if (l->filelen % sizeof(*in))
		Host_Error ("MOD_LoadBmodel: funny lump size in %s",loadmodel->name);
	count = l->filelen / sizeof(*in);
//	out = Hunk_AllocName ( count*sizeof(*out), va("%s surfedges", loadname));
	out = surfedges = qmalloc(count*sizeof(*out));

//	loadmodel->surfedges = out;
//	loadmodel->numsurfedges = count;

	for ( i=0 ; i<count ; i++)
		out[i] = LittleLong (in[i]);
}


/*
=================
Mod_LoadPlanes
=================
*/
void Mod_LoadPlanes (lump_t *l)
{
	int			i, j;
	mplane_t	*out;
	dplane_t 	*in;
	int			count;
	int			bits;
	
	in = (void *)(mod_base + l->fileofs);
	if (l->filelen % sizeof(*in))
		Host_Error ("MOD_LoadBmodel: funny lump size in %s",loadmodel->name);
	count = l->filelen / sizeof(*in);
	out = Hunk_AllocName ( count*2*sizeof(*out), va("%s planes", loadname));

	loadmodel->planes = out;
	loadmodel->numplanes = count;

	for ( i=0 ; i<count ; i++, in++, out++)
	{
		bits = 0;
		for (j=0 ; j<3 ; j++)
		{
			out->normal[j] = LittleFloat (in->normal[j]);
//			if (out->normal[j] < 0)
//				bits |= 1<<j;
		}

		out->dist = LittleFloat (in->dist);
		out->type = LittleLong (in->type);
//		out->signbits = bits;
		BoxOnPlaneSideClassify(out);
	}
}

/*
=================
Mod_LoadBrushModel
=================
*/
void Mod_LoadBrushModel (model_t *mod, void *buffer)
{
	int			i, j;
	dheader_t	*header;
	dmodel_t 	*bm;
	
	loadmodel->type = mod_brush;
	
	header = (dheader_t *)buffer;

	i = LittleLong (header->version);
	if (i != BSPVERSION)
		Host_Error ("Mod_LoadBrushModel: %s has wrong version number (%i should be %i)", mod->name, i, BSPVERSION);

// swap all the lumps
	mod_base = (byte *)header;

	for (i=0 ; i<sizeof(dheader_t)/4 ; i++)
		((int *)header)[i] = LittleLong ( ((int *)header)[i]);

// load into heap
	
	// LordHavoc: had to move entity loading above everything to allow parsing various settings from worldspawn
	Mod_LoadEntities (&header->lumps[LUMP_ENTITIES]);

	Mod_LoadVertexes (&header->lumps[LUMP_VERTEXES]);
	Mod_LoadEdges (&header->lumps[LUMP_EDGES]);
	Mod_LoadSurfedges (&header->lumps[LUMP_SURFEDGES]);
	Mod_LoadLighting (&header->lumps[LUMP_LIGHTING]);
	Mod_LoadPlanes (&header->lumps[LUMP_PLANES]);
	Mod_LoadTexinfo (&header->lumps[LUMP_TEXINFO]);
	Mod_LoadFaces (&header->lumps[LUMP_FACES]);
	qfree(surfedges);
	surfedges = NULL;
	qfree(edges);
	edges = NULL;
	Mod_LoadVisibility (&header->lumps[LUMP_VISIBILITY]);
	Mod_LoadLeafs (&header->lumps[LUMP_LEAFS]);
	Mod_LoadNodes (&header->lumps[LUMP_NODES]);
	Mod_LoadClipnodes (&header->lumps[LUMP_CLIPNODES]);
//	Mod_LoadEntities (&header->lumps[LUMP_ENTITIES]);
	Mod_LoadSubmodels (&header->lumps[LUMP_MODELS]);

	Mod_MakeHull0 ();
	
	mod->numframes = 2;		// regular and alternate animation
	
//
// set up the submodels (FIXME: this is confusing)
//
	for (i=0 ; i<mod->numsubmodels ; i++)
	{
		bm = &mod->submodels[i];

		mod->hulls[0].firstclipnode = bm->headnode[0];
		for (j=1 ; j<MAX_MAP_HULLS ; j++)
		{
			mod->hulls[j].firstclipnode = bm->headnode[j];
			mod->hulls[j].lastclipnode = mod->numclipnodes-1;
		}
		
		mod->firstmodelsurface = bm->firstface;
		mod->nummodelsurfaces = bm->numfaces;
		
		VectorCopy (bm->maxs, mod->maxs);
		VectorCopy (bm->mins, mod->mins);

		mod->radius = RadiusFromBounds (mod->mins, mod->maxs);

		mod->numleafs = bm->visleafs;

		if (isworldmodel && i < (mod->numsubmodels-1)) // LordHavoc: only register submodels if it is the world (prevents bsp models from replacing world submodels)
		{	// duplicate the basic information
			char	name[10];

			sprintf (name, "*%i", i+1);
			loadmodel = Mod_FindName (name);
			*loadmodel = *mod;
			strcpy (loadmodel->name, name);
			mod = loadmodel;
		}
	}
}

int lightpointvalue;
int SV_RecursiveLightPoint (mnode_t *node, float x, float y, float startz, float endz)
{
	int		side, distz = endz - startz;
	float	front, back;
	float	mid;

loc0:
	if (node->contents < 0)
		return false;		// didn't hit anything

	switch (node->plane->type)
	{
	case PLANE_X:
		node = node->children[x < node->plane->dist];
		goto loc0;
	case PLANE_Y:
		node = node->children[y < node->plane->dist];
		goto loc0;
	case PLANE_Z:
		side = startz < node->plane->dist;
		if ((endz < node->plane->dist) == side)
		{
			node = node->children[side];
			goto loc0;
		}
		// found an intersection
//		mid = startz + (endz - startz) * (startz - node->plane->dist) / (startz - endz);
//		mid = startz + distz * (startz - node->plane->dist) / (-distz);
//		mid = startz + (-(startz - node->plane->dist));
//		mid = startz - (startz - node->plane->dist);
//		mid = startz + node->plane->dist - startz;
		mid = node->plane->dist;
		break;
	default:
		back = front = x * node->plane->normal[0] + y * node->plane->normal[1];
		front += startz * node->plane->normal[2];
		back += endz * node->plane->normal[2];
		side = front < node->plane->dist;
		if ((back < node->plane->dist) == side)
		{
			node = node->children[side];
			goto loc0;
		}
		// found an intersection
//		mid = startz + (endz - startz) * ((front - node->plane->dist) / ((front - node->plane->dist) - (back - node->plane->dist)));
//		mid = startz + (endz - startz) * ((front - node->plane->dist) / (front - back));
		mid = startz + distz * (front - node->plane->dist) / (front - back);
		break;
	}
	
	// go down front side
	if (node->children[side]->contents >= 0 && SV_RecursiveLightPoint(node->children[side], x, y, startz, mid))
		return true;	// hit something
	else
	{
		// check for impact on this node
		if (node->numsurfaces)
		{
			int i, ds, dt;
			msurface_t *surf;

			surf = sv.worldmodel->surfaces + node->firstsurface;
			for (i = 0;i < node->numsurfaces;i++, surf++)
			{
				if (surf->flags & TEX_SPECIAL)
					continue;	// no lightmaps

				ds = (int) (x * surf->texinfo->vecs[0][0] + y * surf->texinfo->vecs[0][1] + mid * surf->texinfo->vecs[0][2] + surf->texinfo->vecs[0][3]);
				dt = (int) (x * surf->texinfo->vecs[1][0] + y * surf->texinfo->vecs[1][1] + mid * surf->texinfo->vecs[1][2] + surf->texinfo->vecs[1][3]);

				if (ds < surf->texturemins[0] || dt < surf->texturemins[1])
					continue;
				
				ds -= surf->texturemins[0];
				dt -= surf->texturemins[1];
				
				if (ds > surf->extents[0] || dt > surf->extents[1])
					continue;

				if (surf->samples)
				{
					byte *lightmap;
					int maps, size;
					size = ((surf->extents[0]>>4)+1) * ((surf->extents[1]>>4)+1);

					lightmap = surf->samples + ((dt>>4) * ((surf->extents[0]>>4)+1) + (ds>>4));

					// FIXME: server doesn't know what light styles are doing
					for (maps = 0;maps < MAXLIGHTMAPS && surf->styles[maps] != 255;maps++)
					{
						lightpointvalue += *lightmap;
						lightmap += size;
					}
				}
				return true; // success
			}
		}

		// go down back side
		node = node->children[side ^ 1];
		startz = mid;
		distz = endz - startz;
		goto loc0;
	}
}

void SV_LightPoint (vec3_t color, vec3_t p)
{
	if (!sv.worldmodel->lightdata)
	{
		color[0] = color[1] = color[2] = 255;
		return;
	}
	
	lightpointvalue = 0;
	SV_RecursiveLightPoint (sv.worldmodel->nodes, p[0], p[1], p[2], p[2] - 65536);
	color[0] = color[1] = color[2] = lightpointvalue;
}
