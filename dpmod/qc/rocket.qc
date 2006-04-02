
.float detonatetimeout;

void(vector org, vector vel, entity own, float damage, float force, float damage2, float type, float lifetime, string dethtype, void(entity t, entity a, string m, float dtyp) obitfunc) LaunchGrenade;
void(vector org, vector vel, entity own, float damg, float force, float blastradius, float burndamg, float mburn, string dethtype, void(entity t, entity a, string m, float dtyp) obitfunc) LaunchFireball;

void() SmallFireballExplode =
{
	//local vector v;
	self.solid = SOLID_NOT;
	findbetterlocation2(self);

	T_RadiusDamage(self, self.owner, self.dmg, self.count2, self.dmg2, world, self.deathtype, DT_EXPLOSION, self.obitfunc1);

	//v = findbetterlocation3(self.origin); // move animation away from walls
	effect(self.origin, "progs/s_explod.spr", 0, 6, 10);
	//effect(self.origin, "progs/dpexplosion.spr32", 0, 20, 40);
	remove(self);
};

void() SmallFireballThink =
{
	self.nextthink = time;
	self.angles = vectoangles(self.velocity) + '90 0 0';
	if (time > self.count)
		remove(self);
};

void(vector org, vector vel, entity own, float damg, float force, float blastradius, string dethtype, void(entity t, entity a, string m, float dtyp) obitfunc) LaunchSmallFireball =
{
	newmis = spawn ();
	newmis.deathtype = dethtype;
	newmis.obitfunc1 = obitfunc;
	newmis.shoulddodge = TRUE;
	newmis.dangerrating = blastradius;
	newmis.owner = own;
	newmis.createdtime = time;
	newmis.movetype = MOVETYPE_TOSS;
	newmis.solid = SOLID_BBOX;
	newmis.classname = "fireball";
	newmis.velocity = vel;
	//newmis.angles = vectoangles(newmis.velocity) + '90 0 0';
	newmis.touch = SmallFireballExplode;
	newmis.think = SmallFireballThink;
	newmis.nextthink = time;
	newmis.count = time + 15;
	newmis.dmg = damg;
	newmis.count2 = force;
	newmis.dmg2 = blastradius;
	newmis.effects = EF_RED | EF_FULLBRIGHT;

	if (own.items & IT_QUAD)
	{
		newmis.effects = newmis.effects | EF_BLUE;
		newmis.dmg = newmis.dmg * 4;
		newmis.count2 = newmis.count2 * 4;
	}

	setmodel (newmis, "progs/flame2.mdl");
	setsize (newmis, '0 0 0', '0 0 0');
	setorigin (newmis, org);
};

void() MissileExplodeFireballs =
{
	local float c;
	local vector vel, basevel;
	fightdone = time + 1; // delay stuff until fighting is over
	c = 0;
	basevel = cvar("sv_gravity") * '0 0 0.1';
	//while (c < 5)
	while (c < 50)
	{
		c = c + 1;
		vel = randomvec() * 500 + basevel;
		//LaunchSmallFireball(self.origin, vel, self.owner, 15, 0, 50, self.deathtype, self.obitfunc1);
		LaunchSmallFireball(self.origin, vel, self.owner, 120, 0, 450, self.deathtype, self.obitfunc1);
		newmis.movetype = MOVETYPE_TOSS;
	}
	T_RadiusDamage(self, self.owner, self.dmg, self.count2, self.dmg2, world, self.deathtype, DT_EXPLOSION, self.obitfunc1);
	BecomeExplosion(self, '-1 0 0', self.effects & EF_BLUE);
};

void() MissileExplode =
{
	fightdone = time + 1; // delay stuff until fighting is over
	T_RadiusDamage(self, self.owner, self.dmg, self.count2, self.dmg2, world, self.deathtype, DT_EXPLOSION, self.obitfunc1);
	BecomeExplosion(self, '0 0 0', self.effects & EF_BLUE);
};

void() MissileDet =
{
	self.think = self.th_gib;
	self.nextthink = time;
}

void() MissileTouch =
{
	local vector v;
	if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
	{
		remove(self);
		return;
	}
	fightdone = time + 1; // delay stuff until fighting is over
	if (other == self.owner)
		return; // ignore owner
	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}
	v = normalize(self.velocity);
	setorigin(self, self.origin - v * 16);
	self.th_gib();
};

/*
void() MissileThink =
{
	local float p;
	local vector v;
	self.nextthink = time;
	fightdone = time + 1; // delay stuff until fighting is over
*/
	/*
	if ((self.velocity * self.dest) < self.speed)
	{
		self.velocity = self.velocity + self.dest * self.speed * 2 * frametime;
		p = self.velocity * self.dest;
		if (p > (self.speed + 1))
		{
			p = self.speed - p;
			self.velocity = self.velocity + self.dest * p;
		}
	}
	*/
