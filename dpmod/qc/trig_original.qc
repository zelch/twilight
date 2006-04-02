
void() trigger_reactivate =
{
	self.solid = SOLID_TRIGGER;
};

//=============================================================================

float SPAWNFLAG_NOMESSAGE = 1;
float SPAWNFLAG_NOTOUCH = 1;

// the wait time has passed, so set back up for another activation
void() multi_wait =
{
	if (self.max_health)
	{
		self.health = self.max_health;
		self.takedamage = DAMAGE_YES;
		self.solid = SOLID_BBOX;
	}
};


// the trigger was just touched/killed/used
// self.enemy should be set to the activator so it can be held through a delay
// so wait for the delay time before firing
void() multi_trigger =
{
	if (self.nextthink > time)
		return;         // already triggered

	if (self.classname == "trigger_secret")
	{
		if (self.enemy.classname != "player")
			return;
		found_secrets = found_secrets + 1;
		WriteByte (MSG_ALL, SVC_FOUNDSECRET);
	}

	if (self.noise)
		sound (self, CHAN_VOICE, self.noise, 1, ATTN_NORM);

// don't trigger again until reset
	self.takedamage = DAMAGE_NO;

	activator = self.enemy;

	SUB_UseTargets();

	if (self.wait > 0)
	{
		self.think = multi_wait;
		self.nextthink = time + self.wait;
	}
	else
	{	// we can't just remove (self) here, because this is a touch function
		// called while C code is looping through area links...
		self.touch = SUB_Null;
		self.nextthink = time + 0.1;
		self.think = SUB_Remove;
	}
};

void() multi_killed =
{
	self.enemy = damage_attacker;
	multi_trigger();
};

void() multi_use =
{
	self.enemy = activator;
	multi_trigger();
};

void() multi_touch =
{
	//if (other.classname != "player")
	if (!other.cantrigger)
		return;

// if the trigger has an angles field, check player's facing direction
	if (self.movedir != '0 0 0')
	{
		makevectors (other.angles);
		if (v_forward * self.movedir < 0)
			return;		// not facing the right way
	}

	self.enemy = other;
	multi_trigger ();
};

/*QUAKED trigger_multiple (.5 .5 .5) ? notouch
Variable sized repeatable trigger.  Must be targeted at one or more entities.  If "health" is set, the trigger must be killed to activate each time.
If "delay" is set, the trigger waits some time after activating before firing.
"wait" : Seconds between triggerings. (.2 default)
If notouch is set, the trigger is only fired by other entities, not by touching.
NOTOUCH has been obsoleted by trigger_relay!
sounds
1)	secret
2)	beep beep
3)	large switch
4)
set "message" to text string
*/
void() trigger_multiple =
{
	if (self.sounds == 1)
	{
		precache_sound ("misc/secret.wav");
		self.noise = "misc/secret.wav";
	}
	else if (self.sounds == 2)
	{
		precache_sound ("misc/talk.wav");
		self.noise = "misc/talk.wav";
	}
	else if (self.sounds == 3)
	{
		precache_sound ("misc/trigger1.wav");
		self.noise = "misc/trigger1.wav";
	}

	if (!self.wait)
		self.wait = 0.2;
	self.use = multi_use;

	InitTrigger ();

	if (self.health)
	{
		if (self.spawnflags & SPAWNFLAG_NOTOUCH)
			objerror ("trigger_multiple or trigger_once: health and notouch don't make sense\n");
		self.max_health = self.health;
		self.th_die = multi_killed;
		self.takedamage = DAMAGE_YES;
		self.solid = SOLID_BBOX;
		setorigin (self, self.origin);	// make sure it links into the world
	}
	else if (!(self.spawnflags & SPAWNFLAG_NOTOUCH))
		self.touch = multi_touch;
};

void() trigger_message2 =
{
	self.noise = "misc/talk.wav";
	precache_sound (self.noise);

	if (!self.wait)
		self.wait = 0.2;
	self.use = multi_use;

	if (self.movedir == '0 0 0')
	if (self.angles != '0 0 0')
		SetMovedir ();
	self.solid = SOLID_TRIGGER;
	self.movetype = MOVETYPE_NONE;
	setsize (self, self.mins, self.maxs);

	self.touch = multi_touch;
};


