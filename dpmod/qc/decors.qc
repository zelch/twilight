/*
==============================================================================

DECORS (shell casings, gibs, decals, nails stuck in walls...)

==============================================================================
*/

//DP_PHYSICS
float SOLID_PHYSICS_BOX = 32;
float SOLID_PHYSICS_SPHERE = 33;
float SOLID_PHYSICS_CAPSULE = 34;
float MOVETYPE_PHYSICS = 32;
.float mass;

void(entity e) removedecor =
{
	if (e.classname != "decor")
	{
		// if this is not a decor, just make it invisible
		e.model = "";
		return;
	}
	numdecors = numdecors - 1;
	remove(e);
};

entity(entity e) newdecor =
{
	if (e == world)
	{
		e = spawn();
		e.classname = "decor";
	}
	if (e.classname == "decor")
		numdecors = numdecors + 1;
	// set up common defaults
	e.isdecor = TRUE;
	//e.createdtime = time;
	e.cnt = 10 * (0.5 + random());
	e.alpha = 1;
	e.effects = EF_LOWPRECISION;
	e.flags = e.flags - (e.flags & FL_ONGROUND);
	e.groundentity = world;
	e.movetype = MOVETYPE_NONE;
	e.solid = SOLID_NOT;
	e.frame = 0;
	e.havocattack = FALSE;
	e.touch = SUB_Null;
	return e;
};

//.float createdtime;
float decordecay;

// removes the oldest decors each frame to maintain a certain maximum decors
void() decorframe =
{
	local entity estart, e, next;
	//local float decay;
	//local entity b1, b2, b3, b4, b5, b6, b7, b8, b9, b10;
	//local float bt1, bt2, bt3, bt4, bt5, bt6, bt7, bt8, bt9, bt10, iterations;

	// overridable by saved2 cvar on server console
	maxdecors = cvar("decors");
	// different number of decors in multi-player (to avoid lag on modems)
	if (maxdecors < 1)
	{
		if (maxclients > 1)
			maxdecors = 32;
		else if (cvar("dpmod_odephysics"))
			maxdecors = 50;
		else if (cvar("spawnmonsters"))
			maxdecors = 500;
		else
			maxdecors = 10000;
		if (cvar("ekg"))
			maxdecors = maxdecors * 5;
	}
	maxdecors = bound(1, maxdecors, 16384);

	// numdecors is allowed to be bogus as long as it is >= the real number of decors
	// (but perfection is clearly preferable)
	if (numdecors <= maxdecors)
	{
		decordecay = 0;
		return;
	}

	/*
	// recount all the decors
	numdecors = 0;
	estart = e = findchain(classname, "decor");
	while(e)
	{
		numdecors = numdecors + 1;
		e = e.chain;
	}
	if (numdecors <= maxdecors)
	{
		decordecay = 0;
		return; // nothing to do
	}
	*/

	// changed decor removal policy to simply make them have timeouts that only apply when the decor limit has been reached
	// the timeout rate depends on how far over the limit it is, so this does adapt to sudden excess

	if (numdecors > maxdecors)
		decordecay = frametime * (1 + 2 * numdecors / maxdecors);
	else
		decordecay = frametime;
	numdecors = 0;
	//e = estart;
	estart = e = findchain(classname, "decor");
	while(e)
	{
		numdecors = numdecors + 1;
		next = e.chain;
		e.cnt = e.cnt - decordecay;
		if (e.cnt <= 0)
			remove(e);
		e = next;
	}

/*
	// simply halve the remaining life time on all the decors so they will
	// disappear sooner
	e = estart;
	while(e)
	{
		if (e.cnt > time)
			e.cnt = e.cnt * 0.5 + time * 0.5;
		e = e.chain;
	}
*/
/*
	// limit it to considering 10000 entities per frame,
	// otherwise it can cause a runaway loop error
	iterations = 0;
	while (numdecors > maxdecors && iterations < 10000)
	{
		iterations = iterations + 1;
		// find and remove the oldest decors (upto 10 at once)
		b1 = b2  = b3  = b4  = b5  = b6 = b7 = b8 = b9 = b10 = world;
		bt1 = bt2 = bt3 = bt4 = bt5 = bt6 = bt7 = bt8 = bt9 = bt10 = time + 10000;
		if (iterations > 0)
			estart = findchain(classname, "decor");
		e = estart;
		while(e)
		{
			iterations = iterations + 1;
			if (e.createdtime < bt10)
			{
				if (e.createdtime < bt9)
				{
					if (e.createdtime < bt8)
					{
						if (e.createdtime < bt7)
						{
							if (e.createdtime < bt6)
							{
								if (e.createdtime < bt5)
								{
									if (e.createdtime < bt4)
									{
										if (e.createdtime < bt3)
										{
											if (e.createdtime < bt2)
											{
												if (e.createdtime < bt1)
												{
													b10=b9;bt10=bt9;
													b9=b8;bt9=bt8;
													b8=b7;bt8=bt7;
													b7=b6;bt7=bt6;
													b6=b5;bt6=bt5;
													b5=b4;bt5=bt4;
													b4=b3;bt4=bt3;
													b3=b2;bt3=bt2;
													b2=b1;bt2=bt1;
													b1=e;bt1=e.createdtime;
												}
												else
												{
													b10=b9;bt10=bt9;
													b9=b8;bt9=bt8;
													b8=b7;bt8=bt7;
													b7=b6;bt7=bt6;
													b6=b5;bt6=bt5;
													b5=b4;bt5=bt4;
													b4=b3;bt4=bt3;
													b3=b2;bt3=bt2;
													b2=e;bt2=e.createdtime;
												}
											}
											else
											{
												b10=b9;bt10=bt9;
												b9=b8;bt9=bt8;
												b8=b7;bt8=bt7;
												b7=b6;bt7=bt6;
												b6=b5;bt6=bt5;
												b5=b4;bt5=bt4;
												b4=b3;bt4=bt3;
												b3=e;bt3=e.createdtime;
											}
										}
										else
										{
											b10=b9;bt10=bt9;
											b9=b8;bt9=bt8;
											b8=b7;bt8=bt7;
											b7=b6;bt7=bt6;
											b6=b5;bt6=bt5;
											b5=b4;bt5=bt4;
											b4=e;bt4=e.createdtime;
										}
									}
									else
									{
										b10=b9;bt10=bt9;
										b9=b8;bt9=bt8;
										b8=b7;bt8=bt7;
										b7=b6;bt7=bt6;
										b6=b5;bt6=bt5;
										b5=e;bt5=e.createdtime;
									}
								}
								else
								{
									b10=b9;bt10=bt9;
									b9=b8;bt9=bt8;
									b8=b7;bt8=bt7;
									b7=b6;bt7=bt6;
									b6=e;bt6=e.createdtime;
								}
							}
							else
							{
								b10=b9;bt10=bt9;
								b9=b8;bt9=bt8;
								b8=b7;bt8=bt7;
								b7=e;bt7=e.createdtime;
							}
						}
						else
						{
							b10=b9;bt10=bt9;
							b9=b8;bt9=bt8;
							b8=e;bt8=e.createdtime;
						}
					}
					else
					{
						b10=b9;bt10=bt9;
						b9=e;bt9=e.createdtime;
					}
				}
				else
				{
					b10=e;bt10=e.createdtime;
				}
			}
			// failed all 10 slots
			e = e.chain;
		}
		// remove the oldest decors
		if (numdecors > maxdecors) {numdecors = numdecors - 1;remove(b1);}
		if (numdecors > maxdecors) {numdecors = numdecors - 1;remove(b2);}
		if (numdecors > maxdecors) {numdecors = numdecors - 1;remove(b3);}
		if (numdecors > maxdecors) {numdecors = numdecors - 1;remove(b4);}
		if (numdecors > maxdecors) {numdecors = numdecors - 1;remove(b5);}
		if (numdecors > maxdecors) {numdecors = numdecors - 1;remove(b6);}
		if (numdecors > maxdecors) {numdecors = numdecors - 1;remove(b7);}
		if (numdecors > maxdecors) {numdecors = numdecors - 1;remove(b8);}
		if (numdecors > maxdecors) {numdecors = numdecors - 1;remove(b9);}
		if (numdecors > maxdecors) {numdecors = numdecors - 1;remove(b10);}
	}
*/
};

// used for various little bouncing debris to avoid getting stuck in the air
void() DecorThink =
{
	self.nextthink = time;
	self.flags = self.flags - (self.flags & FL_ONGROUND);
	if (pointcontents(self.origin) == CONTENT_SOLID)
		removedecor(self);
};

void() InitDecors =
{
	if (game == GAME_NEXUIZ)
	{
		precache_model ("models/casing.mdl"); // brass bullet casing
		precache_model("models/gibs/bloodyskull.md3");
		precache_model("models/gibs/eye.md3");
		precache_model("models/gibs/gib1.mdl");
		precache_model("models/gibs/gib2.mdl");
		precache_model("models/gibs/gib3.mdl");
		precache_model("models/gibs/gib4.mdl");
	}
	else
	{
		precache_model ("progs/casing_bronze.mdl"); // bullet casing (made by Tomaz)
		precache_model ("progs/casing_steel.mdl"); // bullet casing (made by Tomaz)
		precache_model ("progs/casing_shell.mdl"); // shell casing (made by Tomaz)
		precache_sound ("weapons/tink1.wav");
		//precache_model ("progs/s_spike.mdl");  // nail in the wall (bullet hole)
		//precache_model ("progs/!blood.spr32"); // blood splat
		//precache_model ("progs/!bloodbig.spr32"); // huge blood pool
		//precache_model ("progs/!plasmamark.spr32");   // plasma scorch mark
		//precache_model ("progs/!pellethole.spr32");  // shotgun pellet hole
		//precache_model ("progs/!bullethole.spr32");  // nailgun hole
		precache_model("progs/gib1.mdl");
		precache_model("progs/gib2.mdl");
		precache_model("progs/gib3.mdl");
		precache_model("progs/rubble1.mdl");
		precache_model("progs/rubble2.mdl");
		precache_model("progs/rubble3.mdl");
		precache_model("progs/zom_gib.mdl");
		//precache_model("progs/dust.mdl"); // little metal piece
		precache_sound ("zombie/z_miss.wav");
	}
};




