
.float detonatetimeout;

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

void() MissileThink =
{
	local float p, deltatime;
	local vector neworg;

	self.nextthink = time;
	fightdone = time + 1; // delay stuff until fighting is over

	deltatime = (time - self.weapon);
	if (deltatime < 1)
		deltatime = deltatime * deltatime;
	deltatime = deltatime;
	self.angles = self.dest3 + deltatime * self.avelocity;
	makevectors(self.angles);
	neworg = self.dest1 + deltatime * self.velocity + self.dest2_x * v_forward + self.dest2_y * v_right + self.dest2_z * v_up;
	tracebox(self.origin, self.mins, self.maxs, neworg, FALSE, self);

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

