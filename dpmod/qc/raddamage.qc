vector raddamage_lasthit;

float raddamage_tracetype = MOVE_NOMONSTERS;

/*
============
CanDamage

Returns true if the inflictor can directly damage the target.  Used for
melee attacks.
============
*/
float(entity targ, entity inflictor) CanDamage =
{
	local vector v, m1, m2;
	local float c, d, s;
	// hack to make tracelines hit dead bodies
	s = inflictor.solid;
	if (s == SOLID_SLIDEBOX)
		inflictor.solid = SOLID_BBOX;
	m1 = targ.mins + targ.origin;
	m2 = targ.maxs + targ.origin - m1;
	d = 0;
	c = 0;
	while(c < 5)
	{
		c = c + 1;
		v_x = m1_x + random() * m2_x;
		v_y = m1_y + random() * m2_y;
		v_z = m1_z + random() * m2_z;
		traceline(inflictor.origin, v, raddamage_tracetype, inflictor);
		if ((trace_fraction == 1 || trace_ent == targ) && !trace_startsolid)
		{
			raddamage_lasthit = trace_endpos;
			d = d + 1;
		}
	}
	if (s == SOLID_SLIDEBOX)
		inflictor.solid = s;
	return (d / 5);
};

float(entity targ, entity ignore, vector org, float checkcount) CanRadDamage =
{
	local vector v, m1, m2;
	local float c, d, s;
	// hack to make tracelines hit dead bodies
	s = ignore.solid;
	if (s == SOLID_SLIDEBOX)
		ignore.solid = SOLID_BBOX;
	m1 = targ.mins + targ.origin;
	m2 = targ.maxs + targ.origin - m1;
	d = 0;
	c = 0;
	while(c < checkcount)
	{
		c = c + 1;
		v_x = m1_x + random() * m2_x;
		v_y = m1_y + random() * m2_y;
		v_z = m1_z + random() * m2_z;
		traceline(org, v, raddamage_tracetype, ignore);
		if (!trace_startsolid)
		if (trace_fraction == 1 || trace_ent == targ)
			d = d + 1;
	}
	if (s == SOLID_SLIDEBOX)
		ignore.solid = s;
	return (d / checkcount);
};

// Quake style falloff
float(entity targ, entity ignore, vector org, float radius, float checkcount) LinearRadDamage =
{
	local vector v, m1, m2;
	local float b, dist;
	m1 = targ.mins + targ.origin;
	m2 = targ.maxs + targ.origin;
	// find nearest point and calc damage for that
	v_x = bound(m1_x, org_x, m2_x);
	v_y = bound(m1_y, org_y, m2_y);
	v_z = bound(m1_z, org_z, m2_z);
	dist = vlen(v - org);
	// if really close, do full damage
	if (dist < 2)
	{
		raddamage_lasthit = org;
		return 1;
	}
	// if outside radius, do no damage
	if (dist >= radius)
		return 0;
	// calculate distance-attenuated damage
	b = 1 - dist/radius;
	if (b < 1)
		return 0; // no damage

	raddamage_lasthit = v;

	// direct hit
	traceline(org, v, MOVE_NOMONSTERS, ignore);
	if (!trace_startsolid)
	if (trace_fraction == 1 || trace_ent == targ)
		return b;

	// partial hit
	return b * CanRadDamage(targ, ignore, org, checkcount);
};

