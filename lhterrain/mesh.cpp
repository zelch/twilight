
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include "mesh.hpp"

Mesh::Mesh()
{
	// TODO: clear fields?
	num_vertices = 0;
	max_vertices = 0;
	num_triangles = 0;
	max_triangles = 0;
}

Mesh::~Mesh()
{
}

void Mesh::ResizeVertices(int newmax)
{
	max_vertices = newmax;
	array_vertex3f = (float *)realloc(array_vertex3f, max_vertices * sizeof(float[3]));
	array_svector3f = (float *)realloc(array_svector3f, max_vertices * sizeof(float[3]));
	array_tvector3f = (float *)realloc(array_tvector3f, max_vertices * sizeof(float[3]));
	array_normal3f = (float *)realloc(array_normal3f, max_vertices * sizeof(float[3]));
	array_texcoord2f = (float *)realloc(array_texcoord2f, max_vertices * sizeof(float[2]));
	array_textureblendindex2i = (int *)realloc(array_textureblendindex2i, max_vertices * sizeof(int[2]));
	array_textureblendfactor1f = (float *)realloc(array_textureblendfactor1f, max_vertices * sizeof(float[1]));
}

void Mesh::ResizeTriangles(int newmax)
{
	max_triangles = newmax;
	array_element3i = (int *)realloc(array_element3i, max_triangles * sizeof(int[3]));
	array_neighbor3i = (int *)realloc(array_neighbor3i, max_triangles * sizeof(int[3]));
}

int Mesh::AddVertex(float x, float y, float z, float nx, float ny, float nz, float s, float t, int tex1, int tex2, float texfactor)
{
	if (max_vertices <= num_vertices)
		ResizeVertices(max_vertices * 2 > 256 ? max_vertices * 2 : 256);
	array_vertex3f[num_vertices*3+0] = x;
	array_vertex3f[num_vertices*3+1] = y;
	array_vertex3f[num_vertices*3+2] = z;
	array_normal3f[num_vertices*3+0] = nx;
	array_normal3f[num_vertices*3+1] = ny;
	array_normal3f[num_vertices*3+2] = nz;
	array_svector3f[num_vertices*3+0] = 0;
	array_svector3f[num_vertices*3+1] = 0;
	array_svector3f[num_vertices*3+2] = 0;
	array_tvector3f[num_vertices*3+0] = 0;
	array_tvector3f[num_vertices*3+1] = 0;
	array_tvector3f[num_vertices*3+2] = 0;
	array_texcoord2f[num_vertices*2+0] = s;
	array_texcoord2f[num_vertices*2+1] = t;
	array_textureblendindex2i[num_vertices*2+0] = tex1;
	array_textureblendindex2i[num_vertices*2+1] = tex2;
	array_textureblendfactor1f[num_vertices*1+0] = texfactor;
	return num_vertices++;
}

int Mesh::AddTriangle(int a, int b, int c)
{
	if (max_triangles <= num_triangles)
		ResizeTriangles(max_triangles * 2 > 256 ? max_triangles * 2 : 256);
	array_element3i[num_triangles*3+0] = a;
	array_element3i[num_triangles*3+1] = b;
	array_element3i[num_triangles*3+2] = c;
	array_neighbor3i[num_triangles*3+0] = -1;
	array_neighbor3i[num_triangles*3+1] = -1;
	array_neighbor3i[num_triangles*3+2] = -1;
	return num_triangles++;
}

void Mesh::CompileTangentVectors(void)
{
	// TODO: code this
}

