/* ALL LIGHTS SHOULD BE 0 1 0 IN COLOR ALL OTHER ITEMS SHOULD
BE .8 .3 .4 IN COLOR */

float itemrespawn; // set in worldspawn based on deathmatch and coop
void() monsterinwall;
void(entity e) waypointspawnforitem;
.string ammo_typestring;

void() SUB_regen =
{
	self.model = self.mdl;		// restore original model
	self.solid = SOLID_TRIGGER;	// allow it to be touched again
	if (game != GAME_NEXUIZ)
		sound (self, CHAN_VOICE, "items/itembk2.wav", 1, ATTN_NORM);	// play respawn sound
	setorigin (self, self.origin);
	self.health = self.max_health;
	if (self.health >= 1)
	{
		self.takedamage = DAMAGE_YES;
		self.solid = SOLID_BBOX;
	}

	//te_teleport(self.origin);
};



/*QUAKED noclass (0 0 0) (-8 -8 -8) (8 8 8)
prints a warning message when spawned
*/
void() noclass =
{
	dprint ("noclass spawned at");
	dprint (vtos(self.origin));
	dprint ("\n");
	remove (self);
};



/*
============
PlaceItem

plants the object on the floor
============
*/
void() PlaceItem =
{
	if (deathmatch == DM_FRAGFEST || deathmatch == DM_ELIM)
	{
		activator = world;
		SUB_UseTargets(); // fire all targets / killtargets
		remove(self);
		return;
	}

	self.mdl = self.model;		// so it can be restored on respawn
	self.flags = FL_ITEM;		// make extra wide
	self.movetype = MOVETYPE_TOSS;
	self.velocity = '0 0 0';
	if (self.health >= 1)
		self.solid = SOLID_BBOX;
	else
		self.solid = SOLID_TRIGGER;

	// make bots pick up this tiem, if it has any value
	if (self.pickupevalfunc)
		self.havocpickup = TRUE;

	tracebox(self.origin + '0 0 1', self.mins, self.maxs, self.origin + '0 0 -256', FALSE, self);
	if (trace_startsolid)
	{
		dprint (self.classname);
		dprint (" spawned in solid at ");
		dprint (vtos(self.origin));
		dprint ("\n");
	}

	if (!droptofloor())
	{
		dprint (self.classname);
		dprint (" could not find floor at ");
		dprint (vtos(self.origin));
		dprint ("\n");
	}

	waypointspawnforitem(self);
};

/*
============
StartItem

Sets the clipping size and plants the object on the floor
============
*/
void() StartItem =
{
	self.solid = SOLID_NOT;
	self.movetype = MOVETYPE_NONE;
	self.velocity = '0 0 0';
	setorigin(self, self.origin);
	self.nextthink = time + 0.2;	// items start after other solids
	self.think = PlaceItem;
};

/*
=========================================================================

HEALTH BOX

=========================================================================
*/
// T_Heal: add health to an entity, limiting health to max_health
// "ignore" will ignore max_health limit
.float rotthink; // used in regen.qc
float (entity e, float healamount, float ignore) T_Heal =
{
	local float m;
	// don't heal a corpse
	if (e.health <= 0)
		return 0;

	// which maxhealth to use
	m = e.max_health;
	if (ignore)
		m = HEALTHMEGAMAX;

	if (e.health >= m)
		return 0;

	e.health = e.health + healamount;
	e.rotthink = time + 5; // 5 sec before rot begins
	e.bodyhealth = e.bodyhealth + healamount;

	if (e.health > m)
		e.health = m;
	return 1;
};

/*QUAKED item_health (.3 .3 1) (0 0 0) (32 32 32) rotten megahealth
Health box. Normally gives 25 points.
Rotten box heals 5-10 points,
megahealth will add 100 health, then
rot you down to your maximum health limit,
one point per second.
*/

float	H_ROTTEN = 1;
float	H_MEGA = 2;
void() health_touch;
// TODO: Nexuiz items
float(entity player, entity item) item_health_pickupeval = {if (player.health >= player.max_health) return -1;return (player.max_health - player.health) * (player.max_health - player.health) * item.dmg / (player.max_health * player.max_health);};
float(entity player, entity item) item_megahealth_pickupeval = {if (player.health >= (HEALTHMEGAMAX + player.max_health) * 0.5) return -1;return (HEALTHMEGAMAX - player.health) * (HEALTHMEGAMAX - player.health) * item.dmg / (HEALTHMEGAMAX * HEALTHMEGAMAX);};

