
void() FireballExplode =
{
	BecomeExplosion(self, self.dmg, self.count2, self.dmg2, world, self.deathtype, '0 0 0', FALSE, self.obitfunc1);
};

void(vector org, vector vel, entity own, float damg, float force, float blastradius, string dethtype, void(entity t, entity a, string m, float dtyp) obitfunc) LaunchFireball =
{
	newmis = spawn ();
	newmis.deathtype = dethtype;
	newmis.obitfunc1 = obitfunc;
	newmis.shoulddodge = TRUE;
	newmis.dangerrating = blastradius;
	newmis.owner = own;
	newmis.createdtime = time;
	newmis.movetype = MOVETYPE_FLYMISSILE;
	newmis.solid = SOLID_BBOX;
	newmis.classname = "fireball";
	newmis.velocity = vel;
	newmis.angles = vectoangles(newmis.velocity);
	newmis.touch = FireballExplode;
	newmis.think = FireballExplode;
	newmis.nextthink = time + 15;
	newmis.dmg = damg;
	newmis.count2 = force;
	newmis.dmg2 = blastradius;
	newmis.effects = EF_RED | EF_FULLBRIGHT;

	if (own.items & IT_QUAD)
	{
		newmis.effects = newmis.effects | EF_BLUE;
		newmis.dmg = newmis.dmg * 4;
		newmis.count2 = newmis.count2 * 4;
	}

	setmodel (newmis, "progs/lavaball.mdl");
	setsize (newmis, '0 0 0', '0 0 0');
	setorigin (newmis, org);
};
