
float   stopfiring; // set by uniquefunc when out of ammo or whatever
.float  wload;
.float  wloadtime;

void() common_precache =
{
	precache_model("progs/muzzleflash.spr32");
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

vector(vector srcvec, vector dstvec) w_directaim =
{
	traceline(srcvec, dstvec, FALSE, self);
	if (trace_fraction < 1 && trace_ent != self.enemy)
		return '0 0 0';
	return dstvec - srcvec;
};

vector(vector srcvec, vector dstvec) w_rocketaim =
{
	if (vlen(dstvec - srcvec) < 150)
		return '0 0 0';
	traceline(srcvec, dstvec, FALSE, self);
	if (trace_fraction < 1 && trace_ent != self.enemy)
		return '0 0 0';
	return dstvec - srcvec;
};

vector(vector srcvec, vector dstvec) w_grenadeaim =
{
	local   vector  v;
	if (vlen(dstvec - srcvec) < 150)
		return '0 0 0';
	traceline(srcvec, dstvec, FALSE, self);
	if (trace_fraction < 1 && trace_ent != self.enemy)
		return '0 0 0';
	if (!findtrajectorywithleading(srcvec, '0 0 0', '0 0 0', self.enemy, 600, 5, 0, self))
		return '0 0 0';
	return findtrajectory_velocity;
};

.float notfiring;

void(string firingsound, float nextshotdelay, void() uniquefunc) W_GenericFireCode =
{
	local   float   nextshotdelay;

	if (time < self.attack_finished) // still busy with the last shot
		return;

	stopfiring = FALSE;
	fightdone = time + 1; // delay stuff until fighting is over

	// not firing yet, set base time to avoid double shots
	if (self.notfiring)
		self.attack_finished = time;
	self.notfiring = FALSE;

	if (firingsound != "")
		sound (self, CHAN_WEAPON, firingsound, 1, ATTN_NORM);
	SuperDamageSound();

	// wake up monsters
	self.show_hostile = time + 1;
	weaponwakeup(self.origin, self);

	while (time >= self.attack_finished && !stopfiring)
	{
		self.attack_finished = self.attack_finished + nextshotdelay;
		uniquefunc();
	}

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

float(float w, float hasammo, float request, void() setupfunc, void() activefunc, void() raisefunc, vector(vector srcvec, vector dstvec) aimfunc, float() ratingfunc, string wname) weapongeneric =
{
	local string s;
	local vector v;
	if (request == WR_SETUP)
	{
		setupfunc();
		return TRUE;
	}
	if (request == WR_SELECTABLE)
	{
		if (!(self.items & w))
			return FALSE;
		return hasammo;
	}
	if (request == WR_RAISE)
	{
		self.weapon = self.switchweapon;
		self.weaponframecode = raisefunc;
		self.wburst = 0;
		self.wload = 0;
		raisefunc();
		return TRUE;
	}
	if (request == WR_INSTANT)
	{
		self.weapon = self.switchweapon;
		self.weaponframecode = activefunc;
		raisefunc(); // sometimes needed to initialize some variables (whether a shotgun is loaded, etc)
		activefunc();
		return TRUE;
	}
	if (request == WR_AIM)
	{
		weaponaimdir = aimfunc(self.origin + '0 0 16', weaponaimtarget);
		return weaponaimdir != '0 0 0';
	}
	if (request == WR_NAME)
	{
		weaponstring = wname;
		return TRUE;
	}
	if (request == WR_WEAPONRATING)
		return ratingfunc();
	bprint("weapongeneric: invalid request number: ");
	bprintfloat(request);
	bprint("\n");
	return FALSE;
};

void(float w, float ammotype, float ammo, float vwep, string m) wset =
{
	self.weapon = w;
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
	if (self.weapon != self.switchweapon)
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
	if (self.weapon != self.switchweapon)
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
	if (self.switchweapon == self.weapon)
	if (!setweapon(self.weapon, WR_SELECTABLE))
		self.switchweapon = W_BestWeapon(TRUE);
	if (!setweapon(self.switchweapon, WR_SELECTABLE))
		self.switchweapon = self.weapon;
	if (self.switchweapon != self.weapon)
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
