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

/*
============
RadDamage

returns amount of damage to apply to target,
based on distance from org,
used for explosions, fire, etc.

note: not used anymore, LinearRadDamage is now used
============
*/
/*
float(entity targ, entity ignore, vector org, float amount, float radius, float checkcount) RadDamage =
{
	local vector v, m1, m2, v1, v2;
	local float b, dist;
	m1 = targ.mins + targ.origin;
	m2 = targ.maxs + targ.origin;
	if (pointcontents(org) == CONTENT_SOLID)
		return 0;
	b = -1;
	raddamage_lasthit = org; // for the following
	if (org_x >= (m1_x - 2)) if (org_x < (m2_x + 2))
	if (org_y >= (m1_y - 2)) if (org_y < (m2_y + 2))
	if (org_z >= (m1_z - 2)) if (org_z < (m2_z + 2))
		return amount;
	// find nearest point and calc damage for that
	v_x = bound(m1_x, org_x, m2_x);
	v_y = bound(m1_y, org_y, m2_y);
	v_z = bound(m1_z, org_z, m2_z);
	dist = vlen(v - org);
	if (dist >= radius)
		return 0; // out of range
	b = amount * (1 - dist / radius);
	if (b < 1)
		return 0; // no damage

	raddamage_lasthit = v;

	// direct hit
	traceline(org, v, raddamage_tracetype, ignore);
	if (!trace_startsolid)
	if (trace_fraction == 1 || trace_ent == targ)
		return b;

	// partial hit
	b = b * CanRadDamage(targ, ignore, org, checkcount);
	return b;
};

float(entity targ, entity ignore, vector org, float amount, float radius, float checkcount) LightningWaterRadDamage =
{
	local vector v, m1, m2, v1, v2;
	local float dist;
	local float b, wt; //, c, d, s;
	m1 = targ.mins + targ.origin;
	m2 = targ.maxs + targ.origin;
	wt = pointcontents(org);
	if (wt == CONTENT_SOLID)
		return 0;
	b = -1;
	raddamage_lasthit = org; // for the following
	if (org_x >= (m1_x - 2)) if (org_x < (m2_x + 2))
	if (org_y >= (m1_y - 2)) if (org_y < (m2_y + 2))
	if (org_z >= (m1_z - 2)) if (org_z < (m2_z + 2))
		return amount;
	// find nearest point and calc damage for that
	v_x = bound(m1_x, org_x, m2_x);
	v_y = bound(m1_y, org_y, m2_y);
	v_z = bound(m1_z, org_z, m2_z);

	if (pointcontents(v) != wt)
		return 0; // not in same type of water/slime/whatever

	dist = vlen(v - org);
	if (dist >= radius)
		return 0; // out of range
	b = amount * (1 - dist / radius);
	if (b < 1)
		return 0; // no damage

	//dist = radius - (vlen(v - org) * 0.5); //(radius - vlen(v - org)) / radius;
	//if (dist < (radius * 0.5))
	//        return 0; // no damage
	//b = amount * (dist * dist);
	//if (b < 1)
	//        return 0; // no damage

	raddamage_lasthit = v;

	// direct hit
	traceline(org, v, raddamage_tracetype, ignore);
	if (!trace_startsolid)
	if (trace_inwater)
	if (!trace_inopen)
	if (trace_fraction == 1 || trace_ent == targ)
		return b;

	// partial hit
	b = b * CanRadDamage(targ, ignore, org, checkcount);
	return b;
};
*/

float(entity targ, entity ignore, vector org, vector dir, float mindot, float amount, float radius, float checkcount) ShapedLinearRadDamage =
{
	local vector v, m1, m2;
	local float b, c, d, dp, c2;
	if (pointcontents(org) == CONTENT_SOLID)
		return 0;
	m1 = targ.mins + targ.origin;
	m2 = targ.maxs + targ.origin;
	b = -1;
	if (org_x >= (m1_x - 2)) if (org_x < (m2_x + 2))
	if (org_y >= (m1_y - 2)) if (org_y < (m2_y + 2))
	if (org_z >= (m1_z - 2)) if (org_z < (m2_z + 2))
	{
		raddamage_lasthit = org;
		return amount;
	}
	// find nearest point and calc damage for that
	v_x = bound(m1_x, org_x, m2_x);
	v_y = bound(m1_y, org_y, m2_y);
	v_z = bound(m1_z, org_z, m2_z);

	d = vlen(v - org);
	if (d >= radius)
		return 0; // out of range
	b = (amount/radius) * (radius - d);
	if (b < 1)
		return 0; // no damage

	traceline(org, v, raddamage_tracetype, ignore);
	if (trace_ent == targ || trace_fraction >= 1)
	{
		raddamage_lasthit = trace_endpos;
		return (b);
	}

	d = 0;
	c = checkcount;
	c2 = 0;
	while(c > 0)
	{
		c = c - 1;
		v = randompos(m1, m2);
		dp = normalize (v - org) * dir;
		if (dp >= mindot)
		{
			c2 = c2 + 1;
			traceline(org, v, raddamage_tracetype, ignore);
			if (trace_ent == targ || trace_fraction >= 1)
			{
				raddamage_lasthit = trace_endpos;
				d = d + b;
			}
		}
	}

	if (c2 > 0)
		return d / c2;
	else
		return 0;
};

// Quake style falloff
float(entity targ, entity ignore, vector org, float amount, float radius, float checkcount) LinearRadDamage =
{
	local vector v, m1, m2;
	local float b, dist;
	//if (pointcontents(org) == CONTENT_SOLID)
	//	return 0;
	m1 = targ.mins + targ.origin;
	m2 = targ.maxs + targ.origin;
	b = -1;
	// find nearest point and calc damage for that
	v_x = bound(m1_x, org_x, m2_x);
	v_y = bound(m1_y, org_y, m2_y);
	v_z = bound(m1_z, org_z, m2_z);
	dist = vlen(v - org);
	if (dist < 2)
	{
		raddamage_lasthit = org;
		return amount;
	}
	if (dist >= radius)
		return 0; // out of range
	b = (amount/radius) * (radius - dist);
	if (b < 1)
		return 0; // no damage

	raddamage_lasthit = v;

	// direct hit
	traceline(org, v, raddamage_tracetype, ignore);
	if (!trace_startsolid)
	if (trace_fraction == 1 || trace_ent == targ)
		return b;

	// partial hit
	b = b * CanRadDamage(targ, ignore, org, checkcount);
	return b;
};

