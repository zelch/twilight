
float MINE_LASERTRIP = 1;
float MINE_PROXIMITY = 2;
float MINE_IMMUNETODAMAGE = 4;
float MINE_TENWARHEAD = 8;
float MINE_DETONATABLE = 16;
float MINE_HOP = 32;
float MINE_FIVEWARHEAD = 64;
float MINE_IMPACTCREATURE = 128;

.float activemines;
void() MineExplode =
{
	local vector v, basevel;
	local float t;
	self.owner.activemines = self.owner.activemines - 1;
	if (self.weapon & MINE_TENWARHEAD)
	{
		basevel = '0 0 0.5' * cvar("sv_gravity");
		t = GRENADE_IMPACT + GRENADE_IMMUNETODAMAGE;
		v = randomvec() * 500 + basevel;LaunchGrenade(self.origin, v, self.owner, self.dmg, self.count2, self.dmg2, t, 1, self.deathtype, self.obitfunc1);
		v = randomvec() * 500 + basevel;LaunchGrenade(self.origin, v, self.owner, self.dmg, self.count2, self.dmg2, t, 1, self.deathtype, self.obitfunc1);
		v = randomvec() * 500 + basevel;LaunchGrenade(self.origin, v, self.owner, self.dmg, self.count2, self.dmg2, t, 1, self.deathtype, self.obitfunc1);
		v = randomvec() * 500 + basevel;LaunchGrenade(self.origin, v, self.owner, self.dmg, self.count2, self.dmg2, t, 1, self.deathtype, self.obitfunc1);
		v = randomvec() * 500 + basevel;LaunchGrenade(self.origin, v, self.owner, self.dmg, self.count2, self.dmg2, t, 1, self.deathtype, self.obitfunc1);
		v = randomvec() * 500 + basevel;LaunchGrenade(self.origin, v, self.owner, self.dmg, self.count2, self.dmg2, t, 1, self.deathtype, self.obitfunc1);
		v = randomvec() * 500 + basevel;LaunchGrenade(self.origin, v, self.owner, self.dmg, self.count2, self.dmg2, t, 1, self.deathtype, self.obitfunc1);
		v = randomvec() * 500 + basevel;LaunchGrenade(self.origin, v, self.owner, self.dmg, self.count2, self.dmg2, t, 1, self.deathtype, self.obitfunc1);
		v = randomvec() * 500 + basevel;LaunchGrenade(self.origin, v, self.owner, self.dmg, self.count2, self.dmg2, t, 1, self.deathtype, self.obitfunc1);
		v = randomvec() * 500 + basevel;LaunchGrenade(self.origin, v, self.owner, self.dmg, self.count2, self.dmg2, t, 1, self.deathtype, self.obitfunc1);
		remove(self);
	}
	else if (self.weapon & MINE_FIVEWARHEAD)
	{
		basevel = '0 0 0.5' * cvar("sv_gravity");
		t = GRENADE_IMPACT + GRENADE_IMMUNETODAMAGE;
		v = randomvec() * 500 + basevel;LaunchGrenade(self.origin, v, self.owner, self.dmg, self.count2, self.dmg2, t, 1, self.deathtype, self.obitfunc1);
		v = randomvec() * 500 + basevel;LaunchGrenade(self.origin, v, self.owner, self.dmg, self.count2, self.dmg2, t, 1, self.deathtype, self.obitfunc1);
		v = randomvec() * 500 + basevel;LaunchGrenade(self.origin, v, self.owner, self.dmg, self.count2, self.dmg2, t, 1, self.deathtype, self.obitfunc1);
		v = randomvec() * 500 + basevel;LaunchGrenade(self.origin, v, self.owner, self.dmg, self.count2, self.dmg2, t, 1, self.deathtype, self.obitfunc1);
		v = randomvec() * 500 + basevel;LaunchGrenade(self.origin, v, self.owner, self.dmg, self.count2, self.dmg2, t, 1, self.deathtype, self.obitfunc1);
		remove(self);
	}
	else if (self.lefty == 2)
	{
		v = self.angles;
		v_x = 0 - v_x;
		makevectors(v);
		shotorg = self.origin;
		FireBullets(self.owner, self, -1, 4, self.dmg / 4, self.dmg / 4, 0, 0, v_forward * 10000, 0.05, "LASERTRIPMINEDIRECT", DT_NAIL, self.obitfunc1);
		T_RadiusDamage(self, self.owner, self.dmg, self.count2, self.dmg2, world, self.deathtype, DT_EXPLOSION, self.obitfunc1);
	}
	else if (self.lefty == 3)
	{
		T_RadiusDamage(self, self.owner, self.dmg, self.count2, self.dmg2, self.enemy, "TAGMINEBLAST", DT_EXPLOSION, self.obitfunc1);
		T_Damage(self.enemy, self, self.owner, self.dmg, self.dmg, "TAGMINEDIRECT", DT_EXPLOSION, self.origin, '0 0 0.5' * self.dmg, self.obitfunc1);
	}
	else
		T_RadiusDamage(self, self.owner, self.dmg, self.count2, self.dmg2, world, self.deathtype, DT_EXPLOSION, self.obitfunc1);
	BecomeExplosion(self, '0 0 0', self.effects & EF_BLUE);
};

