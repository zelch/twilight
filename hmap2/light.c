// lighting.c

#include "light.h"

/*

NOTES
-----

*/

dmodel_t	*bspmodel;

qboolean	lightvis;
qboolean	relight;
qboolean	verbose;

int			extrasamplesbit; // power of 2 extra sampling (0 = 1x1 sampling, 1 = 2x2 sampling, 2 = 4x4 sampling, etc)
vec_t		extrasamplesscale; // 1.0 / pointspersample (extrasamples related)
vec_t		globallightscale;

// filename to write light list to
char lightsfilename[1024];

byte currentvis[(MAX_MAP_LEAFS + 7) / 8];

int			c_occluded;

int num_directlights;
directlight_t directlights[MAP_DIRECTLIGHTS];

/*
==============================================================================

ENTITY FILE PARSING

If a light has a targetname, generate a unique style in the 32-63 range
==============================================================================
*/

int		numlighttargets;
char	lighttargets[32][128];

int LightStyleForTargetname( char *targetname )
{
	int		i;

	for( i = 0; i < numlighttargets; i++ ) {
		if( !strcmp (lighttargets[i], targetname) )
			return 32 + i;
	}

	if( numlighttargets == 32 )
		Error( "LightStyleForTargetname: numlighttargets == 32" );

	strcpy( lighttargets[numlighttargets], targetname );
	numlighttargets++;
	return numlighttargets - 1 + 32;
}


