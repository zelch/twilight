
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>

#define TRUE 1
#define FALSE 0
#define true 1
#define false 0

// very basic entity data
typedef struct entity_s
{
	int active;
	char* classname; // class of object (monster_ogre for example)
	int ox, oy, oz; // origin
	int solid; // checkbox only cares about an ent in the way if this is true
	int minx, miny, minz, maxx, maxy, maxz; // these are absolute (already adjusted by origin)
	int angle;
	int light;
	int flags;
}
entity_t;

// map cells are walls, columns, whatever
typedef struct mapcell_s
{
	char wall; // 0 if empty, 1 for wall, 2 for column, -1 for hole in the floor (special)
	char special; // special object to stamp down (usually staircases, lamps, doors, etc)
//	unsigned short entity; // just an index into the entity array to show cell is occupied
}
mapcell_t;

long intrandom(int min, int max)
{
	if (max <= min)
		return min;
	return ((rand() % (max-min)) + min);
}

int monstersperlevel;
int roomsize_min;
int roomsize_max;
int levelsize;
int cellsize;
int levelcenter;
int levelsperstyle;
int styles;
int levels;
int leveldist;

// a hole in the floor (can drop down to level below)
#define walltype_hole -1
// empty space
#define walltype_empty 0
// a wall between columns or a solid area
#define walltype_wall 1
// a column (small enough to be walked by)
//#define walltype_column 2
// used to signal that the space is taken during the room building process (by a door special, for example)
#define walltype_occupied 3
// border of the level, room building will never use this cell
#define walltype_levelwall 127

// nothing special
#define special_empty 0
// a free-standing lamp (flame ontop of a column)
//#define special_torchstand 1
// an elderworld panel light on the ceiling
#define special_elderceilinglight 2
#define special_doorx 3
#define special_doory 4
// staircase down to the level below (not used yet)
#define special_staircase 120
#define special_entranceexit 110

#define maxentities 1024

#define ENT_MONSTER 1
#define ENT_AMMO 2

entity_t entity[maxentities];

#define mapcell(x, y, z) mapcelldata[((z) * levelsize + (y)) * levelsize + (x)]
mapcell_t *mapcelldata;//[levels][levelsize][levelsize];

char *roomdata[] =
{
	"####D####",
	"#       #",
	"# #   # #",
	"#       #",
	"D   L   D",
	"#       #",
	"# #   # #",
	"#       #",
	"####D####",
	NULL,
	"####D####",
	"#       #",
	"#       #",
	"#       #",
	"D   L   D",
	"#       #",
	"#       #",
	"#       #",
	"####D####",
	NULL,
	"###D###",
	"#     #",
	"#     #",
	"D  L  D",
	"#     #",
	"#     #",
	"###D###",
	NULL,
	"##D##",
	"#   #",
	"D L D",
	"#   #",
	"##D##",
	NULL,
	"#######################",
	"###                 ###",
	"###  #  #  #  #  #  ###",
	"#                     #",
	"D    L     L     L    D",
	"#                     #",
	"###  #  #  #  #  #  ###",
	"###                 ###",
	"#######################",
	NULL,

};

/*
#define MAX_ROOMS 4096

typedef struct
{
	int level;
	int x1, y1, x2, y2;
	int monsters;
	int ammo;
	int health;
	int neighbor[4];
	int neighborcount;
	int parentroom;
}
room_t;

room_t room[MAX_ROOMS];
int rooms;

typedef struct
{
//	int startx, starty;
//	int endx, endy;
	int monsters;
	int ammo;
	int health;
}
levelinfo_t;

levelinfo_t levelinfo[levels];
*/

int lastent;

entity_t* newentity(void)
{
	entity_t *ent;
	if (lastent >= maxentities)
	{
		printf("newentity: ran out of entities\n");
		return NULL;
	}
	ent = &entity[lastent];
	ent->active = TRUE;
	lastent++;
	return ent;
}

int makelight(char* classname, int x, int y, int z, int light)
{
	entity_t* e;
	e = newentity();
	if (!e)
		return FALSE;
	e->classname = classname;
	e->ox = x;
	e->oy = y;
	e->oz = z;
	e->solid = false;
	e->light = light;
	e->angle = 0;
	return TRUE;
}

int makeentity(char* classname, int ox, int oy, int oz, int minx, int miny, int minz, int maxx, int maxy, int maxz, int angle, int flags)
{
	entity_t* e;
	e = newentity();
	if (!e)
		return FALSE;
	e->classname = classname;
	e->ox = ox;
	e->oy = oy;
	e->oz = oz;
	e->solid = false;
	if (minx || miny || minz || maxx || maxy || maxz)
	{
		e->solid = true;
		e->minx = minx + ox;
		e->miny = miny + oy;
		e->minz = minz + oz;
		e->maxx = maxx + ox;
		e->maxy = maxy + oy;
		e->maxz = maxz + oz;
	}
	e->angle = angle;
	e->flags = flags;
	return TRUE;
}

int checkbox(int minx, int miny, int minz, int maxx, int maxy, int maxz)
{
	int i, x1, y1, x2, y2, x, y, level;
	entity_t *ent;
	x1 = (minx + leveldist) / cellsize;
	y1 = (miny + leveldist) / cellsize;
	x2 = (maxx + leveldist + cellsize - 1) / cellsize;
	y2 = (maxy + leveldist + cellsize - 1) / cellsize;
	level = (minz + 128) / -192;
	i = minz - (level * -192 - 128);
	if (i < 0)
		return false; // embedded in floor
	i = maxz - (level * -192 - 128);
	if (i >= 128)
		return false; // embedded in ceiling
	if (x1 < 0 || y1 < 0 || x2 >= levelsize-1 || y2 >= levelsize-1)
		return false; // outside map
	if (level < 0 || level >= levels)
		return false; // invalid level number
	for (y = y1;y <= y2;y++)
		for (x = x1;x <= x2;x++)
			if (mapcell(x,y,level).wall || mapcell(x,y,level).special)
				return false;
	for (i = 0;i < maxentities;i++)
	{
		if (entity[i].active && entity[i].solid)
		{
			ent = &entity[i];
			if (ent->minx > maxx || ent->miny > maxy || ent->minz > maxz || ent->maxx < minx || ent->maxy < miny || ent->maxz < minz)
				continue;
			return false; // occupied
		}
	}
	if (mapcell(x1,y2,level).wall || mapcell(x1,y1,level).special)
	{
		printf("checkbox malfunction\n");
		return false;
	}
	return true; // empty
}


void randomemptyarea(int* x, int* y, int x1, int y1, int x2, int y2, int sx, int sy, int level)
{
	int cx, cy, cx2, cy2;
randomemptyarea_redo:
	*x = intrandom(x1, y2-sy);cx2=*x+sx;
	*y = intrandom(y1, y2-sy);cy2=*y+sy;
	for (cy = *y;cy < cy2;cy++)
		for (cx = *x;cx < cx2;cx++)
			if (mapcell(cx,cy,level).wall != walltype_empty || (mapcell(cx,cy,level).special != special_empty && mapcell(cx,cy,level).special != special_elderceilinglight) /* || mapcell(cx,cy,level).entity*/)
				goto randomemptyarea_redo;
}

int getwall(int x, int y, int level)
{
	if (x < 1 || y < 1 || x >= (levelsize-1) || y >= (levelsize-1) || level < 0 || level > levels)
		return walltype_levelwall; // permanent border
	return mapcell(x,y,level).wall;
}

void setwall(int t, int x, int y, int level)
{
	if (x < 1 || y < 1 || x >= (levelsize-1) || y >= (levelsize-1) || level < 0 || level > levels)
		return; // permanent border
	mapcell(x,y,level).wall = t;
}

int getspecial(int x, int y, int level)
{
	if (x < 1 || y < 1 || x >= (levelsize-1) || y >= (levelsize-1) || level < 0 || level > levels)
		return special_empty; // permanent border
	return mapcell(x,y,level).special;
}

