
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

void(float shots) W_SuperNailgunFireCode =
{
	local vector v, ang;
	W_Hostile();
	sound(self, CHAN_WEAPON, "weapons/spike2.wav", 1, ATTN_NORM);
	v = shotorg;
	while (shots > 0 && Inventory_Quantity(self, "nails") >= 1)
	{
		shots = shots - 1;
		Inventory_AdjustQuantity(self, "nails", -1);
		self.wframe = self.wframe + 0.5; // 10fps animation
		if (self.wframe >= 9)
			self.wframe = 1;
		self.wfiretime = time;

		shotorg = shotorg + v_up * 2;
		w_muzzleflash(shotorg, 1);
		ang = self.v_angle;ang_x = 0 - ang_x;
		ejectcasing(shotorg, v_right * 200 + v_up * 50, 50, ang, '0 50 0', 100, 0);
		FireBullets(self, self, 4, 1, 15, 15, 0, 0, shotdir * 12000, 0.05, "SUPERNAILGUN", DT_NAIL, Obituary_SuperNailgun);
	}
	shotorg = v;
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
	W_Hostile();
	sound(self, CHAN_WEAPON, "weapons/grenade.wav", 1, ATTN_NORM);
	self.wfiretime = time;
	a = 3;
	if (a > Inventory_Quantity(self, "rockets"))
		a = Inventory_Quantity(self, "rockets");
	Inventory_AdjustQuantity(self, "rockets", 0 - a);
	w_muzzleflash(shotorg, 3);
	LaunchMine(shotorg, shotdir * 1000 + v_up * 200, self, a * 100, a * 100 + 50, 20, 10, MINE_PROXIMITY, 60, "PROXIMITYMINE", Obituary_ProximityMine);
};

void() w_snailgundrop1;
void() w_snailgundrop2;
void() w_snailgunraise1;
void() w_snailgunraise2;
void() w_snailgun =
{
	if (widle(w_snailgundrop1))
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
		if (Inventory_Quantity(self, "rockets") >= 3 && time < self.altfiretimeout)
			self.button3 = w_grenadeattackaim(1000, 1);
		else
			self.button0 = w_directattackaim(12000, 1);
	}

	if (self.button0)
	{
		if (Inventory_Quantity(self, "nails") >= 1)
		{
			self.wload = W_ShotsToFire(0.05);
			if (self.wload > 0)
				W_SuperNailgunFireCode(self.wload);
		}
	}
	else
	{
		if (self.button3)
		if (Inventory_Quantity(self, "rockets") >= 1)
		if (W_ShotsToFire(0.5))
			W_SuperNailgunMineFireCode();
	}

	if ((time - self.wfiretime) < 0.15)
		self.weaponframe = self.wframe;
	else
		self.weaponframe = 0;

	havoc_nailanimupdate(self.weaponframe);
};

void() w_snailgunprecache =
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

void() w_snailgunsetup = {wset("supernailgun", IT_NAILS, Inventory_Quantity(self, "nails"), VWEP_SUPER_NAILGUN, "progs/v_dpnail2.mdl");};
float(float request) setupweapon_supernailgun = {return weapongeneric("supernailgun", Inventory_Quantity(self, "nails") >= 1 || Inventory_Quantity(self, "rockets") >= 1, request, w_snailgunsetup, w_snailgun, w_snailgunraise1, "Super Nailgun", 0, 1000, 300, w_snailgunprecache);};
