
.entity domteam;

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_PlasmaTurret =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " was blasted by a plasma turret owned by ";
		deathstring3 = attacker.netname;
		deathstring4 = "";
		if (targ.bodyhealth < 1)
			deathstring2 = " was obliterated by a plasma turret owned by ";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

void() superdomination_turretgun_muzzleflash_think =
{
	self.nextthink = time;
	self.frame = (time - self.cnt) * 20;
	if (self.frame >= 5)
		remove(self);
};

float SUPERDOMINATION_POINTENERGYRATE = 100;
float SUPERDOMINATION_POINTENERGYCAP = 100;
float SUPERDOMINATION_POINTTURRETS = 1;
float PLASMATURRET_VELOCITY = 5000;
float PLASMATURRET_DAMAGE = 9;
float PLASMATURRET_FORCE = 0;
float PLASMATURRET_RADIUS = 100;
float PLASMATURRET_REFIRE = 0.1;
float PLASMATURRET_AMMO = 1;
float PLASMATURRET_RELOADCOST = 10;
float PLASMATURRET_TIMECOST = 0;
float PLASMATURRET_CONSTRUCTIONCOST = 50;
float PLASMATURRET_HEALTH = 600;

.float oldbutton0;
void() superdomination_turretgun_think =
{
	local entity head, best;
	local float rating, bestrating, minturn, maxturn;
	local vector targetorigin, v, v2, desiredangles, change;
	self.nextthink = time;
	if (!self.goalentity.takedamage)
	{
		remove(self);
		return;
	}
	//bprint("a");
	if (time > self.cnt)
	{
		//bprint("b");
		self.cnt = time + 0.2;
		best = world;
		bestrating = 1000000;
		//head = findchainfloat(havocattack, TRUE);
		head = findradius(self.origin, PLASMATURRET_VELOCITY * 2);
		while (head)
		{
			if (head.havocattack)
			if (head.takedamage == DAMAGE_AIM)
			if (head.domteam != self.domteam)
			{
				rating = 0 * head.health + 0.25 * vlen(head.origin + (head.mins + head.maxs) * 0.5 - self.origin);
				//bprint(" ");
				//bprintfloat(rating);
				if (bestrating > rating)
				{
					traceline(self.origin, head.origin + (head.mins + head.maxs) * 0.5, FALSE, self);
					if (trace_ent == head || trace_fraction == 1)
					{
						//bprint("!");
						bestrating = rating;
						best = head;
					}
				}
			}
			head = head.chain;
		}
		//bprint(" ");
		if (self.enemy != best)
		//if (best)
		{
			self.enemy = best;
			self.dest1 = self.enemy.origin;
			self.dest2 = self.enemy.origin;
			self.cnt1 = time;
			self.cnt2 = time;
		}
		//bprint(etos(self.enemy));
		//bprint(" ");
	}
	//bprint("c");
	if (self.enemy.takedamage != DAMAGE_AIM) //!self.enemy.takedamage || (self.enemy.health <= 0 && self.enemy.bodyhealth <= 0))
		self.enemy = world;
	self.oldbutton0 = self.button0;
	self.button0 = FALSE;
	if (self.enemy)
	{
		//bprint("d");
		if (self.enemy.origin != self.dest1)
		{
			self.dest2 = self.dest1;
			self.cnt2 = self.cnt1;
			self.dest1 = self.enemy.origin;
			self.cnt1 = time;
		}
		if (self.cnt1 != self.cnt2)
			targetorigin = self.dest1 + (self.dest1 - self.dest2) * ((vlen(self.enemy.origin + (self.enemy.mins + self.enemy.maxs) * 0.5 - self.origin) / PLASMATURRET_VELOCITY) / (self.cnt1 - self.cnt2));
		else
			targetorigin = self.dest1;
		{
			//targetorigin = self.dest1 + (self.dest1 - self.dest2) * ((vlen(self.enemy.origin + (self.enemy.mins + self.enemy.maxs) * 0.5 - self.origin) / PLASMATURRET_VELOCITY) / (self.cnt1 - self.cnt2));
			tracebox(self.enemy.origin, self.enemy.mins, self.enemy.maxs, targetorigin, FALSE, self.enemy);
			targetorigin = trace_endpos + (self.enemy.mins + self.enemy.maxs) * 0.5;
			traceline(self.origin, targetorigin, FALSE, self);
			if (trace_fraction == 1 || trace_ent == self.enemy)
			{
				//bprint("e");
				desiredangles = vectoangles(targetorigin - self.origin);
				//bprintvector(self.angles);
				//bprint(":");
				//bprintvector(desiredangles);
				change = desiredangles - self.angles;
				if (change_x < -180) change_x = change_x + 360;if (change_x > 180) change_x = change_x - 360;
				if (change_y < -180) change_y = change_y + 360;if (change_y > 180) change_y = change_y - 360;
				if (change_z < -180) change_z = change_z + 360;if (change_z > 180) change_z = change_z - 360;
				//bprint(":");
				//bprintvector(change);
				maxturn = 200 * frametime;
				minturn = 0 - maxturn;
				self.angles_x = self.angles_x + bound(minturn, change_x, maxturn);
				self.angles_y = self.angles_y + bound(minturn, change_y, maxturn);
				self.angles_z = self.angles_z + bound(minturn, change_z, maxturn);
				change = desiredangles - self.angles;
				if (change_x < -180) change_x = change_x + 360;if (change_x > 180) change_x = change_x - 360;
				if (change_y < -180) change_y = change_y + 360;if (change_y > 180) change_y = change_y - 360;
				if (change_z < -180) change_z = change_z + 360;if (change_z > 180) change_z = change_z - 360;
				//bprint(":");
				//bprintvector(desiredangles - self.angles);
				self.button0 = vlen(change) < 5;
			}
		}
	}
	if (self.domteam.ammo_cells >= PLASMATURRET_TIMECOST)
	{
		self.domteam.ammo_cells = self.domteam.ammo_cells - PLASMATURRET_TIMECOST;
		if (self.ammo_cells < 1)
		if (self.domteam.ammo_cells >= PLASMATURRET_RELOADCOST)
		{
			self.ammo_cells = self.ammo_cells + PLASMATURRET_AMMO;
			self.domteam.ammo_cells = self.domteam.ammo_cells - PLASMATURRET_RELOADCOST;
		}
	}
	//bprint("f");
	if (self.button0)
	if (self.attack_finished <= time)
	if (self.ammo_cells >= 1)
	{
		//bprint("g");
		self.ammo_cells = self.ammo_cells - 1;
		self.show_hostile = time + 1;
		fightdone = time + 1; // delay stuff until fighting is over
		if (!self.oldbutton0)
		{
			self.attack_finished = time;
			self.lefty = 0;
		}
		self.lefty = self.lefty + 1;
		if (self.lefty >= 5)
			self.lefty = 1;
		self.attack_finished = self.attack_finished + PLASMATURRET_REFIRE;
		makevectors(self.angles_x * '-1 0 0' + self.angles_y * '0 1 0' + self.angles_z * '0 0 1');
		if (self.lefty == 1)
			v = self.origin + v_forward * 28 + v_right * 9 + v_up * 14;
		else if (self.lefty == 2)
			v = self.origin + v_forward * 28 + v_right * -9 + v_up * 6;
		else if (self.lefty == 3)
			v = self.origin + v_forward * 28 + v_right * -9 + v_up * 14;
		else
			v = self.origin + v_forward * 28 + v_right * 9 + v_up * 6;
		newmis = spawn();
		setmodel(newmis, "progs/pflash2.mdl");
		setorigin(newmis, v);
		newmis.effects = EF_ADDITIVE;
		newmis.angles = self.angles + random() * '0 0 360';
		newmis.cnt = time;
		newmis.think = superdomination_turretgun_muzzleflash_think;
		newmis.nextthink = time;
		v2 = normalize(targetorigin - v);
		//v2 = v2 + randomvec() * 0.0125;
		sound(self, CHAN_AUTO, "plasma/plasma.wav", 1, ATTN_NORM);
		FirePlasma(self.goalentity, self.goalentity, v, v2 * PLASMATURRET_VELOCITY, PLASMATURRET_DAMAGE, PLASMATURRET_FORCE, PLASMATURRET_RADIUS, "PLASMATURRET", Obituary_PlasmaTurret);
	}
	if (time < self.attack_finished)
		self.frame = self.lefty;
	else
		self.frame = 0;
	//bprint("\n");
};

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_PlasmaTurretExplode =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " was caught in the explosion of ";
		deathstring3 = attacker.netname;
		deathstring4 = "'s plasma turret";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

