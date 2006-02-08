
.void(entity t, entity a, string m, float dtyp) obitfunc1;
.entity realowner;

void() bullet_touch =
{
	local   vector  dir;
	dir = normalize(self.velocity);
	T_Damage(other, self, self.realowner, self.dmg, self.count, self.deathtype, self.cnt, self.origin, dir * self.count * 0.2, self.obitfunc1);
	if (other.solid == SOLID_BSP) // hit a wall
	if (self.lefty >= 0)
	if (pointcontents(self.origin) != CONTENT_SKY)
	{
		if (self.lefty == 4) // nail
		{
			nailpuff(self.origin - dir * 4, self.effects & EF_BLUE);
			//if (maxclients == 1)
				newwallspike (self.origin, other, dir);
		}
		else if (self.lefty == 1) // shotgun pellet
			bulletpuff(self.origin - dir * 4, self.effects & EF_BLUE);
		//traceline(self.origin, self.origin + dir, FALSE, self);
		//newdecal(self.origin, other, trace_plane_normal, "models/decals/blastmark.md3", 0, 0);
	}
	setorigin(self, self.origin - dir * 8);
	if (self.count2)
	{
		T_RadiusDamage(self, self.owner, self.dmg2, self.dmg2, self.count2, world, self.deathtype, DT_EXPLOSION, self.obitfunc1);
		BecomeExplosion(self, '-1 0 0', self.effects & EF_BLUE);
	}
	else
		remove(self);
};

void(entity realbulletowner, entity bulletowner, float bullettype, float shotcount, float damage, float bdamage, float edamage, float eradius, vector vel, float spread, string dethtype, float damgtype, void(entity t, entity a, string m, float dtyp) obitfunc) FireBullets =
{
	fightdone = time + 1; // delay stuff until fighting is over
	spread = spread * vlen(vel);
	while (shotcount > 0)
	{
		shotcount = shotcount - 1;
		newmis = spawn();
		newmis.classname = "bullet";
		setorigin(newmis, shotorg);
		newmis.dmg = damage;
		newmis.count = bdamage;
		newmis.dmg2 = edamage;
		newmis.count2 = eradius;
		newmis.effects = EF_LOWPRECISION;
		newmis.lefty = bullettype;
		newmis.solid = SOLID_BBOX;
		newmis.movetype = MOVETYPE_FLY;
		newmis.velocity = vel + randomvec() * spread;// + bullet_launcher.velocity;
		newmis.realowner = realbulletowner;
		newmis.owner = bulletowner;
		newmis.deathtype = dethtype;
		newmis.obitfunc1 = obitfunc;
		newmis.cnt = damgtype;
		newmis.touch = bullet_touch;
		newmis.nextthink = time + 3;
		newmis.think = SUB_Remove;
		if (bulletowner.items & IT_QUAD)
		{
			newmis.dmg = newmis.dmg * 4;
			newmis.count = newmis.count * 4;
			newmis.dmg2 = newmis.dmg2 * 4;
		}
		//if (self.lefty >= 0)
		//	newmis.movetype = MOVETYPE_TOSS;
		//if (self.lefty >= 0)
		if (maxclients == 1)
		if (game != GAME_NEXUIZ)
		{
			// only visible in singleplayer (network bandwidth reasons)
			setmodel(newmis, "progs/s_spike.mdl");
			newmis.angles = vectoangles(newmis.velocity);
			if (bulletowner.items & IT_QUAD)
				newmis.effects = newmis.effects | EF_BLUE;
		}
		setsize(newmis, '0 0 0', '0 0 0');
	}
};

/*
================
FireRailgunBullet

Used by railgun,
railgun is like a sniper rifle,
but the projectile is accelerated far beyond normal speeds
by the magnetic coil system in the barrel,
and can easily kill 5+ things with a single round.

how I do it here is merely keep doing shots until it hits a wall,
note that it starts at the last hit position.
================
*/
/*
void(vector src, float damage, float bdamage, vector dir, string dethtype) FireRailgunBullet =
{
	local   vector  v, lastpos;
	local   entity  saveself, last;
	local   float   damageratio, s, d, dt;
	if (bdamage < 1)
		return;
	damageratio = damage / bdamage;
	last = self;
	lastpos = src;
	while (bdamage > 0)
	{
		traceline (lastpos + dir * 2, lastpos + dir*8192, FALSE, last);
		last = trace_ent;
		lastpos = trace_endpos;
		if (trace_fraction != 1.0)
		{
			if (pointcontents(trace_endpos - dir*4) == CONTENT_SKY)
				return;

			if (trace_ent.solid == SOLID_BSP)
			{
				newblastmark (trace_endpos, trace_ent, trace_plane_normal, 0);
				v = randomvec() * 100 + '0 0 225' - dir * 50 - trace_plane_normal * 100;
				SpawnDust(trace_endpos - dir * 2, v);
				v = randomvec() * 100 + '0 0 225' - dir * 50 - trace_plane_normal * 100;
				SpawnDust(trace_endpos - dir * 2, v);
				v = randomvec() * 100 + '0 0 225' - dir * 50 - trace_plane_normal * 100;
				SpawnDust(trace_endpos - dir * 2, v);
			}
			if (trace_ent.takedamage)
			{
				d = localdamage_getdamage(trace_endpos, dir, trace_ent, bdamage * damageratio);
				dt = localdamage_getdamagetype(trace_endpos, dir, trace_ent, DT_RAIL);
				T_Damage (trace_ent, self, self, d, bdamage, dethtype, dt, trace_endpos);
			}
		}
		if (last.solid == SOLID_BSP)
			bdamage = 0;
	}
	weaponwakeup(lastpos, self);
};
*/