void() item_health =
{
	self.touch = health_touch;

	if (game == GAME_NEXUIZ)
	{
		// TODO: Nexuiz health items
		if (self.spawnflags & H_ROTTEN)
		{
			precache_model("models/items/g_h1.md3");
			setmodel(self, "models/items/g_h1.md3");
			self.netname = "+5 health\n";
			self.count2 = 5;
			self.cnt2 = TRUE;
			self.dmg = 7500;
			self.pickupevalfunc = item_health_pickupeval;
		}
		else if (self.spawnflags & H_MEGA)
		{
			precache_model("models/items/g_h100.md3");
			setmodel(self, "models/items/g_h100.md3");
			self.netname = "+100 health\n";
			self.count2 = 100;
			self.cnt2 = TRUE;
			self.dmg = 25000;
			self.pickupevalfunc = item_megahealth_pickupeval;
		}
		else
		{
			precache_model("models/items/g_h25.md3");
			setmodel(self, "models/items/g_h25.md3");
			self.netname = "+25 health\n";
			self.count2 = 25;
			self.cnt2 = FALSE;
			self.dmg = 12500;
			self.pickupevalfunc = item_health_pickupeval;
		}
		setsize (self, '0 0 0', '32 32 16');
	}
	else
	{
		if (self.spawnflags & H_ROTTEN)
		{
			precache_model("maps/b_bh10.bsp");
			precache_sound("items/r_item1.wav");
			setmodel(self, "maps/b_bh10.bsp");
			self.noise = "items/r_item1.wav";
			self.netname = "+15 health\n";
			self.count2 = 15;
			self.cnt2 = FALSE;
			self.dmg = 7500;
			self.pickupevalfunc = item_health_pickupeval;
		}
		else if (self.spawnflags & H_MEGA)
		{
			precache_model("maps/b_bh100.bsp");
			precache_sound("items/r_item2.wav");
			setmodel(self, "maps/b_bh100.bsp");
			self.noise = "items/r_item2.wav";
			self.netname = "+100 health\n";
			self.count2 = 100;
			self.cnt2 = TRUE;
			self.dmg = 25000;
			self.pickupevalfunc = item_megahealth_pickupeval;
		}
		else
		{
			precache_model("maps/b_bh25.bsp");
			precache_sound("items/health1.wav");
			setmodel(self, "maps/b_bh25.bsp");
			self.noise = "items/health1.wav";
			self.netname = "+25 health\n";
			self.count2 = 25;
			self.cnt2 = FALSE;
			self.dmg = 12500;
			self.pickupevalfunc = item_health_pickupeval;
		}
		setsize (self, '0 0 0', '32 32 16');
	}

	StartItem ();
};


void() health_touch =
{
	if (other.classname != "player")
		return;

	if (!T_Heal(other, self.count2, self.cnt2))
		return;

	sprint(other, self.netname);

	// health touch sound
	sound(other, CHAN_ITEM, self.noise, 1, ATTN_NORM);

	stuffcmd(other, "bf\n");

	self.model = "";
	self.solid = SOLID_NOT;

	if (itemrespawn)
	{
		if (self.cnt2)
			self.nextthink = time + RESPAWNTIME_MEGAHEALTH;
		else
			self.nextthink = time + RESPAWNTIME_HEALTH;
		self.think = SUB_regen;
	}
	else
	{
		self.think = SUB_Remove;
		self.nextthink = time + 0.1;
	}

	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets
};

/*
===============================================================================

ARMOR

===============================================================================
*/

void() armor_touch;

void() armor_touch =
{
	if (other.health <= 0)
		return;
	if (other.classname != "player")
		return;

	// stop fire
	if (other.flame)
		other.flame.cnt = 0; // clear fuel

	if ((other.armortype * other.armorvalue) >= (self.armortype * self.armorvalue))
		return; // wearing better armor already

	other.armortype = self.armortype;
	other.armorvalue = self.armorvalue;
	other.items = other.items - (other.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3)) + self.items;

	self.solid = SOLID_NOT;
	self.model = "";
	if (itemrespawn)
	{
		self.nextthink = time + RESPAWNTIME_ARMOR;
		self.think = SUB_regen;
	}
	else
	{
		self.nextthink = time + 0.1;
		self.think = SUB_Remove;
	}

	sprint (other, self.netname);
	// armor touch sound
	sound(other, CHAN_ITEM, "items/armor1.wav", 1, ATTN_NORM);
	stuffcmd (other, "bf\n");

	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets
};

