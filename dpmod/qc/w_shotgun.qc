
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

void() W_SingleShotgunFireCode =
{
	stopfiring = TRUE;
	self.wfiretime = time;
	self.currentammo = self.ammo_shells = self.ammo_shells - 1;

	w_muzzleflash(shotorg, 2);
	//bullet_type = 1;
	//FireBullets(5, 9, 9, shotdir * 6000, 0.05, "SHOTGUN", DT_SHOTGUN, Obituary_Shotgun);
	//bullet_type = 0;
	//FireBullets(10, 9, 9, shotdir * 6000, 0.05, "SHOTGUN", DT_SHOTGUN, Obituary_Shotgun);
	bullet_type = 1;
	FireBullets(5, 5, 5, shotdir * 6000, 0.05, "SHOTGUN", DT_SHOTGUN, Obituary_Shotgun);
	bullet_type = 0;
	FireBullets(10, 5, 5, shotdir * 6000, 0.05, "SHOTGUN", DT_SHOTGUN, Obituary_Shotgun);

	self.wload = -1;
};

void() w_shotgundrop1;
void() w_shotgundrop2;
void() w_shotgunraise1;
void() w_shotgunraise2;
void() w_shotgun =
{
	local vector a, v;
	if (widle(w_shotgundrop1))
		return;

	if (self.wload > self.ammo_shells)
		self.wload = self.ammo_shells;

	if (self.button0)
	{
		if (self.wload >= 1) // is it loaded?
			W_GenericFireCode("weapons/shotgn2.wav", 0.3, W_SingleShotgunFireCode);
	}
	else
		self.notfiring = TRUE;

	if (self.wload < 1 && time > self.attack_finished)
	{
		if (self.wload < 0)
		{
			self.attack_finished = time + 0.2;
			sound(self, CHAN_AUTO, "weapons/bsgload.wav", 1, ATTN_STATIC);
			v = shotorg + v_forward * -5;
			ejectcasing (v, v_forward, (v_right * 100) + v_up * 40, 30, 1);
			self.wload = 0;
		}
		else if (self.ammo_shells >= 1)
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

void() weapon2_precache =
{
	precache_model("progs/v_dpshot.mdl");
	precache_sound("weapons/shotgn2.wav");
};

float() w_shotgunrating = {return genericweaponrating(0, 2000, 128);};
void() w_shotgunsetup = {wset(IT_WEAPON2, IT_SHELLS, self.ammo_shells, VWEP_SHOTGUN, "progs/v_dpshot.mdl");};
float(float request) setweapon2 = {return weapongeneric(IT_WEAPON2, self.ammo_shells >= 1, request, w_shotgunsetup, w_shotgun, w_shotgunraise1, w_directaim, w_shotgunrating, "Shotgun");};

void() w_shotgunraise1 = {self.wload = 1;wraise(8, w_shotgunraise2, 0.1);};
void() w_shotgunraise2 = {wraise(7, w_shotgun, 0.1);};

void() w_shotgundrop1 = {wdrop(7, w_shotgundrop2, 0.1);};
void() w_shotgundrop2 = {wdropped(8, 0.1);};
