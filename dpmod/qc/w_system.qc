
.float wload;

void(vector muzzleorg, float kickback) w_muzzleflash =
{
	local float image;
	image = floor(random() * 9.7);
	if (kickback >= 3)
		effect(muzzleorg, "progs/muzzleflash.spr32", image + 10, 1, 20);
	else
		effect(muzzleorg, "progs/muzzleflash.spr32", image, 1, 30);
	//te_smallflash(muzzleorg);
	self.effects = self.effects | EF_MUZZLEFLASH;
	//if (self.flags & FL_CLIENT)
	//	stuffcmd(self, "bf\n");
	self.punchangle = (randomvec() + '-1 0 0') * kickback;
	self.punchangle_z = 0; // don't want roll
};

/*
vector(vector srcvec, vector dstvec) w_axeaim =
{
	if (vlen(dstvec - srcvec) > 80)
		return '0 0 0';
	traceline(srcvec, dstvec, FALSE, self);
	if (trace_fraction < 1 && trace_ent != self.enemy)
		return '0 0 0';
	return dstvec - srcvec;
};
*/

vector(vector srcvec, vector dstvec, vector dstvel, float shotspeed) w_directaim =
{
	dstvec = dstvec + dstvel * (vlen(dstvec - srcvec) / shotspeed);
	traceline(srcvec, dstvec, FALSE, self);
	if (trace_fraction < 1 && trace_ent != self.enemy)
		return '0 0 0';
	return dstvec - srcvec;
};

vector(vector srcvec, vector dstvec, vector dstvel, float shotspeed) w_rocketaim =
{
	dstvec = dstvec + dstvel * (vlen(dstvec - srcvec) / shotspeed);
	if (vlen(dstvec - srcvec) < 150)
		return '0 0 0';
	traceline(srcvec, dstvec, FALSE, self);
	if (trace_fraction < 1 && trace_ent != self.enemy)
		return '0 0 0';
	return dstvec - srcvec;
};

vector(vector srcvec, vector dstvec, vector dstvel, float shotspeed) w_grenadeaim =
{
	local   vector  v;
	dstvec = dstvec + dstvel * (vlen(dstvec - srcvec) / shotspeed);
	if (vlen(dstvec - srcvec) < 150)
		return '0 0 0';
	traceline(srcvec, dstvec, FALSE, self);
	if (trace_fraction < 1 && trace_ent != self.enemy)
		return '0 0 0';
	if (!findtrajectorywithleading(srcvec, '0 0 0', '0 0 0', self.enemy, 600, 5, 0, self))
		return '0 0 0';
	return findtrajectory_velocity;
};

float(entity e) w_shouldattack =
{
	if (!e.takedamage)
		return FALSE;
	if (e.deadflag)
		return FALSE;
	if (e.classname == "player")
	if (coop)
		return FALSE;
	if (e.team == self.team)
	if (self.team != 0)
	if (teamplay != 0)
		return FALSE;
	if (e == self)
		return FALSE;
	return TRUE;
};

.float painintensity;
.entity aimtarg;
.float aimlatency;
.vector aimtargorigin;
.vector aimtargvelocity;
.float mousesticktime;
float(vector v, float maxfiredeviation) w_aimdir =
{
	local float dist;
	local vector desiredang, diffang;
	// get the desired angles to aim at
	desiredang = vectoangles(v);
	desiredang_z = self.v_angle_z;

	// pain throws off aim
	if (self.painintensity)
	{
		// shake from pain
		desiredang = desiredang + randomvec() * self.painintensity * 0.2;
	}

	// calculate turn angles
	diffang = desiredang - self.v_angle;
	while (diffang_y < -180)
		diffang_y = diffang_y + 360;
	while (diffang_y >  180)
		diffang_y = diffang_y - 360;

	// jitter tracking
	dist = vlen(diffang);
	diffang = randomvec() * (dist * 0.15 * (3.5 - skill));

	// simulate slight 'stickyness' of mouse on small moves
	if (vlen(diffang) < 0.1)
	{
		if (time < self.mousesticktime)
			return vlen(diffang) < maxfiredeviation;
		else if (random() < 0.5)
		{
			self.mousesticktime = time + 0.2;
			return vlen(diffang) < maxfiredeviation;
		}
	}

	// turn
	self.v_angle = self.v_angle + diffang * (5 * frametime);

	// calculate turn angles again
	diffang = desiredang - self.v_angle;
	while (diffang_y < -180)
		diffang_y = diffang_y + 360;
	while (diffang_y >  180)
		diffang_y = diffang_y - 360;

	// decide whether to fire this time
	return vlen(diffang) < maxfiredeviation;
};

vector(vector targorigin, vector targvelocity, float shotspeed, float shotdelay) w_shotlead =
{
	return targorigin + targvelocity * (shotdelay + vlen(targorigin - shotorg) / shotspeed);
};

float(float shotspeed, float maxshottime) w_directattackaim =
{
	local vector v;
	v = w_shotlead(self.aimtargorigin, self.aimtargvelocity, shotspeed, self.aimlatency);
	if (vlen(v - shotorg) < maxshottime * shotspeed)
		return FALSE;
	traceline(shotorg, v, FALSE, self);
	if (trace_fraction == 1)
		return w_aimdir(v - shotorg, 0.1);
	if (w_shouldattack(trace_ent))
		return w_aimdir(v - shotorg, 0.1);
	return FALSE;
};

float(float shotspeed, float maxshottime) w_grenadeattackaim =
{
	if (!findtrajectorywithleading(shotorg, '0 0 0', '0 0 0', self.aimtarg, shotspeed, maxshottime, 0, self))
		return FALSE;
	return w_aimdir(findtrajectory_velocity, 0.1);
};

void() W_Hostile =
{
	// wake up monsters
	self.show_hostile = time + 1;
	weaponwakeup(self.origin, self);
	fightdone = time + 1; // delay stuff until fighting is over
	SuperDamageSound();
};

.float firing;
.float oldfiring;
float(float nextshotdelay) W_ShotsToFire =
{
	local float shotcount;

	self.firing = TRUE;

	// check if still busy with the previous shot
	if (time < self.attack_finished)
		return 0;

	// if not firing yet, set base time to avoid double shots
	if (!self.oldfiring)
		self.attack_finished = time;

	shotcount = 0;
	while (time >= self.attack_finished)
	{
		self.attack_finished = self.attack_finished + nextshotdelay;
		shotcount = shotcount + 1;
	}
	return shotcount;
};

// linked list of weapon classes
// note: looped double linked list (can seek forward/backward)
entity w_chain;
// links for weapon classes list
.entity w_next;
.entity w_prev;

float WANIMTYPE_SHOTGUN = 1;
float WANIMTYPE_NAILGUN = 2;
float WANIMTYPE_ROCKET = 3;
float WANIMTYPE_LIGHTNING = 4;

void(float wimpulse, string printname, float(float request) func, string itemname, float vwepmode, string modelname, float ammoitembit, float minrange, float preferredrange, float baserating, float animtype) registerweapon =
{
	newmis = spawn();
	newmis.classname = "weaponclass";
	newmis.impulse = wimpulse;
	newmis.netname = printname;
	newmis.w_func = func;
	newmis.w_item = itemname;
	newmis.cnt = vwepmode;
	newmis.weaponmodel = modelname;
	newmis.items = ammoitembit;
	newmis.count = minrange;
	newmis.count2 = preferredrange;
	newmis.count3 = baserating;
	newmis.lefty = animtype;
	if (w_chain == world)
	{
		newmis.w_prev = newmis;
		newmis.w_next = newmis;
		w_chain = newmis;
	}
	else
	{
		newmis.w_next = w_chain;
		newmis.w_prev = newmis.w_next.w_prev;
		newmis.w_prev.w_next = newmis;
		newmis.w_next.w_prev = newmis;
	}
};

void() wanimate =
{
	local float t, f;
	t = time;
	if (t > self.wanim_endtime - 0.001)
		t = self.wanim_endtime - 0.001;
	t = self.wanim_startframe + self.wanim_deltaframe * (t - self.wanim_starttime);
	if (self.wanim_deltaframe > 0)
		t = floor(t);
	else
		t = ceil(t);
	if (self.weaponframe != t)
	{
		//bprintfloat(self.weaponframe);bprint(" -> ");bprintfloat(t);bprint("\n");
		self.weaponframe = t;
		self.weaponclass.w_func(WR_ANIMATIONFRAME);
	}
	f = 0;
	if (self.wanim_id != WANIM_RAISE)
	if (self.wanim_id != WANIM_LOWER)
	if (self.weaponframe >= 0)
		f = self.weaponframe;
	if (self.weaponclass.lefty == WANIMTYPE_SHOTGUN)
		havoc_shotanimupdate(f);
	else if (self.weaponclass.lefty == WANIMTYPE_NAILGUN)
		havoc_nailanimupdate(f);
	else if (self.weaponclass.lefty == WANIMTYPE_ROCKET)
		havoc_rockanimupdate(f);
	else if (self.weaponclass.lefty == WANIMTYPE_LIGHTNING)
		havoc_lightanimupdate(f);
};