void Mesh::CompileTriangleNeighbors(void)
{
	int i, j, p, e1, e2, hashindex, count;
	size_t hashsize;
	int match, *n;
	const int *e;
	typedef struct hashentry
	{
		struct hashentry *next;
		unsigned int triangle;
		unsigned int element[2];
	}
	hashentry_t;
	hashentry_t **hashtable, *hashentries, *hash;

	// this is a tweakable parameter
	hashsize = num_vertices*2;

	// allocate the hashtable for fast edge searches
	hashtable = (hashentry_t **)malloc(hashsize * sizeof(hashentry_t *) + num_triangles * 3 * sizeof(hashentry_t));
	hashentries = (hashentry_t *)(hashtable + hashsize);

	// build edge information in the hashtable
	for (i = 0, e = array_element3i, n = array_neighbor3i;i < num_triangles;i++, e += 3, n += 3)
	{
		for (j = 0, p = 2;j < 3;p = j, j++)
		{
			// two vertex indices define an edge
			e1 = e[p];
			e2 = e[j];

			// this hash index works for both forward and backward edges
			hashindex = e1 + e2;
			hash = hashentries + i * 3 + j;
			hash->next = hashtable[hashindex];
			hashtable[hashindex] = hash;
			hash->triangle = i;
			hash->element[0] = e1;
			hash->element[1] = e2;
		}
	}

	// look up neighboring triangles by finding matching edges in the hashtable
	for (i = 0, e = array_element3i, n = array_neighbor3i;i < num_triangles;i++, e += 3, n += 3)
	{
		for (j = 0, p = 2;j < 3;p = j, j++)
		{
			e1 = e[p];
			e2 = e[j];

			// this hash index works for both forward and backward edges
			hashindex = e1 + e2;
			count = 0;
			match = -1;
			for (hash = hashtable[hashindex];hash;hash = hash->next)
			{
				if (hash->element[0] == e2 && hash->element[1] == e1)
				{
					if (hash->triangle != i)
						match = hash->triangle;
					count++;
				}
				else if (hash->element[0] == e1 && hash->element[1] == e2)
					count++;
			}

			// detect edges shared by three triangles and make them seams
			// (this is a rare case but must be handled properly)
			if (count > 2)
				match = -1;
			n[p] = match;
		}
	}

	// free the allocated hashtable
	free(&hashtable);
}

void Mesh::Compile(void)
{
	int i, j, n;
	char *vertexused;

	// modify the arrays to remove any degenerate triangles
	// (such as those produced by CollapseEdges)
	// note: this corrupts the neighbors array
	n = num_triangles;
	num_triangles = 0;
	for (i = 0;i < n;i++)
		if (array_element3i[i*3+0] == array_element3i[i*3+1] || array_element3i[i*3+1] == array_element3i[i*3+2] || array_element3i[i*3+2] == array_element3i[i*3+0])
			for (j = 0;j < 3;j++)
				array_element3i[num_triangles*3+j] = array_element3i[i*3+j];

	// now check if there are any unused vertices to remove
	vertexused = (char *)calloc(num_vertices, 1);
	for (i = 0;i < num_triangles * 3;i++)
		vertexused[array_element3i[i]] = 1;

	// now remove the unused vertex data
	// note: this does not copy tangent vectors because they are regenerated later
	n = num_vertices;
	num_vertices = 0;
	for (i = 0;i < n;i++)
	{
		if (!vertexused[i])
			continue;
		array_vertex3f[num_vertices*3+0]             = array_vertex3f[i*3+0];
		array_vertex3f[num_vertices*3+1]             = array_vertex3f[i*3+1];
		array_vertex3f[num_vertices*3+2]             = array_vertex3f[i*3+2];
		array_normal3f[num_vertices*3+0]             = array_normal3f[i*3+0];
		array_normal3f[num_vertices*3+1]             = array_normal3f[i*3+1];
		array_normal3f[num_vertices*3+2]             = array_normal3f[i*3+2];
		array_texcoord2f[num_vertices*2+0]           = array_texcoord2f[i*2+0];
		array_texcoord2f[num_vertices*2+1]           = array_texcoord2f[i*2+1];
		array_textureblendindex2i[num_vertices*2+0]  = array_textureblendindex2i[i*2+0];
		array_textureblendindex2i[num_vertices*2+1]  = array_textureblendindex2i[i*2+1];
		array_textureblendfactor1f[num_vertices*1+0] = array_textureblendfactor1f[i*1+0];
		num_vertices++;
	}

	// free the temporary vertexused array
	free(vertexused);

	// resize the arrays to free any wasted space
	ResizeVertices(num_vertices);
	ResizeTriangles(num_triangles);

	// recalculate the tangent vectors and neighbors
	CompileTangentVectors();
	CompileTriangleNeighbors();
}