void() superdomination_turretbase_die =
{
	self.takedamage = DAMAGE_NO;
	self.solid = SOLID_NOT;
	setorigin(self, self.origin);
	T_RadiusDamage(self, self.owner, 150, 200, 200, world, "PLASMATURRETEXPLODE", DT_EXPLOSION, Obituary_PlasmaTurretExplode);
	BecomeExplosion(self, '0 0 0', FALSE);
};

void() superdomination_turretbase_think =
{
	self.nextthink = time;
	if (self.realowner.domteam != self.domteam)
		self.th_die();
};

float(vector org) superdomination_validateturretlocation =
{
	traceline(org + '-16 -16 -24', org + '-16 -16 -44', FALSE, world);if (trace_fraction == 1) return FALSE;
	traceline(org + '16 -16 -24', org + '16 -16 -44', FALSE, world);if (trace_fraction == 1) return FALSE;
	traceline(org + '-16 16 -24', org + '-16 16 -44', FALSE, world);if (trace_fraction == 1) return FALSE;
	traceline(org + '16 16 -24', org + '16 16 -44', FALSE, world);if (trace_fraction == 1) return FALSE;
	traceline(org + '0 0 -24', org + '0 0 -44', FALSE, world);if (trace_fraction == 1) return FALSE;
	return TRUE;
};

