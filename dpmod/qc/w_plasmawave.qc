
void(entity targ, entity attacker, string dmsg, float dtype) Obituary_PlasmaWaveShot =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " was incinerated by ";
		deathstring3 = attacker.netname;
		deathstring4 = "'s plasma inferno";
		if (targ.bodyhealth < 1)
			deathstring2 = " was obliterated by ";
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

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_PlasmaWaveOverload =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " surfed ";
		deathstring3 = attacker.netname;
		deathstring4 = "'s plasma wave";
		if (targ.bodyhealth < 1)
			deathstring2 = " wiped out in ";
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

void() W_PlasmaWaveFireShot =
{
	local float cells;
	W_Hostile();
	sound(self, CHAN_WEAPON, "plasma/plasma.wav", 1, ATTN_NORM);
	cells = Inventory_Quantity(self, "cells");
	if (cells > 10)
		cells = 10;
	self.wfiretime = time;
	Inventory_AdjustQuantity(self, "cells", 0 - cells);
	FirePlasmaBall(self, shotorg, shotdir * 1000, cells * 20, 120, "PLASMAWAVE", Obituary_PlasmaWaveShot);
};

void() W_PlasmaWaveFireWave =
{
	/*
	local float cells;
	W_Hostile();
	sound(self, CHAN_WEAPON, "plasma/plasma.wav", 1, ATTN_NORM);
	cells = Inventory_Quantity(self, "cells");
	if (cells > 50)
		cells = 50;
	self.wfiretime = time;
	Inventory_AdjustQuantity(self, "cells", 0 - cells);
	FirePlasmaBall(self, shotorg, shotdir * 1000, cells * 15, 300, "PLASMAWAVE", Obituary_PlasmaWaveShot);
	*/
	local float cells, shots, damage;
	local vector ang;
	W_Hostile();
	sound(self, CHAN_WEAPON, "plasma/plasma.wav", 1, ATTN_NORM);
	cells = Inventory_Quantity(self, "cells");
	if (cells > 50)
		cells = 50;
	self.wfiretime = time;
	Inventory_AdjustQuantity(self, "cells", 0 - cells);
	//cells = cells + 60;
	shots = ceil(cells / 5);
	if (shots > 12)
		shots = 12;
	damage = cells * 20 / shots;
	ang = self.v_angle - (shots * '0 3 0');
	while (shots > 0)
	{
		shots = shots - 1;
		makevectors(ang);
		FirePlasmaBall(self, shotorg, v_forward * 1000, damage, 120, "PLASMAWAVE", Obituary_PlasmaWaveOverload);
		ang = ang + '0 6 0';
	}
};

.float woverload;
void() w_plasmawavedrop1;
void() w_plasmawavedrop2;
void() w_plasmawaveraise1;
void() w_plasmawaveraise2;
void() w_plasmawave =
{
	if (self.aimtarg) // bot target
	{
		if (time > self.altfirechecktimeout)
		{
			self.altfirechecktimeout = time + 0.1 + random() * 0.2;
			if (time > self.altfiretimeout)
			if (random() < 0.2)
				self.altfiretimeout = time + 0.5 + random() * 0.5;
		}
		if (time < self.altfiretimeout)
			self.button3 = w_directattackaim(1000, 3);
		else
			self.button0 = w_directattackaim(1000, 3);
	}

	// FIXME: need overload fire sound (second overload sound)
	if (self.woverload > 0)
	{
		if (W_ShotsToFire(1))
		{
			self.woverload = 0;
			W_PlasmaWaveFireWave();
		}
	}
	else if (self.button0 && Inventory_Quantity(self, "cells") > 0)
	{
		if (W_ShotsToFire(0.5))
			W_PlasmaWaveFireShot();
	}
	else if (time >= self.attack_finished)
	{
		if (self.button3 && Inventory_Quantity(self, "cells") > 0)
		{
			self.woverload = 1;
			self.attack_finished = time + 0.5;
			// FIXME: need overload charge sound (first overload sound)
			sound(self, CHAN_WEAPON, "plasma/plasexpl.wav", 1, ATTN_NORM);
		}
		else if (widle(w_plasmawavedrop1))
			return;
	}

	if (self.wfiretime)
	{
		self.weaponframe = floor((time - self.wfiretime) * 10 + 1);
		if (self.weaponframe >= 3)
			self.weaponframe = self.wfiretime = 0;
	}
	else
		self.weaponframe = 0;

	havoc_shotanimupdate(self.weaponframe);
};

void() w_plasmawaveprecache =
{
	precache_model("progs/v_dpshot.mdl");
	precache_model("progs/s_bubble.spr");
	precache_model("progs/plasmashot.spr32");
	precache_sound("weapons/rocket1i.wav");
	//precache_sound("plasma/plasma.wav");
	precache_sound("plasma/plasexpl.wav");
};

void() w_plasmawavesetup = {wset("plasmawave", IT_CELLS, Inventory_Quantity(self, "cells"), VWEP_LIGHTNING, "progs/v_dplight.mdl");};
float(float request) setupweapon_plasmawave = {return weapongeneric("plasmawave", Inventory_Quantity(self, "cells") >= 1, request, w_plasmawavesetup, w_plasmawave, w_plasmawaveraise1, "Plasma Wave Cannon", 0, 1500, 200, w_plasmawaveprecache);};

void() w_plasmawaveraise1 = {wraise(3, w_plasmawaveraise2, 0.1);};
void() w_plasmawaveraise2 = {self.wburst = 4;wraise(7, w_plasmawave, 0.1);};

void() w_plasmawavedrop1 = {wdrop(3, w_plasmawavedrop2, 0.1);};
void() w_plasmawavedrop2 = {wdropped(4, 0.1);};