/*
variables:
*/

/*
Example cases:

simple example:
before:
   +
  / \
 / a \  <- a is the active triangle which will be removed
+--b--+ <- b is the active edge
 \ c /  <- c is the far-side triangle of the active edge, also to be removed
  \ /
   +
after:
   +
   |
   |    <- edge (collapsed triangle a, now one edge)
   +    <- vertex (collapsed edge b)
   |    <- edge (collapsed triangle b, now one edge)
   |
   +

another example:
before:
      +-----+-----+
     / \   / \   / \
    /   \ / a \ /   \
   +-----+--b--+-----+
  / \   / \ c / \   / \
 /   \ /   \ /   \ /   \
+-----+-----+-----+-----+
after:
      +-----+-----+
     /  \   |   /  \
    /     \ | /     \
   +--------+--------+
  / \     / | \     / \
 /   \  /   |   \  /   \
+-----+-----+-----+-----+

another example:
before:
   +-----+-----+
  / \   / \   / \
 /   \ / a \ /   \
+-----+--b--+-----+
after:
   +-----+-----+
  /  \   |   /  \
 /     \ | /     \
+--------+--------+

examples of invalid cases: (these should not be collapsed)
   +-----+-----+
  / \ a / \   / \
 /   \ b   \ /   \
+-----+-----+-----+

   +-----+-----+
  / \   / \   / \
 /   \ b a \ /   \
+-----+-----+-----+

   +-----+-----+
  / \   / \   / \
 b a \ /   \ /   \
+-----+-----+-----+

rule:
if this edge has no far side triangle:
	collapse if this triangle has no other edges without far side triangles
else
	collapse if this edge has no border vertices (neighboring triangles using it as part of a no-far-side edge)
*/

// this implementation can be improved
// a better method would be Quadric Error Metrics
float Mesh::EdgeErrorMetric(int e1, int e2)
{
	float result = 0;
	float *v1 = array_vertex3f + 3 * e1;
	float *v2 = array_vertex3f + 3 * e2;
	float midpoint[3];
	float diff[3];

	// if the edge is deleted, return a REALLY high error value
	if (e1 < 0 || e2 < 0)
		return (float)(1<<30) * 2.0f;

	// simple averaged location, not the best method
	midpoint[0] = (array_vertex3f[e1 * 3 + 0] + array_vertex3f[e2 * 3 + 0]) * 0.5;
	midpoint[1] = (array_vertex3f[e1 * 3 + 1] + array_vertex3f[e2 * 3 + 1]) * 0.5;
	midpoint[2] = (array_vertex3f[e1 * 3 + 2] + array_vertex3f[e2 * 3 + 2]) * 0.5;

	// measure the deviation from the vertex's original position
	diff[0] = midpoint[0] - array_originalvertex3f[e1 * 3 + 0];
	diff[1] = midpoint[1] - array_originalvertex3f[e1 * 3 + 1];
	diff[2] = midpoint[2] - array_originalvertex3f[e1 * 3 + 2];
	result += sqrt(diff[0] * diff[0] + diff[1] * diff[1] + diff[2] * diff[2]);

	// measure the deviation from the vertex's original position
	diff[0] = midpoint[0] - array_originalvertex3f[e2 * 3 + 0];
	diff[1] = midpoint[1] - array_originalvertex3f[e2 * 3 + 1];
	diff[2] = midpoint[2] - array_originalvertex3f[e2 * 3 + 2];
	result += sqrt(diff[0] * diff[0] + diff[1] * diff[1] + diff[2] * diff[2]);

	// add an extremely high error rating if the texture blend can't be merged
	if (array_textureblendindex2i[e1 * 2 + 0] != array_textureblendindex2i[e2 * 2 + 0]
	 || array_textureblendindex2i[e1 * 2 + 1] != array_textureblendindex2i[e2 * 2 + 1])
		result += (float)(1<<30);

	return result;
}