/*
==============================================================================

EFFECTS

==============================================================================
*/

/*
void() s_animthink =
{
	self.nextthink = time + 0.1;
	self.frame = self.frame + 1;
	if (self.frame >= self.dmg)
	{
		self.frame = self.dmg;
		self.think = SUB_Remove;
		self.nextthink = time + 0.2;
	}
*/
	/*
	self.nextthink = time; // max accuracy
	self.frame = floor((time - self.cnt) * self.lefty + self.cnt2);
	if (self.frame < 0 || self.frame >= self.dmg)
		remove(self);
	*/
/*
};

void(entity e, string m, float sstarttime, float sfirstframe, float sendframe) s_anim =
{
	setmodel(e, m);
	setsize(e, '-4 -4 -4', '4 4 4');
	e.cnt = sstarttime;
	e.cnt2 = sfirstframe;
	e.dmg = sendframe - 1;
	//e.lefty = sframerate;
	e.think = s_animthink;
	e.nextthink = time;
	e.frame = sfirstframe;
	e.effects = e.effects | EF_LOWPRECISION;
};
*/

void(vector org, vector vel, float amount) blood =
{
	te_blood(org, vel, amount);
	/*
	if (amount > 255) amount = 255;
	if (vlen(vel) > 127) vel = normalize(vel) * 127;
	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_BLOOD);
	WriteVec (MSG_BROADCAST, org);
	WriteByte (MSG_BROADCAST, vel_x);
	WriteByte (MSG_BROADCAST, vel_y);
	WriteByte (MSG_BROADCAST, vel_z);
	WriteByte (MSG_BROADCAST, amount);
	*/
};

void(vector org, vector vel, float amount) spark =
{
	te_spark(org, vel, amount);
	/*
	if (amount > 255) amount = 255;
	if (vlen(vel) > 127) vel = normalize(vel) * 127;
	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_SPARK);
	WriteVec (MSG_BROADCAST, org);
	WriteByte (MSG_BROADCAST, vel_x);
	WriteByte (MSG_BROADCAST, vel_y);
	WriteByte (MSG_BROADCAST, vel_z);
	WriteByte (MSG_BROADCAST, amount);
	*/
};

void(vector m1, vector m2, float vel, float amount) bloodshower =
{
	te_bloodshower(m1, m2, vel, amount);
	/*
	if (amount < 0)
		return;
	if (amount < 1)
		amount = (m2_x - m1_x)*(m2_y - m1_y)*(m2_z - m1_z)/64;
	if (amount < 1)
		return;
	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_BLOODSHOWER);
	WriteVec (MSG_BROADCAST, m1);
	WriteVec (MSG_BROADCAST, m2);
	WriteCoord (MSG_BROADCAST, vel);
	WriteShort (MSG_BROADCAST, amount);
	*/
};

void(vector org, float quad) bulletpuff =
{
	if (quad)
		te_gunshotquad(org);
	else
		te_gunshot(org);
};

void(vector org, float quad) nailpuff =
{
	if (quad)
		te_superspikequad(org);
	else
		te_superspike(org);
};




/*
==============================================================================

SHELL CASINGS

==============================================================================
*/

void() casingtouch =
{
	if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
	{
		remove(self);
		return;
	}
	if (other.solid == SOLID_BSP)
	{
		self.velocity = self.velocity * 0.8;
		if (vlen(self.velocity) >= 50)
		if (time >= self.attack_finished)
		if (self.origin != self.dest + self.groundentity.origin)
		{
			if (game != GAME_NEXUIZ)
				sound (self, CHAN_WEAPON, "weapons/tink1.wav", 0.5, ATTN_NORM);
			self.attack_finished = time + 0.2;
			//self.touch = SUB_Null; // one tink is enough
		}
	}
	self.dest = self.origin - self.groundentity.origin;
};

void() casingthink =
{
	local float p;
	self.nextthink = time + 0.1;
	if (self.flags & FL_ONGROUND)
	if (!self.lefty)
	{
	// just keep the yaw angle
		self.angles_x = 0;
		self.angles_z = 0;
		self.flags = self.flags - FL_ONGROUND;
		self.nextthink = time + 0.5;
	}
	p = pointcontents(self.origin);
	if (p == CONTENT_SOLID || p == CONTENT_LAVA || p == CONTENT_SKY)
	{
		removedecor(self);
		return;
	}
};

// knock loose the casing when disturbed
void() casingknockedloosefunc =
{
	self.lefty = FALSE;
	if (cvar("dpmod_odephysics"))
	{
		if (self.movetype != MOVETYPE_PHYSICS)
		{
			self.movetype = MOVETYPE_PHYSICS;
			self.solid = SOLID_PHYSICS_BOX;
			self.mass = 0.1;
			setmodel(self, self.model); // setmodel sets mins/maxs
		}
	}
	else
	{
		self.movetype = MOVETYPE_BOUNCE;
		self.flags = self.flags - (self.flags & FL_ONGROUND);
	}
	self.avelocity = randomvec() * 300;
	self.nextthink = time + 0.1;
	self.touch = casingtouch;
};

void(vector org, vector vel, float randomvel, vector ang, vector avel, float randomavel, float casingtype) ejectcasing =
{
	local entity e;
	if (cvar("temp1") & 2048)
		return;

	// if in danger of running out of entities, don't spawn any new ones
	if (numdecors >= 16384)
		return;

	e = newdecor(world);
	e.angles = ang;
	e.avelocity = avel + randomvec() * randomavel;
	e.forcescale = 5;
	e.knockedloosefunc = casingknockedloosefunc;
	e.movetype = MOVETYPE_BOUNCE;
	e.nextthink = time;
	e.solid = SOLID_TRIGGER;
	e.think = casingthink;
	e.touch = casingtouch;
	e.velocity = vel + randomvec() * randomvel;
	if (game == GAME_NEXUIZ)
	{
		setmodel (e, "models/casing.mdl");
		e.cnt = 10 * (0.5 + random());
	}
	else
	{
		if (casingtype == 1)
		{
			setmodel (e, "progs/casing_shell.mdl");
			e.cnt = 30 * (0.5 + random());
		}
		else if (casingtype == 2)
		{
			setmodel (e, "progs/casing_steel.mdl");
			e.cnt = 10 * (0.5 + random());
		}
		else
		{
			setmodel (e, "progs/casing_bronze.mdl");
			e.cnt = 10 * (0.5 + random());
		}
	}
	setsize (e, '0 0 -1', '0 0 -1');
	setorigin (e, org);

	if (cvar("dpmod_odephysics"))
	{
		e.movetype = MOVETYPE_PHYSICS;
		e.solid = SOLID_PHYSICS_BOX;
		e.mass = 0.1;
		//setsize(e, '-3 -1 -1', '3 1 1');
		setmodel(e, e.model); // setmodel sets mins/maxs
	}
};




/*
==============================================================================

DECALS (and stuck nails)

==============================================================================
*/

void(vector org, entity en, vector dir, string dmodel, float dskin, float dframe, float importance, float ismodel) newdecal =
{
	local vector dirangles;
	local entity e;
	if (cvar("temp1") & 2048)
		return;
	if (en.solid != SOLID_BSP || en.model == "")
		return;
	dir = normalize(dir);
	org = org + dir; // push it off the surface
	// to orient the bullet hole properly
	if (ismodel)
		dirangles = vectoangles(dir); // sprite bug
	else if (!ismodel)
	{
		dirangles = vectoangles('0 0 0' - dir); // sprite bug
		dirangles_x = 0 - dirangles_x; // sprite bug
	}

	e = findchain(classname, "decor");
	while (e != world)
	{
		if (e.angles == dirangles) // same surface
		if (e.model == dmodel) // same type of decal
		if (vlen(e.origin - org) < 4) // remove existing mark
			remove(e);
		e = e.chain;
	}

	if (importance >= 1000) // permanent
	{
		e = spawn();
		e.classname = "permanentdecal";
	}
	else
	{
		// if in danger of running out of entities, don't spawn any new ones
		if (numdecors >= 16384)
			return;
		e = newdecor(world);
		e.cnt = importance * (0.5 + random());
	}
	e.skin = dskin;
	e.frame = dframe;
	e.angles = dirangles;
	setmodel (e, dmodel);
	setsize (e, '0 0 0', '0 0 0');
	setorigin (e, org);
	if (en != world) // might be a mobile surface, follow it
	{
		e.aiment = en;
		e.view_ofs = org - en.origin;
		e.punchangle = en.angles; // base angles
		e.v_angle = e.angles - en.angles;
		e.movetype = MOVETYPE_FOLLOW;
	}
};

// make a bullet hole
/*
void(vector org, entity en, vector dir, float holetype) newbullethole =
{
	local float r;
	r = random() * 0.999;
	if (holetype == 0) // bullet hole
		newdecal(org, en, dir, "progs/!bullethole.spr32", 0, r * 10, 0);
	else if (holetype == 1) // shotgun pellet hole
		newdecal(org, en, dir, "progs/!pellethole.spr32", 0, r * 10, 0);
	else                    // small burn mark
		newdecal(org, en, dir, "progs/!plasmamark.spr32", 0, r * 10, 0);
};
*/

