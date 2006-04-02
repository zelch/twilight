/*
===============================================================================

WEAPONS

===============================================================================
*/

/*
=============
weapon_touch
=============
*/
void() weapon_touch =
{
	local float switchweapon;
	local entity stemp;

	if (other.classname != "player")
		return;
	if (other.health < 1)
		return;
	/*
	new = self.items;
	if (other.items & self.items == self.items) // has it already
	if ((Inventory_Quantity(other, "shells") >= AMMOMAX_SHELLS ) || (Inventory_Quantity(self, "shells") < 1))
	if ((Inventory_Quantity(other, "nails") >= AMMOMAX_NAILS  ) || (Inventory_Quantity(self, "nails") < 1))
	if ((Inventory_Quantity(other, "rockets") >= AMMOMAX_ROCKETS) || (Inventory_Quantity(self, "rockets") < 1))
	if ((Inventory_Quantity(other, "cells") >= AMMOMAX_CELLS  ) || (Inventory_Quantity(self, "cells") < 1))
		return; // would gain no ammo or weapon

	// if the player was using their best weapon, change up to the new one if better
	stemp = self;
	self = other;
	best = W_BestWeapon(TRUE);
	self = stemp;

	if (itemrespawn && AMMOWEAPONOVERFLOW)
	{
		if (Inventory_Quantity(self, "shells")) if (Inventory_Quantity(other, "shells") < Inventory_Quantity(self, "shells")) Inventory_SetQuantity(other, "shells", Inventory_Quantity(self, "shells")); else Inventory_AdjustQuantity(other, "shells", AMMOWEAPONOVERFLOW_SHELLS);
		if (Inventory_Quantity(self, "nails")) if (Inventory_Quantity(other, "nails") < Inventory_Quantity(self, "nails")) Inventory_SetQuantity(other, "nails", Inventory_Quantity(self, "nails")); else Inventory_AdjustQuantity(other, "nails", AMMOWEAPONOVERFLOW_NAILS);
		if (Inventory_Quantity(self, "rockets")) if (Inventory_Quantity(other, "rockets") < Inventory_Quantity(self, "rockets")) Inventory_SetQuantity(other, "rockets", Inventory_Quantity(self, "rockets")); else Inventory_AdjustQuantity(other, "rockets", AMMOWEAPONOVERFLOW_ROCKETS);
		if (Inventory_Quantity(self, "cells")) if (Inventory_Quantity(other, "cells") < Inventory_Quantity(self, "cells")) Inventory_SetQuantity(other, "cells", Inventory_Quantity(self, "cells")); else Inventory_AdjustQuantity(other, "cells", AMMOWEAPONOVERFLOW_CELLS);
	}
	else
	{
		Inventory_AdjustQuantity(other, "shells", Inventory_Quantity(self, "shells"));
		Inventory_AdjustQuantity(other, "nails", Inventory_Quantity(self, "nails"));
		Inventory_AdjustQuantity(other, "rockets", Inventory_Quantity(self, "rockets"));
		Inventory_AdjustQuantity(other, "cells", Inventory_Quantity(self, "cells"));
	}

	// change to the weapon
	old = other.items;
	other.items = other.items | new;

	stemp = self;
	self = other;

	if (self.switchweapon == best)
		self.switchweapon = W_BestWeapon(TRUE);
//	Deathmatch_Weapon (old, new);

	self = stemp;
	*/
	stemp = self;
	self = other;
	switchweapon = self.switchweaponclass == W_BestWeaponClass(TRUE);
	self = stemp;

	// FIXME: this breaks deathmatch 2 mode which should return if no weapons were added
	// if nothing absorbed, return
	if (!Inventory_AbsorbCloneInventory(other, self))
		return;

	// if the player was using their best weapon, change up to the new one if better
	if (switchweapon)
	{
		self = other;
		self.switchweaponclass = W_BestWeaponClass(TRUE);
		self = stemp;
	}

	if (other.flags & FL_CLIENT)
	{
		sprint (other, self.netname);
		stuffcmd(other, "bf\n");
	}

	// weapon touch sound
	sound (other, CHAN_ITEM, "weapons/pkup.wav", 1, ATTN_NORM);

	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets

	// since the above code breaks deathmatch 2, don't rapidly fill up ammo
	//if (deathmatch != 2)
	{
		// remove it in single player, or setup for respawning in deathmatch
		self.model = "";
		self.solid = SOLID_NOT;
		self.think = SUB_regen;
		self.nextthink = time + RESPAWNTIME_WEAPON;
		if (!itemrespawn)
			remove(self);
	}
};

