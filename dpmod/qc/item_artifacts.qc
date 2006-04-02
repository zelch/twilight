/*
===============================================================================

POWERUPS

===============================================================================
*/

void() powerup_touch;


void() powerup_touch =
{
	if (other.classname != "player")
		return;
	if (other.health < 1)
		return;

	if (other.flags & FL_CLIENT)
	{
		sprint (other, self.netname);
		stuffcmd(other, "bf\n");
	}

	if (itemrespawn)
	{
		self.mdl = self.model;
		self.nextthink = time + RESPAWNTIME_ARTIFACT;
		self.think = SUB_regen;
	}
	else
	{
		self.think = SUB_Remove;
		self.nextthink = time;
	}

	sound (other, CHAN_VOICE, self.noise, 1, ATTN_NORM);
	self.solid = SOLID_NOT;
	other.items = other.items | self.items;
	self.model = "";

// do the apropriate action
	if (self.items & IT_SUIT)
	{
		other.rad_time = 1;
		other.radsuit_finished = time + 60;
	}

	if (self.items & IT_INVULNERABILITY)
	{
		other.invincible_time = 1;
		other.invincible_finished = time + 30;
	}

	if (self.items & IT_INVISIBILITY)
	{
		other.invisible_time = 1;
		other.invisible_finished = time + 60;
	}

	if (self.items & IT_QUAD)
	{
		other.super_time = 1;
		other.super_damage_finished = time + 30;
	}

	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets
};

// TODO: Nexuiz items

/*QUAKED item_artifact_envirosuit (0 .5 .8) (-16 -16 -24) (16 16 32)
Player takes no damage from
water or slime for 60 seconds
*/
void() item_artifact_envirosuit =
{
	self.touch = powerup_touch;

	precache_model ("progs/suit.mdl");
	precache_sound ("items/suit.wav");
	precache_sound ("items/suit2.wav");
	self.noise = "items/suit.wav";
	setmodel (self, "progs/suit.mdl");
	self.netname = "You got the Biosuit\n";
	self.items = IT_SUIT;
	setsize (self, '-16 -16 -24', '16 16 32');

	StartItem ();
};

// FIXME: bother to compare artifact times?  I think it all balanaces out
// really (when you don't have the artifact, you really want it, when you do
// have one already, you want another simply to deny everyone else the
// artifact and prolong your run a bit longer)
float(entity player, entity item) item_artifact_pickupeval = {return item.dmg;};

/*QUAKED item_artifact_invisibility (0 .5 .8) (-16 -16 -24) (16 16 32)
Player is mostly invisible for 60 seconds.
*/
void() item_artifact_invisibility =
{
	self.touch = powerup_touch;

	precache_model ("progs/invisibl.mdl");
	precache_sound ("items/inv1.wav");
	precache_sound ("items/inv2.wav");
	precache_sound ("items/inv3.wav");
	self.noise = "items/inv1.wav";
	setmodel (self, "progs/invisibl.mdl");
	self.netname = "You got the Ring of Shadows!\n";
	self.items = IT_INVISIBILITY;
	setsize (self, '-16 -16 -24', '16 16 32');

	self.havocpickup = TRUE;
	self.dmg = 5000;
	self.pickupevalfunc = item_artifact_pickupeval;

	StartItem ();
};


/*QUAKED item_artifact_super_damage (0 .5 .8) (-16 -16 -24) (16 16 32)
30 second Quad Damage, 'nuff said.
*/
void() item_artifact_super_damage =
{
	self.touch = powerup_touch;

	precache_model ("progs/quaddama.mdl");
	precache_sound ("items/damage.wav");
	precache_sound ("items/damage2.wav");
	precache_sound ("items/damage3.wav");
	self.noise = "items/damage.wav";
	setmodel (self, "progs/quaddama.mdl");
	self.netname = "You got the Quad Damage!\n";
	self.items = IT_QUAD;
	setsize (self, '-16 -16 -24', '16 16 32');

	self.havocpickup = TRUE;
	self.dmg = 5000;
	self.pickupevalfunc = item_artifact_pickupeval;

	StartItem ();
};

/*QUAKED item_artifact_invulnerability (0 .5 .8) (-16 -16 -24) (16 16 32)
Player is invulnerable for 30 seconds
*/
void() item_artifact_invulnerability =
{
	self.touch = powerup_touch;

	precache_model ("progs/invulner.mdl");
	precache_sound ("items/protect.wav");
	precache_sound ("items/protect2.wav");
	precache_sound ("items/protect3.wav");
	self.noise = "items/protect.wav";
	setmodel (self, "progs/invulner.mdl");
	self.netname = "You got the Pentagram of Protection!\n";
	self.items = IT_INVULNERABILITY;
	setsize (self, '-16 -16 -24', '16 16 32');

	self.havocpickup = TRUE;
	self.dmg = 10000;
	self.pickupevalfunc = item_artifact_pickupeval;

	StartItem ();
};
