
/*QUAKED info_null (0 0.5 0) (-4 -4 -4) (4 4 4)
Used as a positional target for spotlights, etc.
*/
void() info_null =
{
	remove(self);
};

/*QUAKED info_notnull (0 0.5 0) (-4 -4 -4) (4 4 4)
Used as a positional target for lightning.
*/
void() info_notnull =
{
};

void() misc_teleporter_dest =
{
	info_teleport_destination();
};


void() info_target_train_find =
{
	local entity targ;

	targ = find(world, targetname, self.target);
	self.target = targ.target;
	setorigin (self, targ.origin - self.mins);
	self.nextthink = self.ltime + 0.1;
	self.think = train_next;
};

/*QUAKED info_target (0 0.5 0) (-4 -4 -4) (4 4 4)
Invisible entity. Used as an optional
target for trap_spikeshooter etc,
can follow path_corners as a moving
target for neat effects.

Keys:
"targetname"
 target name.
"target" (optional)
 if specified it will start at
 this path_corner,
 and follow the path.
"speed"
 movement speed (default 100)
*/
void() info_target =
{
	if (self.target)
	{
		if (!self.speed)
			self.speed = 100;
		self.cnt = 1;
		// LordHavoc: this trick requires DarkPlaces engine
		self.solid = SOLID_NOT;
		self.movetype = MOVETYPE_PUSH;
		self.blocked = SUB_Null;
		self.use = SUB_Null;
		self.avelocity = '100 200 300';

		// this is for testing, so you can see the targets
		// precache_model2 ("progs/teleport.mdl");
		// setmodel (self, "progs/teleport.mdl");
		setsize (self, '0 0 0', '0 0 0');
		setorigin (self, self.origin);

		// start trains on the second frame, to make sure their targets have had
		// a chance to spawn
		self.nextthink = self.ltime + 0.1;
		self.think = info_target_train_find;
	}
};
//============================================================================

float START_OFF = 1;

void() light_use =
{
	if ((self.spawnflags & START_OFF) && !darkmode)
	{
		lightstyle(self.style, "m");
		self.spawnflags = self.spawnflags - START_OFF;
	}
	else
	{
		lightstyle(self.style, "a");
		self.spawnflags = self.spawnflags + START_OFF;
	}
};

/*QUAKED light (0 1 0) (-8 -8 -8) (8 8 8) START_OFF
Non-displayed light.
Default light value is 300
Default style is 0
If targeted, it will toggle between on or off.
*/
void() light =
{
	if (!self.targetname)
	{
		// inert light
		remove(self);
		return;
	}

	if (self.style >= 32)
	{
		self.use = light_use;
		if ((self.spawnflags & START_OFF) || darkmode)
			lightstyle(self.style, "a");
		else
			lightstyle(self.style, "m");
	}
};

/*QUAKED light_fluoro (0 1 0) (-8 -8 -8) (8 8 8) START_OFF
Non-displayed light.
Default light value is 300
Default style is 0
If targeted, it will toggle between on or off.
Makes steady fluorescent humming sound
*/
void() light_fluoro =
{
	if (self.style >= 32)
	{
		self.use = light_use;
		if ((self.spawnflags & START_OFF) || darkmode)
			lightstyle(self.style, "a");
		else
			lightstyle(self.style, "m");
	}

	precache_sound ("ambience/fl_hum1.wav");
	ambientsound (self.origin, "ambience/fl_hum1.wav", 0.5, ATTN_STATIC);
	remove(self);
};

/*QUAKED light_fluorospark (0 1 0) (-8 -8 -8) (8 8 8)
Non-displayed light.
Default light value is 300
Default style is 10
Makes sparking, broken fluorescent sound
*/
void() light_fluorospark =
{
	//if (!self.style)
	//	self.style = 10;

	precache_sound ("ambience/buzz1.wav");
	ambientsound (self.origin, "ambience/buzz1.wav", 0.5, ATTN_STATIC);
	remove(self);
};

