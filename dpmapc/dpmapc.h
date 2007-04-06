
#ifndef DPMAPC_H
#define DPMAPC_H

#include "stdlib.h"

#include "dpmapc_q3bsp.h"

#define dpmapc_trianglenormal(a,b,c,n) ((n)[0] = ((a)[1] - (b)[1]) * ((c)[2] - (b)[2]) - ((a)[2] - (b)[2]) * ((c)[1] - (b)[1]), (n)[1] = ((a)[2] - (b)[2]) * ((c)[0] - (b)[0]) - ((a)[0] - (b)[0]) * ((c)[2] - (b)[2]), (n)[2] = ((a)[0] - (b)[0]) * ((c)[1] - (b)[1]) - ((a)[1] - (b)[1]) * ((c)[0] - (b)[0]))
#define dpmapc_dotproduct(a,b) ((a)[0] * (b)[0] + (a)[1] * (b)[1] + (a)[2] * (b)[2])
#define dpmapc_vectorlength2(a) (dpmapc_dotproduct((a),(a)))
#define dpmapc_vectorlength(a) (sqrt(dpmapc_dotproduct((a),(a))))
#define dpmapc_vectorcopy(a,d) ((d)[0] = (a)[0], (d)[1] = (a)[1], (d)[2] = (a)[2])
#define dpmapc_vectorcopy4(a,d) ((d)[0] = (a)[0], (d)[1] = (a)[1], (d)[2] = (a)[2], (d)[3] = (a)[3])
#define dpmapc_vectoradd(a,b,d) ((d)[0] = (a)[0] + (b)[1], (d)[1] = (a)[1] + (b)[1], (d)[2] = (a)[2] + (b)[2])
#define dpmapc_vectorscale(a,s,d) ((d)[0] = (a)[0] * (s), (d)[1] = (a)[1] * (s), (d)[2] = (a)[2] * (s))
#define dpmapc_vectorma(a,s,b,d) ((d)[0] = (a)[0] + (s) * (b)[1], (d)[1] = (a)[1] + (s) * (b)[1], (d)[2] = (a)[2] + (s) * (b)[2])
#define dpmapc_vectornormalize(d) do{double _d = dpmapc_vectorlength(d);if (d){_d = 1.0 / _d;dpmapc_vectorscale((d),_d,(d));}}while(0)
#define dpmapc_vectorset(a,x,y,z) ((a)[0] = (x), (a)[1] = (y), (a)[2] = (z))
#define dpmapc_vectorset4(a,x,y,z,w) ((a)[0] = (x), (a)[1] = (y), (a)[2] = (z), (a)[3] = (w))

#define DPMAPC_QUADFORPLANE_SIZE (1024.0*1024.0*1024.0)
#define DPMAPC_BRUSH_MAXSIDES 64
#define DPMAPC_BRUSH_MAXPOLYGONPOINTS (DPMAPC_BRUSH_MAXSIDES)
#define DPMAPC_SURFACE_MAXVERTICES 1000
#define DPMAPC_SURFACE_MAXTRIANGLES 2000

// epsilons (tolerances)
#define DPMAPC_PLANECOMPAREEPSILON (1 - (1.0 / 4096.0))
#define DPMAPC_POLYGONCLIP_EPSILON (1.0 / 4096.0)

#define MAX_FILENAME 1024

typedef enum boolean_e
{
	false = 0,
	true = 1
}
boolean;

typedef enum dpmapc_tokentype_e
{
	DPMAPC_TOKENTYPE_EOF,
	DPMAPC_TOKENTYPE_PARSEERROR,
	DPMAPC_TOKENTYPE_NEWLINE,
	DPMAPC_TOKENTYPE_NAME,
	DPMAPC_TOKENTYPE_STRING
}
dpmapc_tokentype_t;

typedef struct dpmapc_tokenstate_s
{
	const char *input;
	const char *inputend;
	char token[64];//4096];
	dpmapc_tokentype_t tokentype;
	int linenumber;
}
dpmapc_tokenstate_t;

typedef struct bspdata_plane_s
{
	double normal[3];
	double dist;
}
bspdata_plane_t;

typedef struct bspdata_brushside_s
{
	struct bspdata_brushside_s *next;
	// for error reporting
	int linenumber;
	// plane of this brush side surface
	bspdata_plane_t plane;
	// polygon of this brushside
	int polygonnumpoints;
	double *polygonpoints;
	// texture applied to this brush side surface
	char texturename[64];
	// axis vectors for computing surface texcoords
	double texvecs[2][3];
	// post transform adjustments
	double bp[2][3];
	// extra properties
	int surfacecontents;
	int surfaceflags;
	int surfacevalue;
}
bspdata_brushside_t;

typedef struct bspdata_brush_s
{
	struct bspdata_brush_s *next;
	int numsides;
	bspdata_brushside_t *sides;
	unsigned int contentflags;
	// used for culling
	double mins[3];
	double maxs[3];
}
bspdata_brush_t;

typedef struct bspdata_surfacevertex_s
{
	double vertex[3];
	double normal[3];
	double texcoordtexture[2];
	double texcoordlightmap[2];
	double color[4];
}
bspdata_surfacevertex_t;

typedef struct bspdata_surface_s
{
	struct bspdata_surface_s *next;
	char texturename[64];
	int numvertices;
	bspdata_surfacevertex_t *vertices;
	int numtriangles;
	int maxtriangles;
	int *elements;
	int surfacecontents;
	int surfaceflags;
	int surfacevalue;
	int primaryaxis;
}
bspdata_surface_t;

