// bsp5.c

#include "bsp5.h"

//
// command line flags
//
qboolean nofill;
qboolean notjunc;
qboolean noclip;
qboolean onlyents;
qboolean verbose;
qboolean allverbose;
qboolean forcevis;
qboolean waterlightmap;

int		subdivide_size;

int		valid;

char	filename_map[1024];
char	filename_bsp[1024];
char	filename_prt[1024];
char	filename_pts[1024];
char	filename_lit[1024];
char	filename_lights[1024];

int		Vis_Main( int argc, char **argv );
int		Light_Main( int argc, char **argv );
int		Bsp2Prt_Main( int argc, char **argv );
int		BspInfo_Main( int argc, char **argv );

//===========================================================================

void qprintf( char *fmt, ... )
{
	va_list argptr;
	extern qboolean verbose;

	if( !verbose )
		return;		// only print if verbose

	va_start( argptr, fmt );
	vprintf( fmt, argptr );
	va_end( argptr );
}

//===========================================================================


/*
===============
ProcessEntity
===============
*/
void ProcessEntity (int entnum, int modnum, int hullnum)
{
	entity_t	*ent;
	tree_t		*tree;

	ent = &entities[entnum];
	if( !ent->brushes )
		return;

	tree = Tree_ProcessEntity( ent, modnum, hullnum );
	EmitNodePlanes( tree->headnode );

	if( hullnum != 0 ) {
		EmitClipNodes( tree->headnode, modnum, hullnum );
	} else {
		EmitNodeFaces( tree->headnode );
		EmitDrawNodes( tree->headnode );
	}

	FreeTree( tree );
}

/*
=================
UpdateEntLump
=================
*/
void UpdateEntLump (void)
{
	int		m, entnum;
	char	mod[80];

	m = 1;
	for (entnum = 1 ; entnum < num_entities ; entnum++)
    {
		if (!entities[entnum].brushes)
			continue;
		sprintf (mod, "*%i", m);
		SetKeyValue (&entities[entnum], "model", mod);
		m++;
    }

	UnparseEntities();
}

/*
=================
CreateSingleHull
=================
*/
void CreateSingleHull ( int hullnum )
{
	int			entnum;
	int			modnum;

	// for each entity in the map file that has geometry
	verbose = true;	// print world
	for( entnum = 0, modnum = 0; entnum < num_entities; entnum++ ) {
		if( !entities[entnum].brushes )
			continue;

		ProcessEntity( entnum, modnum++, hullnum );
		if( !allverbose )
			verbose = false;	// don't print rest of entities
	}
}

/*
=================
CreateHulls
=================
*/
void CreateHulls (void)
{
	// commanded to ignore the hulls altogether
	if (noclip)
    {
		CreateSingleHull ( 0 );
		return;
    }

	// create all the hulls

	// create the hulls sequentially
	printf ("building hulls sequentially...\n");

	CreateSingleHull ( 0 );
	CreateSingleHull ( 1 );
	CreateSingleHull ( 2 );
}

/*
=================
ProcessFile
=================
*/
void ProcessFile (char *sourcebase, char *filename_bsp1)
{
	if (!onlyents)
	{
		remove (filename_bsp);
		remove (filename_prt);
		remove (filename_pts);
		remove (filename_lit);
		remove (filename_lights);
	}

	// load brushes and entities
	LoadMapFile (sourcebase);
	if (onlyents)
	{
		LoadBSPFile (filename_bsp);
		UpdateEntLump ();
		WriteBSPFile (filename_bsp, false);
		return;
	}

	// init the tables to be shared by all models
	BeginBSPFile ();

	// the clipping hulls will be written out to text files by forked processes
	CreateHulls ();

	UpdateEntLump ();

	WriteMiptex ();

	FinishBSPFile ();
}