float(entity player, entity item) item_armor_pickupeval =
{
	local float new, old;
	new = item.dmg;
	old = player.armorvalue * player.armortype;
	if (new <= old)
		return 0;
	else
		return (new - old) * (new - old) * item.dmg2;
};

// TODO: Nexuiz items

/*QUAKED item_armor1 (0 .5 .8) (-16 -16 0) (16 16 32)
100 green armor, 30% absorb
*/

void() item_armor1 =
{
	self.touch = armor_touch;
	if (game == GAME_NEXUIZ)
	{
		precache_model ("models/items/g_a25.md3");
		setmodel (self, "models/items/g_a25.md3");
	}
	else
	{
		precache_model ("progs/armor.mdl");
		setmodel (self, "progs/armor.mdl");
		self.skin = 0;
	}
	self.frame = 0;
	self.armortype = GREENARMOR_TYPE;
	if (self.armorvalue < 1)
		self.armorvalue = GREENARMOR_VALUE;
	self.netname = "Green armor - 30% off damage\n";
	self.items = IT_ARMOR1;
	self.dmg = self.armorvalue * self.armortype;
	self.dmg2 = 10000 / (160 * 160); // 200 red armor = 160 rating (200 * 0.8)
	self.pickupevalfunc = item_armor_pickupeval;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};

/*QUAKED item_armor2 (0 .5 .8) (-16 -16 0) (16 16 32)
150 yellow armor, 60% absorb
*/

void() item_armor2 =
{
	self.touch = armor_touch;
	if (game == GAME_NEXUIZ)
	{
		precache_model ("models/items/g_a25.md3");
		setmodel (self, "models/items/g_a25.md3");
	}
	else
	{
		precache_model ("progs/armor.mdl");
		setmodel (self, "progs/armor.mdl");
		self.skin = 1;
	}
	self.frame = 0;
	self.armortype = YELLOWARMOR_TYPE;
	if (self.armorvalue < 1)
		self.armorvalue = YELLOWARMOR_VALUE;
	self.netname = "Yellow armor - 60% off damage\n";
	self.items = IT_ARMOR2;
	self.dmg = self.armorvalue * self.armortype;
	self.dmg2 = 10000 / (160 * 160); // 200 red armor = 160 rating (200 * 0.8)
	self.pickupevalfunc = item_armor_pickupeval;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};

/*QUAKED item_armorInv (0 .5 .8) (-16 -16 0) (16 16 32)
200 red armor, 80% absorb
*/

void() item_armorInv =
{
	self.touch = armor_touch;
	if (game == GAME_NEXUIZ)
	{
		precache_model ("models/items/g_a25.md3");
		setmodel (self, "models/items/g_a25.md3");
	}
	else
	{
		precache_model ("progs/armor.mdl");
		setmodel (self, "progs/armor.mdl");
		self.skin = 2;
	}
	self.armortype = REDARMOR_TYPE;
	if (self.armorvalue < 1)
		self.armorvalue = REDARMOR_VALUE;
	self.netname = "Red armor - 80% off damage\n";
	self.items = IT_ARMOR3;
	self.dmg = self.armorvalue * self.armortype;
	self.dmg2 = 10000 / (160 * 160); // 200 red armor = 160 rating (200 * 0.8)
	self.pickupevalfunc = item_armor_pickupeval;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};

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
	if (other.health <= 0)
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

	sprint (other, self.netname);
	// weapon touch sound
	sound (other, CHAN_ITEM, "weapons/pkup.wav", 1, ATTN_NORM);
	stuffcmd (other, "bf\n");

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
	entity w;
	// scan our item list to see which weapons a pickup would give
	w = Inventory_GetNextItem(item, world);
	while (w)
	{
		// if this is a weapon, check if the player already has it
		if (w.count1 == 1)
		if (!Inventory_Quantity(player, w.netname))
			return item.dmg;
		w = Inventory_GetNextItem(item, w);
	}
	return 0; // player already has the weapon
};

void(string wmdl, float rating, string name) weapon_spawnhandler =
{
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
	weapon_spawnhandler("progs/g_rock.mdl", 2000, "You got the Grenade Launcher!\n");
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
	weapon_spawnhandler("progs/g_light.mdl", 2000, "You got the Thunderbolt and Plasma Rifle!\n");
	Inventory_SetQuantity(self, "thunderbolt", 1);
	Inventory_SetQuantity(self, "plasmarifle", 1);
	Inventory_SetQuantity(self, "cells", AMMO_CELLS);
};

