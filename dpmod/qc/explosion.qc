entity  xplo;
float   maxdecors;

void() explosionfx_precache =
{
	if (game == GAME_NEXUIZ)
	{
		precache_model("models/sprites/s_explod.spr");
		precache_model("models/sprites/dpexplosion1.spr32");
		precache_model("models/sprites/dpexplosion2.spr32");
		precache_model("models/sprites/s_hexpl.spr");
		precache_sound("weapons/r_exp3.wav");
		precache_sound("weapons/hagexp1.wav");
		precache_sound("weapons/hagexp2.wav");
		precache_sound("weapons/hagexp3.wav");
		precache_sound("weapons/rocket_fire.wav");
	}
	else
	{
		//precache_model("progs/s_explod.spr");
		precache_model("progs/dpexplosion.spr32");
		precache_sound("weapons/r_exp3.wav");
	}
};

void() harmlessfireball_think =
{
	self.nextthink = time + 0.01;
	self.angles = vectoangles(self.velocity) + '90 0 0';
	if (time > self.cnt)
		remove(self);
};

void(vector org, vector vel, float lifetime) SpawnHarmlessFireball =
{
	newmis = spawn();
	newmis.classname = "harmlessfireball";
	setorigin(newmis, org);
	setmodel(newmis, "progs/flame2.mdl");
	setsize (newmis, '0 0 0', '0 0 0');
	newmis.velocity = vel;
	newmis.think = harmlessfireball_think;
	newmis.nextthink = time + 0.01;
	newmis.cnt = time + lifetime;
	newmis.solid = SOLID_NOT;
	newmis.movetype = MOVETYPE_BOUNCE;
	newmis.effects = EF_ADDITIVE;
};

.float anim_fps;
.float anim_endtime;
void() explosionanimate =
{
	self.nextthink = time;
	self.frame = self.frame + self.anim_fps * frametime;
	if (time > self.anim_endtime)
		remove(self);
};

void(entity e, float damg, float force, float radius, entity ignore, string dt, vector explosioncolor, float quad, void(entity t, entity a, string m, float dtyp) obitfunc) BecomeExplosion =
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

	if (explosioncolor == '0 0 0')
	{
		if (quad)
			te_explosionquad(e.origin);
		else
			te_explosion(e.origin);
	}
	else if (explosioncolor == '-1 0 0')
	{
		sound(e, CHAN_AUTO, "weapons/r_exp3.wav", 1, ATTN_NORM);
		te_smallflash(e.origin);
	}
	else if (explosioncolor == '-2 0 0')
		te_tarexplosion(e.origin);
	else
		te_explosionrgb(e.origin, explosioncolor);

	T_RadiusDamage(e, e.owner, damg, force, radius, world, dt, DT_EXPLOSION, obitfunc);
	//remove(e);

	v = findbetterlocation3(org); // move animation away from walls
	// TODO: make caller do the sprite effect so this can go away
	//effect(v, "progs/s_explod.spr", 0, 6, 10);
	//if (game == GAME_NEXUIZ)
	//	effect(v, "models/sprites/dpexplosion1.spr32", 0, 20, 40);
	//else
	//	effect(v, "progs/dpexplosion.spr32", 0, 20, 40);
	setorigin(e, v);
	setmodel(e, "progs/dpexplosion.spr32");
	e.frame = 0;
	e.anim_fps = 40;
	e.anim_endtime = time + 0.5;
	e.think = explosionanimate;
	e.nextthink = time;
	e.velocity = '0 0 0';

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

