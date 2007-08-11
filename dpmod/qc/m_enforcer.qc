/*
==============================================================================

SOLDIER / PLAYER

==============================================================================
*/

$cd id1/models/enforcer
$origin 0 -6 24
$base base
$skin skin

$frame stand1 stand2 stand3 stand4 stand5 stand6 stand7

$frame walk1 walk2 walk3 walk4 walk5 walk6 walk7 walk8 walk9 walk10
$frame walk11 walk12 walk13 walk14 walk15 walk16

$frame run1 run2 run3 run4 run5 run6 run7 run8

$frame attack1 attack2 attack3 attack4 attack5 attack6
$frame attack7 attack8 attack9 attack10

$frame death1 death2 death3 death4 death5 death6 death7 death8
$frame death9 death10 death11 death12 death13 death14

$frame fdeath1 fdeath2 fdeath3 fdeath4 fdeath5 fdeath6 fdeath7 fdeath8
$frame fdeath9 fdeath10 fdeath11

$frame paina1 paina2 paina3 paina4

$frame painb1 painb2 painb3 painb4 painb5

$frame painc1 painc2 painc3 painc4 painc5 painc6 painc7 painc8

$frame paind1 paind2 paind3 paind4 paind5 paind6 paind7 paind8
$frame paind9 paind10 paind11 paind12 paind13 paind14 paind15 paind16
$frame paind17 paind18 paind19


void() enf_run1;


void(vector hit) enforcer_laser =
{
	makevectors (self.angles);
	shotorg = self.origin + v_forward * 15 + v_right * 8.5 + '0 0 16';
	traceline(shotorg, hit, FALSE, self);
	if (trace_fraction < 1 && trace_ent != self.enemy)
	{
		// the shot wouldn't hit, so don't bother
		enf_run1();
		return;
	}
	self.effects = self.effects | EF_MUZZLEFLASH;

	shotdir = normalize(hit - shotorg);
	w_muzzleflash(shotorg, 2);
	LaunchLaser(self, shotorg, shotdir * 1000, DMG_ENFORCER_LASER, self.deathtype, Obituary_Generic);
};

void(vector hit) enforcer_dbshotgun =
{
	makevectors (self.angles);
	shotorg = self.origin + v_forward * 15 + v_right * 8.5 + '0 0 16';
	traceline(shotorg, hit, FALSE, self);
	if (trace_fraction < 1 && trace_ent != self.enemy)
	{
		// the shot wouldn't hit, so don't bother
		enf_run1();
		return;
	}
	if (vlen(trace_endpos - shotorg) > DMG_ENFORCER_DBSHOTGUN_RANGE)
	{
		enf_run1();
		return;
	}
	self.effects = self.effects | EF_MUZZLEFLASH;

	shotdir = normalize(hit - shotorg);
	sound(self, CHAN_WEAPON, "weapons/shotgn2.wav", 1, ATTN_NORM);
	w_muzzleflash(shotorg, 2);
	ejectcasing(shotorg + v_forward * -8 + v_right *  1, v_right *  100 + v_up * 40, 30, self.v_angle_x * '-1 0 0' + self.v_angle_y * '0 1 0', '0 250 0', 100, 1);
	ejectcasing(shotorg + v_forward * -8 + v_right * -1, v_right * -100 + v_up * 40, 30, self.v_angle_x * '-1 0 0' + self.v_angle_y * '0 1 0', '0 -250 0', 100, 1);
	FireBullets(self, self, 1, 20, DMG_ENFORCER_DBSHOTGUN_DAMAGE * 0.05, DMG_ENFORCER_DBSHOTGUN_DAMAGE * 0.05, 0, 0, shotdir * 10000, 0.1, self.deathtype, DT_SHOTGUN, Obituary_Generic);
};

