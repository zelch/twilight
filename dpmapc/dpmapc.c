
// dpmapc map compiler, Copyright 2005 Forest Hale.

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include <math.h>
#include "dpmapc.h"
#include "polygon.h"

#define CLIP_EPSILON (1.0 / 1024.0)
#define CLIP_MAXPOINTS 64

void Vis_RecursivePortalFlow(bspdata_leaf_t *leaf, unsigned char *pvs, int numeyepoints, double *eyepoints, int seenthroughnumpoints, double *seenthroughpoints)
{
	int eyepointindex, seenthroughpointindex, testpointindex;
	int w, tempnumpoints;
	portal_t *portal;
	double edge1[3], edge2[3];
	double plane[4];
	double temppoints[2][CLIP_MAXPOINTS];
	// if this is a vis-blocking leaf, skip it
	if (leaf->clusterindex < 0)
		return;
	// set this leaf as visible in the pvs
	PVS_SETBIT(pvs, leaf->clusterindex);
	// loop over portals on this leaf, flowing outward to neighboring leafs,
	// each time producing a smaller frustum plane set
	// (this is known as a beam tree)
	for (portal = leaf->portals;portal;portal = portal->next)
	{
		// don't flow into vis-blocking (solid) leafs
		if (portal->leaf->clusterindex < 0)
			continue;
		// make sure this portal is not facing the eyeportal
		for (testpointindex = 0;testpointindex < numeyepoints;testpointindex++)
			if (DotProduct(eyepoints + testpointindex + 3, farportal->plane) >= farportal->plane[3])
				break;
		// skip the plane if it is facing the eyeportal
		if (testpointindex < numeyepoints)
			continue;
		// copy this portal polygon into a buffer for clipping operations
		w = 0;
		tempnumpoints = portal->numpoints;
		memcpy(temppoints[0], portal->points, sizeof(double[3]) * portal->numpoints);
		// iterate over all combinations of an eye point and an edge from seenthroughpoints
		for (eyepointindex = 0;eyepointindex;eyepointindex < numeyepoints && tempnumpoints >= 3;eyepointindex++)
		{
			for (seenthroughpointindex = 0;seenthroughpointindex < seenthroughnumpoints && tempnumpoints >= 3;seenthroughpointindex++)
			{
				// generate a plane using one point from eyepoints and two points from seenthroughpoints
				VectorSubtract(eyepoints + eyepointindex * 3, seenthroughpoints + seenthroughpointindex * 3, edge1);
				VectorSubtract(seenthroughpoints + ((seenthroughpointindex + 1) % seenthroughnumpoints) * 3, seenthroughpoints + seenthroughpointindex * 3, edge2);
				CrossProduct(edge1, edge2, plane);
				VectorNormalize(plane);
				plane[3] = DotProduct(eyeportal->points[eyepointindex], plane);
				// see if this plane is valid (does not put any points of seenthrough outside the volume)
				for (testpointindex = 0;testpointindex < seenthroughnumpoints;testpointindex++)
					if (DotProduct(seenthroughpoints + testpointindex + 3, plane) > plane[3] + CLIP_EPSILON)
						break;
				// skip the plane if it is invalid
				if (testpointindex < seenthroughnumpoints)
					continue;
				// clip the polygon by this plane
				PolygonD_Divide(tempnumpoints, temppoints[w], plane[0], plane[1], plane[2], plane[3], CLIP_EPSILON, 0, NULL, NULL, CLIP_MAXPOINTS, temppoints[w^1], &tempnumpoints, NULL);
				// results are now in the other buffer
				w ^= 1;
			}
		}
		// if some part of the portal polygon survived the clipping operations,
		// recurse down the passage, marking additional leafs as visible
		if (tempnumpoints >= 3)
			Vis_RecursivePortalFlow(portal->leaf, numeyepoints, eyepoints, tempnumpoints, temppoints[w]);
	}
}

