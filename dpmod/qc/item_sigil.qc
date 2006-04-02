/*
===============================================================================

END OF LEVEL RUNES

===============================================================================
*/

void() sigil_touch =
{
	// local entity stemp, head;
	// local float best;

	if (other.classname != "player")
		return;
	if (other.health < 1)
		return;

	if (other.flags & FL_CLIENT)
	{
//		centerprint (other, "You got the rune!");
		stuffcmd(other, "bf\n");
	}

	sound (other, CHAN_ITEM, self.noise, 1, ATTN_NORM);
	self.solid = SOLID_NOT;
	self.model = "";
	serverflags = serverflags | (self.spawnflags & 15);
	self.classname = ""; // so rune doors won't find it

	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets

	remove(self);
};


/*QUAKED item_sigil (0 .5 .8) (-16 -16 -24) (16 16 32) E1 E2 E3 E4
End of level sigil, pick up to end episode and return to jrstart.
*/

void() item_sigil =
{
	if (!self.spawnflags)
		objerror ("no spawnflags");

	precache_sound ("misc/runekey.wav");
	self.noise = "misc/runekey.wav";

	if (self.spawnflags & 1)
	{
		precache_model ("progs/end1.mdl");
		setmodel (self, "progs/end1.mdl");
	}
	if (self.spawnflags & 2)
	{
		precache_model2 ("progs/end2.mdl");
		setmodel (self, "progs/end2.mdl");
	}
	if (self.spawnflags & 4)
	{
		precache_model2 ("progs/end3.mdl");
		setmodel (self, "progs/end3.mdl");
	}
	if (self.spawnflags & 8)
	{
		precache_model2 ("progs/end4.mdl");
		setmodel (self, "progs/end4.mdl");
	}

	self.touch = sigil_touch;
	setsize (self, '-16 -16 -24', '16 16 32');
	StartItem ();
};