// semi-qsort-style comparison function for edge sorting
int Mesh::EdgeCompare(int e1, int e2)
{
	// sort by edgeerror
	if (array_edgeerror[e1] > array_edgeerror[e2])
		return 1;
	if (array_edgeerror[e1] < array_edgeerror[e2])
		return -1;
	// sort by edge index
	return e1 - e2;
}

#ifndef DotProduct
#define DotProduct(a,b) ((a)[0] * (b)[0] + (a)[1] * (b)[1] + (a)[2] * (b)[2])
#endif
#ifndef Normalize
#define Normalize(n) do{double sum = sqrt(DotProduct((n),(n)));sum = sum ? 1 / sum : 1;(n)[0] *= sum;(n)[1] *= sum;(n)[2] *= sum;}while(0)
#endif

void Mesh::CollapseEdges_CalculateMidPoint(int vertex, int vertex1, int vertex2)
{
	int i, j;
	float f;
	int besttexindex[4];
	float besttexfactor[4];
	// average most arrays
	array_vertex3f[vertex*3+0] = (array_vertex3f[vertex1*3+0] + array_vertex3f[vertex2*3+0]) * 0.5;
	array_vertex3f[vertex*3+1] = (array_vertex3f[vertex1*3+1] + array_vertex3f[vertex2*3+1]) * 0.5;
	array_vertex3f[vertex*3+2] = (array_vertex3f[vertex1*3+2] + array_vertex3f[vertex2*3+2]) * 0.5;
	array_normal3f[vertex*3+0] = (array_normal3f[vertex1*3+0] + array_normal3f[vertex2*3+0]) * 0.5;
	array_normal3f[vertex*3+1] = (array_normal3f[vertex1*3+1] + array_normal3f[vertex2*3+1]) * 0.5;
	array_normal3f[vertex*3+2] = (array_normal3f[vertex1*3+2] + array_normal3f[vertex2*3+2]) * 0.5;
	Normalize(array_normal3f + vertex * 3);
	array_svector3f[vertex*3+0] = (array_svector3f[vertex1*3+0] + array_svector3f[vertex2*3+0]) * 0.5;
	array_svector3f[vertex*3+1] = (array_svector3f[vertex1*3+1] + array_svector3f[vertex2*3+1]) * 0.5;
	array_svector3f[vertex*3+2] = (array_svector3f[vertex1*3+2] + array_svector3f[vertex2*3+2]) * 0.5;
	Normalize(array_svector3f + vertex * 3);
	array_tvector3f[vertex*3+0] = (array_tvector3f[vertex1*3+0] + array_tvector3f[vertex2*3+0]) * 0.5;
	array_tvector3f[vertex*3+1] = (array_tvector3f[vertex1*3+1] + array_tvector3f[vertex2*3+1]) * 0.5;
	array_tvector3f[vertex*3+2] = (array_tvector3f[vertex1*3+2] + array_tvector3f[vertex2*3+2]) * 0.5;
	Normalize(array_tvector3f + vertex * 3);
	array_texcoord2f[vertex*2+0] = (array_texcoord2f[vertex1*2+0] + array_texcoord2f[vertex2*2+0]) * 0.5;
	array_texcoord2f[vertex*2+1] = (array_texcoord2f[vertex1*2+1] + array_texcoord2f[vertex2*2+1]) * 0.5;

	// texture indices can't be averaged, so try to reduce the indices to a smaller set that still describes the blend
	// note this code is probably overkill because the extreme penalty in the error metric usually prevents the need to merge blends
	besttexindex[0] = array_textureblendindex2i[vertex1 * 2 + 0];
	besttexindex[1] = array_textureblendindex2i[vertex2 * 2 + 0];
	besttexindex[2] = array_textureblendindex2i[vertex1 * 2 + 1];
	besttexindex[3] = array_textureblendindex2i[vertex2 * 2 + 1];
	for (i = 0;i < 4;i++)
		besttexfactor[i] = 0;
	// sum the factors
	for (i = 0;i < 4;i++)
		for (j = 0;j <= i;j++)
			if (besttexindex[j] == besttexindex[i])
				besttexfactor[j] += ((i & 1) ? (1 - array_textureblendfactor1f[i >> 1]) : (array_textureblendfactor1f[i >> 1]));
	// do a select sort on the factors
	for (i = 0;i < 4;i++)
	{
		for (j = i + 1;j < 4;j++)
		{
			if (besttexfactor[i] < besttexfactor[j])
			{
				int k = besttexindex[i];
				float f = besttexfactor[i];
				besttexindex[i] = besttexindex[j];
				besttexfactor[i] = besttexfactor[j];
				besttexindex[j] = k;
				besttexfactor[j] = f;
			}
		}
	}
	// now store the two texture indices
	// make sure the indices are in a canonical order to improve consistency
	// (no reason to have indices swapping back and forth based on factors)
	f = besttexfactor[1] + besttexfactor[2] + besttexfactor[3];
	f = f / (besttexfactor[0] + f);
	if (besttexindex[0] < besttexindex[1])
	{
		array_textureblendindex2i[vertex*2+0] = besttexindex[0];
		array_textureblendindex2i[vertex*2+1] = besttexindex[1];
		array_textureblendfactor1f[vertex*1+0] = f;
	}
	else
	{
		array_textureblendindex2i[vertex*2+0] = besttexindex[1];
		array_textureblendindex2i[vertex*2+1] = besttexindex[0];
		array_textureblendfactor1f[vertex*1+0] = 1 - f;
	}
}

