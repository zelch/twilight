/*
==============================================================================

SOLDIER / PLAYER

==============================================================================
*/

$cd id1/models/soldier3
$origin 0 -6 24
$base base
$skin skin

$frame stand1 stand2 stand3 stand4 stand5 stand6 stand7 stand8

$frame death1 death2 death3 death4 death5 death6 death7 death8
$frame death9 death10

$frame deathc1 deathc2 deathc3 deathc4 deathc5 deathc6 deathc7 deathc8
$frame deathc9 deathc10 deathc11

$frame load1 load2 load3 load4 load5 load6 load7 load8 load9 load10 load11

$frame pain1 pain2 pain3 pain4 pain5 pain6

$frame painb1 painb2 painb3 painb4 painb5 painb6 painb7 painb8 painb9 painb10
$frame painb11 painb12 painb13 painb14

$frame painc1 painc2 painc3 painc4 painc5 painc6 painc7 painc8 painc9 painc10
$frame painc11 painc12 painc13

$frame run1 run2 run3 run4 run5 run6 run7 run8

$frame shoot1 shoot2 shoot3 shoot4 shoot5 shoot6 shoot7 shoot8 shoot9

$frame prowl_1 prowl_2 prowl_3 prowl_4 prowl_5 prowl_6 prowl_7 prowl_8
$frame prowl_9 prowl_10 prowl_11 prowl_12 prowl_13 prowl_14 prowl_15 prowl_16
$frame prowl_17 prowl_18 prowl_19 prowl_20 prowl_21 prowl_22 prowl_23 prowl_24

/*
==============================================================================
SOLDIER CODE
==============================================================================
*/
void() army_stand1 =[$stand1 , army_stand2] {ai_stand();};
void() army_stand2 =[$stand2 , army_stand3] {ai_stand();};
void() army_stand3 =[$stand3 , army_stand4] {ai_stand();};
void() army_stand4 =[$stand4 , army_stand5] {ai_stand();};
void() army_stand5 =[$stand5 , army_stand6] {ai_stand();};
void() army_stand6 =[$stand6 , army_stand7] {ai_stand();};
void() army_stand7 =[$stand7 , army_stand8] {ai_stand();};
void() army_stand8 =[$stand8 , army_stand1] {ai_stand();};

void() army_walk1  =[$prowl_1 , army_walk2 ] {
if (random() < 0.2)
	sound (self, CHAN_VOICE, "soldier/idle.wav", 1, ATTN_IDLE);
ai_walk(1);};
void() army_walk2  =[$prowl_2 , army_walk3 ] {ai_walk(1);};
void() army_walk3  =[$prowl_3 , army_walk4 ] {ai_walk(1);};
void() army_walk4  =[$prowl_4 , army_walk5 ] {ai_walk(1);};
void() army_walk5  =[$prowl_5 , army_walk6 ] {ai_walk(2);};
void() army_walk6  =[$prowl_6 , army_walk7 ] {ai_walk(3);};
void() army_walk7  =[$prowl_7 , army_walk8 ] {ai_walk(4);};
void() army_walk8  =[$prowl_8 , army_walk9 ] {ai_walk(4);};
void() army_walk9  =[$prowl_9 , army_walk10] {ai_walk(2);};
void() army_walk10 =[$prowl_10, army_walk11] {ai_walk(2);};
void() army_walk11 =[$prowl_11, army_walk12] {ai_walk(2);};
void() army_walk12 =[$prowl_12, army_walk13] {ai_walk(1);};
void() army_walk13 =[$prowl_13, army_walk14] {ai_walk(0);};
void() army_walk14 =[$prowl_14, army_walk15] {ai_walk(1);};
void() army_walk15 =[$prowl_15, army_walk16] {ai_walk(1);};
void() army_walk16 =[$prowl_16, army_walk17] {ai_walk(1);};
void() army_walk17 =[$prowl_17, army_walk18] {ai_walk(3);};
void() army_walk18 =[$prowl_18, army_walk19] {ai_walk(3);};
void() army_walk19 =[$prowl_19, army_walk20] {ai_walk(3);};
void() army_walk20 =[$prowl_20, army_walk21] {ai_walk(3);};
void() army_walk21 =[$prowl_21, army_walk22] {ai_walk(2);};
void() army_walk22 =[$prowl_22, army_walk23] {ai_walk(1);};
void() army_walk23 =[$prowl_23, army_walk24] {ai_walk(1);};
void() army_walk24 =[$prowl_24, army_walk1 ] {ai_walk(1);};