/*QUAKED trigger_once (.5 .5 .5) ? notouch
Variable sized trigger. Triggers once, then removes itself.  You must set the key "target" to the name of another object in the level that has a matching
"targetname".  If "health" is set, the trigger must be killed to activate.
If notouch is set, the trigger is only fired by other entities, not by touching.
if "killtarget" is set, any objects that have a matching "target" will be removed when the trigger is fired.
if "angle" is set, the trigger will only fire when someone is facing the direction of the angle.  Use "360" for an angle of 0.
sounds
1)	secret
2)	beep beep
3)	large switch
4)
set "message" to text string
*/
void() trigger_once =
{
	self.wait = -1;
	trigger_multiple();
};

//=============================================================================

/*QUAKED trigger_relay (.5 .5 .5) (-8 -8 -8) (8 8 8)
This fixed size trigger cannot be touched, it can only be fired by other events.  It can contain killtargets, targets, delays, and messages.
*/
void() trigger_relay =
{
	self.use = SUB_UseTargets;
};


//=============================================================================

/*QUAKED trigger_secret (.5 .5 .5) ?
secret counter trigger
sounds
1)	secret
2)	beep beep
3)
4)
set "message" to text string
*/
void() trigger_secret =
{
	total_secrets = total_secrets + 1;
	self.wait = -1;
	if (!self.message)
		self.message = "You found a secret area!";
	if (!self.sounds)
		self.sounds = 1;

	if (self.sounds == 1)
	{
		precache_sound ("misc/secret.wav");
		self.noise = "misc/secret.wav";
	}
	else if (self.sounds == 2)
	{
		precache_sound ("misc/talk.wav");
		self.noise = "misc/talk.wav";
	}

	trigger_multiple ();
};

//=============================================================================


void() counter_use =
{
	self.count = self.count - 1;
	if (self.count < 0)
		return;

	if (self.count != 0)
	{
		if ((activator.flags & FL_CLIENT) && (self.spawnflags & SPAWNFLAG_NOMESSAGE) == 0)
		{
			if (self.count >= 4)
				centerprint (activator, "There are more to go...");
			else if (self.count == 3)
				centerprint (activator, "Only 3 more to go...");
			else if (self.count == 2)
				centerprint (activator, "Only 2 more to go...");
			else
				centerprint (activator, "Only 1 more to go...");
		}
		return;
	}

	if ((activator.flags & FL_CLIENT) && (self.spawnflags & SPAWNFLAG_NOMESSAGE) == 0)
		centerprint(activator, "Sequence completed!");
	self.enemy = activator;
	multi_trigger ();
};

/*QUAKED trigger_counter (.5 .5 .5) ? nomessage
Acts as an intermediary for an action that takes multiple inputs.

If nomessage is not set, t will print "1 more.. " etc when triggered and "sequence complete" when finished.

After the counter has been triggered "count" times (default 2), it will fire all of it's targets and remove itself.
*/
void() trigger_counter =
{
	self.wait = -1;
	if (!self.count)
		self.count = 2;

	self.use = counter_use;
};


/*
==============================================================================

TELEPORT TRIGGERS

==============================================================================
*/

float PLAYER_ONLY	= 1;
float SILENT = 2;

void() play_teleport =
{
	local float v;
	local string tmpstr;

	v = random() * 5;
	if (v < 1)
		tmpstr = "misc/r_tele1.wav";
	else if (v < 2)
		tmpstr = "misc/r_tele2.wav";
	else if (v < 3)
		tmpstr = "misc/r_tele3.wav";
	else if (v < 4)
		tmpstr = "misc/r_tele4.wav";
	else
		tmpstr = "misc/r_tele5.wav";

	sound (self, CHAN_VOICE, tmpstr, 1, ATTN_NORM);
	remove (self);
};

void(vector org) spawn_tfog =
{
	local entity s;
	s = spawn ();
	s.nextthink = time + 0.2;
	s.think = play_teleport;
	setorigin(s, org);

	te_teleport(org);
};

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_Telefrag =
{
	if (dtype == DTYPE_TEAMKILL)
	{
		deathstring1 = targ.netname;
		deathstring2 = " was telefragged by his teammate ";
		deathstring3 = attacker.netname;
		deathstring4 = "";
	}
	else
	{
		deathstring1 = targ.netname;
		deathstring2 = " was telefragged by ";
		deathstring3 = attacker.netname;
		deathstring4 = "";
	}
};

