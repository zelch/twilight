
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
void() bubble_bob;

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

void() bubble_split =
{
	makebubble(self.origin, self.velocity, 1);
	self.frame = 1;
	self.cnt = 10;
};

void() bubble_bob =
{
	local float p;
	local vector v;

	// I added this, so bubbles won't go up through floors etc (much)
	p = pointcontents(self.origin);
	if ((p != CONTENT_WATER) && (p != CONTENT_SLIME))
	{
		remove(self);
		return;
	}

	self.cnt = self.cnt + 1;
	if (self.cnt == 4)
		bubble_split();
	if (self.cnt == 20)
	{
		remove(self);
		return;         // I added this return
	}

	v = self.velocity + randompos('-10 -10 10', '10 10 20');

	if (v_x > 10)
		v_x = 5;
	if (v_x < -10)
		v_x = -5;

	if (v_y > 10)
		v_y = 5;
	if (v_y < -10)
		v_y = -5;

	if (v_z < 10)
		v_z = 15;
	if (v_z > 30)
		v_z = 25;

	self.velocity = v;

	self.think = bubble_bob;
	self.nextthink = time + 0.5;
};

// original: vel '0 0 15' size 0
// split: vel current size 1
void(vector org, vector vel, float bubblesize) makebubble =
{
	if (game == GAME_NEXUIZ)
		return;
	newmis = spawn();
	setmodel (newmis, "progs/s_bubble.spr");
	setorigin (newmis, org);
	newmis.movetype = MOVETYPE_NOCLIP;
	newmis.solid = SOLID_NOT;
	newmis.velocity = vel;
	newmis.think = bubble_bob;
	newmis.nextthink = time + 0.5;
	newmis.touch = SUB_Remove;
	newmis.classname = "bubble";
	newmis.frame = bubblesize;
	if (bubblesize)
		newmis.cnt = 10; // no splitting
	else
		newmis.cnt = 0; // split once
	setsize (newmis, '-8 -8 -8', '8 8 8');
}

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


float SHAKE_SILENT     = 2;
float SHAKE_STARTON    = 4;
float SHAKE_TOGGLE     = 8;

void() shaketouch =
{
	local vector v;
	if (!self.weapon) // is it active
		return;
	if (other.flags & FL_ONGROUND)
	if (other.movetype == MOVETYPE_WALK || other.movetype == MOVETYPE_STEP)
	{
	//         other.earthquaketime = time + 0.2;
		self.flags = self.flags - FL_ONGROUND;
		v_x = crandom();
		v_y = crandom();
		v_z = 4;
		v = normalize(v);
		other.velocity = other.velocity + v * (random() * 150);
	}
};

void() shakethink =
{
	self.nextthink = time + 0.1;
	if (!(self.spawnflags & SHAKE_TOGGLE))
	{
		if (time < self.wait)
		{
			if (self.spawnflags & SHAKE_STARTON)
				self.weapon = 0;
			else
				self.weapon = 1;
		}
		else
		{
			if (self.spawnflags & SHAKE_STARTON)
				self.weapon = 1;
			else
				self.weapon = 0;
		}
	}
	if (!self.weapon) // is it active
		return;
	force_retouch = 2;      // hit even non-moving objects
};

void() shakeuse =
{
	if (self.spawnflags & SHAKE_TOGGLE)
	{
		self.weapon = !self.weapon;
		return;
	}
	if (self.spawnflags & SHAKE_STARTON)
		self.weapon = 0;
	else
		self.weapon = 1;
	self.wait = time + self.delay;
};

/*QUAKED trigger_shake (1 .5 0) ? PLAYERONLY SILENT STARTON TOGGLE
any player touching this feels an earthquake.

when targeted it will flash on/off
see STARTON, TOGGLE and delay

flags:
"PLAYERONLY"
 only affects players.
"SILENT"
 no sound.
"STARTON"
 works in reverse, normally on, off when targeted.
"TOGGLE"
 switches on/off when targeted.

keys:
"delay"
 how long it will stay switched when
 targeted, ignored with TOGGLE.
"targetname"
 guess (flashes/toggles when targeted)
*/
void() trigger_shake =
{
	InitTrigger();
	self.touch = shaketouch;
	self.think = shakethink;
	self.nextthink = time + 0.1;
	self.use = shakeuse;
	/* need a earthquake sound
	if (!(self.spawnflags & SHAKE_SILENT))
		precache_sound ("ambience/fl_hum1.wav");
	*/
	self.wait = 0;
	self.weapon = 0; // start inactive
	if (self.spawnflags & SHAKE_STARTON)
		self.weapon = 1; // oh, turn it on then
};


float INVISIBLEWALL_STARTOFF  =       1;

void() invisiblewall_use =
{
	if (self.solid == SOLID_BSP)
	{
		self.solid = SOLID_NOT;
		self.movetype = MOVETYPE_NONE;
	}
	else
	{
		self.solid = SOLID_BSP;
		self.movetype = MOVETYPE_PUSH;
	}
};

/*QUAKED func_invisiblewall (0 .5 .8) ? STARTOFF
invisible wall,
toggles on/off when triggered.

better than invisible walls
made with CLIP texture
as bullets etc can't go
through this.

Flags:
"STARTOFF"
 uh, guess...
*/

