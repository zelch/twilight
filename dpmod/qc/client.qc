
.float isbot;

.float isadmin, adminnumber, admindigits, adminattempts;

// prototypes
void () W_WeaponFrame;
//void() W_SetCurrentAmmo;
void(entity attacker, float damage, float damgtype, string dethtype) player_pain;
void() player_movestart;
void (vector org) spawn_tfog;
void (vector org, entity death_owner, vector org2) spawn_tdeath;

void() GibPlayer;
void() PlayerDead;

float modelindex_eyes, modelindex_player;
//float modelindex_null;

//used for combo kills
.float combo_time;
.float combo_amount;
//used for killing sprees
.float spree_amount;
.float spree_count;

/*
=============================================================================

				LEVEL CHANGING / INTERMISSION

=============================================================================
*/

float intermission_running;
float intermission_exittime;

/*QUAKED info_intermission (1 0.5 0.5) (-16 -16 -16) (16 16 16)
This is the camera point for the intermission.
Use mangle instead of angle, so you can set pitch or roll as well as yaw.  'pitch roll yaw'
*/
void() info_intermission =
{
};



void() SetNewParms =
{
	// this marks the parms as invalid as far as Inventory_FromParms is
	// concerned, it will take care of the reset on decode
	parm1 = 0;
};

void() SetChangeParms =
{
	if (self.health < 1)
	{
		SetNewParms ();
		return;
	}

	// remove items
	self.items = self.items - (self.items & (IT_KEY1 | IT_KEY2 | IT_INVISIBILITY | IT_INVULNERABILITY | IT_SUIT | IT_QUAD));

	Inventory_ToParms(self);
};

void() DecodeLevelParms =
{
	// reset equipment in some cases
	if (deathmatch || /*self.isbot || */world.model == "maps/start.bsp")
		SetNewParms();

	Inventory_FromParms(self);
};

/*
============
FindIntermission

Returns the entity to view from
============
*/
entity() FindIntermission =
{
	local entity spot;
	local float cyc;

// look for info_intermission first
	spot = find(world, classname, "info_intermission");
	if (spot)
	{
		// pick a random one
		cyc = random() * 50;
		while (cyc > 1)
		{
			spot = find(spot, classname, "info_intermission");
			if (!spot)
				spot = find(spot, classname, "info_intermission");
			cyc = cyc - 1;
		}
		return spot;
	}

// then look for the start position
	spot = find(world, classname, "info_player_start");
	if (spot)
		return spot;

// testinfo_player_start is only found in regioned levels
	spot = find(world, classname, "testplayerstart");
	if (spot)
		return spot;

	objerror ("FindIntermission: no spot");
	return world;
};


string nextmap;
void() GotoNextMap =
{
	local float c, nummaps;
	local string s;
	if (cvar("samelevel")) // if samelevel is set, stay on same level
		changelevel (mapname);
	else
	{
		s = cvar_string("sv_maplist");
		nummaps = tokenize(s);
		if (nummaps >= 1)
		{
			c = 0;
			while (c < nummaps)
			{
				if (argv(c) == mapname)
					break;
				c = c + 1;
			}
			c = c + 1;
			if (c >= nummaps)
				c = 0;
			nextmap = argv(c);
		}
		changelevel (nextmap);
	}
};


void() ExitIntermission =
{
// skip any text in deathmatch
	if (deathmatch)
	{
		GotoNextMap ();
		return;
	}

	intermission_exittime = time + 1;
	intermission_running = intermission_running + 1;

//
// run some text if at the end of an episode
//
	if (intermission_running == 2)
	{
		if (world.model == "maps/e1m7.bsp")
		{
			WriteByte (MSG_ALL, SVC_CDTRACK);
			WriteByte (MSG_ALL, 2);
			WriteByte (MSG_ALL, 3);
			if (!cvar("registered"))
			{
				WriteByte (MSG_ALL, SVC_FINALE);
				WriteString (MSG_ALL, "As the corpse of the monstrous entity\nChthon sinks back into the lava whence\nit rose, you grip the Rune of Earth\nMagic tightly. Now that you have\nconquered the Dimension of the Doomed,\nrealm of Earth Magic, you are ready to\ncomplete your task in the other three\nhaunted lands of Quake. Or are you? If\nyou don't register Quake, you'll never\nknow what awaits you in the Realm of\nBlack Magic, the Netherworld, and the\nElder World!");
			}
			else
			{
				WriteByte (MSG_ALL, SVC_FINALE);
				WriteString (MSG_ALL, "As the corpse of the monstrous entity\nChthon sinks back into the lava whence\nit rose, you grip the Rune of Earth\nMagic tightly. Now that you have\nconquered the Dimension of the Doomed,\nrealm of Earth Magic, you are ready to\ncomplete your task. A Rune of magic\npower lies at the end of each haunted\nland of Quake. Go forth, seek the\ntotality of the four Runes!");
			}
			return;
		}
		else if (world.model == "maps/e2m6.bsp")
		{
			WriteByte (MSG_ALL, SVC_CDTRACK);
			WriteByte (MSG_ALL, 2);
			WriteByte (MSG_ALL, 3);

			WriteByte (MSG_ALL, SVC_FINALE);
			WriteString (MSG_ALL, "The Rune of Black Magic throbs evilly in\nyour hand and whispers dark thoughts\ninto your brain. You learn the inmost\nlore of the Hell-Mother; Shub-Niggurath!\nYou now know that she is behind all the\nterrible plotting which has led to so\nmuch death and horror. But she is not\ninviolate! Armed with this Rune, you\nrealize that once all four Runes are\ncombined, the gate to Shub-Niggurath's\nPit will open, and you can face the\nWitch-Goddess herself in her frightful\notherworld cathedral.");
			return;
		}
		else if (world.model == "maps/e3m6.bsp")
		{
			WriteByte (MSG_ALL, SVC_CDTRACK);
			WriteByte (MSG_ALL, 2);
			WriteByte (MSG_ALL, 3);

			WriteByte (MSG_ALL, SVC_FINALE);
			WriteString (MSG_ALL, "The charred viscera of diabolic horrors\nbubble viscously as you seize the Rune\nof Hell Magic. Its heat scorches your\nhand, and its terrible secrets blight\nyour mind. Gathering the shreds of your\ncourage, you shake the devil's shackles\nfrom your soul, and become ever more\nhard and determined to destroy the\nhideous creatures whose mere existence\nthreatens the souls and psyches of all\nthe population of Earth.");
			return;
		}
		else if (world.model == "maps/e4m7.bsp")
		{
			WriteByte (MSG_ALL, SVC_CDTRACK);
			WriteByte (MSG_ALL, 2);
			WriteByte (MSG_ALL, 3);

			WriteByte (MSG_ALL, SVC_FINALE);
			WriteString (MSG_ALL, "Despite the awful might of the Elder\nWorld, you have achieved the Rune of\nElder Magic, capstone of all types of\narcane wisdom. Beyond good and evil,\nbeyond life and death, the Rune\npulsates, heavy with import. Patient and\npotent, the Elder Being Shub-Niggurath\nweaves her dire plans to clear off all\nlife from the Earth, and bring her own\nfoul offspring to our world! For all the\ndwellers in these nightmare dimensions\nare her descendants! Once all Runes of\nmagic power are united, the energy\nbehind them will blast open the Gateway\nto Shub-Niggurath, and you can travel\nthere to foil the Hell-Mother's plots\nin person.");
			return;
		}

		GotoNextMap();
	}

	if (intermission_running == 3)
	{
		if (!cvar("registered"))
		{
			// shareware episode has been completed, go to sell screen
			WriteByte (MSG_ALL, SVC_SELLSCREEN);
			return;
		}

		if ( (serverflags&15) == 15)
		{
			WriteByte (MSG_ALL, SVC_FINALE);
			WriteString (MSG_ALL, "Now, you have all four Runes. You sense\ntremendous invisible forces moving to\nunseal ancient barriers. Shub-Niggurath\nhad hoped to use the Runes Herself to\nclear off the Earth, but now instead,\nyou will use them to enter her home and\nconfront her as an avatar of avenging\nEarth-life. If you defeat her, you will\nbe remembered forever as the savior of\nthe planet. If she conquers, it will be\nas if you had never been born.");
			return;
		}

	}

	GotoNextMap();
};

/*
============
IntermissionThink

When the player presses attack or jump, change to the next level
============
*/
void() IntermissionThink =
{
	if (time < intermission_exittime)
		return;

	if (!self.button0 && !self.button1 && !self.button2)
		return;

	ExitIntermission ();
};

void() execute_changelevel =
{
	local entity pos;

	intermission_running = 1;

	// enforce a wait time before allowing changelevel
	if (deathmatch)
		intermission_exittime = time + 5;
	else
		intermission_exittime = time + 2;

	WriteByte (MSG_ALL, SVC_CDTRACK);
	WriteByte (MSG_ALL, 3);
	WriteByte (MSG_ALL, 3);

	pos = FindIntermission ();

	other = findchain(classname, "player");
	while (other != world)
	{
		other.view_ofs = '0 0 0';
		other.angles = other.v_angle = pos.mangle;
		other.fixangle = TRUE;		// turn this way immediately
		other.nextthink = time + 0.5;
		other.takedamage = DAMAGE_NO;
		other.solid = SOLID_TRIGGER;
		other.movetype = MOVETYPE_NONE;
		other.modelindex = 0;
		other.model = "";
		setorigin (other, pos.origin);
		other = other.chain;
	}

	WriteByte (MSG_ALL, SVC_INTERMISSION);
};


