
// player animations that can be called from weapon code
void() player_axe1;
void() player_axeb1;
void() player_axec1;
void() player_axed1;
void() player_shot1;
void() player_nail1;
void() player_rocket1;
void() player_light1;

void() W_SetupShot;

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

float(entity e) w_shouldattack =
{
	if (!e.takedamage)
		return FALSE;
	if (e.team == self.team)
	{
		if (teamplay)
			return FALSE;
		if (e == self)
			return FALSE;
	}
	if (coop)
	if (e.classname == self.classname)
		return FALSE;
	if (e.health <= 0)
		return FALSE;
	if (e.deadflag)
		return FALSE;
	if (e.flags & FL_NOTARGET)
		return FALSE;
	return TRUE;
};

.float painintensity;
.entity aimtarg;
.float aimlatency;
.vector aimtargorigin;
.vector aimtargvelocity;
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

	// turn
	self.v_angle = self.v_angle + diffang * min(1, (6 * (skill + 1)) * frametime);
	while (self.v_angle_y < -180)
		self.v_angle_y = self.v_angle_y + 360;
	while (self.v_angle_y >= 180)
		self.v_angle_y = self.v_angle_y - 360;

	// since v_angle changed, we need to call W_SetupShot again
	W_SetupShot();

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

float(float shotspeed, float maxshottime, float applygravity) w_aim =
{
	local float f, r;
	local vector v;
	W_SetupShot();
	v = w_shotlead(self.aimtargorigin, self.aimtargvelocity, shotspeed, self.aimlatency);
	r = vlen(v - shotorg);
	if (applygravity)
	{
		if (!findtrajectorywithleading(shotorg, '0 0 0', '0 0 0', self.aimtarg, shotspeed, maxshottime, 0, self))
			return FALSE;
		f = w_aimdir(findtrajectory_velocity, min(10, 720 / r));
	}
	else
	{
		f = w_aimdir(v - shotorg, min(10, 720 / r));
		//dprint("AIM: ");dprint(vtos(self.aimtargorigin));dprint(" + ");dprint(vtos(self.aimtargvelocity));dprint(" * ");dprint(ftos(self.aimlatency + vlen(self.aimtargorigin - shotorg) / shotspeed));dprint(" = ");dprint(vtos(v));dprint(" : aimdir = ");dprint(vtos(normalize(v - shotorg)));dprint(" : ");dprint(vtos(shotdir));dprint("\n");
		traceline(shotorg, shotorg + shotdir * 10000, FALSE, self);
		if (trace_fraction < 1)
		if (!w_shouldattack(trace_ent))
			return FALSE;
	}
	if (r > maxshottime * shotspeed)
		return FALSE;
	return f;
};

void() W_Hostile =
{
	// wake up monsters
	self.show_hostile = time + 1;
	fightdone = time + 1; // delay stuff until fighting is over
	SuperDamageSound();
};

// linked list of weapon classes
// note: looped double linked list (can seek forward/backward)
entity w_chain;
// links for weapon classes list
.entity w_next;
.entity w_prev;

