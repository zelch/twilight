
// shared spawnflags
float ROTATE_TOUCHDMG = 1;

// door spawnflags
float ROTATEDOOR_CRUSH = 2;
float ROTATEDOOR_TOGGLE = 4;
// object spawnflags
float ROTATINGOBJECT_STARTON = 2;
float ROTATINGOBJECT_NOTSOLID = 4;

//.float rotatetype;
//float ROTATETYPE_OBJECT = 1;
//float ROTATETYPE_MOVEWALL = 2;
//float ROTATETYPE_ENTITY = 3; // anything else


float STATE_CLOSED = 1;
float STATE_CLOSING = 2;
float STATE_OPENING = 3;
float STATE_OPEN = 4;
float STATE_STARTCLOSING = 5;

float MOVEWALL_VISIBLE = 1;
float MOVEWALL_TOUCH = 2;

float STATE_NOTSPINNING = 1;
float STATE_SPINNINGUP = 2;
float STATE_SPINNING = 3;
float STATE_SPINNINGDOWN = 4;

//.float setuprotatetargets;
//.vector rotateoffset;

/*QUAKED info_rotate (0 .5 0) (-8 -8 -8) (8 8 8)
rotate_objects target this to
set center of rotation.
*/

void() info_rotate =
{
	self.think = SUB_Remove;
	self.nextthink = time + 2; // give things a chance to get info
};

void(entity door) rotate_door_group_reversedirection;
void() rotate_door_stateupdate;

void() rotate_touch =
{
	if (time < self.attack_finished)
		return;

	if (self.dmg > 0)
	{
		T_Damage (other, self, self, self.dmg * 0.1, self.dmg * 0.1, self.deathtype, DT_IMPACT, (self.absmin + self.absmax) * 0.5, '0 0 0', Obituary_Generic);
		self.attack_finished = time + 0.1;
	}
};

void() rotate_blocked =
{
	if (time < self.attack_finished)
		return;

	self.attack_finished = time + 0.1;

	if (self.classname == "func_rotatingdoor")
	{
		rotate_door_stateupdate();
		rotate_door_group_reversedirection(self);
	}

	if(self.dmg > 0)
	{
		T_Damage (other, self, self, self.dmg * 0.1, self.dmg * 0.1, self.deathtype, DT_IMPACT, (self.absmin + self.absmax) * 0.5, '0 0 0', Obituary_Generic);
		self.attack_finished = time + 0.1;
	}
};

void(float notsolid) rotate_setup =
{
	local entity e;

	if (notsolid)
		self.solid = SOLID_NOT;
	else
		self.solid = SOLID_BSP;
	self.movetype = MOVETYPE_PUSH;
	setmodel(self, self.model);

	e = find(world, targetname, self.target);
	if (e.classname != "info_rotate")
		objerror("rotate_object: must target an info_rotate\nto define center of rotation");
	setorigin(self, e.origin);
	self.oldorigin = self.origin;

	if (self.spawnflags & ROTATE_TOUCHDMG)
		self.touch = rotate_touch;
	self.blocked = rotate_blocked;
};

void(vector destangles) rotate_calculatemove =
{
	self.ltime = time;
	self.nextthink = time + (vlen(destangles - self.angles) / self.speed);
	if (self.nextthink >= time + 0.01)
		self.avelocity = normalize(destangles - self.angles) * self.speed;
	else
	{
		self.nextthink = time + 0.01;
		self.avelocity = '0 0 0';
	}
};

void() rotate_door_stateupdate =
{
	local float s;
	s = 0;
	if (self.state == STATE_OPENING)
	{
		rotate_calculatemove(self.dest);
		s = 1;
	}
	else if (self.state == STATE_CLOSING)
	{
		rotate_calculatemove(self.dest1);
		s = 1;
	}
	else
		s = 0;
	if (self.cnt != s)
	{
		self.cnt = s;
		if (s == 1)
		{
			if (self.noise2 != "")
				sound(self, CHAN_VOICE, self.noise2, 1, ATTN_NORM);
		}
		else
		{
			if (self.noise3 != "")
				sound(self, CHAN_VOICE, self.noise3, 1, ATTN_NORM);
		}
	}
	if (self.state == STATE_CLOSED || self.state == STATE_CLOSING)
		self.frame = 0;
	else
		self.frame = 1;
};

