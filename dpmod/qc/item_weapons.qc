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
	if ((ItemQuantity(other, "shells") >= AMMOMAX_SHELLS ) || (ItemQuantity(self, "shells") < 1))
	if ((ItemQuantity(other, "nails") >= AMMOMAX_NAILS  ) || (ItemQuantity(self, "nails") < 1))
	if ((ItemQuantity(other, "rockets") >= AMMOMAX_ROCKETS) || (ItemQuantity(self, "rockets") < 1))
	if ((ItemQuantity(other, "cells") >= AMMOMAX_CELLS  ) || (ItemQuantity(self, "cells") < 1))
	if ((ItemQuantity(other, "xshells") >= AMMOMAX_XSHELLS) || (ItemQuantity(self, "xshells") < 1))
		return; // would gain no ammo or weapon

	// if the player was using their best weapon, change up to the new one if better
	stemp = self;
	self = other;
	best = W_BestWeapon(TRUE);
	self = stemp;


	if (itemrespawn && AMMOWEAPONOVERFLOW)
	{
		if (ItemQuantity(self, "shells")) if (ItemQuantity(other, "shells") < ItemQuantity(self, "shells")) ItemSetQuantity(other, "shells", ItemQuantity(self, "shells")); else ItemAdjustQuantity(other, "shells", AMMOWEAPONOVERFLOW_SHELLS);
		if (ItemQuantity(self, "nails")) if (ItemQuantity(other, "nails") < ItemQuantity(self, "nails")) ItemSetQuantity(other, "nails", ItemQuantity(self, "nails")); else ItemAdjustQuantity(other, "nails", AMMOWEAPONOVERFLOW_NAILS);
		if (ItemQuantity(self, "rockets")) if (ItemQuantity(other, "rockets") < ItemQuantity(self, "rockets")) ItemSetQuantity(other, "rockets", ItemQuantity(self, "rockets")); else ItemAdjustQuantity(other, "rockets", AMMOWEAPONOVERFLOW_ROCKETS);
		if (ItemQuantity(self, "cells")) if (ItemQuantity(other, "cells") < ItemQuantity(self, "cells")) ItemSetQuantity(other, "cells", ItemQuantity(self, "cells")); else ItemAdjustQuantity(other, "cells", AMMOWEAPONOVERFLOW_CELLS);
		if (ItemQuantity(self, "xshells")) if (ItemQuantity(other, "xshells") < ItemQuantity(self, "xshells")) ItemSetQuantity(other, "xshells", ItemQuantity(self, "xshells")); else ItemAdjustQuantity(other, "xshells", AMMOWEAPONOVERFLOW_XSHELLS);
	}
	else
	{
		ItemAdjustQuantity(other, "shells", ItemQuantity(self, "shells"));
		ItemAdjustQuantity(other, "nails", ItemQuantity(self, "nails"));
		ItemAdjustQuantity(other, "rockets", ItemQuantity(self, "rockets"));
		ItemAdjustQuantity(other, "cells", ItemQuantity(self, "cells"));
		ItemAdjustQuantity(other, "xshells", ItemQuantity(self, "xshells"));
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

	// remove it in single player, or setup for respawning in deathmatch
	self.model = "";
	self.solid = SOLID_NOT;
	self.think = SUB_regen;
	self.nextthink = time + RESPAWNTIME_WEAPON;
	if (!itemrespawn)
		remove(self);
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
	if (ItemQuantity(item, "shells"))
	if (ItemQuantity(player, "shells") < AMMOMAX_SHELLS)
		f = f + (AMMOMAX_SHELLS - ItemQuantity(player, "shells")) * (AMMOMAX_SHELLS - ItemQuantity(player, "shells")) * 60 * ItemQuantity(item, "shells") / (AMMOMAX_SHELLS * AMMOMAX_SHELLS);
	if (ItemQuantity(item, "nails"))
	if (ItemQuantity(player, "nails") < AMMOMAX_NAILS)
		f = f + (AMMOMAX_NAILS - ItemQuantity(player, "nails")) * (AMMOMAX_NAILS - ItemQuantity(player, "nails")) * 15 * ItemQuantity(item, "nails") / (AMMOMAX_NAILS * AMMOMAX_NAILS);
	if (ItemQuantity(item, "rockets"))
	if (ItemQuantity(player, "rockets") < AMMOMAX_ROCKETS)
		f = f + (AMMOMAX_ROCKETS - ItemQuantity(player, "rockets")) * (AMMOMAX_ROCKETS - ItemQuantity(player, "rockets")) * 120 * ItemQuantity(item, "rockets") / (AMMOMAX_ROCKETS * AMMOMAX_ROCKETS);
	if (ItemQuantity(item, "cells"))
	if (ItemQuantity(player, "cells") < AMMOMAX_CELLS)
		f = f + (AMMOMAX_CELLS - ItemQuantity(player, "cells")) * (AMMOMAX_CELLS - ItemQuantity(player, "cells")) * 30 * ItemQuantity(item, "cells") / (AMMOMAX_CELLS * AMMOMAX_CELLS);
	if (ItemQuantity(item, "xshells"))
	if (ItemQuantity(player, "xshells") < AMMOMAX_XSHELLS)
		f = f + (AMMOMAX_XSHELLS - ItemQuantity(player, "xshells")) * (AMMOMAX_XSHELLS - ItemQuantity(player, "xshells")) * 110 * ItemQuantity(item, "xshells") / (AMMOMAX_XSHELLS * AMMOMAX_XSHELLS);
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
	ItemSetQuantity(self, "shells", shells);
	ItemSetQuantity(self, "nails", nails);
	ItemSetQuantity(self, "rockets", rockets);
	ItemSetQuantity(self, "cells", cells);
	ItemSetQuantity(self, "xshells", xshells);
//	self.havocrating = self.havocrating + ItemQuantity(self, "shells") * 60;
//	self.havocrating = self.havocrating + ItemQuantity(self, "nails") * 15;
//	self.havocrating = self.havocrating + ItemQuantity(self, "rockets") * 120;
//	self.havocrating = self.havocrating + ItemQuantity(self, "cells") * 30;
//	self.havocrating = self.havocrating + ItemQuantity(self, "xshells") * 110;
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