void() army_run1 =[$run1, army_run2] {ai_run(11);if (random() < 0.2) sound (self, CHAN_VOICE, "soldier/idle.wav", 1, ATTN_IDLE);};
void() army_run2 =[$run2, army_run3] {ai_run(15);};
void() army_run3 =[$run3, army_run4] {ai_run(10);};
void() army_run4 =[$run4, army_run5] {ai_run(10);};
void() army_run5 =[$run5, army_run6] {ai_run(8);};
void() army_run6 =[$run6, army_run7] {ai_run(15);};
void() army_run7 =[$run7, army_run8] {ai_run(10);};
void() army_run8 =[$run8, army_run1] {ai_run(8);};

//=============================================================================

/*
===========
SoldierCheckAttack

The player is in view, so decide to move or launch an attack
Returns FALSE if movement should continue
============
*/
float() SoldierCheckAttack =
{
	local vector spot1, spot2;
	local entity targ;
	local float chance;

	if (self.health < 1)
		return FALSE;
	targ = self.enemy;

	// see if any entities are in the way of the shot
	spot1 = self.origin + self.view_ofs;
	spot2 = targ.origin + targ.view_ofs;

	traceline (spot1, spot2, FALSE, self);

	if (trace_ent != targ)
		return FALSE; // don't have a clear shot

	if (trace_inwater)
	if (trace_inopen)
		return FALSE; // sight line crossed contents

	// missile attack
	if (time < self.attack_finished)
		return FALSE;

	if (enemy_range == RANGE_FAR)
		return FALSE;

	if (enemy_range == RANGE_MELEE)
		chance = 0.9;
	else if (enemy_range == RANGE_NEAR)
		chance = 0.6; // was 0.4
	else if (enemy_range == RANGE_MID)
		chance = 0.3; // was 0.05
	else
		chance = 0;

	if (chance > 0)
	if (chance > random())
		return FALSE;

	if (self.th_missile())
	{
		SUB_AttackFinished (1 + random());
		return TRUE;
	}
	return FALSE;
};

void(vector hit) army_pistol =
{
	local vector ang;
	shotorg = self.origin + '0 0 12';
	shotdir = normalize (hit - shotorg);
	shotdir = shotdir * 35 + randomvec();
	shotdir = normalize(shotdir);
	ang = vectoangles(shotdir);

	sound (self, CHAN_WEAPON, "weapons/rocket1i.wav", 1, ATTN_NORM);
	w_muzzleflash (shotorg, 1);
	//ejectcasing (shotorg, '0 0 0', 50, ang, '0 0 0', 150, 0);
	FireBullets (self, self, 4, 1, DMG_SOLDIER_PISTOL_DAMAGE, DMG_SOLDIER_PISTOL_BDAMAGE, 0, 0, shotdir * 6000, 0.025, self.deathtype, DT_NAIL, Obituary_Generic);
};

void() army_pistol1 =[$shoot1, army_pistol2] {ai_face();self.dest = monster_shotleadbullet(0.4);};
void() army_pistol2 =[$shoot2, army_pistol3] {ai_face();};
void() army_pistol3 =[$shoot3, army_pistol4] {ai_face();};
void() army_pistol4 =[$shoot4, army_pistol5] {ai_face();monster_setalpha(0.5);};
void() army_pistol5 =[$shoot5, army_pistol6] {ai_face();monster_setalpha(1.0);army_pistol(self.dest);};
void() army_pistol6 =[$shoot6, army_pistol7] {ai_face();monster_setalpha(0.5);};
void() army_pistol7 =[$shoot7, army_pistol8] {ai_face();monster_setalpha(0.0);SUB_CheckRefire (army_pistol1);};
void() army_pistol8 =[$shoot8, army_pistol9] {ai_face();};
void() army_pistol9 =[$shoot9, army_run1   ] {ai_face();};