/*QUAKED light_globe (0 1 0) (-8 -8 -8) (8 8 8)
Sphere globe light.
Default light value is 300
Default style is 0
*/
void() light_globe =
{
	precache_model ("progs/s_light.spr");
	setmodel (self, "progs/s_light.spr");
	makestatic (self);
};

void() FireAmbient =
{
	precache_sound ("ambience/fire1.wav");
	// attenuate fast
	ambientsound (self.origin, "ambience/fire1.wav", 0.5, ATTN_STATIC);
};

/*
void() flameanimloop =
{
	self.nextthink = time + 0.1;
	self.frame = self.frame + 1;
	if (self.frame >= 10)
		self.frame = 0;
};
*/

/*
void(vector org, vector ang) flamepoly =
{
	local entity e;
	e = spawn();
	setorigin(e, org);
	setmodel(e, "progs/torchflametop3.spr32");
	e.angles = ang;
	e.think = flameanimloop;
	e.nextthink = time + 0.1;
};
*/

void() flamespawn =
{
	newmis = spawn();
	setorigin(newmis, self.origin + self.dest + '0 0 -5');
	setmodel(newmis, "progs/torchflamebase.spr32");
	newmis.effects = EF_ADDITIVE;
	newmis.scale = self.scale;
	if (newmis.scale == 1)
		makestatic(newmis);
	//setmodel (self, "progs/torchflamebase.spr32");
	//self.think = flameanimloop;
	//self.nextthink = time + 0.1;
	newmis = spawn();
	setorigin(newmis, self.origin + self.dest);
	setmodel(newmis, "progs/torchflametop.spr32");
	newmis.effects = EF_ADDITIVE;
	newmis.scale = self.scale;
	if (newmis.scale == 1)
		makestatic(newmis);
	//newmis.think = flameanimloop;
	//newmis.nextthink = time + 0.1;
	/*
	setmodel (self, "progs/torchflamebase2.spr32");
	flamepoly(self.origin, '0 0 0');
	flamepoly(self.origin, '0 90 0');
	flamepoly(self.origin, '0 180 0');
	flamepoly(self.origin, '0 270 0');
	*/
	if (self.model)
		makestatic (self);
	else
		remove(self);
};

void() torchflame =
{
	FireAmbient();
	precache_model ("progs/torchflametop.spr32");
	precache_model ("progs/torchflamebase.spr32");
	self.think = flamespawn;
	self.nextthink = time + 0.1;
};

/*QUAKED light_torch_small_walltorch (0 .5 0) (-10 -10 -20) (10 10 20)
Short wall torch
Default light value is 200
Default style is 0
*/
void() light_torch_small_walltorch =
{
	self.dest = '0 0 16';
	torchflame();
	//FireAmbient ();
	precache_model ("progs/flame.mdl");
	setmodel (self, "progs/flame.mdl");
	//makestatic (self);
};

/*QUAKED light_flame_large_yellow (0 1 0) (-10 -10 -12) (12 12 18)
Large yellow flame ball
*/
void() light_flame_large_yellow =
{
	self.scale = 2;
	self.dest = '0 0 16';
	torchflame();
	//FireAmbient ();
	//precache_model ("progs/flame2.mdl");
	//setmodel (self, "progs/flame2.mdl");
	//self.frame = 1;
	////self.effects = EF_ADDITIVE;
	//makestatic (self);
};

/*QUAKED light_flame_small_yellow (0 1 0) (-8 -8 -8) (8 8 8) START_OFF
Small yellow flame ball
*/
void() light_flame_small_yellow =
{
	self.dest = '0 0 0';
	torchflame();
	//FireAmbient ();
	//precache_model ("progs/flame2.mdl");
	//setmodel (self, "progs/flame2.mdl");
	////self.effects = EF_ADDITIVE;
	//makestatic (self);
};

/*QUAKED light_flame_small_white (0 1 0) (-10 -10 -40) (10 10 40) START_OFF
Small white flame ball
*/
void() light_flame_small_white =
{
	self.dest = '0 0 0';
	torchflame();
	//FireAmbient ();
	//precache_model ("progs/flame2.mdl");
	//setmodel (self, "progs/flame2.mdl");
	//self.effects = EF_ADDITIVE;
	//makestatic (self);
};