void() changelevel_touch =
{
	if (other.classname != "player")
		return;

	if ((cvar("noexit") == 1) || ((cvar("noexit") == 2) && (mapname != "start")))
	{
		//T_Damage (other, self, self, 50000, 50000, " didn't realize the exit is out of order", DT_TELEFRAG, (self.absmin + self.absmax) * 0.5, '0 0 0');
		return;
	}

	if (coop || deathmatch)
	{
		bprint (other.netname);
		bprint (" exited the level\n");
	}

	nextmap = self.map;

	SUB_UseTargets ();

	if ( (self.spawnflags & 1) && (deathmatch == DM_NONE) )
	{
		// NO_INTERMISSION
		GotoNextMap();
		return;
	}

	self.touch = SUB_Null;

// we can't move people right now, because touch functions are called
// in the middle of C movement code, so set a think time to do it
	self.think = execute_changelevel;
	self.nextthink = time + 0.1;
};

/*QUAKED trigger_changelevel (0.5 0.5 0.5) ? NO_INTERMISSION
When the player touches this, he gets sent to the map listed in the "map" variable.  Unless the NO_INTERMISSION flag is set, the view will go to the info_intermission spot and display stats.
*/
void() trigger_changelevel =
{
	if (!self.map)
		objerror ("changelevel trigger doesn't have map");

	InitTrigger ();
	self.touch = changelevel_touch;
};


/*
=============================================================================

				PLAYER GAME EDGE FUNCTIONS

=============================================================================
*/

//void() set_suicide_frame;

// called by ClientKill and DeadThink
void() respawn =
{
	if (coop)
	{
		// make a copy of the dead body for appearances sake
		CopyToBodyQue (self);
		// get the spawn parms as they were at level start
		setspawnparms (self);
		// respawn
		PutClientInServer ();
	}
	else if (deathmatch)
	{
		// make a copy of the dead body for appearances sake
		CopyToBodyQue (self);
		// respawn
		PutClientInServer ();
	}
	else
	{
		// restart the entire server
		localcmd ("restart\n");
	}
};


/*
============
ClientKill

Player entered the suicide command
============
*/
.float nextsuicide;
void() ClientKill =
{
	if (time < self.nextsuicide)
	{
		sprint(self, "you can not suicide more than once every 5 seconds\n");
		return;
	}
	if (self.deadflag) // dead already
		return;
	if ((intermission_running) && ((coop) || (deathmatch))) // not allowed during intermission
		return;
	self.nextsuicide = time + 5;
	// looks better than instantly switching to death frame
	if (self.takedamage)
		T_Damage(self, self, self, 0, 0, " killed himself", DT_TELEFRAG, self.origin, '0 0 0', Obituary_Generic);
	else
		respawn ();
};

/*
============
SelectSpawnPoint

Returns the entity to spawn at
============
*/
entity() SelectSpawnPoint =
{
	local entity spot;
	local entity thing;
	local float pcount;
	local string cname;
	local float picknext;

	// testinfo_player_start is only found in regioned levels
	spot = find(world, classname, "testplayerstart");
	if (spot)
		return spot;

	// support for Rocket Arena maps
	if (find(world, targetname, "tele1")) // two teleport destinations
	if (find(world, targetname, "tele2"))
	if (!find(world, target, "tele1")) // without teleporters to them
	if (!find(world, target, "tele2"))
	{
		spot = lastspawn;
		while (1)
		{
			spot = find(spot, classname, "info_teleport_destination");
			if (spot != world)
			if ((spot.targetname == "tele1") || (spot.targetname == "tele2"))
			{
				if (spot == lastspawn)
					return lastspawn;
				pcount = 0;
				thing = findradius(spot.origin, 100);
				while(thing)
				{
					if (thing.classname == "player")
						pcount = pcount + 1;
					thing = thing.chain;
				}
				if (pcount == 0)
				{
					lastspawn = spot;
					return spot;
				}
			}
		}
	}
	// otherwise fall through to the usual spawn points (deathmatch, etc)

	// choose a info_player_deathmatch point
	if (coop)
	{
		lastspawn = find(lastspawn, classname, "info_player_coop");
		if (lastspawn == world)
			lastspawn = find(lastspawn, classname, "info_player_start");
		if (lastspawn != world)
			return lastspawn;
	}
	else if (deathmatch == DM_CTF_2TEAM || deathmatch == DM_CTF_3TEAM)
	{
		cname = "info_player_deathmatch";
		if (self.team == 5) // red
			cname = "info_player_team1";
		if (self.team == 14) // blue
			cname = "info_player_team2";
		if (self.team == 13) // yellow
			cname = "info_player_team3";
		if (find(world, classname, cname) == world)
			cname = "info_player_deathmatch";
		if (find(world, classname, cname) == world)
			cname = "info_player_start";
		if (find(world, classname, cname) == world)
			error ("PutClientInServer: no info_player_start on level");
		spot = lastspawn;
		picknext = FALSE;
		while (1)
		{
			spot = find(spot, classname, cname);
			if (spot != world)
			{
				pcount = 0;
				thing = findradius(spot.origin, 100);
				while(thing)
				{
					if (thing.classname == "player")
						pcount = pcount + 1;
					thing = thing.chain;
				}
				// if we failed to find a spot, at least pick the next one
				if (pcount == 0 || picknext)
				{
					lastspawn = spot;
					return spot;
				}
				else if (spot == lastspawn)
					picknext = TRUE;
			}
		}
	}
	else if (deathmatch && find(world, classname, "info_player_deathmatch") != world)
	{
		spot = lastspawn;
		picknext = FALSE;
		while (1)
		{
			spot = find(spot, classname, "info_player_deathmatch");
			if (spot != world)
			{
				pcount = 0;
				thing = findradius(spot.origin, 100);
				while(thing)
				{
					if (thing.classname == "player")
						pcount = pcount + 1;
					thing = thing.chain;
				}
				// if we failed to find a spot, at least pick the next one
				if (pcount == 0 || picknext)
				{
					lastspawn = spot;
					return spot;
				}
				else if (spot == lastspawn)
					picknext = TRUE;
			}
		}
	}

	if (serverflags)
	{
		// return with a rune to start
		spot = find(world, classname, "info_player_start2");
		if (spot)
			return spot;
	}

	spot = find(world, classname, "info_player_start");
	if (!spot)
		spot = find(world, classname, "info_player_deathmatch");
	if (!spot)
		error ("PutClientInServer: no info_player_start on level");

	return spot;
};

//
.float cameramode;
.entity actor;
void() CycleCameraMode =
{
	self.cameramode = self.cameramode + 1;
	if (self.cameramode >= 4)
		self.cameramode = 0;
};

// .entity lastwaypoint;
.float bubble_count;
.float candrown;
.entity flashlight;
void() ToggleFlashLight;

/*
===========
PutClientInServer

called each time a player is spawned
============
*/
void() DecodeLevelParms;
void() PlayerDie;
void() havocbot_chooserole;
void() PutClientInServer_Player =
{
	local entity spot;

	/*
	if (self.cameramode)
	{
		if (!self.actor)
		{
			self.actor = spawn();
			self.actor.classname = self.classname;
			self.classname = "clientcamera";
			copyent
		}
	}
	else
	{
	}
	*/

	self.classname = "player";

	updateteams();

	// apply physics stuff (bleeding, drowning, slime, lava, etc)
	self.iscreature = TRUE;
	self.forcescale = 5; // for damage kick calculations
	self.cantrigger = TRUE; // can trigger buttons etc
	self.iscorpse = FALSE;
	self.isdecor = FALSE;
	self.bleedratio = 1; // 100% bleeding damage (see t_damage.qc)
	// make self completely visible
	self.alpha = 0;

	self.flags = FL_CLIENT;

	self.th_pain = player_pain;
	self.th_die = PlayerDie;
	self.th_gib = GibPlayer;

	self.bubble_count = 0;
	self.candrown = TRUE;

	self.combo_amount = 0;
	self.combo_time = 0;

	self.spree_amount = 0;
	self.spree_count = 0;

	self.show_hostile = 0;
	self.air_finished = time + 12;
	self.dmg = 2;   // initial water damage
	self.super_damage_finished = 0;
	self.radsuit_finished = 0;
	self.invisible_finished = 0;
	self.invincible_finished = 0;
	self.effects = 0;
	self.invincible_time = 0;
	self.velocity = '0 0 0'; // don't continue movement from death etc
	self.jump_flag = 0; // clear jump velocity to prevent falling damage
	self.avelocity = '0 0 0';
	self.punchangle = '0 0 0';
	self.frozen = FALSE;
	self.spawnshieldtime = time + 2;

	// set up health and equipment
	DecodeLevelParms();

	self.keys_silver = 0; // clear silver key count
	self.keys_gold = 0;   // clear gold key count

	self.bleedfunc = genericbleedfunc;

	self.doobits = 1;
	self.havocattack = TRUE;
	self.takedamage = DAMAGE_AIM;
	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_WALK;
	self.touch = SUB_Null;

	self.attack_finished = time;

	self.deadflag = DEAD_NO;
	// paustime is set by teleporters to keep the player from moving a while
	self.pausetime = 0;

	spot = SelectSpawnPoint ();

	self.angles = spot.angles;
	self.fixangle = TRUE;           // turn this way immediately
	self.teleport_time = time + 0.5; // zoom effect

	// oh, this is a hack!
	if (modelindex_eyes == 0) // hasn't been done yet
	{
//		setmodel (self, "progs/null.spr");
//		modelindex_null = self.modelindex;

		setmodel (self, "progs/eyes.mdl");
		modelindex_eyes = self.modelindex;

		setmodel (self, "progs/player.mdl");
		modelindex_player = self.modelindex;
	}
	else
		setmodel(self, "progs/player.mdl");

	setsize (self, '-16 -16 -24', '16 16 24');

	self.view_ofs = '0 0 22';

	setorigin(self, spot.origin + '0 0 1');
	// don't snap back to where you died (oldorigin) if the map has a misplaced spawn entity
	self.oldorigin = self.origin;

	self.iscorpse = FALSE;

	/*
	if (deathmatch == DM_ELIM)
	if (self.desiredteam == 0) // should be an observer
	{
		self.forcescale = 5;
		self.iscreature = TRUE;
		self.doobits = 0;
		self.havocattack = FALSE;
		self.weaponframecode = SUB_Null;
		self.takedamage = DAMAGE_NO;
		self.movetype = MOVETYPE_FLY;
		self.flags = FL_CLIENT;
		self.solid = SOLID_NOT;
		self.classname = "player";
		self.health = 999;
		self.armortype = self.armorvalue = self.currentammo = 0;
		Inventory_SetQuantity(self, "shells", 0);
		Inventory_SetQuantity(self, "nails", 0);
		Inventory_SetQuantity(self, "rockets", 0);
		Inventory_SetQuantity(self, "cells", 0);
		self.items = 0;
		self.think = SUB_Null;
		self.nextthink = 0;
		self.cantrigger = FALSE;
		self.weaponmodel = "";
		self.weaponframe = 0;
		// LordHavoc: fixed this in the engine
		// needs a model or player won't get movement updates
		//self.modelindex = modelindex_null;
		return;
	}
	*/

	if (deathmatch || coop)
	{
		makevectors(self.angles);
		spawn_tfog (self.origin + v_forward*20);
	}
	//spawn_tdeath (self.origin, self, '0 0 0');

	if (self.isbot)
		havocbot_chooserole();

	if (!self.solid) // observer
		return;

	player_movestart ();

	if (darkmode)
	if (self.flashlight == world)
		ToggleFlashLight();
};

