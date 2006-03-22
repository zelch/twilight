
float GRENADE_IMPACT = 1;
float GRENADE_PROXIMITY = 2;
float GRENADE_IMMUNETODAMAGE = 4;
float GRENADE_TENWARHEAD = 8;
float GRENADE_DETONATABLE = 16;
float GRENADE_DETONATEONCREATURE = 32;

.float activemines;

void() GrenadeExplode =
{
	local vector v;
	self.owner.activemines = self.owner.activemines - 1;
	if (self.weapon & GRENADE_TENWARHEAD)
	{
		v = randomvec() * 200;LaunchGrenade(self.origin, self.velocity + v, self.owner, self.dmg, self.count2, self.dmg2, GRENADE_IMPACT + GRENADE_IMMUNETODAMAGE, 10, self.deathtype, self.obitfunc1);
		v = randomvec() * 200;LaunchGrenade(self.origin, self.velocity + v, self.owner, self.dmg, self.count2, self.dmg2, GRENADE_IMPACT + GRENADE_IMMUNETODAMAGE, 10, self.deathtype, self.obitfunc1);
		v = randomvec() * 200;LaunchGrenade(self.origin, self.velocity + v, self.owner, self.dmg, self.count2, self.dmg2, GRENADE_IMPACT + GRENADE_IMMUNETODAMAGE, 10, self.deathtype, self.obitfunc1);
		v = randomvec() * 200;LaunchGrenade(self.origin, self.velocity + v, self.owner, self.dmg, self.count2, self.dmg2, GRENADE_IMPACT + GRENADE_IMMUNETODAMAGE, 10, self.deathtype, self.obitfunc1);
		v = randomvec() * 200;LaunchGrenade(self.origin, self.velocity + v, self.owner, self.dmg, self.count2, self.dmg2, GRENADE_IMPACT + GRENADE_IMMUNETODAMAGE, 10, self.deathtype, self.obitfunc1);
		v = randomvec() * 200;LaunchGrenade(self.origin, self.velocity + v, self.owner, self.dmg, self.count2, self.dmg2, GRENADE_IMPACT + GRENADE_IMMUNETODAMAGE, 10, self.deathtype, self.obitfunc1);
		v = randomvec() * 200;LaunchGrenade(self.origin, self.velocity + v, self.owner, self.dmg, self.count2, self.dmg2, GRENADE_IMPACT + GRENADE_IMMUNETODAMAGE, 10, self.deathtype, self.obitfunc1);
		v = randomvec() * 200;LaunchGrenade(self.origin, self.velocity + v, self.owner, self.dmg, self.count2, self.dmg2, GRENADE_IMPACT + GRENADE_IMMUNETODAMAGE, 10, self.deathtype, self.obitfunc1);
		v = randomvec() * 200;LaunchGrenade(self.origin, self.velocity + v, self.owner, self.dmg, self.count2, self.dmg2, GRENADE_IMPACT + GRENADE_IMMUNETODAMAGE, 10, self.deathtype, self.obitfunc1);
		v = randomvec() * 200;LaunchGrenade(self.origin, self.velocity + v, self.owner, self.dmg, self.count2, self.dmg2, GRENADE_IMPACT + GRENADE_IMMUNETODAMAGE, 10, self.deathtype, self.obitfunc1);
		remove(self);
	}
	else if (self.deathtype == "GRENADE")
	{
		if (self.lefty)
			T_RadiusDamage(self, self.owner, self.dmg2, self.count2, self.dmg2, world, "GRENADEBOUNCED", DT_EXPLOSION, self.obitfunc1);
		else
			T_RadiusDamage(self, self.owner, self.dmg2, self.count2, self.dmg2, world, "GRENADEDIRECT", DT_EXPLOSION, self.obitfunc1);
		BecomeExplosion(self, '0 0 0', self.effects & EF_BLUE);
	}
	else
	{
		T_RadiusDamage(self, self.owner, self.dmg2, self.count2, self.dmg2, world, self.deathtype, DT_EXPLOSION, self.obitfunc1);
		BecomeExplosion(self, '0 0 0', self.effects & EF_BLUE);
	}
};

void() GrenadeDet =
{
	self.think = GrenadeExplode;
	self.nextthink = time;
	self.solid = SOLID_NOT;
	self.takedamage = DAMAGE_NO;
	setsize(self, '0 0 0', '0 0 0');
	self.movetype = MOVETYPE_NONE;
};

.float detonatetimeout;

