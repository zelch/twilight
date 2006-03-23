/*
==============================================================================

KNIGHT

==============================================================================
*/

$cd id1/models/knight2
$origin 0 0 24
$base base
$skin skin

$frame stand1 stand2 stand3 stand4 stand5 stand6 stand7 stand8 stand9

$frame walk1 walk2 walk3 walk4 walk5 walk6 walk7 walk8 walk9
$frame walk10 walk11 walk12 walk13 walk14 walk15 walk16 walk17
$frame walk18 walk19 walk20

$frame run1 run2 run3 run4 run5 run6 run7 run8

$frame pain1 pain2 pain3 pain4 pain5

$frame death1 death2 death3 death4 death5 death6 death7 death8
$frame death9 death10 death11 death12

$frame deathb1 deathb2 deathb3 deathb4 deathb5 deathb6 deathb7 deathb8
$frame deathb9

$frame char_a1 char_a2 char_a3 char_a4 char_a5 char_a6 char_a7 char_a8
$frame char_a9 char_a10 char_a11 char_a12 char_a13 char_a14 char_a15 char_a16

$frame magica1 magica2 magica3 magica4 magica5 magica6 magica7 magica8
$frame magica9 magica10 magica11 magica12 magica13 magica14

$frame magicb1 magicb2 magicb3 magicb4 magicb5 magicb6 magicb7 magicb8
$frame magicb9 magicb10 magicb11 magicb12 magicb13

$frame char_b1 char_b2 char_b3 char_b4 char_b5 char_b6

$frame slice1 slice2 slice3 slice4 slice5 slice6 slice7 slice8 slice9 slice10

$frame smash1 smash2 smash3 smash4 smash5 smash6 smash7 smash8 smash9 smash10
$frame smash11

$frame w_attack1 w_attack2 w_attack3 w_attack4 w_attack5 w_attack6 w_attack7
$frame w_attack8 w_attack9 w_attack10 w_attack11 w_attack12 w_attack13 w_attack14
$frame w_attack15 w_attack16 w_attack17 w_attack18 w_attack19 w_attack20
$frame w_attack21 w_attack22

$frame magicc1 magicc2 magicc3 magicc4 magicc5 magicc6 magicc7 magicc8
$frame magicc9 magicc10 magicc11


void() hknight_char_a1;
void() hknight_run1;
void() hk_idle_sound;

/*
===========
HellKnightCheckAttack

The player is in view, so decide to move or launch an attack
Returns FALSE if movement should continue
============
*/
float() HellKnightCheckAttack =
{
	local vector	spot1, spot2;
	local entity	targ;
	local float		chance;

	if (self.health < 1)
		return FALSE;
	targ = self.enemy;

	// see if any entities are in the way of the shot
	spot1 = self.origin + self.view_ofs;
	spot2 = targ.origin + targ.view_ofs;

	traceline (spot1, spot2, FALSE, self);

	if (trace_ent != targ)
		return FALSE; // don't have a clear shot

	if (trace_inopen && trace_inwater)
		return FALSE; // sight line crossed contents

	if (enemy_range == RANGE_MELEE)
	if (targ.classname != "monster_zombie")
	{
		// melee attack
		self.th_melee ();
		return TRUE;
	}

	// missile attack
	if (time < self.attack_finished)
		return FALSE;

	if (enemy_range == RANGE_FAR)
		return FALSE;

	if (targ.classname == "monster_zombie")
	{
		self.th_missile ();
		SUB_AttackFinished (2*random());
		return TRUE;
	}

	if (enemy_range == RANGE_MELEE)
	{
		chance = 0.9;
		self.attack_finished = 0;
	}
	else if (enemy_range == RANGE_NEAR)
		chance = 0.2;
	else if (enemy_range == RANGE_MID)
		chance = 0.05;
	else
		chance = 0;

	if (random() < chance)
	if (self.th_missile ())
	{
		SUB_AttackFinished (2*random());
		return TRUE;
	}

	return FALSE;
};

void() hknightspike_touch =
{
	local   vector  v;
	if (other == self.owner)
		return;
	if (other.solid == SOLID_TRIGGER)
		return; // trigger field, do nothing
	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}

	v = normalize(self.velocity);
	T_Damage (other, self, self.owner, 10, 10, self.deathtype, DT_FIRE, self.origin, v * 10, Obituary_Generic);
	v = self.origin - v * 8;
	te_knightspike(v);
	weaponwakeup(v, self.owner);
	remove(self);
};

void() hknightspike_think =
{
	local vector v, v2;
	self.nextthink = time;
	if (time > self.count || pointcontents(self.origin) != CONTENT_EMPTY)
	{
		remove(self);
		return;
	}
	if (self.enemy)
	{
		if (self.enemy.solid)
		{
			//vectorvectors(self.enemy.origin + '0 0 10' - self.origin);
			//v = self.enemy.origin + '0 0 10' + v_right * self.cnt;
			if (time > self.cnt2)
			{
				self.cnt2 = time + 0.2;
				self.dest = randompos(self.enemy.mins, self.enemy.maxs);
			}
			v = normalize(self.enemy.origin + self.dest - self.origin);
			v2 = normalize(self.velocity);
			if (v * v2 > 0.5)
				self.velocity = self.velocity + (v * 500 - self.velocity) * frametime * 4;
			else // can't see player anymore, fly off
				self.enemy = world;
		}
		else
			self.enemy = world;
	}
	self.angles = vectoangles(self.velocity);
};

