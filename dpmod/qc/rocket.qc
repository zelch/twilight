
void(vector org, vector vel, entity own, float damage, float damage2, float type, float lifetime, string dethtype, void(entity t, entity a, string m, float dtyp) obitfunc) LaunchGrenade;

/*
void(vector org, entity attacker, float damg, float radius, string dt, vector explosioncolor, float quad, void(entity t, entity a, string m, float dtyp) obitfunc) SmallExplosion =
{
	local vector v;
	local entity e;
	e = spawn();
	e.owner = attacker;
	setorigin(e, org);
	findbetterlocation2(e);

	te_plasmaburn(org);
	T_RadiusDamage(e, attacker, damg, radius, world, dt, DT_EXPLOSION, obitfunc);
	remove(e);

	v = findbetterlocation3(org); // move animation away from walls
	effect(v, "progs/s_explod.spr", 0, 6, 10);
	//effect(v, "progs/dpexplosion.spr32", 0, 20, 40);
};
*/

void() MissileExplode =
{
	fightdone = time + 1; // delay stuff until fighting is over
	/*
	if (self.owner.weapon == IT_WEAPON4)
		SmallExplosion(self.origin, self.owner, self.dmg, self.dmg2, self.deathtype, '0 0 0', self.effects & EF_BLUE, self.obitfunc1);
	else
	*/
		Explosion(self.origin, self.owner, self.dmg, self.dmg2, self.deathtype, '0 0 0', self.effects & EF_BLUE, self.obitfunc1);
	remove(self);
};

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
	MissileExplode();
};

void() MissileThink =
{
	local float p;
	local vector v;
	self.nextthink = time;
	fightdone = time + 1; // delay stuff until fighting is over
	/*
	//if (self.owner.weapon == IT_WEAPON7)
	if (self.owner.classname == "player")
	{
		makevectors(self.owner.v_angle);
		traceline(self.owner.origin + '0 0 16', self.owner.origin + '0 0 16' + v_forward * 65536, FALSE, self.owner);
		v = normalize(trace_endpos - self.origin);
		//if (normalize(self.velocity) * v < 0.4 || (self.owner.weapon != IT_WEAPON7 && self.owner.weapon != IT_WEAPON4))
		if (self.owner.weapon != IT_WEAPON7 && self.owner.weapon != IT_WEAPON4)
			v = normalize(self.velocity);
		if (self.owner.weapon == IT_WEAPON4)
			p = 1000;
		else
			p = 5000;
		self.velocity = self.velocity + (v * p - self.velocity) * frametime;
	}
	else*/ if ((self.velocity * self.dest) < 5000)
	{
		self.velocity = self.velocity + self.dest * 10000 * frametime;
		p = self.velocity * self.dest;
		if (p > 5001)
		{
			p = 5000 - p;
			self.velocity = self.velocity + self.dest * p;
		}
	}
	self.angles = vectoangles(self.velocity);
	p = pointcontents(self.origin);
	if (/*(self.owner.button3 && self.owner.weapon == IT_WEAPON7) || */time > self.cnt || p == CONTENT_SOLID || p == CONTENT_LAVA)
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
	newmis.velocity = /*own.velocity + */dir * 20;
	newmis.dest = dir;
	newmis.angles = vectoangles(dir);
	newmis.touch = MissileTouch;
	newmis.think = MissileThink;
	newmis.th_die = MissileExplode;
	newmis.nextthink = time;
	//if (own.weapon == IT_WEAPON4)
	//	newmis.takedamage = DAMAGE_NO;
	//else
		newmis.takedamage = DAMAGE_YES;
	newmis.health = 40;     // can be detonated inflight
	newmis.cnt = time + 15; // 15 seconds max flight time
	newmis.dmg = damg * damagescale;
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