bool Mesh::CollapseEdges_RecursiveCheckEdgeVertices(int thistriangle, int vertex1, int vertex2)
{
	int i;
	bool replaced = false;
	int *e;
	// ignore invalid triangle indices
	if (thistriangle < 0)
		return false;
	e = array_element3i + thistriangle * 3;
	for (i = 0;i < 3;i++)
		if (e[i] == vertex1 || e[i] == vertex2)
			break;
	// if this triangle does not use either of the edge vertices then it is of
	// no interest
	if (i == 3)
		return false;
	for (i = 0;i < 3;i++)
	{
		int fartriangle = array_neighbor3i[thistriangle * 3 + i];
		if (fartriangle >= 0)
		{
			if (CollapseEdges_RecursiveCheckEdgeVertices(fartriangle, vertex1, vertex2))
				return true;
		}
		else
			if (e[i] == vertex1 || e[i] == vertex2 || e[(i+1) % 3] == vertex1 || e[(i+1) % 3] == vertex2)
				return true;
	}
	return false;
}

void Mesh::CollapseEdges_RecursiveReplaceVertex(int thistriangle, int oldvertex, int newvertex)
{
	int i;
	bool replaced = false;
	int *e;
	// ignore invalid triangle indices
	if (thistriangle < 0)
		return;
	// see if this triangle uses the oldvertex
	e = array_element3i + thistriangle * 3;
	for (i = 0;i < 3;i++)
	{
		if (e[i] == oldvertex)
		{
			e[i] = newvertex;
			replaced = true;
		}
	}
	// if no match was found, this triangle is not relevant, so just return
	if (!replaced)
		return;
	// update error metrics
	// they will be re-sorted later
	array_edgeerror[thistriangle * 3 + 0] = Mesh::EdgeErrorMetric(array_element3i[thistriangle * 3 + 0], array_element3i[thistriangle * 3 + 1]);
	array_edgeerror[thistriangle * 3 + 1] = Mesh::EdgeErrorMetric(array_element3i[thistriangle * 3 + 1], array_element3i[thistriangle * 3 + 2]);
	array_edgeerror[thistriangle * 3 + 2] = Mesh::EdgeErrorMetric(array_element3i[thistriangle * 3 + 2], array_element3i[thistriangle * 3 + 0]);
	// we have fixed this triangle, now flow into neighbors
	for (i = 0;i < 3;i++)
		CollapseEdges_RecursiveReplaceVertex(array_neighbor3i[thistriangle * 3 + i], oldvertex, newvertex);
}

