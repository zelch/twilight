/*
==============================================================================

BLOB

==============================================================================
*/

$cd id1/models/tarbaby
$origin 0 0 24
$base base

$skin skin

$frame walk1 walk2 walk3 walk4  walk5 walk6 walk7 walk8 walk9 walk10
$frame walk11 walk12 walk13 walk14 walk15 walk16 walk17 walk18 walk19
$frame walk20 walk21 walk22 walk23 walk24 walk25

$frame run1 run2 run3 run4 run5 run6  run7 run8 run9 run10 run11 run12 run13
$frame run14 run15 run16 run17 run18 run19 run20 run21 run22 run23
$frame run24 run25

$frame jump1 jump2 jump3 jump4 jump5 jump6

$frame fly1 fly2 fly3 fly4

$frame exp

void()	tbaby_stand1	=[	$walk1,		tbaby_stand1	] {ai_stand();};

void()	tbaby_hang1		=[	$walk1,		tbaby_hang1	] {ai_stand();};

void()	tbaby_walk1	=[	$walk1,		tbaby_walk2	] {ai_turn();};
void()	tbaby_walk2	=[	$walk2,		tbaby_walk3	] {ai_turn();};
void()	tbaby_walk3	=[	$walk3,		tbaby_walk4	] {ai_turn();};
void()	tbaby_walk4	=[	$walk4,		tbaby_walk5	] {ai_turn();};
void()	tbaby_walk5	=[	$walk5,		tbaby_walk6	] {ai_turn();};
void()	tbaby_walk6	=[	$walk6,		tbaby_walk7	] {ai_turn();};
void()	tbaby_walk7	=[	$walk7,		tbaby_walk8	] {ai_turn();};
void()	tbaby_walk8	=[	$walk8,		tbaby_walk9	] {ai_turn();};
void()	tbaby_walk9	=[	$walk9,		tbaby_walk10	] {ai_turn();};
void()	tbaby_walk10	=[	$walk10,		tbaby_walk11	] {ai_turn();};
void()	tbaby_walk11	=[	$walk11,		tbaby_walk12	] {ai_walk(2);};
void()	tbaby_walk12	=[	$walk12,		tbaby_walk13	] {ai_walk(2);};
void()	tbaby_walk13	=[	$walk13,		tbaby_walk14	] {ai_walk(2);};
void()	tbaby_walk14	=[	$walk14,		tbaby_walk15	] {ai_walk(2);};
void()	tbaby_walk15	=[	$walk15,		tbaby_walk16	] {ai_walk(2);};
void()	tbaby_walk16	=[	$walk16,		tbaby_walk17	] {ai_walk(2);};
void()	tbaby_walk17	=[	$walk17,		tbaby_walk18	] {ai_walk(2);};
void()	tbaby_walk18	=[	$walk18,		tbaby_walk19	] {ai_walk(2);};
void()	tbaby_walk19	=[	$walk19,		tbaby_walk20	] {ai_walk(2);};
void()	tbaby_walk20	=[	$walk20,		tbaby_walk21	] {ai_walk(2);};
void()	tbaby_walk21	=[	$walk21,		tbaby_walk22	] {ai_walk(2);};
void()	tbaby_walk22	=[	$walk22,		tbaby_walk23	] {ai_walk(2);};
void()	tbaby_walk23	=[	$walk23,		tbaby_walk24	] {ai_walk(2);};
void()	tbaby_walk24	=[	$walk24,		tbaby_walk25	] {ai_walk(2);};
void()	tbaby_walk25	=[	$walk25,		tbaby_walk1	] {ai_walk(2);};