float() army_missile_pistol =
{
	// FIXME: check if it would hit
	army_pistol1();
	return TRUE;
};

void(vector hit) army_nail =
{
	local vector ang;
	shotorg = self.origin + '0 0 12';
	shotdir = normalize (hit - shotorg);
	shotdir = shotdir * 35 + randomvec();
	shotdir = normalize(shotdir);
	ang = vectoangles(shotdir);

	sound (self, CHAN_WEAPON, "weapons/rocket1i.wav", 1, ATTN_NORM);
	w_muzzleflash (shotorg, 1);
	//ejectcasing (shotorg, '0 0 0', 50, ang, '0 0 0', 150, 0);
	FireBullets (self, self, 4, 1, DMG_SOLDIER_MACHINEGUN_DAMAGE, DMG_SOLDIER_MACHINEGUN_BDAMAGE, 0, 0, shotdir * 5000, 0.05, self.deathtype, DT_NAIL, Obituary_Generic);
};

void() army_nail1  =[$shoot1, army_nail2 ] {ai_face();self.dest1 = monster_shotleadbullet(0.4);};
void() army_nail2  =[$shoot2, army_nail3 ] {ai_face();self.dest2 = monster_shotleadbullet(0.4);};
void() army_nail3  =[$shoot3, army_nail4 ] {ai_face();self.dest3 = monster_shotleadbullet(0.4);};
void() army_nail4  =[$shoot4, army_nail5 ] {ai_face();monster_setalpha(0.5);self.dest4 = monster_shotleadbullet(0.4);};
void() army_nail5  =[$shoot5, army_nail6 ] {ai_face();monster_setalpha(1.0);army_nail(self.dest1);};
void() army_nail6  =[$shoot5, army_nail7 ] {ai_face();monster_setalpha(1.0);army_nail(self.dest2);};
void() army_nail7  =[$shoot5, army_nail8 ] {ai_face();monster_setalpha(1.0);army_nail(self.dest3);};
void() army_nail8  =[$shoot5, army_nail9 ] {ai_face();monster_setalpha(1.0);army_nail(self.dest4);};
void() army_nail9  =[$shoot6, army_nail10] {ai_face();monster_setalpha(0.5);};
void() army_nail10 =[$shoot7, army_nail11] {ai_face();monster_setalpha(0.0);SUB_CheckRefire (army_nail1);};
void() army_nail11 =[$shoot8, army_nail12] {ai_face();};
void() army_nail12 =[$shoot9, army_run1  ] {ai_face();};

float() army_missile_nail =
{
	// FIXME: check if it would hit
	army_nail1();
	return TRUE;
};

void(vector hit) army_shotgun =
{
	local vector ang;
	shotorg = self.origin + '0 0 12';
	shotdir = normalize (hit - shotorg);
	shotdir = shotdir * 35 + randomvec();
	shotdir = normalize(shotdir);
	ang = vectoangles(shotdir);

	sound (self, CHAN_WEAPON, "weapons/shotgn2.wav", 1, ATTN_NORM);
	w_muzzleflash (shotorg, 2);
	ejectcasing (shotorg, '0 0 0', 50, ang, '0 0 0', 150, 1);
	FireBullets (self, self, 1, DMG_SOLDIER_SHOTGUN_PELLETS, DMG_SOLDIER_SHOTGUN_DAMAGE, DMG_SOLDIER_SHOTGUN_BDAMAGE, 0, 0, shotdir * 4000, 0.1, self.deathtype, DT_SHOTGUN, Obituary_Generic);
	self.currentammo = self.currentammo - 1;
};

void() army_shotload1;