/*
==================
main

==================
*/
int main (int argc, char **argv)
{
	int		i = 0;
	double		start, end;

	//	malloc_debug (15);
	printf( "hmap2 by LordHavoc and Vic\n");
	printf( "based on id Software's quake qbsp, light and vis utilities source code\n" );
	printf( "\n" );

	//
	// check command line flags
	//

	if( argc == 1 )
		goto error;

	// create all the filenames pertaining to this map
	strcpy(filename_map, argv[argc-1]);ReplaceExtension(filename_map, ".bsp", ".map", ".map");
	strcpy(filename_bsp, filename_map);ReplaceExtension(filename_bsp, ".map", ".bsp", ".bsp");
	strcpy(filename_prt, filename_bsp);ReplaceExtension(filename_prt, ".bsp", ".prt", ".prt");
	strcpy(filename_pts, filename_bsp);ReplaceExtension(filename_pts, ".bsp", ".pts", ".pts");
	strcpy(filename_lit, filename_bsp);ReplaceExtension(filename_lit, ".bsp", ".lit", ".lit");
	strcpy(filename_lights, filename_bsp);ReplaceExtension(filename_lights, ".bsp", ".lights", ".lights");

	if (!strcmp(filename_map, filename_bsp))
		Error("filename_map \"%s\" == filename_bsp \"%s\"\n", filename_map, filename_bsp);

	if( !strcmp( argv[1], "-bsp2prt" ) )
		return Bsp2Prt_Main( argc - 1, argv + 1 );
	else if( !strcmp( argv[1], "-bspinfo" ) )
		return BspInfo_Main( argc - 1, argv + 1 );
	else if( !strcmp( argv[1], "-vis" ) )
		return Vis_Main( argc - 1, argv + 1 );
	else if( !strcmp( argv[1], "-light" ) )
		return Light_Main( argc - 1, argv + 1 );

	nofill = false;
	notjunc = false;
	noclip = false;
	onlyents = false;
	verbose = true;
	allverbose = false;
	transwater = true;
	forcevis = true;
	waterlightmap = true;
	subdivide_size = 240;

	for (i=1 ; i<argc ; i++)
	{
		if (argv[i][0] != '-')
			break;
		else if (!strcmp (argv[i],"-nowater"))
			transwater = false;
		else if (!strcmp (argv[i],"-notjunc"))
			notjunc = true;
		else if (!strcmp (argv[i],"-nofill"))
			nofill = true;
		else if (!strcmp (argv[i],"-noclip"))
			noclip = true;
		else if (!strcmp (argv[i],"-onlyents"))
			onlyents = true;
		else if (!strcmp (argv[i],"-verbose"))
			allverbose = true;
		else if (!strcmp (argv[i],"-nowaterlightmap"))
			waterlightmap = false;
		else if (!strcmp (argv[i],"-subdivide"))
		{
			subdivide_size = atoi(argv[i+1]);
			i++;
		}
		else if (!strcmp (argv[i],"-darkplaces"))
		{
			// produce 256x256 texel lightmaps
			subdivide_size = 4080;
		}
		else if (!strcmp (argv[i],"-noforcevis"))
			forcevis = false;
		else
			Error ("Unknown option '%s'", argv[i]);
	}

	if (i != argc - 1)
error:
		Error ("%s",
"usage: hmap2 [options] sourcefile\n"
"Compiles .map to .bsp, does not compile vis or lighting data\n"
"\n"
"other utilities available:\n"
"-bsp2prt    bsp2prt utility, run -bsp2prt as the first parameter for more\n"
"-bspinfo    bspinfo utility, run -bspinfo as the first parameter for more\n"
"-light      lighting utility, run -light as the first parameter for more\n"
"-vis        vis utility, run -vis as the first parameter for more\n"
"\n"
"What the options do:\n"
"-nowater    disable watervis; r_wateralpha in glquake will not work right\n"
"-notjunc    disable tjunction fixing; glquake will have holes between polygons\n"
"-nofill     disable sealing of map and vis, used for ammoboxes\n"
"-onlyents   patchs entities in existing .bsp, for relighting\n"
"-verbose    show more messages\n"
"-darkplaces allow really big polygons\n"
"-noforcevis don't make a .prt if the map leaks\n"
"-nowaterlightmap disable darkplaces lightmapped water feature\n"
		);

	printf("inputfile: %s\n", filename_map);
	printf("outputfile: %s\n", filename_bsp);

	// init memory
	Q_InitMem ();

	//
	// do it!
	//
	start = I_DoubleTime ();
	ProcessFile (filename_map, filename_bsp);
	end = I_DoubleTime ();
	printf ("%5.1f seconds elapsed\n\n", end-start);

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
