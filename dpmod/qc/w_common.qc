
.float  wload;
.float  wloadtime;

void() grapple_precache;
void() common_precache =
{
	precache_model("progs/muzzleflash.spr32");
	grapple_precache();
};

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

float(float haveammo) W_CheckNoAmmo =
{
	if (haveammo)
		return TRUE;
	self.switchweapon = W_BestWeapon(TRUE);
	return FALSE;
};

.float wstate;
vector weaponaimdir;
vector weaponaimtarget;

float(string wname, float hasammo, float request, void() setupfunc, void() activefunc, void() raisefunc, string name, float minrange, float preferredrange, float baserating, void() precachefunc) weapongeneric =
{
	if (request == WR_PRECACHE)
	{
		precachefunc();
		return TRUE;
	}
	if (request == WR_SETUP)
	{
		setupfunc();
		return TRUE;
	}
	if (request == WR_SELECTABLE)
	{
		if (!Inventory_Quantity(self, wname))
			return FALSE;
		return hasammo;
	}
	if (request == WR_SWITCH)
	{
		if (Inventory_Quantity(self, wname))
		if (hasammo)
		{
			self.switchweapon = WeaponToNumber(wname);
			return TRUE;
		}
		return FALSE;
	}
	if (request == WR_RAISE)
	{
		self.activeweapon = self.switchweapon;
		self.weaponframecode = raisefunc;
		self.wburst = 0;
		self.wload = 0;
		raisefunc();
		return TRUE;
	}
	if (request == WR_INSTANT)
	{
		self.activeweapon = self.switchweapon;
		self.weaponframecode = activefunc;
		raisefunc(); // sometimes needed to initialize some variables (whether a shotgun is loaded, etc)
		activefunc();
		return TRUE;
	}
	if (request == WR_NAME)
	{
		weaponstring = name;
		return TRUE;
	}
	if (request == WR_WEAPONRATING)
		return genericweaponrating(minrange, preferredrange, baserating);
	bprint("weapongeneric: invalid request number: ");
	bprintfloat(request);
	bprint("\n");
	return FALSE;
};

void(string wname, float ammotype, float ammo, float vwep, string m) wset =
{
	self.activeweapon = WeaponToNumber(wname);
	self.items = (self.items - (self.items & (IT_SHELLS | IT_NAILS | IT_ROCKETS | IT_CELLS))) | ammotype;
	self.currentammo = ammo;
	self.visibleweapon = vwep;
	self.weaponmodel = m;
};

.void() wnextframefunc;
.float  wnextframetime, wanimframe;

void() w_switchcode = {setweapon(self.switchweapon, WR_RAISE);};

void() w_animcode =
{
	self.attack_finished = time; // avoid double shot if holding fire while switching weapons
	self.weaponframe = self.wanimframe;
	if (self.wstate == WS_RAISE)
	if (self.activeweapon != self.switchweapon)
	{
		w_switchcode();
		return;
	}
	if (time >= self.wnextframetime)
	{
		self.weaponframecode = self.wnextframefunc;
		self.weaponframecode();
	}
};

void(float f, void() framefunc, float t) wraise =
{
	self.attack_finished = time; // avoid double shot if holding fire while switching weapons
	if (self.activeweapon != self.switchweapon)
	{
		w_switchcode();
		return;
	}
	self.wstate = WS_RAISE;
	self.weaponframe = self.wanimframe = f;
	self.wnextframefunc = framefunc;
	self.wnextframetime = time + t;
	self.weaponframecode = w_animcode;
};

void(float f, void() framefunc, float t) wdrop =
{
	self.attack_finished = time; // avoid double shot if holding fire while switching weapons
	self.wstate = WS_DROP;
	self.weaponframe = self.wanimframe = f;
	self.wnextframefunc = framefunc;
	self.wnextframetime = time + t;
	self.weaponframecode = w_animcode;
};

void(float f, float t) wdropped = {wdrop(f, w_switchcode, t);};

float(void() dropfunc) widle =
{
	self.wstate = WS_ACTIVE;
	if (self.switchweapon == self.activeweapon)
	if (!setweapon(self.activeweapon, WR_SELECTABLE))
		self.switchweapon = W_BestWeapon(TRUE);
	if (!setweapon(self.switchweapon, WR_SELECTABLE))
		self.switchweapon = self.activeweapon;
	if (self.switchweapon != self.activeweapon)
	if (self.wstate == WS_ACTIVE)
	if (time > self.attack_finished)
	{
		self.wstate = WS_DROP;
		self.weaponframecode = dropfunc;
		dropfunc();
		return TRUE;
	}
	return FALSE;
};