.float count1, count2, count3, count4, count5, count6, cnt1, cnt2;

void() thunderthink =
{
	local float c;
	self.nextthink = time + 0.05;
	if (time > self.dmg2) // start a strike
	{
		self.cnt2 = time + random()*(self.count6-self.count5)+self.count5;
		self.dmg2 = time + random()*(self.waitmax-self.waitmin)+self.waitmin;
		self.dmg = random()*(self.count1-self.count)+self.count;
	}
	if (time >= self.cnt2) // thunder sound
	{
		self.cnt2 = time + 100000;
		sound(world, CHAN_VOICE, "ambience/thunder1.wav", 1, ATTN_NONE);
		sound(world, CHAN_BODY, "ambience/thunder1.wav", 1, ATTN_NONE);
	}
	if (self.dmg >= 1)
	if (time > self.cnt) // start a flash
	{
		self.dmg = self.dmg - 1;
		self.cnt = time + random()*(self.count3-self.count2)+self.count2;
		self.ltime = time;
	}
	c = 26 - ((time - self.ltime) * 26 / self.count4);
	if (darkmode)
		c = 0;
	if (c < 0) c = 0;
	if (self.lefty != c)
	{
		self.lefty = c;
	if (c <  1) lightstyle(self.style, "a");
		else if (c <  2) lightstyle(self.style, "b");
		else if (c <  3) lightstyle(self.style, "c");
		else if (c <  4) lightstyle(self.style, "d");
		else if (c <  5) lightstyle(self.style, "e");
		else if (c <  6) lightstyle(self.style, "f");
		else if (c <  7) lightstyle(self.style, "g");
		else if (c <  8) lightstyle(self.style, "h");
		else if (c <  9) lightstyle(self.style, "i");
		else if (c < 10) lightstyle(self.style, "j");
		else if (c < 11) lightstyle(self.style, "k");
		else if (c < 12) lightstyle(self.style, "l");
		else if (c < 13) lightstyle(self.style, "m");
		else if (c < 14) lightstyle(self.style, "n");
		else if (c < 15) lightstyle(self.style, "o");
		else if (c < 16) lightstyle(self.style, "p");
		else if (c < 17) lightstyle(self.style, "q");
		else if (c < 18) lightstyle(self.style, "r");
		else if (c < 19) lightstyle(self.style, "s");
		else if (c < 20) lightstyle(self.style, "t");
		else if (c < 21) lightstyle(self.style, "u");
		else if (c < 22) lightstyle(self.style, "v");
		else if (c < 23) lightstyle(self.style, "w");
		else if (c < 24) lightstyle(self.style, "x");
		else if (c < 25) lightstyle(self.style, "y");
		else             lightstyle(self.style, "z");
	}
};

void() thundersetup =
{
	local entity e;
	e = find(world, targetname, self.target);
	if (e.classname != "light")
		objerror("misc_thunder: must target lights");
	self.style = e.style; // grab the light's style
	if (e.style < 32)
		objerror("misc_thunder: light has no style??");
	self.think = thunderthink;
	self.nextthink = time + 0.5;
};

/*QUAKED misc_thunder (0 1 0) (-8 -8 -8) (8 8 8)
This controls the brightness of the
targeted lights, to simulate thunder.

Keys:
"waitmin"
 mininum time between strikes
 (default 1)
"waitmax"
 maximum time between strikes
 (default 8)
"count"
 minimum number of flashs per strike
 (default 2)
"count1"
 maximum number of flashs per strike
 (default 6)
"count2"
 minimum time between flashs
 (default 0.05)
"count3"
 maximum time between flashs
 (default 0.2)
"count4"
 how long each flash lasts
 (default 0.3)
"count5"
 minimum sound delay
 (default 0.3)
"count6"
 maximum sound delay
 (default 0.8)
"target"
 must target lights
*/
void() misc_thunder =
{
	if (!self.target)
		objerror("misc_thunder: must target lights");
	if (!self.waitmin) self.waitmin = 1;
	if (!self.waitmax) self.waitmax = 8;
	if (!self.count ) self.count  = 2;
	if (!self.count1) self.count1 = 6;
	if (!self.count2) self.count2 = 0.05;
	if (!self.count3) self.count3 = 0.2;
	if (!self.count4) self.count4 = 0.3;
	if (!self.count5) self.count5 = 0.3;
	if (!self.count6) self.count6 = 0.8;
	precache_sound ("ambience/thunder1.wav");
	self.think = thundersetup;
	self.nextthink = time + 0.1;
};