// make a blood splat
/*
void(vector org, entity en, vector dir, float splattype, float importance) newbloodsplat =
{
	local float r;
	r = random() * 0.999;
	if (splattype == 1) // huge blood pool
		newdecal(org, en, dir, "progs/!bloodbig.spr32", 0, r * 5, importance);
	else // blood splat
		newdecal(org, en, dir, "progs/!blood.spr32", 0, r * 10, importance);
};
*/

// make a spike in the wall
void(vector org, entity en, vector dir) newwallspike =
{
	local entity e;
	if (cvar("temp1") & 2048)
		return;
	if (en.solid != SOLID_BSP || en.model == "")
		return;
	// if in danger of running out of entities, don't spawn any new ones
	if (numdecors >= 16384)
		return;
	dir = normalize(dir);

	e = newdecor(world);
	e.cnt = 10 * (0.5 + random());
	e.angles = vectoangles(dir);
	e.flags = FL_ONGROUND;
	e.forcescale = 5;
	e.groundentity = en;
	e.knockedloosefunc = casingknockedloosefunc;
	e.movetype = MOVETYPE_BOUNCE;
	e.nextthink = time;
	e.solid = SOLID_TRIGGER;
	e.think = casingthink;
	e.touch = casingtouch;
	e.lefty = TRUE;
	setmodel (e, "progs/s_spike.mdl");
	setsize (e, '0 0 0', '0 0 0');
	setorigin (e, org - dir * 3);
	if (en != world) // might be a mobile surface, follow it
	{
		e.aiment = en;
		e.view_ofs = org - en.origin;
		e.v_angle = e.angles - en.angles;
		e.movetype = MOVETYPE_FOLLOW;
	}

	if (cvar("dpmod_odephysics"))
	{
		//e.solid = SOLID_PHYSICS_BOX;
		e.mass = 0.1;
		//setsize(e, '-3 -1 -1', '3 1 1');
		setmodel(e, e.model); // setmodel sets mins/maxs
	}
};


// puts bullet holes on the nearest walls
/*
void(vector org, float holetype) blastmarkarea =
{
	local float c, d;
	local vector v, tpn;
	d = 6; // only very close
	c = 0;
	while (c < 20)
	{
		c = c + 1;
		v = normalize(randomvec()) * d;
		traceline(org, org + v, TRUE, world);
		if (trace_fraction < 1)
		if (trace_ent.solid == SOLID_BSP)
		{
			tpn = trace_plane_normal;
			v = '0 0 0' - tpn;
			traceline(org, org + v * 32, TRUE, world);
			if (trace_plane_normal == tpn) // same surface
				newbullethole(trace_endpos, trace_ent, trace_plane_normal, 0, holetype);
		}
	}
};
*/




/*
==============================================================================

GIBS

==============================================================================
*/

// make the gib spin in the air when knocked loose
void() gibknockedloosefunc =
{
	self.flags = self.flags - (self.flags & FL_ONGROUND);
	self.avelocity = randomvec() * 200;
};

void() debristouch =
{
	if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
	{
		remove(self);
		return;
	}
};

void() debristhink =
{
	self.nextthink = time + 0.5;
	self.flags = self.flags - (self.flags & FL_ONGROUND);
}

.float isdecor;
void(entity e, vector org, vector vel, string gibname, float s) ThrowDebris =
{
	if (e)
		e = newdecor(e);
	else
	{
		// if in danger of running out of entities, don't spawn any new ones
		if (numdecors >= 16384)
			return;
		e = newdecor(world);
		e.angles = randomvec() * 360;
	}
	e.forcescale = 2;
	e.cnt = 30 * (0.5 + random());
	setorigin(e, org);
	setmodel (e, gibname);
	setsize (e, '0 0 -8', '0 0 -8');
	e.view_ofs = '0 0 -1';
	e.velocity = vel + randomvec() * 150;
	e.movetype = MOVETYPE_BOUNCE;
	e.avelocity = randomvec()*300;
	e.knockedloosefunc = gibknockedloosefunc;
	e.skin = s; // style of rubble (see func_xplowall for info)
	e.takedamage = DAMAGE_YES;
	e.bleedfunc = genericbleedfunc;
	e.touch = debristouch;
	e.th_die = SUB_Null;
	e.th_gib = SUB_Null;
	e.th_pain = SUB_Null;
	e.think = debristhink;
	e.nextthink = time;

	if (cvar("dpmod_odephysics"))
	{
		e.movetype = MOVETYPE_PHYSICS;
		e.solid = SOLID_PHYSICS_BOX;
		e.mass = 5;
		setmodel(e, e.model); // setmodel sets mins/maxs
	}
};

entity(vector org, vector vel, string modelname) Ragdoll_ThrowGib;

void() meatspraytouch =
{
	if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
	{
		remove(self);
		return;
	}
	if (other.solid != SOLID_BSP)
		return;
	if (trace_plane_normal_z > 0.7)
	{
		remove(self);
		return;
	}
	if (trace_plane_normal_z == 0)
	{
		sound(self, CHAN_WEAPON, "zombie/z_miss.wav", 1, ATTN_NORM);
		self.nextthink = self.nextthink + 5;
		self.velocity = '0 0 -0.1' * cvar("sv_gravity");
		self.gravity = 0.01;
	}
};

void() ThrowMeatSpray =
{
	local vector org;
	local entity e;
	// don't throw a gib if in a NODROP zone (such as lava)
	traceline(self.origin, self.origin, MOVE_NORMAL, self);
	if (trace_dpstartcontents & DPCONTENTS_NODROP)
		return;
	// if in danger of running out of entities, don't spawn any new ones
	if (numdecors >= 16384)
		return;
	org = self.origin + randompos(self.mins, self.maxs);
	e = newdecor(world);
	e.angles = randomvec() * 360;
	e.forcescale = 4;
	setorigin(e, org);
	setmodel (e, "progs/zom_gib.mdl");
	setsize (e, '0 0 0', '0 0 0');
	e.velocity = randomvec() * 500;
	e.avelocity = randomvec()*300;
	e.movetype = MOVETYPE_BOUNCE;
	e.solid = SOLID_TRIGGER;
	e.knockedloosefunc = gibknockedloosefunc;
	e.think = SUB_Remove;
	e.nextthink = time + 1;
	e.touch = meatspraytouch;

	if (cvar("dpmod_odephysics"))
	{
		e.movetype = MOVETYPE_PHYSICS;
		e.solid = SOLID_PHYSICS_BOX;
		e.mass = 1;
		setmodel(e, e.model); // setmodel sets mins/maxs
	}
};

void(string gibname) ThrowGib =
{
	local vector org;
	// don't throw a gib if in a NODROP zone (such as lava)
	traceline(self.origin, self.origin, MOVE_NORMAL, self);
	if (trace_dpstartcontents & DPCONTENTS_NODROP)
		return;
	org = self.origin + randompos(self.mins, self.maxs);
	org_z = bound(self.origin_z + self.mins_z + 8, org_z, self.origin_z + self.maxs_z + 8);
	if (cvar("dpmod_qcphysics_gibs"))
		Ragdoll_ThrowGib(org, '0 0 0', gibname);
	else
		ThrowDebris(world, org, '0 0 0', gibname, 0);
};

void(string gibname) ThrowHead =
{
	local vector org;
	if (cvar("dpmod_qcphysics_gibs"))
	{
		Ragdoll_ThrowGib(self.origin + self.view_ofs, '0 0 0', gibname);
		self.model = "";
	}
	else
	{
		// don't use a visible head gib in a NODROP zone (such as lava)
		traceline(self.origin, self.origin, MOVE_NORMAL, self);
		if (trace_dpstartcontents & DPCONTENTS_NODROP)
		{
			self.model = "";
			return;
		}

		org = self.origin + self.view_ofs;
		org_z = bound(self.origin_z + self.mins_z + 8, org_z, self.origin_z + self.maxs_z + 8);
		ThrowDebris(self, org, '0 0 0', gibname, 0);
	}
};

/*
==============================================================================

CORPSES

==============================================================================
*/

void() corpsedie =
{
	self.takedamage = DAMAGE_NO;
	self.touch = SUB_Null;
	self.th_die = SUB_Null;
	self.solid = SOLID_NOT;
	setsize (self, self.mins, self.maxs); // relink
	//self.think = self.th_gib;
	//self.nextthink = time; // as soon as possible
	self.th_gib();
};

void(vector bmins, vector bmaxs) body_solid =
{
	if (self.solid == SOLID_SLIDEBOX)
	if (bmins == self.mins)
	if (bmaxs == self.maxs)
		return;
	self.solid = SOLID_SLIDEBOX;
	setsize (self, bmins, bmaxs); // relink
};

void(vector bmins, vector bmaxs) body_nonsolid =
{
	if (self.solid == SOLID_CORPSE)
	if (bmins == self.mins)
	if (bmaxs == self.maxs)
		return;
	self.solid = SOLID_CORPSE;
	setsize (self, bmins, bmaxs); // relink
};

void() bodyfirstthink =
{
	local float wasfrozen;
	wasfrozen = self.frozen;
	restorefrozenentity(self);
	self.movetype = MOVETYPE_TOSS;
	setorigin(self, self.oldorigin); // relink
	self.flags = 0; // clear FL_ONGROUND etc
	if (self.bodyhealth < 1 || cvar("ekg"))
		self.th_die();
	else
	{
		self.think = self.think1;
		if (self.think)
			self.think();
		if (wasfrozen)
			refreezefrozenentity(self);
	}
};

