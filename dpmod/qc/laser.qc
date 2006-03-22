
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
