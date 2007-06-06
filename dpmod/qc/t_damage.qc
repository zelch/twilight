
/*
============
Killed
============
*/
void(entity targ, entity attacker, string dmsg, float dtype, void(entity t, entity a, string m, float dtyp) obitfunc) Killed =
{
	local entity oself;

	oself = self;
	self = targ;

	// clean up wanderpath
	if (self.movetarget.classname == "monster_wanderpath")
	{
		remove(self.movetarget);
		self.movetarget = world;
	}

	// I honestly don't care if it shows a strange number,
	// and disabling this means I can check for worse damage
	// in the kill messages etc.
	// infact I've never seen a case where the number shows,
	// always hidden by the score bar stuff.
	// if (self.health < -99)
	//         self.health = -99;              // don't let sbar look bad if a player

	if (self.movetype == MOVETYPE_PUSH || self.movetype == MOVETYPE_NONE)
	{	// doors, triggers, etc
		self.th_die ();
		self = oself;
		return;
	}

	self.takedamage = DAMAGE_NO;
	self.touch = SUB_Null;

	if (!self.iscorpse)
	{
		// bump the monster counter
		if (self.flags & FL_MONSTER)
		{
			self.enemy = attacker;
			killed_monsters = killed_monsters + 1;
			WriteByte (MSG_ALL, SVC_KILLEDMONSTER);
		}
		ClientObituary(self, attacker, dmsg, dtype, obitfunc);
		monster_death_use();
	}

	self.doobits = 0;
	//self.think = self.th_die;
	self.th_die ();

	self = oself;
};

void() frozenthink =
{
	if (self.deadflag == DEAD_DYING)
		self.deadflag = DEAD_DEAD;
	if (time < self.thawtime)
	{
		self.frozen = TRUE;
		self.nextthink = time;
		// FIXME: this really doesn't look much like ice...
		self.effects = self.thawedeffects | (EF_FULLBRIGHT | EF_BLUE);
		if (time > self.thawtime - 1)
		if (((self.thawtime - time) * 10) & 1)
			self.effects = self.thawedeffects;
	}
	else
	{
		// FIXME: play a thaw sound
		bprint("thaw ");bprint(self.classname);bprint("\n");
		self.frozen = FALSE;
		self.effects = self.thawedeffects;
		self.think = self.thawedthink;
		self.nextthink = time + self.thawedthinkdelay;
		self.touch = self.thawedtouch;
		self.movetype = self.thawedmovetype;
	}
};

void(entity ent) freezeentity =
{
	local float freezetime;
	freezetime = 10;
	if (ent.classname == "player")
		freezetime = 2;
	if (ent.radsuit_finished > time)
		freezetime = freezetime * 0.2;
	if (ent.resist_ice)
		freezetime = freezetime * ent.resist_ice;
	if (freezetime < 0.1)
		return;
	if (!ent.frozen)
	{
		// FIXME: play a freeze sound
		bprint("freeze ");bprint(ent.classname);bprint("\n");
		ent.frozen = TRUE;
		ent.thawedeffects = ent.effects;
		ent.thawedthink = ent.think;
		ent.thawedthinkdelay = ent.nextthink - time;
		ent.thawedtouch = ent.touch;
		ent.thawedmovetype = ent.movetype;
		ent.touch = SUB_Null;
		ent.movetype = MOVETYPE_NONE;
	}
	ent.think = frozenthink;
	ent.nextthink = time;
	ent.thawtime = time + freezetime;
};

void(entity ent) restorefrozenentity =
{
	if (!ent.frozen)
		return;
	ent.frozen = FALSE;
	ent.effects = ent.thawedeffects;
	ent.think = ent.thawedthink;
	ent.nextthink = time + ent.thawedthinkdelay;
	ent.touch = ent.thawedtouch;
	ent.movetype = ent.thawedmovetype;
};

void(entity ent) refreezefrozenentity =
{
	if (ent.frozen)
		return;
	ent.frozen = TRUE;
	ent.thawedeffects = ent.effects;
	ent.thawedthink = ent.think;
	ent.thawedthinkdelay = ent.nextthink - time;
	ent.think = frozenthink;
	ent.nextthink = time;
	ent.touch = SUB_Null;
	ent.movetype = MOVETYPE_NONE;
};