void() superdomination_createturret =
{
	local vector org;
	local entity turretbase, head;
	local float turrets, points;
	makevectors(self.v_angle_y * '0 1 0');
	tracebox(self.origin, '-16 -16 -24', '16 16 8', self.origin + '0 0 40', FALSE, world);
	tracebox(trace_endpos, '-16 -16 -24', '16 16 8', trace_endpos + v_forward * 60, FALSE, world);
	tracebox(trace_endpos, '-16 -16 -24', '16 16 8', trace_endpos + '0 0 -60', FALSE, world);
	org = trace_endpos;
	if (!superdomination_validateturretlocation(org))
	{
		if (self.flags & FL_CLIENT)
			centerprint(self, "unsuitable location, try another spot.\n");
		return;
	}
	turrets = 0;
	head = findchain(classname, "turretbase");
	while (head)
	{
		if (head.domteam == self.domteam)
			turrets = turrets + 1;
		head = head.chain;
	}
	points = 0;
	head = findchain(classname, "dom_controlpoint");
	while (head)
	{
		if (head.goalentity == self.domteam)
			points = points + 1;
		head = head.chain;
	}
	if (turrets >= points * SUPERDOMINATION_POINTTURRETS)
	{
		if (self.flags & FL_CLIENT)
			centerprint(self, "You can only have 3 turrets per control point.\n");
		return;
	}
	/*
	if (self.domteam.ammo_cells < PLASMATURRET_CONSTRUCTIONCOST)
	{
		if (self.flags & FL_CLIENT)
			centerprint(self, "your team can't afford a plasma turret, wait for more energy.\n");
		return;
	}
	*/
	//self.domteam.ammo_cells = self.domteam.ammo_cells - PLASMATURRET_CONSTRUCTIONCOST;
	turretbase = newmis = spawn();
	newmis.classname = "turretbase";
	newmis.health = PLASMATURRET_HEALTH;
	newmis.takedamage = DAMAGE_AIM;
	newmis.havocattack = TRUE;
	newmis.dangerrating = 200;
	newmis.realowner = self;
	newmis.team = self.domteam.team;
	newmis.domteam = self.domteam;
	newmis.think = superdomination_turretbase_think;
	newmis.nextthink = time;
	newmis.th_die = superdomination_turretbase_die;
	newmis.solid = SOLID_SLIDEBOX;
	newmis.movetype = MOVETYPE_NONE;
	setmodel(newmis, "progs/turbase.mdl");
	setsize(newmis, '-16 -16 -24', '16 16 8');
	setorigin(newmis, org);

	newmis = spawn();
	newmis.classname = "turretgun";
	newmis.think = superdomination_turretgun_think;
	newmis.nextthink = time;
	newmis.goalentity = turretbase;
	newmis.realowner = self;
	newmis.domteam = self.domteam;
	newmis.team = self.domteam.team;
	setmodel(newmis, "progs/turgun.mdl");
	setsize(newmis, '-16 -16 -24', '16 16 8');
	setorigin(newmis, org);
};