void Vis_CalculatePVSForLeaf(bspdata_leaf_t *leaf, unsigned char *pvs)
{
	int testpointindex;
	portal_t *eyeportal, *farportal;
	bspdata_leaf_t *farleaf;
	PVS_SETBIT(pvs, leaf->clusterindex);
	for (eyeportal = leaf->portals;eyeportal;eyeportal = eyeportal->next)
	{
		farleaf = eyeportal->farleaf;
		PVS_SETBIT(pvs, farleaf->clusterindex);
		for (farportal = farleaf->portals;farportal;farportal = farportal->next)
		{
			// make sure this portal is not facing the eyeportal
			for (testpointindex = 0;testpointindex < eyeportal->numpoints;testpointindex++)
				if (DotProduct(eyeportal->points + testpointindex + 3, farportal->plane) >= farportal->plane[3])
					break;
			// skip the plane if it is facing the eyeportal
			if (testpointindex < eyeportal->numpoints)
				continue;
			// recurse into this leaf
			Vis_RecursivePortalFlow(farportal->farleaf, pvs, eyeportal->numpoints, eyeportal->points, farportal->numpoints, farportal->points);
		}
	}
}

static double dpmapc_normal_primaryaxis[6][3] = {{1, 0, 0}, {0, 1, 0}, {0, 0, 1}, {-1, 0, 0}, {0, -1, 0}, {0, 0, -1}};

int dpmapc_normal_classifyprimaryaxis(double *normal)
{
	int i, best;
	double dist, bestdist;
	best = 0;
	bestdist = dpmapc_dotproduct(normal, dpmapc_normal_primaryaxis[0]);
	for (i = 1;i < 6;i++)
	{
		dist = dpmapc_dotproduct(normal, dpmapc_normal_primaryaxis[i]);
		if (bestdist < dist)
		{
			bestdist = dist;
			best = i;
		}
	}
	return i;
}

// brush functions
bspdata_brush_t *dpmapc_createbrush(int brushnumsides, const bspdata_brushside_t *brushsides)
{
	int polygonnumpoints, polygonnumpoints2, sideindex, sideindex2, pointindex;
	boolean setbounds;
	bspdata_brush_t *brush;
	const bspdata_brushside_t *side, *side2;
	bspdata_brushside_t *s;
	double polygonpoints[DPMAPC_BRUSH_MAXPOLYGONPOINTS*3], polygonpoints2[DPMAPC_BRUSH_MAXPOLYGONPOINTS*3];
	brush = dpmapc_alloc(sizeof(bspdata_brush_t) + brushnumsides * sizeof(bspdata_brushside_t));
	brush->numsides = 0;
	brush->sides = (bspdata_brushside_t *)(brush + 1);
	setbounds = true;
	for (sideindex = 0, side = brushsides;sideindex < brushnumsides;sideindex++, side++)
	{
		PolygonD_QuadForPlane(polygonpoints, side->plane.normal[0], side->plane.normal[1], side->plane.normal[2], side->plane.dist, DPMAPC_QUADFORPLANE_SIZE);
		polygonnumpoints = 4;
		for (sideindex2 = 0, side2 = brushsides;sideindex2 < brushnumsides;sideindex2++, side2++)
		{
			if (sideindex2 == sideindex)
				continue;
			PolygonD_Divide(polygonnumpoints, polygonpoints, side2->plane.normal[0], side2->plane.normal[1], side2->plane.normal[2], side2->plane.dist, DPMAPC_POLYGONCLIP_EPSILON, DPMAPC_BRUSH_MAXPOLYGONPOINTS, polygonpoints2, &polygonnumpoints2, 0, NULL, NULL);
			polygonnumpoints = polygonnumpoints2;
			if (polygonnumpoints < 3)
				break;
			memcpy(polygonpoints, polygonpoints2, polygonnumpoints2 * sizeof(double[3]));
		}
		if (polygonnumpoints < 3)
		{
			dpmapc_warning("brush face clipped away at line %i\n", side->linenumber);
			continue;
		}
		s = brush->sides + brush->numsides++;
		s->polygonnumpoints = polygonnumpoints;
		s->polygonpoints = dpmapc_alloc(polygonnumpoints * sizeof(double[3]));
		memcpy(s->polygonpoints, polygonpoints, polygonnumpoints * sizeof(double[3]));
		if (setbounds)
		{
			setbounds = false;
			dpmapc_bbox_firstpoint(brush->mins, brush->maxs, s->polygonpoints);
		}
		for (pointindex = 0;pointindex < s->polygonnumpoints;pointindex++)
			dpmapc_bbox_addpoint(brush->mins, brush->maxs, s->polygonpoints + pointindex * 3);
	}
	return brush;
}