typedef struct bspdata_entityfield_s
{
	struct bspdata_entityfield_s *next;
	char *key;
	char *value;
}
bspdata_entityfield_t;

// these are created by dpmapc_loadmap
typedef struct bspdata_entity_s
{
	struct bspdata_entity_s *next;
	bspdata_entityfield_t *fieldlist;
	bspdata_brush_t *brushlist;
	bspdata_surface_t *surfacelist;
	// extra data just used for compiling
	char classname[64];
	char target[64];
	char targetname[64];
	double origin[3];
}
bspdata_entity_t;

typedef struct bspdata_submodel_s
{
	double mins[3];
	double maxs[3];

	int firstface;
	int numfaces;
	int firstbrush;
	int numbrushes;
}
bspdata_submodel_t;

typedef struct bspdata_node_s
{
	boolean isnode;

	// bounding box (computed for saving but not used)
	double mins[3];
	double maxs[3];

	// node-specific
	struct bspdata_node_s *children[2];
	bspdata_plane_t plane;

	// leaf-specific
	int clusterindex; // -1 = solid, >= 0 = index into pvs bits
	//int areaindex; // always 0 (areas not supported by dpmapc)
	//int firstleafsurface;
	//int numleafsurface;
	//int firstleafbrush;
	//int numleafbrush;
	bspdata_surface_t *surfacelist;
	bspdata_brush_t *brushlist;
}
bspdata_node_t;

typedef struct bspdata_texinfo_s
{
	char name[Q3PATHLENGTH];
	int surfaceflags;
	int contents;
}
bspdata_texinfo_t;

typedef struct bspdata_s
{
	bspdata_node_t *rootnode;

	int numclusters;

	//int numentitystring;
	//int maxentitystring;
	//char *entitystring;

	//int numtexinfo;
	//int maxtexinfo;
	//bspdata_texinfo_t *texinfo;

	//int numplanes;
	//int maxplanes;
	//bspdata_plane_t *planes;

	//int numnodes;
	//int maxnodes;
	//bspdata_node_t *nodes;

	// TODO: get rid of leafs, count them as nodes instead?
	//int numleafs;
	//int maxleafs;
	//bspdata_node_t *leafs;

	//int numleaffaces;
	//int maxleaffaces;
	//int *leaffaces;

	//int numleafbrushes;
	//int maxleafbrushes;
	//int *leafbrushes;

	//int numsubmodels;
	//int maxsubmodels;
	//bspdata_submodel_t *submodels;

	//int numbrushes;
	//int maxbrushes;
	//bspdata_brush_t *brushes;

	//int numbrushsides;
	//int maxbrushsides;
	//bspdata_brushside_t *brushsides;

	//int numvertices;
	//int maxvertices;
	//bspdata_vertex_t *vertices;

	//int numtriangles;
	//int maxtriangles;
	//bspdata_triangle_t *triangles;

	//int numeffects;
	//int maxeffects;
	//bspdata_effect_t *effects;

	//int numsurfaces;
	//int maxsurfaces;
	//bspdata_surface_t *surfaces;

	//int numlightmaps;
	//int maxlightmaps;
	//unsigned char *lightmaps;

	//int numlightgridcells;
	//int maxlightgridcells;
	//bspdata_lightgridcell_t *lightgridcells;
}
bspdata_t;

typedef enum dpmapc_brushtype_e
{
	DPMAPC_BRUSHTYPE_BRUSHDEF,
	DPMAPC_BRUSHTYPE_BRUSHDEF3,
	DPMAPC_BRUSHTYPE_PATCHDEF2,
	DPMAPC_BRUSHTYPE_PATCHDEF3
}
dpmapc_brushtype_t;

// memory functions
void *dpmapc_alloc(size_t size);
void dpmapc_free(void *mem);

// string functions
size_t dpmapc_strlcpy(char *dest, const char *source, size_t destsize);
size_t dpmapc_strlcat(char *dest, const char *source, size_t destsize);
char *dpmapc_strdup(const char *source);
void dpmapc_strfree(char *source);
size_t dpmapc_stripextension(char *dest, const char *source, size_t destsize);

// terminal print/error functions
void dpmapc_log(const char *format, ...);
void dpmapc_error(const char *format, ...);
void dpmapc_warning(const char *format, ...);

// file I/O functions
void *dpmapc_loadfile(const char *filename, size_t *sizevariable);
void dpmapc_savefile(const char *filename, size_t size, void *filedata);

// parsing functions
void dpmapc_token_begin(dpmapc_tokenstate_t *tokenstate, const char *input, const char *inputend);
dpmapc_tokentype_t dpmapc_token_get(dpmapc_tokenstate_t *tokenstate, boolean skipnewline);

// bbox functions
void dpmapc_bbox_firstpoint(double *mins, double *maxs, double *point);
void dpmapc_bbox_addpoint(double *mins, double *maxs, double *point);

// entity field functions
bspdata_entityfield_t *dpmapc_entity_setvalue(bspdata_entity_t *entity, const char *key, const char *value);
const char *dpmapc_entity_getvalue(bspdata_entity_t *entity, const char *key);

// brush functions
bspdata_brush_t *dpmapc_createbrush(int brushnumsides, const bspdata_brushside_t *brushsides);

// loadmap functions
bspdata_entity_t *dpmapc_loadmap(const char *filename);

#endif