void() superdomination_impulses =
{
	if (deathmatch != DM_SUPERDOMINATION)
		return;
	if (self.deadflag)
		return;
	if (self.impulse == 110)
		superdomination_createturret();
};

void() superdomination_startframe =
{
	local entity head, head2, teams, controlpoints, players, winner;
	local float numcontrolpoints;
	if (deathmatch != DM_SUPERDOMINATION)
		return;
	teams = findchain(classname, "dom_team");
	controlpoints = findchain(classname, "dom_controlpoint");
	if (teams == world || controlpoints == world)
		return;
	players = findchain(classname, "player");
	winner = world;
	head = teams;
	while (head)
	{
		head.frags = 0;
		head = head.chain;
	}
	numcontrolpoints = 0;
	head = controlpoints;
	while (head)
	{
		if (head.goalentity)
			head.goalentity.frags = head.goalentity.frags + 1;
		numcontrolpoints = numcontrolpoints + 1;
		head = head.chain;
	}
	head = teams;
	while (head)
	{
		head.ammo_cells = min(head.ammo_cells + head.frags * SUPERDOMINATION_POINTENERGYRATE * frametime, head.frags * SUPERDOMINATION_POINTENERGYCAP);
		if (head.frags == numcontrolpoints)
			winner = head;
		head = head.chain;
	}
	head = players;
	while (head)
	{
		head.domteam = world;
		head2 = teams;
		while (head2)
		{
			if (head2.team == head.team)
			{
				head.domteam = head2;
				break;
			}
			head2 = head2.chain;
		}
		head = head.chain;
	}
	if (time >= 5)
	if (winner)
	if (winner.netname != "")
	if (!gameover)
		NextLevel ();
};

void() superdomination_endframe =
{
	local entity head;
	if (deathmatch != DM_SUPERDOMINATION)
		return;
	head = findchain(classname, "player");
	while (head)
	{
		head.frags = head.domteam.frags;
		head.currentammo = head.domteam.ammo_cells;
		head = head.chain;
	}
};

void() superdomination_precache =
{
	if (cvar("deathmatch") == DM_DOMINATION || cvar("deathmatch") == DM_SUPERDOMINATION)
		dom_init();
	if (cvar("deathmatch") != DM_SUPERDOMINATION)
		return;
	precache_model("progs/turbase.mdl");
	precache_model("progs/turgun.mdl");
	precache_model("progs/pflash.mdl");
	precache_model("progs/pflash2.mdl");
};


