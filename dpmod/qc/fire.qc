/*
==============================================================================

FIRE

==============================================================================
*/

//float(entity bomb, entity attacker, float damage, float mburn, entity ignore, string dt) T_BurnRadius;
//void(vector org, vector vel, entity own, float damg, string dt) ThrowFlame;

void() fire_precache =
{
	precache_model("progs/flame2.mdl");
	precache_sound("fire/burn.wav");
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
	// local   vector  neworg, v;
	local   float   a, b;
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
		a = 4;b = 4;
		// nothing to burn
		if (self.enemy.takedamage == DAMAGE_NO) {a = b = 10;}
		//// for sake of single-player
		//if (self.enemy.flags & FL_MONSTER) {a = b = 5;}
		//// for better 'viewing' of burning gibs/whatever :)
		//if (self.enemy.iscorpse) {a = 10;b = 0;}
		////if (self.enemy.isgib) {a = 10;b = 0;}
		if (a == b)
		if (a > self.cnt)
			a = b = self.cnt;
		self.cnt = self.cnt - b;
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
/*
float(entity inflictor, entity attacker, float damage, float mburn, entity ignore, string dt) T_BurnRadius =
{
	local   float   points, p, c, dist;
	local   entity  head;

	if (damage > mburn)
		damage = mburn;

	head = findradius(inflictor.origin, damage+300);

	while (head)
	{
		if (head.takedamage)
		if (head.solid != SOLID_BSP)
		if (head != ignore)
		{
			points = RadDamage(head, ignore, inflictor.origin, damage, 3, 0.01);
			if (points > damage)
				points = damage;
			if (head.flame.classname == "fire")
			if ((head.flame.cnt + points) >= mburn)
				points = mburn - head.flame.cnt;
			if (points > 0)
				SpawnFire(head, attacker, points, dt, head.origin);
		}
		head = head.chain;
	}
};
*/
