
float teamsinuse;
float mode_shirtmustmatchpants;

entity team0, team1, team2, team3, team4, team5, team6, team7, team8, team9, team10, team11, team12, team13, team14, team15;

entity() weakestteam;

.float c_pants;
.float c_shirt;
void(entity e, float p, float s) setplayercolor;

string(float c) colorname =
{
	// yikes, the quake color set is HARD to describe
	// many are easy, but, uh, 2 browns???
	// 2 purples???
	// that 'pink' is hard to classify
	// I think 'biege' is a fairly good name for color 10
	// oh well, gotta do all the color names...
	     if (c ==  0) return "white";
	else if (c ==  1) return "brown";
	else if (c ==  2) return "lightblue";
	else if (c ==  3) return "green";
	else if (c ==  4) return "red";
	else if (c ==  5) return "lighterbrown";
	else if (c ==  6) return "orange";
	else if (c ==  7) return "pink";
	else if (c ==  8) return "purple";
	else if (c ==  9) return "redishpurple";
	else if (c == 10) return "biege";
	else if (c == 11) return "aqua";
	else if (c == 12) return "yellow";
	else if (c == 13) return "blue";
	else if (c == 14) return "flamingorange";
	else if (c == 15) return "psychadelic";
	else              return "INVALID COLOR";
};

entity(float c) spawnteam =
{
	newmis = spawn();
	newmis.classname = "teamentity";
	newmis.team = c + 1;
	newmis.frags = 0;
	newmis.count = 0; // how many players on this team
	newmis.netname = colorname(c);
	return newmis;
};

void() spawnteams =
{
	team0 = world;
	team1 = world;
	team2 = world;
	team3 = world;
	team4 = world;
	team5 = world;
	team6 = world;
	team7 = world;
	team8 = world;
	team9 = world;
	team10 = world;
	team11 = world;
	team12 = world;
	team13 = world;
	team14 = world;
	team15 = world;
	if (deathmatch == DM_CTF_3TEAM)
	{
		team4  = spawnteam( 4);
		team12 = spawnteam(12);
		team13 = spawnteam(13);
	}
	else if (deathmatch >= DM_TEAM_MODS_START && deathmatch < DM_TEAM_MODS_END)
	{
		team4  = spawnteam( 4);
		team13 = spawnteam(13);
	}
	else
	{
		team0  = spawnteam( 0);
		team1  = spawnteam( 1);
		team2  = spawnteam( 2);
		team3  = spawnteam( 3);
		team4  = spawnteam( 4);
		team5  = spawnteam( 5);
		team6  = spawnteam( 6);
		team7  = spawnteam( 7);
		team8  = spawnteam( 8);
		team9  = spawnteam( 9);
		team10 = spawnteam(10);
		team11 = spawnteam(11);
		team12 = spawnteam(12);
		team13 = spawnteam(13);
		team14 = spawnteam(14);
		team15 = spawnteam(15);
	}
};

entity(float color) teamentityforcolor =
{
	if (color ==  0) return team0;
	if (color ==  1) return team1;
	if (color ==  2) return team2;
	if (color ==  3) return team3;
	if (color ==  4) return team4;
	if (color ==  5) return team5;
	if (color ==  6) return team6;
	if (color ==  7) return team7;
	if (color ==  8) return team8;
	if (color ==  9) return team9;
	if (color == 10) return team10;
	if (color == 11) return team11;
	if (color == 12) return team12;
	if (color == 13) return team13;
	if (color == 14) return team14;
	if (color == 15) return team15;
	return world;
};

void() checkinvalidteam =
{
	local entity e;
	if (teamentityforcolor(self.team - 1) == world)
	{
		// team not allowed, reassign team
		e = weakestteam();
		setplayercolor(self, e.team - 1, e.team - 1);
	}
};

void() resetteams =
{
	local entity head;
	head = findchain(classname, "teamentity");
	while(head)
	{
		head.frags = 0;
		head.dmg = 0;
		head = head.chain;
	}
};

float(float t) countteammembers =
{
	local   entity  head;
	local   float   c;
	c = 0;
	head = findchain(classname, "player");
	while (head != world)
	{
		if (head.team == t)
			c = c + 1;
		head = head.chain;
	}
	return  c;
};