void setspecial(int t, int x, int y, int level)
{
	if (x < 1 || y < 1 || x >= (levelsize-1) || y >= (levelsize-1) || level < 0 || level > levels)
		return; // permanent border
	mapcell(x,y,level).special = t;
}

void clearlevel(int level)
{
	int x, y;
	for (y = 0;y < levelsize;y++)
	{
		for (x = 0;x < levelsize;x++)
		{
			mapcell(x,y,level).wall = walltype_wall;
			mapcell(x,y,level).special = special_empty;
		}
	}
}

int clearroom(int level, int x1, int y1, int x2, int y2)
{
	int x, y;
	if (x2 <= x1 || y2 <= y1 || x1 < 1 || y1 < 1 || x2 > (levelsize-1) || y2 > (levelsize-1))
		return FALSE; // invalid
	for (y = y1;y < y2;y++)
		for (x = x1;x < x2;x++)
			if (mapcell(x,y,level).wall != walltype_wall) // if anything looks wrong...
				return FALSE; // the space is already used
	for (y = y1;y < y2;y++)
		for (x = x1;x < x2;x++)
			mapcell(x,y,level).wall = walltype_empty;
	return TRUE; // successful
}

int linewall(int level, int x1, int y1, int x2, int y2, int type)
{
	int x, y;
	if (x1 < 1 || y1 < 1 || x1 >= (levelsize-1) || y1 >= (levelsize-1) || x2 < 1 || y2 < 1 || x2 >= (levelsize-1) || y2 >= (levelsize-1))
		return FALSE; // out of bounds
	if (y1 == y2) // horizontal wall
	{
		y = y1;
		if (x2 < x1)
		{
			x = x1;
			x1 = x2;
			x2 = x;
		}
		for (x = x1;x <= x2;x++)
			setwall(type, x, y, level);
		if (type == walltype_wall) // make a doorway
		{
			y = y1;
			if (rand() & 1)
			{
				x = intrandom(x1, x2);
				setwall(walltype_occupied, x, y, level);
				setwall(walltype_occupied, x+1, y, level);
				setspecial(special_doorx, x, y, level);
			}
			else
			{
				x = intrandom(x1, x2);
				setwall(walltype_empty, x, y, level);
				setwall(walltype_empty, x+1, y, level);
			}
		}
		return TRUE;
	}
	else if (x1 == x2) // vertical wall
	{
		x = x1;
		if (y2 < y1)
		{
			y = y1;
			y1 = y2;
			y2 = y;
		}
		for (y = y1;y <= y2;y++)
			setwall(type, x, y, level);
		if (type == walltype_wall) // make a doorway
		{
			x = x1;
			if (rand() & 1)
			{
				y = intrandom(y1, y2);
				setwall(walltype_occupied, x, y, level);
				setwall(walltype_occupied, x, y+1, level);
				setspecial(special_doory, x, y, level);
			}
			else
			{
				y = intrandom(y1, y2);
				setwall(walltype_empty, x, y, level);
				setwall(walltype_empty, x, y+1, level);
			}
		}
		return TRUE;
	}
	else
		return FALSE; // invalid
}

int checkroom(int level, int x1, int y1, int x2, int y2, int type)
{
	int x, y;
	if (x1 < 1 || y1 < 1 || x2 > (levelsize-1) || y2 > (levelsize-1) || x2 <= x1 || y2 <= y1)
		return FALSE; // invalid
	for (y = y1;y < y2;y++)
		for (x = x1;x < x2;x++)
			if (mapcell(x,y,level).wall != type)
				return FALSE;
	return TRUE;
}

int makerooms(int level, int ox1, int oy1, int ox2, int oy2)
{
	int wall, sx, sy, wx1, wy1, wx2, wy2, tries, nx1, ny1, nx2, ny2, c = 0, x, y;
	if (ox1 < 1 || oy1 < 1 || ox2 > (levelsize-1) || oy2 > (levelsize-1) || ox2 <= ox1 || oy2 <= oy1)
		return 0; // out of bounds
	for (tries = 0;tries < 30;tries++)
	{
		sx = intrandom(roomsize_min, roomsize_max); // width of room
		sy = intrandom(roomsize_min, roomsize_max); // height of room
		switch (rand() & 3)
		{
		default:
		case 0: // east
			nx1 = ox2 + 1;nx2 = nx1 + sx;ny1 = intrandom(oy1, oy2) - (sy / 2);ny2 = ny1 + sy;
			wx1 = wx2 = ox2;wy1 = oy1 > ny1 ? oy1 : ny1;wy2 = oy2 < ny2 ? oy2 : ny2;wy2--;
			break;
		case 1: // south
			ny1 = oy2 + 1;ny2 = ny1 + sy;nx1 = intrandom(ox1, ox2) - (sx / 2);nx2 = nx1 + sx;
			wy1 = wy2 = oy2;wx1 = ox1 > nx1 ? ox1 : nx1;wx2 = ox2 < nx2 ? ox2 : nx2;wx2--;
			break;
		case 2: // west
			nx1 = ox1 - 1 - sx;nx2 = nx1 + sx;ny1 = intrandom(oy1, oy2) - (sy / 2);ny2 = ny1 + sy;
			wx1 = wx2 = ox1 - 1;wy1 = oy1 > ny1 ? oy1 : ny1;wy2 = oy2 < ny2 ? oy2 : ny2;wy2--;
			break;
		case 3: // north
			ny1 = oy1 - 1 - sy;ny2 = ny1 + sy;nx1 = intrandom(ox1, ox2) - (sx / 2);nx2 = nx1 + sx;
			wy1 = wy2 = oy1 - 1;wx1 = ox1 > nx1 ? ox1 : nx1;wx2 = ox2 < nx2 ? ox2 : nx2;wx2--;
			break;
		}
		// make sure the area is clear
		if (checkroom(level, nx1-1, ny1-1, nx2+1, ny2+1, walltype_wall))
		{
			printf("*");
			switch(rand() & 3)
			{
			default:
			case 0:
				wall = walltype_empty;
				break;
			case 1:
				wall = walltype_empty;
				break;
			case 2:
				wall = walltype_wall;
				break;
			case 3:
				wall = walltype_wall; //dashed;
				break;
			}
			// make the wall joining the two rooms
			linewall(level, wx1, wy1, wx2, wy2, wall);
			// make the room
			c++;
			clearroom(level, nx1, ny1, nx2, ny2);
			c += makerooms(level, nx1, ny1, nx2, ny2); // add in how many were made
			x = intrandom(nx1+1, nx2-1);
			y = intrandom(ny1+1, ny2-1);
//			if ((rand() & 3) < 1)
//				mapcell(x,y,level).special = special_torchstand;
//			else
				mapcell(x,y,level).special = special_elderceilinglight;
		}
	}
	return c; // how many rooms were made
}

//unsigned char columnclassification[16] = {2, 2, 2, 1, 2, 2, 2, 1, 2, 2, 2, 1, 1, 1, 1, 1};
/*
				switch (c)
				{
				case 0:
				case 1:
				case 2:
				case 4:
				case 5:
				case 6:
				case 8:
				case 9:
				case 10:
					mapcell(x,y,level).wall = walltype_column;
				default: // 3 7 11 12 13 14 15
					mapcell(x,y,level).wall = walltype_wall;
				}
*/

