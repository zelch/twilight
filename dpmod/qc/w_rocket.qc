
void(entity targ, entity attacker, string dmsg, float dtype) Obituary_Rocket =
{
	local float r;
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring3 = attacker.netname;
		if (targ.bodyhealth < -200 && targ.ping >= 400 && attacker.ping < 200)
		{
			// LordHavoc: Thanks to BramBo for this suggestion
			deathstring2 = " found out online gaming with ";
			deathstring4 = " was a big mistake";
 		}
		else if (targ.bodyhealth < -150)
		{
			if (random() < 0.5)
			{
				deathstring2 = " was mistified by ";
				deathstring4 = "'s rocket";
			}
			else
			{
				deathstring2 = " became one with the walls thanks to ";
				deathstring4 = "";
			}
		}
		else if (targ.bodyhealth < 1)
		{
			r = random() * 3;
			if (r < 1)
			{
				deathstring2 = " was torn asunder by ";
				deathstring4 = "";
			}
			else if (r < 2)
			{
				deathstring2 = " was gibbed by ";
				deathstring4 = "";
			}
			else
			{
				deathstring2 = " became extra chunky thanks to ";
				deathstring4 = "";
			}
		}
		else
		{
			r = random() * 4;
			if (r < 1)
			{
				deathstring2 = " was sent flying by ";
				deathstring4 = "";
			}
			else if (r < 2)
			{
				deathstring2 = " got bounced around by ";
				deathstring4 = "";
			}
			else if (r < 3)
			{
				deathstring2 = " was clobbered by ";
				deathstring4 = "";
			}
			else
			{
				deathstring2 = " was fragged by ";
				deathstring4 = "";
			}
		}
	}
	else if (dtype == DTYPE_SUICIDE)
	{
		deathstring1 = targ.netname;
		if (targ.bodyhealth < 1)
		{
			r = random() * 3;
			if (r < 1)
				deathstring2 = " became a fine red mist";
			else if (r < 2)
				deathstring2 = " tripped and fell... all over";
			else
				deathstring2 = " becomes extra chunky";
		}
		else
			deathstring2 = " blew himself up";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
}

void() W_RocketFireCode =
{
	if (self.ammo_rockets < 1/* || self.wload < 1*/) {stopfiring = TRUE;return;}
	fightdone = time + 1; // delay stuff until fighting is over
	self.wfiretime = time;
//	self.punchangle_x = -2;

	//self.velocity = self.velocity + '0 0 40' - shotdir * 50;self.flags = self.flags - (self.flags & FL_ONGROUND);

//	self.wload = self.wload - 1;
	self.currentammo = self.ammo_rockets = self.ammo_rockets - 1;
	w_muzzleflash(shotorg, 4);
	//LaunchMissile(shotorg, shotdir, self, 200, 250, "ROCKET", Obituary_Rocket);
	//LaunchMissile(shotorg, shotdir, self, 100, 250, "ROCKET", Obituary_Rocket);
	LaunchMissile(shotorg, shotdir, self, 120, 120, "ROCKET", Obituary_Rocket);

	if (self.ammo_rockets < 1 || self.wload < 1) {stopfiring = TRUE;return;}
};

/*
void() W_RocketTripleFireCode =
{
	if (self.ammo_rockets < 3) {stopfiring = TRUE;return;}
	fightdone = time + 1; // delay stuff until fighting is over
	self.wfiretime = time;
//	self.punchangle_x = -2;

	//self.velocity = self.velocity + '0 0 40' - shotdir * 50;self.flags = self.flags - (self.flags & FL_ONGROUND);

	self.currentammo = self.ammo_rockets = self.ammo_rockets - 3;
	w_muzzleflash(shotorg, 4);
	//LaunchMissile(shotorg, shotdir, self, 200, 250, "ROCKET", Obituary_Rocket);
	//LaunchMissile(shotorg, shotdir, self, 100, 250, "ROCKET", Obituary_Rocket);
	self.velocity = self.velocity - v_right * 80;
	LaunchMissile(shotorg, shotdir, self, 120, 120, "ROCKET", Obituary_Rocket);
	self.velocity = self.velocity + v_right * 80;
	LaunchMissile(shotorg, shotdir, self, 120, 120, "ROCKET", Obituary_Rocket);
	self.velocity = self.velocity + v_right * 80;
	LaunchMissile(shotorg, shotdir, self, 120, 120, "ROCKET", Obituary_Rocket);
	self.velocity = self.velocity - v_right * 80;

	if (self.ammo_rockets < 3) {stopfiring = TRUE;return;}
};
*/

void() w_rocketdrop1;
void() w_rocketdrop2;
void() w_rocketraise1;
void() w_rocketraise2;
void() w_rocket =
{
	if (widle(w_rocketdrop1))
		return;

	/*
	if (self.wload < 1)
	if (self.ammo_rockets >= 1)
	if (time > self.attack_finished)
	if (!self.button0)
	if (!self.button3)
	{
		self.wload = 3;
		self.attack_finished = time + 0.6;
		sound(self, CHAN_WEAPON, "weapons/bsgload.wav", 1, ATTN_STATIC);
	}
	*/

//	if (self.wload > self.ammo_rockets)
//		self.wload = self.ammo_rockets;

	if (self.button0)
	{
		if (self.ammo_rockets >= 1)
		//if (self.wload >= 1)
			W_GenericFireCode("weapons/sgun1.wav", 0.5, W_RocketFireCode);
	}
	/*
	else if (self.button3)
	{
		if (self.ammo_rockets >= 3)
		//if (self.wload >= 1)
			W_GenericFireCode("weapons/sgun1.wav", 1.0, W_RocketTripleFireCode);
	}
	*/
	else
		self.notfiring = TRUE;

	if (self.wfiretime)
	{
		self.weaponframe = floor((time - self.wfiretime) * 10 + 1);
		if (self.weaponframe >= 7)
		{
			self.weaponframe = 0;
			self.wfiretime = 0;
		}
	}
	else
		self.weaponframe = 0;
	havoc_rockanimupdate(self.weaponframe);
};

void() weapon7_precache =
{
	precache_model("progs/missile.mdl");
	precache_model("progs/v_dprock2.mdl");
	precache_sound("weapons/sgun1.wav");
};

float() w_rocketrating = {return genericweaponrating(200, 1000, 240);};
void() w_rocketsetup = {wset(IT_WEAPON7, IT_ROCKETS, self.ammo_rockets, VWEP_ROCKET_LAUNCHER, "progs/v_dprock2.mdl");};
float(float request) setweapon7 = {return weapongeneric(IT_WEAPON7, self.ammo_rockets >= 1, request, w_rocketsetup, w_rocket, w_rocketraise1, w_rocketaim, w_rocketrating, "Rocket Launcher");};

void() w_rocketraise1 = {wraise(8, w_rocketraise2, 0.1);};
void() w_rocketraise2 = {wraise(7, w_rocket, 0.1);};

void() w_rocketdrop1 = {wdrop(7, w_rocketdrop2, 0.1);};
void() w_rocketdrop2 = {wdropped(8, 0.1);};
