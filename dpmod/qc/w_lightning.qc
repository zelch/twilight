
void(entity targ, entity attacker, string dmsg, float dtype) Obituary_Lightning =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " was sizzled by ";
		deathstring3 = attacker.netname;
		deathstring4 = "";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_LightningExplode =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " was destroyed by ";
		deathstring3 = attacker.netname;
		deathstring4 = "'s lightning gun explosion";
	}
	else if (dtype == DTYPE_SUICIDE)
	{
		deathstring1 = targ.netname;
		deathstring2 = " blow dries his hair in the water";
		deathstring3 = "";
		deathstring4 = "";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_LightningSuperBeam =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " was shocked by ";
		deathstring3 = attacker.netname;
		deathstring4 = "'s super lightning";
	}
	else if (dtype == DTYPE_SUICIDE)
	{
		deathstring1 = targ.netname;
		deathstring2 = " forgot to run from the super lightning";
		deathstring3 = "";
		deathstring4 = "";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_LightningSuperBeamDirectHit =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " was incinerated by ";
		deathstring3 = attacker.netname;
		deathstring4 = "'s super lightning";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

.entity lightningchain;
.float lightningsolidbackup;
.vector lightninghitpoint;
vector(entity inflictor, entity attacker, vector start, vector end, float hdamage, float bdamage, string dmsg, float dtype, void(entity targ2, entity attacker2, string dmsg2, float dtype2) obitfunc) W_BeamDamage =
{
	local entity lightningchainhead, e;
	local float c;
	local vector force;
	force = (normalize(end - start) + '0 0 0.25') * 2 * bdamage;

	// find entities in the beam
	c = 0;
	lightningchainhead = world;
	// need to change self to SOLID_BBOX to do weapon traces (able to hit a corpse)
	self.lightningsolidbackup = self.solid;
	self.solid = SOLID_BBOX;
	while (c < 10)
	{
		c = c + 1;
		traceline(start, end, FALSE, self);
		if (trace_fraction == 1)
			break;
		if (trace_ent.solid == SOLID_BSP)
			break;
		// make entity non-solid so the beam can continue
		trace_ent.lightningsolidbackup = trace_ent.solid;
		trace_ent.solid = SOLID_NOT;
		trace_ent.lightninghitpoint = trace_endpos;
		// add entity to chain
		trace_ent.lightningchain = lightningchainhead;
		lightningchainhead = trace_ent;
	}
	// restore their .solid
	self.solid = self.lightningsolidbackup;
	e = lightningchainhead;
	while (e != world)
	{
		e.solid = e.lightningsolidbackup;
		e = e.lightningchain;
	}
	end = trace_endpos;

	// now damage them
	e = lightningchainhead;
	while (e != world)
	{
		T_Damage(e, inflictor, attacker, hdamage, bdamage, dmsg, dtype, trace_endpos, force, obitfunc);
		e = e.lightningchain;
	}
	return end;
};

void(float cells) W_LightningFireCode =
{
	if (cells > self.ammo_cells)
		cells = self.ammo_cells;
	self.wfiretime = time;
	self.currentammo = self.ammo_cells = self.ammo_cells - cells;
	self.wframe = self.wframe + 1;
	if (self.wframe >= 3)
		self.wframe = 1;
	W_BeamDamage(self, self, shotorg, shotorg + shotdir * 100000, cells * 30 * damagescale, cells * 15 * damagescale, "LIGHTNING", DT_LIGHTNING, Obituary_Lightning);

	traceline(shotorg, shotorg + shotdir * 100000, TRUE, self);
	te_lightning2(self, shotorg, trace_endpos);
};

void() w_lightningdrop1;
void() w_lightningdrop2;
void() w_lightningraise1;
void() w_lightningraise2;
.float oldbutton0;
void() w_lightning =
{
	if (widle(w_lightningdrop1))
		return;

	if (self.button0)
	{
		if (self.ammo_cells > 0)
		{
			if (!self.oldbutton0)
				sound(self, CHAN_AUTO, "weapons/lstart.wav", 1, ATTN_NORM);
			if (time >= self.wfiretime + 0.1)
			{
				self.wfiretime = time;
				W_Hostile();
				sound(self, CHAN_WEAPON, "weapons/lhit.wav", 1, ATTN_NORM);
			}
			self.wload = W_ShotsToFire(1/20);
			if (self.wload > 0)
				W_LightningFireCode(self.wload / 2);
		}
	}
	/*
	else if (self.button3)
	{
		//if (self.button3)
		//if (self.ammo_rockets >= 1)
		//	W_GenericSlowFireCode("weapons/grenade.wav", 0.5, W_SuperNailgunMineFireCode);
	}
	*/
	self.oldbutton0 = self.button0;

	if ((time - self.wfiretime) < 0.15)
		self.weaponframe = self.wframe;
	else
		self.weaponframe = 0;

	havoc_lightanimupdate(self.weaponframe);
};

void() weapon8_precache =
{
	precache_model("progs/v_dplight.mdl");
	precache_sound("weapons/lhit.wav");
	precache_sound("weapons/lstart.wav");
};

void() w_lightningraise1 = {wraise(6, w_lightningraise2, 0.1);};
void() w_lightningraise2 = {wraise( 5, w_lightning, 0.1);};

void() w_lightningdrop1 = {wdrop( 5, w_lightningdrop2, 0.1);};
void() w_lightningdrop2 = {wdropped(6, 0.1);};

float() w_lightningrating = {return genericweaponrating(0, 1000, 300);};
void() w_lightningsetup = {wset(IT_WEAPON8, IT_CELLS, self.ammo_cells, VWEP_LIGHTNING, "progs/v_dplight.mdl");};
float(float request) setweapon8 = {return weapongeneric(IT_WEAPON8, self.ammo_cells >= 1, request, w_lightningsetup, w_lightning, w_lightningraise1, w_directaim, w_lightningrating, "Thunderbolt");};