/*
void convertcolumndata(int level)
{
	int x, y, mx, my, c;
	for (x = 0;x < levelsize;x++)
	{
		mapcell[level][0          ][x          ].wall = walltype_levelwall;
		mapcell[level][levelsize-2][x          ].wall = walltype_levelwall;
		mapcell[level][levelsize-1][x          ].wall = walltype_levelwall;
		mapcell[level][x          ][0          ].wall = walltype_levelwall;
		mapcell[level][x          ][levelsize-2].wall = walltype_levelwall;
		mapcell[level][x          ][levelsize-1].wall = walltype_levelwall;
	}
	for (y = 1,my = 2;y < (levelcolumnsize-1);y++,my+=2)
	{
		for (x = 1,mx = 2;x < (levelcolumnsize-1);x++,mx+=2)
		{
			if (columncell[y][x])
				mapcell[level][my][mx].wall = walltype_column;
			else
				mapcell[level][my][mx].wall = 0;
		}
	}
	// fill between columns
	for (y = 0;y < (levelsize-2);y+=2)
	{
		for (x = 0;x < (levelsize-2);x+=2)
		{
			mapcell[level][y][x+1].wall = mapcell(x,y,level).wall && mapcell[level][y][x+2].wall;
			mapcell[level][y+1][x].wall = mapcell(x,y,level).wall && mapcell[level][y+2][x].wall;
			mapcell[level][y+1][x+1].wall = mapcell(x,y,level).wall && mapcell[level][y][x+2].wall && mapcell[level][y+2][x].wall && mapcell[level][y+2][x+2].wall;
		}
	}
	// mark all corners as columns, and everything else as walls
	for (y = 2;y < (levelsize-2);y++)
	{
		for (x = 2;x < (levelsize-2);x++)
		{
			if (mapcell(x,y,level).wall)
			{
				c = 0;
				if (mapcell[level][y][x-2].wall) c+=1;
				if (mapcell[level][y][x+2].wall) c+=2;
				if (mapcell[level][y-2][x].wall) c+=4;
				if (mapcell[level][y+2][x].wall) c+=8;
				mapcell(x,y,level).wall = columnclassification[c];
			}
		}
	}
}
*/

typedef struct
{
	char *name;
	int minimum, maximum;
	int chance;
	int preferredlevel;
	int randomangle;
	int health; // for a monster this is how much health they have (used in placing ammo), for a healthbox it is how much it restores
	int damage; // for a monster this is how much damage they are likely to do to the player (used in placing health/armor), for a ammo box it is how much damage it does
	int minx, miny, minz, maxx, maxy, maxz;
}
objecttype_t;

int placeobjects, placeobjectrandomangle, placeobjecthealth, placeobjectdamage, placeobjectminx, placeobjectminy, placeobjectminz, placeobjectmaxx, placeobjectmaxy, placeobjectmaxz;
char *placeobjectname;

objecttype_t monstertypes[] =
{
	{"monster_army"					,  4,  8, 5000, 20, true ,   50,      5, -16, -16, -24, 16, 16, 32},
	{"monster_dog"					,  3,  8, 5000,  0, true ,   25,      2, -16, -16, -24, 16, 16, 32},
	{"monster_enforcer"				,  3,  6, 5000, 30, true ,   80,      5, -16, -16, -24, 16, 16, 32},
	{"monster_demon1"				,  3,  6, 5000, 60, true ,  300,      4, -32, -32, -24, 32, 32, 64},
	{"monster_knight"				,  4,  9, 5000, 40, true ,   75,      2, -16, -16, -24, 16, 16, 32},
	{"monster_ogre"					,  3,  5, 5000, 50, true ,  200,      5, -16, -16, -24, 16, 16, 32},
	{"monster_hell_knight"			,  2,  5, 5000, 70, true ,  250,     15, -16, -16, -24, 16, 16, 32},
	{"monster_wizard"				,  3,  8, 5000, 50, true ,   80,      4, -16, -16, -24, 16, 16, 32},
	{"monster_zombie"				,  3, 10, 5000, 70, true ,  100,      3, -16, -16, -24, 16, 16, 32},
	{"monster_shalrath"				,  1,  3, 5000,100, true ,  400,     10, -16, -16, -24, 16, 16, 32},
	{"monster_tarbaby"				,  6, 10, 5000, 90, true ,   50,     10, -16, -16, -24, 16, 16, 32},
	{"monster_shambler"				,  1,  1, 3000,100, true , 1200,     30, -16, -16, -24, 16, 16, 32},
};
/*
// triple packs
	{"monster_army"					, 12, 24,  500,  2, true ,   50,      5, -16, -16, -24, 16, 16, 32},
	{"monster_dog"					, 18, 36,  500,  1, true ,   25,      2, -16, -16, -24, 16, 16, 32},
	{"monster_enforcer"				, 12, 24,  500,  3, true ,   80,      5, -16, -16, -24, 16, 16, 32},
	{"monster_demon1"				,  9, 18,  500,  7, true ,  300,      4, -32, -32, -24, 32, 32, 64},
	{"monster_knight"				, 12, 27,  500,  4, true ,   75,      2, -16, -16, -24, 16, 16, 32},
	{"monster_ogre"					,  9, 15,  500,  6, true ,  200,      5, -16, -16, -24, 16, 16, 32},
	{"monster_hell_knight"			,  6, 15,  500,  9, true ,  250,     15, -16, -16, -24, 16, 16, 32},
	{"monster_wizard"				, 15, 24,  500,  4, true ,   80,      4, -16, -16, -24, 16, 16, 32},
	{"monster_zombie"				, 30, 45,  500,  5, true ,  100,      3, -16, -16, -24, 16, 16, 32},
	{"monster_shalrath"				,  3,  9,  500, 11, true ,  400,     10, -16, -16, -24, 16, 16, 32},
	{"monster_tarbaby"				, 18, 30,  500,  9, true ,   50,     10, -16, -16, -24, 16, 16, 32},
	{"monster_shambler"				,  2,  4,  300, 12, true , 1200,     30, -16, -16, -24, 16, 16, 32},
};
*/

objecttype_t ammotypes[] =
{
//	{"weapon_supershotgun"			,  1,  1, 6000, -1, false,    0,  20*60, -16, -16,   0, 16, 16, 56},
//	{"weapon_nailgun"				,  1,  1, 4000, -1, false,    0,  80*15, -16, -16,   0, 16, 16, 56},
//	{"weapon_supernailgun"			,  1,  1, 1200, -1, false,    0,  80*15, -16, -16,   0, 16, 16, 56},
//	{"weapon_grenadelauncher"		,  1,  1, 1600, -1, false,    0, 10*120, -16, -16,   0, 16, 16, 56},
//	{"weapon_rocketlauncher"		,  1,  1,  800, -1, false,    0, 10*120, -16, -16,   0, 16, 16, 56},
//	{"weapon_lightning"				,  1,  1,  400, -1, false,    0,  40*30, -16, -16,   0, 16, 16, 56},
	{"item_shells"					,  1,  4,10000, -1, false,    0,  32*60,   0,   0,   0, 32, 32, 56},
	{"item_spikes"					,  1,  4, 8000, -1, false,    0,  80*15,   0,   0,   0, 32, 32, 56},
	{"item_rockets"					,  1,  4, 6000, -1, false,    0, 10*120,   0,   0,   0, 32, 32, 56},
	{"item_cells"					,  1,  4, 4000, -1, false,    0,  60*30,   0,   0,   0, 32, 32, 56},
	{"item_artifact_super_damage"	,  1,  1,   50, -1, false,    0,   1000, -16, -16, -24, 16, 16, 32},
};

objecttype_t healthtypes[] =
{
	{"item_health"					,  1,  2, 1000, -1, false,   25,      0,   0,   0,   0, 32, 32, 56},
	{"item_armor1"					,  1,  1,  100, -1, false,   30,      0, -16, -16,   0, 16, 16, 56},
	{"item_armor2"					,  1,  1,  150, -1, false,   90,      0, -16, -16,   0, 16, 16, 56},
	{"item_armorInv"				,  1,  1,  200, -1, false,  160,      0, -16, -16,   0, 16, 16, 56},
	{"item_artifact_invulnerability",  1,  1,    5, -1, false,  300,      0, -16, -16, -24, 16, 16, 32},
};

int totalobjectchance, objecttypelevel = -1000, objecttypechoices, objectchances[1000];
objecttype_t *objecttypetypes;