/*QUAKED weapon_plasma (0 .5 .8) (-16 -16 0) (16 16 32)
*/
void() weapon_plasma =
{
	weapon_spawnhandler("progs/g_light.mdl", 2000, "You got the Plasma Rifle!\n");
	Inventory_SetQuantity(self, "plasmarifle", 1);
	Inventory_SetQuantity(self, "cells", AMMO_CELLS);
};

/*QUAKED weapon_plasma_wave (0 .5 .8) (-16 -16 0) (16 16 32)
*/
void() weapon_plasma_wave =
{
	weapon_spawnhandler("progs/g_light.mdl", 2000, "You got the Plasma Wave Cannon!\n");
	Inventory_SetQuantity(self, "plasmawave", 1);
	Inventory_SetQuantity(self, "cells", AMMO_CELLS);
};

// these are compatibility with various other games, and older (generally unreleased) dpmod maps
void() weapon_machinegun =
{
	weapon_spawnhandler("progs/g_nail.mdl", 2000, "You got the Nailgun!\n");
	Inventory_SetQuantity(self, "nailgun", 1);
	Inventory_SetQuantity(self, "nails", AMMO_NAILS);
};
void() weapon_chaingun =
{
	weapon_spawnhandler("progs/g_nail2.mdl", 2000, "You got the Super Nailgun!\n");
	Inventory_SetQuantity(self, "supernailgun", 1);
	Inventory_SetQuantity(self, "nails", AMMO_NAILS);
};
void() weapon_rifle =
{
	weapon_spawnhandler("progs/g_light.mdl", 2000, "You got the Thunderbolt!\n");
	Inventory_SetQuantity(self, "thunderbolt", 1);
	Inventory_SetQuantity(self, "cells", AMMO_CELLS);
};
void() weapon_proximitygrenade =
{
	weapon_spawnhandler("progs/g_rock.mdl", 2000, "You got the Grenade Launcher!\n");
	Inventory_SetQuantity(self, "grenadelauncher", 1);
	Inventory_SetQuantity(self, "rockets", AMMO_ROCKETS);
};

/*
===============================================================================

AMMO

===============================================================================
*/

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

	sprint (other, self.netname);
	// ammo touch sound
	sound (other, CHAN_ITEM, "weapons/lock4.wav", 1, ATTN_NORM);
	stuffcmd (other, "bf\n");

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

float(entity player, entity item) item_shells_pickupeval  = {local float f;f = Inventory_GetCarriableQuantity(player, "shells")  / self.aflag;return f * f * AMMO_SHELL_DAMAGE ;};
float(entity player, entity item) item_nails_pickupeval   = {local float f;f = Inventory_GetCarriableQuantity(player, "nails")   / self.aflag;return f * f * AMMO_NAIL_DAMAGE  ;};
float(entity player, entity item) item_rockets_pickupeval = {local float f;f = Inventory_GetCarriableQuantity(player, "rockets") / self.aflag;return f * f * AMMO_ROCKET_DAMAGE;};
float(entity player, entity item) item_cells_pickupeval   = {local float f;f = Inventory_GetCarriableQuantity(player, "cells")   / self.aflag;return f * f * AMMO_CELL_DAMAGE  ;};

/*QUAKED item_shells (0 .5 .8) (0 0 0) (32 32 32) big
*/

void() item_shells =
{
	self.touch = ammo_touch;

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
	self.weapon = 1;
	setsize (self, '-16 -16 0', '16 16 8');
	setorigin(self, self.origin + '16 16 0');
	self.ammo_typestring = "shells";
	self.pickupevalfunc = item_shells_pickupeval;
	StartItem ();
};

/*QUAKED item_spikes (0 .5 .8) (0 0 0) (32 32 32) big
*/

void() item_spikes =
{
	self.touch = ammo_touch;

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
	self.weapon = 2;
	self.ammo_typestring = "nails";
	self.pickupevalfunc = item_nails_pickupeval;
	StartItem ();
};

/*QUAKED item_rockets (0 .5 .8) (0 0 0) (32 32 32) big
*/

void() item_rockets =
{
	self.touch = ammo_touch;

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
	self.weapon = 3;
	self.ammo_typestring = "rockets";
	setsize (self, '-16 -16 0', '16 16 16');
	setorigin(self, self.origin + '16 16 0');
	self.pickupevalfunc = item_rockets_pickupeval;
	StartItem ();
};

