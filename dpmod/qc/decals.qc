
void() InitDecals =
{
//	precache_model ("progs/s_spike.mdl");  // nail in the wall (bullet hole)
//	precache_model ("progs/!blood.spr32"); // blood splat
//	precache_model ("progs/!bloodbig.spr32"); // huge blood pool
//	precache_model ("progs/!plasmamark.spr32");   // plasma scorch mark
//	precache_model ("progs/!pellethole.spr32");  // shotgun pellet hole
//	precache_model ("progs/!bullethole.spr32");  // nailgun hole
};

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
		e.createdtime = time;
	}
	else
	{
		e = newdecor();
		e.createdtime = time + importance;
	}
	setmodel (e, dmodel);
	e.skin = dskin;
	e.frame = dframe;
	e.angles = dirangles;
	setorigin (e, org);
	e.solid = SOLID_NOT;
	e.movetype = MOVETYPE_NONE;
	//e.effects = EF_DELTA;
	setsize (e, '0 0 0', '0 0 0');
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
	dir = normalize(dir);

	e = newdecor();
	e.isdecor = TRUE;
	e.createdtime = time;
	e.alpha = 1;
	e.angles = vectoangles(dir);
	e.cnt = time + 10;
	e.effects = EF_LOWPRECISION;
	e.flags = FL_ONGROUND;
	e.forcescale = 15;
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
