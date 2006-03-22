
void() InitGore =
{
	if (game == GAME_NEXUIZ)
	{
		precache_model("models/gibs/bloodyskull.md3");
		precache_model("models/gibs/eye.md3");
		precache_model("models/gibs/gib1.mdl");
		precache_model("models/gibs/gib2.mdl");
		precache_model("models/gibs/gib3.mdl");
		precache_model("models/gibs/gib4.mdl");
	}
	else
	{
		precache_model("progs/gib1.mdl");
		precache_model("progs/gib2.mdl");
		precache_model("progs/gib3.mdl");
		precache_model("progs/rubble1.mdl");
		precache_model("progs/rubble2.mdl");
		precache_model("progs/rubble3.mdl");
		precache_model("progs/zom_gib.mdl");
		//precache_model("progs/dust.mdl"); // little metal piece
	}
};

// make the gib spin in the air when knocked loose
void() gibknockedloosefunc =
{
	self.flags = self.flags - (self.flags & FL_ONGROUND);
	self.avelocity = randomvec() * 200;
};

void() debristouch =
{
	if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
	{
		remove(self);
		return;
	}
};

void() debristhink =
{
	//local   float   p;
	self.flags = self.flags - (self.flags & FL_ONGROUND);
	self.nextthink = time + 0.1;
	/*
	p = pointcontents(self.mins + self.maxs + self.origin);
	if (p == CONTENT_SOLID || p == CONTENT_SKY || p == CONTENT_LAVA)
	{
		if (self.classname == "decor")
			removedecor(self);
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
				removedecor(self);
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
	e.forcescale = 6;
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
	e.touch = debristouch;
	e.th_die = SUB_Null;
	e.th_gib = SUB_Null;
	e.th_pain = SUB_Null;
	if (maxclients == 1)
		e.cnt = time + 3000;
	else
		e.cnt = time + 30; // + random() * 50;
};

entity(vector org, vector vel, string modelname) Ragdoll_ThrowGib;

void(string gibname) ThrowGib =
{
	local   vector  org;
	// don't throw a gib if in a NODROP zone (such as lava)
	traceline(self.origin, self.origin, MOVE_NORMAL, self);
	if (trace_dpstartcontents & DPCONTENTS_NODROP)
		return;
	org = randompos(self.absmin, self.absmax);
	if (cvar("dpmod_qcphysics_gibs"))
		Ragdoll_ThrowGib(org, '0 0 0', gibname);
	else
		ThrowDebris(world, org, '0 0 0', gibname, 0);
};

void(string gibname) ThrowHead =
{
	if (cvar("dpmod_qcphysics_gibs"))
	{
		Ragdoll_ThrowGib(self.origin + self.view_ofs, '0 0 0', gibname);
		self.model = "";
	}
	else
	{
		// don't use a visible head gib in a NODROP zone (such as lava)
		traceline(self.origin, self.origin, MOVE_NORMAL, self);
		if (trace_dpstartcontents & DPCONTENTS_NODROP)
		{
			self.model = "";
			return;
		}

		ThrowDebris(self, self.origin + self.view_ofs, '0 0 0', gibname, 0);
	}
};

/*
void(vector org, vector vel) SpawnDust =
{
	local   entity  e;
	if (cvar("temp1") & 2048)
		return;
	e = newdecor();
	e.forcescale = 6;
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
	newmis.forcescale = 6;
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
	local float wasfrozen;
	wasfrozen = self.frozen;
	restorefrozenentity(self);
	self.movetype = MOVETYPE_TOSS;
	setorigin(self, self.oldorigin); // relink
	self.flags = 0; // clear FL_ONGROUND etc
	if (self.bodyhealth < 1)
		self.th_die();
	else
	{
		self.think = self.think1;
		if (self.think)
			self.think();
		if (wasfrozen)
			refreezefrozenentity(self);
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
	local entity c;
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
	c.frozen = t.frozen;

	c.flags = 0;
	setorigin (c, t.origin);
	setsize (c, t.mins, t.maxs);
	c.flags = 0; // clear FL_ONGROUND etc
};

// used specifically by monsters, choose any of the above methods
// here to affect all monsters except zombies.
void(entity t, void() framefunc) MonsterCorpse =
{
	// setup for recycling
	t.classname = "decor";
	numdecors++;
	// make sure it won't be replaced anytime soon
	t.createdtime = time + 30;
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
	if (game == GAME_NEXUIZ)
	{
		while (gibs > 0) {gibs = gibs - 1;r = random() * 4;if (r < 1) ThrowGib("models/gibs/gib1.mdl");else if (r < 2) ThrowGib("models/gibs/gib2.mdl");else if (r < 3) ThrowGib("models/gibs/gib3.mdl");else ThrowGib("models/gibs/gib4.mdl");}
	}
	else
	{
		while (gibs > 0) {gibs = gibs - 1;r = random() * 3;if (r < 1) ThrowGib("progs/gib1.mdl");else if (r < 2) ThrowGib("progs/gib2.mdl");else ThrowGib("progs/gib3.mdl");}
	}
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
	//local   vector  v;
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

/*
.float ragdoll_bounce;
.float ragdoll_friction;
.entity ragdoll_particlelist;
.entity ragdoll_sticklist;
.entity ragdoll_next;
.vector neworg;
.float newtime, currenttime, oldtime;
void() RagDollThink =
{
	local float bump, ftime;
	local vector offset, neworg;
	local entity part, stick;
	self.ragdoll_bounce = 1.2; // slight bounce
	self.ragdoll_friction = 0.05; // slight friction
	// maintain 64fps regardless of frametime for robustness
	while (self.ltime < time)
	{
		self.ltime = self.ltime + (1.0 / 64.0); // 64fps
		// allow up to 4 collisions per move step
		// each move tries to reach self.ltime but may be cut short by a
		// collision event, in which case the next move attempt will usually
		// move it further (in another direction)
		bump = 0;
		while (bump < 4)
		{
			bump = bump + 1;
			part = self.ragdoll_particlelist;
			while (part)
			{
				ftime = self.ltime - part.newtime;
				neworg = part.neworg + (part.neworg - part.origin) * (ftime / (part.newtime - part.currenttime)) + '0 0 -1' * sv_gravity * (ftime * ftime);
				setorigin(part, part.neworg);
				part.currenttime = part.newtime;
				part.neworg = neworg;
				part.newtime = self.ltime;
				part = part.ragdoll_next;
			}
			stick = self.ragdoll_sticklist;
			while (stick)
			{
				offset = (stick.p2.neworg - stick.p1.neworg);
				offset = offset * (stick.ragdoll_preferredlength / vlen(offset));
				stick.p1.neworg = stick.p1.neworg + offset;
				stick.p2.neworg = stick.p2.neworg + offset;
				stick = stick.ragdoll_next;
			}
			part = self.ragdoll_particlelist;
			while (part)
			{
				traceline(part.origin, part.neworg, TRUE, part);
				if (trace_fraction < 1)
				{
					part.neworg = trace_endpos;
					part.newtime = part.currenttime + (part.newtime - part.currenttime) * trace_fraction;
					// reflect the origin to the other side of the plane so that it will bounce/slide
					part.origin = part.origin - trace_plane_normal * (trace_plane_normal * part.origin - trace_plane_normal * part.neworg) * bouncefactor;
					// apply friction
					part.origin = part.origin + (part.neworg - part.origin) * friction;
				}
				part = part.ragdoll_next;
			}
		}
	}
};

// semi-implicit euler
void() RagDollThink =
{
	local float bump, ftime;
	local vector offset, voffset, dir;
	local entity part, stick;
	self.ragdoll_bounce = 1.2; // slight bounce
	self.ragdoll_friction = 0.05; // slight friction
	// maintain 64fps regardless of frametime for robustness
	while (self.ltime < time)
	{
		ftime = (1.0 / 64.0); // 64fps
		self.ltime = self.ltime + ftime;
		// apply acceleration to the particles and calculate neworg values
		part = self.ragdoll_particlelist;
		while (part)
		{
			part.velocity_z = part.velocity_z - sv_gravity * ftime;
			part.neworg = part.origin + part.velocity * ftime;
			part = part.ragdoll_next;
		}
		// apply stick constraints to the neworg values
		stick = self.ragdoll_sticklist;
		while (stick)
		{
			dir = normalize(stick.p2.neworg - stick.p1.neworg);
			offset = dir * 0.5 * (stick.ragdoll_preferredlength - dir * (stick.p2.neworg - stick.p1.neworg));
			voffset = dir * 0.5 * (0 - dir * (stick.p2.velocity - stick.p1.velocity));
			stick.p1.neworg = stick.p1.neworg + offset;
			stick.p2.neworg = stick.p2.neworg - offset;
			stick.p1.velocity = stick.p1.velocity + voffset;
			stick.p2.velocity = stick.p2.velocity - voffset;
			stick = stick.ragdoll_next;
		}
		part = self.ragdoll_particlelist;
		while (part)
		{
			t = ftime;
			bump = 0;
			while (bump < 16 && t >= 0.0001)
			{
				bump = bump + 1;
				traceline(part.origin, part.neworg, TRUE, part);
				// check if there was an impact
				if (trace_fraction == 1)
				{
					// no impact, update origin to the new position
					setorigin(part.origin, trace_endpos);
					// we're done!
					break;
				}
				else
				{
					// impact detected
					// reflect the velocity off the plane (bounce), and reduce velocity by a percentage (friction)
					part.velocity = (part.velocity - trace_plane_normal * (trace_plane_normal * part.velocity) * part.ragdoll_bounce) * (1 - part.ragdoll_friction);
					// if at least a little progress was made, update origin
					if (trace_fraction >= 0.0001)
					{
						// reduce remaining time
						t = t * (1 - trace_fraction);
						// update origin to the new position
						setorigin(part.origin, trace_endpos);
					}
					part.neworg = part.origin + part.velocity * t;
				}
			}
			// go to the next particle
			part = part.ragdoll_next;
		}
	}
};
*/

/*
.float ragdoll_bounce; // used on particles, recommended 1.2
.float ragdoll_friction; // used on particles, recommended 0.05
.entity ragdoll_next; // next particle/stick in list
.entity ragdoll_particlelist; // first entity in particle list of this body
.entity ragdoll_sticklist; // first entity in stick list of this body
.entity ragdoll_p1; // particle 1 of this stick (start)
.entity ragdoll_p2; // particle 2 of this stick (end)
.entity ragdoll_p3; // particle 3 of this stick (rotation)
.float ragdoll_preferredlength; // preferred length of this stick
void(entity ragdoll) Ragdoll_Remove;
// implicit euler/verlet hybrid
void() Ragdoll_Think =
{
	local float move, bump, iftime, ftime, t, f, averagecount, c;
	//local float step, sqrlength;
	local vector offset, dir, averageorigin;
	local entity part, stick, p1, p2;
	self.nextthink = time;
	if (time >= self.lefty)
	{
		Ragdoll_Remove(self);
		return;
	}
	// run at least a certain framerate for robustness
	//iftime = 32;
	//ftime = 1 / iftime;
	//if (ftime > frametime)
	//{
	//	ftime = frametime;
	//	iftime = 1 / ftime;
	//}
	//while (self.ltime < time)
	//{
	//	//self.ltime = self.ltime + ftime;
	ftime = frametime / 4;
	iftime = 1 / ftime;
	move = 0;
	while (move < 4)
	{
		move = move + 1;
		// apply acceleration to the particles and calculate dest values
		part = self.ragdoll_particlelist;
		while (part)
		{
			// integration method: implicit verlet/implicit euler hybrid
			// calculate dest for constraints to alter
			// (during tracing this will be converted back to velocity)
			part.dest = part.origin + part.velocity * ftime + '0 0 -1' * sv_gravity * ftime * ftime;
			part.velocity = (part.dest - part.origin) * iftime;
			part = part.ragdoll_next;
		}
		c = 0;
		while (c < 1)
		{
			c = c + 1;
			// apply stick constraints to the dest values
			stick = self.ragdoll_sticklist;
			while (stick)
			{
				p1 = stick.ragdoll_p1;
				p2 = stick.ragdoll_p2;
				//sqrlength = stick.ragdoll_preferredlength * stick.ragdoll_preferredlength;
				//dir = p2.dest - p1.dest;
				//offset = dir * (sqrlength/((dir * dir)+sqrlength)-0.5);
				dir = normalize(p2.dest - p1.dest);
				offset = dir * 0.5 * (stick.ragdoll_preferredlength - dir * (p2.dest - p1.dest));
				p1.dest = p1.dest - offset;
				p2.dest = p2.dest + offset;
				offset = dir * 0.5 * (0 - dir * (p2.velocity - p1.velocity));
				p1.velocity = p1.velocity - offset;
				p2.velocity = p2.velocity + offset;
				stick = stick.ragdoll_next;
			}
		}
		// move the particles to the new proposed locations, and bounce off any
		// surfaces in the way
		averageorigin = '0 0 0';
		averagecount = 0;
		part = self.ragdoll_particlelist;
		while (part)
		{
			// integration method: implicit verlet/implicit euler hybrid
			// convert dest back to velocity
			part.velocity = ((part.dest - part.origin) * iftime);
			//f = vlen(part.velocity);
			//c = f - ftime * 10;
			//if (c > 0)
			//	part.velocity = part.velocity * (c / f);
			//else
			//	part.velocity = '0 0 0';
			// perform moves until the end of the time slice
			t = ftime;
			bump = 0;
			while (bump < 16)
			{
				bump = bump + 1;
				// check if there was an impact
				tracebox(part.origin, part.mins, part.maxs, part.origin + part.velocity * t, TRUE, part);
				if (trace_fraction == 1)
				{
					// no impact, update origin to the new position
					setorigin(part, trace_endpos);
					// we're done!
					break;
				}
				// impact detected
				// reflect the velocity off the plane (bounce), and reduce velocity by a percentage (friction)
				f = 1 - part.ragdoll_friction * 0.1;
				part.velocity = (part.velocity - trace_plane_normal * (trace_plane_normal * part.velocity) * part.ragdoll_bounce) * f;
				// if at least a little progress was made, update origin
				if (trace_fraction >= 0.0001)
				{
					// reduce remaining time
					t = t * (1 - trace_fraction);
					// update origin to the new position
					setorigin(part, trace_endpos);
				}
			}
			part.dest = part.origin;
			averageorigin = averageorigin + part.origin;
			averagecount = averagecount + 1;
			// go to the next particle
			part = part.ragdoll_next;
		}
	}
	// update stick models
	stick = self.ragdoll_sticklist;
	while (stick)
	{
		setorigin(stick, (stick.ragdoll_p1.origin + stick.ragdoll_p2.origin) * 0.5);
		stick.angles = vectoangles(stick.ragdoll_p2.origin - stick.ragdoll_p1.origin);
		if (stick.ragdoll_p3)
		{
			makevectors(stick.angles_x * '-1 0 0' + stick.angles_y * '0 1 0');
			offset = (stick.ragdoll_p3.origin - stick.ragdoll_p1.origin);
			stick.angles_z = vectoyaw((offset * v_right) * '-1 0 0' + (offset * v_up) * '0 1 0');
		}
		stick = stick.ragdoll_next;
	}
};
*/
/*
.float ragdoll_bounce; // used on particles, recommended 1.2
.float ragdoll_friction; // used on particles, recommended 0.05
.entity ragdoll_next; // next particle/stick in list
.entity ragdoll_particlelist; // first entity in particle list of this body
.entity ragdoll_sticklist; // first entity in stick list of this body
.entity ragdoll_p1; // particle 1 of this stick (start)
.entity ragdoll_p2; // particle 2 of this stick (end)
.entity ragdoll_p3; // particle 3 of this stick (rotation)
.float ragdoll_preferredlength; // preferred length of this stick
void(entity ragdoll) Ragdoll_Remove;
// implicit euler/verlet hybrid
void() Ragdoll_Think =
{
	//local float move;
	local float bump;
	local float iftime;
	local float ftime;
	local float t;
	local float f;
	local float step;
	local float steps;
	//local float stepiftime;
	//local float steptolerance;
	local vector org;
	local vector vel;
	//local float c;
	//local float averagecount;
	//local float step;
	//local float sqrlength;
	local vector offset;
	//local vector dir;
	//local vector averageorigin;
	local entity part, stick, p1, p2;
	self.nextthink = time;
	if (time >= self.lefty)
	{
		Ragdoll_Remove(self);
		return;
	}
	// run at least a certain framerate for robustness
	//iftime = 20;
	//ftime = 1 / iftime;
	//if (ftime > frametime)
	//{
		ftime = frametime;
		iftime = 1 / ftime;
	//}
	//while (self.ltime < time)
	{
		//self.ltime = self.ltime + ftime;
		// apply acceleration to the particles
		// integration method: semi-implicit euler
		//part = self.ragdoll_particlelist;
		//while (part)
		//{
		//	part.velocity = part.velocity + '0 0 -1' * sv_gravity * ftime;
		//	part = part.ragdoll_next;
		//}

		// apply stick constraints to the origins
		part = self.ragdoll_particlelist;
		while (part)
		{
			part.dest = part.origin;
			// go to the next particle
			part = part.ragdoll_next;
		}
		// apply stick constraints to the velocities
		stick = self.ragdoll_sticklist;
		while (stick)
		{
			p1 = stick.ragdoll_p1;
			p2 = stick.ragdoll_p2;
			offset = (normalize(p2.dest - p1.dest) * stick.ragdoll_preferredlength - (p2.dest - p1.dest)) * 0.5;
			p1.dest = p1.dest - offset;
			p2.dest = p2.dest + offset;
			stick = stick.ragdoll_next;
		}

		// move the particles to the new proposed locations, and bounce off any
		// surfaces in the way
		part = self.ragdoll_particlelist;
		while (part)
		{
			// apply acceleration to the particles
			// integration method: semi-implicit euler
			part.velocity = part.velocity + '0 0 -1' * sv_gravity * ftime;
			org = part.origin;
			vel = part.velocity;
			steps = floor(vlen(part.velocity * ftime) * 0.125 + 1);
			step = 0;
			while (step < steps)
			{
				// perform moves until the end of the time slice
				step = step + 1;
				t = ftime / steps;
				bump = 0;
				while (bump < 16)
				{
					bump = bump + 1;
					// check if there was an impact
					tracebox(part.origin, part.mins, part.maxs, part.dest + part.velocity * t, TRUE, part);
					if (trace_fraction == 1)
					{
						// ignore successful moves over short distances after the
						// first bump, as they tend to destabilize the constraints
						//if (bump == 0 || vlen(part.velocity) >= 10)
						{
							// no impact, update origin to the new position
							setorigin(part, trace_endpos);
							part.dest = part.origin;
						}
						// we're done!
						break;
					}
					// impact detected
					if (part.velocity * trace_plane_normal < 0)
					{
						// reflect the velocity off the plane (bounce), and reduce velocity by a percentage (friction)
						f = 1 - part.ragdoll_friction * 0.1;
						if (f < 0)
							f = 0;
						// BUG: ragdoll_bounce occurs in addition to the natural spring back of the sticks when flattened against a surface...
						part.velocity = (part.velocity - trace_plane_normal * (trace_plane_normal * part.velocity) * part.ragdoll_bounce) * f;
						//c = vlen(part.velocity);
						//f = c - ftime * 50;
						//if (f > 0)
						//	part.velocity = part.velocity * (f / c);
						//else
						//	part.velocity = '0 0 0';
					}
					// if at least a little progress was made, update origin
					if (trace_fraction >= 0.0001)
					{
						// reduce remaining time
						t = t * (1 - trace_fraction);
						// update origin to the new position
						setorigin(part, trace_endpos);
						part.dest = part.origin;
					}
				}
			}
			// go to the next particle
			part = part.ragdoll_next;
		}
		// apply stick constraints to the velocities
		stick = self.ragdoll_sticklist;
		while (stick)
		{
			p1 = stick.ragdoll_p1;
			p2 = stick.ragdoll_p2;
			//offset = p2.origin - p1.origin + (p2.velocity - p1.velocity) * ftime;
			//offset = normalize(offset) * stick.ragdoll_preferredlength - offset;
			//offset = offset * iftime * 0.5;
			//offset = p2.origin - p1.origin + (p2.velocity - p1.velocity) * 0.0625;
			//offset = normalize(offset) * stick.ragdoll_preferredlength - offset;
			//offset = offset * 16 * 0.5;
			//offset = (p2.origin - p1.origin) * iftime + (p2.velocity - p1.velocity);
			//offset = normalize(offset) * stick.ragdoll_preferredlength * iftime - offset;
			//offset = offset * 0.5;
			//offset = ((normalize(p2.origin - p1.origin) * stick.ragdoll_preferredlength - (p2.origin - p1.origin)) * iftime - (p2.velocity - p1.velocity)) * 0.5;
			//offset = ((normalize((p2.origin - p1.origin) * iftime + (p2.velocity - p1.velocity)) * stick.ragdoll_preferredlength - (p2.origin - p1.origin)) * iftime - (p2.velocity - p1.velocity)) * 0.5;
			offset = (p2.velocity - p1.velocity) * 0.5;
			p1.velocity = p1.velocity - offset;
			p2.velocity = p2.velocity + offset;
			stick = stick.ragdoll_next;
		}
		//averageorigin = '0 0 0';
		//averagecount = 0;
		//	averageorigin = averageorigin + part.origin;
		//	averagecount = averagecount + 1;
	}
	// update stick models
	stick = self.ragdoll_sticklist;
	while (stick)
	{
		if (stick.modelindex)
		{
			setorigin(stick, (stick.ragdoll_p1.origin + stick.ragdoll_p2.origin) * 0.5);
			stick.angles = vectoangles(stick.ragdoll_p2.origin - stick.ragdoll_p1.origin);
			if (stick.ragdoll_p3)
			{
				makevectors(stick.angles_x * '-1 0 0' + stick.angles_y * '0 1 0');
				offset = (stick.ragdoll_p3.origin - stick.ragdoll_p1.origin);
				stick.angles_z = vectoyaw((offset * v_right) * '-1 0 0' + (offset * v_up) * '0 1 0');
			}
		}
		stick = stick.ragdoll_next;
	}
};
*/
/*
.float ragdoll_bounce; // used on particles, recommended 1.2
.float ragdoll_friction; // used on particles, recommended 0.05
.entity ragdoll_next; // next particle/stick in list
.entity ragdoll_particlelist; // first entity in particle list of this body
.entity ragdoll_sticklist; // first entity in stick list of this body
.entity ragdoll_p1; // particle 1 of this stick (start)
.entity ragdoll_p2; // particle 2 of this stick (end)
.entity ragdoll_p3; // particle 3 of this stick (rotation)
.float ragdoll_preferredlength; // preferred length of this stick
void(entity ragdoll) Ragdoll_Remove;
// implicit euler/verlet hybrid
void() Ragdoll_Think =
{
	//local float move;
	local float bump;
	local float iftime;
	local float ftime;
	local float t;
	local float f;
	//local float step;
	//local float steps;
	//local float stepiftime;
	//local float steptolerance;
	//local vector org;
	//local vector vel;
	//local float c;
	//local float averagecount;
	//local float step;
	//local float sqrlength;
	local vector offset;
	//local vector dir;
	//local vector averageorigin;
	local entity part, stick, p1, p2;
	self.nextthink = time;
	if (time >= self.lefty)
	{
		Ragdoll_Remove(self);
		return;
	}
	// run at least a certain framerate for robustness
	//iftime = 20;
	//ftime = 1 / iftime;
	//if (ftime > frametime)
	//{
		ftime = frametime;
		iftime = 1 / ftime;
	//}
	//while (self.ltime < time)
	{
		//self.ltime = self.ltime + ftime;
		// apply acceleration to the particles
		// integration method: semi-implicit euler
		//part = self.ragdoll_particlelist;
		//while (part)
		//{
		//	part.velocity = part.velocity + '0 0 -1' * sv_gravity * ftime;
		//	part = part.ragdoll_next;
		//}

		// move the particles to the new proposed locations, and bounce off any
		// surfaces in the way
		part = self.ragdoll_particlelist;
		while (part)
		{
			// apply acceleration to the particles
			// integration method: semi-implicit euler
			part.velocity = part.velocity + '0 0 -1' * sv_gravity * ftime;
			t = ftime;
			bump = 0;
			while (bump < 16)
			{
				bump = bump + 1;
				// check if there was an impact
				tracebox(part.origin, part.mins, part.maxs, part.origin + part.velocity * t, TRUE, part);
				if (trace_fraction == 1)
				{
					// ignore successful moves over short distances after the
					// first bump, as they tend to destabilize the constraints
					//if (bump == 0 || vlen(part.velocity) >= 10)
					{
						// no impact, update origin to the new position
						setorigin(part, trace_endpos);
					}
					// we're done!
					break;
				}
				// impact detected
				if (part.velocity * trace_plane_normal < 0)
				{
					// reflect the velocity off the plane (bounce), and reduce velocity by a percentage (friction)
					f = 1 - part.ragdoll_friction * 0.1;
					if (f < 0)
						f = 0;
					// BUG: ragdoll_bounce occurs in addition to the natural spring back of the sticks when flattened against a surface...
					part.velocity = (part.velocity - trace_plane_normal * (trace_plane_normal * part.velocity) * part.ragdoll_bounce) * f;
					//c = vlen(part.velocity);
					//f = c - ftime * 50;
					//if (f > 0)
					//	part.velocity = part.velocity * (f / c);
					//else
					//	part.velocity = '0 0 0';
				}
				// if at least a little progress was made, update origin
				if (trace_fraction >= 0.0001)
				{
					// reduce remaining time
					t = t * (1 - trace_fraction);
					// update origin to the new position
					setorigin(part, trace_endpos);
				}
			}
			// apply stick constraints to the velocities
			stick = self.ragdoll_sticklist;
			while (stick)
			{
				p1 = stick.ragdoll_p1;
				p2 = stick.ragdoll_p2;
				//offset = p2.origin - p1.origin + (p2.velocity - p1.velocity) * ftime;
				//offset = normalize(offset) * stick.ragdoll_preferredlength - offset;
				//offset = offset * iftime * 0.5;
				//offset = p2.origin - p1.origin + (p2.velocity - p1.velocity) * 0.0625;
				//offset = normalize(offset) * stick.ragdoll_preferredlength - offset;
				//offset = offset * 16 * 0.5;
				//offset = (p2.origin - p1.origin) * iftime + (p2.velocity - p1.velocity);
				//offset = normalize(offset) * stick.ragdoll_preferredlength * iftime - offset;
				//offset = offset * 0.5;
				//offset = ((normalize(p2.origin - p1.origin) * stick.ragdoll_preferredlength - (p2.origin - p1.origin)) * iftime - (p2.velocity - p1.velocity)) * 0.5;
				offset = ((normalize((p2.origin - p1.origin) * iftime + (p2.velocity - p1.velocity)) * stick.ragdoll_preferredlength - (p2.origin - p1.origin)) * iftime - (p2.velocity - p1.velocity)) * 0.5;
				p1.velocity = p1.velocity - offset;
				p2.velocity = p2.velocity + offset;
				stick = stick.ragdoll_next;
			}
			// go to the next particle
			part = part.ragdoll_next;
		}
		//averageorigin = '0 0 0';
		//averagecount = 0;
		//	averageorigin = averageorigin + part.origin;
		//	averagecount = averagecount + 1;
	}
	// update stick models
	stick = self.ragdoll_sticklist;
	while (stick)
	{
		if (stick.modelindex)
		{
			setorigin(stick, (stick.ragdoll_p1.origin + stick.ragdoll_p2.origin) * 0.5);
			stick.angles = vectoangles(stick.ragdoll_p2.origin - stick.ragdoll_p1.origin);
			if (stick.ragdoll_p3)
			{
				makevectors(stick.angles_x * '-1 0 0' + stick.angles_y * '0 1 0');
				offset = (stick.ragdoll_p3.origin - stick.ragdoll_p1.origin);
				stick.angles_z = vectoyaw((offset * v_right) * '-1 0 0' + (offset * v_up) * '0 1 0');
			}
		}
		stick = stick.ragdoll_next;
	}
};
*/

.float ragdoll_bounce; // used on particles, recommended 1.2
.float ragdoll_friction; // used on particles, recommended 0.05
.entity ragdoll_next; // next particle/stick in list
.entity ragdoll_particlelist; // first entity in particle list of this body
.entity ragdoll_sticklist; // first entity in stick list of this body
.entity ragdoll_p1; // particle 1 of this stick (start)
.entity ragdoll_p2; // particle 2 of this stick (end)
.entity ragdoll_p3; // particle 3 of this stick (rotation)
.float ragdoll_mass;
.float ragdoll_inversemass;
.float ragdoll_preferredlength; // preferred length of this stick
void(entity ragdoll) Ragdoll_Remove;
// implicit euler/verlet hybrid
void() Ragdoll_Think =
{
	//local float move;
	local float bump;
	local float iftime;
	local float ftime;
	local float t;
	local float f;
	local vector force;
	//local float step;
	//local float steps;
	//local float stepiftime;
	//local float steptolerance;
	//local vector org;
	//local vector vel;
	//local float c;
	//local float averagecount;
	//local float sqrlength;
	local vector offset;
	local vector org1, org2, org3;
	//local vector dir;
	//local vector averageorigin;
	local entity part, stick, p1, p2;
	self.nextthink = time;
	if (time >= self.lefty)
	{
		Ragdoll_Remove(self);
		return;
	}

	//steps = 1;
	//part = self.ragdoll_particlelist;
	//while (part)
	//{
	//	f = floor(vlen(part.velocity * frametime + '0 0 -1' * sv_gravity * frametime * frametime) / 4 + 1);
	//	if (steps < f)
	//		steps = f;
	//	// go to the next particle
	//	part = part.ragdoll_next;
	//}
	//ftime = frametime / steps;
	//iftime = 1 / ftime;
	//step = 0;
	//while (step < steps)
	//{
	//	step = step + 1;
	// run at least a certain framerate for robustness
	iftime = 100;
	ftime = 1 / iftime;
	//if (ftime > frametime)
	//{
	//	ftime = frametime;
	//	iftime = 1 / ftime;
	//}
	while (self.ltime < time)
	{
		self.ltime = self.ltime + ftime;
		// apply stick constraints to the velocities
		stick = self.ragdoll_sticklist;
		while (stick)
		{
			p1 = stick.ragdoll_p1;
			p2 = stick.ragdoll_p2;
			//offset = p2.origin - p1.origin + (p2.velocity - p1.velocity) * ftime;
			//offset = normalize(offset) * stick.ragdoll_preferredlength - offset;
			//offset = offset * iftime * 0.5;
			//offset = p2.origin - p1.origin + (p2.velocity - p1.velocity) * 0.0625;
			//offset = normalize(offset) * stick.ragdoll_preferredlength - offset;
			//offset = offset * 16 * 0.5;
			//offset = (p2.origin - p1.origin) * iftime + (p2.velocity - p1.velocity);
			//offset = normalize(offset) * stick.ragdoll_preferredlength * iftime - offset;
			//offset = offset * 0.5;
			//offset = ((normalize(p2.origin - p1.origin) * stick.ragdoll_preferredlength - (p2.origin - p1.origin)) * iftime - (p2.velocity - p1.velocity)) * 0.5;
			//if (p1 == part || p2 == part)
			{
				offset = ((normalize((p2.origin - p1.origin) * iftime + (p2.velocity - p1.velocity)) * stick.ragdoll_preferredlength - (p2.origin - p1.origin)) * iftime - (p2.velocity - p1.velocity)) * 0.5;
				p1.velocity = p1.velocity - offset;
				p2.velocity = p2.velocity + offset;
			}
			stick = stick.ragdoll_next;
		}
		// move the particles to the new proposed locations, and bounce off any
		// surfaces in the way
		part = self.ragdoll_particlelist;
		while (part)
		{
			// apply acceleration to the particles
			// integration method: semi-implicit euler
			//part.velocity = part.velocity + '0 0 -1' * sv_gravity * ftime;
			// integration method: half-step implicit euler
			part.velocity = part.velocity + '0 0 -0.5' * sv_gravity * ftime;
			t = ftime;
			bump = 0;
			while (bump < 16)
			{
				bump = bump + 1;
				// check if there was an impact
				tracebox(part.origin, part.mins, part.maxs, part.origin + part.velocity * t, FALSE, part);
				if (trace_fraction == 1)
				{
					// ignore successful moves over short distances after the
					// first bump, as they tend to destabilize the constraints
					//if (bump == 0 || vlen(part.velocity) >= 10)
					{
						// no impact, update origin to the new position
						setorigin(part, trace_endpos);
					}
					// we're done!
					break;
				}
				// impact detected
				if (part.velocity * trace_plane_normal < 0)
				{
					// reflect the velocity off the plane (bounce), and reduce velocity by a percentage (friction)
					f = 1 - part.ragdoll_friction * 0.1;
					if (f < 0)
						f = 0;
					// BUG: ragdoll_bounce occurs in addition to the natural spring back of the sticks when flattened against a surface...
					if (trace_ent.classname == "ragdoll_particle")
					{
						// hack to make particles behave sort of spherically
						//trace_plane_normal = normalize(part.origin - trace_ent.origin);
						// calculate impulse (impact force)
						force = trace_plane_normal * (trace_plane_normal * (part.velocity * part.ragdoll_mass - trace_ent.velocity * trace_ent.ragdoll_mass));
						// apply to both particles (in opposite directions)
						part.velocity = (part.velocity - force * part.ragdoll_inversemass * part.ragdoll_bounce) * f;
						trace_ent.velocity = (part.velocity + force * part.ragdoll_inversemass * part.ragdoll_bounce) * f;
					}
					else
						part.velocity = (part.velocity - (trace_plane_normal * (trace_plane_normal * part.velocity)) * part.ragdoll_bounce) * f;
					//c = vlen(part.velocity);
					//f = c - ftime * 50;
					//if (f > 0)
					//	part.velocity = part.velocity * (f / c);
					//else
					//	part.velocity = '0 0 0';
				}
				// if at least a little progress was made, update origin
				if (trace_fraction >= 0.0001)
				{
					// reduce remaining time
					t = t * (1 - trace_fraction);
					// update origin to the new position
					setorigin(part, trace_endpos);
				}
			}
			// apply the rest of the acceleration now
			part.velocity = part.velocity + '0 0 -0.5' * sv_gravity * ftime;
			// go to the next particle
			part = part.ragdoll_next;
		}

		//averageorigin = '0 0 0';
		//averagecount = 0;
		//	averageorigin = averageorigin + part.origin;
		//	averagecount = averagecount + 1;
	}
	// update stick models
	stick = self.ragdoll_sticklist;
	while (stick)
	{
		if (stick.modelindex)
		{
			org1 = stick.ragdoll_p1.origin + stick.ragdoll_p1.velocity * ftime;
			org2 = stick.ragdoll_p2.origin + stick.ragdoll_p2.velocity * ftime;
			setorigin(stick, (org1 + org2) * 0.5);
			stick.angles = vectoangles(org2 - org1);
			if (stick.ragdoll_p3)
			{
				org3 = stick.ragdoll_p3.origin + stick.ragdoll_p3.velocity * ftime;
				makevectors(stick.angles_x * '-1 0 0' + stick.angles_y * '0 1 0');
				offset = org3 - org1;
				stick.angles_z = vectoyaw((offset * v_right) * '-1 0 0' + (offset * v_up) * '0 1 0');
			}
		}
		stick = stick.ragdoll_next;
	}
};

entity(float expirationdate) Ragdoll_Spawn =
{
	local entity e;
	e = spawn();
	e.classname = "ragdoll";
	e.think = Ragdoll_Think;
	e.nextthink = time;
	e.ltime = time;
	e.lefty = time + expirationdate;
	return e;
};

void(entity ragdoll) Ragdoll_Remove =
{
	local entity e, next;
	e = ragdoll.ragdoll_particlelist;
	while (e)
	{
		next = e.ragdoll_next;
		remove(e);
		e = next;
	}
	e = ragdoll.ragdoll_sticklist;
	while (e)
	{
		next = e.ragdoll_next;
		remove(e);
		e = next;
	}
	remove(ragdoll);
};

entity(entity ragdoll, vector org, vector vel, vector m1, vector m2, float mas, float forcescal, float bouncefactor, float frictionfactor) Ragdoll_AddParticle =
{
	local entity e;
	e = spawn();
	e.classname = "ragdoll_particle";
	e.owner = ragdoll;
	e.ragdoll_next = e.owner.ragdoll_particlelist;
	e.owner.ragdoll_particlelist = e;
	e.ragdoll_mass = mas;
	e.ragdoll_inversemass = 1.0 / mas;
	e.ragdoll_bounce = bouncefactor;
	e.ragdoll_friction = frictionfactor;
	e.forcescale = forcescal;
	e.takedamage = DAMAGE_YES;
	e.th_die = SUB_Null;
	e.th_gib = SUB_Null;
	e.th_pain = SUB_Null;
	e.solid = SOLID_TRIGGER;//BBOX;
	e.movetype = MOVETYPE_NONE;
	e.velocity = vel;
	setorigin(e, org);
	//setmodel(e, "progs/s_bubble.spr"); // debugging
	setsize(e, m1, m2);
	return e;
};

entity(entity ragdoll, entity p1, entity p2, entity p3, string modelname) Ragdoll_AddStick =
{
	local entity e;
	e = spawn();
	e.classname = "ragdoll_stick";
	e.owner = ragdoll;
	e.ragdoll_next = e.owner.ragdoll_sticklist;
	e.owner.ragdoll_sticklist = e;
	e.ragdoll_p1 = p1;
	e.ragdoll_p2 = p2;
	e.ragdoll_p3 = p3;
	e.ragdoll_preferredlength = vlen(p2.origin - p1.origin);
	if (modelname != "")
		setmodel(e, modelname);
	//eprint(e);
	return e;
};

entity(vector org1, vector vel1, vector org2, vector vel2, string modelname) Ragdoll_ThrowCasing =
{
	local entity r, p1, p2;
	r = Ragdoll_Spawn(60);
	p1 = Ragdoll_AddParticle(r, org1, vel1, '-1 -1 -3', '1 1 3', 1, 6, 1.5, 0.2);
	p2 = Ragdoll_AddParticle(r, org2, vel2, '-1 -1 -3', '1 1 3', 1, 6, 1.5, 0.2);
	Ragdoll_AddStick(r, p1, p2, world, modelname);
	return r;
};

entity(vector org, vector vel, string modelname) Ragdoll_ThrowGib =
{
	local entity r, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10;
	r = Ragdoll_Spawn(60);
	makevectors(randomvec() * 360);
	if (modelname == "progs/gib1.mdl")
	{
		// arm piece
		p1 = Ragdoll_AddParticle(r, org + v_forward * -8, vel + randomvec() * 150, '-1 -1 -3', '1 1 3', 0.5, 5, 1.5, 1.0);
		//p2 = Ragdoll_AddParticle(r, org + v_forward *  8, vel + randomvec() * 150, '-1 -1 -3', '1 1 3', 0.5, 5, 1.5, 1.0);
		p3 = Ragdoll_AddParticle(r, org + v_right *  2, vel + randomvec() * 150, '-1 -1 -3', '1 1 3', 0.5, 5, 1.5, 1.0);
		p4 = Ragdoll_AddParticle(r, org + v_right * -2, vel + randomvec() * 150, '-1 -1 -3', '1 1 3', 0.5, 5, 1.5, 1.0);
		//Ragdoll_AddStick(r, p1, p2, world, "");
		Ragdoll_AddStick(r, p1, p3, world, "");
		Ragdoll_AddStick(r, p1, p4, world, "");
		//Ragdoll_AddStick(r, p2, p3, world, "");
		//Ragdoll_AddStick(r, p2, p4, world, "");
		Ragdoll_AddStick(r, p3, p4, p1, modelname);
	}
	else if (modelname == "progs/gib2.mdl")
	{
		// rib cage
		p1 = Ragdoll_AddParticle(r, org + v_forward *  12, vel + randomvec() * 150, '-1 -1 -1', '1 1 1', 1.5, 5, 1.5, 1.0);
		p2 = Ragdoll_AddParticle(r, org + v_forward * -12, vel + randomvec() * 150, '-1 -1 -1', '1 1 1', 1.5, 5, 1.5, 1.0);
		p3 = Ragdoll_AddParticle(r, org + v_forward * 8 + v_right   *  12, vel + randomvec() * 150, '-1 -1 -1', '1 1 1', 1.5, 5, 1.5, 1.0);
		p4 = Ragdoll_AddParticle(r, org + v_forward * 8 + v_right   * -12, vel + randomvec() * 150, '-1 -1 -1', '1 1 1', 1.5, 5, 1.5, 1.0);
		p5 = Ragdoll_AddParticle(r, org + v_up      *  6, vel + randomvec() * 150, '-1 -1 -1', '1 1 1', 1.5, 5, 1.5, 1.0);
		p6 = Ragdoll_AddParticle(r, org + v_up      * -6, vel + randomvec() * 150, '-1 -1 -1', '1 1 1', 1.5, 5, 1.5, 1.0);
		Ragdoll_AddStick(r, p1, p2, p3, modelname);
		Ragdoll_AddStick(r, p1, p3, world, "");
		Ragdoll_AddStick(r, p1, p4, world, "");
		Ragdoll_AddStick(r, p1, p5, world, "");
		Ragdoll_AddStick(r, p1, p6, world, "");
		Ragdoll_AddStick(r, p2, p3, world, "");
		Ragdoll_AddStick(r, p2, p4, world, "");
		Ragdoll_AddStick(r, p2, p5, world, "");
		Ragdoll_AddStick(r, p2, p6, world, "");
		Ragdoll_AddStick(r, p3, p4, world, "");
		Ragdoll_AddStick(r, p3, p5, world, "");
		Ragdoll_AddStick(r, p3, p6, world, "");
		Ragdoll_AddStick(r, p4, p5, world, "");
		Ragdoll_AddStick(r, p4, p6, world, "");
		Ragdoll_AddStick(r, p5, p6, world, "");
	}
	else if (modelname == "progs/gib3.mdl")
	{
		// slab of meat
		p1 = Ragdoll_AddParticle(r, org + v_forward *  12, vel + randomvec() * 150, '-1 -1 -3', '1 1 3', 10, 5, 1.5, 1.0);
		p2 = Ragdoll_AddParticle(r, org + v_forward * -12, vel + randomvec() * 150, '-1 -1 -3', '1 1 3', 10, 5, 1.5, 1.0);
		p3 = Ragdoll_AddParticle(r, org + v_right   *  12, vel + randomvec() * 150, '-1 -1 -3', '1 1 3', 10, 5, 1.5, 1.0);
		//p4 = Ragdoll_AddParticle(r, org + v_right   * -12, vel + randomvec() * 150, '-1 -1 -3', '1 1 3', 10, 5, 1.5, 1.0);
		Ragdoll_AddStick(r, p1, p2, p3, modelname);
		Ragdoll_AddStick(r, p1, p3, world, "");
		//Ragdoll_AddStick(r, p1, p4, world, "");
		Ragdoll_AddStick(r, p2, p3, world, "");
		//Ragdoll_AddStick(r, p2, p4, world, "");
		//Ragdoll_AddStick(r, p3, p4, world, "");
	}
	else
	{
		// probably a head
		p1 = Ragdoll_AddParticle(r, org + v_up      *  0 + v_forward *  5, vel + randomvec() * 150, '-1 -1 -1', '1 1 1', 7, 5, 1.5, 1.0);
		p2 = Ragdoll_AddParticle(r, org + v_up      *  0 + v_forward * -5, vel + randomvec() * 150, '-1 -1 -1', '1 1 1', 7, 5, 1.5, 1.0);
		p3 = Ragdoll_AddParticle(r, org + v_up      *  0 + v_right   *  5, vel + randomvec() * 150, '-1 -1 -1', '1 1 1', 7, 5, 1.5, 1.0);
		p4 = Ragdoll_AddParticle(r, org + v_up      *  0 + v_right   * -5, vel + randomvec() * 150, '-1 -1 -1', '1 1 1', 7, 5, 1.5, 1.0);
		p5 = Ragdoll_AddParticle(r, org + v_up      * 12 + v_forward *  5, vel + randomvec() * 150, '-1 -1 -1', '1 1 1', 7, 5, 1.5, 1.0);
		p6 = Ragdoll_AddParticle(r, org + v_up      * 12 + v_forward * -5, vel + randomvec() * 150, '-1 -1 -1', '1 1 1', 7, 5, 1.5, 1.0);
		p7 = Ragdoll_AddParticle(r, org + v_up      * 12 + v_right   *  5, vel + randomvec() * 150, '-1 -1 -1', '1 1 1', 7, 5, 1.5, 1.0);
		p8 = Ragdoll_AddParticle(r, org + v_up      * 12 + v_right   * -5, vel + randomvec() * 150, '-1 -1 -1', '1 1 1', 7, 5, 1.5, 1.0);
		p9 = Ragdoll_AddParticle(r, org + v_up      *  0, vel + randomvec() * 150, '-1 -1 -1', '1 1 1', 7, 5, 1.5, 1.0);
		p10= Ragdoll_AddParticle(r, org + v_up      * 12, vel + randomvec() * 150, '-1 -1 -1', '1 1 1', 7, 5, 1.5, 1.0);
		Ragdoll_AddStick(r, p1, p2, p3, modelname);
		Ragdoll_AddStick(r, p1, p3, world, "");
		Ragdoll_AddStick(r, p1, p4, world, "");
		Ragdoll_AddStick(r, p1, p5, world, "");
		Ragdoll_AddStick(r, p1, p6, world, "");
		Ragdoll_AddStick(r, p1, p7, world, "");
		Ragdoll_AddStick(r, p1, p8, world, "");
		Ragdoll_AddStick(r, p1, p9, world, "");
		Ragdoll_AddStick(r, p1, p10, world, "");
		Ragdoll_AddStick(r, p2, p3, world, "");
		Ragdoll_AddStick(r, p2, p4, world, "");
		Ragdoll_AddStick(r, p2, p5, world, "");
		Ragdoll_AddStick(r, p2, p6, world, "");
		Ragdoll_AddStick(r, p2, p7, world, "");
		Ragdoll_AddStick(r, p2, p8, world, "");
		Ragdoll_AddStick(r, p2, p9, world, "");
		Ragdoll_AddStick(r, p2, p10, world, "");
		Ragdoll_AddStick(r, p3, p4, world, "");
		Ragdoll_AddStick(r, p3, p5, world, "");
		Ragdoll_AddStick(r, p3, p6, world, "");
		Ragdoll_AddStick(r, p3, p7, world, "");
		Ragdoll_AddStick(r, p3, p8, world, "");
		Ragdoll_AddStick(r, p3, p9, world, "");
		Ragdoll_AddStick(r, p3, p10, world, "");
		Ragdoll_AddStick(r, p4, p5, world, "");
		Ragdoll_AddStick(r, p4, p6, world, "");
		Ragdoll_AddStick(r, p4, p7, world, "");
		Ragdoll_AddStick(r, p4, p8, world, "");
		Ragdoll_AddStick(r, p4, p9, world, "");
		Ragdoll_AddStick(r, p4, p10, world, "");
		Ragdoll_AddStick(r, p5, p6, world, "");
		Ragdoll_AddStick(r, p5, p7, world, "");
		Ragdoll_AddStick(r, p5, p8, world, "");
		Ragdoll_AddStick(r, p5, p9, world, "");
		Ragdoll_AddStick(r, p5, p10, world, "");
		Ragdoll_AddStick(r, p6, p7, world, "");
		Ragdoll_AddStick(r, p6, p8, world, "");
		Ragdoll_AddStick(r, p6, p9, world, "");
		Ragdoll_AddStick(r, p6, p10, world, "");
		Ragdoll_AddStick(r, p7, p8, world, "");
		Ragdoll_AddStick(r, p7, p9, world, "");
		Ragdoll_AddStick(r, p7, p10, world, "");
		Ragdoll_AddStick(r, p8, p9, world, "");
		Ragdoll_AddStick(r, p8, p10, world, "");
		Ragdoll_AddStick(r, p9, p10, world, "");
	}
	return r;
};

.float rb_lastmovetime;
.vector rb_origin;
.vector rb_velocity;
.vector rb_forward;
.vector rb_left;
.vector rb_up;
.vector rb_spinaxis;
.float rb_spinspeed;
.float rb_mass;
.float rb_numpoints;
.vector rb_points[16];

vector _rb_origin;
vector _rb_forward;
vector _rb_left;
vector _rb_up;

float _rb_trace_fraction;
vector _rb_trace_contact_point;
vector _rb_trace_contact_point_local;
vector _rb_trace_contact_plane_normal;

vector(vector a, vector b) crossproduct =
{
	local vector v;
	v_x = a_y * b_z - a_z * b_y;
	v_y = a_z * b_x - a_x * b_z;
	v_z = a_x * b_y - a_y * b_x;
	return v;
};

void(entity body) RigidBody_FixMatrix =
{
	body.rb_forward = normalize(body.rb_forward);
	body.rb_left = normalize(body.rb_left);
	body.rb_up = normalize(body.rb_up);
	if (fabs(body.rb_forward * body.rb_up) > 0.01 || vlen(body.rb_left) < 0.9)
	{
		// no left, regenerate it from forward and up
		body.rb_left = crossproduct(body.rb_forward, body.rb_up);
		body.rb_forward = crossproduct(body.rb_left, body.rb_up);
	}
	else if (fabs(body.rb_forward * body.rb_left) > 0.01 || vlen(body.rb_up) < 0.9)
	{
		// no up, regenerate it from forward and left
		body.rb_up = crossproduct(body.rb_forward, body.rb_left);
		body.rb_forward = crossproduct(body.rb_left, body.rb_up);
	}
	else if (fabs(body.rb_left * body.rb_up) > 0.01 || vlen(body.rb_forward) < 0.9)
	{
		// no forward, regenerate it from left and up
		body.rb_forward = crossproduct(body.rb_left, body.rb_up);
		body.rb_left = crossproduct(body.rb_forward, body.rb_up);
	}
	if (vlen(body.rb_spinaxis) < 0.999)
	{
		body.rb_spinaxis = normalize(body.rb_spinaxis);
		if (vlen(body.rb_spinaxis) < 0.9)
		{
			body.rb_spinaxis = '1 0 0';
			body.rb_spinspeed = 0;
		}
	}
	if (vlen(body.rb_velocity) < 0.001)
		body.rb_velocity = '0 0 0';
};

/*
void(vector in1_forward, vector in1_left, vector in1_up, vector in2_forward, vector in2_left, vector in2_up) RigidBody_MultiplyMatrix
{
	_rb_temp_forward_x = in1_forward_x * in2_forward_x + in1_left_x * in2_forward_y + in1_up_x * in2_forward_z;
	_rb_temp_forward_y = in1_forward_y * in2_forward_x + in1_left_y * in2_forward_y + in1_up_y * in2_forward_z;
	_rb_temp_forward_z = in1_forward_z * in2_forward_x + in1_left_z * in2_forward_y + in1_up_z * in2_forward_z;
	_rb_temp_left_x = in1_forward_x * in2_left_x + in1_left_x * in2_left_y + in1_up_x * in2_left_z;
	_rb_temp_left_y = in1_forward_y * in2_left_x + in1_left_y * in2_left_y + in1_up_y * in2_left_z;
	_rb_temp_left_z = in1_forward_z * in2_left_x + in1_left_z * in2_left_y + in1_up_z * in2_left_z;
	_rb_temp_up_x = in1_forward_x * in2_up_x + in1_left_x * in2_up_y + in1_up_x * in2_up_z;
	_rb_temp_up_y = in1_forward_y * in2_up_x + in1_left_y * in2_up_y + in1_up_y * in2_up_z;
	_rb_temp_up_z = in1_forward_z * in2_up_x + in1_left_z * in2_up_y + in1_up_z * in2_up_z;
}

void(vector axis, float angle) RigidBody_MatrixFromRodriguesVector
{
	local float c, s, mc;

	axis = normalize(axis);
	c = cos(angle);mc = 1 - c;
	s = sin(angle);

	// proper orientation
	_rb_temp_forward_x = axis_x * axis_x + c * (1 - axis_x * axis_x);
	_rb_temp_forward_y = axis_x * axis_y * mc - axis_z * s;
	_rb_temp_forward_z = axis_z * axis_x * mc + axis_y * s;
	_rb_temp_left_x = axis_x * axis_y * mc + axis_z * s;
	_rb_temp_left_y = axis_y * axis_y + c * (1 - axis_y * axis_y);
	_rb_temp_left_z = axis_y * axis_z * mc - axis_x * s;
	_rb_temp_up_x = axis_z * axis_x * mc - axis_y * s;
	_rb_temp_up_y = axis_y * axis_z * mc + axis_x * s;
	_rb_temp_up_z = axis_z * axis_z + c * (1 - axis_z * axis_z);
}
*/

void(entity body, float movetime) RigidBody_ExtrapolateMotion =
{
	local vector startorigin;
	local vector forward;
	local vector left;
	local vector up;
	local vector vel;
	local vector axis;
	local float spin;
	local float c, s, mc;
	local vector rforward;
	local vector rleft;
	local vector rup;

	startorigin = body.rb_origin;
	forward = body.rb_forward;
	left = body.rb_left;
	up = body.rb_up;
	vel = body.rb_velocity;
	axis = body.rb_spinaxis;
	spin = body.rb_spinspeed;

	axis = normalize(axis);
	c = cos(spin * movetime);mc = 1 - c;
	s = sin(spin * movetime);

	rforward_x = axis_x * axis_x + c * (1 - axis_x * axis_x);
	rforward_y = axis_x * axis_y * mc - axis_z * s;
	rforward_z = axis_z * axis_x * mc + axis_y * s;
	rleft_x = axis_x * axis_y * mc + axis_z * s;
	rleft_y = axis_y * axis_y + c * (1 - axis_y * axis_y);
	rleft_z = axis_y * axis_z * mc - axis_x * s;
	rup_x = axis_z * axis_x * mc - axis_y * s;
	rup_y = axis_y * axis_z * mc + axis_x * s;
	rup_z = axis_z * axis_z + c * (1 - axis_z * axis_z);

	_rb_origin = startorigin + vel * movetime;
	_rb_forward_x = rforward_x * forward_x + rleft_x * forward_y + rup_x * forward_z;
	_rb_forward_y = rforward_y * forward_x + rleft_y * forward_y + rup_y * forward_z;
	_rb_forward_z = rforward_z * forward_x + rleft_z * forward_y + rup_z * forward_z;
	_rb_left_x = rforward_x * left_x + rleft_x * left_y + rup_x * left_z;
	_rb_left_y = rforward_y * left_x + rleft_y * left_y + rup_y * left_z;
	_rb_left_z = rforward_z * left_x + rleft_z * left_y + rup_z * left_z;
	_rb_up_x = rforward_x * up_x + rleft_x * up_y + rup_x * up_z;
	_rb_up_y = rforward_y * up_x + rleft_y * up_y + rup_y * up_z;
	_rb_up_z = rforward_z * up_x + rleft_z * up_y + rup_z * up_z;

	/*
	// swapped multiply order
	_rb_forward_x = forward_x * rforward_x + left_x * rforward_y + up_x * rforward_z;
	_rb_forward_y = forward_y * rforward_x + left_y * rforward_y + up_y * rforward_z;
	_rb_forward_z = forward_z * rforward_x + left_z * rforward_y + up_z * rforward_z;
	_rb_left_x = forward_x * rleft_x + left_x * rleft_y + up_x * rleft_z;
	_rb_left_y = forward_y * rleft_x + left_y * rleft_y + up_y * rleft_z;
	_rb_left_z = forward_z * rleft_x + left_z * rleft_y + up_z * rleft_z;
	_rb_up_x = forward_x * rup_x + left_x * rup_y + up_x * rup_z;
	_rb_up_y = forward_y * rup_x + left_y * rup_y + up_y * rup_z;
	_rb_up_z = forward_z * rup_x + left_z * rup_y + up_z * rup_z;
	*/
};

void(entity body, vector p, vector a, vector b) RigidBody_TracePoint =
{
	traceline(a, b, FALSE, body);
	// TODO: handle multiple contacts
	if (_rb_trace_fraction > trace_fraction)
	{
		_rb_trace_fraction = trace_fraction;
		_rb_trace_contact_point = trace_endpos;
		_rb_trace_contact_plane_normal = trace_plane_normal;
		_rb_trace_contact_point_local = p;
	}
};

void(entity body) RigidBody_Trace =
{
	local float i;
	local vector p;
	local vector aorigin;
	local vector aforward;
	local vector aleft;
	local vector aup;
	local vector borigin;
	local vector bforward;
	local vector bleft;
	local vector bup;

	aorigin = body.rb_origin;
	aforward = body.rb_forward;
	aleft = body.rb_left;
	aup = body.rb_up;
	borigin = _rb_origin;
	bforward = _rb_forward;
	bleft = _rb_left;
	bup = _rb_up;

	_rb_trace_fraction = 1;
	_rb_trace_contact_point = '0 0 0';
	_rb_trace_contact_plane_normal = '0 0 0';
	for (i = 0;i < body.rb_numpoints;i++)
	{
		p = body.(rb_points[i]);
		RigidBody_TracePoint(body, p, aorigin + p_x * aforward + p_y * aleft + p_z * aup, borigin + p_x * bforward + p_y * bleft + p_z * bup);
	}
}

void(entity body, vector org, vector forward, vector left, vector up) RigidBody_UpdatePosition =
{
	body.rb_origin = org;
	body.rb_forward = forward;
	body.rb_left = left;
	body.rb_up = up;
};

void(entity body, vector lp, vector lf) RigidBody_ApplyImpulse =
{
/*
	local vector aorigin;
	local vector aforward;
	local vector aleft;
	local vector aup;
	local vector borigin;
	local vector bforward;
	local vector bleft;
	local vector bup;
	local vector fspinaxis;
	local float fspinspeed;
	local vector an, bn;

	// FIXME: finish this
	lf = lf * (1 / body.rb_mass);
	fspinaxis = normalize(crossproduct(lp, lf));
	fspinspeed = vlen(lf) * (1 / vlen(lp));

	aorigin = body.rb_origin;
	aforward = body.rb_forward;
	aleft = body.rb_left;
	aup = body.rb_up;
	borigin = _rb_origin;
	bforward = _rb_forward;
	bleft = _rb_left;
	bup = _rb_up;

	// TODO
	an_x = n * aforward;
	an_y = n * aleft;
	an_z = n * aup;

	temp = lp_x * bforward + p_y * bleft + p_z * bup;
	lp2_x = temp * aforward;
	lp2_y = temp * aleft;
	lp2_z = temp * aup;
	d = (lp2 - lp) * an;
	if (d >= 0)
		return;
	c = lp2 - an * d;

	p1 = aorigin + p_x * aforward + p_y * aleft + p_z * aup;
	p2 = borigin + p_x * bforward + p_y * bleft + p_z * bup;
	d = (p2 - p1) * n;
	if (d >= 0)
		return;
	c = p2 - n * d;
	c2 = c - borigin;
	lc_x = c2 * bforward;
	lc_y = c2 * bleft;
	lc_z = c2 * bup;

	p1 = aorigin + p_x * aforward + p_y * aleft + p_z * aup;
	p2 = borigin + p_x * bforward + p_y * bleft + p_z * bup;
*/
};

void() RigidBody_Think =
{
	local float movetime;
	local float collisiontime;
	self.nextthink = time;
	movetime = time - self.rb_lastmovetime;
	self.rb_lastmovetime = time;
	while (movetime > 0.001)
	{
		RigidBody_ExtrapolateMotion(self, movetime);
		RigidBody_Trace(self);
		collisiontime = movetime * _rb_trace_fraction;
		movetime = movetime - collisiontime;
		RigidBody_ExtrapolateMotion(self, collisiontime);
		RigidBody_UpdatePosition(self, _rb_origin, _rb_forward, _rb_left, _rb_up);
		RigidBody_FixMatrix(self);
		if (_rb_trace_fraction < 1)
		{
			// now apply contact joints
			RigidBody_ExtrapolateMotion(self, 1 / 65536);
			// FIXME: code this
			//RigidBody_ApplyContact(_rb_trace_contact_point_local, _rb_trace_contact_plane_normal);
			RigidBody_FixMatrix(self);
		}
	}
};

entity(string modelname, vector org, vector forward, vector left, vector up, float mass, vector vel, vector axis, float spin) RigidBody_Spawn =
{
	local entity body;
	body = spawn();
	body.classname = "rigidbody";
	body.think = RigidBody_Think;
	body.nextthink = time;
	body.rb_lastmovetime = time;
	setmodel(body, modelname);
	body.rb_forward = forward;
	body.rb_left = left;
	body.rb_up = up;
	body.rb_mass = mass;
	body.rb_velocity = vel;
	body.rb_spinaxis = axis;
	body.rb_spinspeed = spin;
	RigidBody_FixMatrix(body);
	return body;
};

void(entity body, vector org) RigidBody_AddPoint =
{
	if (body.rb_numpoints >= 16)
		return;
	body.(rb_points[body.rb_numpoints]) = org;
	body.rb_numpoints = body.rb_numpoints + 1;
};

void(entity body) RigidBody_Remove =
{
	remove(body);
};