void dpmapc_buildbsp(bspdata_t *bspdata, bspdata_entity_t *entitylist)
{
	bspdata->rootnode = dpmapc_alloc(sizeof(bspdata_node_t));
	bspdata->rootnode->isnode = false;
	bspdata->numclusters = 0;
	// TODO: initialize BSP tree to a kdtree grid
	// TODO: compile structural solid brushes into bsp tree
	// TODO: mark solid leafs as clusterindex -1 and others as clusterindex 0
	// TODO: if a plane normal matches a negative axis, swap child order and flip plane
}

// note: only alters leafs with clusterindex >= 0 (as -1 is used for solid clusters)
void dpmapc_recursiveassignclusters(bspdata_t *bspdata, bspdata_node_t *node)
{
	if (node->isnode)
	{
		dpmapc_recursiveassignclusters(bspdata, node->children[0]);
		dpmapc_recursiveassignclusters(bspdata, node->children[1]);
	}
	else if (node->clusterindex >= 0)
		node->clusterindex = bspdata->numclusters++;
}

void dpmapc_vertexforbrushside(bspdata_surfacevertex_t *vertex, double *point, bspdata_brushside_t *side)
{
	dpmapc_vectorcopy(point, vertex->vertex);
	dpmapc_vectorcopy(side->plane.normal, vertex->normal);
	vertex->texcoordtexture[0] = dpmapc_dotproduct(vertex->vertex, side->texvecs[0]) * side->bp[0][0] + dpmapc_dotproduct(vertex->vertex, side->texvecs[1]) * side->bp[0][1] + side->bp[0][2];
	vertex->texcoordtexture[1] = dpmapc_dotproduct(vertex->vertex, side->texvecs[0]) * side->bp[1][0] + dpmapc_dotproduct(vertex->vertex, side->texvecs[1]) * side->bp[1][1] + side->bp[1][2];
	vertex->texcoordlightmap[0] = 0;
	vertex->texcoordlightmap[1] = 0;
	vertex->color[0] = 0;
	vertex->color[1] = 0;
	vertex->color[2] = 0;
	vertex->color[3] = 0;
}

void dpmapc_surface_addtriangle(bspdata_surface_t *surface, bspdata_surfacevertex_t *vertex)
{
	int i, j;
	bspdata_surfacevertex_t *v, *sv;
	if (surface->maxtriangles <= surface->numtriangles)
	{
		bspdata_surfacevertex_t *oldvertices;
		int *oldelements;
		surface->maxtriangles += 64;
		oldvertices = surface->vertices;
		oldelements = surface->elements;
		surface->vertices = dpmapc_alloc(sizeof(bspdata_surfacevertex_t) * surface->maxtriangles * 3 + sizeof(int) * surface->maxtriangles * 3);
		surface->elements = (int *)(surface->vertices + surface->maxtriangles * 3);
		if (surface->numtriangles)
		{
			memcpy(surface->vertices, oldvertices, surface->numvertices * sizeof(bspdata_surfacevertex_t));
			memcpy(surface->elements, oldelements, surface->numtriangles * sizeof(int[3]));
			dpmapc_free(oldvertices);
		}
	}
	// add the triangle vertices and elements
	for (i = 0, v = vertex;i < 3;i++, v++)
	{
		// add a vertex only if it's different from the existing ones
		// TODO: hash search?  probably not worth it
		for (j = 0, sv = surface->vertices;j < surface->numvertices;j++, sv++)
			if (sv->vertex[0] == v->vertex[0] && sv->vertex[1] == v->vertex[1] && sv->vertex[2] == v->vertex[2]
			 && sv->normal[0] == v->normal[0] && sv->normal[1] == v->normal[1] && sv->normal[2] == v->normal[2]
			 && sv->texcoordtexture[0] == v->texcoordtexture[0] && sv->texcoordtexture[1] == v->texcoordtexture[1]
			 && sv->texcoordlightmap[0] == v->texcoordlightmap[0] && sv->texcoordlightmap[1] == v->texcoordlightmap[1]
			 && sv->color[0] == v->color[0] && sv->color[1] == v->color[1] && sv->color[2] == v->color[2] && sv->color[3] == v->color[3])
				break;
		if (j == surface->numvertices)
		{
			surface->numvertices++;
			sv->vertex[0] = v->vertex[0];
			sv->vertex[1] = v->vertex[1];
			sv->vertex[2] = v->vertex[2];
			sv->normal[0] = v->normal[0];
			sv->normal[1] = v->normal[1];
			sv->normal[2] = v->normal[2];
			sv->texcoordtexture[0] = v->texcoordtexture[0];
			sv->texcoordtexture[1] = v->texcoordtexture[1];
			sv->texcoordlightmap[0] = v->texcoordlightmap[0];
			sv->texcoordlightmap[1] = v->texcoordlightmap[1];
			sv->color[0] = v->color[0];
			sv->color[1] = v->color[1];
			sv->color[2] = v->color[2];
			sv->color[3] = v->color[3];
		}
		// store the vertex index
		surface->elements[surface->numtriangles*3+i] = j;
	}
	surface->numtriangles++;
}