/*
============
T_Damage

The damage is coming from inflictor, but get mad at attacker
This should be the only function that ever reduces health.
============
*/
void() FoundTarget;
.float painenemytime;
void(entity targ, entity inflictor, entity attacker, float healthdamage, float damage, string dethtype, float damgtype, vector damgpoint, vector force, void(entity t, entity a, string m, float dtyp) obitfunc) T_Damage =
{
	local entity oldself;
	local float save, htake, take, ratio;

	oldself = self;

	// figure momentum add
	if (force != '0 0 0') // trying to push?
	if (targ.forcescale > 0) // can it be moved?
	{
		if (targ.flags & FL_ONGROUND)
		{
			targ.flags = targ.flags - FL_ONGROUND;
			tracebox(targ.origin, targ.mins, targ.maxs, targ.origin + '0 0 1', FALSE, targ);
			setorigin(targ, trace_endpos);
		}
		//if (targ.movetype != MOVETYPE_NONE)
		if (targ.movetype != MOVETYPE_NOCLIP)
		if (targ.movetype != MOVETYPE_PUSH)
		{
			targ.flags = targ.flags - (targ.flags & FL_ONGROUND);
			targ.velocity = targ.velocity + force * targ.forcescale;
			targ.punchvector = targ.punchvector + force * targ.forcescale * -0.2;
			if (vlen(targ.punchvector) > 4)
				targ.punchvector = normalize(targ.punchvector) * 4;
		}
		if (targ.knockedloosefunc)
		{
			self = targ;
			targ.knockedloosefunc();
			self = oldself;
		}
	}

	if (!targ.takedamage)
		return;

	if (damgtype & DTF_FREEZE)
	{
		if (targ.frozen)
			freezeentity(targ);
		else
		{
			freezeentity(targ);
			return;
		}
	}


	// used by buttons and triggers to set activator for target firing
	damage_attacker = attacker;

	if (damgtype & DTF_TELEFRAG)
	{
		// used by buttons and triggers to set activator for target firing
		damage_attacker = attacker;
		htake = 50000;
		save = targ.armorvalue;
		take = 50000;
		targ.health = -1;
		targ.bodyhealth = -1000;
		targ.armorvalue = 0;
		targ.armortype = 0;
		targ.velocity = '0 0 0';
	}
	else
	{
		if (damage <= 0) // no damage to begin with
			return;
		if (targ.spawnshieldtime >= time || targ.invincible_finished >= time)
		{
			if (self.invincible_sound < time)
			{
				sound (targ, CHAN_ITEM, "items/protect3.wav", 1, ATTN_NORM);
				self.invincible_sound = time + 2;
			}
			return;
		}

// team play damage avoidance
		if (teamplay)
		if (targ.team > 0)
		if (attacker.team > 0)
		if (teamplay != TP_CANHURTTEAM)
		if (attacker.classname == "player")
		if (targ.classname == "player")
		{
			if (targ == attacker)
			{
				if (teamplay != TP_NOTEAMDAMAGE)
				if (teamplay != TP_COOP)
					return;
			}
			else
			{
				if (targ.team == attacker.team)
					return;
				if (teamplay == TP_COOP)
					return;
			}
		}

		// consult the target's damage modifier code and resistance data
		ratio = 1.0;
		if (targ.damagemodifier)
			ratio = ratio * targ.damagemodifier(targ, healthdamage, damage, damgtype, dethtype);

		if (attacker.flags & FL_MONSTER) ratio = ratio * monsterdamagescale;
		if (attacker.classname == "player") ratio = ratio * playerdamagescale;

		if (targ.resist_bullet   ) if (damgtype & DTF_RESIST_BULLET   ) ratio = ratio * targ.resist_bullet;
		if (targ.resist_explosive) if (damgtype & DTF_RESIST_EXPLOSIVE) ratio = ratio * targ.resist_explosive;
		if (targ.resist_energy   ) if (damgtype & DTF_RESIST_ENERGY   ) ratio = ratio * targ.resist_energy;
		if (targ.resist_fire     ) if (damgtype & DTF_RESIST_FIRE     ) ratio = ratio * targ.resist_fire;
		if (targ.resist_axe      ) if (damgtype & DTF_RESIST_AXE      ) ratio = ratio * targ.resist_axe;
		if (targ.flags & FL_MONSTER) ratio = ratio * monsterresistancescale;

		if (ratio <= 0) // resistance prevented damage
			return;

		// apply resistances
		healthdamage = healthdamage * ratio;
		damage = damage * ratio;

		// healthdamage can only be more than damage
		if (healthdamage < damage)
			healthdamage = damage;

		ratio = healthdamage / damage; // all calcs are done on damage
		// how much bleed damage 'matters'
		ratio = (ratio - 1) * targ.bleedratio + 1;

		// save damage based on the target's armor level
		take = damage; // body damage
		save = 0;
		if (damgtype & DTF_ARMOR)
		{
			save = targ.armortype * damage;
			if (save >= 0.1)
			{
				if (save > targ.armorvalue)
					save = targ.armorvalue;
				targ.armorvalue = targ.armorvalue - save;
				take = take - save;
			}
			else
				save = 0;
		}
		if (take <= 0)
			take = 0;
		if (take == 0)
		if (save == 0)
			return; // no damage to do

		htake = take * ratio; // health damage
		if (htake < 0.01) htake = 0.01;

		// add to the damage total for clients, which will be sent as a single
		// message at the end of the frame
		// FIXME: remove after combining shotgun blasts?
		if (targ.flags & FL_CLIENT)
		{
			targ.dmg_take = targ.dmg_take + htake;
			targ.dmg_save = targ.dmg_save + save;
			targ.dmg_inflictor = inflictor;
		}

		if (targ.bleedfunc)
		{
			self = targ;
			self.bleedfunc(damgpoint, take, save, force, damgtype);
			self = oldself;
		}

		if (targ.flags & FL_GODMODE)
			return;

		// moved below bleedfunc for sake of showing the correct armortype
		if (targ.armorvalue < 1)
		{
			targ.armorvalue = 0;
			targ.armortype = 0;     // lost all armor
			targ.items = targ.items - (targ.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3));
		}

		// do the damage
		targ.health = targ.health - htake;
		targ.bodyhealth = targ.bodyhealth - take;
	}

	targ.regenthink = time + 2; // stop regeneration for 2 sec

	targ.deathmsg = dethtype;
	// check health < 1 because values in the range 0-.9999 are shown as 0 on the client, which makes the view tilt and scoreboard show, even though the player is not really dead yet
	if (targ.health < 1)
	if (targ.th_die)
	if (targ.th_die != SUB_Null)
	if (!targ.iscorpse || targ.bodyhealth <= 0)
	{
		Killed (targ, attacker, dethtype, damgtype, obitfunc);
		return;
	}

	// react to the damage
	self = targ;

	if ( (self.flags & FL_MONSTER) && attacker != world)
	if (attacker.takedamage)
	if (time > self.painenemytime || self.enemy == world)
	{
	// get mad unless of the same class (except for soldiers)
		if (self != attacker && attacker != self.enemy)
		{
			if ( (self.classname != attacker.classname)
			|| (self.classname == "monster_army" ) )
			{
				if (self.enemy.classname == "player")
					self.oldenemy = self.enemy;
				self.painenemytime = time + 1;
				self.enemy = attacker;
				FoundTarget ();
			}
		}
	}

	if (self.th_pain)
	if (!self.frozen)
	{
		self.healthlostthisframe = self.healthlostthisframe + htake;
		self.th_pain (attacker, self.healthlostthisframe, damgtype, dethtype);
		// nightmare mode monsters don't go into pain frames often
		if (skill >= 3)
		if (self.flags & FL_MONSTER)
			self.pain_finished = time + 5;
	}

	self = oldself;
};