void() army_shotgun1   =[$shoot1, army_shotgun2  ] {ai_face();self.dest = monster_shotleadbullet(0.4);};
void() army_shotgun2   =[$shoot2, army_shotgun3  ] {ai_face();};
void() army_shotgun3   =[$shoot3, army_shotgun4  ] {ai_face();};
void() army_shotgun4   =[$shoot4, army_shotgun5  ] {ai_face();monster_setalpha(0.5);};
void() army_shotgun5   =[$shoot5, army_shotgun6  ] {ai_face();monster_setalpha(1.0);army_shotgun(self.dest);};
void() army_shotgun6   =[$shoot6, army_shotgun7  ] {ai_face();monster_setalpha(0.5);};
void() army_shotgun7   =[$shoot7, army_shotgun8  ] {ai_face();monster_setalpha(0.0);SUB_CheckRefire (army_shotgun1);};
void() army_shotgun8   =[$shoot8, army_shotgun9  ] {ai_face();};
void() army_shotgun9   =[$shoot9, army_run1      ] {ai_face();if (self.currentammo < 1){self.think = army_shotload1;}};
void() army_shotload1  =[$load1 , army_shotload2 ] {ai_face();};
void() army_shotload2  =[$load2 , army_shotload3 ] {ai_face();};
void() army_shotload3  =[$load3 , army_shotload4 ] {ai_face();};
void() army_shotload4  =[$load4 , army_shotload5 ] {ai_face();};
void() army_shotload5  =[$load5 , army_shotload6 ] {ai_face();};
void() army_shotload6  =[$load6 , army_shotload7 ] {ai_face();};
void() army_shotload7  =[$load7 , army_shotload8 ] {ai_face();};
void() army_shotload8  =[$load8 , army_shotload9 ] {ai_face();};
void() army_shotload9  =[$load9 , army_shotload10] {ai_face();sound (self, CHAN_WEAPON, "weapons/bsgload.wav", 1, ATTN_NORM);};
void() army_shotload10 =[$load10, army_shotload11] {ai_face();};
void() army_shotload11 =[$load11, army_run1      ] {ai_face();self.currentammo = 10;};

float() army_missile_shotgun =
{
	// FIXME: check if it would hit
	army_shotgun1();
	return TRUE;
};

/*
void(vector hit) army_rocket =
{
	local vector dir;

	dir = normalize (hit - (self.origin + '0 0 12'));
	dir = dir * 35 + randomvec();
	dir = normalize(dir);

	sound (self, CHAN_WEAPON, "weapons/sgun1.wav", 1, ATTN_NORM);
	LaunchMissile(self.origin + '0 0 12', dir, self, DMG_SOLDIER_ROCKET_DAMAGE, DMG_SOLDIER_ROCKET_FORCE, DMG_SOLDIER_ROCKET_RADIUS, self.deathtype, Obituary_Generic);
};

void() army_rocket1    =[$shoot1, army_rocket2   ] {ai_face();self.dest = monster_shotlead(0.4, 1000);};
void() army_rocket2    =[$shoot2, army_rocket3   ] {ai_face();};
void() army_rocket3    =[$shoot3, army_rocket4   ] {ai_face();};
void() army_rocket4    =[$shoot4, army_rocket5   ] {ai_face();monster_setalpha(0.5);};
void() army_rocket5    =[$shoot5, army_rocket6   ] {ai_face();monster_setalpha(1.0);army_rocket(self.dest);};
void() army_rocket6    =[$shoot6, army_rocket7   ] {ai_face();monster_setalpha(0.5);};
void() army_rocket7    =[$shoot7, army_rocket8   ] {ai_face();monster_setalpha(0.0);SUB_CheckRefire (army_rocket1);};
void() army_rocket8    =[$shoot8, army_rocket9   ] {ai_face();};
void() army_rocket9    =[$shoot9, army_rockload1 ] {ai_face();};
void() army_rockload1  =[$load1 , army_rockload2 ] {ai_face();};
void() army_rockload2  =[$load2 , army_rockload3 ] {ai_face();};
void() army_rockload3  =[$load3 , army_rockload4 ] {ai_face();};
void() army_rockload4  =[$load4 , army_rockload5 ] {ai_face();};
void() army_rockload5  =[$load5 , army_rockload6 ] {ai_face();};
void() army_rockload6  =[$load6 , army_rockload7 ] {ai_face();};
void() army_rockload7  =[$load7 , army_rockload8 ] {ai_face();};
void() army_rockload8  =[$load8 , army_rockload9 ] {ai_face();};
void() army_rockload9  =[$load9 , army_rockload10] {ai_face();};
void() army_rockload10 =[$load10, army_rockload11] {ai_face();};
void() army_rockload11 =[$load11, army_run1      ] {ai_face();};

// out of ammo, so just bash the guy
// hacked up by Lord Havoc, using some shooting frames
// as the grunts NEED a melee attack when out of ammo
void() army_bash1 = [$shoot4, army_bash2] {ai_face();monster_setalpha(1.0);ai_charge(4);ai_charge(4);ai_charge(4);ai_melee();ai_melee();};
void() army_bash2 = [$shoot4, army_bash3] {ai_face();monster_setalpha(0.5);};
void() army_bash3 = [$shoot3, army_bash4] {ai_face();monster_setalpha(0.0);};
void() army_bash4 = [$shoot2, army_bash5] {ai_face();};
void() army_bash5 = [$shoot1, army_run1 ] {ai_face();};
*/

