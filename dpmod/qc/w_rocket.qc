
void(entity targ, entity attacker, string dmsg, float dtype) Obituary_Rocket =
{
	local float r;
	//bprint("targ bodyhealth ");
	//bprintfloat(targ.bodyhealth);
	//bprint("\n");
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
		else if (targ.bodyhealth < -250 && dmsg != "ROCKET1")
		{
			deathstring2 = " met a rocket storm from ";
			deathstring4 = "";
		}
		else if (targ.bodyhealth < -150)
		{
			if (random() < 0.5)
			{
				deathstring2 = " was mistified by ";
				if (dmsg == "ROCKET1")
					deathstring4 = "'s rocket";
				else
					deathstring4 = "'s rockets";
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
	self.wfiretime = time;
	self.flags = self.flags - (self.flags & FL_ONGROUND);
	if (self.wload >= 3)
	{
		self.velocity = self.velocity - shotdir * 150;
		self.currentammo = self.ammo_rockets = self.ammo_rockets - 3;
		w_muzzleflash(shotorg, 4);
		LaunchMissile(shotorg, shotdir                , self, 120, 120, "ROCKET3", Obituary_Rocket);
		LaunchMissile(shotorg, shotdir + v_right * 0.1, self, 120, 120, "ROCKET3", Obituary_Rocket);
		LaunchMissile(shotorg, shotdir - v_right * 0.1, self, 120, 120, "ROCKET3", Obituary_Rocket);
	}
	else if (self.wload >= 2)
	{
		self.velocity = self.velocity - shotdir * 100;
		self.currentammo = self.ammo_rockets = self.ammo_rockets - 2;
		w_muzzleflash(shotorg, 4);
		LaunchMissile(shotorg, shotdir + v_right * 0.05, self, 120, 120, "ROCKET2", Obituary_Rocket);
		LaunchMissile(shotorg, shotdir - v_right * 0.05, self, 120, 120, "ROCKET2", Obituary_Rocket);
	}
	else
	{
		self.velocity = self.velocity - shotdir * 50;
		self.currentammo = self.ammo_rockets = self.ammo_rockets - 1;
		w_muzzleflash(shotorg, 4);
		LaunchMissile(shotorg, shotdir                 , self, 120, 120, "ROCKET1", Obituary_Rocket);
	}

	self.wload = 0;
};

void() w_rocketdrop1;
void() w_rocketdrop2;
void() w_rocketraise1;
void() w_rocketraise2;
void() w_rocket =
{
	if (widle(w_rocketdrop1))
		return;

	if (self.wload > self.ammo_rockets)
		self.wload = self.ammo_rockets;

	if (time >= self.attack_finished)
	{
		if (self.wload < 1)
		{
			self.wload = 1;
			self.attack_finished = time + 0.4;
		}
		else if (self.button0)
			W_GenericSlowFireCode("weapons/sgun1.wav", 0.2, W_RocketFireCode);
		else
		{
			if (self.button3)
			if (self.wload < 3)
			if (self.wload < self.ammo_rockets)
			{
				self.wload = self.wload + 1;
				self.attack_finished = time + 0.4;
				sound(self, CHAN_WEAPON, "weapons/bsgload.wav", 1, ATTN_STATIC);
			}
		}
	}

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
