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
	local   float   best, new, old;
	local	entity	stemp;

	if (other.classname != "player")
		return;
	if (other.health < 1)
		return;
	new = self.weapon;
	if (other.items & self.weapon == self.weapon) // has it already
	if ((Inventory_Quantity(other, "shells") >= AMMOMAX_SHELLS ) || (Inventory_Quantity(self, "shells") < 1))
	if ((Inventory_Quantity(other, "nails") >= AMMOMAX_NAILS  ) || (Inventory_Quantity(self, "nails") < 1))
	if ((Inventory_Quantity(other, "rockets") >= AMMOMAX_ROCKETS) || (Inventory_Quantity(self, "rockets") < 1))
	if ((Inventory_Quantity(other, "cells") >= AMMOMAX_CELLS  ) || (Inventory_Quantity(self, "cells") < 1))
	if ((Inventory_Quantity(other, "xshells") >= AMMOMAX_XSHELLS) || (Inventory_Quantity(self, "xshells") < 1))
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
		if (Inventory_Quantity(self, "xshells")) if (Inventory_Quantity(other, "xshells") < Inventory_Quantity(self, "xshells")) Inventory_SetQuantity(other, "xshells", Inventory_Quantity(self, "xshells")); else Inventory_AdjustQuantity(other, "xshells", AMMOWEAPONOVERFLOW_XSHELLS);
	}
	else
	{
		Inventory_AdjustQuantity(other, "shells", Inventory_Quantity(self, "shells"));
		Inventory_AdjustQuantity(other, "nails", Inventory_Quantity(self, "nails"));
		Inventory_AdjustQuantity(other, "rockets", Inventory_Quantity(self, "rockets"));
		Inventory_AdjustQuantity(other, "cells", Inventory_Quantity(self, "cells"));
		Inventory_AdjustQuantity(other, "xshells", Inventory_Quantity(self, "xshells"));
	}

	if (other.flags & FL_CLIENT)
	{
		sprint (other, self.netname);
		stuffcmd(other, "bf\n");
	}

	// weapon touch sound
	sound (other, CHAN_ITEM, "weapons/pkup.wav", 1, ATTN_NORM);

	// change to the weapon
	old = other.items;
	other.items = other.items | new;

	stemp = self;
	self = other;

	if (self.switchweapon == best)
		self.switchweapon = W_BestWeapon(TRUE);
//	Deathmatch_Weapon (old, new);

	self = stemp;

	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets

	if (deathmatch != 2)
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
	local float f, w;
	f = 0;
	// figure out which weapons would be gained
	w = item.weapon - (item.weapon & player.items);
	if (w)
	{
		if (w & IT_WEAPON1) f = f + 600;
		if (w & IT_WEAPON2) f = f + 1200;
		if (w & IT_WEAPON3) f = f + 2000;
		if (w & IT_WEAPON4) f = f + 1500;
		if (w & IT_WEAPON5) f = f + 3000;
		if (w & IT_WEAPON6) f = f + 2000;
		if (w & IT_WEAPON7) f = f + 2400;
		if (w & IT_WEAPON8) f = f + 3000;
		if (w & IT_WEAPON9) f = f + 1000;
		if (w & IT_WEAPON10) f = f + 3000;
	}
	if (Inventory_Quantity(item, "shells"))
	if (Inventory_Quantity(player, "shells") < AMMOMAX_SHELLS)
		f = f + (AMMOMAX_SHELLS - Inventory_Quantity(player, "shells")) * (AMMOMAX_SHELLS - Inventory_Quantity(player, "shells")) * 60 * Inventory_Quantity(item, "shells") / (AMMOMAX_SHELLS * AMMOMAX_SHELLS);
	if (Inventory_Quantity(item, "nails"))
	if (Inventory_Quantity(player, "nails") < AMMOMAX_NAILS)
		f = f + (AMMOMAX_NAILS - Inventory_Quantity(player, "nails")) * (AMMOMAX_NAILS - Inventory_Quantity(player, "nails")) * 15 * Inventory_Quantity(item, "nails") / (AMMOMAX_NAILS * AMMOMAX_NAILS);
	if (Inventory_Quantity(item, "rockets"))
	if (Inventory_Quantity(player, "rockets") < AMMOMAX_ROCKETS)
		f = f + (AMMOMAX_ROCKETS - Inventory_Quantity(player, "rockets")) * (AMMOMAX_ROCKETS - Inventory_Quantity(player, "rockets")) * 120 * Inventory_Quantity(item, "rockets") / (AMMOMAX_ROCKETS * AMMOMAX_ROCKETS);
	if (Inventory_Quantity(item, "cells"))
	if (Inventory_Quantity(player, "cells") < AMMOMAX_CELLS)
		f = f + (AMMOMAX_CELLS - Inventory_Quantity(player, "cells")) * (AMMOMAX_CELLS - Inventory_Quantity(player, "cells")) * 30 * Inventory_Quantity(item, "cells") / (AMMOMAX_CELLS * AMMOMAX_CELLS);
	if (Inventory_Quantity(item, "xshells"))
	if (Inventory_Quantity(player, "xshells") < AMMOMAX_XSHELLS)
		f = f + (AMMOMAX_XSHELLS - Inventory_Quantity(player, "xshells")) * (AMMOMAX_XSHELLS - Inventory_Quantity(player, "xshells")) * 110 * Inventory_Quantity(item, "xshells") / (AMMOMAX_XSHELLS * AMMOMAX_XSHELLS);
	return f;
};