void Mesh::CollapseEdges_CollapseTriangle(int thistriangle, int othertriangle)
{
	int i, j;
	int side[2];

	// make sure this is a valid triangle index
	// (which allows the caller to be sloppy)
	if (thistriangle < 0)
		return;

	// find out what triangles are beside the triangle
	for (i = 0, j = 0;i < 3;i++)
		if (array_neighbor3i[thistriangle * 3 + i] != othertriangle)
			side[j++] = array_neighbor3i[thistriangle * 3 + i];
	// now that we know which two sides of this triangle to merge, do so
	for (i = 0;i < 2;i++)
	{
		if (side[i] < 0)
			continue;
		// update any references to this triangle to refer to the triangle on
		// the other side instead
		for (j = 0;j < 3;j++)
			if (array_neighbor3i[side[i] * 3 + j] == thistriangle)
				array_neighbor3i[side[i] * 3 + j] = side[i ^ 1];
	}

	// now this triangle no longer exists, but since it would be a real hassle
	// to resize the arrays, just make it a degenerate triangle which can be
	// removed at a later phase
	for (i = 0;i < 3;i++)
	{
		array_element3i[thistriangle * 3 + i] = -1;
		array_neighbor3i[thistriangle * 3 + i] = -1;
		array_edgeerror[thistriangle * 3 + i] = Mesh::EdgeErrorMetric(-1, -1);
	}
}