void() func_invisiblewall =
{
	setmodel (self, self.model);    // set size and link into world
	self.model = "";                // make it invisible
	self.use = invisiblewall_use;
	self.solid = SOLID_BSP; // make it solid
	self.movetype = MOVETYPE_PUSH;
	if (self.spawnflags & INVISIBLEWALL_STARTOFF)
	{
		self.solid = SOLID_NOT; // oh, turn it off
		self.movetype = MOVETYPE_NONE;
	}
};

void() rain_think =
{
	self.nextthink = time + 0.1;
	te_particlerain(self.absmin, self.absmax, self.dest, self.count, self.cnt);
//	te_particlesnow(self.absmin, self.absmax, self.dest * 0.25, self.count, self.cnt);
//	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
//	WriteByte (MSG_BROADCAST, TE_PARTICLERAIN);
//	WriteVec (MSG_BROADCAST, self.absmin);
//	WriteVec (MSG_BROADCAST, self.absmax);
//	WriteVec (MSG_BROADCAST, self.dest);
//	WriteShort (MSG_BROADCAST, self.count);
//	WriteByte (MSG_BROADCAST, self.cnt);
};

/*QUAKED func_rain (0 .5 .8) ?
This is an invisible area like a trigger, which rain falls inside of.

Keys:
"velocity"
 falling direction (should be something like '0 0 -700', use the X and Y velocity for wind)
"cnt"
 sets color of rain (default 12 - white)
"count"
 adjusts rain density, this many particles fall every second, experiment to see the effects (default is based on area size)
*/
void() func_rain =
{
	self.dest = self.velocity;
	self.velocity = '0 0 0';
	if (!self.dest)
		self.dest = '0 0 -700';
	self.angles = '0 0 0';
	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_NOT;
	setmodel(self, self.model);
	setorigin(self, self.origin);
	setsize(self, self.mins, self.maxs);
	self.model = "";
	if (!self.cnt)
		self.cnt = 12;
	if (!self.count)
		self.count = (self.absmax_x - self.absmin_x)*(self.absmax_y - self.absmin_y)/8192;
	if (self.count < 1)
	{
		remove(self);
		return;
	}
	// convert from per second to per 0.1 sec,
	self.count = ceil(self.count * 0.1);
	self.think = rain_think;
	self.nextthink = time + 0.5;
};

void() snow_think =
{
	self.nextthink = time + 0.1;
	te_particlesnow(self.absmin, self.absmax, self.dest, self.count, self.cnt);
//	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
//	WriteByte (MSG_BROADCAST, TE_PARTICLESNOW);
//	WriteVec (MSG_BROADCAST, self.absmin);
//	WriteVec (MSG_BROADCAST, self.absmax);
//	WriteVec (MSG_BROADCAST, self.dest);
//	WriteShort (MSG_BROADCAST, self.count);
//	WriteByte (MSG_BROADCAST, self.cnt);
};

/*QUAKED func_snow (0 .5 .8) ?
This is an invisible area like a trigger, which snow falls inside of.

Keys:
"velocity"
 falling direction (should be something like '0 0 -300', use the X and Y velocity for wind)
"cnt"
 sets color of rain (default 12 - white)
"count"
 adjusts snow density, this many particles fall every second, experiment to see the effects (default is based on area size)
*/
void() func_snow =
{
	self.dest = self.velocity;
	self.velocity = '0 0 0';
	if (!self.dest)
		self.dest = '0 0 -300';
	self.angles = '0 0 0';
	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_NOT;
	setmodel(self, self.model);
	setorigin(self, self.origin);
	setsize(self, self.mins, self.maxs);
	self.model = "";
	if (!self.cnt)
		self.cnt = 12;
	if (!self.count)
		self.count = (self.absmax_x - self.absmin_x)*(self.absmax_y - self.absmin_y)/8192;
	if (self.count < 1)
	{
		remove(self);
		return;
	}
	// convert from per second to per 0.1 sec,
	self.count = ceil(self.count * 0.1);
	self.think = snow_think;
	self.nextthink = time + 0.5;
};

void() particlecube_think =
{
	self.nextthink = time + 0.1;
	te_particlecube(self.absmin, self.absmax, self.dest, self.count, self.cnt, (self.spawnflags & 1) != 0, self.cnt2);
//	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
//	WriteByte (MSG_BROADCAST, TE_PARTICLECUBE);
//	WriteVec (MSG_BROADCAST, self.absmin);
//	WriteVec (MSG_BROADCAST, self.absmax);
//	WriteVec (MSG_BROADCAST, self.dest);
//	WriteShort (MSG_BROADCAST, self.count);
//	WriteByte (MSG_BROADCAST, self.cnt);
//	if (self.spawnflags & 1)
//		WriteByte (MSG_BROADCAST, 1);
//	else
//		WriteByte (MSG_BROADCAST, 0);
//	WriteCoord (MSG_BROADCAST, self.cnt2);
};

