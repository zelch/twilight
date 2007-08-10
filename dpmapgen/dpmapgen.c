
#include <stdlib.h>
#include <stdio.h>

#ifndef true
#define true 1
#define false 0
#endif

/*
xxxxxx|---|
xxxxxxD   |
xxxxxx|D--|
-D--xx|   |
|  |--|   |
|  D  D   |
-----------
*/

typedef struct brushface_s
{
	float plane[4];
	float texturesettings[5];
	const char *texturename;
	struct brushface_s *next;
}
brushface_t;

typedef struct brush_s
{
	brushface_t *face;
	struct brush_s *next;
}
brush_t;

typedef struct entityfield_s
{
	struct entityfield_s *next;
	char *key;
	char *value;
}
entityfield_t;

typedef struct entity_s
{
	struct entity_s *next;
	brush_t *brushchain;
	entityfield_t *fieldchain;
}
entity_t;

#define MAX_ROOMLINKS 16

typedef struct room_s
{
	struct room_s *next;
	// entities to add (which may have brushes)
	entity_t *entitychain;
	// links (extracted from entity data)
	int numlinks;
	double linkorigin[16][3];
	char linktype
}
room_t;

typedef struct linkroom_s
{
	double roomorigin[3];
	// numlinks/linkorigin/linktype come from room, and are not stored here
	struct linkroom_s *links[16];
	room_t *room;
}
linkroom_t;

// loaded rooms (to insert at linknodes)
room_t *roomchain = NULL;

void newentityfield(entity_t *entity, char *key, char *value)
{
	entityfield_t *field;
	field = malloc(sizeof(*field) + strlen(key) + 1 + strlen(value) + 1);
	memset(field, 0, sizeof(*field));
	field->next = entity->fieldchain;
	entity->entitychain = field;
	field->key = (char *)(field + 1);
	field->value = field->key + strlen(key) + 1;
	strcpy(field->key, key);
	strcpy(field->value, value);
}

void freefield(entityfield_t *field)
{
	free(field);
}

void newbrushface(brush_t *brush, float normalx, float normaly, float normalz, float dist, const char *texturename, float textureoffsets, float textureoffsett, float textureangle, float texturescales, float texturescalet)
{
	brushface_t *brushface;
	brushface = malloc(sizeof(brushface_t));
	memset(brushface, 0, sizeof(*brushface));
	brushface->next = brush->face;
	brush->face = brushface;
	brushface->plane[0] = normalx;
	brushface->plane[1] = normaly;
	brushface->plane[2] = normalz;
	brushface->plane[3] = dist;
	brushface->texturename = malloc(strlen(texturename) + 1);
	strcpy(brushface->texturename, texturename);
	brushface->texturesettings[0] = textureoffsets;
	brushface->texturesettings[1] = textureoffsett;
	brushface->texturesettings[2] = textureangle;
	brushface->texturesettings[3] = texturescales;
	brushface->texturesettings[4] = texturescalet;
}

void freebrushface(brushface_t *brushface)
{
	free(brushface);
}

brush_t *newbrush(entity_t *entity)
{
	brush_t *brush;
	brush = malloc(sizeof(brush_t));
	memset(brush, 0, sizeof(*brush));
	brush->face = NULL;
	brush->next = entity->brushchain;
	entity->brushchain = brush;
	return brush;
}

void freebrush(brush_t *brush)
{
	for (brushface = brush->face;brushface;brushface = brushfacenext)
	{
		brushfacenext = brushface->next;
		freebrushface(brushface);
	}
	free(brush);
}

entity_t *newentity(room_t *room)
{
	entity_t *entity;
	entity = malloc(sizeof(*entity));
	memset(entity, 0, sizeof(*entity));
	entity->next = room->entitychain;
	room->entitychain = entity;
}

void freeentity(entity_t *entity)
{
	entityfield_t *field, *fieldnext;
	entitybrush_t *brush, *brushnext;
	for (field = entity->fieldchain;field;field = fieldnext)
	{
		fieldnext = field->next;
		freefield(field);
	}
	for (brush = entity->brushchain;brush;brush = brushnext)
	{
		brushnext = brush->next;
		freebrush(brush);
	}
	free(entity);
}