void(float animid, float startframe, float deltaframe, float deltatime) wsetanim =
{
	self.wanim_id = animid;
	self.wanim_starttime = time;
	self.wanim_endtime = time + deltatime;
	self.wanim_startframe = startframe;
	if (deltatime > 0)
		self.wanim_deltaframe = deltaframe / deltatime;
	else
		self.wanim_deltaframe = 0;
	wanimate();
};

void(entity wclass, float instantswitch) wsetweapon =
{
	self.switchweaponclass = wclass;
	self.weaponclass = wclass;
	self.items = (self.items - (self.items & (IT_SHELLS | IT_NAILS | IT_ROCKETS | IT_CELLS))) | self.weaponclass.items;
	self.weaponmodel = self.weaponclass.weaponmodel;
	self.weaponframe = -1;
	if (instantswitch)
		self.weaponclass.w_func(WR_INSTANTSETUP);
	else
		self.weaponclass.w_func(WR_SETUP);
	// let the animations settle down before returning
	self.weaponclass.w_func(WR_FRAME);
	self.weaponclass.w_func(WR_FRAME);
};

void() wswitch =
{
	wsetweapon(self.switchweaponclass, FALSE);
};

float(entity wclass) WeaponClassToNumber =
{
	local float number;
	number = 0;
	while (wclass != w_chain)
	{
		wclass = wclass.w_prev;
		number = number + 1;
	}
	return number;
};

entity(float number) NumberToWeaponClass =
{
	local entity wclass;
	wclass = w_chain;
	while (number > 0)
	{
		wclass = wclass.w_next;
		number = number - 1;
	}
	return wclass;
};


void(float matchimpulse, float backward) W_Cycle =
{
	local entity e;
	if (self.switchweaponclass == world)
		self.switchweaponclass = w_chain;
	e = self.switchweaponclass;
	/*
	bprint("matchimpulse = ");
	bprintfloat(matchimpulse);
	bprint(" backward = ");
	bprintfloat(backward);
	bprint(" switchweaponclass = ");
	bprint(e.w_item);
	bprint("\n");
	*/
	while (1)
	{
		if (backward)
			e = e.w_prev;
		else
			e = e.w_next;
		if (e == self.switchweaponclass)
			return;
		//bprint(e.w_item);
		if (!matchimpulse || e.impulse == matchimpulse)
		{
			//bprint(" impulse");
			if (Inventory_Quantity(self, e.w_item))
			{
				//bprint(" quantity");
				if (e.w_func(WR_HASAMMO))
				{
					//bprint(" hasammo");
					self.switchweaponclass = e;
					return;
				}
			}
		}
		//bprint("\n");
	}
};

void() W_ChangeWeapon =
{
	if (self.impulse >= 201 && self.impulse < 220)
		self.impulse = self.impulse - 200;
	//bprintfloat(self.impulse);
	//bprint(" changeweapon\n");
	W_Cycle(self.impulse, FALSE);
	self.impulse = 0;
};

void() CycleWeaponCommand =
{
	W_Cycle(0, FALSE);
	self.impulse = 0;
};

void() CycleWeaponReverseCommand =
{
	W_Cycle(0, TRUE);
	self.impulse = 0;
};

entity(entity targ) BestWeaponForTarget =
{
	local float rating, bestrating, weaponrange;
	local entity e, best;
	weaponrange = vlen(targ.origin - self.origin);
	bestrating = 0;
	best = world;
	e = w_chain;
	do
	{
		if (Inventory_Quantity(e, e.w_item))
		{
			if (weaponrange < e.count) // minimum range
				rating = 0;
			else if (weaponrange <= e.count2) // preferred range
				rating = e.count3; // rating at >= minimum range && <= preferred range
			else
				rating = e.count3 * e.count2 * e.count2 / (weaponrange * weaponrange);
			if (bestrating < rating)
			{
				bestrating = rating;
				best = e;
			}
		}
		e = e.chain;
	}
	while(e != w_chain);
	return best;
};

entity(float dangerous) W_BestWeaponClass =
{
	local entity wclass, best;
	local float bestrating, rating;
	best = w_chain;
	wclass = w_chain.w_next;
	while (wclass != w_chain)
	{
		if (wclass.count3 > best.count3) // baserating
		if (wclass.count == 0 || dangerous) // minimum range for use
		if (Inventory_Quantity(self, wclass.w_item))
		if (wclass.w_func(WR_HASAMMO))
			best = wclass;
		wclass = wclass.w_next;
	}
	return best;
};

/*
============
CheatCommand
============
*/
void() CheatCommand =
{
	local entity wclass;
	if (self.health < 1)
		return;

	Inventory_SetQuantity(self, "shells", AMMOMAX_SHELLS);
	Inventory_SetQuantity(self, "nails", AMMOMAX_NAILS);
	Inventory_SetQuantity(self, "rockets", AMMOMAX_ROCKETS);
	Inventory_SetQuantity(self, "cells", AMMOMAX_SHELLS);
	/*
	self.items = self.items
	 | IT_WEAPON1
	 | IT_WEAPON2
	 | IT_WEAPON3
	 | IT_WEAPON4
	 | IT_WEAPON5
	 | IT_WEAPON6
	 | IT_WEAPON7
	 | IT_WEAPON8
	 | IT_WEAPON9
	 | IT_WEAPON10
	// | IT_KEY1 | IT_KEY2
	;
	*/
	wclass = w_chain;
	do
	{
		Inventory_SetQuantity(self, wclass.w_item, 1);
		wclass = wclass.w_next;
	}
	while(wclass != w_chain);

	self.impulse = 0;
};

.float character_nextsave;
.float character_loaded;

.float seenhelp;
.float idealzoom;

/*
============
W_WeaponFrame

Called every frame so impulse events can be handled as well as possible
============
*/
.float notfiringcountdown;
void() w_frame_grapple;
void() W_WeaponFrame =
{
	local vector v;
	local float f;
	local string s;
	//local vector v, realvangle;

	updateammodisplay(self);

	if (time > self.seenhelp)
	{
		if (self.seenhelp == 0)
			self.seenhelp = time + 5;
		else
		{
			self.seenhelp = time + 9999999;
			if (self.flags & FL_CLIENT)
			{
				//            12345678901234567890123456789012345678
				sprint(self, "Lord Havoc's Dark Places\n");
				sprint(self, "be sure to type dphelp in console for very useful information\n");
				sprint(self, "http://icculus.org/twilight/darkplaces\n");
			}
		}
	}
	/*
	if (time > self.character_nextsave)
	{
		self.character_nextsave = time + 15;
		if (self.character_loaded)
			Character_Save();
		else
			Character_Load();
	}
	*/

	if (!self.solid) // observer
		return;

	if (self.deadflag >= DEAD_DYING) // dead
		return;

	if (nofire)
		self.button0 = self.button3 = self.button4 = self.button5 = self.button6 = self.button7 = self.button8 = 0;

	/*
	realvangle = self.v_angle;
	makevectors (self.v_angle);
	traceline(self.origin + self.view_ofs, self.origin + self.view_ofs + v_forward * 65536, FALSE, self);
	shotorg = self.origin + self.view_ofs + v_right * 6 - v_up * 6 + v_forward * 15;
	//shotorg = self.origin + '0 0 16' + v_forward * 15;
	shotdir = normalize(trace_endpos - shotorg);
	self.v_angle = vectoangles(shotdir);
	self.v_angle_z = realvangle_z;
	self.v_angle_x = 0 - self.v_angle_x;
	*/
	makevectors(self.v_angle + self.punchangle);
	shotorg = self.origin + self.view_ofs + v_right * 6 - v_up * 6 + v_forward * 15;
	shotdir = v_forward;

	/*
	// DP_QC_TRACE_MOVETYPE_HITMODEL test code
	traceline(shotorg, shotorg + shotdir * 1000, MOVE_NORMAL, self);
	if (trace_fraction < 1)
	if (trace_ent.solid == SOLID_SLIDEBOX)
	{
		sprint(self, "aiming at slidebox entity ");
		s = etos(trace_ent);
		sprint(self, s);
		sprint(self, " box");
		traceline(shotorg, shotorg + shotdir * 1000, MOVE_HITMODEL, self);
		if (trace_fraction < 1)
		if (trace_ent.solid == SOLID_SLIDEBOX)
			sprint(self, " model");
		sprint(self, \n");
	}
	*/

	self.idealzoom = 1;
	if (self.button4)
		self.idealzoom = 0.2;

	if (self.viewzoom == 0)
		self.viewzoom = 1;

	if (self.weaponclass == self.switchweaponclass)
	if (self.weaponclass.w_func)
	if (!self.weaponclass.w_func(WR_HASAMMO))
		self.switchweaponclass = W_BestWeaponClass(FALSE);

	w_frame_grapple();

	// weapon animation, firing, etc
	self.oldfiring = self.firing;
	self.firing = FALSE;
	//wanimate();
	if (self.weaponclass.w_func)
	{
		self.weaponclass.w_func(WR_FRAME);
		self.weaponclass.w_func(WR_FRAME);
		self.weaponclass.w_func(WR_FRAME);
	}
	//wanimate();

	if (self.viewzoom != self.idealzoom)
	{
		if (self.viewzoom > self.idealzoom)
		{
			self.viewzoom = self.viewzoom - frametime * 10;
			if (self.viewzoom < self.idealzoom)
				self.viewzoom = self.idealzoom;
		}
		else if (self.viewzoom < self.idealzoom)
		{
			self.viewzoom = self.viewzoom + frametime * 10;
			if (self.viewzoom > self.idealzoom)
				self.viewzoom = self.idealzoom;
		}
	}

	//self.v_angle = realvangle;

	if (cvar("temp1") & 4096)
	if (self.flags & FL_CLIENT)
	{
		v = self.velocity;
		v_z = 0;
		sprint(self, "vel ");
		s = ftos(self.velocity_x);
		sprint(self, s);
		sprint(self, " ");
		s = ftos(self.velocity_y);
		sprint(self, s);
		sprint(self, " speed ");
		f = vlen(v);
		s = ftos(f);
		sprint(self, s);
		sprint(self, " (");
		f = f * 100 / cvar("sv_maxspeed");
		f = floor(f);
		s = ftos(f);
		sprint(self, s);
		sprint(self, "%)\n");
	}
};