.float iscreature;
.float bubble_count;

/*
// call this the moment the monster/player/bot etc dies,
// it will do the anim you give it if not a gib, or immediately gib.
// you should use BecomeCorpse2() for monsters, so the edicts are freed.
// (unlike normal quake, where corpses/heads hang around *FOREVER*)
*/
void(entity c, void() framefunc) BecomeCorpse =
{
	local entity saveself;
	saveself = self;
	self = c;
	self.havocattack = FALSE;
	self.touch = SUB_Null;
	self.th_pain = SUB_Null;
	self.th_walk = SUB_Null;
	self.th_melee = SUB_Null;
	self.th_missile = SUB_Null;
	self.th_run = SUB_Null;
	self.th_stand = SUB_Null;
	self.iscorpse = TRUE;
	self.cantrigger = FALSE;
	self.th_die = corpsedie;
	self.takedamage = DAMAGE_YES;
	self.movetype = MOVETYPE_NONE;
	self.angles_x = self.angles_z = 0; // make sure it's not tilted
	self.avelocity = '0 0 0'; // make sure it won't spin
	self.think1 = framefunc; // first frame of death animation
	self.think = bodyfirstthink;
	self.nextthink = time;
	self.flags = 0;
	self.oldorigin = self.origin + '0 0 1';

	if (self.bodyhealth < 1 || cvar("ekg"))
		self.th_die();
	self = saveself;
};

void(entity t) CopyToBodyQue =
{
	local entity c;
	// if in danger of running out of entities, don't spawn any new ones
	if (numdecors >= 16384)
		return;
	c = newdecor(world);
	c.cnt = 100 * (0.5 + random());
	c.iscorpse = TRUE;

	c.angles = t.angles;
	c.model = t.model;
	c.modelindex = t.modelindex;
	c.frame = t.frame;
	c.skin = t.skin;
	c.colormap = t.colormap;
	c.movetype = t.movetype;
	c.velocity = t.velocity;
	c.solid = t.solid;
	c.avelocity = t.avelocity;
	c.forcescale = t.forcescale;
	c.deathmsg = t.deathmsg;
	c.bleedfunc = t.bleedfunc;
	c.bubble_count = t.bubble_count;
	c.think1 = t.think1;
	c.think = t.think;
	c.nextthink = t.nextthink;
	c.iscreature = t.iscreature;
	c.bodyhealth = t.bodyhealth;
	c.health = t.health;
	c.armortype = t.armortype;
	c.armorvalue = t.armorvalue;
	c.th_die = t.th_die;
	c.th_gib = t.th_gib;
	c.takedamage = t.takedamage;
	c.frozen = t.frozen;
	// if on fire, transfer the flame to the corpse
	if (t.flame)
	{
		c.flame = t.flame;
		c.flame.enemy = c;
	}

	setorigin (c, t.origin);
	setsize (c, t.mins, t.maxs);
	c.oldorigin = t.origin;
	c.flags = 0; // clear FL_ONGROUND etc
};

// used specifically by monsters, choose any of the above methods
// here to affect all monsters except zombies.
void(entity t, void() framefunc) MonsterCorpse =
{
	// setup for recycling
	BecomeCorpse(t, framefunc);
	CopyToBodyQue(t);
	remove(t);
};

void(string headname, float gibs, string gibname1, float gibs1, string gibname2, float gibs2) MonsterGibs =
{
	// gibs is generic gibs, headname is the head,
	// gibs1/gibname1 and gibs2/gibname2 are specialty debris
	local float r, gibmultiplier;
	// make self non-solid while spawning gibs
	self.solid = SOLID_NOT;
	setorigin(self, self.origin);
	// prevent gibs from replacing their corpse if their corpse is a decor
	self.cnt = self.cnt + 10;
	gibmultiplier = cvar("dpmod_gibbagemultiplier");
	if (cvar("ekg"))
		gibmultiplier = gibmultiplier * 5;
	gibs = gibs * gibmultiplier;
	gibs1 = gibs1 * gibmultiplier;
	gibs2 = gibs2 * gibmultiplier;
	// spawn gibs
	if (game == GAME_NEXUIZ)
	{
		while (gibs > 0) {gibs = gibs - 1;ThrowMeatSpray();r = random() * 4;if (r < 1) ThrowGib("models/gibs/gib1.mdl");else if (r < 2) ThrowGib("models/gibs/gib2.mdl");else if (r < 3) ThrowGib("models/gibs/gib3.mdl");else ThrowGib("models/gibs/gib4.mdl");}
	}
	else
	{
		while (gibs > 0) {gibs = gibs - 1;ThrowMeatSpray();r = random() * 3;if (r < 1) ThrowGib("progs/gib1.mdl");else if (r < 2) ThrowGib("progs/gib2.mdl");else ThrowGib("progs/gib3.mdl");}
	}
	while (gibs1 > 0) {gibs1 = gibs1 - 1;ThrowGib(gibname1);}
	while (gibs2 > 0) {gibs2 = gibs2 - 1;ThrowGib(gibname2);}
	// now become a head
	if (headname) ThrowHead(headname);
};

void(string headname, float gibs, string gibname1, float gibs1, string gibname2, float gibs2) PlayerGibs =
{
	MonsterGibs(headname, gibs, gibname1, gibs1, gibname2, gibs2);
};

//.float bleeddamagecount;
void(vector org, float bodydamage, float armordamage, vector force, float damgtype) genericbleedfunc =
{
	local vector v;
	v = '0 0 0' - force * 0.05;
	if (armordamage > 0)
		spark(org, v, armordamage * 3);
	if (bodydamage > 0)
		blood(org, v, bodydamage);

	if (cvar("temp1") & 2048)
		return;
};

void() deadbodygib =
{
	self.solid = SOLID_NOT;
	sound (self, CHAN_VOICE, "player/udeath.wav", 1, ATTN_NORM);
	MonsterGibs(self.deathtype, self.count, "", 0, "", 0);
};

// creates a generic dead body, used by dead_ monsters
void(string modelname, string headname, void() animfuncname, float gibcount, float forcescalevalue, float bhealth) deadmonstersetup =
{
	precache_model (modelname);
	precache_model (headname);
	self.deathtype = headname;
	self.count = gibcount;
	self.forcescale = forcescalevalue;
	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_TOSS;
	self.takedamage = DAMAGE_YES;
	self.iscreature = TRUE;
	self.bleedfunc = genericbleedfunc;
	self.health = -1;
	self.bodyhealth = bhealth;
	self.th_gib = deadbodygib;

	setmodel (self, modelname);
	setorigin(self, self.origin);

	BecomeCorpse(self, animfuncname);
};

void() dead_gibs_doit =
{
	MonsterGibs(self.mdl, self.count, "", 0, "", 0);
};

/*QUAKED dead_gibs (1 0 0) (-16 -16 -16) (16 16 16)
Splatters the area with gibs and creates a large pool

keys:
"targetname"
 explodes in gibs when triggered
 (does so only once)
"count"
 number of gibs (default: 6)
"mdl"
 head model (normally no head is thrown)
*/
void() dead_gibs =
{
	if (self.mdl)
		precache_model(self.mdl);
	if (self.count == 0)
		self.count = 6;
	setorigin(self, self.origin);
	setsize(self, '-16 -16 -16', '16 16 16');
	if (self.targetname)
	{
		self.use = dead_gibs_doit;
		return;
	}
	dead_gibs_doit();
};

void() dead_bloodarea_doit =
{
	bloodshower(self.origin - '16 16 16', self.origin + '16 16 16', 200, self.count * 10);
	remove(self);
};

/*QUAKED dead_bloodarea (1 0 0) (-16 -16 -16) (16 16 16)
Splatters the area with blood

keys:
"targetname"
 explodes in blood when triggered
"count"
 number of splatters (default: 6)
*/
void() dead_bloodarea =
{
	if (self.count == 0)
		self.count = 6;
	if (self.targetname)
	{
		self.use = dead_bloodarea_doit;
		return;
	}
	dead_bloodarea_doit();
};




/*
==============================================================================

PHYSICS EXPERIMENTS

==============================================================================
*/

.float ragdoll_bounce; // used on particles, recommended 1.2
.float ragdoll_friction; // used on particles, recommended 0.05
.entity ragdoll_next; // next particle/stick in list
.entity ragdoll_particlelist; // first entity in particle list of this body
.entity ragdoll_sticklist; // first entity in stick list of this body
.entity ragdoll_p1; // particle 1 of this stick (start)
.entity ragdoll_p2; // particle 2 of this stick (end)
.entity ragdoll_p3; // particle 3 of this stick (rotation)
.float ragdoll_mass;
.float ragdoll_inversemass;
.float ragdoll_preferredlength; // preferred length of this stick
.float ragdoll_lockdown;

void(float fscale) Ragdoll_ApplyAcceleration =
{
	local entity part;
	local float grav;
	grav = sv_gravity * fscale;
	part = self.ragdoll_particlelist;
	while (part)
	{
		part.velocity_z = part.velocity_z - grav;
		// go to the next particle
		part = part.ragdoll_next;
	}
}

void() Ragdoll_ClearLockdownFlags =
{
	local entity part;
	part = self.ragdoll_particlelist;
	while (part)
	{
		part.ragdoll_lockdown = FALSE;
		// go to the next particle
		part = part.ragdoll_next;
	}
}