room_t *newroom(void)
{
	room_t *room;
	room = malloc(sizeof(room_t));
	memset(room, 0, sizeof(*room));
	room->next = roomchain;
	roomchain = room;
}

void freeroom(room_t *room)
{
	entity_t *entity, *entitynext;
	for (entity = room->entitychain;entity;entity = entitynext)
	{
		entitynext = entity->next;
		freeentity(entity);
	}
	free(room);
}

void freeroomchain(void)
{
	room_t *room, *roomnext;
	for (room = roomchain;room;room = roomnext)
	{
		roomnext = room->next;
		freeroom(room);
	}
	roomchain = NULL;
}

void room_parseentity(room_t *room, FILE *file)
{
	int pointnum;
	float points[9], textureoffsets, textureoffsett, textureangle, texturescales, texturescalet, normal[3], dist;
	entity_t *entity;
	brush_t *brush;
	const char *token;
	char name[256];
	for (;;)
	{
		token = parsetoken(file);
		if (!token)
			return;
		if (strcmp(token, "{"))
		{
			printf("room_parseentity: error parsing, expected \"%s\" and found \"%s\"\n", "{", token);
			return;
		}
		ent = newentity(room);
		for(;;)
		{
			token = parsetoken(file);
			if (!strcmp("token", "}"))
			{
				// end of entity
				break;
			}
			if (!strcmp("token", "{"))
			{
				// parse a brush
				brush = newbrush(entity);
				for(;;)
				{
					token = parsetoken(file);
					if (!strcmp(token, "}"))
						break;
					for (pointnum = 0;pointnum < 3;pointnum++)
					{
						token = parsetoken(file);
						if (strcmp(token, "("))
						{
							printf("room_parseentity: error parsing, expected \"%s\" and found \"%s\"\n", "(", token);
							break;
						}
						points[pointnum * 3 + 0] = atof(parsetoken(file));
						points[pointnum * 3 + 1] = atof(parsetoken(file));
						points[pointnum * 3 + 2] = atof(parsetoken(file));
						if (strcmp(token, ")"))
						{
							printf("room_parseentity: error parsing, expected \"%s\" and found \"%s\"\n", ")", token);
							break;
						}
					}
					token = parsetoken(file);
					strcpy(name, token);
					textureoffsets = atof(parsetoken(file));
					textureoffsett = atof(parsetoken(file));
					textureangle = atof(parsetoken(file));
					texturescales = atof(parsetoken(file));
					texturescalet = atof(parsetoken(file));
					normal[0] = (points[1] - points[4]) * (points[8] - points[5]) - (points[2] - points[5]) * (points[7] - points[4]);
					normal[1] = (points[2] - points[5]) * (points[6] - points[3]) - (points[0] - points[3]) * (points[8] - points[5]);
					normal[2] = (points[0] - points[3]) * (points[7] - points[4]) - (points[1] - points[4]) * (points[6] - points[3]);
					dist = sqrt(normal[0] * normal[0] + normal[1] * normal[1] + normal[2] * normal[2]);
					if (dist)
						dist = 1.0f / dist;
					normal[0] *= dist;
					normal[1] *= dist;
					normal[2] *= dist;
					dist = normal[0] * points[0] + normal[1] * points[1] + normal[2] * points[2];
					newbrushface(brush, normal[0], normal[1], normal[2], dist, name, textureoffsets, textureoffsett, textureangle, texturescales, texturescalet);
				}
			}
			else
			{
				token = parsetoken(file);
				strcpy(name, token);
				token = parsetoken(file);
				newentityfield(entity, name, token);
			}
		}
	}
}

void room_loadfile(const char *filename)
{
	FILE *file;
	file = fopen(filename, "rb");
	if (file == NULL)
		return;
	room = newroom();
	while (room_parseentity(room, file));
	fclose(file);
	if (room_findentitybyclassname(room->entitychain, "info_linknode") == NULL)
	{
		printf("no info_linknodes found in room file \"%s\"\n", filename);
		freeroom(room);
		return NULL;
	}
	return room;
}