float PISTOL_NAIL = 30;
float PISTOL_NAILS = 1;
float PISTOL_EMPTY = 15; // damage pistol does when empty (0 = disable)
float PISTOL_REFIRE = 0.7;
float SHOTGUN_SHELL = 90;
float SHOTGUN_SHELLS = 1;
float SHOTGUN_REFIRE = 0.9;
float PLASMASHOTGUN_SHELL = 90;
float PLASMASHOTGUN_CELL = 30;
float PLASMASHOTGUN_CELLS = 2;
float PLASMASHOTGUN_RADIUS = 60;
float PLASMASHOTGUN_REFIRE = 0.9;
float DBSHOTGUN_SHELL = 90;
float DBSHOTGUN_SHELLS = 2;
float DBSHOTGUN_REFIRE = 1.6;
float NAILGUN_NAIL = 15;
float NAILGUN_NAILS = 1;
float NAILGUN_REFIRE = 0.1;
float SUPERNAILGUN_NAIL = 15;
float SUPERNAILGUN_NAILS = 1;
float SUPERNAILGUN_REFIRE = 0.05;
float GRENADELAUNCHER_ROCKET = 150;
float GRENADELAUNCHER_RADIUS = 120;
float GRENADELAUNCHER_REFIRE = 0.8;
float ROCKETLAUNCHER_SINGLE_ROCKET = 120;
float ROCKETLAUNCHER_SINGLE_RADIUS = 150;
float ROCKETLAUNCHER_SINGLE_REFIRE = 0.8;
float ROCKETLAUNCHER_TRIPLE_ROCKET = 120;
float ROCKETLAUNCHER_TRIPLE_RADIUS = 150;
float ROCKETLAUNCHER_TRIPLE_REFIRE = 0.8;
float THUNDERBOLT_CELL_HEALTH = 30;
float THUNDERBOLT_CELL_BODY = 15;
float THUNDERBOLT_CELLSPERSECOND = 10;
float PLASMARIFLE_NORMAL_CELL = 30;
float PLASMARIFLE_NORMAL_CELLS = 1;
float PLASMARIFLE_NORMAL_RADIUS = 50;
float PLASMARIFLE_SUPER_CELL = 30;
float PLASMARIFLE_SUPER_CELLS = 3;
float PLASMARIFLE_SUPER_RADIUS = 80;
float PLASMARIFLE_REFIRE = 0.1;
float PLASMAWAVE_SINGLE_CELL = 20;
float PLASMAWAVE_SINGLE_CELLS = 10;
float PLASMAWAVE_SINGLE_REFIRE = 0.6;
float PLASMAWAVE_SINGLE_BURNRADIUS = 120;
float PLASMAWAVE_WAVE_CELL = 20;
float PLASMAWAVE_WAVE_MAXCELLS = 50;
float PLASMAWAVE_WAVE_CELLSPERSHOT = 5;
float PLASMAWAVE_WAVE_MAXSHOTS = 10;
float PLASMAWAVE_WAVE_CHARGETIME = 0.5;
float PLASMAWAVE_WAVE_REFIRE = 1.1;
float PLASMAWAVE_WAVE_BURNRADIUS = 120;
float PLASMAWAVE_WAVE_SPREADANGLEPERSHOT = 6;
float LASERRIFLE_CELL = 45;
float LASERRIFLE_BURST = 3;
float LASERRIFLE_BURSTREFIRE = 0.1;
float LASERRIFLE_BETWEENBURSTREFIRE = 0.3;

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_Pistol =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " was gunned down by ";
		deathstring3 = attacker.netname;
		deathstring4 = "";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

