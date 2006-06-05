
#include <stdlib.h>
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
		ResizeVertices(max_vertices < 256 ? 256 : max_vertices * 2);
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
		ResizeTriangles(max_vertices < 256 ? 256 : max_vertices * 2);
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
	ResizeVertices(num_vertices);
	ResizeTriangles(num_triangles);
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

*/

// this implementation is TEMPORARY and simply returns the edge length, squared
// a better metric would take into account the flatness of the edge (surface normal comparison between the two triangles using the edge)
// and I should spend some time researching Quadric Error Metrics as those seem to be considered the best
float Mesh::EdgeErrorMetric(float *v1, float *v2)
{
	float diff[3];
	diff[0] = v2[0] - v1[0];
	diff[1] = v2[1] - v1[1];
	diff[2] = v2[2] - v1[2];
	return (diff[0] * diff[0] + diff[1] * diff[1] + diff[2] * diff[2]);
}

// semi-qsort-style comparison function for edge sorting
int Mesh::EdgeCompare(int e1, int e2)
{
	if (array_edgeerror[e1] > array_edgeerror[e2])
		return 1;
	if (array_edgeerror[e1] < array_edgeerror[e2])
		return -1;
	return e1 - e2;
}

void Mesh::CollapseEdges(float tolerance)
{
	int i, j;
	array_edgeerror = (float *)malloc(num_triangles * 3 * sizeof(float));
	array_edgesortindex = (int *)malloc(num_triangles * 3 * sizeof(int));
	// we need the triangle neighbors for edge information
	CompileTriangleNeighbors();
	// compute edge error metrics
	for (i = 0;i < num_triangles;i++)
	{
		array_edgeerror[i * 3 + 0] = Mesh::EdgeErrorMetric(array_vertex3f + 3 * array_element3i[i * 3 + 0], array_vertex3f + 3 * array_element3i[i * 3 + 1]);
		array_edgeerror[i * 3 + 1] = Mesh::EdgeErrorMetric(array_vertex3f + 3 * array_element3i[i * 3 + 1], array_vertex3f + 3 * array_element3i[i * 3 + 2]);
		array_edgeerror[i * 3 + 2] = Mesh::EdgeErrorMetric(array_vertex3f + 3 * array_element3i[i * 3 + 2], array_vertex3f + 3 * array_element3i[i * 3 + 0]);
		array_edgesortindex[i * 3 + 0] = i * 3 + 0;
		array_edgesortindex[i * 3 + 1] = i * 3 + 1;
		array_edgesortindex[i * 3 + 2] = i * 3 + 2;
	}
	// selection sort of the edge error metrics (could use qsort instead but the edgesortindex array would have to contain edgeerror data as qsort does not allow multiple data parameters to the compare function)
	// prefer lowest error metric first, then border edges at the end of the array
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
		if (array_edgeerror[array_edgesortindex[0]] > tolerance)
			break;
		// don't collapse an edge if one or both of its endpoints lie along a border that is perpendicular to it (if it is a boedge edge itself it is fine to collapse, but not if it is an interior edge with a border endpoint)
		// TODO: how to check for this?
		// we have accepted this edge as a valid one to collapse
		// TODO: code this

		// if there is a far-side triangle, collapse it first
		if (array_neighbor3i[array_edgesortindex[0]] >= 0)
		{
			// there is a far side triangle, so collapse it
		}

		// now collapse this triangle
	}
	free(array_edgeerror);array_edgeerror = NULL;
	free(array_edgesortindex);array_edgesortindex = NULL;
}

