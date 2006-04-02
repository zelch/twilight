
/*
Exploding Walls
*/

float XWALL_NOHEAL = 1;
float XWALL_SILVERKEY = 2;
float XWALL_GOLDKEY = 4;

void() xwall_break;
void() xwall_heal;
void() xwall_keytouch;

void() xwall_respawn =
{
	self.solid = SOLID_BSP;
	self.movetype = MOVETYPE_PUSH;
	setorigin (self, self.origin);
	setmodel (self, self.mdl);

	self.use = xwall_break;
	if (self.max_health >= 1)
	{
		self.takedamage = DAMAGE_YES;
		self.th_die = xwall_break;
		if (self.spawnflags & XWALL_NOHEAL)
			self.th_pain = SUB_Null;
		else
			self.th_pain = xwall_heal;
	}
	else
		self.takedamage = DAMAGE_NO;

	if (self.items)
		self.touch = xwall_keytouch;
	else
		self.touch = SUB_Null;
};

void() xwall_hidethink;

void() xwall_breakthink =
{
	local float t, r, t2, t3;
	local vector v, v2;
	local entity ts;
	self.think = xwall_breakthink;
	self.nextthink = time + self.owner.delay;
	t = 0; // give up the search after 20 failures
	while (t < 20)
	{
		v = randompos(self.absmin, self.absmax);
		t = t + 1;
		if (pointcontents(v) != CONTENT_SOLID) // found a spot
			t = 1000000;
	}

	t3 = TRUE; // pick a new location for each piece of rubble
	if (self.cnt2 > 0)
	{
		t3 = FALSE; // spawn rubble from each explosion
		self.cnt2 = self.cnt2 - 1;
		newmis = spawn();
		newmis.owner = self.owner;
		setorigin(newmis, v);
		T_RadiusDamage(newmis, newmis.owner, newmis.owner.dmg, newmis.owner.dmg, newmis.owner.dmg, world, self.deathtype, DT_EXPLOSION, Obituary_Generic);
		BecomeExplosion(newmis, '0 0 0', FALSE);
	}
	t2 = floor(self.cnt);
	self.cnt = self.cnt + self.count;
	r = floor(random()*3);
	while (t2 < self.cnt)
	{
		t2 = t2 + 1;
		if (t3) // pick a new location for each piece of rubble
		{
			t = 0; // give up the search after 20 failures
			while (t < 20)
			{
				v = randompos(self.absmin, self.absmax);
				t = t + 1;
				if (pointcontents(v) != CONTENT_SOLID) // found a spot
					t = 1000000;
			}
		}
		v2 = randomvec() * (self.owner.dmg + 20) * 3 + '0 0 120';
		if (r == 0) ThrowDebris(world, v, v2, "progs/rubble1.mdl", self.owner.style);
		if (r == 1) ThrowDebris(world, v, v2, "progs/rubble2.mdl", self.owner.style);
		if (r == 2) ThrowDebris(world, v, v2, "progs/rubble3.mdl", self.owner.style);
		r = r + 1;
		if (r >= 3)
			r = 0;
	}
	if (self.cnt2 < 1)
	{
		ts = self;
		self = self.owner;
		if (self.use == SUB_Null)
		xwall_hidethink();
		self = ts;
		remove(self);
	}
};

void() xwall_hidethink =
{
	SUB_UseTargets();
	self.solid = SOLID_NOT;
	self.movetype = MOVETYPE_NONE;
	setorigin(self, self.origin); // relink
	self.model = "";
	self.modelindex = 0;
	self.think = xwall_respawn;
	if (self.wait > 0)
		self.nextthink = time + self.wait;
	else
		remove(self);
};

void() xwall_break =
{
	local entity e;
	if (self.use == SUB_Null)
		return;
	e = spawn();
	e.owner = self;
	e.solid = SOLID_NOT;
	e.movetype = MOVETYPE_NONE;
	setorigin(e, '0 0 0');
	setsize(e, self.absmin - '16 16 16', self.absmax + '16 16 16');
	e.think = xwall_breakthink;
	e.nextthink = time + 0.1;
	e.cnt = 0;
	e.cnt2 = self.count2;
	e.count = self.count;
	e.count2 = self.count2;
	self.think = xwall_hidethink;
	self.nextthink = time + (self.delay * self.count2);
	self.takedamage = DAMAGE_NO;
	self.th_pain = SUB_Null;
	self.th_die = SUB_Null;
	self.touch = SUB_Null;
	self.use = SUB_Null;
};