void(vector hit) enforcer_supernail =
{
	makevectors (self.angles);
	shotorg = self.origin + v_forward * 15 + v_right * 8.5 + '0 0 16';
	traceline(shotorg, hit, FALSE, self);
	if (trace_fraction < 1 && trace_ent != self.enemy)
	{
		// the shot wouldn't hit, so don't bother
		enf_run1();
		return;
	}
	self.effects = self.effects | EF_MUZZLEFLASH;

	shotdir = normalize(hit - shotorg);
	w_muzzleflash(shotorg, 2);
	sound(self, CHAN_WEAPON, "weapons/spike2.wav", 1, ATTN_NORM);
	ejectcasing(shotorg + v_forward * -5, v_right *  150 + v_up * 50, 50, self.v_angle_x * '-1 0 0' + self.v_angle_y * '0 1 0', '0 250 0', 100, 0);
	FireBullets(self, self, 4, 2, DMG_ENFORCER_SUPERNAIL_DAMAGE, DMG_ENFORCER_SUPERNAIL_DAMAGE, 0, 0, shotdir * 10000, 0.05, self.deathtype, DT_NAIL, Obituary_Generic);
};

void(vector hit) enforcer_rocket =
{
	makevectors (self.angles);
	shotorg = self.origin + v_forward * 15 + v_right * 8.5 + '0 0 16';
	traceline(shotorg, hit, FALSE, self);
	if (trace_fraction < 1 && trace_ent != self.enemy)
	{
		// the shot wouldn't hit, so don't bother
		enf_run1();
		return;
	}
	if (vlen(trace_endpos - shotorg) < DMG_ENFORCER_ROCKET_RADIUS)
	{
		enf_run1();
		return;
	}
	self.effects = self.effects | EF_MUZZLEFLASH;

	shotdir = normalize(hit - shotorg);
	sound(self, CHAN_WEAPON, "weapons/sgun1.wav", 1, ATTN_NORM);
	w_muzzleflash(shotorg, 5);
	LaunchMissile(shotorg, shotdir * 3000, self, DMG_ENFORCER_ROCKET_DAMAGE, DMG_ENFORCER_ROCKET_FORCE, DMG_ENFORCER_ROCKET_RADIUS, self.deathtype, Obituary_Generic);
};

void(vector hit) enforcer_plasma =
{
	makevectors (self.angles);
	shotorg = self.origin + v_forward * 15 + v_right * 8.5 + '0 0 16';
	traceline(shotorg, hit, FALSE, self);
	if (trace_fraction < 1 && trace_ent != self.enemy)
	{
		// the shot wouldn't hit, so don't bother
		enf_run1();
		return;
	}
	self.effects = self.effects | EF_MUZZLEFLASH;

	shotdir = normalize(hit - shotorg);
	w_muzzleflash(shotorg, 2);
	sound (self, CHAN_WEAPON, "plasma/plasma.wav", 1, ATTN_NORM);
	FirePlasma(self, self, shotorg, shotdir * 5000, DMG_ENFORCER_PLASMA_DAMAGE, DMG_ENFORCER_PLASMA_FORCE, DMG_ENFORCER_PLASMA_RADIUS, self.deathtype, Obituary_Generic);
};

//============================================================================

void() enf_stand1	=[	$stand1,	enf_stand2	] {ai_stand();};
void() enf_stand2	=[	$stand2,	enf_stand3	] {ai_stand();};
void() enf_stand3	=[	$stand3,	enf_stand4	] {ai_stand();};
void() enf_stand4	=[	$stand4,	enf_stand5	] {ai_stand();};
void() enf_stand5	=[	$stand5,	enf_stand6	] {ai_stand();};
void() enf_stand6	=[	$stand6,	enf_stand7	] {ai_stand();};
void() enf_stand7	=[	$stand7,	enf_stand1	] {ai_stand();};

