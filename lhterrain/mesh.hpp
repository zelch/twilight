
#ifndef MESH_HPP
#define MESH_HPP

class Mesh
{
protected:
	void ResizeVertices(int newmax);
	void ResizeTriangles(int newmax);
	float *array_edgeerror;
	int *array_edgesortindex;
	float EdgeErrorMetric(float *v1, float *v2);
	int EdgeCompare(int e1, int e2);
	void CompileTangentVectors(void);
	void CompileTriangleNeighbors(void);
public:
	int num_triangles;
	int max_triangles;
	int *array_element3i;
	int *array_neighbor3i;

	int num_vertices;
	int max_vertices;
	float *array_vertex3f;
	float *array_svector3f;
	float *array_tvector3f;
	float *array_normal3f;
	float *array_texcoord2f;
	int *array_textureblendindex2i;
	float *array_textureblendfactor1f;

	Mesh();
	~Mesh();

	int AddVertex(float x, float y, float z, float nx, float ny, float nz, float s, float t, int tex1, int tex2, float texfactor);
	int AddTriangle(int a, int b, int c);

	void Compile(void);
	void CollapseEdges(float tolerance);
};

#endif