void(float ftime, float iterations) Ragdoll_ApplyConstraints =
{
	local float iftime, iter;
	local entity stick, p1, p2, part;
	local vector offset, diff;
	iftime = 1 / ftime;
	part = self.ragdoll_particlelist;
	while (part)
	{
		part.dest = part.origin + part.velocity * ftime;
		part = part.ragdoll_next;
	}
	iter = 0;
	while (iter < iterations)
	{
		iter = iter + 1;
		stick = self.ragdoll_sticklist;
		while (stick)
		{
			p1 = stick.ragdoll_p1;
			p2 = stick.ragdoll_p2;
			if (p1.ragdoll_lockdown)
			{
				if (!p2.ragdoll_lockdown)
				{
					diff = p2.dest - p1.dest;
					offset = normalize(diff) * stick.ragdoll_preferredlength - diff;
					p2.dest = p2.dest + offset;
				}
			}
			else if (p2.ragdoll_lockdown)
			{
				diff = p2.dest - p1.dest;
				offset = normalize(diff) * stick.ragdoll_preferredlength - diff;
				p1.dest = p1.dest - offset;
			}
			else
			{
				diff = p2.dest - p1.dest;
				offset = (normalize(diff) * stick.ragdoll_preferredlength - diff) * 0.5;
				p1.dest = p1.dest - offset;
				p2.dest = p2.dest + offset;
			}
			stick = stick.ragdoll_next;
		}
	}
	part = self.ragdoll_particlelist;
	while (part)
	{
		part.velocity = (part.dest - part.origin) * iftime;
		part = part.ragdoll_next;
	}
/*
	stick = self.ragdoll_sticklist;
	while (stick)
	{
		p1 = stick.ragdoll_p1;
		p2 = stick.ragdoll_p2;
		if (p1.ragdoll_lockdown)
		{
			if (!p2.ragdoll_lockdown)
			{
				p1new = p1.origin;
				p2new = p2.origin + p2.velocity * ftime;
				offset = (normalize(p2new - p1new) * stick.ragdoll_preferredlength - (p2new - p1new)) * iftime;
				p2.velocity = p2.velocity + offset;
			}
		}
		else if (p2.ragdoll_lockdown)
		{
			p1new = p1.origin + p1.velocity * ftime;
			p2new = p2.origin;
			offset = (normalize(p2new - p1new) * stick.ragdoll_preferredlength - (p2new - p1new)) * iftime;
			p1.velocity = p1.velocity - offset;
		}
		else
		{
			p1new = p1.origin + p1.velocity * ftime;
			p2new = p2.origin + p2.velocity * ftime;
			offset = (normalize(p2new - p1new) * stick.ragdoll_preferredlength - (p2new - p1new)) * iftime * 0.5;
			p1.velocity = p1.velocity - offset;
			p2.velocity = p2.velocity + offset;
		}
		stick = stick.ragdoll_next;
	}
*/
}

void(float ftime) Ragdoll_ApplySequentialConstraints =
{
	local entity part;
	part = self.ragdoll_particlelist;
	while (part)
	{
		Ragdoll_ApplyConstraints(ftime, 1);
		part.ragdoll_lockdown = TRUE;
		part = part.ragdoll_next;
	}
}

void(float ftime) Ragdoll_ApplyFriction =
{
	local entity part;
	local float f;
	local float applied;
	local vector o;
	// counteract some units of velocity based on friction for any particles
	// that are currently held against a surface by acceleration
	applied = FALSE;
	part = self.ragdoll_particlelist;
	while (part)
	{
		o = part.origin + '0 0 1' * part.mins_z;
		traceline(o, o - '0 0 1', MOVE_NORMAL, self);
		if (trace_fraction < 1)
		{
/*
			f = bound(0, 1 - part.ragdoll_friction * 0.1, 1);
			if (f > 0)
				part.velocity = part.velocity * f;
*/
			f = bound(0, vlen(part.velocity), part.ragdoll_friction * 300 * ftime);
			if (f > 0)
				part.velocity = part.velocity - normalize(part.velocity) * f;
			applied = TRUE;
		}
		// go to the next particle
		part = part.ragdoll_next;
	}

	// damping does not seem to help with unstable systems and serves no other real purpose
/*
	// if friction is applied, we also apply a damping effect to cause the
	// entire system to lose energy
	if (applied)
	{
		part = self.ragdoll_particlelist;
		while (part)
		{
			part.velocity = part.velocity * (1 - ftime);
			// go to the next particle
			part = part.ragdoll_next;
		}
	}
*/
};

float(float ftime, float restlimit) Ragdoll_Move =
{
	local entity part;
	local float t, bump, resting;
	local vector force;
	resting = TRUE;
	part = self.ragdoll_particlelist;
	while (part)
	{
		// move particle repeatedly until the time slice is used up
		// (deals with bounces)
		part.oldorigin = part.origin;
		t = ftime;
		bump = 0;
		while (bump < 16)
		{
			bump = bump + 1;
			// check if there was an impact
			tracebox(part.origin, part.mins, part.maxs, part.origin + part.velocity * t, MOVE_NORMAL, self);
			if (trace_fraction == 1)
			{
				// ignore successful moves over short distances after the
				// first bump, as they tend to destabilize the constraints
				// no impact, update origin to the new position
				setorigin(part, trace_endpos);
				// we're done!
				break;
			}
			// impact detected
			if (part.velocity * trace_plane_normal < 0)
			{
				// reflect the velocity off the plane (bounce)
				// BUG: ragdoll_bounce occurs in addition to the natural spring back of the sticks when flattened against a surface...
				if (trace_ent.classname == "ragdoll_particle")
				{
					// hack to make particles behave sort of spherically
					trace_plane_normal = normalize(part.origin - trace_ent.origin);
					// calculate impulse (impact force)
					force = trace_plane_normal * (trace_plane_normal * (part.velocity * part.ragdoll_mass - trace_ent.velocity * trace_ent.ragdoll_mass));
					// apply to both particles (in opposite directions)
					part.velocity = part.velocity - force * part.ragdoll_inversemass * part.ragdoll_bounce;
					trace_ent.velocity = part.velocity + force * part.ragdoll_inversemass * part.ragdoll_bounce;
				}
				else
					part.velocity = part.velocity - (trace_plane_normal * (trace_plane_normal * part.velocity)) * part.ragdoll_bounce;
				// never come to rest on a pusher
				if (trace_ent != world)
					resting = FALSE;
			}
			// reduce remaining time
			t = t * (1 - trace_fraction);
			// if at least a little progress was made, update origin
			// don't accept very short moves as they tend to cause jitter
			if (trace_fraction >= 0.0001)
			{
				// update origin to the new position
				setorigin(part, trace_endpos);
			}
		}
		if (vlen(part.origin - part.oldorigin) >= restlimit)
			resting = FALSE;
		// lock down this particle now that it has moved
		//part.ragdoll_lockdown = TRUE;
		// apply constraints again, honoring this newly locked particle
		//Ragdoll_ApplyConstraints(ftime);
		// go to the next particle
		part = part.ragdoll_next;
	}
	// if not significantly disturbed, reset the whole system back to the old
	// values, this hides minor jitter when resting
	if (resting)
	{
		part = self.ragdoll_particlelist;
		while (part)
		{
			setorigin(part, part.oldorigin);
			part = part.ragdoll_next;
		}
	}
	return resting;
}

void() Ragdoll_UpdateStickModels =
{
	local entity stick;
	local vector org1, org2, org3, offset;
	stick = self.ragdoll_sticklist;
	while (stick)
	{
		if (stick.modelindex)
		{
			org1 = stick.ragdoll_p1.origin;
			org2 = stick.ragdoll_p2.origin;
			setorigin(stick, (org1 + org2) * 0.5);
			if (stick.ragdoll_p3)
			{
				stick.angles = vectoangles(org2 - org1);
				org3 = stick.ragdoll_p3.origin;
				makevectors(stick.angles_x * '-1 0 0' + stick.angles_y * '0 1 0');
				offset = org3 - org1;
				stick.angles_z = vectoyaw((offset * v_right) * '-1 0 0' + (offset * v_up) * '0 1 0');
				//stick.angles = vectoangles2(org2 - org1, org3 - org1);
				makevectors(stick.angles_x * '-1 0 0' + stick.angles_y * '0 1 0' + stick.angles_z * '0 0 1');
				stick.angles = vectoangles2(v_forward, v_up);
				vectoangles2('0 0 1', '231 8943 0');
				vectoangles('0 0 1');
				offset = randomvec() * 360;
				offset_x = 90;
				makevectors(offset);
				vectoangles2(v_forward, v_up);
				vectoangles(v_forward);
			}
			else
				stick.angles = vectoangles(org2 - org1);
		}
		stick = stick.ragdoll_next;
	}
}

void() Ragdoll_KnockedLooseFunc =
{
	// clear parent's rest state so it will start moving again
	self.owner.dmg = FALSE;
};

