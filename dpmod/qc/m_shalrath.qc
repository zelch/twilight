/*
==============================================================================

SHAL-RATH

==============================================================================
*/
$cd id1/models/shalrath
$origin 0 0 24
$base base
$skin skin
$scale 0.7

$frame attack1 attack2 attack3 attack4 attack5 attack6 attack7 attack8
$frame attack9 attack10 attack11

$frame pain1 pain2 pain3 pain4 pain5

$frame death1 death2 death3 death4 death5 death6 death7

$frame	walk1 walk2 walk3 walk4 walk5 walk6 walk7 walk8 walk9 walk10
$frame	walk11 walk12

void() shalrath_pain;
void() ShalMissile;
void() shal_stand     =[      $walk1,       shal_stand    ] {ai_stand();};

void() shal_walk1     =[      $walk2,       shal_walk2    ] {
if (random() < 0.2)
	sound (self, CHAN_VOICE, "shalrath/idle.wav", 1, ATTN_IDLE);
ai_walk(6);};
void() shal_walk2     =[      $walk3,       shal_walk3    ] {ai_walk(4);};
void() shal_walk3     =[      $walk4,       shal_walk4    ] {ai_walk(0);};
void() shal_walk4     =[      $walk5,       shal_walk5    ] {ai_walk(0);};
void() shal_walk5     =[      $walk6,       shal_walk6    ] {ai_walk(0);};
void() shal_walk6     =[      $walk7,       shal_walk7    ] {ai_walk(0);};
void() shal_walk7     =[      $walk8,       shal_walk8    ] {ai_walk(5);};
void() shal_walk8     =[      $walk9,       shal_walk9    ] {ai_walk(6);};
void() shal_walk9     =[      $walk10,       shal_walk10    ] {ai_walk(5);};
void() shal_walk10    =[      $walk11,       shal_walk11    ] {ai_walk(0);};
void() shal_walk11    =[      $walk12,       shal_walk12    ] {ai_walk(4);};
void() shal_walk12    =[      $walk1,       shal_walk1    ] {ai_walk(5);};

void() shal_run1     =[      $walk2,       shal_run2    ] {
if (random() < 0.2)
	sound (self, CHAN_VOICE, "shalrath/idle.wav", 1, ATTN_IDLE);
ai_run(6);};
void() shal_run2     =[      $walk3,       shal_run3    ] {ai_run(4);};
void() shal_run3     =[      $walk4,       shal_run4    ] {ai_run(0);};
void() shal_run4     =[      $walk5,       shal_run5    ] {ai_run(0);};
void() shal_run5     =[      $walk6,       shal_run6    ] {ai_run(0);};
void() shal_run6     =[      $walk7,       shal_run7    ] {ai_run(0);};
void() shal_run7     =[      $walk8,       shal_run8    ] {ai_run(5);};
void() shal_run8     =[      $walk9,       shal_run9    ] {ai_run(6);};
void() shal_run9     =[      $walk10,       shal_run10    ] {ai_run(5);};
void() shal_run10    =[      $walk11,       shal_run11    ] {ai_run(0);};
void() shal_run11    =[      $walk12,       shal_run12    ] {ai_run(4);};
void() shal_run12    =[      $walk1,       shal_run1    ] {ai_run(5);};

void() shal_attack1     =[      $attack1,       shal_attack2    ] {
sound (self, CHAN_VOICE, "shalrath/attack.wav", 1, ATTN_NORM);
ai_face();
};
void() shal_attack2     =[      $attack2,       shal_attack3    ] {ai_face();};
void() shal_attack3     =[      $attack3,       shal_attack4    ] {ai_face();};
void() shal_attack4     =[      $attack4,       shal_attack5    ] {ai_face();};
void() shal_attack5     =[      $attack5,       shal_attack6    ] {ai_face();};
void() shal_attack6     =[      $attack6,       shal_attack7    ] {monster_setalpha(0.5);ai_face();};
void() shal_attack7     =[      $attack7,       shal_attack8    ] {monster_setalpha(1.0);ai_face();};
void() shal_attack8     =[      $attack8,       shal_attack9    ] {monster_setalpha(1.0);ai_face();};
void() shal_attack9     =[      $attack9,       shal_attack10   ] {monster_setalpha(1.0);ShalMissile();};
void() shal_attack10    =[      $attack10,      shal_attack11   ] {monster_setalpha(1.0);ai_face();};
void() shal_attack11    =[      $attack11,      shal_run1   ] {monster_setalpha(0.0);};

