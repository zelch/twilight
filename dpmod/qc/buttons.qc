// button and multiple button

void() button_wait;
void() button_return;

void() button_wait =
{
	self.state = STATE_TOP;
	self.nextthink = self.ltime + self.wait;
	self.think = button_return;
	activator = self.enemy;
	SUB_UseTargets();
	self.frame = 1;			// use alternate textures
};

void() button_done =
{
	self.state = STATE_BOTTOM;
};

void() button_return =
{
	self.state = STATE_DOWN;
	SUB_CalcMove (self.pos1, self.speed, button_done);
	self.frame = 0;			// use normal textures
	if (self.health)
	{
		self.havocattack = TRUE;
		self.takedamage = DAMAGE_YES;	// can be shot again
	}
};


void() button_blocked =
{
	// do nothing, just don't come all the way back out
};


void() button_fire =
{
	self.health = self.max_health;
	self.havocattack = TRUE;
	self.takedamage = DAMAGE_NO;    // will be reset upon return

	if (self.state == STATE_UP || self.state == STATE_TOP)
		return;

	if (self.noise != "")
		sound (self, CHAN_VOICE, self.noise, 1, ATTN_NORM);

	self.state = STATE_UP;
	SUB_CalcMove (self.pos2, self.speed, button_wait);
};


void() button_use =
{
//	if (activator.classname != "player")
//	{
//		dprint(activator.classname);
//		dprint(" triggered a button\n");
//	}
	self.enemy = activator;
	button_fire ();
};

void() button_touch =
{
//	if (activator.classname != "player")
//	{
//		dprint(activator.classname);
//		dprint(" touched a button\n");
//	}
	if (!other.cantrigger)
		return;
	self.enemy = other;
	if (other.owner)
		self.enemy = other.owner;
	button_fire ();
};

void() button_killed =
{
//	if (activator.classname != "player")
//	{
//		dprint(activator.classname);
//		dprint(" killed a button\n");
//	}
	self.enemy = damage_attacker;
	button_fire ();
};


/*QUAKED func_button (0 .5 .8) ?
When a button is touched, it moves some distance in the direction of it's angle, triggers all of it's targets, waits some time, then returns to it's original position where it can be triggered again.

"angle"		determines the opening direction
"target"	all entities with a matching targetname will be used
"speed"		override the default 40 speed
"wait"		override the default 1 second wait (-1 = never return)
"lip"		override the default 4 pixel lip remaining at end of move
"health"	if set, the button must be killed instead of touched
"sounds"
0) steam metal
1) wooden clunk
2) metallic click
3) in-out
*/
void() func_button =
{
	if (game != GAME_NEXUIZ)
	{
		if (self.sounds == 0)
		{
			precache_sound ("buttons/airbut1.wav");
			self.noise = "buttons/airbut1.wav";
		}
		if (self.sounds == 1)
		{
			precache_sound ("buttons/switch21.wav");
			self.noise = "buttons/switch21.wav";
		}
		if (self.sounds == 2)
		{
			precache_sound ("buttons/switch02.wav");
			self.noise = "buttons/switch02.wav";
		}
		if (self.sounds == 3)
		{
			precache_sound ("buttons/switch04.wav");
			self.noise = "buttons/switch04.wav";
		}
	}

	SetMovedir ();

	self.movetype = MOVETYPE_PUSH;
	self.solid = SOLID_BSP;
	setmodel (self, self.model);

	self.blocked = button_blocked;
	self.use = button_use;

//	if (self.health == 0) // all buttons are now shootable
//		self.health = 10;
	if (self.health)
	{
		self.havocattack = TRUE;
		self.max_health = self.health;
		self.th_die = button_killed;
		self.takedamage = DAMAGE_YES;
	}
	else
		self.touch = button_touch;

	if (!self.speed)
		self.speed = 40;
	if (!self.wait)
		self.wait = 1;
	if (!self.lip)
		self.lip = 4;

	self.state = STATE_BOTTOM;

	self.pos1 = self.origin;
	self.pos2 = self.pos1 + self.movedir*(fabs(self.movedir*self.size) - self.lip);
};