void Mesh::CollapseEdges(float tolerance)
{
	int i, j;

	array_edgeerror = (float *)malloc(num_triangles * 3 * sizeof(float));
	array_edgesortindex = (int *)malloc(num_triangles * 3 * sizeof(int));
	array_originalvertex3f = (float *)malloc(num_vertices * 3 + sizeof(float));
	memcpy(array_originalvertex3f, array_vertex3f, num_vertices * 3 + sizeof(float));

	// we need the triangle neighbors for edge information
	CompileTriangleNeighbors();

	// compute edge error metrics
	for (i = 0;i < num_triangles;i++)
	{
		array_edgeerror[i * 3 + 0] = Mesh::EdgeErrorMetric(array_element3i[i * 3 + 0], array_element3i[i * 3 + 1]);
		array_edgeerror[i * 3 + 1] = Mesh::EdgeErrorMetric(array_element3i[i * 3 + 1], array_element3i[i * 3 + 2]);
		array_edgeerror[i * 3 + 2] = Mesh::EdgeErrorMetric(array_element3i[i * 3 + 2], array_element3i[i * 3 + 0]);
		array_edgesortindex[i * 3 + 0] = i * 3 + 0;
		array_edgesortindex[i * 3 + 1] = i * 3 + 1;
		array_edgesortindex[i * 3 + 2] = i * 3 + 2;
	}

	// initial selection sort of the edge error metrics (could use qsort instead but the edgesortindex array would have to contain edgeerror data as qsort does not allow multiple data parameters to the compare function)
	// see EdgeCompare code for more details
	for (i = 0;i < num_triangles * 3;i++)
	{
		for (j = i + 1;j < num_triangles * 3;j++)
		{
			if (EdgeCompare(array_edgesortindex[i], array_edgesortindex[j]) > 0)
			{
				int k = array_edgesortindex[i];
				array_edgesortindex[i] = array_edgesortindex[j];
				array_edgesortindex[j] = k;
			}
		}
	}

	// repeatedly pick an edge to collapse from the sorted list until we have a minimal set
	for(;;)
	{
		// don't collapse any more edges if we reached the tolerance
		int thistriangle, fartriangle;
		int vertex1, vertex2;
		int edgeindex;
		int edge;
		for (edgeindex = 0;edgeindex < num_triangles * 3;edgeindex++)
		{
			edge = array_edgesortindex[edgeindex];
			if (array_edgeerror[edge] > tolerance)
			{
				edgeindex = num_triangles * 3;
				break;
			}
			thistriangle = edge / 3;

			//the rule:
			//if this edge has no far side triangle:
			//	collapse if this triangle has no other edges without far side triangles
			//else
			//	collapse if this edge has no border vertices (neighboring triangles using it as part of a no-far-side edge)

			if (array_neighbor3i[edge] < 0)
			{
				int n;
				n = array_neighbor3i[thistriangle * 3 + 0] < 0;
				n += array_neighbor3i[thistriangle * 3 + 1] < 0;
				n += array_neighbor3i[thistriangle * 3 + 2] < 0;
				if (n > 1)
					continue;
			}
			else
			{
				if (CollapseEdges_RecursiveCheckEdgeVertices(thistriangle, vertex1, vertex2))
					continue;
			}
			// we found one we can collapse
			break;
		}

		// if the tolerance was reached, we're done
		if (edgeindex == num_triangles * 3)
			break;

		// we found an edge to collapse
		// set up some index variables
		thistriangle = edge / 3;
		fartriangle = array_neighbor3i[edge];
		vertex1 = array_element3i[edge];
		vertex2 = array_element3i[edge - thistriangle * 3 == 2 ? edge - 2 : edge + 1];

		// modify the two vertices to the midpoint of the edge
		CollapseEdges_CalculateMidPoint(vertex1, vertex1, vertex2);

		// modify all connected triangles referring to vertex2 to instead refer to vertex1
		CollapseEdges_RecursiveReplaceVertex(thistriangle, vertex2, vertex1);

		// if there is a far-side triangle, collapse it
		CollapseEdges_CollapseTriangle(fartriangle, thistriangle);

		// now collapse this triangle
		CollapseEdges_CollapseTriangle(thistriangle, fartriangle);

		// bubble sort the edge error metrics incase any have changed place
		// note: this always has to move the collapsed triangles to the end of the index array
		// note: doing this each triangle is inefficient, but the use of the array_edgesortindex array does not allow backwards referencing of individual indices when the error metrics are changed, so the entire array needs to be checked...
		for (i = 0;i < num_triangles * 3;i++)
		{
			for (j = i;j > 0 && EdgeCompare(array_edgesortindex[j - 1], array_edgesortindex[j]) > 0;j--)
			{
				int k = array_edgesortindex[j - 1];
				array_edgesortindex[j - 1] = array_edgesortindex[j];
				array_edgesortindex[j] = k;
			}
			for (j = i + 1;j < (num_triangles * 3) && EdgeCompare(array_edgesortindex[j - 1], array_edgesortindex[j]) > 0;j++)
			{
				int k = array_edgesortindex[j - 1];
				array_edgesortindex[j - 1] = array_edgesortindex[j];
				array_edgesortindex[j] = k;
			}
		}
	}

	free(array_originalvertex3f);array_originalvertex3f = NULL;
	free(array_edgeerror);array_edgeerror = NULL;
	free(array_edgesortindex);array_edgesortindex = NULL;

	// now recompile the mesh to remove the deleted elements
	Compile();
}