/*
==================
ParseLightEntities
==================
*/
void ParseLightEntities( void )
{
	int	i, j;
	entity_t *ent;
	char *value, *targetname, *style;
	directlight_t *l;
	double vec[4], color2[3];
	qboolean isLight;

	num_directlights = 0;
	for( i = 0, ent = entities; i < num_entities; i++, ent++ ) {
		value = ValueForKey( ent, "classname" );

		if( strncmp (value, "light", 5) )
			continue;

		if( !strcmp (value, "light") )
			isLight = true;
		else
			isLight = false;

		if( num_directlights == MAP_DIRECTLIGHTS )
			Error( "numdirectlights == MAP_DIRECTLIGHTS" );

		l = &directlights[num_directlights++];
		memset( l, 0, sizeof (*l) );
		color2[0] = color2[1] = color2[2] = 1.0f;
		l->color[0] = l->color[1] = l->color[2] = 1.0f;
		l->lightoffset = LIGHTDISTBIAS;
		GetVectorForKey( ent, "origin", l->origin );

		l->falloff = FloatForKey( ent, "wait" );
		if( !l->falloff )
			l->falloff = DEFAULTFALLOFF;
		l->falloff *= l->falloff; // square it for lighting calculations

		l->lightradius = FloatForKey( ent, "_lightradius" );

		l->style = FloatForKey( ent, "style" );
		if( (unsigned)l->style > 254 )
			Error( "LoadLights: Bad light style %i (must be 0-254)", l->style );

		l->angle = FloatForKey( ent, "angle" );

		value = ValueForKey( ent, "color" );
		if( !value[0] )
			value = ValueForKey( ent, "_color" );
		if( value[0] ) {
			// scan into doubles, then assign
			// which makes it vec_t size independent
			if( sscanf (value, "%lf %lf %lf", &vec[0], &vec[1], &vec[2]) != 3 )
				Error( "LoadEntities: not 3 values for color" );

			// scale the color to have at least one component at 1.0
			vec[3] = vec[0];
			if( vec[1] > vec[3] )
				vec[3] = vec[1];
			if( vec[2] > vec[3] )
				vec[3] = vec[2];
			if( vec[3] != 0.0 )
				vec[3] = 1.0 / vec[3];
			color2[0] = vec[0] * vec[3];
			color2[1] = vec[1] * vec[3];
			color2[2] = vec[2] * vec[3];
		}

		value = ValueForKey( ent, "light" );
		if( !value[0] )
			value = ValueForKey( ent, "_light" );

		if( value[0] ) {
			i = sscanf ( value, "%lf %lf %lf %lf", &vec[0], &vec[1], &vec[2], &vec[3] );

			switch( i ) {
				case 4:// HalfLife light
					l->light = (int)vec[3];
					l->color[0] = vec[0] * (1.0f / 255.0f);
					l->color[1] = vec[1] * (1.0f / 255.0f);
					l->color[2] = vec[2] * (1.0f / 255.0f);
					break;
				case 3:
					l->light = 1;
					l->color[0] = vec[0];
					l->color[1] = vec[1];
					l->color[2] = vec[2];
					break;
				case 1:
					l->light = (int)vec[0];
					l->color[0] = 1.0f;
					l->color[1] = 1.0f;
					l->color[2] = 1.0f;
					break;
				default:
					Error( "LoadEntities: _light (or light) key must be 1 (Quake), 4 (HalfLife), or 3 (HLight) values, \"%s\" is not valid\n", value );
			}
		}

		if( !l->light )
			l->light = DEFAULTLIGHTLEVEL;

		// convert to subtraction to the brightness for the whole light, so it will fade nicely, rather than being clipped off
		l->color[0] *= color2[0] * l->light * /*l->falloff */ 16384.0 * globallightscale;
		l->color[1] *= color2[1] * l->light * /*l->falloff */ 16384.0 * globallightscale;
		l->color[2] *= color2[2] * l->light * /*l->falloff */ 16384.0 * globallightscale;

		if( l->lightradius )
			l->subbrightness = 1.0 / (l->lightradius * l->lightradius * l->falloff + LIGHTDISTBIAS);
		if( l->subbrightness < (1.0 / 1048576.0) )
			l->subbrightness = (1.0 / 1048576.0);

		if( isLight ) {
			value = ValueForKey( ent, "targetname" );

			if( value[0] && !l->style ) {
				char s[16];

				l->style = LightStyleForTargetname( value );

				memset( s, 0, sizeof(s) );
				sprintf( s, "%i", l->style );
				SetKeyValue( ent, "style", s );
			}
		}

		value = ValueForKey( ent, "target" );
		if( !value[0] )
			continue;

		for( j = 0; j < num_entities; j++ ) {
			if( i == j )
				continue;

			targetname = ValueForKey( &entities[j], "targetname" );
			if( !strcmp (targetname, value) ) {
				vec3_t origin;

				GetVectorForKey( &entities[j], "origin", origin );

				// set up spotlight values for lighting code to use
				VectorSubtract( origin, l->origin, l->spotdir );
				VectorNormalize( l->spotdir );

				if( !l->angle )
					l->spotcone = -cos( 20 * Q_PI / 180 );
				else
					l->spotcone = -cos( l->angle / 2 * Q_PI / 180 );

				if( l->spotcone <= 0 ) {
					VectorClear( l->spotdir );
					l->spotcone = 0;
				}
				break;
			}
		}

		if( j == num_entities )	{
			printf( "WARNING: light at (%i,%i,%i) has unmatched target\n", (int)l->origin[0], (int)l->origin[1], (int)l->origin[2]);
			continue;
		}

		// set the style on the source ent for switchable lights
		style = ValueForKey( &entities[j], "style" );
		if( style[0] && atof (style) ) {
			char s[16];

			l->style = atof( style );
			if( (unsigned)l->style > 254 )
				Error( "LoadLights: Bad target light style %i (must be 0-254)", l->style );

			memset( s, 0, sizeof(s) );
			sprintf( s, "%i", l->style );
			SetKeyValue( ent, "style", s );
		}
	}
}

void WriteLights( void )
{
	int i;
	FILE *f;
	directlight_t *l;

	printf ("building .lights file\n");

	f = fopen( lightsfilename, "wb" );
	for( i = 0, l = directlights; i < num_directlights; i++, l++ )
		fprintf( f, "%f %f %f %f %f %f %f %f %f %f %f %f %f %d\n", (double)l->origin[0], (double)l->origin[1], (double)l->origin[2], (double)l->falloff, (double)l->color[0], (double)l->color[1], (double)l->color[2], (double)l->subbrightness, (double)l->spotdir[0], (double)l->spotdir[1], (double)l->spotdir[2], (double)l->spotcone, (double)l->lightoffset, l->style );
	fclose( f );
}

