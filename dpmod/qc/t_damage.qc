
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

.float frozen;
.float thawtime;
.float thawedeffects;
.void() thawedtouch;
.float thawedmovetype;
.void() thawedthink;
.float thawedthinkdelay;

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
.float regenthink; // next time player will regen some health
void(entity targ, entity inflictor, entity attacker, float healthdamage, float damage, string dethtype, float damgtype, vector damgpoint, vector force, void(entity t, entity a, string m, float dtyp) obitfunc) T_Damage =
{
	local entity oldself;
	local float save, htake, take, ratio;

	if (damgtype & DTF_FREEZE)
	if (targ.takedamage)
	{
		if (targ.frozen)
			freezeentity(targ);
		else
		{
			freezeentity(targ);
			return;
		}
	}

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
		if (damage < 1) // no damage to begin with
			return;

		// used by buttons and triggers to set activator for target firing
		damage_attacker = attacker;

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
		if (targ.flags & FL_MONSTER) ratio = ratio * monsterresistancescale;
		if (targ.items & IT_INVULNERABILITY)
		{
			if (attacker.classname == "player" && targ.classname == "player" && targ != attacker)
				ratio = ratio * 0.33;
			else
				ratio = 0;
		}

//		// check for quad damage powerup on the attacker
//		if (attacker.items & IT_QUAD)
//			ratio = ratio * 4;

		if (targ.team > 0)
		if (targ.team == attacker.team)
		if (teamplay == 1 || teamplay == 3)
		if (targ != attacker || teamplay == 1)
			ratio = 0;
		if (targ.flags & FL_GODMODE)
			ratio = 0;

		// apply resistances
		healthdamage = healthdamage * ratio;
		damage = damage * ratio;

		if (damage < 1) // resistance prevented damage
			return;

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

		if (targ.bleedfunc)
		{
			self = targ;
			self.bleedfunc(damgpoint, take, save, force, damgtype);
			self = oldself;
		}

		// moved below bleedfunc for sake of showing the correct armortype
		if (targ.armorvalue < 1)
		{
			targ.armorvalue = 0;
			targ.armortype = 0;     // lost all armor
			targ.items = targ.items - (targ.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3));
		}

		// add to the damage total for clients, which will be sent as a single
		// message at the end of the frame
		// FIXME: remove after combining shotgun blasts?
		if (targ.flags & FL_CLIENT)
		{
			targ.dmg_take = targ.dmg_take + take;
			targ.dmg_save = targ.dmg_save + save;
			targ.dmg_inflictor = inflictor;
		}

		// team play damage avoidance
		if (teamplay == 1 || teamplay == 3)
		if (targ.team > 0)
		if (targ.team == attacker.team)
		if (targ != attacker || teamplay == 1)
			return;

		if (targ.flags & FL_GODMODE)
			return;

		// do the damage
		targ.health = targ.health - htake;
		targ.bodyhealth = targ.bodyhealth - take;
	}

	targ.regenthink = time + 2; // stop regeneration for 2 sec

	targ.deathmsg = dethtype;
	if (targ.th_die)
	if (targ.th_die != SUB_Null)
	{
		if (targ.iscorpse)
		{
			if (targ.bodyhealth < 1)
			{
				Killed (targ, attacker, dethtype, damgtype, obitfunc);
				return;
			}
		}
		else
		{
			if (targ.health < 1)
			{
				Killed (targ, attacker, dethtype, damgtype, obitfunc);
				return;
			}
		}
	}

	// react to the damage
	self = targ;

	if ((self.flags & FL_MONSTER) && attacker != world) // get mad unless of the same class (except for soldiers)
	if (self != attacker && attacker != self.enemy)
	if (self.classname != attacker.classname || self.classname == "monster_army")
//	//if (attacker.classname == "player")
	if (attacker.takedamage)
	if (attacker.havocattack == TRUE)
	{
		if (self.enemy.classname == "player")
			self.oldenemy = self.enemy;
		self.enemy = attacker;
		FoundTarget ();
	}

	if (self.th_pain)
	if (!self.frozen)
	{
		self.th_pain (attacker, htake);
		// nightmare mode monsters don't go into pain frames often
		if (skill >= 3)
		if (self.flags & FL_MONSTER)
			self.pain_finished = time + 5;
	}

	self = oldself;
};