void() army_pain1 = [$pain1, army_pain2] {monster_setalpha(1.00);};
void() army_pain2 = [$pain2, army_pain3] {monster_setalpha(0.75);};
void() army_pain3 = [$pain3, army_pain4] {monster_setalpha(0.50);};
void() army_pain4 = [$pain4, army_pain5] {monster_setalpha(0.25);};
void() army_pain5 = [$pain5, army_pain6] {monster_setalpha(0.00);};
void() army_pain6 = [$pain6, army_run1 ] {ai_pain(1);};

void() army_painb1  = [$painb1 , army_painb2 ] {monster_setalpha(1.00);};
void() army_painb2  = [$painb2 , army_painb3 ] {monster_setalpha(0.75);ai_painforward(13);};
void() army_painb3  = [$painb3 , army_painb4 ] {monster_setalpha(0.50);ai_painforward(9);};
void() army_painb4  = [$painb4 , army_painb5 ] {monster_setalpha(0.25);};
void() army_painb5  = [$painb5 , army_painb6 ] {monster_setalpha(0.00);};
void() army_painb6  = [$painb6 , army_painb7 ] {};
void() army_painb7  = [$painb7 , army_painb8 ] {};
void() army_painb8  = [$painb8 , army_painb9 ] {};
void() army_painb9  = [$painb9 , army_painb10] {};
void() army_painb10 = [$painb10, army_painb11] {};
void() army_painb11 = [$painb11, army_painb12] {};
void() army_painb12 = [$painb12, army_painb13] {ai_pain(2);};
void() army_painb13 = [$painb13, army_painb14] {};
void() army_painb14 = [$painb14, army_run1   ] {};

void() army_painc1  = [$painc1 , army_painc2 ] {monster_setalpha(1.00);};
void() army_painc2  = [$painc2 , army_painc3 ] {monster_setalpha(0.75);ai_pain(1);};
void() army_painc3  = [$painc3 , army_painc4 ] {monster_setalpha(0.50);};
void() army_painc4  = [$painc4 , army_painc5 ] {monster_setalpha(0.25);};
void() army_painc5  = [$painc5 , army_painc6 ] {monster_setalpha(0.00);ai_painforward(1);};
void() army_painc6  = [$painc6 , army_painc7 ] {ai_painforward(1);};
void() army_painc7  = [$painc7 , army_painc8 ] {};
void() army_painc8  = [$painc8 , army_painc9 ] {ai_pain(1);};
void() army_painc9  = [$painc9 , army_painc10] {ai_painforward(4);};
void() army_painc10 = [$painc10, army_painc11] {ai_painforward(3);};
void() army_painc11 = [$painc11, army_painc12] {ai_painforward(6);};
void() army_painc12 = [$painc12, army_painc13] {ai_painforward(8);};
void() army_painc13 = [$painc13, army_run1   ] {};

