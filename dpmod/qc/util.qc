// traces a curved trajectory (grenades for instance)
// sets the trace info for the last segment (the one which hit something)
// and returns the flight time upto the impact
float(vector org, vector vel, float maxtime, float nomonsters, entity ignore) oldtracetoss =
{
	local   float   c, grav;
	local   vector  v, vel2;
	grav = cvar("sv_gravity") * 0.1; // only reads the cvar once
	c = 0;v = org;vel2 = vel;
	while (c < maxtime)
	{
		//dprint("vel2=");
		//dprintvector(vel2);
		//dprint("\n");
		//particle(v, '0 0 0', 104, 4);
		traceline(v, v + vel2 * 0.05, nomonsters, ignore);
		if (trace_fraction < 1)
		{
			c = c + trace_fraction * 0.05;
			//dprint("tracetoss: ");
			//dprint(ftos(c * 1000));
			//dprint(" impact:");
			//dprint(trace_ent.classname);
			//dprint("\n");
			return c; // how long it took to impact
		}
		if (trace_startsolid)
		{
			//dprint("tracetoss: started in a solid\n");
			return 0; // started in a solid?
		}
		vel2_z = vel2_z - grav;
		v = v + vel2 * 0.1;
		c = c + 0.1;
	}
	//dprint("tracetoss: ran out of time\n");
	return maxtime; // didn't impact
};

entity tracetossent;
entity tracetossfaketarget;

void(vector org, vector m1, vector m2, vector vel, entity ignore) tracetossnoent =
{
	if (!tracetossent)
		tracetossent = spawn();
	setorigin(tracetossent, org);
	setsize(tracetossent, m1, m2);
	tracetossent.velocity = vel;
	tracetoss(tracetossent, ignore);
};

// traces multiple trajectories to find one that will impact the target
// 'end' vector is the place it aims for,
// returns TRUE only if it hit targ (don't target non-solid entities)
vector  findtrajectory_velocity; // calculated direction
float(vector org, vector end, entity targ, float shotspeed, float maxtime, float nomonsters, entity ignore) oldfindtrajectory =
{
	local   float   c;
	local   vector  dir;
	if (shotspeed < 1)
		return FALSE; // could cause division by zero if calculated
	if (nomonsters)
	if (targ.solid != SOLID_BSP) // nomonsters ignores BBOX and SLIDEBOX
		return FALSE; // could never hit it
	if (targ.solid < SOLID_BBOX) // SOLID_NOT and SOLID_TRIGGER
		return FALSE; // could never hit it
	c = 0;
	if (maxtime == 0) // calculate maxtime
		maxtime = vlen(end - org) / shotspeed + 0.2;
	dir = normalize(end - org);
	while (c < 1) // won't aim more than 1.0 above direct direction
	{
		findtrajectory_velocity = normalize(dir) * shotspeed;
		//dprint("findtrajectory: testing vel=");
		//dprintvector(findtrajectory_velocity);
		//dprint("\n");
		oldtracetoss(org, findtrajectory_velocity, maxtime, nomonsters, ignore);
		if (trace_ent == targ) // done
		{
			//dprint("findtrajectory: found target\n");
			return TRUE;
		}
		dir_z = dir_z + 0.1; // aim up a little more
		c = c + 0.1; // 10 traces
	}
	//dprint("findtrajectory: didn't reach target\n");
	// leave a valid one even if it won't reach
	findtrajectory_velocity = normalize(end - org) * shotspeed;
	return FALSE;
};

// returns TRUE if it was able to calculate a trajectory which would hit,
// FALSE if not
float(vector org, vector m1, vector m2, entity targ, float shotspeed, float maxtime, entity ignore) findtrajectory =
{
	local   float   c;
	local   vector  dir, vel, end;
	if (shotspeed < 1)
		return FALSE; // could cause division by zero if calculated
	if (targ.solid < SOLID_BBOX) // SOLID_NOT and SOLID_TRIGGER
		return FALSE; // could never hit it
	end = (targ.absmin + targ.absmax) * 0.5;
	if ((vlen(end - org) / shotspeed + 0.2) > maxtime)
		return FALSE; // out of range
	if (!tracetossent)
		tracetossent = spawn();
	setsize(tracetossent, m1, m2);
	c = 0;
	dir = normalize(end - org);
	while (c < 1) // won't aim more than 1.0 above direct direction
	{
		setorigin(tracetossent, org); // reset
		tracetossent.velocity = findtrajectory_velocity = normalize(dir) * shotspeed;
		tracetoss(tracetossent, ignore); // love builtin functions...
		if (trace_ent == targ) // done
			return TRUE;
		dir_z = dir_z + 0.1; // aim up a little more
		c = c + 0.1; // 10 traces
	}
	// leave a valid one even if it won't reach
	findtrajectory_velocity = normalize(end - org) * shotspeed;
	return FALSE;
};