void(string wmdl, float w, float shells, float nails, float rockets, float cells, float xshells, string name) weapon_spawnhandler =
{
	self.havocpickup = TRUE;
	self.pickupevalfunc = item_weapon_pickupeval;
	precache_model (wmdl);
	setmodel (self, wmdl);
	self.netname = name;
	self.weapon = w;
	/*
	if (deathmatch)
	{
		if (shells) shells = 99999;
		if (nails) nails = 99999;
		if (rockets) rockets = 99999;
		if (cells) cells = 99999;
		if (xshells) xshells = 99999;
	}
	*/
	Inventory_SetQuantity(self, "shells", shells);
	Inventory_SetQuantity(self, "nails", nails);
	Inventory_SetQuantity(self, "rockets", rockets);
	Inventory_SetQuantity(self, "cells", cells);
	Inventory_SetQuantity(self, "xshells", xshells);
//	self.havocrating = self.havocrating + Inventory_Quantity(self, "shells") * 60;
//	self.havocrating = self.havocrating + Inventory_Quantity(self, "nails") * 15;
//	self.havocrating = self.havocrating + Inventory_Quantity(self, "rockets") * 120;
//	self.havocrating = self.havocrating + Inventory_Quantity(self, "cells") * 30;
//	self.havocrating = self.havocrating + Inventory_Quantity(self, "xshells") * 110;
	self.touch = weapon_touch;
	setsize (self, '-16 -16 0', '16 16 32');
	StartItem ();
};

/*QUAKED weapon_supershotgun (0 .5 .8) (-16 -16 0) (16 16 32)
*/
void() weapon_supershotgun    = {weapon_spawnhandler("progs/g_shot.mdl" , IT_WEAPON3,  30,   0,   0,   0,   0, "You got the Super Shotgun!\n");};

/*QUAKED weapon_nailgun (0 .5 .8) (-16 -16 0) (16 16 32)
*/
void() weapon_nailgun         = {weapon_spawnhandler("progs/g_nail.mdl" , IT_WEAPON4,   0,  50,   0,   0,   0, "You got the Nailgun!\n");};

/*QUAKED weapon_supernailgun (0 .5 .8) (-16 -16 0) (16 16 32)
*/
void() weapon_supernailgun    = {weapon_spawnhandler("progs/g_nail2.mdl", IT_WEAPON5,   0,  50,   0,   0,   0, "You got the Super Nailgun!\n");};

/*QUAKED weapon_grenadelauncher (0 .5 .8) (-16 -16 0) (16 16 32)
*/
void() weapon_grenadelauncher = {weapon_spawnhandler("progs/g_rock.mdl" , IT_WEAPON6,   0,   0,  10,   0,   0, "You got the Proximity Grenade Launcher!\n");};

/*QUAKED weapon_rocketlauncher (0 .5 .8) (-16 -16 0) (16 16 32)
*/
void() weapon_rocketlauncher  = {weapon_spawnhandler("progs/g_rock2.mdl", IT_WEAPON7,   0,   0,  10,   0,   0, "You got the Rocket Launcher!\n");};

/*QUAKED weapon_lightning (0 .5 .8) (-16 -16 0) (16 16 32)
*/
void() weapon_lightning       = {weapon_spawnhandler("progs/g_light.mdl" , IT_WEAPON8 | IT_WEAPON9 | IT_WEAPON10,   0,   0,   0,  20,   0, "You got the Plasma Gun!\n");};
//void() weapon_lightning       = {weapon_spawnhandler("progs/g_light.mdl" , IT_WEAPON8 | IT_WEAPON9,   0,   0,   0,  50,   0, "You got the Plasma Gun!\n");};