entity() weakestteam =
{
	local entity head, best;
	local float bestcount;
	best = world;
	bestcount = 1000000000;
	head = findchain(classname, "teamentity");
	while (head)
	{
		/*
		bprint("teamentity: color ");
		bprintfloat(head.team - 1);
		bprint(", players ");
		bprintfloat(head.count);
		bprint("\n");
		*/
		if (bestcount > head.count)
		{
			best = head;
			bestcount = head.count;
		}
		head = head.chain;
	}
	return best;
};

float(float p) checkteamcolor =
{
	local entity t;
	t = teamentityforcolor(p);
	if (t == world)
		t = weakestteam();
	return t.team - 1;
};

void(entity e, float pants, float shirt) setplayercolor =
{
	//local string s;
	local float old;
	e.c_pants = pants;
	e.c_shirt = shirt;
	old = e.colormap;
	e.colormap = e.c_pants + e.c_shirt * 16 + 1024;
	e.team = pants + 1;
	if (e.flags & FL_CLIENT)
		setcolor(e, e.colormap - 1024);
};

void(float color) SV_ChangeTeam =
{
	local float pants, shirt, old;
	if (color >= 0)
	{
		pants = color & 15;
		shirt = (color / 16) & 15;
	}
	else
	{
		pants = -1;
		shirt = -1;
	}
	/*
	bprint("SV_ChangeTeam(");
	bprintfloat(pants);
	bprint(", ");
	bprintfloat(shirt);
	bprint(")\n");
	*/
	pants = checkteamcolor(pants);
	if (mode_shirtmustmatchpants || shirt < 0)
		shirt = pants;
	old = self.c_pants;
	setplayercolor(self, pants, shirt);
	if (pants != old && old >= 0 && teamplay && deathmatch)
	{
		//T_Damage(self, self, self, 0, 0, " changed teams", DT_TELEFRAG, self.origin, '0 0 0', Obituary_Generic);
		PutClientInServer ();
		self.frags = 0;
	}
};


string dmmessage;

void(string m) setdm =
{
	dmmessage = m;
	cvar_set("deathmatch", m);
}

void() mode_updatecvars =
{
	     if (cvar("deathmatch") ==  0) setdm("0?Dark Places - Coop");
	else if (cvar("deathmatch") ==  1) setdm("1?Dark Places - Deathmatch");
	else if (cvar("deathmatch") ==  2) setdm("2?Dark Places - Deathmatch 2 (can only pickup gun once)");
	else if (cvar("deathmatch") ==  3) setdm("3?Dark Places - Deathmatch 3 (quick ammo respawn)");
	else if (cvar("deathmatch") ==  5) setdm("5?Dark Places - Frag Fest (spawn with full pack)");
//	else if (cvar("deathmatch") ==  6) setdm("6?Dark Places - Random Weapons (spawn with 2 random weapons)"); // removed
	else if (cvar("deathmatch") ==  7) setdm("7?Dark Places - Monsters");
//	else if (cvar("deathmatch") ==  8) setdm("8?Dark Places - Elimination");
//	else if (cvar("deathmatch") ==  9) setdm("9?Dark Places - Kill The Leader Mode");
	else if (cvar("deathmatch") == 10) setdm("10?Dark Places - Capture The Flag - 2 Team");
	else if (cvar("deathmatch") == 11) setdm("11?Dark Places - Capture The Flag - 3 Team");
	else if (cvar("deathmatch") == 12) setdm("12?Dark Places - Domination");
	else if (cvar("deathmatch") == 30) setdm("30?Dark Places - Role Playing Game");
	else                               setdm("1?Dark Places - Deathmatch");

	/*if (deathmatch == 8) cvar_set("teamplay", "3?Dark Places - Elimination");
	else if (deathmatch == 9) cvar_set("teamplay", "3?Dark Places - Kill The Leader");
	else*/ if (deathmatch == 10) cvar_set("teamplay", "3?Dark Places - Capture The Flag - 2 Team");
	else if (deathmatch == 11) cvar_set("teamplay", "3?Dark Places - Capture The Flag - 3 Team");
	else if (deathmatch == 12) cvar_set("teamplay", "3?Dark Places - Domination");
	else
	{
		     if (cvar("teamplay") == 0) cvar_set("teamplay", "0?Dark Places - No Teamplay");
		else if (cvar("teamplay") == 1) cvar_set("teamplay", "1?Dark Places - No team damage");
		else if (cvar("teamplay") == 2) cvar_set("teamplay", "2?Dark Places - Can hurt anyone");
		else if (cvar("teamplay") == 3) cvar_set("teamplay", "3?Dark Places - No team damage, but can hurt self");
		else                            cvar_set("teamplay", "0?Dark Places - No Teamplay");
	}
};

