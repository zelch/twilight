
void() spinningspotlightthink =
{
	self.nextthink = time;
	self.angles = self.angles + self.avelocity * frametime;
	makevectors(self.angles);
	traceline(self.dest, v_forward * 8192 + self.dest, FALSE, self);
	setorigin(self, trace_endpos - v_forward);
};

/*QUAKED effect_spinningspotlight (0 1 0) (-8 -8 -8) (8 8 8)
A spinning spot light,
nifty disco like effects or anything
else you think up.

Keys:
"angles"
 starting direction in degrees (pitch yaw roll)
"avelocity"
 rotation speed in degrees per second (pitch yaw roll)
*/

void() effect_spinningspotlight =
{
	self.dest = self.origin;
	self.effects = EF_DIMLIGHT;
	self.think = spinningspotlightthink;
	self.nextthink = time + 0.2;
	precache_model("progs/null.spr");
	setmodel(self, "progs/null.spr");
	setorigin(self, self.origin);
};
