float   damagescale;
.void() knockedloosefunc; // called when kinetically disturbed
.float  forcescale; // used for damage force calculations (shambler has lower forcescale than player for instance)

// how much bleeding 'matters' to this entity, a percentage between
// bodydamage (-1 = 0% as 0 doesn't work) and healthdamage (1.0 = 100%)
// for instance a player is 100% and a zombie is 0% (bleeding doesn't matter)
.float  bleedratio;
.float(entity e, float healthdamage, float damage, float damgtype, string dethtype) damagemodifier;

.void() th_gib;

.float  health; // if this goes below 1 the thing is dead
.float  bodyhealth; // used for gibbing

float   monsterdamagescale; // set in world.qc when level starts

void(entity targ, entity attacker, string dmsg, float dtype, void(entity t, entity a, string m, float dtyp) obitfunc) ClientObituary;

void() monster_death_use;

//============================================================================

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

	if ((self.flags & FL_MONSTER) && attacker != world)
		self.enemy = attacker;

	// bump the monster counter
	if (self.flags & FL_MONSTER && self.classname != "spawnedgrunt")
	{
		killed_monsters = killed_monsters + 1;
		WriteByte (MSG_ALL, SVC_KILLEDMONSTER);
	}

	ClientObituary(self, attacker, dmsg, dtype, obitfunc);

	self.takedamage = DAMAGE_NO;
	self.touch = SUB_Null;

	if (!self.iscorpse)
		monster_death_use();

	self.doobits = 0;
	//self.think = self.th_die;
	self.th_die ();

	self = oself;
};

/*
============
T_MaxBodyDamage

Returns how much damage is needed to gib this entity.
If higher than bodydamage, return bodydamage.
============
*/
/* FIXME: needs updating
float(entity targ, float damage, float damgtype) T_MaxBodyDamage =
{
	local   float   save, take, d, ratio;

	if (damage < 1)
		return 0;

	if (!targ.takedamage)
		return 0;

	// save damage based on the target's armor level
	save = 0;
	if (damgtype & DTF_ARMOR)
		save = ceil(targ.armortype * damage);
	if (save > targ.armorvalue)
		save = targ.armorvalue;
	take = ceil(damage-save); // body damage
	if (take > targ.bodyhealth)
		take = targ.bodyhealth;

	return take+save;
};
*/

/*
============
T_Damage

The damage is coming from inflictor, but get mad at attacker
This should be the only function that ever reduces health.
============
*/
.float  regenthink; // next time player will regen some health
void(entity targ, entity inflictor, entity attacker, float healthdamage, float damage, string dethtype, float damgtype, vector damgpoint, vector force, void(entity t, entity a, string m, float dtyp) obitfunc) T_Damage =
{
	local vector dir;
	local entity oldself;
	local float save, htake, take, ratio, f;

	oldself = self;

	// figure momentum add
	if (force != '0 0 0') // trying to push?
	if (targ.forcescale > 0) // can it be moved?
	{
		if (targ.knockedloosefunc)
		{
			self = targ;
			targ.knockedloosefunc();
			self = oldself;
		}
		if (targ.movetype != MOVETYPE_NONE)
		if (targ.movetype != MOVETYPE_NOCLIP)
		if (targ.movetype != MOVETYPE_PUSH)
		{
			targ.flags = targ.flags - (targ.flags & FL_ONGROUND);
			targ.velocity = targ.velocity + force * targ.forcescale;
			targ.punchvector = targ.punchvector + force * targ.forcescale * -0.2;
			if (vlen(targ.punchvector) > 4)
				targ.punchvector = normalize(targ.punchvector) * 4;
		}
	}

	if (!targ.takedamage)
		return;

	if (damgtype == DTF_TELEFRAG)
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

		if (targ.resist_bullet   ) if (damgtype & DTF_RESIST_BULLET   ) ratio = ratio * targ.resist_bullet;
		if (targ.resist_explosive) if (damgtype & DTF_RESIST_EXPLOSIVE) ratio = ratio * targ.resist_explosive;
		if (targ.resist_energy   ) if (damgtype & DTF_RESIST_ENERGY   ) ratio = ratio * targ.resist_energy;
		if (targ.resist_fire     ) if (damgtype & DTF_RESIST_FIRE     ) ratio = ratio * targ.resist_fire;

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

		if (targ.classname == "player") // only protects players from damage
		if (attacker.flags & FL_MONSTER)
			damage = damage * monsterdamagescale;

		if (targ.items & IT_INVULNERABILITY)
		{
			if (targ != attacker && targ.classname == "player" && attacker.classname == "player")
				damage = damage * 0.33;
			else
				damage = 0;
		}

//		// check for quad damage powerup on the attacker
//		if (attacker.items & IT_QUAD)
//			damage = damage * 4;

		// save damage based on the target's armor level
		save = 0;
		if (damgtype & DTF_ARMOR)
			save = targ.armortype * damage;
		if (targ.team > 0)
		if (targ.team == attacker.team)
		if (teamplay == 1 || teamplay == 3)
		if (targ != attacker || teamplay == 1)
			save = 0;
		if (targ.flags & FL_GODMODE)
			save = 0;

		if (save > targ.armorvalue)
			save = targ.armorvalue;
		targ.armorvalue = targ.armorvalue - save;
		take = damage - save; // body damage
		if (take < 0)
			take = 0;

		if (take < 0.01)
		if (save < 0.01)
			return; // no damage to do

		htake = take * ratio; // health damage
		if (htake < 0.01) htake = 0.01;

		if (targ.bleedfunc) // telefrag doesn't cause bleeding
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

		if (attacker.items & IT_QUAD) // Fury is vampiric
		if (attacker.classname == "player")
		if (targ.iscreature)
		if (targ != attacker)
		if (targ.health > 0)
		{
			f = 0.1;
			if (targ.classname == "player")
				f = 0.5;
			f = attacker.health + min(htake, targ.health) * f;
			f = min(f, HEALTHMEGAMAX);
			attacker.health = max(f, attacker.health);
		}

		// do the damage
		targ.health = targ.health - htake;
//		if (damgtype & DTF_RESIST_EXPLOSIVE)
//			targ.bodyhealth = targ.bodyhealth - take;
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
	{
		self.th_pain (attacker, htake);
		// nightmare mode monsters don't go into pain frames often
		if (skill >= 3)
		if (self.flags & FL_MONSTER)
			self.pain_finished = time + 5;
	}

	self = oldself;
};
