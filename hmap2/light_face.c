
#include "light.h"

/*
===============================================================================

SAMPLE POINT DETERMINATION

void SetupBlock (dface_t *f) Returns with point[] set

This is a little tricky because the lightmap covers more area than the face.
If done in the straightforward fashion, some of the
sample points will be inside walls or on the other side of walls, causing
false shadows and light bleeds.

To solve this, I only consider a sample point valid if a line can be drawn
between it and the exact midpoint of the face.  If invalid, it is adjusted
towards the center until it is valid.

(this doesn't completely work)

===============================================================================
*/

// LordHavoc: increased from 18x18 samples to 256x256 samples
#define SINGLEMAP (256*256)

typedef struct
{
	vec3_t		v;
	qboolean	occluded;
	int			samplepos; // the offset into the lightmap that this point contributes to
} lightpoint_t;

typedef struct
{
	vec3_t c;
} lightsample_t;

typedef struct
{
	vec_t			facedist;
	vec3_t			facenormal;

	int				numpoints;
	int				numsamples;
	// *32 for -extra8x8
//	lightpoint_t	point[SINGLEMAP*64];
	lightpoint_t	*point;
	lightsample_t	sample[MAXLIGHTMAPS][SINGLEMAP];

	vec3_t			texorg;
	vec3_t			worldtotex[2];	// s = (world - texorg) . worldtotex[0]
	vec3_t			textoworld[2];	// world = texorg + s * textoworld[0]

	vec_t			exactmins[2], exactmaxs[2];

	int				texmins[2], texsize[2];
	int				lightstyles[MAXLIGHTMAPS];
	dface_t			*face;
} lightinfo_t;

//#define BUGGY_TEST

/*
================
CalcFaceVectors

Fills in texorg, worldtotex. and textoworld
================
*/
void CalcFaceVectors (lightinfo_t *l, vec3_t faceorg)
{
	texinfo_t	*tex;
	int			i, j;
	vec3_t	texnormal;
	vec_t	distscale;
	vec_t	dist, len;

	tex = &texinfo[l->face->texinfo];

// convert from float to vec_t
	for (i=0 ; i<2 ; i++)
		for (j=0 ; j<3 ; j++)
			l->worldtotex[i][j] = tex->vecs[i][j];

// calculate a normal to the texture axis.  points can be moved along this
// without changing their S/T
	// LordHavoc: this is actually a CrossProduct
	texnormal[0] = tex->vecs[1][1]*tex->vecs[0][2] - tex->vecs[1][2]*tex->vecs[0][1];
	texnormal[1] = tex->vecs[1][2]*tex->vecs[0][0] - tex->vecs[1][0]*tex->vecs[0][2];
	texnormal[2] = tex->vecs[1][0]*tex->vecs[0][1] - tex->vecs[1][1]*tex->vecs[0][0];
	VectorNormalize (texnormal);

// flip it towards plane normal
	distscale = DotProduct (texnormal, l->facenormal);
	if (!distscale)
		Error ("Texture axis perpendicular to face");
	if (distscale < 0)
	{
		distscale = -distscale;
		VectorNegate (texnormal, texnormal);
	}

// distscale is the ratio of the distance along the texture normal to
// the distance along the plane normal
	distscale = 1/distscale;

	for (i=0 ; i<2 ; i++)
	{
		len = VectorLength (l->worldtotex[i]);
		dist = DotProduct (l->worldtotex[i], l->facenormal);
		dist *= distscale;
		VectorMA (l->worldtotex[i], -dist, texnormal, l->textoworld[i]);
		VectorScale (l->textoworld[i], (1/len)*(1/len), l->textoworld[i]);
	}


// calculate texorg on the texture plane
	for (i=0 ; i<3 ; i++)
		l->texorg[i] = -tex->vecs[0][3] * l->textoworld[0][i] - tex->vecs[1][3] * l->textoworld[1][i];

	VectorAdd(l->texorg, faceorg, l->texorg);

// project back to the face plane
	dist = DotProduct (l->texorg, l->facenormal) - l->facedist - 1;
	dist *= distscale;
	VectorMA (l->texorg, -dist, texnormal, l->texorg);
}