void(float offset) hknight_shot =
{
	local	vector	offang;
	local   vector  org;
	local   vector  vec;

	offang = vectoangles (self.enemy.origin - self.origin);
	offang_y = offang_y + offset * 6;

	makevectors (offang);

	self.effects = self.effects | EF_MUZZLEFLASH;

	org = self.origin + self.mins + self.size*0.5 + v_forward * 20;

	// set missile speed
	vec = v_forward + randomvec() * 0.05;
	vec_z = 0 - vec_z;

	sound (self, CHAN_WEAPON, "hknight/attack1.wav", 1, ATTN_NORM);
//	launch_spike (org, vec * 750, self, 20, 2, self.deathtype);

	newmis = spawn ();
	newmis.shoulddodge = TRUE;
	newmis.dangerrating = 20;
	setmodel (newmis, "progs/k_spike.mdl");
	setsize (newmis, '0 0 0', '0 0 0');
	setorigin (newmis, org);
	newmis.effects = EF_ADDITIVE;
	newmis.velocity = vec * 750;
	newmis.deathtype = self.deathtype;
	newmis.owner = self;
	newmis.enemy = self.enemy;
	newmis.movetype = MOVETYPE_FLY;
	newmis.solid = SOLID_BBOX;
	newmis.angles = vectoangles(newmis.velocity);
	newmis.touch = hknightspike_touch;
	newmis.classname = "knightspike";
	newmis.think = hknightspike_think;
	newmis.nextthink = time + 0.2;
	newmis.count = time + 20;
	newmis.cnt = offset * 6;
	if (newmis.enemy == self)
		newmis.enemy = world;

	// homing shots was just too painful
	//newmis.enemy = world;
};

void() hknight_fireball =
{
	local   vector  org, vec, dir;

	traceline((self.absmin + self.absmax) * 0.5, (self.enemy.absmin + self.enemy.absmax) * 0.5, FALSE, self);
	if (trace_ent != self.enemy)
		return; // can't hit
	self.effects = self.effects | EF_MUZZLEFLASH;
	org = self.origin + '0 0 7';
	//dir = monster_shotlead(0, 1000) - org;dir = normalize(dir);
	dir = normalize((self.enemy.absmin + self.enemy.absmax) * 0.5 - (self.absmin + self.absmax) * 0.5);

	// set missile speed
	vec = dir + randomvec() * 0.05;

	LaunchFireball(org, vec * 1000, self, 30, 30, 110, 60, 300, self.deathtype, Obituary_Generic);
	newmis.movetype = MOVETYPE_FLYMISSILE;
	sound (self, CHAN_WEAPON, "weapons/sgun1.wav", 1, ATTN_NORM);
};

void() hknight_infernowarning =
{
	traceline((self.absmin + self.absmax) * 0.5, (self.enemy.absmin + self.enemy.absmax) * 0.5, TRUE, world);
	if (trace_fraction != 1)
		return; // not visible
	self.enemy.effects = self.enemy.effects | EF_MUZZLEFLASH;
	sound(self.enemy, CHAN_AUTO, "fire/burn.wav", 1, ATTN_NORM);
	//self.effects = self.effects | EF_MUZZLEFLASH;
	//sound(self, CHAN_AUTO, "fire/burn.wav", 1, ATTN_NORM);
};

void() hknight_inferno =
{
	traceline((self.absmin + self.absmax) * 0.5, (self.enemy.absmin + self.enemy.absmax) * 0.5, TRUE, world);
	if (trace_fraction != 1)
		return; // not visible
	//T_Damage(self.enemy, self, self, 75, 75, self.deathtype, DT_EXPLOSION, self.enemy.origin + '0 0 -8', '0 0 0');
	SpawnFire(self.enemy, self, 75, self.deathtype, (self.enemy.absmin + self.enemy.absmax) * 0.5);
	//SpawnFire(self, self, 500, self.deathtype, (self.enemy.absmin + self.enemy.absmax) * 0.5);
};

float() hknight_missile;

float() hknight_checkmagic =
{
	local   vector  v1, v2;
	local   float   dot;

	// use magic to kill zombies as they heal too fast for sword
	if (self.enemy.classname == "monster_zombie")
	{
		traceline((self.absmin + self.absmax) * 0.5, (self.enemy.absmin + self.enemy.absmax) * 0.5, FALSE, self);
		if (trace_ent == self.enemy)
		{
			hknight_missile();
			return TRUE;
		}
	}

	if (random() < 0.25)
		return FALSE; // 25% of the time it won't do anything
	v1 = normalize(self.enemy.velocity);
	v2 = normalize(self.enemy.origin - self.origin);
	dot = v1 * v2;
	if (dot >= 0.7) // moving away
	if (vlen(self.enemy.velocity) >= 150) // walking/running away
		return hknight_missile();
	return FALSE;
};

