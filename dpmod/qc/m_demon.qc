/*
==============================================================================

DEMON

==============================================================================
*/

$cd id1/models/demon3
$scale	0.8
$origin 0 0 24
$base base
$skin base

$frame stand1 stand2 stand3 stand4 stand5 stand6 stand7 stand8 stand9
$frame stand10 stand11 stand12 stand13

$frame walk1 walk2 walk3 walk4 walk5 walk6 walk7 walk8

$frame run1 run2 run3 run4 run5 run6

$frame leap1 leap2 leap3 leap4 leap5 leap6 leap7 leap8 leap9 leap10
$frame leap11 leap12

$frame pain1 pain2 pain3 pain4 pain5 pain6

$frame death1 death2 death3 death4 death5 death6 death7 death8 death9

$frame attacka1 attacka2 attacka3 attacka4 attacka5 attacka6 attacka7 attacka8
$frame attacka9 attacka10 attacka11 attacka12 attacka13 attacka14 attacka15

//============================================================================

void() Demon_JumpTouch;
void() Demon_JumpCheckGround;

void() demon1_stand1	=[	$stand1,	demon1_stand2	] {ai_stand();};
void() demon1_stand2	=[	$stand2,	demon1_stand3	] {ai_stand();};
void() demon1_stand3	=[	$stand3,	demon1_stand4	] {ai_stand();};
void() demon1_stand4	=[	$stand4,	demon1_stand5	] {ai_stand();};
void() demon1_stand5	=[	$stand5,	demon1_stand6	] {ai_stand();};
void() demon1_stand6	=[	$stand6,	demon1_stand7	] {ai_stand();};
void() demon1_stand7	=[	$stand7,	demon1_stand8	] {ai_stand();};
void() demon1_stand8	=[	$stand8,	demon1_stand9	] {ai_stand();};
void() demon1_stand9	=[	$stand9,	demon1_stand10	] {ai_stand();};
void() demon1_stand10	=[	$stand10,	demon1_stand11	] {ai_stand();};
void() demon1_stand11	=[	$stand11,	demon1_stand12	] {ai_stand();};
void() demon1_stand12	=[	$stand12,	demon1_stand13	] {ai_stand();};
void() demon1_stand13	=[	$stand13,	demon1_stand1	] {ai_stand();};

void() demon1_walk1	=[	$walk1,		demon1_walk2	] {
if (random() < 0.2)
	sound (self, CHAN_VOICE, "demon/idle1.wav", 1, ATTN_IDLE);
ai_walk(8);
};
void() demon1_walk2	=[	$walk2,		demon1_walk3	] {ai_walk(6);};
void() demon1_walk3	=[	$walk3,		demon1_walk4	] {ai_walk(6);};
void() demon1_walk4	=[	$walk4,		demon1_walk5	] {ai_walk(7);};
void() demon1_walk5	=[	$walk5,		demon1_walk6	] {ai_walk(4);};
void() demon1_walk6	=[	$walk6,		demon1_walk7	] {ai_walk(6);};
void() demon1_walk7	=[	$walk7,		demon1_walk8	] {ai_walk(10);};
void() demon1_walk8	=[	$walk8,		demon1_walk1	] {ai_walk(10);};

void() demon1_run1	=[	$run1,		demon1_run2	] {
if (random() < 0.2)
	sound (self, CHAN_VOICE, "demon/idle1.wav", 1, ATTN_IDLE);
ai_run(20);};
void() demon1_run2	=[	$run2,		demon1_run3	] {ai_run(15);};
void() demon1_run3	=[	$run3,		demon1_run4	] {ai_run(36);};
void() demon1_run4	=[	$run4,		demon1_run5	] {ai_run(20);};
void() demon1_run5	=[	$run5,		demon1_run6	] {ai_run(15);};
void() demon1_run6	=[	$run6,		demon1_run1	] {ai_run(36);};

