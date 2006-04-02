float maxspeed;
float havocbot_bestrating;
entity havocbot_bestgoal;

void() havocbot_markroutes;
void(entity e) havocbot_routetogoal;
void(entity e, float f) havocbot_routerating;
//float(entity e) routedist;
//entity() choosebestroute;

void() havocbot_goalrating_start =
{
	havocbot_bestrating = -1;
	havocbot_bestgoal = world;
	havocbot_markroutes();
};

void() havocbot_goalrating_end =
{
	havocbot_routetogoal(havocbot_bestgoal);
};

void(float ratingscale, vector org, float sradius) havocbot_goalrating_items =
{
	local entity head;
	local float t;
	head = findchainfloat(havocpickup, TRUE);
	while (head)
	{
		if (head.solid) // must be possible to pick up (respawning items don't count)
		if (vlen(head.origin - org) < sradius)
		{
			// debugging
			//if (!head.pickupevalfunc || head.model == "")
			//	eprint(head);
			// get the value of the item
			t = head.pickupevalfunc(self, head) * 0.0001;
			if (t > 0)
			{
				havocbot_routerating(head, t * ratingscale);
			}
		}
		head = head.chain;
	}
};

void(float ratingscale, vector org, float sradius) havocbot_goalrating_monsters =
{
	local entity head;
	head = findchainfloat(ismonster, TRUE);
	while (head)
	{
		if (head.health > 0)
		if (vlen(head.origin - org) < sradius)
			havocbot_routerating(head, ratingscale);
		head = head.chain;
	}
};

void(float ratingscale, vector org, float sradius) havocbot_goalrating_enemyplayers =
{
	local entity head;
	local float t, noteam;
	ratingscale = ratingscale * 1200;
	noteam = self.team == 0 || teamplay == 0;
	head = findchain(classname, "player");
	while (head)
	{
		if (head.health > 0)
		if (head.team != self.team || noteam)
		if (vlen(head.origin - org) < sradius)
		{
			t = head.frags + 25;
			if (t < 1)
				t = 1;
			t = t / (head.health + head.armortype * head.armorvalue);
			if (t > 0)
				havocbot_routerating(head, t * ratingscale);
		}
		head = head.chain;
	}
};

void(float ratingscale, vector org, float sradius) havocbot_goalrating_ctf_carrieritems =
{
	local entity head;
	local float t;
	head = findchainfloat(havocpickup, TRUE);
	while (head)
	{
		// look for health and armor only
		if (head.solid) // must be possible to pick up (respawning items don't count)
		if (head.pickupevalfunc == item_health_pickupeval || head.pickupevalfunc == item_armor_pickupeval)
		if (vlen(head.origin - org) < sradius)
		{
			// debugging
			//if (!head.pickupevalfunc || head.model == "")
			//	eprint(head);
			// get the value of the item
			t = head.pickupevalfunc(self, head) * 0.0001;
			if (t > 0)
				havocbot_routerating(head, t * ratingscale);
		}
		head = head.chain;
	}
};

void(float ratingscale) havocbot_goalrating_ctf_ourflag =
{
	local entity head;
	if (self.team == 5) // red
		head = find(world, classname, "item_flag_team1"); // red flag
	else // blue
		head = find(world, classname, "item_flag_team2"); // blue flag
	havocbot_routerating(head, ratingscale);
};

void(float ratingscale) havocbot_goalrating_ctf_enemyflag =
{
	local entity head;
	if (self.team == 5) // red
		head = find(world, classname, "item_flag_team2"); // blue flag
	else // blue
		head = find(world, classname, "item_flag_team1"); // red flag
	havocbot_routerating(head, ratingscale);
};

void(float ratingscale) havocbot_goalrating_ctf_ourstolenflag =
{
	local entity head;
	if (self.team == 5) // red
		head = find(world, classname, "item_flag_team1"); // red flag
	else // blue
		head = find(world, classname, "item_flag_team2"); // blue flag
	if (head.cnt != FLAG_BASE)
		havocbot_routerating(head, ratingscale);
};

void(float ratingscale) havocbot_goalrating_ctf_droppedflags =
{
	local entity redflag, blueflag;

	redflag = find(world, classname, "item_flag_team1");
	blueflag = find(world, classname, "item_flag_team2");

	if (redflag == world)
		error("havocbot: item_flag_team1 missing\n");
	if (blueflag == world)
		error("havocbot: item_flag_team2 missing\n");

	if (redflag.cnt != FLAG_BASE) // red flag is carried or out in the field
		havocbot_routerating(redflag, ratingscale);
	if (blueflag.cnt != FLAG_BASE) // blue flag is carried or out in the field
		havocbot_routerating(blueflag, ratingscale);
};

.float havocbot_role_timeout;
.float goaltime;
.void() havocbot_role;

void() havocbot_role_coop;
void() havocbot_role_dm;
void() havocbot_role_elimination;
void() havocbot_role_ctf_rogue;
void() havocbot_role_ctf_carrier;
void() havocbot_role_ctf_offense;
void() havocbot_role_ctf_middle;
void() havocbot_role_ctf_defense;

