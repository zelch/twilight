
void(entity targ, entity attacker, string dmsg, float dtype) Obituary_Pistol =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " was gunned down by ";
		deathstring3 = attacker.netname;
		deathstring4 = "";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

void() W_PistolFireCode =
{
	local vector ang;
	W_Hostile();
	sound(self, CHAN_WEAPON, "weapons/rocket1i.wav", 1, ATTN_NORM);
	self.wfiretime = time;
	w_muzzleflash(shotorg, 1);
	ang = self.v_angle;ang_x = 0 - ang_x;
	ejectcasing(shotorg, v_right * 150 + v_up * 50, 50, ang, '0 250 0', 100, 0);
	FireBullets(self, self, 4, 1, 35, 35, 0, 0, shotdir * 12000, 0, "PISTOL", DT_NAIL, Obituary_Pistol);
};

void() w_pistoldrop1;
void() w_pistoldrop2;
void() w_pistolraise1;
void() w_pistolraise2;
void() w_pistol =
{
	if (widle(w_pistoldrop1))
		return;

	if (self.aimtarg) // bot target
		self.button0 = w_directattackaim(12000, 2);

	if (self.button0)
	if (W_ShotsToFire(0.4))
		W_PistolFireCode();

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

void() w_pistolprecache =
{
	precache_model("progs/v_dpshot.mdl");
	precache_sound("weapons/rocket1i.wav");
};

void() w_pistolsetup = {wset("pistol", 0, 0, VWEP_SHOTGUN, "progs/v_dpshot.mdl");};
float(float request) setupweapon_pistol = {return weapongeneric("pistol", TRUE, request, w_pistolsetup, w_pistol, w_pistolraise1, "Pistol", 0, 99999, 75, w_pistolprecache);};

void() w_pistolraise1 = {wraise(8, w_pistolraise2, 0.1);};
void() w_pistolraise2 = {wraise(7, w_pistol, 0.1);};

void() w_pistoldrop1 = {wdrop(7, w_pistoldrop2, 0.1);};
void() w_pistoldrop2 = {wdropped(8, 0.1);};
