
.float isbot;

.float isadmin, adminnumber, admindigits, adminattempts;

// prototypes
void () W_WeaponFrame;
//void() W_SetCurrentAmmo;
void(entity attacker, float take) player_pain;
void() player_move;
void (vector org) spawn_tfog;
void (vector org, entity death_owner, vector org2) spawn_tdeath;

void() GibPlayer;
void() PlayerDead;

float modelindex_eyes/*, modelindex_player*/;
//float modelindex_player_sg, modelindex_player_dbsg;
//float modelindex_player_ng, modelindex_player_sng;
//float modelindex_player_gl, modelindex_player_rl;
//float modelindex_player_lg;
//float modelindex_null;

float modelindex_nogun;

//used for combo kills
.float combo_time;
.float combo_amount;
//used for killing sprees
.float spree_amount;
.float spree_count;

/*
void() speech_precache =
{
	gibcomment_precache();
	// used by taunt code in weapons.qc impulse system
	precache_sound("speech/camp/campgrnd.wav");
	precache_sound("speech/camp/tentfire.wav");
	precache_sound("speech/camp/view.wav");
	precache_sound("speech/gib/lookbetr.wav");
	precache_sound("speech/taunt/crawlfrm.wav");
	precache_sound("speech/gib/niceday.wav");
	precache_sound("speech/gib/cool.wav");
	precache_sound("speech/gib/awesome.wav");
	precache_sound("speech/gib/aisle12.wav");
	precache_sound("speech/gib/scrapeof.wav");
};
*/

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

	if ( (self.spawnflags & 1) && (deathmatch == 0) )
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
		//if (self.flags & FL_CLIENT) // not needed with DP_SV_BOTCLIENT
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
//	bprint (self.netname);
//	bprint (" killed himself\n");
//	set_suicide_frame ();
//	self.modelindex = modelindex_player;
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
	else if (deathmatch == DM_CTF_2TEAM || deathmatch == DM_CTF_3TEAM || deathmatch == DM_MCTF_2TEAM)
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
		while (1)
		{
			spot = find(spot, classname, cname);
			if (spot != world)
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
	else if (deathmatch && find(world, classname, "info_player_deathmatch") != world)
	{
		spot = lastspawn;
		while (1)
		{
			spot = find(spot, classname, "info_player_deathmatch");
			if (spot != world)
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
void() PutClientInServer =
{
	local entity spot;

	self.classname = "player";

	// apply physics stuff (bleeding, drowning, slime, lava, etc)
	self.iscreature = TRUE;
	self.forcescale = 5; // for damage kick calculations
	self.cantrigger = TRUE; // can trigger buttons etc
	// self.lastwaypoint = world; // to avoid confusing the waypoint list
	self.iscorpse = FALSE;
	self.isdecor = FALSE;
	self.bleedratio = 1; // 100% bleeding damage (see t_damage.qc)
	// make self completely visible
	self.alpha = 0;

	// not needed with DP_SV_BOTCLIENT
	//if (self.isbot)
	//	self.flags = 0;
	//else
		self.flags = FL_CLIENT;

	self.th_pain = player_pain;
	self.th_die = PlayerDie;
	self.th_gib = GibPlayer;

//	self.bleeddamagecount = 0; // just used for how much gore to do...

//	self.bleedcount = 0; // clear the bleeding damage counter
	self.bubble_count = 0;
	self.candrown = TRUE;

	/*
	// localdamage stuff (headshots etc)
	self.localdamage = TRUE;
	self.localdamage_head_mul = 5.0;
	self.localdamage_body_mul = 1.0;
	self.localdamage_hit = LD_NORMAL;
	*/

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

	// oh, this is a hack!
	if (modelindex_eyes == 0) // hasn't been done yet
	{
//		setmodel (self, "progs/null.spr");
//		modelindex_null = self.modelindex;

		setmodel (self, "progs/eyes.mdl");
		modelindex_eyes = self.modelindex;

/*
		setmodel (self, "progs/playersg.mdl");
		modelindex_player_sg = self.modelindex;

		setmodel (self, "progs/playerss.mdl");
		modelindex_player_dbsg = self.modelindex;

		setmodel (self, "progs/playernl.mdl");
		modelindex_player_ng = self.modelindex;

		setmodel (self, "progs/playersn.mdl");
		modelindex_player_sng = self.modelindex;

		setmodel (self, "progs/playergr.mdl");
		modelindex_player_gl = self.modelindex;

		setmodel (self, "progs/playerrl.mdl");
		modelindex_player_rl = self.modelindex;

		setmodel (self, "progs/playerli.mdl");
		modelindex_player_lg = self.modelindex;
*/

		setmodel (self, "progs/playernogun.mdl");
		modelindex_nogun = self.modelindex;

		setmodel (self, "progs/player.mdl");
//		modelindex_player = self.modelindex;
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

//	if (deathmatch || coop)
//	{
//		makevectors(self.angles);
//		spawn_tfog (self.origin + v_forward*20);
//	}
	spawn_tfog(self.origin);
	spawn_tdeath (self.origin, self, '0 0 0');

	if (self.isbot)
		havocbot_chooserole();

	if (!self.solid) // observer
		return;

	player_move ();

	if (darkmode)
	if (self.flashlight == world)
		ToggleFlashLight();
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
	if (metroidmode)
		self.velocity_z = self.velocity_z + 350;
	else
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

	// fade pain view kick
	a = vlen(self.punchvector);
	if (a)
	{
		r = a - frametime * 15;
		if (r < 0)
			r = 0;
		self.punchvector = self.punchvector * (r / a);
	}

	if (!self.solid) // observer
	{
		self.frame = 0;
//		return;
	}
	/*
	if (self.deadflag)
	{
		self.model = "";
		self.modelindex = 0;
	}
	*/

	if (cvar("temp1") & 4096)
	{
		Inventory_SetQuantity(self, "shells", AMMOMAX_SHELLS);
		Inventory_SetQuantity(self, "nails", AMMOMAX_NAILS);
		Inventory_SetQuantity(self, "rockets", AMMOMAX_ROCKETS);
		Inventory_SetQuantity(self, "cells", AMMOMAX_CELLS);
	}

	if (intermission_running)
	{
		IntermissionThink (); // otherwise a button could be missed
		return;               // between the think tics
	}

	if (self.view_ofs == '0 0 0')
		return;		// intermission or finale

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
		//self.model = "";
		//self.modelindex = 0;
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
		//self.model = "";
		//self.modelindex = 0; // in DP players are invisible when dead
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
					flashscreen(self);
				}
				if (game != GAME_NEXUIZ)
					sound (self, CHAN_AUTO, "items/inv2.wav", 1, ATTN_NORM);
				self.invisible_time = time + 1;
			}

			if (self.invisible_time < time)
			{
				self.invisible_time = time + 1;
				flashscreen(self);
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
					flashscreen(self);
				}
				if (game != GAME_NEXUIZ)
					sound (self, CHAN_AUTO, "items/protect2.wav", 1, ATTN_NORM);
				self.invincible_time = time + 1;
			}

			if (self.invincible_time < time)
			{
				self.invincible_time = time + 1;
				flashscreen(self);
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
					flashscreen(self);
				}
				if (game != GAME_NEXUIZ)
					sound (self, CHAN_AUTO, "items/damage2.wav", 1, ATTN_NORM);
				self.super_time = time + 1;
			}

			if (self.super_time < time)
			{
				self.super_time = time + 1;
				flashscreen(self);
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
					flashscreen(self);
				}
				if (game != GAME_NEXUIZ)
					sound (self, CHAN_AUTO, "items/suit2.wav", 1, ATTN_NORM);
				self.rad_time = time + 1;
			}

			if (self.rad_time < time)
			{
				self.rad_time = time + 1;
				flashscreen(self);
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

void() havoc_laywaypoints;

void() player_updatebounds;

/*
================
PlayerPostThink

Called every frame after physics are run
================
*/
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

	if (self.view_ofs == '0 0 0')
		return; // intermission or finale

	if (self.impulse)
		ImpulseCommands();

	if (self.solid)
	if (!self.frozen)
	{
		RegenStuff();

		//if (!self.isbot)
			havoc_laywaypoints (); // teach the bots
		W_WeaponFrame ();
		CheckPowerups ();
		player_updatebounds(); // for detecting headshots etc
		GibCommentCheck();
		playerfootstep();
	}

	dovisibleweapon();
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
};


