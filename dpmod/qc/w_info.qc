
// called by worldspawn
void() W_Precache =
{
	explosionfx_precache();
	fire_precache();
	lightning_precache();
	common_precache();

	/*
	if (deathmatch == DM_FORTRESS)
	{
		weapon11_precache();
		weapon12_precache();
		weapon13_precache();
		weapon14_precache();
		weapon15_precache();
		weapon16_precache();
		weapon17_precache();
		weapon18_precache();
		weapon19_precache();
		weapon20_precache();
	}
	else
	{
	*/
		weapon1_precache();
		weapon2_precache();
		weapon3_precache();
		weapon4_precache();
		weapon5_precache();
		weapon6_precache();
		weapon7_precache();
		weapon8_precache();
		weapon9_precache();
		weapon10_precache();
	//}

	//precache_model ("progs/lsight.mdl");
};

float(float w, float request) setweapon =
{
	if (self.health < 1)
		return FALSE;
	if (w == 0)
		w = IT_WEAPON1;
	if ((self.items & w) == 0)
		return FALSE;
	/*
	if (deathmatch == DM_FORTRESS)
	{
		     if (w == IT_WEAPON1 ) return setweapon11(request);
		else if (w == IT_WEAPON2 ) return setweapon12(request);
		else if (w == IT_WEAPON3 ) return setweapon13(request);
		else if (w == IT_WEAPON4 ) return setweapon14(request);
		else if (w == IT_WEAPON5 ) return setweapon15(request);
		else if (w == IT_WEAPON6 ) return setweapon16(request);
		else if (w == IT_WEAPON7 ) return setweapon17(request);
		else if (w == IT_WEAPON8 ) return setweapon18(request);
		else if (w == IT_WEAPON9 ) return setweapon19(request);
		else if (w == IT_WEAPON10) return setweapon20(request);
		else return setweapon1(request); // should never happen
	}
	else
	{
	*/
			 if (w == IT_WEAPON1 ) return setweapon1 (request);
		else if (w == IT_WEAPON2 ) return setweapon2 (request);
		else if (w == IT_WEAPON3 ) return setweapon3 (request);
		else if (w == IT_WEAPON4 ) return setweapon4 (request);
		else if (w == IT_WEAPON5 ) return setweapon5 (request);
		else if (w == IT_WEAPON6 ) return setweapon6 (request);
		else if (w == IT_WEAPON7 ) return setweapon7 (request);
		else if (w == IT_WEAPON8 ) return setweapon8 (request);
		else if (w == IT_WEAPON9 ) return setweapon9 (request);
		else if (w == IT_WEAPON10) return setweapon10(request);
		else return setweapon1(request); // should never happen
	//}
};

float(float dangerous) W_BestWeapon =
{
	local float w;
	w = IT_WEAPON8;if(setweapon(w, WR_SELECTABLE)) return w;
	w = IT_WEAPON10;if(setweapon(w, WR_SELECTABLE)) return w;
	if (dangerous)
	{
		w = IT_WEAPON7;if(setweapon(w, WR_SELECTABLE)) return w;
		w = IT_WEAPON6;if(setweapon(w, WR_SELECTABLE)) return w;
	}
	w = IT_WEAPON5;if(setweapon(w, WR_SELECTABLE)) return w;
	w = IT_WEAPON4;if(setweapon(w, WR_SELECTABLE)) return w;
	w = IT_WEAPON3;if(setweapon(w, WR_SELECTABLE)) return w;
	w = IT_WEAPON2;if(setweapon(w, WR_SELECTABLE)) return w;
	return IT_WEAPON1;
};