void(entity targ, entity attacker, string dmsg, float dtype) Obituary_TriedToTelefrag =
{
	if (dtype == DTYPE_TEAMKILL)
	{
		deathstring1 = targ.netname;
		deathstring2 = "'s telefrag was deflected by his teammate ";
		deathstring3 = attacker.netname;
		deathstring4 = "";
	}
	else
	{
		deathstring1 = targ.netname;
		deathstring2 = "'s telefrag was deflected by ";
		deathstring3 = attacker.netname;
		deathstring4 = "";
	}
};

float chthonisdead; // set when chthon dies
void() tdeath_touch =
{
	if (chthonisdead) // fix the chthon gib scene
	if ((self.owner.health < 1) || (self.owner.flags & FL_MONSTER))
	{
		T_Damage (self.owner, self, world, 0, 0, " gibbed", DT_TELEFRAG, self.owner.origin, '0 0 0', Obituary_Generic);
		return;
	}
	if (other == self.owner)
		return;
	// so teleporting shots etc can't telefrag
	if (!self.owner.takedamage)
		return;
	if (!other.takedamage)
		return;
	//if (other.solid == SOLID_TRIGGER) // big bug in quake engine...  crashs if other is removed during a collision
	//	return;
	if ((self.owner.classname == "player") && (self.owner.health >= 1))
	{
		/*
		if (other.classname == "player")
		{
			if (self.dest2 != '0 0 0')
			{
				setorigin(self.owner, self.dest2);
				self.owner.velocity = '0 0 0' - self.owner.velocity;
				spawn_tfog(self.owner.origin);
			}
			else
				T_Damage (self.owner, self, other, 0, 0, "TRIEDTOTELEFRAG", DT_TELEFRAG, self.owner.origin, '0 0 0', Obituary_TriedToTelefrag);
		}
		else
		*/
			T_Damage (other, self, self.owner, 0, 0, "TELEFRAG", DT_TELEFRAG, other.origin, '0 0 0', Obituary_Telefrag);
	}
	else if (other.health < 1) // corpses gib
		T_Damage (other, self, self.owner, 0, 0, "TELEFRAG", DT_TELEFRAG, other.origin, '0 0 0', Obituary_Telefrag);
	else // dead bodies and monsters gib themselves instead of telefragging
		T_Damage (self.owner, self, other, 0, 0, "TRIEDTOTELEFRAG", DT_TELEFRAG, self.owner.origin, '0 0 0', Obituary_TriedToTelefrag);
};

// org2 is where they will return to if the teleport fails
void(vector org, entity death_owner, vector org2) spawn_tdeath =
{
	local entity death;

	death = spawn();
//	death.classname = "teledeath";
	death.movetype = MOVETYPE_NONE;
	death.solid = SOLID_TRIGGER;
	death.angles = '0 0 0';
	death.dest2 = org2;
	setsize (death, death_owner.mins - '1 1 1', death_owner.maxs + '1 1 1');
	setorigin (death, org);
	death.touch = tdeath_touch;
	death.nextthink = time + 0.2;
	death.think = SUB_Remove;
	death.owner = death_owner;

	force_retouch = 2;		// make sure even still objects get hit
};

.float monsterawaitingteleport;

void() teleport_changevelocityent =
{
	if (self.owner.solid) // make sure it still exists
		self.owner.velocity = self.dest;
	remove(self);
};