//============================================================================


/*QUAKED misc_fireball (0 .5 .8) (-8 -8 -8) (8 8 8)
Lava Balls
*/

void() fire_fly;
void() fire_touch;
void() misc_fireball =
{

	precache_model ("progs/lavaball.mdl");
	self.classname = "fireball";
	self.nextthink = time + (random() * 5);
	self.think = fire_fly;
	if (!self.speed)
		self.speed = 1000;
};

void() fire_fly =
{
	self.think = fire_fly;
	if (serverinactive) // no players
	{
		self.nextthink = time + 15;
		return;
	}
	self.nextthink = time + (random() * 5) + 3;

	newmis = spawn();
	newmis.solid = SOLID_TRIGGER;
	newmis.movetype = MOVETYPE_TOSS;
	newmis.velocity_x = (random() * 100) - 50;
	newmis.velocity_y = (random() * 100) - 50;
	newmis.velocity_z = self.speed + (random() * 200);
	newmis.classname = "newmis";
	setmodel (newmis, "progs/lavaball.mdl");
	setsize (newmis, '0 0 0', '0 0 0');
	setorigin (newmis, self.origin);
	newmis.nextthink = time + 5;
	newmis.think = SUB_Remove;
	newmis.touch = fire_touch;
};


void() fire_touch =
{
	T_Damage (other, self, self, 200, 200, " tasted the spicy lava balls", DT_LAVA, self.origin, '0 0 0', Obituary_Generic);
	remove(self);
};

//============================================================================


void() barrel_explode =
{
	local vector v, v2;
	// these are all kicked by the blast itself, so there is no need for much movement
	v = randompos(self.mins, self.maxs) + self.origin;v2 = randomvec() * 50;ThrowDebris(world, v, v2, "progs/rubble1.mdl", 5);
	v = randompos(self.mins, self.maxs) + self.origin;v2 = randomvec() * 50;ThrowDebris(world, v, v2, "progs/rubble2.mdl", 5);
	v = randompos(self.mins, self.maxs) + self.origin;v2 = randomvec() * 50;ThrowDebris(world, v, v2, "progs/rubble3.mdl", 5);
	v = randompos(self.mins, self.maxs) + self.origin;v2 = randomvec() * 50;ThrowDebris(world, v, v2, "progs/rubble1.mdl", 5);
	v = randompos(self.mins, self.maxs) + self.origin;v2 = randomvec() * 50;ThrowDebris(world, v, v2, "progs/rubble2.mdl", 5);
	v = randompos(self.mins, self.maxs) + self.origin;v2 = randomvec() * 50;ThrowDebris(world, v, v2, "progs/rubble3.mdl", 5);
	SUB_UseTargets();
	setorigin(self, (self.absmin + self.absmax) * 0.5);
	T_RadiusDamage(self, self.owner, self.dmg, self.dmg, self.dmg * 0.5, world, self.deathtype, DT_EXPLOSION, Obituary_Generic);
	BecomeExplosion(self, '0 0 0', FALSE);
};

void() barrel_det =
{
	self.think = barrel_explode;
	self.nextthink = time;
};

