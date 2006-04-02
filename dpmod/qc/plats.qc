

void() plat_center_touch;
void() plat_outside_touch;
void() plat_trigger_use;
void() plat_go_up;
void() plat_go_down;
void() plat_crush;
float PLAT_LOW_TRIGGER = 1;

void() plat_spawn_inside_trigger =
{
	local entity trigger;
	local vector tmin, tmax;

//
// middle trigger
//
	trigger = spawn();
	trigger.touch = plat_center_touch;
	trigger.movetype = MOVETYPE_NONE;
	trigger.solid = SOLID_TRIGGER;
	trigger.enemy = self;

	tmin = self.mins + '25 25 0';
	tmax = self.maxs - '25 25 -8';
	tmin_z = tmax_z - (self.pos1_z - self.pos2_z + 8);
	if (self.spawnflags & PLAT_LOW_TRIGGER)
		tmax_z = tmin_z + 8;

	if (self.size_x <= 50)
	{
		tmin_x = (self.mins_x + self.maxs_x) / 2;
		tmax_x = tmin_x + 1;
	}
	if (self.size_y <= 50)
	{
		tmin_y = (self.mins_y + self.maxs_y) / 2;
		tmax_y = tmin_y + 1;
	}

	setsize (trigger, tmin, tmax);
};

void() plat_hit_top =
{
	if (self.noise1 != "")
		sound (self, CHAN_VOICE, self.noise1, 1, ATTN_NORM);
	self.state = STATE_TOP;
	self.think = plat_go_down;
	self.nextthink = self.ltime + 3;
};

void() plat_hit_bottom =
{
	if (self.noise1 != "")
		sound (self, CHAN_VOICE, self.noise1, 1, ATTN_NORM);
	self.state = STATE_BOTTOM;
};

void() plat_go_down =
{
	if (self.noise != "")
		sound (self, CHAN_VOICE, self.noise, 1, ATTN_NORM);
	self.state = STATE_DOWN;
	SUB_CalcMove (self.pos2, self.speed, plat_hit_bottom);
};

void() plat_go_up =
{
	if (self.noise != "")
		sound (self, CHAN_VOICE, self.noise, 1, ATTN_NORM);
	self.state = STATE_UP;
	SUB_CalcMove (self.pos1, self.speed, plat_hit_top);
};

void() plat_center_touch =
{
	//if (other.classname != "player")
	if (!other.cantrigger)
		return;

	if (other.health < 1)
		return;

	self = self.enemy;
	if (self.state == STATE_BOTTOM)
		plat_go_up ();
	else if (self.state == STATE_TOP)
		self.nextthink = self.ltime + 1;	// delay going down
};

void() plat_outside_touch =
{
	//if (other.classname != "player")
	if (!other.cantrigger)
		return;

	if (other.health < 1)
		return;

	//dprint ("plat_outside_touch\n");
	self = self.enemy;
	if (self.state == STATE_TOP)
		plat_go_down ();
};

void() plat_trigger_use =
{
	if (self.think)
		return;		// allready activated
	plat_go_down();
};


void() plat_crush =
{
	//dprint ("plat_crush\n");

	if (other.iscorpse)
		T_Damage (other, self, self, 10, 10, self.deathtype, DT_IMPACT, (self.absmin + self.absmax) * 0.5, '0 0 0', Obituary_Generic);
	else
		T_Damage (other, self, self, 1, 1, self.deathtype, DT_IMPACT, (self.absmin + self.absmax) * 0.5, '0 0 0', Obituary_Generic);

	if (!other.iscorpse) // let it crush dead bodies
	{
		if (self.state == STATE_UP)
			plat_go_down ();
		else if (self.state == STATE_DOWN)
			plat_go_up ();
		else
			objerror ("plat_crush: bad self.state\n");
	}
};

void() plat_use =
{
	self.use = SUB_Null;
	if (self.state != STATE_UP)
		objerror ("plat_use: not in up state");
	plat_go_down();
};