void() demon1_jump1	=[	$leap1,		demon1_jump2	] {monster_setalpha(0.5);ai_face();};
void() demon1_jump2	=[	$leap2,		demon1_jump3	] {monster_setalpha(1.0);ai_face();};
void() demon1_jump3	=[	$leap3,		demon1_jump4	] {monster_setalpha(1.0);ai_face();};
void() demon1_jump4	=[	$leap4,		demon1_jump5	]
{
	if (skill >= 5 && random() < 0.5) // half the fiend/tarbaby jumps in skill 5 are ghosted (causing the monster to pass through the player)
		monster_setalpha(0);
	else
		monster_setalpha(1.0);
	ai_face();

	self.touch = Demon_JumpTouch;
	makevectors (self.angles_y * '0 1 0');
	self.velocity = v_forward * 600 + '0 0 250';
	if (self.flags & FL_ONGROUND)
		self.flags = self.flags - FL_ONGROUND;
};
void() demon1_jump5	=[	$leap5,		demon1_jump6	] {Demon_JumpCheckGround();};
void() demon1_jump6	=[	$leap6,		demon1_jump7	] {Demon_JumpCheckGround();};
void() demon1_jump7	=[	$leap7,		demon1_jump8	] {Demon_JumpCheckGround();};
void() demon1_jump8	=[ $leap8,		demon1_jump9	] {Demon_JumpCheckGround();};
void() demon1_jump9	=[ $leap9,		demon1_jump10	] {Demon_JumpCheckGround();};
void() demon1_jump10	=[ $leap10,	demon1_jump1	] {
// if three seconds pass, assume demon is stuck and jump again
self.nextthink = time + 3;
Demon_JumpCheckGround();
};

void() demon1_jump11	=[ $leap11,	demon1_jump12	] {monster_setalpha(0.0);};
void() demon1_jump12	=[ $leap12,	demon1_run1	] {};


void() demon1_atta1	=[	$attacka1,		demon1_atta2	] {monster_setalpha(0);ai_charge(4);};
void() demon1_atta2	=[	$attacka2,		demon1_atta3	] {monster_setalpha(0.50);ai_charge(0);};
void() demon1_atta3	=[	$attacka3,		demon1_atta4	] {monster_setalpha(1.00);ai_charge(0);};
void() demon1_atta4	=[	$attacka4,		demon1_atta5	] {monster_setalpha(1.00);ai_charge(1);};
void() demon1_atta5	=[	$attacka5,		demon1_atta6	] {monster_setalpha(1.00);ai_charge(2); Demon_Melee(200);};
void() demon1_atta6	=[	$attacka6,		demon1_atta7	] {monster_setalpha(1.00);ai_charge(1);};
void() demon1_atta7	=[	$attacka7,		demon1_atta8	] {monster_setalpha(1.00);ai_charge(6);};
void() demon1_atta8	=[	$attacka8,		demon1_atta9	] {monster_setalpha(1.00);ai_charge(8);};
void() demon1_atta9	=[	$attacka9,		demon1_atta10	] {monster_setalpha(1.00);ai_charge(4);};
void() demon1_atta10	=[	$attacka10,		demon1_atta11] {monster_setalpha(1.00);ai_charge(2);};
void() demon1_atta11	=[	$attacka11,		demon1_atta12] {monster_setalpha(1.00);Demon_Melee(-200);};
void() demon1_atta12	=[	$attacka12,		demon1_atta13] {monster_setalpha(1.00);ai_charge(5);};
void() demon1_atta13	=[	$attacka13,		demon1_atta14] {monster_setalpha(1.00);ai_charge(8);};
void() demon1_atta14	=[	$attacka14,		demon1_atta15] {monster_setalpha(0.50);ai_charge(4);};
void() demon1_atta15	=[	$attacka15,		demon1_run1] {monster_setalpha(0);ai_charge(4);};

void() demon1_pain1	=[	$pain1,		demon1_pain2	] {monster_setalpha(1.00);};
void() demon1_pain2	=[	$pain2,		demon1_pain3	] {monster_setalpha(1.00);};
void() demon1_pain3	=[	$pain3,		demon1_pain4	] {monster_setalpha(1.00);};
void() demon1_pain4	=[	$pain4,		demon1_pain5	] {monster_setalpha(0.50);};
void() demon1_pain5	=[	$pain5,		demon1_pain6	] {monster_setalpha(0.00);};
void() demon1_pain6	=[	$pain6,		demon1_run1	] {};

void(entity attacker, float damage, float damgtype, string dethtype) demon1_pain =
{
	if (self.touch == Demon_JumpTouch)
		return;

	if (self.pain_finished > time)
		return;

	self.pain_finished = time + 1;
	sound (self, CHAN_VOICE, "demon/dpain1.wav", 1, ATTN_NORM);

	if (random()*200 > damage)
		return;		// didn't flinch

	demon1_pain1 ();
};