void() CheckForCharge =
{
	// check for mad charge
	if (!visible(self.enemy))
		return;
	if (time < self.attack_finished)
		return;
	if ( fabs(self.origin_z - self.enemy.origin_z) > 20)
		return;		// too much height change
	if ( vlen (self.origin - self.enemy.origin) < 80)
		return;		// use regular attack
	if (hknight_checkmagic())
		return; // chose magic

	// charge
	SUB_AttackFinished (2);
	hknight_char_a1 ();
};

void() CheckContinueCharge =
{
	if (hknight_checkmagic())
		return; // chose magic
	if (time > self.attack_finished)
	{
		SUB_AttackFinished (3);
		hknight_run1 ();
		return;		// done charging
	}
	if (random() > 0.5)
		sound (self, CHAN_WEAPON, "knight/sword2.wav", 1, ATTN_NORM);
	else
		sound (self, CHAN_WEAPON, "knight/sword1.wav", 1, ATTN_NORM);
};

//===========================================================================

void()	hknight_stand1	=[	$stand1,	hknight_stand2	] {ai_stand();};
void()	hknight_stand2	=[	$stand2,	hknight_stand3	] {ai_stand();};
void()	hknight_stand3	=[	$stand3,	hknight_stand4	] {ai_stand();};
void()	hknight_stand4	=[	$stand4,	hknight_stand5	] {ai_stand();};
void()	hknight_stand5	=[	$stand5,	hknight_stand6	] {ai_stand();};
void()	hknight_stand6	=[	$stand6,	hknight_stand7	] {ai_stand();};
void()	hknight_stand7	=[	$stand7,	hknight_stand8	] {ai_stand();};
void()	hknight_stand8	=[	$stand8,	hknight_stand9	] {ai_stand();};
void()	hknight_stand9	=[	$stand9,	hknight_stand1	] {ai_stand();};

//===========================================================================

void()	hknight_walk1	=[	$walk1,		hknight_walk2	] {
hk_idle_sound();
ai_walk(2);};
void()	hknight_walk2	=[	$walk2,		hknight_walk3	] {ai_walk(5);};
void()	hknight_walk3	=[	$walk3,		hknight_walk4	] {ai_walk(5);};
void()	hknight_walk4	=[	$walk4,		hknight_walk5	] {ai_walk(4);};
void()	hknight_walk5	=[	$walk5,		hknight_walk6	] {ai_walk(4);};
void()	hknight_walk6	=[	$walk6,		hknight_walk7	] {ai_walk(2);};
void()	hknight_walk7	=[	$walk7,		hknight_walk8	] {ai_walk(2);};
void()	hknight_walk8	=[	$walk8,		hknight_walk9	] {ai_walk(3);};
void()	hknight_walk9	=[	$walk9,		hknight_walk10	] {ai_walk(3);};
void()	hknight_walk10	=[	$walk10,	hknight_walk11	] {ai_walk(4);};
void()	hknight_walk11	=[	$walk11,	hknight_walk12	] {ai_walk(3);};
void()	hknight_walk12	=[	$walk12,	hknight_walk13	] {ai_walk(4);};
void()	hknight_walk13	=[	$walk13,	hknight_walk14	] {ai_walk(6);};
void()	hknight_walk14	=[	$walk14,	hknight_walk15	] {ai_walk(2);};
void()	hknight_walk15	=[	$walk15,	hknight_walk16	] {ai_walk(2);};
void()	hknight_walk16	=[	$walk16,	hknight_walk17	] {ai_walk(4);};
void()	hknight_walk17	=[	$walk17,	hknight_walk18	] {ai_walk(3);};
void()	hknight_walk18	=[	$walk18,	hknight_walk19	] {ai_walk(3);};
void()	hknight_walk19	=[	$walk19,	hknight_walk20	] {ai_walk(3);};
void()	hknight_walk20	=[	$walk20,	hknight_walk1	] {ai_walk(2);};

//===========================================================================

void()	hknight_run1	=[	$run1,		hknight_run2	] {
hk_idle_sound();
ai_run (20); CheckForCharge (); };
void()	hknight_run2	=[	$run2,		hknight_run3	] {ai_run(25);};
void()	hknight_run3	=[	$run3,		hknight_run4	] {ai_run(18);};
void()	hknight_run4	=[	$run4,		hknight_run5	] {ai_run(16);};
void()	hknight_run5	=[	$run5,		hknight_run6	] {ai_run(14);};
void()	hknight_run6	=[	$run6,		hknight_run7	] {ai_run(25);};
void()	hknight_run7	=[	$run7,		hknight_run8	] {ai_run(21);};
void()	hknight_run8	=[	$run8,		hknight_run1	] {ai_run(13);};

//============================================================================

void()	hknight_pain1	=[	$pain1,		hknight_pain2	] {monster_setalpha(1.00);sound (self, CHAN_VOICE, "hknight/pain1.wav", 1, ATTN_NORM);};
void()	hknight_pain2	=[	$pain2,		hknight_pain3	] {monster_setalpha(0.75);};
void()	hknight_pain3	=[	$pain3,		hknight_pain4	] {monster_setalpha(0.50);};
void()	hknight_pain4	=[	$pain4,		hknight_pain5	] {monster_setalpha(0.25);};
void()	hknight_pain5	=[	$pain5,		hknight_run1	] {monster_setalpha(0.00);};