void(string netname1, string model1, string deathmessage, float damage) barrel_spawn =
{
	local float oldz;

	precache_model (model1);
	precache_sound ("weapons/r_exp3.wav");

	if (!self.deathtype) // map makers can override this
		self.deathtype = deathmessage;
	if (!self.dmg)
		self.dmg = damage;
	self.netname = netname1;

	self.owner = self;
	self.solid = SOLID_BBOX;
	self.movetype = MOVETYPE_NONE;
	setmodel (self, model1);
	self.health = 20;
	self.th_die = barrel_det;
	self.takedamage = DAMAGE_AIM;
	self.think = SUB_Null;
	self.nextthink = -1;
	self.flags = 0;

	self.origin_z = self.origin_z + 2;
	oldz = self.origin_z;
	droptofloor();
	if (oldz - self.origin_z > 250)
	{
		dprint ("explosive box fell out of level at ");
		dprint (vtos(self.origin));
		dprint ("\n");
		remove(self);
	}
};

/*QUAKED misc_explobox (0 .5 .8) (0 0 0) (32 32 64)
TESTING THING
*/
void() misc_explobox =
{
	barrel_spawn("Large exploding box", "maps/b_explob.bsp", " was blown up by an explosive box", 750);
};

/*QUAKED misc_explobox2 (0 .5 .8) (0 0 0) (32 32 64)
Smaller exploding box, REGISTERED ONLY
*/
void() misc_explobox2 =
{
	barrel_spawn("Small exploding box", "maps/b_exbox2.bsp", " was blown up by an explosive box", 250);
};

//============================================================================

float TRAP_SUPERSPIKE   = 1;
float TRAP_LASER        = 2;
float TRAP_LIGHTNING    = 4;
float TRAP_ONLYSTRIKE   = 128;

.float strikedist;

void() trapspike_shootthink =
{
	self.nextthink = time + self.delay;
	if (self.enemy != world)
		self.dest = normalize(self.enemy.origin - self.origin);
	sound (self, CHAN_VOICE, "weapons/rocket1i.wav", 1, ATTN_NORM);
	launch_spike (self.origin, self.dest * self.speed, self, self.dmg, 0, self.deathtype, Obituary_Generic);
	self.cnt = self.cnt - 1;
	if (self.cnt < 1)
		remove(self);
};

void() trapsuperspike_shootthink =
{
	self.nextthink = time + self.delay;
	if (self.enemy != world)
		self.dest = normalize(self.enemy.origin - self.origin);
	sound (self, CHAN_VOICE, "weapons/spike2.wav", 1, ATTN_NORM);
	launch_spike (self.origin, self.dest * self.speed, self, self.dmg, 0, self.deathtype, Obituary_Generic);
	self.cnt = self.cnt - 1;
	if (self.cnt < 1)
		remove(self);
};

void() traplaser_shootthink =
{
	self.nextthink = time + self.delay;
	if (self.enemy != world)
		self.dest = normalize(self.enemy.origin - self.origin);
	LaunchLaser (self, self.origin, self.dest * self.speed, self.dmg, self.deathtype, Obituary_Generic);
	self.cnt = self.cnt - 1;
	if (self.cnt < 1)
		remove(self);
};

void() traplightning_shootthink =
{
	if (self.enemy == world)        // lightning must have a target
		remove(self);
	self.nextthink = time + self.delay;
	LightningBolt(self.origin, self.enemy.origin, self.dmg, self.deathtype, Obituary_Generic);
	self.cnt = self.cnt - 1;
	if (self.cnt < 1)
		remove(self);
};