/*QUAKED func_plat (0 .5 .8) ? PLAT_LOW_TRIGGER
speed	default 150

Plats are always drawn in the extended position, so they will light correctly.

If the plat is the target of another trigger or button, it will start out disabled in the extended position until it is trigger, when it will lower and become a normal plat.

If the "height" key is set, that will determine the amount the plat moves, instead of being implicitly determined by the model's height.
Set "sounds" to one of the following:
1) base fast
2) chain slow
*/


void() func_plat =
{
	self.deathtype = " was squished"; // NOT LIKELY, 1 damage on block

	if (!self.t_length)
		self.t_length = 80;
	if (!self.t_width)
		self.t_width = 10;

// FIX THIS TO LOAD A GENERIC PLAT SOUND

	if (game != GAME_NEXUIZ)
	{
		if (self.sounds == 0)
			self.sounds = 2;
		if (self.sounds == 1)
		{
			precache_sound ("plats/plat1.wav");
			precache_sound ("plats/plat2.wav");
			self.noise = "plats/plat1.wav";
			self.noise1 = "plats/plat2.wav";
		}
		if (self.sounds == 2)
		{
			precache_sound ("plats/medplat1.wav");
			precache_sound ("plats/medplat2.wav");
			self.noise = "plats/medplat1.wav";
			self.noise1 = "plats/medplat2.wav";
		}
	}


	self.mangle = self.angles;
	self.angles = '0 0 0';

	self.solid = SOLID_BSP;
	self.movetype = MOVETYPE_PUSH;
	setorigin (self, self.origin);
	setmodel (self, self.model);
	setsize (self, self.mins , self.maxs);

	self.blocked = plat_crush;
	if (!self.speed)
		self.speed = 150;

// pos1 is the top position, pos2 is the bottom
	self.pos1 = self.origin;
	self.pos2 = self.origin;
	if (self.height)
		self.pos2_z = self.origin_z - self.height;
	else
		self.pos2_z = self.origin_z - self.size_z + 8;

	self.use = plat_trigger_use;

	plat_spawn_inside_trigger ();	// the "start moving" trigger

	if (self.targetname)
	{
		self.state = STATE_UP;
		self.use = plat_use;
	}
	else
	{
		setorigin (self, self.pos2);
		self.state = STATE_BOTTOM;
	}
};

//============================================================================

void() train_next;
void() func_train_find;

void() train_blocked =
{
	if (time < self.attack_finished)
		return;
	if (!other.iscorpse) // crush dead bodies quickly
		self.attack_finished = time + 0.5;
	T_Damage (other, self, self, self.dmg, self.dmg, self.deathtype, DT_IMPACT, (self.absmin + self.absmax) * 0.5, '0 0 0', Obituary_Generic);
};
void() train_use =
{
	if (self.think != func_train_find)
		return;		// already activated
	train_next();
};

void() train_wait =
{
	if (self.wait)
	{
		self.nextthink = self.ltime + self.wait;
		if (self.noise != "")
			sound (self, CHAN_VOICE, self.noise, 1, ATTN_NORM);
	}
	else
		self.nextthink = self.ltime + 0.1;

	self.think = train_next;
};

void() train_next =
{
	local entity targ;

	targ = find(world, targetname, self.target);
	self.target = targ.target;
	if (!self.target)
		objerror ("train_next: no next target");
	if (targ.wait)
		self.wait = targ.wait;
	else
		self.wait = 0;
	if (self.noise1 != "")
		sound (self, CHAN_VOICE, self.noise1, 1, ATTN_NORM);
	SUB_CalcMove (targ.origin - self.mins, self.speed, train_wait);
};

void() func_train_find =
{
	local entity targ;

	targ = find(world, targetname, self.target);
	self.target = targ.target;
	setorigin (self, targ.origin - self.mins);
	// increased to 1 second from 0.1, now the train won't move before
	// monsters appear, leaving them falling,
	// or at least causing a nasty monster in wall error.
	if (!self.targetname)
	{
		// not triggered, so start immediately
		self.nextthink = self.ltime + 1;
		self.think = train_next;
	}
};