void dpmapc_insertsurface_recursivebrushside_leaf(bspdata_node_t *node, int numpoints, double *points, bspdata_brushside_t *side)
{
	int primaryaxis, triangleindex;
	bspdata_surface_t *surface;
	bspdata_surfacevertex_t vertex[3];
	primaryaxis = dpmapc_normal_classifyprimaryaxis(side->plane.normal);
	for (surface = node->surfacelist;surface;surface = surface->next)
		if (surface->primaryaxis == primaryaxis
		&& surface->surfacecontents == side->surfacecontents
		&& surface->surfaceflags == side->surfaceflags
		&& surface->surfacevalue == side->surfacevalue
		&& !strcmp(surface->texturename, side->texturename)
		&& surface->numvertices + numpoints <= DPMAPC_SURFACE_MAXVERTICES
		&& surface->numtriangles + (numpoints - 2) <= DPMAPC_SURFACE_MAXTRIANGLES)
			break;
	if (!surface)
	{
		surface = dpmapc_alloc(sizeof(bspdata_surface_t));
		surface->primaryaxis = primaryaxis;
		surface->surfacecontents = side->surfacecontents;
		surface->surfaceflags = side->surfaceflags;
		surface->surfacevalue = side->surfacevalue;
		dpmapc_strlcpy(surface->texturename, side->texturename, sizeof(surface->texturename));
		surface->next = node->surfacelist;
		node->surfacelist = surface;
	}
	// Yes this is not in Quake3's preferred strip order, this is fan order,
	// I don't know how to generate it as a strip, and strip sorting could be
	// done as an optimization in later processing
	for (triangleindex = 0;triangleindex < side->polygonnumpoints - 2;triangleindex++)
	{
		dpmapc_vertexforbrushside(vertex + 0, points, side);
		dpmapc_vertexforbrushside(vertex + 1, points + triangleindex * 3 + 3, side);
		dpmapc_vertexforbrushside(vertex + 2, points + triangleindex * 3 + 6, side);
		dpmapc_surface_addtriangle(surface, vertex);
	}
}

void dpmapc_insertsurface_recursive_node(bspdata_node_t *node, int numpoints, double *points, bspdata_brushside_t *side);

void dpmapc_insertsurface_recursive_split(bspdata_node_t *node, int numpoints, double *points, bspdata_brushside_t *side)
{
	int newnumpoints[2];
	double newpoints[2][DPMAPC_BRUSH_MAXPOLYGONPOINTS*3];
	PolygonD_Divide(numpoints, points, node->plane.normal[0], node->plane.normal[1], node->plane.normal[2], node->plane.dist, DPMAPC_POLYGONCLIP_EPSILON, DPMAPC_BRUSH_MAXPOLYGONPOINTS, newpoints[0], &newnumpoints[0], DPMAPC_BRUSH_MAXPOLYGONPOINTS, newpoints[1], &newnumpoints[1]);
	dpmapc_insertsurface_recursive_node(node->children[0], newnumpoints[0], newpoints[0], side);
	dpmapc_insertsurface_recursive_node(node->children[1], newnumpoints[1], newpoints[1], side);
}