void() enf_walk1	=[	$walk1 ,	enf_walk2	] {
if (random() < 0.2)
	sound (self, CHAN_VOICE, "enforcer/idle1.wav", 1, ATTN_IDLE);
ai_walk(2);};
void() enf_walk2	=[	$walk2 ,	enf_walk3	] {ai_walk(4);};
void() enf_walk3	=[	$walk3 ,	enf_walk4	] {ai_walk(4);};
void() enf_walk4	=[	$walk4 ,	enf_walk5	] {ai_walk(3);};
void() enf_walk5	=[	$walk5 ,	enf_walk6	] {ai_walk(1);};
void() enf_walk6	=[	$walk6 ,	enf_walk7	] {ai_walk(2);};
void() enf_walk7	=[	$walk7 ,	enf_walk8	] {ai_walk(2);};
void() enf_walk8	=[	$walk8 ,	enf_walk9	] {ai_walk(1);};
void() enf_walk9	=[	$walk9 ,	enf_walk10	] {ai_walk(2);};
void() enf_walk10	=[	$walk10,	enf_walk11	] {ai_walk(4);};
void() enf_walk11	=[	$walk11,	enf_walk12	] {ai_walk(4);};
void() enf_walk12	=[	$walk12,	enf_walk13	] {ai_walk(1);};
void() enf_walk13	=[	$walk13,	enf_walk14	] {ai_walk(2);};
void() enf_walk14	=[	$walk14,	enf_walk15	] {ai_walk(3);};
void() enf_walk15	=[	$walk15,	enf_walk16	] {ai_walk(4);};
void() enf_walk16	=[	$walk16,	enf_walk1	] {ai_walk(2);};

void() enf_run1	=[	$run1  ,	enf_run2	] {
if (random() < 0.2)
	sound (self, CHAN_VOICE, "enforcer/idle1.wav", 1, ATTN_IDLE);
ai_run(18);};
void() enf_run2	=[	$run2  ,	enf_run3	] {ai_run(14);};
void() enf_run3	=[	$run3  ,	enf_run4	] {ai_run(7);};
void() enf_run4	=[	$run4  ,	enf_run5	] {ai_run(12);};
void() enf_run5	=[	$run5  ,	enf_run6	] {ai_run(14);};
void() enf_run6	=[	$run6  ,	enf_run7	] {ai_run(14);};
void() enf_run7	=[	$run7  ,	enf_run8	] {ai_run(7);};
void() enf_run8	=[	$run8  ,	enf_run1	] {ai_run(11);};

void() enf_laser1	=[	$attack1,	enf_laser2	] {ai_face();};
void() enf_laser2	=[	$attack2,	enf_laser3	] {ai_face();};
void() enf_laser3	=[	$attack3,	enf_laser4	] {ai_face();self.dest1 = monster_shotlead(0.3, 1000);};
void() enf_laser4	=[	$attack4,	enf_laser5	] {monster_setalpha(0.5);ai_face();self.dest2 = monster_shotlead(0.3, 1000);};
void() enf_laser5	=[	$attack5,	enf_laser6	] {monster_setalpha(1.0);ai_face();};
void() enf_laser6	=[	$attack6,	enf_laser7	] {monster_setalpha(1.0);ai_face();enforcer_laser(self.dest1);};
void() enf_laser7	=[	$attack6,	enf_laser8	] {monster_setalpha(1.0);ai_face();enforcer_laser(self.dest2);};
void() enf_laser8	=[	$attack7,	enf_laser9	] {monster_setalpha(1.0);ai_face();};
void() enf_laser9	=[	$attack8,	enf_laser10	] {monster_setalpha(0.5);ai_face();};
void() enf_laser10	=[	$attack9,	enf_laser11	] {monster_setalpha(0.0);ai_face();};
void() enf_laser11	=[	$attack10,	enf_run1	] {ai_face();SUB_CheckRefire (enf_laser1);};

float() enf_missile_laser =
{
	enf_laser1();
	return TRUE;
};