/*
	self.angles = vectoangles(self.velocity);
	self.angles_z = time * self.count1 - self.wait;
	p = pointcontents(self.origin);
	if (time > self.cnt || p == CONTENT_SOLID || p == CONTENT_LAVA)
	{
		self.th_gib();
		return;
	}
	if (p == CONTENT_SKY)
		remove(self);
};

void(vector org, vector dir, entity own, float damg, float force, float blastradius, string dethtype, void(entity t, entity a, string m, float dtyp) obitfunc, float spinspeed) LaunchMissile =
{
	fightdone = time + 1; // delay stuff until fighting is over
	newmis = spawn ();
	//newmis.cantrigger = TRUE; // can trigger buttons
	newmis.shoulddodge = TRUE;
	newmis.dangerrating = 150;
	newmis.owner = own;
	newmis.createdtime = time;
	newmis.movetype = MOVETYPE_FLY;
	newmis.solid = SOLID_BBOX; // only solid so it can be shot
	newmis.classname = "missile";
	newmis.deathtype = dethtype;
	newmis.obitfunc1 = obitfunc;
	newmis.dest = normalize(dir);
	newmis.velocity = dir;//newmis.dest * 20;
	newmis.angles = vectoangles(newmis.dest);
	newmis.touch = MissileTouch;
	newmis.think = MissileThink;
	newmis.th_die = MissileDet;
	newmis.th_gib = MissileExplode;
	newmis.nextthink = time;
	newmis.takedamage = DAMAGE_YES;
	newmis.health = 1;     // can be detonated inflight
	newmis.cnt = time + 15; // 15 seconds max flight time
	newmis.dmg = damg;
	newmis.count2 = force;
	newmis.dmg2 = blastradius;
	newmis.wait = time;
	newmis.effects = EF_LOWPRECISION;
	newmis.speed = vlen(dir);
	newmis.count1 = spinspeed;

	if (own.items & IT_QUAD)
	{
		newmis.effects = newmis.effects | EF_BLUE;
		newmis.dmg = newmis.dmg * 4;
		newmis.count2 = newmis.count2 * 4;
	}

	setmodel (newmis, "progs/missile.mdl");
	setsize (newmis, '0 0 0', '0 0 0');
	setorigin (newmis, org);
};
*/

void() MissileThink =
{
	local float p, deltatime;
	local vector neworg;

	self.nextthink = time;
	fightdone = time + 1; // delay stuff until fighting is over

	//self.angles = vectoangles(self.velocity) + (time - self.wait) * self.avelocity;
	deltatime = (time - self.weapon);
	if (deltatime < 1)
		deltatime = deltatime * deltatime;
	deltatime = deltatime;
	self.angles = self.dest3 + deltatime * self.avelocity;
	makevectors(self.angles);
	neworg = self.dest1 + deltatime * self.velocity + self.dest2_x * v_forward + self.dest2_y * v_right + self.dest2_z * v_up;
	tracebox(self.origin, self.mins, self.maxs, neworg, FALSE, self);

	/*
	//self.angles = vectoangles(self.velocity) + (time - self.wait) * self.avelocity;
	self.angles = self.angles + frametime * self.avelocity;
	makevectors(self.angles);
	neworg = self.origin - self.dest + frametime * self.velocity;
	self.dest = self.dest2_x * v_forward + self.dest2_y * v_right + self.dest2_z * v_up;
	*/

	//tracebox(self.origin, self.mins, self.maxs, neworg + self.dest, FALSE, self);
	setorigin(self, trace_endpos);

	p = pointcontents(self.origin);
	if (p == CONTENT_SKY)
		remove(self);
	else if (time > self.cnt || p == CONTENT_SOLID || p == CONTENT_LAVA || (trace_fraction < 1 && trace_ent != self.owner) || (time < self.owner.detonatetimeout))
		self.th_gib();
};

void(vector org, vector vel, entity own, float damg, float force, float blastradius, string dethtype, void(entity t, entity a, string m, float dtyp) obitfunc) LaunchMissile =
{
	fightdone = time + 1; // delay stuff until fighting is over
	newmis = spawn ();
	//newmis.cantrigger = TRUE; // can trigger buttons
	newmis.shoulddodge = TRUE;
	newmis.dangerrating = 150;
	newmis.owner = own;
	newmis.createdtime = time;
	newmis.movetype = MOVETYPE_FLY;
	newmis.solid = SOLID_BBOX; // only solid so it can be shot
	newmis.classname = "missile";
	newmis.deathtype = dethtype;
	newmis.obitfunc1 = obitfunc;
	newmis.weapon = time;
	newmis.velocity = vel;
	newmis.angles = vectoangles(vel);
	newmis.touch = MissileTouch;
	newmis.think = MissileThink;
	newmis.th_die = MissileDet;
	newmis.th_gib = MissileExplode;
	newmis.nextthink = time;
	newmis.takedamage = DAMAGE_YES;
	newmis.health = 1;     // can be detonated inflight
	newmis.cnt = time + 15; // 15 seconds max flight time
	newmis.dmg = damg;
	newmis.count2 = force;
	newmis.dmg2 = blastradius;
	newmis.wait = time;
	newmis.effects = EF_LOWPRECISION;

	if (own.items & IT_QUAD)
	{
		newmis.effects = newmis.effects | EF_BLUE;
		newmis.dmg = newmis.dmg * 4;
		newmis.count2 = newmis.count2 * 4;
	}

	setmodel (newmis, "progs/missile.mdl");
	setsize (newmis, '0 0 0', '0 0 0');
	setorigin (newmis, org);

	newmis.dest1 = org;
	newmis.dest3 = newmis.angles;
};

