
void(entity targ, entity attacker, string dmsg, float dtype) Obituary_Grenade =
{
	if (dtype == DTYPE_PLAYER && dmsg == "GRENADE")
	{
		deathstring1 = targ.netname;
		deathstring3 = attacker.netname;
		if (targ.bodyhealth < 1) // gib
		{
			deathstring2 = " ate one of ";
			deathstring4 = "'s pineapples";
		}
		else
		{
			deathstring2 = " was blown away by ";
			deathstring4 = "'s grenade";
		}
	}
	else if (dtype == DTYPE_SUICIDE && dmsg == "GRENADE")
	{
		deathstring1 = targ.netname;
		if (targ.bodyhealth < 1) // gib
			deathstring2 = " ate a pineapple";
		else
			deathstring2 = " held onto the grenade";
	}
	else if (dtype == DTYPE_PLAYER && dmsg == "STICKYGRENADE")
	{
		deathstring1 = targ.netname;
		deathstring3 = attacker.netname;
		if (targ.bodyhealth < 1) // gib
		{
			deathstring2 = " was torn asunder by ";
			deathstring4 = "'s mine";
		}
		else
		{
			deathstring2 = " was a victim of ";
			deathstring4 = "'s mine";
		}
	}
	else if (dtype == DTYPE_SUICIDE && dmsg == "STICKYGRENADE")
	{
		deathstring1 = targ.netname;
		deathstring2 = " pressed the button";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

/*
.float grenademode;

void() W_GrenadeFireImpact =
{
	self.wfiretime = time;
	self.currentammo = self.ammo_rockets = self.ammo_rockets - 1;
	w_muzzleflash(shotorg, 3);
	//LaunchGrenade(shotorg, shotdir * 1000 + v_up * 200 + self.velocity, self, 150 * damagescale, 200, GRENADE_IMPACT | GRENADE_IMMUNETODAMAGE, 25, "GRENADE", Obituary_Grenade);
	LaunchGrenade(shotorg, shotdir * 1000 + v_up * 200, self, 150 * damagescale, 120, GRENADE_IMPACT | GRENADE_IMMUNETODAMAGE, 25, "GRENADE", Obituary_Grenade);
};
*/

void() W_GrenadeFirePipebomb =
{
	W_Hostile();
	sound(self, CHAN_WEAPON, "weapons/grenade.wav", 1, ATTN_NORM);
	self.wfiretime = time;
	self.currentammo = self.ammo_rockets = self.ammo_rockets - 1;
	w_muzzleflash(shotorg, 5);
	LaunchGrenade(shotorg, shotdir * 1000 + v_up * 200, self, 150 * damagescale, 120, GRENADE_DETONATABLE | GRENADE_DETONATEONCREATURE, 60, "PIPEBOMB", Obituary_Grenade);
};

/*
void() W_GrenadeFireProximity =
{
	self.wfiretime = time;
	self.currentammo = self.ammo_rockets = self.ammo_rockets - 1;
	w_muzzleflash(shotorg, 3);
	LaunchGrenade(shotorg, shotdir * 1000 + v_up * 200, self, 100 * damagescale, 150, GRENADE_PROXIMITY, 5, "GRENADE", Obituary_Grenade);
};
*/

/*
void() W_GrenadeFireSticky =
{
	self.wfiretime = time;
	self.currentammo = self.ammo_rockets = self.ammo_rockets - 1;
	w_muzzleflash(shotorg, 3);
	LaunchMine(shotorg, shotdir * 1000 + v_up * 200, self, 120 * damagescale, 120, 50 * damagescale, 20 * damagescale, MINE_DETONATABLE, 60, "STICKYGRENADE", Obituary_Grenade);
};
*/

.float activemines;
//.float oldbutton3;
void() w_grenadedrop1;
void() w_grenadedrop2;
void() w_grenaderaise1;
void() w_grenaderaise2;
void() w_grenade =
{
	local float c;
	if (widle(w_grenadedrop1))
		return;

	if (time > self.detonatetimeout)
	if (time > self.attack_finished)
	{
		if (self.button0)
		{
			if (self.activemines < 20)
			{
				if (self.ammo_rockets >= 1)
				{
					if (W_ShotsToFire(0.6))
						W_GrenadeFirePipebomb();
				}
				else
					self.switchweapon = W_BestWeapon(TRUE);
			}
			else
			{
				self.attack_finished = time + 0.3;
				sprint(self, "only 20 remote explosives allowed, you must detonate some before placing more\n");
			}
		}
		if (self.button3)
		if (self.activemines > 0)
		{
			self.attack_finished = time + 0.3;
			sound(self, CHAN_WEAPON, "weapons/bomb/trigger.wav", 1, ATTN_STATIC);
			self.detonatetimeout = time + 0.1;
		}
	}

	/*
	if (time > self.attack_finished)
	{
		if (self.button3)
		{
			if (self.activemines < 20)
			{
				if (self.ammo_rockets >= 1)
					W_GenericSlowFireCode("weapons/grenade.wav", 0.6, W_GrenadeFirePipebomb);
			}
			else
			{
				if (time > self.attack_finished)
				{
					self.attack_finished = time + 0.5;
					sprint(self, "only 20 remote explosives allowed, you must detonate some before placing more\n");
				}
			}
		}
		else if (self.button0)
		{
			if (self.activemines > 0)
			{
				self.attack_finished = time + 0.2;
				sound(self, CHAN_WEAPON, "weapons/bomb/trigger.wav", 1, ATTN_STATIC);
				self.detonatetimeout = time + 0.1;
			}
			else if (self.ammo_rockets >= 1)
				W_GenericSlowFireCode("weapons/grenade.wav", 0.6, W_GrenadeFireImpact);
			else
				self.switchweapon = W_BestWeapon(TRUE);
		}
	}
	*/

	/*
	if (time > self.attack_finished)
	{
		if ((self.button3 && !self.oldbutton3) || (self.activemines < 1 && self.grenademode == 2))
		{
			self.attack_finished = time + 0.2;
			if (self.activemines >= 1)
			{
				sound(self, CHAN_WEAPON, "weapons/bomb/trigger.wav", 1, ATTN_STATIC);
				self.detonatetimeout = time + 0.1;
			}
			else
			{
				sound(self, CHAN_WEAPON, "weapons/bsgload.wav", 1, ATTN_STATIC);
				self.grenademode = self.grenademode + 1;
				if (self.grenademode >= 2)
					self.grenademode = 0;
				if (self.grenademode == 0)
					sprint(self, "mode: impact grenades\n");
				else if (self.grenademode == 1)
					sprint(self, "mode: pipebombs\n");
			}
		}
		else if (self.button0)
		{
			if (self.ammo_rockets >= 1)
			{
				if (self.grenademode == 0)
					W_GenericSlowFireCode("weapons/grenade.wav", 0.6, W_GrenadeFireImpact);
				else if (self.grenademode == 1)
				{
					if (self.activemines < 20)
						W_GenericSlowFireCode("weapons/grenade.wav", 0.6, W_GrenadeFirePipebomb);
					else
					{
						if (time > self.attack_finished)
						{
							self.attack_finished = time + 0.5;
							sprint(self, "only 20 remote explosives allowed, you must detonate some before placing more\n");
						}
					}
				}
			}
			else
				self.switchweapon = W_BestWeapon(TRUE);
		}
	}
	self.oldbutton3 = self.button3;
	*/
	/*
	if (self.button0)
	{
		if (self.ammo_rockets >= 1)
			W_GenericSlowFireCode("weapons/grenade.wav", 0.5, W_GrenadeFireImpact);
	}
	else if (self.button3)
	{
		if (self.ammo_rockets >= 1)
			W_GenericSlowFireCode("weapons/grenade.wav", 0.8, W_GrenadeFireProximity);
	}
	*/

	if (self.wfiretime)
	{
		self.weaponframe = (time - self.wfiretime) * 10 + 1;
		if (self.weaponframe >= 7)
		{
			self.weaponframe = 0;
			self.wfiretime = 0;
		}
	}
	else
		self.weaponframe = 0;
	havoc_rockanimupdate(self.weaponframe);
};

void() weapon6_precache =
{
	precache_model("progs/v_dprock.mdl");
	precache_model("progs/grenade.mdl");
	precache_model("progs/s_explod.spr");
	precache_sound("weapons/grenade.wav");
	precache_sound("weapons/bomb/fire.wav");
	precache_sound("weapons/bomb/trigger.wav");
	precache_sound("weapons/bounce.wav");
};

float() w_grenaderating = {return genericweaponrating(200, 500, 300);};
void() w_grenadesetup = {wset(IT_WEAPON6, IT_ROCKETS, self.ammo_rockets, VWEP_GRENADE_LAUNCHER, "progs/v_dprock.mdl");};
float(float request) setweapon6 = {return weapongeneric(IT_WEAPON6, self.ammo_rockets >= 1 || self.activemines > 0, request, w_grenadesetup, w_grenade, w_grenaderaise1, w_grenadeaim, w_grenaderating, "Grenade Launcher");};

void() w_grenaderaise1 = {wraise(8, w_grenaderaise2, 0.1);};
void() w_grenaderaise2 = {wraise(7, w_grenade, 0.1);};

void() w_grenadedrop1 = {wdrop(7, w_grenadedrop2, 0.1);};
void() w_grenadedrop2 = {wdropped(8, 0.1);};