/*QUAKED item_cells (0 .5 .8) (0 0 0) (32 32 32) big
*/

void() item_cells =
{
	self.touch = ammo_touch;

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
	self.weapon = 4;
	self.ammo_typestring = "cells";
	self.pickupevalfunc = item_cells_pickupeval;
	StartItem ();
};


/*QUAKED item_weapon (0 .5 .8) (0 0 0) (32 32 32) shotgun rocket spikes big
DO NOT USE THIS!!!! IT WILL BE REMOVED!
*/

float WEAPON_SHOTGUN = 1;
float WEAPON_ROCKET = 2;
float WEAPON_SPIKES = 4;
float WEAPON_BIG = 8;
void() item_weapon =
{
	// Lord Havoc note: I would have removed this function,
	// but while playing e2m2 and other maps I found it was used :(
	// at least I cleaned up and shrunk the thing...
	self.weapon = self.spawnflags;
	self.spawnflags = self.weapon - (self.weapon & (WEAPON_SHOTGUN | WEAPON_ROCKET | WEAPON_SPIKES | WEAPON_BIG));
	if (self.weapon & WEAPON_BIG    ) self.spawnflags = self.spawnflags | WEAPON_BIG2;
	if (self.weapon & WEAPON_SHOTGUN) item_shells();
	else if (self.weapon & WEAPON_SPIKES ) item_spikes();
	else if (self.weapon & WEAPON_ROCKET ) item_rockets();
};

/*
===============================================================================

KEYS

===============================================================================
*/

void() key_touch =
{
	if (other.classname != "player")
		return;
	if (other.health <= 0)
		return;
	if (coop)
	if (other.items & self.items)
		return;

	sprint (other, "You got the ");
	sprint (other, self.netname);
	sprint (other,"\n");

	sound (other, CHAN_ITEM, self.noise, 1, ATTN_NORM);
	stuffcmd (other, "bf\n");
	if (self.items == IT_KEY1)
		other.keys_silver = other.keys_silver + 1;
	if (self.items == IT_KEY2)
		other.keys_gold = other.keys_gold + 1;
	other.items = other.items | self.items;

	/*
	if (coop)
	{
		self.solid = SOLID_NOT;
		self.model = "";
		self.think = SUB_regen;
		self.nextthink = time + 5;
	}
	*/

	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets

	if (coop == 0)
		remove(self);
};


void() key_setsounds =
{
	// 0-2 are normal quake maps, 3-5 are Dark Places maps
	if (world.worldtype == 0 || world.worldtype == 3)
	{
		precache_sound ("misc/medkey.wav");
		self.noise = "misc/medkey.wav";
	}
	if (world.worldtype == 1 || world.worldtype == 4)
	{
		precache_sound ("misc/runekey.wav");
		self.noise = "misc/runekey.wav";
	}
	if (world.worldtype == 2 || world.worldtype == 5)
	{
		precache_sound2 ("misc/basekey.wav");
		self.noise = "misc/basekey.wav";
	}
};

/*QUAKED item_key1 (0 .5 .8) (-16 -16 -24) (16 16 32)
SILVER key
In order for keys to work
you MUST set your maps
worldtype to one of the
following:
0: medieval
1: metal
2: base
*/

void() item_key1 =
{
	if (deathmatch)
	{
		remove(self);
		return;
	}
	// 0-2 are normal quake maps, 3-5 are Dark Places maps
	if (world.worldtype == 0 || world.worldtype == 3)
	{
		precache_model ("progs/w_s_key.mdl");
		setmodel (self, "progs/w_s_key.mdl");
		self.netname = "silver key";
	}
	if (world.worldtype == 1 || world.worldtype == 4)
	{
		precache_model ("progs/m_s_key.mdl");
		setmodel (self, "progs/m_s_key.mdl");
		self.netname = "silver runekey";
	}
	if (world.worldtype == 2 || world.worldtype == 5)
	{
		precache_model2 ("progs/b_s_key.mdl");
		setmodel (self, "progs/b_s_key.mdl");
		self.netname = "silver keycard";
	}
	key_setsounds();
	self.touch = key_touch;
	self.items = IT_KEY1;
	setsize (self, '-16 -16 -24', '16 16 32');
	StartItem ();
};

