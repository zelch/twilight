
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

void(float shots) W_NailgunFireCode =
{
	local vector v, casingdir, ang;
	W_Hostile();
	sound(self, CHAN_WEAPON, "weapons/rocket1i.wav", 1, ATTN_NORM);
	while (shots > 0 && Inventory_Quantity(self, "nails") >= 1)
	{
		shots = shots - 1;
		self.wfiretime = time;
		Inventory_AdjustQuantity(self, "nails", -1);
		self.wframe = self.wframe + 1;
		if (self.wframe >= 9)
			self.wframe = 1;
		self.wfiretime = time;
		self.punchangle_x = -2;

		v = shotorg;
		ang = self.v_angle;ang_x = 0 - ang_x;
		if (self.wframe & 1)
		{
			shotorg = shotorg + v_right * 2;
			ejectcasing(shotorg, v_right * 200 + v_up * 50, 50, ang, '0 250 0', 100, 0);
		}
		else
		{
			shotorg = shotorg - v_right * 2;
			ejectcasing(shotorg, v_right * -200 + v_up * 50, 50, ang, '0 -250 0', 100, 0);
		}

		w_muzzleflash(shotorg, 1);
		FireBullets(self, self, 4, 1, 15, 15, 0, 0, shotdir * 15000, 0.025, "NAILGUN", DT_NAIL, Obituary_Nailgun);
		shotorg = v;
	}
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
	W_Hostile();
	sound(self, CHAN_WEAPON, "weapons/grenade.wav", 1, ATTN_NORM);
	self.wfiretime = time;
	Inventory_AdjustQuantity(self, "rockets", -1);
	w_muzzleflash(shotorg, 1);
	//LaunchGrenade(shotorg, shotdir * 1000 + v_up * 200, self, 80, 300, GRENADE_IMPACT, 2.5, "NAILGUNGRENADE", Obituary_NailgunGrenade);
	LaunchMine(shotorg, shotdir * 1000 + v_up * 200, self, 200, 70, 20, 10, MINE_LASERTRIP, 60, "LASERTRIPMINE", Obituary_NailgunMine);
};

void() w_nailgundrop1;
void() w_nailgundrop2;
void() w_nailgunraise1;
void() w_nailgunraise2;
void() w_nailgun =
{
	if (widle(w_nailgundrop1))
		return;

	if (self.aimtarg) // bot target
	{
		if (time > self.altfirechecktimeout)
		{
			self.altfirechecktimeout = time + 0.1 + random() * 0.2;
			if (time > self.altfiretimeout)
			if (vlen(self.aimtarg.origin - self.origin) < 600)
			if (random() < 0.2)
				self.altfiretimeout = time + 0.5 + random() * 0.5;
		}
		if (Inventory_Quantity(self, "rockets") && time < self.altfiretimeout)
			self.button3 = w_grenadeattackaim(1000, 1);
		else
			self.button0 = w_directattackaim(12000, 2);
	}

	if (self.button0)
	{
		if (Inventory_Quantity(self, "nails") >= 1)
		{
			self.wload = W_ShotsToFire(0.1);
			if (self.wload)
				W_NailgunFireCode(self.wload);
		}
	}
	else
	{
		if (self.button3)
		if (Inventory_Quantity(self, "rockets") >= 1)
		if (W_ShotsToFire(0.8))
			W_NailgunGrenadeFireCode();
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
void() w_nailgunsetup = {wset(IT_WEAPON4, IT_NAILS, Inventory_Quantity(self, "nails"), VWEP_NAILGUN, "progs/v_dpnail.mdl");};
float(float request) setweapon4 = {return weapongeneric(IT_WEAPON4, Inventory_Quantity(self, "nails") >= 1 || Inventory_Quantity(self, "rockets") >= 1, request, w_nailgunsetup, w_nailgun, w_nailgunraise1, w_directaim, w_nailgunrating, "Nailgun");};

