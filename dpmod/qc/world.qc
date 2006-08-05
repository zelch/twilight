
float darkmode;

float maxclients; // how many player slots there actually are

float monsterwander;

.float dmgtime;
.float candrown;
.float drown_finished;

void() damagescaleupdate;

entity lastspawn;

string nextmap;
void() execute_changelevel;

void(vector org, vector vel, float size) makebubble;

.float iscreature;

void() CheckRules; // defined in client.qc
void() modeupdate;
void() modesetup;
void() havocbot_serverframe;

float serverinactive;

.float bubble_time;

/*
===============================================================================

RULES

===============================================================================
*/

/*
go to the next level for deathmatch
only called if a time or frag limit has expired
*/
void() NextLevel =
{
	local entity o;

	if (cvar("samelevel"))
	{
		nextmap = mapname;
		gameover = TRUE;
		execute_changelevel();
		return;
	}

	if (mapname == "start")
	{
		if (!cvar("registered"))
		{
			mapname = "e1m1";
		}
		else if (!(serverflags & 1))
		{
			mapname = "e1m1";
			serverflags = serverflags | 1;
		}
		else if (!(serverflags & 2))
		{
			mapname = "e2m1";
			serverflags = serverflags | 2;
		}
		else if (!(serverflags & 4))
		{
			mapname = "e3m1";
			serverflags = serverflags | 4;
		}
		else if (!(serverflags & 8))
		{
			mapname = "e4m1";
			serverflags = serverflags - 7;
		}

		o = spawn();
		o.map = mapname;
	}
	else
	{
		// find a trigger changelevel
		o = find(world, classname, "trigger_changelevel");

		// go back to start if no trigger_changelevel
		if (!o)
		{
			mapname = "start";
			o = spawn();
			o.map = mapname;
		}
	}

	nextmap = o.map;
	gameover = TRUE;

	if (o.nextthink < time)
	{
		o.think = execute_changelevel;
		o.nextthink = time + 0.1;
	}
};

/*
============
CheckRules

Exit deathmatch games upon conditions
============
*/
void() CheckRules =
{
	local float timelimit;
	local float fraglimit;
	local entity head;

	if (gameover) // someone else quit the game already
		return;

	timelimit = cvar("timelimit") * 60;
	fraglimit = cvar("fraglimit");

	if (timelimit > 0)
	if (time >= timelimit)
	{
		NextLevel ();
		return;
	}

	if (fraglimit > 0)
	{
		head = findchain(classname, "player");
		while (head)
		{
			if (head.frags >= fraglimit)
			{
				NextLevel ();
				return;
			}
			head = head.chain;
		}
	}
};