void() havocbot_chooserole_coop =
{
	self.havocbot_role = havocbot_role_coop;
};

void() havocbot_chooserole_dm =
{
	self.havocbot_role = havocbot_role_dm;
};

void() havocbot_chooserole_elimination =
{
	self.havocbot_role = havocbot_role_elimination;
};

void() havocbot_chooserole_ctf =
{
	local float r;
	if (self.team == 13)
		self.havocbot_role = havocbot_role_ctf_rogue;
	else
	{
		r = random() * 3;
		if (r < 0)
			self.havocbot_role = havocbot_role_ctf_offense;
		else if (r < 1)
			self.havocbot_role = havocbot_role_ctf_middle;
		else
			self.havocbot_role = havocbot_role_ctf_defense;
	}
};

void() havocbot_chooserole =
{
	havocbot_routetogoal(world);
	self.goaltime = -1;
	self.havocbot_role = SUB_Null;
	if (deathmatch == DM_NONE)
		havocbot_chooserole_coop();
	if (deathmatch == DM_ELIM)
		havocbot_chooserole_elimination();
	if (deathmatch == DM_CTF_2TEAM || deathmatch == DM_CTF_3TEAM || deathmatch == DM_MCTF_2TEAM)
		havocbot_chooserole_ctf();
	// assume anything else is deathmatch
	if (self.havocbot_role == SUB_Null)
		havocbot_chooserole_dm();
};

/*
coop:
go to best items
go to monsters
*/

void() havocbot_role_coop =
{
	if (self.goaltime < time)
	{
		self.goaltime = time + 0.5;
		havocbot_goalrating_start();
		havocbot_goalrating_items(10000, self.origin, 10000);
		havocbot_goalrating_monsters(3000, self.origin, 3000);
		havocbot_goalrating_end();
	}
};

/*
DM:
go to best items
*/

void() havocbot_role_dm =
{
	if (self.goaltime < time)
	{
		self.goaltime = time + 0.5;
		havocbot_goalrating_start();
		havocbot_goalrating_items(10000, self.origin, 10000);
		havocbot_goalrating_monsters(3000, self.origin, 3000);
		//havocbot_goalrating_enemyplayers(2000, self.origin, 2000);
		havocbot_goalrating_end();
	}
};

/*
Elimination: (always teamplay)
go to enemy players (is this rule a good choice?)
*/

void() havocbot_role_elimination =
{
	if (self.goaltime < time)
	{
		self.goaltime = time + 0.5;
		havocbot_goalrating_start();
		havocbot_goalrating_enemyplayers(100000, self.origin, 100000);
		havocbot_goalrating_end();
	}
};

/*
CTF: (always teamplay)
*/

/*
role rogue: (third team, available only in DM_CTF_3TEAM mode)
pick up items and dropped flags (with big rating boost to dropped flags)
*/

void() havocbot_role_ctf_rogue =
{
	if (self.goaltime < time)
	{
		self.goaltime = time + 0.5;
		havocbot_goalrating_start();
		havocbot_goalrating_ctf_droppedflags(5000);
		//havocbot_goalrating_enemyplayers(3000, self.origin, 3000);
		havocbot_goalrating_items(10000, self.origin, 10000);
		havocbot_goalrating_end();
	}
}

/*
role flag carrier:
pick up armor and health
go to our flag spot
*/

void() havocbot_role_ctf_carrier =
{
	if (self.flagcarried == world)
	{
		bprint("changing role to middle\n");
		self.havocbot_role = havocbot_role_ctf_middle;
		self.havocbot_role_timeout = 0;
		return;
	}
	if (self.goaltime < time)
	{
		self.goaltime = time + 0.5;
		havocbot_goalrating_start();
		havocbot_goalrating_ctf_ourflag(5000);
		havocbot_goalrating_ctf_carrieritems(1000, self.origin, 1000);
		havocbot_goalrating_end();
	}
};

/*
role offense:
pick up armor and health
if rockets < 25 || health < 100, change role to middle
if carrying flag, change role to flag carrier
if our flag taken, change role to interceptor
(60-90 second timer) change role to middle
go to enemy flag
*/

void() havocbot_role_ctf_offense =
{
	//local entity f;
	if (self.flagcarried)
	{
		bprint("changing role to carrier\n");
		self.havocbot_role = havocbot_role_ctf_carrier;
		self.havocbot_role_timeout = 0;
		return;
	}
	/*
	// check our flag
	if (self.team == 5) // red
		f = find(world, classname, "item_flag_team1");
	else // blue
		f = find(world, classname, "item_flag_team2");
	if (f.cnt != FLAG_BASE && canreach(f))
	{
		bprint("changing role to interceptor\n");
		self.havocbot_role = havocbot_role_ctf_interceptor;
		self.havocbot_role_timeout = 0;
		return;
	}
	*/
	if (!self.havocbot_role_timeout)
		self.havocbot_role_timeout = time + random() * 30 + 60;
	if (Inventory_Quantity(self, "rockets") < 15 || time > self.havocbot_role_timeout)
	{
		bprint("changing role to middle\n");
		self.havocbot_role = havocbot_role_ctf_middle;
		self.havocbot_role_timeout = 0;
		return;
	}
	if (self.goaltime < time)
	{
		self.goaltime = time + 0.5;
		havocbot_goalrating_start();
		havocbot_goalrating_ctf_ourstolenflag(5000);
		havocbot_goalrating_ctf_enemyflag(3000);
		havocbot_goalrating_items(10000, self.origin, 10000);
		havocbot_goalrating_end();
	}
};