void() teleport_touch =
{
	local entity t;

	//if (!other.takedamage)
	//        return;
	if (self.targetname)
	if (self.nextthink < time)
	{
		if (world.worldtype < 3) // normal quake maps
		if (other.flags & FL_MONSTER) // it's a monster
		if ((self.spawnflags & PLAYER_ONLY) == 0) // not player only
			other.monsterawaitingteleport = TRUE; // freeze it
		return;         // not fired yet
	}

	if (self.spawnflags & PLAYER_ONLY)
	if (other.classname != "player")
		return;

	// only teleport living creatures
	if (other.health < 1)
		return;
	if (other.solid != SOLID_SLIDEBOX)
		return;
	if (other.movetype == MOVETYPE_NONE || other.movetype == MOVETYPE_PUSH || other.solid == SOLID_NOT)
		return;

	other.monsterawaitingteleport = FALSE; // unfreeze monster AI

	SUB_UseTargets ();

	// put a tfog where the player was
	spawn_tfog (other.origin);

	t = find(world, targetname, self.target);
	if (!t)
		objerror ("trigger_teleport: couldn't find target");

	// spawn a tfog flash in front of the destination
	makevectors (t.mangle);
	//org = t.origin + 32 * v_forward;

	spawn_tfog (t.origin); //org);
	spawn_tdeath(t.origin, other, other.origin);

	// move the player and lock him down for a little while
	setorigin (other, t.origin);
	// LordHavoc: made all things behave the same
	newmis = spawn();
	newmis.think = teleport_changevelocityent;
	newmis.nextthink = time + 0.01;
	newmis.owner = other;
	//if (other.teleportsavevelocity)
	//	other.velocity = other.teleportsavevelocity;
	if (other.health < 1)
	{
		other.origin = t.origin;
		other.velocity = (v_forward * other.velocity_x) - (v_right * other.velocity_y) + (v_up * other.velocity_z) + self.dest;
		newmis.velocity = other.velocity;
		other.flags = other.flags - (other.flags & FL_ONGROUND);
		return;
	}
	other.velocity = t.dest;
	newmis.velocity = other.velocity;

	other.angles = t.mangle;
	if (other.classname == "player")
	{
		other.fixangle = 1;		// turn this way immediately

		/*
		// clear the waypoint info (just useful for the bots)
		other.enemy = world;
		other.goalentity = world;
		other.looktime = 0;
		*/

		other.teleport_time = time + 0.5;
		//other.velocity = t.dest;
	}
	other.flags = other.flags - (other.flags & FL_ONGROUND);
};

/*QUAKED info_teleport_destination (.5 .5 .5) (-8 -8 -8) (8 8 32)
This is the destination
marker for a teleporter.

It should have a
"targetname" field with
the same value as a
teleporter's "target"
field.

Keys:
"dest"
 velocity on exiting
 teleport, nice for
 tricks.
 default: normal
 (throws player out
  a bit)
*/
void() info_teleport_destination =
{
	// this does nothing, just serves as a target spot
	self.mangle = self.angles;
	self.angles = '0 0 0';
	self.model = "";
	setorigin(self, self.origin + '0 0 27');
	if (!self.targetname)
		objerror ("no targetname");
	if (self.dest == '0 0 0') // the usual
	{
		makevectors(self.mangle);
		self.dest = v_forward * 200; //300;
	}
};

void() teleport_use =
{
	self.nextthink = time + 0.2;
	force_retouch = 2;              // make sure even still objects get hit
	self.think = SUB_Null;
	/*
	self.solid = SOLID_BSP;
	self.movetype = MOVETYPE_PUSH;
	setmodel(self, self.mdl);
	self.model = "";
	*/
};

/*QUAKED trigger_teleport (.5 .5 .5) ? PLAYER_ONLY SILENT
Any object touching this will be transported to the corresponding info_teleport_destination entity. You must set the "target" field, and create an object with a "targetname" field that matches.

If the trigger_teleport has a targetname, it will only teleport entities when it has been fired.
*/
void() trigger_teleport =
{
	self.mdl = self.model;
	if (deathmatch) // teleporters teleport shots in DM :)
	{
		if (self.targetname)
			InitTrigger ();
		else
			InitSolidBSPTrigger ();
	}
	else
		InitTrigger ();
	self.touch = teleport_touch;
	// find the destination
	if (!self.target)
		objerror ("trigger_teleport: no target");
	self.use = teleport_use;

	if (!(self.spawnflags & SILENT))
	{
		precache_sound ("ambience/hum1.wav");
		ambientsound ((self.absmin + self.absmax)*0.5, "ambience/hum1.wav",0.5 , ATTN_STATIC);
	}
};