void pickobjecttype(objecttype_t *types, int choices, int level)
{
	int i, j, r;
	// scale to standard level comparisons  (so number of levels can be adjusted easily, with monster distribution scaling to match)
	level = (level * 100 + 50) / levels;
	if (objecttypelevel != level || types != objecttypetypes || choices != objecttypechoices) // rebuild cache
	{
		totalobjectchance = 0;
		for (i = 0;i < choices;i++)
		{
			// reduce chances the further from the intended level this is
			if (types[i].preferredlevel >= 0 && levels > 1)
			{
				j = types[i].preferredlevel - level;
				if (j < 0)
					j = -j;
				j += 1;
				objectchances[i] = types[i].chance / j;
			}
			else
			{
				// no level preference
				objectchances[i] = types[i].chance;
			}
			totalobjectchance += objectchances[i];
		}
	}
	i = 0;
	r = ((rand() * 32768 + rand()) & 0x7FFFFFFF) % totalobjectchance;
	while (r >= objectchances[i])
	{
		r -= objectchances[i];
		i++;
	}
	placeobjectname = types[i].name;
	placeobjects = intrandom(types[i].minimum, types[i].maximum + 1);
	placeobjectrandomangle = types[i].randomangle;
	placeobjecthealth = types[i].health;
	placeobjectdamage = types[i].damage;
	placeobjectminx = types[i].minx;
	placeobjectminy = types[i].miny;
	placeobjectminz = types[i].minz;
	placeobjectmaxx = types[i].maxx;
	placeobjectmaxy = types[i].maxy;
	placeobjectmaxz = types[i].maxz;
}

void pickmonstertype(int level)
{
	pickobjecttype(monstertypes, sizeof(monstertypes) / sizeof(objecttype_t), level);
}

void pickammotype(int level)
{
	pickobjecttype(ammotypes, sizeof(ammotypes) / sizeof(objecttype_t), level);
}

void pickhealthtype(int level)
{
	pickobjecttype(healthtypes, sizeof(healthtypes) / sizeof(objecttype_t), level);
}

void generatelevels()
{
	int ex, ey, level, rx1, ry1, rx2, ry2, rsx, rsy, i, x, y, z, j, m, entx, enty, entz, startx, starty, monsterhealth, monsterdamage;
	int monsterhealtharray[levels], monsterdamagearray[levels];
	printf("generating levels\n");
	memset(monsterhealtharray, 0, sizeof(monsterhealtharray));
	memset(monsterdamagearray, 0, sizeof(monsterdamagearray));
	startx = starty = ex = ey = levelsize / 2;
	x = ex * cellsize - leveldist + (cellsize/2);
	y = ey * cellsize - leveldist + (cellsize/2);
	z = -128 + 24;
	makeentity("info_player_start", x, y, z, -16, -16, -24, 16, 16, 32, 0, 0);
	makeentity("weapon_supershotgun", x + 40, y - 100, z, -16, -16, 0, 16, 16, 56, 0, 0);
	makeentity("weapon_nailgun", x + 40, y - 60, z, -16, -16, 0, 16, 16, 56, 0, 0);
	makeentity("weapon_supernailgun", x + 40, y - 20, z, -16, -16, 0, 16, 16, 56, 0, 0);
	makeentity("weapon_grenadelauncher", x + 40, y + 20, z, -16, -16, 0, 16, 16, 56, 0, 0);
	makeentity("weapon_rocketlauncher", x + 40, y + 60, z, -16, -16, 0, 16, 16, 56, 0, 0);
	makeentity("weapon_lightning", x + 40, y + 100, z, -16, -16, 0, 16, 16, 56, 0, 0);
	for (level = 0;level < levels;level++)
	{
		printf("generating level %d\n", level+1);
		rsx = intrandom(roomsize_min, roomsize_max);rsy = intrandom(roomsize_min, roomsize_max);
		rx1 = ex - (rsx / 2);ry1 = ey - (rsy / 2);rx2 = rx1 + rsx;ry2 = ry1 + rsy;
		if (rx1 < 1) {i = (1 - rx1);rx1 += i;rx2 += i;}
		if (ry1 < 1) {i = (1 - ry1);ry1 += i;ry2 += i;}
		if (rx2 > (levelsize-1)) {i = rx2 - (levelsize-1);rx1 -= i;rx2 -= i;}
		if (ry2 > (levelsize-1)) {i = ry2 - (levelsize-1);ry1 -= i;ry2 -= i;}
		clearlevel(level);
		clearroom(level, rx1, ry1, rx2, ry2);
		mapcell(ex-1,ey-1,level).wall = walltype_empty;
		mapcell(ex  ,ey-1,level).wall = walltype_empty;
		mapcell(ex+1,ey-1,level).wall = walltype_empty;
		mapcell(ex-1,ey  ,level).wall = walltype_empty;
		mapcell(ex  ,ey  ,level).wall = walltype_empty;
		mapcell(ex+1,ey  ,level).wall = walltype_empty;
		mapcell(ex-1,ey+1,level).wall = walltype_empty;
		mapcell(ex  ,ey+1,level).wall = walltype_empty;
		mapcell(ex+1,ey+1,level).wall = walltype_empty;
		mapcell(ex-1,ey-1,level).special = special_entranceexit;
		mapcell(ex  ,ey-1,level).special = special_entranceexit;
		mapcell(ex+1,ey-1,level).special = special_entranceexit;
		mapcell(ex-1,ey  ,level).special = special_entranceexit;
		mapcell(ex  ,ey  ,level).special = special_entranceexit;
		mapcell(ex+1,ey  ,level).special = special_entranceexit;
		mapcell(ex-1,ey+1,level).special = special_entranceexit;
		mapcell(ex  ,ey+1,level).special = special_entranceexit;
		mapcell(ex+1,ey+1,level).special = special_entranceexit;
		randomemptyarea(&x, &y, rx1+1, ry1+1, rx2-1, ry2-1, 1, 1, level);
		mapcell(x,y,level).special = special_elderceilinglight;
		printf("rooms: *");
		makerooms(level, rx1, ry1, rx2, ry2);
		printf("\n");
		/*
		for (i = 0;i < lightsperlevel;i++)
		{
			randomemptyarea(&x, &y, 1, 1, levelsize-1, levelsize-1, 3, 3, level);
			mapcell[level][y+1][x+1].special = special_torchstand;
		}
		*/
		if (level < (levels-1)) // on the final level there is no exit
		{
			// find a distant location for the exit
			int bestx = -1;
			int besty = -1;
			int best = -1;
			printf("placing exit\n");
			for (i = 0;i < 1000;i++)
			{
				randomemptyarea(&x, &y, 1, 1, levelsize-1, levelsize-1, 5, 5, level);
				x += 1;y += 1;
				j = (x - ex) * (x - ex) + (y - ey) * (y - ey);
				if (j > best)
				{
					best = j;
					bestx = x;
					besty = y;
				}
			}
			if (best < 0)
			{
				printf("could not find a place for an exit\n");
				exit(1);
			}
			ex = bestx;ey = besty;
			mapcell(ex-1,ey-1,level).wall = walltype_hole;
			mapcell(ex  ,ey-1,level).wall = walltype_hole;
			mapcell(ex+1,ey-1,level).wall = walltype_hole;
			mapcell(ex-1,ey  ,level).wall = walltype_hole;
			mapcell(ex  ,ey  ,level).wall = walltype_hole;
			mapcell(ex+1,ey  ,level).wall = walltype_hole;
			mapcell(ex-1,ey+1,level).wall = walltype_hole;
			mapcell(ex  ,ey+1,level).wall = walltype_hole;
			mapcell(ex+1,ey+1,level).wall = walltype_hole;
		}
	}
	printf("placing monsters and items\n");
	for (level = 0;level < levels;level++)
	{
		// place the monsters
		monsterhealth = 0;
		monsterdamage = 0;
		i = 0;
		while(i < monstersperlevel)
		{
			pickmonstertype(level);
			randomemptyarea(&x, &y, 1, 1, levelsize-1, levelsize-1, 3, 3, level);
			if (level == 0)
			{
				while(abs(x - startx) < 12 && abs(y - starty) < 12)
					randomemptyarea(&x, &y, 1, 1, levelsize-1, levelsize-1, 3, 3, level);
			}
			for (j = 0;j < placeobjects;j++)
			{
				for (m = 0;m < 15;m++)
				{
					entx = intrandom(-192, 193) + x * cellsize - leveldist + (cellsize/2);
					enty = intrandom(-192, 193) + y * cellsize - leveldist + (cellsize/2);
					entz = level * -192 - 128 - placeobjectminz;
					if (checkbox(entx + placeobjectminx - 1, enty + placeobjectminy - 1, entz + placeobjectminz, entx + placeobjectmaxx + 1, enty + placeobjectmaxy + 1, entz + placeobjectmaxz))
					{
						// found a spot
						makeentity(placeobjectname, entx, enty, entz, placeobjectminx, placeobjectminy, placeobjectminz, placeobjectmaxx, placeobjectmaxy, placeobjectmaxz, placeobjectrandomangle ? rand() % 360 : 0, ENT_MONSTER);
						monsterhealth += placeobjecthealth;
						monsterdamage += placeobjectdamage;
						i++;
						break;
					}
				}
			}
		}
		monsterhealtharray[level] = (int) (monsterhealth * 1.20); // place 20% more ammo than needed
		monsterdamagearray[level] = monsterdamage; // how much health to place
		// place enough ammo to handle those monsters
		monsterhealth = (int) (monsterhealth * 1.20); // place 20% more ammo than needed
	}
	for (level = 0;level < levels;level++)
	{
		monsterhealth = monsterhealtharray[level];
		monsterdamage = monsterdamagearray[level];
		i = 0;
		while(i < monsterhealth)
		{
			pickammotype(level);
			randomemptyarea(&x, &y, 1, 1, levelsize-1, levelsize-1, 3, 3, level);
			for (j = 0;j < placeobjects;j++)
			{
				for (m = 0;m < 15;m++)
				{
					entx = intrandom(-192, 193) + x * cellsize - leveldist + (cellsize/2);
					enty = intrandom(-192, 193) + y * cellsize - leveldist + (cellsize/2);
					entz = level * -192 - 128 - placeobjectminz;
					if (checkbox(entx + placeobjectminx - 1, enty + placeobjectminy - 1, entz + placeobjectminz, entx + placeobjectmaxx + 1, enty + placeobjectmaxy + 1, entz + placeobjectmaxz))
					{
						// found a spot
						if (!strcmp(placeobjectname, "item_shells") || !strcmp(placeobjectname, "item_spikes") || !strcmp(placeobjectname, "item_rockets") || !strcmp(placeobjectname, "item_cells"))
							makeentity(placeobjectname, entx, enty, entz, placeobjectminx, placeobjectminy, placeobjectminz, placeobjectmaxx, placeobjectmaxy, placeobjectmaxz, placeobjectrandomangle ? rand() % 360 : 0, ENT_AMMO);
						else
							makeentity(placeobjectname, entx, enty, entz, placeobjectminx, placeobjectminy, placeobjectminz, placeobjectmaxx, placeobjectmaxy, placeobjectmaxz, placeobjectrandomangle ? rand() % 360 : 0, 0);
						i += placeobjectdamage;
						break;
					}
				}
			}
		}
		// place enough health and armor to handle how much damage they're likely to do to the player
		i = 0;
		while(i < monsterdamage)
		{
			pickhealthtype(level);
			randomemptyarea(&x, &y, 1, 1, levelsize-1, levelsize-1, 3, 3, level);
			for (j = 0;j < placeobjects;j++)
			{
				for (m = 0;m < 15;m++)
				{
					entx = intrandom(-192, 193) + x * cellsize - leveldist + (cellsize/2);
					enty = intrandom(-192, 193) + y * cellsize - leveldist + (cellsize/2);
					entz = level * -192 - 128 - placeobjectminz;
					if (checkbox(entx + placeobjectminx - 1, enty + placeobjectminy - 1, entz + placeobjectminz, entx + placeobjectmaxx + 1, enty + placeobjectmaxy + 1, entz + placeobjectmaxz))
					{
						// found a spot
						makeentity(placeobjectname, entx, enty, entz, placeobjectminx, placeobjectminy, placeobjectminz, placeobjectmaxx, placeobjectmaxy, placeobjectmaxz, placeobjectrandomangle ? rand() % 360 : 0, 0);
						i += placeobjecthealth;
						break;
					}
				}
			}
		}
	}
}

