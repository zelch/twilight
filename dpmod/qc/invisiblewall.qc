
float INVISIBLEWALL_STARTOFF  =       1;

void() invisiblewall_use =
{
	if (self.solid == SOLID_BSP)
	{
		self.solid = SOLID_NOT;
		self.movetype = MOVETYPE_NONE;
	}
	else
	{
		self.solid = SOLID_BSP;
		self.movetype = MOVETYPE_PUSH;
	}
};

/*QUAKED func_invisiblewall (0 .5 .8) ? STARTOFF
invisible wall,
toggles on/off when triggered.

better than invisible walls
made with CLIP texture
as bullets etc can't go
through this.

Flags:
"STARTOFF"
 uh, guess...
*/

void() func_invisiblewall =
{
	setmodel (self, self.model);    // set size and link into world
	self.model = "";                // make it invisible
	self.use = invisiblewall_use;
	self.solid = SOLID_BSP; // make it solid
	self.movetype = MOVETYPE_PUSH;
	if (self.spawnflags & INVISIBLEWALL_STARTOFF)
	{
		self.solid = SOLID_NOT; // oh, turn it off
		self.movetype = MOVETYPE_NONE;
	}
};