void() trigger_teleport2 =
{
	if (self.movedir == '0 0 0')
	if (self.angles != '0 0 0')
		SetMovedir ();
	self.solid = SOLID_TRIGGER;
	self.movetype = MOVETYPE_NONE;
	setsize (self, self.mins, self.maxs);

	self.touch = teleport_touch;
	if (!self.target)
		objerror ("trigger_teleport2: no target");
	self.use = teleport_use;

	if (!(self.spawnflags & SILENT))
	{
		precache_sound ("ambience/hum1.wav");
		ambientsound (self.origin, "ambience/hum1.wav", 0.5, ATTN_STATIC);
	}
};

/*
==============================================================================

trigger_setskill

==============================================================================
*/

void() trigger_skill_touch =
{
	if (other.classname != "player")
		return;

	cvar_set ("skill", self.message);
};

/*QUAKED trigger_setskill (.5 .5 .5) ?
sets skill level to the value of "message".
Only used on start map.
*/
void() trigger_setskill =
{
	InitTrigger ();
	self.touch = trigger_skill_touch;
};

void() trigger_setskill2 =
{
	if (self.movedir == '0 0 0')
	if (self.angles != '0 0 0')
		SetMovedir ();
	self.solid = SOLID_TRIGGER;
	self.movetype = MOVETYPE_NONE;
	setsize (self, self.mins, self.maxs);
	self.touch = trigger_skill_touch;
};

/*
==============================================================================

ONLY REGISTERED TRIGGERS

==============================================================================
*/

void() trigger_onlyregistered_touch =
{
	if (other.classname != "player")
		return;
	if (self.attack_finished > time)
		return;

	self.attack_finished = time + 2;
	if (cvar("registered"))
	{
		self.message = "";
		SUB_UseTargets ();
		remove (self);
	}
	else
	{
		if (self.message != "")
		{
			if (other.flags & FL_CLIENT)
				centerprint (other, self.message);
			sound (other, CHAN_BODY, "misc/talk.wav", 1, ATTN_NORM);
		}
	}
};

/*QUAKED trigger_onlyregistered (.5 .5 .5) ?
Only fires if playing the registered version, otherwise prints the message
*/
void() trigger_onlyregistered =
{
	precache_sound ("misc/talk.wav");
	InitTrigger ();
	self.touch = trigger_onlyregistered_touch;
};

//============================================================================


void( entity ent, float amount ) hurt_setdamage =
{
	ent.dmg = amount;
	if (!amount)
		ent.solid = SOLID_NOT;
	else
		ent.solid = SOLID_TRIGGER;
	ent.nextthink = -1;
};

void() hurt_on =
{
	self.solid = SOLID_TRIGGER;
	self.nextthink = -1;
};

void() hurt_touch =
{
	if (other.takedamage)
	{
		self.solid = SOLID_NOT;
		T_Damage (other, self, self, self.dmg, self.dmg, self.deathtype, DT_HURT, (self.absmin + self.absmax) * 0.5, '0 0 0', Obituary_Generic);
		self.think = hurt_on;
		self.nextthink = time + 1;
		if (self.cnt > 0)
		{
			self.cnt = self.cnt - 1;
			if (self.cnt == 0)
			{
				self.touch = SUB_Null;
				self.nextthink = time + 0.1;
				self.think = SUB_Remove;
			}
		}
	}
	return;
};

/*QUAKED trigger_hurt (.5 .5 .5) ?
Anything touching will be hurt.

Keys:
"dmg"
 damage amount
 default: 5
"cnt"
 how many times to trigger,
 default: unlimited
*/
void() trigger_hurt =
{
	if (!self.deathtype) // map makers can override this
		self.deathtype = " died";
	InitTrigger ();
	self.touch = hurt_touch;
	if (!self.dmg)
		self.dmg = 5;
};

//============================================================================

float PUSH_ONCE = 1;
float PUSH_SILENT = 2;

void() target_position = {};