/*
================
CalcFaceExtents

Fills in s->texmins[] and s->texsize[]
also sets exactmins[] and exactmaxs[]
================
*/
void CalcFaceExtents (lightinfo_t *l)
{
	dface_t *s;
	vec_t	mins[2], maxs[2], val;
	int		i,j, e;
	dvertex_t	*v;
	texinfo_t	*tex;

	s = l->face;

	mins[0] = mins[1] = BOGUS_RANGE;
	maxs[0] = maxs[1] = -BOGUS_RANGE;

	tex = &texinfo[s->texinfo];

	for (i=0 ; i<s->numedges ; i++)
	{
		e = dsurfedges[s->firstedge+i];
		if (e >= 0)
			v = dvertexes + dedges[e].v[0];
		else
			v = dvertexes + dedges[-e].v[1];

		for (j=0 ; j<2 ; j++)
		{
			val = v->point[0] * tex->vecs[j][0] +
				v->point[1] * tex->vecs[j][1] +
				v->point[2] * tex->vecs[j][2] +
				tex->vecs[j][3];
			if (val < mins[j])
				mins[j] = val;
			if (val > maxs[j])
				maxs[j] = val;
		}
	}

	for (i=0 ; i<2 ; i++)
	{
		l->exactmins[i] = mins[i];
		l->exactmaxs[i] = maxs[i];

		mins[i] = floor(mins[i]/16);
		maxs[i] = ceil(maxs[i]/16);

		l->texmins[i] = mins[i];
		l->texsize[i] = maxs[i] + 1 - mins[i];
		if (l->texsize[i] > 256) // LordHavoc: was 17, much much bigger allowed now
			Error ("Bad surface extents");
	}
}

void CalcSamples (lightinfo_t *l)
{
	/*
	int				i, mapnum;
	lightsample_t	*sample;
	*/

	l->numsamples = l->texsize[0] * l->texsize[1];
	// no need to clear because the lightinfo struct was cleared already
	/*
	for (mapnum = 0;mapnum < MAXLIGHTMAPS;mapnum++)
	{
		for (i = 0, sample = l->sample[mapnum];i < l->numsamples;i++, sample++)
		{
			sample->c[0] = 0;
			sample->c[1] = 0;
			sample->c[2] = 0;
		}
	}
	*/
}

/*
=================
CalcPoints

For each texture aligned grid point, back project onto the plane
to get the world xyz value of the sample point
=================
*/
//int c_bad;
void CalcPoints (lightinfo_t *l)
{
	int j, s, t, w, h, realw, realh, stepbit;
	vec_t starts, startt, us, ut, mids, midt;
	vec3_t facemid, base;
#ifndef BUGGY_TEST
	vec3_t			v;
#else
	int i;
#endif
	lightTrace_t	tr;
	lightpoint_t	*point;

//
// fill in point array
// the points are biased towards the center of the surface
// to help avoid edge cases just inside walls
//
	mids = (l->exactmaxs[0] + l->exactmins[0]) * 0.5;
	midt = (l->exactmaxs[1] + l->exactmins[1]) * 0.5;

	VectorAdd( l->texorg, l->facenormal, base );

	for (j = 0;j < 3;j++)
		facemid[j] = base[j] + l->textoworld[0][j] * mids + l->textoworld[1][j] * midt;

	realw = l->texsize[0];
	realh = l->texsize[1];
	starts = l->texmins[0] * 16;
	startt = l->texmins[1] * 16;

	stepbit = 4 - extrasamplesbit;

	w = realw << extrasamplesbit;
	h = realh << extrasamplesbit;

	if (stepbit < 4)
	{
		starts -= 1 << stepbit;
		startt -= 1 << stepbit;
	}

	point = l->point;
	l->numpoints = w * h;
	for (t = 0;t < h;t++)
	{
		for (s = 0;s < w;s++, point++)
		{
			us = starts + (s << stepbit);
			ut = startt + (t << stepbit);
			point->occluded = false;
			point->samplepos = (t >> extrasamplesbit) * realw + (s >> extrasamplesbit);

#ifndef BUGGY_TEST
			// calculate texture point
			for (j = 0;j < 3;j++)
				point->v[j] = base[j] + l->textoworld[0][j] * us + l->textoworld[1][j] * ut;

			if( !Light_TraceLine( &tr, facemid, point->v ) ) {
				// test failed, adjust to nearest position
				VectorCopy(tr.impact, point->v);
				VectorSubtract(facemid, point->v, v);
				VectorNormalize(v);
				VectorMA(point->v, 0.5, v, point->v);

				if( Light_PointContents( point->v ) == CONTENTS_SOLID ) {
					c_occluded++;
					point->occluded = true;
				}
			}

			//VectorSubtract(facemid, point->v, v);
			//VectorNormalize(v);
			//VectorMA(point->v, 0.25, v, point->v);
#else
			// if a line can be traced from point to facemid, the point is good
			for (i = 0;i < 6;i++)
			{
				// calculate texture point
				for (j = 0;j < 3;j++)
					point->v[j] = base[j] + l->textoworld[0][j] * us + l->textoworld[1][j] * ut;

				if (!Light_TraceLine (&tr, facemid, point->v))
					break;	// got it

				if (i & 1)
				{
					if (us > mids)
					{
						us -= 8;
						if (us < mids)
							us = mids;
					}
					else
					{
						us += 8;
						if (us > mids)
							us = mids;
					}
				}
				else
				{
					if (ut > midt)
					{
						ut -= 8;
						if (ut < midt)
							ut = midt;
					}
					else
					{
						ut += 8;
						if (ut > midt)
							ut = midt;
					}
				}
			}
			//if (i == 2)
			//	c_bad++;
#endif
		}
	}
}


