
void(vector org, vector vel, entity own, float damage, float damage2, float type, float lifetime, string dethtype, void(entity t, entity a, string m, float dtyp) obitfunc) LaunchGrenade;

void() MissileExplode =
{
	fightdone = time + 1; // delay stuff until fighting is over
	Explosion(self.origin, self.owner, self.dmg, self.dmg2, self.deathtype, '0 0 0', self.effects & EF_BLUE, self.obitfunc1);
	remove(self);
};

void() MissileDet =
{
	self.think = MissileExplode;
	self.nextthink = time;
}

void() MissileTouch =
{
	local   vector  v;
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
	MissileExplode();
};

void() MissileThink =
{
	local float p;
	local vector v;
	self.nextthink = time;
	fightdone = time + 1; // delay stuff until fighting is over
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
	self.angles = vectoangles(self.velocity);
	p = pointcontents(self.origin);
	if (time > self.cnt || p == CONTENT_SOLID || p == CONTENT_LAVA)
	{
		MissileExplode();
		return;
	}
	if (p == CONTENT_SKY)
		remove(self);
};

void(vector org, vector dir, entity own, float damg, float blastradius, string dethtype, void(entity t, entity a, string m, float dtyp) obitfunc) LaunchMissile =
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
	newmis.velocity = newmis.dest * 20;
	newmis.angles = vectoangles(newmis.dest);
	newmis.touch = MissileTouch;
	newmis.think = MissileThink;
	newmis.th_die = MissileDet;
	newmis.nextthink = time;
	newmis.takedamage = DAMAGE_YES;
	newmis.health = 40;     // can be detonated inflight
	newmis.cnt = time + 15; // 15 seconds max flight time
	newmis.dmg = damg;
	newmis.dmg2 = blastradius;
	newmis.wait = time;
	newmis.effects = EF_LOWPRECISION;
	newmis.speed = vlen(dir);

	if (own.items & IT_QUAD)
	{
		newmis.dmg = newmis.dmg * 4;
		newmis.effects = newmis.effects | EF_BLUE;
	}

	setmodel (newmis, "progs/missile.mdl");
	setsize (newmis, '0 0 0', '0 0 0');
	setorigin (newmis, org);
};

void() MissileSpiralThink =
{
	local float p;

	if (!self.enemy.health)
	{
		MissileExplode();
		return;
	}

	self.nextthink = time;
	fightdone = time + 1; // delay stuff until fighting is over

	makevectors(self.enemy.angles + '0 0 720' * (time - self.weapon));
	p = (time - self.weapon) * 4;
	if (p > 1)
		p = 1;
	p = p * self.lefty;
	tracebox(self.origin, self.mins, self.maxs, self.enemy.origin + v_right * p + v_up * p, FALSE, self);
	setorigin(self, trace_endpos);

	self.velocity = self.enemy.velocity;
	self.angles = vectoangles(self.velocity);

	p = pointcontents(self.origin);
	if (p == CONTENT_SKY)
		remove(self);
	if (time > self.cnt || p == CONTENT_SOLID || p == CONTENT_LAVA || (trace_fraction < 1 && trace_ent != self.owner))
	{
		MissileExplode();
		return;
	}
};

entity spiralmissile_orbitentity;
void(vector org, vector dir, entity own, float damg, float blastradius, string dethtype, void(entity t, entity a, string m, float dtyp) obitfunc, float orbitdistance) LaunchSpiralMissile =
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
	newmis.velocity = dir * 20;
	newmis.lefty = orbitdistance;
	newmis.dest = dir;
	newmis.weapon = time;
	newmis.enemy = spiralmissile_orbitentity;
	newmis.angles = vectoangles(dir);
	newmis.touch = MissileTouch;
	newmis.think = MissileSpiralThink;
	newmis.th_die = MissileDet;
	newmis.nextthink = time;
	newmis.takedamage = DAMAGE_YES;
	newmis.health = 40;     // can be detonated inflight
	newmis.cnt = time + 15; // 15 seconds max flight time
	newmis.dmg = damg;
	newmis.dmg2 = blastradius;
	newmis.wait = time;
	newmis.effects = EF_LOWPRECISION;

	if (own.items & IT_QUAD)
	{
		newmis.dmg = newmis.dmg * 4;
		newmis.effects = newmis.effects | EF_BLUE;
	}

	setmodel (newmis, "progs/missile.mdl");
	setsize (newmis, '0 0 0', '0 0 0');
	setorigin (newmis, org);
};