void() PutClientInServer_TowerDefense =
{
	local entity spot;

	self.classname = "commander";

	updateteams();

	// apply physics stuff (bleeding, drowning, slime, lava, etc)
	self.iscreature = FALSE;
	self.forcescale = 0; // for damage kick calculations
	self.cantrigger = FALSE; // can trigger buttons etc
	self.iscorpse = FALSE;
	self.isdecor = FALSE;
	self.bleedratio = 0; // 100% bleeding damage (see t_damage.qc)
	// make self completely visible
	self.alpha = 0;

	self.flags = FL_CLIENT;

	self.th_pain = SUB_Null;
	self.th_die = SUB_Null;
	self.th_gib = SUB_Null;

	self.bubble_count = 0;
	self.candrown = FALSE;

	self.combo_amount = 0;
	self.combo_time = 0;

	self.spree_amount = 0;
	self.spree_count = 0;

	self.show_hostile = 0;
	self.air_finished = 0;
	self.dmg = 0;   // initial water damage
	self.super_damage_finished = 0;
	self.radsuit_finished = 0;
	self.invisible_finished = 0;
	self.invincible_finished = 0;
	self.effects = 0;
	self.invincible_time = 0;
	self.velocity = '0 0 0'; // don't continue movement from death etc
	self.jump_flag = 0; // clear jump velocity to prevent falling damage
	self.avelocity = '0 0 0';
	self.punchangle = '0 0 0';
	self.frozen = FALSE;
	self.spawnshieldtime = 0;

	// set up health and equipment
	self.items = IT_WEAPON1 | IT_WEAPON2 | IT_WEAPON4 | IT_WEAPON6;
	self.health = 20;
	self.max_health = 100;
	self.bodyhealth = 0;
	self.armorvalue = 0;
	self.armortype = 0;
	self.weaponclass = world;

	self.keys_silver = 0; // clear silver key count
	self.keys_gold = 0;   // clear gold key count

	self.bleedfunc = SUB_Null;

	self.think = SUB_Null;
	self.nextthink = 0;
	self.weaponmodel = "";
	self.weaponframe = 0;

	self.doobits = 0;
	self.havocattack = FALSE;
	self.takedamage = DAMAGE_NO;
	self.solid = SOLID_NOT;
	self.movetype = MOVETYPE_NONE;
	self.touch = SUB_Null;

	self.attack_finished = 0;

	self.deadflag = DEAD_NO;
	self.pausetime = 0;

	spot = SelectSpawnPoint ();

	self.angles = '90 0 0';
	self.v_angle = self.angles;
	self.fixangle = TRUE;           // turn this way immediately
	self.teleport_time = 0;

	self.model = "";
	self.modelindex = 0;

	setsize (self, '0 0 0', '0 0 0');

	self.view_ofs = '0 0 0';

	setorigin(self, spot.origin);
	// don't snap back to where you died (oldorigin) if the map has a misplaced spawn entity
	self.oldorigin = self.origin;

	self.iscorpse = FALSE;
};

void() PutClientInServer =
{
	if (mapgametype == MAPGAME_TOWERDEFENSE)
		PutClientInServer_TowerDefense();
	else
		PutClientInServer_Player();
};


/*
=============================================================================

				QUAKED FUNCTIONS

=============================================================================
*/

void() info_player_deathmatch_activate =
{
	self.classname = self.mdl;
	self.mdl = "";
	self.use = SUB_Null;
};

void() info_player_deathmatch_setup =
{
	if (self.targetname)
	{
		self.use = info_player_deathmatch_activate;
		self.mdl = self.classname;
		self.classname = ""; // restored when triggered
	}
};



/*QUAKED info_player_start (1 0 0) (-16 -16 -24) (16 16 24)
The normal starting point for a level.
*/
void() info_player_start =
{
};


/*QUAKED info_player_start2 (1 0 0) (-16 -16 -24) (16 16 24)
Only used on start map for the return point from an episode.
*/
void() info_player_start2 =
{
};


/*
saved out by quaked in region mode
*/
void() testplayerstart =
{
};

/*QUAKED info_player_deathmatch (1 0 1) (-16 -16 -24) (16 16 24)
potential spawning position for deathmatch games

new in Dark Places:
"targetname"
 inactive (skipped) until triggered.
 (for use in combination with
  trigger_playercount)
*/
void() info_player_deathmatch =
{
	info_player_deathmatch_setup();
};

/*QUAKED info_player_coop (1 0 1) (-16 -16 -24) (16 16 24)
potential spawning position for coop games
*/
void() info_player_coop =
{
};

/*QUAKED info_player_team1 (.7 0 0) (-16 -16 -24) (16 16 24)
potential spawning position for teamplay games
team #1 - red

new in Dark Places:
"targetname"
 inactive (skipped) until triggered.
 (for use in combination with
  trigger_playercount)
*/
void() info_player_team1 =
{
	info_player_deathmatch_setup();
};

/*QUAKED info_player_team2 (0 0 .7) (-16 -16 -24) (16 16 24)
potential spawning position for teamplay games
team #2 - blue

new in Dark Places:
"targetname"
 inactive (skipped) until triggered.
 (for use in combination with
  trigger_playercount)
*/
void() info_player_team2 =
{
	info_player_deathmatch_setup();
};

/*QUAKED info_player_team3 (.7 .7 .7) (-16 -16 -24) (16 16 24)
potential spawning position for teamplay games
team #3 - grey

new in Dark Places:
"targetname"
 inactive (skipped) until triggered.
 (for use in combination with
  trigger_playercount)
*/
void() info_player_team3 =
{
	info_player_deathmatch_setup();
};

//============================================================================

void() PlayerDeathThink =
{
	local float forward;

	if ((self.flags & FL_ONGROUND))
	{
		forward = vlen (self.velocity) - 200 * frametime;
		if (forward <= 0)
			self.velocity = '0 0 0';
		else
			self.velocity = forward * normalize(self.velocity);
	}

	if (self.deadflag == DEAD_DEAD)
	{
		// wait for all buttons released
		if (self.button2 || self.button0)
			return;
		self.deadflag = DEAD_RESPAWNABLE;
	}
	else if (self.deadflag == DEAD_RESPAWNABLE)
	{
		// wait for any button down
		if (!self.button2 && !self.button0)
			return;
		self.deadflag = DEAD_RESPAWNING;
	}
	else if (self.deadflag == DEAD_RESPAWNING)
	{
		// wait for all buttons released
		if (self.button2 || self.button0)
			return;
		respawn();
	}
};


void() PlayerJump =
{
	if (self.flags & FL_WATERJUMP)
		return;

	if (self.waterlevel >= 2)
	{
		if (self.watertype == CONTENT_WATER)
			self.velocity_z = 100;
		else if (self.watertype == CONTENT_SLIME)
			self.velocity_z = 80;
		else
			self.velocity_z = 50;

		if (self.solid) // silent for observers
		{
			// play swiming sound
			if (self.swim_flag < time)
			{
				self.swim_flag = time + 1;
				if (game != GAME_NEXUIZ)
				{
					// FIXME: make swimming sounds when swimming normally (not jumping)?
					if (random() < 0.5)
						sound (self, CHAN_BODY, "misc/water1.wav", 1, ATTN_NORM);
					else
						sound (self, CHAN_BODY, "misc/water2.wav", 1, ATTN_NORM);
				}
			}
		}

		return;
	}

	if (!(self.flags & FL_ONGROUND))
		return;

	if (!(self.flags & FL_JUMPRELEASED))
		return;		// don't pogo stick

	self.flags = self.flags - (self.flags & FL_JUMPRELEASED);

	self.flags = self.flags - FL_ONGROUND;	// don't stairwalk

	self.button2 = 0;
	if (self.solid) // silent for observers
	{
		// player jumping sound
		if (game != GAME_NEXUIZ)
			sound (self, CHAN_BODY, "player/plyrjmp8.wav", 1, ATTN_NORM);
	}
	self.velocity_z = self.velocity_z + 270;
};

// .float steamtime;

void() CheckWaterJump =
{
	local vector start, end;

// check for a jump-out-of-water
	makevectors (self.angles);
	start = self.origin;
	start_z = start_z + 8;
	v_forward_z = 0;
	normalize(v_forward);
	end = start + v_forward*24;
	traceline (start, end, TRUE, self);
	if (trace_fraction < 1)
	{
		// solid at waist
		start_z = start_z + self.maxs_z - 8;
		end = start + v_forward*24;
		self.movedir = trace_plane_normal * -50;
		traceline (start, end, TRUE, self);
		if (trace_fraction == 1)
		{
			// open at eye level
			self.flags = self.flags | FL_WATERJUMP;
			self.velocity_z = 225;
			self.flags = self.flags - (self.flags & FL_JUMPRELEASED);
			self.teleport_time = time + 2;  // safety net
			return;
		}
	}
};