/*QUAKED func_particlecube (0 .5 .8) ? GRAVITY
This is an invisible area like a trigger, which particles spawn in.

Flags:
gravity
 if set the particles will fall.

Keys:
"velocity"
 particle velocity. (default is '0 0 0)
"cnt"
 sets color of particles (default 12 - white), the colors are actually a range of 4 colors, starting with this color.
"count"
 adjusts particle density, this many particles appear every second, experiment to see the effects (default is based on area size).
"cnt2"
 random velocity adjustment, default is 0, higher makes the particles more random, 0 makes them follow velocity exactly.
*/
void() func_particlecube =
{
	self.dest = self.velocity;
	self.velocity = '0 0 0';
	self.angles = '0 0 0';
	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_NOT;
	setmodel(self, self.model);
	setorigin(self, self.origin);
	setsize(self, self.mins, self.maxs);
	self.model = "";
	if (!self.cnt)
		self.cnt = 12;
	if (!self.count)
		self.count = (self.absmax_x - self.absmin_x)*(self.absmax_y - self.absmin_y)*(self.absmax_z - self.absmin_z)/65536;
	if (self.count < 1)
	{
		remove(self);
		return;
	}
	if (self.spawnflags & 1)
		self.lefty = 1;
	// convert from per second to per 0.1 sec,
	// and round up to nearest multiple of 4
	self.count = ((self.count * 0.1) + 3) & 65532;
	self.think = particlecube_think;
	self.nextthink = time + 0.5;
};


/*
Exploding Walls
*/

float XWALL_NOHEAL = 1;
float XWALL_SILVERKEY = 2;
float XWALL_GOLDKEY = 4;

void() xwall_break;
void() xwall_heal;
void() xwall_keytouch;

void() xwall_respawn =
{
	self.solid = SOLID_BSP;
	self.movetype = MOVETYPE_PUSH;
	setorigin (self, self.origin);
	setmodel (self, self.mdl);

	self.use = xwall_break;
	if (self.max_health >= 1)
	{
		self.takedamage = DAMAGE_YES;
		self.th_die = xwall_break;
		if (self.spawnflags & XWALL_NOHEAL)
			self.th_pain = SUB_Null;
		else
			self.th_pain = xwall_heal;
	}
	else
		self.takedamage = DAMAGE_NO;

	if (self.items)
		self.touch = xwall_keytouch;
	else
		self.touch = SUB_Null;
};

void() xwall_hidethink;

void() xwall_breakthink =
{
	local float t, r, t2, t3;
	local vector v, v2;
	local entity ts;
	self.think = xwall_breakthink;
	self.nextthink = time + self.owner.delay;
	t = 0; // give up the search after 20 failures
	while (t < 20)
	{
		v = randompos(self.absmin, self.absmax);
		t = t + 1;
		if (pointcontents(v) != CONTENT_SOLID) // found a spot
			t = 1000000;
	}

	t3 = TRUE; // pick a new location for each piece of rubble
	if (self.cnt2 > 0)
	{
		t3 = FALSE; // spawn rubble from each explosion
		self.cnt2 = self.cnt2 - 1;
		newmis = spawn();
		newmis.owner = self.owner;
		setorigin(newmis, v);
		T_RadiusDamage(newmis, newmis.owner, newmis.owner.dmg, newmis.owner.dmg, newmis.owner.dmg, world, self.deathtype, DT_EXPLOSION, Obituary_Generic);
		BecomeExplosion(newmis, '0 0 0', FALSE);
	}
	t2 = floor(self.cnt);
	self.cnt = self.cnt + self.count;
	r = floor(random()*3);
	while (t2 < self.cnt)
	{
		t2 = t2 + 1;
		if (t3) // pick a new location for each piece of rubble
		{
			t = 0; // give up the search after 20 failures
			while (t < 20)
			{
				v = randompos(self.absmin, self.absmax);
				t = t + 1;
				if (pointcontents(v) != CONTENT_SOLID) // found a spot
					t = 1000000;
			}
		}
		v2 = randomvec() * (self.owner.dmg + 20) * 3 + '0 0 120';
		if (r == 0) ThrowDebris(world, v, v2, "progs/rubble1.mdl", self.owner.style);
		if (r == 1) ThrowDebris(world, v, v2, "progs/rubble2.mdl", self.owner.style);
		if (r == 2) ThrowDebris(world, v, v2, "progs/rubble3.mdl", self.owner.style);
		r = r + 1;
		if (r >= 3)
			r = 0;
	}
	if (self.cnt2 < 1)
	{
		ts = self;
		self = self.owner;
		if (self.use == SUB_Null)
		xwall_hidethink();
		self = ts;
		remove(self);
	}
};

void() xwall_hidethink =
{
	SUB_UseTargets();
	self.solid = SOLID_NOT;
	self.movetype = MOVETYPE_NONE;
	setorigin(self, self.origin); // relink
	self.model = "";
	self.modelindex = 0;
	self.think = xwall_respawn;
	if (self.wait > 0)
		self.nextthink = time + self.wait;
	else
		remove(self);
};

void() xwall_break =
{
	local entity e;
	if (self.use == SUB_Null)
		return;
	e = spawn();
	e.owner = self;
	e.solid = SOLID_NOT;
	e.movetype = MOVETYPE_NONE;
	setorigin(e, '0 0 0');
	setsize(e, self.absmin - '16 16 16', self.absmax + '16 16 16');
	e.think = xwall_breakthink;
	e.nextthink = time + 0.1;
	e.cnt = 0;
	e.cnt2 = self.count2;
	e.count = self.count;
	e.count2 = self.count2;
	self.think = xwall_hidethink;
	self.nextthink = time + (self.delay * self.count2);
	self.takedamage = DAMAGE_NO;
	self.th_pain = SUB_Null;
	self.th_die = SUB_Null;
	self.touch = SUB_Null;
	self.use = SUB_Null;
};


void() xwall_heal =
{
	self.health = self.max_health;
};