void(float wimpulse, string printname, float(float request) func, string itemname, string modelname, float ammoitembit, float minrange, float preferredrange, float baserating) registerweapon =
{
	newmis = spawn();
	newmis.classname = "weaponclass";
	newmis.impulse = wimpulse;
	newmis.netname = printname;
	newmis.w_func = func;
	newmis.w_item = itemname;
	newmis.weaponmodel = modelname;
	newmis.items = ammoitembit;
	newmis.count = minrange;
	newmis.count2 = preferredrange;
	newmis.count3 = baserating;
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

.float wanim_framesleft;
void(float animid, float startframe, float deltaframe, float deltatime) wsetanim =
{
	self.wanim_id = animid;
	self.wanim_increment = 1;
	if (deltaframe == 0)
		deltaframe = 1;
	else if (deltaframe < 0)
		self.wanim_increment = -1;
	self.wanim_framesleft = deltaframe * self.wanim_increment;
	self.wanim_frameseconds = deltatime / self.wanim_framesleft;
	self.wanim_finalframe = startframe + deltaframe;
	self.weaponframe = startframe;
	self.wanim_accumulator = self.wanim_accumulator - self.wanim_frameseconds;
	self.weaponclass.w_func(WR_ANIMATIONFRAME);
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
};

void(entity wclass, float instantswitch) wsetweapon =
{
	self.switchweaponclass = wclass;
	self.weaponclass = wclass;
	self.items = (self.items - (self.items & (IT_SHELLS | IT_NAILS | IT_ROCKETS | IT_CELLS))) | self.weaponclass.items;
	self.weaponmodel = self.weaponclass.weaponmodel;
	self.weaponframe = 0;
	W_SetupShot();
	if (instantswitch)
		self.weaponclass.w_func(WR_INSTANTSETUP);
	else
		self.weaponclass.w_func(WR_SETUP);
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
========
SuperDamageSound

Plays sound if needed
========
*/
void() SuperDamageSound =
{
	if (self.items & IT_QUAD)
	{
		if (self.super_sound < time)
		{
			self.super_sound = time + 1;
			sound (self, CHAN_BODY, "items/damage3.wav", 1, ATTN_NORM);
		}
	}
	return;
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
	wclass = w_chain;
	do
	{
		Inventory_SetQuantity(self, wclass.w_item, 1);
		wclass = wclass.w_next;
	}
	while(wclass != w_chain);

	self.impulse = 0;
};

.float seenhelp;

void() W_SetupShot =
{
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
void() w_frame_grapple;
void() W_WeaponFrame =
{
	local vector v;
	local float f;
	local string s;

	updateammodisplay(self);

	if (time > self.seenhelp)
	{
		if (self.seenhelp == 0)
			self.seenhelp = time + 5;
		else
		{
			self.seenhelp = time + 9999999;
			centerprint(self, "Lord Havoc's Dark Places\nbe sure to type dphelp in console for very useful information\nhttp://icculus.org/twilight/darkplaces\n");
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
		self.button0 = self.button3 = self.button4 = self.button5 = self.button6 = self.button7 = self.button8 = self.buttonuse = 0;

	W_SetupShot();

	if (self.button4)
		self.viewzoom = 0.2;
	else
		self.viewzoom = 1;

	if (self.weaponclass == self.switchweaponclass)
	if (self.weaponclass.w_func)
	if (!self.weaponclass.w_func(WR_HASAMMO))
		self.switchweaponclass = W_BestWeaponClass(FALSE);

	w_frame_grapple();

	// weapon animation, firing, etc
	if (self.weaponclass)
	{
		self.weaponclass.w_func(WR_FRAME);
		// run 10 times to give a weapon a chance to fire multiple times per
		// frame if needed
		self.wanim_accumulator = self.wanim_accumulator + frametime;
		f = 0;
		while (self.wanim_accumulator > 0 && f < 10)
		{
			f = f + 1;
			self.weaponframe = self.weaponframe + self.wanim_increment;
			if (self.weaponframe == self.wanim_finalframe)
				self.weaponclass.w_func(WR_ANIMATIONFINISH);
			else
			{
				self.wanim_accumulator = self.wanim_accumulator - self.wanim_frameseconds;
				self.weaponclass.w_func(WR_ANIMATIONFRAME);
			}
		}
		// if 10 frames was not enough to push the accumulator into the
		// negatives, reset it
		if (self.wanim_accumulator > 0)
			self.wanim_accumulator = 0;
	}

	if (cvar("temp1") & 4096)
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

float AXE_REFIRE = 0.5;
float SHOTGUN_REFIRE = 0.5;
float DBSHOTGUN_AMMO = 2;
float DBSHOTGUN_REFIRE = 0.7;
float NAILGUN_REFIRE = 0.1;
float NAILGUN_MINE_IMPACT = 10;
float NAILGUN_MINE_IMPACTBODY = 5;
float NAILGUN_MINE_TIME = 600;
float NAILGUN_MINE_ARMDELAY = 3;
float SUPERNAILGUN_REFIRE = 0.05;
float SUPERNAILGUN_GRENADE_TIME = 60;
float GRENADELAUNCHER_REFIRE = 0.6;
float ROCKETLAUNCHER_REFIRE = 0.8;
float ROCKETLAUNCHER_LOADTIME = 0.2;
float ROCKETLAUNCHER_MAXLOAD = 2;
float ROCKETLAUNCHER_VELOCITY = 3000;
float ROCKETLAUNCHER_MULTI_VELOCITY = 3000;
float THUNDERBOLT_REFIRE = 0.1;
float PLASMARIFLE_NORMAL_AMMO = 1;
float PLASMARIFLE_NORMAL_RADIUS = 80;
float PLASMARIFLE_NORMAL_VELOCITY = 5000;
float PLASMARIFLE_NORMAL_REFIRE = 0.1;
float PLASMARIFLE_SUPER_AMMO = 4;
float PLASMARIFLE_SUPER_RADIUS = 80;
float PLASMARIFLE_SUPER_VELOCITY = 5000;
float PLASMARIFLE_SUPER_REFIRE = 0.5;
float PLASMAWAVE_SINGLE_AMMO = 10;
float PLASMAWAVE_SINGLE_REFIRE = 0.6;
float PLASMAWAVE_SINGLE_BURNRADIUS = 120;
float PLASMAWAVE_WAVE_CELL = 30;
float PLASMAWAVE_WAVE_MAXAMMO = 50;
float PLASMAWAVE_WAVE_AMMOPERSHOT = 5;
float PLASMAWAVE_WAVE_MAXSHOTS = 10;
float PLASMAWAVE_WAVE_CHARGETIME = 0.5;
float PLASMAWAVE_WAVE_REFIRE = 1.1;
float PLASMAWAVE_WAVE_BURNRADIUS = 120;
float PLASMAWAVE_WAVE_SPREADANGLEPERSHOT = 6;
float LASERRIFLE_REFIRE = 0.2;

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

// called from player animations
void() W_FireAxe =
{
	W_SetupShot();
	weapontraceline (shotorg, shotorg + shotdir * 64, FALSE, self);
	if (trace_fraction < 1)
	{
		if (trace_ent.solid == SOLID_BSP)
		{
			sound (self, CHAN_WEAPON, "player/axhit2.wav", 1, ATTN_NORM);
			te_gunshot(trace_endpos - shotdir * 4);
		}
		T_Damage (trace_ent, self, self, AMMO_AXE_DAMAGE, AMMO_AXE_BODYDAMAGE, "AXE", DT_AX, trace_endpos - shotdir * 4, '0 0 0', Obituary_Axe);
	}
};

float(float request) w_axe =
{
	local float f;
	if (request == WR_REGISTER)
	{
		precache_model("progs/v_axe.mdl");
		// the * 0.1 is because the axe has limited range
		registerweapon(1, "Axe", w_axe, "axe", "progs/v_axe.mdl", 0, 0, 2000, AMMO_AXE_DAMAGE / AXE_REFIRE * 0.1);
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
		self.button0 = w_aim(10000, 1, FALSE);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
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
			//W_Hostile(); // axe doesn't wake up monsters
			f = random() * 4;
			// animate the player model, and the view model
			if (f < 1)
			{
				player_axe1();
				wsetanim(WANIM_FIRE1, 1, 4, AXE_REFIRE);
			}
			else if (f < 2)
			{
				player_axeb1();
				wsetanim(WANIM_FIRE1, 5, 4, AXE_REFIRE);
			}
			else if (f < 3)
			{
				player_axec1();
				wsetanim(WANIM_FIRE1, 1, 4, AXE_REFIRE);
			}
			else
			{
				player_axed1();
				wsetanim(WANIM_FIRE1, 5, 4, AXE_REFIRE);
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
		registerweapon(2, "Shotgun", w_shotgun, "shotgun", "progs/v_dpshot.mdl", IT_SHELLS, 0, 2000, AMMO_SHELL_DAMAGE / SHOTGUN_REFIRE);
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
		self.button0 = w_aim(10000, 1, FALSE);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
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
			FireBullets(self, self, 1, 10, AMMO_SHELL_DAMAGE * 0.1, AMMO_SHELL_BODYDAMAGE * 0.1, 0, 0, shotdir * 10000, 0.03, "SHOTGUN", DT_SHOTGUN, Obituary_Shotgun);
			player_shot1();
			wsetanim(WANIM_FIRE1, 1, 6, SHOTGUN_REFIRE);
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
		registerweapon(3, "Double Barreled Shotgun", w_dbshotgun, "supershotgun", "progs/v_dpshot2.mdl", IT_SHELLS, 0, 500, AMMO_SHELL_DAMAGE * DBSHOTGUN_AMMO / DBSHOTGUN_REFIRE);
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
		self.button0 = w_aim(10000, 1, FALSE);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
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
				FireBullets(self, self, 1, 10, AMMO_SHELL_DAMAGE * 0.1, AMMO_SHELL_BODYDAMAGE * 0.1, 0, 0, shotdir * 10000, 0.1, "SHOTGUN", DT_SHOTGUN, Obituary_DBShotgun);
			}
			if (Inventory_Quantity(self, "shells") >= 1)
			{
				self.shotgunshells = self.shotgunshells | 2;
				Inventory_AdjustQuantity(self, "shells", -1);
				FireBullets(self, self, 1, 10, AMMO_SHELL_DAMAGE * 0.1, AMMO_SHELL_BODYDAMAGE * 0.1, 0, 0, shotdir * 10000, 0.1, "SHOTGUN", DT_SHOTGUN, Obituary_DBShotgun);
			}
			player_shot1();
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
		registerweapon(4, "Nailgun", w_nailgun, "nailgun", "progs/v_dpnail.mdl", IT_NAILS, 0, 4000, AMMO_NAIL_DAMAGE / NAILGUN_REFIRE);
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
				w_muzzleflash(shotorg, 0);//2);
				Inventory_AdjustQuantity(self, "nails", -1);
				v = shotorg;
				if (self.weaponframe & 1)
				{
					shotorg = shotorg + v_right;
					FireBullets(self, self, 4, 1, AMMO_NAIL_DAMAGE, AMMO_NAIL_BODYDAMAGE, 0, 0, shotdir * 10000, 0.01, "NAILGUN", DT_NAIL, Obituary_Nailgun);
					//ejectcasing(shotorg + v_forward * -5, v_right *  150 + v_up * 50, 50, self.v_angle_x * '-1 0 0' + self.v_angle_y * '0 1 0', '0 250 0', 100, 0);
				}
				else
				{
					shotorg = shotorg - v_right;
					FireBullets(self, self, 4, 1, AMMO_NAIL_DAMAGE, AMMO_NAIL_BODYDAMAGE, 0, 0, shotdir * 10000, 0.01, "NAILGUN", DT_NAIL, Obituary_Nailgun);
					//ejectcasing(shotorg + v_forward * -5, v_right * -150 + v_up * 50, 50, self.v_angle_x * '-1 0 0' + self.v_angle_y * '0 1 0', '0 -250 0', 100, 0);
				}
				shotorg = v;
				// update the player animation
				player_nail1();
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
		self.button0 = w_aim(10000, 1, FALSE);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
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
			wsetanim(WANIM_FIRE1, 1, 8, NAILGUN_REFIRE * 8);
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
			LaunchMine(shotorg, shotdir * 600 + v_up * 200, self, AMMO_ROCKET_DAMAGE, AMMO_ROCKET_FORCE, AMMO_ROCKET_RADIUS, NAILGUN_MINE_IMPACT, NAILGUN_MINE_IMPACTBODY, MINE_PROXIMITY, NAILGUN_MINE_TIME, NAILGUN_MINE_ARMDELAY, "PROXIMITYMINE", Obituary_NailgunMine);
			wsetanim(WANIM_FIRE2, 0, 0, 0.6);
			// update the player animation
			player_rocket1();
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
	if (request == WR_REGISTER)
	{
		precache_model("progs/v_dpnail2.mdl");
		precache_sound("weapons/spike2.wav");
		precache_sound("weapons/bomb/trigger.wav");
		registerweapon(5, "Super Nailgun", w_supernailgun, "supernailgun", "progs/v_dpnail2.mdl", IT_NAILS, 0, 1500, AMMO_NAIL_DAMAGE / SUPERNAILGUN_REFIRE);
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
				w_muzzleflash(shotorg, 0);//2);
				Inventory_AdjustQuantity(self, "nails", -1);
				FireBullets(self, self, 4, 1, AMMO_NAIL_DAMAGE, AMMO_NAIL_BODYDAMAGE, 0, 0, shotdir * 10000, 0.05, "SUPERNAILGUN", DT_NAIL, Obituary_SuperNailgun);
				if (cvar("dpmod_qcphysics_casings"))
					Ragdoll_ThrowCasing(shotorg + v_forward * -5, v_right * 200 + v_up * 75, shotorg + v_forward * -3, v_right * 150 + v_up * 50, "progs/casing_bronze.mdl");
				else
					ejectcasing(shotorg + v_forward * -5, v_right *  150 + v_up * 50, 50, self.v_angle_x * '-1 0 0' + self.v_angle_y * '0 1 0', '0 250 0', 100, 0);
				// update the player animation
				player_nail1();
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
		self.button0 = w_aim(10000, 1, FALSE);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
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
			wsetanim(WANIM_FIRE1, 1, 8, SUPERNAILGUN_REFIRE * 8);
			return TRUE;
		}
		if (self.button3)
		if (Inventory_Quantity(self, "rockets") > 0)
		{
			W_Hostile();
			sound(self, CHAN_WEAPON, "weapons/grenade.wav", 1, ATTN_NORM);
			self.wfiretime = time;
			Inventory_AdjustQuantity(self, "rockets", -1);
			w_muzzleflash(shotorg, 3);
			LaunchGrenade(shotorg, shotdir * 600 + v_up * 200, self, AMMO_ROCKET_DAMAGE, AMMO_ROCKET_FORCE, AMMO_ROCKET_RADIUS, GRENADE_IMPACT, SUPERNAILGUN_GRENADE_TIME, "SUPERNAILGUNGRENADE", Obituary_SuperNailgunGrenade);
			wsetanim(WANIM_FIRE2, 0, 0, 0.6);
			// update the player animation
			player_rocket1();
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
		registerweapon(6, "Grenade Launcher", w_grenadelauncher, "grenadelauncher", "progs/v_dprock.mdl", IT_ROCKETS, AMMO_ROCKET_RADIUS + 50, 2000, AMMO_ROCKET_DAMAGE / GRENADELAUNCHER_REFIRE);
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
		self.button0 = w_aim(1000, 2, TRUE);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
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
				LaunchGrenade(shotorg, shotdir * 1000 + v_up * 200, self, AMMO_ROCKET_DAMAGE, AMMO_ROCKET_FORCE, AMMO_ROCKET_RADIUS, GRENADE_IMPACT | GRENADE_IMMUNETODAMAGE, 25, "GRENADE", Obituary_Grenade);
			else
				LaunchGrenade(shotorg, shotdir * 1000 + v_up * 200, self, AMMO_ROCKET_DAMAGE, AMMO_ROCKET_FORCE, AMMO_ROCKET_RADIUS, GRENADE_IMMUNETODAMAGE, 3, "GRENADE", Obituary_Grenade);
			wsetanim(WANIM_FIRE1, 1, 6, GRENADELAUNCHER_REFIRE);
			// update the player animation
			player_rocket1();
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
		registerweapon(7, "Rocket Launcher", w_rocketlauncher, "rocketlauncher", "progs/v_dprock2.mdl", IT_ROCKETS, AMMO_ROCKET_RADIUS + 50, 2000, AMMO_ROCKET_DAMAGE / ROCKETLAUNCHER_REFIRE);
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
		self.button0 = w_aim(ROCKETLAUNCHER_VELOCITY, 1, FALSE);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
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
				LaunchMissile(shotorg, shotdir * ROCKETLAUNCHER_VELOCITY, self, AMMO_ROCKET_DAMAGE, AMMO_ROCKET_FORCE, AMMO_ROCKET_RADIUS, "ROCKET", Obituary_Rocket);
			}
			else
			{
				step = 360 / self.wburst;
				while (self.wburst > 0)
				{
					self.wburst = self.wburst - 1;
					LaunchMissile(shotorg, shotdir * ROCKETLAUNCHER_MULTI_VELOCITY, self, AMMO_ROCKET_DAMAGE, AMMO_ROCKET_FORCE, AMMO_ROCKET_RADIUS, "ROCKET", Obituary_Rocket);
					//newmis.angles_z = step * self.wburst;
					newmis.dest3_z = step * self.wburst;
					newmis.dest2 = '0 8 0';
					newmis.avelocity = '0 0 1440';
				}
			}
			wsetanim(WANIM_FIRE1, 1, 6, ROCKETLAUNCHER_REFIRE);
			// update the player animation
			player_rocket1();
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
	if (request == WR_REGISTER)
	{
		precache_model("progs/v_dpnail2.mdl");
		precache_model("progs/plasmashot.spr32");
		precache_sound("plasma/plasma.wav");
		precache_sound("plasma/plasexpl.wav");
		registerweapon(9, "Plasma Rifle", w_plasmarifle, "plasmarifle", "progs/v_dpnail2.mdl", IT_CELLS, 100, 1500, AMMO_CELL_DAMAGE * PLASMARIFLE_NORMAL_AMMO / PLASMARIFLE_NORMAL_REFIRE);
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
				if (cells > PLASMARIFLE_NORMAL_AMMO)
					cells = PLASMARIFLE_NORMAL_AMMO;
				FirePlasma(self, self, shotorg, shotdir * PLASMARIFLE_NORMAL_VELOCITY, AMMO_CELL_DAMAGE * cells, 0, PLASMARIFLE_NORMAL_RADIUS, "PLASMARIFLE", Obituary_PlasmaRifle);
				Inventory_AdjustQuantity(self, "cells", 0 - cells);
				//while (cells > 0)
				//{
				//	cells = cells - 1;
				//	ejectcasing(shotorg + v_forward * -5, v_right *  150 + v_up * 50, 100, self.v_angle_x * '-1 0 0' + self.v_angle_y * '0 1 0', '0 250 0', 100, 0);
				//}
				// update the player animation
				player_light1();
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
		self.button0 = w_aim(10000, 1, FALSE);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
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
			if (cells > PLASMARIFLE_SUPER_AMMO)
				cells = PLASMARIFLE_SUPER_AMMO;
			FirePlasma(self, self, shotorg, shotdir * PLASMARIFLE_SUPER_VELOCITY, AMMO_CELL_DAMAGE * cells, AMMO_CELL_DAMAGE * cells, PLASMARIFLE_SUPER_RADIUS, "PLASMARIFLE", Obituary_PlasmaRifle);
			Inventory_AdjustQuantity(self, "cells", 0 - cells);
			//while (cells > 0)
			//{
			//	cells = cells - 1;
			//	ejectcasing(shotorg + v_forward * -5, v_right *  150 + v_up * 50, 100, self.v_angle_x * '-1 0 0' + self.v_angle_y * '0 1 0', '0 250 0', 100, 0);
			//}
			self.attack_finished = time + PLASMARIFLE_SUPER_REFIRE;
			// update the player animation
			player_rocket1();
			return TRUE;
		}
		if (self.button0)
		if (time > self.attack_finished)
		if (Inventory_Quantity(self, "cells") > 0)
		{
			wsetanim(WANIM_FIRE1, 1, 8, PLASMARIFLE_NORMAL_REFIRE * 8);
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
	force = '0 0 0';//(normalize(end - start) + '0 0 0.25') * 2 * bdamage;

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
			T_Damage(e, inflictor, attacker, hdamage, bdamage, dmsg, dtype, e.lightninghitpoint, force, obitfunc);
		e = e.lightningchain;
	}
	return end;
};

.float wtime;
float(float request) w_thunderbolt =
{
	local float cells;
	local vector v;
	if (request == WR_REGISTER)
	{
		precache_model("progs/v_dplight.mdl");
		precache_model("progs/bolt2.mdl");
		precache_sound("weapons/lstart.wav");
		precache_sound("weapons/lhit.wav");
		registerweapon(8, "Thunderbolt", w_thunderbolt, "thunderbolt", "progs/v_dplight.mdl", IT_CELLS, 0, 1500, AMMO_CELL_DAMAGE / THUNDERBOLT_REFIRE);
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
			sound(self, CHAN_WEAPON, "weapons/lhit.wav", 1, ATTN_NORM);
			cells = Inventory_Quantity(self, "cells");
			if (self.button0)
			if (cells > 0)
			{
				cells = min(cells, 1);
				self.wfiretime = time;
				W_Hostile();
				Inventory_AdjustQuantity(self, "cells", 0 - cells);
				v = W_BeamDamage(self, self, shotorg, shotorg + shotdir * 100000, AMMO_CELL_DAMAGE * cells, AMMO_CELL_BODYDAMAGE * cells, "LIGHTNING", DT_LIGHTNING, Obituary_Lightning);
				te_lightning2(self, shotorg, v);
				// update the player animation
				player_light1();
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
			wsetanim(WANIM_FIRE1, 1, 4, 4 * THUNDERBOLT_REFIRE);
		else
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request == WR_AIM)
	{
		self.button0 = w_aim(100000, 1, FALSE);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
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
			wsetanim(WANIM_FIRE1, 1, 4, 4 * THUNDERBOLT_REFIRE);
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
		registerweapon(10, "Plasma Wave", w_plasmawave, "plasmawave", "progs/v_dplight.mdl", IT_CELLS, 100, 1500, PLASMAWAVE_SINGLE_AMMO * AMMO_CELL_DAMAGE / PLASMAWAVE_SINGLE_REFIRE);
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
			if (cells > PLASMAWAVE_WAVE_MAXAMMO)
				cells = PLASMAWAVE_WAVE_MAXAMMO;
			self.wfiretime = time;
			Inventory_AdjustQuantity(self, "cells", 0 - cells);
			w_muzzleflash(shotorg, 4);
			shots = ceil(cells / PLASMAWAVE_WAVE_AMMOPERSHOT);
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
			// update the player animation
			player_rocket1();
		}
		else
			wsetanim(WANIM_READY, 0, 0, 0);
		return TRUE;
	}
	if (request == WR_AIM)
	{
		if (random() < 0.2)
			self.button3 = w_aim(3000, 1, FALSE);
		else
			self.button0 = w_aim(5000, 1, FALSE);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
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
			if (cells > PLASMAWAVE_SINGLE_AMMO)
				cells = PLASMAWAVE_SINGLE_AMMO;
			self.wfiretime = time;
			Inventory_AdjustQuantity(self, "cells", 0 - cells);
			w_muzzleflash(shotorg, 4);
			FirePlasmaBall(self, self, shotorg, shotdir * 1000, cells * AMMO_CELL_DAMAGE, cells * AMMO_CELL_DAMAGE, PLASMAWAVE_SINGLE_BURNRADIUS, "PLASMAWAVE", Obituary_PlasmaWaveShot);
			wsetanim(WANIM_FIRE1, 0, 0, PLASMAWAVE_SINGLE_REFIRE);
			// update the player animation
			player_rocket1();
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
	if (request == WR_REGISTER)
	{
		precache_model("progs/v_dpshot.mdl");
		precache_model("progs/laser.mdl");
		precache_sound("enforcer/enfire.wav");
		precache_sound("enforcer/enfstop.wav");
		registerweapon(10, "Laser Rifle", w_laserrifle, "laserrifle", "progs/v_dpshot.mdl", IT_CELLS, 0, 2000, AMMO_CELL_DAMAGE / LASERRIFLE_REFIRE);
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
		self.button0 = w_aim(10000, 1, FALSE);
		return TRUE;
	}
	if (request != WR_FRAME)
		return FALSE;
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
			sound(self, CHAN_WEAPON, "enforcer/enfire.wav", 1, ATTN_NORM);
			Inventory_AdjustQuantity(self, "cells", -1);
			w_muzzleflash(shotorg, 0.5);
			LaunchLaser(self, shotorg, shotdir * 10000, AMMO_CELL_DAMAGE, "LASERRIFLE", Obituary_LaserRifle);
			wsetanim(WANIM_FIRE1, 1, 0, LASERRIFLE_REFIRE);
			// update the player animation
			player_shot1();
		}
		return TRUE;
	}
	return TRUE;
};

.entity grapple;

void() grappleflythink;

void() grapplereturnthink =
{
	local float f;
	self.nextthink = time;
	f = vlen(self.owner.origin - self.origin) / frametime;
	f = min(f, 3000);
	self.velocity = normalize(self.owner.origin - self.origin) * f;
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
	local float f;
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
	}
	else // pull owner to object
	{
		setorigin(self, (self.enemy.absmin + self.enemy.absmax) * 0.5);
		//self.enemy.velocity = normalize(self.owner.origin - self.origin) * 600;
		//self.enemy.flags = self.enemy.flags - (self.enemy.flags & FL_ONGROUND);
	}
	f = vlen(self.origin - self.owner.origin) / frametime;
	f = min(f, 1000);
	self.owner.velocity = normalize(self.origin - self.owner.origin) * f;
	self.owner.flags = self.owner.flags - (self.owner.flags & FL_ONGROUND);
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
	local float p;
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
	grapplebolt.velocity = dir * 3000;
	grapplebolt.think = grappleflythink;
	grapplebolt.nextthink = time;
	grapplebolt.cnt = time + 3;
	sound(grapplebolt, CHAN_BODY, "weapons/chain1.wav", 1, ATTN_NORM);
	c = 0.25;
	while (c < 1)
	{
		bit = spawn();
		bit.owner = grapplebolt;
		bit.think = grapplebit_think;
		bit.nextthink = time;
		bit.count = c;
		setmodel(bit, "progs/bit.mdl");
		c = c + 0.25;
	}
};

void() W_GrappleFireCode =
{
	W_Hostile();
	sound(self, CHAN_WEAPON, "weapons/sgun1.wav", 1, ATTN_NORM);
	self.wfiretime = time;
	w_muzzleflash(shotorg, 1);
	FireGrapple(self, shotorg, shotdir);
	// update the player animation
	player_rocket1();
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

.float grappleactive;
void() w_frame_grapple =
{
	if (self.button5) // fire
	{
		if (!self.grapple)
		if (time >= self.attack_finished)
		{
			self.attack_finished = time + 0.5;
			W_GrappleFireCode();
		}
	}
	else if (self.grappleactive)
	{
		sound(self, CHAN_WEAPON2, "weapons/bounce2.wav", 1, ATTN_STATIC);
		self.grappleactive = FALSE;
	}
};

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

		w_axe(WR_REGISTER);
		w_shotgun(WR_REGISTER);
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
	}
};