void() RegenStuff;

/*
================
PlayerPreThink

Called every frame before physics are run
================
*/
void() PlayerPreThink =
{
	local float r, a;

	// fade pain view kick
	a = vlen(self.punchvector);
	if (a)
	{
		r = a - frametime * 15;
		if (r < 0)
			r = 0;
		self.punchvector = self.punchvector * (r / a);
	}

	if (intermission_running)
	{
		IntermissionThink (); // otherwise a button could be missed
		return;               // between the think tics
	}

	if (self.view_ofs == '0 0 0')
		return;		// intermission or finale

	/*
	bprint("pre : ");
	bprintvector(self.origin);
	bprint(" ");
	bprintvector(self.angles);
	bprint(" ");
	bprintvector(self.v_angle);
	bprint(" ");
	bprintfloat(intermission_running);
	bprint(" ");
	bprintfloat(intermission_exittime);
	bprint("\n");
	*/

	checkinvalidteam();

	if (cvar("temp1") & 4096)
	{
		Inventory_SetQuantity(self, "shells", AMMOMAXSP_SHELLS);
		Inventory_SetQuantity(self, "nails", AMMOMAXSP_NAILS);
		Inventory_SetQuantity(self, "rockets", AMMOMAXSP_ROCKETS);
		Inventory_SetQuantity(self, "cells", AMMOMAXSP_CELLS);
	}

	if (self.waterlevel == 2)
		CheckWaterJump ();
	else if (self.flags & FL_WATERJUMP )
	{
		self.velocity_x = self.movedir_x;
		self.velocity_y = self.movedir_y;
		if (time > self.teleport_time || self.waterlevel == 0)
		{
			self.flags = self.flags - (self.flags & FL_WATERJUMP);
			self.teleport_time = 0;
		}
	}

	if (self.deadflag >= DEAD_DYING)
	{
		if (self.deadflag >= DEAD_DEAD)
			PlayerDeathThink ();
		return; // dying or dead, so do nothing
	}

	if (self.button2)
		PlayerJump ();
	else
		self.flags = self.flags | FL_JUMPRELEASED;

	// teleporters can force a non-moving pause time
	if (time < self.pausetime)
		self.velocity = '0 0 0';
};

/*
================
CheckPowerups

Check for turning off powerups
================
*/
void() CheckPowerups =
{
	if (self.deadflag) // dead
	{
		self.effects = 0;
		return;
	}

	self.effects = self.effects - (self.effects & (EF_BLUE + EF_RED + EF_DIMLIGHT + EF_ADDITIVE/* + EF_REFLECTIVE*/));
	self.items = self.items - (self.items & (IT_INVISIBILITY + IT_INVULNERABILITY + IT_QUAD + IT_SUIT));

	// invisibility
	if (self.invisible_finished)
	{
		self.items = self.items + IT_INVISIBILITY;
		// sound and screen flash when items starts to run out
		if (self.invisible_sound < time)
		{
			if (game != GAME_NEXUIZ)
				sound (self, CHAN_AUTO, "items/inv3.wav", 0.5, ATTN_IDLE);
			self.invisible_sound = time + ((random() * 3) + 1);
		}

		if (self.invisible_finished < time + 3)
		{
			if (self.invisible_time == 1)
			{
				if (self.flags & FL_CLIENT)
				{
					sprint (self, "Ring of Shadows magic is fading\n");
					stuffcmd (self, "bf\n");
				}
				if (game != GAME_NEXUIZ)
					sound (self, CHAN_AUTO, "items/inv2.wav", 1, ATTN_NORM);
				self.invisible_time = time + 1;
			}

			if (self.invisible_time < time)
			{
				self.invisible_time = time + 1;
				stuffcmd (self, "bf\n");
			}
		}

		if (self.invisible_finished < time)
		{	// just stopped
			self.invisible_finished = 0;
			self.invisible_time = 0;
		}
	}

	// invincibility
	if (self.invincible_finished)
	{
		self.items = self.items + IT_INVULNERABILITY;
		// sound and screen flash when items starts to run out
		if (self.invincible_finished < time + 3)
		{
			if (self.invincible_time == 1)
			{
				if (self.flags & FL_CLIENT)
				{
					sprint (self, "Protection is running out\n");
					stuffcmd (self, "bf\n");
				}
				if (game != GAME_NEXUIZ)
					sound (self, CHAN_AUTO, "items/protect2.wav", 1, ATTN_NORM);
				self.invincible_time = time + 1;
			}

			if (self.invincible_time < time)
			{
				self.invincible_time = time + 1;
				stuffcmd (self, "bf\n");
			}
		}

		if (self.invincible_finished < time)
		{	// just stopped
			self.invincible_time = 0;
			self.invincible_finished = 0;
		}
	}

	// super damage
	if (self.super_damage_finished)
	{
		self.items = self.items + IT_QUAD;
		// sound and screen flash when items starts to run out
		if (self.super_damage_finished < time + 3)
		{
			if (self.super_time == 1)
			{
				if (self.flags & FL_CLIENT)
				{
					sprint (self, "Quad Damage is fading\n");
					stuffcmd (self, "bf\n");
				}
				if (game != GAME_NEXUIZ)
					sound (self, CHAN_AUTO, "items/damage2.wav", 1, ATTN_NORM);
				self.super_time = time + 1;
			}

			if (self.super_time < time)
			{
				self.super_time = time + 1;
				stuffcmd (self, "bf\n");
			}
		}

		if (self.super_damage_finished < time)
		{	// just stopped
			self.super_damage_finished = 0;
			self.super_time = 0;
		}
	}

	// suit
	if (self.radsuit_finished)
	{
		self.items = self.items + IT_SUIT;

		self.air_finished = time + 12;		// don't drown

		// sound and screen flash when items starts to run out
		if (self.radsuit_finished < time + 3)
		{
			if (self.rad_time == 1)
			{
				if (self.flags & FL_CLIENT)
				{
					sprint (self, "Air supply in Biosuit expiring\n");
					stuffcmd (self, "bf\n");
				}
				if (game != GAME_NEXUIZ)
					sound (self, CHAN_AUTO, "items/suit2.wav", 1, ATTN_NORM);
				self.rad_time = time + 1;
			}

			if (self.rad_time < time)
			{
				self.rad_time = time + 1;
				stuffcmd (self, "bf\n");
			}
		}

		if (self.radsuit_finished < time)
		{	// just stopped
			self.rad_time = 0;
			self.radsuit_finished = 0;
		}
	}

// 'glow' armor
	if (self.armortype == 1.0)
		self.effects = self.effects | EF_DIMLIGHT;
	if (self.items & IT_INVULNERABILITY)
		self.effects = self.effects | (EF_RED/* + EF_REFLECTIVE*/);
	if (self.items & IT_QUAD)
		self.effects = self.effects | (EF_BLUE/* + EF_REFLECTIVE*/);
};

.float regenthink;
.float rotthink; // rot down megahealth

void() RegenStuff =
{
	if (!self.deadflag)
	{
		if (time > self.rotthink)
		{
			// rot health
			self.rotthink = time + 1;
			if (self.health > self.max_health)
			{
				self.health = self.health - 1;
				if (self.health < self.max_health)
					self.health = self.max_health;
			}
		}
		if (time > self.regenthink)
		{
			self.regenthink = time + 0.25;
			if (self.health < self.max_health)
			{
				self.health = self.health + 1;
				if (self.health > self.max_health)
					self.health = self.max_health;
			}
			if (self.bodyhealth < self.health + 100)
			{
				self.bodyhealth = self.bodyhealth + 2;
				if (self.bodyhealth > self.health + 100)
					self.bodyhealth = self.health + 100;
			}
		}
	}
	if (self.health > self.max_health)
		self.items = self.items | IT_SUPERHEALTH;
	else
		self.items = self.items - (self.items & IT_SUPERHEALTH);
};

void() havoc_laywaypoints;

.float nextfootstep;

void() playerfootstep =
{
	local float r;

	if (!self.solid) // observer
		return;
	if (self.deadflag) // not walking dead...
		return;
	if (!(self.flags & FL_ONGROUND))
		return;
	if (vlen(self.velocity) < 300)
		return;

	if (time < self.nextfootstep)
		return;
	self.nextfootstep = time + 0.3;

	if (game != GAME_NEXUIZ)
	{
		r = random() * 7;
		// ATTN_IDLE to make them short range
		if (r < 1) sound(self, CHAN_FOOT, "misc/foot1.wav", 0.5, ATTN_IDLE);
		else if (r < 2) sound(self, CHAN_FOOT, "misc/foot2.wav", 0.5, ATTN_IDLE);
		else if (r < 3) sound(self, CHAN_FOOT, "misc/foot3.wav", 0.5, ATTN_IDLE);
		else if (r < 4) sound(self, CHAN_FOOT, "misc/foot4.wav", 0.5, ATTN_IDLE);
		else if (r < 5) sound(self, CHAN_FOOT, "misc/foot5.wav", 0.5, ATTN_IDLE);
		else if (r < 6) sound(self, CHAN_FOOT, "misc/foot6.wav", 0.5, ATTN_IDLE);
		else            sound(self, CHAN_FOOT, "misc/foot7.wav", 0.5, ATTN_IDLE);
	}
};

