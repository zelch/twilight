// mathlib.c -- math primitives

#include "cmdlib.h"
#include "mathlib.h"

vec3_t vec3_origin = {0,0,0};
/*
vec_t VectorNormalize (vec3_t v)
{
  int		i;
  double	length = sqrt((v[0]*v[0]) + (v[1]*v[1]) + (v[2]*v[2]));

  if (!length)
    return 0;

  for (i=0 ; i< 3; i++)
    v[i] /= length;

  return length;
}
*/

double ColorNormalize(vec3_t v, vec3_t n)
{
	double vn_length, ilength;
	vn_length = v[0];
	if (vn_length < v[1])
		vn_length = v[1];
	if (vn_length < v[2])
		vn_length = v[2];
	ilength = 0;
	if (vn_length != 0)
		ilength = 1.0 / vn_length;
	n[0] = v[0] * ilength;
	n[1] = v[1] * ilength;
	n[2] = v[2] * ilength;
	return vn_length;
}




