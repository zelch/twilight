
float GRENADE_IMPACT = 1;
float GRENADE_PROXIMITY = 2;
float GRENADE_IMMUNETODAMAGE = 4;
float GRENADE_TENWARHEAD = 8;
float GRENADE_DETONATEONBUTTON3 = 16;

void() GrenadeExplode =
{
	local vector v;
	if (self.weapon & GRENADE_TENWARHEAD)
	{
		v = randomvec() * 200;LaunchGrenade(self.origin, self.velocity + v, self.owner, self.dmg, self.dmg2, GRENADE_IMPACT + GRENADE_IMMUNETODAMAGE, 10, self.deathtype, self.obitfunc1);
		v = randomvec() * 200;LaunchGrenade(self.origin, self.velocity + v, self.owner, self.dmg, self.dmg2, GRENADE_IMPACT + GRENADE_IMMUNETODAMAGE, 10, self.deathtype, self.obitfunc1);
		v = randomvec() * 200;LaunchGrenade(self.origin, self.velocity + v, self.owner, self.dmg, self.dmg2, GRENADE_IMPACT + GRENADE_IMMUNETODAMAGE, 10, self.deathtype, self.obitfunc1);
		v = randomvec() * 200;LaunchGrenade(self.origin, self.velocity + v, self.owner, self.dmg, self.dmg2, GRENADE_IMPACT + GRENADE_IMMUNETODAMAGE, 10, self.deathtype, self.obitfunc1);
		v = randomvec() * 200;LaunchGrenade(self.origin, self.velocity + v, self.owner, self.dmg, self.dmg2, GRENADE_IMPACT + GRENADE_IMMUNETODAMAGE, 10, self.deathtype, self.obitfunc1);
		v = randomvec() * 200;LaunchGrenade(self.origin, self.velocity + v, self.owner, self.dmg, self.dmg2, GRENADE_IMPACT + GRENADE_IMMUNETODAMAGE, 10, self.deathtype, self.obitfunc1);
		v = randomvec() * 200;LaunchGrenade(self.origin, self.velocity + v, self.owner, self.dmg, self.dmg2, GRENADE_IMPACT + GRENADE_IMMUNETODAMAGE, 10, self.deathtype, self.obitfunc1);
		v = randomvec() * 200;LaunchGrenade(self.origin, self.velocity + v, self.owner, self.dmg, self.dmg2, GRENADE_IMPACT + GRENADE_IMMUNETODAMAGE, 10, self.deathtype, self.obitfunc1);
		v = randomvec() * 200;LaunchGrenade(self.origin, self.velocity + v, self.owner, self.dmg, self.dmg2, GRENADE_IMPACT + GRENADE_IMMUNETODAMAGE, 10, self.deathtype, self.obitfunc1);
		v = randomvec() * 200;LaunchGrenade(self.origin, self.velocity + v, self.owner, self.dmg, self.dmg2, GRENADE_IMPACT + GRENADE_IMMUNETODAMAGE, 10, self.deathtype, self.obitfunc1);
	}
	else if (self.deathtype == "GRENADE")
	{
		if (self.lefty)
			Explosion(self.origin, self.owner, self.dmg, self.dmg2, "GRENADEBOUNCED", '0 0 0', self.effects & EF_BLUE, self.obitfunc1);
		else
			Explosion(self.origin, self.owner, self.dmg, self.dmg2, "GRENADEDIRECT", '0 0 0', self.effects & EF_BLUE, self.obitfunc1);
	}
	else
		Explosion(self.origin, self.owner, self.dmg, self.dmg2, self.deathtype, '0 0 0', self.effects & EF_BLUE, self.obitfunc1);
	remove(self);
};

void() GrenadeDet =
{
	self.think = GrenadeExplode;
	self.nextthink = time;
	self.solid = SOLID_NOT;
	self.takedamage = DAMAGE_NO;
	setsize(self, '0 0 0', '0 0 0');
	self.movetype = MOVETYPE_NONE;
};