void() main =
{
	dprint ("main function\n");

// these just command the prog compiler to copy these files

	precache_file ("progs.dat");
	precache_file ("gfx.wad");
	precache_file ("quake.rc");
	precache_file ("default.cfg");

	precache_file ("end1.bin");
	precache_file2 ("end2.bin");

	precache_file ("demo1.dem");
	precache_file ("demo2.dem");
	precache_file ("demo3.dem");

//
// these are all of the lumps from the cached.ls files
//
	precache_file ("gfx/palette.lmp");
	precache_file ("gfx/colormap.lmp");

	precache_file2 ("gfx/pop.lmp");

	precache_file ("gfx/complete.lmp");
	precache_file ("gfx/inter.lmp");

	precache_file ("gfx/ranking.lmp");
	precache_file ("gfx/vidmodes.lmp");
	precache_file ("gfx/finale.lmp");
	precache_file ("gfx/conback.lmp");
	precache_file ("gfx/qplaque.lmp");

	precache_file ("gfx/menudot1.lmp");
	precache_file ("gfx/menudot2.lmp");
	precache_file ("gfx/menudot3.lmp");
	precache_file ("gfx/menudot4.lmp");
	precache_file ("gfx/menudot5.lmp");
	precache_file ("gfx/menudot6.lmp");

	precache_file ("gfx/menuplyr.lmp");
	precache_file ("gfx/bigbox.lmp");
	precache_file ("gfx/dim_modm.lmp");
	precache_file ("gfx/dim_drct.lmp");
	precache_file ("gfx/dim_ipx.lmp");
	precache_file ("gfx/dim_tcp.lmp");
	precache_file ("gfx/dim_mult.lmp");
	precache_file ("gfx/mainmenu.lmp");

	precache_file ("gfx/box_tl.lmp");
	precache_file ("gfx/box_tm.lmp");
	precache_file ("gfx/box_tr.lmp");

	precache_file ("gfx/box_ml.lmp");
	precache_file ("gfx/box_mm.lmp");
	precache_file ("gfx/box_mm2.lmp");
	precache_file ("gfx/box_mr.lmp");

	precache_file ("gfx/box_bl.lmp");
	precache_file ("gfx/box_bm.lmp");
	precache_file ("gfx/box_br.lmp");

	precache_file ("gfx/sp_menu.lmp");
	precache_file ("gfx/ttl_sgl.lmp");
	precache_file ("gfx/ttl_main.lmp");
	precache_file ("gfx/ttl_cstm.lmp");

	precache_file ("gfx/mp_menu.lmp");

	precache_file ("gfx/netmen1.lmp");
	precache_file ("gfx/netmen2.lmp");
	precache_file ("gfx/netmen3.lmp");
	precache_file ("gfx/netmen4.lmp");
	precache_file ("gfx/netmen5.lmp");

	precache_file ("gfx/sell.lmp");

	precache_file ("gfx/help0.lmp");
	precache_file ("gfx/help1.lmp");
	precache_file ("gfx/help2.lmp");
	precache_file ("gfx/help3.lmp");
	precache_file ("gfx/help4.lmp");
	precache_file ("gfx/help5.lmp");

	precache_file ("gfx/pause.lmp");
	precache_file ("gfx/loading.lmp");

	precache_file ("gfx/p_option.lmp");
	precache_file ("gfx/p_load.lmp");
	precache_file ("gfx/p_save.lmp");
	precache_file ("gfx/p_multi.lmp");

// sounds loaded by C code
	precache_sound ("misc/menu1.wav");
	precache_sound ("misc/menu2.wav");
	precache_sound ("misc/menu3.wav");

	precache_sound ("ambience/water1.wav");
	precache_sound ("ambience/wind2.wav");

// shareware
	precache_file ("maps/start.bsp");

	precache_file ("maps/e1m1.bsp");
	precache_file ("maps/e1m2.bsp");
	precache_file ("maps/e1m3.bsp");
	precache_file ("maps/e1m4.bsp");
	precache_file ("maps/e1m5.bsp");
	precache_file ("maps/e1m6.bsp");
	precache_file ("maps/e1m7.bsp");
	precache_file ("maps/e1m8.bsp");

// registered
	precache_file2 ("gfx/pop.lmp");

	precache_file2 ("maps/e2m1.bsp");
	precache_file2 ("maps/e2m2.bsp");
	precache_file2 ("maps/e2m3.bsp");
	precache_file2 ("maps/e2m4.bsp");
	precache_file2 ("maps/e2m5.bsp");
	precache_file2 ("maps/e2m6.bsp");
	precache_file2 ("maps/e2m7.bsp");

	precache_file2 ("maps/e3m1.bsp");
	precache_file2 ("maps/e3m2.bsp");
	precache_file2 ("maps/e3m3.bsp");
	precache_file2 ("maps/e3m4.bsp");
	precache_file2 ("maps/e3m5.bsp");
	precache_file2 ("maps/e3m6.bsp");
	precache_file2 ("maps/e3m7.bsp");

	precache_file2 ("maps/e4m1.bsp");
	precache_file2 ("maps/e4m2.bsp");
	precache_file2 ("maps/e4m3.bsp");
	precache_file2 ("maps/e4m4.bsp");
	precache_file2 ("maps/e4m5.bsp");
	precache_file2 ("maps/e4m6.bsp");
	precache_file2 ("maps/e4m7.bsp");
	precache_file2 ("maps/e4m8.bsp");

	precache_file2 ("maps/end.bsp");

	precache_file2 ("maps/dm1.bsp");
	precache_file2 ("maps/dm2.bsp");
	precache_file2 ("maps/dm3.bsp");
	precache_file2 ("maps/dm4.bsp");
	precache_file2 ("maps/dm5.bsp");
	precache_file2 ("maps/dm6.bsp");

	precache_model ("progs/bolt.mdl");		// for lightning gun
	precache_model ("progs/bolt2.mdl");		// for lightning gun
	precache_model ("progs/bolt3.mdl");		// for boss shock
};