void() spikeshooter_use =
{
	local entity targ, head;
	local vector dir;
	local float a, b;
	targ = world;
	dir = self.movedir;
	if (self.target)
	{
		targ = find(world, targetname, self.target);
		if (targ == world)
			dprint("spikeshooter: no target\n");
	}
	a = 0;
	if (self.strikedist)
	{
		b = self.strikedist;
		head = findradius(self.origin, self.strikedist);
		while (head != world)
		{
			if (head.takedamage == DAMAGE_AIM && head != self)
			if (vlen(head.origin - self.origin) < b)
			{
				traceline(self.origin, head.origin, TRUE, world);
				if (trace_fraction >= 1)
				{
					a = 1;
					targ = head;
					b = vlen(head.origin - self.origin);
				}
			}
			head = head.chain;
		}
	}
	if (targ != world)
		dir = normalize(targ.origin - self.origin);
	if ((self.spawnflags & TRAP_ONLYSTRIKE) && !a)
		return;
	newmis = spawn();
	newmis.owner = self;
	setorigin(newmis,self.origin);
	newmis.enemy = targ;
	newmis.dest = dir;
	newmis.dmg = self.dmg;
	newmis.cnt = self.count;
	newmis.speed = self.speed;
	newmis.delay = self.delay;
	newmis.think = trapspike_shootthink;
	newmis.nextthink = time;
	newmis.deathtype = self.deathtype;
	if (self.spawnflags & TRAP_SUPERSPIKE)
		newmis.think = trapsuperspike_shootthink;
	if (self.spawnflags & TRAP_LASER)
		newmis.think = traplaser_shootthink;
	if (self.spawnflags & TRAP_LIGHTNING)
		newmis.think = traplightning_shootthink;
};

void() shooter_think =
{
	spikeshooter_use ();
	self.nextthink = time + self.wait;
};

/*QUAKED trap_spikeshooter (0 .5 .8) (-8 -8 -8) (8 8 8) superspike laser lightning x x x x onlystrike
When triggered, fires a spike in
the direction determined by angle.

Flags:
"superspike"
 fires large spikes
"laser"
 fires laser
"lightning"
 fires lightning
 (only fires with a target,
  either an info_target or when
  striking something)
"onlystrike"
 does not fire unless striking
 at something

Keys:
"deathtype"
 as with nearly all things in
 Dark Places, deathtype is
 the kill message.
 default: depends on shot type
"angle"
 angle to fire
 (can be pitch yaw roll)
"target"
 much better than angle setting.
"speed"
 speed of shot - default 500
 (not applicable to lightning)
"dmg"
 how much damage the shot does
 default depends on shot:
 spike - 9
 superspike - 18
 laser - 15
 lightning - 30
"count"
 how many shots are fired per
 burst.
"delay"
 time between shots in a burst.
"strikedist"
 max distance for striking.
 (meaning it acts as a turret)
*/

void() trap_spikeshooter =
{
	SetMovedir ();
	self.use = spikeshooter_use;
	if (!self.delay)
		self.delay = 0.2;
	if (!self.count)
		self.count = 1;
	if (!self.speed)
		self.speed = 500;
	if (self.spawnflags & TRAP_SUPERSPIKE)
	{
		precache_model ("progs/s_spike.mdl");
		precache_sound ("weapons/spike2.wav");
		if (!self.dmg)
			self.dmg = 18;
		if (!self.deathtype)
			self.deathtype = " was super spiked";
	}
	else if (self.spawnflags & TRAP_LASER)
	{
		precache_model ("progs/laser.mdl");
		precache_sound ("enforcer/enfire.wav");
		precache_sound ("enforcer/enfstop.wav");
		if (!self.dmg)
			self.dmg = 15;
		if (!self.deathtype)
			self.deathtype = " was fried by a laser";
	}
	else if (self.spawnflags & TRAP_LIGHTNING)
	{
		precache_sound ("weapons/lhit.wav");
		if (!self.dmg)
			self.dmg = 30;
		if (!self.deathtype)
			self.deathtype = " was shocked";
	}
	else
	{
		precache_model ("progs/spike.mdl");
		precache_sound ("weapons/rocket1i.wav");
		if (!self.dmg)
			self.dmg = 9;
		if (!self.deathtype)
			self.deathtype = " was spiked";
	}
};