float(entity player, entity item) item_weapon_pickupeval =
{
	return item.dmg;
};

void(string wmdl, float rating, string name) weapon_spawnhandler =
{
	self.havocpickup = TRUE;
	self.pickupevalfunc = item_weapon_pickupeval;
	self.dmg = rating;
	precache_model (wmdl);
	setmodel (self, wmdl);
	self.netname = name;
	self.touch = weapon_touch;
	setsize (self, '-16 -16 0', '16 16 32');
	StartItem ();
};

// TODO: Nexuiz items

/*QUAKED weapon_supershotgun (0 .5 .8) (-16 -16 0) (16 16 32)
*/
void() weapon_supershotgun =
{
	if (metroidmode)
	{
		weapon_spawnhandler("progs/g_shot.mdl", 2000, "You got the Muli Cannon upgrade!\n");
		Inventory_SetQuantity(self, "mmulticannon", 1);
		return;
	}
	weapon_spawnhandler("progs/g_shot.mdl", 2000, "You got the Super Shotgun!\n");
	Inventory_SetQuantity(self, "supershotgun", 1);
	Inventory_SetQuantity(self, "shells", AMMO_SHELLS);
};

/*QUAKED weapon_nailgun (0 .5 .8) (-16 -16 0) (16 16 32)
*/
void() weapon_nailgun =
{
	if (metroidmode)
	{
		weapon_spawnhandler("progs/g_shot.mdl", 2000, "You got the Charge Cannon upgrade!\n");
		Inventory_SetQuantity(self, "mchargecannon", 1);
		return;
	}
	weapon_spawnhandler("progs/g_nail.mdl", 2000, "You got the Nailgun!\n");
	Inventory_SetQuantity(self, "nailgun", 1);
	Inventory_SetQuantity(self, "nails", AMMO_NAILS);
};

/*QUAKED weapon_supernailgun (0 .5 .8) (-16 -16 0) (16 16 32)
*/
void() weapon_supernailgun =
{
	if (metroidmode)
	{
		weapon_spawnhandler("progs/g_nail2.mdl", 2000, "You got the Grapple upgrade!\n");
		Inventory_SetQuantity(self, "mgrapple", 1);
		return;
	}
	weapon_spawnhandler("progs/g_nail2.mdl", 2000, "You got the Super Nailgun!\n");
	Inventory_SetQuantity(self, "supernailgun", 1);
	Inventory_SetQuantity(self, "nails", AMMO_NAILS);
};

/*QUAKED weapon_grenadelauncher (0 .5 .8) (-16 -16 0) (16 16 32)
*/
void() weapon_grenadelauncher =
{
	if (metroidmode)
	{
		weapon_spawnhandler("progs/g_rock.mdl", 2000, "You got the Bomb upgrade!\n");
		Inventory_SetQuantity(self, "mbomblauncher", 1);
		return;
	}
	weapon_spawnhandler("progs/g_rock.mdl", 2000, "You got the Proximity Grenade Launcher!\n");
	Inventory_SetQuantity(self, "grenadelauncher", 1);
	Inventory_SetQuantity(self, "rockets", AMMO_ROCKETS);
};

/*QUAKED weapon_rocketlauncher (0 .5 .8) (-16 -16 0) (16 16 32)
*/
void() weapon_rocketlauncher =
{
	if (metroidmode)
	{
		remove(self);
		//weapon_spawnhandler("progs/g_shot.mdl", 2000, "You got the Charge Cannon upgrade!\n");
		//Inventory_SetQuantity(self, "mchargecannon", 1);
		return;
	}
	weapon_spawnhandler("progs/g_rock2.mdl", 2000, "You got the Rocket Launcher!\n");
	Inventory_SetQuantity(self, "rocketlauncher", 1);
	Inventory_SetQuantity(self, "rockets", AMMO_ROCKETS);
};

/*QUAKED weapon_lightning (0 .5 .8) (-16 -16 0) (16 16 32)
*/
void() weapon_lightning =
{
	if (metroidmode)
	{
		weapon_spawnhandler("progs/g_light.mdl", 2000, "You got the Plasma Beam!\n");
		Inventory_SetQuantity(self, "mplasmabeam", 1);
		return;
	}
	weapon_spawnhandler("progs/g_light.mdl", 2000, "You got the Thunderbolt!\n");
	Inventory_SetQuantity(self, "thunderbolt", 1);
	Inventory_SetQuantity(self, "plasmarifle", 1);
	Inventory_SetQuantity(self, "plasmawave", 1);
	Inventory_SetQuantity(self, "cells", AMMO_CELLS);
};

