
void() InitGore =
{
	precache_model("progs/gib1.mdl");
	precache_model("progs/gib2.mdl");
	precache_model("progs/gib3.mdl");
	precache_model("progs/rubble1.mdl");
	precache_model("progs/rubble2.mdl");
	precache_model("progs/rubble3.mdl");
	precache_model("progs/zom_gib.mdl");
	//precache_model("progs/dust.mdl"); // little metal piece
};

// make the gib spin in the air when knocked loose
void() gibknockedloosefunc =
{
	self.flags = self.flags - (self.flags & FL_ONGROUND);
	self.avelocity = randomvec() * 200;
};

void() debristhink =
{
	local   float   p;
	self.flags = self.flags - (self.flags & FL_ONGROUND);
	self.nextthink = time + 0.1;
	/*
	p = pointcontents(self.mins + self.maxs + self.origin);
	if (p == CONTENT_SOLID || p == CONTENT_SKY || p == CONTENT_LAVA)
	{
		if (self.classname == "decor")
			remove(self);
		else
			self.model = "";
		return;
	}
	*/
	if (time > self.cnt)
	{
		self.nextthink = time;
		self.alpha = self.alpha - frametime * 0.5;
		if (self.alpha < 0.0625)
		{
			self.nextthink = 0;
			if (self.classname == "decor")
				remove(self);
			else
				self.model = "";
		}
	}
};

.float isdecor;
void(entity e, vector org, vector vel, string gibname, float s) ThrowDebris =
{
	if (e == world)
		e = newdecor();
	e.isdecor = TRUE; // let explosions find it
	e.forcescale = 3;
	e.createdtime = time;
	setorigin(e, org);
	setmodel (e, gibname);
	setsize (e, '0 0 -8', '0 0 -8');
	e.view_ofs = '0 0 -1';
	e.velocity = vel + randomvec() * 150;
	e.movetype = MOVETYPE_BOUNCE;
	e.havocattack = FALSE;
	e.solid = SOLID_NOT;
	e.avelocity = randomvec()*300;
	e.knockedloosefunc = gibknockedloosefunc;
	e.frame = 0;
	e.skin = s; // style of rubble (see func_xplowall for info)
	e.effects = EF_LOWPRECISION;
	e.alpha = 1;
	e.think = debristhink;
	e.nextthink = time;
	e.takedamage = DAMAGE_YES;
	e.th_die = SUB_Null;
	e.th_gib = SUB_Null;
	e.th_pain = SUB_Null;
	if (maxclients == 1)
		e.cnt = time + 3000;
	else
		e.cnt = time + 30; // + random() * 50;
};

void(string gibname) ThrowGib =
{
	local   vector  org;
	org = randompos(self.absmin, self.absmax);
	ThrowDebris(world, org, '0 0 0', gibname, 0);
};

void(string gibname) ThrowHead =
{
	ThrowDebris(self, self.origin + self.view_ofs, '0 0 0', gibname, 0);
};

/*
void(vector org, vector vel) SpawnDust =
{
	local   entity  e;
	if (cvar("temp1") & 2048)
		return;
	e = newdecor();
	e.forcescale = 3;
	e.createdtime = time;
	e.movetype = MOVETYPE_BOUNCE;
	e.solid = SOLID_NOT;
	e.velocity = vel;
	e.effects = EF_LOWPRECISION;
	setmodel (e, "progs/dust.mdl");
	setsize (e, '0 0 -1', '0 0 -1');
	setorigin (e, org);
};
*/

/*
void() MeatSprayThink =
{
	self.nextthink = time;
	self.flags = self.flags - (self.flags & FL_ONGROUND);
	if (pointcontents(self.origin) != CONTENT_EMPTY)
	{
		remove(self);
		return;
	}

	traceline(self.origin, self.origin + self.velocity * frametime, TRUE, world);
	if (trace_fraction >= 1)
	{
		traceline(self.origin + '0 0 1', self.origin + '0 0 -20', FALSE, self);
		if (trace_startsolid)
			traceline(self.origin + '0 0 1', self.origin + '0 0 -20', TRUE, self);
	}
	if (trace_fraction < 1 && trace_ent.solid == SOLID_BSP)
	{
//		newbloodsplat(trace_endpos, trace_ent, trace_plane_normal, 0, 0.5);
		remove(self);
		return;
	}
};

void(vector org, vector vel) SpawnMeatSpray =
{
	if (cvar("temp1") & 2048)
		return;
	if (pointcontents(org) != CONTENT_EMPTY)
		return;

	newmis = newdecor();
	newmis.forcescale = 3;
	newmis.createdtime = time + 0.5;
	newmis.movetype = MOVETYPE_BOUNCE;
	newmis.solid = SOLID_NOT;
	newmis.velocity = vel;
	newmis.nextthink = time;
	newmis.think = MeatSprayThink;
	setmodel (newmis, "progs/zom_gib.mdl");
	setsize (newmis, '0 0 -1', '0 0 -1');
	setorigin (newmis, org);
	newmis.effects = EF_LOWPRECISION;
};
*/