/*
role middle:
pick up items
if carrying flag, change role to flag carrier
if our flag taken, change role to interceptor
if see flag (of either team) follow it (this has many implications)
(10-20 second timer) change role to defense or offense
go to least recently visited area
*/

void() havocbot_role_ctf_middle =
{
	if (self.flagcarried)
	{
		bprint("changing role to carrier\n");
		self.havocbot_role = havocbot_role_ctf_carrier;
		self.havocbot_role_timeout = 0;
		return;
	}
	/*
	// check our flag
	if (self.team == 5) // red
		f = find(world, classname, "item_flag_team1");
	else // blue
		f = find(world, classname, "item_flag_team2");
	if (f.cnt != FLAG_BASE && canreach(f))
	{
		bprint("changing role to interceptor\n");
		self.havocbot_role = havocbot_role_ctf_interceptor;
		self.havocbot_role_timeout = 0;
		return;
	}
	*/
	if (!self.havocbot_role_timeout)
		self.havocbot_role_timeout = time + random() * 10 + 10;
	if (time > self.havocbot_role_timeout)
	if (Inventory_Quantity(self, "rockets") >= 25)
	{
		if (random() < 0.5)
		{
			bprint("changing role to offense\n");
			self.havocbot_role = havocbot_role_ctf_offense;
		}
		else
		{
			bprint("changing role to defense\n");
			self.havocbot_role = havocbot_role_ctf_defense;
		}
		self.havocbot_role_timeout = 0;
		return;
	}

	if (self.goaltime < time)
	{
		self.goaltime = time + 0.5;
		havocbot_goalrating_start();
		havocbot_goalrating_ctf_ourstolenflag(5000);
		havocbot_goalrating_ctf_droppedflags(3000);
		//havocbot_goalrating_enemyplayers(1000, self.origin, 1000);
		havocbot_goalrating_items(10000, self.origin, 10000);
		havocbot_goalrating_end();
	}
};

/*
role defense:
if rockets < 25 || health < 100, change role to middle
if carrying flag, change role to flag carrier
if our flag taken, change role to interceptor
(30-50 second timer) change role to middle
move to nearest unclaimed defense spot
*/

void() havocbot_role_ctf_defense =
{
	local entity f;
	if (self.flagcarried)
	{
		bprint("changing role to carrier\n");
		self.havocbot_role = havocbot_role_ctf_carrier;
		self.havocbot_role_timeout = 0;
		return;
	}
	/*
	// check our flag
	if (self.team == 5) // red
		f = find(world, classname, "item_flag_team1");
	else // blue
		f = find(world, classname, "item_flag_team2");
	if (f.cnt != FLAG_BASE && canreach(f))
	{
		bprint("changing role to interceptor\n");
		self.havocbot_role = havocbot_role_ctf_interceptor;
		self.havocbot_role_timeout = 0;
		return;
	}
	*/
	if (!self.havocbot_role_timeout)
		self.havocbot_role_timeout = time + random() * 20 + 30;
	if (Inventory_Quantity(self, "rockets") < 15 || time > self.havocbot_role_timeout)
	{
		bprint("changing role to middle\n");
		self.havocbot_role = havocbot_role_ctf_middle;
		self.havocbot_role_timeout = 0;
		return;
	}
	if (self.goaltime < time)
	{
		self.goaltime = time + 0.5;
		havocbot_goalrating_start();
		havocbot_goalrating_ctf_ourstolenflag(20000);
		havocbot_goalrating_items(10000, f.origin, 10000);
		havocbot_goalrating_end();
	}
	/*
	// FIXME: place info_ctf_defensepoint entities in DP CTF maps and use them
	// change position occasionally
	if (time > self.goaltime || self.goalentity.classname != "info_ctf_defensepoint")
	{
		self.goaltime = time + random() * 45 + 15;
		self.goalentity = world;
		head = findchain(classname, "info_ctf_defensepoint");
		while (head)
		{
			if (time > head.count)
			{
				self.goalentity = head;
				head.chain = world;
			}
			head = head.chain;
		}
		// if there are no defensepoints defined, switch to middle
		if (self.goalentity == world)
		{
			bprint("changing role to middle\n");
			self.havocbot_role = havocbot_role_ctf_middle;
			self.havocbot_role_timeout = 0;
			return;
		}
	}
	// keep anyone else from taking this spot
	if (self.goalentity != world)
		self.goalentity.count = time + 0.5;
	*/
};
