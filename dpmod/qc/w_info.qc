
// called by worldspawn
void() W_Precache =
{
	explosionfx_precache();
	fire_precache();
	lightning_precache();
	common_precache();

	//precache_model ("progs/lsight.mdl");
};

float(string wname, float request) setweapon =
{
	local string s;
	local entity it;
	if (self.health < 1)
		return FALSE;
	it = Inventory_ItemByName(self, wname);
	if (it == world || it.count == 0 || !it.it_setupweapon)
		return FALSE;
	return it.it_setupweapon(request);
};

string(float dangerous) W_BestWeapon =
{
	local string wname;
	wname = "thunderbolt";if(setweapon(wname, WR_SELECTABLE)) return wname;
	wname = "plasmarifle";if(setweapon(wname, WR_SELECTABLE)) return wname;
	if (dangerous)
	{
		wname = "rocketlauncher";if(setweapon(wname, WR_SELECTABLE)) return wname;
		wname = "grenadelauncher";if(setweapon(wname, WR_SELECTABLE)) return wname;
	}
	wname = "supernailgun";if(setweapon(wname, WR_SELECTABLE)) return wname;
	wname = "supershotgun";if(setweapon(wname, WR_SELECTABLE)) return wname;
	wname = "nailgun";if(setweapon(wname, WR_SELECTABLE)) return wname;
	wname = "shotgun";if(setweapon(wname, WR_SELECTABLE)) return wname;
	wname = "pistol";if(setweapon(wname, WR_SELECTABLE)) return wname;
	return "";
};

string(entity targ) W_BestWeaponForTarget =
{
	local float bestrating, rating, bit;
	local string s, best;
	best = "";
	bestrating = 0;
	weaponrange = vlen(targ.origin - self.origin);
	bit = 1;
	s = NumberToWeapon(bit);
	while(s != "")
	{
		rating = setweapon(s, WR_WEAPONRATING);
		if (rating > bestrating)
		{
			best = s;
			bestrating = rating;
		}
		bit = bit + bit;
		s = NumberToWeapon(bit);
	}
	return best;
};

float(float minrange, float preferredrange, float baserating) genericweaponrating =
{
	if (weaponrange < minrange)
		return 0;
	if (weaponrange <= preferredrange)
		return baserating;
	return baserating * preferredrange * preferredrange / (weaponrange * weaponrange);
};

/*
============
W_ChangeWeapon

============
*/
void() W_ChangeWeapon =
{
	local float n, bit;
	local string s;
	if (self.health < 1)
		return;
	if (self.impulse >= 200)
		self.impulse = self.impulse - 200;
	n = 1;
	bit = 1;
	while (n < self.impulse)
	{
		n = n + 1;
		bit = bit * 2;
	}
	s = NumberToWeapon(bit);
	if (s != "")
		setweapon(s, WR_SWITCH);
	self.impulse = 0;
};

/*
============
CheatCommand
============
*/
void() CheatCommand =
{
	local float bit;
	local string s;
	if (deathmatch) // || coop)
		return;
	if (self.health < 1)
		return;

	Inventory_SetQuantity(self, "shells", AMMOMAX_SHELLS);
	Inventory_SetQuantity(self, "nails", AMMOMAX_NAILS);
	Inventory_SetQuantity(self, "rockets", AMMOMAX_ROCKETS);
	Inventory_SetQuantity(self, "cells", AMMOMAX_SHELLS);
	/*
	self.items = self.items
	 | IT_WEAPON1
	 | IT_WEAPON2
	 | IT_WEAPON3
	 | IT_WEAPON4
	 | IT_WEAPON5
	 | IT_WEAPON6
	 | IT_WEAPON7
	 | IT_WEAPON8
	 | IT_WEAPON9
	 | IT_WEAPON10
	// | IT_KEY1 | IT_KEY2
	;
	*/
	bit = 1;
	s = NumberToWeapon(bit);
	while (s != "")
	{
		Inventory_SetQuantity(self, s, 9999);
		bit = bit * 2;
		s = NumberToWeapon(bit);
	}

	self.impulse = 0;
};

/*
============
CycleWeaponCommand

Go to the next weapon with ammo
============
*/
void() CycleWeaponCommand =
{
	local float looped, w;
	local string s;
	if (self.health < 1)
		return;
	looped = FALSE;
	w = WeaponToNumber(self.switchweapon);
	while(1)
	{
		w = w * 2;
		s = NumberToWeapon(w);
		if (s == "")
		{
			if (looped)
				return;
			looped = TRUE;
			w = 1;
			s = NumberToWeapon(w);
		}
		if (setweapon(s, WR_SELECTABLE))
		{
			self.switchweapon = s;
			return;
		}
	}
};

/*
============
CycleWeaponReverseCommand

Go to the prev weapon with ammo
============
*/
void() CycleWeaponReverseCommand =
{
	local float looped, w;
	local string s;
	if (self.health < 1)
		return;
	looped = FALSE;
	w = WeaponToNumber(self.switchweapon);
	while(1)
	{
		w = w * 0.5;
		s = NumberToWeapon(w);
		if (s == "")
		{
			if (looped)
				return;
			looped = TRUE;
			w = 1;
			while (NumberToWeapon(w) != "")
				w = w * 2;
			w = w * 0.5;
			s = NumberToWeapon(w);
		}
		if (setweapon(s, WR_SELECTABLE))
		{
			self.switchweapon = s;
			return;
		}
	}
};