/*
===============================================================================

FACE LIGHTING

===============================================================================
*/

int		c_culldistplane, c_proper;

int SingleLightFace_FindMapNum(lightinfo_t *l, int style)
{
	int mapnum;
	for (mapnum = 0;mapnum < MAXLIGHTMAPS;mapnum++)
	{
		if (l->lightstyles[mapnum] == style)
			break;
		if (l->lightstyles[mapnum] == 255)
		{
			if (relight)
				return MAXLIGHTMAPS;
			// cleared already
			//memset(l->sample[mapnum], 0, sizeof(lightsample_t) * l->numsamples);
			l->lightstyles[mapnum] = style;
			break;
		}
	}

	if (mapnum == MAXLIGHTMAPS)
		printf ("WARNING: Too many light styles on a face\n");
	return mapnum;
}

void SingleLightFace_Sun (directlight_t *light, lightinfo_t *l)
{
	vec_t			shade;
	vec3_t			testpos, c;
	int				mapnum;
	int				i;
	lightpoint_t	*point;
	lightsample_t	*sample;
	lightTrace_t	tr;

	// ignore backfaces
	shade = -DotProduct (light->spotdir, l->facenormal);
	if (shade <= 0)
		return;
	// LordHavoc: FIXME: decide this 0.5 bias based on shader properties (some are dull, some are shiny)
	shade = (shade * 0.5 + 0.5);

	// mapnum won't be allocated until some light hits the surface
	mapnum = -1;
	c_proper++;

	for (i = 0, point = l->point;i < l->numpoints;i++, point++)
	{
		// LordHavoc: changed to be more realistic (entirely different lighting model)
		// LordHavoc: FIXME: use subbrightness on all lights, simply to have some distance culling
		VectorMA(point->v, 131072, light->spotdir, testpos);
		// if trace hits solid don't cast sun
		if (point->occluded || (!Light_TraceLine(&tr, point->v, testpos) && tr.endcontents == CONTENTS_SOLID))
			continue;

		c[0] = shade * light->color[0] * tr.filter[0];
		c[1] = shade * light->color[1] * tr.filter[1];
		c[2] = shade * light->color[2] * tr.filter[2];

		// ignore colors too dim
		if (DotProduct(c, c) < (1.0 / 32.0))
			continue;

		// if there is some light, alloc a style for it
		if (mapnum < 0)
			if ((mapnum = SingleLightFace_FindMapNum(l, light->style)) >= MAXLIGHTMAPS)
				return;

		// accumulate the lighting
		sample = &l->sample[mapnum][point->samplepos];
		VectorMA(sample->c, extrasamplesscale, c, sample->c);
	}
}