// returns TRUE if it was able to calculate a trajectory which would hit,
// FALSE if not
float(vector org, vector m1, vector m2, entity targ, float shotspeed, float maxtime, float shotdelay, entity ignore) findtrajectorywithleading =
{
	local float c, savesolid;
	local vector dir, vel, end, v;
	if (targ.velocity == '0 0 0') // immobile targets can be hit with the normal method
		return findtrajectory(org, m1, m2, targ, shotspeed, maxtime, ignore);
	if (shotspeed < 1)
		return FALSE; // could cause division by zero if calculated
	if (targ.solid < SOLID_BBOX) // SOLID_NOT and SOLID_TRIGGER
		return FALSE; // could never hit it
	if (!tracetossent)
		tracetossent = spawn();
	setsize(tracetossent, m1, m2);
	savesolid = targ.solid;
	targ.solid = SOLID_NOT;
	v = targ.velocity * ((vlen(targ.origin - org) / shotspeed) + shotdelay) + targ.origin;
	tracebox(targ.origin, targ.mins, targ.maxs, v, FALSE, targ);
	v = trace_endpos;
	end = v + (targ.mins + targ.maxs) * 0.5;
	if ((vlen(end - org) / shotspeed + 0.2) > maxtime)
	{
		// out of range
		targ.solid = savesolid;
		return FALSE;
	}

	if (!tracetossfaketarget)
		tracetossfaketarget = spawn();
	tracetossfaketarget.solid = savesolid;
	tracetossfaketarget.movetype = targ.movetype;
	setmodel(tracetossfaketarget, targ.model);
	tracetossfaketarget.model = "";
	tracetossfaketarget.modelindex = targ.modelindex;
	setsize(tracetossfaketarget, targ.mins, targ.maxs);
	setorigin(tracetossfaketarget, v);

	c = 0;
	dir = normalize(end - org);
	while (c < 1) // won't aim more than 1.0 above direct direction
	{
		setorigin(tracetossent, org); // reset
		tracetossent.velocity = findtrajectory_velocity = normalize(dir) * shotspeed;
		tracetoss(tracetossent, ignore); // love builtin functions...
		if (trace_ent == tracetossfaketarget) // done
		{
			targ.solid = savesolid;

			// make it disappear
			tracetossfaketarget.solid = SOLID_NOT;
			tracetossfaketarget.movetype = MOVETYPE_NONE;
			tracetossfaketarget.model = "";
			tracetossfaketarget.modelindex = 0;
			// relink to remove it from physics considerations
			setorigin(tracetossfaketarget, v);

			return TRUE;
		}
		dir_z = dir_z + 0.1; // aim up a little more
		c = c + 0.1; // 10 traces
	}
	targ.solid = savesolid;

	// make it disappear
	tracetossfaketarget.solid = SOLID_NOT;
	tracetossfaketarget.movetype = MOVETYPE_NONE;
	tracetossfaketarget.model = "";
	tracetossfaketarget.modelindex = 0;
	// relink to remove it from physics considerations
	setorigin(tracetossfaketarget, v);

	// leave a valid one even if it won't reach
	findtrajectory_velocity = normalize(end - org) * shotspeed;
	return FALSE;
};

/*
==============================================================================

WIZARD

If the player moves behind cover before the missile is launched, launch it
at the last visible spot with no velocity leading, in hopes that the player
will duck back out and catch it.
==============================================================================
*/

/*
=============
WizardLaunchMissile

Sets the given entities velocity and angles so that it will hit self.enemy
if self.enemy maintains it's current velocity
0.1 is moderately accurate, 0.0 is totally accurate
=============
*/
void(entity missile, float mspeed, float accuracy) WizardLaunchMissile =
{
	local	vector	vec, move;
	local	float	fly;

	makevectors (self.angles);

// set missile speed
	vec = self.enemy.origin + self.enemy.mins + self.enemy.size * 0.7 - missile.origin;

// calc aproximate time for missile to reach vec
	fly = vlen (vec) / mspeed;

// get the entities xy velocity
	move = self.enemy.velocity;
	move_z = 0;

// project the target forward in time
	vec = vec + move * fly;
	
	vec = normalize(vec);
	vec = vec + accuracy*v_up*(random()- 0.5) + accuracy*v_right*(random()- 0.5);
	
	missile.velocity = vec * mspeed;

	missile.angles = '0 0 0';
	missile.angles_y = vectoyaw(missile.velocity);

// set missile duration
	missile.nextthink = time + 5;
	missile.think = SUB_Remove;
};

vector(float shotdelay) monster_shotleadbullet =
{
	// project latency movement
	tracebox(self.enemy.origin, self.enemy.mins, self.enemy.maxs, self.enemy.origin + self.enemy.velocity * shotdelay, FALSE, self.enemy);
	traceline(self.origin + '0 0 16', trace_endpos, FALSE, self);
	if (trace_fraction < 1 && trace_ent != self.enemy)
	{
		// can't hit that, return current position and hope for the best
		return self.enemy.origin;
	}
	return trace_endpos;
};

vector(float shotdelay, float shotspeed) monster_shotlead =
{
	local float f;
	// project latency and shot leading movement
	f = shotdelay + vlen(self.enemy.origin - self.origin) / shotspeed;
	tracebox(self.enemy.origin, self.enemy.mins, self.enemy.maxs, self.enemy.origin + self.enemy.velocity * f, FALSE, self.enemy);
	// check if self can shoot that spot
	traceline(self.origin + '0 0 16', trace_endpos, FALSE, self);
	if (trace_fraction < 1 && trace_ent != self.enemy)
	{
		// try with latency but not shot leading
		tracebox(self.enemy.origin, self.enemy.mins, self.enemy.maxs, self.enemy.origin + self.enemy.velocity * shotdelay, FALSE, self.enemy);
		traceline(self.origin + '0 0 16', trace_endpos, FALSE, self);
		if (trace_fraction < 1 && trace_ent != self.enemy)
		{
			// can't hit that either, return current position and hope for the best
			return self.enemy.origin;
		}
	}
	return trace_endpos;
};

// hack to make it hit dead bodies
// (traceline using a SLIDEBOX will normally skip CORPSE,
//  desirable for visibility checking but not for weapons fire)
void(vector start, vector end, float noents, entity attacker) weapontraceline =
{
	local   float   s;
	s = attacker.solid;
	if (attacker.solid == SOLID_SLIDEBOX)
		attacker.solid = SOLID_BBOX;
	traceline(start, end, noents, attacker);
	if (s == SOLID_SLIDEBOX)
		attacker.solid = s;
};
