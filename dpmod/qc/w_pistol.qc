
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
	self.wfiretime = time;
	w_muzzleflash(shotorg, 1);
	ejectcasing(shotorg, shotdir, v_right * 150 + v_up * 50, 50, 0);
	bullet_type = 4;
	if (self.button3)
		FireBullets(1, 30, 30, shotdir * 7000, 0.05, "PISTOL", DT_NAIL, Obituary_Pistol);
	else
		FireBullets(1, 30, 30, shotdir * 7000, 0.0125, "PISTOL", DT_NAIL, Obituary_Pistol);
};

void() w_pistoldrop1;
void() w_pistoldrop2;
void() w_pistolraise1;
void() w_pistolraise2;
void() w_pistol =
{
	if (widle(w_pistoldrop1))
		return;

	if (self.button0)
		W_GenericSlowFireCode("weapons/rocket1i.wav", 0.4, W_PistolFireCode);
	else if (self.button3)
		W_GenericSlowFireCode("weapons/rocket1i.wav", 0.2, W_PistolFireCode);

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

void() weapon1_precache =
{
	precache_model("progs/v_dpshot.mdl");
	precache_sound("weapons/rocket1i.wav");
};

float() w_pistolrating = {return genericweaponrating(0, 99999, 75);};
void() w_pistolsetup = {wset(IT_WEAPON1, 0, 0, VWEP_SHOTGUN, "progs/v_dpshot.mdl");};
float(float request) setweapon1 = {return weapongeneric(IT_WEAPON1, TRUE, request, w_pistolsetup, w_pistol, w_pistolraise1, w_directaim, w_pistolrating, "Pistol");};

void() w_pistolraise1 = {wraise(8, w_pistolraise2, 0.1);};
void() w_pistolraise2 = {wraise(7, w_pistol, 0.1);};

void() w_pistoldrop1 = {wdrop(7, w_pistoldrop2, 0.1);};
void() w_pistoldrop2 = {wdropped(8, 0.1);};