/*QUAKED trap_shooter (0 .5 .8) (-8 -8 -8) (8 8 8) superspike laser lightning x x x x onlystrike
Continuously fires spikes.

Flags:
"superspike"
 fires large spikes
"laser"
 fires laser
"lightning"
 fires lightning
 (only fires with a target,
  either an info_target or when
  striking something)
"onlystrike"
 does not fire unless striking
 at something

Keys:
"deathtype"
 as with nearly all things in
 Dark Places, deathtype is
 the kill message.
 default: depends on shot type
"angle"
 angle to fire
 (can be pitch yaw roll)
"target"
 much better than angle setting.
"speed"
 speed of shot - default 500
 (not applicable to lightning)
"dmg"
 how much damage the shot does
 default depends on shot:
 spike - 9
 superspike - 18
 laser - 15
 lightning - 30
"count"
 how many shots are fired per
 burst.
"delay"
 time between shots in a burst.
"strikedist"
 max distance for striking.
 (meaning it acts as a turret)
"wait"
 delay between start of bursts.
 (not the time between bursts,
  but the time between the
  start of each burst)
*/

void() trap_shooter =
{
	trap_spikeshooter ();

	if (self.wait == 0)
		self.wait = 1;
	self.nextthink = self.nextthink + self.wait + self.ltime;
	self.think = shooter_think;
};

/*
===============================================================================


===============================================================================
*/


void() make_bubbles;

/*QUAKED air_bubbles (0 .5 .8) (-8 -8 -8) (8 8 8)
testing air bubbles
*/

void() air_bubbles =
{
	if (deathmatch)
	{
		remove (self);
		return;
	}
	precache_model ("progs/s_bubble.spr");
	self.nextthink = time + 1;
	self.think = make_bubbles;
};

void() make_bubbles =
{
	makebubble(self.origin, '0 0 15', 0);
	self.nextthink = time + random() + 0.5;
	self.think = make_bubbles;
};

/*~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>
~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~*/

/*QUAKED viewthing (0 .5 .8) (-8 -8 -8) (8 8 8)
Just for the debugging level.  Don't use
*/

void() viewthing =
{
	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_NOT;
	precache_model ("progs/player.mdl");
	setorigin(self, self.origin);
	setmodel(self, "progs/player.mdl");
};


/*
==============================================================================

SIMPLE BMODELS

==============================================================================
*/

void() func_wall_use =
{
	// change to alternate textures
	self.frame = 1 - self.frame;
};

/*QUAKED func_wall (0 .5 .8) ?
This is just a solid wall if not inhibitted
*/
void() func_wall =
{
	self.angles = '0 0 0';
	self.movetype = MOVETYPE_PUSH;	// so it doesn't get pushed by anything
	self.solid = SOLID_BSP;
	self.use = func_wall_use;
	setmodel (self, self.model);
	/*
	self.think = SUB_Null;
	self.nextthink = 999999999;
	if (self.avelocity)
	{
		self.mins = '-10000 -10000 -10000';
		self.maxs = '10000 10000 10000';
	}
	*/
};

/*QUAKED func_vanishwall (0 .5 .8) ?
Mainly used for changing the 'scale' of a
dm level based on active player count.

For use in combination with
trigger_playercount.

Keys:
"targetname"
 removes self when triggered.
*/
void() func_vanishwall =
{
	self.use = SUB_Remove;
	self.angles = '0 0 0';
	self.movetype = MOVETYPE_PUSH;  // so it doesn't get pushed by anything
	self.solid = SOLID_BSP;
	setmodel (self, self.model);
};

/*QUAKED func_illusionary (0 .5 .8) ?
A simple entity that looks solid but lets you walk through it.
*/
void() func_illusionary =
{
	self.angles = '0 0 0';
	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_NOT;
	setmodel (self, self.model);
	makestatic (self);
};

/*QUAKED func_episodegate (0 .5 .8) ? E1 E2 E3 E4
This bmodel will appear if the episode has allready been completed, so players can't reenter it.
*/
void() func_episodegate =
{
	if (!(serverflags & self.spawnflags))
		return;			// can still enter episode

	self.angles = '0 0 0';
	self.movetype = MOVETYPE_PUSH;	// so it doesn't get pushed by anything
	self.solid = SOLID_BSP;
	self.use = func_wall_use;
	setmodel (self, self.model);
};