void()	tbaby_run1	=[	$run1,		tbaby_run2	] {ai_face();};
void()	tbaby_run2	=[	$run2,		tbaby_run3	] {ai_face();};
void()	tbaby_run3	=[	$run3,		tbaby_run4	] {ai_face();};
void()	tbaby_run4	=[	$run4,		tbaby_run5	] {ai_face();};
void()	tbaby_run5	=[	$run5,		tbaby_run6	] {ai_face();};
void()	tbaby_run6	=[	$run6,		tbaby_run7	] {ai_face();};
void()	tbaby_run7	=[	$run7,		tbaby_run8	] {ai_face();};
void()	tbaby_run8	=[	$run8,		tbaby_run9	] {ai_face();};
void()	tbaby_run9	=[	$run9,		tbaby_run10	] {ai_face();};
void()	tbaby_run10	=[	$run10,		tbaby_run11	] {ai_face();};
void()	tbaby_run11	=[	$run11,		tbaby_run12	] {ai_run(2);};
void()	tbaby_run12	=[	$run12,		tbaby_run13	] {ai_run(2);};
void()	tbaby_run13	=[	$run13,		tbaby_run14	] {ai_run(2);};
void()	tbaby_run14	=[	$run14,		tbaby_run15	] {ai_run(2);};
void()	tbaby_run15	=[	$run15,		tbaby_run16	] {ai_run(2);};
void()	tbaby_run16	=[	$run16,		tbaby_run17	] {ai_run(2);};
void()	tbaby_run17	=[	$run17,		tbaby_run18	] {ai_run(2);};
void()	tbaby_run18	=[	$run18,		tbaby_run19	] {ai_run(2);};
void()	tbaby_run19	=[	$run19,		tbaby_run20	] {ai_run(2);};
void()	tbaby_run20	=[	$run20,		tbaby_run21	] {ai_run(2);};
void()	tbaby_run21	=[	$run21,		tbaby_run22	] {ai_run(2);};
void()	tbaby_run22	=[	$run22,		tbaby_run23	] {ai_run(2);};
void()	tbaby_run23	=[	$run23,		tbaby_run24	] {ai_run(2);};
void()	tbaby_run24	=[	$run24,		tbaby_run25	] {ai_run(2);};
void()	tbaby_run25	=[	$run25,		tbaby_run1	] {ai_run(2);};


//============================================================================


void()	tbaby_jump1;

void()	Tar_JumpTouch =
{
	local	float	ldmg;

	// dunno why this would be called when dead, but to be safe
	if (self.health < 1)
		return;
	if (other.takedamage && other.classname != self.classname)
	{
		if (vlen(self.velocity) > 400)
		{
			//if (other.classname == "player")
			//	eprint(self);
			ldmg = DMG_TARBABY_JUMP_BASE + DMG_TARBABY_JUMP_RANDOM*random();
			T_Damage (other, self, self, ldmg, ldmg, self.deathtype, DT_IMPACT, self.origin, self.velocity * 0.05, Obituary_Generic);
			sound (self, CHAN_WEAPON, "blob/hit1.wav", 1, ATTN_NORM);
		}
	}
	else
		sound (self, CHAN_WEAPON, "blob/land1.wav", 1, ATTN_NORM);

	if (!checkbottom(self))
	{
		if (self.flags & FL_ONGROUND)
		{
			// jump randomly to not get hung up
			//dprint ("popjump\n");
			self.touch = SUB_Null;
			self.think = tbaby_run1;
			self.movetype = MOVETYPE_STEP;
			self.nextthink = time + 0.1;

//			self.velocity_x = (random() - 0.5) * 600;
//			self.velocity_y = (random() - 0.5) * 600;
//			self.velocity_z = 200;
//			self.flags = self.flags - FL_ONGROUND;
		}
		return;	// not on ground yet
	}

	self.touch = SUB_Null;
	self.think = tbaby_jump1;
	self.nextthink = time + 0.1;

	monster_setalpha(0.0);
};

void()	tbaby_jump5;

void()	tbaby_fly1		=[	$fly1,	tbaby_fly2	] {monster_setalpha(1.0);};
void()	tbaby_fly2		=[	$fly2,	tbaby_fly3	] {monster_setalpha(1.0);};
void()	tbaby_fly3		=[	$fly3,	tbaby_fly4	] {monster_setalpha(1.0);};
void()	tbaby_fly4		=[	$fly4,	tbaby_fly1	] {monster_setalpha(1.0);
self.cnt = self.cnt + 1;
if (self.cnt >= 4)
{
//dprint ("spawn hop\n");
tbaby_jump5 ();
}
};