float nextcvarupdate;
void() deathmatch7update;
void() modeupdate =
{
	if (time > nextcvarupdate)
	{
		nextcvarupdate = time + 1;
		mode_updatecvars();
	}
	if (deathmatch == 7)
		deathmatch7update();
};

// true if items should respawn
float itemrespawn;
// when the next monster spawning check will occur in deathmatch 7 mode
float spawnchecktime;

void() precachemonsters;
void() modesetup =
{
	mode_shirtmustmatchpants = deathmatch >= DM_TEAM_MODS_START && deathmatch < DM_TEAM_MODS_END;
	spawnteams();

	itemrespawn = deathmatch || cvar("coop");

	// don't spawn any monsters until 15 seconds
	spawnchecktime = 15;
	if (deathmatch == 7)
		precachemonsters();
};

float monsterspawn;
void() spawnmonster_think =
{
	//local float c;
	local void() sfunc;
	self.nextthink = time;
	if (time > self.cnt)
	{
		remove(self);
		return;
	}
	if (vlen(self.velocity) > 5)
		return; // try again later

	//if (!(self.flags & FL_FLY))
	//	droptofloor();
	// don't spawn if something is in the way
	/*
	// walk around a lot
	if (walkmove(0,0))
	{
		if (self.lefty > 0)
		{
			c = 100;
			self.lefty = self.lefty - 1;
			self.angles = '0 0 0';
			while(c > 0)
			{
				c = c - 1;
				if (!walkmove(self.angles_y, 16))
					self.angles_y = random() * 360;
			}
			self.angles = '0 0 0';
			return;
		}
	}
	*/
	// don't spawn if something is in the way
	if (!walkmove(0,0))
	{
		self.lefty = 10;
		setorigin(self, self.dest);
		self.flags = self.flags - (self.flags & FL_ONGROUND);
		self.velocity = randomvec() * 700 + '0 0 1000';
		return;
	}
	newmis = findchain(classname, "player");
	while (newmis)
	{
		if (vlen(newmis.origin - self.origin) < 300)
			return;
		newmis = newmis.chain;
	}

	// spawn in
	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_NOT;
	self.velocity = '0 0 0';
	self.flags = 0;
	self.model = "";
	self.modelindex = 0;
	setorigin(self, self.origin);
	self.angles = '0 360 0' * random();
	self.classname = self.netname;
	self.netname = "";
	self.cnt = 0;
	self.think = SUB_Remove;
	sfunc = self.th_run;
	self.th_run = SUB_Null;
	te_teleport(self.origin);
	monsterspawn = TRUE;
	sfunc();
	monsterspawn = FALSE;
};

void(float c1, float c2, string cname, void() spawnfunc, vector m1, vector m2) spawnmonster =
{
	local float c;
	local entity head;
	c = random() * 50 + 1;
	head = world;
	while (c > 0)
	{
		c = c - 1;
		head = find(head, classname, "info_player_deathmatch");
		if (head == world)
			head = find(head, classname, "info_player_deathmatch");
	}
	c = (c2 - c1) * random() + c1;
	c = rint(c);
	while (c > 0)
	{
		c = c - 1;

		newmis = spawn();
		newmis.cnt = time + 10;
		newmis.lefty = 10;
		newmis.dest = head.origin;
		newmis.classname = "spawningmonster";
		newmis.netname = cname;
		newmis.solid = SOLID_TRIGGER;
		if (cname == "monster_wizard")
		{
			newmis.flags = FL_FLY;
			newmis.movetype = MOVETYPE_FLY;
		}
		else
		{
			newmis.flags = 0;
			newmis.movetype = MOVETYPE_TOSS;
		}
		newmis.velocity = randomvec() * 700 + '0 0 1000';
		newmis.th_run = spawnfunc;
		newmis.think = spawnmonster_think;
		newmis.nextthink = time + random() * 0.5 + 0.3;
		setorigin(newmis, head.origin);
		setmodel(newmis, "progs/s_explod.spr");
		setsize(newmis, m1, m2);
	}
};