/*QUAKED func_train (0 .5 .8) ?
Trains are moving platforms that players can ride.
The targets origin specifies the min point of the train at each corner.
The train spawns at the first target it is pointing at.
If the train is the target of a button or trigger, it will not begin moving until activated.
speed	default 100
dmg		default	2
sounds
1) ratchet metal

*/
void() func_train =
{
	if (!self.deathtype) // map makers can override this
		self.deathtype = " was crushed";
	if (!self.speed)
		self.speed = 100;
	if (!self.target)
		objerror ("func_train without a target");
	if (!self.dmg)
		self.dmg = 2;

	if (game == GAME_NEXUIZ)
	{
		if (self.sounds == 1)
		{
			self.noise = ("plats/train2.wav");
			precache_sound ("plats/train2.wav");
			self.noise1 = ("plats/train1.wav");
			precache_sound ("plats/train1.wav");
		}
	}

	self.cnt = 1;
	self.solid = SOLID_BSP;
	self.movetype = MOVETYPE_PUSH;
	self.blocked = train_blocked;
	self.use = train_use;
	// self.classname = "train";

	setmodel (self, self.model);
	setsize (self, self.mins , self.maxs);
	setorigin (self, self.origin);

// start trains on the second frame, to make sure their targets have had
// a chance to spawn
	self.nextthink = self.ltime + 0.1;
	self.think = func_train_find;
};

/*
void() misc_teleporttrain_modelentitythink =
{
	if (self.owner.classname != "misc_teleporttrain")
	{
		remove(self);
		return;
	}
	self.nextthink = time;
	setorigin (self, self.owner.origin);
};
*/

/*QUAKED misc_teleporttrain (0 .5 .8) (-8 -8 -8) (8 8 8)
This is used for the final boss
*/
/*
void() misc_teleporttrain =
{
	if (!self.speed)
		self.speed = 100;
	if (!self.target)
		objerror ("func_train without a target");
	self.classname = "misc_teleporttrain";

	self.cnt = 1;
	self.solid = SOLID_NOT;
	self.movetype = MOVETYPE_PUSH;
	self.blocked = train_blocked;
	self.use = train_use;
//	self.avelocity = '100 200 300';
	self.avelocity = '0 0 0';

	precache_model2 ("progs/teleport.mdl");
	setorigin (self, self.origin);
// hack to avoid physics code crashes, why did id do something so stupid?
// I mean using MOVETYPE_PUSH with a non-bsp model is just plain STUPID.
// because the engine dumps you out with an error in that situation...
// and I would gladly change it to MOVETYPE_NOCLIP if that actually worked.

// but because it seems to not have the error if there is no model at all,
// I just spawn an entity which you actually see,
// which just setorigin's itself as fast as possible to follow the train.

// oh well, it works...  infact it reminds me of my bullet hole following...
// gee would be nice if I could specify a relative origin instead,
// less code, and looks cleaner...  would be good for bullet holes...
// Lord Havoc
	newmis = spawn();
	setmodel (newmis, "progs/teleport.mdl");
	setsize (newmis, '0 0 0', '0 0 0');
	setorigin (newmis, self.origin);
	newmis.think = misc_teleporttrain_modelentitythink;
	newmis.nextthink = time + 0.01;
	newmis.owner = self;
	newmis.classname = "misc_teleporttrain_modelentity";

// start trains on the second frame, to make sure their targets have had
// a chance to spawn
	self.nextthink = self.ltime + 0.1;
	self.think = func_train_find;
};
*/

void() misc_teleporttrain =
{
	if (!self.speed)
		self.speed = 100;
	if (!self.target)
		objerror ("func_train without a target");

	self.cnt = 1;
	self.solid = SOLID_NOT;
	self.movetype = MOVETYPE_PUSH;
	self.blocked = train_blocked;
	self.use = train_use;
	self.avelocity = '100 200 300';

	precache_model2 ("progs/teleport.mdl");
	setmodel (self, "progs/teleport.mdl");
	setsize (self, self.mins , self.maxs);
	setorigin (self, self.origin);

// start trains on the second frame, to make sure their targets have had
// a chance to spawn
	self.nextthink = self.ltime + 0.1;
	self.think = func_train_find;
};
