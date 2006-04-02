entity xplo;
float maxdecors;

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
.float anim_endframe;
void() explosionanimate =
{
	self.nextthink = time;
	self.frame = self.frame + self.anim_fps * frametime;
	if (self.frame >= self.anim_endframe)
		remove(self);
};

void(entity e, vector explosioncolor, float quad) BecomeExplosion =
{
	local vector org, v;
	if (e.solid == SOLID_BSP)
		setorigin(e, (e.absmin + e.absmax) * 0.5);
	e.model = "";
	e.solid = SOLID_NOT;
	e.movetype = MOVETYPE_NONE;
	e.takedamage = DAMAGE_NO;

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

	//remove(e);

	v = findbetterlocation3(org); // move animation away from walls
	// TODO: make caller do the sprite effect so this can go away
	//effect(v, "progs/s_explod.spr", 0, 6, 10);
	//if (game == GAME_NEXUIZ)
	//	effect(v, "models/sprites/dpexplosion1.spr32", 0, 20, 40);
	//else
	//	effect(v, "progs/dpexplosion.spr32", 0, 20, 40);
	e.movetype = MOVETYPE_NONE;
	e.solid = SOLID_NOT;
	e.takedamage = DAMAGE_NO;
	setorigin(e, v);
	setmodel(e, "progs/dpexplosion.spr32");
	e.frame = 0;
	e.anim_fps = 40;
	e.anim_endframe = 20;
	e.think = explosionanimate;
	e.nextthink = time;
	e.velocity = '0 0 0';
};