void()	enf_dbshotgun10;
void()	enf_dbshotgun1	=[	$attack1,	enf_dbshotgun2	] {ai_face();};
void()	enf_dbshotgun2	=[	$attack2,	enf_dbshotgun3	] {ai_face();self.dest1 = monster_shotlead(0.4, 10000);};
void()	enf_dbshotgun3	=[	$attack3,	enf_dbshotgun4	] {ai_face();};
void()	enf_dbshotgun4	=[	$attack4,	enf_dbshotgun5	] {monster_setalpha(0.5);ai_face();};
void()	enf_dbshotgun5	=[	$attack5,	enf_dbshotgun6	] {monster_setalpha(1.0);ai_face();self.dest2 = monster_shotlead(0.3, 2000);};
void()	enf_dbshotgun6	=[	$attack6,	enf_dbshotgun7	] {monster_setalpha(1.0);ai_face();enforcer_dbshotgun(self.dest1);};
void()	enf_dbshotgun7	=[	$attack7,	enf_dbshotgun8	] {monster_setalpha(1.0);if (skill < 3) self.think = enf_dbshotgun10;ai_face();};
void()	enf_dbshotgun8	=[	$attack6,	enf_dbshotgun9	] {monster_setalpha(1.0);ai_face();enforcer_dbshotgun(self.dest2);};
void()	enf_dbshotgun9	=[	$attack7,	enf_dbshotgun10	] {monster_setalpha(1.0);ai_face();};
void()	enf_dbshotgun10	=[	$attack8,	enf_dbshotgun11	] {monster_setalpha(0.5);ai_face();};
void()	enf_dbshotgun11	=[	$attack9,	enf_dbshotgun12	] {monster_setalpha(0.0);ai_face();};
void()	enf_dbshotgun12	=[	$attack10,	enf_run1		] {ai_face();};

float() enf_missile_dbshotgun =
{
	enf_dbshotgun1();
	return TRUE;
};

void()	enf_supernail1	=[	$attack1,	enf_supernail2	] {ai_face();};
void()	enf_supernail2	=[	$attack2,	enf_supernail3	] {ai_face();self.dest1 = monster_shotlead(0.4, 10000);};
void()	enf_supernail3	=[	$attack3,	enf_supernail4	] {ai_face();self.dest2 = monster_shotlead(0.4, 10000);};
void()	enf_supernail4	=[	$attack4,	enf_supernail5	] {ai_face();self.dest3 = monster_shotlead(0.4, 10000);};
void()	enf_supernail5	=[	$attack5,	enf_supernail6	] {monster_setalpha(0.5);ai_face();self.dest4 = monster_shotlead(0.4, 10000);};
void()	enf_supernail6	=[	$attack6,	enf_supernail7	] {monster_setalpha(1.0);ai_face();enforcer_supernail(self.dest1);self.dest1 = monster_shotlead(0.4, 10000);};
void()	enf_supernail7	=[	$attack6,	enf_supernail8	] {monster_setalpha(1.0);ai_face();enforcer_supernail(self.dest2);self.dest2 = monster_shotlead(0.4, 10000);};
void()	enf_supernail8	=[	$attack6,	enf_supernail9	] {monster_setalpha(1.0);ai_face();enforcer_supernail(self.dest3);};
void()	enf_supernail9	=[	$attack6,	enf_supernail10	] {monster_setalpha(1.0);ai_face();enforcer_supernail(self.dest4);};
void()	enf_supernail10	=[	$attack6,	enf_supernail11	] {monster_setalpha(1.0);ai_face();enforcer_supernail(self.dest1);};
void()	enf_supernail11	=[	$attack6,	enf_supernail12	] {monster_setalpha(1.0);ai_face();enforcer_supernail(self.dest2);};
void()	enf_supernail12	=[	$attack7,	enf_supernail13	] {monster_setalpha(0.5);ai_face();};
void()	enf_supernail13	=[	$attack8,	enf_supernail14	] {monster_setalpha(0.0);ai_face();};
void()	enf_supernail14	=[	$attack9,	enf_supernail15	] {ai_face();};
void()	enf_supernail15	=[	$attack10,	enf_run1		] {ai_face();SUB_CheckRefire (enf_supernail1);};

float() enf_missile_supernailgun =
{
	enf_supernail1();
	return TRUE;
};

