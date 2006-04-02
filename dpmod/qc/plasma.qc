
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

/*
void() plasmaball_burn =
{
	local entity head;
	head = findradius(self.origin, self.dmg2);
};
*/

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
			//plasmaball_burn();
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


