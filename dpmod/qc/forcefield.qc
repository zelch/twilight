
float FORCEFIELD_PLAYERONLY   = 1;
float FORCEFIELD_SILENT       = 2;
float FORCEFIELD_STARTOFF     = 4;
float FORCEFIELD_TOGGLE       = 8;
float FORCEFIELD_WALL         = 16;

void(vector org, float p) forcefieldflash =
{
	//local vector v;
	//local float c, d;
	/*
	// great flash
	while (p > 0)
	{
		v = randompos(self.absmin, self.absmax);
		p = p - 10;
		particle(v, '0 0 0', 13, 10);
	}
	*/
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
//	forcefieldflash(self.damagepoint, take);
	forcefieldflash(self.absmin + self.absmax * 0.5, take);
};

/*
void() forcefieldgibcheck =
{
	local float c;
	local vector v;
	if (!self.enemy.takedamage) return;
	if (!self.weapon) return;
	if (self.enemy.absmax_x < (self.absmin_x + 4)) return;
	if (self.enemy.absmin_x > (self.absmax_x - 4)) return;
	if (self.enemy.absmax_y < (self.absmin_y + 4)) return;
	if (self.enemy.absmin_y > (self.absmax_y - 4)) return;
	if (self.enemy.absmax_z < (self.absmin_z + 4)) return;
	if (self.enemy.absmin_z > (self.absmax_z - 4)) return;
	// PLASMA FLASH :)
*/
	/*
	c = 4;
	while (c > 0)
	{
		c = c - 1;
		v = randompos(self.enemy.absmin, self.enemy.absmax);
		SpawnShock(v);
	}
	*/
/*
	T_Damage(self.enemy, self, self, 50000, 50000, self.deathtype, DT_LIGHTNING, self.enemy.origin, '0 0 0', Obituary_Generic);
	// just to trigger a huge flash on the forcefield
	T_Damage(self, self, self, 120, 0, "", DT_IMPACT, (self.absmin + self.absmax) * 0.5, '0 0 0', Obituary_Generic);
};
*/

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
	// self.nextthink = time + 0.1;
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
	/*
	if (self.enemy != world)
	if (self.spawnflags & FORCEFIELD_WALL)
	if (self.enemy.takedamage)
	if (self.enemy.solid == SOLID_BBOX || self.enemy.solid == SOLID_SLIDEBOX)
		forcefieldgibcheck();
	*/
	/*
	v1 = self.absmin;
	v2 = self.absmax;
	self.cnt = self.cnt + 8;
	if (self.size_x > self.size_y && self.size_x > self.size_z)
	{
		v1_x = self.cnt + self.absmin_x;
		while (v1_x > v2_x)
		{
			self.cnt = self.cnt - self.size_x;
			v1_x = v1_x - self.size_x;
		}
		v2_x = v1_x + 8;
	}
	else if (self.size_y > self.size_x && self.size_y > self.size_z)
	{
		v1_y = self.cnt + self.absmin_y;
		while (v1_y > v2_y)
		{
			self.cnt = self.cnt - self.size_y;
			v1_y = v1_y - self.size_y;
		}
		v2_y = v1_y + 8;
	}
	else // (self.size_z > self.size_x && self.size_z > self.size_y)
	{
		v1_z = self.cnt + self.absmin_z;
		while (v1_z > v2_z)
		{
			self.cnt = self.cnt - self.size_z;
			v1_z = v1_z - self.size_z;
		}
		v2_z = v1_z + 8;
	}
	if (v1_x < self.absmin_x) v1_x = self.absmin_x;
	if (v1_y < self.absmin_y) v1_y = self.absmin_y;
	if (v1_z < self.absmin_z) v1_z = self.absmin_z;
	if (v2_x > self.absmax_x) v2_x = self.absmax_x;
	if (v2_y > self.absmax_y) v2_y = self.absmax_y;
	if (v2_z > self.absmax_z) v2_z = self.absmax_z;
	*/
	/*
	c = 5;
	while (c > 0)
	{
		c = c - 1;
		v = randompos(v1, v2);
		particle(v, '0 0 0', 230, 10);
	}
	*/
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