//============================================================================

void()  hknight_die1    =[      $death1,        hknight_die2    ] {body_solid('-16 -16 -24', '16 16  32');ai_forward(10);};
void()  hknight_die2    =[      $death2,        hknight_die3    ] {body_solid('-16 -16 -24', '16 16  32');ai_forward(8);};
void()  hknight_die3    =[      $death3,        hknight_die4    ] {body_solid('-16 -16 -24', '16 16  26');ai_forward(7);};
void()  hknight_die4    =[      $death4,        hknight_die5    ] {body_solid('-16 -16 -24', '16 16  26');};
void()  hknight_die5    =[      $death5,        hknight_die6    ] {body_solid('-16 -16 -24', '16 16  24');};
void()  hknight_die6    =[      $death6,        hknight_die7    ] {body_solid('-16 -16 -24', '16 16  21');};
void()  hknight_die7    =[      $death7,        hknight_die8    ] {body_solid('-16 -16 -24', '16 16  19');};
void()  hknight_die8    =[      $death8,        hknight_die9    ] {body_solid('-16 -16 -24', '16 16  17');ai_forward(10);};
void()  hknight_die9    =[      $death9,        hknight_die10   ] {body_nonsolid('-16 -16 -24', '16 16   8');ai_forward(11);};
void()  hknight_die10   =[      $death10,       hknight_die11   ] {body_nonsolid('-16 -16 -24', '16 16  -7');};
void()  hknight_die11   =[      $death11,       hknight_die12   ] {body_nonsolid('-16 -16 -24', '16 16 -12');};
void()  hknight_die12   =[      $death12,       hknight_die12   ] {body_nonsolid('-16 -16 -24', '16 16 -12');};

void()  hknight_dieb1   =[      $deathb1,       hknight_dieb2   ] {body_solid('-16 -16 -24', '16 16  32');};
void()  hknight_dieb2   =[      $deathb2,       hknight_dieb3   ] {body_solid('-16 -16 -24', '16 16  32');};
void()  hknight_dieb3   =[      $deathb3,       hknight_dieb4   ] {body_solid('-16 -16 -24', '16 16  32');};
void()  hknight_dieb4   =[      $deathb4,       hknight_dieb5   ] {body_solid('-16 -16 -24', '16 16  22');};
void()  hknight_dieb5   =[      $deathb5,       hknight_dieb6   ] {body_nonsolid('-16 -16 -24', '16 16   4');};
void()  hknight_dieb6   =[      $deathb6,       hknight_dieb7   ] {body_nonsolid('-16 -16 -24', '16 16  -3');};
void()  hknight_dieb7   =[      $deathb7,       hknight_dieb8   ] {body_nonsolid('-16 -16 -24', '16 16 -10');};
void()  hknight_dieb8   =[      $deathb8,       hknight_dieb9   ] {body_nonsolid('-16 -16 -24', '16 16 -10');};
void()  hknight_dieb9   =[      $deathb9,       hknight_dieb9   ] {body_nonsolid('-16 -16 -24', '16 16 -13');};

void() hknight_gib =
{
	monster_setalpha(1);
	sound (self, CHAN_VOICE, "player/udeath.wav", 1, ATTN_NORM);
	MonsterGibs("progs/h_hellkn.mdl", 6, "", 0, "", 0);
};

void() hknight_die =
{
	monster_setalpha(1);
	mctf_spawnpickup(self.origin, 2, 0, 0.5, 0.2);
	sound (self, CHAN_VOICE, "hknight/death1.wav", 1, ATTN_NORM);
	if (random() > 0.5)
		MonsterCorpse(self, hknight_die1);
	else
		MonsterCorpse(self, hknight_dieb1);
};


//============================================================================

void()  hknight_magica1 =[      $magica1,       hknight_magica2 ] {hknight_infernowarning();ai_face();};
void()  hknight_magica2 =[      $magica2,       hknight_magica3 ] {hknight_infernowarning();ai_face();};
void()  hknight_magica3 =[      $magica3,       hknight_magica4 ] {hknight_infernowarning();ai_face();};
void()  hknight_magica4 =[      $magica4,       hknight_magica5 ] {hknight_infernowarning();ai_face();};
void()  hknight_magica5 =[      $magica5,       hknight_magica6 ] {hknight_infernowarning();ai_face();};
void()  hknight_magica6 =[      $magica6,       hknight_magica7 ] {hknight_infernowarning();ai_face();};
void()  hknight_magica7 =[      $magica7,       hknight_magica8 ] {hknight_infernowarning();};
void()  hknight_magica8 =[      $magica8,       hknight_magica9 ] {hknight_infernowarning();};
void()  hknight_magica9 =[      $magica9,       hknight_magica10] {monster_setalpha(0.5);hknight_infernowarning();};
void()  hknight_magica10 =[     $magica10,      hknight_magica11] {monster_setalpha(1.0);hknight_inferno();};
void()  hknight_magica11 =[     $magica11,      hknight_magica12] {monster_setalpha(0.5);};
void()  hknight_magica12 =[     $magica12,      hknight_magica13] {monster_setalpha(0.0);};
void()	hknight_magica13 =[	$magica13,	hknight_magica14] {ai_face();};
void()	hknight_magica14 =[	$magica14,	hknight_run1	] {ai_face();};