void(entity attacker, float damage, float damgtype, string dethtype) army_pain =
{
	local float r;

	if (self.pain_finished > time || random() < 0.75)
		return;

	r = random();

	if (r < 0.2)
	{
		self.pain_finished = time + 0.6;
		army_pain1 ();
		sound (self, CHAN_VOICE, "soldier/pain1.wav", 1, ATTN_NORM);
	}
	else if (r < 0.6)
	{
		self.pain_finished = time + 1.1;
		army_painb1 ();
		sound (self, CHAN_VOICE, "soldier/pain2.wav", 1, ATTN_NORM);
	}
	else
	{
		self.pain_finished = time + 1.1;
		army_painc1 ();
		sound (self, CHAN_VOICE, "soldier/pain2.wav", 1, ATTN_NORM);
	}
};

void() army_die1  = [$death1 , army_die2 ] {body_solid('-16 -16 -24', '16 16 32');};
void() army_die2  = [$death2 , army_die3 ] {body_solid('-16 -16 -24', '16 16 29');};
void() army_die3  = [$death3 , army_die4 ] {body_solid('-16 -16 -24', '16 16 29');};
void() army_die4  = [$death4 , army_die5 ] {body_solid('-16 -16 -24', '16 16 23');};
void() army_die5  = [$death5 , army_die6 ] {body_nonsolid('-16 -16 -24', '16 16 10');};
void() army_die6  = [$death6 , army_die7 ] {body_nonsolid('-16 -16 -24', '16 16 2');};
void() army_die7  = [$death7 , army_die8 ] {body_nonsolid('-16 -16 -24', '16 16 -1');};
void() army_die8  = [$death8 , army_die9 ] {body_nonsolid('-16 -16 -24', '16 16 -5');};
void() army_die9  = [$death9 , army_die10] {body_nonsolid('-16 -16 -24', '16 16 -12');};
void() army_die10 = [$death10, army_die10] {body_nonsolid('-16 -16 -24', '16 16 -13');};

void() army_cdie1  = [$deathc1 , army_cdie2 ] {body_solid('-16 -16 -24', '16 16 32');};
void() army_cdie2  = [$deathc2 , army_cdie3 ] {body_solid('-16 -16 -24', '16 16 30');ai_back(5);};
void() army_cdie3  = [$deathc3 , army_cdie4 ] {body_solid('-16 -16 -24', '16 16 26');ai_back(4);};
void() army_cdie4  = [$deathc4 , army_cdie5 ] {body_solid('-16 -16 -24', '16 16 23');ai_back(13);};
void() army_cdie5  = [$deathc5 , army_cdie6 ] {body_nonsolid('-16 -16 -24', '16 16 12');ai_back(3);};
void() army_cdie6  = [$deathc6 , army_cdie7 ] {body_nonsolid('-16 -16 -24', '16 16 9');ai_back(4);};
void() army_cdie7  = [$deathc7 , army_cdie8 ] {body_nonsolid('-16 -16 -24', '16 16 -3');};
void() army_cdie8  = [$deathc8 , army_cdie9 ] {body_nonsolid('-16 -16 -24', '16 16 -9');};
void() army_cdie9  = [$deathc9 , army_cdie10] {body_nonsolid('-16 -16 -24', '16 16 -11');};
void() army_cdie10 = [$deathc10, army_cdie11] {body_nonsolid('-16 -16 -24', '16 16 -12');};
void() army_cdie11 = [$deathc11, army_cdie11] {body_nonsolid('-16 -16 -24', '16 16 -13');};

void() army_gib =
{
	monster_setalpha(1);
	sound (self, CHAN_VOICE, "player/udeath.wav", 1, ATTN_NORM);
	MonsterGibs("progs/h_guard.mdl", 6, "", 0, "", 0);
};

void() army_die =
{
	monster_setalpha(1);
	DropBackpack();
	sound (self, CHAN_VOICE, "soldier/death1.wav", 1, ATTN_NORM);
	if (random() < 0.5)
		MonsterCorpse(self, army_die1);
	else
		MonsterCorpse(self, army_cdie1);
};

void() soldier_sightsound =
{
	sound (self, CHAN_VOICE, "soldier/sight1.wav", 1, ATTN_NORM);
};

