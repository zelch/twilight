
void(entity targ, entity attacker, string dmsg, float dtype) Obituary_SuperNailgun =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " was shredded by ";
		deathstring3 = attacker.netname;
		deathstring4 = "";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

void() W_SuperNailgunFireCode =
{
	local vector v;
	self.currentammo = self.ammo_nails = self.ammo_nails - 1;
	self.wframe = self.wframe + 0.5; // 10fps animation
	if (self.wframe >= 9)
		self.wframe = 1;
	self.wfiretime = time;

	v = shotorg;
	shotorg = shotorg + v_up * 2;
	w_muzzleflash(shotorg, 1);
	//ejectcasing(shotorg, shotdir, v_right * 200 + v_up * 50, 50, 0);
	bullet_type = 4;
	FireBullets(1, 15, 15, shotdir * 7000, 0.05, "SUPERNAILGUN", DT_NAIL, Obituary_SuperNailgun);
	shotorg = v;

	if (self.ammo_nails < 1) {stopfiring = TRUE;return;}
};

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_ProximityMine =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring3 = attacker.netname;
		if (targ.bodyhealth < -150) // gib
		{
			deathstring2 = " was turned into a fine red mist by ";
			deathstring4 = "'s mine";
		}
		else if (targ.bodyhealth < 1) // gib
		{
			deathstring2 = " was turned into kibble by ";
			deathstring4 = "'s mine";
		}
		else
		{
			deathstring2 = " was thrown into the afterlife by ";
			deathstring4 = "'s mine";
		}
	}
	else if (dtype == DTYPE_SUICIDE)
	{
		deathstring1 = targ.netname;
		if (targ.bodyhealth < -100) // gib
			deathstring2 = " was turned into a fine red mist by his own mine";
		else if (targ.bodyhealth < 1) // gib
			deathstring2 = " was turned into kibble by his own mine";
		else
			deathstring2 = " was thrown into the afterlife by his own mine";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

void() W_SuperNailgunMineFireCode =
{
	local float a;
	stopfiring = TRUE;
	self.wfiretime = time;

	a = 3;
	if (a > self.ammo_rockets)
		a = self.ammo_rockets;
	self.currentammo = self.ammo_rockets = self.ammo_rockets - a;
	w_muzzleflash(shotorg, 3);
	LaunchMine(shotorg, shotdir * 1000 + v_up * 200, self, a * 100, a * 100 + 50, MINE_PROXIMITY | MINE_DETONATEONBUTTON3, 60, "PROXIMITYMINE", Obituary_ProximityMine);
};

void() w_snailgundrop1;
void() w_snailgundrop2;
void() w_snailgunraise1;
void() w_snailgunraise2;
void() w_snailgun =
{
	if (widle(w_snailgundrop1))
		return;

	if (self.button0)
	{
		if (self.ammo_nails >= 1)
			W_GenericFireCode("weapons/spike2.wav", 0.05, W_SuperNailgunFireCode);
	}
	else if (self.button3)
	{
		if (self.ammo_rockets >= 1)
			W_GenericFireCode("weapons/grenade.wav", 0.5, W_SuperNailgunMineFireCode);
	}
	else
		self.notfiring = TRUE;

	if ((time - self.wfiretime) < 0.15)
		self.weaponframe = self.wframe;
	else
		self.weaponframe = 0;

	havoc_nailanimupdate(self.weaponframe);
};

void() weapon5_precache =
{
	precache_model("progs/v_dpnail2.mdl");
	precache_model("progs/s_spike.mdl");
	precache_sound("weapons/rocket1i.wav");
	precache_sound("weapons/spike2.wav");
};

void() w_snailgunraise1 = {wraise(10, w_snailgunraise2, 0.1);};
void() w_snailgunraise2 = {wraise( 9, w_snailgun      , 0.1);};

void() w_snailgundrop1 = {wdrop( 9, w_snailgundrop2, 0.1);};
void() w_snailgundrop2 = {wdropped(10, 0.1);};

float() w_snailgunrating = {return genericweaponrating(0, 1000, 300);};
void() w_snailgunsetup = {wset(IT_WEAPON5, IT_NAILS, self.ammo_nails, VWEP_SUPER_NAILGUN, "progs/v_dpnail2.mdl");};
float(float request) setweapon5 = {return weapongeneric(IT_WEAPON5, self.ammo_nails >= 1 || self.ammo_rockets >= 1, request, w_snailgunsetup, w_snailgun, w_snailgunraise1, w_directaim, w_snailgunrating, "Super Nailgun");};