void() xwall_keytouch =
{
	if (!self.items)
		return;
	if (time < self.lefty) // uh, didn't want to add a new entity field
		return;
	self.lefty = time + 2;
	if (other.classname != "player")
		return;

	// FIXME: blink key on player's status bar
	if ( (self.items & other.items) != self.items )
	{
		if (self.items == IT_KEY1)
		{
			if (world.worldtype == 2)
			{
				if (other.flags & FL_CLIENT)
					centerprint (other, "You need the silver keycard");
				sound (self, CHAN_VOICE, self.noise3, 1, ATTN_NORM);
			}
			else if (world.worldtype == 1)
			{
				if (other.flags & FL_CLIENT)
					centerprint (other, "You need the silver runekey");
				sound (self, CHAN_VOICE, self.noise3, 1, ATTN_NORM);
			}
			else if (world.worldtype == 0)
			{
				if (other.flags & FL_CLIENT)
					centerprint (other, "You need the silver key");
				sound (self, CHAN_VOICE, self.noise3, 1, ATTN_NORM);
			}
			else if (world.worldtype == 5)
			{
				if (other.flags & FL_CLIENT)
					centerprint (other, "You need the silver keycard");
				sound (self, CHAN_VOICE, self.noise3, 1, ATTN_NORM);
			}
			else if (world.worldtype == 4)
			{
				if (other.flags & FL_CLIENT)
					centerprint (other, "You need the silver runekey");
				sound (self, CHAN_VOICE, self.noise3, 1, ATTN_NORM);
			}
			else if (world.worldtype == 3)
			{
				if (other.flags & FL_CLIENT)
					centerprint (other, "You need the silver key");
				sound (self, CHAN_VOICE, self.noise3, 1, ATTN_NORM);
			}
		}
		else
		{
			if (world.worldtype == 2)
			{
				if (other.flags & FL_CLIENT)
					centerprint (other, "You need the gold keycard");
				sound (self, CHAN_VOICE, self.noise3, 1, ATTN_NORM);
			}
			else if (world.worldtype == 1)
			{
				if (other.flags & FL_CLIENT)
					centerprint (other, "You need the gold runekey");
				sound (self, CHAN_VOICE, self.noise3, 1, ATTN_NORM);
			}
			else if (world.worldtype == 0)
			{
				if (other.flags & FL_CLIENT)
					centerprint (other, "You need the gold key");
				sound (self, CHAN_VOICE, self.noise3, 1, ATTN_NORM);
			}
			if (world.worldtype == 5)
			{
				if (other.flags & FL_CLIENT)
					centerprint (other, "You need the gold keycard");
				sound (self, CHAN_VOICE, self.noise3, 1, ATTN_NORM);
			}
			else if (world.worldtype == 4)
			{
				if (other.flags & FL_CLIENT)
					centerprint (other, "You need the gold runekey");
				sound (self, CHAN_VOICE, self.noise3, 1, ATTN_NORM);
			}
			else if (world.worldtype == 3)
			{
				if (other.flags & FL_CLIENT)
					centerprint (other, "You need the gold key");
				sound (self, CHAN_VOICE, self.noise3, 1, ATTN_NORM);
			}
		}
		return;
	}

	// take away 1 key
	if (self.items == IT_KEY1 && other.keys_silver > 0)
		other.keys_silver = other.keys_silver - 1;
	if (self.items == IT_KEY2 && other.keys_gold > 0)
		other.keys_gold = other.keys_gold - 1;

	// kill the key on scorebar if the player is now out of keys
	if (other.keys_silver < 1)
		other.items = other.items - (other.items & IT_KEY1);
	if (other.keys_gold < 1)
		other.items = other.items - (other.items & IT_KEY2);

	self.touch = SUB_Null;

	sound (self, CHAN_VOICE, self.noise4, 1, ATTN_NORM);

	xwall_break ();
};

/*
=============================================================================

SPAWNING FUNCTIONS

=============================================================================
*/

/*QUAKED func_xplowall (0 .5 .8) ? NoHeal SilverKey GoldKey

Normally you must do enough damage
in one blast to break the wall.

Flags:
"NoHeal"
 progressive damage will break
 this wall.
"SilverKey"
 will break if touched by player
 with silver key.
"GoldKey"
 will break if touched by player
 with gold key.

Keys:
"targetname"
 will break if targeted.
"target"
 will trigger when destroyed.
"health"
 if health is -1 then can only be
 broken by targeting and keys,
 default 100
 (close pipebomb will break).
"dmg"
 explosions do this much radius
 damage if set.
"count"
 how many pieces of debris
 (releases this much debris
  total, some every explosion)
 (default is 5, -1 for no debris)
"count2"
 how many explosions
 (will release debris with none)
 (default is 3, use -1 for none)
"delay"
 time between explosions
 default: 0.1
"wait"
 time before respawning
 (default is no respawn)
 (this time is counted from the
  last explosion)
"style"
 type of debris,
 hard to describe these:
0) red
1) yellow
2) green
3) blue
4) brown
5) biege
6) rock
*/