void() rotate_door_statethink =
{
	self.nextthink = 0;
	self.avelocity = '0 0 0';
	// all of these are right when the state begins
	if (self.state == STATE_STARTCLOSING)
		self.state = STATE_CLOSING;
	else if (self.state == STATE_CLOSING)
		self.state = STATE_CLOSED;
	else if (self.state == STATE_OPENING)
	{
		self.state = STATE_OPEN;
		if (!(self.spawnflags & ROTATEDOOR_TOGGLE))
		if (self.wait >= 0)
		{
			self.nextthink = time + self.wait;
			self.state = STATE_STARTCLOSING;
		}
	}
	rotate_door_stateupdate();
};

void() rotate_door_use =
{
	if (self.spawnflags & ROTATEDOOR_TOGGLE)
	{
		if (self.state == STATE_OPEN || self.state == STATE_STARTCLOSING || self.state == STATE_OPENING)
			self.state = STATE_CLOSING;
		if (self.state == STATE_CLOSED || self.state == STATE_CLOSED)
			self.state = STATE_OPENING;
	}
	else
	{
		if (self.state != STATE_OPEN)
		if (self.state != STATE_OPENING)
		{
			if (self.state == STATE_STARTCLOSING)
				self.nextthink = time + self.wait;
			else
				self.state = STATE_OPENING;
		}
	}
	rotate_door_stateupdate();
};

void() rotate_door_reversedirection =
{
	if (self.spawnflags & ROTATEDOOR_CRUSH)
		return;

	if (self.state == STATE_CLOSED || self.state == STATE_CLOSING)
		self.state = STATE_OPENING;
	else
		self.state = STATE_CLOSING;

	rotate_door_stateupdate();
};

void(entity door) rotate_door_group_reversedirection =
{
	local string n;
	local entity eself;

	eself = self;
	self = door;

	// reverse all in group
	if (self.group)
	{
		n = self.group;
		self = find(world, group, n);
		while(self != world)
		{
			rotate_door_reversedirection();
			self = find(self, group, n);
		}
	}
	else
		rotate_door_reversedirection();
	self = eself;
};

/*QUAKED func_rotatingdoor (.6 0 .9) ? TOUCHDMG CRUSH TOGGLE
rotating door.

Flags:
"TOUCHDMG"
 if set, will do block damage
 when touched, not just when
 blocked.
"CRUSH"
 will crush things instead of
 reversing direction when
 blocked, useful when making a
 door to block off an area.
"TOGGLE"
 opens/closes when triggered,
 rather than just opening.

Keys:
"dmg"
 damage to cause when blocked,
 default is 2, use -1 for no
 damage.
"speed"
 how fast it rotates,
 in degrees per second.
 default: 90
"angles"
 start angles (pitch yaw roll).
"dest"
 end angles (pitch yaw roll).
"wait"
 how long to stay open.
 (not used with TOGGLE)
 default: 3 seconds
"target"
 must target info_rotate
 object to define origin
"targetname"
 must be targeted, rotating
 doors operate only when
 triggered
"group"
 you can group rotating doors,
 when grouped all rotating
 doors will reverse direction
 at the same time
"deathtype"
 as with basically all things
 in Dark Places, deathtype
 is message when something is
 killed by this.
 default: " got in the way"
"sounds"
1) medieval (default)
2) metal
3) base
*/

