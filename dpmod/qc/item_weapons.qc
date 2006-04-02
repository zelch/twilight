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
	weapon_spawnhandler("progs/g_shot.mdl", 2000, "You got the Super Shotgun!\n");
	Inventory_SetQuantity(self, "supershotgun", 1);
	Inventory_SetQuantity(self, "shells", AMMO_SHELLS);
};

/*QUAKED weapon_nailgun (0 .5 .8) (-16 -16 0) (16 16 32)
*/
void() weapon_nailgun =
{
	weapon_spawnhandler("progs/g_nail.mdl", 2000, "You got the Nailgun!\n");
	Inventory_SetQuantity(self, "nailgun", 1);
	Inventory_SetQuantity(self, "nails", AMMO_NAILS);
};

/*QUAKED weapon_supernailgun (0 .5 .8) (-16 -16 0) (16 16 32)
*/
void() weapon_supernailgun =
{
	weapon_spawnhandler("progs/g_nail2.mdl", 2000, "You got the Super Nailgun!\n");
	Inventory_SetQuantity(self, "supernailgun", 1);
	Inventory_SetQuantity(self, "nails", AMMO_NAILS);
};

/*QUAKED weapon_grenadelauncher (0 .5 .8) (-16 -16 0) (16 16 32)
*/
void() weapon_grenadelauncher =
{
	weapon_spawnhandler("progs/g_rock.mdl", 2000, "You got the Proximity Grenade Launcher!\n");
	Inventory_SetQuantity(self, "grenadelauncher", 1);
	Inventory_SetQuantity(self, "rockets", AMMO_ROCKETS);
};

/*QUAKED weapon_rocketlauncher (0 .5 .8) (-16 -16 0) (16 16 32)
*/
void() weapon_rocketlauncher =
{
	weapon_spawnhandler("progs/g_rock2.mdl", 2000, "You got the Rocket Launcher!\n");
	Inventory_SetQuantity(self, "rocketlauncher", 1);
	Inventory_SetQuantity(self, "rockets", AMMO_ROCKETS);
};

/*QUAKED weapon_lightning (0 .5 .8) (-16 -16 0) (16 16 32)
*/
void() weapon_lightning =
{
	weapon_spawnhandler("progs/g_light.mdl", 2000, "You got the Thunderbolt!\n");
	Inventory_SetQuantity(self, "thunderbolt", 1);
	Inventory_SetQuantity(self, "plasmarifle", 1);
	Inventory_SetQuantity(self, "plasmawave", 1);
	Inventory_SetQuantity(self, "cells", AMMO_CELLS);
};