/*
==============================================================================

CORPSES

==============================================================================
*/

void() corpsedie =
{
	self.takedamage = DAMAGE_NO;
	self.touch = SUB_Null;
	self.th_die = SUB_Null;
	self.solid = SOLID_NOT;
	setsize (self, self.mins, self.maxs); // relink
	//self.think = self.th_gib;
	//self.nextthink = time; // as soon as possible
	self.th_gib();
};

void(vector bmins, vector bmaxs) body_solid =
{
	if (self.solid == SOLID_SLIDEBOX)
	if (bmins == self.mins)
	if (bmaxs == self.maxs)
		return;
	self.solid = SOLID_SLIDEBOX;
	setsize (self, bmins, bmaxs); // relink
};

void(vector bmins, vector bmaxs) body_nonsolid =
{
	if (self.solid == SOLID_CORPSE)
	if (bmins == self.mins)
	if (bmaxs == self.maxs)
		return;
	self.solid = SOLID_CORPSE;
	setsize (self, bmins, bmaxs); // relink
};

void() bodyfirstthink =
{
	self.movetype = MOVETYPE_TOSS;
	setorigin(self, self.oldorigin); // relink
	self.flags = 0; // clear FL_ONGROUND etc
	if (self.bodyhealth < 1)
		self.th_die();
	else
	{
		self.think = self.think1;
		self.think();
	}
};

.float iscreature;
.float bubble_count;

/*
//.float flamecount, flametime, flamesoundtime;
//.entity flameowner;
// call this the moment the monster/player/bot etc dies,
// it will do the anim you give it if not a gib, or immediately gib.
// you should use BecomeCorpse2() for monsters, so the edicts are freed.
// (unlike normal quake, where corpses/heads hang around *FOREVER*)
*/
void(entity c, void() framefunc) BecomeCorpse =
{
	local entity saveself;
	saveself = self;
	self = c;
	self.havocattack = FALSE;
	self.touch = SUB_Null;
	self.th_pain = SUB_Null;
	self.th_walk = SUB_Null;
	self.th_melee = SUB_Null;
	self.th_missile = SUB_Null;
	self.th_run = SUB_Null;
	self.th_stand = SUB_Null;
	self.iscorpse = TRUE;
	self.cantrigger = FALSE;
	self.th_die = corpsedie;
	self.takedamage = DAMAGE_YES;
	self.movetype = MOVETYPE_NONE;
	self.angles_x = self.angles_z = 0; // make sure it's not tilted
	self.avelocity = '0 0 0'; // make sure it won't spin
	self.think1 = framefunc; // first frame of death animation
	self.think = bodyfirstthink;
	self.nextthink = time;
	self.flags = 0;
	self.oldorigin = self.origin + '0 0 1';

	if (self.bodyhealth < 1)
		self.th_die();
	self = saveself;
};

void(entity t) CopyToBodyQue =
{
	local entity e, c;
	c = newdecor();
	c.createdtime = time + 10; // give priority over bullet holes and such
	c.iscorpse = TRUE;

	c.angles = t.angles;
	c.model = t.model;
	c.modelindex = t.modelindex;
	c.frame = t.frame;
	c.skin = t.skin;
	c.colormap = t.colormap;
	c.movetype = t.movetype;
	c.velocity = t.velocity;
	c.solid = t.solid;
	c.avelocity = t.avelocity;
	c.forcescale = t.forcescale;
	c.deathmsg = t.deathmsg;
	c.bleedfunc = t.bleedfunc;
	c.bubble_count = t.bubble_count;
	c.think1 = t.think1;
	c.think = t.think;
	c.nextthink = t.nextthink;
	c.iscreature = t.iscreature;
	c.bodyhealth = t.bodyhealth;
	c.health = t.health;
	c.armortype = t.armortype;
	c.armorvalue = t.armorvalue;
	c.th_die = t.th_die;
	c.th_gib = t.th_gib;
	c.takedamage = t.takedamage;

	c.flags = 0;
	setorigin (c, t.origin);
	setsize (c, t.mins, t.maxs);
	c.flags = 0; // clear FL_ONGROUND etc
};

// used specifically by monsters, choose any of the above methods
// here to affect all monsters.
void(entity t, void() framefunc) MonsterCorpse =
{
	t.classname = "decor"; // setup for recycling
	t.createdtime = time + 30; // make sure it won't be replaced anytime soon
	BecomeCorpse(t, framefunc);
};