void()	demon1_die1	=[	$death1,	demon1_die2	] {body_solid('-32 -32 -24', '32 32 24');sound (self, CHAN_VOICE, "demon/ddeath.wav", 1, ATTN_NORM);};
void()	demon1_die2	=[	$death2,	demon1_die3	] {body_solid('-32 -32 -24', '32 32 24');};
void()	demon1_die3	=[	$death3,	demon1_die4	] {body_solid('-32 -32 -24', '32 32 24');};
void()	demon1_die4	=[	$death4,	demon1_die5	] {body_solid('-32 -32 -24', '32 32 21');};
void()	demon1_die5	=[	$death5,	demon1_die6	] {body_solid('-32 -32 -24', '32 32 10');};
void()	demon1_die6	=[	$death6,	demon1_die7	] {body_nonsolid('-32 -32 -24', '32 32  2');};
void()	demon1_die7	=[	$death7,	demon1_die8	] {body_nonsolid('-32 -32 -24', '32 32  0');};
void()	demon1_die8	=[	$death8,	demon1_die9	] {body_nonsolid('-32 -32 -24', '32 32 -4');};
void()	demon1_die9	=[	$death9,	demon1_die9	] {body_nonsolid('-32 -32 -24', '32 32 -12');}; // -5

void() demon_gib =
{
	monster_setalpha(1);
	sound (self, CHAN_VOICE, "player/udeath.wav", 1, ATTN_NORM);
	MonsterGibs("progs/h_demon.mdl", 6, "", 0, "", 0);
};

void() demon_die =
{
	monster_setalpha(1);
	MonsterCorpse(self, demon1_die1);
};


void() Demon_MeleeAttack =
{
	demon1_atta1 ();
};




/*
==============================================================================

DEMON

==============================================================================
*/

/*
==============
CheckDemonJump

==============
*/
float() CheckDemonJump =
{
	local vector old;

	/*
	if (self.origin_z + self.mins_z > self.enemy.origin_z + self.enemy.mins_z + 0.75 * self.enemy.size_z)
		return FALSE;

	if (self.origin_z + self.maxs_z < self.enemy.origin_z + self.enemy.mins_z + 0.25 * self.enemy.size_z)
		return FALSE;

	dist = self.enemy.origin + self.enemy.velocity * 0.4 - self.origin;
	dist_z = 0;

	d = vlen(dist);

	if (d < 100)
		return FALSE;

	if (d > 200)
	{
		if (random() < 0.9)
			return FALSE;
	}
	*/

	// LordHavoc: do further checking now
	makevectors (self.angles_y * '0 1 0');
	old = self.velocity;
	self.velocity = v_forward * 600 + '0 0 250';
	tracetoss(self, self);
	self.velocity = old;
	if (trace_ent != self.enemy)
		return FALSE;

	return TRUE;
};

float() demon1_missile =
{
	if (CheckDemonJump())
	{
		demon1_jump1();
		return TRUE;
	}
	return FALSE;
};

float() DemonCheckAttack =
{
	if (vlen(self.enemy.origin - self.origin) > 1000) // long traces are slow
		return FALSE;

// if close enough for slashing, go for it
	if (enemy_range == RANGE_MELEE)
	{	// FIXME: check canreach
		self.attack_state = AS_MELEE;
		return TRUE;
	}

	if (CheckDemonJump ())
	{
		self.attack_state = AS_MISSILE;
		sound (self, CHAN_VOICE, "demon/djump.wav", 1, ATTN_NORM);
		return TRUE;
	}

	return FALSE;
};


//===========================================================================

void(float side) Demon_Melee =
{
	local float ldmg;
	local vector delta;

	ai_face ();
	walkmove (self.ideal_yaw, 12);	// allow a little closing

	delta = self.enemy.origin - self.origin;

	if (vlen(delta) > 100)
		return;
	if (!CanDamage (self.enemy, self))
		return;

	sound (self, CHAN_WEAPON, "demon/dhit2.wav", 1, ATTN_NORM);
	ldmg = DMG_FIEND_MELEE_BASE + DMG_FIEND_MELEE_RANDOM*random();
	T_Damage (self.enemy, self, self, ldmg, ldmg * 0.5, self.deathtype, DT_CUT, self.origin, '0 0 0', Obituary_Generic);

	//makevectors (self.angles);
	//SpawnMeatSpray (self.origin + v_forward*16, side * v_right);
};


