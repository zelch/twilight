
.float seenhelp;

/*
============
W_WeaponFrame

Called every frame so impulse events can be handled as well as possible
============
*/
void() W_WeaponFrame =
{
	local vector v;
	local float f;
	local string s;
	//local vector v, realvangle;

	if (time > self.seenhelp)
	{
		if (self.seenhelp == 0)
			self.seenhelp = time + 5;
		else
		{
			self.seenhelp = time + 9999999;
			if (self.flags & FL_CLIENT)
			{
				//            12345678901234567890123456789012345678
				sprint(self, "Lord Havoc's Dark Places\n");
				sprint(self, "be sure to type dphelp in console for very useful information\n");
				sprint(self, "http://darkplaces.gamevisions.com\n");
			}
		}
	}

	if (!self.solid) // observer
		return;

	if (self.deadflag >= DEAD_DYING) // dead
		return;

	if (nofire)
		self.button0 = self.button3 = self.button4 = self.button5 = self.button6 = self.button7 = self.button8 = 0;

	if (self.impulse) // only if there is one
	//if (self.attack_finished < time)
		ImpulseCommands();

	/*
	realvangle = self.v_angle;
	makevectors (self.v_angle);
	traceline(self.origin + self.view_ofs, self.origin + self.view_ofs + v_forward * 65536, FALSE, self);
	shotorg = self.origin + self.view_ofs + v_right * 6 - v_up * 6 + v_forward * 15;
	//shotorg = self.origin + '0 0 16' + v_forward * 15;
	shotdir = normalize(trace_endpos - shotorg);
	self.v_angle = vectoangles(shotdir);
	self.v_angle_z = realvangle_z;
	self.v_angle_x = 0 - self.v_angle_x;
	*/
	makevectors(self.v_angle);
	shotorg = self.origin + self.view_ofs + v_right * 6 - v_up * 6 + v_forward * 15;
	shotdir = v_forward;

	self.idealzoom = 1;
	if (self.button4)
		self.idealzoom = 0.2;

	if (self.viewzoom == 0)
		self.viewzoom = 1;

	// weapon animation, firing, etc
	setweapon(self.weapon, WR_SETUP);
	self.weaponframecode();
	setweapon(self.weapon, WR_SETUP);

	if (self.viewzoom != self.idealzoom)
	{
		if (self.viewzoom > self.idealzoom)
		{
			self.viewzoom = self.viewzoom - frametime * 10;
			if (self.viewzoom < self.idealzoom)
				self.viewzoom = self.idealzoom;
		}
		else if (self.viewzoom < self.idealzoom)
		{
			self.viewzoom = self.viewzoom + frametime * 10;
			if (self.viewzoom > self.idealzoom)
				self.viewzoom = self.idealzoom;
		}
	}

	//self.v_angle = realvangle;

	if (cvar("temp1") & 4096)
	if (self.flags & FL_CLIENT)
	{
		v = self.velocity;
		v_z = 0;
		sprint(self, "vel ");
		s = ftos(self.velocity_x);
		sprint(self, s);
		sprint(self, " ");
		s = ftos(self.velocity_y);
		sprint(self, s);
		sprint(self, " speed ");
		f = vlen(v);
		s = ftos(f);
		sprint(self, s);
		sprint(self, " (");
		f = f * 100 / cvar("sv_maxspeed");
		f = floor(f);
		s = ftos(f);
		sprint(self, s);
		sprint(self, "%)\n");
	}
};