void(string headname, float gibs, string gibname1, float gibs1, string gibname2, float gibs2) MonsterGibs =
{
	// gibs is generic gibs, headname is the head,
	// gibs1/gibname1 and gibs2/gibname2 are specialty debris
	local float r;
	// make self non-solid while spawning gibs
	self.solid = SOLID_NOT;
	setorigin(self, self.origin);
	// prevent gibs from replacing their corpse if their corpse is a decor
	self.createdtime = time + 1;
	// spawn gibs
	while (gibs > 0) {gibs = gibs - 1;r = random() * 3;if (r < 1) ThrowGib("progs/gib1.mdl");else if (r < 2) ThrowGib("progs/gib2.mdl");else ThrowGib("progs/gib3.mdl");}
	while (gibs1 > 0) {gibs1 = gibs1 - 1;ThrowGib(gibname1);}
	while (gibs2 > 0) {gibs2 = gibs2 - 1;ThrowGib(gibname2);}
	// now become a head
	if (headname) ThrowHead(headname);
//	if (time >= 0.5) // no blood effects until game really begins
//		bloodshower(self.origin + self.mins, self.origin + self.maxs, 100, 50);
};

void(string headname, float gibs, string gibname1, float gibs1, string gibname2, float gibs2) PlayerGibs =
{
	MonsterGibs(headname, gibs, gibname1, gibs1, gibname2, gibs2);
};

//.float bleeddamagecount;
void(vector org, float bodydamage, float armordamage, vector force, float damgtype) genericbleedfunc =
{
	local   vector  v;
	v = '0 0 0' - force * 0.05;
	if (armordamage > 0)
		spark(org, v, armordamage * 3);
	if (bodydamage > 0)
		blood(org, v, bodydamage);

	if (cvar("temp1") & 2048)
		return;

	/*
	if (bodydamage > 0)
	{
//		self.bleedcount = self.bleedcount + bodydamage;
		self.bleeddamagecount = self.bleeddamagecount + bodydamage;
		if (self.bleeddamagecount > 150)
			self.bleeddamagecount = 150;
		while (self.bleeddamagecount >= 10)
		{
			self.bleeddamagecount = self.bleeddamagecount - 10;
			v = randomvec() * 150 + force;
			SpawnMeatSpray(org, v);
		}
	}
	*/
};

void() deadbodygib =
{
	self.solid = SOLID_NOT;
	sound (self, CHAN_VOICE, "player/udeath.wav", 1, ATTN_NORM);
	MonsterGibs(self.deathtype, self.count, "", 0, "", 0);
};

// creates a generic dead body, used by dead_ monsters
void(string modelname, string headname, void() animfuncname, float gibcount, float forcescalevalue, float bhealth) deadmonstersetup =
{
	precache_model (modelname);
	precache_model (headname);
	self.deathtype = headname;
	self.count = gibcount;
	self.forcescale = forcescalevalue;
	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_TOSS;
	self.takedamage = DAMAGE_YES;
	self.iscreature = TRUE;
	self.bleedfunc = genericbleedfunc;
	self.health = -1;
	self.bodyhealth = bhealth;
	self.th_gib = deadbodygib;

	setmodel (self, modelname);
	setorigin(self, self.origin);

	BecomeCorpse(self, animfuncname);
};

void() dead_gibs_doit =
{
	MonsterGibs(self.mdl, self.count, "", 0, "", 0);
};

/*QUAKED dead_gibs (1 0 0) (-16 -16 -16) (16 16 16)
Splatters the area with gibs and creates a large pool

keys:
"targetname"
 explodes in gibs when triggered
 (does so only once)
"count"
 number of gibs (default: 6)
"mdl"
 head model (normally no head is thrown)
*/
void() dead_gibs =
{
	if (self.mdl)
		precache_model(self.mdl);
	if (self.count == 0)
		self.count = 6;
	setorigin(self, self.origin);
	setsize(self, '-16 -16 -16', '16 16 16');
	if (self.targetname)
	{
		self.use = dead_gibs_doit;
		return;
	}
	dead_gibs_doit();
};

void() dead_bloodarea_doit =
{
	local   vector  v;
	bloodshower(self.origin - '16 16 16', self.origin + '16 16 16', 200, self.count * 10);
	/*
	while (self.count > 0)
	{
		self.count = self.count - 1;
		v = randomvec() * 150 + '0 0 160';
		SpawnMeatSpray(self.origin, v);
	}
	*/
	remove(self);
};

/*QUAKED dead_bloodarea (1 0 0) (-16 -16 -16) (16 16 16)
Splatters the area with blood

keys:
"targetname"
 explodes in blood when triggered
"count"
 number of splatters (default: 6)
*/
void() dead_bloodarea =
{
	if (self.count == 0)
		self.count = 6;
	if (self.targetname)
	{
		self.use = dead_bloodarea_doit;
		return;
	}
	dead_bloodarea_doit();
};