void dpmapc_insertsurface_recursive_node(bspdata_node_t *node, int numpoints, double *points, bspdata_brushside_t *side)
{
	while (node->isnode)
	{
		int i;
		int sideflags = 0;
		for (i = 0;i < numpoints;i++)
			sideflags |= (dpmapc_dotproduct(node->plane.normal, points + i*3) < node->plane.dist) + 1;
		if (sideflags == 3)
		{
			dpmapc_insertsurface_recursive_split(node, numpoints, points, side);
			return;
		}
		else
			node = node->children[sideflags - 1];
	}
	dpmapc_insertsurface_recursive_leaf(node, numpoints, points, side);
}

void dpmapc_insertbrush_recursive_node(bspdata_node_t *node, bspdata_brush_t *brush)
{
	blarg
}

void dpmapc_insertgeometry(bspdata_t *bspdata, bspdata_entity_t *entitylist)
{
	int sidenum;
	bspdata_entity_t *entity;
	bspdata_brush_t *brush;
	bspdata_brushside_t *side;
	for (entity = entitylist;entity;entity = entity->next)
	{
		for (brush = entity->brushlist;brush;brush = brush->next)
		{
			for (sidenum = 0, side = brush->sides;sidenum < brush->numsides;sidenum++, side++)
				dpmapc_insertsurface_recursive_node(bspdata->rootnode, side->polygonnumpoints, side->polygonpoints, side);
			dpmapc_insertbrush(bspdata, brush);
		}
		// TODO: handle patchlist
		// TODO: handle modellist
	}
}

bspdata_t *dpmapc_compilegeometry(bspdata_entity_t *entitylist)
{
	bspdata_t *bspdata = dpmapc_alloc(sizeof(bspdata_t));
	if (!bspdata)
		return NULL;
	dpmapc_buildbsp(bspdata, entitylist);
	dpmapc_recursiveassignclusters(bspdata, bspdata->rootnode);
	dpmapc_insertgeometry(bspdata, entitylist);
	return bspdata;
}

bspdata_t *dpmapc_loadbsp(const char *filename)
{
	void *bspfiledata;
	size_t bspfilesize;
	bspdata_t *bspdata = NULL;
	bspfiledata = dpmapc_loadfile(filename, &bspfilesize);
	if (!bspfiledata)
	{
		dpmapc_warning("unable to load \"%s\"\n", filename);
		return NULL;
	}
	// TODO: decode bsp file
	dpmapc_free(bspfiledata);
	return bspdata;
}

void dpmapc_onlyents(bspdata_t *bspdata, const char *filename)
{
	void *maptext;
	size_t maptextsize;
	maptext = dpmapc_loadfile(filename, &maptextsize);
	if (!maptext)
	{
		dpmapc_warning("unable to load \"%s\"\n", filename);
		return;
	}
	// TODO: parse maptext and replace bspdata->entities data
	dpmapc_free(maptext);
}

void dpmapc_freebsp(bspdata_t *bspdata)
{
	// TODO: free data attached to bspdata
	dpmapc_free(bspdata);
}

void dpmapc_savebsp(bspdata_t *bspdata, const char *filename)
{
	// TODO: encode bsp file
}

void dpmapc_exportase(bspdata_t *bspdata, const char *filename)
{
	// TODO: encode ase file
}

void dpmapc_printinfo(bspdata_t *bspdata)
{
	// TODO: print bspdata info
}

void dpmapc_vis(bspdata_t *bspdata)
{
	// TODO; iterate over bspdata->nodes and generate leaf portals
	// TODO: iterate over bspdata->leafs and recursively follow portals outward, clipping by planes surrounding the two polygons they are seen through and passing the new clipped polygon to the recursive call, set pvs bits accordingly
}

void dpmapc_light(bspdata_t *bspdata)
{
	// TODO: raytrace from surface vertices/lightmap texels to lights and accumulate color
}