//============================================================================

void()	hknight_magicb1 =[	$magicb1,	hknight_magicb2	] {ai_face();};
void()	hknight_magicb2 =[	$magicb2,	hknight_magicb3	] {ai_face();};
void()	hknight_magicb3 =[	$magicb3,	hknight_magicb4	] {ai_face();};
void()	hknight_magicb4 =[	$magicb4,	hknight_magicb5	] {ai_face();};
void()	hknight_magicb5 =[	$magicb5,	hknight_magicb6	] {ai_face();};
void()	hknight_magicb6 =[	$magicb6,	hknight_magicb7	] {monster_setalpha(0.5);ai_face();};
void()  hknight_magicb7 =[	$magicb7,	hknight_magicb8 ] {monster_setalpha(1.0);hknight_fireball();};
void()  hknight_magicb8 =[	$magicb8,	hknight_magicb9 ] {monster_setalpha(0.5);};
void()  hknight_magicb9 =[	$magicb9,	hknight_magicb10] {monster_setalpha(0.0);};
void()  hknight_magicb10 =[	$magicb10,	hknight_magicb11] {};
void()  hknight_magicb11 =[	$magicb11,	hknight_magicb12] {};
void()  hknight_magicb12 =[	$magicb12,	hknight_magicb13] {};
void()	hknight_magicb13 =[	$magicb13,	hknight_run1] {ai_face();};

//============================================================================

void()  hknight_magicc1  =[     $magicc1,       hknight_magicc2 ] {ai_face();};
void()  hknight_magicc2  =[     $magicc2,       hknight_magicc3 ] {ai_face();};
void()  hknight_magicc3  =[     $magicc3,       hknight_magicc4 ] {ai_face();};
void()  hknight_magicc4  =[     $magicc4,       hknight_magicc5 ] {ai_face();};
void()  hknight_magicc5  =[     $magicc5,       hknight_magicc6 ] {monster_setalpha(0.5);ai_face();};
void()  hknight_magicc6  =[     $magicc6,       hknight_magicc7 ] {monster_setalpha(1.0);hknight_shot(-2);};
void()  hknight_magicc7  =[     $magicc7,       hknight_magicc8 ] {monster_setalpha(1.0);hknight_shot(-1);};
void()  hknight_magicc8  =[     $magicc8,       hknight_magicc9 ] {monster_setalpha(1.0);hknight_shot( 0);};
void()  hknight_magicc9  =[     $magicc9,       hknight_magicc10] {monster_setalpha(1.0);hknight_shot( 1);};
void()  hknight_magicc10 =[     $magicc10,      hknight_magicc11] {monster_setalpha(1.0);hknight_shot( 2);};
void()  hknight_magicc11 =[     $magicc11,      hknight_run1    ] {monster_setalpha(0.0);};

//===========================================================================

void()  hknight_char_a1 =[	$char_a1,	hknight_char_a2 ] {ai_charge(20);hknight_checkmagic();};
void()	hknight_char_a2	=[	$char_a2,	hknight_char_a3	] {ai_charge(25);};
void()	hknight_char_a3	=[	$char_a3,	hknight_char_a4	] {ai_charge(18);};
void()	hknight_char_a4	=[	$char_a4,	hknight_char_a5	] {ai_charge(16);};
void()	hknight_char_a5	=[	$char_a5,	hknight_char_a6	] {monster_setalpha(0.5);ai_charge(14);};
void()  hknight_char_a6 =[	$char_a6,	hknight_char_a7 ] {monster_setalpha(1.0);ai_charge(20);ai_melee();hknight_checkmagic();};
void()	hknight_char_a7	=[	$char_a7,	hknight_char_a8	] {monster_setalpha(1.0);ai_charge(21);ai_melee();};
void()	hknight_char_a8	=[	$char_a8,	hknight_char_a9	] {monster_setalpha(1.0);ai_charge(13);ai_melee();};
void()	hknight_char_a9	=[	$char_a9,	hknight_char_a10	] {monster_setalpha(1.0);ai_charge(20);ai_melee();};
void()	hknight_char_a10=[	$char_a10,	hknight_char_a11	] {monster_setalpha(1.0);ai_charge(20);ai_melee();};
void()  hknight_char_a11=[	$char_a11,	hknight_char_a12	] {monster_setalpha(1.0);ai_charge(18);ai_melee();hknight_checkmagic();};
void()	hknight_char_a12=[	$char_a12,	hknight_char_a13	] {monster_setalpha(0.5);ai_charge(16);};
void()	hknight_char_a13=[	$char_a13,	hknight_char_a14	] {monster_setalpha(0.0);ai_charge(14);};
void()	hknight_char_a14=[	$char_a14,	hknight_char_a15	] {ai_charge(25);};
void()	hknight_char_a15=[	$char_a15,	hknight_char_a16	] {ai_charge(21);};
void()  hknight_char_a16=[	$char_a16,	hknight_run1	] {ai_charge(13);hknight_checkmagic();};