.entity td_towercursor;
void() Player_TowerDefenseFrame =
{
	local vector p;
	local vector dir;
	local vector buildposition;
	local float buildpositionvalid;
	local entity head;
	local entity start;
	local string m;
	local float cost;
	if (self.deadflag)
	{
		if (self.deadflag == DEAD_DYING)
		if (time > self.pain_finished)
			self.deadflag = DEAD_DEAD;
		if (self.deadflag == DEAD_DEAD)
		if (!self.button0)
		if (!self.button2)
			self.deadflag = DEAD_RESPAWNABLE;
		if (self.deadflag == DEAD_RESPAWNABLE)
		if (self.button0 || self.button2)
			respawn();
		return;
	}

	buildpositionvalid = FALSE;
	dir = normalize(self.cursor_trace_endpos - self.cursor_trace_start);
	traceline(self.origin, self.origin + dir * 8192, MOVE_NOMONSTERS, self);
	buildposition_x = floor(trace_endpos_x / 64) * 64;
	buildposition_y = floor(trace_endpos_y / 64) * 64;
	buildposition_z = trace_endpos_z;
	if (trace_fraction < 1)
	if (trace_ent == world)
	{
		buildpositionvalid = TRUE;
		tracebox(buildposition, '0 0 0.03125', '64 64 64.03125', buildposition, MOVE_NORMAL, self);
		if (trace_startsolid)
			buildpositionvalid = FALSE;
		else
		{
			start = findchain(classname, "towerdefense_buildarea");
			head = start;
			while (head)
			{
				head.solid = SOLID_BSP;
				setorigin(head, head.origin);
				head = head.chain;
			}
			traceline(p +   '1 1 10', p +   '1 1 -1', MOVE_NOMONSTERS, self);if (trace_ent.classname != "towerdefense_buildarea") buildpositionvalid = FALSE;
			traceline(p +  '63 1 10', p +  '63 1 -1', MOVE_NOMONSTERS, self);if (trace_ent.classname != "towerdefense_buildarea") buildpositionvalid = FALSE;
			traceline(p +  '1 63 10', p +  '1 63 -1', MOVE_NOMONSTERS, self);if (trace_ent.classname != "towerdefense_buildarea") buildpositionvalid = FALSE;
			traceline(p + '63 63 10', p + '63 63 -1', MOVE_NOMONSTERS, self);if (trace_ent.classname != "towerdefense_buildarea") buildpositionvalid = FALSE;
			head = start;
			while (head)
			{
				head.solid = SOLID_NOT;
				setorigin(head, head.origin);
				head = head.chain;
			}
		}
	}

	if (!self.td_towercursor)
		self.td_towercursor = spawn();

	self.td_towercursor.classname = "td_towercursor";
	self.td_towercursor.think = SUB_Remove;
	self.td_towercursor.nextthink = time + 0.11;

	setorigin(self.td_towercursor, buildposition);
	     if (self.weapon == IT_WEAPON2) {m = "progs/td_tshotgun.md3"  ;cost =   15;}
	else if (self.weapon == IT_WEAPON3) {m = "progs/td_tshotgun2.md3" ;cost =   50;}
	else if (self.weapon == IT_WEAPON4) {m = "progs/td_tnailgun.md3"  ;cost =   40;}
	else if (self.weapon == IT_WEAPON5) {m = "progs/td_tnailgun2.md3" ;cost =  170;}
	else if (self.weapon == IT_WEAPON6) {m = "progs/td_tgrenade.md3"  ;cost =  150;}
	else if (self.weapon == IT_WEAPON7) {m = "progs/td_trocket.md3"   ;cost =  250;}
	else if (self.weapon == IT_WEAPON8) {m = "progs/td_tlightning.md3";cost =  400;}
	else                                {m = "progs/td_cursor.md3"    ;cost =    0;}

	if (self.td_towercursor.model != m)
		setmodel(self.td_towercursor, m);

	if (buildpositionvalid)
		self.td_towercursor.colormod = '0 0 0';
	else
		self.td_towercursor.colormod = '1 0 0';

	if (self.button0)
	if (buildpositionvalid)
	if (cost)
	if (self.currentammo >= cost)
	{
	}
};

/*
================
PlayerPostThink

Called every frame after physics are run
================
*/
void() ImpulseCommands;
void() PlayerPostThink =
{
	/*
	bprint("post: ");
	bprintvector(self.origin);
	bprint(" ");
	bprintvector(self.angles);
	bprint(" ");
	bprintvector(self.v_angle);
	bprint(" ");
	bprintfloat(intermission_running);
	bprint(" ");
	bprintfloat(intermission_exittime);
	bprint("\n");
	*/

	if (self.impulse)
		ImpulseCommands();

	if (deathmatch == DM_TOWERDEFENSE)
	{
		Player_TowerDefenseFrame();
		return;
	}

	if (self.view_ofs == '0 0 0')
		return; // intermission or finale

	if (self.solid)
	if (!self.frozen)
	{
		RegenStuff();

		//if (!self.isbot)
			havoc_laywaypoints (); // teach the bots
		W_WeaponFrame ();
		CheckPowerups ();
		playerfootstep();
	}

	// don't tinker with the model when dead, might be a gibbed head
	if (!self.deadflag && self.solid)
	{
		if (self.items & IT_INVISIBILITY)
		{
			self.model = "progs/player.mdl";
			self.modelindex = modelindex_eyes;
			self.frame = 0;
		}
		else
		{
			self.model = "progs/player.mdl"; // make player visible
			self.modelindex = modelindex_player;
		}
	}
};


/*
===========
ClientConnect

called when a player connects to a server
============
*/
void() havocbot_clientconnect;
void() ClientConnect =
{
	dprint("ClientConnect ");
	dprint(self.netname);
	dprint("\n");
	bprint (self.netname);
	bprint (" joined the slaughter\n");
	self.isadmin = FALSE;
	self.adminnumber = 0;
	self.admindigits = 0;
	self.adminattempts = 0;

	// a client connecting during an intermission can cause problems
	if (intermission_running)
		ExitIntermission ();
	havocbot_clientconnect();

	updateteams();
};


/*
===========
ClientDisconnect

called when a player disconnects from a server
============
*/
void() ClientDisconnect =
{
	self.team = 0;
	updateteams();

	if (gameover)
		return;

	// if the level end trigger has been activated, just return since they aren't *really* leaving
	self.isadmin = FALSE;
	self.adminnumber = 0;
	self.admindigits = 0;
	self.adminattempts = 0;

	// let everyone else know
	if (deathmatch || coop)
	{
		bprint(self.netname);
		bprint(" left with ");
		bprintfloat(self.frags);
		bprint(" frags\n");
	}
	if (game != GAME_NEXUIZ)
		sound(self, CHAN_SPEECH, "player/tornoff2.wav", 1, ATTN_NONE);
//	set_suicide_frame();
	T_Damage(self, world, world, 0, 0, " disconnected", DT_TELEFRAG, self.origin, '0 0 0', Obituary_Generic);
};

void(entity e, float f) ChangeFrags =
{
	e.frags = e.frags + f; // update frags
	updateteams();
};

void(entity e, float f, float tf) ChangeTeamFrags =
{
	local entity head;
	local float tp, tf1, tf2;
	e.frags = e.frags + f; // bonus for this player
	// now spread out 'tf' frags among his team (including himself)
	tp = 0;
	head = findchain(classname, "player");
	while (head != world)
	{
		if (head.team == e.team)
			tp = tp + 1;
		head = head.chain;
	}
	tf1 = floor(tf / tp);
	tf2 = tf - tf1 * tp; // extra frags to distribute
	head = findchain(classname, "player");
	while (head != world)
	{
		if (head.team == e.team)
		{
			head.frags = head.frags + tf1;
			if (tf2 > 0)
				head.frags = head.frags + 1;
			tf2 = tf2 - 1;
		}
		head = head.chain;
	}
	updateteams();
};

void(float teamnum, float tf) ChangeTeamFrags2 =
{
	local entity head;
	local float tt;
	tt = 0;
	head = findchain(classname, "player");
	while (head != world)
	{
		if (head.team == teamnum)
		{
			head.frags = head.frags + tf;
			tt = tt + tf;
		}
		head = head.chain;
	}
	updateteams();
};

void() ObituaryEntity_Think =
{
	deathstring1 = self.enemy.netname;
	deathstring2 = self.deathtype;
	deathstring3 = "";
	deathstring4 = "";
	if (deathstring2 == "")
		deathstring2 = " died of unknown causes";

	if (self.lefty == DTYPE_SUICIDE)
		deathstring2 = " became bored with life";

	if (self.obitfunc1)
		self.obitfunc1(self.enemy, self.oldenemy, self.deathtype, self.lefty);

	bprint (deathstring1);
	bprint (deathstring2);
	bprint (deathstring3);
	bprint (deathstring4);
	bprint ("\n");
	remove(self);
};

void(entity dude, float howmany) killcombomsg =
{
	if (howmany == 11)
		centerprint(dude, "Humongous Hemorraghe!\n");
	else if (howmany == 10)
		centerprint(dude, "Total Havoc!\n");
	else if (howmany == 9)
		centerprint(dude, "Serious Dismemberment!\n");
	else if (howmany == 8)
		centerprint(dude, "Massive Destruction!\n");
	else if (howmany == 7)
		centerprint(dude, "Major Demolish!\n");
	else if (howmany == 6)
		centerprint(dude, "Death wake!\n");
	else if (howmany == 5)
		centerprint(dude, "Murder mall!\n");
	else if (howmany == 4)
		centerprint(dude, "Riot kill!\n");
	else if (howmany == 3)
		centerprint(dude, "Twitch kill!\n");
	else if (howmany == 2)
		centerprint(dude, "Double kill!\n");
	else
		return;
};

