
void() InitCasings =
{
	if (game == GAME_NEXUIZ)
	{
		precache_model ("models/casing.mdl"); // brass bullet casing
	}
	else
	{
		precache_model ("progs/casing_bronze.mdl"); // bullet casing (made by Tomaz)
		precache_model ("progs/casing_steel.mdl"); // bullet casing (made by Tomaz)
		precache_model ("progs/casing_shell.mdl"); // shell casing (made by Tomaz)
		precache_sound ("weapons/tink1.wav");
	}
};

void() casingtouch =
{
	if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
	{
		remove(self);
		return;
	}
	if (other.solid == SOLID_BSP)
	{
		self.velocity = self.velocity * 0.8;
		if (vlen(self.velocity) >= 50)
		if (time >= self.attack_finished)
		if (self.origin != self.dest + self.groundentity.origin)
		{
			if (game != GAME_NEXUIZ)
				sound (self, CHAN_WEAPON, "weapons/tink1.wav", 0.5, ATTN_NORM);
			self.attack_finished = time + 0.2;
			//self.touch = SUB_Null; // one tink is enough
		}
	}
	self.dest = self.origin - self.groundentity.origin;
};

void() casingthink =
{
	local float p;
	self.nextthink = time + 0.1;
	if (self.flags & FL_ONGROUND)
	if (!self.lefty)
	{
	// just keep the yaw angle
		self.angles_x = 0;
		self.angles_z = 0;
		self.flags = self.flags - FL_ONGROUND;
		self.nextthink = time + 0.5;
	}
	p = pointcontents(self.origin);
	if (p == CONTENT_SOLID || p == CONTENT_LAVA || p == CONTENT_SKY)
	{
		removedecor(self);
		return;
	}
	if (time > self.cnt)
	{
		self.nextthink = time;
		self.alpha = self.alpha - frametime;
		if (self.alpha < 0.0625)
			removedecor(self);
	}
};

// knock loose the casing when disturbed
void() casingknockedloosefunc =
{
	self.lefty = FALSE;
	self.movetype = MOVETYPE_BOUNCE;
	self.flags = self.flags - (self.flags & FL_ONGROUND);
	self.avelocity = randomvec() * 300;
	self.nextthink = time + 0.1;
	self.touch = casingtouch;
};

void(vector org, vector vel, float randomvel, vector ang, vector avel, float randomavel, float casingtype) ejectcasing =
{
	local entity e;
	if (cvar("temp1") & 2048)
		return;

	e = newdecor();
	e.isdecor = TRUE;
	e.createdtime = time;
	e.alpha = 1;
	e.angles = ang;
	e.avelocity = avel + randomvec() * randomavel;
	e.forcescale = 15;
	e.knockedloosefunc = casingknockedloosefunc;
	e.movetype = MOVETYPE_BOUNCE;
	e.nextthink = time;
	e.solid = SOLID_TRIGGER;
	e.think = casingthink;
	e.touch = casingtouch;
	e.velocity = vel + randomvec() * randomvel;
	//e.effects = EF_LOWPRECISION;
	if (game == GAME_NEXUIZ)
	{
		setmodel (e, "models/casing.mdl");
		e.cnt = time + 10;
	}
	else
	{
		if (casingtype == 1)
		{
			setmodel (e, "progs/casing_shell.mdl");
			e.cnt = time + 30;
			// bias to make these be considered more important than other things
			e.createdtime = time + 1;
		}
		else if (casingtype == 2)
		{
			setmodel (e, "progs/casing_steel.mdl");
			e.cnt = time + 10;
		}
		else
		{
			setmodel (e, "progs/casing_bronze.mdl");
			e.cnt = time + 10;
		}
	}
	if (maxclients == 1)
		e.cnt = time + 3000;
	setsize (e, '0 0 -1', '0 0 -1');
	setorigin (e, org);
};
