
void() plasma_touch =
{
	local   vector  v;
	if (other == self.owner)
		return;
	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}
	v = normalize(self.velocity);
	T_Damage(other, self, self.owner, self.dmg, self.dmg, self.deathtype, DT_PLASMA, self.origin, v * self.dmg, self.obitfunc1);
	T_RadiusDamage(self, self.owner, self.dmg, self.dmg2, other, self.deathtype, DT_PLASMA, self.obitfunc1);
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
	/*
	if (self.owner.classname == "player" && self.owner.weapon == IT_WEAPON8 && self.owner.viewzoom < 0.5)
	{
		makevectors(self.owner.v_angle);
		traceline(self.owner.origin + '0 0 16', self.owner.origin + '0 0 16' + v_forward * 65536, FALSE, self.owner);
		self.velocity = self.velocity + (normalize(trace_endpos - self.origin) * 10000 - self.velocity) * frametime * 5;
	}
	*/
	if (time > self.count)
		remove(self);
};

void(entity own, vector org, vector dir, float damg, float damg2, vector casingdir, string dethtype, void(entity t, entity a, string m, float dtyp) obitfunc) FirePlasma =
{
	local   vector  a;

	//sound (own, CHAN_WEAPON, "plasma/plasma.wav", 1, ATTN_NORM);
	sound (own, CHAN_WEAPON, "weapons/rocket1i.wav", 1, ATTN_NORM);

	fightdone = time + 1; // delay stuff until fighting is over

	newmis = spawn();
	newmis.classname = "plasma";
	newmis.owner = own;
	newmis.solid = SOLID_BBOX;
	newmis.movetype = MOVETYPE_FLY; //TOSS; //FLYMISSILE;
	setmodel(newmis, "progs/plasmashot.spr32");
	setsize(newmis, '0 0 0', '0 0 0');
	setorigin(newmis, org);
	newmis.effects = EF_LOWPRECISION;
	newmis.velocity = dir * 5000;// + self.velocity;
	newmis.dmg = damg;
	newmis.dmg2 = damg2;
	if (self.items & IT_QUAD)
	{
		newmis.dmg = newmis.dmg * 4;
		newmis.effects = newmis.effects | EF_BLUE;
	}
	newmis.deathtype = dethtype;
	newmis.obitfunc1 = obitfunc;
//	newmis.frame = random() * 9.999;
//	newmis.frame = floor(newmis.frame);
	newmis.count = time + 5;
	newmis.touch = plasma_touch;
	newmis.think = plasma_think;
	newmis.nextthink = time + 0.1;
};