float() shal_missile =
{
	// don't throw if it is blocked
	traceline(self.origin + '0 0 10', self.enemy.origin + '0 0 10', FALSE, self);
	if (trace_ent != self.enemy)
		return FALSE;
	shal_attack1();
	return TRUE;
};

void() shal_pain1       =[      $pain1, shal_pain2      ] {monster_setalpha(1.00);};
void() shal_pain2       =[      $pain2, shal_pain3      ] {monster_setalpha(1.00);};
void() shal_pain3       =[      $pain3, shal_pain4      ] {monster_setalpha(1.00);};
void() shal_pain4       =[      $pain4, shal_pain5      ] {monster_setalpha(0.50);};
void() shal_pain5       =[      $pain5, shal_run1      ] {monster_setalpha(0.00);};

void() shal_death1      =[      $death1,        shal_death2     ] {body_solid('-32 -32 -24', '32 32 32');};
void() shal_death2      =[      $death2,        shal_death3     ] {body_solid('-32 -32 -24', '32 32 20');};
void() shal_death3      =[      $death3,        shal_death4     ] {body_solid('-32 -32 -24', '32 32  6');};
void() shal_death4      =[      $death4,        shal_death5     ] {body_solid('-32 -32 -24', '32 32 -1');};
void() shal_death5      =[      $death5,        shal_death6     ] {body_nonsolid('-32 -32 -24', '32 32 -3');};
void() shal_death6      =[      $death6,        shal_death7     ] {body_nonsolid('-32 -32 -24', '32 32 -4');};
void() shal_death7      =[      $death7,        shal_death7     ] {body_nonsolid('-32 -32 -24', '32 32 -12');}; // -6


void() shalrath_pain =
{
	if (self.pain_finished > time)
		return;

	sound (self, CHAN_VOICE, "shalrath/pain.wav", 1, ATTN_NORM);
	shal_pain1();
	self.pain_finished = time + 3;
};

void() shal_gib =
{
	monster_setalpha(1);
	sound (self, CHAN_VOICE, "player/udeath.wav", 1, ATTN_NORM);
	MonsterGibs("progs/h_shal.mdl", 6, "", 0, "", 0);
};

void() shalrath_die =
{
	monster_setalpha(1);
	sound (self, CHAN_VOICE, "shalrath/death.wav", 1, ATTN_NORM);
	MonsterCorpse(self, shal_death1);
};

/*
================
ShalMissile
================
*/

void() ShalMissileDie =
{
	T_RadiusDamage(self, self.owner, DMG_SHALRATH_MISSILE_DAMAGE, DMG_SHALRATH_MISSILE_FORCE, DMG_SHALRATH_MISSILE_RADIUS, world, self.deathtype, DT_EXPLOSION, Obituary_Generic);
	BecomeExplosion(self, '0.8 0.5 1', FALSE);
};

void() ShalHome =
{
	local vector dir, vtemp;
	vtemp = self.enemy.origin + '0 0 10';
	if (self.enemy.health < 1 || self.enemy.deadflag)
	{
		ShalMissileDie();
		return;
	}
	dir = normalize(vtemp - self.origin);
	// fast
	self.velocity = dir * (150 * skill + 400);
	self.nextthink = time + 0.2;
	self.think = ShalHome;
};

void() ShalMissileTouch =
{
	if (other == self.owner)
		return;		// don't explode on owner
	if (other.classname == "monster_zombie")
		T_Damage (other, self, self, 1000, 1000, self.deathtype, DT_EXPLOSION, self.origin, '0 0 0', Obituary_Generic);
	ShalMissileDie();
};

