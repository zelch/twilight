
#include "cmdlib.h"
#include "mathlib.h"
#include "bspfile.h"
#include "mem.h"

#define ON_EPSILON 0.1

#define MAXLIGHTS 1024
#define LIGHTDISTBIAS 65536.0

#define DEFAULTLIGHTLEVEL	300
#define DEFAULTFALLOFF	1.0f

extern char lightsfilename[1024];

typedef struct
{
	vec3_t	origin;
	vec_t	angle;
	int		light;
	int		style;

	vec_t	falloff;
	vec_t	lightradius;
	vec_t	subbrightness;
	vec_t	lightoffset;
	vec3_t	color;
	vec3_t	spotdir;
	vec_t	spotcone;
} directlight_t;

typedef struct lightchain_s
{
	directlight_t *light;
	struct lightchain_s *next;
} lightchain_t;

typedef struct
{
	qboolean	startSolid;
	vec_t		fraction;
	vec3_t		impact;
	vec3_t		filter;
	plane_t	plane;
} lightTrace_t;

int Light_PointContents( vec3_t p );
qboolean Light_TraceLine (lightTrace_t *trace, vec3_t start, vec3_t end);

void LightFace (dface_t *f, lightchain_t *lightchain, directlight_t **novislight, int novislights, vec3_t faceorg);
void LightLeaf (dleaf_t *leaf);

void MakeTnodes (dmodel_t *bm);

extern	int		c_occluded;
extern	int		c_culldistplane, c_proper;

extern qboolean relight;

#define MAP_DIRECTLIGHTS	MAX_MAP_ENTITIES

extern int num_directlights;
extern directlight_t directlights[MAP_DIRECTLIGHTS];

extern int extrasamplesbit; // power of 2 extra sampling (0 = 1x1 sampling, 1 = 2x2 sampling, 2 = 4x4 sampling, etc)
extern vec_t extrasamplesscale; // 1.0 / pointspersample (extrasamples related)
extern vec_t globallightscale;
