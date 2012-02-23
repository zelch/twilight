
float mapgen_enabled;
float mapgen_hasrun;
.float mapgen_entitybelongstoroomnumber;
.string realclassname;
.void() realspawnfunc;
.string roomtemplate;
.string roomtemplatename;
.entity roomtemplate_entitychain;

entity roomtemplatehead;

void() mapgen_roomtemplate_connector =
{
};

float(void() spawnfnc) mapgen_roomtemplate_setup =
{
	local entity head;
	if (!self.roomtemplate)
		return FALSE;

	// see if this entity belongs to a new roomtemplate and create an info entity for it if so
	head = roomtemplatehead;
	while (head)
	{
		if (head.roomtemplate == self.roomtemplate)
			break;
		head = head.enemy;
	}
	if (!head)
	{
		head = spawn();
		head.classname = "info_roomtemplate";
		head.roomtemplate = self.roomtemplate;
		head.enemy = roomtemplatehead;
		roomtemplatehead = head;
	}

	// add this entity to the roomtemplate's entitychain
	self.roomtemplate_entitychain = head.roomtemplate_entitychain;
	head.roomtemplate_entitychain = self;
	// flag the room template as being an entry room if appropriate
	if (self.classname == "info_player_start" || self.classname == "info_player_deathmatch")
	{
		head.lefty = TRUE; // has player starts
		mapgen_enabled = TRUE;
	}

	// set up the delayed spawning aspects
	self.realclassname = self.classname;
	if (self.classname == "info_notnull")
	{
		self.realspawnfunc = mapgen_roomtemplate_connector;
		self.classname = "mapgen_roomtemplate_connector";
	}
	else
	{
		self.realspawnfunc = spawnfnc;
		self.classname = "mapgen_roomtemplate_entity";
	}
	return TRUE;
};

entity(float needplayerstart, string connectortype) mapgen_randomroominfo =
{
	local entity list;
	local entity e;
	local entity roominfo;
	local float roomchoices;
	local float roomchoice;
	roominfo = world;
	roomchoices = 0;
	e = roomtemplatehead;
	while (e)
	{
		if (e.lefty || !needplayerstart)
			roomchoices = roomchoices + 1;
		e = e.chain;
	}
	roomchoice = random() * roomchoices;
	e = list;
	while (e && roomchoice > 0)
	{
		if (e.lefty || !needplayerstart)
		{
			roominfo = e;
			roomchoice = roomchoice - 1;
		}
		e = e.chain;
	}
	return roominfo;
};

float(vector org, entity roominfo, entity connector, float roomnumber) mapgen_spawnroom =
{
	// move room template to match connector.origin to org and spawn room there
	// roomnumber lets us easily despawn the entities if the room fails (which it does a lot!)
	// FIXME CODE THIS
	return FALSE;
};

float(float minrooms, float maxrooms) mapgen_buildmap =
{
	local entity roominfo;
	local entity firstconnector;
	local entity e;
	local entity next;
	local float failed;
	local float tries;
	local float roomnumber;
	local float roomcount;

	failed = FALSE;
	roomcount = 0;
	roomnumber = 0; // this will be incremented before first use

	// pick a random entry room
	roominfo = mapgen_randomroominfo(TRUE, "");
	if (!roominfo)
		return FALSE; // failed to spawn an entry room
	e = roominfo.roomtemplate_entitychain;
	while (e)
	{
		next = e.roomtemplate_entitychain;
		if (e.classname == "mapgen_roomtemplate_connector")
		{
			roomnumber = roomnumber + 1;
			if (mapgen_spawnroom('0 0 0', roominfo, e, roomnumber))
			{
				roomcount = roomcount + 1;
				break;
			}
		}
		e = next;
	}

	// if the entry room failed, give up
	if (e == world)
		return FALSE;

	firstconnector = find(world, classname, "info_notnull");
	while (firstconnector)
	{
		if (firstconnector.roomtemplate)
		{
			tries = 0;
			while (TRUE)
			{
				tries = tries + 1;
				if (tries >= 100)
				{
					failed = TRUE;
					break;
				}
				roominfo = mapgen_randomroominfo(FALSE, firstconnector.message);
				e = roominfo.roomtemplate_entitychain;
				while (e)
				{
					next = e.roomtemplate_entitychain;
					if (e.classname == "mapgen_roomtemplate_connector")
					{
						roomnumber = roomnumber + 1;
						if (mapgen_spawnroom(firstconnector.origin, roominfo, e, roomnumber))
						{
							roomcount = roomcount + 1;
							break;
						}
					}
					e = next;
				}
				if (e)
					break; // suceeded with this room
			}
		}
		remove(firstconnector);
		firstconnector = find(firstconnector, classname, "info_notnull");
	}
	if (roomcount < minrooms)
		failed = TRUE;
	if (failed)
	{
		// destroy them all...
		e = findchainflags(mapgen_entitybelongstoroomnumber, 16777215);
		while(e)
		{
			next = e.chain;
			remove(e);
			e = next;
		}
		return FALSE;
	}
	return TRUE;
}

float() mapgen_start =
{
	local float maxrooms;

	// try repeatedly to generate a valid map, using fewer and fewer rooms because eventually it will succeed
	maxrooms = 50;
	while(maxrooms > 0)
	{
		if (mapgen_buildmap(maxrooms * 0.5, maxrooms))
			return TRUE;
		maxrooms = maxrooms - 1;
	}
	return FALSE;
};
