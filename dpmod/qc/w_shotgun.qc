
void(entity targ, entity attacker, string dmsg, float dtype) Obituary_Shotgun =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " was another victim of ";
		deathstring3 = attacker.netname;
		deathstring4 = "'s hunting season";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

float SHOTGUN = 50;

void() W_SingleShotgunFireCode =
{
	W_Hostile();
	sound(self, CHAN_WEAPON, "weapons/shotgn2.wav", 1, ATTN_NORM);
	self.wfiretime = time;
	Inventory_AdjustQuantity(self, "shells", -1);
	w_muzzleflash(shotorg, 2);
	FireBullets(self, self, 1, 5, SHOTGUN * 0.1, SHOTGUN * 0.1, 0, 0, shotdir * 6000, 0.05, "SHOTGUN", DT_SHOTGUN, Obituary_Shotgun);
	FireBullets(self, self, 0, 5, SHOTGUN * 0.1, SHOTGUN * 0.1, 0, 0, shotdir * 6000, 0.05, "SHOTGUN", DT_SHOTGUN, Obituary_Shotgun);
	self.wload = -1;
};

void() w_shotgundrop1;
void() w_shotgundrop2;
void() w_shotgunraise1;
void() w_shotgunraise2;
void() w_shotgun =
{
	local vector v, ang;
	if (widle(w_shotgundrop1))
		return;

	if (self.aimtarg) // bot target
		self.button0 = w_directattackaim(6000, 1);

	if (self.wload > Inventory_Quantity(self, "shells"))
		self.wload = Inventory_Quantity(self, "shells");

	if (self.button0)
	{
		if (self.wload >= 1) // is it loaded?
		if (W_ShotsToFire(0.3))
			W_SingleShotgunFireCode();
	}

	if (self.wload < 1 && time > self.attack_finished)
	{
		if (self.wload < 0)
		{
			self.attack_finished = time + 0.2;
			sound(self, CHAN_AUTO, "weapons/bsgload.wav", 1, ATTN_STATIC);
			v = shotorg + v_forward * -5;
			ang = self.v_angle;ang_x = 0 - ang_x;
			ejectcasing(v, v_right * 100 + v_up * 40, 30, ang, '0 250 0', 100, 1);
			self.wload = 0;
		}
		else if (Inventory_Quantity(self, "shells") >= 1)
		{
			self.wload = 1;
			self.attack_finished = time + 0.2;
			sound(self, CHAN_AUTO, "weapons/bsgload.wav", 1, ATTN_STATIC);
		}
		else if (widle(w_shotgundrop1))
			return;
	}
	else if (widle(w_shotgundrop1))
		return;

	if (self.wfiretime)
	{
		self.weaponframe = floor((time - self.wfiretime) * 10 + 1);
		if (self.weaponframe >= 7)
			self.weaponframe = self.wfiretime = 0;
	}
	else
		self.weaponframe = 0;

	havoc_shotanimupdate(self.weaponframe);
};

void() w_shotgunprecache =
{
	precache_model("progs/v_dpshot.mdl");
	precache_sound("weapons/shotgn2.wav");
};

void() w_shotgunsetup = {wset("shotgun", IT_SHELLS, Inventory_Quantity(self, "shells"), VWEP_SHOTGUN, "progs/v_dpshot.mdl");};
float(float request) setupweapon_shotgun = {return weapongeneric("shotgun", Inventory_Quantity(self, "shells") >= 1, request, w_shotgunsetup, w_shotgun, w_shotgunraise1, "Shotgun", 0, 2000, 128, w_shotgunprecache);};

void() w_shotgunraise1 = {self.wload = 1;wraise(8, w_shotgunraise2, 0.1);};
void() w_shotgunraise2 = {wraise(7, w_shotgun, 0.1);};

void() w_shotgundrop1 = {wdrop(7, w_shotgundrop2, 0.1);};
void() w_shotgundrop2 = {wdropped(8, 0.1);};
