
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
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

/*
void() W_PlasmaRifleFire5 =
{
	self.wfiretime = time;
	self.currentammo = self.ammo_cells = self.ammo_cells - 5;
	FirePlasma(self, shotorg, shotdir, 600 * damagescale, 300, '0 0 0', "PLASMARIFLE", Obituary_PlasmaRifle);
};

void() W_PlasmaRifleFire1 =
{
	self.wfiretime = time;
	self.currentammo = self.ammo_cells = self.ammo_cells - 1;
	FirePlasma(self, shotorg, shotdir, 120 * damagescale, 60, '0 0 0', "PLASMARIFLE", Obituary_PlasmaRifle);
};
*/

void() W_PlasmaRifleFire =
{
	if (self.wload > self.ammo_cells)
		self.wload = self.ammo_cells;
	self.wfiretime = time;
	self.currentammo = self.ammo_cells = self.ammo_cells - self.wload;
	self.wburst = self.wburst - self.wload;
	FirePlasma(self, shotorg, shotdir, self.wload * 30 * damagescale, 45, '0 0 0', "PLASMARIFLE", Obituary_PlasmaRifle);
};

.float idealzoom;

void() w_plasmarifledrop1;
void() w_plasmarifledrop2;
void() w_plasmarifleraise1;
void() w_plasmarifleraise2;
void() w_plasmarifle =
{
	if (self.button3)
		self.idealzoom = 0.2;

	/*
	if (time > self.attack_finished)
	{
		if (self.button0)
		{
			if (self.ammo_cells >= 1)
			if (self.wburst < 5)
			{
				if (self.wburst < 1)
				{
					self.wburst = 1;
					// FIXME: need a prep sound
					sound(self, CHAN_WEAPON, "plasma/plasexpl.wav", 1, ATTN_NORM);
				}
				self.wburst = self.wburst + frametime * 4;
				if (self.wburst >= 5)
				{
					self.wburst = 5;
					// FIXME: need a full charge reached sound
					sound(self, CHAN_WEAPON, "plasma/plasexpl.wav", 1, ATTN_NORM);
				}
			}
		}
		else
		{
			// discharge sound
			if (self.ammo_cells >= 1)
			if (self.wburst)
			{
				// FIXME: need a high power fire sound (and a new low power one)
				if (self.wburst >= 5)
					W_GenericSlowFireCode("plasma/plasma.wav", 2, W_PlasmaRifleFire5);
				else
					W_GenericSlowFireCode("plasma/plasma.wav", 0.7, W_PlasmaRifleFire1);
			}
			self.wburst = 0;
			if (!self.button3)
			if (widle(w_plasmarifledrop1))
				return;
		}
	}
	*/

	/*
	if (time > self.attack_finished)
	{
		if (self.button0)
		{
			if (self.wburst)
				self.wload = self.wload + frametime * 2;
			else
				self.wload = 2;
			while (self.wload >= 1 && self.ammo_cells >= 1 && self.wburst < 5)
			{
				// FIXME: need a proper charge sound
				//if (!self.wburst)
				//	sound(self, CHAN_WEAPON, "weapons/plasmarifle/charge.wav", 1, ATTN_NORM);
				//	sound(self, CHAN_WEAPON, "plasma/plasma.wav", 1, ATTN_NORM);
				sound(self, CHAN_WEAPON, "plasma/plasexpl.wav", 1, ATTN_NORM);
				self.wburst = self.wburst + 1;
				self.currentammo = self.ammo_cells = self.ammo_cells - 1;
				self.wload = self.wload - 1;
			}
		}
		else
		{
			if (self.button0)
			{
				// fire
				// FIXME: need a proper fire sound
				//sound(self, CHAN_WEAPON, "weapons/plasmarifle/fire.wav", 1, ATTN_NORM);
				sound(self, CHAN_WEAPON, "plasma/plasma.wav", 1, ATTN_NORM);
				W_GenericSlowFireCode("", 0.7, W_PlasmaRifleFire);
				self.wburst = 0;
			}
			else if (self.wload)
			{
				// discharge without firing (wasted ammo)
				// FIXME: need a proper discharge sound
				//sound(self, CHAN_WEAPON, "weapons/plasmarifle/discharge.wav", 1, ATTN_NORM);
				sound(self, CHAN_WEAPON, "plasma/plasexpl.wav", 1, ATTN_NORM);
			}
			else if (widle(w_plasmarifledrop1))
				return;
			self.wload = 0;
		}
	}
	*/

	if (time >= self.attack_finished)
	{
		if (self.button0 && self.wburst > 0 && self.ammo_cells > 0)
		{
			// fire higher powered shots if zoomed
			// (but they use ammo faster, so the burst runs out sooner)
			self.wload = 1;
			if (self.idealzoom < 1)
				self.wload = 3;
			if (self.wload > self.wburst)
				self.wload = self.wburst;
			W_GenericSlowFireCode("plasma/plasma.wav", 0.05, W_PlasmaRifleFire);
		}
		else if (self.wburst <= 0 && self.ammo_cells > 0)
		{
			self.wburst = 9;
			self.attack_finished = time + 0.4;
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

void() weapon8_precache =
{
	precache_model("progs/v_dpshot.mdl");
	precache_model("progs/s_bubble.spr");
	precache_model("progs/plasmashot.spr32");
	precache_sound("plasma/plasma.wav");
	precache_sound("plasma/plasexpl.wav");
};

float() w_plasmariflerating = {return genericweaponrating(0, 1500, 200);};
void() w_plasmariflesetup = {wset(IT_WEAPON8, IT_CELLS, self.ammo_cells, VWEP_SHOTGUN, "progs/v_dpshot.mdl");};
float(float request) setweapon8 = {return weapongeneric(IT_WEAPON8, self.ammo_cells >= 1, request, w_plasmariflesetup, w_plasmarifle, w_plasmarifleraise1, w_directaim, w_plasmariflerating, "PlasmaRifle");};

void() w_plasmarifleraise1 = {wraise(8, w_plasmarifleraise2, 0.1);};
void() w_plasmarifleraise2 = {self.wburst = 9;wraise(7, w_plasmarifle, 0.1);};

void() w_plasmarifledrop1 = {wdrop(7, w_plasmarifledrop2, 0.1);};
void() w_plasmarifledrop2 = {wdropped(8, 0.1);};