void() func_xplowall =
{
	if (!self.deathtype) // map makers can override this
		self.deathtype = " was splattered by a wall";
	if (!self.count)
		self.count = 5;
	if (!self.count2)
		self.count2 = 5;
	if (self.delay < 0.1)
		self.delay = 0.1;
	if (!self.health)
		self.health = 100;

	if (self.count2 >= 1)
		self.count = self.count / self.count2;

	precache_sound ("weapons/r_exp3.wav");
	precache_model ("progs/rubble1.mdl");
	precache_model ("progs/rubble2.mdl");
	precache_model ("progs/rubble3.mdl");

	self.mdl = self.model;
	self.max_health = self.health;

	if (self.spawnflags & XWALL_SILVERKEY)
		self.items = IT_KEY1;
	if (self.spawnflags & XWALL_GOLDKEY)
		self.items = IT_KEY2;
	if (self.items)
	if (game != GAME_NEXUIZ)
	{
		if (world.worldtype == 0)
		{
			precache_sound ("doors/medtry.wav");
			precache_sound ("doors/meduse.wav");
			self.noise3 = "doors/medtry.wav";
			self.noise4 = "doors/meduse.wav";
		}
		else if (world.worldtype == 1)
		{
			precache_sound ("doors/runetry.wav");
			precache_sound ("doors/runeuse.wav");
			self.noise3 = "doors/runetry.wav";
			self.noise4 = "doors/runeuse.wav";
		}
		else if (world.worldtype == 2)
		{
			precache_sound ("doors/basetry.wav");
			precache_sound ("doors/baseuse.wav");
			self.noise3 = "doors/basetry.wav";
			self.noise4 = "doors/baseuse.wav";
		}
		else if (world.worldtype == 3)
		{
			precache_sound ("doors/medtry.wav");
			precache_sound ("doors/meduse.wav");
			self.noise3 = "doors/medtry.wav";
			self.noise4 = "doors/meduse.wav";
		}
		else if (world.worldtype == 4)
		{
			precache_sound ("doors/runetry.wav");
			precache_sound ("doors/runeuse.wav");
			self.noise3 = "doors/runetry.wav";
			self.noise4 = "doors/runeuse.wav";
		}
		else if (world.worldtype == 5)
		{
			precache_sound ("doors/basetry.wav");
			precache_sound ("doors/baseuse.wav");
			self.noise3 = "doors/basetry.wav";
			self.noise4 = "doors/baseuse.wav";
		}
		else
			dprint ("no worldtype set!\n");
	}

	xwall_respawn();
};

/*QUAKED func_wallchunk (0 .5 .8) ?
wall chunk, destroyed by damage.

you must do enough damage
in one blast to break the wall.

simply a nice effect,
used in Dark Places maps.

make a hole in the wall,
cover it with a
func_wallchunk,
set the style for debris,
and you've got a wall that
gets damaged in a fight.

actually just a simplified
func_xplowall.

normally 3 pieces of debris.
set count to a dif # if you
like.
no explosions.

Keys:
"count"
 how many pieces of debris.
 default is 3.
"style"
 type of debris,
 hard to describe these:
0) red
1) yellow
2) green
3) blue
4) brown
5) biege
6) rock
*/

void() func_wallchunk =
{
	self.spawnflags = XWALL_NOHEAL;
	if (self.count == 0)
		self.count = 5;
	self.count2 = -1;
	self.health = 150;
	func_xplowall();
};




float FORCEFIELD_PLAYERONLY   = 1;
float FORCEFIELD_SILENT       = 2;
float FORCEFIELD_STARTOFF     = 4;
float FORCEFIELD_TOGGLE       = 8;
float FORCEFIELD_WALL         = 16;

void(vector org, float p) forcefieldflash =
{
	self.frame = 1;
	if (time > self.fly_sound && !(self.spawnflags & FORCEFIELD_SILENT))
	{
		self.fly_sound = time + 0.6;
		xplo = spawn();
		xplo.think = SUB_Remove;
		xplo.nextthink = time + 0.1;
		setorigin(xplo, org);
		sound (xplo, CHAN_AUTO, "weapons/lhit.wav", 1, ATTN_NORM);
	}
	self.alpha = 0.5;
};

void(entity attacker, float take) forcefieldpain =
{
	self.health = 99999999;
	forcefieldflash(self.absmin + self.absmax * 0.5, take);
};

void() forcefieldtouch =
{
	local vector v1, v2, v;
	if (other.takedamage)
		self.enemy = other;
	if (!self.weapon) // is it active
		return;
	if (time < self.dmgtime)
		return;
	if (other.movetype != MOVETYPE_NONE && other.movetype != MOVETYPE_PUSH)
	{
		if (self.spawnflags & FORCEFIELD_PLAYERONLY)
		if (other.classname != "player")
			return;
		self.dmgtime = time + 0.1;
		forcefieldflash(other.origin, 20);
		// FIXME: this would be a lot more sane if we knew what plane normal was involved in the collision
		v1 = (other.absmin + other.absmax) * 0.5;
		v2 = (self.absmin + self.absmax) * 0.5;
		v = normalize(v1 - v2) * self.speed;
		T_Damage(other, self, self, self.dmg, self.dmg, self.deathtype, DT_LIGHTNING, other.origin, v, Obituary_Generic);
		SUB_UseTargets();
	}
};