/*QUAKED func_bossgate (0 .5 .8) ?
This bmodel appears unless players have all of the episode sigils.
*/
void() func_bossgate =
{
	if ((serverflags & 15) == 15)
		return;		// all episodes completed
	self.angles = '0 0 0';
	self.movetype = MOVETYPE_PUSH;	// so it doesn't get pushed by anything
	self.solid = SOLID_BSP;
	self.use = func_wall_use;
	setmodel (self, self.model);
};

//============================================================================
/*QUAKED ambient_suck_wind (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_suck_wind =
{
	precache_sound ("ambience/suck1.wav");
	ambientsound (self.origin, "ambience/suck1.wav", 1, ATTN_STATIC);
	remove(self);
};

/*QUAKED ambient_drone (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_drone =
{
	precache_sound ("ambience/drone6.wav");
	ambientsound (self.origin, "ambience/drone6.wav", 0.5, ATTN_STATIC);
	remove(self);
};

/*QUAKED ambient_flouro_buzz (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_flouro_buzz =
{
	precache_sound ("ambience/buzz1.wav");
	ambientsound (self.origin, "ambience/buzz1.wav", 1, ATTN_STATIC);
	remove(self);
};
/*QUAKED ambient_drip (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_drip =
{
	precache_sound ("ambience/drip1.wav");
	ambientsound (self.origin, "ambience/drip1.wav", 0.5, ATTN_STATIC);
	remove(self);
};
/*QUAKED ambient_comp_hum (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_comp_hum =
{
	precache_sound ("ambience/comp1.wav");
	ambientsound (self.origin, "ambience/comp1.wav", 1, ATTN_STATIC);
	remove(self);
};
/*QUAKED ambient_thunder (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_thunder =
{
	precache_sound ("ambience/thunder1.wav");
	ambientsound (self.origin, "ambience/thunder1.wav", 0.5, ATTN_STATIC);
	remove(self);
};
/*QUAKED ambient_light_buzz (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_light_buzz =
{
	precache_sound ("ambience/fl_hum1.wav");
	ambientsound (self.origin, "ambience/fl_hum1.wav", 0.5, ATTN_STATIC);
	remove(self);
};
/*QUAKED ambient_swamp1 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_swamp1 =
{
	precache_sound ("ambience/swamp1.wav");
	ambientsound (self.origin, "ambience/swamp1.wav", 0.5, ATTN_STATIC);
	remove(self);
};
/*QUAKED ambient_swamp2 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_swamp2 =
{
	precache_sound ("ambience/swamp2.wav");
	ambientsound (self.origin, "ambience/swamp2.wav", 0.5, ATTN_STATIC);
	remove(self);
};

//============================================================================

void() noise_think =
{
	self.nextthink = time + 0.5;
	sound (self, 1, "enforcer/enfire.wav", 1, ATTN_NORM);
	sound (self, 2, "enforcer/enfstop.wav", 1, ATTN_NORM);
	sound (self, 3, "enforcer/sight1.wav", 1, ATTN_NORM);
	sound (self, 4, "enforcer/sight2.wav", 1, ATTN_NORM);
	sound (self, 5, "enforcer/sight3.wav", 1, ATTN_NORM);
	sound (self, 6, "enforcer/sight4.wav", 1, ATTN_NORM);
	sound (self, 7, "enforcer/pain1.wav", 1, ATTN_NORM);
};

/*QUAKED misc_noisemaker (1 0.5 0) (-10 -10 -10) (10 10 10)
For optimzation testing, starts a lot of sounds.
*/

void() misc_noisemaker =
{
	precache_sound2 ("enforcer/enfire.wav");
	precache_sound2 ("enforcer/enfstop.wav");
	precache_sound2 ("enforcer/sight1.wav");
	precache_sound2 ("enforcer/sight2.wav");
	precache_sound2 ("enforcer/sight3.wav");
	precache_sound2 ("enforcer/sight4.wav");
	precache_sound2 ("enforcer/pain1.wav");
	precache_sound2 ("enforcer/pain2.wav");
	precache_sound2 ("enforcer/death1.wav");
	precache_sound2 ("enforcer/idle1.wav");

	self.nextthink = time + 0.1 + random();
	self.think = noise_think;
};

// TODO: Nexuiz stuff