void() MineDet =
{
	self.takedamage = DAMAGE_NO;
	self.think = MineExplode;
	if (self.weapon & MINE_HOP)
	{
		self.nextthink = time + 0.3;
		self.movetype = MOVETYPE_BOUNCE;
		self.velocity = '0 0 500';
	}
	else
	{
		self.nextthink = time;
		self.movetype = MOVETYPE_NONE;
		self.solid = SOLID_NOT;
	}
	self.flags = self.flags - (self.flags & FL_ONGROUND);
	setsize(self, '0 0 0', '0 0 0');
};

.float detonatetimeout;

void() MineThink =
{
	local entity head;
	local float p;
	local vector v;
	self.nextthink = time;
	fightdone = time + 1; // delay stuff until fighting is over
	if (time > self.cnt)
	{
		self.th_die();
		return;
	}
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
	if (self.weapon & MINE_DETONATABLE)
	if (time < self.owner.detonatetimeout)
	{
		MineExplode();
		return;
	}
	if (self.lefty)
	if (time >= self.count)
	{
		self.count = time + 0.05;
		if (self.lefty == 3)
		if (!self.enemy.takedamage)
		{
			MineExplode();
			return;
		}
		if (self.weapon & (MINE_PROXIMITY | MINE_LASERTRIP))
		if (time > self.cnt2)
		{
			head = findradius(self.origin, self.dmg2 * 0.25);
			while (head)
			{
				if ((head.flags & FL_MONSTER) || head.classname == "player")
				//if (head != self.owner)
				//if (head.team == 0 || head.team != self.owner.team || teamplay == 0)
				//if (head != self.enemy)
				{
					traceline(head.origin, self.origin, TRUE, world);
					if (trace_fraction == 1)
					{
						// trigger
						self.count = time + 1000;
						self.cnt = time + 0.1;
						if (game != GAME_NEXUIZ)
							sound(self, CHAN_VOICE, "weapons/bomb/trigger.wav", 1, ATTN_STATIC);
						break;
					}
				}
				head = head.chain;
			}
			if (self.lefty == 2)
			{
				v = self.angles;
				v_x = 0 - v_x;
				makevectors(v);
				newmis = self.owner;
				self.owner = world;
				traceline(self.origin, self.origin + v_forward * 65536, FALSE, self);
				self.owner = newmis;
				self.dest = trace_endpos;
				if (trace_ent)
				if ((trace_ent.flags & FL_MONSTER) || trace_ent.classname == "player")
				//if (trace_ent.team == 0 || trace_ent.team != self.owner.team)
				{
					// trigger
					self.count = time + 1000;
					self.cnt = 0;
					if (game != GAME_NEXUIZ)
						sound(self, CHAN_VOICE, "weapons/bomb/trigger.wav", 1, ATTN_STATIC);
				}
			}
		}
	}
};

void(entity targ) MineAttach =
{
	self.enemy = targ;
	self.touch = SUB_Null;
	self.movetype = MOVETYPE_FOLLOW;
	if (targ.solid == SOLID_BSP)
		self.solid = SOLID_BBOX;
	else
		self.solid = SOLID_TRIGGER;
	self.cnt2 = time + self.cnt2;
	setsize(self, '-8 -8 -8', '8 8 8');
	// set up the follow parameters
	self.aiment = targ;
	self.punchangle = targ.angles;
	self.view_ofs = self.origin + trace_plane_normal - targ.origin;
	self.v_angle = self.angles - targ.angles;
	// relink
	setorigin(self, self.origin);
	// FIXME: this should be some kind of attach sound
	if (game != GAME_NEXUIZ)
		sound (self, CHAN_WEAPON, "weapons/bounce.wav", 1, ATTN_NORM);  // bounce sound
};

