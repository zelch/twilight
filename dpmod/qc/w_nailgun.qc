
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
	FireBullets(self, self, 4, 1, 15 * damagescale, 15 * damagescale, 0, 0, shotdir * 7000, 0.025, "NAILGUN", DT_NAIL, Obituary_Nailgun);
	shotorg = v;

	if (self.ammo_nails < 1) {stopfiring = TRUE;return;}
};

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
	self.wfiretime = time;
	self.currentammo = self.ammo_rockets = self.ammo_rockets - 1;
	w_muzzleflash(shotorg, 3);
	//LaunchGrenade(shotorg, shotdir * 1000 + v_up * 200, self, 80 * damagescale, 300, GRENADE_IMPACT, 2.5, "NAILGUNGRENADE", Obituary_NailgunGrenade);
	LaunchMine(shotorg, shotdir * 1000 + v_up * 200, self, 200 * damagescale, 70, 20 * damagescale, 10 * damagescale, MINE_LASERTRIP, 60, "LASERTRIPMINE", Obituary_NailgunMine);
};


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
			W_GenericRapidFireCode("weapons/rocket1i.wav", 0.1, W_NailgunFireCode);
	}
	else
	{
		self.notfiring = TRUE;
		if (self.button3)
		if (self.ammo_rockets >= 1)
			W_GenericSlowFireCode("weapons/grenade.wav", 0.8, W_NailgunGrenadeFireCode);
	}

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