void()	enf_rocket10;
void()	enf_rocket1		=[	$attack1,	enf_rocket2		] {ai_face();};
void()	enf_rocket2		=[	$attack2,	enf_rocket3		] {ai_face();};
void()	enf_rocket3		=[	$attack3,	enf_rocket4		] {ai_face();self.dest1 = monster_shotlead(0.3, 2000);};
void()	enf_rocket4		=[	$attack4,	enf_rocket5		] {monster_setalpha(0.5);ai_face();};
void()	enf_rocket5		=[	$attack5,	enf_rocket6		] {monster_setalpha(1.0);ai_face();self.dest2 = monster_shotlead(0.3, 2000);};
void()	enf_rocket6		=[	$attack6,	enf_rocket7		] {monster_setalpha(1.0);ai_face();enforcer_rocket(self.dest1);};
void()	enf_rocket7		=[	$attack7,	enf_rocket8		] {monster_setalpha(1.0);if (skill < 3) self.think = enf_rocket10;ai_face();};
void()	enf_rocket8		=[	$attack6,	enf_rocket9		] {monster_setalpha(1.0);ai_face();enforcer_rocket(self.dest2);};
void()	enf_rocket9		=[	$attack7,	enf_rocket10	] {monster_setalpha(1.0);ai_face();};
void()	enf_rocket10	=[	$attack8,	enf_rocket11	] {monster_setalpha(0.5);ai_face();};
void()	enf_rocket11	=[	$attack9,	enf_rocket12	] {monster_setalpha(0.0);ai_face();};
void()	enf_rocket12	=[	$attack10,	enf_run1		] {ai_face();};

float() enf_missile_rocket =
{
	enf_rocket1();
	return TRUE;
};

void()	enf_plasma1		=[	$attack1,	enf_plasma2		] {ai_face();};
void()	enf_plasma2		=[	$attack2,	enf_plasma3		] {ai_face();};
void()	enf_plasma3		=[	$attack3,	enf_plasma4		] {ai_face();self.dest1 = monster_shotlead(0.3, 3000);};
void()	enf_plasma4		=[	$attack4,	enf_plasma5		] {monster_setalpha(0.5);ai_face();self.dest2 = monster_shotlead(0.3, 3000);};
void()	enf_plasma5		=[	$attack5,	enf_plasma6		] {monster_setalpha(1.0);ai_face();self.dest3 = monster_shotlead(0.3, 3000);};
void()	enf_plasma6		=[	$attack6,	enf_plasma7		] {monster_setalpha(1.0);ai_face();enforcer_plasma(self.dest1);};
void()	enf_plasma7		=[	$attack6,	enf_plasma8		] {monster_setalpha(1.0);ai_face();enforcer_plasma(self.dest2);};
void()	enf_plasma8		=[	$attack6,	enf_plasma9		] {monster_setalpha(1.0);ai_face();enforcer_plasma(self.dest3);};
void()	enf_plasma9		=[	$attack7,	enf_plasma10	] {monster_setalpha(1.0);ai_face();};
void()	enf_plasma10	=[	$attack8,	enf_plasma11	] {monster_setalpha(0.5);ai_face();};
void()	enf_plasma11	=[	$attack9,	enf_plasma12	] {monster_setalpha(0.0);ai_face();};
void()	enf_plasma12	=[	$attack10,	enf_run1		] {ai_face();SUB_CheckRefire (enf_plasma1);};

float() enf_missile_plasma =
{
	enf_plasma1();
	return TRUE;
};



void() enf_paina1	=[	$paina1,	enf_paina2	] {monster_setalpha(1.00);};
void() enf_paina2	=[	$paina2,	enf_paina3	] {monster_setalpha(1.00);};
void() enf_paina3	=[	$paina3,	enf_paina4	] {monster_setalpha(0.50);};
void() enf_paina4	=[	$paina4,	enf_run1	] {monster_setalpha(0.00);};

void() enf_painb1	=[	$painb1,	enf_painb2	] {monster_setalpha(1.00);};
void() enf_painb2	=[	$painb2,	enf_painb3	] {monster_setalpha(1.00);};
void() enf_painb3	=[	$painb3,	enf_painb4	] {monster_setalpha(1.00);};
void() enf_painb4	=[	$painb4,	enf_painb5	] {monster_setalpha(0.50);};
void() enf_painb5	=[	$painb5,	enf_run1	] {monster_setalpha(0.00);};