void() forcefieldthink =
{
	self.frame = 0;
	if (!(self.spawnflags & FORCEFIELD_TOGGLE))
	{
		if (time < self.wait)
		{
			if (self.spawnflags & FORCEFIELD_STARTOFF)
				self.weapon = 1;
			else
				self.weapon = 0;
		}
		else
		{
			if (self.spawnflags & FORCEFIELD_STARTOFF)
				self.weapon = 0;
			else
				self.weapon = 1;
		}
	}
	if (self.weapon != self.items)
	{
		self.items = self.weapon;
		if (self.weapon)
		{
			if (self.spawnflags & FORCEFIELD_WALL)
			{
				self.movetype = MOVETYPE_PUSH;
				self.solid = SOLID_BSP;
			}
			else
			{
				self.movetype = MOVETYPE_NONE;
				self.solid = SOLID_TRIGGER;
			}
			self.alpha = 0.3;
		}
		else
		{
			self.movetype = MOVETYPE_NONE;
			self.solid = SOLID_TRIGGER;
			self.alpha = 0;
		}
		setmodel(self, self.mdl);
	}
	if (!self.weapon) // is it active?
		return;
	if (time < self.dmgtime)
		self.alpha = 0.5;
	else
		self.alpha = 0.3;
	force_retouch = 2;      // hit even non-moving objects
};

void() forcefielduse =
{
	if (self.spawnflags & FORCEFIELD_TOGGLE)
	{
		self.weapon = !self.weapon;
		return;
	}
	if (self.spawnflags & FORCEFIELD_STARTOFF)
		self.weapon = 1;
	else
		self.weapon = 0;
	self.wait = time + self.delay;
};

void() doforcefieldthink =
{
	local entity saveself;
	self.nextthink = time + 0.1;
	saveself = self;
	self = saveself.owner;
	forcefieldthink();
	self = saveself;
};

/*QUAKED trigger_forcefield (1 .5 0) ? PLAYERONLY SILENT STARTOFF TOGGLE WALL
anything touching this can be pushed away,
can be blocked, and can be hurt.

when targeted it will flash off/on
see STARTOFF, TOGGLE and delay

flags:
"PLAYERONLY"
 only affects players, still flashes
 on monsters, but no effect.
"SILENT"
 no hum or push sound.
"STARTOFF"
 works in reverse, normally off, on when targeted.
"TOGGLE"
 switches on/off when targeted.
"WALL"
 is totally solid when on.

keys:
"dmg"
 amount of damage to do when touched, default 0
"delay"
 how long it will stay switched when
 targeted, ignored with TOGGLE.
"speed"
 how much force, default 0
"targetname"
 guess (flashes when targeted)
"target"
 triggered on touch
*/
void() trigger_forcefield =
{
	local vector o;
	if (!self.deathtype) // map makers can override this
		self.deathtype = " walked into a rather painful forcefield";
	if (self.speed < 30)
		self.speed = 30;
	self.mdl = self.model;
	self.solid = SOLID_TRIGGER;
	setmodel (self, self.model);    // set size and link into world
	self.movetype = MOVETYPE_NONE;
	self.modelindex = 0;
	self.model = "";
	self.touch = forcefieldtouch;
	self.takedamage = DAMAGE_YES;
	self.health = 99999999;
	self.th_pain = forcefieldpain;
	self.th_die = forcefieldpain;
	self.think = forcefieldthink;
	self.nextthink = time + 0.1;
	self.use = forcefielduse;
	self.alpha = 0.5;
	self.effects = EF_ADDITIVE;
	if (!(self.spawnflags & FORCEFIELD_SILENT))
	{
		// same as light_flouro, sounds about perfect for this
		precache_sound ("ambience/fl_hum1.wav");
		o = (self.mins + self.maxs)*0.5;
		ambientsound (o, "ambience/fl_hum1.wav", 1, ATTN_STATIC);
	}
	self.wait = 0;
	self.weapon = 1; // start active
	if (self.spawnflags & FORCEFIELD_STARTOFF)
		self.weapon = 0; // oh, turn it off then
	self.items = -1; // make think set up the solid/trigger/off stuff
	self.think();
	// normal thinking wasn't working, so this is a hack...
	self.think = SUB_Null;
	self.nextthink = -1;
	newmis = spawn();
	newmis.think = doforcefieldthink;
	newmis.nextthink = time + 0.1;
	newmis.owner = self;
};


// shared spawnflags
float ROTATE_TOUCHDMG = 1;

// door spawnflags
float ROTATEDOOR_CRUSH = 2;
float ROTATEDOOR_TOGGLE = 4;
// object spawnflags
float ROTATINGOBJECT_STARTON = 2;
float ROTATINGOBJECT_NOTSOLID = 4;

//.float rotatetype;
//float ROTATETYPE_OBJECT = 1;
//float ROTATETYPE_MOVEWALL = 2;
//float ROTATETYPE_ENTITY = 3; // anything else


float STATE_CLOSED = 1;
float STATE_CLOSING = 2;
float STATE_OPENING = 3;
float STATE_OPEN = 4;
float STATE_STARTCLOSING = 5;

float MOVEWALL_VISIBLE = 1;
float MOVEWALL_TOUCH = 2;

float STATE_NOTSPINNING = 1;
float STATE_SPINNINGUP = 2;
float STATE_SPINNING = 3;
float STATE_SPINNINGDOWN = 4;

//.float setuprotatetargets;
//.vector rotateoffset;

/*QUAKED info_rotate (0 .5 0) (-8 -8 -8) (8 8 8)
rotate_objects target this to
set center of rotation.
*/

void() info_rotate =
{
	self.think = SUB_Remove;
	self.nextthink = time + 2; // give things a chance to get info
};

void(entity door) rotate_door_group_reversedirection;
void() rotate_door_stateupdate;

