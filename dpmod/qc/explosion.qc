entity  xplo;
float   maxdecors;

void() explosionfx_precache =
{
	//precache_model("progs/s_explod.spr");
	precache_model("progs/dpexplosion.spr32");
	precache_sound("weapons/r_exp3.wav");
};

void() harmlessfireball_think =
{
	self.nextthink = time + 0.01;
	self.angles = vectoangles(self.velocity);
	if (time > self.cnt)
		remove(self);
};

void(vector org, vector vel, float lifetime) SpawnHarmlessFireball =
{
	newmis = spawn();
	newmis.classname = "harmlessfireball";
	setorigin(newmis, org);
	setmodel(newmis, "progs/fireball.mdl");
	setsize (newmis, '0 0 0', '0 0 0');
	newmis.velocity = vel;
	newmis.think = harmlessfireball_think;
	newmis.nextthink = time + 0.01;
	newmis.cnt = time + lifetime;
	newmis.solid = SOLID_NOT;
	newmis.movetype = MOVETYPE_BOUNCE;
	newmis.effects = EF_ADDITIVE;
};

void(vector org, entity attacker, float damg, float radius, string dt, vector explosioncolor, float quad, void(entity t, entity a, string m, float dtyp) obitfunc) Explosion =
{
	local vector v;
	local entity e;
	e = spawn();
	e.owner = attacker;
	setorigin(e, org);
	findbetterlocation2(e);

	if (explosioncolor == '0 0 0')
	{
		if (quad)
			te_explosionquad(org);
		else
			te_explosion(org);
	}
	else
		te_explosionrgb(e.origin, explosioncolor);

	T_RadiusDamage(e, attacker, damg, radius, world, dt, DT_EXPLOSION, obitfunc);
	remove(e);

	v = findbetterlocation3(org); // move animation away from walls
	//effect(v, "progs/s_explod.spr", 0, 6, 10);
	effect(v, "progs/dpexplosion.spr32", 0, 20, 40);

	/*
	// LordHavoc: HACKY HACKY, experimental!!
	WriteByte(MSG_BROADCAST, svc_cgame);
	WriteShort(MSG_BROADCAST, 13);
	WriteByte(MSG_BROADCAST, 1); // explosion rubble
	WriteCoord(MSG_BROADCAST, v_x);
	WriteCoord(MSG_BROADCAST, v_y);
	WriteCoord(MSG_BROADCAST, v_z);
	*/
};

void(vector org, entity attacker, float damg, float radius, entity ignore, string dt, vector explosioncolor, float quad, void(entity t, entity a, string m, float dtyp) obitfunc) ExplosionIgnore =
{
	local vector v;
	local entity e;
	e = spawn();
	e.owner = attacker;
	setorigin(e, org);
	findbetterlocation2(e);

	if (explosioncolor == '0 0 0')
	{
		if (quad)
			te_explosionquad(org);
		else
			te_explosion(org);
	}
	else
		te_explosionrgb(e.origin, explosioncolor);

	T_RadiusDamage(e, attacker, damg, radius, ignore, dt, DT_EXPLOSION, obitfunc);
	remove(e);

	v = findbetterlocation3(org); // move animation away from walls
	//effect(v, "progs/s_explod.spr", 0, 6, 10);
	effect(v, "progs/dpexplosion.spr32", 0, 20, 40);

	/*
	// LordHavoc: HACKY HACKY, experimental!!
	WriteByte(MSG_BROADCAST, svc_cgame);
	WriteShort(MSG_BROADCAST, 13);
	WriteByte(MSG_BROADCAST, 1); // explosion rubble
	WriteCoord(MSG_BROADCAST, v_x);
	WriteCoord(MSG_BROADCAST, v_y);
	WriteCoord(MSG_BROADCAST, v_z);
	*/
};

void(entity e, float damg, float radius, string dt, vector explosioncolor, float quad, void(entity t, entity a, string m, float dtyp) obitfunc) BecomeExplosion =
{
	local vector org, v, v2;
	if (e.solid == SOLID_BSP)
	{
		e.solid = SOLID_NOT;
		e.model = "";
		setorigin(e, (e.absmin + e.absmax) * 0.5);
	}
	else
	{
		e.solid = SOLID_NOT;
		e.model = "";
	}
	org = e.origin;
	findbetterlocation2(e);

	if (explosioncolor_x >= 0)
	{
		if (explosioncolor == '0 0 0')
		{
			if (quad)
				te_explosionquad(e.origin);
			else
				te_explosion(e.origin);
		}
		else
			te_explosionrgb(e.origin, explosioncolor);
	}
	else
	{
		sound(e, CHAN_AUTO, "weapons/r_exp3.wav", 1, ATTN_NORM);
		te_smallflash(e.origin);
	}

	T_RadiusDamage(e, e.owner, damg, radius, world, dt, DT_EXPLOSION, obitfunc);
	remove(e);

	v = findbetterlocation3(org); // move animation away from walls
	//effect(v, "progs/s_explod.spr", 0, 6, 10);
	effect(v, "progs/dpexplosion.spr32", 0, 20, 40);

	/*
	// LordHavoc: HACKY HACKY, experimental!!
	WriteByte(MSG_BROADCAST, svc_cgame);
	WriteShort(MSG_BROADCAST, 13);
	WriteByte(MSG_BROADCAST, 1); // explosion rubble
	WriteCoord(MSG_BROADCAST, v_x);
	WriteCoord(MSG_BROADCAST, v_y);
	WriteCoord(MSG_BROADCAST, v_z);
	*/
};

void(entity e, float damg, float radius, string dt) TarbabyExplosion =
{
	te_tarexplosion(e.origin);

	T_RadiusDamage(e, e, damg, radius, world, dt, DT_EXPLOSION, Obituary_Generic);

	//effect(e.origin, "progs/s_explod.spr", 0, 6, 10);
	effect(e.origin, "progs/dpexplosion.spr32", 0, 20, 40);

	remove(e);
};