void() GrenadeThink =
{
	local   entity  head;
	local   float   p;
	self.nextthink = time;
	fightdone = time + 1; // delay stuff until fighting is over
	p = pointcontents(self.origin);
	if (p == CONTENT_SKY)
	{
		remove(self);
		return;
	}
	if (p == CONTENT_LAVA || time > self.cnt)
	{
		self.th_die();
		return;
	}
	if (self.weapon & GRENADE_DETONATEONBUTTON3)
	if (self.owner.button3)
	if (self.deathtype == "GRENADE")
	{
		GrenadeExplode();
		return;
	}
	if (self.weapon & GRENADE_PROXIMITY)
	{
		if (time >= self.count)
		{
			self.count = time + 0.05;
			head = findradius(self.origin, self.dmg2 * 0.5);
			while (head)
			{
				if ((head.flags & FL_MONSTER) || head.classname == "player")
				if (head != self.owner)
				if (head.team == 0 || head.team != self.owner.team)
				{
					// trigger
					self.count = time + 1000;
					self.cnt = time + 0.1;
					sound(self, CHAN_VOICE, "weapons/bomb/trigger.wav", 1, ATTN_STATIC);
					break;
				}
				head = head.chain;
			}
		}
	}
	if (self.flags & FL_ONGROUND)
	{
		if (self.mins_z == 0)
		{
			setsize(self, '0 0 -2', '0 0 0');
			traceline(self.origin + '0 0 1', self.origin + '0 0 -4', TRUE, world);
			if (trace_fraction < 1)
				setorigin(self, trace_endpos + '0 0 4');
		}
		self.angles_x = 0;
		self.angles_z = 0;
		self.avelocity = '0 0 0';
	}
//	else
//		self.angles = vectoangles(self.velocity);
};

void() GrenadeTouch =
{
	if (other == self.owner)
		return; // don't hit owner
	if (vlen(self.velocity))
	if (other.solid == SOLID_BSP)
		self.avelocity = randomvec() * 400;
	if (self.weapon & GRENADE_IMPACT)
	{
		GrenadeExplode();
		return;
	}
	//if (self.weapon & GRENADE_PROXIMITY)
	if ((other.flags & FL_MONSTER) || other.classname == "player")
	if (other.team == 0 || other.team != self.owner.team)
	{
		GrenadeExplode();
		return;
	}
	self.lefty = TRUE;
	if (vlen(self.velocity) >= 15)
		sound (self, CHAN_WEAPON, "weapons/bounce.wav", 1, ATTN_NORM);  // bounce sound
};

void(vector org, vector vel, entity own, float damage, float damage2, float type, float lifetime, string dethtype, void(entity t, entity a, string m, float dtyp) obitfunc) LaunchGrenade =
{
	local   vector  v;
	DelayGibComment();      // make him wait before commenting on gibs so it's not drown out by explosions etc

	fightdone = time + 1; // delay stuff until fighting is over
	v = normalize(vel);
	newmis = spawn ();
	//newmis.cantrigger = TRUE; // can trigger buttons
	newmis.shoulddodge = TRUE;
	newmis.dangerrating = damage2;
	newmis.owner = own;
	newmis.movetype = MOVETYPE_BOUNCE;
	newmis.solid = SOLID_BBOX;
	newmis.classname = "grenade";
	// set newmis speed
	newmis.velocity = vel;
	newmis.avelocity = '0 0 0';
	newmis.angles = vectoangles(newmis.velocity);
	newmis.touch = GrenadeTouch;
	newmis.dmg = damage;
	newmis.dmg2 = damage2;
	newmis.effects = EF_LOWPRECISION;
	if (self.items & IT_QUAD)
	{
		newmis.effects = newmis.effects | EF_BLUE;
		newmis.dmg = newmis.dmg * 4;
	}
	// set newmis duration
	newmis.cnt = time + lifetime;
	newmis.deathtype = dethtype;
	newmis.obitfunc1 = obitfunc;
	newmis.weapon = type;
	newmis.think = GrenadeThink;
	newmis.nextthink = time;
	if (type & GRENADE_IMMUNETODAMAGE)
		newmis.takedamage = DAMAGE_NO;
	else
		newmis.takedamage = DAMAGE_YES;
	newmis.health = 20; // can be shot
	newmis.th_die = GrenadeDet;
	setmodel (newmis, "progs/grenade.mdl");
	setsize (newmis, '0 0 0', '0 0 0');
	setorigin (newmis, org);
};
