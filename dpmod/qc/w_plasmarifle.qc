
void(entity targ, entity attacker, string dmsg, float dtype) Obituary_PlasmaRifle =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " was burned by ";
		deathstring3 = attacker.netname;
		deathstring4 = "'s plasma rifle";
		if (targ.bodyhealth < 1)
			deathstring2 = " was splattered by ";
	}
	else if (dtype == DTYPE_SUICIDE)
	{
		deathstring1 = targ.netname;
		deathstring2 = " became crispy";
		deathstring3 = "";
		deathstring4 = "";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

.float plasmabarrel;
void(float shots, float cellspershot, float damagepercell, float r) W_PlasmaRifleFire =
{
	local vector v;
	local float cells;
	W_Hostile();
	sound(self, CHAN_WEAPON, "plasma/plasma.wav", 1, ATTN_NORM);
	while (shots > 0)
	{
		shots = shots - 1;
		cells = cellspershot;
		if (cells > self.ammo_cells)
			cells = self.ammo_cells;
		if (cells <= 0)
			return;
		self.currentammo = self.ammo_cells = self.ammo_cells - cells;
		self.wfiretime = time;
		if (self.plasmabarrel == 0)
		{
			self.plasmabarrel = 1;
			v = v_up * 2;
		}
		else if (self.plasmabarrel == 1)
		{
			self.plasmabarrel = 2;
			v = v_right * 1.4 + v_up * -1.4;
		}
		else
		{
			self.plasmabarrel = 0;
			v = v_right * -1.4 + v_up * -1.4;
		}
		FirePlasma(self, shotorg + v, (shotdir + v * 0.005) * 5000, damagepercell * cells * damagescale, r, "PLASMARIFLE", Obituary_PlasmaRifle);
	}
};

.float woverload;
/*
void() W_PlasmaRifleFireOverload2 =
{
	local float d, r;
	local vector v;
	W_Hostile();
	sound(self, CHAN_WEAPON, "plasma/plasma.wav", 1, ATTN_NORM);
	self.wfiretime = time;
	d = self.woverload * 20;
	r = 120;
	v = v_up    *  2                    ;FirePlasma(self, shotorg + v, (shotdir + v * 0.005) * 10000, d * damagescale, r, "PLASMARIFLE", Obituary_PlasmaRifle);
	v = v_right *  1.414 + v_up * -1.414;FirePlasma(self, shotorg + v, (shotdir + v * 0.005) * 10000, d * damagescale, r, "PLASMARIFLE", Obituary_PlasmaRifle);
	v = v_right * -1.414 + v_up * -1.414;FirePlasma(self, shotorg + v, (shotdir + v * 0.005) * 10000, d * damagescale, r, "PLASMARIFLE", Obituary_PlasmaRifle);
};
*/

void() w_plasmarifledrop1;
void() w_plasmarifledrop2;
void() w_plasmarifleraise1;
void() w_plasmarifleraise2;
void() w_plasmarifle =
{
	// FIXME: need overload fire sound (second overload sound)
	if (self.woverload > 0)
	{
		if (W_ShotsToFire(1))
		{
			W_PlasmaRifleFire(3, self.woverload / 3, 30, 120);
			self.woverload = 0;
		}
	}
	else if (self.button0 && self.ammo_cells > 0)
	{
		self.wload = W_ShotsToFire(0.05);
		if (self.wload > 0)
			W_PlasmaRifleFire(self.wload, 1, 30, 60);
	}
	else if (time >= self.attack_finished)
	{
		if (self.button3 && self.ammo_cells > 0)
		{
			self.woverload = 12;
			//if (self.woverload > self.ammo_cells)
			//	self.woverload = self.ammo_cells;
			//self.currentammo = self.ammo_cells = self.ammo_cells - self.woverload;
			self.attack_finished = time + 0.2;
			// FIXME: need overload charge sound (first overload sound)
			sound(self, CHAN_WEAPON, "plasma/plasexpl.wav", 1, ATTN_NORM);
		}
		else if (widle(w_plasmarifledrop1))
			return;
	}

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

void() weapon9_precache =
{
	precache_model("progs/v_dpshot.mdl");
	precache_model("progs/s_bubble.spr");
	precache_model("progs/plasmashot.spr32");
	//precache_sound("weapons/rocket1i.wav");
	precache_sound("plasma/plasma.wav");
	precache_sound("plasma/plasexpl.wav");
};

float() w_plasmariflerating = {return genericweaponrating(0, 1500, 200);};
void() w_plasmariflesetup = {wset(IT_WEAPON9, IT_CELLS, self.ammo_cells, VWEP_SHOTGUN, "progs/v_dpshot.mdl");};
float(float request) setweapon9 = {return weapongeneric(IT_WEAPON9, self.ammo_cells >= 1, request, w_plasmariflesetup, w_plasmarifle, w_plasmarifleraise1, w_directaim, w_plasmariflerating, "PlasmaRifle");};

void() w_plasmarifleraise1 = {wraise(8, w_plasmarifleraise2, 0.1);};
void() w_plasmarifleraise2 = {self.wburst = 9;wraise(7, w_plasmarifle, 0.1);};

void() w_plasmarifledrop1 = {wdrop(7, w_plasmarifledrop2, 0.1);};
void() w_plasmarifledrop2 = {wdropped(8, 0.1);};