/*
================
SingleLightFace
================
*/
void SingleLightFace (directlight_t *light, lightinfo_t *l)
{
	vec_t			dist, idist, dist2, dist3, rad2;
	vec3_t			incoming, c;
	vec_t			add;
	int				mapnum;
	int				i;
	lightpoint_t	*point;
	lightsample_t	*sample;
	lightTrace_t	tr;

	if (light->type == LIGHTTYPE_SUN)
	{
		SingleLightFace_Sun(light, l);
		return;
	}

	dist = (DotProduct (light->origin, l->facenormal) - l->facedist);

// don't bother with lights behind the surface
	if (dist < 0)
		return;

// don't bother with light too far away
	if (dist > light->radius)
	{
		c_culldistplane++;
		return;
	}

	// mapnum won't be allocated until some light hits the surface
	mapnum = -1;
	c_proper++;

	for (i = 0, point = l->point;i < l->numpoints;i++, point++)
	{
		VectorSubtract (light->origin, point->v, incoming);
		dist = sqrt(DotProduct(incoming, incoming));
		if (!dist || dist > light->radius)
			continue;
		idist = 1.0 / dist;
		VectorScale( incoming, idist, incoming );

		// spotlight
		if (light->spotcone && DotProduct (light->spotdir, incoming) > light->spotcone)
			continue;

		//printf("light->type %i\n", light->type);
		dist2 = dist / light->radius;
		dist3 = dist / light->clampradius;
		rad2 = light->clampradius / light->radius;
		switch(light->type)
		{
		case LIGHTTYPE_MINUSX:  add = (1.0 - (dist2        )) - (1.0 - (rad2       )) * dist3;break;
		case LIGHTTYPE_MINUSXX: add = (1.0 - (dist2 * dist2)) - (1.0 - (rad2 * rad2)) * dist3;break;
		case LIGHTTYPE_RECIPX:  add = (1.0 / (dist2        )) - (1.0 / (rad2       )) * dist3;break;
		case LIGHTTYPE_RECIPXX: add = (1.0 / (dist2 * dist2)) - (1.0 / (rad2 * rad2)) * dist3;break;
		//case LIGHTTYPE_RECIPXX: add = (1.0 / ((light->distbias + dist) * (light->distbias + dist)) * (light->distscale * light->distscale)) - (1.0 / (((light->distbias + light->radius) * (light->distbias + light->radius)) * (light->distscale * light->distscale))) * (dist / light->radius);break;
		default: add = 1.0;break;
		}

		if (add <= 0 || point->occluded || !Light_TraceLine(&tr, point->v, light->origin) || tr.startcontents == CONTENTS_SOLID)
			continue;

		// LordHavoc: FIXME: decide this 0.5 bias based on shader properties (some are dull, some are shiny)
		add = add * (DotProduct (incoming, l->facenormal) * 0.5 + 0.5);
		c[0] = add * light->color[0] * tr.filter[0];
		c[1] = add * light->color[1] * tr.filter[1];
		c[2] = add * light->color[2] * tr.filter[2];

		// ignore colors too dim
		if (DotProduct(c, c) < (1.0 / 32.0))
			continue;

		// if there is some light, alloc a style for it
		if (mapnum < 0)
			if ((mapnum = SingleLightFace_FindMapNum(l, light->style)) >= MAXLIGHTMAPS)
				return;

		// accumulate the lighting
		sample = &l->sample[mapnum][point->samplepos];
		VectorMA(sample->c, extrasamplesscale, c, sample->c);
	}
}

int ranout = false;

