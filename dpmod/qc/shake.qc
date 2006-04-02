
float SHAKE_SILENT     = 2;
float SHAKE_STARTON    = 4;
float SHAKE_TOGGLE     = 8;

void() shaketouch =
{
	local vector v;
	if (!self.weapon) // is it active
		return;
	if (other.flags & FL_ONGROUND)
	if (other.movetype == MOVETYPE_WALK || other.movetype == MOVETYPE_STEP)
	{
	//         other.earthquaketime = time + 0.2;
		self.flags = self.flags - FL_ONGROUND;
		v_x = crandom();
		v_y = crandom();
		v_z = 4;
		v = normalize(v);
		other.velocity = other.velocity + v * (random() * 150);
	}
};

void() shakethink =
{
	self.nextthink = time + 0.1;
	if (!(self.spawnflags & SHAKE_TOGGLE))
	{
		if (time < self.wait)
		{
			if (self.spawnflags & SHAKE_STARTON)
				self.weapon = 0;
			else
				self.weapon = 1;
		}
		else
		{
			if (self.spawnflags & SHAKE_STARTON)
				self.weapon = 1;
			else
				self.weapon = 0;
		}
	}
	if (!self.weapon) // is it active
		return;
	force_retouch = 2;      // hit even non-moving objects
};

void() shakeuse =
{
	if (self.spawnflags & SHAKE_TOGGLE)
	{
		self.weapon = !self.weapon;
		return;
	}
	if (self.spawnflags & SHAKE_STARTON)
		self.weapon = 0;
	else
		self.weapon = 1;
	self.wait = time + self.delay;
};

/*QUAKED trigger_shake (1 .5 0) ? PLAYERONLY SILENT STARTON TOGGLE
any player touching this feels an earthquake.

when targeted it will flash on/off
see STARTON, TOGGLE and delay

flags:
"PLAYERONLY"
 only affects players.
"SILENT"
 no sound.
"STARTON"
 works in reverse, normally on, off when targeted.
"TOGGLE"
 switches on/off when targeted.

keys:
"delay"
 how long it will stay switched when
 targeted, ignored with TOGGLE.
"targetname"
 guess (flashes/toggles when targeted)
*/
void() trigger_shake =
{
	InitTrigger();
	self.touch = shaketouch;
	self.think = shakethink;
	self.nextthink = time + 0.1;
	self.use = shakeuse;
	/* need a earthquake sound
	if (!(self.spawnflags & SHAKE_SILENT))
		precache_sound ("ambience/fl_hum1.wav");
	*/
	self.wait = 0;
	self.weapon = 0; // start inactive
	if (self.spawnflags & SHAKE_STARTON)
		self.weapon = 1; // oh, turn it on then
};