void() enf_painc1	=[	$painc1,	enf_painc2	] {monster_setalpha(1.00);};
void() enf_painc2	=[	$painc2,	enf_painc3	] {monster_setalpha(1.00);};
void() enf_painc3	=[	$painc3,	enf_painc4	] {monster_setalpha(1.00);};
void() enf_painc4	=[	$painc4,	enf_painc5	] {monster_setalpha(0.50);};
void() enf_painc5	=[	$painc5,	enf_painc6	] {monster_setalpha(0.00);};
void() enf_painc6	=[	$painc6,	enf_painc7	] {};
void() enf_painc7	=[	$painc7,	enf_painc8	] {};
void() enf_painc8	=[	$painc8,	enf_run1	] {};

void() enf_paind1	=[	$paind1,	enf_paind2	] {monster_setalpha(1.00);};
void() enf_paind2	=[	$paind2,	enf_paind3	] {monster_setalpha(1.00);};
void() enf_paind3	=[	$paind3,	enf_paind4	] {monster_setalpha(1.00);};
void() enf_paind4	=[	$paind4,	enf_paind5	] {monster_setalpha(0.50);ai_painforward(2);};
void() enf_paind5	=[	$paind5,	enf_paind6	] {monster_setalpha(0.00);ai_painforward(1);};
void() enf_paind6	=[	$paind6,	enf_paind7	] {};
void() enf_paind7	=[	$paind7,	enf_paind8	] {};
void() enf_paind8	=[	$paind8,	enf_paind9	] {};
void() enf_paind9	=[	$paind9,	enf_paind10	] {};
void() enf_paind10	=[	$paind10,	enf_paind11	] {};
void() enf_paind11	=[	$paind11,	enf_paind12	] {ai_painforward(1);};
void() enf_paind12	=[	$paind12,	enf_paind13	] {ai_painforward(1);};
void() enf_paind13	=[	$paind13,	enf_paind14	] {ai_painforward(1);};
void() enf_paind14	=[	$paind14,	enf_paind15	] {};
void() enf_paind15	=[	$paind15,	enf_paind16	] {};
void() enf_paind16	=[	$paind16,	enf_paind17	] {ai_pain(1);};
void() enf_paind17	=[	$paind17,	enf_paind18	] {ai_pain(1);};
void() enf_paind18	=[	$paind18,	enf_paind19	] {};
void() enf_paind19	=[	$paind19,	enf_run1	] {};

void(entity attacker, float damage, float damgtype, string dethtype) enf_pain =
{
	local float r;

	r = random ();
	if (self.pain_finished > time)
		return;

	if (r < 0.5)
		sound (self, CHAN_VOICE, "enforcer/pain1.wav", 1, ATTN_NORM);
	else
		sound (self, CHAN_VOICE, "enforcer/pain2.wav", 1, ATTN_NORM);

	if (r < 0.2)
	{
		self.pain_finished = time + 1;
		enf_paina1 ();
	}
	else if (r < 0.4)
	{
		self.pain_finished = time + 1;
		enf_painb1 ();
	}
	else if (r < 0.7)
	{
		self.pain_finished = time + 1;
		enf_painc1 ();
	}
	else
	{
		self.pain_finished = time + 2;
		enf_paind1 ();
	}
};

//============================================================================




void()	enf_die1	=[	$death1,	enf_die2	] {body_solid('-16 -16 -24', '16 16 24');};
void()	enf_die2	=[	$death2,	enf_die3	] {body_solid('-16 -16 -24', '16 16 23');};
void()	enf_die3	=[	$death3,	enf_die4	] {body_solid('-16 -16 -24', '16 16 22');};
void()	enf_die4	=[	$death4,	enf_die5	] {body_solid('-16 -16 -24', '16 16 22');ai_forward(14);};
void()	enf_die5	=[	$death5,	enf_die6	] {body_solid('-16 -16 -24', '16 16 22');ai_forward(2);};
void()	enf_die6	=[	$death6,	enf_die7	] {body_solid('-16 -16 -24', '16 16 22');};
void()	enf_die7	=[	$death7,	enf_die8	] {body_solid('-16 -16 -24', '16 16 22');};
void()	enf_die8	=[	$death8,	enf_die9	] {body_solid('-16 -16 -24', '16 16 22');};
void()	enf_die9	=[	$death9,	enf_die10	] {body_solid('-16 -16 -24', '16 16 17');ai_forward(3);};
void()	enf_die10	=[	$death10,	enf_die11	] {body_nonsolid('-16 -16 -24', '16 16  7');ai_forward(5);};
void()	enf_die11	=[	$death11,	enf_die12	] {body_nonsolid('-16 -16 -24', '16 16 -2');ai_forward(5);};
void()	enf_die12	=[	$death12,	enf_die13	] {body_nonsolid('-16 -16 -24', '16 16 -2');ai_forward(5);};
void()	enf_die13	=[	$death13,	enf_die14	] {body_nonsolid('-16 -16 -24', '16 16 -3');};
void()	enf_die14	=[	$death14,	enf_die14	] {body_nonsolid('-16 -16 -24', '16 16 -10');}; // -3

