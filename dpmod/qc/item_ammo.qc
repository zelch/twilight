
/*
===============================================================================

AMMO

===============================================================================
*/

.string ammo_typestring;

void() ammo_touch =
{
	local entity stemp;
	local float used;
	local float switchweapon;

	if (other.classname != "player")
		return;
	if (other.health < 1)
		return;

	stemp = self;
	self = other;
	switchweapon = self.switchweaponclass == W_BestWeaponClass(TRUE);
	self = stemp;

	used = Inventory_AdjustQuantity(other, self.ammo_typestring, self.aflag);
	if (used < 1)
		return;

	// if the player was using his best weapon, change up to the new one if better
	if (switchweapon)
	{
		self = other;
		self.switchweaponclass = W_BestWeaponClass(TRUE);
		self = stemp;
	}

	if (other.flags & FL_CLIENT)
	{
//		sprint (other, self.netname);
		stuffcmd(other, "bf\n");
	}
	// ammo touch sound
	sound (other, CHAN_ITEM, "weapons/lock4.wav", 1, ATTN_NORM);

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

// TODO: Nexuiz items

float(entity player, entity item) item_shells_pickupeval = {if (Inventory_Quantity(player, "shells") < AMMOMAX_SHELLS) return (AMMOMAX_SHELLS - Inventory_Quantity(player, "shells")) * (AMMOMAX_SHELLS - Inventory_Quantity(player, "shells")) * item.dmg;else return 0;};
float(entity player, entity item) item_nails_pickupeval = {if (Inventory_Quantity(player, "nails") < AMMOMAX_NAILS) return (AMMOMAX_NAILS - Inventory_Quantity(player, "nails")) * (AMMOMAX_NAILS - Inventory_Quantity(player, "nails")) * item.dmg;else return 0;};
float(entity player, entity item) item_rockets_pickupeval = {if (Inventory_Quantity(player, "rockets") < AMMOMAX_ROCKETS) return (AMMOMAX_ROCKETS - Inventory_Quantity(player, "rockets")) * (AMMOMAX_ROCKETS - Inventory_Quantity(player, "rockets")) * item.dmg;else return 0;};
float(entity player, entity item) item_cells_pickupeval = {if (Inventory_Quantity(player, "cells") < AMMOMAX_CELLS) return (AMMOMAX_CELLS - Inventory_Quantity(player, "cells")) * (AMMOMAX_CELLS - Inventory_Quantity(player, "cells")) * item.dmg;else return 0;};

/*QUAKED item_shells (0 .5 .8) (0 0 0) (32 32 32)
*/

void() item_shells =
{
	self.touch = ammo_touch;

	self.ammo_typestring = "shells";
	self.weapon = 1;
	if (self.spawnflags & WEAPON_BIG2)
	{
		if (game == GAME_NEXUIZ)
		{
			precache_model ("models/items/a_shells.md3");
			setmodel (self, "models/items/a_shells.md3");
		}
		else
		{
			precache_model ("progs/a_shell2.mdl");
			setmodel (self, "progs/a_shell2.mdl");
			self.netname = "You got some shotgun shells\n";
		}
		if (self.aflag < 1)
			self.aflag = AMMO_SHELLS * 2;
	}
	else
	{
		if (game == GAME_NEXUIZ)
		{
			precache_model ("models/items/a_shells.md3");
			setmodel (self, "models/items/a_shells.md3");
		}
		else
		{
			precache_model ("progs/a_shell1.mdl");
			setmodel (self, "progs/a_shell1.mdl");
			self.netname = "You got some shotgun shells\n";
		}
		if (self.aflag < 1)
			self.aflag = AMMO_SHELLS;
	}
	setsize (self, '-16 -16 0', '16 16 8');
	setorigin(self, self.origin + '16 16 0');

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

	self.ammo_typestring = "nails";
	self.weapon = 2;
	if (self.spawnflags & WEAPON_BIG2)
	{
		if (game == GAME_NEXUIZ)
		{
			precache_model ("models/items/a_bullets.zym");
			setmodel (self, "models/items/a_bullets.zym");
		}
		else
		{
			precache_model ("maps/b_nail1.bsp");
			setmodel (self, "maps/b_nail1.bsp");
			self.netname = "You got a large box of nails\n";
		}
		if (self.aflag < 1)
			self.aflag = AMMO_NAILS * 2;
		setsize (self, '0 0 0', '32 32 24');
	}
	else
	{
		if (game == GAME_NEXUIZ)
		{
			precache_model ("models/items/a_bullets.zym");
			setmodel (self, "models/items/a_bullets.zym");
		}
		else
		{
			precache_model ("maps/b_nail0.bsp");
			setmodel (self, "maps/b_nail0.bsp");
			self.netname = "You got a small box of nails\n";
		}
		if (self.aflag < 1)
			self.aflag = AMMO_NAILS;
		setsize (self, '0 0 0', '24 24 24');
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
	self.touch = ammo_touch;

	self.ammo_typestring = "rockets";
	self.weapon = 3;
	if (self.spawnflags & WEAPON_BIG2)
	{
		if (game == GAME_NEXUIZ)
		{
			precache_model ("models/items/a_rockets.md3");
			setmodel (self, "models/items/a_rockets.md3");
		}
		else
		{
			precache_model ("progs/a_rock8.mdl");
			setmodel (self, "progs/a_rock8.mdl");
			self.netname = "You got some rockets\n";
		}
		if (self.aflag < 1)
			self.aflag = AMMO_ROCKETS * 2;
	}
	else
	{
		if (game == GAME_NEXUIZ)
		{
			precache_model ("models/items/a_rockets.md3");
			setmodel (self, "models/items/a_rockets.md3");
		}
		else
		{
			precache_model ("progs/a_rock4.mdl");
			setmodel (self, "progs/a_rock4.mdl");
			self.netname = "You got some rockets\n";
		}
		if (self.aflag < 1)
			self.aflag = AMMO_ROCKETS;
	}
	setsize (self, '-16 -16 0', '16 16 16');
	setorigin(self, self.origin + '16 16 0');

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

	self.ammo_typestring = "cells";
	self.weapon = 4;
	if (self.spawnflags & WEAPON_BIG2)
	{
		if (game == GAME_NEXUIZ)
		{
			precache_model ("models/items/a_cells.md3");
			setmodel (self, "models/items/a_cells.md3");
		}
		else
		{
			precache_model ("maps/b_batt1.bsp");
			setmodel (self, "maps/b_batt1.bsp");
			self.netname = "You got a large energy cell\n";
		}
		if (self.aflag < 1)
			self.aflag = AMMO_CELLS * 2;
		setsize (self, '0 0 0', '32 32 24');
	}
	else
	{
		if (game == GAME_NEXUIZ)
		{
			precache_model ("models/items/a_cells.md3");
			setmodel (self, "models/items/a_cells.md3");
		}
		else
		{
			precache_model ("maps/b_batt0.bsp");
			setmodel (self, "maps/b_batt0.bsp");
			self.netname = "You got a small energy cell\n";
		}
		if (self.aflag < 1)
			self.aflag = AMMO_CELLS;
		setsize (self, '0 0 0', '24 24 24');
	}

	self.havocpickup = TRUE;
	self.dmg = 30 * self.aflag / (AMMOMAX_CELLS * AMMOMAX_CELLS);
	self.pickupevalfunc = item_cells_pickupeval;

	StartItem ();
};


