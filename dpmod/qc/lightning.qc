
void() lightning_precache =
{
	if (game != GAME_NEXUIZ)
	{
		//precache_model("progs/v_light.mdl");
		precache_model("progs/bolt.mdl"); // actually this is the hook chain
		precache_model("progs/bolt2.mdl");
		precache_model("progs/bolt3.mdl");
		precache_sound("weapons/lhit.wav");
		precache_sound("weapons/lstart.wav");
	}
};

/*
=================
LightningDamage
=================
*/
void(vector p1, vector p2, entity from, float damage, string dethtype, void(entity t, entity a, string m, float dtyp) obitfunc) LightningDamage =
{
	local vector f;
	local entity e1, e2;

	f = p2 - p1;
	normalize (f);
	f_x = 0 - f_y;
	f_y = f_x;
	f_z = 0;
	f = f*16;

	weapontraceline (p1, p2, FALSE, self);
	e1 = trace_ent;
	if (trace_ent.takedamage)
		T_Damage (trace_ent, from, from, damage, damage, dethtype, DT_LIGHTNING, trace_endpos, '0 0 0', obitfunc);

	weapontraceline (p1 + f, p2 + f, FALSE, self);
	e2 = trace_ent;
	if (trace_ent.takedamage)
	if (trace_ent != e1)
		T_Damage (trace_ent, from, from, damage, damage, dethtype, DT_LIGHTNING, trace_endpos, '0 0 0', obitfunc);

	weapontraceline (p1 - f, p2 - f, FALSE, self);
	if (trace_ent.takedamage)
	if (trace_ent != e1)
	if (trace_ent != e2)
		T_Damage (trace_ent, from, from, damage, damage, dethtype, DT_LIGHTNING, trace_endpos, '0 0 0', obitfunc);
};

void(vector v1, vector v2, float d, string dethtype, void(entity t, entity a, string m, float dtyp) obitfunc) LightningBolt =
{
	local vector dir;
	dir = normalize(v2 - v1);
	if (self.t_width < time)
	{
		sound (self, CHAN_WEAPON, "weapons/lhit.wav", 1, ATTN_NORM);
		self.t_width = time + 0.6;
	}

	weapontraceline (v1, v2, TRUE, self);

	te_lightning2(self, v1, trace_endpos);

	LightningDamage (self.origin, trace_endpos + dir*4, self, 30, dethtype, obitfunc);
};
