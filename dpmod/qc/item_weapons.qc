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
	if ((other.ammo_shells  >= AMMOMAX_SHELLS ) || (self.ammo_shells  < 1))
	if ((other.ammo_nails   >= AMMOMAX_NAILS  ) || (self.ammo_nails   < 1))
	if ((other.ammo_rockets >= AMMOMAX_ROCKETS) || (self.ammo_rockets < 1))
	if ((other.ammo_cells   >= AMMOMAX_CELLS  ) || (self.ammo_cells   < 1))
	if ((other.ammo_xshells >= AMMOMAX_XSHELLS) || (self.ammo_xshells < 1))
		return; // would gain no ammo or weapon

	// if the player was using their best weapon, change up to the new one if better		
	stemp = self;
	self = other;
	best = W_BestWeapon(TRUE);
	self = stemp;


	if (itemrespawn && AMMOWEAPONOVERFLOW)
	{
		if (self.ammo_shells ) if (other.ammo_shells  < self.ammo_shells ) other.ammo_shells  = self.ammo_shells ; else other.ammo_shells  = other.ammo_shells  + AMMOWEAPONOVERFLOW_SHELLS ;
		if (self.ammo_nails  ) if (other.ammo_nails   < self.ammo_nails  ) other.ammo_nails   = self.ammo_nails  ; else other.ammo_nails   = other.ammo_nails   + AMMOWEAPONOVERFLOW_NAILS  ;
		if (self.ammo_rockets) if (other.ammo_rockets < self.ammo_rockets) other.ammo_rockets = self.ammo_rockets; else other.ammo_rockets = other.ammo_rockets + AMMOWEAPONOVERFLOW_ROCKETS;
		if (self.ammo_cells  ) if (other.ammo_cells   < self.ammo_cells  ) other.ammo_cells   = self.ammo_cells  ; else other.ammo_cells   = other.ammo_cells   + AMMOWEAPONOVERFLOW_CELLS  ;
		if (self.ammo_xshells) if (other.ammo_xshells < self.ammo_xshells) other.ammo_xshells = self.ammo_xshells; else other.ammo_xshells = other.ammo_xshells + AMMOWEAPONOVERFLOW_XSHELLS;
	}
	else
	{
		other.ammo_shells  = other.ammo_shells  + self.ammo_shells ;
		other.ammo_nails   = other.ammo_nails   + self.ammo_nails  ;
		other.ammo_rockets = other.ammo_rockets + self.ammo_rockets;
		other.ammo_cells   = other.ammo_cells   + self.ammo_cells  ;
		other.ammo_xshells = other.ammo_xshells + self.ammo_xshells;
	}

	if (other.flags & FL_CLIENT)
	{
		sprint (other, self.netname);
		stuffcmd(other, "bf\n");
	}

	// weapon touch sound
	sound (other, CHAN_ITEM, "weapons/pkup.wav", 1, ATTN_NORM);

	bound_ammo (other);

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
	if (item.ammo_shells)
	if (player.ammo_shells < AMMOMAX_SHELLS)
		f = f + (AMMOMAX_SHELLS - player.ammo_shells) * (AMMOMAX_SHELLS - player.ammo_shells) * 60 * item.ammo_shells / (AMMOMAX_SHELLS * AMMOMAX_SHELLS);
	if (item.ammo_nails)
	if (player.ammo_nails < AMMOMAX_NAILS)
		f = f + (AMMOMAX_NAILS - player.ammo_nails) * (AMMOMAX_NAILS - player.ammo_nails) * 15 * item.ammo_nails / (AMMOMAX_NAILS * AMMOMAX_NAILS);
	if (item.ammo_rockets)
	if (player.ammo_rockets < AMMOMAX_ROCKETS)
		f = f + (AMMOMAX_ROCKETS - player.ammo_rockets) * (AMMOMAX_ROCKETS - player.ammo_rockets) * 120 * item.ammo_rockets / (AMMOMAX_ROCKETS * AMMOMAX_ROCKETS);
	if (item.ammo_cells)
	if (player.ammo_cells < AMMOMAX_CELLS)
		f = f + (AMMOMAX_CELLS - player.ammo_cells) * (AMMOMAX_CELLS - player.ammo_cells) * 30 * item.ammo_cells / (AMMOMAX_CELLS * AMMOMAX_CELLS);
	if (item.ammo_xshells)
	if (player.ammo_xshells < AMMOMAX_XSHELLS)
		f = f + (AMMOMAX_XSHELLS - player.ammo_xshells) * (AMMOMAX_XSHELLS - player.ammo_xshells) * 110 * item.ammo_xshells / (AMMOMAX_XSHELLS * AMMOMAX_XSHELLS);
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
	self.ammo_shells  = shells;
	self.ammo_nails   = nails;
	self.ammo_rockets = rockets;
	self.ammo_cells   = cells;
	self.ammo_xshells = xshells;
//	self.havocrating = self.havocrating + self.ammo_shells * 60;
//	self.havocrating = self.havocrating + self.ammo_nails * 15;
//	self.havocrating = self.havocrating + self.ammo_rockets * 120;
//	self.havocrating = self.havocrating + self.ammo_cells * 30;
//	self.havocrating = self.havocrating + self.ammo_xshells * 110;
	self.touch = weapon_touch;
	setsize (self, '-16 -16 0', '16 16 32');
	/*
	if (deathmatch)
	{
		if (shells ) self.ammo_shells  = 999;
		if (nails  ) self.ammo_nails   = 999;
		if (rockets) self.ammo_rockets = 999;
		if (cells  ) self.ammo_cells   = 999;
		if (xshells) self.ammo_xshells = 999;
	}
	*/
	StartItem ();
};

/*QUAKED weapon_supershotgun (0 .5 .8) (-16 -16 0) (16 16 32)
*/
void() weapon_supershotgun    = {weapon_spawnhandler("progs/g_shot.mdl" , IT_WEAPON3,  30,   0,   0,   0,  20, "You got the Super Shotgun!\n");};

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
//void() weapon_lightning       = {weapon_spawnhandler("progs/g_light.mdl" , IT_WEAPON8 | IT_WEAPON9 | IT_WEAPON10,   0,   0,   0,  20,   0, "You got the Plasma Gun!\n");};
void() weapon_lightning       = {weapon_spawnhandler("progs/g_light.mdl" , IT_WEAPON8 | IT_WEAPON9,   0,   0,   0,  50,   0, "You got the Plasma Gun!\n");};