void(entity ragdoll) Ragdoll_Remove;
// implicit euler/verlet hybrid
void() Ragdoll_Think =
{
	local float ftime;
	if (time >= self.lefty)
	{
		Ragdoll_Remove(self);
		return;
	}

	self.nextthink = time;

	while (self.ltime < time)
	{
		ftime = bound(1.0 / 1024.0, time - self.ltime, 1.0 / 128.0);
		self.ltime = self.ltime + ftime;
		if (self.dmg)
			continue;
		// prepare for an update
		// basically, we clear the lockdown flags, then apply impulses and
		// accelerations, then we constrain all the particles so that their
		// future position at the end of the frame is sensible
		// then we move each particle in turn and lock down its position,
		// altering all other particles to conform
		//
		// this method of impulse and acceleration is what I call half-step
		// velocity verlet integration, which applies half the acceleration
		// before the move and half after, giving exactly the same result as
		// standard velocity verlet if no constraints or collisions occur, but
		// allowing constraints and movement to be performed on velocity
		// rather than extrapolated position (which changes often during this)
		Ragdoll_ClearLockdownFlags();
		// add half of the acceleration before constraints and movement
		Ragdoll_ApplyAcceleration(ftime * 0.5);
		// apply constraints to the velocities
		Ragdoll_ApplyConstraints(ftime, 2);
		// apply constraints again
		//Ragdoll_ApplySequentialConstraints(ftime);
		// apply friction to any particles currently stuck to the floor
		Ragdoll_ApplyFriction(ftime);
		// move particles to new proposed locations based on velocity, and
		// deal with any impacts along the way,
		self.dmg = Ragdoll_Move(ftime, ftime * 10);
		// add the other part of the acceleration
		Ragdoll_ApplyAcceleration(ftime * 0.5);
	}
	// update stick models
	Ragdoll_UpdateStickModels();
};

entity(float expirationdate, entity own) Ragdoll_Spawn =
{
	local entity e;
	e = spawn();
	e.classname = "ragdoll";
	e.think = Ragdoll_Think;
	e.nextthink = time;
	e.ltime = time;
	e.lefty = time + expirationdate;
	e.owner = own;
	return e;
};

void(entity ragdoll) Ragdoll_Remove =
{
	local entity e, next;
	e = ragdoll.ragdoll_particlelist;
	while (e)
	{
		next = e.ragdoll_next;
		remove(e);
		e = next;
	}
	e = ragdoll.ragdoll_sticklist;
	while (e)
	{
		next = e.ragdoll_next;
		remove(e);
		e = next;
	}
	remove(ragdoll);
};

entity(entity ragdoll, vector org, vector vel, vector m1, vector m2, float mas, float forcescal, float bouncefactor, float frictionfactor) Ragdoll_AddParticle =
{
	local entity e;
	e = spawn();
	e.classname = "ragdoll_particle";
	e.owner = ragdoll;
	e.ragdoll_next = e.owner.ragdoll_particlelist;
	e.owner.ragdoll_particlelist = e;
	e.ragdoll_mass = mas;
	e.ragdoll_inversemass = 1.0 / mas;
	e.ragdoll_bounce = bouncefactor;
	e.ragdoll_friction = frictionfactor;
	e.forcescale = forcescal;
	e.takedamage = DAMAGE_YES;
	e.th_die = SUB_Null;
	e.th_gib = SUB_Null;
	e.th_pain = SUB_Null;
	e.knockedloosefunc = Ragdoll_KnockedLooseFunc;
	e.solid = SOLID_TRIGGER;//BBOX;
	e.movetype = MOVETYPE_NONE;
	e.velocity = vel;
	setorigin(e, org);
//	setmodel(e, "progs/s_bubble.spr"); // debugging
	setsize(e, m1, m2);
	return e;
};

entity(entity ragdoll, entity p1, entity p2, entity p3, string modelname) Ragdoll_AddStick =
{
	local entity e;
	e = spawn();
	e.classname = "ragdoll_stick";
	e.owner = ragdoll;
	e.ragdoll_next = e.owner.ragdoll_sticklist;
	e.owner.ragdoll_sticklist = e;
	e.ragdoll_p1 = p1;
	e.ragdoll_p2 = p2;
	e.ragdoll_p3 = p3;
	e.ragdoll_preferredlength = vlen(p2.origin - p1.origin);
	if (modelname != "")
		setmodel(e, modelname);
	return e;
};

entity(vector org1, vector vel1, vector org2, vector vel2, string modelname) Ragdoll_ThrowCasing =
{
	local entity r, p1, p2, s;
	r = Ragdoll_Spawn(60, self);
	p1 = Ragdoll_AddParticle(r, org1, vel1, '-1 -1 -1', '1 1 1', 1, 6, 1.5, 0.2);
	p2 = Ragdoll_AddParticle(r, org2, vel2, '-1 -1 -1', '1 1 1', 1, 6, 1.5, 0.2);
	s = Ragdoll_AddStick(r, p1, p2, world, modelname);
	s.solid = SOLID_CORPSE;
	setsize(s, '-3 -3 -1', '3 3 1');
	return r;
};

entity(vector org, vector vel, string modelname) Ragdoll_ThrowGib =
{
	local entity r, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, s;
	r = Ragdoll_Spawn(60, world);
	makevectors(randomvec() * 360);
	if (modelname == "progs/gib1.mdl")
	{
		// arm piece
		p1 = Ragdoll_AddParticle(r, org + v_forward * -8, vel + randomvec() * 150, '-1 -1 -3', '1 1 3', 0.5, 5, 1.5, 1.0);
		//p2 = Ragdoll_AddParticle(r, org + v_forward *  8, vel + randomvec() * 150, '-1 -1 -3', '1 1 3', 0.5, 5, 1.5, 1.0);
		p3 = Ragdoll_AddParticle(r, org + v_right *  2, vel + randomvec() * 150, '-1 -1 -3', '1 1 3', 0.5, 5, 1.5, 1.0);
		p4 = Ragdoll_AddParticle(r, org + v_right * -2, vel + randomvec() * 150, '-1 -1 -3', '1 1 3', 0.5, 5, 1.5, 1.0);
		//Ragdoll_AddStick(r, p1, p2, world, "");
		Ragdoll_AddStick(r, p1, p3, world, "");
		Ragdoll_AddStick(r, p1, p4, world, "");
		//Ragdoll_AddStick(r, p2, p3, world, "");
		//Ragdoll_AddStick(r, p2, p4, world, "");
		s = Ragdoll_AddStick(r, p3, p4, p1, modelname);
		s.solid = SOLID_CORPSE;
		setsize(s, '-8 -8 -2', '8 8 2');
	}
	else if (modelname == "progs/gib2.mdl")
	{
		// rib cage
		p1 = Ragdoll_AddParticle(r, org + v_forward *  12, vel + randomvec() * 150, '-1 -1 -1', '1 1 1', 1.5, 5, 1.5, 1.0);
		p2 = Ragdoll_AddParticle(r, org + v_forward * -12, vel + randomvec() * 150, '-1 -1 -1', '1 1 1', 1.5, 5, 1.5, 1.0);
		p3 = Ragdoll_AddParticle(r, org + v_forward * 8 + v_right   *  12, vel + randomvec() * 150, '-1 -1 -1', '1 1 1', 1.5, 5, 1.5, 1.0);
		p4 = Ragdoll_AddParticle(r, org + v_forward * 8 + v_right   * -12, vel + randomvec() * 150, '-1 -1 -1', '1 1 1', 1.5, 5, 1.5, 1.0);
		p5 = Ragdoll_AddParticle(r, org + v_up      *  6, vel + randomvec() * 150, '-1 -1 -1', '1 1 1', 1.5, 5, 1.5, 1.0);
		p6 = Ragdoll_AddParticle(r, org + v_up      * -6, vel + randomvec() * 150, '-1 -1 -1', '1 1 1', 1.5, 5, 1.5, 1.0);
		s = Ragdoll_AddStick(r, p1, p2, p3, modelname);
		Ragdoll_AddStick(r, p1, p3, world, "");
		Ragdoll_AddStick(r, p1, p4, world, "");
		Ragdoll_AddStick(r, p1, p5, world, "");
		Ragdoll_AddStick(r, p1, p6, world, "");
		Ragdoll_AddStick(r, p2, p3, world, "");
		Ragdoll_AddStick(r, p2, p4, world, "");
		Ragdoll_AddStick(r, p2, p5, world, "");
		Ragdoll_AddStick(r, p2, p6, world, "");
		Ragdoll_AddStick(r, p3, p4, world, "");
		Ragdoll_AddStick(r, p3, p5, world, "");
		Ragdoll_AddStick(r, p3, p6, world, "");
		Ragdoll_AddStick(r, p4, p5, world, "");
		Ragdoll_AddStick(r, p4, p6, world, "");
		Ragdoll_AddStick(r, p5, p6, world, "");
		s.solid = SOLID_CORPSE;
		setsize(s, '-12 -12 -6', '12 12 6');
	}
	else if (modelname == "progs/gib3.mdl")
	{
		// slab of meat
		p1 = Ragdoll_AddParticle(r, org + v_forward *  12, vel + randomvec() * 150, '-1 -1 -3', '1 1 3', 10, 5, 1.5, 1.0);
		p2 = Ragdoll_AddParticle(r, org + v_forward * -12, vel + randomvec() * 150, '-1 -1 -3', '1 1 3', 10, 5, 1.5, 1.0);
		p3 = Ragdoll_AddParticle(r, org + v_right   *  12, vel + randomvec() * 150, '-1 -1 -3', '1 1 3', 10, 5, 1.5, 1.0);
		//p4 = Ragdoll_AddParticle(r, org + v_right   * -12, vel + randomvec() * 150, '-1 -1 -3', '1 1 3', 10, 5, 1.5, 1.0);
		s = Ragdoll_AddStick(r, p1, p2, p3, modelname);
		Ragdoll_AddStick(r, p1, p3, world, "");
		//Ragdoll_AddStick(r, p1, p4, world, "");
		Ragdoll_AddStick(r, p2, p3, world, "");
		//Ragdoll_AddStick(r, p2, p4, world, "");
		//Ragdoll_AddStick(r, p3, p4, world, "");
		s.solid = SOLID_CORPSE;
		setsize(s, '-12 -12 -3', '12 12 3');
	}
	else
	{
		// probably a head
		p1 = Ragdoll_AddParticle(r, org + v_up      *  0 + v_forward *  5, vel + randomvec() * 150, '-1 -1 -1', '1 1 1', 7, 5, 1.5, 1.0);
		p2 = Ragdoll_AddParticle(r, org + v_up      *  0 + v_forward * -5, vel + randomvec() * 150, '-1 -1 -1', '1 1 1', 7, 5, 1.5, 1.0);
		p3 = Ragdoll_AddParticle(r, org + v_up      *  0 + v_right   *  5, vel + randomvec() * 150, '-1 -1 -1', '1 1 1', 7, 5, 1.5, 1.0);
		p4 = Ragdoll_AddParticle(r, org + v_up      *  0 + v_right   * -5, vel + randomvec() * 150, '-1 -1 -1', '1 1 1', 7, 5, 1.5, 1.0);
		p5= Ragdoll_AddParticle(r, org + v_up      *  0, vel + randomvec() * 150, '-1 -1 -1', '1 1 1', 7, 5, 1.5, 1.0);
		p6= Ragdoll_AddParticle(r, org + v_up      * 12 + v_forward *  5, vel + randomvec() * 150, '-1 -1 -1', '1 1 1', 7, 5, 1.5, 1.0);
		p7= Ragdoll_AddParticle(r, org + v_up      * 12 + v_forward * -5, vel + randomvec() * 150, '-1 -1 -1', '1 1 1', 7, 5, 1.5, 1.0);
		p8= Ragdoll_AddParticle(r, org + v_up      * 12 + v_right   *  5, vel + randomvec() * 150, '-1 -1 -1', '1 1 1', 7, 5, 1.5, 1.0);
		p9= Ragdoll_AddParticle(r, org + v_up      * 12 + v_right   * -5, vel + randomvec() * 150, '-1 -1 -1', '1 1 1', 7, 5, 1.5, 1.0);
		p10= Ragdoll_AddParticle(r, org + v_up      * 12, vel + randomvec() * 150, '-1 -1 -1', '1 1 1', 7, 5, 1.5, 1.0);
		Ragdoll_AddStick(r, p9, p10, world, "");
		Ragdoll_AddStick(r, p9, p5, world, "");
		Ragdoll_AddStick(r, p8, p10, world, "");
		Ragdoll_AddStick(r, p8, p9, world, "");
		Ragdoll_AddStick(r, p8, p5, world, "");
		Ragdoll_AddStick(r, p7, p10, world, "");
		Ragdoll_AddStick(r, p7, p9, world, "");
		Ragdoll_AddStick(r, p7, p8, world, "");
		Ragdoll_AddStick(r, p7, p5, world, "");
		Ragdoll_AddStick(r, p6, p10, world, "");
		Ragdoll_AddStick(r, p6, p9, world, "");
		Ragdoll_AddStick(r, p6, p8, world, "");
		Ragdoll_AddStick(r, p6, p7, world, "");
		Ragdoll_AddStick(r, p6, p5, world, "");
		Ragdoll_AddStick(r, p5, p10, world, "");
		Ragdoll_AddStick(r, p4, p10, world, "");
		Ragdoll_AddStick(r, p4, p9, world, "");
		Ragdoll_AddStick(r, p4, p8, world, "");
		Ragdoll_AddStick(r, p4, p7, world, "");
		Ragdoll_AddStick(r, p4, p6, world, "");
		Ragdoll_AddStick(r, p4, p5, world, "");
		Ragdoll_AddStick(r, p3, p10, world, "");
		Ragdoll_AddStick(r, p3, p9, world, "");
		Ragdoll_AddStick(r, p3, p8, world, "");
		Ragdoll_AddStick(r, p3, p7, world, "");
		Ragdoll_AddStick(r, p3, p6, world, "");
		Ragdoll_AddStick(r, p3, p5, world, "");
		Ragdoll_AddStick(r, p3, p4, world, "");
		Ragdoll_AddStick(r, p2, p10, world, "");
		Ragdoll_AddStick(r, p2, p9, world, "");
		Ragdoll_AddStick(r, p2, p8, world, "");
		Ragdoll_AddStick(r, p2, p7, world, "");
		Ragdoll_AddStick(r, p2, p6, world, "");
		Ragdoll_AddStick(r, p2, p5, world, "");
		Ragdoll_AddStick(r, p2, p4, world, "");
		Ragdoll_AddStick(r, p2, p3, world, "");
		Ragdoll_AddStick(r, p1, p10, world, "");
		Ragdoll_AddStick(r, p1, p9, world, "");
		Ragdoll_AddStick(r, p1, p8, world, "");
		Ragdoll_AddStick(r, p1, p7, world, "");
		Ragdoll_AddStick(r, p1, p6, world, "");
		Ragdoll_AddStick(r, p1, p5, world, "");
		Ragdoll_AddStick(r, p1, p4, world, "");
		Ragdoll_AddStick(r, p1, p3, world, "");
		s = Ragdoll_AddStick(r, p1, p2, p3, modelname);
		s.solid = SOLID_CORPSE;
		setsize(s, '-12 -12 -5', '12 12 5');
	}
	return r;
};

