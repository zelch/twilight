
void(entity e, vector v) printsurfaceinfo =
{
	local float surfnum, numpoints, vnum;
	local string s;
	local vector n;
	surfnum = getsurfacenearpoint(e, v);
	if (surfnum >= 0)
	{
		bprint("texture: ");
		s = getsurfacetexture(e, surfnum);
		bprint(s);
		bprint(" normal: ");
		n = getsurfacenormal(e, surfnum);
		bprintvector(n);
		bprint(" ");
		numpoints = getsurfacenumpoints(e, surfnum);
		bprintfloat(numpoints);
		bprint(" verts:");
		vnum = 0;
		while (vnum < numpoints)
		{
			bprint(" ");
			n = getsurfacepoint(e, surfnum, vnum);
			bprintvector(n);
			vnum = vnum + 1;
		}
		bprint(" point tested: ");
		bprintvector(v);
		bprint(" nearest point on surface: ");
		n = getsurfaceclippedpoint(e, surfnum, v);
		bprintvector(n);
		bprint("\n");
	}
};

void() GibClone =
{
	if (random() < 0.5)
		sound (self, CHAN_VOICE, "player/gib.wav", 1, ATTN_NONE);
	else
		sound (self, CHAN_VOICE, "player/udeath.wav", 1, ATTN_NONE);

	MonsterGibs("", 6, "", 0, "", 0);
};


/*
============
ImpulseCommands

============
*/
void() ImpulseCommands =
{
	if (self.impulse == 29)
	{
		newmis = spawn();
		//newmis.viewmodelforclient = self;
		//newmis.owner = self;
		setmodel(newmis, "progs/player.mdl");
		setsize(newmis, '-16 -16 -24', '16 16 24');
		newmis.frame = 0;
		newmis.angles = '0 0 0';
		newmis.movetype = MOVETYPE_TOSS;
		newmis.solid = SOLID_SLIDEBOX;
		newmis.takedamage = DAMAGE_YES;
		newmis.health = 100;
		newmis.effects = EF_FLAME;
		newmis.th_die = GibClone;
		setorigin(newmis, self.origin);
	}
	if (self.impulse == 28)
	{
		newmis = spawn();
		//newmis.viewmodelforclient = self;
		//newmis.owner = self;
		setmodel(newmis, "progs/player.mdl");
		setsize(newmis, '-16 -16 -24', '16 16 24');
		newmis.frame = 0;
		newmis.angles = '0 0 0';
		newmis.movetype = MOVETYPE_TOSS;
		newmis.solid = SOLID_SLIDEBOX;
		newmis.takedamage = DAMAGE_YES;
		newmis.health = 100;
		newmis.effects = EF_STARDUST;
		newmis.th_die = GibClone;
		setorigin(newmis, self.origin);
	}
	/*
	if (self.impulse == 27)
	{
		makevectors(self.v_angle);
		self.oldorigin = self.origin + v_forward * 32;
		setorigin(self, self.oldorigin);
	}
	if (self.impulse == 26)
	{
		newmis = spawn();
		//newmis.viewmodelforclient = self;
		//newmis.owner = self;
		setmodel(newmis, "progs/player.mdl");
		setsize(newmis, '-16 -16 -24', '16 16 24');
		newmis.frame = 0;
		newmis.angles = '0 0 0';
		newmis.movetype = MOVETYPE_TOSS;
		newmis.solid = SOLID_SLIDEBOX;
		newmis.takedamage = DAMAGE_YES;
		newmis.health = 100;
		newmis.th_die = GibClone;
		setorigin(newmis, self.origin);
	}
	*/
	/*
	if (self.impulse == 26)
	{
		newmis = spawn();
		newmis.viewmodelforclient = newmis.owner = self;
		setmodel(newmis, "progs/g_rock2.mdl");
		newmis.frame = 0;
		setorigin(newmis, '0 0 0');
		newmis.angles = '0 0 90';
	}
	if (self.impulse == 22)
	{
		makevectors(self.v_angle);
		weapontraceline(self.origin + self.view_ofs, self.origin + self.view_ofs + v_forward * 1024, FALSE, self);
		if (trace_ent)
		{
			trace_ent.alpha = trace_ent.alpha - 1/8;
			if (trace_ent.alpha < 0)
				trace_ent.alpha = 7/8;
		}
	}
	if (self.impulse == 17)
	{
		if (self.scale == 0)
			self.scale = 1;
		self.scale = self.scale - 0.0625;
	}
	if (self.impulse == 18)
	{
		if (self.scale == 0)
			self.scale = 1;
		self.scale = self.scale + 0.0625;
	}
	*/
	if (self.impulse == 16)
	{
		makevectors(self.v_angle);
		traceline(self.origin + self.view_ofs, self.origin + self.view_ofs + v_forward * 4096, FALSE, self);
		if (trace_ent)
			eprint(trace_ent);
	}
	if (self.impulse == 15)
	{
		makevectors(self.v_angle);
		traceline(self.origin + self.view_ofs, self.origin + self.view_ofs + v_forward * 4096, FALSE, self);
		if (trace_fraction < 1)
			printsurfaceinfo(trace_ent, trace_endpos);
	}
	if ((self.impulse >= 1 && self.impulse <= 9) || (self.impulse >= 201 && self.impulse <= 211)) W_ChangeWeapon ();
	else if (self.impulse == 10) CycleWeaponCommand ();
	else if (self.impulse == 11) ServerflagsCommand ();
	else if (self.impulse == 12) CycleWeaponReverseCommand ();
	else if (self.impulse == 234) CheatCommand ();
	else if (self.impulse == 255) QuadCheat ();

	self.impulse = 0;
};
