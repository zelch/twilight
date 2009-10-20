/*
==============================================================================

EXPLOSIONS

==============================================================================
*/

entity xplo;
float maxdecors;

void() explosionfx_precache =
{
	if (game == GAME_NEXUIZ)
	{
		precache_model("models/sprites/s_explod.spr");
		precache_model("models/sprites/dpexplosion1.spr32");
		precache_model("models/sprites/dpexplosion2.spr32");
		precache_model("models/sprites/s_hexpl.spr");
		precache_sound("weapons/r_exp3.wav");
		precache_sound("weapons/hagexp1.wav");
		precache_sound("weapons/hagexp2.wav");
		precache_sound("weapons/hagexp3.wav");
		precache_sound("weapons/rocket_fire.wav");
	}
	else
	{
		//precache_model("progs/s_explod.spr");
		precache_model("progs/dpexplosion.spr32");
		precache_sound("weapons/r_exp3.wav");
	}
};

.float anim_fps;
.float anim_endframe;
void() explosionanimate =
{
	self.nextthink = time;
	self.frame = self.frame + self.anim_fps * frametime;
	if (self.frame >= self.anim_endframe)
		remove(self);
};

void(entity e, vector explosioncolor, float quad) BecomeExplosion =
{
	local vector org, v;
	if (e.solid == SOLID_BSP)
		setorigin(e, (e.absmin + e.absmax) * 0.5);
	e.model = "";
	e.solid = SOLID_NOT;
	e.movetype = MOVETYPE_NONE;
	e.takedamage = DAMAGE_NO;

	org = e.origin;
	findbetterlocation2(e);

	if (explosioncolor == '0 0 0')
	{
		if (quad)
			te_explosionquad(e.origin);
		else
			te_explosion(e.origin);
	}
	else if (explosioncolor == '-1 0 0')
	{
		sound(e, CHAN_AUTO, "weapons/r_exp3.wav", 1, ATTN_NORM);
		te_smallflash(e.origin);
	}
	else if (explosioncolor == '-2 0 0')
		te_tarexplosion(e.origin);
	else
		te_explosionrgb(e.origin, explosioncolor);

	//remove(e);

	v = findbetterlocation3(org); // move animation away from walls
	// TODO: make caller do the sprite effect so this can go away
	//effect(v, "progs/s_explod.spr", 0, 6, 10);
	//if (game == GAME_NEXUIZ)
	//	effect(v, "models/sprites/dpexplosion1.spr32", 0, 20, 40);
	//else
	//	effect(v, "progs/dpexplosion.spr32", 0, 20, 40);
	e.movetype = MOVETYPE_NONE;
	e.solid = SOLID_NOT;
	e.takedamage = DAMAGE_NO;
	setorigin(e, v);
	setmodel(e, "progs/dpexplosion.spr32");
	e.frame = 0;
	e.anim_fps = 40;
	e.anim_endframe = 20;
	e.think = explosionanimate;
	e.nextthink = time;
	e.velocity = '0 0 0';
};

/*
==============================================================================

FIRE

==============================================================================
*/