void() rotate_touch =
{
	if (time < self.attack_finished)
		return;

	if (self.dmg > 0)
	{
		T_Damage (other, self, self, self.dmg * 0.1, self.dmg * 0.1, self.deathtype, DT_IMPACT, (self.absmin + self.absmax) * 0.5, '0 0 0', Obituary_Generic);
		self.attack_finished = time + 0.1;
	}
};

void() rotate_blocked =
{
	if (time < self.attack_finished)
		return;

	self.attack_finished = time + 0.1;

	if (self.classname == "func_rotatingdoor")
	{
		rotate_door_stateupdate();
		rotate_door_group_reversedirection(self);
	}

	if(self.dmg > 0)
	{
		T_Damage (other, self, self, self.dmg * 0.1, self.dmg * 0.1, self.deathtype, DT_IMPACT, (self.absmin + self.absmax) * 0.5, '0 0 0', Obituary_Generic);
		self.attack_finished = time + 0.1;
	}
};

void(float notsolid) rotate_setup =
{
	if (notsolid)
		self.solid = SOLID_NOT;
	else
		self.solid = SOLID_BSP;
	self.movetype = MOVETYPE_PUSH;
	setmodel(self, self.model);

	self.oldorigin = self.origin;

	if (self.spawnflags & ROTATE_TOUCHDMG)
		self.touch = rotate_touch;
	self.blocked = rotate_blocked;
};

void(vector destangles) rotate_calculatemove =
{
	local vector ang;
	ang = destangles - self.angles;
	ang_x = ang_x - 360 * floor(ang_x / 360);if (ang_x >= 180) ang_x = ang_x - 360;
	ang_y = ang_y - 360 * floor(ang_y / 360);if (ang_y >= 180) ang_y = ang_y - 360;
	ang_z = ang_z - 360 * floor(ang_z / 360);if (ang_z >= 180) ang_z = ang_z - 360;
	self.ltime = time;
	self.nextthink = time + (vlen(ang) / self.speed);
	if (self.nextthink >= time + 0.01)
		self.avelocity = normalize(ang) * self.speed;
	else
	{
		self.nextthink = time + 0.01;
		self.avelocity = '0 0 0';
	}
};

void() rotate_door_stateupdate =
{
	local float s;
	s = 0;
	if (self.state == STATE_OPENING)
	{
		rotate_calculatemove(self.dest);
		s = 1;
	}
	else if (self.state == STATE_CLOSING)
	{
		rotate_calculatemove(self.dest1);
		s = 1;
	}
	else
		s = 0;
	if (self.cnt != s)
	{
		self.cnt = s;
		if (s == 1)
		{
			if (self.noise2 != "")
				sound(self, CHAN_VOICE, self.noise2, 1, ATTN_NORM);
		}
		else
		{
			if (self.noise3 != "")
				sound(self, CHAN_VOICE, self.noise3, 1, ATTN_NORM);
		}
	}
	if (self.state == STATE_CLOSED || self.state == STATE_CLOSING)
		self.frame = 0;
	else
		self.frame = 1;
};

void() rotate_door_statethink =
{
	self.nextthink = 0;
	self.avelocity = '0 0 0';
	// all of these are right when the state begins
	if (self.state == STATE_STARTCLOSING)
		self.state = STATE_CLOSING;
	else if (self.state == STATE_CLOSING)
		self.state = STATE_CLOSED;
	else if (self.state == STATE_OPENING)
	{
		self.state = STATE_OPEN;
		if (!(self.spawnflags & ROTATEDOOR_TOGGLE))
		if (self.wait >= 0)
		{
			self.nextthink = time + self.wait;
			self.state = STATE_STARTCLOSING;
		}
	}
	rotate_door_stateupdate();
};

void() rotate_door_use =
{
	if (self.spawnflags & ROTATEDOOR_TOGGLE)
	{
		if (self.state == STATE_OPEN || self.state == STATE_STARTCLOSING || self.state == STATE_OPENING)
			self.state = STATE_CLOSING;
		if (self.state == STATE_CLOSED || self.state == STATE_CLOSED)
			self.state = STATE_OPENING;
	}
	else
	{
		if (self.state != STATE_OPEN)
		if (self.state != STATE_OPENING)
		{
			if (self.state == STATE_STARTCLOSING)
				self.nextthink = time + self.wait;
			else
				self.state = STATE_OPENING;
		}
	}
	rotate_door_stateupdate();
};

void() rotate_door_reversedirection =
{
	if (self.spawnflags & ROTATEDOOR_CRUSH)
		return;

	if (self.state == STATE_CLOSED || self.state == STATE_CLOSING)
		self.state = STATE_OPENING;
	else
		self.state = STATE_CLOSING;

	rotate_door_stateupdate();
};

void(entity door) rotate_door_group_reversedirection =
{
	local string n;
	local entity eself;

	eself = self;
	self = door;

	// reverse all in group
	if (self.group)
	{
		n = self.group;
		self = find(world, group, n);
		while(self != world)
		{
			rotate_door_reversedirection();
			self = find(self, group, n);
		}
	}
	else
		rotate_door_reversedirection();
	self = eself;
};