void()	tbaby_jump1		=[	$jump1,	tbaby_jump2		] {ai_face();};
void()	tbaby_jump2		=[	$jump2,	tbaby_jump3		] {ai_face();};
void()	tbaby_jump3		=[	$jump3,	tbaby_jump4		] {ai_face();};
void()	tbaby_jump4		=[	$jump4,	tbaby_jump5		] {monster_setalpha(0.5);ai_face();};
void()	tbaby_jump5		=[	$jump5,	tbaby_jump6		]
{
	monster_setalpha(1.0);
	self.cnt = 0;
// dunno why this would be called when dead, but to be safe
	if (self.health < 1)
		return;
	self.movetype = MOVETYPE_BOUNCE;
	self.touch = Tar_JumpTouch;
	makevectors (self.angles);
	self.origin_z = self.origin_z + 1;
	self.velocity = v_forward * 600 + '0 0 200';
	self.velocity_z = self.velocity_z + random()*150;
	if (self.flags & FL_ONGROUND)
		self.flags = self.flags - FL_ONGROUND;
};
void()	tbaby_jump6	=[	$jump6,tbaby_fly1	] {monster_setalpha(1.0);};

float() tbaby_missile =
{
	tbaby_jump1();
	return TRUE;
};


//=============================================================================

void()  tbaby_die1      =[      $exp,           tbaby_die2      ]
{
	monster_setalpha(1);
	self.takedamage = DAMAGE_NO;
	self.touch = SUB_Null;
	self.th_pain = SUB_Null;
	self.th_die = SUB_Null;
	self.solid = SOLID_NOT;
	self.movetype = MOVETYPE_NONE;
	self.bodyhealth = -1;
	self.health = -1;
};
void()  tbaby_die2      =[      $exp,           tbaby_die2      ]
{
	mctf_spawnpickup(self.origin, 1, 0.3, 0.2, 0.1);
	MonsterGibs("", 0, "progs/tar_gib.mdl", 4, "", 0);
	self.skin = 0;
	self.owner = self;
	T_RadiusDamage(self, self.owner, DMG_TARBABY_DIE_DAMAGE, DMG_TARBABY_DIE_FORCE, DMG_TARBABY_DIE_RADIUS, world, self.deathtype, DT_EXPLOSION, Obituary_Generic);
	BecomeExplosion(self, '-2 0 0', FALSE);
};

void() tarbaby_sightsound =
{
	sound (self, CHAN_VOICE, "blob/sight1.wav", 1, ATTN_NORM);
};

//=============================================================================


void() precachemonster_tarbaby =
{
	precache_model2 ("progs/tarbaby.mdl");

	precache_model2 ("progs/tar_gib.mdl"); // GIBS!!!! :)

	precache_sound2 ("blob/death1.wav");
	precache_sound2 ("blob/hit1.wav");
	precache_sound2 ("blob/land1.wav");
	precache_sound2 ("blob/sight1.wav");
};

/*QUAKED monster_tarbaby (1 0 0) (-16 -16 -24) (16 16 24) Ambush
*/
void() monster_tarbaby =
{
	if (deathmatch)
	if (!monsterspawn)
	{
		remove(self);
		return;
	}
	if (!self.deathtype) // map makers can override this
		self.deathtype = " was slimed by a spawn";

	self.shoulddodge = TRUE;
	self.dangerrating = 200;

	if (!monsterspawn)
		precachemonster_tarbaby();

	self.forcescale = 6;
	self.netname = "a spawn";
	// self.doobits = 1;
	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_STEP;

	setmodel (self, "progs/tarbaby.mdl");

	setsize (self, '-16 -16 -24', '16 16 32');
	if (self.health < 1)
		self.health = MH_TARBABY;
	self.health = self.health;
	self.bodyhealth = 1000000000; // avoid a gib message
	self.bleedratio = 0; // no blood to lose

	self.th_stand = tbaby_stand1;
	self.th_walk = tbaby_walk1;
	self.th_run = tbaby_run1;
	self.th_checkattack = GenericCheckAttack;
	self.th_missile = tbaby_missile;
	self.th_melee = tbaby_jump1;
	self.th_die = tbaby_die1;
	self.th_sightsound = tarbaby_sightsound;

	walkmonster_start ();
	self.candrown = 0;
};

/*QUAKED dead_tarbaby (1 0 0) (-16 -16 -24) (16 16 24)
*/
/*
void() dead_tarbaby =
{
        precache_model("progs/tar_gib.mdl");
        MonsterGibs("", 0, "progs/tar_gib.mdl", 4, "", 0);
};
*/