//===========================================================================

void()	hknight_char_b1	=[	$char_b1,	hknight_char_b2	]
{monster_setalpha(1.0);CheckContinueCharge (); ai_charge(23); ai_melee();};
void()	hknight_char_b2	=[	$char_b2,	hknight_char_b3	] {monster_setalpha(1.0);ai_charge(17); ai_melee();};
void()	hknight_char_b3	=[	$char_b3,	hknight_char_b4	] {monster_setalpha(1.0);ai_charge(12); ai_melee();};
void()	hknight_char_b4	=[	$char_b4,	hknight_char_b5	] {monster_setalpha(1.0);ai_charge(22); ai_melee();};
void()	hknight_char_b5	=[	$char_b5,	hknight_char_b6	] {monster_setalpha(1.0);ai_charge(18); ai_melee();};
void()	hknight_char_b6	=[	$char_b6,	hknight_char_b1	] {monster_setalpha(0.0);ai_charge(8); ai_melee();};

//===========================================================================

void()	hknight_slice1	=[	$slice1,	hknight_slice2	] {ai_charge(9);};
void()	hknight_slice2	=[	$slice2,	hknight_slice3	] {ai_charge(6);};
void()	hknight_slice3	=[	$slice3,	hknight_slice4	] {ai_charge(13);};
void()	hknight_slice4	=[	$slice4,	hknight_slice5	] {monster_setalpha(0.5);ai_charge(4);};
void()	hknight_slice5	=[	$slice5,	hknight_slice6	] {monster_setalpha(1.0);ai_charge(7);ai_melee();};
void()	hknight_slice6	=[	$slice6,	hknight_slice7	] {monster_setalpha(1.0);ai_charge(15);ai_melee();};
void()	hknight_slice7	=[	$slice7,	hknight_slice8	] {monster_setalpha(1.0);ai_charge(8);ai_melee();};
void()	hknight_slice8	=[	$slice8,	hknight_slice9	] {monster_setalpha(1.0);ai_charge(2);ai_melee();};
void()	hknight_slice9	=[	$slice9,	hknight_slice10	] {monster_setalpha(1.0);ai_melee();};
void()	hknight_slice10	=[	$slice10,	hknight_run1	] {monster_setalpha(0.0);ai_charge(3);};

//===========================================================================

void()	hknight_smash1	=[	$smash1,	hknight_smash2	] {ai_charge(1);};
void()	hknight_smash2	=[	$smash2,	hknight_smash3	] {ai_charge(13);};
void()	hknight_smash3	=[	$smash3,	hknight_smash4	] {ai_charge(9);};
void()	hknight_smash4	=[	$smash4,	hknight_smash5	] {monster_setalpha(0.5);ai_charge(11);};
void()	hknight_smash5	=[	$smash5,	hknight_smash6	] {monster_setalpha(1.0);ai_charge(10);ai_melee();};
void()	hknight_smash6	=[	$smash6,	hknight_smash7	] {monster_setalpha(1.0);ai_charge(7);ai_melee();};
void()	hknight_smash7	=[	$smash7,	hknight_smash8	] {monster_setalpha(1.0);ai_charge(12);ai_melee();};
void()	hknight_smash8	=[	$smash8,	hknight_smash9	] {monster_setalpha(1.0);ai_charge(2);ai_melee();};
void()	hknight_smash9	=[	$smash9,	hknight_smash10	] {monster_setalpha(1.0);ai_charge(3);ai_melee();};
void()	hknight_smash10	=[	$smash10,	hknight_smash11	] {monster_setalpha(0.5);ai_charge(0);};
void()	hknight_smash11	=[	$smash11,	hknight_run1	] {monster_setalpha(0.0);ai_charge(0);};

//============================================================================