/*QUAKED item_key2 (0 .5 .8) (-16 -16 -24) (16 16 32)
GOLD key
In order for keys to work
you MUST set your maps
worldtype to one of the
following:
0: medieval
1: metal
2: base
*/

void() item_key2 =
{
	if (deathmatch)
	{
		remove(self);
		return;
	}
	// 0-2 are normal quake maps, 3-5 are Dark Places maps
	if (world.worldtype == 0 || world.worldtype == 3)
	{
		precache_model ("progs/w_g_key.mdl");
		setmodel (self, "progs/w_g_key.mdl");
		self.netname = "gold key";
	}
	if (world.worldtype == 1 || world.worldtype == 4)
	{
		precache_model ("progs/m_g_key.mdl");
		setmodel (self, "progs/m_g_key.mdl");
		self.netname = "gold runekey";
	}
	if (world.worldtype == 2 || world.worldtype == 5)
	{
		precache_model2 ("progs/b_g_key.mdl");
		setmodel (self, "progs/b_g_key.mdl");
		self.netname = "gold keycard";
	}
	key_setsounds();
	self.touch = key_touch;
	self.items = IT_KEY2;
	setsize (self, '-16 -16 -24', '16 16 32');
	StartItem ();
};



/*
===============================================================================

END OF LEVEL RUNES

===============================================================================
*/

void() sigil_touch =
{
	if (other.classname != "player")
		return;
	if (other.health <= 0)
		return;

	centerprint (other, "You got the rune!");

	sound (other, CHAN_ITEM, self.noise, 1, ATTN_NORM);
	stuffcmd (other, "bf\n");
	self.solid = SOLID_NOT;
	self.model = "";
	serverflags = serverflags | (self.spawnflags & 15);
	self.classname = "";		// so rune doors won't find it

	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets

	remove(self);
};


/*QUAKED item_sigil (0 .5 .8) (-16 -16 -24) (16 16 32) E1 E2 E3 E4
End of level sigil, pick up to end episode and return to jrstart.
*/

void() item_sigil =
{
	if (!self.spawnflags)
		objerror ("no spawnflags");

	precache_sound ("misc/runekey.wav");
	self.noise = "misc/runekey.wav";

	if (self.spawnflags & 1)
	{
		precache_model ("progs/end1.mdl");
		setmodel (self, "progs/end1.mdl");
	}
	if (self.spawnflags & 2)
	{
		precache_model2 ("progs/end2.mdl");
		setmodel (self, "progs/end2.mdl");
	}
	if (self.spawnflags & 4)
	{
		precache_model2 ("progs/end3.mdl");
		setmodel (self, "progs/end3.mdl");
	}
	if (self.spawnflags & 8)
	{
		precache_model2 ("progs/end4.mdl");
		setmodel (self, "progs/end4.mdl");
	}

	self.touch = sigil_touch;
	setsize (self, '-16 -16 -24', '16 16 32');
	StartItem ();
};

/*
===============================================================================

POWERUPS

===============================================================================
*/

void() powerup_touch;


void() powerup_touch =
{
	if (other.classname != "player")
		return;
	if (other.health <= 0)
		return;

	sprint (other, self.netname);

	if (itemrespawn)
	{
		self.mdl = self.model;
		self.nextthink = time + RESPAWNTIME_ARTIFACT;
		self.think = SUB_regen;
	}
	else
	{
		self.think = SUB_Remove;
		self.nextthink = time;
	}

	sound (other, CHAN_VOICE, self.noise, 1, ATTN_NORM);
	stuffcmd (other, "bf\n");
	self.solid = SOLID_NOT;
	other.items = other.items | self.items;
	self.model = "";

// do the apropriate action
	if (self.items & IT_SUIT)
	{
		other.rad_time = 1;
		other.radsuit_finished = time + ARTIFACT_SUIT_TIME;
	}

	if (self.items & IT_INVULNERABILITY)
	{
		other.invincible_time = 1;
		other.invincible_finished = time + ARTIFACT_INVULNERABILITY_TIME;
	}

	if (self.items & IT_INVISIBILITY)
	{
		other.invisible_time = 1;
		other.invisible_finished = time + ARTIFACT_INVISIBILITY_TIME;
	}

	if (self.items & IT_QUAD)
	{
		other.super_time = 1;
		other.super_damage_finished = time + ARTIFACT_SUPER_DAMAGE_TIME;
	}

	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets
};

// TODO: Nexuiz items