/*QUAKED func_rotatingdoor (.6 0 .9) ? TOUCHDMG CRUSH TOGGLE
rotating door.

Flags:
"TOUCHDMG"
 if set, will do block damage
 when touched, not just when
 blocked.
"CRUSH"
 will crush things instead of
 reversing direction when
 blocked, useful when making a
 door to block off an area.
"TOGGLE"
 opens/closes when triggered,
 rather than just opening.

Keys:
"dmg"
 damage to cause when blocked,
 default is 2, use -1 for no
 damage.
"speed"
 how fast it rotates,
 in degrees per second.
 default: 90
"angles"
 start angles (pitch yaw roll).
"dest"
 end angles (pitch yaw roll).
"wait"
 how long to stay open.
 (not used with TOGGLE)
 default: 3 seconds
"target"
 must target info_rotate
 object to define origin
"targetname"
 must be targeted, rotating
 doors operate only when
 triggered
"group"
 you can group rotating doors,
 when grouped all rotating
 doors will reverse direction
 at the same time
"deathtype"
 as with basically all things
 in Dark Places, deathtype
 is message when something is
 killed by this.
 default: " got in the way"
"sounds"
1) medieval (default)
2) metal
3) base
*/

void() func_rotatingdoor =
{
	if (!self.deathtype) // map makers can override this
		self.deathtype = " got in the way";

	self.dest1 = self.angles;

	if (self.speed <= 0)
		self.speed = 90;
	if (self.wait == 0)
		self.wait = 3;
	if (self.wait <= 0)
		self.wait = 0;

	if (self.dmg == 0)
		self.dmg = 2;
	else if (self.dmg < 0)
		self.dmg = 0;

	if (game != GAME_NEXUIZ)
	{
		if (self.sounds == 0)
			self.sounds = 1;
		if (self.sounds == 1)
		{
			precache_sound ("doors/winch2.wav");
			precache_sound ("doors/drclos4.wav");
			self.noise2 = "doors/winch2.wav";
			self.noise3 = "doors/drclos4.wav";
		}
		if (self.sounds == 2)
		{
			precache_sound ("doors/airdoor1.wav");
			precache_sound ("doors/airdoor2.wav");
			self.noise2 = "doors/airdoor1.wav";
			self.noise3 = "doors/airdoor2.wav";
		}
		if (self.sounds == 3)
		{
			precache_sound ("doors/basesec1.wav");
			precache_sound ("doors/basesec2.wav");
			self.noise2 = "doors/basesec1.wav";
			self.noise3 = "doors/basesec2.wav";
		}
	}

	rotate_setup(FALSE);

	self.state = STATE_CLOSED;
	self.use = rotate_door_use;
	self.think = rotate_door_statethink;
	self.nextthink = 0;
};

void() rotatingobject_think =
{
	local float t, s;
	self.nextthink = time;
	self = self.owner;

	t = time - self.count;
	self.count = time;

	self.avelocity = self.rotate * self.speed;

	if (self.state == STATE_SPINNINGUP)
	{
		if (self.delay)
			s = t * self.delay;
		else
			s = 1;
		self.speed = self.speed + s;
		if (self.speed >= 1)
		{
			self.speed = 1;
			self.state = STATE_SPINNING;
		}
	}
	else if (self.state == STATE_SPINNINGDOWN)
	{
		if (self.delay)
			s = t * self.delay;
		else
			s = 1;
		self.speed = self.speed - s;
		if (self.speed <= 0)
		{
			self.speed = 0;
			self.state = STATE_NOTSPINNING;
		}
	}
	if (self.state == STATE_SPINNINGUP || self.state == STATE_SPINNING)
		self.frame = 1;
	else
		self.frame = 0;
};

void() rotatingobject_use =
{
	if (self.state == STATE_SPINNINGUP || self.state == STATE_SPINNING)
		self.state = STATE_SPINNINGDOWN;
	else
		self.state = STATE_SPINNINGUP;
};

void() rotatingobject_setup =
{
	self.enemy = spawn();
	self.enemy.owner = self;
	self.enemy.think = rotatingobject_think;
	self.enemy.nextthink = self.count = time + 0.1;

	self.state = STATE_NOTSPINNING;
	self.use = rotatingobject_use;
	self.think = SUB_Null;
	self.nextthink = 99999999999;
	if ((self.spawnflags & ROTATINGOBJECT_STARTON) || (!self.targetname))
	{
		self.speed = 1;
		self.state = STATE_SPINNING;
	}
};

/*QUAKED func_rotatingobject (.6 0 .9) ? TOUCHDMG STARTON NOTSOLID
a rotating 'thing',
like a spinning fan.

Flags:
"TOUCHDMG"
 cause damage when touched,
 not just when blocked.
 (example: blades)
"STARTON"
 easy to guess this one,
 meaningless if it can't be
 triggered.
"NOTSOLID"
 if set, the object is not
 solid.

Keys:
"dmg"
 damage to cause when blocked.
 default: 0
"delay"
 how long it takes
 to completely spin up/down.
 default: 0 (instant)
"rotate"
 rotation per second
 (pitch yaw roll, in degrees).
"target"
 of course this must be set
"targetname"
 if set, it will only
 start/stop spinning when
 triggered, rather than
 simply spinning all the time.
"deathtype"
 as with basically all things
 in Dark Places, deathtype
 is message when something is
 killed by this.
 default: " got in the way"
*/

void() func_rotatingobject =
{
	if (!self.deathtype) // map makers can override this
		self.deathtype = " got in the way";

	if (self.delay < 0.01)
		self.delay = 0;
	// change to acceleration rate
	if (self.delay)
		self.delay = 1 / self.delay;
	self.speed = 0;

	rotate_setup(self.spawnflags & ROTATINGOBJECT_NOTSOLID);

	self.think = rotatingobject_setup;
	self.nextthink = time + 0.2;
};