void()	enf_fdie1	=[	$fdeath1,	enf_fdie2	] {body_solid('-16 -16 -24', '16 16 24');};
void()	enf_fdie2	=[	$fdeath2,	enf_fdie3	] {body_solid('-16 -16 -24', '16 16 24');};
void()	enf_fdie3	=[	$fdeath3,	enf_fdie4	] {body_solid('-16 -16 -24', '16 16 24');};
void()	enf_fdie4	=[	$fdeath4,	enf_fdie5	] {body_solid('-16 -16 -24', '16 16 20');};
void()	enf_fdie5	=[	$fdeath5,	enf_fdie6	] {body_solid('-16 -16 -24', '16 16 10');};
void()	enf_fdie6	=[	$fdeath6,	enf_fdie7	] {body_solid('-16 -16 -24', '16 16  3');};
void()	enf_fdie7	=[	$fdeath7,	enf_fdie8	] {body_solid('-16 -16 -24', '16 16 -2');};
void()	enf_fdie8	=[	$fdeath8,	enf_fdie9	] {body_nonsolid('-16 -16 -24', '16 16 -6');};
void()	enf_fdie9	=[	$fdeath9,	enf_fdie10	] {body_nonsolid('-16 -16 -24', '16 16 -8');};
void()	enf_fdie10	=[	$fdeath10,	enf_fdie11	] {body_nonsolid('-16 -16 -24', '16 16 -8');};
void()	enf_fdie11	=[	$fdeath11,	enf_fdie11	] {body_nonsolid('-16 -16 -24', '16 16 -10');}; // -8

void() enf_gib =
{
	monster_setalpha(1);
	sound (self, CHAN_VOICE, "player/udeath.wav", 1, ATTN_NORM);
	MonsterGibs("progs/h_mega.mdl", 6, "", 0, "", 0);
};

void() enf_die =
{
	monster_setalpha(1);
	DropBackpack();
	sound (self, CHAN_VOICE, "enforcer/death1.wav", 1, ATTN_NORM);
	if (random() > 0.5)
		MonsterCorpse(self, enf_die1);
	else
		MonsterCorpse(self, enf_fdie1);
};


void() enforcer_sightsound =
{
	local float rsnd;
	rsnd = random();
	if (rsnd >= 0.75)
		sound (self, CHAN_VOICE, "enforcer/sight1.wav", 1, ATTN_NORM);
	else if (rsnd >= 0.5)
		sound (self, CHAN_VOICE, "enforcer/sight2.wav", 1, ATTN_NORM);
	else if (rsnd >= 0.25)
		sound (self, CHAN_VOICE, "enforcer/sight3.wav", 1, ATTN_NORM);
	else
		sound (self, CHAN_VOICE, "enforcer/sight4.wav", 1, ATTN_NORM);
};

void() precachemonster_enforcer =
{
	precache_model2 ("progs/enforcer.mdl");
	precache_model2 ("progs/h_mega.mdl");
	precache_model2 ("progs/laser.mdl");

	precache_sound2 ("enforcer/death1.wav");
	precache_sound2 ("enforcer/enfire.wav");
	precache_sound2 ("enforcer/enfstop.wav");
	precache_sound2 ("enforcer/idle1.wav");
	precache_sound2 ("enforcer/pain1.wav");
	precache_sound2 ("enforcer/pain2.wav");
	precache_sound2 ("enforcer/sight1.wav");
	precache_sound2 ("enforcer/sight2.wav");
	precache_sound2 ("enforcer/sight3.wav");
	precache_sound2 ("enforcer/sight4.wav");
};