dleaf_t *Light_PointInLeaf(vec3_t point)
{
	int num;
	num = 0;
	while (num >= 0)
		num = dnodes[num].children[DotProduct(point, dplanes[dnodes[num].planenum].normal) < dplanes[dnodes[num].planenum].dist];
	return dleafs + (-1 - num);
}

#define LIGHTCHAINS (MAX_MAP_FACES * 32)

lightchain_t *surfacelightchain[MAX_MAP_FACES];
lightchain_t lightchainbuf[LIGHTCHAINS];
byte surfacehit[MAX_MAP_FACES];
directlight_t *novislight[MAX_MAP_ENTITIES];
directlight_t *alllight[MAX_MAP_ENTITIES];
int novislights, alllights;
int lightchainbufindex;

/*
=============
LightWorld
=============
*/
extern int dlightdatapos;
void LightWorld (void)
{
	int			i, k, n, m, count;
	unsigned short	*mark;
	time_t		lightstarttime, oldtime, newtime;
	directlight_t *light;
	dleaf_t		*leaf;
	int			lightcount = 0, castcount = 0, emptycount = 0, solidcount = 0, watercount = 0, slimecount = 0, lavacount = 0, skycount = 0, misccount = 0, ignorevis;
	vec3_t		org;
	char		name[8];
	entity_t	*ent;
//	filebase = file_p = dlightdata;
//	file_end = filebase + MAX_MAP_LIGHTING;
	if (!relight)
		lightdatasize = 0;
	rgblightdatasize = 0;
	lightstarttime = time(NULL);

	lightchainbufindex = 0;
	novislights = alllights = 0;
	memset(surfacelightchain, 0, sizeof(surfacelightchain));

	// LordHavoc: find the right leaf for each entity
	for (i = 0, light = directlights;i < num_directlights;i++, light++)
	{
		lightcount++;
		alllight[alllights++] = light;
		leaf = Light_PointInLeaf(light->origin);
		ignorevis = false;
		switch (leaf->contents)
		{
		case CONTENTS_EMPTY:
			emptycount++;
			break;
		case CONTENTS_SOLID:
			solidcount++;
			ignorevis = true;
			break;
		case CONTENTS_WATER:
			watercount++;
			break;
		case CONTENTS_SLIME:
			slimecount++;
			break;
		case CONTENTS_LAVA:
			lavacount++;
			break;
		case CONTENTS_SKY:
			skycount++;
			ignorevis = true;
			break;
		default:
			misccount++;
			break;
		}
		if (leaf->visofs == -1 || ignorevis || !lightvis)
		{
			/*
			if ((lightchainbufindex + numfaces) > LIGHTCHAINS)
				Error("LightWorld: ran out of light chains!  complain to maintainer of hlight\n");
			for (m = 0;m < numfaces;m++)
			{
				castcount++;
				lightchainbuf[lightchainbufindex].light = entity;
				lightchainbuf[lightchainbufindex].next = surfacelightchain[m];
				surfacelightchain[m] = &lightchainbuf[lightchainbufindex++];
			}
			*/
			castcount += numfaces;
			novislight[novislights++] = light;
		}
		else
		{
			DecompressVis(dvisdata + leaf->visofs, currentvis, (numleafs + 7) >> 3);
			memset(surfacehit, 0, numfaces);
			for (n = 0, leaf = dleafs+1;n < numleafs;n++, leaf++) // leafs begin at 1
			{
				if (!leaf->nummarksurfaces)
					continue;
				if (currentvis[n >> 3] & (1 << (n & 7)))
				{
					if ((lightchainbufindex + leaf->nummarksurfaces) > LIGHTCHAINS)
						Error("LightWorld: ran out of light chains!  complain to maintainer of hlight\n");
					for (m = 0, mark = dmarksurfaces + leaf->firstmarksurface;m < leaf->nummarksurfaces;m++, mark++)
					{
						if (surfacehit[*mark])
							continue;
						surfacehit[*mark] = true;
						castcount++;
						lightchainbuf[lightchainbufindex].light = light;
						lightchainbuf[lightchainbufindex].next = surfacelightchain[*mark];
						surfacelightchain[*mark] = &lightchainbuf[lightchainbufindex++];
					}
				}
			}
		}
	}

	printf("%4i lights, %4i air, %4i solid, %4i water, %4i slime, %4i lava, %4i sky, %4i unknown\n", lightcount, emptycount, solidcount, watercount, slimecount, lavacount, skycount, misccount);

	i = 0;
	for (m = 0;m < numfaces;m++)
		if (surfacelightchain[m])
			i++;
	printf("%5i faces, %5i (%3i%%) may receive light\n", numfaces, i, i * 100 / numfaces);

	if (solidcount || skycount)
		printf("warning: %4i lights of %4i lights (%3i%%) were found in sky or solid and will not be accelerated using vis, move them out of the solid or sky to accelerate compiling\n", solidcount+skycount, lightcount, (solidcount+skycount) * 100 / lightcount);

	printf("%4i lights will be cast onto %5i surfaces, %10i casts will be performed\n", lightcount, numfaces, castcount);

	// LordHavoc: let there be light
	count = dmodels[0].numfaces;
//	k = 1;
//	j = (int) ((double) count * (double) k * (1.0 / 100.0));
	org[0] = org[1] = org[2] = 0;
	oldtime = time(NULL);
	for (m = 0;m < count;)
	{
		LightFace (dfaces + m + dmodels[0].firstface, surfacelightchain[m + dmodels[0].firstface], novislight, novislights, org);
		m++;
		newtime = time(NULL);
		if (newtime != oldtime)
		{
			printf ("\rworld face %5i of %5i (%3i%%), estimated time left: %5i ", m, count, (int) (m*100)/count, (int) (((count-m)*(newtime-lightstarttime))/m));
			fflush(stdout);
			oldtime = newtime;
		}
	}
	printf ("\n%5i faces done\nlightdatasize: %i\n", numfaces, lightdatasize);
	printf ("c_occluded: %i\n", c_occluded);

	printf("\nlighting %5i submodels:\n", nummodels);
	fflush(stdout);
	// LordHavoc: light bmodels
	for (k = 1;k < nummodels;k++)
	{
		newtime = time(NULL);
		if (newtime != oldtime)
		{
			m = k;
			count = nummodels;
			printf ("\rsubmodel %3i of %3i (%3i%%), estimated time left: %5i ", m, count, (int) (m*100)/count, (int) (((count-m)*(newtime-lightstarttime))/m));
			fflush(stdout);
			oldtime = newtime;
		}
		sprintf(name, "*%d", k);
		ent = FindEntityWithKeyPair("model", name);
		if (!ent)
			Error("FindFaceOffsets: Couldn't find entity for model %s.\n", name);

		org[0] = org[1] = org[2] = 0;
		if (!strncmp(ValueForKey (ent, "classname"), "rotate_", 7))
			GetVectorForKey(ent, "origin", org);

		for (m = 0;m < dmodels[k].numfaces;m++)
			LightFace (dfaces + m + dmodels[k].firstface, NULL, alllight, alllights, org);
	}

//	lightdatasize = file_p - filebase;
//	rgblightdatasize = lightdatasize * 3;

	printf ("\n%5i submodels done\nlightdatasize: %i\n", nummodels, lightdatasize);
	printf ("c_occluded: %i\n", c_occluded);
}

