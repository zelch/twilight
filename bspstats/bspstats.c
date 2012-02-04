
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <memory.h>

typedef enum outputtarget_e
{
	OUT_TXT,
	OUT_CSV,
	OUT_XML,
}
outputtarget_t;

typedef struct tallypattern_s
{
	char *name; // report tally as this column name
	char *match_classname; // classname this entity must be to match this pattern
	int match_spawnflags; // what spawnflags must be, after masking
	int match_spawnflagsmask; // which spawnflags bits matter
}
tallypattern_t;

#define MAXTALLYPATTERNS 1024
int numtallypatterns = 0;
tallypattern_t tallypatterns[MAXTALLYPATTERNS];

outputtarget_t option_output;

int bspstats_addtallypattern(const char *name, const char *classname, int spawnflags, int spawnflagsmask)
{
	if (numtallypatterns >= MAXTALLYPATTERNS)
		return 1;
	tallypatterns[numtallypatterns].name = strdup(namebuffer);
	tallypatterns[numtallypatterns].match_classname = strdup(classnamebuffer);
	tallypatterns[numtallypatterns].match_spawnflags = spawnflags;
	tallypatterns[numtallypatterns].match_spawnflagsmask = spawnflagsmask;
	numtallypatterns++;
}

int bspstats_entity(const char *filename, const char *classname, int spawnflags)
{
	int i;
	for (i = 0;i < numtallypatterns;i++)
	{
		for (
	}
}

int bspstats_preparecustom(const char *filename)
{
	FILE *f;
	char linebuffer[1024];
	char *line;
	int linenumber = 0;
	numtallypatterns = 0;
	f = fopen(filename, "r");
	if (!f)
		return 1;
	for(;;)
	{
		linenumber++;
		line = fgets(linebuffer, sizeof(linebuffer), f);
		if (!line)
			break;
		namebuffer[0] = 0;
		classnamebuffer[0] = 0;
		spawnflags = 0;
		spawnflagsmask = 0;
		numparms = sscanf("name \"%*s\" classname \"%*s\" spawnflags %d spawnflagsmask %d", namebuffer, sizeof(namebuffer), classnamebuffer, sizeof(classnamebuffer), &spawnflags, &spawnflagsmask);
		if (numparms < 2)
		{
			fprintf(stderr, "WARNING %s:%i: unable to parse this line\n", filename, linenumber);
			continue; // don't understand it!
		}
		if (namebuffer[0] && classnamebuffer[0])
			bspstats_addtallypattern(strdup(namebuffer), strdup(classnamebuffer), spawnflags, spawnflagsmask);
	}
	if (numtallypatterns < 1)
	{
		fprintf(stderr, "WARNING: failed to read any tally patterns from file\n");
		fprintf(stderr, "example contents of a custom tally file:\nname \"singleplayer start\" classname \"info_player_start\" spawnflags 0 spawnflagsmask 0\n");
		return 1;
	}
	return 0;
}

int bspstats_preparestandard(int option_tally_spawns, int option_tally_monsters, int option_tally_ammo, int option_tally_weapons, int option_tally_health, int option_tally_armor)
{
	if (option_tally_miscellaneous)
	{
		bspstats_addtallypattern("air_bubbles"                , "air_bubbles"                     , 0, 0);
		bspstats_addtallypattern("ambient_comp_hum"           , "ambient_comp_hum"                , 0, 0);
		bspstats_addtallypattern("ambient_drip"               , "ambient_drip"                    , 0, 0);
		bspstats_addtallypattern("ambient_drone"              , "ambient_drone"                   , 0, 0);
		bspstats_addtallypattern("ambient_suck_wind"          , "ambient_suck_wind"               , 0, 0);
		bspstats_addtallypattern("ambient_swamp1"             , "ambient_swamp1"                  , 0, 0);
		bspstats_addtallypattern("ambient_swamp2"             , "ambient_swamp2"                  , 0, 0);
		bspstats_addtallypattern("event_lightning"            , "event_lightning"                 , 0, 0);
		bspstats_addtallypattern("func_bossgate"              , "func_bossgate"                   , 0, 0);
		bspstats_addtallypattern("func_button"                , "func_button"                     , 0, 0);
		bspstats_addtallypattern("func_door"                  , "func_door"                       , 0, 0);
		bspstats_addtallypattern("func_door_secret"           , "func_door_secret"                , 0, 0);
		bspstats_addtallypattern("func_episodegate"           , "func_episodegate"                , 0, 0);
		bspstats_addtallypattern("func_illusionary"           , "func_illusionary"                , 0, 0);
		bspstats_addtallypattern("func_plat"                  , "func_plat"                       , 0, 0);
		bspstats_addtallypattern("func_train"                 , "func_train"                      , 0, 0);
		bspstats_addtallypattern("func_wall"                  , "func_wall"                       , 0, 0);
		bspstats_addtallypattern("info_intermission"          , "info_intermission"               , 0, 0);
		bspstats_addtallypattern("info_null"                  , "info_null"                       , 0, 0);
		bspstats_addtallypattern("info_player_start2"         , "info_player_start2"              , 0, 0);
		bspstats_addtallypattern("info_teleport_destination"  , "info_teleport_destination"       , 0, 0);
		bspstats_addtallypattern("light"                      , "light"                           , 0, 0);
		bspstats_addtallypattern("light_flame_large_yellow"   , "light_flame_large_yellow"        , 0, 0);
		bspstats_addtallypattern("light_flame_small_white"    , "light_flame_small_white"         , 0, 0);
		bspstats_addtallypattern("light_flame_small_yellow"   , "light_flame_small_yellow"        , 0, 0);
		bspstats_addtallypattern("light_fluoro"               , "light_fluoro"                    , 0, 0);
		bspstats_addtallypattern("light_fluorospark"          , "light_fluorospark"               , 0, 0);
		bspstats_addtallypattern("light_globe"                , "light_globe"                     , 0, 0);
		bspstats_addtallypattern("light_torch_small_walltorch", "light_torch_small_walltorch"     , 0, 0);
		bspstats_addtallypattern("misc_fireball"              , "misc_fireball"                   , 0, 0);
		bspstats_addtallypattern("misc_teleporttrain"         , "misc_teleporttrain"              , 0, 0);
		bspstats_addtallypattern("path_corner"                , "path_corner"                     , 0, 0);
		bspstats_addtallypattern("trigger_changelevel"        , "trigger_changelevel"             , 0, 0);
		bspstats_addtallypattern("trigger_counter"            , "trigger_counter"                 , 0, 0);
		bspstats_addtallypattern("trigger_hurt"               , "trigger_hurt"                    , 0, 0);
		bspstats_addtallypattern("trigger_monsterjump"        , "trigger_monsterjump"             , 0, 0);
		bspstats_addtallypattern("trigger_multiple"           , "trigger_multiple"                , 0, 0);
		bspstats_addtallypattern("trigger_once"               , "trigger_once"                    , 0, 0);
		bspstats_addtallypattern("trigger_onlyregistered"     , "trigger_onlyregistered"          , 0, 0);
		bspstats_addtallypattern("trigger_relay"              , "trigger_relay"                   , 0, 0);
		bspstats_addtallypattern("trigger_setskill"           , "trigger_setskill"                , 0, 0);
		bspstats_addtallypattern("trigger_teleport"           , "trigger_teleport"                , 0, 0);
		bspstats_addtallypattern("worldspawn"                 , "worldspawn"                      , 0, 0);
		bspstats_addtallypattern("trap_spikeshooter (small)"  , "trap_spikeshooter"               , 0, 3);
		bspstats_addtallypattern("trap_spikeshooter (super)"  , "trap_spikeshooter"               , 1, 3);
		bspstats_addtallypattern("trap_spikeshooter (laser)"  , "trap_spikeshooter"               , 2, 3);
		bspstats_addtallypattern("misc_explobox"              , "misc_explobox"                   , 0, 0);
		bspstats_addtallypattern("misc_explobox2"             , "misc_explobox2"                  , 0, 0);
		bspstats_addtallypattern("trigger_push"               , "trigger_push"                    , 0, 0);
		bspstats_addtallypattern("trigger_secret"             , "trigger_secret"                  , 0, 0);
	}
	if (option_tally_spawns)
	{
		bspstats_addtallypattern("sp start"                   , "info_player_start"               , 0, 0);
		bspstats_addtallypattern("coop start"                 , "info_player_coop"                , 0, 0);
		bspstats_addtallypattern("dm start"                   , "info_player_deathmatch"          , 0, 0);
	}
	if (option_tally_items)
	{
		bspstats_addtallypattern("green armor"                , "item_armor1"                     , 0, 0);
		bspstats_addtallypattern("yellow armor"               , "item_armor2"                     , 0, 0);
		bspstats_addtallypattern("red armor"                  , "item_armorInv"                   , 0, 0);
		bspstats_addtallypattern("rad suit"                   , "item_artifact_envirosuit"        , 0, 0);
		bspstats_addtallypattern("ring"                       , "item_artifact_invisibility"      , 0, 0);
		bspstats_addtallypattern("pent"                       , "item_artifact_invulnerability"   , 0, 0);
		bspstats_addtallypattern("quad"                       , "item_artifact_super_damage"      , 0, 0);
		bspstats_addtallypattern("small shells"               , "item_shells"                     , 0, 1);
		bspstats_addtallypattern("large shells"               , "item_shells"                     , 1, 1);
		bspstats_addtallypattern("small nails"                , "item_spikes"                     , 0, 1);
		bspstats_addtallypattern("large nails"                , "item_spikes"                     , 1, 1);
		bspstats_addtallypattern("small rockets"              , "item_rockets"                    , 0, 1);
		bspstats_addtallypattern("large rockets"              , "item_rockets"                    , 1, 1);
		bspstats_addtallypattern("small cells"                , "item_cells"                      , 0, 1);
		bspstats_addtallypattern("large cells"                , "item_cells"                      , 1, 1);
		bspstats_addtallypattern("small shells (obs)"         , "item_weapon"                     , 1, 15);
		bspstats_addtallypattern("large shells (obs)"         , "item_weapon"                     , 9, 15);
		bspstats_addtallypattern("small rockets (obs)"        , "item_weapon"                     , 2, 15);
		bspstats_addtallypattern("large rockets (obs)"        , "item_weapon"                     , 10, 15);
		bspstats_addtallypattern("small spikes (obs)"         , "item_weapon"                     , 4, 15);
		bspstats_addtallypattern("large spikes (obs)"         , "item_weapon"                     , 12, 15);
		bspstats_addtallypattern("rotten health"              , "item_health"                     , 1, 3);
		bspstats_addtallypattern("health"                     , "item_health"                     , 0, 3);
		bspstats_addtallypattern("mega health"                , "item_health"                     , 2, 3);
		bspstats_addtallypattern("silver key"                 , "item_key1"                       , 0, 0);
		bspstats_addtallypattern("gold key"                   , "item_key2"                       , 0, 0);
		bspstats_addtallypattern("rune of earth magic"        , "item_sigil"                      , 1, 15);
		bspstats_addtallypattern("rune of black magic"        , "item_sigil"                      , 2, 15);
		bspstats_addtallypattern("rune of hell magic"         , "item_sigil"                      , 4, 15);
		bspstats_addtallypattern("rune of elder magic"        , "item_sigil"                      , 8, 15);
		bspstats_addtallypattern("grenade launcher"           , "weapon_grenadelauncher"          , 0, 0);
		bspstats_addtallypattern("lightning gun"              , "weapon_lightning"                , 0, 0);
		bspstats_addtallypattern("nailgun"                    , "weapon_nailgun"                  , 0, 0);
		bspstats_addtallypattern("rocket launcher"            , "weapon_rocketlauncher"           , 0, 0);
		bspstats_addtallypattern("super nailgun"              , "weapon_supernailgun"             , 0, 0);
		bspstats_addtallypattern("super shotgun"              , "weapon_supershotgun"             , 0, 0);
	}
	if (option_tally_monsters)
	{
		bspstats_addtallypattern("grunt"                      , "monster_army"                    , 0, 0);
		bspstats_addtallypattern("chthon"                     , "monster_boss"                    , 0, 0);
		bspstats_addtallypattern("fiend"                      , "monster_demon1"                  , 0, 0);
		bspstats_addtallypattern("dog"                        , "monster_dog"                     , 0, 0);
		bspstats_addtallypattern("enforcer"                   , "monster_enforcer"                , 0, 0);
		bspstats_addtallypattern("rotfish"                    , "monster_fish"                    , 0, 0);
		bspstats_addtallypattern("death knight"               , "monster_hell_knight"             , 0, 0);
		bspstats_addtallypattern("knight"                     , "monster_knight"                  , 0, 0);
		bspstats_addtallypattern("ogre"                       , "monster_ogre"                    , 0, 0);
		bspstats_addtallypattern("shub-niggurath"             , "monster_oldone"                  , 0, 0);
		bspstats_addtallypattern("vore"                       , "monster_shalrath"                , 0, 0);
		bspstats_addtallypattern("shambler"                   , "monster_shambler"                , 0, 0);
		bspstats_addtallypattern("tarbaby"                    , "monster_tarbaby"                 , 0, 0);
		bspstats_addtallypattern("scrag"                      , "monster_wizard"                  , 0, 0);
		bspstats_addtallypattern("zombie"                     , "monster_zombie"                  , 0, 0);
	}
}

#define GETLONG(b) ((b)[0] + (b)[1] * 256 + (b)[2] * 65536 + (b)[3] * 16777216)

void bspstats_parseentitylump(const char *filename, const char *entitytext)
{
	const char *text = entitytext;
	const char *linestart = NULL;
	const char *lineend = NULL;
	const char *t = NULL;
	int nesting = 0;
	int spawnflags = 0;
	char key[2][1024], classname[1024]; // note: strcpy is used here, make sure these match in size
	while (*text)
	{
		linestart = text;
		for (lineend = linestart;*lineend && *lineend != '\n' && *lineend != '\r';lineend++)
			;
		if (lineend[0] == '\r' && lineend[1] == '\n')
			text = lineend + 2;
		else
			text = lineend + 1;
		t = linestart;
		// skip leading whitespace
		while (t < lineend && *t == ' ' || *t == '\t')
			t++;
		// decide what kind of statement this is
		if (t[0] == '{')
		{
			// opening bracket, increase nesting level, this may be the beginning of an entity
			nesting++;
			if (nesting == 1)
			{
				classname[0] = 0;
				spawnflags = 0;
			}
		}
		else if (t[0] == '}')
		{
			// closing bracket, decrease nesting level, this may be the end of an entity
			if (nesting == 1 && classname[0])
			{
				// we now have a classname and spawnflags value, tally it
				bspstats_entity(filename, classname, spawnflags);
			}
			nesting--;
		}
		else if (t[0] == '"')
		{
			for (k = 0;k < 2;k++)
			{
				// skip leading whitespace to the first "
				while (t < lineend && *t != '"')
					t++;
				if (t < lineend)
					t++;
				// read each character into the array
				keylen = 0;
				while (t < lineend && *t != '"')
				{
					if (keylen < sizeof(key[k])-1)
					{
						// if we wanted to handle \n here, we could...
						key[k][keylen++] = *t;
					}
					t++;
				}
				key[keylen] = 0;
				if (t < lineend)
					t++;
			}
			if (!strcmp(key[0], "classname"))
				strcpy(classname, key[0]); // this is safe
			else if (!strcmp(key[0], "spawnflags"))
				spawnflags = (int)atof(key[1]);
		}
	}
}

void bspstats_file(const char **filename)
{
	unsigned char header[4+15*8];
	FILE *file = NULL;
	char *entitytext = NULL;
	int ofs_entities = 0;
	int size_entities = 0;
	int readsize = 0;
	file = fopen(filename, "rb");
	if (!file)
	{
		fprintf(stderr, "%s: failed to open file\n", filename);
		goto done;
	}
	headersize = fread(&header, 1, sizeof(header), file);
	if (headersize < sizeof(header))
	{
		fprintf(stderr, "%s: failed to read header\n", filename);
		goto done;
	}
	bspversion = GETLONG(header + 0);
	if (bspversion != 29)
	{
		fprintf(stderr, "%s: bspversion %i != 29\n", filename, bspversion);
		goto done;
	}
	ofs_entities = GETLONG(header + 4);
	size_entities = GETLONG(header + 8);
	if (size_entities < 0 || size_entities > 1<<28)
	{
		fprintf(stderr, "%s: entity lump has funny size: %i\n", filename, size_entities);
		goto done;
	}
	entitytext = malloc(size_entities + 1);
	if (!entitytext)
	{
		fprintf(stderr, "%s: malloc failed on entity lump (size %i)\n", filename, size_entities);
		goto done;
	}
	memset(entitytext, 0, size_entities + 1);
	fseek(file, ofs_entities, SEEK_SET);
	readsize = fread(entitytext, 1, size_entities, file);
	if (readsize != size_entities)
	{
		fprintf(stderr, "%s: read failed on entity lump (size %i)\n", filename, size_entities);
		goto done;
	}
	bspstats_parseentitylump(filename, entitytext);
done:
	if (entitytext)
		free(entitytext);
	if (file)
		fclose(file);
}

int main(int argc, char **argv)
{
	int i;
	int option_quaketoascii = 1; // convert characters to ascii (do not use on a bsp containing UTF-8 text)
	int option_treestats = 1;
	int option_tally_miscellaneous = 0;
	int option_tally_spawns = 0;
	int option_tally_monsters = 0;
	int option_tally_items = 0;
	int option_nooptions = 0;
	option_output = OUT_TXT;
	for (i = 0;i < argc;i++)
	{
		if (!argv[i])
			continue;
		if (!option_nooptions && argv[i][0] == '-')
		{
			     if (!strcmp(argv[i], "--")) option_nooptions = 1;
			else if (!strcmp(argv[i], "-txt")) option_output = OUT_TXT;
			else if (!strcmp(argv[i], "-csv")) option_output = OUT_CSV;
			else if (!strcmp(argv[i], "-xml")) option_output = OUT_XML;
			else if (!strcmp(argv[i], "-misc")) option_tally_miscellaneous = 1;
			else if (!strcmp(argv[i], "-nomisc")) option_tally_miscellaneous = 0;
			else if (!strcmp(argv[i], "-spawns")) option_tally_spawns = 1;
			else if (!strcmp(argv[i], "-nospawns")) option_tally_spawns = 0;
			else if (!strcmp(argv[i], "-items")) option_tally_items = 1;
			else if (!strcmp(argv[i], "-noitems")) option_tally_items = 0;
			else if (!strcmp(argv[i], "-monsters")) option_tally_monsters = 1;
			else if (!strcmp(argv[i], "-nomonsters")) option_tally_monsters = 0;
			else if (!strcmp(argv[i], "-custom") && i+1 < argc) {option_tally_custom = 1;option_tally_custom_name = argv[++i];}
			else {fprintf(stderr, "unrecognized option: %s\n", argv[i]);return 1;}
		}
		else
			break;
	}
	// from here on we just process filenames
	// prepare the tally patterns
	if (option_tally_custom)
		bspstats_preparecustom(option_tally_custom_name);
	else
		bspstats_preparestandard(option_tally_spawns, option_tally_monsters, option_tally_ammo, option_tally_weapons, option_tally_health, option_tally_armor);
	for (;i < argc;i++)
		bspstats_file(argv[i]);
	return 0;
}