//=======================
/*QUAKED worldspawn (0 0 0) ?
Only used for the world entity.
Should be only one per MAP.

Keys:
"wad"
 which graphics wad to use
"message"
 sets the title of the map
"worldtype"
 normal quake maps:
 0 = medieval
 1 = metal
 2 = base
 Dark Places world types:
 3 = medieval
 4 = metal
 5 = base
 Dark Places maps have special
 properties such as 3x falling
 damage
 (falling 1024 units is like
  270 damage rather than 90)
 you should use one of the
 Dark Places world types if
 making a map for Dark Places

 MUST be set when using keys!
"sounds"
 CD track to play
"light"
 default light level
*/
//=======================
.string music;
void() trigger_message2;
void() trigger_setskill2;
void() trigger_teleport2;
void() worldspawn =
{
	local float c;
	local entity head;

	game = GAME_QUAKE;

	c = 0;
	head = nextent(world);
	while (head != world)
	{
		head = nextent(head);
		c = c + 1;
	}
	maxclients = c;

	lastspawn = world;
	InitDecors ();

// custom map attributes
	if (self.model == "maps/e1m8.bsp")
		cvar_set ("sv_gravity", "100");
	else
		cvar_set ("sv_gravity", "800");


	// precache weapons
	W_Precache ();
	explosionfx_precache();

	// sounds used from C physics code
	precache_sound ("demon/dland2.wav");		// landing thud
	precache_sound ("misc/h2ohit1.wav");		// landing splash

	// player gib sounds
	precache_sound ("player/gib.wav");			// player gib sound
	precache_sound ("player/udeath.wav");		// player gib sound
	precache_sound ("player/tornoff2.wav");		// gib sound

	// player pain sounds
	precache_sound ("player/pain1.wav");
	precache_sound ("player/pain2.wav");
	precache_sound ("player/pain3.wav");
	precache_sound ("player/pain4.wav");
	precache_sound ("player/pain5.wav");
	precache_sound ("player/pain6.wav");

	// player death sounds
	precache_sound ("player/death1.wav");
	precache_sound ("player/death2.wav");
	precache_sound ("player/death3.wav");
	precache_sound ("player/death4.wav");
	precache_sound ("player/death5.wav");

	precache_sound ("player/h2ojump.wav");		// player jumping into water
	precache_sound ("player/slimbrn2.wav");		// player enter slime
	precache_sound ("player/inh2o.wav");		// player enter water
	precache_sound ("player/inlava.wav");		// player enter lava
	precache_sound ("misc/outwater.wav");		// leaving water sound

	precache_sound ("player/lburn1.wav");		// lava burn
	precache_sound ("player/lburn2.wav");		// lava burn

	precache_sound ("misc/water1.wav");			// swimming
	precache_sound ("misc/water2.wav");			// swimming

	precache_sound ("misc/foot1.wav");
	precache_sound ("misc/foot2.wav");
	precache_sound ("misc/foot3.wav");
	precache_sound ("misc/foot4.wav");
	precache_sound ("misc/foot5.wav");
	precache_sound ("misc/foot6.wav");
	precache_sound ("misc/foot7.wav");

	precache_sound ("weapons/r_exp3.wav");          // new rocket explosion

	// setup precaches always needed
	precache_sound ("items/itembk2.wav");		// item respawn sound
	precache_sound ("player/plyrjmp8.wav");		// player jump
	precache_sound ("player/land.wav");			// player landing
	precache_sound ("player/land2.wav");		// player hurt landing
	precache_sound ("player/drown1.wav");		// drowning pain
	precache_sound ("player/drown2.wav");		// drowning pain
	precache_sound ("player/gasp1.wav");		// gasping for air
	precache_sound ("player/gasp2.wav");		// taking breath
	precache_sound ("player/h2odeath.wav");		// drowning death
	precache_sound ("player/udeath.wav");		// gib death

	precache_sound ("misc/talk.wav");			// talk
	precache_sound ("player/teledth1.wav");		// telefrag
	precache_sound ("misc/r_tele1.wav");		// teleport sounds
	precache_sound ("misc/r_tele2.wav");
	precache_sound ("misc/r_tele3.wav");
	precache_sound ("misc/r_tele4.wav");
	precache_sound ("misc/r_tele5.wav");
	precache_sound ("weapons/lock4.wav");		// ammo pick up
	precache_sound ("weapons/pkup.wav");		// weapon up
	precache_sound ("items/armor1.wav");		// armor up
	precache_sound ("items/damage3.wav");

	precache_model ("progs/s_bubble.spr");	// drowning bubbles

	if (game == GAME_NEXUIZ)
	{
		// player precaches
		precache_sound ("misc/bodyimpact1.wav");
		precache_sound ("misc/bodyimpact2.wav");
		precache_sound ("player/hitground1.wav");
		precache_sound ("player/hitground2.wav");
		precache_sound ("player/udeath.wav");		// gib death

		precache_model("models/gibs/bloodyskull.md3");
		precache_model("models/gibs/eye.md3");
		precache_model("models/gibs/gib1.mdl");
		precache_model("models/gibs/gib2.mdl");
		precache_model("models/gibs/gib3.mdl");
		precache_model("models/gibs/gib4.mdl");

		precache_model("models/player/dummy.zym");
		precache_model("models/player/grunt.zym");
		precache_model("models/player/headhunter.zym");
		precache_model("models/player/joandarc.zym");
		precache_model("models/player/marine.zym");
		precache_model("models/player/player.zym");
		precache_model("models/player/pryia.zym");
		precache_model("models/player/shock.zym");
		precache_model("models/player/visitant.zym");
	}
	else
	{
		// player precaches
		precache_sound ("weapons/ax1.wav");			// ax swoosh
		precache_sound ("player/axhit1.wav");		// ax hit meat
		precache_sound ("player/axhit2.wav");		// ax hit world

		//precache_model ("progs/playersg.mdl"); // used for visible weapons
		//precache_model ("progs/playerss.mdl"); // used for visible weapons
		//precache_model ("progs/playernl.mdl"); // used for visible weapons
		//precache_model ("progs/playersn.mdl"); // used for visible weapons
		//precache_model ("progs/playergr.mdl"); // used for visible weapons
		//precache_model ("progs/playerrl.mdl"); // used for visible weapons
		//precache_model ("progs/playerli.mdl"); // used for visible weapons

		precache_model ("progs/playernogun.mdl");
		precache_model ("progs/playergun.mdl");

		precache_model ("progs/player.mdl");
		precache_model ("progs/eyes.mdl");
		precache_model ("progs/h_player.mdl");
		precache_model ("progs/gib1.mdl");
		precache_model ("progs/gib2.mdl");
		precache_model ("progs/gib3.mdl");

		precache_model ("progs/backpack.mdl");

		precache_sound ("weapons/lhit.wav");		//lightning
		precache_sound ("weapons/lstart.wav");		//lightning start

		// spikey ball, used for monster in wall errors.
		precache_model ("progs/star.mdl");
	}

//
// Setup light animation tables. 'a' is total darkness, 'z' is maxbright.
//

	// 0 normal
	lightstyle(0, "m");

	// 1 FLICKER (first variety)
	lightstyle(1, "mmnmmommommnonmmonqnmmo");

	// 2 SLOW STRONG PULSE
	lightstyle(2, "abcdefghijklmnopqrstuvwxyzyxwvutsrqponmlkjihgfedcba");

	// 3 CANDLE (first variety)
	lightstyle(3, "mmmmmaaaaammmmmaaaaaabcdefgabcdefg");

	// 4 FAST STROBE
	lightstyle(4, "mamamamamama");

	// 5 GENTLE PULSE 1
	lightstyle(5,"jklmnopqrstuvwxyzyxwvutsrqponmlkj");

	// 6 FLICKER (second variety)
	lightstyle(6, "nmonqnmomnmomomno");

	// 7 CANDLE (second variety)
	lightstyle(7, "mmmaaaabcdefgmmmmaaaammmaamm");

	// 8 CANDLE (third variety)
	lightstyle(8, "mmmaaammmaaammmabcdefaaaammmmabcdefmmmaaaa");

	// 9 SLOW STROBE (fourth variety)
	lightstyle(9, "aaaaaaaazzzzzzzz");

	// 10 FLUORESCENT FLICKER
	lightstyle(10, "mmamammmmammamamaaamammma");

	// 11 SLOW PULSE NOT FADE TO BLACK
	lightstyle(11, "abcdefghijklmnopqrrqponmlkjihgfedcba");

	// styles 32-62 are assigned by the light program for switchable lights

	// 63 testing
	lightstyle(63, "a");

	darkmode = cvar("darkmode");
	if (darkmode)
	{
		c = 0;
		while (c < 255)
		{
			lightstyle(c, "a");
			c = c + 1;
		}
		lightstyle(255, "m");
	}
	else if (cvar("skill") >= 5)
		lightstyle(0, "mmnmmommommnonmmonqnmmo");

	damagescaleupdate();

	modesetup();

	// spawn skill 4 teleport on the other side of the wooden beam that leads
	// to the nightmare (skill 3) teleport
	if (self.model == "maps/start.bsp")
	{
	// spawn message trigger
		self = spawn ();
		self.wait = 2;
		self.message = "This beam selects UNREASONABLE skill!";
		self.origin = '1390 1551 -146';
		self.mins = '-58 -16 -24';
		self.maxs = '58 16 32';
		self.classname = "trigger_message2";
		trigger_message2 ();
	// spawn teleport
		self = spawn ();
		self.spawnflags = 2;	// SILENT (don't make a humming sound)
		self.target = "t1";
		self.origin = '1520 1551 -146';
		self.mins = '-15 -15 -23';
		self.maxs = '15 15 31';
		self.classname = "trigger_teleport2";
		trigger_teleport2 ();
	// spawn setskill
		self = spawn ();
		self.message = "4";
		self.origin = '1520 1551 -146';
		self.mins = '-16 -16 -24';
		self.maxs = '16 16 32';
		self.classname = "trigger_setskill2";
		trigger_setskill2 ();

		self = world;
	}

	// plays music for the level if there is any
	if (self.music)
	{
		precache_sound (self.music);
		// the Quake engine spatializes ATTN_NONE, so spawn it in two places to get less directional sound
		//ambientsound ('-4095 -4095 -4095', self.noise, 1.00, ATTN_NONE);
		//ambientsound ('4095 4095 4095', self.noise, 1.00, ATTN_NONE);
		// the DarkPlaces engine does not spatialize ATTN_NONE.
		ambientsound ('0 0 0', self.music, 1.00, ATTN_NONE);
	}

	monsterwander = cvar("monsterwander");
	// monsterwander is always on in skill 5
	if (skill >= 5)
		monsterwander = TRUE;

	ItemClass_RegisterDefaultClasses();
};

