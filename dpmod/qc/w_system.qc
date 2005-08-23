
float metroidmode;

.float wload;

void(vector muzzleorg, float kickback) w_muzzleflash =
{
	local float image;
	image = floor(random() * 9.7);
	//if (kickback >= 3)
	//	effect(muzzleorg, "progs/muzzleflash.spr32", image + 10, 1, 20);
	//else
	//	effect(muzzleorg, "progs/muzzleflash.spr32", image, 1, 30);
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
	if (e.health <= 0)
		return FALSE;
	if (e.classname == "player")
	if (coop)
		return FALSE;
	if (e.team == self.team)
	if (self.team)
	if (teamplay)
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
.float firetimer;
float(vector v, float maxfiredeviation) w_aimdir =
{
	local float dist;
	local vector desiredang, diffang;

	// make sure v_angle is sane first
	//while (self.v_angle_x < -180) self.v_angle_x = self.v_angle_x + 360;
	//while (self.v_angle_x >= 180) self.v_angle_x = self.v_angle_x - 360;
	while (self.v_angle_y < -180) self.v_angle_y = self.v_angle_y + 360;
	while (self.v_angle_y >= 180) self.v_angle_y = self.v_angle_y - 360;
	//while (self.v_angle_z < -180) self.v_angle_z = self.v_angle_z + 360;
	//while (self.v_angle_z >= 180) self.v_angle_z = self.v_angle_z - 360;

	// get the desired angles to aim at
	desiredang = vectoangles(v);
	desiredang_x = 0 - desiredang_x;
	desiredang_z = self.v_angle_z;
	if (desiredang_x >= 180)
		desiredang_x = desiredang_x - 360;

	// pain throws off aim
	if (self.painintensity)
	{
		// shake from pain
		desiredang = desiredang + randomvec() * self.painintensity * 0.2;
	}

	// calculate turn angles
	diffang = desiredang - self.v_angle;

	// wrap yaw turn
	while (diffang_y < -180)
		diffang_y = diffang_y + 360;
	while (diffang_y >  180)
		diffang_y = diffang_y - 360;

	// jitter tracking
	dist = vlen(diffang);
	//diffang = diffang + randomvec() * (dist * 0.05 * (3.5 - bound(0, skill, 3)));

	/*
	// simulate slight 'stickyness' of mouse on small moves
	if (vlen(diffang) < 0.1)
	{
		//bprint("c\n");
		if (time >= self.mousesticktime)
		if (random() < 0.5)
		{
			//bprint("d\n");
			self.mousesticktime = time + 0.2;
		}
		return vlen(diffang) < maxfiredeviation;
	}
	*/

	// turn
	self.v_angle = self.v_angle + diffang * min(1, (3 * (skill + 1)) * frametime);
	while (self.v_angle_y < -180)
		self.v_angle_y = self.v_angle_y + 360;
	while (self.v_angle_y >= 180)
		self.v_angle_y = self.v_angle_y - 360;

	// calculate turn angles again
	diffang = desiredang - self.v_angle;
	while (diffang_y < -180)
		diffang_y = diffang_y + 360;
	while (diffang_y >  180)
		diffang_y = diffang_y - 360;

	//bprint("e ");bprintvector(diffang);bprint(" < ");bprintfloat(maxfiredeviation);bprint("\n");

	// decide whether to fire this time
	if (vlen(diffang) < maxfiredeviation)
		self.firetimer = time + 0.3;
	return time < self.firetimer;
};

vector(vector targorigin, vector targvelocity, float shotspeed, float shotdelay) w_shotlead =
{
	return targorigin + targvelocity * (shotdelay + vlen(targorigin - shotorg) / shotspeed);
};

float(float shotspeed, float maxshottime) w_directattackaim =
{
	local float f, r;
	local vector v;
	v = w_shotlead(self.aimtargorigin, self.aimtargvelocity, shotspeed, self.aimlatency);
	//bprint("AIM: ");bprintvector(v);bprint("\n");
	r = vlen(v - shotorg);
	f = w_aimdir(v - shotorg, min(10, 720 / r));
	if (r > maxshottime * shotspeed)
		return FALSE;
	traceline(shotorg, v, FALSE, self);
	if (trace_fraction < 1)
	if (!w_shouldattack(trace_ent))
		return FALSE;
	//bprint("b\n");
	return f;
};

float(float shotspeed, float maxshottime) w_grenadeattackaim =
{
	local float f, r;
	local vector v;
	if (!findtrajectorywithleading(shotorg, '0 0 0', '0 0 0', self.aimtarg, shotspeed, maxshottime, 0, self))
		return FALSE;
	v = w_shotlead(self.aimtargorigin, self.aimtargvelocity, shotspeed, self.aimlatency);
	r = vlen(v - shotorg);
	f = w_aimdir(findtrajectory_velocity, min(10, 720 / r));
	if (r > maxshottime * shotspeed)
		return FALSE;
	return f;
};

void() W_SetupShot;
void() W_Hostile =
{
	// wake up monsters
	self.show_hostile = time + 1;
	weaponwakeup(self.origin, self);
	fightdone = time + 1; // delay stuff until fighting is over
	SuperDamageSound();
	W_SetupShot();
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
	local float f;

	f = bound(0, time - self.wanim_lasttime, 0.1);
	self.wanim_lasttime = time;
	if (f)
	{
		self.wanim_accumulator = self.wanim_accumulator + f;
		if (self.wanim_frameseconds)
		{
			/*
			bprint("f: ");
			bprintfloat(f);
			bprint("\nbefore accum: ");
			bprintfloat(self.wanim_accumulator);
			bprint(" increment: ");
			bprintfloat(self.wanim_increment);
			bprint(" frame: ");
			bprintfloat(self.weaponframe);
			bprint(" finalframe: ");
			bprintfloat(self.wanim_finalframe);
			bprint(" ->\n");
			*/
			while (self.wanim_accumulator >= self.wanim_frameseconds)
			{
				self.wanim_accumulator = self.wanim_accumulator - self.wanim_frameseconds;
				self.weaponclass.w_func(WR_ANIMATIONFRAME);
				if (self.weaponframe != self.wanim_finalframe)
					self.weaponframe = self.weaponframe + self.wanim_increment;
				else
					self.weaponclass.w_func(WR_ANIMATIONFINISH);
				if (!self.wanim_frameseconds)
					break;
			}
			/*
			bprint("after accum: ");
			bprintfloat(self.wanim_accumulator);
			bprint(" increment: ");
			bprintfloat(self.wanim_increment);
			bprint(" frame: ");
			bprintfloat(self.weaponframe);
			bprint(" finalframe: ");
			bprintfloat(self.wanim_finalframe);
			bprint("\n");
			*/
		}
		else
		{
			self.wanim_accumulator = 0;
			if (self.weaponframe != self.wanim_finalframe)
			{
				self.weaponframe = self.weaponframe + self.wanim_increment;
				self.weaponclass.w_func(WR_ANIMATIONFRAME);
			}
			else
				self.weaponclass.w_func(WR_ANIMATIONFINISH);
		}
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
	self.weaponframe = startframe;
	self.wanim_increment = 1;
	if (deltaframe == 0)
		deltaframe = 1;
	else if (deltaframe < 0)
		self.wanim_increment = -1;
	self.wanim_frameseconds = deltatime / (deltaframe * self.wanim_increment);
	self.wanim_finalframe = startframe + deltaframe - self.wanim_increment;
	/*
	bprint("animid ");bprintfloat(animid);
	bprint(" startframe ");bprintfloat(startframe);
	bprint(" deltaframe ");bprintfloat(deltaframe);
	bprint(" deltatime ");bprintfloat(deltatime);
	bprint(" increment ");bprintfloat(self.wanim_increment);
	bprint(" frameseconds ");bprintfloat(self.wanim_frameseconds);
	bprint(" finalframe ");bprintfloat(self.wanim_finalframe);
	bprint("\n");
	*/
	wanimate();
};

void(entity wclass, float instantswitch) wsetweapon =
{
	self.wanim_lasttime = time;
	self.wanim_accumulator = 0;
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
	W_Cycle(self.impulse, TRUE);
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

	Inventory_SetQuantity(self, "shells", 9999);
	Inventory_SetQuantity(self, "nails", 9999);
	Inventory_SetQuantity(self, "rockets", 9999);
	Inventory_SetQuantity(self, "cells", 9999);
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

void() W_SetupShot =
{
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
};

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

	W_SetupShot();

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
	if (self.weaponclass)
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

float AXE_DAMAGE = 20;
float AXE_REFIRE = 0.5;
float SHOTGUN_SHELL = 60;
float SHOTGUN_SHELLS = 1;
float SHOTGUN_REFIRE = 0.9;
float PLASMASHOTGUN_SHELL = 150;
float PLASMASHOTGUN_CELL = 30;
float PLASMASHOTGUN_CELLS = 3;
float PLASMASHOTGUN_RADIUS = 60;
float PLASMASHOTGUN_REFIRE = 0.9;
float DBSHOTGUN_SHELL = 60;
float DBSHOTGUN_SHELLS = 2;
float DBSHOTGUN_REFIRE = 1.4;
float NAILGUN_NAIL = 15;
float NAILGUN_NAILS = 1;
float NAILGUN_REFIRE = 0.1;
float SUPERNAILGUN_NAIL = 15;
float SUPERNAILGUN_NAILS = 1;
float SUPERNAILGUN_REFIRE = 0.05;
float GRENADELAUNCHER_DAMAGE = 150;
float GRENADELAUNCHER_FORCE = 150;
float GRENADELAUNCHER_RADIUS = 120;
float GRENADELAUNCHER_REFIRE = 0.8;
float ROCKETLAUNCHER_DAMAGE = 150;
float ROCKETLAUNCHER_FORCE = 150;
float ROCKETLAUNCHER_RADIUS = 200;
float ROCKETLAUNCHER_REFIRE = 0.8;
float ROCKETLAUNCHER_LOADTIME = 0.2;
float ROCKETLAUNCHER_MAXLOAD = 2;
float ROCKETLAUNCHER_VELOCITY = 3000;
float ROCKETLAUNCHER_MULTI_VELOCITY = 3000;
float THUNDERBOLT_CELL_HEALTH = 60;
float THUNDERBOLT_CELL_BODY = 15;
float THUNDERBOLT_CELLSPERSECOND = 5;
float PLASMARIFLE_NORMAL_CELL = 60;
float PLASMARIFLE_NORMAL_CELLS = 1;
float PLASMARIFLE_NORMAL_RADIUS = 80;
float PLASMARIFLE_NORMAL_VELOCITY = 5000;
float PLASMARIFLE_NORMAL_REFIRE = 0.2;
float PLASMARIFLE_SUPER_CELL = 60;
float PLASMARIFLE_SUPER_CELLS = 4;
float PLASMARIFLE_SUPER_RADIUS = 80;
float PLASMARIFLE_SUPER_VELOCITY = 5000;
float PLASMARIFLE_SUPER_REFIRE = 0.5;
/*
float PLASMARIFLE_NORMAL_CELL = 30;
float PLASMARIFLE_NORMAL_CELLS = 1;
float PLASMARIFLE_NORMAL_RADIUS = 50;
float PLASMARIFLE_NORMAL_VELOCITY = 25000;
float PLASMARIFLE_NORMAL_REFIRE = 0.1;
float PLASMARIFLE_SUPER_CELL = 30;
float PLASMARIFLE_SUPER_CELLS = 3;
float PLASMARIFLE_SUPER_RADIUS = 80;
float PLASMARIFLE_SUPER_VELOCITY = 25000;
float PLASMARIFLE_SUPER_REFIRE = 0.1;
*/
float PLASMAWAVE_SINGLE_CELL = 60;
float PLASMAWAVE_SINGLE_CELLS = 10;
float PLASMAWAVE_SINGLE_REFIRE = 0.6;
float PLASMAWAVE_SINGLE_BURNRADIUS = 120;
float PLASMAWAVE_WAVE_CELL = 60;
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
float FLAMER_SHOT_VELOCITY = 1200;
float FLAMER_SHOT_TIME = 1;
float FLAMER_SHOT_CELLS = 3;
float FLAMER_SHOT_DAMAGE = 30;
float FLAMER_SHOT_BURN = 180;
float FLAMER_SHOT_BURNLIMIT = 2000;
float FLAMER_SHOT_FORCE = 25;
float FLAMER_SHOT_RADIUS = 100;
float FLAMER_SHOT_REFIRE = 0.7;
float FLAMER_SHOT_COOLDOWN = 0;
float FLAMER_DROP_VELOCITY = 600;
float FLAMER_DROP_UPVELOCITY = 200;
float FLAMER_DROP_SPREAD = 0.1;
float FLAMER_DROP_TIME = 15;
float FLAMER_DROP_CELLS = 3;
float FLAMER_DROP_COUNT = 3;
float FLAMER_DROP_DAMAGE = 120;
float FLAMER_DROP_FORCE = 120;
float FLAMER_DROP_RADIUS = 200;
float FLAMER_DROP_REFIRE = 0.8;

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_Axe =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " was ax-murdered by ";
		deathstring3 = attacker.netname;
		deathstring4 = "";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

float(float request) w_axe =
{
	local float f;
	local vector v;
	if (request == WR_REGISTER)
	{
		precache_model("progs/v_axe.mdl");
		registerweapon(1, "Axe", w_axe, "axe", VWEP_AXE, "progs/v_axe.mdl", 0, 0, 2000, AXE_DAMAGE / AXE_REFIRE, WANIMTYPE_SHOTGUN);
		return TRUE;
	}
	if (request == WR_HASAMMO)
		return TRUE;
	if (request == WR_SETUP)
	{
		wsetanim(WANIM_RAISE, 0, 0, 0);
		return TRUE;
	}
	if (request == WR_INSTANTSETUP)
	{
		wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request == WR_ANIMATIONFINISH)
	{
		if (self.wanim_id == WANIM_LOWER)
			wswitch();
		else
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request == WR_AIM)
	{
		self.button0 = w_directattackaim(10000, 1);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
	wanimate();
	self.currentammo = 0;
	if (self.wanim_id == WANIM_READY)
	{
		if (self.switchweaponclass != self.weaponclass)
		{
			wsetanim(WANIM_LOWER, 0, 0, 0);
			return TRUE;
		}
		if (self.button0)
		{
			W_Hostile();
			// FIXME: this needs to animate the player model too
			f = random() * 4;
			if (f < 1)
				wsetanim(WANIM_FIRE1, 1, 4, AXE_REFIRE); // player_axe
			else if (f < 2)
				wsetanim(WANIM_FIRE1, 5, 4, AXE_REFIRE); // player_axeb
			else if (f < 3)
				wsetanim(WANIM_FIRE1, 1, 4, AXE_REFIRE); // player_axec
			else
				wsetanim(WANIM_FIRE1, 5, 4, AXE_REFIRE); // player_axed
			// FIXME: damage code should be on third animation frame
			// change solid type so the traceline hits SOLID_CORPSE
			f = self.solid;
			self.solid = SOLID_BBOX;
			traceline (shotorg, shotorg + shotdir * 64, FALSE, self);
			self.solid = f;
			if (trace_fraction < 1)
			{
				if (trace_ent.solid == SOLID_BSP)
				{
					sound (self, CHAN_WEAPON, "player/axhit2.wav", 1, ATTN_NORM);
					te_gunshot(trace_endpos - shotdir * 4);
				}
				T_Damage (trace_ent, self, self, AXE_DAMAGE, AXE_DAMAGE, "AXE", DT_CUT, trace_endpos - shotdir * 4, '0 0 0', Obituary_Axe);
			}
		}
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
				if (cvar("dpmod_qcphysics_casings"))
					Ragdoll_ThrowCasing(shotorg + v_forward * -5, v_right * 120 + v_up * 40, shotorg + v_forward * -3, v_right * 80 + v_up * 50, "progs/casing_shell.mdl");
				else
					ejectcasing(shotorg + v_forward * -5, v_right * 100 + v_up * 40, 30, self.v_angle_x * '-1 0 0' + self.v_angle_y * '0 1 0', '0 250 0', 100, 1);
			}
			if (self.weaponframe == 5)
				sound(self, CHAN_AUTO, "weapons/bsgload.wav", 1, ATTN_STATIC);
		}
	}
	if (request == WR_ANIMATIONFINISH)
	{
		if (self.wanim_id == WANIM_LOWER)
			wswitch();
		else
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request == WR_AIM)
	{
		self.button0 = w_directattackaim(10000, 1);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
	wanimate();
	self.currentammo = Inventory_Quantity(self, "shells");
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
			FireBullets(self, self, 1, 5, SHOTGUN_SHELL * 0.2, SHOTGUN_SHELL * 0.2, 0, 0, shotdir * 10000, 0.015, "SHOTGUN", DT_SHOTGUN, Obituary_Shotgun);
			//FireBullets(self, self, 0, 5, SHOTGUN_SHELL * 0.1, SHOTGUN_SHELL * 0.1, 0, 0, shotdir * 10000, 0.05, "SHOTGUN", DT_SHOTGUN, Obituary_Shotgun);
			wsetanim(WANIM_FIRE1, 1, 6, SHOTGUN_REFIRE);
		}
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
				if (cvar("dpmod_qcphysics_casings"))
					Ragdoll_ThrowCasing(shotorg + v_forward * -5, v_right * 120 + v_up * 40, shotorg + v_forward * -3, v_right * 80 + v_up * 50, "progs/casing_shell.mdl");
				else
					ejectcasing(shotorg + v_forward * -5, v_right * 100 + v_up * 40, 30, self.v_angle_x * '-1 0 0' + self.v_angle_y * '0 1 0', '0 250 0', 100, 1);
			}
			if (self.weaponframe == 5)
				sound(self, CHAN_AUTO, "weapons/bsgload.wav", 1, ATTN_STATIC);
		}
	}
	if (request == WR_ANIMATIONFINISH)
	{
		if (self.wanim_id == WANIM_LOWER)
			wswitch();
		else
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request == WR_AIM)
	{
		self.button0 = w_directattackaim(10000, 1);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
	wanimate();
	self.currentammo = Inventory_Quantity(self, "cells") / PLASMASHOTGUN_CELLS;
	f = Inventory_Quantity(self, "shells");
	if (self.currentammo > f)
		self.currentammo = f;
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
			FirePlasma(self, self, shotorg, shotdir * 10000, PLASMASHOTGUN_SHELL + PLASMASHOTGUN_CELL * PLASMASHOTGUN_CELLS, PLASMASHOTGUN_SHELL + PLASMASHOTGUN_CELL * PLASMASHOTGUN_CELLS, PLASMASHOTGUN_RADIUS, "PLASMASHOTGUN", Obituary_PlasmaShotgun);
			/*
			f = 0.2;
			v = shotdir * 10000 + randomvec() * 500;
			FirePlasma(self, self, shotorg, v, PLASMASHOTGUN_SHELL * f, PLASMASHOTGUN_RADIUS, "PLASMASHOTGUN", Obituary_PlasmaShotgun);
			v = shotdir * 10000 + randomvec() * 500;
			FirePlasma(self, self, shotorg, v, PLASMASHOTGUN_SHELL * f, PLASMASHOTGUN_RADIUS, "PLASMASHOTGUN", Obituary_PlasmaShotgun);
			v = shotdir * 10000 + randomvec() * 500;
			FirePlasma(self, self, shotorg, v, PLASMASHOTGUN_SHELL * f, PLASMASHOTGUN_RADIUS, "PLASMASHOTGUN", Obituary_PlasmaShotgun);
			v = shotdir * 10000 + randomvec() * 500;
			FirePlasma(self, self, shotorg, v, PLASMASHOTGUN_SHELL * f, PLASMASHOTGUN_RADIUS, "PLASMASHOTGUN", Obituary_PlasmaShotgun);
			v = shotdir * 10000 + randomvec() * 500;
			FirePlasma(self, self, shotorg, v, PLASMASHOTGUN_SHELL * f, PLASMASHOTGUN_RADIUS, "PLASMASHOTGUN", Obituary_PlasmaShotgun);
			*/
			//FireBullets(self, self, 1, 5, PLASMASHOTGUN_SHELL * 0.1, PLASMASHOTGUN_SHELL * 0.1, 0, 0, shotdir * 10000, 0.05, "PLASMASHOTGUN", DT_SHOTGUN, Obituary_PlasmaShotgun);
			//FireBullets(self, self, 0, 5, PLASMASHOTGUN_SHELL * 0.1, PLASMASHOTGUN_SHELL * 0.1, 0, 0, shotdir * 10000, 0.05, "PLASMASHOTGUN", DT_SHOTGUN, Obituary_PlasmaShotgun);
			wsetanim(WANIM_FIRE1, 1, 6, PLASMASHOTGUN_REFIRE);
		}
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
				{
					if (cvar("dpmod_qcphysics_casings"))
						Ragdoll_ThrowCasing(shotorg + v_forward * -8 + v_right *  1, v_right *  120 + v_up * 40, shotorg + v_forward * -6 + v_right *  1, v_right *  80 + v_up * 50, "progs/casing_shell.mdl");
					else
						ejectcasing(shotorg + v_forward * -8 + v_right *  1, v_right *  100 + v_up * 40, 30, self.v_angle_x * '-1 0 0' + self.v_angle_y * '0 1 0', '0 250 0', 100, 1);
				}
				if (self.shotgunshells & 2)
				{
					if (cvar("dpmod_qcphysics_casings"))
						Ragdoll_ThrowCasing(shotorg + v_forward * -8 + v_right * -1, v_right * -120 + v_up * 40, shotorg + v_forward * -6 + v_right * -1, v_right * -80 + v_up * 50, "progs/casing_shell.mdl");
					else
						ejectcasing(shotorg + v_forward * -8 + v_right * -1, v_right * -100 + v_up * 40, 30, self.v_angle_x * '-1 0 0' + self.v_angle_y * '0 1 0', '0 -250 0', 100, 1);
				}
				self.shotgunshells = 0;
			}
			if (self.weaponframe == 5)
				sound(self, CHAN_AUTO, "weapons/bsgload.wav", 1, ATTN_STATIC);
		}
	}
	if (request == WR_ANIMATIONFINISH)
	{
		if (self.wanim_id == WANIM_LOWER)
			wswitch();
		else
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request == WR_AIM)
	{
		self.button0 = w_directattackaim(10000, 1);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
	wanimate();
	self.currentammo = Inventory_Quantity(self, "shells");
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
				FireBullets(self, self, 1, 5, DBSHOTGUN_SHELL * 0.05, DBSHOTGUN_SHELL * 0.05, 0, 0, shotdir * 10000, 0.025, "SHOTGUN", DT_SHOTGUN, Obituary_DBShotgun);
				FireBullets(self, self, 0, 5, DBSHOTGUN_SHELL * 0.05, DBSHOTGUN_SHELL * 0.05, 0, 0, shotdir * 10000, 0.025, "SHOTGUN", DT_SHOTGUN, Obituary_DBShotgun);
			}
			if (Inventory_Quantity(self, "shells") >= 1)
			{
				self.shotgunshells = self.shotgunshells | 2;
				Inventory_AdjustQuantity(self, "shells", -1);
				FireBullets(self, self, 1, 5, DBSHOTGUN_SHELL * 0.05, DBSHOTGUN_SHELL * 0.05, 0, 0, shotdir * 10000, 0.025, "SHOTGUN", DT_SHOTGUN, Obituary_DBShotgun);
				FireBullets(self, self, 0, 5, DBSHOTGUN_SHELL * 0.05, DBSHOTGUN_SHELL * 0.05, 0, 0, shotdir * 10000, 0.025, "SHOTGUN", DT_SHOTGUN, Obituary_DBShotgun);
			}
			wsetanim(WANIM_FIRE1, 1, 7, DBSHOTGUN_REFIRE);
		}
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
				W_SetupShot();
				w_muzzleflash(shotorg, 2);
				Inventory_AdjustQuantity(self, "nails", -1);
				v = shotorg;
				if (self.weaponframe & 1)
				{
					shotorg = shotorg + v_right;
					FireBullets(self, self, 4, 1, NAILGUN_NAIL, NAILGUN_NAIL, 0, 0, shotdir * 10000, 0.025, "NAILGUN", DT_NAIL, Obituary_Nailgun);
					//ejectcasing(shotorg + v_forward * -5, v_right *  150 + v_up * 50, 50, self.v_angle_x * '-1 0 0' + self.v_angle_y * '0 1 0', '0 250 0', 100, 0);
				}
				else
				{
					shotorg = shotorg - v_right;
					FireBullets(self, self, 4, 1, NAILGUN_NAIL, NAILGUN_NAIL, 0, 0, shotdir * 10000, 0.025, "NAILGUN", DT_NAIL, Obituary_Nailgun);
					//ejectcasing(shotorg + v_forward * -5, v_right * -150 + v_up * 50, 50, self.v_angle_x * '-1 0 0' + self.v_angle_y * '0 1 0', '0 -250 0', 100, 0);
				}
				shotorg = v;
				return TRUE;
			}
			wsetanim(WANIM_READY, 0, 0, 0);
			return TRUE;
		}
	}
	if (request == WR_ANIMATIONFINISH)
	{
		if (self.wanim_id == WANIM_LOWER)
			wswitch();
		else if (self.wanim_id == WANIM_FIRE1)
			wsetanim(WANIM_FIRE1, 1, 8, NAILGUN_REFIRE * 8);
		else
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request == WR_AIM)
	{
		self.button0 = w_directattackaim(10000, 1);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
	wanimate();
	self.currentammo = Inventory_Quantity(self, "nails");
	if (self.wanim_id == WANIM_READY)
	{
		if (self.switchweaponclass != self.weaponclass)
		{
			wsetanim(WANIM_LOWER, 9, 2, 0.2);
			return TRUE;
		}
		if (self.button0)
		if (Inventory_Quantity(self, "nails") > 0)
		{
			wsetanim(WANIM_FIRE1, 1, 0, 0);
			return TRUE;
		}
		if (self.button3)
		if (Inventory_Quantity(self, "rockets") > 0)
		{
			W_Hostile();
			sound(self, CHAN_WEAPON, "weapons/grenade.wav", 1, ATTN_NORM);
			self.wfiretime = time;
			Inventory_AdjustQuantity(self, "rockets", -1);
			w_muzzleflash(shotorg, 1);
			//LaunchGrenade(shotorg, shotdir * 1000 + v_up * 200, self, 80, 80, 300, GRENADE_IMPACT, 2.5, "NAILGUNGRENADE", Obituary_NailgunGrenade);
			//LaunchMine(shotorg, shotdir * 1000 + v_up * 200, self, 200, 200, 70, 20, 10, MINE_LASERTRIP, 60, 2, "LASERTRIPMINE", Obituary_NailgunMine);
			LaunchMine(shotorg, shotdir * 600 + v_up * 200, self, 100, 100, 250, 20, 10, MINE_PROXIMITY, 60, 3, "PROXIMITYMINE", Obituary_NailgunMine);
			wsetanim(WANIM_FIRE2, 0, 0, 0.6);
		}
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

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_SuperNailgunGrenade =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring3 = attacker.netname;
		if (targ.bodyhealth < -150) // gib
		{
			deathstring2 = " was turned into a fine red mist by ";
			deathstring4 = "'s grenade";
		}
		else if (targ.bodyhealth < 1) // gib
		{
			deathstring2 = " was turned into kibble by ";
			deathstring4 = "'s grenade";
		}
		else
		{
			deathstring2 = " was thrown into the afterlife by ";
			deathstring4 = "'s grenade";
		}
	}
	else if (dtype == DTYPE_SUICIDE)
	{
		deathstring1 = targ.netname;
		if (targ.bodyhealth < -100) // gib
			deathstring2 = " was turned into a fine red mist by his own grenade";
		else if (targ.bodyhealth < 1) // gib
			deathstring2 = " was turned into kibble by his own grenade";
		else
			deathstring2 = " was thrown into the afterlife by his own grenade";
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
				W_SetupShot();
				sound(self, CHAN_WEAPON, "weapons/spike2.wav", 1, ATTN_NORM);
				w_muzzleflash(shotorg, 2);
				Inventory_AdjustQuantity(self, "nails", -1);
				FireBullets(self, self, 4, 1, SUPERNAILGUN_NAIL, SUPERNAILGUN_NAIL, 0, 0, shotdir * 10000, 0.025, "SUPERNAILGUN", DT_NAIL, Obituary_SuperNailgun);
				if (cvar("dpmod_qcphysics_casings"))
					Ragdoll_ThrowCasing(shotorg + v_forward * -5, v_right * 200 + v_up * 75, shotorg + v_forward * -3, v_right * 150 + v_up * 50, "progs/casing_bronze.mdl");
				else
					ejectcasing(shotorg + v_forward * -5, v_right *  150 + v_up * 50, 50, self.v_angle_x * '-1 0 0' + self.v_angle_y * '0 1 0', '0 250 0', 100, 0);
				return TRUE;
			}
			wsetanim(WANIM_READY, 0, 0, 0);
		}
	}
	if (request == WR_ANIMATIONFINISH)
	{
		if (self.wanim_id == WANIM_LOWER)
			wswitch();
		else if (self.wanim_id == WANIM_FIRE1)
			wsetanim(WANIM_FIRE1, 1, 8, SUPERNAILGUN_REFIRE * 8);
		else
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request == WR_AIM)
	{
		self.button0 = w_directattackaim(10000, 1);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
	wanimate();
	self.currentammo = Inventory_Quantity(self, "nails");
	if (self.wanim_id == WANIM_READY)
	{
		if (self.switchweaponclass != self.weaponclass)
		{
			wsetanim(WANIM_LOWER, 9, 2, 0.2);
			return TRUE;
		}
		if (self.button0)
		if (Inventory_Quantity(self, "nails") > 0)
		{
			wsetanim(WANIM_FIRE1, 1, 0, 0);
			return TRUE;
		}
		if (self.button3)
		if (Inventory_Quantity(self, "rockets") > 0)
		{
			W_Hostile();
			sound(self, CHAN_WEAPON, "weapons/grenade.wav", 1, ATTN_NORM);
			self.wfiretime = time;
			a = 1;
			if (a > Inventory_Quantity(self, "rockets"))
				a = Inventory_Quantity(self, "rockets");
			Inventory_AdjustQuantity(self, "rockets", 0 - a);
			w_muzzleflash(shotorg, 3);
			//LaunchMine(shotorg, shotdir * 1000 + v_up * 200, self, a * 100, a * 100, 350, 20, 10, MINE_PROXIMITY, 60, 2, "PROXIMITYMINE", Obituary_ProximityMine);
			LaunchGrenade(shotorg, shotdir * 600 + v_up * 200, self, a * 150, a * 150, 200, GRENADE_IMPACT, 60, "SUPERNAILGUNGRENADE", Obituary_SuperNailgunGrenade);
			wsetanim(WANIM_FIRE2, 0, 0, 0.6);
		}
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
		registerweapon(6, "Grenade Launcher", w_grenadelauncher, "grenadelauncher", VWEP_GRENADE_LAUNCHER, "progs/v_dprock.mdl", IT_ROCKETS, 0, 2000, GRENADELAUNCHER_DAMAGE / GRENADELAUNCHER_REFIRE, WANIMTYPE_ROCKET);
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
	if (request == WR_ANIMATIONFINISH)
	{
		if (self.wanim_id == WANIM_LOWER)
			wswitch();
		else
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request == WR_AIM)
	{
		self.button0 = w_grenadeattackaim(1000, 2);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
	wanimate();
	self.currentammo = Inventory_Quantity(self, "rockets");
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
				LaunchGrenade(shotorg, shotdir * 1000 + v_up * 200, self, GRENADELAUNCHER_DAMAGE, GRENADELAUNCHER_FORCE, GRENADELAUNCHER_RADIUS, GRENADE_IMPACT | GRENADE_IMMUNETODAMAGE, 25, "GRENADE", Obituary_Grenade);
			else
				LaunchGrenade(shotorg, shotdir * 1000 + v_up * 200, self, GRENADELAUNCHER_DAMAGE, GRENADELAUNCHER_FORCE, GRENADELAUNCHER_RADIUS, GRENADE_IMMUNETODAMAGE, 3, "GRENADE", Obituary_Grenade);
			wsetanim(WANIM_FIRE1, 1, 6, GRENADELAUNCHER_REFIRE);
		}
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
	local float step;
	if (request == WR_REGISTER)
	{
		precache_model("progs/v_dprock2.mdl");
		precache_model("progs/missile.mdl");
		precache_sound("weapons/sgun1.wav");
		precache_sound("weapons/lock4.wav");
		registerweapon(7, "Rocket Launcher", w_rocketlauncher, "rocketlauncher", VWEP_ROCKET_LAUNCHER, "progs/v_dprock2.mdl", IT_ROCKETS, 0, 2000, ROCKETLAUNCHER_DAMAGE / ROCKETLAUNCHER_REFIRE, WANIMTYPE_ROCKET);
		return TRUE;
	}
	if (request == WR_HASAMMO)
		return Inventory_Quantity(self, "rockets") > 0;
	if (request == WR_SETUP)
	{
		self.wburst = 0;
		wsetanim(WANIM_RAISE, 8, -2, 0.2);
		return TRUE;
	}
	if (request == WR_INSTANTSETUP)
	{
		self.wburst = 0;
		wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request == WR_ANIMATIONFINISH)
	{
		if (self.wanim_id == WANIM_LOWER)
			wswitch();
		else
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request == WR_AIM)
	{
		self.button0 = w_directattackaim(ROCKETLAUNCHER_VELOCITY, 1);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
	wanimate();
	self.currentammo = Inventory_Quantity(self, "rockets");
	if (self.button3)
		self.detonatetimeout = time + 0.1;
	if (self.wanim_id == WANIM_READY)
	{
		if (self.switchweaponclass != self.weaponclass)
		{
			wsetanim(WANIM_LOWER, 7, 2, 0.2);
			return TRUE;
		}
		/*
		if (self.button3 || self.wburst < 1)
		if (self.wburst < ROCKETLAUNCHER_MAXLOAD)
		if (Inventory_Quantity(self, "rockets") >= self.wburst + 1)
		{
			self.wburst = self.wburst + 1;
			sound(self, CHAN_WEAPON, "weapons/lock4.wav", 1, ATTN_NORM);
			wsetanim(WANIM_FIRE1, 0, 0, ROCKETLAUNCHER_LOADTIME);
			return TRUE;
		}
		*/
		if (self.button0)
			self.wburst = 1;
		//if (self.button3)
		//	self.wburst = ROCKETLAUNCHER_MAXLOAD;
		if (self.wburst >= 1)
		if (self.wburst > Inventory_Quantity(self, "rockets"))
			self.wburst = Inventory_Quantity(self, "rockets");
		if (self.wburst >= 1)
		{
			W_Hostile();
			sound(self, CHAN_WEAPON, "weapons/sgun1.wav", 1, ATTN_NORM);
			//self.flags = self.flags - (self.flags & FL_ONGROUND);
			//self.velocity = self.velocity - shotdir * self.wburst * 150;
			Inventory_AdjustQuantity(self, "rockets", 0 - self.wburst);
			w_muzzleflash(shotorg, self.wburst * 4);
			if (self.wburst == 1)
			{
				self.wburst = self.wburst - 1;
				LaunchMissile(shotorg, shotdir * ROCKETLAUNCHER_VELOCITY, self, ROCKETLAUNCHER_DAMAGE, ROCKETLAUNCHER_FORCE, ROCKETLAUNCHER_RADIUS, "ROCKET", Obituary_Rocket);
			}
			else
			{
				step = 360 / self.wburst;
				while (self.wburst > 0)
				{
					self.wburst = self.wburst - 1;
					LaunchMissile(shotorg, shotdir * ROCKETLAUNCHER_MULTI_VELOCITY, self, ROCKETLAUNCHER_DAMAGE, ROCKETLAUNCHER_FORCE, ROCKETLAUNCHER_RADIUS, "ROCKET", Obituary_Rocket);
					//newmis.angles_z = step * self.wburst;
					newmis.dest3_z = step * self.wburst;
					newmis.dest2 = '0 8 0';
					newmis.avelocity = '0 0 1440';
				}
			}
			wsetanim(WANIM_FIRE1, 1, 6, ROCKETLAUNCHER_REFIRE);
			return TRUE;
		}
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
		registerweapon(9, "Plasma Rifle", w_plasmarifle, "plasmarifle", VWEP_SUPER_NAILGUN, "progs/v_dpnail2.mdl", IT_CELLS, 0, 1500, PLASMARIFLE_NORMAL_CELL * PLASMARIFLE_NORMAL_CELLS / PLASMARIFLE_NORMAL_REFIRE, WANIMTYPE_NAILGUN);
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
			if (self.button0)
			if (Inventory_Quantity(self, "cells"))
			{
				W_Hostile();
				sound(self, CHAN_WEAPON, "plasma/plasma.wav", 1, ATTN_NORM);
				w_muzzleflash(shotorg, 0);
				cells = Inventory_Quantity(self, "cells");
				if (cells > PLASMARIFLE_NORMAL_CELLS)
					cells = PLASMARIFLE_NORMAL_CELLS;
				FirePlasma(self, self, shotorg, shotdir * PLASMARIFLE_NORMAL_VELOCITY, PLASMARIFLE_NORMAL_CELL * cells, PLASMARIFLE_NORMAL_CELL * cells, PLASMARIFLE_NORMAL_RADIUS, "PLASMARIFLE", Obituary_PlasmaRifle);
				Inventory_AdjustQuantity(self, "cells", 0 - cells);
				//while (cells > 0)
				//{
				//	cells = cells - 1;
				//	ejectcasing(shotorg + v_forward * -5, v_right *  150 + v_up * 50, 100, self.v_angle_x * '-1 0 0' + self.v_angle_y * '0 1 0', '0 250 0', 100, 0);
				//}
				return TRUE;
			}
			wsetanim(WANIM_READY, 0, 0, 0);
		}
	}
	if (request == WR_ANIMATIONFINISH)
	{
		if (self.wanim_id == WANIM_LOWER)
			wswitch();
		else if (self.wanim_id == WANIM_FIRE1)
			wsetanim(WANIM_FIRE1, 1, 8, PLASMARIFLE_NORMAL_REFIRE * 8);
		else
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request == WR_AIM)
	{
		self.button0 = w_directattackaim(10000, 1);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
	wanimate();
	self.currentammo = Inventory_Quantity(self, "cells");
	if (self.wanim_id == WANIM_READY)
	{
		if (self.switchweaponclass != self.weaponclass)
		{
			wsetanim(WANIM_LOWER, 9, 2, 0.2);
			return TRUE;
		}
		if (self.button3)
		if (time > self.attack_finished)
		if (Inventory_Quantity(self, "cells") > 0)
		{
			W_Hostile();
			sound(self, CHAN_WEAPON, "plasma/plasma.wav", 1, ATTN_NORM);
			w_muzzleflash(shotorg, 2);
			cells = Inventory_Quantity(self, "cells");
			if (cells > PLASMARIFLE_SUPER_CELLS)
				cells = PLASMARIFLE_SUPER_CELLS;
			FirePlasma(self, self, shotorg, shotdir * PLASMARIFLE_SUPER_VELOCITY, PLASMARIFLE_SUPER_CELL * cells, PLASMARIFLE_SUPER_CELL * cells, PLASMARIFLE_SUPER_RADIUS, "PLASMARIFLE", Obituary_PlasmaRifle);
			Inventory_AdjustQuantity(self, "cells", 0 - cells);
			//while (cells > 0)
			//{
			//	cells = cells - 1;
			//	ejectcasing(shotorg + v_forward * -5, v_right *  150 + v_up * 50, 100, self.v_angle_x * '-1 0 0' + self.v_angle_y * '0 1 0', '0 250 0', 100, 0);
			//}
			self.attack_finished = time + PLASMARIFLE_SUPER_REFIRE;
			return TRUE;
		}
		if (self.button0)
		if (time > self.attack_finished)
		if (Inventory_Quantity(self, "cells") > 0)
		{
			wsetanim(WANIM_FIRE1, 1, 0, 0);
			return TRUE;
		}
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
	while (c < 50)
	{
		c = c + 1;
		// pass world instead of attacker so it can hit corpses (could also just set self to SOLID_BBOX) and hit owned objects like plasmacharges
		traceline(start, end, MOVE_MISSILE, world);
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
		if (e != attacker)
			T_Damage(e, inflictor, attacker, hdamage, bdamage, dmsg, dtype, trace_endpos, force, obitfunc);
		e = e.lightningchain;
	}
	return end;
};

.float wtime;
float(float request) w_thunderbolt =
{
	local float cells, f, wframetime;
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
		self.wtime = time;
		wsetanim(WANIM_RAISE, 6, -2, 0.2);
		return TRUE;
	}
	if (request == WR_INSTANTSETUP)
	{
		self.wtime = time;
		wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request == WR_ANIMATIONFRAME)
	{
		if (self.wanim_id == WANIM_FIRE1)
		{
			if (self.button0)
			if (Inventory_Quantity(self, "cells") >= 1)
			{
				self.wfiretime = time;
				W_Hostile();
				sound(self, CHAN_WEAPON, "weapons/lhit.wav", 1, ATTN_NORM);
				Inventory_AdjustQuantity(self, "cells", -1);
				v = W_BeamDamage(self, self, shotorg, shotorg + shotdir * 100000, THUNDERBOLT_CELL_HEALTH, THUNDERBOLT_CELL_BODY, "LIGHTNING", DT_LIGHTNING, Obituary_Lightning);
				te_lightning2(self, shotorg, v);
				return TRUE;
			}
			wsetanim(WANIM_READY, 0, 0, 0);
			return TRUE;
		}
		return TRUE;
	}
	if (request == WR_ANIMATIONFINISH)
	{
		if (self.wanim_id == WANIM_LOWER)
			wswitch();
		else if (self.wanim_id == WANIM_FIRE1)
			wsetanim(WANIM_FIRE1, 1, 4, 4 / THUNDERBOLT_CELLSPERSECOND);
		else
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request == WR_AIM)
	{
		self.button0 = w_directattackaim(100000, 1);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
	wframetime = time - self.wtime;
	self.wtime = time;
	wanimate();
	self.currentammo = Inventory_Quantity(self, "cells");
	if (self.wanim_id == WANIM_READY)
	{
		if (self.switchweaponclass != self.weaponclass)
		{
			wsetanim(WANIM_LOWER, 5, 2, 0.2);
			return TRUE;
		}
		if (self.button0)
		if (Inventory_Quantity(self, "cells") > 0)
		{
			sound(self, CHAN_AUTO, "weapons/lstart.wav", 1, ATTN_NORM);
			self.wfiretime = time;
			wsetanim(WANIM_FIRE1, 1, 4, 4 / THUNDERBOLT_CELLSPERSECOND);
		}
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
	if (request == WR_ANIMATIONFINISH)
	{
		if (self.wanim_id == WANIM_LOWER)
			wswitch();
		else if (self.wanim_id == WANIM_FIRE2)
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
				FirePlasmaBall(self, self, shotorg, v_forward * 1000, damage, damage, PLASMAWAVE_WAVE_BURNRADIUS, "PLASMAWAVE", Obituary_PlasmaWaveOverload);
				ang = ang + '0 1 0' * PLASMAWAVE_WAVE_SPREADANGLEPERSHOT;
			}
			wsetanim(WANIM_FIRE1, 0, 0, PLASMAWAVE_WAVE_REFIRE - PLASMAWAVE_WAVE_CHARGETIME);
		}
		else
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request == WR_AIM)
	{
		if (random() < 0.2)
			self.button3 = w_directattackaim(3000, 1);
		else
			self.button0 = w_directattackaim(5000, 1);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
	wanimate();
	self.currentammo = Inventory_Quantity(self, "cells");
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
			FirePlasmaBall(self, self, shotorg, shotdir * 1000, cells * PLASMAWAVE_SINGLE_CELL, cells * PLASMAWAVE_SINGLE_CELL, PLASMAWAVE_SINGLE_BURNRADIUS, "PLASMAWAVE", Obituary_PlasmaWaveShot);
			wsetanim(WANIM_FIRE1, 0, 0, PLASMAWAVE_SINGLE_REFIRE);
			return TRUE;
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
	if (request == WR_ANIMATIONFINISH)
	{
		if (self.wanim_id == WANIM_LOWER)
			wswitch();
		else if (self.wanim_id == WANIM_FIRE1)
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
		else
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request == WR_AIM)
	{
		self.button0 = w_directattackaim(10000, 1);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
	wanimate();
	self.currentammo = Inventory_Quantity(self, "cells");
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
	return TRUE;
};

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_Flamer =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " was set ablaze by ";
		deathstring3 = attacker.netname;
		deathstring4 = "'s flamer";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_FlamerShell =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " was charred by ";
		deathstring3 = attacker.netname;
		deathstring4 = "'s firebombs";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

float(float request) w_flamer =
{
	local float f;
	local vector v;
	if (request == WR_REGISTER)
	{
		precache_model("progs/v_dpshot.mdl");
		precache_model("progs/flame2.mdl");
		precache_model("progs/grenade.mdl");
		precache_model("progs/s_explod.spr");
		precache_sound("fire/launch.wav");
		precache_sound("fire/burn.wav");
		registerweapon(10, "Flamer", w_flamer, "flamer", VWEP_SHOTGUN, "progs/v_dpshot.mdl", IT_CELLS, 0, FLAMER_SHOT_VELOCITY, FLAMER_SHOT_DAMAGE / FLAMER_SHOT_REFIRE, WANIMTYPE_SHOTGUN);
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
	if (request == WR_ANIMATIONFINISH)
	{
		if (self.wanim_id == WANIM_LOWER)
			wswitch();
		else if (self.wanim_id == WANIM_FIRE1)
		{
			if (self.button0)
			if (Inventory_Quantity(self, "cells"))
			{
				W_Hostile();
				sound(self, CHAN_WEAPON, "enforcer/enfire.wav", 1, ATTN_NORM);
				Inventory_AdjustQuantity(self, "cells", 0 - FLAMER_SHOT_CELLS);
				w_muzzleflash(shotorg, 1);
				//LaunchFlamer(self, shotorg, shotdir * FLAMER_SHOT_VELOCITY, FLAMER_SHOT_TIME, FLAMER_SHOT_DAMAGE, FLAMER_SHOT_FORCE, FLAMER_SHOT_RADIUS, "FLAMER", Obituary_Flamer);
				LaunchFireball(shotorg, shotdir * FLAMER_SHOT_VELOCITY, self, FLAMER_SHOT_DAMAGE, FLAMER_SHOT_FORCE, FLAMER_SHOT_RADIUS, FLAMER_SHOT_BURN, FLAMER_SHOT_BURNLIMIT, "FLAMER", Obituary_Flamer);
				wsetanim(WANIM_FIRE1, 1, 0, FLAMER_SHOT_REFIRE);
				return TRUE;
			}
			wsetanim(WANIM_FIRE2, 2, 5, FLAMER_SHOT_COOLDOWN);
		}
		else
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request == WR_AIM)
	{
		self.button0 = w_directattackaim(FLAMER_SHOT_VELOCITY, FLAMER_SHOT_TIME);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
	wanimate();
	self.currentammo = Inventory_Quantity(self, "cells");
	if (self.wanim_id == WANIM_READY)
	{
		if (self.switchweaponclass != self.weaponclass)
		{
			wsetanim(WANIM_LOWER, 7, 2, 0.2);
			return TRUE;
		}
		if (self.button0)
		{
			if (Inventory_Quantity(self, "cells") >= FLAMER_SHOT_CELLS)
				wsetanim(WANIM_FIRE1, 1, 0, 0);
		}
		else if (self.button3)
		{
			if (Inventory_Quantity(self, "cells") >= FLAMER_DROP_CELLS)
			{
				W_Hostile();
				sound(self, CHAN_WEAPON, "enforcer/enfire.wav", 1, ATTN_NORM);
				Inventory_AdjustQuantity(self, "cells", 0 - FLAMER_DROP_CELLS);
				w_muzzleflash(shotorg, 1);
				f = 0;
				while (f < FLAMER_DROP_COUNT)
				{
					f = f + 1;
					v = (shotdir + randomvec() * FLAMER_DROP_SPREAD) * FLAMER_DROP_VELOCITY + '0 0 1' * FLAMER_DROP_UPVELOCITY;
					//LaunchFireBomb(self, shotorg, v, FLAMER_DROP_TIME, FLAMER_DROP_DAMAGE, FLAMER_DROP_FORCE, FLAMER_DROP_RADIUS, "FLAMERSHELL", Obituary_FlamerShell);
					LaunchGrenade(shotorg, v, self, FLAMER_DROP_DAMAGE, FLAMER_DROP_FORCE, FLAMER_DROP_RADIUS, GRENADE_DETONATEONCREATURE, FLAMER_DROP_TIME, "FLAMERSHELL", Obituary_FlamerShell);
				}
				wsetanim(WANIM_FIRE2, 1, 6, FLAMER_DROP_REFIRE);
			}
		}
		return TRUE;
	}
	return TRUE;
};

/*
float PISTOL_NAIL = 30;
float PISTOL_NAILS = 1;
float PISTOL_EMPTY = 15; // damage pistol does when empty (0 = disable)
float PISTOL_REFIRE = 0.7;

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
		return TRUE;//PISTOL_EMPTY > 0 || Inventory_Quantity(self, "nails") > 0;
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
	if (request == WR_ANIMATIONFINISH)
	{
		if (self.wanim_id == WANIM_LOWER)
			wswitch();
		else
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request == WR_AIM)
	{
		self.button0 = w_directattackaim(10000, 1);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
	wanimate();
	self.currentammo = Inventory_Quantity(self, "nails");
	if (self.wanim_id == WANIM_READY)
	{
		if (self.switchweaponclass != self.weaponclass)
		{
			wsetanim(WANIM_LOWER, 7, 2, 0.2);
			return TRUE;
		}
		if (self.button0)
		//if (Inventory_Quantity(self, "nails") > 0 || PISTOL_EMPTY > 0)
		{
			W_Hostile();
			sound(self, CHAN_WEAPON, "weapons/rocket1i.wav", 1, ATTN_NORM);
			w_muzzleflash(shotorg, 2);
			if (Inventory_Quantity(self, "nails") >= 1)
			{
				Inventory_AdjustQuantity(self, "nails", -1);
				FireBullets(self, self, 1, 1, PISTOL_NAIL, PISTOL_NAIL, 0, 0, shotdir * 10000, 0.025, "PISTOL", DT_NAIL, Obituary_Pistol);
				//ejectcasing(shotorg + v_forward * -5, v_right * 150 + v_up * 50, 50, self.v_angle_x * '-1 0 0' + self.v_angle_y * '0 1 0', '0 250 0', 100, 0);
			}
			else
				FireBullets(self, self, 1, 1, PISTOL_EMPTY, PISTOL_EMPTY, 0, 0, shotdir * 10000, 0.025, "PISTOL", DT_NAIL, Obituary_Pistol);
			wsetanim(WANIM_FIRE1, 1, 6, PISTOL_REFIRE);
		}
		return TRUE;
	}
	return TRUE;
};

float CHAINSAW_DAMAGE = 15;
float CHAINSAW_REFIRE = 0.1;

float HANDGRENADE_DAMAGE = 120;
float HANDGRENADE_FORCE = 120;
float HANDGRENADE_RADIUS = 200;
float HANDGRENADE_REFIRE = 0.9;

float HOPPER_DAMAGE = 120;
float HOPPER_FORCE = 120;
float HOPPER_RADIUS = 200;
float HOPPER_REFIRE = 0.6;

float PRICKLER_DAMAGE = 25;
float PRICKLER_REFIRE = 0.2;

float SCATTERGUN_RAPIDDAMAGE = 25;
float SCATTERGUN_RAPIDAMMO = 1;
float SCATTERGUN_RAPIDREFIRE = 0.1;
float SCATTERGUN_BLASTDAMAGE = 25;
float SCATTERGUN_BLASTAMMO = 5;
float SCATTERGUN_BLASTREFIRE = 0.8;

float RIFLE_DAMAGE = 90;
float RIFLE_REFIRE = 0.9;

float MACHINEGUN_DAMAGE = 25;
float MACHINEGUN_REFIRE = 0.1;

float VULCAN_DAMAGE = 25;
float VULCAN_REFIRE = 0.05;

float EXECUTIONER_DAMAGE = 90;
float EXECUTIONER_RADIUS = 90;
float EXECUTIONER_REFIRE = 0.5;

float JACKHAMMER_DAMAGE = 90;
float JACKHAMMER_RADIUS = 90;
float JACKHAMMER_RAPIDREFIRE = 0.2;
float JACKHAMMER_SINGLEREFIRE = 0.5;

float GRENADELAUNCHER2_DAMAGE = 120;
float GRENADELAUNCHER2_FORCE = 120;
float GRENADELAUNCHER2_AMMO = 3;
float GRENADELAUNCHER2_RADIUS = 200;
float GRENADELAUNCHER2_REFIRE = 0.6;

float BACKPACKMORTAR_DAMAGE = 100;
float BACKPACKMORTAR_FORCE = 100;
float BACKPACKMORTAR_AMMO = 3;
float BACKPACKMORTAR_RADIUS = 250;
float BACKPACKMORTAR_REFIRE = 0.6;

float INCINERATOR_DAMAGE = 40;
float INCINERATOR_REFIRE = 0.05;

float RAILGUN_DAMAGE = 90;
float RAILGUN_REFIRE = 0.9;

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_Chainsaw =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " was chainsawed by ";
		deathstring3 = attacker.netname;
		deathstring4 = "";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

.float chainsaw_finished;
float(float request) w_chainsaw =
{
	local float f;
	local vector v;
	if (request == WR_REGISTER)
	{
		precache_model("progs/v_saw.mdl");
		precache_sound("weapons/sawidle.wav");
		precache_sound("weapons/sawridle.wav");
		precache_sound("weapons/sawatck.wav");
		precache_sound("weapons/sawguts.wav");
		registerweapon(1, "Chainsaw", w_chainsaw, "chainsaw", VWEP_AXE, "progs/v_saw.mdl", 0, 0, 2000, CHAINSAW_DAMAGE / CHAINSAW_REFIRE, WANIMTYPE_SHOTGUN);
		return TRUE;
	}
	if (request == WR_HASAMMO)
		return TRUE;
	if (request == WR_SETUP)
	{
		self.chainsaw_finished = time + 4;
		sound(self, CHAN_AUTO, "weapons/sawidle.wav", 1, ATTN_STATIC);
		//wsetanim(WANIM_LOWER, 8, -2, 0.2);
		wsetanim(WANIM_READY, 0, 5, 0.5);
		return TRUE;
	}
	if (request == WR_INSTANTSETUP)
	{
		wsetanim(WANIM_READY, 0, 5, 0.5);
		return TRUE;
	}
	if (request == WR_ANIMATIONFRAME)
	{
		if (self.wanim_id == WANIM_FIRE1)
		{
			if (!self.button0)
			{
				wsetanim(WANIM_READY, 0, 5, 0.5);
				return TRUE;
			}

			W_Hostile();
			if (time >= self.chainsaw_finished)
			{
				self.chainsaw_finished = time + random() * 0.6 + 0.8;
				sound(self, CHAN_WEAPON, "weapons/sawatck.wav", 1, ATTN_STATIC);
			}

			// change solid type so the traceline hits SOLID_CORPSE
			f = self.solid;
			self.solid = SOLID_BBOX;
			traceline (shotorg, shotorg + shotdir * 64, FALSE, self);
			self.solid = f;

			if (trace_fraction < 1)
			{
				if (trace_ent.solid == SOLID_BSP)
				{
					sound (self, CHAN_AUTO, "player/axhit2.wav", 1, ATTN_NORM);
					te_gunshot(trace_endpos - shotdir * 4);
				}
				if (trace_ent.iscreature)
					sound(self, CHAN_AUTO, "weapons/sawguts.wav", 1, ATTN_STATIC);
				T_Damage (trace_ent, self, self, CHAINSAW_DAMAGE, CHAINSAW_DAMAGE, "CHAINSAW", DT_CUT, trace_endpos - shotdir * 4, '0 0 0', Obituary_Chainsaw);
			}
		}
		return TRUE;
	}
	if (request == WR_ANIMATIONFINISH)
	{
		if (self.wanim_id == WANIM_LOWER)
			wswitch();
		else if (self.wanim_id == WANIM_FIRE1)
			wsetanim(WANIM_FIRE1, 5, 6, CHAINSAW_REFIRE * 6);
		else
			wsetanim(WANIM_READY, 0, 5, 0.5);
		return TRUE;
	}
	if (request == WR_AIM)
	{
		self.button0 = w_directattackaim(10000, 1);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
	wanimate();
	self.currentammo = 0;
	if (self.wanim_id == WANIM_READY)
	{
		if (time >= self.chainsaw_finished)
		{
			self.chainsaw_finished = time + random() * 0.6 + 0.8;
			sound(self, CHAN_WEAPON, "weapons/sawridle.wav", 1, ATTN_STATIC);
		}
		if (self.switchweaponclass != self.weaponclass)
		{
			//wsetanim(WANIM_LOWER, 7, 2, 0.2);
			wswitch();
			return TRUE;
		}
		if (self.button0)
		{
			self.chainsaw_finished = time + random() * 0.6 + 0.8;
			sound(self, CHAN_WEAPON, "weapons/sawatck.wav", 1, ATTN_STATIC);
			wsetanim(WANIM_FIRE1, 5, 6, CHAINSAW_REFIRE * 6);
		}
		return TRUE;
	}
	return TRUE;
};

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_Hopper =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " was blasted by a hopper from ";
		deathstring3 = attacker.netname;
		deathstring4 = "";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

float(float request) w_hopper =
{
	if (request == WR_REGISTER)
	{
		precache_model("progs/v_dprock.mdl");
		precache_model("progs/grenade.mdl");
		precache_sound("weapons/grenade.wav");
		precache_sound("weapons/bounce.wav");
		registerweapon(1, "Hopper ", w_hopper, "hopper", VWEP_GRENADE_LAUNCHER, "progs/v_dprock.mdl", IT_ROCKETS, 0, 2000, HOPPER_DAMAGE / HOPPER_REFIRE, WANIMTYPE_ROCKET);
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
	if (request == WR_ANIMATIONFINISH)
	{
		if (self.wanim_id == WANIM_LOWER)
			wswitch();
		else
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request == WR_AIM)
	{
		self.button0 = w_grenadeattackaim(1000, 2);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
	wanimate();
	self.currentammo = Inventory_Quantity(self, "rockets");
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
				LaunchGrenade(shotorg, shotdir * 1000 + v_up * 200, self, HOPPER_DAMAGE, HOPPER_FORCE, HOPPER_RADIUS, GRENADE_IMPACT | GRENADE_IMMUNETODAMAGE, 25, "HOPPER", Obituary_Hopper);
			else
				LaunchGrenade(shotorg, shotdir * 1000 + v_up * 200, self, HOPPER_DAMAGE, HOPPER_FORCE, HOPPER_RADIUS, GRENADE_IMMUNETODAMAGE, 3, "HOPPER", Obituary_Hopper);
			wsetanim(WANIM_FIRE1, 1, 6, HOPPER_REFIRE);
		}
		return TRUE;
	}
	return TRUE;
};

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_Grenade3 =
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

float(float request) w_handgrenade =
{
	if (request == WR_REGISTER)
	{
		precache_model("progs/v_dprock.mdl");
		precache_model("progs/grenade.mdl");
		precache_sound("weapons/grenade.wav");
		precache_sound("weapons/bounce.wav");
		registerweapon(1, "Grenade", w_handgrenade, "handgrenade", VWEP_GRENADE_LAUNCHER, "progs/v_dprock.mdl", IT_ROCKETS, 0, 2000, HANDGRENADE_DAMAGE / HANDGRENADE_REFIRE, WANIMTYPE_ROCKET);
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
	if (request == WR_ANIMATIONFINISH)
	{
		if (self.wanim_id == WANIM_LOWER)
			wswitch();
		else
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request == WR_AIM)
	{
		self.button0 = w_directattackaim(1000, 2);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
	wanimate();
	self.currentammo = Inventory_Quantity(self, "rockets");
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
				LaunchGrenade(shotorg, shotdir * 1000 + v_up * 200, self, HANDGRENADE_DAMAGE, HANDGRENADE_FORCE, HANDGRENADE_RADIUS, GRENADE_IMPACT | GRENADE_IMMUNETODAMAGE, 25, "GRENADE", Obituary_Grenade3);
			else
				LaunchGrenade(shotorg, shotdir * 1000 + v_up * 200, self, HANDGRENADE_DAMAGE, HANDGRENADE_FORCE, HANDGRENADE_RADIUS, GRENADE_IMMUNETODAMAGE, 3, "GRENADE", Obituary_Grenade3);
			wsetanim(WANIM_FIRE1, 1, 6, HANDGRENADE_REFIRE);
		}
		return TRUE;
	}
	return TRUE;
};

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_Prickler =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " was prickled by ";
		deathstring3 = attacker.netname;
		deathstring4 = "";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

float(float request) w_prickler =
{
	local float f;
	local vector v;
	if (request == WR_REGISTER)
	{
		precache_model("progs/v_dpshot.mdl");
		precache_model("progs/spike.mdl");
		precache_sound("weapons/rocket1i.wav");
		registerweapon(2, "Prickler", w_prickler, "prickler", VWEP_SHOTGUN, "progs/v_dpshot.mdl", 0, 0, 2000, PRICKLER_DAMAGE / PRICKLER_REFIRE, WANIMTYPE_SHOTGUN);
		return TRUE;
	}
	if (request == WR_HASAMMO)
		return Inventory_Quantity(self, "shells");
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
	if (request == WR_ANIMATIONFINISH)
	{
		if (self.wanim_id == WANIM_LOWER)
			wswitch();
		else
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request == WR_AIM)
	{
		self.button0 = w_directattackaim(10000, 1);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
	wanimate();
	self.currentammo = Inventory_Quantity(self, "shells");
	if (self.wanim_id == WANIM_READY)
	{
		if (self.switchweaponclass != self.weaponclass)
		{
			wsetanim(WANIM_LOWER, 7, 2, 0.2);
			return TRUE;
		}
		if (self.button0)
		if (Inventory_Quantity(self, "shells"))
		{
			W_Hostile();
			sound(self, CHAN_WEAPON, "weapons/rocket1i.wav", 1, ATTN_NORM);
			Inventory_AdjustQuantity(self, "shells", -1);
			w_muzzleflash(shotorg, 0.5);
			FireBullets(self, self, 1, 1, PRICKLER_DAMAGE, PRICKLER_DAMAGE, 0, 0, shotdir * 10000, 0.025, "PRICKLER", DT_NAIL, Obituary_Prickler);
			wsetanim(WANIM_FIRE1, 1, 0, PRICKLER_REFIRE);
		}
		return TRUE;
	}
	return TRUE;
};

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_Scattergun =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " was prickled by ";
		deathstring3 = attacker.netname;
		deathstring4 = "";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

float(float request) w_scattergun =
{
	local float f;
	local vector v;
	if (request == WR_REGISTER)
	{
		precache_model("progs/v_dpshot.mdl");
		precache_model("progs/spike.mdl");
		precache_sound("weapons/shotgn2.wav");
		registerweapon(2, "Scattergun", w_scattergun, "scattergun", VWEP_SHOTGUN, "progs/v_dpshot.mdl", 0, 0, 2000, SCATTERGUN_RAPIDDAMAGE * SCATTERGUN_RAPIDAMMO / SCATTERGUN_RAPIDREFIRE, WANIMTYPE_SHOTGUN);
		return TRUE;
	}
	if (request == WR_HASAMMO)
		return Inventory_Quantity(self, "shells");
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
	if (request == WR_ANIMATIONFINISH)
	{
		if (self.wanim_id == WANIM_LOWER)
			wswitch();
		else
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request == WR_AIM)
	{
		self.button0 = w_directattackaim(10000, 1);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
	wanimate();
	self.currentammo = Inventory_Quantity(self, "shells");
	if (self.wanim_id == WANIM_READY)
	{
		if (self.switchweaponclass != self.weaponclass)
		{
			wsetanim(WANIM_LOWER, 7, 2, 0.2);
			return TRUE;
		}
		if (self.button0)
		if (Inventory_Quantity(self, "shells"))
		{
			W_Hostile();
			sound(self, CHAN_WEAPON, "weapons/shotgn2.wav", 1, ATTN_NORM);
			f = Inventory_Quantity(self, "shells");
			if (f > SCATTERGUN_RAPIDAMMO)
				f = SCATTERGUN_RAPIDAMMO;
			Inventory_AdjustQuantity(self, "shells", 0 - f);
			w_muzzleflash(shotorg, 0.5);
			FireBullets(self, self, 1, f, SCATTERGUN_RAPIDDAMAGE, SCATTERGUN_RAPIDDAMAGE, 0, 0, shotdir * 10000, 0.05, "SCATTERGUN", DT_NAIL, Obituary_Scattergun);
			wsetanim(WANIM_FIRE1, 1, 0, SCATTERGUN_RAPIDREFIRE);
			return TRUE;
		}
		if (self.button3)
		if (Inventory_Quantity(self, "shells"))
		{
			W_Hostile();
			sound(self, CHAN_WEAPON, "weapons/shotgn2.wav", 1, ATTN_NORM);
			f = Inventory_Quantity(self, "shells");
			if (f > SCATTERGUN_BLASTAMMO)
				f = SCATTERGUN_BLASTAMMO;
			Inventory_AdjustQuantity(self, "shells", 0 - f);
			w_muzzleflash(shotorg, 0.5);
			FireBullets(self, self, 1, f, SCATTERGUN_BLASTDAMAGE, SCATTERGUN_BLASTDAMAGE, 0, 0, shotdir * 10000, 0.05, "SCATTERGUN", DT_NAIL, Obituary_Scattergun);
			wsetanim(WANIM_FIRE1, 1, 0, SCATTERGUN_BLASTREFIRE);
			return TRUE;
		}
		return TRUE;
	}
	return TRUE;
};

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_Rifle =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " was eliminated by a rifle round from ";
		deathstring3 = attacker.netname;
		deathstring4 = "";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

float(float request) w_rifle =
{
	local float f;
	local vector v;
	if (request == WR_REGISTER)
	{
		precache_model("progs/v_dpshot.mdl");
		precache_model("progs/spike.mdl");
		precache_sound("weapons/rocket1i.wav");
		registerweapon(3, "Rifle", w_rifle, "rifle", VWEP_SHOTGUN, "progs/v_dpshot.mdl", 0, 0, 2000, RIFLE_DAMAGE / RIFLE_REFIRE, WANIMTYPE_SHOTGUN);
		return TRUE;
	}
	if (request == WR_HASAMMO)
		return Inventory_Quantity(self, "shells");
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
	if (request == WR_ANIMATIONFINISH)
	{
		if (self.wanim_id == WANIM_LOWER)
			wswitch();
		else
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request == WR_AIM)
	{
		self.button0 = w_directattackaim(10000, 1);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
	wanimate();
	self.currentammo = Inventory_Quantity(self, "shells");
	if (self.wanim_id == WANIM_READY)
	{
		if (self.switchweaponclass != self.weaponclass)
		{
			wsetanim(WANIM_LOWER, 7, 2, 0.2);
			return TRUE;
		}
		if (self.button0)
		if (Inventory_Quantity(self, "shells"))
		{
			W_Hostile();
			sound(self, CHAN_WEAPON, "weapons/rocket1i.wav", 1, ATTN_NORM);
			Inventory_AdjustQuantity(self, "shells", -1);
			w_muzzleflash(shotorg, 0.5);
			FireBullets(self, self, 1, 1, RIFLE_DAMAGE, RIFLE_DAMAGE, 0, 0, shotdir * 10000, 0, "RIFLE", DT_NAIL, Obituary_Rifle);
			wsetanim(WANIM_FIRE1, 1, 0, RIFLE_REFIRE);
		}
		return TRUE;
	}
	return TRUE;
};

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_Machinegun =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " was machinegunned by ";
		deathstring3 = attacker.netname;
		deathstring4 = "";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

float(float request) w_machinegun =
{
	local float f;
	local vector v;
	if (request == WR_REGISTER)
	{
		precache_model("progs/v_dpshot.mdl");
		precache_model("progs/spike.mdl");
		precache_sound("weapons/rocket1i.wav");
		registerweapon(4, "Machinegun", w_machinegun, "machinegun", VWEP_SHOTGUN, "progs/v_dpshot.mdl", 0, 0, 2000, MACHINEGUN_DAMAGE / MACHINEGUN_REFIRE, WANIMTYPE_SHOTGUN);
		return TRUE;
	}
	if (request == WR_HASAMMO)
		return Inventory_Quantity(self, "nails");
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
	if (request == WR_ANIMATIONFINISH)
	{
		if (self.wanim_id == WANIM_LOWER)
			wswitch();
		else
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request == WR_AIM)
	{
		self.button0 = w_directattackaim(10000, 1);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
	wanimate();
	self.currentammo = Inventory_Quantity(self, "nails");
	if (self.wanim_id == WANIM_READY)
	{
		if (self.switchweaponclass != self.weaponclass)
		{
			wsetanim(WANIM_LOWER, 7, 2, 0.2);
			return TRUE;
		}
		if (self.button0)
		if (Inventory_Quantity(self, "nails"))
		{
			W_Hostile();
			sound(self, CHAN_WEAPON, "weapons/rocket1i.wav", 1, ATTN_NORM);
			Inventory_AdjustQuantity(self, "nails", -1);
			w_muzzleflash(shotorg, 0.5);
			FireBullets(self, self, 1, 1, MACHINEGUN_DAMAGE, MACHINEGUN_DAMAGE, 0, 0, shotdir * 10000, 0.025, "MACHINEGUN", DT_NAIL, Obituary_Machinegun);
			wsetanim(WANIM_FIRE1, 1, 0, MACHINEGUN_REFIRE);
		}
		return TRUE;
	}
	return TRUE;
};

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_Vulcan =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " was vulcanned by ";
		deathstring3 = attacker.netname;
		deathstring4 = "";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

float(float request) w_vulcan =
{
	local float f;
	local vector v;
	if (request == WR_REGISTER)
	{
		precache_model("progs/v_dpshot.mdl");
		precache_model("progs/spike.mdl");
		precache_sound("weapons/rocket1i.wav");
		registerweapon(5, "Vulcan", w_vulcan, "vulcan", VWEP_SHOTGUN, "progs/v_dpshot.mdl", 0, 0, 2000, VULCAN_DAMAGE / VULCAN_REFIRE, WANIMTYPE_SHOTGUN);
		return TRUE;
	}
	if (request == WR_HASAMMO)
		return Inventory_Quantity(self, "nails");
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
	if (request == WR_ANIMATIONFINISH)
	{
		if (self.wanim_id == WANIM_LOWER)
			wswitch();
		else
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request == WR_AIM)
	{
		self.button0 = w_directattackaim(10000, 1);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
	wanimate();
	self.currentammo = Inventory_Quantity(self, "nails");
	if (self.wanim_id == WANIM_READY)
	{
		if (self.switchweaponclass != self.weaponclass)
		{
			wsetanim(WANIM_LOWER, 7, 2, 0.2);
			return TRUE;
		}
		if (self.button0)
		if (Inventory_Quantity(self, "nails"))
		{
			W_Hostile();
			sound(self, CHAN_WEAPON, "weapons/rocket1i.wav", 1, ATTN_NORM);
			Inventory_AdjustQuantity(self, "nails", -1);
			w_muzzleflash(shotorg, 0.5);
			FireBullets(self, self, 1, 1, VULCAN_DAMAGE, VULCAN_DAMAGE, 0, 0, shotdir * 10000, 0.05, "VULCAN", DT_NAIL, Obituary_Vulcan);
			wsetanim(WANIM_FIRE1, 1, 0, VULCAN_REFIRE);
		}
		return TRUE;
	}
	return TRUE;
};

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_Executioner =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " was executionerned by ";
		deathstring3 = attacker.netname;
		deathstring4 = "";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

float(float request) w_executioner =
{
	local float f;
	local vector v;
	if (request == WR_REGISTER)
	{
		precache_model("progs/v_dpshot.mdl");
		precache_model("progs/spike.mdl");
		precache_sound("weapons/rocket1i.wav");
		registerweapon(6, "Executioner", w_executioner, "executioner", VWEP_SHOTGUN, "progs/v_dpshot.mdl", 0, 0, 2000, EXECUTIONER_DAMAGE / EXECUTIONER_REFIRE, WANIMTYPE_SHOTGUN);
		return TRUE;
	}
	if (request == WR_HASAMMO)
		return Inventory_Quantity(self, "rockets");
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
	if (request == WR_ANIMATIONFINISH)
	{
		if (self.wanim_id == WANIM_LOWER)
			wswitch();
		else
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request == WR_AIM)
	{
		self.button0 = w_directattackaim(10000, 1);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
	wanimate();
	self.currentammo = Inventory_Quantity(self, "rockets");
	if (self.wanim_id == WANIM_READY)
	{
		if (self.switchweaponclass != self.weaponclass)
		{
			wsetanim(WANIM_LOWER, 7, 2, 0.2);
			return TRUE;
		}
		if (self.button0)
		if (Inventory_Quantity(self, "rockets"))
		{
			W_Hostile();
			sound(self, CHAN_WEAPON, "weapons/rocket1i.wav", 1, ATTN_NORM);
			Inventory_AdjustQuantity(self, "rockets", -1);
			w_muzzleflash(shotorg, 0.5);
			FireBullets(self, self, 1, 1, 0, 0, EXECUTIONER_DAMAGE, EXECUTIONER_RADIUS, shotdir * 10000, 0.025, "EXECUTIONER", DT_NAIL, Obituary_Executioner);
			wsetanim(WANIM_FIRE1, 1, 0, EXECUTIONER_REFIRE);
		}
		return TRUE;
	}
	return TRUE;
};

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_Jackhammer =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " was jackhammerned by ";
		deathstring3 = attacker.netname;
		deathstring4 = "";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

float(float request) w_jackhammer =
{
	local float f;
	local vector v;
	if (request == WR_REGISTER)
	{
		precache_model("progs/v_dpshot.mdl");
		precache_model("progs/spike.mdl");
		precache_sound("weapons/rocket1i.wav");
		registerweapon(6, "Jackhammer", w_jackhammer, "rocketlauncher", VWEP_SHOTGUN, "progs/v_dpshot.mdl", 0, 0, 2000, JACKHAMMER_DAMAGE / JACKHAMMER_RAPIDREFIRE, WANIMTYPE_SHOTGUN);
		return TRUE;
	}
	if (request == WR_HASAMMO)
		return Inventory_Quantity(self, "rockets");
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
	if (request == WR_ANIMATIONFINISH)
	{
		if (self.wanim_id == WANIM_LOWER)
			wswitch();
		else
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request == WR_AIM)
	{
		self.button0 = w_directattackaim(10000, 1);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
	wanimate();
	self.currentammo = Inventory_Quantity(self, "rockets");
	if (self.wanim_id == WANIM_READY)
	{
		if (self.switchweaponclass != self.weaponclass)
		{
			wsetanim(WANIM_LOWER, 7, 2, 0.2);
			return TRUE;
		}
		if (self.button0)
		if (Inventory_Quantity(self, "rockets"))
		{
			W_Hostile();
			sound(self, CHAN_WEAPON, "weapons/rocket1i.wav", 1, ATTN_NORM);
			Inventory_AdjustQuantity(self, "rockets", -1);
			w_muzzleflash(shotorg, 0.5);
			FireBullets(self, self, 1, 1, 0, 0, JACKHAMMER_DAMAGE, JACKHAMMER_RADIUS, shotdir * 10000, 0.05, "JACKHAMMER", DT_NAIL, Obituary_Jackhammer);
			wsetanim(WANIM_FIRE1, 1, 0, JACKHAMMER_RAPIDREFIRE);
			return TRUE;
		}
		if (self.button3)
		if (Inventory_Quantity(self, "rockets"))
		{
			W_Hostile();
			sound(self, CHAN_WEAPON, "weapons/rocket1i.wav", 1, ATTN_NORM);
			Inventory_AdjustQuantity(self, "rockets", -1);
			w_muzzleflash(shotorg, 0.5);
			FireBullets(self, self, 1, 1, 0, 0, JACKHAMMER_DAMAGE, JACKHAMMER_RADIUS, shotdir * 10000, 0.0125, "JACKHAMMER", DT_NAIL, Obituary_Jackhammer);
			wsetanim(WANIM_FIRE1, 1, 0, JACKHAMMER_SINGLEREFIRE);
			return TRUE;
		}
		return TRUE;
	}
	return TRUE;
};

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_Grenade2 =
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

float(float request) w_grenadelauncher2 =
{
	local float f;
	if (request == WR_REGISTER)
	{
		precache_model("progs/v_dprock.mdl");
		precache_model("progs/grenade.mdl");
		precache_sound("weapons/grenade.wav");
		precache_sound("weapons/bounce.wav");
		registerweapon(7, "Grenade Launcher", w_grenadelauncher2, "grenadelauncher", VWEP_GRENADE_LAUNCHER, "progs/v_dprock.mdl", IT_ROCKETS, 0, 2000, GRENADELAUNCHER2_DAMAGE / GRENADELAUNCHER2_REFIRE, WANIMTYPE_ROCKET);
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
	if (request == WR_ANIMATIONFINISH)
	{
		if (self.wanim_id == WANIM_LOWER)
			wswitch();
		else
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request == WR_AIM)
	{
		self.button0 = w_grenadeattackaim(1000, 2);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
	wanimate();
	self.currentammo = Inventory_Quantity(self, "rockets");
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
			f = Inventory_Quantity(self, "rockets");
			if (f > GRENADELAUNCHER2_AMMO)
				f = GRENADELAUNCHER2_AMMO;
			Inventory_AdjustQuantity(self, "rockets", 0 - f);
			w_muzzleflash(shotorg, 2);
			if (self.button0)
				LaunchGrenade(shotorg, shotdir * 1000 + v_up * 200, self, GRENADELAUNCHER2_DAMAGE * f, GRENADELAUNCHER2_FORCE * f, GRENADELAUNCHER2_RADIUS, GRENADE_IMPACT | GRENADE_IMMUNETODAMAGE, 25, "GRENADE", Obituary_Grenade2);
			else
				LaunchGrenade(shotorg, shotdir * 1000 + v_up * 200, self, GRENADELAUNCHER2_DAMAGE * f, GRENADELAUNCHER2_FORCE * f, GRENADELAUNCHER2_RADIUS, GRENADE_IMMUNETODAMAGE, 3, "GRENADE", Obituary_Grenade2);
			wsetanim(WANIM_FIRE1, 1, 6, GRENADELAUNCHER_REFIRE);
		}
		return TRUE;
	}
	return TRUE;
};

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_BackpackMortar =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " was blasted by a mortar from ";
		deathstring3 = attacker.netname;
		deathstring4 = "";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

float(float request) w_backpackmortar =
{
	local float f;
	local vector v;
	if (request == WR_REGISTER)
	{
		//precache_model("progs/v_dprock.mdl");
		precache_model("progs/grenade.mdl");
		precache_sound("weapons/grenade.wav");
		precache_sound("weapons/bounce.wav");
		registerweapon(6, "Backpack Mortar", w_backpackmortar, "backpackmortar", VWEP_GRENADE_LAUNCHER, "", IT_ROCKETS, 0, 2000, BACKPACKMORTAR_DAMAGE / BACKPACKMORTAR_REFIRE, WANIMTYPE_ROCKET);
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
	if (request == WR_ANIMATIONFINISH)
	{
		if (self.wanim_id == WANIM_LOWER)
			wswitch();
		else
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request == WR_AIM)
	{
		self.button0 = w_grenadeattackaim(1000, 2);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
	wanimate();
	self.currentammo = Inventory_Quantity(self, "rockets");
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
			f = Inventory_Quantity(self, "rockets");
			if (f > BACKPACKMORTAR_AMMO)
				f = BACKPACKMORTAR_AMMO;
			Inventory_AdjustQuantity(self, "rockets", 0 - f);
			w_muzzleflash(shotorg, 4);
			while (f > 0)
			{
				v = shotdir * 200 + v_up * 600 + randomvec() * f * 30;
				if (self.button3)
					LaunchGrenade(shotorg, v, self, BACKPACKMORTAR_DAMAGE, BACKPACKMORTAR_FORCE, BACKPACKMORTAR_RADIUS, GRENADE_IMPACT | GRENADE_IMMUNETODAMAGE, 25, "BACKPACKMORTAR", Obituary_BackpackMortar);
				else
					LaunchGrenade(shotorg, v, self, BACKPACKMORTAR_DAMAGE, BACKPACKMORTAR_FORCE, BACKPACKMORTAR_RADIUS, GRENADE_IMMUNETODAMAGE, 1.5, "BACKPACKMORTAR", Obituary_BackpackMortar);
				f = f - 1;
			}
			wsetanim(WANIM_FIRE1, 1, 6, BACKPACKMORTAR_REFIRE);
		}
		return TRUE;
	}
	return TRUE;
};

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_Incinerator =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " was incinerated by ";
		deathstring3 = attacker.netname;
		deathstring4 = "";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

.float incinerator_time;
float(float request) w_incinerator =
{
	local float f;
	local vector v;
	if (request == WR_REGISTER)
	{
		precache_model("progs/v_dpshot.mdl");
		precache_model("progs/spike.mdl");
		precache_sound("fire/burn.wav");
		registerweapon(8, "Incinerator", w_incinerator, "incinerator", VWEP_SHOTGUN, "progs/v_dpshot.mdl", 0, 0, 2000, INCINERATOR_DAMAGE / INCINERATOR_REFIRE, WANIMTYPE_SHOTGUN);
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
	if (request == WR_ANIMATIONFINISH)
	{
		if (self.wanim_id == WANIM_LOWER)
			wswitch();
		else
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request == WR_AIM)
	{
		self.button0 = w_directattackaim(10000, 1);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
	wanimate();
	self.currentammo = Inventory_Quantity(self, "cells");
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
			W_Hostile();

			// fixme: need a blowtorch sort of sound
			if (time > self.incinerator_time)
			{
				self.incinerator_time = time + 0.2;
				sound(self, CHAN_WEAPON, "fire/burn.wav", 1, ATTN_NORM);
			}

			Inventory_AdjustQuantity(self, "cells", -1);

			// FIXME: spawn a long torch flame model

			// change solid type so the traceline hits SOLID_CORPSE
			f = self.solid;
			self.solid = SOLID_BBOX;
			traceline (shotorg, shotorg + shotdir * 350, FALSE, self);
			self.solid = f;
			if (trace_fraction < 1)
				T_Damage (trace_ent, self, self, INCINERATOR_DAMAGE * (1 - trace_fraction), INCINERATOR_DAMAGE * (1 - trace_fraction), "INCINERATOR", DT_CUT, trace_endpos - shotdir * 4, '0 0 0', Obituary_Incinerator);

			wsetanim(WANIM_FIRE1, 1, 0, INCINERATOR_REFIRE);
		}
		return TRUE;
	}
	return TRUE;
};

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_Railgun =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " was railguned by ";
		deathstring3 = attacker.netname;
		deathstring4 = "";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

float(float request) w_railgun =
{
	local float f;
	local vector v;
	if (request == WR_REGISTER)
	{
		precache_model("progs/v_dpshot.mdl");
		precache_model("progs/spike.mdl");
		precache_sound("weapons/rocket1i.wav");
		registerweapon(8, "Railgun", w_railgun, "railgun", VWEP_SHOTGUN, "progs/v_dpshot.mdl", 0, 0, 2000, RAILGUN_DAMAGE / RAILGUN_REFIRE, WANIMTYPE_SHOTGUN);
		return TRUE;
	}
	if (request == WR_HASAMMO)
		return Inventory_Quantity(self, "shells");
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
	if (request == WR_ANIMATIONFINISH)
	{
		if (self.wanim_id == WANIM_LOWER)
			wswitch();
		else
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request == WR_AIM)
	{
		self.button0 = w_directattackaim(10000, 1);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
	wanimate();
	self.currentammo = Inventory_Quantity(self, "shells");
	if (self.wanim_id == WANIM_READY)
	{
		if (self.switchweaponclass != self.weaponclass)
		{
			wsetanim(WANIM_LOWER, 7, 2, 0.2);
			return TRUE;
		}
		if (self.button0)
		if (Inventory_Quantity(self, "shells"))
		{
			W_Hostile();
			sound(self, CHAN_WEAPON, "weapons/rocket1i.wav", 1, ATTN_NORM);
			Inventory_AdjustQuantity(self, "shells", -1);
			w_muzzleflash(shotorg, 0.5);
			FireBullets(self, self, 1, 1, RAILGUN_DAMAGE, RAILGUN_DAMAGE, 0, 0, shotdir * 10000, 0.025, "RAILGUN", DT_NAIL, Obituary_Railgun);
			wsetanim(WANIM_FIRE1, 1, 0, RAILGUN_REFIRE);
		}
		return TRUE;
	}
	return TRUE;
};
*/

void() PlasmaChargeExplode =
{
	fightdone = time + 1; // delay stuff until fighting is over
	// FIXME: normal explosion does not look right for ice shots
	T_RadiusDamage(self, self.owner, self.dmg, self.count2, self.dmg2, world, self.deathtype, self.count3, self.obitfunc1);
	BecomeExplosion(self, '-1 0 0', self.effects & EF_BLUE);
};

void() PlasmaChargeDet =
{
	self.think = PlasmaChargeExplode;
	self.nextthink = time;
}

void() PlasmaChargeTouch =
{
	//local vector v;
	fightdone = time + 1; // delay stuff until fighting is over
	if (other == self.owner)
		return; // ignore owner
	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}
	//v = normalize(self.velocity);
	//setorigin(self, self.origin - v * 1);
	PlasmaChargeDet();
};

void() PlasmaChargeThink =
{
	local float p;
	self.nextthink = time;
	fightdone = time + 1; // delay stuff until fighting is over
	p = pointcontents(self.origin);
	if (time > self.cnt || p == CONTENT_SOLID || p == CONTENT_LAVA)
	{
		PlasmaChargeExplode();
		return;
	}
	if (p == CONTENT_SKY)
		remove(self);
};

void(vector org, vector vel, entity own, float damg, float force, float blastradius, float dmgtype, string dethtype, void(entity t, entity a, string m, float dtyp) obitfunc) LaunchPlasmaCharge =
{
	fightdone = time + 1; // delay stuff until fighting is over
	newmis = spawn ();
	//newmis.cantrigger = TRUE; // can trigger buttons
	newmis.shoulddodge = TRUE;
	newmis.dangerrating = 150;
	newmis.owner = own;
	newmis.createdtime = time;
	newmis.movetype = MOVETYPE_FLY;
	newmis.solid = SOLID_BBOX; // only solid so it can be shot
	newmis.classname = "plasmacharge";
	newmis.deathtype = dethtype;
	newmis.obitfunc1 = obitfunc;
	newmis.velocity = vel;
	newmis.touch = PlasmaChargeTouch;
	newmis.think = PlasmaChargeThink;
	newmis.nextthink = time;
	newmis.th_die = PlasmaChargeDet;
	newmis.th_gib = PlasmaChargeDet;
	//newmis.takedamage = DAMAGE_YES;
	newmis.health = 5;     // can be detonated inflight
	newmis.cnt = time + 15; // 15 seconds max flight time
	newmis.dmg = damg;
	newmis.count2 = force;
	newmis.count3 = dmgtype;
	newmis.dmg2 = blastradius;
	newmis.wait = time;
	newmis.effects = EF_LOWPRECISION;

	if (own.items & IT_QUAD)
	{
		newmis.effects = newmis.effects | EF_BLUE;
		newmis.dmg = newmis.dmg * 4;
		newmis.count2 = newmis.count2 * 4;
	}

	//newmis.flags = FL_MONSTER; // make it larger to missile attacks (beam)
	// FIXME: different model for ice shots?
	setmodel (newmis, "progs/plasmashot.spr32");
	//setsize (newmis, '-16 -16 -16', '16 16 16');
	//setsize (newmis, '-1.45 -1.45 -1.45', '1.45 1.45 1.45');
	setsize (newmis, '0 0 0', '0 0 0');
	setorigin (newmis, org);
	newmis.scale = damg / 200;
	if (newmis.scale < 0.25)
		newmis.scale = 0.25;
};

void(vector start, vector end, entity own, float damg, float force, float blastradius, float dmgtype, string dethtype, void(entity t, entity a, string m, float dtyp) obitfunc) LaunchPlasmaBeam =
{
	local vector forcevec;
	end = W_BeamDamage(own, own, start, end, 10, 10, dethtype, dmgtype, obitfunc);
	te_lightning2(world, start, end);

	forcevec = normalize(end - start) * force;
	traceline(start, end, MOVE_NORMAL, own);
	te_gunshotquad(trace_endpos);
	if (damg > 10)
		T_Damage(trace_ent, own, own, damg - 10, damg - 10, dethtype, dmgtype, trace_endpos, forcevec, obitfunc);
	newmis = spawn();
	newmis.owner = own;
	setorigin(newmis, end);
	BecomeExplosion(newmis, '-1 0 0', self.effects & EF_BLUE);

	/*
	end = W_BeamDamage(own, own, start, end, damg, damg, dethtype, DT_PLASMA, obitfunc);
	te_lightning2(world, start, end);
	newmis = spawn();
	newmis.owner = own;
	setorigin(newmis, end);
	BecomeExplosion(newmis, '-1 0 0', self.effects & EF_BLUE);
	*/
	/*
	local vector forcevec;
	forcevec = normalize(end - start) * force;
	traceline(start, end, MOVE_NORMAL, world);
	te_lightning2(world, start, trace_endpos);
	//te_plasmaburn(trace_endpos);
	te_gunshotquad(trace_endpos);
	T_Damage(trace_ent, own, own, damg, damg, dethtype, DT_PLASMA, trace_endpos, forcevec, obitfunc);
	//newmis = spawn();
	//newmis.owner = own;
	//setorigin(newmis, end);
	////T_RadiusDamage(newmis, newmis.owner, damg, force, blastradius, world, dethtype, DT_PLASMA, obitfunc);
	//BecomeExplosion(newmis, '-1 0 0', self.effects & EF_BLUE);
	*/
};

float PLASMACANNON_MISSILE_SINGLE_DAMAGE = 90;
float PLASMACANNON_MISSILE_SINGLE_FORCE = 90;
float PLASMACANNON_MISSILE_SINGLE_MUZZLEFLASH = 0;
float PLASMACANNON_MISSILE_SINGLE_RADIUS = 50;
float PLASMACANNON_MISSILE_SINGLE_REFIRE = 0.3;
float PLASMACANNON_MISSILE_SINGLE_VELOCITY = 3000;
float PLASMACANNON_MISSILE_SINGLE_SHAKE = 0;
float PLASMACANNON_MISSILE_SUPER_FULL = 5;
float PLASMACANNON_MISSILE_SUPER_MINIMUM = 1;
float PLASMACANNON_MISSILE_SUPER_DAMAGE = 450;
float PLASMACANNON_MISSILE_SUPER_FORCE = 450;
float PLASMACANNON_MISSILE_SUPER_MUZZLEFLASH = 0;
float PLASMACANNON_MISSILE_SUPER_RADIUS = 150;
float PLASMACANNON_MISSILE_SUPER_REFIRE = 0.3;
float PLASMACANNON_MISSILE_SUPER_VELOCITY = 3000;
float PLASMACANNON_MISSILE_SUPER_SHAKE = 0;
float PLASMACANNON_MISSILE_SUPER_TIME = 0.1;
float PLASMACANNON_PLASMA_SINGLE_DAMAGE = 30;
float PLASMACANNON_PLASMA_SINGLE_FORCE = 0;
float PLASMACANNON_PLASMA_SINGLE_MUZZLEFLASH = 0;
float PLASMACANNON_PLASMA_SINGLE_RADIUS = 0;
float PLASMACANNON_PLASMA_SINGLE_REFIRE = 0.3;
float PLASMACANNON_PLASMA_SINGLE_SHAKE = 0;
float PLASMACANNON_PLASMA_SINGLE_VELOCITY = 5000;
float PLASMACANNON_PLASMA_SUPER_DAMAGE = 140;
float PLASMACANNON_PLASMA_SUPER_FORCE = 50;
float PLASMACANNON_PLASMA_SUPER_FULL = 20;
float PLASMACANNON_PLASMA_SUPER_MINIMUM = 1;
float PLASMACANNON_PLASMA_SUPER_MUZZLEFLASH = 0;
float PLASMACANNON_PLASMA_SUPER_RADIUS = 100;
float PLASMACANNON_PLASMA_SUPER_REFIRE = 0.3;
float PLASMACANNON_PLASMA_SUPER_SHAKE = 1;
float PLASMACANNON_PLASMA_SUPER_TIME = 0.05;
float PLASMACANNON_PLASMA_SUPER_VELOCITY = 5000;
//float PLASMACANNON_PLASMA_QUICK_REFIRE = 0.1;

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_PlasmaCannon =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " was blasted by ";
		deathstring3 = attacker.netname;
		deathstring4 = "";
		if (targ.bodyhealth < 1)
			deathstring2 = " was obliterated by ";
	}
	else if (dtype == DTYPE_SUICIDE)
	{
		deathstring1 = targ.netname;
		deathstring2 = " didn't know where to point the gun";
		deathstring3 = "";
		deathstring4 = "";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_PlasmaCannonMissile =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " was blasted by a missile from ";
		deathstring3 = attacker.netname;
		deathstring4 = "";
		if (targ.bodyhealth < 1)
			deathstring2 = " was torn asunder by ";
	}
	else if (dtype == DTYPE_SUICIDE)
	{
		deathstring1 = targ.netname;
		deathstring2 = " didn't know where to point the gun";
		deathstring3 = "";
		deathstring4 = "";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

float(float m1, float m2, float c, float c1, float c2) lerp =
{
	return m1 + (m2 - m1) * (c - c1) / (c2 - c1);
};

/*
.float missilemode;
float(float request) w_mplasmacannon =
{
	//local float cells, shots, damage;
	//local vector ang;
	local vector shotvelocity;
	local float shotdamage;
	local float shotforce;
	local float shotradius;
	if (request == WR_REGISTER)
	{
		precache_model("progs/v_dpshot.mdl");
		precache_model("progs/plasmashot.spr32");
		precache_sound("plasma/plasma.wav");
		precache_sound("plasma/plasexpl.wav");
		precache_model("progs/spike.mdl");
		precache_sound("weapons/rocket1i.wav");
		precache_sound("player/axhit2.wav");
		registerweapon(1, "Plasma Cannon", w_mplasmacannon, "mplasmacannon", VWEP_LIGHTNING, "progs/v_dplight.mdl", IT_SHELLS, 0, 500, 9999, WANIMTYPE_LIGHTNING);
		return TRUE;
	}
	if (request == WR_HASAMMO)
		return TRUE;
	if (request == WR_SETUP)
	{
		self.missilemode = FALSE;
		wsetanim(WANIM_RAISE, 6, -2, 0.2);
		return TRUE;
	}
	if (request == WR_INSTANTSETUP)
	{
		self.missilemode = FALSE;
		wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request == WR_ANIMATIONFRAME)
	{
		if (self.wanim_id == WANIM_FIRE2)
		{
			if (self.missilemode)
			{
				if (self.wburst < PLASMACANNON_MISSILE_SUPER_FULL)
				if (self.wburst < Inventory_Quantity(self, "rockets"))
					self.wburst = self.wburst + 1;
				self.punchangle = (randomvec() + '-1 0 0') * lerp(PLASMACANNON_MISSILE_SINGLE_SHAKE, PLASMACANNON_MISSILE_SUPER_SHAKE, self.wburst, 1, PLASMACANNON_MISSILE_SUPER_FULL);
				self.punchangle_z = 0; // don't want roll
			}
			else
			{
				if (self.wburst < PLASMACANNON_PLASMA_SUPER_FULL)
					self.wburst = self.wburst + 1;
				self.punchangle = (randomvec() + '-1 0 0') * lerp(PLASMACANNON_PLASMA_SINGLE_SHAKE, PLASMACANNON_PLASMA_SUPER_SHAKE, self.wburst, 1, PLASMACANNON_PLASMA_SUPER_FULL);
				self.punchangle_z = 0; // don't want roll
			}
			return TRUE;
		}
	}
	if (request == WR_ANIMATIONFINISH)
	{
		if (self.wanim_id == WANIM_LOWER)
			wswitch();
		if (self.wanim_id == WANIM_FIRE1)
		{
			// user held button the entire time, begin charging
			// (but only if user has the charge upgrade)
			if (Inventory_Quantity(self, "mchargecannon"))
			{
				// user has the charge upgrade, begin charging anim
				if (self.missilemode)
				{
					sound(self, CHAN_WEAPON, "weapons/lstart.wav", 1, ATTN_NORM);
					self.wburst = 1;
					wsetanim(WANIM_FIRE2, 1, 4, 4 * PLASMACANNON_MISSILE_SUPER_TIME);
				}
				else
				{
					sound(self, CHAN_WEAPON, "weapons/lstart.wav", 1, ATTN_NORM);
					self.wburst = 1;
					wsetanim(WANIM_FIRE2, 1, 4, 4 * PLASMACANNON_PLASMA_SUPER_TIME);
				}
				return TRUE;
			}
			// user does not have the charge upgrade,
			// do nothing to wait for button release
			// (WR_ANIMATIONFINISH repeats until wsetanim)
			// uncomment this to refire immediately
			//wsetanim(WANIM_READY, 0, 0, 0);
		}
		else if (self.wanim_id == WANIM_FIRE2)
		{
			if (self.missilemode)
				wsetanim(WANIM_FIRE2, 1, 4, 4 * PLASMACANNON_MISSILE_SUPER_TIME);
			else
				wsetanim(WANIM_FIRE2, 1, 4, 4 * PLASMACANNON_PLASMA_SUPER_TIME);
		}
		else
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request == WR_AIM)
	{
		self.button0 = w_directattackaim(5000, 1);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
	wanimate();
	self.currentammo = self.wburst;
	if (self.wanim_id == WANIM_READY)
	{
		self.wburst = 0;
		if (self.switchweaponclass != self.weaponclass)
		{
			wsetanim(WANIM_LOWER, 5, 2, 0.2);
			return TRUE;
		}
		if (time < self.attack_finished)
			return TRUE;
		if (self.missilemode)
		{
			if (!self.button3)
			{
				self.missilemode = FALSE;
				//sound(self, CHAN_WEAPON, "player/axhit2.wav", 1, ATTN_NORM);
				self.attack_finished = time + 0.1;
				return TRUE;
			}
			if (self.button0)
			if (Inventory_Quantity(self, "rockets") >= 1)
			{
				// fire a low power shot
				self.wburst = 1;
				W_Hostile();
				self.wfiretime = time;
				sound(self, CHAN_WEAPON, "weapons/sgun1.wav", 1, ATTN_NORM);
				Inventory_AdjustQuantity(self, "rockets", 0 - self.wburst);
				w_muzzleflash(shotorg, lerp(PLASMACANNON_MISSILE_SINGLE_MUZZLEFLASH, PLASMACANNON_MISSILE_SUPER_MUZZLEFLASH, self.wburst, 1, PLASMACANNON_MISSILE_SUPER_FULL));
				shotvelocity = shotdir * lerp(PLASMACANNON_MISSILE_SINGLE_VELOCITY, PLASMACANNON_MISSILE_SUPER_VELOCITY, self.wburst, 1, PLASMACANNON_MISSILE_SUPER_FULL);
				shotdamage = lerp(PLASMACANNON_MISSILE_SINGLE_DAMAGE, PLASMACANNON_MISSILE_SUPER_DAMAGE, self.wburst, 1, PLASMACANNON_MISSILE_SUPER_FULL);
				shotforce = lerp(PLASMACANNON_MISSILE_SINGLE_FORCE, PLASMACANNON_MISSILE_SUPER_FORCE, self.wburst, 1, PLASMACANNON_MISSILE_SUPER_FULL);
				shotradius = lerp(PLASMACANNON_MISSILE_SINGLE_RADIUS, PLASMACANNON_MISSILE_SUPER_RADIUS, self.wburst, 1, PLASMACANNON_MISSILE_SUPER_FULL);
				LaunchMissile(shotorg, shotvelocity, self, shotdamage, shotforce, shotradius, "PLASMACANNONMISSILE", Obituary_PlasmaCannonMissile);
				wsetanim(WANIM_FIRE1, 0, 0, lerp(PLASMACANNON_MISSILE_SINGLE_REFIRE, PLASMACANNON_MISSILE_SUPER_REFIRE, self.wburst, 1, PLASMACANNON_MISSILE_SUPER_FULL));
				self.wburst = 0;
				return TRUE;
			}
		}
		else
		{
			if (self.button3)
			{
				self.missilemode = TRUE;
				//sound(self, CHAN_WEAPON, "player/axhit2.wav", 1, ATTN_NORM);
				self.attack_finished = time + 0.1;
				return TRUE;
			}
			if (self.button0)
			{
				// fire a low power shot
				self.wburst = 1;
				W_Hostile();
				self.wfiretime = time;
				sound(self, CHAN_WEAPON, "plasma/plasma.wav", 1, ATTN_NORM);
				w_muzzleflash(shotorg, lerp(PLASMACANNON_PLASMA_SINGLE_MUZZLEFLASH, PLASMACANNON_PLASMA_SUPER_MUZZLEFLASH, self.wburst, 1, PLASMACANNON_PLASMA_SUPER_FULL));
				shotvelocity = shotdir * lerp(PLASMACANNON_PLASMA_SINGLE_VELOCITY, PLASMACANNON_PLASMA_SUPER_VELOCITY, self.wburst, 1, PLASMACANNON_PLASMA_SUPER_FULL);
				shotdamage = lerp(PLASMACANNON_PLASMA_SINGLE_DAMAGE, PLASMACANNON_PLASMA_SUPER_DAMAGE, self.wburst, 1, PLASMACANNON_PLASMA_SUPER_FULL);
				shotforce = lerp(PLASMACANNON_PLASMA_SINGLE_FORCE, PLASMACANNON_PLASMA_SUPER_FORCE, self.wburst, 1, PLASMACANNON_PLASMA_SUPER_FULL);
				shotradius = lerp(PLASMACANNON_PLASMA_SINGLE_RADIUS, PLASMACANNON_PLASMA_SUPER_RADIUS, self.wburst, 1, PLASMACANNON_PLASMA_SUPER_FULL);
				LaunchPlasmaCharge(shotorg, shotvelocity, self, shotdamage, shotforce, shotradius, DT_PLASMA, "PLASMACANNON", Obituary_PlasmaCannon);
				wsetanim(WANIM_FIRE1, 0, 0, lerp(PLASMACANNON_PLASMA_SINGLE_REFIRE, PLASMACANNON_PLASMA_SUPER_REFIRE, self.wburst, 1, PLASMACANNON_PLASMA_SUPER_FULL));
				self.wburst = 0;
				return TRUE;
			}
		}
		return TRUE;
	}
	if (self.wanim_id == WANIM_FIRE1)
	{
		// if button is released during refire delay, switch to a more rapid
		// fire mode (allows repeated pressing to fire more quickly)
		if (!self.button0)
			self.wanim_id = WANIM_FIRE4;
		return TRUE;
	}
	if (self.wanim_id == WANIM_FIRE2)
	{
		if (!self.button0)
		{
			if (self.missilemode)
			{
				if (self.wburst >= PLASMACANNON_MISSILE_SUPER_MINIMUM)
				{
					W_Hostile();
					self.wfiretime = time;
					sound(self, CHAN_WEAPON, "weapons/sgun1.wav", 1, ATTN_NORM);
					Inventory_AdjustQuantity(self, "rockets", 0 - self.wburst);
					w_muzzleflash(shotorg, lerp(PLASMACANNON_MISSILE_SINGLE_MUZZLEFLASH, PLASMACANNON_MISSILE_SUPER_MUZZLEFLASH, self.wburst, 1, PLASMACANNON_MISSILE_SUPER_FULL));
					shotvelocity = shotdir * lerp(PLASMACANNON_MISSILE_SINGLE_VELOCITY, PLASMACANNON_MISSILE_SUPER_VELOCITY, self.wburst, 1, PLASMACANNON_MISSILE_SUPER_FULL);
					shotdamage = lerp(PLASMACANNON_MISSILE_SINGLE_DAMAGE, PLASMACANNON_MISSILE_SUPER_DAMAGE, self.wburst, 1, PLASMACANNON_MISSILE_SUPER_FULL);
					shotforce = lerp(PLASMACANNON_MISSILE_SINGLE_FORCE, PLASMACANNON_MISSILE_SUPER_FORCE, self.wburst, 1, PLASMACANNON_MISSILE_SUPER_FULL);
					shotradius = lerp(PLASMACANNON_MISSILE_SINGLE_RADIUS, PLASMACANNON_MISSILE_SUPER_RADIUS, self.wburst, 1, PLASMACANNON_MISSILE_SUPER_FULL);
					LaunchMissile(shotorg, shotvelocity, self, shotdamage, shotforce, shotradius, "PLASMACANNONMISSILE", Obituary_PlasmaCannonMissile);
					wsetanim(WANIM_FIRE1, 0, 0, lerp(PLASMACANNON_MISSILE_SINGLE_REFIRE, PLASMACANNON_MISSILE_SUPER_REFIRE, self.wburst, 1, PLASMACANNON_MISSILE_SUPER_FULL));
					self.wburst = 0;
					return TRUE;
				}
			}
			else
			{
				if (self.wburst >= PLASMACANNON_PLASMA_SUPER_MINIMUM)
				{
					W_Hostile();
					self.wfiretime = time;
					sound(self, CHAN_WEAPON, "plasma/plasma.wav", 1, ATTN_NORM);
					w_muzzleflash(shotorg, lerp(PLASMACANNON_PLASMA_SINGLE_MUZZLEFLASH, PLASMACANNON_PLASMA_SUPER_MUZZLEFLASH, self.wburst, 1, PLASMACANNON_PLASMA_SUPER_FULL));
					shotvelocity = shotdir * lerp(PLASMACANNON_PLASMA_SINGLE_VELOCITY, PLASMACANNON_PLASMA_SUPER_VELOCITY, self.wburst, 1, PLASMACANNON_PLASMA_SUPER_FULL);
					shotdamage = lerp(PLASMACANNON_PLASMA_SINGLE_DAMAGE, PLASMACANNON_PLASMA_SUPER_DAMAGE, self.wburst, 1, PLASMACANNON_PLASMA_SUPER_FULL);
					shotforce = lerp(PLASMACANNON_PLASMA_SINGLE_FORCE, PLASMACANNON_PLASMA_SUPER_FORCE, self.wburst, 1, PLASMACANNON_PLASMA_SUPER_FULL);
					shotradius = lerp(PLASMACANNON_PLASMA_SINGLE_RADIUS, PLASMACANNON_PLASMA_SUPER_RADIUS, self.wburst, 1, PLASMACANNON_PLASMA_SUPER_FULL);
					LaunchPlasmaCharge(shotorg, shotvelocity, self, shotdamage, shotforce, shotradius, DT_PLASMA, "PLASMACANNON", Obituary_PlasmaCannon);
					wsetanim(WANIM_FIRE1, 0, 0, lerp(PLASMACANNON_PLASMA_SINGLE_REFIRE, PLASMACANNON_PLASMA_SUPER_REFIRE, self.wburst, 1, PLASMACANNON_PLASMA_SUPER_FULL));
					self.wburst = 0;
					return TRUE;
				}
			}
			wsetanim(WANIM_READY, 0, 0, 0);
		}
		return TRUE;
	}
	return TRUE;
};
*/

/*
float(float request) w_mplasmacannon =
{
	//local float cells, shots, damage;
	//local vector ang;
	local vector shotvelocity;
	local float shotdamage;
	local float shotforce;
	local float shotradius;
	if (request == WR_REGISTER)
	{
		precache_model("progs/v_dpshot.mdl");
		precache_model("progs/plasmashot.spr32");
		precache_sound("plasma/plasma.wav");
		precache_sound("plasma/plasexpl.wav");
		precache_model("progs/spike.mdl");
		precache_sound("weapons/rocket1i.wav");
		precache_sound("player/axhit2.wav");
		registerweapon(1, "Plasma Cannon", w_mplasmacannon, "mplasmacannon", VWEP_LIGHTNING, "progs/v_dplight.mdl", IT_SHELLS, 0, 500, 9999, WANIMTYPE_LIGHTNING);
		return TRUE;
	}
	if (request == WR_HASAMMO)
		return TRUE;
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
	if (request == WR_ANIMATIONFRAME)
	{
		if (self.wanim_id == WANIM_FIRE2)
		{
			if (self.wburst < PLASMACANNON_PLASMA_SUPER_FULL)
				self.wburst = self.wburst + 1;
			self.punchangle = (randomvec() + '-1 0 0') * lerp(PLASMACANNON_PLASMA_SINGLE_SHAKE, PLASMACANNON_PLASMA_SUPER_SHAKE, self.wburst, 1, PLASMACANNON_PLASMA_SUPER_FULL);
			self.punchangle_z = 0; // don't want roll
			return TRUE;
		}
	}
	if (request == WR_ANIMATIONFINISH)
	{
		if (self.wanim_id == WANIM_LOWER)
			wswitch();
		if (self.wanim_id == WANIM_FIRE1)
		{
			// wait for button0 release
			wsetanim(WANIM_READY, 0, 0, 0);
		}
		else if (self.wanim_id == WANIM_FIRE2)
			wsetanim(WANIM_FIRE2, 1, 4, 4 * PLASMACANNON_PLASMA_SUPER_TIME);
		else
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request == WR_AIM)
	{
		self.button0 = w_directattackaim(5000, 1);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
	wanimate();
	self.currentammo = self.wburst;
	if (self.wanim_id == WANIM_READY)
	{
		self.wburst = 0;
		if (self.switchweaponclass != self.weaponclass)
		{
			wsetanim(WANIM_LOWER, 5, 2, 0.2);
			return TRUE;
		}
		if (time < self.attack_finished)
			return TRUE;
		if (self.button3)
		if (Inventory_Quantity(self, "mchargecannon"))
		{
			// user has the charge upgrade, begin charging anim
			sound(self, CHAN_WEAPON, "weapons/lstart.wav", 1, ATTN_NORM);
			self.wburst = 1;
			wsetanim(WANIM_FIRE2, 1, 4, 4 * PLASMACANNON_MISSILE_SUPER_TIME);
			return TRUE;
		}
		if (self.button0)
		{
			// fire a low power shot
			self.wburst = 1;
			W_Hostile();
			self.wfiretime = time;
			sound(self, CHAN_WEAPON, "plasma/plasma.wav", 1, ATTN_NORM);
			w_muzzleflash(shotorg, lerp(PLASMACANNON_PLASMA_SINGLE_MUZZLEFLASH, PLASMACANNON_PLASMA_SUPER_MUZZLEFLASH, self.wburst, 1, PLASMACANNON_PLASMA_SUPER_FULL));
			shotvelocity = shotdir * lerp(PLASMACANNON_PLASMA_SINGLE_VELOCITY, PLASMACANNON_PLASMA_SUPER_VELOCITY, self.wburst, 1, PLASMACANNON_PLASMA_SUPER_FULL);
			shotdamage = lerp(PLASMACANNON_PLASMA_SINGLE_DAMAGE, PLASMACANNON_PLASMA_SUPER_DAMAGE, self.wburst, 1, PLASMACANNON_PLASMA_SUPER_FULL);
			shotforce = lerp(PLASMACANNON_PLASMA_SINGLE_FORCE, PLASMACANNON_PLASMA_SUPER_FORCE, self.wburst, 1, PLASMACANNON_PLASMA_SUPER_FULL);
			shotradius = lerp(PLASMACANNON_PLASMA_SINGLE_RADIUS, PLASMACANNON_PLASMA_SUPER_RADIUS, self.wburst, 1, PLASMACANNON_PLASMA_SUPER_FULL);
			if (Inventory_Quantity(self, "mmulticannon"))
			{
				shotdamage = shotdamage * 2;
				shotforce = shotforce * 2;
			}
			LaunchPlasmaCharge(shotorg, shotvelocity, self, shotdamage, shotforce, shotradius, DT_PLASMA, "PLASMACANNON", Obituary_PlasmaCannon);
			wsetanim(WANIM_FIRE1, 0, 0, lerp(PLASMACANNON_PLASMA_SINGLE_REFIRE, PLASMACANNON_PLASMA_SUPER_REFIRE, self.wburst, 1, PLASMACANNON_PLASMA_SUPER_FULL));
			self.wburst = 0;
			return TRUE;
		}
		return TRUE;
	}
	if (self.wanim_id == WANIM_FIRE1)
	{
		// if button is released during refire delay, switch to a more rapid
		// fire mode (allows repeated pressing to fire more quickly)
		if (!self.button0)
		//	wsetanim(WANIM_FIRE1, 0, 0, PLASMACANNON_PLASMA_QUICK_REFIRE);
			self.wanim_id = WANIM_FIRE4;
		return TRUE;
	}
	if (self.wanim_id == WANIM_FIRE2)
	{
		if (!self.button3)
		{
			if (self.wburst >= PLASMACANNON_PLASMA_SUPER_MINIMUM)
			{
				W_Hostile();
				self.wfiretime = time;
				sound(self, CHAN_WEAPON, "plasma/plasma.wav", 1, ATTN_NORM);
				w_muzzleflash(shotorg, lerp(PLASMACANNON_PLASMA_SINGLE_MUZZLEFLASH, PLASMACANNON_PLASMA_SUPER_MUZZLEFLASH, self.wburst, 1, PLASMACANNON_PLASMA_SUPER_FULL));
				shotvelocity = shotdir * lerp(PLASMACANNON_PLASMA_SINGLE_VELOCITY, PLASMACANNON_PLASMA_SUPER_VELOCITY, self.wburst, 1, PLASMACANNON_PLASMA_SUPER_FULL);
				shotdamage = lerp(PLASMACANNON_PLASMA_SINGLE_DAMAGE, PLASMACANNON_PLASMA_SUPER_DAMAGE, self.wburst, 1, PLASMACANNON_PLASMA_SUPER_FULL);
				shotforce = lerp(PLASMACANNON_PLASMA_SINGLE_FORCE, PLASMACANNON_PLASMA_SUPER_FORCE, self.wburst, 1, PLASMACANNON_PLASMA_SUPER_FULL);
				shotradius = lerp(PLASMACANNON_PLASMA_SINGLE_RADIUS, PLASMACANNON_PLASMA_SUPER_RADIUS, self.wburst, 1, PLASMACANNON_PLASMA_SUPER_FULL);
				if (Inventory_Quantity(self, "mmulticannon"))
				{
					shotdamage = shotdamage * 2;
					shotforce = shotforce * 2;
				}
				LaunchPlasmaCharge(shotorg, shotvelocity, self, shotdamage, shotforce, shotradius, DT_PLASMA, "PLASMACANNON", Obituary_PlasmaCannon);
				wsetanim(WANIM_FIRE1, 0, 0, lerp(PLASMACANNON_PLASMA_SINGLE_REFIRE, PLASMACANNON_PLASMA_SUPER_REFIRE, self.wburst, 1, PLASMACANNON_PLASMA_SUPER_FULL));
				self.wburst = 0;
				return TRUE;
			}
			wsetanim(WANIM_READY, 0, 0, 0);
		}
		return TRUE;
	}
	return TRUE;
};
*/

float(float request) w_mplasmacannon =
{
	//local float cells, shots, damage;
	//local vector ang;
	local vector shotvelocity;
	local float shotdamage;
	local float shotforce;
	local float shotradius;
	if (request == WR_REGISTER)
	{
		precache_model("progs/v_dpshot.mdl");
		precache_model("progs/plasmashot.spr32");
		precache_sound("plasma/plasma.wav");
		precache_sound("plasma/plasexpl.wav");
		precache_model("progs/spike.mdl");
		precache_sound("weapons/rocket1i.wav");
		precache_sound("player/axhit2.wav");
		registerweapon(1, "Plasma Cannon", w_mplasmacannon, "mplasmacannon", VWEP_LIGHTNING, "progs/v_dplight.mdl", IT_SHELLS, 0, 500, 9999, WANIMTYPE_LIGHTNING);
		return TRUE;
	}
	if (request == WR_HASAMMO)
		return TRUE;
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
	if (request == WR_ANIMATIONFRAME)
	{
		if (self.wanim_id == WANIM_FIRE2)
		{
			if (self.wburst < PLASMACANNON_PLASMA_SUPER_FULL)
				self.wburst = self.wburst + 1;
			self.punchangle = (randomvec() + '-1 0 0') * lerp(PLASMACANNON_PLASMA_SINGLE_SHAKE, PLASMACANNON_PLASMA_SUPER_SHAKE, self.wburst, 1, PLASMACANNON_PLASMA_SUPER_FULL);
			self.punchangle_z = 0; // don't want roll
			return TRUE;
		}
		if (self.wanim_id == WANIM_FIRE3)
		{
			if (self.wburst < Inventory_Quantity(self, "rockets"))
			if (self.wburst < PLASMACANNON_MISSILE_SUPER_FULL)
				self.wburst = self.wburst + 1;
			self.punchangle = (randomvec() + '-1 0 0') * lerp(PLASMACANNON_MISSILE_SINGLE_SHAKE, PLASMACANNON_MISSILE_SUPER_SHAKE, self.wburst, 1, PLASMACANNON_MISSILE_SUPER_FULL);
			self.punchangle_z = 0; // don't want roll
			return TRUE;
		}
	}
	if (request == WR_ANIMATIONFINISH)
	{
		if (self.wanim_id == WANIM_LOWER)
			wswitch();
		if (self.wanim_id == WANIM_FIRE1)
		{
			if (self.button0)
			{
				if (Inventory_Quantity(self, "mchargecannon"))
				{
					// user has the charge upgrade, begin charging anim
					sound(self, CHAN_WEAPON, "weapons/lstart.wav", 1, ATTN_NORM);
					self.wburst = 1;
					if (self.button3)
						wsetanim(WANIM_FIRE3, 1, 4, 4 * PLASMACANNON_MISSILE_SUPER_TIME);
					else
						wsetanim(WANIM_FIRE2, 1, 4, 4 * PLASMACANNON_PLASMA_SUPER_TIME);
				}
				else
				{
					// fire again
					wsetanim(WANIM_READY, 0, 0, 0);
				}
			}
			else
			{
				// go to idle mode
				wsetanim(WANIM_READY, 0, 0, 0);
			}
		}
		else if (self.wanim_id == WANIM_FIRE2)
			wsetanim(WANIM_FIRE2, 1, 4, 4 * PLASMACANNON_PLASMA_SUPER_TIME);
		else if (self.wanim_id == WANIM_FIRE3)
			wsetanim(WANIM_FIRE3, 1, 4, 4 * PLASMACANNON_MISSILE_SUPER_TIME);
		else
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request == WR_AIM)
	{
		self.button0 = w_directattackaim(5000, 1);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
	wanimate();
	self.currentammo = self.wburst;
	if (self.wanim_id == WANIM_READY)
	{
		self.wburst = 0;
		if (self.switchweaponclass != self.weaponclass)
		{
			wsetanim(WANIM_LOWER, 5, 2, 0.2);
			return TRUE;
		}
		if (time < self.attack_finished)
			return TRUE;
		if (self.button0)
		{
			if (self.button3)
			{
				if (Inventory_Quantity(self, "rockets") > 0)
				{
					// fire a low power shot
					self.wburst = 1;
					W_Hostile();
					self.wfiretime = time;
					w_muzzleflash(shotorg, lerp(PLASMACANNON_MISSILE_SINGLE_MUZZLEFLASH, PLASMACANNON_MISSILE_SUPER_MUZZLEFLASH, self.wburst, 1, PLASMACANNON_MISSILE_SUPER_FULL));
					shotvelocity = shotdir * lerp(PLASMACANNON_MISSILE_SINGLE_VELOCITY, PLASMACANNON_MISSILE_SUPER_VELOCITY, self.wburst, 1, PLASMACANNON_MISSILE_SUPER_FULL);
					shotdamage = lerp(PLASMACANNON_MISSILE_SINGLE_DAMAGE, PLASMACANNON_MISSILE_SUPER_DAMAGE, self.wburst, 1, PLASMACANNON_MISSILE_SUPER_FULL);
					shotforce = lerp(PLASMACANNON_MISSILE_SINGLE_FORCE, PLASMACANNON_MISSILE_SUPER_FORCE, self.wburst, 1, PLASMACANNON_MISSILE_SUPER_FULL);
					shotradius = lerp(PLASMACANNON_MISSILE_SINGLE_RADIUS, PLASMACANNON_MISSILE_SUPER_RADIUS, self.wburst, 1, PLASMACANNON_MISSILE_SUPER_FULL);
					sound(self, CHAN_WEAPON, "weapons/sgun1.wav", 1, ATTN_NORM);
					Inventory_AdjustQuantity(self, "rockets", 0 - self.wburst);
					LaunchMissile(shotorg, shotvelocity, self, shotdamage, shotforce, shotradius, "MISSILE", Obituary_PlasmaCannonMissile);
					wsetanim(WANIM_FIRE1, 0, 0, lerp(PLASMACANNON_MISSILE_SINGLE_REFIRE, PLASMACANNON_MISSILE_SUPER_REFIRE, self.wburst, 1, PLASMACANNON_MISSILE_SUPER_FULL));
					self.wburst = 0;
					return TRUE;
				}
			}
			else
			{
				// fire a low power shot
				self.wburst = 1;
				W_Hostile();
				self.wfiretime = time;
				w_muzzleflash(shotorg, lerp(PLASMACANNON_PLASMA_SINGLE_MUZZLEFLASH, PLASMACANNON_PLASMA_SUPER_MUZZLEFLASH, self.wburst, 1, PLASMACANNON_PLASMA_SUPER_FULL));
				shotvelocity = shotdir * lerp(PLASMACANNON_PLASMA_SINGLE_VELOCITY, PLASMACANNON_PLASMA_SUPER_VELOCITY, self.wburst, 1, PLASMACANNON_PLASMA_SUPER_FULL);
				shotdamage = lerp(PLASMACANNON_PLASMA_SINGLE_DAMAGE, PLASMACANNON_PLASMA_SUPER_DAMAGE, self.wburst, 1, PLASMACANNON_PLASMA_SUPER_FULL);
				shotforce = lerp(PLASMACANNON_PLASMA_SINGLE_FORCE, PLASMACANNON_PLASMA_SUPER_FORCE, self.wburst, 1, PLASMACANNON_PLASMA_SUPER_FULL);
				shotradius = lerp(PLASMACANNON_PLASMA_SINGLE_RADIUS, PLASMACANNON_PLASMA_SUPER_RADIUS, self.wburst, 1, PLASMACANNON_PLASMA_SUPER_FULL);
				if (Inventory_Quantity(self, "mmulticannon"))
				{
					shotdamage = shotdamage * 2;
					shotforce = shotforce * 2;
				}
				sound(self, CHAN_WEAPON, "plasma/plasma.wav", 1, ATTN_NORM);
				LaunchPlasmaCharge(shotorg, shotvelocity, self, shotdamage, shotforce, shotradius, DT_PLASMA, "PLASMACANNON", Obituary_PlasmaCannon);
				wsetanim(WANIM_FIRE1, 0, 0, lerp(PLASMACANNON_PLASMA_SINGLE_REFIRE, PLASMACANNON_PLASMA_SUPER_REFIRE, self.wburst, 1, PLASMACANNON_PLASMA_SUPER_FULL));
				self.wburst = 0;
				return TRUE;
			}
		}
		return TRUE;
	}
	if (self.wanim_id == WANIM_FIRE1)
	{
		// if button is released during refire delay, switch to a more rapid
		// fire mode (allows repeated pressing to fire more quickly)
		//if (!self.button0)
		//	wsetanim(WANIM_FIRE1, 0, 0, PLASMACANNON_PLASMA_QUICK_REFIRE);
		//	self.wanim_id = WANIM_FIRE4;
		return TRUE;
	}
	if (self.wanim_id == WANIM_FIRE2)
	{
		if (!self.button0)
		{
			if (self.wburst >= PLASMACANNON_PLASMA_SUPER_MINIMUM)
			{
				W_Hostile();
				self.wfiretime = time;
				sound(self, CHAN_WEAPON, "plasma/plasma.wav", 1, ATTN_NORM);
				w_muzzleflash(shotorg, lerp(PLASMACANNON_PLASMA_SINGLE_MUZZLEFLASH, PLASMACANNON_PLASMA_SUPER_MUZZLEFLASH, self.wburst, 1, PLASMACANNON_PLASMA_SUPER_FULL));
				shotvelocity = shotdir * lerp(PLASMACANNON_PLASMA_SINGLE_VELOCITY, PLASMACANNON_PLASMA_SUPER_VELOCITY, self.wburst, 1, PLASMACANNON_PLASMA_SUPER_FULL);
				shotdamage = lerp(PLASMACANNON_PLASMA_SINGLE_DAMAGE, PLASMACANNON_PLASMA_SUPER_DAMAGE, self.wburst, 1, PLASMACANNON_PLASMA_SUPER_FULL);
				shotforce = lerp(PLASMACANNON_PLASMA_SINGLE_FORCE, PLASMACANNON_PLASMA_SUPER_FORCE, self.wburst, 1, PLASMACANNON_PLASMA_SUPER_FULL);
				shotradius = lerp(PLASMACANNON_PLASMA_SINGLE_RADIUS, PLASMACANNON_PLASMA_SUPER_RADIUS, self.wburst, 1, PLASMACANNON_PLASMA_SUPER_FULL);
				if (Inventory_Quantity(self, "mmulticannon"))
				{
					shotdamage = shotdamage * 2;
					shotforce = shotforce * 2;
				}
				LaunchPlasmaCharge(shotorg, shotvelocity, self, shotdamage, shotforce, shotradius, DT_PLASMA, "PLASMACANNON", Obituary_PlasmaCannon);
				wsetanim(WANIM_FIRE1, 0, 0, lerp(PLASMACANNON_PLASMA_SINGLE_REFIRE, PLASMACANNON_PLASMA_SUPER_REFIRE, self.wburst, 1, PLASMACANNON_PLASMA_SUPER_FULL));
				self.wburst = 0;
				return TRUE;
			}
			wsetanim(WANIM_READY, 0, 0, 0);
		}
		return TRUE;
	}
	if (self.wanim_id == WANIM_FIRE3)
	{
		if (!self.button0)
		{
			if (self.wburst >= PLASMACANNON_MISSILE_SUPER_MINIMUM)
			{
				W_Hostile();
				self.wfiretime = time;
				w_muzzleflash(shotorg, lerp(PLASMACANNON_MISSILE_SINGLE_MUZZLEFLASH, PLASMACANNON_MISSILE_SUPER_MUZZLEFLASH, self.wburst, 1, PLASMACANNON_MISSILE_SUPER_FULL));
				shotvelocity = shotdir * lerp(PLASMACANNON_MISSILE_SINGLE_VELOCITY, PLASMACANNON_MISSILE_SUPER_VELOCITY, self.wburst, 1, PLASMACANNON_MISSILE_SUPER_FULL);
				shotdamage = lerp(PLASMACANNON_MISSILE_SINGLE_DAMAGE, PLASMACANNON_MISSILE_SUPER_DAMAGE, self.wburst, 1, PLASMACANNON_MISSILE_SUPER_FULL);
				shotforce = lerp(PLASMACANNON_MISSILE_SINGLE_FORCE, PLASMACANNON_MISSILE_SUPER_FORCE, self.wburst, 1, PLASMACANNON_MISSILE_SUPER_FULL);
				shotradius = lerp(PLASMACANNON_MISSILE_SINGLE_RADIUS, PLASMACANNON_MISSILE_SUPER_RADIUS, self.wburst, 1, PLASMACANNON_MISSILE_SUPER_FULL);
				sound(self, CHAN_WEAPON, "weapons/sgun1.wav", 1, ATTN_NORM);
				Inventory_AdjustQuantity(self, "rockets", 0 - self.wburst);
				LaunchMissile(shotorg, shotvelocity, self, shotdamage, shotforce, shotradius, "MISSILE", Obituary_PlasmaCannonMissile);
				wsetanim(WANIM_FIRE1, 0, 0, lerp(PLASMACANNON_MISSILE_SINGLE_REFIRE, PLASMACANNON_MISSILE_SUPER_REFIRE, self.wburst, 1, PLASMACANNON_MISSILE_SUPER_FULL));
				self.wburst = 0;
				return TRUE;
			}
			wsetanim(WANIM_READY, 0, 0, 0);
		}
		return TRUE;
	}
	return TRUE;
};

float ICECANNON_STARTFREECELLS = 0;
float ICECANNON_FREECELLS = 0;
float ICECANNON_CELLS = 10;
float ICECANNON_CELLTIME = 0.1;

float ICECANNON_BASEDAMAGE = 50;
float ICECANNON_CELLDAMAGE = 20;
float ICECANNON_BASEFORCE = 50;
float ICECANNON_CELLFORCE = 20;
float ICECANNON_BASERADIUS = 50;
float ICECANNON_CELLRADIUS = 0;
float ICECANNON_REFIRE = 0.2;
float ICECANNON_BASEKICKBACK = 0;
float ICECANNON_CELLKICKBACK = 0;
float ICECANNON_BASEMUZZLEFLASH = 0;
float ICECANNON_CELLMUZZLEFLASH = 0;
float ICECANNON_VELOCITY = 1000;

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_IceCannon =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " was frozen by ";
		deathstring3 = attacker.netname;
		deathstring4 = "";
		if (targ.bodyhealth < 1)
			deathstring2 = " was shattered by ";
	}
	else if (dtype == DTYPE_SUICIDE)
	{
		deathstring1 = targ.netname;
		deathstring2 = " didn't know where to point the gun";
		deathstring3 = "";
		deathstring4 = "";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

float(float request) w_micecannon =
{
	local float cells, shots, damage;
	local vector ang;
	if (request == WR_REGISTER)
	{
		precache_model("progs/v_dplight.mdl");
		precache_model("progs/plasmashot.spr32");
		precache_sound("plasma/plasma.wav");
		precache_sound("plasma/plasexpl.wav");
		precache_model("progs/spike.mdl");
		precache_sound("weapons/rocket1i.wav");
		registerweapon(4, "Ice Cannon", w_micecannon, "micecannon", VWEP_LIGHTNING, "progs/v_dplight.mdl", IT_CELLS, 0, 500, 9999, WANIMTYPE_LIGHTNING);
		return TRUE;
	}
	if (request == WR_HASAMMO)
		return TRUE;
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
	if (request == WR_ANIMATIONFRAME)
	{
		if (self.wanim_id == WANIM_FIRE1)
		{
			cells = ICECANNON_CELLS;
			if (!Inventory_Quantity(self, "supershotgun"))
				cells = 1;
			if (self.wburst < cells)
			{
				self.wburst = self.wburst + 1;
				sound(self, CHAN_WEAPON, "plasma/plasexpl.wav", 0.5, ATTN_STATIC);
				return TRUE;
			}
			return TRUE;
		}
	}
	if (request == WR_ANIMATIONFINISH)
	{
		if (self.wanim_id == WANIM_LOWER)
			wswitch();
		else if (self.wanim_id == WANIM_FIRE1)
			wsetanim(WANIM_FIRE1, 1, 4, 4 * ICECANNON_CELLTIME);
		else
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request == WR_AIM)
	{
		self.button0 = w_directattackaim(3000, 1);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
	wanimate();
	self.currentammo = self.wburst;
	if (self.wanim_id == WANIM_READY)
	{
		self.wburst = 0;
		if (self.switchweaponclass != self.weaponclass)
		{
			wsetanim(WANIM_LOWER, 5, 2, 0.2);
			return TRUE;
		}
		if (self.button0)
		{
			// first an initial shot
			self.wburst = 1;
			LaunchPlasmaCharge(shotorg, shotdir * ICECANNON_VELOCITY, self, ICECANNON_BASEDAMAGE + self.wburst * ICECANNON_CELLDAMAGE, ICECANNON_BASEFORCE + self.wburst * ICECANNON_CELLFORCE, ICECANNON_BASERADIUS + self.wburst * ICECANNON_CELLRADIUS, DT_ICE, "ICECANNON", Obituary_IceCannon);
			self.attack_finished = time + 0.2;
			// begin charging (but only if you have the charge cannon)
			if (Inventory_Quantity(self, "supershotgun"))
			{
				self.wburst = ICECANNON_STARTFREECELLS;
				wsetanim(WANIM_FIRE1, 1, 4, 4 * ICECANNON_CELLTIME);
			}
			self.wburst = ICECANNON_STARTFREECELLS;
			wsetanim(WANIM_FIRE1, 1, 4, 4 * ICECANNON_CELLTIME);
			return TRUE;
		}
		return TRUE;
	}
	if (self.wanim_id == WANIM_FIRE1)
	{
		if (!self.button0)
		{
			if (self.wburst >= 1)
			{
				W_Hostile();
				sound(self, CHAN_WEAPON, "plasma/plasma.wav", 1, ATTN_NORM);
				self.velocity = self.velocity - shotdir * (ICECANNON_BASEKICKBACK + self.wburst * ICECANNON_CELLKICKBACK);
				self.flags = self.flags - (self.flags & FL_ONGROUND);
				self.wfiretime = time;
				w_muzzleflash(shotorg, ICECANNON_BASEMUZZLEFLASH + self.wburst * ICECANNON_CELLMUZZLEFLASH);
				LaunchPlasmaCharge(shotorg, shotdir * ICECANNON_VELOCITY, self, ICECANNON_BASEDAMAGE + self.wburst * ICECANNON_CELLDAMAGE, ICECANNON_BASEFORCE + self.wburst * ICECANNON_CELLFORCE, ICECANNON_BASERADIUS + self.wburst * ICECANNON_CELLRADIUS, DT_ICE, "ICECANNON", Obituary_IceCannon);
				self.wburst = 0;
			}
			wsetanim(WANIM_FIRE4, 0, 0, ICECANNON_REFIRE);
		}
		return TRUE;
	}
	return TRUE;
};

float PLASMABEAM_STARTFREECELLS = 0;
float PLASMABEAM_FREECELLS = 0;
float PLASMABEAM_CELLS = 10;
float PLASMABEAM_CELLTIME = 0.1;

float PLASMABEAM_BASEDAMAGE = 40;
float PLASMABEAM_CELLDAMAGE = 15;
float PLASMABEAM_BASEFORCE = 40;
float PLASMABEAM_CELLFORCE = 15;
float PLASMABEAM_BASERADIUS = 0;
float PLASMABEAM_CELLRADIUS = 0;
float PLASMABEAM_REFIRE = 0.8;
float PLASMABEAM_BASEKICKBACK = 0;
float PLASMABEAM_CELLKICKBACK = 0;
float PLASMABEAM_BASEMUZZLEFLASH = 0;
float PLASMABEAM_CELLMUZZLEFLASH = 0;

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_PlasmaBeam =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " sports a new hole from ";
		deathstring3 = attacker.netname;
		deathstring4 = "";
		if (targ.bodyhealth < 1)
			deathstring2 = " falls apart thanks to ";
	}
	else if (dtype == DTYPE_SUICIDE)
	{
		deathstring1 = targ.netname;
		deathstring2 = " didn't know where to point the gun";
		deathstring3 = "";
		deathstring4 = "";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

float(float request) w_mplasmabeam =
{
	local float cells, shots, damage;
	local vector ang;
	if (request == WR_REGISTER)
	{
		precache_model("progs/v_dplight.mdl");
		precache_model("progs/plasmashot.spr32");
		precache_sound("plasma/plasma.wav");
		precache_sound("plasma/plasexpl.wav");
		precache_model("progs/spike.mdl");
		precache_sound("weapons/rocket1i.wav");
		registerweapon(8, "Plasma Beam", w_mplasmabeam, "mplasmabeam", VWEP_LIGHTNING, "progs/v_dplight.mdl", IT_CELLS, 0, 500, 9999, WANIMTYPE_LIGHTNING);
		return TRUE;
	}
	if (request == WR_HASAMMO)
		return TRUE;
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
	if (request == WR_ANIMATIONFRAME)
	{
		if (self.wanim_id == WANIM_FIRE1)
		{
			if (self.wburst < PLASMABEAM_CELLS)
			{
				self.wburst = self.wburst + 1;
				sound(self, CHAN_WEAPON, "plasma/plasexpl.wav", 0.5, ATTN_STATIC);
				return TRUE;
			}
			return TRUE;
		}
	}
	if (request == WR_ANIMATIONFINISH)
	{
		if (self.wanim_id == WANIM_LOWER)
			wswitch();
		else if (self.wanim_id == WANIM_FIRE1)
			wsetanim(WANIM_FIRE1, 1, 4, 4 * PLASMABEAM_CELLTIME);
		else
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request == WR_AIM)
	{
		self.button0 = w_directattackaim(5000, 1);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
	wanimate();
	self.currentammo = self.wburst;
	if (self.wanim_id == WANIM_READY)
	{
		self.wburst = 0;
		if (self.switchweaponclass != self.weaponclass)
		{
			wsetanim(WANIM_LOWER, 5, 2, 0.2);
			return TRUE;
		}
		if (self.button0)
		{
			// first an initial shot
			self.wburst = 1;
			LaunchPlasmaBeam(shotorg, shotorg + shotdir * 100000, self, PLASMABEAM_BASEDAMAGE + self.wburst * PLASMABEAM_CELLDAMAGE, (PLASMABEAM_BASEFORCE + self.wburst * PLASMABEAM_CELLFORCE) * 0.5, 50, DT_PLASMA, "PLASMABEAM", Obituary_PlasmaBeam);
			self.attack_finished = time + 0.2;
			// begin charging (but only if you have the charge cannon)
			if (Inventory_Quantity(self, "supershotgun"))
			{
				self.wburst = PLASMABEAM_STARTFREECELLS;
				wsetanim(WANIM_FIRE1, 1, 4, 4 * PLASMABEAM_CELLTIME);
			}
			return TRUE;
		}
		return TRUE;
	}
	if (self.wanim_id == WANIM_FIRE1)
	{
		if (!self.button0)
		{
			if (self.wburst >= 1)
			{
				W_Hostile();
				sound(self, CHAN_WEAPON, "plasma/plasma.wav", 1, ATTN_NORM);
				self.velocity = self.velocity - shotdir * (PLASMABEAM_BASEKICKBACK + self.wburst * PLASMABEAM_CELLKICKBACK);
				self.flags = self.flags - (self.flags & FL_ONGROUND);
				self.wfiretime = time;
				w_muzzleflash(shotorg, PLASMABEAM_BASEMUZZLEFLASH + self.wburst * PLASMABEAM_CELLMUZZLEFLASH);
				LaunchPlasmaBeam(shotorg, shotorg + shotdir * 100000, self, PLASMABEAM_BASEDAMAGE + self.wburst * PLASMABEAM_CELLDAMAGE, (PLASMABEAM_BASEFORCE + self.wburst * PLASMABEAM_CELLFORCE) * 0.5, 50, DT_PLASMA, "PLASMABEAM", Obituary_PlasmaBeam);
				self.wburst = 0;
			}
			wsetanim(WANIM_FIRE4, 0, 0, PLASMABEAM_REFIRE);
		}
		return TRUE;
	}
	return TRUE;
};

float MISSILELAUNCHER_SINGLE_DAMAGE = 300;
float MISSILELAUNCHER_SINGLE_FORCE = 150;
float MISSILELAUNCHER_SINGLE_RADIUS = 200;
float MISSILELAUNCHER_SINGLE_REFIRE = 1;
float MISSILELAUNCHER_SHOCKWAVE_DAMAGE = 5;
float MISSILELAUNCHER_SHOCKWAVE_FORCE = 300;
float MISSILELAUNCHER_SHOCKWAVE_RADIUS = 300;
float MISSILELAUNCHER_SHOCKWAVE_REFIRE = 1;

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_Missile =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " was blasted by a missile from ";
		deathstring3 = attacker.netname;
		deathstring4 = "";
		if (targ.bodyhealth < 1)
			deathstring2 = " was obliterated by ";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

float(float request) w_mmissilelauncher =
{
	if (request == WR_REGISTER)
	{
		precache_model("progs/v_dprock2.mdl");
		precache_model("progs/missile.mdl");
		precache_sound("weapons/sgun1.wav");
		registerweapon(7, "Missile Launcher", w_mmissilelauncher, "mmissilelauncher", VWEP_ROCKET_LAUNCHER, "progs/v_dprock2.mdl", IT_ROCKETS, 0, 2000, 9998, WANIMTYPE_ROCKET);
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
	if (request == WR_ANIMATIONFINISH)
	{
		if (self.wanim_id == WANIM_LOWER)
			wswitch();
		else
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request == WR_AIM)
	{
		self.button0 = w_directattackaim(3000, 1);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
	wanimate();
	self.currentammo = Inventory_Quantity(self, "rockets");
	if (self.wanim_id == WANIM_READY)
	{
		if (self.switchweaponclass != self.weaponclass)
		{
			wsetanim(WANIM_LOWER, 7, 2, 0.2);
			return TRUE;
		}
		/*
		if (self.button3)
		if (Inventory_Quantity(self, "rockets") > 0)
		{
			W_Hostile();
			sound(self, CHAN_WEAPON, "weapons/sgun1.wav", 1, ATTN_NORM);
			self.flags = self.flags - (self.flags & FL_ONGROUND);
			Inventory_AdjustQuantity(self, "rockets", -1);
			w_muzzleflash(shotorg, 0);
			LaunchMissile(shotorg, shotdir * 10000, self, MISSILELAUNCHER_SHOCKWAVE_DAMAGE, MISSILELAUNCHER_SHOCKWAVE_FORCE, MISSILELAUNCHER_SHOCKWAVE_RADIUS, "MISSILE", Obituary_Missile);
			wsetanim(WANIM_FIRE1, 1, 6, MISSILELAUNCHER_SHOCKWAVE_REFIRE);
			return TRUE;
		}
		*/
		if (self.button0)
		if (Inventory_Quantity(self, "rockets") > 0)
		{
			W_Hostile();
			sound(self, CHAN_WEAPON, "weapons/sgun1.wav", 1, ATTN_NORM);
			Inventory_AdjustQuantity(self, "rockets", -1);
			w_muzzleflash(shotorg, 0);
			LaunchMissile(shotorg, shotdir * 5000, self, MISSILELAUNCHER_SINGLE_DAMAGE, MISSILELAUNCHER_SINGLE_FORCE, MISSILELAUNCHER_SINGLE_RADIUS, "MISSILE", Obituary_Missile);
			//newmis.th_gib = MissileExplodeFireballs;
			wsetanim(WANIM_FIRE1, 1, 6, MISSILELAUNCHER_SINGLE_REFIRE);
			return TRUE;
		}
		return TRUE;
	}
	return TRUE;
};

float BOMBLAUNCHER_SINGLE_DAMAGE = 90;
float BOMBLAUNCHER_SINGLE_FORCE = 90;
float BOMBLAUNCHER_SINGLE_RADIUS = 150;
float BOMBLAUNCHER_SINGLE_REFIRE = 0.8;
float BOMBLAUNCHER_AMMO = 3;
float BOMBLAUNCHER_AMMOREGEN = 1;

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_Bomb =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " was blasted by a bomb from ";
		deathstring3 = attacker.netname;
		deathstring4 = "";
		if (targ.bodyhealth < 1)
			deathstring2 = " was obliterated by ";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

float(float request) w_mbomblauncher =
{
	if (request == WR_REGISTER)
	{
		precache_model("progs/v_dprock.mdl");
		precache_model("progs/grenade.mdl");
		precache_sound("weapons/grenade.wav");
		precache_sound("weapons/bounce.wav");
		registerweapon(6, "Bomb Launcher", w_mbomblauncher, "mbomblauncher", VWEP_GRENADE_LAUNCHER, "progs/v_dprock.mdl", IT_ROCKETS, 0, 2000, 9998, WANIMTYPE_ROCKET);
		return TRUE;
	}
	if (request == WR_HASAMMO)
		return TRUE;//Inventory_Quantity(self, "rockets") > 0;
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
	if (request == WR_ANIMATIONFINISH)
	{
		if (self.wanim_id == WANIM_LOWER)
			wswitch();
		else
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request == WR_AIM)
	{
		self.button0 = w_grenadeattackaim(600, 2);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
	wanimate();
	self.currentammo = bound(0, self.currentammo + BOMBLAUNCHER_AMMOREGEN * frametime, BOMBLAUNCHER_AMMO);//Inventory_Quantity(self, "rockets");
	if (self.wanim_id == WANIM_READY)
	{
		if (self.switchweaponclass != self.weaponclass)
		{
			wsetanim(WANIM_LOWER, 7, 2, 0.2);
			return TRUE;
		}
		if (self.button3)
			self.detonatetimeout = time + 0.1;
		if (self.button0)
		if (self.currentammo >= 1)
		//if (Inventory_Quantity(self, "rockets") > 0)
		{
			W_Hostile();
			sound(self, CHAN_WEAPON, "weapons/grenade.wav", 1, ATTN_NORM);
			//Inventory_AdjustQuantity(self, "rockets", -1);
			self.currentammo = self.currentammo - 1;
			w_muzzleflash(shotorg, 0);
			LaunchMine(shotorg, shotdir * 600 + v_up * 200, self, BOMBLAUNCHER_SINGLE_DAMAGE, BOMBLAUNCHER_SINGLE_FORCE, BOMBLAUNCHER_SINGLE_RADIUS, 1, 1, /*MINE_PROXIMITY | */MINE_DETONATABLE, 5, 0, "BOMB", Obituary_Bomb);
			newmis.radiusdamage_ownerdamagescale = 0.1;
			//newmis.th_gib = BombExplodeFireballs;
			wsetanim(WANIM_FIRE1, 1, 6, BOMBLAUNCHER_SINGLE_REFIRE);
			return TRUE;
		}
		return TRUE;
	}
	return TRUE;
};

.entity grapple;

void() grappleflythink;

void() grapplereturnthink =
{
	self.nextthink = time;
	if (time > self.count2)
	{
		self.count2 = time + 0.05;
		te_lightning2(self.owner, self.owner.origin + '0 0 16', self.origin);
	}
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
	if (time > self.count2)
	{
		self.count2 = time + 0.05;
		te_lightning2(self.owner, self.owner.origin + '0 0 16', self.origin);
	}
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
	if (time > self.count2)
	{
		self.count2 = time + 0.05;
		te_lightning2(self.owner, self.owner.origin + '0 0 16', self.origin);
	}
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

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_LightningGrapple =
{
	if (dtype == DTYPE_PLAYER)
	{
		deathstring1 = targ.netname;
		deathstring2 = " was zapped by ";
		deathstring3 = attacker.netname;
		deathstring4 = "";
		if (targ.bodyhealth < 1)
			deathstring2 = " was obliterated by ";
	}
	else
		Obituary_Fallback(targ, attacker, dmsg, dtype);
};

.float grappletime;
.float grapplesoundtime;
.float grappleactive;
.entity grappletarget;
.vector grappledest;
void() w_frame_grapple =
{
	local vector vstart, vend, vdir;
	if (self.button5) // fire
	{
		if (metroidmode)
		{
			if (!self.grappleactive)
			if (Inventory_Quantity(self, "mgrapple"))
			{
				W_SetupShot();
				weapontraceline(shotorg, shotorg + shotdir * 2000, FALSE, self);
				if (trace_fraction < 1)
				if (pointcontents(trace_endpos) != CONTENT_SKY)
				{
					self.grappleactive = TRUE;
					self.grappletarget = trace_ent;
					self.grappledest = trace_endpos - trace_ent.origin;
					sound(self, CHAN_AUTO, "weapons/lstart.wav", 1, ATTN_STATIC);
					sound(self, CHAN_AUTO, "player/axhit2.wav", 1, ATTN_STATIC);
				}
			}
			if (self.grappleactive)
			{
				if (self.grappletarget.solid)
				{
					W_SetupShot();
					vstart = self.origin + '0 0 16';
					vend = self.grappletarget.origin + self.grappledest;
					vdir = normalize(vend - vstart);
					vend = vend + vdir; // go just a little bit past
					te_lightning2(self, vstart, vend);
					self.velocity = vdir * 1000;
					//self.velocity = self.velocity + vdir * 10 * self.forcescale;
					self.flags = self.flags - (self.flags & FL_ONGROUND);
					/*
					if (time > self.grapplesoundtime)
					{
						self.grapplesoundtime = time + 0.2;
						sound(self, CHAN_WEAPON2, "weapons/lhit.wav", 1, ATTN_STATIC);
					}
					*/
					if (time > self.grappletime)
					{
						self.grappletime = time + 0.1;
						W_BeamDamage(self, self, vstart, vend, 5, 5, "LIGHTNINGGRAPPLE", DT_LIGHTNING, Obituary_LightningGrapple);

						/*
						weapontraceline(vstart, vend, FALSE, self);

						if (trace_fraction < 1)
						if (trace_ent != self.grappletarget)
							T_Damage(trace_ent, self, self, 5, 5, "LIGHTNINGGRAPPLE", DT_LIGHTNING, trace_endpos, vdir * -10, Obituary_LightningGrapple);

						T_Damage(self.grappletarget, self, self, 5, 5, "LIGHTNINGGRAPPLE", DT_LIGHTNING, vend, vdir * -10, Obituary_LightningGrapple);
						*/
					}
				}
				else // unable to use grapple again until button is released
					self.grappletime = time + 999999999;
			}
		}
		else
		{
			if (!self.grapple)
			if (W_ShotsToFire(0.5))
				W_GrappleFireCode();
		}
	}
	else if (self.grappleactive)
	{
		sound(self, CHAN_WEAPON2, "weapons/bounce2.wav", 1, ATTN_STATIC);
		self.grappleactive = FALSE;
	}
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

void() mctf_precache;
void() W_Precache =
{
	if (game == GAME_NEXUIZ)
	{
		precache_model("models/bullet.mdl");
		precache_model("models/casing.mdl");
		precache_model("models/grenademodel.md3");
		precache_model("models/hagarmissile.mdl");
		precache_model("models/rocketmissile.mdl");
		precache_model("models/spike.mdl");

		precache_model("models/gibs/bloodyskull.md3");
		precache_model("models/gibs/eye.md3");
		precache_model("models/gibs/gib1.mdl");
		precache_model("models/gibs/gib2.mdl");
		precache_model("models/gibs/gib3.mdl");
		precache_model("models/gibs/gib4.mdl");

		precache_model("models/items/a_bullets.zym");
		precache_model("models/items/a_cells.md3");
		precache_model("models/items/a_rockets.md3");
		precache_model("models/items/a_shells.md3");
		precache_model("models/items/g_a1.md3");
		precache_model("models/items/g_a25.md3");
		precache_model("models/items/g_h1.md3");
		precache_model("models/items/g_h100.md3");
		precache_model("models/items/g_h25.md3");
		precache_model("models/items/g_invincible.zym");
		precache_model("models/items/g_slowmo.zym");
		precache_model("models/items/g_speed.zym");
		precache_model("models/items/g_strength.zym");

		precache_model("models/player/dummy.zym");
		precache_model("models/player/grunt.zym");
		precache_model("models/player/headhunter.zym");
		precache_model("models/player/joandarc.zym");
		precache_model("models/player/marine.zym");
		precache_model("models/player/player.zym");
		precache_model("models/player/pryia.zym");
		precache_model("models/player/shock.zym");
		precache_model("models/player/visitant.zym");

		precache_model("models/sprites/dpexplosion1.spr32");
		precache_model("models/sprites/dpexplosion2.spr32");
		precache_model("models/sprites/muzzleflash.spr32");
		precache_model("models/sprites/plasmahitwall.spr32");
		precache_model("models/sprites/plasmashot.spr32");
		precache_model("models/sprites/spark.spr");
		precache_model("models/sprites/s_explod.spr");
		precache_model("models/sprites/s_hexpl.spr");

		precache_model("models/weapons/g_crylink.md3");
		precache_model("models/weapons/g_electro.md3");
		precache_model("models/weapons/g_gl.md3");
		precache_model("models/weapons/g_hagar.md3");
		precache_model("models/weapons/g_nex.md3");
		precache_model("models/weapons/g_rl.md3");
		precache_model("models/weapons/g_shotgun.md3");
		precache_model("models/weapons/g_uzi.md3");
		precache_model("models/weapons/w_crylink.md3");
		precache_model("models/weapons/w_electro.md3");
		precache_model("models/weapons/w_gl.md3");
		precache_model("models/weapons/w_hagar.md3");
		precache_model("models/weapons/w_laser.md3");
		precache_model("models/weapons/w_nex.md3");
		precache_model("models/weapons/w_rl.md3");
		precache_model("models/weapons/w_shotgun.md3");
		precache_model("models/weapons/w_uzi.md3");
		precache_model("models/weapons/w_crylink.zym");
		precache_model("models/weapons/w_electro.zym");
		precache_model("models/weapons/w_hagar.zym");
		precache_model("models/weapons/w_nex.zym");
		precache_model("models/weapons/w_rl.zym");
		precache_model("models/weapons/w_shotgun.zym");
		precache_model("models/weapons/w_laser.zym");
		precache_model("models/weapons/w_uzi.zym");
		precache_model("models/weapons/w_gl.zym");
		precache_model("models/hagarmissile.mdl");
		precache_model("models/rocketmissile.mdl");

		precache_model("progs/beam.mdl");
		precache_model("progs/bolt.mdl");
		precache_model("progs/s_bubble.spr");
		precache_model("progs/s_light.spr");

		precache_sound("demon/dland2.wav");
		precache_sound("level/jumppad.wav");
		//precache_sound("misc/bodyimpact1.wav");
		//precache_sound("misc/bodyimpact2.wav");
		precache_sound("misc/menu1.wav");
		//precache_sound("player/hitground1.wav");
		//precache_sound("player/hitground2.wav");
		precache_sound("weapons/bullethitwall1.wav");
		precache_sound("weapons/bullethitwall2.wav");
		precache_sound("weapons/bullethitwall3.wav");
		precache_sound("weapons/crylink.wav");
		precache_sound("weapons/electro_fire.wav");
		precache_sound("weapons/grenade_bounce.wav");
		precache_sound("weapons/grenade_fire.wav");
		precache_sound("weapons/grenade_impact.wav");
		precache_sound("weapons/hagar_fire.wav");
		precache_sound("weapons/hagexp1.wav");
		precache_sound("weapons/hagexp2.wav");
		precache_sound("weapons/hagexp3.wav");
		precache_sound("weapons/invshot.wav");
		precache_sound("weapons/lazergun_fire.wav");
		precache_sound("weapons/nexfire.wav");
		precache_sound("weapons/neximpact.wav");
		precache_sound("weapons/rocket_fire.wav");
		precache_sound("weapons/rocket_impact.wav");
		precache_sound("weapons/shotgun_fire.wav");
		precache_sound("weapons/uzi_fire.wav");
		precache_sound("weapons/weaponpickup.wav");

		// TODO: Nexuiz weapons
	}
	else
	{
		precache_model("progs/s_explod.spr");
		precache_model("progs/spike.mdl");
		precache_model("progs/s_spike.mdl");
		precache_model("progs/muzzleflash.spr32");
		precache_model("progs/missile.mdl");
		precache_model("progs/grenade.mdl");
		precache_model("progs/flame2.mdl");
		precache_sound("fire/burn.wav");
		grapple_precache();
		mctf_precache();

		w_axe(WR_REGISTER);
		//w_chainsaw(WR_REGISTER);
		//w_pistol(WR_REGISTER);
		w_shotgun(WR_REGISTER);
		//w_plasmashotgun(WR_REGISTER);
		//w_prickler(WR_REGISTER);
		w_dbshotgun(WR_REGISTER);
		//w_scattergun(WR_REGISTER);
		if (cvar("registered"))
			w_laserrifle(WR_REGISTER);
		w_nailgun(WR_REGISTER);
		w_supernailgun(WR_REGISTER);
		w_grenadelauncher(WR_REGISTER);
		//w_backpackmortar(WR_REGISTER);
		w_rocketlauncher(WR_REGISTER);
		//w_jackhammer(WR_REGISTER);
		w_thunderbolt(WR_REGISTER);
		w_plasmarifle(WR_REGISTER);
		w_plasmawave(WR_REGISTER);
		w_flamer(WR_REGISTER);

		//w_handgrenade(WR_REGISTER);
		//w_hopper(WR_REGISTER);
		//w_rifle(WR_REGISTER);
		//w_machinegun(WR_REGISTER);
		//w_vulcan(WR_REGISTER);
		//w_executioner(WR_REGISTER);
		//w_jackhammer(WR_REGISTER);
		//w_grenadelauncher2(WR_REGISTER);
		//w_backpackmortar(WR_REGISTER);
		//w_incinerator(WR_REGISTER);
		//w_railgun(WR_REGISTER);

		w_mplasmacannon(WR_REGISTER);
		w_micecannon(WR_REGISTER);
		w_mplasmabeam(WR_REGISTER);
		w_mbomblauncher(WR_REGISTER);
		w_mmissilelauncher(WR_REGISTER);
	}
};