FILE* outfile;

void map_beginentity() {fprintf(outfile, "{\n");}
void map_endentity() {fprintf(outfile, "}\n");}
void map_beginbrush() {fprintf(outfile, "{\n");}
void map_endbrush() {fprintf(outfile, "}\n");}
void map_kvtext(char* key, char* value) {fprintf(outfile, "\"%s\" \"%s\"\n", key, value);}
void map_kvfloat(char* key, float value) {fprintf(outfile, "\"%s\" \"%.0f\"\n", key, value);}
void map_kvvector(char* key, float x, float y, float z) {fprintf(outfile, "\"%s\" \"%.0f %.0f %.0f\"\n", key, x, y, z);}
void map_brushface(int x1, int y1, int z1, int x2, int y2, int z2, int x3, int y3, int z3, char* texture, float tx, float ty, float tr, float tsx, float tsy) {fprintf(outfile, "( %d %d %d ) ( %d %d %d ) ( %d %d %d ) %s %.0f %.0f %.0f %.0f %.0f\n", x1,y1,z1, x2,y2,z2, x3,y3,z3, texture, tx,ty,tr,tsx,tsy);}
void map_cube(int x1, int y1, int z1, int x2, int y2, int z2, char* texture, char* toptexture, char* bottomtexture)
{
	map_beginbrush();
	map_brushface(x1,y2,z2, x1,y1,z2, x1,y1,z1, texture, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f); // west face
	map_brushface(x2,y2,z2, x1,y2,z2, x1,y2,z1, texture, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f); // north face
	map_brushface(x2,y1,z2, x2,y2,z2, x2,y2,z1, texture, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f); // east face
	map_brushface(x1,y1,z2, x2,y1,z2, x2,y1,z1, texture, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f); // south face
	map_brushface(x1,y1,z2, x1,y2,z2, x2,y2,z2, toptexture, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f); // top face
	map_brushface(x2,y2,z1, x1,y2,z1, x1,y1,z1, bottomtexture, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f); // bottom face
	map_endbrush();
}
void mapobj_beginbrush() {fprintf(outfile, "{\n");}
void mapobj_endbrush() {fprintf(outfile, "}\n");}
void mapobj_brushface(int ox, int oy, int oz, int x1, int y1, int z1, int x2, int y2, int z2, int x3, int y3, int z3, char* texture, float tx, float ty, float tr, float tsx, float tsy) {fprintf(outfile, "( %d %d %d ) ( %d %d %d ) ( %d %d %d ) %s %.0f %.0f %.0f %.0f %.0f\n", x1+ox,y1+oy,z1+oz, x2+ox,y2+oy,z2+oz, x3+ox,y3+oy,z3+oz, texture, tx,ty,tr,tsx,tsy);}
void mapobj_light(char* classname, int x, int y, int z, int light) {makelight(classname, x, y, z, light);}
void mapobj_cube(int ox, int oy, int oz, int x1, int y1, int z1, int x2, int y2, int z2, char* texture, char* toptexture, char* bottomtexture)
{
	mapobj_beginbrush();
	mapobj_brushface(ox,oy,oz, x1,y2,z2, x1,y1,z2, x1,y1,z1, texture, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f); // west face
	mapobj_brushface(ox,oy,oz, x2,y2,z2, x1,y2,z2, x1,y2,z1, texture, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f); // north face
	mapobj_brushface(ox,oy,oz, x2,y1,z2, x2,y2,z2, x2,y2,z1, texture, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f); // east face
	mapobj_brushface(ox,oy,oz, x1,y1,z2, x2,y1,z2, x2,y1,z1, texture, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f); // south face
	mapobj_brushface(ox,oy,oz, x1,y1,z2, x1,y2,z2, x2,y2,z2, toptexture, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f); // top face
	mapobj_brushface(ox,oy,oz, x2,y2,z1, x1,y2,z1, x1,y1,z1, bottomtexture, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f); // bottom face
	mapobj_endbrush();
}