/*
===========
WaterMove

============
*/

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_Water =
{
	local float r;
	deathstring1 = targ.netname;
	deathstring3 = "";
	deathstring4 = "";
	r = random()*9;
	if (r < 1) deathstring2 = " entered davey jones's locker";
	else if (r < 2) deathstring2 = " joined the fishies";
	else if (r < 3) deathstring2 = " stayed under a bit too long";
	else if (r < 4) deathstring2 = " forgot his diving gear";
	else if (r < 5) deathstring2 = " couldn't swim";
	else if (r < 6) deathstring2 = " wished he had gills";
	else if (r < 7) deathstring2 = " failed to find oxygen";
	else if (r < 8) deathstring2 = " thought he was a fish";
	else            deathstring2 = " forgot the SCUBA gear";
};

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_Slime =
{
	local float r;
	deathstring1 = targ.netname;
	deathstring3 = "";
	deathstring4 = "";
	r = random()*4;
	if (r < 0) deathstring2 = " went for a swim in the slime";
	else if (r < 1) deathstring2 = " forgot his biosuit";
	else if (r < 2) deathstring2 = " got too close to the goo";
	else            deathstring2 = " found the secret sauce";
};

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_Lava =
{
	local float r;
	deathstring1 = targ.netname;
	deathstring3 = "";
	deathstring4 = "";
	if (targ.waterlevel >= 2)
		deathstring2 = " fell off the wrong ledge";
	else
	{
		r = random()*2;
		if (r < 1) deathstring2 = " visited the sauna";
		else       deathstring2 = " thought he could firewalk";
	}
};