// FIXME: bother to compare artifact times?  I think it all balances out
// really (when you don't have the artifact, you really want it, when you do
// have one already, you want another simply to deny everyone else the
// artifact and prolong your run a bit longer)
float(entity player, entity item) item_artifact_pickupeval = {return item.dmg;};

/*QUAKED item_artifact_invulnerability (0 .5 .8) (-16 -16 -24) (16 16 32)
Player is invulnerable for 30 seconds
*/
void() item_artifact_invulnerability =
{
	self.touch = powerup_touch;

	precache_model ("progs/invulner.mdl");
	precache_sound ("items/protect.wav");
	precache_sound ("items/protect2.wav");
	precache_sound ("items/protect3.wav");
	self.noise = "items/protect.wav";
	setmodel (self, "progs/invulner.mdl");
	self.netname = "You got the Pentagram of Protection!\n";
	self.items = IT_INVULNERABILITY;
	setsize (self, '-16 -16 -24', '16 16 32');
	self.dmg = 10000;
	self.pickupevalfunc = item_artifact_pickupeval;
	StartItem ();
};

/*QUAKED item_artifact_envirosuit (0 .5 .8) (-16 -16 -24) (16 16 32)
Player takes no damage from
water or slime for 60 seconds
*/
void() item_artifact_envirosuit =
{
	self.touch = powerup_touch;

	precache_model ("progs/suit.mdl");
	precache_sound ("items/suit.wav");
	precache_sound ("items/suit2.wav");
	self.noise = "items/suit.wav";
	setmodel (self, "progs/suit.mdl");
	self.netname = "You got the Biosuit\n";
	self.items = IT_SUIT;
	setsize (self, '-16 -16 -24', '16 16 32');
	StartItem ();
};

/*QUAKED item_artifact_invisibility (0 .5 .8) (-16 -16 -24) (16 16 32)
Player is mostly invisible for 60 seconds.
*/
void() item_artifact_invisibility =
{
	self.touch = powerup_touch;

	precache_model ("progs/invisibl.mdl");
	precache_sound ("items/inv1.wav");
	precache_sound ("items/inv2.wav");
	precache_sound ("items/inv3.wav");
	self.noise = "items/inv1.wav";
	setmodel (self, "progs/invisibl.mdl");
	self.netname = "You got the Ring of Shadows!\n";
	self.items = IT_INVISIBILITY;
	setsize (self, '-16 -16 -24', '16 16 32');
	self.dmg = 5000;
	self.pickupevalfunc = item_artifact_pickupeval;
	StartItem ();
};


/*QUAKED item_artifact_super_damage (0 .5 .8) (-16 -16 -24) (16 16 32)
30 second Quad Damage, 'nuff said.
*/
void() item_artifact_super_damage =
{
	self.touch = powerup_touch;

	precache_model ("progs/quaddama.mdl");
	precache_sound ("items/damage.wav");
	precache_sound ("items/damage2.wav");
	precache_sound ("items/damage3.wav");
	self.noise = "items/damage.wav";
	setmodel (self, "progs/quaddama.mdl");
	self.netname = "You got the Quad Damage!\n";
	self.items = IT_QUAD;
	setsize (self, '-16 -16 -24', '16 16 32');
	self.dmg = 5000;
	self.pickupevalfunc = item_artifact_pickupeval;
	StartItem ();
};



/*
===============================================================================

PLAYER BACKPACKS

===============================================================================
*/

// TODO: Nexuiz items

void() BackpackRemove =
{
	Inventory_DestroyByName(self, "", 99999);
	remove(self);
};

