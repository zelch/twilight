
void(entity targ, entity attacker, string dmsg, float dtype) Obituary_DBShotgunSingle =
{
	if (dtype == DTYPE_PLAYER)
	{
		if (dmsg == "SHOTGUNEXPLOSIVESLUG")
		{
			if (targ.bodyhealth < 1)
			{
				deathstring1 = targ.netname;
				deathstring2 = " was blown apart by an explosive slug from ";
				deathstring3 = attacker.netname;
				deathstring4 = "";
			}
			else
			{
				deathstring1 = targ.netname;
				deathstring2 = " met an explosive slug from ";
				deathstring3 = attacker.netname;
				deathstring4 = "";
			}
		}
		else
		{
			deathstring1 = targ.netname;
			deathstring2 = " was blown away by ";
			deathstring3 = attacker.netname;
			deathstring4 = "";
		}
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_DBShotgunDouble =
{
	if (dtype == DTYPE_PLAYER)
	{
		if (dmsg == "SHOTGUNEXPLOSIVESLUG")
		{
			if (targ.bodyhealth < 1)
			{
				deathstring1 = targ.netname;
				deathstring2 = " was blown apart by two explosive slugs from ";
				deathstring3 = attacker.netname;
				deathstring4 = "";
			}
			else
			{
				deathstring1 = targ.netname;
				deathstring2 = " took two explosive slugs from ";
				deathstring3 = attacker.netname;
				deathstring4 = "";
			}
		}
		else
		{
			deathstring1 = targ.netname;
			deathstring2 = " took both barrels from ";
			deathstring3 = attacker.netname;
			deathstring4 = "";
		}
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

//float DBSHOTGUNBUCKSHOT = 80;
float DBSHOTGUNEXPLOSIVESLUG = 50;

.float shotgunmode, shotgunshells;
void(void(entity t, entity a, string m, float dtyp) obitfunc, float spreadboost) W_DBShotgunFireShell =
{
	local vector v;

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
	self.wload = self.wload - 1;
	/*
	if (self.shotgunmode)
		self.currentammo = self.ammo_xshells = self.ammo_xshells - 1;
	else
	*/
		self.currentammo = self.ammo_shells = self.ammo_shells - 1;
	self.wfiretime = time;
	w_muzzleflash(v, 4);
	//if (self.shotgunmode)
		FireBullets(self, self, 1, 1, 0, 0, DBSHOTGUNEXPLOSIVESLUG * damagescale, 80, shotdir * 5000, spreadboost, "SHOTGUNEXPLOSIVESLUG", DT_SHOTGUN, obitfunc);
	/*
	else
	{
		FireBullets(self, self, 1, 5, DBSHOTGUNBUCKSHOT * 0.1 * damagescale, DBSHOTGUNBUCKSHOT * 0.1 * damagescale, 0, 0, shotdir * 6000, spreadboost + 0.03, "SHOTGUN", DT_SHOTGUN, obitfunc);
		FireBullets(self, self, 0, 5, DBSHOTGUNBUCKSHOT * 0.1 * damagescale, DBSHOTGUNBUCKSHOT * 0.1 * damagescale, 0, 0, shotdir * 6000, spreadboost + 0.03, "SHOTGUN", DT_SHOTGUN, obitfunc);
	}
	*/
	shotorg = v;
};

void() W_DBShotgunSingleFireCode =
{
	W_DBShotgunFireShell(Obituary_DBShotgunSingle, 0);
};

void() W_DBShotgunDoubleFireCode =
{
	if (self.wload > 1)
	{
		while (self.wload > 0)
			W_DBShotgunFireShell(Obituary_DBShotgunDouble, 0);
	}
	else
		W_DBShotgunSingleFireCode();
};

void() w_dbshotgundrop1;
void() w_dbshotgundrop2;
void() w_dbshotgunraise1;
void() w_dbshotgunraise2;
void() w_dbshotgun =
{
	//local float swapmode, otherammo;
	local vector v;

	if (widle(w_dbshotgundrop1))
		return;

	/*
	if (self.shotgunmode)
	{
		swapmode = self.ammo_xshells < 1 && self.ammo_shells >= 1;
		otherammo = self.ammo_shells >= 1;
	}
	else
	{
		swapmode = self.ammo_shells < 1 && self.ammo_xshells >= 1;
		otherammo = self.ammo_xshells >= 1;
	}

	if (otherammo)
	if (self.button5 || swapmode)
	if (time > self.attack_finished)
	{
		self.shotgunmode = !self.shotgunmode;
		self.wload = 0;
		sound(self, CHAN_AUTO, "weapons/bsgload.wav", 1, ATTN_STATIC);
		self.attack_finished = time + 1;
		if (self.shotgunmode)
			sprint(self, "Ammo: Explosive slugs\n");
		else
			sprint(self, "Ammo: Buckshot\n");
	}
	*/

	if (self.wload > 0)
	{
		if (self.button0)
			W_GenericSlowFireCode("weapons/shotgn2.wav", 0.2, W_DBShotgunSingleFireCode);
		else if (self.button3)
			W_GenericSlowFireCode("weapons/shotgn2.wav", 0.2, W_DBShotgunDoubleFireCode);
	}
	else
	{
		if (time > self.attack_finished)
		{
			if (self.shotgunshells)
			{
				self.attack_finished = time + 0.4;
				sound(self, CHAN_AUTO, "weapons/bsgload.wav", 1, ATTN_STATIC);
				v = shotorg + v_forward * -8;
				if (self.shotgunshells & 1) ejectcasing (v + v_right *  1, shotdir, '0 0 0', 30, 1);
				if (self.shotgunshells & 2) ejectcasing (v + v_right * -1, shotdir, '0 0 0', 30, 1);
				self.shotgunshells = 0;
			}
			else
			{
				/*
				if (self.shotgunmode)
				{
					if (self.ammo_xshells >= 1)
					{
						self.wload = min(self.ammo_xshells, 2);
						self.attack_finished = time + 0.2;
						sound(self, CHAN_AUTO, "weapons/bsgload.wav", 1, ATTN_STATIC);
					}
				}
				else
				*/
				{
					if (self.ammo_shells >= 1)
					{
						self.wload = min(self.ammo_shells, 2);
						self.attack_finished = time + 0.2;
						sound(self, CHAN_AUTO, "weapons/bsgload.wav", 1, ATTN_STATIC);
					}
				}
			}
		}
	}

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
	precache_sound("weapons/shotgn2.wav");
	precache_sound("weapons/bsgnoammo.wav");
	precache_sound("weapons/bsgload.wav");
};

float() w_dbshotgunrating = {return genericweaponrating(0, 250, 175);};
void() w_dbshotgunsetup =
{
	/*
	if (self.shotgunmode)
		wset(IT_WEAPON3, IT_SHELLS, self.ammo_xshells, VWEP_SUPER_SHOTGUN, "progs/v_dpshot2.mdl");
	else
	*/
		wset(IT_WEAPON3, IT_SHELLS, self.ammo_shells, VWEP_SUPER_SHOTGUN, "progs/v_dpshot2.mdl");
};
float(float request) setweapon3 = {return weapongeneric(IT_WEAPON3, self.ammo_shells >= 1/* || self.ammo_xshells >= 1*/, request, w_dbshotgunsetup, w_dbshotgun, w_dbshotgunraise1, w_directaim, w_dbshotgunrating, "Double Barrel Shotgun");};

void() w_dbshotgunraise1 = {self.wload = 0;self.shotgunshells = 0;wraise(9, w_dbshotgunraise2, 0.1);};
void() w_dbshotgunraise2 = {wraise(8, w_dbshotgun, 0.1);};

void() w_dbshotgundrop1 = {wdrop(8, w_dbshotgundrop2, 0.1);};
void() w_dbshotgundrop2 = {wdropped(9, 0.1);};