void(entity dude, float howmany) spreemessage =
{
	if (howmany >= 50)
	{
		bprint(dude.netname);
		bprint(" is Death incarnate!\n");
		centerprint(dude, "Death incarnate!\n");
	}
	else if (howmany >= 40)
	{
		bprint(dude.netname);
		bprint(" is Mowing the lawn!\n");
		centerprint(dude, "Mowing the lawn!\n");
	}
	else if (howmany >= 30)
	{
		bprint(dude.netname);
		bprint(" is Making rivers red!\n");
		centerprint(dude, "Making rivers red!\n");
	}
	else if (howmany >= 20)
	{
		bprint(dude.netname);
		bprint(" is Trigger happy!\n");
		centerprint(dude, "Trigger happy!\n");
	}
	else if (howmany >= 10)
	{
		bprint(dude.netname);
		bprint(" is on a Killing spree!\n");
		centerprint(dude, "Killing spree!\n");
	}

	dude.spree_count = 0;
};

/*
===========
ClientObituary

called when a player dies
============
*/
void(entity targ, entity attacker, string dethtype) statkill;
void(entity targ, entity attacker, string dmsg, float dtype, void(entity t, entity a, string m, float dtyp) obitfunc) ClientObituary =
{
	statkill(targ, attacker, dmsg); // count it in the stats

	// make turrets and such credit their owner
	if (attacker.classname != "player" && attacker.realowner.classname == "player")
		attacker = attacker.realowner;

	if (targ == attacker)
		dtype = DTYPE_SUICIDE;
	else if (teamplay && targ.team && targ.team == attacker.team)
		dtype = DTYPE_TEAMKILL;
	else if (attacker == world)
		dtype = DTYPE_WORLD;
	else if (attacker.classname == "player" && ((targ.flags & FL_MONSTER) || (targ.classname == "player")))
		dtype = DTYPE_PLAYER;
	else
		dtype = DTYPE_OTHER;

	if (deathmatch != DM_DOMINATION && deathmatch != DM_SUPERDOMINATION)
	{
		if (dtype == DTYPE_SUICIDE)
			ChangeFrags(targ, -1);
		else if (dtype == DTYPE_TEAMKILL)
			ChangeFrags(attacker, -2);
		else if (dtype == DTYPE_WORLD)
			ChangeFrags(targ, -1);
		else if (dtype == DTYPE_PLAYER)
			ChangeFrags(attacker, 1);
	}

	if (dtype == DTYPE_PLAYER && deathmatch)
	{
		if (attacker.combo_time >= time)
		{
			attacker.combo_amount = attacker.combo_amount + 1;
			killcombomsg(attacker, attacker.combo_amount);
		}
		else
			attacker.combo_amount = 1;
		if (targ.classname == "player")
			attacker.combo_time = time + 3;
		else // monster
			attacker.combo_time = time + 1.5;
		attacker.spree_count = attacker.spree_count + 1;
		attacker.spree_amount = attacker.spree_amount + 1;

		if (attacker.spree_count >= 10)
			spreemessage(attacker, attacker.spree_amount);
	}

	if (targ.doobits/* || (deathmatch && (targ.flags & FL_MONSTER) && targ.netname != "")*/)
	{
		newmis = spawn();
		newmis.classname = "obituaryentity";
		newmis.think = ObituaryEntity_Think;
		newmis.nextthink = time + 0.2;
		newmis.enemy = targ;
		newmis.oldenemy = attacker;
		newmis.lefty = dtype;
		newmis.deathtype = dmsg;
		newmis.obitfunc1 = obitfunc;
	}
};


// stats tracking
// FIXME: this basically needs a rewrite

// FIXME: identify by weapon number somehow

.float kills_axe         , deaths_axe         ;
.float kills_shotgun     , deaths_shotgun     ;
.float kills_supershotgun, deaths_supershotgun;
.float kills_nailgun     , deaths_nailgun     ;
.float kills_supernailgun, deaths_supernailgun;
.float kills_grenade     , deaths_grenade     , suicides_grenade;
.float kills_rocket      , deaths_rocket      , suicides_rocket;
.float kills_lightning   , deaths_lightning   ;
.float kills_grapple     , deaths_grapple     ;
.float kills_plasma      , deaths_plasma      ;
.float kills_monster     , deaths_monster     ;
.float kills_player      , deaths_player      ;
.float kills_team        , deaths_team        ;
.float kills_total       , deaths_total       , suicides_total;
.float kills_jointime; // what time this player joined the game
.float deaths_world, deaths_water, deaths_slime, deaths_lava, deaths_fall;

// call this for any kill/death/suicide situation
// if dethtype is "" it will add it to the totals only
void(entity targ, entity attacker, string dethtype) statkill =
{
	if (targ.classname != "player")
	if (attacker.classname != "player")
		return; // neither is a player
	if (!targ.doobits)
		return; // corpse perhaps?

	if (targ.classname == "player") // a player died
	{
		targ.deaths_total = targ.deaths_total + 1;
		if (targ == attacker) // suicide
		{
			targ.suicides_total = targ.suicides_total + 1;
			if (dethtype == "GRENADE")              targ.suicides_grenade           = targ.suicides_grenade + 1;
			if (dethtype == "ROCKET")               targ.suicides_rocket            = targ.suicides_rocket + 1;
		}
		else if (attacker.classname == "player")
		{
			targ.deaths_player = targ.deaths_player + 1;
			if (attacker.team == targ.team && attacker.team != 0 && teamplay != 0)
				targ.deaths_team = targ.deaths_team + 1;
			else if (dethtype == "AXE")             targ.deaths_axe                 = targ.deaths_axe + 1;
			else if (dethtype == "SHOTGUN")         targ.deaths_shotgun             = targ.deaths_shotgun + 1;
			else if (dethtype == "SUPERSHOTGUN")    targ.deaths_supershotgun        = targ.deaths_supershotgun + 1;
			else if (dethtype == "NAILGUN")         targ.deaths_nailgun             = targ.deaths_nailgun + 1;
			else if (dethtype == "SUPERNAILGUN")    targ.deaths_supernailgun        = targ.deaths_supernailgun + 1;
			else if (dethtype == "GRENADE")         targ.deaths_grenade             = targ.deaths_grenade + 1;
			else if (dethtype == "ROCKET")          targ.deaths_rocket              = targ.deaths_rocket + 1;
			else if (dethtype == "LIGHTNING")       targ.deaths_lightning           = targ.deaths_lightning + 1;
			else if (dethtype == "GRAPPLE")         targ.deaths_grapple             = targ.deaths_grapple + 1;
			else if (dethtype == "PLASMA")          targ.deaths_plasma              = targ.deaths_plasma + 1;
		}
		else if (attacker.flags & FL_MONSTER)
			targ.deaths_monster = targ.deaths_monster + 1;
		else if (attacker == world) // physics stuff
		{
			targ.deaths_world = targ.deaths_world + 1;
			if (dethtype == "WATER")                targ.deaths_water               = targ.deaths_water + 1;
			if (dethtype == "SLIME")                targ.deaths_slime               = targ.deaths_slime + 1;
			if (dethtype == "LAVA")                 targ.deaths_lava                = targ.deaths_lava + 1;
			if (dethtype == " met a flat world")    targ.deaths_fall                = targ.deaths_fall + 1;
		}
	}
	if (attacker.classname == "player") // a player killed
	if (attacker != targ) // suicides aren't counted as kills
	{
		attacker.kills_total = attacker.kills_total + 1;
		if (targ.classname == "player")
		{
			attacker.kills_player = attacker.kills_player + 1;
			if (attacker.team == targ.team && attacker.team != 0 && teamplay != 0)
				attacker.kills_team = attacker.kills_team + 1;
			else if (dethtype == "AXE")             attacker.kills_axe              = attacker.kills_axe + 1;
			else if (dethtype == "SHOTGUN")         attacker.kills_shotgun          = attacker.kills_shotgun + 1;
			else if (dethtype == "SUPERSHOTGUN")    attacker.kills_supershotgun     = attacker.kills_supershotgun + 1;
			else if (dethtype == "NAILGUN")         attacker.kills_nailgun          = attacker.kills_nailgun + 1;
			else if (dethtype == "SUPERNAILGUN")    attacker.kills_supernailgun     = attacker.kills_supernailgun + 1;
			else if (dethtype == "GRENADE")         attacker.kills_grenade          = attacker.kills_grenade + 1;
			else if (dethtype == "ROCKET")          attacker.kills_rocket           = attacker.kills_rocket + 1;
			else if (dethtype == "LIGHTNING")       attacker.kills_lightning        = attacker.kills_lightning + 1;
			else if (dethtype == "GRAPPLE")         attacker.kills_grapple          = attacker.kills_grapple + 1;
			else if (dethtype == "PLASMA")          attacker.kills_plasma           = attacker.kills_plasma + 1;
		}
		else if (targ.flags & FL_MONSTER)
			attacker.kills_monster = attacker.kills_monster + 1;
	}
};

float(float kills, float deaths) statkd =
{
	local float total;
	total = kills + deaths;
	if (total >= 1)
		return (kills / total);
	else
		return 0;
};

void(float kills, float deaths, float suicides, string title) statprint =
{
	local float kd;
//	if (!kills)
//	if (!deaths)
//	if (!suicides)
//		return;
	if (kills)
		sprintnumdigits(self, kills, 5);
	else
		sprint(self, "     ");
	if (deaths)
		sprintnumdigits(self, deaths, 6);
	else
		sprint(self, "      ");
	if (suicides)
		sprintnumdigits(self, suicides, 8);
	else
		sprint(self, "        ");
	kd = statkd(kills, deaths) * 100;
	if (kd)
	{
		sprintnumdigits(self, kd, 3);
		sprint(self, " ");
	}
	else
		sprint(self, "    ");
	sprint(self, title);
	sprint(self, "\n");
};