.float rb_lastmovetime;
.vector rb_origin;
.vector rb_velocity;
.vector rb_forward;
.vector rb_left;
.vector rb_up;
.vector rb_spinaxis;
.float rb_spinspeed;
.float rb_mass;
.float rb_numpoints;
.vector rb_points[16];

vector _rb_origin;
vector _rb_forward;
vector _rb_left;
vector _rb_up;

float _rb_trace_fraction;
vector _rb_trace_contact_point;
vector _rb_trace_contact_point_local;
vector _rb_trace_contact_plane_normal;

vector(vector a, vector b) crossproduct =
{
	local vector v;
	v_x = a_y * b_z - a_z * b_y;
	v_y = a_z * b_x - a_x * b_z;
	v_z = a_x * b_y - a_y * b_x;
	return v;
};

void(entity body) RigidBody_FixMatrix =
{
	body.rb_forward = normalize(body.rb_forward);
	body.rb_left = normalize(body.rb_left);
	body.rb_up = normalize(body.rb_up);
	if (fabs(body.rb_forward * body.rb_up) > 0.01 || vlen(body.rb_left) < 0.9)
	{
		// no left, regenerate it from forward and up
		body.rb_left = crossproduct(body.rb_forward, body.rb_up);
		body.rb_forward = crossproduct(body.rb_left, body.rb_up);
	}
	else if (fabs(body.rb_forward * body.rb_left) > 0.01 || vlen(body.rb_up) < 0.9)
	{
		// no up, regenerate it from forward and left
		body.rb_up = crossproduct(body.rb_forward, body.rb_left);
		body.rb_forward = crossproduct(body.rb_left, body.rb_up);
	}
	else if (fabs(body.rb_left * body.rb_up) > 0.01 || vlen(body.rb_forward) < 0.9)
	{
		// no forward, regenerate it from left and up
		body.rb_forward = crossproduct(body.rb_left, body.rb_up);
		body.rb_left = crossproduct(body.rb_forward, body.rb_up);
	}
	if (vlen(body.rb_spinaxis) < 0.999)
	{
		body.rb_spinaxis = normalize(body.rb_spinaxis);
		if (vlen(body.rb_spinaxis) < 0.9)
		{
			body.rb_spinaxis = '1 0 0';
			body.rb_spinspeed = 0;
		}
	}
	if (vlen(body.rb_velocity) < 0.001)
		body.rb_velocity = '0 0 0';
};

/*
void(vector in1_forward, vector in1_left, vector in1_up, vector in2_forward, vector in2_left, vector in2_up) RigidBody_MultiplyMatrix
{
	_rb_temp_forward_x = in1_forward_x * in2_forward_x + in1_left_x * in2_forward_y + in1_up_x * in2_forward_z;
	_rb_temp_forward_y = in1_forward_y * in2_forward_x + in1_left_y * in2_forward_y + in1_up_y * in2_forward_z;
	_rb_temp_forward_z = in1_forward_z * in2_forward_x + in1_left_z * in2_forward_y + in1_up_z * in2_forward_z;
	_rb_temp_left_x = in1_forward_x * in2_left_x + in1_left_x * in2_left_y + in1_up_x * in2_left_z;
	_rb_temp_left_y = in1_forward_y * in2_left_x + in1_left_y * in2_left_y + in1_up_y * in2_left_z;
	_rb_temp_left_z = in1_forward_z * in2_left_x + in1_left_z * in2_left_y + in1_up_z * in2_left_z;
	_rb_temp_up_x = in1_forward_x * in2_up_x + in1_left_x * in2_up_y + in1_up_x * in2_up_z;
	_rb_temp_up_y = in1_forward_y * in2_up_x + in1_left_y * in2_up_y + in1_up_y * in2_up_z;
	_rb_temp_up_z = in1_forward_z * in2_up_x + in1_left_z * in2_up_y + in1_up_z * in2_up_z;
}

void(vector axis, float angle) RigidBody_MatrixFromRodriguesVector
{
	local float c, s, mc;

	axis = normalize(axis);
	c = cos(angle);mc = 1 - c;
	s = sin(angle);

	// proper orientation
	_rb_temp_forward_x = axis_x * axis_x + c * (1 - axis_x * axis_x);
	_rb_temp_forward_y = axis_x * axis_y * mc - axis_z * s;
	_rb_temp_forward_z = axis_z * axis_x * mc + axis_y * s;
	_rb_temp_left_x = axis_x * axis_y * mc + axis_z * s;
	_rb_temp_left_y = axis_y * axis_y + c * (1 - axis_y * axis_y);
	_rb_temp_left_z = axis_y * axis_z * mc - axis_x * s;
	_rb_temp_up_x = axis_z * axis_x * mc - axis_y * s;
	_rb_temp_up_y = axis_y * axis_z * mc + axis_x * s;
	_rb_temp_up_z = axis_z * axis_z + c * (1 - axis_z * axis_z);
}
*/