/*
============
LightFace
============
*/
lightinfo_t l; // if this is made multithreaded again, this should be inside the function, but be warned, it's currently 38mb
void LightFace (dface_t *f, lightchain_t *lightchain, directlight_t **novislight, int novislights, vec3_t faceorg)
{
	int				i, j, size;
	int				red, green, blue, white;
	byte			*out, *lit;
	lightsample_t	*sample;

	//memset (&l, 0, sizeof(l));
	l.face = f;
	if( !l.point )
		l.point = qmalloc(sizeof(lightpoint_t) * SINGLEMAP * (1<<extrasamplesbit)*(1<<extrasamplesbit) );

//
// some surfaces don't need lightmaps
//

	if (relight)
	{
		if (f->lightofs == -1)
			return;
	}
	else
	{
		for (i = 0;i < MAXLIGHTMAPS;i++)
			f->styles[i] = l.lightstyles[i] = 255;
		f->lightofs = -1;

		if (texinfo[f->texinfo].flags & TEX_SPECIAL)
		{
			// non-lit texture
			return;
		}
	}

//
// rotate plane
//
	VectorCopy (dplanes[f->planenum].normal, l.facenormal);
	l.facedist = dplanes[f->planenum].dist;
	if (f->side)
	{
		VectorNegate (l.facenormal, l.facenormal);
		l.facedist = -l.facedist;
	}

	CalcFaceVectors (&l, faceorg);
	CalcFaceExtents (&l);
	CalcSamples (&l);
	CalcPoints (&l);

	if (l.numsamples > SINGLEMAP)
		Error ("Bad lightmap size");

	// clear all the samples to 0
	for (i = 0;i < MAXLIGHTMAPS;i++)
		memset(l.sample[i], 0, sizeof(lightsample_t) * l.numsamples);

	// if -minlight or -ambientlight is used we always allocate style 0
	if (minlight > 0 || ambientlight > 0)
		l.lightstyles[0] = 0;

	if (relight)
	{
		// reserve the correct light styles
		for (i = 0;i < MAXLIGHTMAPS;i++)
			l.lightstyles[i] = f->styles[i];
	}

//
// cast all lights
//
	while (lightchain)
	{
		SingleLightFace (lightchain->light, &l);
		lightchain = lightchain->next;
	}
	while (novislights--)
		SingleLightFace (*novislight++, &l);

	// apply ambientlight if needed
	if (ambientlight > 0)
		for (i = 0;i < l.numsamples;i++)
			for (j = 0;j < 3;j++)
				l.sample[0][i].c[j] += ambientlight;

	// apply minlight if needed
	if (minlight > 0)
		for (i = 0;i < l.numsamples;i++)
			for (j = 0;j < 3;j++)
				if (l.sample[0][i].c[j] < minlight)
					l.sample[0][i].c[j] = minlight;

// save out the values

	if (relight)
	{
		// relighting an existing map without changing it's lightofs table

		for (i = 0;i < MAXLIGHTMAPS;i++)
			if (f->styles[i] == 255)
				break;
		size = l.numsamples * i;

		if (f->lightofs < 0 || f->lightofs + size > lightdatasize)
			Error("LightFace: Error while trying to relight map: invalid lightofs value, %i must be >= 0 && < %i\n", f->lightofs, lightdatasize);
	}
	else
	{
		// creating lightofs table from scratch

		for (i = 0;i < MAXLIGHTMAPS;i++)
			if (l.lightstyles[i] == 255)
				break;
		size = l.numsamples * i;

		if (!size)
		{
			// no light styles
			return;
		}

		if (lightdatasize + size > MAX_MAP_LIGHTING)
		{
			//Error("LightFace: ran out of lightmap dataspace");
			if (!ranout)
				printf("LightFace: ran out of lightmap dataspace");
			ranout = true;
			return;
		}

		for (i = 0;i < MAXLIGHTMAPS;i++)
			f->styles[i] = l.lightstyles[i];

		f->lightofs = lightdatasize;
		lightdatasize += size;
	}

	rgblightdatasize = lightdatasize * 3;

	out = dlightdata + f->lightofs;
	lit = drgblightdata + f->lightofs * 3;

	for (i = 0;i < MAXLIGHTMAPS && f->styles[i] != 255;i++)
	{
		for (j = 0, sample = l.sample[i];j < l.numsamples;j++, sample++)
		{
			red   = (int) sample->c[0];
			green = (int) sample->c[1];
			blue  = (int) sample->c[2];
			white = (int) ((sample->c[0] + sample->c[1] + sample->c[2]) * (1.0 / 3.0));
			if (red > 255) red = 255;
			if (red < 0) red = 0;
			if (green > 255) green = 255;
			if (green < 0) green = 0;
			if (blue > 255) blue = 255;
			if (blue < 0) blue = 0;
			if (white > 255) white = 255;
			if (white < 0) white = 0;
			*lit++ = red;
			*lit++ = green;
			*lit++ = blue;
			*out++ = white;
		}
	}
}