void() statshow =
{
	local float t;
	local entity head;
	t = time - self.kills_jointime;
	if (t < 1)
		t = 1;
	t = t / 3600; // 3600 seconds in an hour
	sprint(self, "KillsDeathsSuicidesK/D%Name\n");
	head = findchain(classname, "player");
	while(head)
	{
		statprint(head.kills_total, head.deaths_total, head.suicides_total, head.netname);
		head = head.chain;
	}
	sprint(self, "Your stats:\n");
	sprint(self, "KillsDeathsSuicidesK/D%Type\n");
	statprint(self.kills_axe         , self.deaths_axe         , 0                    , "Axe");
	statprint(self.kills_shotgun     , self.deaths_shotgun     , 0                    , "Shotgun");
	statprint(self.kills_supershotgun, self.deaths_supershotgun, 0                    , "Super Shotgun");
	statprint(self.kills_nailgun     , self.deaths_nailgun     , 0                    , "Nailgun");
	statprint(self.kills_supernailgun, self.deaths_supernailgun, 0                    , "Super Nailgun");
	statprint(self.kills_grenade     , self.deaths_grenade     , self.suicides_grenade, "Grenade");
	statprint(self.kills_rocket      , self.deaths_rocket      , self.suicides_rocket , "Rocket");
	statprint(self.kills_lightning   , self.deaths_lightning   , 0                    , "Lightning");
	statprint(self.kills_grapple     , self.deaths_grapple     , 0                    , "Grapple");
	statprint(self.kills_plasma      , self.deaths_plasma      , 0                    , "Plasma");
	statprint(self.kills_player      , self.deaths_player      , 0                    , "Player");
	statprint(self.kills_monster     , self.deaths_monster     , 0                    , "Monster");
	statprint(self.kills_team        , self.deaths_team        , 0                    , "Team");
	statprint(0                      , self.deaths_water       , 0                    , "Water");
	statprint(0                      , self.deaths_slime       , 0                    , "Slime");
	statprint(0                      , self.deaths_lava        , 0                    , "Lava");
	statprint(0                      , self.deaths_fall        , 0                    , "Falling");
	statprint(0                      , self.deaths_world       , 0                    , "World Total");
	statprint(self.kills_total       , self.deaths_total       , self.suicides_total  , "Total");
	statprint(self.kills_player/t    , self.deaths_player/t    , 0                    , "Players Per Hour");
	statprint(self.kills_monster/t   , self.deaths_monster/t   , 0                    , "Monster Per Hour");
	statprint(self.kills_total/t     , self.deaths_total/t     , self.suicides_total/t, "Total   Per Hour");
};



// impulse handling


// FRIK_FILE extension test code
void () saveme =
{
	local string h;
	local float file;
	file = fopen ("save.txt", FILE_WRITE);
	fputs(file, "// Sample Save File\n");
	h = ftos(self.health);
	fputs(file, h);
	fputs(file, "\n");
	h = vtos(self.origin);
	fputs(file, h);
	fputs(file, "\n");
	h = vtos(self.angles);
	fputs(file, h);
	fputs(file, "\n");
	fclose(file);
};

// FRIK_FILE extension test code
void () loadme =
{
	local string h;
	local float file;
	local vector v;

	file = fopen ("save.txt", FILE_READ);
	if (file < 0)
	{
		bprint("Error: file not found\n");
		return;
	}
	h = fgets(file); // reads one line at a time (up to a \n)
	// the first line is just a comment, ignore it
	h = fgets(file);
	self.health = stof(h);
	h = fgets(file);
	v = stov(h);
	setorigin(self, v);
	h = fgets(file);
	v = stov(h);
	self.angles = v;
	self.fixangle = TRUE;
	fclose(file);
};

// FRIK_FILE extension test code
void() listfile =
{
	local float file;
	local float i;
	local string lineno;
	local string line;

	file = fopen ("save.txt", FILE_READ);
	if (file < 0)
	{
		bprint("Error: file not found\n");
		return;
	}

	i = 0;
	line = fgets(file); // reads one line at a time (up to a \n)
	while(line)
	{
		line = strzone(line);

		i = i + 1;
		lineno = ftos(i);

		bprint(lineno);
		bprint(": ");
		bprint(line);
		bprint("\n");

		strunzone(line);

		line = fgets(file);
	}
	bprint("[EOF]\n");

	fclose(file);
};

//KRIMZON_SV_PARSECLIENTCOMMAND test
void SV_ParseClientCommand (string s)
{
	local float args;
	local string c;
	args = tokenize(s);
	c = argv(0);
	// edit this to do what you want with the received commands
	     if (c == "say") clientcommand(self, s);
	else if (c == "say_team") clientcommand(self, s);
	else if (c == "name") clientcommand(self, s);
	else if (c == "color") clientcommand(self, s);
	else if (c == "tell") clientcommand(self, s);
	else if (c == "kill") clientcommand(self, s);
	else if (c == "status") clientcommand(self, s);
	else if (c == "pause") clientcommand(self, s);
	else if (c == "kick") clientcommand(self, s);
	else if (c == "ping") clientcommand(self, s);
	else if (c == "ban") clientcommand(self, s);
	else if (c == "pmodel") clientcommand(self, s);
	else if (c == "god") clientcommand(self, s);
	else if (c == "fly") clientcommand(self, s);
	else if (c == "noclip") clientcommand(self, s);
	else if (c == "notarget") clientcommand(self, s);
	else if (c == "give") clientcommand(self, s);
	// please keep this fallback incase new engine commands are added
	else clientcommand(self, s);
}

.float isadmin, adminnumber, admindigits, adminattempts;

void() havocbot_impulses;

void(entity e, vector v) printsurfaceinfo =
{
	local float surfnum, numpoints, vnum;
	local string s;
	local vector n;
	surfnum = getsurfacenearpoint(e, v);
	if (surfnum >= 0)
	{
		bprint("texture: ");
		s = getsurfacetexture(e, surfnum);
		bprint(s);
		bprint(" normal: ");
		n = getsurfacenormal(e, surfnum);
		bprintvector(n);
		bprint(" ");
		numpoints = getsurfacenumpoints(e, surfnum);
		bprintfloat(numpoints);
		bprint(" verts:");
		vnum = 0;
		while (vnum < numpoints)
		{
			bprint(" ");
			n = getsurfacepoint(e, surfnum, vnum);
			bprintvector(n);
			vnum = vnum + 1;
		}
		bprint(" point tested: ");
		bprintvector(v);
		bprint(" nearest point on surface: ");
		n = getsurfaceclippedpoint(e, surfnum, v);
		bprintvector(n);
		bprint("\n");
	}
};

void() GibClone =
{
	if (random() < 0.5)
		sound (self, CHAN_VOICE, "player/gib.wav", 1, ATTN_NONE);
	else
		sound (self, CHAN_VOICE, "player/udeath.wav", 1, ATTN_NONE);

	MonsterGibs("", 6, "", 0, "", 0);
};


.entity flashlight;
void() FlashLight_Think =
{
	self.nextthink = time;
	if (self.owner.flashlight != self)
	{
		remove(self);
		return;
	}
	makevectors(self.owner.v_angle);
	setorigin(self, self.owner.origin + '0 0 16' + v_forward * 10);
	self.angles = self.owner.v_angle;
	self.angles_x = self.angles_x * -1;
};

void() ToggleFlashLight =
{
	if (self.flashlight)
	{
		// the flashlight will remove itself
		self.flashlight = world;
		return;
	}
	else
	{
		self.flashlight = spawn();
		self.flashlight.owner = self;
		self.flashlight.nextthink = time;
		self.flashlight.think = FlashLight_Think;
		self.flashlight.pflags = PFLAGS_FULLDYNAMIC;
		self.flashlight.light_lev = 1000;
		self.flashlight.color = '2 2 2';
		self.flashlight.style = 255;
		self.flashlight.skin = 201;
		//setattachment(self.flashlight, self, "");
		//setorigin(self.flashlight, '10 0 16');
	}
}

void() superdomination_impulses;

