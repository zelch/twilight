
void() mctf_pickup_smallhealth_touch =
{
	if (other.classname == "player")
	if (!other.deadflag)
	{
		if (other.flags & FL_CLIENT)
			stuffcmd(other, "bf\n");
		sound(other, CHAN_AUTO, "items/r_item1.wav", 1, ATTN_STATIC);
		T_Heal(other, 15, FALSE);
		// FIXME: play disappear animation
		remove(self);
	}
};

void() mctf_pickup_smallhealth_think =
{
	// FIXME: play appear animation (before idle)
	// FIXME: play idle animation (after appear)
	self.nextthink = time;
	makevectors((time - self.count) * '0 90 0');
	setorigin(self, self.dest + '0 0 4' * v_forward_x);
	if (time > self.cnt)
	{
		// FIXME: play disappear animation
		remove(self);
	}
};

void(vector org) mctf_pickup_smallhealth_spawn =
{
	newmis = spawn();
	newmis.classname = "mctf_pickup_smallhealth";
	newmis.touch = mctf_pickup_smallhealth_touch;
	newmis.think = mctf_pickup_smallhealth_think;
	newmis.nextthink = time;
	newmis.cnt = time + 15;
	newmis.solid = SOLID_TRIGGER;
	newmis.movetype = MOVETYPE_NONE;
	newmis.frame = 0;
	newmis.dest = org;
	newmis.count = time;
	newmis.effects = EF_FULLBRIGHT;
	setmodel(newmis, "progs/gib1.mdl");
	setsize(newmis, '-16 -16 -16', '16 16 16');
	setorigin(newmis, org);
	//bprint("smallhealth\n");
};

void() mctf_pickup_largehealth_touch =
{
	if (other.classname == "player")
	if (!other.deadflag)
	{
		if (other.flags & FL_CLIENT)
			stuffcmd(other, "bf\n");
		sound(other, CHAN_AUTO, "items/health1.wav", 1, ATTN_STATIC);
		T_Heal(other, 50, FALSE);
		// FIXME: play disappear animation
		remove(self);
	}
};

void() mctf_pickup_largehealth_think =
{
	// FIXME: play appear animation (before idle)
	// FIXME: play idle animation (after appear)
	self.nextthink = time;
	makevectors((time - self.count) * '0 90 0');
	setorigin(self, self.dest + '0 0 4' * v_forward_x);
	if (time > self.cnt)
	{
		// FIXME: play disappear animation
		remove(self);
	}
};

void(vector org) mctf_pickup_largehealth_spawn =
{
	newmis = spawn();
	newmis.classname = "mctf_pickup_largehealth";
	newmis.touch = mctf_pickup_largehealth_touch;
	newmis.think = mctf_pickup_largehealth_think;
	newmis.nextthink = time;
	newmis.cnt = time + 15;
	newmis.solid = SOLID_TRIGGER;
	newmis.movetype = MOVETYPE_NONE;
	newmis.frame = 1;
	newmis.dest = org;
	newmis.count = time;
	newmis.effects = EF_FULLBRIGHT;
	setmodel(newmis, "progs/gib2.mdl");
	setsize(newmis, '-16 -16 -16', '16 16 16');
	setorigin(newmis, org);
	//bprint("largehealth\n");
};

void() mctf_pickup_missile_touch =
{
	if (other.classname == "player")
	if (!other.deadflag)
	{
		if (other.flags & FL_CLIENT)
			stuffcmd(other, "bf\n");
		sound(other, CHAN_AUTO, "weapons/lock4.wav", 1, ATTN_STATIC);
		Inventory_AdjustQuantity(other, "rockets", 1);
		// FIXME: play disappear animation
		remove(self);
	}
};

void() mctf_pickup_missile_think =
{
	// FIXME: play appear animation (before idle)
	// FIXME: play idle animation (after appear)
	self.nextthink = time;
	makevectors((time - self.count) * '20 90 0');
	setorigin(self, self.dest + 4 * v_up);
	if (time > self.cnt)
	{
		// FIXME: play disappear animation
		remove(self);
	}
};

void(vector org) mctf_pickup_missile_spawn =
{
	newmis = spawn();
	newmis.classname = "mctf_pickup_missile";
	newmis.touch = mctf_pickup_missile_touch;
	newmis.think = mctf_pickup_missile_think;
	newmis.nextthink = time;
	newmis.cnt = time + 15;
	newmis.solid = SOLID_TRIGGER;
	newmis.movetype = MOVETYPE_NONE;
	newmis.angles = '90 0 0';
	newmis.dest = org;
	newmis.count = time;
	newmis.effects = EF_FULLBRIGHT;
	setmodel(newmis, "progs/missile.mdl");
	setsize(newmis, '-16 -16 -16', '16 16 16');
	setorigin(newmis, org);
	//bprint("missile\n");
};

void(vector org, float howmany, float smallhealthchance, float largehealthchance, float missilechance) mctf_spawnpickup =
{
	local vector v;
	if (deathmatch != DM_MCTF_2TEAM)
		return;
	v = org;
	while (howmany > 0)
	{
		howmany = howmany - 1;
		if (random() < missilechance)
			mctf_pickup_missile_spawn(v);
		else if (random() < largehealthchance)
			mctf_pickup_largehealth_spawn(v);
		else if (random() < smallhealthchance)
			mctf_pickup_smallhealth_spawn(v);
		else
			continue;
		v = org + '0 0 8' + randomvec() * 8;
		//bprint("!\n");
	}
};

void() mctf_precache =
{
	precache_model("progs/gib1.mdl");
	precache_model("progs/gib2.mdl");
	precache_model("progs/missile.mdl");
	precache_sound("items/health1.wav");
	precache_sound("items/r_item1.wav");
	precache_sound("weapons/lock4.wav");
};

