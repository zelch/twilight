
void(entity targ, entity attacker, string dmsg, float dtype) Obituary_PlasmaRifle =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " was burned by ";
		deathstring3 = attacker.netname;
		deathstring4 = "'s plasma rifle";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

void() W_PlasmaRifleFireCode =
{
	local vector dir;
	local float cells;

	if (self.ammo_cells < 1)
	{
		stopfiring = TRUE;
		return;
	}

	cells = floor(self.wload);
	if (cells > self.ammo_cells)
		cells = self.ammo_cells;
	self.wload = 0;
	self.currentammo = self.ammo_cells = self.ammo_cells - cells;
	self.wfiretime = time;

	if (self.viewzoom < 1)
	{
		dir = shotdir;

		//FireBullets(self, self, shotorg, 4, 1, cells * 30, cells * 30, dir * 10000, 0, "PLASMARIFLE", DT_NAIL, Obituary_PlasmaRifle);
		FirePlasma(self, shotorg, dir, cells * 30, 105, '0 0 0', "PLASMARIFLE", Obituary_PlasmaRifle);
	}
	else
	{
		dir = shotdir + randomvec() * 0.03;
		w_muzzleflash(shotorg, 1);

		//FireBullets(self, self, shotorg, 4, 1, cells * 30, cells * 30, dir * 10000, 0, "PLASMARIFLE", DT_NAIL, Obituary_PlasmaRifle);
		FirePlasma(self, shotorg, dir, cells * 30, 45, '0 0 0', "PLASMARIFLE", Obituary_PlasmaRifle);
	}

	if (self.ammo_cells < 1)
		stopfiring = TRUE;
};

.float idealzoom;

void() w_plasmarifledrop1;
void() w_plasmarifledrop2;
void() w_plasmarifleraise1;
void() w_plasmarifleraise2;
void() w_plasmarifle =
{
	if (widle(w_plasmarifledrop1))
		return;

	if (self.button3)
		self.idealzoom = 0.2;

	if (self.button0)
	{
		if (self.viewzoom < 1)
		{
			self.wload = 4;
			W_GenericFireCode("", 0.7, W_PlasmaRifleFireCode);
		}
		else
		{
			self.wload = 1;
			W_GenericFireCode("", 0.1, W_PlasmaRifleFireCode);
		}
	}
	else
		self.notfiring = TRUE;

	if (widle(w_plasmarifledrop1))
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

void() weapon8_precache =
{
	precache_model("progs/v_dpshot.mdl");
	precache_model("progs/s_bubble.spr");
	precache_model("progs/plasmashot.spr32");
	//precache_sound("plasma/plasma.wav");
	precache_sound("plasma/plasexpl.wav");
};

float() w_plasmariflerating = {return genericweaponrating(0, 1500, 200);};
void() w_plasmariflesetup = {wset(IT_WEAPON8, IT_CELLS, self.ammo_cells, VWEP_SHOTGUN, "progs/v_dpshot.mdl");};
float(float request) setweapon8 = {return weapongeneric(IT_WEAPON8, self.ammo_cells >= 1, request, w_plasmariflesetup, w_plasmarifle, w_plasmarifleraise1, w_directaim, w_plasmariflerating, "PlasmaRifle");};

void() w_plasmarifleraise1 = {wraise(8, w_plasmarifleraise2, 0.1);};
void() w_plasmarifleraise2 = {wraise(7, w_plasmarifle, 0.1);};

void() w_plasmarifledrop1 = {wdrop(7, w_plasmarifledrop2, 0.1);};
void() w_plasmarifledrop2 = {wdropped(8, 0.1);};