void() ShalMissile =
{
	local vector dir;
	local float dist;

	// don't throw if it is blocked
	traceline(self.origin + '0 0 10', self.enemy.origin + '0 0 10', FALSE, self);
	if (trace_ent != self.enemy)
		return;

	dir = normalize((self.enemy.origin + '0 0 10') - self.origin);
	dist = vlen (self.enemy.origin - self.origin);

	self.effects = self.effects | EF_MUZZLEFLASH;
	sound (self, CHAN_WEAPON, "shalrath/attack2.wav", 1, ATTN_NORM);

	newmis = spawn ();
	newmis.shoulddodge = TRUE;
	newmis.dangerrating = 60;
	newmis.owner = self;

	newmis.solid = SOLID_BBOX;
	newmis.movetype = MOVETYPE_FLYMISSILE;
	setmodel (newmis, "progs/v_spike.mdl");
	//setsize (newmis, '-16 -16 -16', '16 16 16');
	setsize(newmis, '-1 -1 -1', '1 1 1');
	setorigin(newmis, self.origin + '0 0 10');
	newmis.velocity = dir * 400;
	newmis.avelocity = '300 300 300';
	newmis.nextthink = time;
	newmis.think = ShalHome;
	newmis.enemy = self.enemy;
	newmis.touch = ShalMissileTouch;
	newmis.deathtype = self.deathtype;
	newmis.glow_color = 144;
	newmis.glow_size = 200;
	newmis.health = 50;
	newmis.takedamage = DAMAGE_YES;
	newmis.th_die = ShalMissileDie;
	newmis.havocattack = TRUE;
};

void() shalrath_sightsound =
{
	sound (self, CHAN_VOICE, "shalrath/sight.wav", 1, ATTN_NORM);
};

//=================================================================

void() precachemonster_shalrath =
{
	precache_model2 ("progs/shalrath.mdl");
	precache_model2 ("progs/h_shal.mdl");
	precache_model2 ("progs/v_spike.mdl");

	precache_sound2 ("shalrath/attack.wav");
	precache_sound2 ("shalrath/attack2.wav");
	precache_sound2 ("shalrath/death.wav");
	precache_sound2 ("shalrath/idle.wav");
	precache_sound2 ("shalrath/pain.wav");
	precache_sound2 ("shalrath/sight.wav");
};

/*QUAKED monster_shalrath (1 0 0) (-32 -32 -24) (32 32 48) Ambush
*/
void() monster_shalrath =
{
	if (deathmatch)
	if (!monsterspawn)
	{
		remove(self);
		return;
	}
	if (!self.deathtype) // map makers can override this
		self.deathtype = " was exploded by a shalrath";

	if (!monsterspawn)
		precachemonster_shalrath();

	self.forcescale = 0.3;
	self.netname = "a shalrath";
	// self.doobits = 1;
	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_STEP;

	setmodel (self, "progs/shalrath.mdl");
	setsize (self, '-32 -32 -24', '32 32 32');
	if (!self.health)
		self.health = MH_SHALRATH;
	self.health = self.health;
	self.bodyhealth = self.health + MB_SHALRATH;
	self.bleedratio = 0.75; // alive but tough

	self.th_stand = shal_stand;
	self.th_walk = shal_walk1;
	self.th_run = shal_run1;
	self.th_die = shalrath_die;
	self.th_pain = shalrath_pain;
	self.th_checkattack = GenericCheckAttack;
	self.th_missile = shal_missile;
	self.th_gib = shal_gib;
	self.th_sightsound = shalrath_sightsound;

	walkmonster_start();
	self.radsuit_finished = 99999999; // allow them to travel through slime
};

/*QUAKED dead_shalrath (1 0 0) (-32 -32 -24) (32 32 -12)
*/
void() dead_shalrath =
{
	deadmonstersetup("progs/shalrath.mdl", "progs/h_shal.mdl", shal_death7, 6, 2.5, MB_SHALRATH);
};