float(entity targ, entity ignore, vector org, float checkcount) CanRadDamage =
{
	local vector v, m1, m2;
	local float c, d, s;
	// hack to make tracelines hit dead bodies
	s = ignore.solid;
	if (s == SOLID_SLIDEBOX)
		ignore.solid = SOLID_BBOX;
	m1 = targ.mins + targ.origin;
	m2 = targ.maxs + targ.origin - m1;
	d = 0;
	c = 0;
	while(c < checkcount)
	{
		c = c + 1;
		v_x = m1_x + random() * m2_x;
		v_y = m1_y + random() * m2_y;
		v_z = m1_z + random() * m2_z;
		traceline(org, v, MOVE_NOMONSTERS, ignore);
		if (!trace_startsolid)
		if (trace_fraction == 1 || trace_ent == targ)
			d = d + 1;
	}
	if (s == SOLID_SLIDEBOX)
		ignore.solid = s;
	return (d / checkcount);
};

// Quake style falloff
float(entity targ, entity ignore, vector org, float radius, float checkcount) LinearRadDamage =
{
	local vector v, m1, m2;
	local float b, dist;
	m1 = targ.mins + targ.origin;
	m2 = targ.maxs + targ.origin;
	// find nearest point and calc damage for that
	v_x = bound(m1_x, org_x, m2_x);
	v_y = bound(m1_y, org_y, m2_y);
	v_z = bound(m1_z, org_z, m2_z);
	dist = vlen(v - org);
	// if really close, do full damage
	if (dist < 2)
	{
		raddamage_lasthit = org;
		return 1;
	}
	// if outside radius, do no damage
	if (dist >= radius)
		return 0;
	// calculate distance-attenuated damage
	b = 1 - dist/radius;
	if (b <= 0)
		return 0; // no damage

	raddamage_lasthit = v;

	// direct hit
	traceline(org, v, MOVE_NOMONSTERS, ignore);
	if (!trace_startsolid)
	if (trace_fraction == 1 || trace_ent == targ)
		return b;

	// partial hit
	return b * CanRadDamage(targ, ignore, org, checkcount);
};