void() GrenadeThink =
{
	local   entity  head;
	local   float   p;
	self.nextthink = time;
	fightdone = time + 1; // delay stuff until fighting is over
	p = pointcontents(self.origin);
	if (p == CONTENT_SKY)
	{
		self.owner.activemines = self.owner.activemines - 1;
		remove(self);
		return;
	}
	if (p == CONTENT_LAVA || time > self.cnt)
	{
		self.th_die();
		return;
	}
	if (self.weapon & GRENADE_DETONATABLE)
	if (time < self.owner.detonatetimeout)
	{
		self.th_die();
		return;
	}
	if (self.weapon & GRENADE_PROXIMITY)
	{
		if (time >= self.count)
		{
			self.count = time + 0.05;
			head = findradius(self.origin, self.dmg2 * 0.25);
			while (head)
			{
				if ((head.flags & FL_MONSTER) || head.classname == "player")
				if (head != self.owner)
				if (head.team == 0 || head.team != self.owner.team)
				{
					// trigger
					self.count = time + 1000;
					self.cnt = time + 0.1;
					sound(self, CHAN_VOICE, "weapons/bomb/trigger.wav", 1, ATTN_STATIC);
					break;
				}
				head = head.chain;
			}
		}
	}
	if (self.flags & FL_ONGROUND)
	{
		if (self.mins_z == 0)
		{
			setsize(self, '0 0 -2', '0 0 0');
			traceline(self.origin + '0 0 1', self.origin + '0 0 -4', TRUE, world);
			if (trace_fraction < 1)
				setorigin(self, trace_endpos + '0 0 4');
		}
		self.angles_x = 0;
		self.angles_z = 0;
		self.avelocity = '0 0 0';
	}
//	else
//		self.angles = vectoangles(self.velocity);
};

void() GrenadeTouch =
{
	local vector v;
	if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
	{
		remove(self);
		return;
	}
	if (other == self.owner)
		return; // don't hit owner
	if (vlen(self.velocity))
	if (other.solid == SOLID_BSP)
		self.avelocity = randomvec() * 400;
	if (self.weapon & GRENADE_IMPACT)
	{
		v = normalize(self.velocity);
		setorigin(self, self.origin - v * 16);
		self.th_die();
		return;
	}
	if (self.weapon & GRENADE_DETONATEONCREATURE)
	if ((other.flags & FL_MONSTER) || other.classname == "player" || other.classname == "turretbase")
	if (other.team == 0 || other.team != self.owner.team)
	{
		self.th_die();
		return;
	}
	self.lefty = TRUE;
	if (vlen(self.velocity) >= 15)
		sound (self, CHAN_WEAPON, "weapons/bounce.wav", 1, ATTN_NORM);  // bounce sound
};

void(vector org, vector vel, entity own, float damage, float force, float damage2, float type, float lifetime, string dethtype, void(entity t, entity a, string m, float dtyp) obitfunc) LaunchGrenade =
{
	local   vector  v;
	DelayGibComment();      // make him wait before commenting on gibs so it's not drown out by explosions etc

	own.activemines = own.activemines + 1;

	fightdone = time + 1; // delay stuff until fighting is over
	v = normalize(vel);
	newmis = spawn ();
	//newmis.cantrigger = TRUE; // can trigger buttons
	newmis.shoulddodge = TRUE;
	newmis.dangerrating = damage2;
	newmis.owner = own;
	newmis.movetype = MOVETYPE_BOUNCE;
	newmis.solid = SOLID_BBOX;
	newmis.classname = "grenade";
	// set newmis speed
	newmis.velocity = vel;
	newmis.avelocity = randomvec() * 100;//'0 0 0';
	newmis.angles = vectoangles(newmis.velocity);
	newmis.touch = GrenadeTouch;
	newmis.dmg = damage;
	newmis.count2 = force;
	newmis.dmg2 = damage2;
	newmis.effects = EF_LOWPRECISION;
	if (self.items & IT_QUAD)
	{
		newmis.effects = newmis.effects | EF_BLUE;
		newmis.dmg = newmis.dmg * 4;
		newmis.count2 = newmis.count2 * 4;
	}
	// set newmis duration
	newmis.cnt = time + lifetime;
	newmis.deathtype = dethtype;
	newmis.obitfunc1 = obitfunc;
	newmis.weapon = type;
	newmis.think = GrenadeThink;
	newmis.nextthink = time;
	if (type & GRENADE_IMMUNETODAMAGE)
		newmis.takedamage = DAMAGE_NO;
	else
		newmis.takedamage = DAMAGE_YES;
	newmis.health = 20; // can be shot
	newmis.th_die = GrenadeDet;
	setmodel (newmis, "progs/grenade.mdl");
	setsize (newmis, '0 0 0', '0 0 0');
	setorigin (newmis, org);
};