float(float request) w_pistol =
{
	if (request == WR_REGISTER)
	{
		precache_model("progs/v_dpshot.mdl");
		precache_sound("weapons/rocket1i.wav");
		registerweapon(1, "Pistol", w_pistol, "pistol", VWEP_SHOTGUN, "progs/v_dpshot.mdl", IT_NAILS, 0, 4000, PISTOL_NAIL / PISTOL_REFIRE, WANIMTYPE_SHOTGUN);
		return TRUE;
	}
	if (request == WR_HASAMMO)
		return PISTOL_EMPTY > 0 || Inventory_Quantity(self, "nails") > 0;
	if (request == WR_SETUP)
	{
		wsetanim(WANIM_RAISE, 8, -2, 0.2);
		return TRUE;
	}
	if (request == WR_INSTANTSETUP)
	{
		wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
	wanimate();
	self.currentammo = Inventory_Quantity(self, "nails");
	if (self.aimtarg) // bot target
		self.button0 = w_directattackaim(10000, 1);
	if (self.wanim_id == WANIM_RAISE)
	{
		if (time >= self.wanim_endtime)
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (self.wanim_id == WANIM_LOWER)
	{
		if (time >= self.wanim_endtime)
			wswitch();
		return TRUE;
	}
	if (self.wanim_id == WANIM_READY)
	{
		if (self.switchweaponclass != self.weaponclass)
		{
			wsetanim(WANIM_LOWER, 7, 2, 0.2);
			return TRUE;
		}
		if (self.button0)
		if (Inventory_Quantity(self, "nails") > 0 || PISTOL_EMPTY > 0)
		{
			W_Hostile();
			sound(self, CHAN_WEAPON, "weapons/rocket1i.wav", 1, ATTN_NORM);
			w_muzzleflash(shotorg, 2);
			if (Inventory_Quantity(self, "nails") >= 1)
			{
				Inventory_AdjustQuantity(self, "nails", -1);
				FireBullets(self, self, 1, 1, PISTOL_NAIL, PISTOL_NAIL, 0, 0, shotdir * 10000, 0.025, "PISTOL", DT_NAIL, Obituary_Pistol);
				ejectcasing(shotorg + v_forward * -5, v_right * 150 + v_up * 50, 50, self.v_angle_x * '-1 0 0' + self.v_angle_y * '0 1 0', '0 250 0', 100, 0);
			}
			else
				FireBullets(self, self, 1, 1, PISTOL_EMPTY, PISTOL_EMPTY, 0, 0, shotdir * 10000, 0.025, "PISTOL", DT_NAIL, Obituary_Pistol);
			wsetanim(WANIM_FIRE1, 1, 6, PISTOL_REFIRE);
		}
		return TRUE;
	}
	if (self.wanim_id == WANIM_FIRE1)
	{
		if (time >= self.wanim_endtime)
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	return TRUE;
};

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_Shotgun =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " was another victim of ";
		deathstring3 = attacker.netname;
		deathstring4 = "'s hunting season";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

float(float request) w_shotgun =
{
	if (request == WR_REGISTER)
	{
		precache_model("progs/v_dpshot.mdl");
		precache_sound("weapons/shotgn2.wav");
		precache_sound("weapons/bsgnoammo.wav");
		precache_sound("weapons/bsgload.wav");
		registerweapon(2, "Shotgun", w_shotgun, "shotgun", VWEP_SHOTGUN, "progs/v_dpshot.mdl", IT_SHELLS, 0, 2000, SHOTGUN_SHELL / SHOTGUN_REFIRE, WANIMTYPE_SHOTGUN);
		return TRUE;
	}
	if (request == WR_HASAMMO)
		return Inventory_Quantity(self, "shells") > 0;
	if (request == WR_SETUP)
	{
		wsetanim(WANIM_RAISE, 8, -2, 0.2);
		return TRUE;
	}
	if (request == WR_INSTANTSETUP)
	{
		wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request == WR_ANIMATIONFRAME)
	{
		if (self.wanim_id == WANIM_FIRE1)
		{
			if (self.weaponframe == 3)
			{
				sound(self, CHAN_AUTO, "weapons/bsgload.wav", 1, ATTN_STATIC);
				ejectcasing(shotorg + v_forward * -5, v_right * 100 + v_up * 40, 30, self.v_angle_x * '-1 0 0' + self.v_angle_y * '0 1 0', '0 250 0', 100, 1);
			}
			if (self.weaponframe == 5)
				sound(self, CHAN_AUTO, "weapons/bsgload.wav", 1, ATTN_STATIC);
		}
	}
	if (request != WR_FRAME)
		return FALSE;
	wanimate();
	self.currentammo = Inventory_Quantity(self, "shells");
	if (self.aimtarg) // bot target
		self.button0 = w_directattackaim(6000, 1);
	if (self.wanim_id == WANIM_RAISE)
	{
		if (time >= self.wanim_endtime)
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (self.wanim_id == WANIM_LOWER)
	{
		if (time >= self.wanim_endtime)
			wswitch();
		return TRUE;
	}
	if (self.wanim_id == WANIM_READY)
	{
		if (self.switchweaponclass != self.weaponclass)
		{
			wsetanim(WANIM_LOWER, 7, 2, 0.2);
			return TRUE;
		}
		if (self.button0)
		if (Inventory_Quantity(self, "shells") > 0)
		{
			W_Hostile();
			sound(self, CHAN_WEAPON, "weapons/shotgn2.wav", 1, ATTN_NORM);
			Inventory_AdjustQuantity(self, "shells", -1);
			w_muzzleflash(shotorg, 2);
			FireBullets(self, self, 1, 5, SHOTGUN_SHELL * 0.1, SHOTGUN_SHELL * 0.1, 0, 0, shotdir * 6000, 0.05, "SHOTGUN", DT_SHOTGUN, Obituary_Shotgun);
			FireBullets(self, self, 0, 5, SHOTGUN_SHELL * 0.1, SHOTGUN_SHELL * 0.1, 0, 0, shotdir * 6000, 0.05, "SHOTGUN", DT_SHOTGUN, Obituary_Shotgun);
			wsetanim(WANIM_FIRE1, 1, 6, SHOTGUN_REFIRE);
		}
		return TRUE;
	}
	if (self.wanim_id == WANIM_FIRE1)
	{
		if (time >= self.wanim_endtime)
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	return TRUE;
};

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_PlasmaShotgun =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " was incinerated by ";
		deathstring3 = attacker.netname;
		deathstring4 = "'s plasma shotgun";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

float(float request) w_plasmashotgun =
{
	local float f;
	local vector v;
	if (request == WR_REGISTER)
	{
		precache_model("progs/v_dpshot.mdl");
		precache_sound("weapons/shotgn2.wav");
		precache_sound("weapons/bsgnoammo.wav");
		precache_sound("weapons/bsgload.wav");
		registerweapon(2, "Plasma Shotgun", w_plasmashotgun, "shotgun", VWEP_SHOTGUN, "progs/v_dpshot.mdl", IT_SHELLS, 0, 2000, (PLASMASHOTGUN_SHELL + PLASMASHOTGUN_CELL * PLASMASHOTGUN_CELLS) / PLASMASHOTGUN_REFIRE, WANIMTYPE_SHOTGUN);
		return TRUE;
	}
	if (request == WR_HASAMMO)
		return Inventory_Quantity(self, "shells") >= 1 && Inventory_Quantity(self, "cells") >= PLASMASHOTGUN_CELLS;
	if (request == WR_SETUP)
	{
		wsetanim(WANIM_RAISE, 8, -2, 0.2);
		return TRUE;
	}
	if (request == WR_INSTANTSETUP)
	{
		wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request == WR_ANIMATIONFRAME)
	{
		if (self.wanim_id == WANIM_FIRE1)
		{
			if (self.weaponframe == 3)
			{
				sound(self, CHAN_AUTO, "weapons/bsgload.wav", 1, ATTN_STATIC);
				ejectcasing(shotorg + v_forward * -5, v_right * 100 + v_up * 40, 30, self.v_angle_x * '-1 0 0' + self.v_angle_y * '0 1 0', '0 250 0', 100, 1);
			}
			if (self.weaponframe == 5)
				sound(self, CHAN_AUTO, "weapons/bsgload.wav", 1, ATTN_STATIC);
		}
	}
	if (request != WR_FRAME)
		return FALSE;
	wanimate();
	self.currentammo = Inventory_Quantity(self, "cells") / PLASMASHOTGUN_CELLS;
	f = Inventory_Quantity(self, "shells");
	if (self.currentammo > f)
		self.currentammo = f;
	if (self.aimtarg) // bot target
		self.button0 = w_directattackaim(10000, 1);
	if (self.wanim_id == WANIM_RAISE)
	{
		if (time >= self.wanim_endtime)
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (self.wanim_id == WANIM_LOWER)
	{
		if (time >= self.wanim_endtime)
			wswitch();
		return TRUE;
	}
	if (self.wanim_id == WANIM_READY)
	{
		if (self.switchweaponclass != self.weaponclass)
		{
			wsetanim(WANIM_LOWER, 7, 2, 0.2);
			return TRUE;
		}
		if (self.button0)
		if (Inventory_Quantity(self, "shells") >= 1)
		if (Inventory_Quantity(self, "cells") >= PLASMASHOTGUN_CELLS)
		{
			W_Hostile();
			sound(self, CHAN_WEAPON, "weapons/shotgn2.wav", 1, ATTN_NORM);
			Inventory_AdjustQuantity(self, "shells", -1);
			Inventory_AdjustQuantity(self, "cells", 0 - PLASMASHOTGUN_CELLS);
			w_muzzleflash(shotorg, 2);
			//FireBullets(self, self, 1, 5, PLASMASHOTGUN_SHELL * 0.1, PLASMASHOTGUN_SHELL * 0.1, 0, 0, shotdir * 10000, 0.05, "PLASMASHOTGUN", DT_SHOTGUN, Obituary_PlasmaShotgun);
			//FireBullets(self, self, 0, 5, PLASMASHOTGUN_SHELL * 0.1, PLASMASHOTGUN_SHELL * 0.1, 0, 0, shotdir * 10000, 0.05, "PLASMASHOTGUN", DT_SHOTGUN, Obituary_PlasmaShotgun);
			FirePlasma(self, shotorg, shotdir * 10000, PLASMASHOTGUN_SHELL + PLASMASHOTGUN_CELL * PLASMASHOTGUN_CELLS, PLASMASHOTGUN_RADIUS, "PLASMASHOTGUN", Obituary_PlasmaShotgun);
			/*
			f = 0.2;
			v = shotdir * 10000 + randomvec() * 500;
			FirePlasma(self, shotorg, v, PLASMASHOTGUN_SHELL * f, PLASMASHOTGUN_RADIUS, "PLASMASHOTGUN", Obituary_PlasmaShotgun);
			v = shotdir * 10000 + randomvec() * 500;
			FirePlasma(self, shotorg, v, PLASMASHOTGUN_SHELL * f, PLASMASHOTGUN_RADIUS, "PLASMASHOTGUN", Obituary_PlasmaShotgun);
			v = shotdir * 10000 + randomvec() * 500;
			FirePlasma(self, shotorg, v, PLASMASHOTGUN_SHELL * f, PLASMASHOTGUN_RADIUS, "PLASMASHOTGUN", Obituary_PlasmaShotgun);
			v = shotdir * 10000 + randomvec() * 500;
			FirePlasma(self, shotorg, v, PLASMASHOTGUN_SHELL * f, PLASMASHOTGUN_RADIUS, "PLASMASHOTGUN", Obituary_PlasmaShotgun);
			v = shotdir * 10000 + randomvec() * 500;
			FirePlasma(self, shotorg, v, PLASMASHOTGUN_SHELL * f, PLASMASHOTGUN_RADIUS, "PLASMASHOTGUN", Obituary_PlasmaShotgun);
			*/
			//FireBullets(self, self, 1, 5, PLASMASHOTGUN_SHELL * 0.1, PLASMASHOTGUN_SHELL * 0.1, 0, 0, shotdir * 10000, 0.05, "PLASMASHOTGUN", DT_SHOTGUN, Obituary_PlasmaShotgun);
			//FireBullets(self, self, 0, 5, PLASMASHOTGUN_SHELL * 0.1, PLASMASHOTGUN_SHELL * 0.1, 0, 0, shotdir * 10000, 0.05, "PLASMASHOTGUN", DT_SHOTGUN, Obituary_PlasmaShotgun);
			wsetanim(WANIM_FIRE1, 1, 6, PLASMASHOTGUN_REFIRE);
		}
		return TRUE;
	}
	if (self.wanim_id == WANIM_FIRE1)
	{
		if (time >= self.wanim_endtime)
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	return TRUE;
};

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_DBShotgun =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " took both barrels from ";
		deathstring3 = attacker.netname;
		deathstring4 = "";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

.float shotgunshells;
float(float request) w_dbshotgun =
{
	if (request == WR_REGISTER)
	{
		precache_model("progs/v_dpshot2.mdl");
		precache_sound("weapons/shotgn2.wav");
		precache_sound("weapons/bsgnoammo.wav");
		precache_sound("weapons/bsgload.wav");
		registerweapon(3, "Double Barreled Shotgun", w_dbshotgun, "supershotgun", VWEP_SUPER_SHOTGUN, "progs/v_dpshot2.mdl", IT_SHELLS, 0, 500, DBSHOTGUN_SHELL * DBSHOTGUN_SHELLS / DBSHOTGUN_REFIRE, WANIMTYPE_SHOTGUN);
		return TRUE;
	}
	if (request == WR_HASAMMO)
		return Inventory_Quantity(self, "shells") > 0;
	if (request == WR_SETUP)
	{
		wsetanim(WANIM_RAISE, 9, -2, 0.2);
		self.shotgunshells = 0;
		return TRUE;
	}
	if (request == WR_INSTANTSETUP)
	{
		wsetanim(WANIM_READY, 0, 0, 0);
		self.shotgunshells = 0;
		return TRUE;
	}
	if (request == WR_ANIMATIONFRAME)
	{
		if (self.wanim_id == WANIM_FIRE1)
		{
			if (self.weaponframe == 3)
			{
				sound(self, CHAN_AUTO, "weapons/bsgload.wav", 1, ATTN_STATIC);
				if (self.shotgunshells & 1)
					ejectcasing(shotorg + v_forward * -8 + v_right *  1, v_right *  100 + v_up * 40, 30, self.v_angle_x * '-1 0 0' + self.v_angle_y * '0 1 0', '0 250 0', 100, 1);
				if (self.shotgunshells & 2)
					ejectcasing(shotorg + v_forward * -8 + v_right * -1, v_right * -100 + v_up * 40, 30, self.v_angle_x * '-1 0 0' + self.v_angle_y * '0 1 0', '0 -250 0', 100, 1);
				self.shotgunshells = 0;
			}
			if (self.weaponframe == 5)
				sound(self, CHAN_AUTO, "weapons/bsgload.wav", 1, ATTN_STATIC);
		}
	}
	if (request != WR_FRAME)
		return FALSE;
	wanimate();
	self.currentammo = Inventory_Quantity(self, "shells");
	if (self.aimtarg) // bot target
		self.button0 = w_directattackaim(6000, 1);
	if (self.wanim_id == WANIM_RAISE)
	{
		if (time >= self.wanim_endtime)
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (self.wanim_id == WANIM_LOWER)
	{
		if (time >= self.wanim_endtime)
			wswitch();
		return TRUE;
	}
	if (self.wanim_id == WANIM_READY)
	{
		if (self.switchweaponclass != self.weaponclass)
		{
			wsetanim(WANIM_LOWER, 8, 2, 0.2);
			return TRUE;
		}
		if (self.button0)
		if (Inventory_Quantity(self, "shells") > 0)
		{
			W_Hostile();
			sound(self, CHAN_WEAPON, "weapons/shotgn2.wav", 1, ATTN_NORM);
			w_muzzleflash(shotorg, 2);
			self.shotgunshells = 0;
			if (Inventory_Quantity(self, "shells") >= 1)
			{
				self.shotgunshells = self.shotgunshells | 1;
				Inventory_AdjustQuantity(self, "shells", -1);
				FireBullets(self, self, 1, 5, DBSHOTGUN_SHELL * 0.05, DBSHOTGUN_SHELL * 0.05, 0, 0, shotdir * 6000, 0.05, "SHOTGUN", DT_SHOTGUN, Obituary_DBShotgun);
				FireBullets(self, self, 0, 5, DBSHOTGUN_SHELL * 0.05, DBSHOTGUN_SHELL * 0.05, 0, 0, shotdir * 6000, 0.05, "SHOTGUN", DT_SHOTGUN, Obituary_DBShotgun);
			}
			if (Inventory_Quantity(self, "shells") >= 1)
			{
				self.shotgunshells = self.shotgunshells | 2;
				Inventory_AdjustQuantity(self, "shells", -1);
				FireBullets(self, self, 1, 5, DBSHOTGUN_SHELL * 0.05, DBSHOTGUN_SHELL * 0.05, 0, 0, shotdir * 6000, 0.05, "SHOTGUN", DT_SHOTGUN, Obituary_DBShotgun);
				FireBullets(self, self, 0, 5, DBSHOTGUN_SHELL * 0.05, DBSHOTGUN_SHELL * 0.05, 0, 0, shotdir * 6000, 0.05, "SHOTGUN", DT_SHOTGUN, Obituary_DBShotgun);
			}
			wsetanim(WANIM_FIRE1, 1, 7, DBSHOTGUN_REFIRE);
		}
		return TRUE;
	}
	if (self.wanim_id == WANIM_FIRE1)
	{
		if (time >= self.wanim_endtime)
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	return TRUE;
};

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_Nailgun =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = "'s coffin was nailed by ";
		deathstring3 = attacker.netname;
		deathstring4 = "";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_NailgunMine =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring3 = attacker.netname;
		if (targ.bodyhealth < 1) // gib
		{
			deathstring2 = " was shredded by ";
			deathstring4 = "'s porcupine";
		}
		else
		{
			deathstring2 = " was torn up by ";
			deathstring4 = "'s porcupine";
		}
	}
	else if (dtype == DTYPE_SUICIDE)
	{
		deathstring1 = targ.netname;
		if (targ.bodyhealth < 1) // gib
			deathstring2 = " was shredded by his own porcupine";
		else
			deathstring2 = " was torn up by his own porcupine";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

float(float request) w_nailgun =
{
	local vector v;
	if (request == WR_REGISTER)
	{
		precache_model("progs/v_dpnail.mdl");
		precache_sound("weapons/rocket1i.wav");
		precache_sound("weapons/bomb/trigger.wav");
		registerweapon(4, "Nailgun", w_nailgun, "nailgun", VWEP_NAILGUN, "progs/v_dpnail.mdl", IT_NAILS, 0, 4000, NAILGUN_NAIL / NAILGUN_REFIRE, WANIMTYPE_NAILGUN);
		return TRUE;
	}
	if (request == WR_HASAMMO)
		return Inventory_Quantity(self, "nails") > 0;
	if (request == WR_SETUP)
	{
		wsetanim(WANIM_RAISE, 10, -2, 0.2);
		return TRUE;
	}
	if (request == WR_INSTANTSETUP)
	{
		wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request == WR_ANIMATIONFRAME)
	{
		if (self.wanim_id == WANIM_FIRE1)
		{
			if (self.button0)
			if (Inventory_Quantity(self, "nails"))
			{
				W_Hostile();
				sound(self, CHAN_WEAPON, "weapons/rocket1i.wav", 1, ATTN_NORM);
				w_muzzleflash(shotorg, 2);
				Inventory_AdjustQuantity(self, "nails", -1);
				v = shotorg;
				if (self.weaponframe & 1)
				{
					shotorg = shotorg + v_right;
					FireBullets(self, self, 1, 1, NAILGUN_NAIL, NAILGUN_NAIL, 0, 0, shotdir * 10000, 0.025, "NAILGUN", DT_NAIL, Obituary_Nailgun);
					ejectcasing(shotorg + v_forward * -5, v_right *  150 + v_up * 50, 50, self.v_angle_x * '-1 0 0' + self.v_angle_y * '0 1 0', '0 250 0', 100, 0);
				}
				else
				{
					shotorg = shotorg - v_right;
					FireBullets(self, self, 1, 1, NAILGUN_NAIL, NAILGUN_NAIL, 0, 0, shotdir * 10000, 0.025, "NAILGUN", DT_NAIL, Obituary_Nailgun);
					ejectcasing(shotorg + v_forward * -5, v_right * -150 + v_up * 50, 50, self.v_angle_x * '-1 0 0' + self.v_angle_y * '0 1 0', '0 -250 0', 100, 0);
				}
				shotorg = v;
				return TRUE;
			}
			wsetanim(WANIM_READY, 0, 0, 0);
			return TRUE;
		}
	}
	if (request != WR_FRAME)
		return FALSE;
	wanimate();
	self.currentammo = Inventory_Quantity(self, "nails");
	if (self.aimtarg) // bot target
		self.button0 = w_directattackaim(10000, 1);
	if (self.wanim_id == WANIM_RAISE)
	{
		if (time >= self.wanim_endtime)
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (self.wanim_id == WANIM_LOWER)
	{
		if (time >= self.wanim_endtime)
			wswitch();
		return TRUE;
	}
	if (self.wanim_id == WANIM_READY)
	{
		if (self.switchweaponclass != self.weaponclass)
		{
			wsetanim(WANIM_LOWER, 9, 2, 0.2);
			return TRUE;
		}
		if (self.button0)
		if (Inventory_Quantity(self, "nails") > 0)
			wsetanim(WANIM_FIRE1, 1, 0, 0);
		if (self.button3)
		if (Inventory_Quantity(self, "rockets") > 0)
		{
			W_Hostile();
			sound(self, CHAN_WEAPON, "weapons/grenade.wav", 1, ATTN_NORM);
			self.wfiretime = time;
			Inventory_AdjustQuantity(self, "rockets", -1);
			w_muzzleflash(shotorg, 1);
			//LaunchGrenade(shotorg, shotdir * 1000 + v_up * 200, self, 80, 300, GRENADE_IMPACT, 2.5, "NAILGUNGRENADE", Obituary_NailgunGrenade);
			LaunchMine(shotorg, shotdir * 1000 + v_up * 200, self, 200, 70, 20, 10, MINE_LASERTRIP, 60, "LASERTRIPMINE", Obituary_NailgunMine);
			wsetanim(WANIM_FIRE2, 0, 0, 0.6);
		}
		return TRUE;
	}
	if (self.wanim_id == WANIM_FIRE1)
	{
		if (time >= self.wanim_endtime)
			wsetanim(WANIM_FIRE1, 1, 8, NAILGUN_REFIRE * 8);
		return TRUE;
	}
	if (self.wanim_id == WANIM_FIRE2)
	{
		if (time >= self.wanim_endtime)
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	return TRUE;
};

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_SuperNailgun =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " was perforated by ";
		deathstring3 = attacker.netname;
		deathstring4 = "";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
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

float(float request) w_supernailgun =
{
	local vector v;
	local float a;
	if (request == WR_REGISTER)
	{
		precache_model("progs/v_dpnail2.mdl");
		precache_sound("weapons/spike2.wav");
		precache_sound("weapons/bomb/trigger.wav");
		registerweapon(5, "Super Nailgun", w_supernailgun, "supernailgun", VWEP_SUPER_NAILGUN, "progs/v_dpnail2.mdl", IT_NAILS, 0, 1500, SUPERNAILGUN_NAIL / SUPERNAILGUN_REFIRE, WANIMTYPE_NAILGUN);
		return TRUE;
	}
	if (request == WR_HASAMMO)
		return Inventory_Quantity(self, "nails") > 0;
	if (request == WR_SETUP)
	{
		wsetanim(WANIM_RAISE, 10, -2, 0.2);
		return TRUE;
	}
	if (request == WR_INSTANTSETUP)
	{
		wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request == WR_ANIMATIONFRAME)
	{
		if (self.wanim_id == WANIM_FIRE1)
		{
			if (self.button0)
			if (Inventory_Quantity(self, "nails"))
			{
				W_Hostile();
				sound(self, CHAN_WEAPON, "weapons/spike2.wav", 1, ATTN_NORM);
				w_muzzleflash(shotorg, 2);
				Inventory_AdjustQuantity(self, "nails", -1);
				FireBullets(self, self, 1, 1, SUPERNAILGUN_NAIL, SUPERNAILGUN_NAIL, 0, 0, shotdir * 10000, 0.025, "SUPERNAILGUN", DT_NAIL, Obituary_SuperNailgun);
				ejectcasing(shotorg + v_forward * -5, v_right *  150 + v_up * 50, 50, self.v_angle_x * '-1 0 0' + self.v_angle_y * '0 1 0', '0 250 0', 100, 0);
				return TRUE;
			}
			wsetanim(WANIM_READY, 0, 0, 0);
		}
	}
	if (request != WR_FRAME)
		return FALSE;
	wanimate();
	self.currentammo = Inventory_Quantity(self, "nails");
	if (self.aimtarg) // bot target
		self.button0 = w_directattackaim(10000, 1);
	if (self.wanim_id == WANIM_RAISE)
	{
		if (time >= self.wanim_endtime)
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (self.wanim_id == WANIM_LOWER)
	{
		if (time >= self.wanim_endtime)
			wswitch();
		return TRUE;
	}
	if (self.wanim_id == WANIM_READY)
	{
		if (self.switchweaponclass != self.weaponclass)
		{
			wsetanim(WANIM_LOWER, 9, 2, 0.2);
			return TRUE;
		}
		if (self.button0)
		if (Inventory_Quantity(self, "nails") > 0)
			wsetanim(WANIM_FIRE1, 1, 0, 0);
		if (self.button3)
		if (Inventory_Quantity(self, "rockets") > 0)
		{
			W_Hostile();
			sound(self, CHAN_WEAPON, "weapons/grenade.wav", 1, ATTN_NORM);
			self.wfiretime = time;
			a = 3;
			if (a > Inventory_Quantity(self, "rockets"))
				a = Inventory_Quantity(self, "rockets");
			Inventory_AdjustQuantity(self, "rockets", 0 - a);
			w_muzzleflash(shotorg, 3);
			LaunchMine(shotorg, shotdir * 1000 + v_up * 200, self, a * 100, 350, 20, 10, MINE_PROXIMITY, 60, "PROXIMITYMINE", Obituary_ProximityMine);
			wsetanim(WANIM_FIRE2, 0, 0, 0.6);
		}
		return TRUE;
	}
	if (self.wanim_id == WANIM_FIRE1)
	{
		if (time >= self.wanim_endtime)
			wsetanim(WANIM_FIRE1, 1, 8, SUPERNAILGUN_REFIRE * 8);
		return TRUE;
	}
	if (self.wanim_id == WANIM_FIRE2)
	{
		if (time >= self.wanim_endtime)
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	return TRUE;
};

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_Grenade =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " was blasted by a grenade from ";
		deathstring3 = attacker.netname;
		deathstring4 = "";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

float(float request) w_grenadelauncher =
{
	if (request == WR_REGISTER)
	{
		precache_model("progs/v_dprock.mdl");
		precache_model("progs/grenade.mdl");
		precache_sound("weapons/grenade.wav");
		precache_sound("weapons/bounce.wav");
		registerweapon(6, "Grenade Launcher", w_grenadelauncher, "grenadelauncher", VWEP_GRENADE_LAUNCHER, "progs/v_dprock.mdl", IT_ROCKETS, 0, 2000, GRENADELAUNCHER_ROCKET / GRENADELAUNCHER_REFIRE, WANIMTYPE_ROCKET);
		return TRUE;
	}
	if (request == WR_HASAMMO)
		return Inventory_Quantity(self, "rockets") > 0;
	if (request == WR_SETUP)
	{
		wsetanim(WANIM_RAISE, 8, -2, 0.2);
		return TRUE;
	}
	if (request == WR_INSTANTSETUP)
	{
		wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
	wanimate();
	self.currentammo = Inventory_Quantity(self, "rockets");
	if (self.aimtarg) // bot target
		self.button0 = w_grenadeattackaim(1000, 2);
	if (self.wanim_id == WANIM_RAISE)
	{
		if (time >= self.wanim_endtime)
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (self.wanim_id == WANIM_LOWER)
	{
		if (time >= self.wanim_endtime)
			wswitch();
		return TRUE;
	}
	if (self.wanim_id == WANIM_READY)
	{
		if (self.switchweaponclass != self.weaponclass)
		{
			wsetanim(WANIM_LOWER, 7, 2, 0.2);
			return TRUE;
		}
		if (self.button0 || self.button3)
		if (Inventory_Quantity(self, "rockets") > 0)
		{
			W_Hostile();
			sound(self, CHAN_WEAPON, "weapons/grenade.wav", 1, ATTN_NORM);
			Inventory_AdjustQuantity(self, "rockets", -1);
			w_muzzleflash(shotorg, 2);
			if (self.button0)
				LaunchGrenade(shotorg, shotdir * 1000 + v_up * 200, self, GRENADELAUNCHER_ROCKET, GRENADELAUNCHER_RADIUS, GRENADE_IMPACT | GRENADE_IMMUNETODAMAGE, 25, "GRENADE", Obituary_Grenade);
			else
				LaunchGrenade(shotorg, shotdir * 1000 + v_up * 200, self, GRENADELAUNCHER_ROCKET, GRENADELAUNCHER_RADIUS, GRENADE_IMMUNETODAMAGE, 3, "GRENADE", Obituary_Grenade);
			wsetanim(WANIM_FIRE1, 1, 6, GRENADELAUNCHER_REFIRE);
		}
		return TRUE;
	}
	if (self.wanim_id == WANIM_FIRE1)
	{
		if (time >= self.wanim_endtime)
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	return TRUE;
};

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_Rocket =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " was blasted by a rocket from ";
		deathstring3 = attacker.netname;
		deathstring4 = "";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

float(float request) w_rocketlauncher =
{
	if (request == WR_REGISTER)
	{
		precache_model("progs/v_dprock2.mdl");
		precache_model("progs/missile.mdl");
		precache_sound("weapons/sgun1.wav");
		registerweapon(7, "Rocket Launcher", w_rocketlauncher, "rocketlauncher", VWEP_ROCKET_LAUNCHER, "progs/v_dprock2.mdl", IT_ROCKETS, 0, 2000, ROCKETLAUNCHER_SINGLE_ROCKET / ROCKETLAUNCHER_SINGLE_REFIRE, WANIMTYPE_ROCKET);
		return TRUE;
	}
	if (request == WR_HASAMMO)
		return Inventory_Quantity(self, "rockets") > 0;
	if (request == WR_SETUP)
	{
		wsetanim(WANIM_RAISE, 8, -2, 0.2);
		return TRUE;
	}
	if (request == WR_INSTANTSETUP)
	{
		wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
	wanimate();
	self.currentammo = Inventory_Quantity(self, "rockets");
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
			self.button3 = w_directattackaim(3000, 1);
		else
			self.button0 = w_directattackaim(5000, 1);
	}
	if (self.wanim_id == WANIM_RAISE)
	{
		if (time >= self.wanim_endtime)
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (self.wanim_id == WANIM_LOWER)
	{
		if (time >= self.wanim_endtime)
			wswitch();
		return TRUE;
	}
	if (self.wanim_id == WANIM_READY)
	{
		if (self.switchweaponclass != self.weaponclass)
		{
			wsetanim(WANIM_LOWER, 7, 2, 0.2);
			return TRUE;
		}
		if (self.button3)
		if (Inventory_Quantity(self, "rockets") > 0)
		{
			W_Hostile();
			sound(self, CHAN_WEAPON, "weapons/sgun1.wav", 1, ATTN_NORM);
			self.flags = self.flags - (self.flags & FL_ONGROUND);
			self.velocity = self.velocity - shotdir * 450;
			Inventory_AdjustQuantity(self, "rockets", -1);
			w_muzzleflash(shotorg, 4);
			LaunchMissile(shotorg, shotdir * 3000, self, ROCKETLAUNCHER_TRIPLE_ROCKET, ROCKETLAUNCHER_TRIPLE_RADIUS, "ROCKET", Obituary_Rocket);
			spiralmissile_orbitentity = newmis;
			if (Inventory_Quantity(self, "rockets") >= 1)
			{
				Inventory_AdjustQuantity(self, "rockets", -1);
				w_muzzleflash(shotorg + v_right * 8, 4);
				LaunchSpiralMissile(shotorg, shotdir, self, ROCKETLAUNCHER_TRIPLE_ROCKET, ROCKETLAUNCHER_TRIPLE_RADIUS, "ROCKET", Obituary_Rocket, -12);
				if (Inventory_Quantity(self, "rockets") >= 1)
				{
					Inventory_AdjustQuantity(self, "rockets", -1);
					w_muzzleflash(shotorg - v_right * 8, 4);
					LaunchSpiralMissile(shotorg, shotdir, self, ROCKETLAUNCHER_TRIPLE_ROCKET, ROCKETLAUNCHER_TRIPLE_RADIUS, "ROCKET", Obituary_Rocket, 12);
				}
			}
			wsetanim(WANIM_FIRE1, 1, 6, ROCKETLAUNCHER_TRIPLE_REFIRE);
			return TRUE;
		}
		if (self.button0)
		if (Inventory_Quantity(self, "rockets") > 0)
		{
			W_Hostile();
			sound(self, CHAN_WEAPON, "weapons/sgun1.wav", 1, ATTN_NORM);
			Inventory_AdjustQuantity(self, "rockets", -1);
			w_muzzleflash(shotorg, 4);
			LaunchMissile(shotorg, shotdir * 5000, self, ROCKETLAUNCHER_SINGLE_ROCKET, ROCKETLAUNCHER_SINGLE_RADIUS, "ROCKET", Obituary_Rocket);
			wsetanim(WANIM_FIRE1, 1, 6, ROCKETLAUNCHER_SINGLE_REFIRE);
			return TRUE;
		}
		return TRUE;
	}
	if (self.wanim_id == WANIM_FIRE1)
	{
		if (time >= self.wanim_endtime)
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	return TRUE;
};

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_PlasmaRifle =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " was scorched by ";
		deathstring3 = attacker.netname;
		deathstring4 = "";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

float(float request) w_plasmarifle =
{
	local float cells;
	local vector v;
	if (request == WR_REGISTER)
	{
		precache_model("progs/v_dpnail2.mdl");
		precache_model("progs/plasmashot.spr32");
		precache_sound("plasma/plasma.wav");
		precache_sound("plasma/plasexpl.wav");
		registerweapon(9, "Plasma Rifle", w_plasmarifle, "plasmarifle", VWEP_SUPER_NAILGUN, "progs/v_dpnail2.mdl", IT_CELLS, 0, 1500, PLASMARIFLE_NORMAL_CELL * PLASMARIFLE_NORMAL_CELLS / PLASMARIFLE_REFIRE, WANIMTYPE_NAILGUN);
		return TRUE;
	}
	if (request == WR_HASAMMO)
		return Inventory_Quantity(self, "cells") > 0;
	if (request == WR_SETUP)
	{
		wsetanim(WANIM_RAISE, 10, -2, 0.2);
		return TRUE;
	}
	if (request == WR_INSTANTSETUP)
	{
		wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request == WR_ANIMATIONFRAME)
	{
		if (self.wanim_id == WANIM_FIRE1)
		{
			if (self.button0 || self.button3)
			if (Inventory_Quantity(self, "cells"))
			{
				W_Hostile();
				sound(self, CHAN_WEAPON, "plasma/plasma.wav", 1, ATTN_NORM);
				w_muzzleflash(shotorg, 2);
				cells = Inventory_Quantity(self, "cells");
				if (self.button3)
				{
					if (cells > PLASMARIFLE_SUPER_CELLS)
						cells = PLASMARIFLE_SUPER_CELLS;
					FirePlasma(self, shotorg, shotdir * 25000, PLASMARIFLE_SUPER_CELL * cells, PLASMARIFLE_SUPER_RADIUS, "PLASMARIFLE", Obituary_PlasmaRifle);
				}
				else
				{
					if (cells > PLASMARIFLE_NORMAL_CELLS)
						cells = PLASMARIFLE_NORMAL_CELLS;
					FirePlasma(self, shotorg, shotdir * 25000, PLASMARIFLE_NORMAL_CELL * cells, PLASMARIFLE_NORMAL_RADIUS, "PLASMARIFLE", Obituary_PlasmaRifle);
				}
				Inventory_AdjustQuantity(self, "cells", 0 - cells);
				/*
				while (cells > 0)
				{
					cells = cells - 1;
					ejectcasing(shotorg + v_forward * -5, v_right *  150 + v_up * 50, 100, self.v_angle_x * '-1 0 0' + self.v_angle_y * '0 1 0', '0 250 0', 100, 0);
				}
				*/
				return TRUE;
			}
			wsetanim(WANIM_READY, 0, 0, 0);
		}
	}
	if (request != WR_FRAME)
		return FALSE;
	wanimate();
	self.currentammo = Inventory_Quantity(self, "cells");
	if (self.aimtarg) // bot target
		self.button0 = w_directattackaim(10000, 1);
	if (self.wanim_id == WANIM_RAISE)
	{
		if (time >= self.wanim_endtime)
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (self.wanim_id == WANIM_LOWER)
	{
		if (time >= self.wanim_endtime)
			wswitch();
		return TRUE;
	}
	if (self.wanim_id == WANIM_READY)
	{
		if (self.switchweaponclass != self.weaponclass)
		{
			wsetanim(WANIM_LOWER, 9, 2, 0.2);
			return TRUE;
		}
		if (self.button0 || self.button3)
		if (Inventory_Quantity(self, "cells") > 0)
			wsetanim(WANIM_FIRE1, 1, 0, 0);
		return TRUE;
	}
	if (self.wanim_id == WANIM_FIRE1)
	{
		if (time >= self.wanim_endtime)
			wsetanim(WANIM_FIRE1, 1, 8, PLASMARIFLE_REFIRE * 8);
		return TRUE;
	}
	return TRUE;
};

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_Lightning =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " was struck down by ";
		deathstring3 = attacker.netname;
		deathstring4 = "";
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

float(float request) w_thunderbolt =
{
	local float cells, f;
	local vector v;
	if (request == WR_REGISTER)
	{
		precache_model("progs/v_dplight.mdl");
		precache_model("progs/bolt2.mdl");
		precache_sound("weapons/lstart.wav");
		precache_sound("weapons/lhit.wav");
		registerweapon(8, "Thunderbolt", w_thunderbolt, "thunderbolt", VWEP_LIGHTNING, "progs/v_dplight.mdl", IT_CELLS, 0, 1500, THUNDERBOLT_CELL_HEALTH * THUNDERBOLT_CELLSPERSECOND, WANIMTYPE_LIGHTNING);
		return TRUE;
	}
	if (request == WR_HASAMMO)
		return Inventory_Quantity(self, "cells") > 0;
	if (request == WR_SETUP)
	{
		wsetanim(WANIM_RAISE, 6, -2, 0.2);
		return TRUE;
	}
	if (request == WR_INSTANTSETUP)
	{
		wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
	wanimate();
	self.currentammo = Inventory_Quantity(self, "cells");
	if (self.aimtarg) // bot target
		self.button0 = w_directattackaim(100000, 1);
	if (self.wanim_id == WANIM_RAISE)
	{
		if (time >= self.wanim_endtime)
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (self.wanim_id == WANIM_LOWER)
	{
		if (time >= self.wanim_endtime)
			wswitch();
		return TRUE;
	}
	if (self.wanim_id == WANIM_READY)
	{
		if (self.switchweaponclass != self.weaponclass)
		{
			wsetanim(WANIM_LOWER, 5, 2, 0.2);
			return TRUE;
		}
		if (self.button0 || self.button3)
		if (Inventory_Quantity(self, "cells") > 0)
		{
			sound(self, CHAN_AUTO, "weapons/lstart.wav", 1, ATTN_NORM);
			wsetanim(WANIM_FIRE1, 1, 4, 0.4);
		}
		return TRUE;
	}
	if (self.wanim_id == WANIM_FIRE1)
	{
		if (time >= self.wanim_endtime)
			wsetanim(WANIM_FIRE1, 1, 4, 0.4);
		if (self.button0 || self.button3)
		if (Inventory_Quantity(self, "cells"))
		{
			f = frametime * THUNDERBOLT_CELLSPERSECOND;
			cells = Inventory_Quantity(self, "cells");
			if (cells > f)
				cells = f;
			if (cells > 0)
			{
				if (time >= self.wfiretime + 0.1)
				{
					self.wfiretime = time;
					W_Hostile();
					sound(self, CHAN_WEAPON, "weapons/lhit.wav", 1, ATTN_NORM);
				}
				Inventory_AdjustQuantity(self, "cells", 0 - cells);
				W_BeamDamage(self, self, shotorg, shotorg + shotdir * 100000, cells * THUNDERBOLT_CELL_HEALTH, cells * THUNDERBOLT_CELL_BODY, "LIGHTNING", DT_LIGHTNING, Obituary_Lightning);
				traceline(shotorg, shotorg + shotdir * 100000, TRUE, self);
				te_lightning2(self, shotorg, trace_endpos);
				return TRUE;
			}
		}
		wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	return TRUE;
};

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

float(float request) w_plasmawave =
{
	local float cells, shots, damage;
	local vector ang;
	if (request == WR_REGISTER)
	{
		precache_model("progs/v_dplight.mdl");
		precache_model("progs/plasmashot.spr32");
		precache_sound("plasma/plasma.wav");
		precache_sound("plasma/plasexpl.wav");
		registerweapon(10, "Plasma Wave", w_plasmawave, "plasmawave", VWEP_LIGHTNING, "progs/v_dplight.mdl", IT_CELLS, 0, 1500, 200, WANIMTYPE_ROCKET);
		return TRUE;
	}
	if (request == WR_HASAMMO)
		return Inventory_Quantity(self, "cells") > 0;
	if (request == WR_SETUP)
	{
		wsetanim(WANIM_RAISE, 6, -2, 0.2);
		return TRUE;
	}
	if (request == WR_INSTANTSETUP)
	{
		wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
	wanimate();
	self.currentammo = Inventory_Quantity(self, "cells");
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
			self.button3 = w_directattackaim(3000, 1);
		else
			self.button0 = w_directattackaim(5000, 1);
	}
	if (self.wanim_id == WANIM_RAISE)
	{
		if (time >= self.wanim_endtime)
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (self.wanim_id == WANIM_LOWER)
	{
		if (time >= self.wanim_endtime)
			wswitch();
		return TRUE;
	}
	if (self.wanim_id == WANIM_READY)
	{
		if (self.switchweaponclass != self.weaponclass)
		{
			wsetanim(WANIM_LOWER, 5, 2, 0.2);
			return TRUE;
		}
		if (self.button3)
		if (Inventory_Quantity(self, "cells") > 0)
		{
			W_Hostile();
			sound(self, CHAN_WEAPON, "plasma/plasexpl.wav", 1, ATTN_NORM);
			wsetanim(WANIM_FIRE2, 0, 0, PLASMAWAVE_WAVE_CHARGETIME);
			return TRUE;
		}
		if (self.button0)
		if (Inventory_Quantity(self, "cells") > 0)
		{
			W_Hostile();
			sound(self, CHAN_WEAPON, "plasma/plasma.wav", 1, ATTN_NORM);
			cells = Inventory_Quantity(self, "cells");
			if (cells > PLASMAWAVE_SINGLE_CELLS)
				cells = PLASMAWAVE_SINGLE_CELLS;
			self.wfiretime = time;
			Inventory_AdjustQuantity(self, "cells", 0 - cells);
			w_muzzleflash(shotorg, 4);
			FirePlasmaBall(self, shotorg, shotdir * 1000, cells * PLASMAWAVE_SINGLE_CELL * 20, PLASMAWAVE_SINGLE_BURNRADIUS, "PLASMAWAVE", Obituary_PlasmaWaveShot);
			wsetanim(WANIM_FIRE1, 0, 0, PLASMAWAVE_SINGLE_REFIRE);
			return TRUE;
		}
		return TRUE;
	}
	if (self.wanim_id == WANIM_FIRE1)
	{
		if (time >= self.wanim_endtime)
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (self.wanim_id == WANIM_FIRE2)
	{
		if (time >= self.wanim_endtime)
		{
			W_Hostile();
			sound(self, CHAN_WEAPON, "plasma/plasma.wav", 1, ATTN_NORM);
			cells = Inventory_Quantity(self, "cells");
			if (cells > PLASMAWAVE_WAVE_MAXCELLS)
				cells = PLASMAWAVE_WAVE_MAXCELLS;
			self.wfiretime = time;
			Inventory_AdjustQuantity(self, "cells", 0 - cells);
			w_muzzleflash(shotorg, 4);
			shots = ceil(cells / PLASMAWAVE_WAVE_CELLSPERSHOT);
			if (shots > PLASMAWAVE_WAVE_MAXSHOTS)
				shots = PLASMAWAVE_WAVE_MAXSHOTS;
			damage = cells * PLASMAWAVE_WAVE_CELL / shots;
			ang = self.v_angle - (shots * '0 0.5 0' * PLASMAWAVE_WAVE_SPREADANGLEPERSHOT);
			while (shots > 0)
			{
				shots = shots - 1;
				makevectors(ang);
				FirePlasmaBall(self, shotorg, v_forward * 1000, damage, PLASMAWAVE_WAVE_BURNRADIUS, "PLASMAWAVE", Obituary_PlasmaWaveOverload);
				ang = ang + '0 1 0' * PLASMAWAVE_WAVE_SPREADANGLEPERSHOT;
			}
			wsetanim(WANIM_FIRE1, 0, 0, PLASMAWAVE_WAVE_REFIRE - PLASMAWAVE_WAVE_CHARGETIME);
		}
		return TRUE;
	}
	return TRUE;
};

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_LaserRifle =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " was incinerated by ";
		deathstring3 = attacker.netname;
		deathstring4 = "'s Laser Rifle";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

float(float request) w_laserrifle =
{
	local float f;
	local vector v;
	if (request == WR_REGISTER)
	{
		precache_model("progs/v_dpshot.mdl");
		precache_model("progs/laser.mdl");
		precache_sound("enforcer/enfire.wav");
		precache_sound("enforcer/enfstop.wav");
		registerweapon(3, "Laser Rifle", w_laserrifle, "laserrifle", VWEP_SHOTGUN, "progs/v_dpshot.mdl", IT_CELLS, 0, 2000, LASERRIFLE_CELL * LASERRIFLE_BURST / (LASERRIFLE_BURST * LASERRIFLE_BURSTREFIRE + LASERRIFLE_BETWEENBURSTREFIRE), WANIMTYPE_SHOTGUN);
		return TRUE;
	}
	if (request == WR_HASAMMO)
		return Inventory_Quantity(self, "cells");
	if (request == WR_SETUP)
	{
		wsetanim(WANIM_RAISE, 8, -2, 0.2);
		return TRUE;
	}
	if (request == WR_INSTANTSETUP)
	{
		wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
	wanimate();
	self.currentammo = Inventory_Quantity(self, "cells");
	if (self.aimtarg) // bot target
		self.button0 = w_directattackaim(10000, 1);
	if (self.wanim_id == WANIM_RAISE)
	{
		if (time >= self.wanim_endtime)
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (self.wanim_id == WANIM_LOWER)
	{
		if (time >= self.wanim_endtime)
			wswitch();
		return TRUE;
	}
	if (self.wanim_id == WANIM_READY)
	{
		if (self.switchweaponclass != self.weaponclass)
		{
			wsetanim(WANIM_LOWER, 7, 2, 0.2);
			return TRUE;
		}
		if (self.button0)
		if (Inventory_Quantity(self, "cells"))
		{
			self.wload = LASERRIFLE_BURST;
			wsetanim(WANIM_FIRE1, 1, 0, 0);
		}
		return TRUE;
	}
	if (self.wanim_id == WANIM_FIRE1)
	{
		if (time >= self.wanim_endtime)
		{
			if (self.wload > 0)
			if (Inventory_Quantity(self, "cells"))
			{
				self.wload = self.wload - 1;
				W_Hostile();
				sound(self, CHAN_WEAPON, "enforcer/enfire.wav", 1, ATTN_NORM);
				Inventory_AdjustQuantity(self, "cells", -1);
				w_muzzleflash(shotorg, 0.5);
				LaunchLaser(self, shotorg, shotdir * 10000, LASERRIFLE_CELL, "LASERRIFLE", Obituary_LaserRifle);
				wsetanim(WANIM_FIRE1, 1, 0, LASERRIFLE_BURSTREFIRE);
				return TRUE;
			}
			wsetanim(WANIM_FIRE2, 2, 5, LASERRIFLE_BETWEENBURSTREFIRE);
		}
		return TRUE;
	}
	if (self.wanim_id == WANIM_FIRE2)
	{
		if (time >= self.wanim_endtime)
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	return TRUE;
};

void() grapple_precache;
void() W_Precache =
{
	precache_model("progs/s_explod.spr");
	precache_model("progs/spike.mdl");
	precache_model("progs/s_spike.mdl");
	precache_model("progs/muzzleflash.spr32");
	grapple_precache();
	w_pistol(WR_REGISTER);
	w_shotgun(WR_REGISTER);
	w_plasmashotgun(WR_REGISTER);
	w_dbshotgun(WR_REGISTER);
	w_nailgun(WR_REGISTER);
	w_supernailgun(WR_REGISTER);
	w_grenadelauncher(WR_REGISTER);
	w_rocketlauncher(WR_REGISTER);
	w_thunderbolt(WR_REGISTER);
	w_plasmarifle(WR_REGISTER);
	w_plasmawave(WR_REGISTER);
	if (cvar("registered"))
		w_laserrifle(WR_REGISTER);
};