void() trigger_push_touch =
{
	local float flighttime, dist, grav;
	local vector org, v;
	if (other.movetype == MOVETYPE_NONE || other.movetype == MOVETYPE_PUSH)
		return;
	other.flags = other.flags - (other.flags & FL_ONGROUND);
	other.velocity = self.movedir;
	if (self.enemy)
	{
		/*
		// old code for hitting a target landing spot
		if (self.wait) // flight time
			t = self.wait;
		else
			t = vlen(self.enemy.origin - other.origin) / self.speed - 0.1;
		// direct path, with boost to counter gravity
		other.velocity = (self.enemy.origin - other.origin) * (1 / t) + '0 0 1' * (t * t * cvar("sv_gravity"));
		*/

		// start point
		org = other.origin;

		// figure out how long it will take to hit the point considering gravity
		grav = cvar("sv_gravity");
		flighttime = sqrt((self.enemy.origin_z - org_z) / (0.5 * grav));
		if (!flighttime)
		{
			remove(self);
			return;
		}

		// how far in X and Y to move
		v = (self.enemy.origin - org);
		v_z = 0;
		dist = vlen(v);

		// finally calculate the velocity
		other.velocity = normalize(v) * (dist / flighttime);
		other.velocity_z = flighttime * grav;
	}
	else
		other.velocity = self.movedir;
	if (self.noise != "")
	if (other.classname == "player" || (other.flags & FL_MONSTER))
	if (other.fly_sound < time)
	{
		if (self.target)
		{
			other.fly_sound = time + 0.2;
			if (game == GAME_NEXUIZ)
				sound (other, CHAN_BODY, "level/jumppad.wav", 1, ATTN_NORM);
			else
				sound (other, CHAN_BODY, "player/plyrjmp8.wav", 1, ATTN_NORM);
		}
		else
		{
			other.fly_sound = time + 1.5;
			sound (other, CHAN_AUTO, "ambience/windfly.wav", 1, ATTN_NORM);
		}
	}
	if (self.spawnflags & PUSH_ONCE)
	{
		self.touch = SUB_Null;
		self.think = SUB_Remove;
		self.nextthink = time;
	}
};

void() trigger_push_findtarget =
{
	// find the target
	self.enemy = find(world, targetname, self.target);
	if (!self.enemy)
		objerror("trigger_push: target not found\n");
};

/*QUAKED trigger_push (.5 .5 .5) ? PUSH_ONCE SILENT
Improved version of normal trigger_push.

Pushes anything that touches it,
or acts as a jump pad, hitting "target"
at the apogee (peak) of the jump.

Target should be an info_notnull.

Flags:
"PUSH_ONCE"
 removes itself after push
"SILENT"
 no 'windtunnel' noise
Keys:
"angles"
 direction to push.
 (not for jumppad)
"speed"
 how fast.
 (not for jumppad)
"movedir"
 direction of push,
 this is turned into
 a direction. (no speed)
 (not for jumppad)
"target"
 acts as jump pad, hits this entity
*/
void() trigger_push =
{
	InitTrigger ();
	if (!(self.spawnflags & PUSH_SILENT))
	{
		if (self.target)
		{
			if (game == GAME_NEXUIZ)
				self.noise = "level/jumppad.wav";
			else
				self.noise = "player/plyrjmp8.wav";
		}
		else
			self.noise = "ambience/windfly.wav";
	}
	if (self.noise != "")
		precache_sound (self.noise);
	self.touch = trigger_push_touch;
	if (!self.speed)
		self.speed = 1000;
	self.movedir = self.movedir * self.speed * 10; // why the * 10 I dunno...
	if (self.target)
	{
		self.think = trigger_push_findtarget;
		self.nextthink = time + 0.2;
	}
};

//============================================================================

void() trigger_monsterjump_touch =
{
	if ( other.flags & (FL_MONSTER | FL_FLY | FL_SWIM) != FL_MONSTER )
		return;

// set XY even if not on ground, so the jump will clear lips
	other.velocity_x = self.movedir_x * self.speed;
	other.velocity_y = self.movedir_y * self.speed;

	if ( !(other.flags & FL_ONGROUND) )
		return;

	other.flags = other.flags - FL_ONGROUND;

	other.velocity_z = self.height;
};

/*QUAKED trigger_monsterjump (.5 .5 .5) ?
Walking monsters touching
this will jump in the
direction of the angle.

Keys:
"speed"
 horizontal speed
 default: 200
"height"
 upward speed
 default: 200
*/
void() trigger_monsterjump =
{
	if (!self.speed)
		self.speed = 200;
	if (!self.height)
		self.height = 200;
	if (self.angles == '0 0 0')
		self.angles = '0 360 0';
	InitTrigger ();
	self.touch = trigger_monsterjump_touch;
};