void()	hknight_watk1	=[	$w_attack1,	hknight_watk2	] {ai_charge(2);};
void()	hknight_watk2	=[	$w_attack2,	hknight_watk3	] {ai_charge(0);};
void()	hknight_watk3	=[	$w_attack3,	hknight_watk4	] {monster_setalpha(0.5);ai_charge(0);};
void()	hknight_watk4	=[	$w_attack4,	hknight_watk5	] {monster_setalpha(1.0);ai_melee();};
void()	hknight_watk5	=[	$w_attack5,	hknight_watk6	] {monster_setalpha(1.0);ai_melee();};
void()	hknight_watk6	=[	$w_attack6,	hknight_watk7	] {monster_setalpha(1.0);ai_melee();};
void()	hknight_watk7	=[	$w_attack7,	hknight_watk8	] {monster_setalpha(0.5);ai_charge(1);};
void()	hknight_watk8	=[	$w_attack8,	hknight_watk9	] {monster_setalpha(0.0);ai_charge(4);};
void()	hknight_watk9	=[	$w_attack9,	hknight_watk10	] {monster_setalpha(0.5);ai_charge(5);};
void()	hknight_watk10	=[	$w_attack10,	hknight_watk11	] {monster_setalpha(1.0);ai_charge(3); ai_melee();};
void()	hknight_watk11	=[	$w_attack11,	hknight_watk12	] {monster_setalpha(1.0);ai_charge(2); ai_melee();};
void()	hknight_watk12	=[	$w_attack12,	hknight_watk13	] {monster_setalpha(1.0);ai_charge(2); ai_melee();};
void()	hknight_watk13	=[	$w_attack13,	hknight_watk14	] {monster_setalpha(0.5);ai_charge(0);};
void()	hknight_watk14	=[	$w_attack14,	hknight_watk15	] {monster_setalpha(0.0);ai_charge(0);};
void()	hknight_watk15	=[	$w_attack15,	hknight_watk16	] {ai_charge(0);};
void()	hknight_watk16	=[	$w_attack16,	hknight_watk17	] {monster_setalpha(0.5);ai_charge(1);};
void()	hknight_watk17	=[	$w_attack17,	hknight_watk18	] {monster_setalpha(1.0);ai_charge(1); ai_melee();};
void()	hknight_watk18	=[	$w_attack18,	hknight_watk19	] {monster_setalpha(1.0);ai_charge(3); ai_melee();};
void()	hknight_watk19	=[	$w_attack19,	hknight_watk20	] {monster_setalpha(1.0);ai_charge(4); ai_melee();};
void()	hknight_watk20	=[	$w_attack20,	hknight_watk21	] {monster_setalpha(0.5);ai_charge(6);};
void()	hknight_watk21	=[	$w_attack21,	hknight_watk22	] {monster_setalpha(0.0);ai_charge(7);};
void()	hknight_watk22	=[	$w_attack22,	hknight_run1	] {ai_charge(3);};

//============================================================================

void() hk_idle_sound =
{
	if (random() < 0.2)
		sound (self, CHAN_VOICE, "hknight/idle.wav", 1, ATTN_NORM);
};

void(entity attacker, float damage)	hknight_pain =
{
	if (self.pain_finished > time)
		return;

	sound (self, CHAN_VOICE, "hknight/pain1.wav", 1, ATTN_NORM);

	if (time - self.pain_finished > 5)
	{	// allways go into pain frame if it has been a while
		hknight_pain1 ();
		self.pain_finished = time + 1;
		return;
	}

	if ((random()*30 > damage) )
		return;		// didn't flinch

	self.pain_finished = time + 1;
	hknight_pain1 ();
};

float	hknight_type;

void() hknight_melee =
{
	hknight_type = hknight_type + 1;

	sound (self, CHAN_WEAPON, "hknight/slash1.wav", 1, ATTN_NORM);
	if (hknight_type == 1)
		hknight_slice1 ();
	else if (hknight_type == 2)
		hknight_smash1 ();
        else
	{
		hknight_watk1 ();
		hknight_type = 0;
	}
};

float   hknight_mtype;

float() hknight_missile =
{
	local float old;

	if (!(self.flags & FL_ONGROUND))
		return FALSE;

	if (self.enemy.classname == "monster_zombie")
	{
		// always use fireball to kill zombies
		traceline((self.absmin + self.absmax) * 0.5, (self.enemy.absmin + self.enemy.absmax) * 0.5, FALSE, self);
		if (trace_ent == self.enemy)
		{
			hknight_magicb1();
			return TRUE;
		}
		return FALSE;
	}
	old = hknight_mtype;
	hknight_mtype = hknight_mtype + 1;
	if (hknight_mtype > 3)
		hknight_mtype = 0;
	while(hknight_mtype != old)
	{
		if (hknight_mtype == 0) // fireball
		{
			hknight_mtype = 1;
			traceline((self.absmin + self.absmax) * 0.5, (self.enemy.absmin + self.enemy.absmax) * 0.5, FALSE, self);
			if (trace_ent == self.enemy)
			{
				hknight_magicb1();
				return TRUE;
			}
		}
		else // fireball spray
		{
			hknight_mtype = 0; // wrap counter
			if (pointcontents(self.origin) == CONTENT_EMPTY) // in air
			if (pointcontents(self.enemy.origin) == CONTENT_EMPTY) // in air
			{
				traceline((self.absmin + self.absmax) * 0.5, (self.enemy.absmin + self.enemy.absmax) * 0.5, FALSE, self);
				if (trace_ent == self.enemy)
				{
					hknight_magicc1();
					return TRUE;
				}
			}
		}
/*
		if (hknight_mtype == 0) // inferno
		{
			hknight_mtype = 1;
//			if (self.flame.cnt <= 0) // not already burning
//			if (self.flamecount <= 0) // not already burning
			if (pointcontents(self.origin) == CONTENT_EMPTY) // in air
			if (pointcontents(self.enemy.origin) == CONTENT_EMPTY) // in air
			{
				hknight_magica1();
				return TRUE;
			}
		}
		else if (hknight_mtype == 1) // fireball
		{
			hknight_mtype = 2;
			traceline((self.absmin + self.absmax) * 0.5, (self.enemy.absmin + self.enemy.absmax) * 0.5, FALSE, self);
			if (trace_ent == self.enemy)
			{
				hknight_magicb1();
				return TRUE;
			}
		}
		else if (hknight_mtype == 2) // jump
		{
			hknight_mtype = 3;
			if (self.health >= 100)
			if (vlen(self.enemy.origin - self.origin) >= 400)
			if (findtrajectorywithleading(self.origin, self.mins, self.maxs, self.enemy, 1000, 10, 0, self))
			{
				self.velocity = findtrajectory_velocity;
				T_Damage(self, self, self, 25, 25, "JUMP", DT_FALL, self.origin, '0 0 0', Obituary_Generic);
				return TRUE;
			}
		}
		else // fireball spray
		{
			hknight_mtype = 0; // wrap counter
			if (pointcontents(self.origin) == CONTENT_EMPTY) // in air
			if (pointcontents(self.enemy.origin) == CONTENT_EMPTY) // in air
			{
				traceline((self.absmin + self.absmax) * 0.5, (self.enemy.absmin + self.enemy.absmax) * 0.5, FALSE, self);
				if (trace_ent == self.enemy)
				{
					hknight_magicc1();
					return TRUE;
				}
			}
		}
*/
	}
	return FALSE;
};