void() func_rotatingdoor =
{
	if (!self.deathtype) // map makers can override this
		self.deathtype = " got in the way";
	if (!self.target)
		objerror("func_rotateingdoor: must have targets.");

	self.dest1 = self.angles;

	if (self.speed <= 0)
		self.speed = 90;
	if (self.wait == 0)
		self.wait = 3;
	if (self.wait <= 0)
		self.wait = 0;

	if (self.dmg == 0)
		self.dmg = 2;
	else if (self.dmg < 0)
		self.dmg = 0;

	if (game != GAME_NEXUIZ)
	{
		if (self.sounds == 0)
			self.sounds = 1;
		if (self.sounds == 1)
		{
			precache_sound ("doors/winch2.wav");
			precache_sound ("doors/drclos4.wav");
			self.noise2 = "doors/winch2.wav";
			self.noise3 = "doors/drclos4.wav";
		}
		if (self.sounds == 2)
		{
			precache_sound ("doors/airdoor1.wav");
			precache_sound ("doors/airdoor2.wav");
			self.noise2 = "doors/airdoor1.wav";
			self.noise3 = "doors/airdoor2.wav";
		}
		if (self.sounds == 3)
		{
			precache_sound ("doors/basesec1.wav");
			precache_sound ("doors/basesec2.wav");
			self.noise2 = "doors/basesec1.wav";
			self.noise3 = "doors/basesec2.wav";
		}
	}

	rotate_setup(FALSE);

	self.state = STATE_CLOSED;
	self.use = rotate_door_use;
	self.think = rotate_door_statethink;
	self.nextthink = 0;
};

void() rotatingobject_think =
{
	local float t, s;
	self.nextthink = time;
	self = self.owner;

	t = time - self.count;
	self.count = time;

	self.avelocity = self.rotate * self.speed;

	if (self.state == STATE_SPINNINGUP)
	{
		if (self.delay)
			s = t * self.delay;
		else
			s = 1;
		self.speed = self.speed + s;
		if (self.speed >= 1)
		{
			self.speed = 1;
			self.state = STATE_SPINNING;
		}
	}
	else if (self.state == STATE_SPINNINGDOWN)
	{
		if (self.delay)
			s = t * self.delay;
		else
			s = 1;
		self.speed = self.speed - s;
		if (self.speed <= 0)
		{
			self.speed = 0;
			self.state = STATE_NOTSPINNING;
		}
	}
	if (self.state == STATE_SPINNINGUP || self.state == STATE_SPINNING)
		self.frame = 1;
	else
		self.frame = 0;
};

void() rotatingobject_use =
{
	if (self.state == STATE_SPINNINGUP || self.state == STATE_SPINNING)
		self.state = STATE_SPINNINGDOWN;
	else
		self.state = STATE_SPINNINGUP;
};

void() rotatingobject_setup =
{
	self.enemy = spawn();
	self.enemy.owner = self;
	self.enemy.think = rotatingobject_think;
	self.enemy.nextthink = self.count = time + 0.1;

	self.state = STATE_NOTSPINNING;
	self.use = rotatingobject_use;
	self.think = SUB_Null;
	self.nextthink = 99999999999;
	if ((self.spawnflags & ROTATINGOBJECT_STARTON) || (!self.targetname))
	{
		self.speed = 1;
		self.state = STATE_SPINNING;
	}
};

/*QUAKED func_rotatingobject (.6 0 .9) ? TOUCHDMG STARTON NOTSOLID
a rotating 'thing',
like a spinning fan.

Flags:
"TOUCHDMG"
 cause damage when touched,
 not just when blocked.
 (example: blades)
"STARTON"
 easy to guess this one,
 meaningless if it can't be
 triggered.
"NOTSOLID"
 if set, the object is not
 solid.

Keys:
"dmg"
 damage to cause when blocked.
 default: 0
"delay"
 how long it takes
 to completely spin up/down.
 default: 0 (instant)
"rotate"
 rotation per second
 (pitch yaw roll, in degrees).
"target"
 of course this must be set
"targetname"
 if set, it will only
 start/stop spinning when
 triggered, rather than
 simply spinning all the time.
"deathtype"
 as with basically all things
 in Dark Places, deathtype
 is message when something is
 killed by this.
 default: " got in the way"
*/

void() func_rotatingobject =
{
	if (!self.deathtype) // map makers can override this
		self.deathtype = " got in the way";
	if (!self.target)
		objerror("func_rotatingobject: must target info_rotate.");

	if (self.delay < 0.01)
		self.delay = 0;
	// change to acceleration rate
	if (self.delay)
		self.delay = 1 / self.delay;
	self.speed = 0;

	rotate_setup(self.spawnflags & ROTATINGOBJECT_NOTSOLID);

	self.think = rotatingobject_setup;
	self.nextthink = time + 0.2;
};

