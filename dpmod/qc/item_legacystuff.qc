// compatibility stuff for 'normal' quake maps

void() item_armor1 = {item_armor_green();};
void() item_armor2 = {item_armor_yellow();};
void() item_armorInv = {item_armor_red();};
// pentagram replaced by 'glow armor', have to adjust position
//void() item_artifact_invulnerability = {self.origin_z = self.origin_z - 24;item_armor_glow();};


/*
void() weapon_supershotgun = {remove(self);}; //weapon_chainshotgun ();};
void() weapon_nailgun = {remove(self);}; //weapon_chaingun ();};
void() weapon_supernailgun = {remove(self);}; //weapon_turbochaingun ();};
void() weapon_grenadelauncher = {remove(self);}; //weapon_proxmine ();};
void() weapon_rocketlauncher = {remove(self);}; //weapon_rocket ();};
void() weapon_lightning = {remove(self);}; //weapon_plasma ();};
*/

// reenabled weapon pickups
//void() weapon_supershotgun = {weapon_supershotgun();};
//void() weapon_nailgun = {weapon_machinegun();};
//void() weapon_supernailgun = {weapon_chaingun();};
//void() weapon_grenadelauncher = {weapon_proximitygrenade();};
//void() weapon_rocketlauncher = {weapon_rocket();};
//void() weapon_lightning = {weapon_rifle();};

/*QUAKED item_weapon (0 .5 .8) (0 0 0) (32 32 32) shotgun rocket spikes big
DO NOT USE THIS!!!! IT WILL BE REMOVED!
*/

// Lord Havoc note: I would have removed this function,
// but while playing e2m2 and other maps I found it was used :(
// at least I cleaned up and shrunk the thing...

float WEAPON_SHOTGUN = 1;
float WEAPON_ROCKET = 2;
float WEAPON_SPIKES = 4;
float WEAPON_BIG = 8;
void() item_weapon =
{
	self.weapon = self.spawnflags;
	self.spawnflags = self.weapon - (self.weapon & (WEAPON_SHOTGUN | WEAPON_ROCKET | WEAPON_SPIKES | WEAPON_BIG));
	if (self.weapon & WEAPON_BIG    ) self.spawnflags = self.spawnflags | WEAPON_BIG2;
	if (self.weapon & WEAPON_SHOTGUN) item_shells();
	else if (self.weapon & WEAPON_SPIKES ) item_spikes();
	else if (self.weapon & WEAPON_ROCKET ) item_rockets();
};

void() havoc_waypoint = {remove(self);};