void() monster_army;
void() monster_demon1;
void() monster_dog;
void() monster_enforcer;
void() monster_hell_knight;
void() monster_knight;
void() monster_ogre;
void() monster_shalrath;
void() monster_shambler;
void() monster_tarbaby;
void() monster_wizard;
void() monster_zombie;

void() spawnmonsters =
{
	local float r;
	if (find(world, classname, "info_player_deathmatch") == world)
		return;

	r = random() * 12;
	     if (r <  1) spawnmonster( 5, 10, "monster_army"       , monster_army       , '-16 -16 -24', '16 16 32');
	else if (r <  2) spawnmonster( 3,  6, "monster_demon1"     , monster_demon1     , '-32 -32 -24', '32 32 64');
	else if (r <  3) spawnmonster( 6, 12, "monster_dog"        , monster_dog        , '-16 -16 -24', '16 16 32');
	else if (r <  4) spawnmonster( 4,  8, "monster_enforcer"   , monster_enforcer   , '-16 -16 -24', '16 16 32');
	else if (r <  5) spawnmonster( 4,  8, "monster_hell_knight", monster_hell_knight, '-16 -16 -24', '16 16 32');
	else if (r <  6) spawnmonster( 6, 12, "monster_knight"     , monster_knight     , '-16 -16 -24', '16 16 32');
	else if (r <  7) spawnmonster( 3,  6, "monster_ogre"       , monster_ogre       , '-32 -32 -24', '32 32 64');
	else if (r <  8) spawnmonster( 1,  3, "monster_shalrath"   , monster_shalrath   , '-32 -32 -24', '32 32 64');
	else if (r <  9) spawnmonster( 1,  1, "monster_shambler"   , monster_shambler   , '-32 -32 -24', '32 32 64');
	else if (r < 10) spawnmonster(10, 15, "monster_tarbaby"    , monster_tarbaby    , '-16 -16 -24', '16 16 32');
	else if (r < 11) spawnmonster( 6, 10, "monster_wizard"     , monster_wizard     , '-16 -16 -24', '16 16 32');
	else if (r < 12) spawnmonster( 4,  8, "monster_zombie"     , monster_zombie     , '-16 -16 -24', '16 16 32');
};

void() precachemonster_army;
void() precachemonster_demon1;
void() precachemonster_dog;
void() precachemonster_enforcer;
void() precachemonster_hell_knight;
void() precachemonster_knight;
void() precachemonster_ogre;
void() precachemonster_shalrath;
void() precachemonster_shambler;
void() precachemonster_tarbaby;
void() precachemonster_wizard;
void() precachemonster_zombie;

void() precachemonsters =
{
	precachemonster_army();
	precachemonster_demon1();
	precachemonster_dog();
	precachemonster_enforcer();
	precachemonster_hell_knight();
	precachemonster_knight();
	precachemonster_ogre();
	precachemonster_shalrath();
	precachemonster_shambler();
	precachemonster_tarbaby();
	precachemonster_wizard();
	precachemonster_zombie();
};

void() deathmatch7update =
{
	local entity e;
	local float f, monster_count;
	if (time > spawnchecktime)
	{
		spawnchecktime = time + 0.2;
		monster_count = 0;
		e = findchainfloat(iscreature, TRUE);
		while (e)
		{
			if (e.flags & FL_MONSTER)
				monster_count = monster_count + 1;
			e = e.chain;
		}
		f = cvar("scratch1");
		if (f < 1)
			f = 50;
		if (monster_count < f)
		{
			e = findchain(classname, "spawningmonster");
			while (e)
			{
				monster_count = monster_count + 1;
				e = e.chain;
			}
			if (monster_count < f)
				spawnmonsters();
		}
	}
}
