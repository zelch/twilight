
void() spike_touch =
{
	if (other == self.owner)
		return;
	if (other.solid == SOLID_TRIGGER)
		return; // trigger field, do nothing
	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}
	self.dest = normalize(self.dest);
	setorigin(self, self.origin - 8*self.dest);
	T_Damage (other, self, self.owner, self.health, self.health, self.deathtype, DT_NAIL, self.origin, self.dest * self.health, self.obitfunc1);

	if (self.weapon == 1) te_wizspike(self.origin);
	else if (self.weapon == 2) te_knightspike(self.origin);
	else                       te_spike(self.origin);

	weaponwakeup(self.origin, self.owner);
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
