
.entity grapple;

void() grappleflythink;

void() grapplereturnthink =
{
	self.nextthink = time;
	self.velocity = normalize(self.owner.origin - self.origin) * 1500;
	self.flags = self.flags - (self.flags & FL_ONGROUND);
	traceline(self.origin, self.owner.origin + '0 0 16', TRUE, self);
	if (trace_fraction < 1)
		self.cnt = 0;
	if (vlen(self.origin - (self.owner.origin + '0 0 16')) < 30 || time > self.cnt)
	{
		if (self.owner.grapple == self)
			self.owner.grapple = world;
		remove(self);
	}
};

void() grapplereturn =
{
	self.think = grapplereturnthink;
	self.nextthink = time;
	self.cnt = time + 4;
	sound(self, CHAN_BODY, "weapons/bounce2.wav", 1, ATTN_NORM);
	self.movetype = MOVETYPE_FLY;
	grapplereturnthink();
};

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_Grapple =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " was grappled by ";
		deathstring3 = attacker.netname;
		deathstring4 = "";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

void() grapplepull =
{
	self.nextthink = time; // as often as possible
	if (time > self.cnt2)
	{
		self.cnt2 = time + 0.1;
		if (self.owner.items & IT_QUAD)
			T_Damage(self.enemy, self, self.owner, 20, 20, "GRAPPLE", DT_CUT, self.origin, '0 0 0', Obituary_Grapple);
		else
			T_Damage(self.enemy, self, self.owner, 5, 5, "GRAPPLE", DT_CUT, self.origin, '0 0 0', Obituary_Grapple);
	}
	if (self.owner.items & IT_QUAD)
		self.effects = self.effects | EF_BLUE;
	else
		self.effects = self.effects - (self.effects & EF_BLUE);
	if (self.enemy.solid == SOLID_NOT || self.owner.deadflag || self.owner.button5 == 0)
	//if (self.enemy.solid == SOLID_NOT || self.owner.deadflag || (self.owner.button0 == 0 && self.owner.activeweapon == IT_WEAPON10 && self.owner.switchweapon == IT_WEAPON10))
	{
		grapplereturn();
		return;
	}
	if (self.enemy.solid == SOLID_BSP) // pull owner to wall
	{
		setorigin(self, self.dest + self.enemy.origin);
		self.owner.velocity = normalize(self.origin - (self.owner.origin + '0 0 16')) * 500;
		self.owner.flags = self.owner.flags - (self.owner.flags & FL_ONGROUND);
		if (vlen(self.origin - (self.owner.origin + '0 0 16')) < 30)
			self.owner.velocity = normalize(self.origin - (self.owner.origin + '0 0 16')) * 200;
	}
	else // pull owner to object
	{
		setorigin(self, (self.enemy.absmin + self.enemy.absmax) * 0.5);
		//self.enemy.velocity = normalize(self.owner.origin - self.origin) * 600;
		//self.enemy.flags = self.enemy.flags - (self.enemy.flags & FL_ONGROUND);
		self.owner.velocity = normalize(self.origin - (self.owner.origin + '0 0 16')) * 500;
		self.owner.flags = self.owner.flags - (self.owner.flags & FL_ONGROUND);
		if (vlen(self.origin - (self.owner.origin + '0 0 16')) < 30)
			self.owner.velocity = normalize(self.origin - (self.owner.origin + '0 0 16')) * 200;
	}
	if (vlen(self.origin - (self.owner.origin + '0 0 16')) < 30)
	{
		if (self.dmg != 0)
			sound(self, CHAN_BODY, "weapons/chain3.wav", 1, ATTN_NORM);
		self.dmg = 0;
	}
	else
	{
		if (self.dmg != 1)
			sound(self, CHAN_BODY, "weapons/chain2.wav", 1, ATTN_NORM);
		self.dmg = 1;
	}
};

void() grappleflycontinue =
{
	self.nextthink = time + 0.05;
	self.velocity = self.dest;
	self.think = grappleflythink;
};

void() grappleflytouch =
{
	local   float   p;
	p = pointcontents(self.origin);
	if (p == CONTENT_SKY || p == CONTENT_LAVA)
	{
		grapplereturn();
		return;
	}
	self.enemy = other;
	if (self.enemy.solid != SOLID_SLIDEBOX)
		sound(self, CHAN_WEAPON, "player/axhit2.wav", 1, ATTN_NORM);
//	if (self.enemy != world)
//		self.enemy.axhitme = TRUE;
	if (self.owner.items & IT_QUAD)
		T_Damage(self.enemy, self, self.owner, 240, 240, "GRAPPLEIMPACT", DT_CUT, self.origin, '0 0 0', Obituary_Grapple);
	else
		T_Damage(self.enemy, self, self.owner, 60, 60, "GRAPPLEIMPACT", DT_CUT, self.origin, '0 0 0', Obituary_Grapple);
	if (self.enemy.solid == SOLID_NOT) // gibbed, keep going
	{
		self.dest = self.velocity;
		self.think = grappleflycontinue;
		return;
	}
	if (self.enemy.solid == SOLID_BSP) // wall/door/whatever
		self.dest = self.origin - self.enemy.origin;
	else
		self.dest = '0 0 8';
	sound(self, CHAN_BODY, "weapons/chain2.wav", 1, ATTN_NORM);
	self.movetype = MOVETYPE_NONE;
	self.velocity = '0 0 0';
	self.touch = SUB_Null;
	self.enemy = other;
	self.think = grapplepull;
	grapplepull();
};