void() xwall_heal =
{
	self.health = self.max_health;
};

void() xwall_keytouch =
{
	if (!self.items)
		return;
	if (time < self.lefty) // uh, didn't want to add a new entity field
		return;
	self.lefty = time + 2;
	if (other.classname != "player")
		return;

	// FIXME: blink key on player's status bar
	if ( (self.items & other.items) != self.items )
	{
		if (self.items == IT_KEY1)
		{
			if (world.worldtype == 2)
			{
				if (other.flags & FL_CLIENT)
					centerprint (other, "You need the silver keycard");
				sound (self, CHAN_VOICE, self.noise3, 1, ATTN_NORM);
			}
			else if (world.worldtype == 1)
			{
				if (other.flags & FL_CLIENT)
					centerprint (other, "You need the silver runekey");
				sound (self, CHAN_VOICE, self.noise3, 1, ATTN_NORM);
			}
			else if (world.worldtype == 0)
			{
				if (other.flags & FL_CLIENT)
					centerprint (other, "You need the silver key");
				sound (self, CHAN_VOICE, self.noise3, 1, ATTN_NORM);
			}
			else if (world.worldtype == 5)
			{
				if (other.flags & FL_CLIENT)
					centerprint (other, "You need the silver keycard");
				sound (self, CHAN_VOICE, self.noise3, 1, ATTN_NORM);
			}
			else if (world.worldtype == 4)
			{
				if (other.flags & FL_CLIENT)
					centerprint (other, "You need the silver runekey");
				sound (self, CHAN_VOICE, self.noise3, 1, ATTN_NORM);
			}
			else if (world.worldtype == 3)
			{
				if (other.flags & FL_CLIENT)
					centerprint (other, "You need the silver key");
				sound (self, CHAN_VOICE, self.noise3, 1, ATTN_NORM);
			}
		}
		else
		{
			if (world.worldtype == 2)
			{
				if (other.flags & FL_CLIENT)
					centerprint (other, "You need the gold keycard");
				sound (self, CHAN_VOICE, self.noise3, 1, ATTN_NORM);
			}
			else if (world.worldtype == 1)
			{
				if (other.flags & FL_CLIENT)
					centerprint (other, "You need the gold runekey");
				sound (self, CHAN_VOICE, self.noise3, 1, ATTN_NORM);
			}
			else if (world.worldtype == 0)
			{
				if (other.flags & FL_CLIENT)
					centerprint (other, "You need the gold key");
				sound (self, CHAN_VOICE, self.noise3, 1, ATTN_NORM);
			}
			if (world.worldtype == 5)
			{
				if (other.flags & FL_CLIENT)
					centerprint (other, "You need the gold keycard");
				sound (self, CHAN_VOICE, self.noise3, 1, ATTN_NORM);
			}
			else if (world.worldtype == 4)
			{
				if (other.flags & FL_CLIENT)
					centerprint (other, "You need the gold runekey");
				sound (self, CHAN_VOICE, self.noise3, 1, ATTN_NORM);
			}
			else if (world.worldtype == 3)
			{
				if (other.flags & FL_CLIENT)
					centerprint (other, "You need the gold key");
				sound (self, CHAN_VOICE, self.noise3, 1, ATTN_NORM);
			}
		}
		return;
	}

	// take away 1 key
	if (self.items == IT_KEY1 && other.keys_silver > 0)
		other.keys_silver = other.keys_silver - 1;
	if (self.items == IT_KEY2 && other.keys_gold > 0)
		other.keys_gold = other.keys_gold - 1;

	// kill the key on scorebar if the player is now out of keys
	if (other.keys_silver < 1)
		other.items = other.items - (other.items & IT_KEY1);
	if (other.keys_gold < 1)
		other.items = other.items - (other.items & IT_KEY2);

	self.touch = SUB_Null;

	sound (self, CHAN_VOICE, self.noise4, 1, ATTN_NORM);

	xwall_break ();
};

/*
=============================================================================

SPAWNING FUNCTIONS

=============================================================================
*/