float(entity targ) W_BestWeaponForTarget =
{
	local float best, bestrating, w, rating, c;
	best = 0;
	bestrating = 0;
	weaponrange = vlen(targ.origin - self.origin);
	w = IT_WEAPON1 ;rating = setweapon(w, WR_WEAPONRATING);if (rating > bestrating) {best = w;bestrating = rating;}
	w = IT_WEAPON2 ;rating = setweapon(w, WR_WEAPONRATING);if (rating > bestrating) {best = w;bestrating = rating;}
	w = IT_WEAPON3 ;rating = setweapon(w, WR_WEAPONRATING);if (rating > bestrating) {best = w;bestrating = rating;}
	w = IT_WEAPON4 ;rating = setweapon(w, WR_WEAPONRATING);if (rating > bestrating) {best = w;bestrating = rating;}
	w = IT_WEAPON5 ;rating = setweapon(w, WR_WEAPONRATING);if (rating > bestrating) {best = w;bestrating = rating;}
	w = IT_WEAPON6 ;rating = setweapon(w, WR_WEAPONRATING);if (rating > bestrating) {best = w;bestrating = rating;}
	w = IT_WEAPON7 ;rating = setweapon(w, WR_WEAPONRATING);if (rating > bestrating) {best = w;bestrating = rating;}
	w = IT_WEAPON8 ;rating = setweapon(w, WR_WEAPONRATING);if (rating > bestrating) {best = w;bestrating = rating;}
	w = IT_WEAPON9 ;rating = setweapon(w, WR_WEAPONRATING);if (rating > bestrating) {best = w;bestrating = rating;}
	w = IT_WEAPON10;rating = setweapon(w, WR_WEAPONRATING);if (rating > bestrating) {best = w;bestrating = rating;}
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
float(float w) RankForWeapon =
{
	if (w == IT_WEAPON10) return 1;
	if (w == IT_WEAPON8) return 2;
	if (w == IT_WEAPON7) return 3;
	if (w == IT_WEAPON6) return 4;
	if (w == IT_WEAPON5) return 5;
	if (w == IT_WEAPON4) return 6;
	if (w == IT_WEAPON3) return 7;
	if (w == IT_WEAPON2) return 8;
	if (w == IT_WEAPON9) return 9;
	if (w == IT_WEAPON1) return 10;
	// this should never happen, as it catches all valid weapons in the code above
	return 100;
};
*/

/*
=============
Deathmatch_Weapon

Deathmatch weapon change rules for picking up a weapon

=============
*/
/*
void(float old, float new) Deathmatch_Weapon =
{
	local float or, nr;

	if (self.health < 1)
		return;
	// change self.weapon if desired
	or = RankForWeapon (self.weapon);
	nr = RankForWeapon (new);
	if (nr < or)
		self.switchweapon = new;
};
*/

/*
============
W_ChangeWeapon

============
*/
void() W_ChangeWeapon =
{
	local   float   fl;
	if (self.health < 1)
		return;
	if (self.impulse >= 200)
		self.impulse = self.impulse - 200;
	if (self.impulse == 1) {fl = IT_WEAPON1;}
	if (self.impulse == 2) {fl = IT_WEAPON2;}
	if (self.impulse == 3) {fl = IT_WEAPON3;}
	if (self.impulse == 4) {fl = IT_WEAPON4;}
	if (self.impulse == 5) {fl = IT_WEAPON5;}
	if (self.impulse == 6) {fl = IT_WEAPON6;}
	if (self.impulse == 7) {fl = IT_WEAPON7;}
	if (self.impulse == 8) {fl = IT_WEAPON8;}
	if (self.impulse == 9) {fl = IT_WEAPON9;}
	if (self.impulse == 10) {fl = IT_WEAPON10;}
	self.impulse = 0;
	/*
	if (!(self.items & fl))
	{
		// don't have the weapon or the ammo
		if (self.flags & FL_CLIENT)
			sprint(self, "That weapon does not appear to be in your posession\n");
		return;
	}
	if (!setweapon(fl, TRUE, FALSE))
	{
		// don't have the ammo
		if (self.flags & FL_CLIENT)
			sprint (self, "Insufficient ammunition for that weapon\n");
		return;
	}
	*/
	if (setweapon(fl, WR_SELECTABLE))
		self.switchweapon = fl;
};

/*
============
CheatCommand
============
*/
void() CheatCommand =
{
	if (deathmatch) // || coop)
		return;
	if (self.health < 1)
		return;

	self.ammo_shells  = 999;
	self.ammo_nails   = 999;
	self.ammo_rockets = 999;
	self.ammo_cells   = 999;
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
	bound_ammo(self);

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
	local float w;
	self.impulse = 0;
	w = self.switchweapon;
	if (w == 0) w = IT_WEAPON1;
	if (self.health < 1)
		return;
	while (1)
	{
		     if (w == IT_WEAPON10) w = IT_WEAPON1;
		//     if (w == IT_WEAPON9) w = IT_WEAPON1;
		else if (w == IT_WEAPON1) w = IT_WEAPON2;
		else if (w == IT_WEAPON2) w = IT_WEAPON3;
		else if (w == IT_WEAPON3) w = IT_WEAPON4;
		else if (w == IT_WEAPON4) w = IT_WEAPON5;
		else if (w == IT_WEAPON5) w = IT_WEAPON6;
		else if (w == IT_WEAPON6) w = IT_WEAPON7;
		else if (w == IT_WEAPON7) w = IT_WEAPON8;
		else if (w == IT_WEAPON8) w = IT_WEAPON9;
		else if (w == IT_WEAPON9) w = IT_WEAPON10;
		if (setweapon(w, WR_SELECTABLE))
		{
			self.switchweapon = w;
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
	local float w;
	self.impulse = 0;
	w = self.switchweapon;
	if (w == 0) w = IT_WEAPON1;
	if (self.health < 1)
		return;
	while (1)
	{
		     if (w == IT_WEAPON10) w = IT_WEAPON9;
		else if (w == IT_WEAPON9) w = IT_WEAPON8;
		else if (w == IT_WEAPON8) w = IT_WEAPON7;
		else if (w == IT_WEAPON7) w = IT_WEAPON6;
		else if (w == IT_WEAPON6) w = IT_WEAPON5;
		else if (w == IT_WEAPON5) w = IT_WEAPON4;
		else if (w == IT_WEAPON4) w = IT_WEAPON3;
		else if (w == IT_WEAPON3) w = IT_WEAPON2;
		else if (w == IT_WEAPON2) w = IT_WEAPON1;
		else if (w == IT_WEAPON1) w = IT_WEAPON10;
		//else if (w == IT_WEAPON1) w = IT_WEAPON9;
		if (setweapon(w, WR_SELECTABLE))
		{
			self.switchweapon = w;
			return;
		}
	}
};