void() fire_precache =
{
	if (game != GAME_NEXUIZ)
	{
		precache_model("progs/flame2.mdl");
		precache_sound("fire/burn.wav");
	}
};

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_Fire =
{
	if (dtype == DTYPE_SUICIDE)
	{
		deathstring1 = targ.netname;
		deathstring2 = " played with fire";
		deathstring3 = "";
		deathstring4 = "";
	}
	else if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " was flame broiled by ";
		deathstring3 = attacker.netname;
		deathstring4 = "";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

void() Fire_burnthink =
{
	local float a;
	self.nextthink = time;
	if (self.enemy != world)
	if (!self.enemy.takedamage || (time <= self.enemy.radsuit_finished) || (self.enemy.solid == SOLID_BSP) || (self.enemy.flame != self))
	{
		if (self.enemy.flame == self)
			self.enemy.flame = world;
		self.enemy = world;
		self.movetype = MOVETYPE_TOSS;
		self.flags = self.flags - (self.flags & FL_ONGROUND);
		self.velocity = VEC_ORIGIN;
	}
	if (self.cnt < 1)
	{
		if (self.enemy.flame == self)
			self.enemy.flame = world;
		remove(self);
		return;
	}
	if (self.enemy.solid != SOLID_BSP)
	{
		self.movetype = MOVETYPE_NONE;
		if (self.enemy.movetype == MOVETYPE_STEP)
			self.movetype = MOVETYPE_STEP;
		if (self.enemy.health < 1)
			setorigin (self, (self.enemy.absmax + self.enemy.absmin) * 0.5);
		else if (self.enemy.classname == "monster_hell_knight")
			setorigin (self, self.enemy.origin + '0 0 28');
		else
			setorigin (self, self.enemy.origin + '0 0 18');
	}
	if (time >= self.count)
	{
		self.count = time + 0.1;
		if (time > self.pain_finished)
		{
			sound (self, CHAN_WEAPON, "fire/burn.wav", 1, ATTN_NORM);
			self.pain_finished = time + 0.5;
		}
		a = 4; // 40 damage per second
		if (a > self.cnt)
			a = self.cnt;
		self.cnt = self.cnt - a;
		if (self.enemy.classname != "monster_hell_knight") // immune
		if (self.enemy.takedamage)
		{
			if (self.enemy.health >= 1)
			if (time > self.enemy.pain_finished)
			if (self.enemy.classname == "player")
			{
				self.enemy.pain_finished = time + 0.3;
				if (random() > 0.5)
					sound (self.enemy, CHAN_VOICE, "player/lburn1.wav", 1, ATTN_NORM);
				else
					sound (self.enemy, CHAN_VOICE, "player/lburn2.wav", 1, ATTN_NORM);
			}
			T_Damage (self.enemy, self, self.owner, a, a, self.deathtype, DT_FIRE, self.origin, '0 0 0', Obituary_Fire);
		}
	}
	if (time >= self.cnt2)
	{
		//self.count = time + 0.6;
		//T_BurnRadius (self, self.owner, 40, self.cnt, self.enemy, self.deathtype);
		self.cnt2 = time + 0.3;
		T_RadiusDamage(self, self.owner, 20, 0, 80, self.enemy, self.deathtype, DT_FIRE, Obituary_Fire);
	}
	if (pointcontents(self.origin) != CONTENT_EMPTY)
		self.cnt = 0;
	if (self.cnt < 1)
	{
		if (self.enemy.flame == self)
			self.enemy.flame = world;
		remove(self);
		return;
	}
};

float(entity victim, entity attacker, float amount, string dt, vector v) SpawnFire =
{
	if (game == GAME_NEXUIZ)
		return 0;
	if (victim.flame != world)
	{
		victim.flame.cnt = victim.flame.cnt + amount;
		victim.flame.deathtype = dt;
	}
	else
	{
		if (victim.solid != SOLID_BSP)
		{
			if (victim.health < 1)
				v = (victim.absmax + victim.absmin) * 0.5;
			else if (victim.classname == "monster_hell_knight")
				v = victim.origin + '0 0 28';
			else
				v = victim.origin + '0 0 18';
		}
		newmis = spawn ();
		newmis.shoulddodge = TRUE;
		newmis.dangerrating = 50;
		newmis.classname = "fire";
		newmis.movetype = MOVETYPE_NONE;
		newmis.velocity = VEC_ORIGIN;
		newmis.touch = SUB_Null;
		setorigin (newmis, v);
		setmodel (newmis, "progs/flame2.mdl");
		setsize (newmis, '-1 -1 -1', '1 1 1');
		newmis.frame = 1;                       // BIG flame
		newmis.effects = EF_DIMLIGHT + EF_ADDITIVE + EF_FLAME;
		newmis.solid = SOLID_NOT;
		newmis.think = Fire_burnthink;
		newmis.nextthink = time + 0.1;
		newmis.cnt = amount;
		newmis.owner = attacker;
		newmis.enemy = victim;
		newmis.deathtype = dt;
		if (victim == world)
			newmis.movetype = MOVETYPE_TOSS;
		else
			victim.flame = newmis;
	}
//	victim.flamecount = victim.flamecount + amount;
//	victim.flameowner = attacker;
	return amount;
};

/*
============
T_BurnRadius
============
*/
float(entity inflictor, entity attacker, float damage, float radius, float mburn, entity ignore, string dt) T_BurnRadius =
{
	local float points, totalpoints;
	local entity head;

	traceline(inflictor.origin, inflictor.origin, TRUE, world);
	if (trace_startsolid)
	{
		dprint("T_BurnRadius: inflictor in a solid\n");
		return 0; // uh, it's in a wall, uh, lets be as sensible as we can in this strange situation...
	}

	if (damage > mburn)
		damage = mburn;

	head = findradius(inflictor.origin, radius);

	totalpoints = 0;
	while (head)
	{
		if (head.takedamage)
		if (head.solid != SOLID_BSP)
		if (head != ignore)
		{
			points = damage * LinearRadDamage(head, ignore, inflictor.origin, radius, 3);
			if (head.flame.classname == "fire")
			if ((head.flame.cnt + points) >= mburn)
				points = mburn - head.flame.cnt;
			if (points > 0)
			{
				totalpoints = totalpoints + points;
				SpawnFire(head, attacker, points, dt, head.origin);
			}
		}
		head = head.chain;
	}
	return totalpoints;
};

void() FireballExplode =
{
	T_RadiusDamage(self, self.owner, self.dmg, self.count2, self.dmg2, world, self.deathtype, DT_EXPLOSION, self.obitfunc1);
	BecomeExplosion(self, '0 0 0', FALSE);
	T_BurnRadius(self, self.owner, self.count3, self.dmg2, self.count1, world, self.deathtype);
};

void(vector org, vector vel, entity own, float damg, float force, float blastradius, float burndamg, float mburn, string dethtype, void(entity t, entity a, string m, float dtyp) obitfunc) LaunchFireball =
{
	newmis = spawn ();
	newmis.deathtype = dethtype;
	newmis.obitfunc1 = obitfunc;
	newmis.shoulddodge = TRUE;
	newmis.dangerrating = blastradius;
	newmis.owner = own;
	newmis.movetype = MOVETYPE_FLYMISSILE;
	newmis.solid = SOLID_BBOX;
	newmis.classname = "fireball";
	newmis.velocity = vel;
	newmis.angles = vectoangles(newmis.velocity) + '90 0 0';
	newmis.touch = FireballExplode;
	newmis.think = FireballExplode;
	newmis.nextthink = time + 15;
	newmis.dmg = damg;
	newmis.count2 = force;
	newmis.dmg2 = blastradius;
	newmis.count3 = burndamg;
	newmis.count1 = mburn;
	newmis.effects = EF_FULLBRIGHT;

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


/*
==============================================================================

BULLETS

==============================================================================
*/

void() bullet_touch =
{
	local vector dir;
	if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
	{
		remove(self);
		return;
	}
	dir = normalize(self.velocity);
	T_Damage(other, self, self.realowner, self.dmg, self.count, self.deathtype, self.cnt, self.origin, '0 0 0', self.obitfunc1);
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
		//newdecal(self.origin + trace_plane_normal * 0.125, other, trace_plane_normal, "models/decals/decal.md3", 0, 0, 0, TRUE);
	}
	if (self.count2)
	{
		T_RadiusDamage(self, self.owner, self.dmg2, self.dmg2, self.count2, world, self.deathtype, DT_EXPLOSION, self.obitfunc1);
		setorigin(self, self.origin - dir * 8);
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
		if (shotcount < 3 || maxclients == 1)
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
==============================================================================

GRENADES

==============================================================================
*/

float GRENADE_IMPACT = 1;
float GRENADE_PROXIMITY = 2;
float GRENADE_IMMUNETODAMAGE = 4;
float GRENADE_DETONATABLE = 16;
float GRENADE_DETONATEONCREATURE = 32;

.float activemines;

void() GrenadeExplode =
{
	local vector v;
	self.owner.activemines = self.owner.activemines - 1;
	v = normalize(self.velocity);
	if (self.deathtype == "GRENADE")
	{
		if (self.lefty)
			T_RadiusDamage(self, self.owner, self.dmg, self.count2, self.dmg2, world, "GRENADEBOUNCED", DT_EXPLOSION, self.obitfunc1);
		else
			T_RadiusDamage(self, self.owner, self.dmg, self.count2, self.dmg2, world, "GRENADEDIRECT", DT_EXPLOSION, self.obitfunc1);
		setorigin(self, self.origin - v * 16);
		BecomeExplosion(self, '0 0 0', self.effects & EF_BLUE);
	}
	else
	{
		T_RadiusDamage(self, self.owner, self.dmg, self.count2, self.dmg2, world, self.deathtype, DT_EXPLOSION, self.obitfunc1);
		setorigin(self, self.origin - v * 16);
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
	local entity head;
	local float p;
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
	local vector v;

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

	if (!(newmis.weapon & GRENADE_IMPACT))
	if (cvar("dpmod_odephysics"))
	{
		newmis.movetype = MOVETYPE_PHYSICS;
		newmis.solid = SOLID_PHYSICS_BOX;
		newmis.mass = 1;
		setmodel(newmis, newmis.model); // setmodel sets mins/maxs
	}

	newmis.pflags = PFLAGS_FULLDYNAMIC;
	newmis.light_lev = 150;
	newmis.color = '0.6 0.05 0.05';
};

/*
==============================================================================

ROCKETS

==============================================================================
*/

.float detonatetimeout;

void() MissileExplode =
{
	local vector v;
	fightdone = time + 1; // delay stuff until fighting is over
	T_RadiusDamage(self, self.owner, self.dmg, self.count2, self.dmg2, world, self.deathtype, DT_EXPLOSION, self.obitfunc1);
	v = normalize(self.velocity);
	setorigin(self, self.origin - v * 16);
	BecomeExplosion(self, '0 0 0', self.effects & EF_BLUE);
};

void() MissileDet =
{
	self.think = self.th_gib;
	self.nextthink = time;
}

void() MissileTouch =
{
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
	self.th_gib();
};

void() MissileThink =
{
	self.nextthink = time;
	fightdone = time + 1; // delay stuff until fighting is over

/*
	local float deltatime;
	local vector neworg;
	deltatime = (time - self.weapon);
	if (deltatime < 1)
		deltatime = deltatime * deltatime;
	deltatime = deltatime;
	self.angles = self.dest3 + deltatime * self.avelocity;
	makevectors(self.angles);
	neworg = self.dest1 + deltatime * self.velocity + self.dest2_x * v_forward + self.dest2_y * v_right + self.dest2_z * v_up;
	tracebox(self.origin, self.mins, self.maxs, neworg, FALSE, self);

	setorigin(self, trace_endpos);
	if (trace_fraction < 1 && trace_ent != self.owner)
	{
		self.th_gib();
		return;
	}
*/

	local float p;
	p = pointcontents(self.origin);
	if (p == CONTENT_SKY)
		remove(self);
	else if (time > self.cnt || p == CONTENT_SOLID || p == CONTENT_LAVA || (time < self.owner.detonatetimeout))
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

/*
==============================================================================

LIGHTNING

==============================================================================
*/

void() lightning_precache =
{
	if (game != GAME_NEXUIZ)
	{
		//precache_model("progs/v_light.mdl");
		precache_model("progs/bolt.mdl"); // actually this is the hook chain
		precache_model("progs/bolt2.mdl");
		precache_model("progs/bolt3.mdl");
		precache_sound("weapons/lhit.wav");
		precache_sound("weapons/lstart.wav");
	}
};

void(vector p1, vector p2, entity from, float damage, string dethtype, void(entity t, entity a, string m, float dtyp) obitfunc) LightningDamage =
{
	local vector f;
	local entity e1, e2;

	f = p2 - p1;
	// note: in Quake this line was bugged, it was normalize (f); with no f =
	f = normalize (f);
	f_x = 0 - f_y;
	f_y = f_x;
	f_z = 0;
	f = f*16;

	weapontraceline (p1, p2, FALSE, self);
	e1 = trace_ent;
	if (trace_ent.takedamage)
		T_Damage (trace_ent, from, from, damage, damage, dethtype, DT_LIGHTNING, trace_endpos, '0 0 0', obitfunc);

	weapontraceline (p1 + f, p2 + f, FALSE, self);
	e2 = trace_ent;
	if (trace_ent.takedamage)
	if (trace_ent != e1)
		T_Damage (trace_ent, from, from, damage, damage, dethtype, DT_LIGHTNING, trace_endpos, '0 0 0', obitfunc);

	weapontraceline (p1 - f, p2 - f, FALSE, self);
	if (trace_ent.takedamage)
	if (trace_ent != e1)
	if (trace_ent != e2)
		T_Damage (trace_ent, from, from, damage, damage, dethtype, DT_LIGHTNING, trace_endpos, '0 0 0', obitfunc);
};

void(vector v1, vector v2, float d, string dethtype, void(entity t, entity a, string m, float dtyp) obitfunc) LightningBolt =
{
	local vector dir;
	dir = normalize(v2 - v1);
	if (self.t_width < time)
	{
		sound (self, CHAN_WEAPON, "weapons/lhit.wav", 1, ATTN_NORM);
		self.t_width = time + 0.6;
	}

	weapontraceline (v1, v2, TRUE, self);

	te_lightning2(self, v1, trace_endpos);

	LightningDamage (self.origin, trace_endpos + dir*4, self, 30, dethtype, obitfunc);
};

/*
==============================================================================

LASERS

==============================================================================
*/

void() Laser_Touch =
{
	if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
	{
		remove(self);
		return;
	}
	if (other == self.owner)
		return;		// don't explode on owner

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}

	sound (self, CHAN_WEAPON, "enforcer/enfstop.wav", 1, ATTN_STATIC);

	te_plasmaburn(self.origin);

	T_Damage (other, self, self.owner, self.dmg, self.dmg2, self.deathtype, DT_LASER, self.origin, '0 0 0', self.obitfunc1);

	remove(self);
};

void(entity own, vector org, vector vel, float damg, string dethtype, void(entity t, entity a, string m, float dtyp) obitfunc) LaunchLaser =
{
	sound (own, CHAN_WEAPON, "enforcer/enfire.wav", 1, ATTN_NORM);

	newmis = spawn();
	newmis.shoulddodge = TRUE;
	newmis.dangerrating = 20;
	newmis.owner = own;
	newmis.movetype = MOVETYPE_FLY;
	newmis.solid = SOLID_BBOX;
	newmis.effects = EF_RED + EF_ADDITIVE;
	setmodel (newmis, "progs/laser.mdl");
	setsize (newmis, VEC_ORIGIN, VEC_ORIGIN);
	setorigin (newmis, org);
	newmis.velocity = vel;
	newmis.angles = vectoangles(newmis.velocity);
	newmis.nextthink = time + 5;
	newmis.think = SUB_Remove;
	newmis.touch = Laser_Touch;
	newmis.dmg = damg;
	newmis.dmg2 = damg;
	if (self.items & IT_QUAD)
	{
		newmis.effects = newmis.effects | EF_BLUE;
		newmis.dmg = newmis.dmg * 4;
		newmis.dmg2 = newmis.dmg2 * 4;
	}
	newmis.deathtype = dethtype;
	newmis.obitfunc1 = obitfunc;
};

/*
==============================================================================

SPIKES

==============================================================================
*/

void() spike_touch =
{
	local vector v;
	if (other == self.owner)
		return;
	if (other.solid == SOLID_TRIGGER)
		return; // trigger field, do nothing
	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}
	T_Damage (other, self, self.owner, self.health, self.health, self.deathtype, DT_NAIL, self.origin, '0 0 0', self.obitfunc1);

	v = normalize(self.velocity);
	setorigin(self, self.origin - 8*v);
	if (self.weapon == 1) te_wizspike(self.origin);
	else if (self.weapon == 2) te_knightspike(self.origin);
	else                       te_spike(self.origin);

	remove(self);
};

void(vector org, vector vel, entity own, float damage, float super, string dethtype, void(entity t, entity a, string m, float dtyp) obitfunc) launch_spike =
{
	newmis = spawn ();
	newmis.shoulddodge = TRUE;
	newmis.dangerrating = damage;
	newmis.health = damage;
	newmis.weapon = super;
	if (super == 1)
	{
		setmodel (newmis, "progs/w_spike.mdl");
//		newmis.effects = EF_ADDITIVE;
	}
	else if (super == 2)
	{
		setmodel (newmis, "progs/k_spike.mdl");
//		newmis.effects = EF_ADDITIVE;
	}
	else
		setmodel (newmis, "progs/s_spike.mdl");
	setsize (newmis, VEC_ORIGIN, VEC_ORIGIN);
	setorigin (newmis, org);
	newmis.velocity = vel;
	newmis.speed = vlen(vel);
	newmis.dest = newmis.velocity;
	newmis.deathtype = dethtype;
	newmis.obitfunc1 = obitfunc;
	newmis.owner = own;
	newmis.movetype = MOVETYPE_FLY;
	newmis.solid = SOLID_BBOX;
	newmis.angles = vectoangles(vel);
	newmis.touch = spike_touch;
	newmis.classname = "spike";
	newmis.think = SUB_Remove;
	newmis.nextthink = time + 6;
};

/*
==============================================================================

PLASMA

==============================================================================
*/

void() plasma_touch =
{
	local vector v;
	if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
	{
		remove(self);
		return;
	}
	if (other == self.owner)
		return;
	if (other.owner == self.owner)
		return;
	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}
	v = normalize(self.velocity);
	T_Damage(other, self, self.realowner, self.dmg, self.dmg, self.deathtype, DT_PLASMA, self.origin, v * self.count2, self.obitfunc1);
	T_RadiusDamage(self, self.realowner, self.dmg, self.count2, self.dmg2, other, self.deathtype, DT_PLASMA, self.obitfunc1);
	sound(self, CHAN_WEAPON, "plasma/plasexpl.wav", 1, ATTN_NORM);
	effect(self.origin - v * 16, "progs/plasmashot.spr32", 10, 5, 30);
	te_plasmaburn(self.origin - v);
	remove(self);
};

void() plasma_think =
{
	self.nextthink = time;
	if (time > self.cnt)
	{
		self.cnt = time + 0.1;
		self.frame = self.frame + 1;
		if (self.frame >= 10)
			self.frame = 0;
	}
	if (time > self.count)
		remove(self);
};

void(entity own, entity realown, vector org, vector vel, float damg, float force, float damg2, string dethtype, void(entity t, entity a, string m, float dtyp) obitfunc) FirePlasma =
{
	//sound (own, CHAN_WEAPON, "plasma/plasma.wav", 1, ATTN_NORM);
	//sound (own, CHAN_WEAPON, "weapons/rocket1i.wav", 1, ATTN_NORM);

	fightdone = time + 1; // delay stuff until fighting is over

	newmis = spawn();
	newmis.classname = "plasma";
	newmis.owner = own;
	newmis.realowner = realown;
	newmis.solid = SOLID_BBOX;
	newmis.movetype = MOVETYPE_FLY; //TOSS; //FLYMISSILE;
	setmodel(newmis, "progs/plasmashot.spr32");
	setsize(newmis, '0 0 0', '0 0 0');
	setorigin(newmis, org);
	newmis.effects = EF_LOWPRECISION;
	newmis.velocity = vel;// + self.velocity;
	newmis.dmg = damg;
	newmis.count2 = force;
	newmis.dmg2 = damg2;
	if (self.items & IT_QUAD)
	{
		newmis.effects = newmis.effects | EF_BLUE;
		newmis.dmg = newmis.dmg * 4;
		newmis.count2 = newmis.count2 * 4;
	}
	newmis.deathtype = dethtype;
	newmis.obitfunc1 = obitfunc;
//	newmis.frame = random() * 9.999;
//	newmis.frame = floor(newmis.frame);
	newmis.count = time + 20;
	newmis.touch = plasma_touch;
	newmis.think = plasma_think;
	newmis.nextthink = time + 0.1;
	// FIXME: make a smaller sprite
	newmis.scale = 0.5;
};

void() plasmaball_touch =
{
	local vector v;
	if (other == self.owner)
		return;
	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}
	if (other.solid != SOLID_BSP)
		return;
	v = normalize(self.velocity);
	T_Damage(other, self, self.realowner, self.dmg, self.dmg, self.deathtype, DT_PLASMA, self.origin, v * self.count2, self.obitfunc1);
	T_RadiusDamage(self, self.realowner, self.dmg, self.count2, self.dmg2, other, self.deathtype, DT_PLASMA, self.obitfunc1);
	sound(self, CHAN_WEAPON, "plasma/plasexpl.wav", 1, ATTN_NORM);
	effect(self.origin - v * 16, "progs/plasmashot.spr32", 10, 5, 30);
	te_plasmaburn(self.origin - v);
	remove(self);
};

void() plasmaball_think =
{
	local float damage, step, steps;
	local vector backup;
	self.nextthink = time;
	if (time > self.cnt)
	{
		self.cnt = time + 0.1;
		self.frame = self.frame + 1;
		if (self.frame >= 10)
			self.frame = 0;
	}
	damage = self.dmg * (time - self.count1) * 5;
	if (damage >= 10)
	{
		self.count1 = time;
		steps = ceil(damage / 50);
		damage = damage / steps;
		backup = self.origin;
		step = 0;
		while (step < steps)
		{
			step = step + 1;
			self.origin = (backup - self.dest) * (step / steps) + self.dest;
			T_RadiusDamage(self, self.realowner, damage, 0, self.dmg2, self.owner, self.deathtype, DT_PLASMA, self.obitfunc1);
		}
		// the above loop leaves self.origin restored to what it should be
	}
	if (time > self.count)
		remove(self);
};

void(entity own, entity realown, vector org, vector vel, float damg, float force, float damg2, string dethtype, void(entity t, entity a, string m, float dtyp) obitfunc) FirePlasmaBall =
{
	//sound (own, CHAN_WEAPON, "plasma/plasma.wav", 1, ATTN_NORM);
	//sound (own, CHAN_WEAPON, "weapons/rocket1i.wav", 1, ATTN_NORM);

	fightdone = time + 1; // delay stuff until fighting is over

	newmis = spawn();
	newmis.classname = "plasmaball";
	newmis.owner = own;
	newmis.realowner = realown;
	newmis.solid = SOLID_TRIGGER;
	newmis.movetype = MOVETYPE_FLY;
	setmodel(newmis, "progs/plasmashot.spr32");
	setsize(newmis, '0 0 0', '0 0 0');
	setorigin(newmis, org);
	newmis.effects = EF_LOWPRECISION;
	newmis.velocity = vel;// + self.velocity;
	newmis.dmg = damg;
	newmis.count2 = force;
	newmis.dmg2 = damg2;
	if (self.items & IT_QUAD)
	{
		newmis.effects = newmis.effects | EF_BLUE;
		newmis.dmg = newmis.dmg * 4;
		newmis.count2 = newmis.count2 * 4;
	}
	newmis.deathtype = dethtype;
	newmis.obitfunc1 = obitfunc;
//	newmis.frame = random() * 9.999;
//	newmis.frame = floor(newmis.frame);
	newmis.count = time + 50;
	newmis.count1 = time;
	newmis.dest = self.origin;
	newmis.touch = plasmaball_touch;
	newmis.think = plasmaball_think;
	newmis.nextthink = time + 0.1;
};




/*
==============================================================================

PROXIMITY MINES

==============================================================================
*/

float MINE_LASERTRIP = 1;
float MINE_PROXIMITY = 2;
float MINE_IMMUNETODAMAGE = 4;
float MINE_DETONATABLE = 16;
float MINE_HOP = 32;
float MINE_IMPACTCREATURE = 128;

.float activemines;
void() MineExplode =
{
	local vector v;
	self.owner.activemines = self.owner.activemines - 1;
	if (self.lefty == 2)
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
				if (head != self.owner)
				if (head.team == 0 || !teamplay || (head.team != self.owner.team && (self.owner.classname != "player" || teamplay != TP_COOP)))
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
