
void(entity targ, entity attacker, string dmsg, float dtype) Obituary_Nailgun =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = "'s coffin was nailed by ";
		deathstring3 = attacker.netname;
		deathstring4 = "";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

void() W_NailgunFireCode =
{
	local vector v, casingdir;
	if (self.ammo_nails < 1) {stopfiring = TRUE;return;}
	self.wfiretime = time;
	self.currentammo = self.ammo_nails = self.ammo_nails - 1;
	self.wframe = self.wframe + 1;
	if (self.wframe >= 9)
		self.wframe = 1;
	self.wfiretime = time;
	self.punchangle_x = -2;

	v = shotorg;
	if (self.wframe & 1)
	{
		shotorg = shotorg + v_right * 2;
		//ejectcasing(shotorg, shotdir, v_right *  200 + v_up * 50, 50, 0);
	}
	else
	{
		shotorg = shotorg - v_right * 2;
		//ejectcasing(shotorg, shotdir, v_right * -200 + v_up * 50, 50, 0);
	}

	w_muzzleflash(shotorg, 1);
	bullet_type = 4;
	FireBullets(1, 15, 15, shotdir * 7000, 0.025, "NAILGUN", DT_NAIL, Obituary_Nailgun);
	shotorg = v;

	if (self.ammo_nails < 1) {stopfiring = TRUE;return;}
};

/*
void(entity targ, entity attacker, string dmsg, float dtype) Obituary_NailgunGrenade =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring3 = attacker.netname;
		if (targ.bodyhealth < 1) // gib
		{
			deathstring2 = " ate one of ";
			deathstring4 = "'s porcupines";
		}
		else
		{
			deathstring2 = " was torn up by ";
			deathstring4 = "'s nail grenade";
		}
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};
*/

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_NailgunMine =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring3 = attacker.netname;
		if (targ.bodyhealth < 1) // gib
		{
			deathstring2 = " was shredded by ";
			deathstring4 = "'s porcupine";
		}
		else
		{
			deathstring2 = " was torn up by ";
			deathstring4 = "'s porcupine";
		}
	}
	else if (dtype == DTYPE_SUICIDE)
	{
		deathstring1 = targ.netname;
		if (targ.bodyhealth < 1) // gib
			deathstring2 = " was shredded by his own porcupine";
		else
			deathstring2 = " was torn up by his own porcupine";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

void() W_NailgunGrenadeFireCode =
{
	stopfiring = TRUE;
	self.wfiretime = time;

	self.currentammo = self.ammo_rockets = self.ammo_rockets - 1;
	w_muzzleflash(shotorg, 3);
	//LaunchGrenade(shotorg, shotdir * 1000 + v_up * 200, self, 80, 300, GRENADE_IMPACT, 2.5, "NAILGUNGRENADE", Obituary_NailgunGrenade);
	LaunchMine(shotorg, shotdir * 1000 + v_up * 200, self, 200, 70, MINE_LASERTRIP | MINE_DETONATEONBUTTON3, 60, "LASERTRIPMINE", Obituary_NailgunMine);
};

/*
void(entity targ, entity attacker, string dmsg, float dtype) Obituary_ProximityMine =
{
	Obituary_Fallback(targ, attacker, dmsg, dtype);
};

void() W_NailgunMineFireCode =
{
	stopfiring = TRUE;
	self.wfiretime = time;

	self.currentammo = self.ammo_rockets = self.ammo_rockets - 1;
	w_muzzleflash(shotorg, 3);
	//LaunchMine(shotorg, shotdir * 1000 + v_up * 200, self, 300, 60, MINE_LASERTRIP | MINE_DETONATEONBUTTON3, 60, "LASERTRIPMINE", Obituary_LaserTripMine);
	LaunchMine(shotorg, shotdir * 1000 + v_up * 200, self, 100, 120, MINE_PROXIMITY | MINE_TENWARHEAD | MINE_DETONATEONBUTTON3, 60, "PROXIMITYMIRV", Obituary_ProximityMine);
};
*/

/*
void(entity targ, entity attacker, string dmsg, float dtype) Obituary_NailgunRocket =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring3 = attacker.netname;
		if (targ.bodyhealth < 1) // gib
		{
			deathstring2 = " was torn asunder by ";
			deathstring4 = "'s rocket";
		}
		else
		{
			deathstring2 = "'s world was rocked by ";
			deathstring4 = "";
		}
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
}

void() W_NailgunRocketFireCode =
{
	if (self.ammo_rockets < 0.2) {stopfiring = TRUE;return;}
	fightdone = time + 1; // delay stuff until fighting is over
	self.wfiretime = time;
	self.currentammo = self.ammo_rockets = self.ammo_rockets - 0.2;
	w_muzzleflash(shotorg, 1);
	LaunchMissile(shotorg, shotdir, self, 30, 60, "NAILGUNROCKET", Obituary_NailgunRocket);
	if (self.ammo_rockets < 0.2) {stopfiring = TRUE;return;}
};
*/


void() w_nailgundrop1;
void() w_nailgundrop2;
void() w_nailgunraise1;
void() w_nailgunraise2;
void() w_nailgun =
{
	if (widle(w_nailgundrop1))
		return;

	if (self.button0)
	{
		if (self.ammo_nails >= 1)
			W_GenericFireCode("weapons/rocket1i.wav", 0.1, W_NailgunFireCode);
	}
	/*
	else if (self.button3)
	{
		if (self.ammo_rockets >= 0.2)
			W_GenericFireCode("weapons/sgun1.wav", 0.2, W_NailgunRocketFireCode);
	}
	*/
	/*
	else if (self.button3)
	{
		if (self.ammo_rockets >= 1)
			W_GenericFireCode("weapons/grenade.wav", 0.5, W_NailgunMineFireCode);
	}
	*/
	else if (self.button3)
	{
		if (self.ammo_rockets >= 1)
			W_GenericFireCode("weapons/grenade.wav", 0.8, W_NailgunGrenadeFireCode);
	}
	else
		self.notfiring = TRUE;

	if ((time - self.wfiretime) < 0.15)
		self.weaponframe = self.wframe;
	else
		self.weaponframe = 0;

	havoc_nailanimupdate(self.weaponframe);
};

void() weapon4_precache =
{
	precache_model("progs/v_dpnail.mdl");
	precache_model("progs/s_spike.mdl");
	precache_model("progs/s_explod.spr");
	precache_sound("weapons/rocket1i.wav");
	precache_sound("weapons/spike2.wav");
};

void() w_nailgunraise1 = {wraise(10, w_nailgunraise2, 0.1);};
void() w_nailgunraise2 = {wraise( 9, w_nailgun, 0.1);};

void() w_nailgundrop1 = {wdrop( 9, w_nailgundrop2, 0.1);};
void() w_nailgundrop2 = {wdropped(10, 0.1);};

float() w_nailgunrating = {return genericweaponrating(0, 1200, 150);};
void() w_nailgunsetup = {wset(IT_WEAPON4, IT_NAILS, self.ammo_nails, VWEP_NAILGUN, "progs/v_dpnail.mdl");};
float(float request) setweapon4 = {return weapongeneric(IT_WEAPON4, self.ammo_nails >= 1 || self.ammo_rockets >= 1, request, w_nailgunsetup, w_nailgun, w_nailgunraise1, w_directaim, w_nailgunrating, "Nailgun");};