/*
============
T_RadiusDamage
============
*/
void(entity inflictor, entity attacker, float damage, float force, float radius, entity ignore, string dethtype, float damgtype, void(entity t, entity a, string m, float dtyp) obitfunc) T_RadiusDamage =
{
	local	float	points, damagepoints, forcepoints, wt, d, ownerdamagescale;
	local	entity	head;
	local	vector	v, l;

	/*
	traceline(inflictor.origin, inflictor.origin, TRUE, world);
	if (trace_startsolid)
	{
		dprint("T_RadiusDamage: inflictor in a solid\n");
		return; // uh, it's in a wall, uh, lets be as sensible as we can in this strange situation...
	}
	*/
	wt = pointcontents(inflictor.origin);
	if ((wt != CONTENT_WATER) && (wt != CONTENT_SLIME))
		wt = 0;
	ownerdamagescale = inflictor.radiusdamage_ownerdamagescale;
	if (!ownerdamagescale)
		ownerdamagescale = 0.5;

	damgtype = damgtype | DTF_INDIRECT; // splash not direct damage

	// first count the damage
	// (we can't apply it here because th_pain or th_die functions might call findradius, messing up the chain)
	head = findradius(inflictor.origin, radius + 4);
	while (head)
	{
		if (head.takedamage)
		if (!head.isdecor)
		if (head.classname != "ragdoll_particle")
		if (head != ignore)
		{
			points = LinearRadDamage(head, ignore, inflictor.origin, radius, 3);
			if (points > 0)
			{
				damagepoints = damage * points;
				forcepoints = force * points;
				if (head == attacker)
					damagepoints = damagepoints * ownerdamagescale;
				head.radiusdamage_amount = head.radiusdamage_amount + damagepoints;
				head.radiusdamage_force = head.radiusdamage_force + normalize((head.absmin + head.absmax) * 0.5 - inflictor.origin) * forcepoints;
				head.radiusdamage_hit = 1;
				head.radiusdamage_lasthit = raddamage_lasthit;
			}
		}
		head = head.chain;
	}

	// then apply it
	head = findfloat(world, radiusdamage_hit, 1);
	while (head)
	{
		d = head.radiusdamage_amount;
		v = head.radiusdamage_force;
		l = head.radiusdamage_lasthit;
		head.radiusdamage_amount = 0;
		head.radiusdamage_hit = 0;
		head.radiusdamage_force = '0 0 0';
		head.radiusdamage_lasthit = '0 0 0';
		if (d > 0 || v != '0 0 0')
			T_Damage (head, inflictor, attacker, d, d, dethtype, damgtype, l, v, obitfunc);
		head = findfloat(head, radiusdamage_hit, 1);
	}

	// now push around gibs and ragdolls and such
	// (such as those made by a corpse which was just gibbed)
	head = findradius(inflictor.origin, radius + 4);
	while (head)
	{
		if (head.isdecor || head.classname == "ragdoll_particle")
		{
			points = LinearRadDamage(head, ignore, inflictor.origin, radius, 1);
			if (points > 0)
			{
				d = damage * points;
				v = normalize((head.absmin + head.absmax) * 0.5 - inflictor.origin) * (force * points);
				T_Damage (head, inflictor, attacker, d, d, dethtype, damgtype, head.radiusdamage_lasthit, v, obitfunc);
			}
		}
		head = head.chain;
	}
};


/*
============
CanDamage

Returns true if the inflictor can directly damage the target.  Used for
explosions and melee attacks.
============
*/
float(entity targ, entity inflictor) CanDamage =
{
// bmodels need special checking because their origin is 0,0,0
	if (targ.movetype == MOVETYPE_PUSH)
	{
		traceline(inflictor.origin, 0.5 * (targ.absmin + targ.absmax), TRUE, self);
		if (trace_fraction == 1)
			return TRUE;
		if (trace_ent == targ)
			return TRUE;
		return FALSE;
	}

	traceline(inflictor.origin, targ.origin, TRUE, self);
	if (trace_fraction == 1)
		return TRUE;
	traceline(inflictor.origin, targ.origin + '15 15 0', TRUE, self);
	if (trace_fraction == 1)
		return TRUE;
	traceline(inflictor.origin, targ.origin + '-15 -15 0', TRUE, self);
	if (trace_fraction == 1)
		return TRUE;
	traceline(inflictor.origin, targ.origin + '-15 15 0', TRUE, self);
	if (trace_fraction == 1)
		return TRUE;
	traceline(inflictor.origin, targ.origin + '15 -15 0', TRUE, self);
	if (trace_fraction == 1)
		return TRUE;

	return FALSE;
};
