
.float shotgunshells;

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_DBShotgunSingle =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " was blown away by ";
		deathstring3 = attacker.netname;
		deathstring4 = "";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_DBShotgunDouble =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " took both barrels from ";
		deathstring3 = attacker.netname;
		deathstring4 = "";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

void(void(entity t, entity a, string m, float dtyp) obitfunc) W_DBShotgunFireShell =
{
	local vector v;

	self.wfiretime = time;
	self.currentammo = self.ammo_shells = self.ammo_shells - 1;
	self.wload = self.wload - 1;
	v = shotorg;
	if (!(self.shotgunshells & 1))
	{
		self.shotgunshells = self.shotgunshells + 1;
		shotorg = shotorg - v_right;
	}
	else if (!(self.shotgunshells & 2))
	{
		self.shotgunshells = self.shotgunshells + 2;
		shotorg = shotorg + v_right;
	}
	else
		return; // never happens
	w_muzzleflash(v, 4);
	//bullet_type = 1;
	//FireBullets(5, 9 * damagescale, 9 * damagescale, shotdir * 4000, 0.1, "SUPERSHOTGUN", DT_SHOTGUN, obitfunc);
	//bullet_type = 0;
	//FireBullets(10, 9 * damagescale, 9 * damagescale, shotdir * 4000, 0.1, "SUPERSHOTGUN", DT_SHOTGUN, obitfunc);
	bullet_type = 1;
	FireBullets(5, 4 * damagescale, 4 * damagescale, shotdir * 4000, 0.1, "SUPERSHOTGUN", DT_SHOTGUN, obitfunc);
	bullet_type = 0;
	FireBullets(10, 4 * damagescale, 4 * damagescale, shotdir * 4000, 0.1, "SUPERSHOTGUN", DT_SHOTGUN, obitfunc);
	shotorg = v;
};

void() W_DBShotgunSingleFireCode =
{
	W_DBShotgunFireShell(Obituary_DBShotgunSingle);
};

void() W_DBShotgunDoubleFireCode =
{
	while (self.wload >= 1)
		W_DBShotgunFireShell(Obituary_DBShotgunDouble);
};

/*
void(entity targ, entity attacker, string dmsg, float dtype) Obituary_DBShotgunMine =
{
	Obituary_Fallback(targ, attacker, dmsg, dtype);
};

void() W_DBShotgunMineFireCode =
{
	self.wfiretime = time;
	self.currentammo = self.ammo_rockets = self.ammo_rockets - 1;
	w_muzzleflash(shotorg, 3);
	LaunchMine(shotorg, shotdir * 1000 + v_up * 200, self, 200 * damagescale, 250, MINE_PROXIMITY | MINE_DETONATEONBUTTON3, 2.5, "DBSHOTGUNMINE", Obituary_DBShotgunMine);
};
*/

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_DBShotgunGrenade =
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
			deathstring2 = " was torn up by ";
			deathstring4 = "'s grenades";
		}
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

void() W_DBShotgunGrenadeFireCode =
{
	self.wfiretime = time;
	self.currentammo = self.ammo_rockets = self.ammo_rockets - 1;
	w_muzzleflash(shotorg, 3);
	//LaunchGrenade(shotorg, shotdir * 1000 + v_up * 200, self, 200 * damagescale, 250, GRENADE_IMPACT, 2.5, "DBSHOTGUNGRENADE", Obituary_DBShotgunGrenade);
	LaunchGrenade(shotorg, shotdir * 1000 + v_up * 200, self, 100 * damagescale, 250, GRENADE_IMPACT, 2.5, "DBSHOTGUNGRENADE", Obituary_DBShotgunGrenade);
};

void() w_dbshotgundrop1;
void() w_dbshotgundrop2;
void() w_dbshotgunraise1;
void() w_dbshotgunraise2;
void() w_dbshotgun =
{
	local vector v;

	if (self.wload > self.ammo_shells)
		self.wload = self.ammo_shells;

	if (self.button0)
	{
		if (self.wload > 0)
			W_GenericSlowFireCode("weapons/shotgn2.wav", 0.2, W_DBShotgunDoubleFireCode);
			//W_GenericSlowFireCode("weapons/shotgn2.wav", 0.2, W_DBShotgunSingleFireCode);
	}
	else if (self.button3)
	{
		/*
		if (self.wload > 0)
			W_GenericSlowFireCode("weapons/shotgn2.wav", 0.2, W_DBShotgunDoubleFireCode);
		*/
		if (self.ammo_rockets > 0)
			W_GenericSlowFireCode("weapons/grenade.wav", 0.8, W_DBShotgunGrenadeFireCode);
	}
	else
		self.notfiring = TRUE;

	if (self.wload < 1 && time > self.attack_finished)
	{
		if (self.shotgunshells)
		{
			self.attack_finished = time + 0.3;
			sound(self, CHAN_AUTO, "weapons/bsgload.wav", 1, ATTN_STATIC);
			v = shotorg + v_forward * -8;
			if (self.shotgunshells & 1) ejectcasing (v + v_right *  1, shotdir, '0 0 0', 30, 1);
			if (self.shotgunshells & 2) ejectcasing (v + v_right * -1, shotdir, '0 0 0', 30, 1);
			self.shotgunshells = 0;
		}
		else if (self.ammo_shells >= 1)
		{
			self.wload = 2;
			self.attack_finished = time + 0.2;
			sound(self, CHAN_AUTO, "weapons/bsgload.wav", 1, ATTN_STATIC);
		}
		else if (widle(w_dbshotgundrop1))
			return;
	}
	else if (widle(w_dbshotgundrop1))
		return;

	if (self.wfiretime)
	{
		self.weaponframe = floor((time - self.wfiretime) * 10 + 1);
		if (self.weaponframe >= 8)
			self.weaponframe = self.wfiretime = 0;
	}
	else
		self.weaponframe = 0;

	if (self.weaponframe < 7)
		havoc_shotanimupdate(self.weaponframe);
	else // super shotgun has one more recoil frame than the player model
		havoc_shotanimupdate(0);
};

void() weapon3_precache =
{
	precache_model("progs/v_dpshot2.mdl");
	precache_model("progs/grenade.mdl");
	precache_sound("weapons/shotgn2.wav");
	precache_sound("weapons/grenade.wav");
	precache_sound("weapons/bsgnoammo.wav");
	precache_sound("weapons/bsgload.wav");
};

float() w_dbshotgunrating = {return genericweaponrating(0, 250, 175);};
void() w_dbshotgunsetup = {wset(IT_WEAPON3, IT_SHELLS, self.ammo_shells, VWEP_SUPER_SHOTGUN, "progs/v_dpshot2.mdl");};
float(float request) setweapon3 = {return weapongeneric(IT_WEAPON3, self.ammo_shells >= 1, request, w_dbshotgunsetup, w_dbshotgun, w_dbshotgunraise1, w_directaim, w_dbshotgunrating, "Double Barrel Shotgun");};

void() w_dbshotgunraise1 = {self.wload = 2;self.shotgunshells = 0;wraise(9, w_dbshotgunraise2, 0.1);};
void() w_dbshotgunraise2 = {wraise(8, w_dbshotgun, 0.1);};

void() w_dbshotgundrop1 = {wdrop(8, w_dbshotgundrop2, 0.1);};
void() w_dbshotgundrop2 = {wdropped(9, 0.1);};