#if 0
void mapobj_torchstand(int ox, int oy, int oz)
{
	/*
	mapobj_beginbrush();
	mapobj_brushface(ox,oy,oz, -16,-16, 64, -16,-16,-16, -16, 48,-16, "METAL2_2", 0.0f, 0.0f, 0.0f, 1.0f, 1.0f);
	mapobj_brushface(ox,oy,oz,  -8, 16, 64,  -8, 16,-16,   8, 16,-16, "METAL2_2", 0.0f, 0.0f, 0.0f, 1.0f, 1.0f);
	mapobj_brushface(ox,oy,oz,  16, 60, 64,  16, 60,-16,  16, -4,-16, "METAL2_2", 0.0f, 0.0f, 0.0f, 1.0f, 1.0f);
	mapobj_brushface(ox,oy,oz,   8,-16, 64,   8,-16,-16,  -8,-16,-16, "METAL2_2", 0.0f, 0.0f, 0.0f, 1.0f, 1.0f);
	mapobj_brushface(ox,oy,oz,   8, 48,  0,  -8, 48,  0,  -8,-16,  0, "METAL2_2", 0.0f, 0.0f, 0.0f, 1.0f, 1.0f);
	mapobj_brushface(ox,oy,oz,   0, -4, 12,   0,  4, 12,  16, -4, 12, "METAL2_2", 0.0f, 0.0f, 0.0f, 1.0f, 1.0f);
	mapobj_brushface(ox,oy,oz, -16, 16,  8, -12,  0, 12, -16,  0,  8, "METAL2_2", 0.0f, 0.0f, 0.0f, 1.0f, 1.0f);
	mapobj_brushface(ox,oy,oz,  12, 16, 12,  16,  0,  8,  12,  0, 12, "METAL2_2", 0.0f, 0.0f, 0.0f, 1.0f, 1.0f);
	mapobj_brushface(ox,oy,oz,   4,-12, 12, -11,-16,  8, -11,-12, 12, "METAL2_2", 0.0f, 0.0f, 0.0f, 1.0f, 1.0f);
	mapobj_brushface(ox,oy,oz,   4, 16,  8, -11, 12, 12, -11, 16,  8, "METAL2_2", 0.0f, 0.0f, 0.0f, 1.0f, 1.0f);
	mapobj_endbrush();
	*/

	mapobj_beginbrush();
	mapobj_brushface(ox,oy,oz, -16, 48, 80, -16,-16, 80, -16,-16,  0, "METAL2_2", 0.0f, 0.0f, 0.0f, 1.0f, 1.0f);
	mapobj_brushface(ox,oy,oz,   8, 16, 80,  -8, 16, 80,  -8, 16,  0, "METAL2_2", 0.0f, 0.0f, 0.0f, 1.0f, 1.0f);
	mapobj_brushface(ox,oy,oz,  16, -4, 80,  16, 60, 80,  16, 60,  0, "METAL2_2", 0.0f, 0.0f, 0.0f, 1.0f, 1.0f);
	mapobj_brushface(ox,oy,oz,  -8,-16, 80,   8,-16, 80,   8,-16,  0, "METAL2_2", 0.0f, 0.0f, 0.0f, 1.0f, 1.0f);
	mapobj_brushface(ox,oy,oz,  -8,-16, 48,  -8, 48, 48,   8, 48, 48, "METAL2_2", 0.0f, 0.0f, 0.0f, 1.0f, 1.0f);
	mapobj_brushface(ox,oy,oz,  16, -4, 36,   0,  4, 36,   0, -4, 36, "METAL2_2", 0.0f, 0.0f, 0.0f, 1.0f, 1.0f);
	mapobj_brushface(ox,oy,oz, -16,  0, 40, -12,  0, 36, -16, 16, 40, "METAL2_2", 0.0f, 0.0f, 0.0f, 1.0f, 1.0f);
	mapobj_brushface(ox,oy,oz,  12,  0, 36,  16,  0, 40,  12, 16, 36, "METAL2_2", 0.0f, 0.0f, 0.0f, 1.0f, 1.0f);
	mapobj_brushface(ox,oy,oz, -11,-12, 36, -11,-16, 40,   4,-12, 36, "METAL2_2", 0.0f, 0.0f, 0.0f, 1.0f, 1.0f);
	mapobj_brushface(ox,oy,oz, -11, 16, 40, -11, 12, 36,   4, 16, 40, "METAL2_2", 0.0f, 0.0f, 0.0f, 1.0f, 1.0f);
	mapobj_endbrush();

	mapobj_beginbrush();
	mapobj_brushface(ox,oy,oz,  -8, 56, 80,  -8, -8, 80,  -8, -8,  0, "METAL2_2", 0.0f, 0.0f, 0.0f, 1.0f, 1.0f);
	mapobj_brushface(ox,oy,oz,   8,  8, 80,  -8,  8, 80,  -8,  8,  0, "METAL2_2", 0.0f, 0.0f, 0.0f, 1.0f, 1.0f);
	mapobj_brushface(ox,oy,oz,   8,-16, 80,   8, 48, 80,   8, 48,  0, "METAL2_2", 0.0f, 0.0f, 0.0f, 1.0f, 1.0f);
	mapobj_brushface(ox,oy,oz,  -8, -8, 80,   8, -8, 80,   8, -8,  0, "METAL2_2", 0.0f, 0.0f, 0.0f, 1.0f, 1.0f);
	mapobj_brushface(ox,oy,oz,   8, 48,  0,  -8, 48,  0,  -8,-16,  0, "METAL2_2", 0.0f, 0.0f, 0.0f, 1.0f, 1.0f);
	mapobj_brushface(ox,oy,oz,  16,  0, 36,   0,-12, 36,   0,  0, 36, "METAL2_2", 0.0f, 0.0f, 0.0f, 1.0f, 1.0f);
	mapobj_endbrush();

	mapobj_light("light_flame_large_yellow", ox-1, oy-1, oz+56, 200);
	mapobj_light("light"                   , ox-1, oy-1, oz+80, 600);
}
#endif

void mapobj_elderceilinglight(int ox, int oy, int oz)
{
//	map_cube(-16, -16, 128, 16, 16, 132, "METAL2_2", "METAL2_2", "LIGHT1_3")
	mapobj_beginbrush();
	mapobj_brushface(ox,oy,oz, -32, 32,132, -32,-32,132, -32,-32,128, "METAL2_2", 0.0f, 0.0f, 0.0f, 1.0f, 1.0f); // west face
	mapobj_brushface(ox,oy,oz,  32, 32,132, -32, 32,132, -32, 32,128, "METAL2_2", 0.0f, 0.0f, 0.0f, 1.0f, 1.0f); // north face
	mapobj_brushface(ox,oy,oz,  32,-32,132,  32, 32,132,  32, 32,128, "METAL2_2", 0.0f, 0.0f, 0.0f, 1.0f, 1.0f); // east face
	mapobj_brushface(ox,oy,oz, -32,-32,132,  32,-32,132,  32,-32,128, "METAL2_2", 0.0f, 0.0f, 0.0f, 1.0f, 1.0f); // south face
	mapobj_brushface(ox,oy,oz, -32,-32,132, -32, 32,132,  32, 32,132, "METAL2_2", 0.0f, 0.0f, 0.0f, 1.0f, 1.0f); // top face
	mapobj_brushface(ox,oy,oz,  32, 32,128, -32, 32,128, -32,-32,128, "LIGHT1_3", 0.0f, 0.0f, 0.0f, 1.0f, 1.0f); // bottom face
	mapobj_endbrush();

	mapobj_light("light", ox, oy, oz+124, 600);
}