void(entity e) WaterMove =
{
	local float wl, wt;
	//dprint (ftos(e.waterlevel));
	wl = e.waterlevel;
	wt = e.watertype;
	if (wt < CONTENT_EMPTY)
	if (e.movetype != MOVETYPE_WALK) // non-walk creatures have depth 1
		wl = 3;

	if (!(e.flags & FL_INWATER))
	{
		// player enter water sound
		if (e.solid) // ignore observers
		{
			if (wt == CONTENT_LAVA)
				sound (e, CHAN_BODY, "player/inlava.wav", 1, ATTN_NORM);
			else if (wt == CONTENT_WATER)
				sound (e, CHAN_BODY, "player/inh2o.wav", 1, ATTN_NORM);
			else if (wt == CONTENT_SLIME)
				sound (e, CHAN_BODY, "player/slimbrn2.wav", 1, ATTN_NORM);
		}

		e.bubble_count = 0;
		e.air_finished = time + 12;
		e.dmgtime = 0;
		e.flags = e.flags | FL_INWATER;
	}

	if (!(e.flags & FL_WATERJUMP) )
		e.velocity = e.velocity - 0.8*wl*frametime*e.velocity;

	if (e.radsuit_finished < time) // no biosuit
	{
		if (e.health >= 1)
		if (e.candrown)
		{
			if (wl != 3)
			{
				if (e.solid) // ignore observers
				{
					if (e.air_finished < time)
						sound (e, CHAN_VOICE, "player/gasp2.wav", 1, ATTN_NORM);
					else if (e.air_finished < time + 9)
						sound (e, CHAN_VOICE, "player/gasp1.wav", 1, ATTN_NORM);
				}
				e.air_finished = time + 12;
				e.dmg = 2;
			}
			else if (e.air_finished < time)
			{
				// drown!
				if (e.drown_finished < time)
				{
					e.dmg = e.dmg + 2;
					if (e.dmg > 15)
						e.dmg = 10;
					if (e.solid) // ignore observers
					{
						if (wt == CONTENT_WATER)
							T_Damage (e, world, world, e.dmg, 1, "WATER", DT_WATERDROWN, e.origin, '0 0 0', Obituary_Water);
						else if (wt == CONTENT_SLIME)
							T_Damage (e, world, world, e.dmg, 1, "SLIME", DT_SLIMEDROWN, e.origin, '0 0 0', Obituary_Slime);
						else if (wt == CONTENT_LAVA)
							T_Damage (e, world, world, e.dmg, 1, "LAVA", DT_LAVADROWN, e.origin, '0 0 0', Obituary_Lava);
					}
					e.drown_finished = time + 1;
				}
			}
		}

		if (wt == CONTENT_LAVA || wt == CONTENT_SLIME)
		if (time >= e.dmgtime)
		{
			if (wt == CONTENT_LAVA)
			{
				e.dmgtime = e.dmgtime + 0.2;
				if (e.dmgtime < time)
					e.dmgtime = time + 0.2;
				//particle(randompos(e.absmin, e.absmax), '0 0 100', 232, 30);
				T_Damage (e, world, world, 10*wl, 10*wl, "LAVA", DT_LAVA, e.origin, '0 0 0', Obituary_Lava);
			}
			else if (wt == CONTENT_SLIME)
			{
				e.dmgtime = e.dmgtime + 0.2;
				if (e.dmgtime < time)
					e.dmgtime = time + 0.2;
				//particle(randompos(e.absmin, e.absmax), '0 0 100', 61, 30);
				T_Damage (e, world, world, 0.4*wl, 0.4*wl, "SLIME", DT_SLIME, e.origin, '0 0 0', Obituary_Slime);
			}
		}
		if (time >= e.dmgtime)
		{
			if (wt == CONTENT_LAVA)
			{
				e.dmgtime = e.dmgtime + 0.2;
				if (e.dmgtime < time)
					e.dmgtime = time + 0.2;
				//particle(randompos(e.absmin, e.absmax), '0 0 100', 232, 30);
				T_Damage (e, world, world, 10*wl, 10*wl, "LAVA", DT_LAVA, e.origin, '0 0 0', Obituary_Lava);
			}
			else if (wt == CONTENT_SLIME)
			{
				e.dmgtime = e.dmgtime + 1;
				if (e.dmgtime < time)
					e.dmgtime = time + 1;
				//particle(randompos(e.absmin, e.absmax), '0 0 100', 61, 30);
				T_Damage (e, world, world, 4*wl, 4*wl, "SLIME", DT_SLIME, e.origin, '0 0 0', Obituary_Slime);
			}
		}
	}
	else
	{
		if (wt == CONTENT_LAVA)
		if (time >= e.dmgtime)
		{
			e.dmgtime = e.dmgtime + 1;
			if (e.dmgtime < time)
				e.dmgtime = time + 1;
			//particle(randompos(e.absmin, e.absmax), '0 0 100', 232, 30);
			T_Damage (e, world, world, 10*wl, 10*wl, "LAVA", DT_LAVA, e.origin, '0 0 0', Obituary_Lava);
		}
	}
};