void(float tries, vector org, float rad) findnearestsurface =
{
	local float bestfrac;
	local vector bestdir, v;
	bestfrac = 2;
	bestdir = '1 0 0';

	while (tries > 0)
	{
		tries = tries - 1;
		if (tries >= 6)
		{
			v = randomvec();
			v = normalize(v);
		}
		else if (tries >= 5)
			v = '0 0 -1';
		else if (tries >= 4)
			v = '0 0 1';
		else if (tries >= 3)
			v = '0 -1 0';
		else if (tries >= 2)
			v = '0 1 0';
		else if (tries >= 1)
			v = '-1 0 0';
		else
			v = '1 0 0';
		traceline(org, org + v * rad, FALSE, world);
		if (bestfrac > trace_fraction)
		{
			bestfrac = trace_fraction;
			bestdir = v;
		}
	}
	traceline(org, org + bestdir * rad, FALSE, world);
}

void() laserdotthink =
{
	self.nextthink = time;
	if (!self.owner.modelindex)
	{
		remove(self);
		return;
	}
	setorigin(self, self.owner.dest);
	//self.angles = self.owner.angles;
};

.float count3, count4;
void() MineTouch =
{
	local vector v;
	if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
	{
		remove(self);
		return;
	}
	if (other == self.owner)
		return; // don't hit owner
	if (other.solid == SOLID_BSP)
	{
		findnearestsurface(16, self.origin, 32);
		self.angles = vectoangles(trace_plane_normal);
		if (self.weapon & MINE_LASERTRIP)
		{
			newmis = spawn();
			newmis.classname = "laserdot";
			newmis.owner = self;
			newmis.think = laserdotthink;
			newmis.nextthink = time;
			setmodel(newmis, "progs/s_bubble.spr");
			setsize(newmis, '0 0 0', '0 0 0');
		}
		if (self.weapon & MINE_LASERTRIP)
			self.lefty = 2;
		else
			self.lefty = 1;
		MineAttach(other);
		return;
	}
	if ((other.flags & FL_MONSTER) || other.classname == "player")
	if (other.team == 0 || other.team != self.owner.team)
	{
		if (self.count3)
		{
			v = normalize(self.velocity) * self.count4;
			T_Damage(other, self, self.owner, self.count3, self.count4, self.deathtype, DT_IMPACT, self.origin, v, self.obitfunc1);
			if (!other.takedamage)
				return;
		}
		if (self.weapon & (MINE_IMPACTCREATURE))
		{
			MineExplode();
			return;
		}
		self.lefty = 3;
		MineAttach(other);
		return;
	}
};

void(vector org, vector vel, entity own, float damage, float force, float damage2, float impactdamage, float impactbodydamage, float type, float lifetime, float armdelay, string dethtype, void(entity t, entity a, string m, float dtyp) obitfunc) LaunchMine =
{
	local vector v;

	own.activemines = own.activemines + 1;

	fightdone = time + 1; // delay stuff until fighting is over
	v = normalize(vel);
	newmis = spawn ();
	//newmis.cantrigger = TRUE; // can trigger buttons
	newmis.shoulddodge = TRUE;
	newmis.dangerrating = damage2;
	newmis.havocattack = TRUE;
	newmis.owner = own;
	newmis.movetype = MOVETYPE_TOSS;//BOUNCE;
	newmis.solid = SOLID_BBOX;
	newmis.classname = "mine";
	// set newmis speed
	newmis.velocity = vel;// + self.velocity;
	newmis.avelocity = '0 0 0';
	newmis.angles = vectoangles(newmis.velocity);
	newmis.touch = MineTouch;
	newmis.dmg = damage;
	newmis.count2 = force;
	newmis.dmg2 = damage2;
	newmis.count3 = impactdamage;
	newmis.count4 = impactbodydamage;
	newmis.effects = EF_LOWPRECISION;
	if (self.items & IT_QUAD)
	{
		newmis.effects = newmis.effects | EF_BLUE;
		newmis.dmg = newmis.dmg * 4;
		newmis.count2 = newmis.count2 * 4;
	}
	// set newmis duration
	newmis.cnt = time + lifetime;
	newmis.cnt2 = armdelay;
	newmis.deathtype = dethtype;
	newmis.obitfunc1 = obitfunc;
	newmis.weapon = type;
	newmis.think = MineThink;
	newmis.nextthink = time;
	if (type & MINE_IMMUNETODAMAGE)
		newmis.takedamage = DAMAGE_NO;
	else
		newmis.takedamage = DAMAGE_YES;
	newmis.health = 1; // can be shot
	newmis.th_die = MineDet;
	setmodel (newmis, "progs/grenade.mdl");
	setsize (newmis, '0 0 0', '0 0 0');
	setorigin (newmis, org);
};