void mapobj_doorx(int ox, int oy, int oz)
{
	map_beginentity();
	map_kvtext("sounds", "1");
	map_kvtext("angle", "0");
	map_kvtext("classname", "func_door");
	map_beginbrush();
	mapobj_brushface(ox,oy,oz,   0, 16, 80,128, 16, 80,128, 16,  0,"ADOOR02_2", 0.0f - ox, 64.0f, 0.0f, 1.0f, 1.0f);
	mapobj_brushface(ox,oy,oz, 128, 48, 80,  0, 48, 80,  0, 48,  0,"ADOOR02_2", 0.0f - ox, 64.0f, 0.0f, 1.0f, 1.0f);
	mapobj_brushface(ox,oy,oz,   0,  0,128,  0,128,128,128,128,128,"ADOOR03_3", 0.0f, 0.0f, 0.0f, 1.0f, 1.0f);
	mapobj_brushface(ox,oy,oz, 128,128,  0,  0,128,  0,  0,  0,  0,"ADOOR03_3", 0.0f, 0.0f, 0.0f, 1.0f, 1.0f);
	mapobj_brushface(ox,oy,oz, 128,  0,144,128, 64, 19,128,  0,128,"ADOOR03_3", 0.0f, 0.0f, 0.0f, 1.0f, 1.0f);
	mapobj_brushface(ox,oy,oz,  64, 31,128, 64,128, 64, 64, 47,128,"ADOOR03_3", 0.0f, 0.0f, 0.0f, 1.0f, 1.0f);
	map_endbrush();
	map_endentity();
	map_beginentity();
	map_kvtext("sounds", "1");
	map_kvtext("angle", "180");
	map_kvtext("classname","func_door");
	map_beginbrush();
	mapobj_brushface(ox,oy,oz,   0, 16, 80,128, 16, 80,128, 16,  0,"ADOOR02_2", 0.0f - ox, 64.0f, 0.0f, 1.0f, 1.0f);
	mapobj_brushface(ox,oy,oz, 128, 48, 80,  0, 48, 80,  0, 48,  0,"ADOOR02_2", 0.0f - ox, 64.0f, 0.0f, 1.0f, 1.0f);
	mapobj_brushface(ox,oy,oz,   0,128, 80,  0,  0, 80,  0,  0,  0,"ADOOR03_3", 0.0f, 0.0f, 0.0f, 1.0f, 1.0f);
	mapobj_brushface(ox,oy,oz,   0,  0,128,  0,128,128,128,128,128,"ADOOR03_3", 0.0f, 0.0f, 0.0f, 1.0f, 1.0f);
	mapobj_brushface(ox,oy,oz, 128,128,  0,  0,128,  0,  0,  0,  0,"ADOOR03_3", 0.0f, 0.0f, 0.0f, 1.0f, 1.0f);
	mapobj_brushface(ox,oy,oz,  64, 47,128, 64,128, 64, 64, 31,128,"ADOOR03_3", 0.0f, 0.0f, 0.0f, 1.0f, 1.0f);
	map_endbrush();
	map_endentity();
}

void mapobj_doory(int ox, int oy, int oz)
{
	map_beginentity();
	map_kvtext("sounds", "1");
	map_kvtext("angle", "90");
	map_kvtext("classname", "func_door");
	map_beginbrush();
	mapobj_brushface(ox,oy,oz,  16, 95,128, 16,192, 64, 16,111,128,"ADOOR02_2", 0.0f - oy, 64.0f, 0.0f, 1.0f, 1.0f);
	mapobj_brushface(ox,oy,oz,  48, 64,144, 48,128, 19, 48, 64,128,"ADOOR02_2", 0.0f - oy, 64.0f, 0.0f, 1.0f, 1.0f);
	mapobj_brushface(ox,oy,oz,  64,128, 80,-64,128, 80,-64,128,  0,"ADOOR03_3", 0.0f, 0.0f, 0.0f, 1.0f, 1.0f);
	mapobj_brushface(ox,oy,oz, -64, 64, 80, 64, 64, 80, 64, 64,  0,"ADOOR03_3", 0.0f, 0.0f, 0.0f, 1.0f, 1.0f);
	mapobj_brushface(ox,oy,oz, -64, 64,128,-64,192,128, 64,192,128,"ADOOR03_3", 0.0f, 0.0f, 0.0f, 1.0f, 1.0f);
	mapobj_brushface(ox,oy,oz,  64,192,  0,-64,192,  0,-64, 64,  0,"ADOOR03_3", 0.0f, 0.0f, 0.0f, 1.0f, 1.0f);
	map_endbrush();
	map_endentity();
	map_beginentity();
	map_kvtext("sounds", "1");
	map_kvtext("angle", "270");
	map_kvtext("classname", "func_door");
	map_beginbrush();
	mapobj_brushface(ox,oy,oz,  16,128, 80, 16,  0, 80, 16,  0,  0,"ADOOR02_2", 0.0f - oy, 64.0f, 0.0f, 1.0f, 1.0f);
	mapobj_brushface(ox,oy,oz,  48, 47,128, 48,128, 64, 48, 31,128,"ADOOR02_2", 0.0f - oy, 64.0f, 0.0f, 1.0f, 1.0f);
	mapobj_brushface(ox,oy,oz, 128, 64, 80,  0, 64, 80,  0, 64,  0,"ADOOR03_3", 0.0f, 0.0f, 0.0f, 1.0f, 1.0f);
	mapobj_brushface(ox,oy,oz,   0,  0, 80,128,  0, 80,128,  0,  0,"ADOOR03_3", 0.0f, 0.0f, 0.0f, 1.0f, 1.0f);
	mapobj_brushface(ox,oy,oz,   0,  0,128,  0,128,128,128,128,128,"ADOOR03_3", 0.0f, 0.0f, 0.0f, 1.0f, 1.0f);
	mapobj_brushface(ox,oy,oz, 128,128,  0,  0,128,  0,  0,  0,  0,"ADOOR03_3", 0.0f, 0.0f, 0.0f, 1.0f, 1.0f);
	map_endbrush();
	map_endentity();
}

#if WIN32
#include <windows.h>
#include <process.h>
#include <winbase.h>
#endif