/*QUAKED monster_enforcer (1 0 0) (-16 -16 -24) (16 16 32) Ambush
*/
void() monster_enforcer =
{
	local float r;
	if (deathmatch)
	if (!monsterspawn)
	{
		remove(self);
		return;
	}
	if (!monsterspawn)
		precachemonster_enforcer();

	self.forcescale = 0.5;
	self.netname = "an enforcer";
	// self.doobits = 1;
	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_STEP;

	setmodel (self, "progs/enforcer.mdl");

	setsize (self, '-16 -16 -24', '16 16 24');
	if (!self.health)
		self.health = MH_ENFORCER;
	self.health = self.health;
	self.bodyhealth = self.health + MB_ENFORCER;
	self.bleedratio = 0.25; // not much health damage due to armor suit
	self.radsuit_finished = 99999999;

	self.resist_fire = 0.25; // suit mostly prevents fire damage

	r = random();
	if (r < 0.20)
	{
		self.th_missile = enf_missile_rocket;
		Inventory_SetQuantity(self, "rockets", AMMO_ENFORCER_ROCKETLAUNCHER);
		Inventory_SetQuantity(self, "rocketlauncher", 1);
		if (!self.deathtype) // map makers can override this
			self.deathtype = " was blasted by an enforcer";
	}
	else if (r < 0.40)
	{
		self.th_missile = enf_missile_plasma;
		Inventory_SetQuantity(self, "cells", AMMO_ENFORCER_PLASMARIFLE);
		Inventory_SetQuantity(self, "plasmarifle", 1);
		if (!self.deathtype) // map makers can override this
			self.deathtype = " was scorched by an enforcer";
	}
	else if (r < 0.60)
	{
		self.th_missile = enf_missile_dbshotgun;
		Inventory_SetQuantity(self, "shells", AMMO_ENFORCER_DBSHOTGUN);
		Inventory_SetQuantity(self, "supershotgun", 1);
		if (!self.deathtype) // map makers can override this
			self.deathtype = " was scorched by an enforcer";
	}
	else if (r < 0.80)
	{
		self.th_missile = enf_missile_supernailgun;
		Inventory_SetQuantity(self, "nails", AMMO_ENFORCER_SUPERNAILGUN);
		Inventory_SetQuantity(self, "supernailgun", 1);
		if (!self.deathtype) // map makers can override this
			self.deathtype = " was scorched by an enforcer";
	}
	else
	{
		self.th_missile = enf_missile_laser;
		Inventory_SetQuantity(self, "cells", AMMO_ENFORCER_LASERRIFLE);
		Inventory_SetQuantity(self, "laserrifle", 1);
		self.items = 0;
		if (!self.deathtype) // map makers can override this
			self.deathtype = " was blasted by an enforcer";
	}

	/*
	r = random();
	if (r < 0.20)
	{
		self.armorvalue = 100;
		self.armortype = 0.8;
	}
	else if (r < 0.50)
	{
		self.armorvalue = 60;
		self.armortype = 0.6;
	}
	else
	{
		self.armorvalue = 30;
		self.armortype = 0.3;
	}
	*/

	self.th_stand = enf_stand1;
	self.th_walk = enf_walk1;
	self.th_run = enf_run1;
	self.th_pain = enf_pain;
	self.th_die = enf_die;
	self.th_checkattack = GenericCheckAttack;
	self.th_gib = enf_gib;
	self.th_sightsound = enforcer_sightsound;

	monster_checkbossflag();
	walkmonster_start();
};

/*QUAKED dead_enforcer (1 0 0) (-16 -16 -24) (16 16 -10)
*/
void() dead_enforcer =
{
	if (random() < 0.5)
		deadmonstersetup("progs/enforcer.mdl", "progs/h_mega.mdl", enf_die14, 6, 3, MB_ENFORCER);
	else
		deadmonstersetup("progs/enforcer.mdl", "progs/h_mega.mdl", enf_fdie11, 6, 3, MB_ENFORCER);
};