void() hknight_sightsound =
{
	sound (self, CHAN_VOICE, "hknight/sight1.wav", 1, ATTN_NORM);
};

/* not necessary since I implemented generic resistances
float(entity e, float healthdamage, float damage, float damgtype, string dethtype) hellknight_damagemodifier =
{
	if (damgtype == DT_FIRE)
		return 0; // totally fire resistant
	return 1;
};
*/

void() precachemonster_hell_knight =
{
	precache_model2 ("progs/hknight.mdl");
	precache_model2 ("progs/k_spike.mdl");
	precache_model2 ("progs/h_hellkn.mdl");

	precache_sound2 ("hknight/attack1.wav");
	precache_sound2 ("hknight/death1.wav");
	precache_sound2 ("hknight/pain1.wav");
	precache_sound2 ("hknight/sight1.wav");
	precache_sound ("hknight/hit.wav");		// used by C code, so don't sound2
	precache_sound2 ("hknight/slash1.wav");
	precache_sound2 ("hknight/idle.wav");
	precache_sound2 ("hknight/grunt.wav");

	precache_sound ("knight/sword1.wav");
	precache_sound ("knight/sword2.wav");
	precache_model("progs/lavaball.mdl");
};

/*QUAKED monster_hell_knight (1 0 0) (-16 -16 -24) (16 16 32) Ambush
*/
void() monster_hell_knight =
{
	if (deathmatch)
	if (!monsterspawn)
	{
		remove(self);
		return;
	}
	if (!self.deathtype) // map makers can override this
		self.deathtype = " was slain by a Hell-Knight";

	self.shoulddodge = TRUE;
	self.dangerrating = 40;

	// localdamage stuff (headshots etc)
	/*
	self.localdamage = TRUE;
	self.localdamage_head_z1 = 20;
	self.localdamage_head_z2 = 1032;
	self.localdamage_head_mul = 1.5; // heavy armor
	self.localdamage_body_z1 = -1024;
	self.localdamage_body_z2 = 24;
	self.localdamage_body_mul = 1.0;
	self.localdamage_hit = LD_NORMAL;
	*/

	if (!monsterspawn)
		precachemonster_hell_knight();

	self.forcescale = 4;
	self.netname = "a Hell-Knight";
	// self.doobits = 1;
	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_STEP;

	setmodel (self, "progs/hknight.mdl");

	setsize (self, '-16 -16 -24', '16 16 32');
	if (!self.health)
		self.health = MH_HELLKNIGHT;
	self.health = self.health;
	self.bodyhealth = self.health + MB_HELLKNIGHT;
	self.bleedratio = 0.25; // not much health damage due to armor
	// fire immunity
	self.resist_fire = -1;
	// not necessary since I implemented generic resistances
	//	self.damagemodifier = hellknight_damagemodifier;

	self.th_stand = hknight_stand1;
	self.th_walk = hknight_walk1;
	self.th_run = hknight_run1;
	self.th_checkattack = HellKnightCheckAttack;
	self.th_melee = hknight_melee;
	self.th_missile = hknight_missile;
	self.th_pain = hknight_pain;
	self.th_die = hknight_die;
	self.th_gib = hknight_gib;
	self.th_sightsound = hknight_sightsound;

	walkmonster_start ();
	//self.radsuit_finished = 9999999; // that suit ain't just for looks
	self.candrown = FALSE;
};

/*QUAKED dead_hell_knight (1 0 0) (-16 -16 -24) (16 16 -12)
*/
void() dead_hell_knight =
{
	if (random() < 0.5)
		deadmonstersetup("progs/hknight.mdl", "progs/h_hellkn.mdl", hknight_die12, 6, 2.5, MB_HELLKNIGHT);
	else
		deadmonstersetup("progs/hknight.mdl", "progs/h_hellkn.mdl", hknight_dieb9, 6, 2.5, MB_HELLKNIGHT);
};