void CheckLightmaps(void);

/*
========
Light_Main

light modelfile
========
*/
int Light_Main (int argc, char **argv)
{
	char source[1024];
	double start, end;
	int i;

// LordHavoc
	printf ("hlight 1.04 by LordHavoc\n");
	printf ("based on id Software's quake light utility source code\n");
	extrasamplesbit = 0;
	lightvis = true;
	relight = false;
	globallightscale = 1.0;

	for (i=1 ; i<argc ; i++)
	{
		if (!strcmp(argv[i],"-extra"))
		{
			extrasamplesbit = 1;
			printf ("2x2 sampling enabled (tip: -extra4x4 is even higher quality)\n");
		}
		else if (!strcmp(argv[i],"-extra4x4"))
		{
			extrasamplesbit = 2;
			printf ("4x4 sampling enabled\n");
		}
		else if (!strcmp(argv[i],"-extra8x8"))
		{
			extrasamplesbit = 3;
			printf ("8x8 sampling enabled\n");
		}
		else if (!strcmp(argv[i],"-nolightvis"))
		{
			printf("use of vis data to optimize lighting disabled\n");
			lightvis = false;
		}
		else if (!strcmp(argv[i],"-relight"))
		{
			printf("relighting map to create .lit file without modifying .bsp\n");
			relight = true;
		}
		else if (!strcmp(argv[i],"-intensity"))
		{
			i++;
			if (i >= argc)
				Error("no value was given to -intensity\n");
			globallightscale = atof(argv[i]);
			if (globallightscale < 0.01)
				globallightscale = 0.01;
		}
		else if (argv[i][0] == '-')
			Error ("Unknown option \"%s\"", argv[i]);
		else
			break;
	}

	extrasamplesscale = 1.0f / (1 << (extrasamplesbit * 2));

// LordHavoc
	if (i != argc - 1)
		Error ("%s",
"usage: hlight [options] bspfile\n"
"Quick usage notes for entities: (place these in key/value pairs)\n"
"wait - falloff rate (1.0 default, 0.5 = bigger radius, 2 = smaller, affects area the light covers)\n"
"_color - 3 values (red green blue), specifies color of light, the scale of the numbers does not matter (\"1 3 2.5\" is identical to \"1000 3000 2500\")\n"
"_lightradius - limits light to this radius (and darkens light to make it blend well at the edges)\n"
"What the options do:\n"
"-extra         antialiased lighting (takes much longer, higher quality)\n"
"-extra4x4      antialiased lighting (even slower and higher quality than -extra)\n"
"-extra8x8      antialiased lighting (even slower and higher quality than -extra4x4)\n"
"-nolightvis    disables use of visibility data to optimize lighting\n"
"-relight       makes a .lit file for an existing map without modifying the .bsp\n"
		);

	// init memory
	Q_InitMem ();

	printf ("----- LightFaces ----\n");

//	InitThreads ();

	start = I_DoubleTime ();

	strcpy(source, argv[i]);
	strcpy(lightsfilename, source);
	DefaultExtension(source, ".bsp");
	ReplaceExtension(lightsfilename, ".lights");

	LoadBSPFile (source);
	memset(dlightdata, 0, sizeof(dlightdata));
	memset(drgblightdata, 0, sizeof(drgblightdata));
	//for (i = 0;i < sizeof(dlightdata);i++)
	//	dlightdata[i] = i;
	CheckLightmaps();

	if (!visdatasize)
	{
		printf("no visibility data found (run -vis before -light to compile faster)\n");
		lightvis = false;
	}

	ParseEntities ();
	printf ("%i entities read\n", num_entities);

	ParseLightEntities ();

	CheckLightmaps();

	MakeTnodes (&dmodels[0]);
	CheckLightmaps();

	LightWorld ();
	CheckLightmaps();

	WriteLights ();

	UnparseEntities ();

	CheckLightmaps();
	WriteBSPFile (source, relight);
	CheckLightmaps();

	end = I_DoubleTime ();
	printf ("%5.2f seconds elapsed\n\n", end-start);

	// print memory stats
	Q_PrintMem ();

#if _MSC_VER && _DEBUG
	printf("press any key\n");
	getchar();
#endif

	// free allocated memory
	Q_ShutdownMem ();

	return 0;
}

