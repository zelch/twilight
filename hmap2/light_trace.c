// trace.c

#include "light.h"

typedef struct
{
	int		type;
	vec3_t	normal;
	vec_t	dist;
	int		children[2];
} tnode_t;

tnode_t		*tnodes, *tnode_p;

/*
==============
MakeTnode

Converts the disk node structure into the efficient tracing structure
==============
*/
void MakeTnode (int nodenum)
{
	tnode_t			*t;
	dplane_t		*plane;
	int				i;
	dnode_t 		*node;
	
	t = tnode_p++;

	node = dnodes + nodenum;
	plane = dplanes + node->planenum;

	t->type = plane->type;
	VectorCopy (plane->normal, t->normal);
	t->dist = plane->dist;

	for (i=0 ; i<2 ; i++)
	{
		if (node->children[i] < 0)
			t->children[i] = dleafs[-node->children[i] - 1].contents;
		else
		{
			t->children[i] = tnode_p - tnodes;
			MakeTnode (node->children[i]);
		}
	}
			
}


/*
=============
MakeTnodes

Loads the node structure out of a .bsp file to be used for light occlusion
=============
*/
void MakeTnodes (dmodel_t *bm)
{
	tnodes = qmalloc((numnodes/*+1*/) * sizeof(tnode_t));
//	tnodes = (tnode_t *)(((int)tnodes + 31) & ~31);
	tnode_p = tnodes;

	MakeTnode (0);
}



/*
==============================================================================

LINE TRACING

The major lighting operation is a point to point visibility test, performed
by recursive subdivision of the line by the BSP tree.

==============================================================================
*/

int Light_PointContents( vec3_t p )
{
	vec_t		d;
	tnode_t		*tnode;
	int			num = 0;

	while( num >= 0 ) {
		tnode = tnodes + num;
		if( tnode->type < 3 )
			d = p[tnode->type] - tnode->dist;
		else
			d = DotProduct( tnode->normal, p ) - tnode->dist;
		num = tnode->children[(d < 0)];
	}

	return num;
}

#define TESTLINESTATE_BLOCKED 0
#define TESTLINESTATE_EMPTY 1
#define TESTLINESTATE_SOLID 2

/*
==============
TestLine
==============
*/
// LordHavoc: TestLine returns true if there is no impact,
// see below for precise definition of impact (important)
lightTrace_t *trace_trace;

static int RecursiveTestLine (int num, float p1f, float p2f, vec3_t p1, vec3_t p2)
{
	int			side, ret;
	vec_t		t1, t2, frac, midf;
	vec3_t		mid;
	tnode_t		*tnode;

	// LordHavoc: this function operates by doing depth-first front-to-back
	// recursion through the BSP tree, checking at every split for an empty to solid
	// transition (impact) in the children, and returns false if one is found

	// LordHavoc: note: 'no impact' does not mean it is empty, it occurs when there
	// is no transition from empty to solid; all solid or a transition from solid
	// to empty are not considered impacts. (this does mean that tracing is not
	// symmetrical; point A to point B may have different results than point B to
	// point A, if either start in solid)

	// check for empty
loc0:
	if (num < 0)
	{
		if (!trace_trace->startcontents)
			trace_trace->startcontents = num;
		trace_trace->endcontents = num;
		if (num == CONTENTS_SOLID || num == CONTENTS_SKY)
		{
//			VectorClear( trace_trace->filter );
			return TESTLINESTATE_SOLID;
		}
		else if (num == CONTENTS_WATER)
		{
//			trace_trace->filter[0] *= 0.6;
//			trace_trace->filter[1] *= 0.6;
		}
		else if (num == CONTENTS_LAVA)
		{
//			trace_trace->filter[1] *= 0.6;
//			trace_trace->filter[2] *= 0.6;
		}
		return TESTLINESTATE_EMPTY;
	}

	// find the point distances
	tnode = tnodes + num;

	if (tnode->type < 3)
	{
		t1 = p1[tnode->type] - tnode->dist;
		t2 = p2[tnode->type] - tnode->dist;
	}
	else
	{
		t1 = DotProduct (tnode->normal, p1) - tnode->dist;
		t2 = DotProduct (tnode->normal, p2) - tnode->dist;
	}

	if (t1 >= 0)
	{
		if (t2 >= 0)
		{
			num = tnode->children[0];
			goto loc0;
		}
		side = 0;
	}
	else
	{
		if (t2 < 0)
		{
			num = tnode->children[1];
			goto loc0;
		}
		side = 1;
	}

	frac = t1 / (t1 - t2);
	if (frac < 0)
		frac = 0;
	if (frac > 1)
		frac = 1;

	midf = p1f + (p2f - p1f) * frac;
	mid[0] = p1[0] + frac * (p2[0] - p1[0]);
	mid[1] = p1[1] + frac * (p2[1] - p1[1]);
	mid[2] = p1[2] + frac * (p2[2] - p1[2]);

	// front side first
	ret = RecursiveTestLine (tnode->children[side], p1f, midf, p1, mid);
	if (ret != TESTLINESTATE_EMPTY)
		return ret; // solid or blocked

	ret = RecursiveTestLine (tnode->children[!side], midf, p2f, mid, p2);
	if (ret != TESTLINESTATE_SOLID)
		return ret; // empty or blocked

	if (!side)
	{
		VectorCopy (tnode->normal, trace_trace->plane.normal);
		trace_trace->plane.dist = tnode->dist;
		trace_trace->plane.type = tnode->type;
	}
	else
	{
		VectorNegate (tnode->normal, trace_trace->plane.normal);
		trace_trace->plane.dist = -tnode->dist;
		trace_trace->plane.type = PLANE_ANYX;
	}

	trace_trace->fraction = midf;
	VectorCopy( mid, trace_trace->impact );

	return TESTLINESTATE_BLOCKED;
}

qboolean Light_TraceLine (lightTrace_t *trace, vec3_t start, vec3_t end)
{
	static plane_t nullplane;

	if (!trace)
		return false;

	trace_trace = trace;
	trace_trace->fraction = 1.0;
	trace_trace->plane = nullplane;
	trace_trace->startcontents = 0;
	trace_trace->endcontents = 0;
	VectorSet (trace_trace->filter, 1, 1, 1);
	VectorCopy (end, trace_trace->impact);

	return ( RecursiveTestLine( 0, 0, 1, start, end ) != TESTLINESTATE_BLOCKED );
}
