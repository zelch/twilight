/* ALL LIGHTS SHOULD BE 0 1 0 IN COLOR ALL OTHER ITEMS SHOULD
BE .8 .3 .4 IN COLOR */

float itemrespawn; // set in worldspawn based on deathmatch and coop

void() SUB_regen =
{
	self.model = self.mdl;		// restore original model
	self.solid = SOLID_TRIGGER;	// allow it to be touched again
	if (game != GAME_NEXUIZ)
		sound (self, CHAN_VOICE, "items/itembk2.wav", 1, ATTN_NORM);	// play respawn sound
	setorigin (self, self.origin);
	self.health = self.max_health;
	if (self.health >= 1)
	{
		self.takedamage = DAMAGE_YES;
		self.solid = SOLID_BBOX;
	}

	//te_teleport(self.origin);
};



/*QUAKED noclass (0 0 0) (-8 -8 -8) (8 8 8)
prints a warning message when spawned
*/
void() noclass =
{
	dprint("noclass spawned at");
	dprintvector(self.origin);
	dprint("\n");
	remove(self);
};

/*
============
PlaceItem

plants the object on the floor
============
*/
void() monsterinwall;
void(entity e) waypointspawnforitem;
void() PlaceItem =
{
	// local float c;
	if (deathmatch == DM_FRAGFEST || deathmatch == DM_ELIM)
	{
		activator = world;
		SUB_UseTargets(); // fire all targets / killtargets
		remove(self);
		return;
	}

	// so it can be restored on respawn
	self.mdl = self.model;
	// make extra wide
	self.flags = FL_ITEM;
	if (self.health >= 1)
		self.solid = SOLID_BBOX;
	else
		self.solid = SOLID_TRIGGER;
	self.movetype = MOVETYPE_TOSS;
	self.velocity = '0 0 0';

	tracebox(self.origin + '0 0 1', self.mins, self.maxs, self.origin + '0 0 -256', FALSE, self);
	if (trace_startsolid || trace_fraction == 1)
	{
		dprint(self.classname);
		if (trace_startsolid)
			dprint(" spawned in solid at ");
		else
			dprint(" fell out of level at ");
		dprintvector(self.origin);
		dprint("\n");
		monsterinwall();
	}
	else // all is well
		setorigin(self, trace_endpos);

	waypointspawnforitem(self);
};

/*
============
StartItem

Sets the clipping size and plants the object on the floor
============
*/
void() StartItem =
{
	self.solid = SOLID_NOT;
	self.movetype = MOVETYPE_NONE;
	self.velocity = '0 0 0';
	setorigin(self, self.origin);
	self.nextthink = time + 0.2;	// items start after other solids
	self.think = PlaceItem;
};