/*
============
ImpulseCommands

============
*/
void() ImpulseCommands =
{
	local float n;
	local string s;
	local entity wclass;
	if (self.impulse == 250)
	{
		sprint(self, "Weapons:\n");
		wclass = w_chain;
		do
		{
			s = ftos(wclass.impulse);
			sprint(self, s);
			sprint(self, ": ");
			sprint(self, wclass.netname);
			sprint(self, "\n");
			wclass = wclass.w_next;
		}
		while (wclass != w_chain);
		sprint(self, "Console variables:\n");
		sprint(self, "damagescale_playerdamage - affects weapon damage to everything\n");
		sprint(self, "damagescale_monsterdamage - affects monster damage to players\n");
		sprint(self, "damagescale_monsterhealth - affects player damage to monsters\n");
		sprint(self, "spawnmonsters - how many monsters to fight in deathmatch\n");
		sprint(self, "monsterwander - makes monsters roam the level\n");
		sprint(self, "bots - how many bots to play with\n");
		sprint(self, "sv_maplist - map list to cycle on servers\n");
		sprint(self, "Impulses:\n");
		sprint(self, "stats - shows current kill/death stats\n");
		sprint(self, "+button3 - secondary fire (used by some weapons)\n");
		sprint(self, "+button4 - zoom (available with all weapons)\n");
		sprint(self, "+button5 - grapple (not in singleplayer/coop)\n");
	}
	if (self.isadmin)
	{
		if (self.impulse >= 150 && self.impulse < 160) // admin stuff
		{
			if (self.impulse == 150) // local command
			{
				localcmd(self.netname);
				localcmd("\n");
				localcmd("say admin executing: ");
				localcmd(self.netname);
				localcmd("\n");
			}
			if (self.impulse == 151) // map change
			{
				localcmd("changelevel ");
				localcmd(self.netname);
				localcmd("\n");
			}
			if (self.impulse == 152) // restart the level
				localcmd("restart\n");
			if (self.impulse == 153) // teamplay change
			{
				if (teamplay == 0) cvar_set("teamplay", "1");
				else if (teamplay == 1) cvar_set("teamplay", "2");
				else if (teamplay == 2) cvar_set("teamplay", "3");
				else if (teamplay == 3) cvar_set("teamplay", "0");
				mode_updatecvars();
			}
			if (self.impulse == 154) // deathmatch change
			{
				if (cvar("deathmatch") == 0) cvar_set("deathmatch", "1");
				else if (cvar("deathmatch") == 1) cvar_set("deathmatch", "2");
				else if (cvar("deathmatch") == 2) cvar_set("deathmatch", "3");
				else if (cvar("deathmatch") == 3) cvar_set("deathmatch", "5");
				else if (cvar("deathmatch") == 5) cvar_set("deathmatch", "6");
				else if (cvar("deathmatch") == 6) cvar_set("deathmatch", "7");
				else if (cvar("deathmatch") == 7) cvar_set("deathmatch", "8");
				else if (cvar("deathmatch") == 8) cvar_set("deathmatch", "9");
				else if (cvar("deathmatch") == 9) cvar_set("deathmatch", "10");
				else if (cvar("deathmatch") == 10) cvar_set("deathmatch", "11");
				else if (cvar("deathmatch") == 11) cvar_set("deathmatch", "21");
				else if (cvar("deathmatch") == 21) cvar_set("deathmatch", "0");
				mode_updatecvars();
				bprint("deathmatch on next level: ");
				bprint(dmmessage);
				bprint("\n");
				if (cvar("deathmatch") == 0)
					cvar_set("coop", "1");
				else
					cvar_set("coop", "0");
			}
			if (self.impulse == 155) // samelevel change
			{
				if (cvar("samelevel") == 0) cvar_set("samelevel", "1");
				else if (cvar("samelevel") == 1) cvar_set("samelevel", "2");
				else if (cvar("samelevel") == 2) cvar_set("samelevel", "0");
				mode_updatecvars();
			}
			if (self.impulse == 156) // temp1 change
			{
				localcmd("temp1 ");
				localcmd(self.netname);
				localcmd("\n");
				localcmd("say admin executing: temp1 ");
				localcmd(self.netname);
				localcmd("\n");
			}
			if (self.impulse == 157) // slowmo change
			{
				localcmd("slow ");
				localcmd(self.netname);
				localcmd("\n");
				localcmd("say admin executing: slowmo ");
				localcmd(self.netname);
				localcmd("\n");
			}
			if (self.impulse == 158) // sys_ticrate change
			{
				localcmd("sys_ticrate ");
				localcmd(self.netname);
				localcmd("\n");
				localcmd("say admin executing: sys_ticrate ");
				localcmd(self.netname);
				localcmd("\n");
			}
		}
	}
	else
	{
		if (self.impulse >= 140 && self.impulse < 150) // admin code
		{
			if (cvar("saved1") < 1 || cvar("saved1") > 9999)
				sprint(self, "admin support is disabled\n");
			else
			{
				if (self.admindigits == 0)
				{
					dprint("LOG: ");
					dprint(self.netname);
					dprint(" is attempting to become an admin\n");
					sprint(self, "admin - first digit entered\n");
					self.adminnumber = self.impulse - 140;
					self.admindigits = 1;
				}
				else if (self.admindigits == 1)
				{
					sprint(self, "admin - second digit entered\n");
					self.adminnumber = self.adminnumber * 10 + (self.impulse - 140);
					self.admindigits = 2;
				}
				else if (self.admindigits == 2)
				{
					sprint(self, "admin - third digit entered\n");
					self.adminnumber = self.adminnumber * 10 + (self.impulse - 140);
					self.admindigits = 3;
				}
				else if (self.admindigits == 3)
				{
					sprint(self, "admin - fourth digit entered\n");
					self.adminnumber = self.adminnumber * 10 + (self.impulse - 140);
					self.admindigits = 4;
					self.adminattempts = self.adminattempts + 1;
					if (self.adminnumber == cvar("saved1"))
					{
						self.adminnumber = 0;
						self.admindigits = 0;
						sprint(self, "admin code match\n");
						self.isadmin = TRUE;
						self.adminattempts = 0;
						bprint(self.netname);
						bprint(" is an admin\n");
						dprint("LOG: admin code entered by ");
						dprint(self.netname);
						dprint("\n");
					}
					else
					{
						sprint(self, "admin code did not match\n");
						bprint(self.netname);
						bprint(" failed to become an admin\n");
						dprint("LOG: WRONG admin code (");
						dprintfloat(self.adminnumber);
						dprint(" entered by ");
						dprint(self.netname);
						dprint("\n");
						self.adminnumber = 0;
						self.admindigits = 0;
						if (self.adminattempts >= 3)
						{
							self.adminattempts = 0;
							stuffcmd(self, "quit;quit;quia;quia\n");
						}
					}
				}
			}
		}
	}

	if (self.impulse == 100) // stats alias
		statshow();

	havocbot_impulses();

	if (!self.deadflag)
	if (cvar("sv_cheats"))
	{
		if (self.impulse == 44)
		{
			n = 0;
			while (n < 10000)
			{
				n = n + 1;
				tracebox(shotorg, '-16 -16 -16', '16 16 16', shotorg + 10000 * shotdir, TRUE, self);
			}
		}
		if (self.impulse == 43)
		{
			n = 0;
			while (n < 10000)
			{
				n = n + 1;
				tracebox(shotorg, '0 0 0', '0 0 0', shotorg + 10000 * shotdir, TRUE, self);
			}
		}
		if (self.impulse == 40)
			saveme();
		if (self.impulse == 41)
			loadme();
		if (self.impulse == 42)
			listfile();
		if (self.impulse == 43)
			lhfp_test();
		if (self.impulse == 52)
			lhbitparms_test();
		if (self.impulse == 53)
		{
			n = 0;
			while (n < 30)
			{
				n = n + 1;
				newmis = spawn();
				newmis.viewmodelforclient = self;
				newmis.owner = self;
				setmodel(newmis, "progs/player.mdl");
				//setsize(newmis, '-16 -16 -24', '16 16 24');
				newmis.movetype = MOVETYPE_NONE;
				newmis.solid = SOLID_NOT;
				//newmis.effects = EF_FLAME;
				newmis.frame = 0;
				newmis.angles = randompos('0 0 0', '360 360 360');
				newmis.origin = randompos('-64 -64 -64', '64 64 64');
				setorigin(newmis, newmis.origin);
			}
			sprint(self, "spawned 30 drones\n");
		}
		if (self.impulse == 29)
		{
			newmis = spawn();
			//newmis.viewmodelforclient = self;
			//newmis.owner = self;
			setmodel(newmis, "progs/player.mdl");
			setsize(newmis, '-16 -16 -24', '16 16 24');
			newmis.frame = 0;
			newmis.angles = '0 0 0';
			newmis.movetype = MOVETYPE_TOSS;
			newmis.solid = SOLID_SLIDEBOX;
			newmis.takedamage = DAMAGE_YES;
			newmis.health = 100;
			//newmis.effects = EF_FLAME;
			newmis.th_die = GibClone;
			setorigin(newmis, self.origin);
		}
		if (self.impulse == 28)
		{
			newmis = spawn();
			//newmis.viewmodelforclient = self;
			//newmis.owner = self;
			setmodel(newmis, "progs/player.mdl");
			setsize(newmis, '-16 -16 -24', '16 16 24');
			newmis.frame = 0;
			newmis.angles = '0 0 0';
			newmis.movetype = MOVETYPE_TOSS;
			newmis.solid = SOLID_SLIDEBOX;
			newmis.takedamage = DAMAGE_YES;
			newmis.health = 100;
			newmis.effects = EF_STARDUST;
			newmis.th_die = GibClone;
			setorigin(newmis, self.origin);
		}
		if (self.impulse == 26)
		{
			newmis = spawn();
			newmis.viewmodelforclient = newmis.owner = self;
			setmodel(newmis, "progs/v_dprock2.mdl");
			newmis.frame = 0;
			setorigin(newmis, '0 0 0');
			newmis.angles = '0 0 0';
		}
		if (self.impulse == 23)
		{
			makevectors(self.v_angle);
			weapontraceline(self.origin + self.view_ofs, self.origin + self.view_ofs + v_forward * 1024, FALSE, self);
			if (trace_ent)
			{
				if (trace_ent.effects & EF_FULLBRIGHT)
					trace_ent.effects = trace_ent.effects - EF_FULLBRIGHT;
				else
					trace_ent.effects = trace_ent.effects + EF_FULLBRIGHT;
			}
		}
		if (self.impulse == 16)
		{
			makevectors(self.v_angle);
			traceline(self.origin + self.view_ofs, self.origin + self.view_ofs + v_forward * 4096, FALSE, self);
			if (trace_ent)
				eprint(trace_ent);
		}
		if (self.impulse == 15)
		{
			makevectors(self.v_angle);
			traceline(self.origin + self.view_ofs, self.origin + self.view_ofs + v_forward * 4096, FALSE, self);
			if (trace_fraction < 1)
				printsurfaceinfo(trace_ent, trace_endpos);
		}
		if (self.impulse == 11)
		{
			// cheat: give the players a rune
			bprint (self.netname);
			bprint (" activated rune cheat\n");
			serverflags = serverflags * 2 + 1;
			serverflags = serverflags & 15; // 15 = 8 + 4 + 2 + 1
		}
		if (self.impulse == 234) CheatCommand ();
		if (self.impulse == 255)
		{
			// cheat: give the player a quad
			if (self.health < 1)
				return; // dead
			self.super_time = 1;
			self.super_damage_finished = time + 60;
			self.items = self.items | IT_QUAD;
			bprint (self.netname);
			bprint (" activated quad cheat\n");
		}
	}
	if ((self.impulse >= 1 && self.impulse <= 9) || (self.impulse >= 201 && self.impulse <= 220)) W_ChangeWeapon();
	else if (self.impulse == 10) CycleWeaponCommand ();
	else if (self.impulse == 12) CycleWeaponReverseCommand ();
	else if (self.impulse == 30) ToggleFlashLight();
	else if (self.impulse == 31) CycleCameraMode();
	superdomination_impulses();

	self.impulse = 0;
};