void() Demon_JumpCheckGround =
{
	if (!checkbottom(self))
		return;
	self.touch = SUB_Null;
	self.think = demon1_jump11;
	self.nextthink = time + 0.1;
};

void() Demon_JumpTouch =
{
	local float ldmg;

	if (self.health < 1)
		return;

	if (other.takedamage)
	{
		if ( vlen(self.velocity) > 400 )
		{
			ldmg = DMG_FIEND_JUMP_BASE + DMG_FIEND_JUMP_RANDOM*random();
			T_Damage (other, self, self, ldmg, ldmg * 0.25, self.deathtype, DT_IMPACT, self.origin, self.velocity * 0.1, Obituary_Generic);
		}
	}

	// LordHavoc: added (other.absmax_z < (self.absmin_z + 2)) checks
	// to make fiends jump when ontop of player
	if ((!checkbottom(self)) || ((other.absmax_z < (self.absmin_z + 2)) && (other.solid == SOLID_SLIDEBOX)))
	{
		if ((self.flags & FL_ONGROUND) || ((other.absmax_z < (self.absmin_z + 2)) && (other.solid == SOLID_SLIDEBOX)))
		{
			// jump randomly to not get hung up
			//dprint ("popjump\n");
			self.touch = SUB_Null;
			self.think = demon1_jump1;
			self.nextthink = time + 0.1;

//			self.velocity_x = (random() - 0.5) * 600;
//			self.velocity_y = (random() - 0.5) * 600;
//			self.velocity_z = 200;
//			self.flags = self.flags - FL_ONGROUND;
		}
		return;	// not on ground yet
	}

	self.touch = SUB_Null;
	self.think = demon1_jump11;
	self.nextthink = time + 0.1;
};

void() demon1_sightsound =
{
	sound (self, CHAN_VOICE, "demon/sight2.wav", 1, ATTN_NORM);
};

void() precachemonster_demon1 =
{
	precache_model ("progs/demon.mdl");
	precache_model ("progs/h_demon.mdl");

	precache_sound ("demon/ddeath.wav");
	precache_sound ("demon/dhit2.wav");
	precache_sound ("demon/djump.wav");
	precache_sound ("demon/dpain1.wav");
	precache_sound ("demon/idle1.wav");
	precache_sound ("demon/sight2.wav");
};

/*QUAKED monster_demon1 (1 0 0) (-32 -32 -24) (32 32 64) Ambush
*/
void() monster_demon1 =
{
	if (deathmatch)
	if (!monsterspawn)
	{
		remove(self);
		return;
	}
	if (!self.deathtype) // map makers can override this
		self.deathtype = " was torn apart by a Fiend";

	self.shoulddodge = TRUE;
	self.dangerrating = 90;

	if (!monsterspawn)
		precachemonster_demon1();

	self.forcescale = 1;
	self.netname = "a fiend";
	// self.doobits = 1;
	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_STEP;

	setmodel (self, "progs/demon.mdl");

	setsize (self, '-32 -32 -24', '32 32 24');
	if (!self.health)
		self.health = MH_DEMON;
	self.health = self.health;
	self.bodyhealth = self.health + MB_DEMON;
	self.bleedratio = 1; // demons are alive, and thus bleeding matters

	self.th_stand = demon1_stand1;
	self.th_walk = demon1_walk1;
	self.th_run = demon1_run1;
	self.th_die = demon_die;
	self.th_checkattack = DemonCheckAttack;
	self.th_melee = Demon_MeleeAttack;		// one of two attacks
	self.th_missile = demon1_missile;			// jump attack
	self.th_pain = demon1_pain;
	self.th_gib = demon_gib;
	self.th_sightsound = demon1_sightsound;

	monster_checkbossflag();
	walkmonster_start();
};

/*QUAKED dead_demon1 (1 0 0) (-32 -32 -24) (32 32 -12)
*/
void() dead_demon1 =
{
	deadmonstersetup("progs/demon.mdl", "progs/h_demon.mdl", demon1_die9, 6, 4, MB_DEMON);
};