char *findentityfield(entity_t *entity, char *keyname)
{
	entityfield_t *entityfield;
	for (entityfield = entity->fieldchain;entityfield;entityfield = entityfield->next)
		if (!strcmp(entityfield->key, "netname"))
			return entityfield->value;
	return NULL;
}

int checkroom(room_t *room, float *roomorigin)
{
	memset(&linkroom[linkrooms], 0, sizeof(linkroom[linkrooms]));
	linkroom[linkrooms].room = room;
	linkroom[linkrooms].roomorigin[0] = roomorigin[0];
	linkroom[linkrooms].roomorigin[1] = roomorigin[1];
	linkroom[linkrooms].roomorigin[2] = roomorigin[2];
	for (i = 0;i < linkrooms;i++)
	{
		if (
		linkroom[i].
	}
	return true;
}

/*
void insertroom(room_t *room, float *roomorigin)
{
	for (entity = room->entitychain;entity;entity = entity->next)
	{
		classname = findentityfield(entity, "classname");
		if (classname && !strcmp(classname, "worldspawn"))
		{
			// add just the brushes to worldspawn
			newentity = worldentity;
		}
		else
		{
			// add a clone of the whole entity, with a few changes
			newentity = newentity(worldroom);
		}
	}
}
*/

int chooseroom(char *linktype, float *linkorigin)
{
	int i, choiceindex;
	room_t *room;
	for (room = roomchain;room && choices < MAX_CHOICES;room = room->next)
	{
		for (i = 0;i < room->numlinks;i++)
		{
			if (!strcmp(room->linktype[i], linktype) && checkroom(room, linkx - room->linkorigin[0], linky - room->linkorigin[1], linkz - room->linkorigin[2]))
			{
				choice[choices].room = room;
				choice[choices].origin[0] = linkx - room->linkorigin[0];
				choice[choices].origin[1] = linky - room->linkorigin[1];
				choice[choices].origin[2] = linkz - room->linkorigin[2];
				choices++;
			}
		}
	}
	if (choices < 1)
		return false;
	choiceindex = (int)(rand() * (double)choices / (double)RAND_MAX);
	insertroom(choice[choiceindex].room, choice[choiceindex].origin);
	return true;
	/*
		for (entity = room->entitychain;entity;entity = entity->next)
		{
			key_netname = NULL;
			key_classname = NULL;
			key_origin = NULL;
			for (entityfield = entity->fieldchain;entityfield;entityfield = entityfield->next)
			{
				if (!strcmp(entityfield->key, "netname"))
					key_netname = entityfield->value;
				if (!strcmp(entityfield->key, "classname"))
					key_classname = entityfield->value;
				if (!strcmp(entityfield->key, "origin"))
					key_origin = entityfield->value;
			}
			if (!strcmp(classname, "info_linknode") && !strcmp(type, linktype) && sscanf(key_origin, "%f %f %f", &origin[0], &origin[1], &origin[2]))
			{
				if (testroom(room, linkx - origin[0], linky - origin[1], linkz - origin[2]))
				{
					choice[choices].room = room;
					choice[choices].offset[0] = linkx - origin[0];
					choice[choices].offset[1] = linky - origin[1];
					choice[choices].offset[2] = linkz - origin[2];
					choices++;
				}
			}
		}
	}
	if (choices < 1)
		return false;
	choiceindex = (int)(rand() * (double)choices / (double)RAND_MAX);
	room = choice[choiceindex].room;
	for (entity = room->entitychain;entity;entity = entity->next)
	{
	}
	return chooseroom(choi
	*/
	/*
	int i;
	int numtypes;
	for (numtypes = 0;roomtypes[numtypes].function != NULL;numtypes++);
	for (i = 0;i < 10000;i++)
	{
		if (roomtypes[rand() % numtypes].function(doorway))
			return true;
	}
	return false;
	*/
}

void buildworld(void)
{
	insertroom(0, 0, 0, NULL);
}

void saveworld(const char *filename)
{
}

int main(int argc, char **argv)
{
	loadroomfile("rooms/test.map");
	buildworld();
	saveworld("dpgen.map");
	return 0;
}