/*
===========
ClientDisconnect

called when a player disconnects from a server
============
*/
void() ClientDisconnect =
{
	if (gameover)
		return;
	// if the level end trigger has been activated, just return since they aren't *really* leaving
	self.isadmin = FALSE;
	self.adminnumber = 0;
	self.admindigits = 0;
	self.adminattempts = 0;

	// let everyone else know
//	bprint(self.netname);
//	bprint(" left with ");
//	bprintfloat(self.frags);
//	bprint(" frags\n");
	if (game != GAME_NEXUIZ)
		sound(self, CHAN_SPEECH, "player/tornoff2.wav", 1, ATTN_NONE);
//	set_suicide_frame();
	T_Damage(self, world, world, 0, 0, " disconnected", DT_TELEFRAG, self.origin, '0 0 0', Obituary_Generic);
};

void(entity e, float f) ChangeFrags =
{
	local entity head;
	e.frags = e.frags + f; // update frags
	// now update the info on the team
	head = findchain(classname, "teamscore");
	while (head != world)
	{
		if (head.team == e.team)
		{
			head.frags = head.frags + f;
			if (teamplay)
			{
				bprint(head.netname);
				bprint(" team now has ");
				bprintfloat(head.frags);
				bprint(" frags\n");
			}
			head = world;
		}
		else
			head = head.chain;
	}
	//onevsallupdateteams();
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
	// now update the info on the team
	head = findchain(classname, "teamscore");
	while (head != world)
	{
		if (head.team == e.team)
		{
			head.frags = head.frags + f + tf;
			if (teamplay)
			{
				bprint(head.netname);
				bprint(" team now has ");
				bprintfloat(head.frags);
				bprint(" frags\n");
			}
		}
		head = head.chain;
	}
	//onevsallupdateteams();
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
	// now update the info on the team
	head = findchain(classname, "teamscore");
	while (head != world)
	{
		if (head.team == teamnum)
		{
			head.frags = head.frags + tt;
			if (teamplay)
			{
				bprint(head.netname);
				bprint(" team now has ");
				bprintfloat(head.frags);
				bprint(" frags\n");
			}
		}
		head = head.chain;
	}
	//onevsallupdateteams();
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