void() grappleflythink =
{
	self.nextthink = time + 0.05;
	traceline(self.owner.origin + '0 0 16', self.origin, TRUE, self);
	if (trace_fraction < 1 || time > self.cnt || !self.owner.button5)
	//if (trace_fraction < 1 || time > self.cnt || !self.owner.button0)
		grapplereturn();
};

void() grapplebit_think =
{
	if (self.owner.modelindex == 0)
	{
		remove(self);
		return;
	}
	if (self.owner.owner.modelindex == 0)
	{
		remove(self);
		return;
	}
	self.nextthink = time;
	setorigin(self, self.owner.owner.origin + self.count * (self.owner.origin - self.owner.owner.origin));
};

void(entity own, vector org, vector dir) FireGrapple =
{
	local entity grapplebolt, bit;
	local float c;
	w_muzzleflash(org, 3);
	own.grapple = grapplebolt = spawn();
	grapplebolt.classname = "grapple";
	grapplebolt.owner = own;
	grapplebolt.movetype = MOVETYPE_FLYMISSILE;
	grapplebolt.solid = SOLID_BBOX;
	grapplebolt.touch = grappleflytouch;
	setorigin(grapplebolt, org);
	setmodel(grapplebolt, "progs/star.mdl");
	setsize(grapplebolt, '0 0 0', '0 0 0');
	grapplebolt.angles = vectoangles(dir);
	grapplebolt.velocity = dir * 1500;
	grapplebolt.think = grappleflythink;
	grapplebolt.nextthink = time;
	grapplebolt.cnt = time + 3;
	sound(grapplebolt, CHAN_BODY, "weapons/chain1.wav", 1, ATTN_NORM);
	c = 0;
	while (c < 1)
	{
		c = c + 0.25;
		if (c >= 1)
			break;
		bit = spawn();
		bit.owner = grapplebolt;
		bit.think = grapplebit_think;
		bit.nextthink = time;
		bit.count = c;
		setmodel(bit, "progs/bit.mdl");
	}
};

void() W_GrappleFireCode =
{
	W_Hostile();
	sound(self, CHAN_WEAPON, "weapons/sgun1.wav", 1, ATTN_NORM);
	self.wfiretime = time;
	w_muzzleflash(shotorg, 1);
	FireGrapple(self, shotorg, shotdir);
};

void() grapple_precache =
{
	precache_model("progs/star.mdl");
	precache_model("progs/bit.mdl");
	precache_sound("weapons/sgun1.wav");
	precache_sound("player/axhit2.wav");
	precache_sound("weapons/chain1.wav");
	precache_sound("weapons/chain2.wav");
	precache_sound("weapons/chain3.wav");
	precache_sound("weapons/bounce2.wav");
};

void() w_frame_grapple =
{
	if (self.button5) // fire
	if (!self.grapple)
	if (W_ShotsToFire(0.5))
		W_GrappleFireCode();
};

/*
void() w_grappledrop1;
void() w_grappledrop2;
void() w_grappleraise1;
void() w_grappleraise2;
void() w_grapple =
{
	if (widle(w_grappledrop1))
		return;

	if (self.button0) // fire
	{
		if (!self.grapple)
		if (W_ShotsToFire(0.5))
			W_GrappleFireCode();
	}
	// else if (self.button3)
		// FIXME: add chainsaw

	if (self.wfiretime)
	{
		self.weaponframe = (time - self.wfiretime) * 10 + 1;
		if (self.weaponframe >= 7)
			self.weaponframe = self.wfiretime = 0;
	}
	else
		self.weaponframe = 0;

	havoc_shotanimupdate(self.weaponframe);
};

void() w_grappleprecache =
{
	precache_model("progs/v_dpshot.mdl");
	precache_model("progs/star.mdl");
	precache_sound("weapons/sgun1.wav");
	precache_sound("player/axhit2.wav");
	precache_sound("weapons/chain1.wav");
	precache_sound("weapons/chain2.wav");
	precache_sound("weapons/chain3.wav");
	precache_sound("weapons/bounce2.wav");
};

void() w_grapplesetup = {wset("grapple", 0, 0, VWEP_GENERIC, "progs/v_dpshot.mdl");};
float(float request) setupweapon_grapple = {return weapongeneric("grapple", TRUE, request, w_grapplesetup, w_grapple, w_grappleraise1, "Grapple", 0, 500, 50, w_grappleprecache);};

void() w_grappleraise1 = {wraise(8, w_grappleraise2, 0.1);};
void() w_grappleraise2 = {wraise(7, w_grapple, 0.1);};

void() w_grappledrop1 = {wdrop(7, w_grappledrop2, 0.1);};
void() w_grappledrop2 = {wdropped(8, 0.1);};
*/
