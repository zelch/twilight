
/*
===============================================================================

AMMO

===============================================================================
*/

void() ammo_touch =
{
	local   entity  stemp;
	local   float   best;
	local   float   used;

	if (other.classname != "player")
		return;
	if (other.health < 1)
		return;
	used = full_ammo(other, self.weapon, self.aflag);
	if (used < 1)
		return;

	// if the player was using his best weapon, change up to the new one if better   
	stemp = self;
	self = other;
	best = W_BestWeapon(TRUE);
	self = stemp;

	if (self.weapon == 1) other.ammo_shells  = other.ammo_shells  + self.aflag;
	if (self.weapon == 2) other.ammo_nails   = other.ammo_nails   + self.aflag;
	if (self.weapon == 3) other.ammo_rockets = other.ammo_rockets + self.aflag;
	if (self.weapon == 4) other.ammo_cells   = other.ammo_cells   + self.aflag;

	bound_ammo (other);

	if (other.flags & FL_CLIENT)
	{
//		sprint (other, self.netname);
		stuffcmd(other, "bf\n");
	}
	// ammo touch sound
	sound (other, CHAN_ITEM, "weapons/lock4.wav", 1, ATTN_NORM);

	// change to a better weapon if appropriate
	if (other.switchweapon == best)
	{
		stemp = self;
		self = other;
		self.switchweapon = W_BestWeapon(TRUE);
		self = stemp;
	}

	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets

	// Dark Places behavior is rather different than quake:
	// in single player, the ammo taken is removed from the box,
	// leaving the box intact if it has some left.
	// while in deathmatch it behaves like quake (vanishs and respawns)
	// and coop behaves like deathmatch (quake didn't respawn ammo in coop)
	if (itemrespawn)
	{
		self.model = "";
		self.solid = SOLID_NOT;
		self.think = SUB_regen;
		self.nextthink = time + RESPAWNTIME_AMMO;
	}
	else
	{
		self.aflag = self.aflag - used;
		if (self.aflag <= 0)
			remove(self);
	}
};

float WEAPON_BIG2 = 1;

float(entity player, entity item) item_shells_pickupeval = {if (player.ammo_shells < AMMOMAX_SHELLS) return (AMMOMAX_SHELLS - player.ammo_shells) * (AMMOMAX_SHELLS - player.ammo_shells) * item.dmg;else return 0;};
float(entity player, entity item) item_nails_pickupeval = {if (player.ammo_nails < AMMOMAX_NAILS) return (AMMOMAX_NAILS - player.ammo_nails) * (AMMOMAX_NAILS - player.ammo_nails) * item.dmg;else return 0;};
float(entity player, entity item) item_rockets_pickupeval = {if (player.ammo_rockets < AMMOMAX_ROCKETS) return (AMMOMAX_ROCKETS - player.ammo_rockets) * (AMMOMAX_ROCKETS - player.ammo_rockets) * item.dmg;else return 0;};
float(entity player, entity item) item_cells_pickupeval = {if (player.ammo_cells < AMMOMAX_CELLS) return (AMMOMAX_CELLS - player.ammo_cells) * (AMMOMAX_CELLS - player.ammo_cells) * item.dmg;else return 0;};

/*QUAKED item_shells (0 .5 .8) (0 0 0) (32 32 32)
*/

void() item_shells =
{
	self.touch = ammo_touch;

	if (self.spawnflags & WEAPON_BIG2)
	{
		precache_model ("progs/a_shell2.mdl");
		setmodel (self, "progs/a_shell2.mdl");
		if (self.aflag < 1)
			self.aflag = AMMO_SHELLS * 2;
		self.netname = "You got some shotgun shells\n";
	}
	else
	{
		precache_model ("progs/a_shell1.mdl");
		setmodel (self, "progs/a_shell1.mdl");
		if (self.aflag < 1)
			self.aflag = AMMO_SHELLS;
		self.netname = "You got some shotgun shells\n";
	}
	setsize (self, '-16 -16 0', '16 16 8');
	setorigin(self, self.origin + '16 16 0');
	self.weapon = 1;

	self.havocpickup = TRUE;
	self.dmg = 60 * self.aflag / (AMMOMAX_SHELLS * AMMOMAX_SHELLS);
	self.pickupevalfunc = item_shells_pickupeval;

	StartItem ();
};

/*QUAKED item_spikes (0 .5 .8) (0 0 0) (32 32 32) big
*/

void() item_spikes =
{
	self.touch = ammo_touch;

	self.weapon = 2;
	if (self.spawnflags & WEAPON_BIG2)
	{
		precache_model ("maps/b_nail1.bsp");
		setmodel (self, "maps/b_nail1.bsp");
		if (self.aflag < 1)
			self.aflag = AMMO_NAILS * 2;
		setsize (self, '0 0 0', '32 32 24');
		self.netname = "You got a large box of nails\n";
	}
	else
	{
		precache_model ("maps/b_nail0.bsp");
		setmodel (self, "maps/b_nail0.bsp");
		if (self.aflag < 1)
			self.aflag = AMMO_NAILS;
		setsize (self, '0 0 0', '24 24 24');
		self.netname = "You got a small box of nails\n";
	}

	self.havocpickup = TRUE;
	self.dmg = 15 * self.aflag / (AMMOMAX_NAILS * AMMOMAX_NAILS);
	self.pickupevalfunc = item_nails_pickupeval;

	StartItem ();
};

/*QUAKED item_rockets (0 .5 .8) (0 0 0) (32 32 32) big
*/

void() item_rockets =
{
	if (deathmatch == 7) {remove(self);return;}

	self.touch = ammo_touch;
	if (self.spawnflags & WEAPON_BIG2)
	{
		precache_model ("progs/a_rock8.mdl");
		setmodel (self, "progs/a_rock8.mdl");
		if (self.aflag < 1)
			self.aflag = AMMO_ROCKETS * 2;
		self.netname = "You got some rockets\n";
	}
	else
	{
		precache_model ("progs/a_rock4.mdl");
		setmodel (self, "progs/a_rock4.mdl");
		if (self.aflag < 1)
			self.aflag = AMMO_ROCKETS;
		self.netname = "You got some rockets\n";
	}
	setsize (self, '-16 -16 0', '16 16 16');
	setorigin(self, self.origin + '16 16 0');
	self.weapon = 3;

	self.havocpickup = TRUE;
	self.dmg = 120 * self.aflag / (AMMOMAX_ROCKETS * AMMOMAX_ROCKETS);
	self.pickupevalfunc = item_rockets_pickupeval;

	StartItem ();
};

/*QUAKED item_cells (0 .5 .8) (0 0 0) (32 32 32) big
*/

void() item_cells =
{
	self.touch = ammo_touch;

	self.weapon = 4;
	if (self.spawnflags & WEAPON_BIG2)
	{
		precache_model ("maps/b_batt1.bsp");
		setmodel (self, "maps/b_batt1.bsp");
		if (self.aflag < 1)
			self.aflag = AMMO_CELLS * 2;
		setsize (self, '0 0 0', '32 32 24');
		self.netname = "You got a large energy cell\n";
	}
	else
	{
		precache_model ("maps/b_batt0.bsp");
		setmodel (self, "maps/b_batt0.bsp");
		if (self.aflag < 1)
			self.aflag = AMMO_CELLS;
		setsize (self, '0 0 0', '24 24 24');
		self.netname = "You got a small energy cell\n";
	}

	self.havocpickup = TRUE;
	self.dmg = 30 * self.aflag / (AMMOMAX_CELLS * AMMOMAX_CELLS);
	self.pickupevalfunc = item_cells_pickupeval;

	StartItem ();
};


