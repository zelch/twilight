
void(entity targ, entity attacker, string dmsg, float dtype) Obituary_Grenade =
{
	if (dtype == DTYPE_PLAYER)
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
	else if (dtype == DTYPE_SUICIDE)
	{
		deathstring1 = targ.netname;
		if (targ.bodyhealth < 1) // gib
			deathstring2 = " ate a pineapple";
		else
			deathstring2 = " held onto the grenade";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

/*
void() W_GrenadeFireImpact =
{
	local float a;
	stopfiring = TRUE;
	self.wfiretime = time;
	a = self.ammo_rockets;
	if (a > 1)
		a = 1;
	self.wfiretime = time;
	self.currentammo = self.ammo_rockets = self.ammo_rockets - a;
	w_muzzleflash(shotorg, 3);
	//LaunchGrenade(shotorg, shotdir * 1000 + v_up * 200 + self.velocity, self, (50 + 100 * a) * damagescale, 100 + 100 * a, GRENADE_IMPACT | GRENADE_IMMUNETODAMAGE, 25, "GRENADE", Obituary_Grenade);
	LaunchGrenade(shotorg, shotdir * 1000 + v_up * 200, self, (50 + 100 * a) * damagescale, 100 + 100 * a, GRENADE_IMPACT | GRENADE_IMMUNETODAMAGE, 25, "GRENADE", Obituary_Grenade);
};

void() W_GrenadeFireProximity =
{
	local float a;
	stopfiring = TRUE;
	a = self.ammo_rockets;
	if (a > 1)
		a = 1;
	self.wfiretime = time;
	self.currentammo = self.ammo_rockets = self.ammo_rockets - a;
	w_muzzleflash(shotorg, 3);
	LaunchGrenade(shotorg, shotdir * 1000 + v_up * 200, self, 100 * damagescale, 150, GRENADE_PROXIMITY, 5, "GRENADE", Obituary_Grenade);
};
*/

void() W_GrenadeFireSticky =
{
	stopfiring = TRUE;
	self.wfiretime = time;
	self.currentammo = self.ammo_rockets = self.ammo_rockets - 1;
	w_muzzleflash(shotorg, 3);
	LaunchMine(shotorg, shotdir * 3000 + v_up * 0, self, 150 * damagescale, 200, 50 * damagescale, 20 * damagescale, MINE_DETONATEONBUTTON3, 60, "STICKYGRENADE", Obituary_Grenade);
};

.float activemines;
void() w_grenadedrop1;
void() w_grenadedrop2;
void() w_grenaderaise1;
void() w_grenaderaise2;
void() w_grenade =
{
	local float c;
	if (widle(w_grenadedrop1))
		return;

	if (self.button0)
	{
		if (self.activemines >= 20)
		{
			if (time > self.attack_finished)
			{
				self.attack_finished = time + 0.5;
				sprint(self, "only 20 remote explosives allowed, you must detonate some before placing more\n");
			}
		}
		else if (self.ammo_rockets >= 1)
			W_GenericSlowFireCode("weapons/grenade.wav", 0.5, W_GrenadeFireSticky);
	}
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