/*QUAKED func_xplowall (0 .5 .8) ? NoHeal SilverKey GoldKey

Normally you must do enough damage
in one blast to break the wall.

Flags:
"NoHeal"
 progressive damage will break
 this wall.
"SilverKey"
 will break if touched by player
 with silver key.
"GoldKey"
 will break if touched by player
 with gold key.

Keys:
"targetname"
 will break if targeted.
"target"
 will trigger when destroyed.
"health"
 if health is -1 then can only be
 broken by targeting and keys,
 default 100
 (close pipebomb will break).
"dmg"
 explosions do this much radius
 damage if set.
"count"
 how many pieces of debris
 (releases this much debris
  total, some every explosion)
 (default is 5, -1 for no debris)
"count2"
 how many explosions
 (will release debris with none)
 (default is 3, use -1 for none)
"delay"
 time between explosions
 default: 0.1
"wait"
 time before respawning
 (default is no respawn)
 (this time is counted from the
  last explosion)
"style"
 type of debris,
 hard to describe these:
0) red
1) yellow
2) green
3) blue
4) brown
5) biege
6) rock
*/

void() func_xplowall =
{
	if (!self.deathtype) // map makers can override this
		self.deathtype = " was splattered by a wall";
	if (!self.count)
		self.count = 5;
	if (!self.count2)
		self.count2 = 5;
	if (self.delay < 0.1)
		self.delay = 0.1;
	if (!self.health)
		self.health = 100;

	if (self.count2 >= 1)
		self.count = self.count / self.count2;

	precache_sound ("weapons/r_exp3.wav");
	precache_model ("progs/rubble1.mdl");
	precache_model ("progs/rubble2.mdl");
	precache_model ("progs/rubble3.mdl");

	self.mdl = self.model;
	self.max_health = self.health;

	if (self.spawnflags & XWALL_SILVERKEY)
		self.items = IT_KEY1;
	if (self.spawnflags & XWALL_GOLDKEY)
		self.items = IT_KEY2;
	if (self.items)
	if (game != GAME_NEXUIZ)
	{
		if (world.worldtype == 0)
		{
			precache_sound ("doors/medtry.wav");
			precache_sound ("doors/meduse.wav");
			self.noise3 = "doors/medtry.wav";
			self.noise4 = "doors/meduse.wav";
		}
		else if (world.worldtype == 1)
		{
			precache_sound ("doors/runetry.wav");
			precache_sound ("doors/runeuse.wav");
			self.noise3 = "doors/runetry.wav";
			self.noise4 = "doors/runeuse.wav";
		}
		else if (world.worldtype == 2)
		{
			precache_sound ("doors/basetry.wav");
			precache_sound ("doors/baseuse.wav");
			self.noise3 = "doors/basetry.wav";
			self.noise4 = "doors/baseuse.wav";
		}
		else if (world.worldtype == 3)
		{
			precache_sound ("doors/medtry.wav");
			precache_sound ("doors/meduse.wav");
			self.noise3 = "doors/medtry.wav";
			self.noise4 = "doors/meduse.wav";
		}
		else if (world.worldtype == 4)
		{
			precache_sound ("doors/runetry.wav");
			precache_sound ("doors/runeuse.wav");
			self.noise3 = "doors/runetry.wav";
			self.noise4 = "doors/runeuse.wav";
		}
		else if (world.worldtype == 5)
		{
			precache_sound ("doors/basetry.wav");
			precache_sound ("doors/baseuse.wav");
			self.noise3 = "doors/basetry.wav";
			self.noise4 = "doors/baseuse.wav";
		}
		else
			dprint ("no worldtype set!\n");
	}

	xwall_respawn();
};

/*QUAKED func_wallchunk (0 .5 .8) ?
wall chunk, destroyed by damage.

you must do enough damage
in one blast to break the wall.

simply a nice effect,
used in Dark Places maps.

make a hole in the wall,
cover it with a
func_wallchunk,
set the style for debris,
and you've got a wall that
gets damaged in a fight.

actually just a simplified
func_xplowall.

normally 3 pieces of debris.
set count to a dif # if you
like.
no explosions.

Keys:
"count"
 how many pieces of debris.
 default is 3.
"style"
 type of debris,
 hard to describe these:
0) red
1) yellow
2) green
3) blue
4) brown
5) biege
6) rock
*/

void() func_wallchunk =
{
	self.spawnflags = XWALL_NOHEAL;
	if (self.count == 0)
		self.count = 5;
	self.count2 = -1;
	self.health = 150;
	func_xplowall();
};