void() BackpackTouch =
{
	local entity stemp, item;
	local string s;
	local float old, new, switchweapon;
	local float acount, d;

	if (other.classname != "player")
		return;
	if (other.health <= 0)
		return;

	acount = 0;
	self.items = self.items - (self.items & other.items);

	stemp = self;
	self = other;
	switchweapon = self.switchweaponclass == W_BestWeaponClass(TRUE);
	self = stemp;

	new = self.items;
	old = other.items;
	other.items = old | new;

	item = Inventory_GetNextItem(self, world);
	while (item)
	{
		d = Inventory_AbsorbItem(other, item);
		if (d)
		{
			if (other.flags & FL_CLIENT)
			{
				s = ftos(d);
				if (acount)
					sprint(other, ", ");
				else
					sprint(other, "You get ");
				acount = 1;
				sprint (other, s);
				sprint (other, " ");
				sprint (other, item.netname);
			}
			if (item.count == 0)
			{
				Item_Destroy(item);
				item = world;
			}
		}
		item = Inventory_GetNextItem(self, item);
	}
	if (other.flags & FL_CLIENT)
	{
		if (self.super_damage_finished > time)
		{
			if (acount)
				sprint(other, ", ");
			else
				sprint(other, "You get ");
			acount = 1;
			sprint (other, "quad");
		}
		if (self.invisible_finished > time)
		{
			if (acount)
				sprint(other, ", ");
			else
				sprint(other, "You get ");
			acount = 1;
			sprint (other, "ring");
		}
		if (self.invincible_finished > time)
		{
			if (acount)
				sprint(other, ", ");
			else
				sprint(other, "You get ");
			acount = 1;
			sprint (other, "protection");
		}

		if (acount)
			sprint (other, "\n");
	}
// backpack touch sound
	sound (other, CHAN_ITEM, "weapons/lock4.wav", 1, ATTN_NORM);
	stuffcmd (other, "bf\n");

	// if the player was using their best weapon, change up to the new one if better
	if (switchweapon)
	{
		self = other;
		self.switchweaponclass = W_BestWeaponClass(TRUE);
		self = stemp;
	}

	// remove the backpack
	BackpackRemove();
};

// FIXME: bother to rate backpacks based on their contents?
float(entity player, entity item) item_backpack_pickupeval =
{
	return 4000;
};

/*
===============
DropBackpack
===============
*/
void() DropBackpack =
{
	local entity item, head, killent;
	local float c, t;

	if (deathmatch == DM_FRAGFEST || deathmatch == DM_ELIM)
		return;

	//if (deathmatch == DM_RPG)
	//	Inventory_DropByName(self, "", 99999);

	if (!Inventory_GetNextItem(self, world))
	//if (!(Inventory_Quantity(self, "shells") + Inventory_Quantity(self, "nails") + Inventory_Quantity(self, "rockets") + Inventory_Quantity(self, "cells")))
	//if (!(self.items & (IT_WEAPON3 | IT_WEAPON4 | IT_WEAPON5 | IT_WEAPON6 | IT_WEAPON7 | IT_WEAPON8 | IT_WEAPON9 | IT_WEAPON10)))
		return; // nothing in it

	// don't drop a backpack if in a NODROP zone (such as lava)
	traceline(self.origin, self.origin, MOVE_NORMAL, self);
	if (trace_dpstartcontents & DPCONTENTS_NODROP)
		return;

	head = findchain(classname, "backpack");
	if (head)
	{
		// pick the first one
		killent = head;
		t = killent.nextthink;
		head = head.chain;
		// then see if any others are older
		c = 1;
		while (head != world)
		{
			c = c + 1;
			if (head.nextthink < t)
			{
				t = head.nextthink;
				killent = head;
			}
			head = head.chain;
		}
		// if there are at least 30 backpacks, remove the oldest
		if (c >= 30)
		{
			killent.solid = SOLID_NOT;
			killent.classname = "";
			killent.think = BackpackRemove;
			killent.nextthink = time;
		}
	}

	item = spawn();
	//item.owner = item;
	//item.enemy = item;
	item.classname = "backpack";
	item.havocpickup = TRUE;
	item.pickupevalfunc = item_backpack_pickupeval;

	item.velocity_x = crandom() * 100;
	item.velocity_y = crandom() * 100;
	item.velocity_z = 300;

	item.colormap = self.colormap; // color backpack like player
	item.flags = FL_ITEM;
	item.solid = SOLID_TRIGGER;
	item.movetype = MOVETYPE_TOSS;
	setmodel (item, "progs/backpack.mdl");
	setsize (item, '-16 -16 0', '16 16 56');
	setorigin(item, self.origin - '0 0 24');
	item.touch = BackpackTouch;

	if (self.flags & FL_MONSTER)
		item.nextthink = time + 3600;    // remove after 60 minutes
	else
		item.nextthink = time + 120;    // remove after 2 minutes
	item.think = BackpackRemove;

	// this transfers legacy items
	//item.items = self.items & (IT_WEAPON1 | IT_WEAPON2 | IT_WEAPON3 | IT_WEAPON4 | IT_WEAPON5 | IT_WEAPON6 | IT_WEAPON7 | IT_WEAPON8 | IT_WEAPON9 | IT_WEAPON10);
	// this transfers all inventory items (ammo, etc)
	Inventory_AbsorbInventory(item, self);
};