void() damagescaleupdate =
{
	local float f;

	skill = cvar("skill");

	// monster damage multiplier
	monsterdamagescale = 1;
	// skill 0 =  50% of Quake values
	// skill 1 = 100% of Quake values
	// skill 2 = 150% of Quake values
	// skill 3 = 200% of Quake values
	if (skill >= 5)
		monsterdamagescale = monsterdamagescale * (bound(0, skill - 3, 3) * 0.5 + 0.5);
	else
		monsterdamagescale = monsterdamagescale * (bound(0, skill, 3) * 0.5 + 0.5);
	f = f * cvar("damagescale_monsterdamage");

	// monster health multiplier (implemented by resisting player damage)
	monsterresistancescale = 1 / cvar("damagescale_monsterhealth"); // 1 = 1x health, and so on up

	// damage multiplier
	playerdamagescale = cvar("damagescale_playerdamage");
};

.float findtarget;
entity creaturetocheck;
void() startframe_creaturecode =
{
	local entity oldself;
	local vector b, v;
	local float iterations;
	oldself = self;
	self = creaturetocheck;
	if (self == world)
		self = findfloat(world, iscreature, TRUE);
	// only process up to 200 creatures per frame
	iterations = 0;
	while (self && iterations < 200)
	{
		iterations = iterations + 1;
		if (self.iscreature)
		{
			if (self.takedamage || self.health > 0)
			{
				if (self.findtarget)
				{
					self.findtarget = FALSE;
					FindTarget();
				}
				if (self.watertype >= CONTENT_EMPTY)
				{
					if (self.flags & FL_INWATER)
					{
						// play leave water sound, but only if not an observer
						if (self.solid)
							sound (self, CHAN_BODY, "misc/outwater.wav", 1, ATTN_NORM);
						self.flags = self.flags - FL_INWATER;
					}
				}
				else
				{
					if (self.movetype != MOVETYPE_NOCLIP)
						WaterMove(self);
				}
				if (self.bubble_count)
				if (time > self.bubble_time)
				{
					self.bubble_time = time + 0.1;
					v = randomvec2() * 5;
					makebubble(self.origin + '0 0 18', '0 0 15' + v, 0);
					self.bubble_count = self.bubble_count - 1;
					if (self.bubble_count < 1)
						self.bubble_count = 0;
				}
				if (self.jump_flag < -200)
				if (self.flags & FL_ONGROUND)
				if (self.solid) // ignore observers
				{
					local float d;
					d = 0;
					b = self.origin;
					b_z = self.absmin_z;
					if (self.watertype != CONTENT_WATER)
					{
						if (self.jump_flag < -650 && world.worldtype < 3) // normal quake maps
							d = 5;//d = (-650 - self.jump_flag) * 0.1;
						else if (self.jump_flag < -500 && world.worldtype >= 3) // Dark Places maps
							d = 5;//d = (-500 - self.jump_flag) * 0.3;
					}
					if (d)
						T_Damage (self, world, world, d, d, " met a flat world", DT_FALL, b, '0 0 20', Obituary_Generic);
					if (!self.deadflag && self.classname == "player")
					{
						if (self.watertype == CONTENT_WATER)
							sound (self, CHAN_BODY, "player/h2ojump.wav", 1, ATTN_NORM);
						else if (d)
							sound (self, CHAN_VOICE, "player/land2.wav", 1, ATTN_NORM);
						else
							sound (self, CHAN_VOICE, "player/land.wav", 1, ATTN_NORM);
					}
				}
				self.jump_flag = self.velocity_z;
				if (self.movetype == MOVETYPE_STEP || self.movetype == MOVETYPE_WALK)
				if (pointcontents(self.origin) == CONTENT_SOLID)
					T_Damage(self, world, world, 0, 0, " was in solid", DT_TELEFRAG, self.origin, '0 0 0', Obituary_Generic);
			}
			else
				self.iscreature = FALSE;
		}
		self = findfloat(self, iscreature, TRUE);
	}
	creaturetocheck = self;
	self = oldself;
};

void() superdomination_startframe;
void() superdomination_endframe;

float spawnedwaypoints;
void() StartFrame =
{
	framecount = framecount + 1;

	serverinactive = find(world, classname, "player") == world;
	if (serverinactive)
		return; // don't waste time on idling dedicated servers

	if (!spawnedwaypoints)
	{
		spawnedwaypoints = TRUE;
		// spawn waypoints for the bots to use on this map
		waypoint_spawnformap();
	}

	modeupdate(); // all kinds of stuff (teamplay changing etc)

	teamplay = cvar("teamplay");
	damagescaleupdate();

	CheckRules ();

	havocbot_serverframe();

	startframe_creaturecode();

	superdomination_startframe();
};

void() EndFrame =
{
	if (serverinactive)
		return; // don't waste time on idling dedicated servers

	decorframe(); // removes old decors, etc

	superdomination_endframe();
};