void(entity body, float movetime) RigidBody_ExtrapolateMotion =
{
	local vector startorigin;
	local vector forward;
	local vector left;
	local vector up;
	local vector vel;
	local vector axis;
	local float spin;
	local float c, s, mc;
	local vector rforward;
	local vector rleft;
	local vector rup;

	startorigin = body.rb_origin;
	forward = body.rb_forward;
	left = body.rb_left;
	up = body.rb_up;
	vel = body.rb_velocity;
	axis = body.rb_spinaxis;
	spin = body.rb_spinspeed;

	axis = normalize(axis);
	c = cos(spin * movetime);mc = 1 - c;
	s = sin(spin * movetime);

	rforward_x = axis_x * axis_x + c * (1 - axis_x * axis_x);
	rforward_y = axis_x * axis_y * mc - axis_z * s;
	rforward_z = axis_z * axis_x * mc + axis_y * s;
	rleft_x = axis_x * axis_y * mc + axis_z * s;
	rleft_y = axis_y * axis_y + c * (1 - axis_y * axis_y);
	rleft_z = axis_y * axis_z * mc - axis_x * s;
	rup_x = axis_z * axis_x * mc - axis_y * s;
	rup_y = axis_y * axis_z * mc + axis_x * s;
	rup_z = axis_z * axis_z + c * (1 - axis_z * axis_z);

	_rb_origin = startorigin + vel * movetime;
	_rb_forward_x = rforward_x * forward_x + rleft_x * forward_y + rup_x * forward_z;
	_rb_forward_y = rforward_y * forward_x + rleft_y * forward_y + rup_y * forward_z;
	_rb_forward_z = rforward_z * forward_x + rleft_z * forward_y + rup_z * forward_z;
	_rb_left_x = rforward_x * left_x + rleft_x * left_y + rup_x * left_z;
	_rb_left_y = rforward_y * left_x + rleft_y * left_y + rup_y * left_z;
	_rb_left_z = rforward_z * left_x + rleft_z * left_y + rup_z * left_z;
	_rb_up_x = rforward_x * up_x + rleft_x * up_y + rup_x * up_z;
	_rb_up_y = rforward_y * up_x + rleft_y * up_y + rup_y * up_z;
	_rb_up_z = rforward_z * up_x + rleft_z * up_y + rup_z * up_z;

	/*
	// swapped multiply order
	_rb_forward_x = forward_x * rforward_x + left_x * rforward_y + up_x * rforward_z;
	_rb_forward_y = forward_y * rforward_x + left_y * rforward_y + up_y * rforward_z;
	_rb_forward_z = forward_z * rforward_x + left_z * rforward_y + up_z * rforward_z;
	_rb_left_x = forward_x * rleft_x + left_x * rleft_y + up_x * rleft_z;
	_rb_left_y = forward_y * rleft_x + left_y * rleft_y + up_y * rleft_z;
	_rb_left_z = forward_z * rleft_x + left_z * rleft_y + up_z * rleft_z;
	_rb_up_x = forward_x * rup_x + left_x * rup_y + up_x * rup_z;
	_rb_up_y = forward_y * rup_x + left_y * rup_y + up_y * rup_z;
	_rb_up_z = forward_z * rup_x + left_z * rup_y + up_z * rup_z;
	*/
};

void(entity body, vector p, vector a, vector b) RigidBody_TracePoint =
{
	traceline(a, b, FALSE, body);
	// TODO: handle multiple contacts
	if (_rb_trace_fraction > trace_fraction)
	{
		_rb_trace_fraction = trace_fraction;
		_rb_trace_contact_point = trace_endpos;
		_rb_trace_contact_plane_normal = trace_plane_normal;
		_rb_trace_contact_point_local = p;
	}
};

void(entity body) RigidBody_Trace =
{
	local float i;
	local vector p;
	local vector aorigin;
	local vector aforward;
	local vector aleft;
	local vector aup;
	local vector borigin;
	local vector bforward;
	local vector bleft;
	local vector bup;

	aorigin = body.rb_origin;
	aforward = body.rb_forward;
	aleft = body.rb_left;
	aup = body.rb_up;
	borigin = _rb_origin;
	bforward = _rb_forward;
	bleft = _rb_left;
	bup = _rb_up;

	_rb_trace_fraction = 1;
	_rb_trace_contact_point = '0 0 0';
	_rb_trace_contact_plane_normal = '0 0 0';
	for (i = 0;i < body.rb_numpoints;i++)
	{
		p = body.(rb_points[i]);
		RigidBody_TracePoint(body, p, aorigin + p_x * aforward + p_y * aleft + p_z * aup, borigin + p_x * bforward + p_y * bleft + p_z * bup);
	}
}

void(entity body, vector org, vector forward, vector left, vector up) RigidBody_UpdatePosition =
{
	body.rb_origin = org;
	body.rb_forward = forward;
	body.rb_left = left;
	body.rb_up = up;
};

void(entity body, vector lp, vector lf) RigidBody_ApplyImpulse =
{
	/*
	local vector fspinaxis;
	fspinaxis = normalize(crossproduct(lp, lf));
	vectorvectors(fspinaxis);
	fspinforward = v_forward;
	fspinleft = v_right * -1;
	fspinup = v_up;
	p1 = lp_x * body.rb_forward + lp_y * body.rb_left + lp_z * body.rb_up + body.rb_origin;
	RigidBody_ExtrapolateMotion(body, 1 / 128);
	p2 = lp_x * _rb_forward + lp_y * _rb_left + lp_z * _rb_up + _rb_origin;
	temp = p2 - body.rb_origin;
	lp2_x = temp * body.rb_forward;
	lp2_y = temp * body.rb_left;
	lp2_z = temp * body.rb_up;
	lpv = (lp2 - lp) * 128;
	lpvf = lpv + lf * (1 / body.rb_mass);
	*/

/*
	local vector aorigin;
	local vector aforward;
	local vector aleft;
	local vector aup;
	local vector borigin;
	local vector bforward;
	local vector bleft;
	local vector bup;
	local vector fspinaxis;
	local float fspinspeed;
	local vector an, bn;

	// FIXME: finish this
	lf = lf * (1 / body.rb_mass);
	fspinaxis = normalize(crossproduct(lp, lf));
	fspinspeed = vlen(lf) * (1 / vlen(lp));

	aorigin = body.rb_origin;
	aforward = body.rb_forward;
	aleft = body.rb_left;
	aup = body.rb_up;
	borigin = _rb_origin;
	bforward = _rb_forward;
	bleft = _rb_left;
	bup = _rb_up;

	// TODO
	an_x = n * aforward;
	an_y = n * aleft;
	an_z = n * aup;

	temp = lp_x * bforward + p_y * bleft + p_z * bup;
	lp2_x = temp * aforward;
	lp2_y = temp * aleft;
	lp2_z = temp * aup;
	d = (lp2 - lp) * an;
	if (d >= 0)
		return;
	c = lp2 - an * d;

	p1 = aorigin + p_x * aforward + p_y * aleft + p_z * aup;
	p2 = borigin + p_x * bforward + p_y * bleft + p_z * bup;
	d = (p2 - p1) * n;
	if (d >= 0)
		return;
	c = p2 - n * d;
	c2 = c - borigin;
	lc_x = c2 * bforward;
	lc_y = c2 * bleft;
	lc_z = c2 * bup;

	p1 = aorigin + p_x * aforward + p_y * aleft + p_z * aup;
	p2 = borigin + p_x * bforward + p_y * bleft + p_z * bup;
*/
};

void() RigidBody_Think =
{
	local float movetime;
	local float collisiontime;
	self.nextthink = time;
	movetime = time - self.rb_lastmovetime;
	self.rb_lastmovetime = time;
	while (movetime > 0.001)
	{
		RigidBody_ExtrapolateMotion(self, movetime);
		RigidBody_Trace(self);
		collisiontime = movetime * _rb_trace_fraction;
		movetime = movetime - collisiontime;
		RigidBody_ExtrapolateMotion(self, collisiontime);
		RigidBody_UpdatePosition(self, _rb_origin, _rb_forward, _rb_left, _rb_up);
		RigidBody_FixMatrix(self);
		if (_rb_trace_fraction < 1)
		{
			// now apply contact joints
			RigidBody_ExtrapolateMotion(self, 1 / 65536);
			// FIXME: code this
			//RigidBody_ApplyContact(_rb_trace_contact_point_local, _rb_trace_contact_plane_normal);
			RigidBody_FixMatrix(self);
		}
	}
};

entity(string modelname, vector org, vector forward, vector left, vector up, float bmass, vector vel, vector axis, float spin) RigidBody_Spawn =
{
	local entity body;
	body = spawn();
	body.classname = "rigidbody";
	body.think = RigidBody_Think;
	body.nextthink = time;
	body.rb_lastmovetime = time;
	setmodel(body, modelname);
	body.rb_forward = forward;
	body.rb_left = left;
	body.rb_up = up;
	body.rb_mass = bmass;
	body.rb_velocity = vel;
	body.rb_spinaxis = axis;
	body.rb_spinspeed = spin;
	RigidBody_FixMatrix(body);
	return body;
};

void(entity body, vector org) RigidBody_AddPoint =
{
	if (body.rb_numpoints >= 16)
		return;
	body.(rb_points[body.rb_numpoints]) = org;
	body.rb_numpoints = body.rb_numpoints + 1;
};

void(entity body) RigidBody_Remove =
{
	remove(body);
};