void() precachemonster_army =
{
	precache_model ("progs/soldier.mdl");
	precache_model ("progs/h_guard.mdl");
	precache_model ("progs/gib1.mdl");
	precache_model ("progs/gib2.mdl");
	precache_model ("progs/gib3.mdl");

	precache_sound ("soldier/death1.wav");
	precache_sound ("soldier/idle.wav");
	precache_sound ("soldier/pain1.wav");
	precache_sound ("soldier/pain2.wav");
	precache_sound ("soldier/sattck1.wav");
	precache_sound ("soldier/sight1.wav");

	precache_sound ("weapons/rocket1i.wav");
	precache_sound ("weapons/shotgn2.wav");
	precache_sound ("weapons/sgun1.wav");

	precache_sound ("player/udeath.wav");		// gib death

	precache_sound ("weapons/bsgload.wav");
};

/*QUAKED monster_army (1 0 0) (-16 -16 -24) (16 16 32) ambush x x x x x x appear
Grunt, normally 100 health.

Flags:
"ambush"
 the monster will only wake up on
 really seeing the player, not another
 monster getting angry
"appear"
 the monster is invisible until triggered
 (basically, teleport in)

Keys:
"deathtype"
 death message.
 default: " lays down for a Grunt"
"health"
 default: 30
*/
void() monster_army =
{
	local float r;
	if (deathmatch)
	if (!monsterspawn)
	{
		remove(self);
		return;
	}

	if (!monsterspawn)
		precachemonster_army();

	self.forcescale = 6;
	self.netname = "a grunt";
	// self.doobits = 1;

	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_STEP;

	setmodel (self, "progs/soldier.mdl");

	setsize (self, '-16 -16 -24', '16 16 32');
	if (self.health < 1)
		self.health = MH_GRUNT;
	self.health = self.health;
	self.bodyhealth = self.health + MB_GRUNT;
	self.bleedratio = 0.75; // hardwired zombie, bleeding means less
	self.currentammo = 10;

	r = random();
	if (r < 0.30)
	{
		self.th_missile = army_missile_nail;
		Inventory_SetQuantity(self, "nails", AMMO_GRUNT_NAILGUN);
		Inventory_SetQuantity(self, "nailgun", 1);
		if (!self.deathtype) // map makers can override this
			self.deathtype = " was nailed by a grunt";
	}
	else if (r < 0.70)
	{
		self.th_missile = army_missile_shotgun;
		Inventory_SetQuantity(self, "shells", AMMO_GRUNT_SHOTGUN);
		Inventory_SetQuantity(self, "shotgun", 1);
		if (!self.deathtype) // map makers can override this
			self.deathtype = " was gunned down by a grunt";
	}
	else
	{
		self.items = 0;
		self.th_missile = army_missile_pistol;
		Inventory_SetQuantity(self, "nails", AMMO_GRUNT_PISTOL);
		Inventory_SetQuantity(self, "pistol", 1);
		if (!self.deathtype) // map makers can override this
			self.deathtype = " lays down for a grunt";
	}
	/*
	r = random();
	if (r < 0.20)
	{
		self.armorvalue = 100;
		self.armortype = 0.8;
	}
	else if (r < 0.40)
	{
		self.armorvalue = 60;
		self.armortype = 0.6;
	}
	else if (r < 0.70)
	{
		self.armorvalue = 25;
		self.armortype = 0.6;
	}
	*/

	self.th_stand = army_stand1;
	self.th_walk = army_walk1;
	self.th_run = army_run1;
	self.th_checkattack = SoldierCheckAttack;
	self.th_pain = army_pain;
	self.th_die = army_die;
	self.th_gib = army_gib;
	self.th_sightsound = soldier_sightsound;

	walkmonster_start ();
};

/*QUAKED dead_army (1 0 0) (-16 -16 -24) (16 16 -13)
*/
void() dead_army =
{
	if (random() < 0.5)
		deadmonstersetup("progs/soldier.mdl", "progs/h_guard.mdl", army_die10, 6, 6, MB_GRUNT);
	else
		deadmonstersetup("progs/soldier.mdl", "progs/h_guard.mdl", army_cdie11, 6, 6, MB_GRUNT);
};