static void usage(void)
{
	fprintf(stderr,
"DPMapC Copyright 2005 Forest Hale\n"
"usage: dpmapc [-bsp] [-vis] [-light] [-info] [-onlyents] filename\n"
"-bsp       compile .map geometry/entities to .bsp\n"
"-vis       compile visibility data for a .bsp\n"
"-light     compile lighting data for a .bsp\n"
"-info      print statistics of a .bsp\n"
"-onlyents  update .bsp entities string from .map (can not be used with -bsp)\n"
"-exportase save .bsp geometry to .ase model\n"
"Common usage: dpmapc -bsp -vis -light -info mymap\n"
	);
	exit(1);
}

#define DPMAPCMODE_BSP 1
#define DPMAPCMODE_VIS 2
#define DPMAPCMODE_LIGHT 4
#define DPMAPCMODE_INFO 8
#define DPMAPCMODE_ONLYENTS 16
#define DPMAPCMODE_EXPORTASE 32

int main(int argc, char **argv)
{
	int i;
	int mode;
	const char *filename;
	char bspfilename[MAX_FILENAME];
	char asefilename[MAX_FILENAME];
	char mapfilename[MAX_FILENAME];
	bspdata_t *bspdata;
	mode = 0;
	filename = NULL;
	for (i = 1;i < argc;i++)
	{
		if (argv[i] && argv[i][0] == '-')
		{
			if (!strcmp(argv[i], "-bsp"))
				mode |= DPMAPCMODE_BSP;
			else if (!strcmp(argv[i], "-vis"))
				mode |= DPMAPCMODE_VIS;
			else if (!strcmp(argv[i], "-light"))
				mode |= DPMAPCMODE_LIGHT;
			else if (!strcmp(argv[i], "-info"))
				mode |= DPMAPCMODE_INFO;
			else if (!strcmp(argv[i], "-onlyents"))
				mode |= DPMAPCMODE_ONLYENTS;
			else if (!strcmp(argv[i], "-exportase"))
				mode |= DPMAPCMODE_EXPORTASE;
			else
				usage();
		}
		else
		{
			if (filename)
				usage();
			filename = argv[i];
		}
	}
	if (!filename || (mode & (DPMAPCMODE_BSP | DPMAPCMODE_ONLYENTS)) == (DPMAPCMODE_BSP | DPMAPCMODE_ONLYENTS))
		usage();
	dpmapc_stripextension(bspfilename, filename, sizeof(bspfilename));
	dpmapc_strlcpy(mapfilename, bspfilename, sizeof(mapfilename));
	dpmapc_strlcpy(asefilename, bspfilename, sizeof(asefilename));
	dpmapc_strlcat(bspfilename, ".bsp", sizeof(bspfilename));
	dpmapc_strlcat(mapfilename, ".map", sizeof(mapfilename));
	dpmapc_strlcat(asefilename, ".ase", sizeof(asefilename));
	if (mode & DPMAPCMODE_BSP)
	{
		bspdata_entity_t *entitylist = dpmapc_loadmap(mapfilename);
		if (!entitylist)
			dpmapc_error("failed to load entities from \"%s\"\n", mapfilename);
		bspdata = dpmapc_compilegeometry(entitylist);
		dpmapc_free(entitylist);
		if (!bspdata)
			dpmapc_error("failed to compile bsp from \"%s\"\n", mapfilename);
	}
	else
	{
		bspdata = dpmapc_loadbsp(bspfilename);
		if (!bspdata)
			dpmapc_error("failed to load bsp from \"%s\"\n", bspfilename);
		if (mode & DPMAPCMODE_ONLYENTS)
			dpmapc_onlyents(bspdata, mapfilename);
	}
	if (mode & DPMAPCMODE_VIS)
		dpmapc_vis(bspdata);
	if (mode & DPMAPCMODE_LIGHT)
		dpmapc_light(bspdata);
	if (mode & DPMAPCMODE_EXPORTASE)
		dpmapc_exportase(bspdata, asefilename);
	if (mode & DPMAPCMODE_INFO)
		dpmapc_printinfo(bspdata);
	if (mode & (DPMAPCMODE_BSP | DPMAPCMODE_VIS | DPMAPCMODE_LIGHT | DPMAPCMODE_ONLYENTS))
		dpmapc_savebsp(bspdata, bspfilename);
	dpmapc_freebsp(bspdata);
	return 0;
}