void savemap(char *filename)
{
	int x, y, level, e, floorsolid, wallsolid;
	int ox, oy, oz, ox2;
#if WIN32
	SetCurrentDirectory("c:\\quake\\id1\\maps");
#endif
	printf("saving map\nopening output map file\n");
	if ((outfile = fopen(filename, "wb")))
	{
		printf("fopen successful\n");
		map_beginentity();
		map_kvtext("classname", "worldspawn");
		map_kvtext("wad", "quake101.wad");
		// top ceiling
		map_cube(-leveldist,-leveldist,0, leveldist,leveldist,64, "WBRICK1_5", "WALL9_8", "CITY4_2");
		// bottom floor
		map_cube(-leveldist,-leveldist,levels * -192, leveldist,leveldist,levels * -192 + 64, "WBRICK1_5", "WALL9_8", "CITY4_2");
		for (level = 0;level < levels;level++)
		{
			printf("writing level %d\n", level + 1);
			oz = level * -192;
			for (y = 0;y < levelsize-1;y++)
			{
				oy = y * cellsize - leveldist;
				ox2 = -leveldist;
				if (level < (levels-1)) // no holes in the floor on the last level
				{
					for (x = 0, floorsolid = FALSE;x < levelsize-1;x++)
					{
						ox = x * cellsize - leveldist;
						if (mapcell(x,y,level).wall == walltype_hole) // floor is open
						{
							if (floorsolid) // finish up previous run of floor
								map_cube(ox2, oy, oz-192, ox, oy+cellsize, oz-128, "WBRICK1_5", "WALL9_8", "CITY4_2");
							floorsolid = FALSE;
						}
						else // floor is solid
						{
							if (!floorsolid) // start a new run of floor
								ox2 = ox;
							floorsolid = TRUE;
						}
					}
					if (floorsolid) // finish up previous run of floor
						map_cube(ox2,oy,oz-192, leveldist,oy+cellsize,oz-128, "WBRICK1_5", "WALL9_8", "CITY4_2");
				}
				wallsolid = FALSE;
				ox2 = -leveldist;
				for (x = 0;x < levelsize-1;x++)
				{
					ox = x * cellsize - leveldist;
					switch (mapcell(x,y,level).wall)
					{
					case walltype_hole: // hole in the floor
					case walltype_empty: // empty space
					case walltype_occupied: // a door or something is here
						if (wallsolid) // finish up previous run of wall
							map_cube(ox2,oy,oz-128, ox,oy+cellsize,oz, "WBRICK1_5", "WBRICK1_5", "WBRICK1_5");
						wallsolid = FALSE;
						break;
						/*
					case walltype_column: // column
						if (wallsolid) // finish up previous run of wall
								map_cube(ox2,oy,oz-128, ox,oy+cellsize,oz, "WBRICK1_5", "WBRICK1_5", "WBRICK1_5");
						wallsolid = FALSE;
						map_cube(ox,oy,oz-128, ox+24,oy+24,oz, "WBRICK1_5", "WBRICK1_5", "WBRICK1_5"); //WALL14_5");
						break;
						*/
					// wall
					default:
						if (!wallsolid)
							ox2 = ox;
						wallsolid = TRUE;
						//map_cube(ox,oy,oz-128, ox+32,oy+32,oz, "WBRICK1_5");
						break;
					}
				}
				if (wallsolid) // finish up previous run of wall
					map_cube(ox2,oy,oz-128, leveldist,oy+cellsize,oz, "WBRICK1_5", "WBRICK1_5", "WBRICK1_5");
			}
		}
		for (level = 0;level < levels;level++)
		{
			printf("level %d\n", level + 1);
			oz = level * -192;
			for (y = 0;y < levelsize-1;y++)
			{
				oy = y * cellsize - leveldist;
				for (x = 0;x < levelsize-1;x++)
				{
					ox = x * cellsize - leveldist;
					switch (mapcell(x,y,level).special)
					{
					case special_empty:
						break;
					case special_entranceexit:
						// empty space but protects it from everything else
						break;
//					case special_torchstand:
//						mapobj_torchstand(ox+(cellsize/2), oy+(cellsize/2), oz-128);
//						break;
					case special_elderceilinglight:
						mapobj_elderceilinglight(ox+(cellsize/2), oy+(cellsize/2), oz-128);
						break;
					case special_doorx:
						break;
					case special_doory:
						break;
					default:
						printf("undefined special %i\n", mapcell(x,y,level).special);
						break;
					}
				}
			}
		}
		map_endentity();
		printf("writing brush model entities\n");
		for (level = 0;level < levels;level++)
		{
			printf("level %d\n", level + 1);
			oz = level * -192;
			for (y = 0;y < levelsize-1;y++)
			{
				oy = y * cellsize - leveldist;
				for (x = 0;x < levelsize-1;x++)
				{
					ox = x * cellsize - leveldist;
					switch (mapcell(x,y,level).special)
					{
					case special_empty:
						break;
					case special_entranceexit:
						break;
//					case special_torchstand:
//						mapobj_torchstand(ox+(cellsize/2), oy+(cellsize/2), oz-128);
//						break;
					case special_elderceilinglight:
						break;
					case special_doorx:
						mapobj_doorx(ox, oy, oz-128);
						break;
					case special_doory:
						mapobj_doory(ox, oy, oz-128);
						break;
					default:
						printf("undefined special %i\n", mapcell(x,y,level).special);
						break;
					}
				}
			}
		}
		printf("writing point entities\n");
		for (e = 0;e < maxentities;e++)
		{
			if (entity[e].active)
			{
				map_beginentity();
				map_kvtext("classname", entity[e].classname);
//				if (entity[e].ox) // specific origin
					map_kvvector("origin", (float) entity[e].ox, (float) entity[e].oy, (float) entity[e].oz);
//				else if (strncmp(entity[e].classname, "item", 4) == 0) // items
//					map_kvvector("origin", (float) entity[e].x * cellsize - leveldist + (cellsize/2) - 16, (float) entity[e].y * cellsize - leveldist + (cellsize/2) - 16,entity[e].level * -192.0f - 128.0f);
//				else // monsters and other centered objects
//					map_kvvector("origin", (float) entity[e].x * cellsize - leveldist + (cellsize/2), (float) entity[e].y * cellsize - leveldist + (cellsize/2),entity[e].level * -192.0f - 104.0f);
				if (entity[e].light)
					map_kvfloat("light", (float) entity[e].light);
				if (entity[e].angle)
					map_kvfloat("angle", (float) entity[e].angle);
				if (entity[e].flags & ENT_AMMO)
					map_kvtext("spawnflags", "1"); // big box
				if (entity[e].flags & ENT_MONSTER)
				{
//					if (level >= 2)
//					{
//						map_kvtext("spawnflags", "128");
//						map_kvtext("targetname", "monsterspawn");
//					}
				}
				map_endentity();
			}
		}
//		map_beginentity();
//		map_kvtext("classname", "trigger_once");
//		map_kvtext("target", "monsterspawn");
////		map_cube(-levelcenter, -levelcenter, levels * -192, levelcenter, levelcenter, 64, "TRIGGER", "TRIGGER", "TRIGGER");
////		map_cube(entity[0].ox - 64, entity[0].oy - 64, entity[0].oz - 24, entity[0].ox + 64, entity[0].oy + 64, entity[0].oz - 24 + 128, "TRIGGER", "TRIGGER", "TRIGGER");
//		map_cube(-levelcenter, -levelcenter, 1 * -192, levelcenter, levelcenter, 1 * -192 + 128, "TRIGGER", "TRIGGER", "TRIGGER");
//		map_endentity();
		printf("closing output map file\n");
		fclose(outfile);
#if WIN32
		if (_spawnlp(_P_WAIT, "hqbsp", "hqbsp", filename, NULL))
		{
#if WIN32 && _DEBUG
			getchar();
#endif
			return;
		}
		if (_spawnlp(_P_WAIT, "hvis", "hvis", filename, NULL))
		{
#if WIN32 && _DEBUG
			getchar();
#endif
			return;
		}
		if (_spawnlp(_P_WAIT, "hlight", "hlight", "-extra", filename, NULL))
		{
#if WIN32 && _DEBUG
			getchar();
#endif
			return;
		}
#endif
		printf("compiled map\n");
	}
}

#include <time.h>

void usage(void)
{
	printf("dpmapgen2d by Forest \"LordHavoc\" Wroncy-Hale (havoc@gamevisions.com or havoc@inside3d.com)\nusage: dpmapgen2d [-monsters n] [-roomsizemin n] [-roomsizemax n] [-levelsize n] [-cellsize n] [-levels n] [--help] [-?] filename.map\n");
}

int main(int argc, char** argv)
{
	int i, n, monsters;
	monsters = 400;
	roomsize_min = 6;
	roomsize_max = 10;
	levelsize = 32;
	cellsize = 64;
	styles = 1;
	levelsperstyle = 8;

	for (i = 1;i < argc;i++)
	{
		n = 0;
		if (argv[i][0] == '-')
		{
			if (i + 1 < argc)
				n = atoi(argv[i+1]);
			     if (!strcmp(argv[i], "-monsters")) {i++;monsters = n;}
			else if (!strcmp(argv[i], "-roomsizemin")) {i++;roomsize_min = n;}
			else if (!strcmp(argv[i], "-roomsizemax")) {i++;roomsize_max = n;}
			else if (!strcmp(argv[i], "-levelsize")) {i++;levelsize = n;}
			else if (!strcmp(argv[i], "-cellsize")) {i++;cellsize = n;}
			else if (!strcmp(argv[i], "-levels")) {i++;levelsperstyle = n;}
			else if (!strcmp(argv[i], "--help") || !strcmp(argv[i], "-?"))
			{
				usage();
				return 1;
			}
			else
			{
				printf("unrecognized option \"%s\"\n", argv[i]);
				usage();
				return 1;
			}
		}
		else
		{
			levelcenter = (levelsize * (cellsize/2));
			levels = (levelsperstyle * styles);
			leveldist = (levelsize * cellsize);
			monstersperlevel = monsters / levels;
			mapcelldata = malloc(sizeof(mapcell_t) * levels * levelsize * levelsize);
			memset(mapcelldata, 0, sizeof(mapcell_t) * levels * levelsize * levelsize);

			srand(time(NULL));
			generatelevels();
			savemap(argv[i]);

			free(mapcelldata);
		}
	}

	return 0;
}