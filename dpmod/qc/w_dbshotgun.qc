
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

float DBSHOTGUN = 50;

.float shotgunshells;

/*
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
	Inventory_AdjustQuantity(self, "shells", -1);
	self.wfiretime = time;
	w_muzzleflash(v, 4);
	FireBullets(self, self, 1, 5, DBSHOTGUN * 0.1, DBSHOTGUN * 0.1, 0, 0, shotdir * 6000, spreadboost + 0.03, "SHOTGUN", DT_SHOTGUN, obitfunc);
	FireBullets(self, self, 0, 5, DBSHOTGUN * 0.1, DBSHOTGUN * 0.1, 0, 0, shotdir * 6000, spreadboost + 0.03, "SHOTGUN", DT_SHOTGUN, obitfunc);
	shotorg = v;
};

void() W_DBShotgunSingleFireCode =
{
	W_DBShotgunFireShell(Obituary_DBShotgunSingle, 0, FALSE);
};

void() W_DBShotgunDoubleFireCode =
{
	while (self.wload > 0)
		W_DBShotgunFireShell(Obituary_DBShotgunDouble, 0, FALSE);
};
*/

void(void(entity t, entity a, string m, float dtyp) obitfunc, float spreadboost) W_DBShotgunGatlingFireShell =
{
	local vector v;

	v = shotorg;
	if (self.wload)
	{
		self.wload = 0;
		self.shotgunshells = self.shotgunshells + 1;
		shotorg = shotorg - v_right;
	}
	else
	{
		self.wload = 1;
		self.shotgunshells = self.shotgunshells + 2;
		shotorg = shotorg + v_right;
	}
	Inventory_AdjustQuantity(self, "shells", -1);
	self.wfiretime = time;
	w_muzzleflash(v, 2);
	FireBullets(self, self, 1, 5, DBSHOTGUN * 0.1, DBSHOTGUN * 0.1, 0, 0, shotdir * 6000, spreadboost + 0.03, "SHOTGUN", DT_SHOTGUN, obitfunc);
	FireBullets(self, self, 0, 5, DBSHOTGUN * 0.1, DBSHOTGUN * 0.1, 0, 0, shotdir * 6000, spreadboost + 0.03, "SHOTGUN", DT_SHOTGUN, obitfunc);
	shotorg = v;
};

void() W_DBShotgunGatlingFireCode =
{
	W_Hostile();
	sound(self, CHAN_WEAPON, "weapons/shotgn2.wav", 1, ATTN_NORM);
	W_DBShotgunGatlingFireShell(Obituary_DBShotgunSingle, 0);
};


void() w_dbshotgundrop1;
void() w_dbshotgundrop2;
void() w_dbshotgunraise1;
void() w_dbshotgunraise2;
void() w_dbshotgun =
{
	//local float swapmode, otherammo;
	local vector v, ang;

	if (widle(w_dbshotgundrop1))
		return;

	if (time > self.attack_finished)
	{
		if (self.shotgunshells)
		{
			sound(self, CHAN_AUTO, "weapons/bsgload.wav", 1, ATTN_STATIC);
			v = shotorg + v_forward * -8;
			ang = self.v_angle;ang_x = 0 - ang_x;
			if (self.shotgunshells & 1) ejectcasing (v + v_right *  1, '0 0 0', 30, ang, '0 0 0', 150, 1);
			if (self.shotgunshells & 2) ejectcasing (v + v_right * -1, '0 0 0', 30, ang, '0 0 0', 150, 1);
			self.shotgunshells = 0;
		}
		if (self.button0)
		if (Inventory_Quantity(self, "shells") > 0)
		if (W_ShotsToFire(0.2))
			W_DBShotgunGatlingFireCode();
	}

	/*
	if (self.wload > 0)
	{
		if (self.button0)
			W_GenericSlowFireCode("weapons/shotgn2.wav", 0.2, W_DBShotgunSingleFireCode);
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
				ang = self.v_angle;ang_x = 0 - ang_x;
				if (self.shotgunshells & 1) ejectcasing (v + v_right *  1, '0 0 0', 30, ang, '0 0 0', 150, 1);
				if (self.shotgunshells & 2) ejectcasing (v + v_right * -1, '0 0 0', 30, ang, '0 0 0', 150, 1);
				self.shotgunshells = 0;
			}
			else
			{
				if (Inventory_Quantity(self, "shells") >= 1)
				{
					self.wload = min(Inventory_Quantity(self, "shells"), 2);
					self.attack_finished = time + 0.2;
					sound(self, CHAN_AUTO, "weapons/bsgload.wav", 1, ATTN_STATIC);
				}
			}
		}
	}
	*/

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
void() w_dbshotgunsetup = {wset(IT_WEAPON3, IT_SHELLS, Inventory_Quantity(self, "shells"), VWEP_SUPER_SHOTGUN, "progs/v_dpshot2.mdl");};
float(float request) setweapon3 = {return weapongeneric(IT_WEAPON3, Inventory_Quantity(self, "shells") >= 1, request, w_dbshotgunsetup, w_dbshotgun, w_dbshotgunraise1, w_directaim, w_dbshotgunrating, "Double Barrel Shotgun");};

void() w_dbshotgunraise1 = {self.wload = 0;self.shotgunshells = 0;wraise(9, w_dbshotgunraise2, 0.1);};
void() w_dbshotgunraise2 = {wraise(8, w_dbshotgun, 0.1);};

void() w_dbshotgundrop1 = {wdrop(8, w_dbshotgundrop2, 0.1);};
void() w_dbshotgundrop2 = {wdropped(9, 0.1);};
