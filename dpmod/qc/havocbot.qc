
// itemscore = (howmuchmoreIwant / howmuchIcanwant) / itemdistance
// waypointscore = 0.7 / waypointdistance

float(entity e, vector start, vector m1, vector m2, vector end) tracewalk;
float(vector m1, vector m2, vector m3, vector m4) boxesoverlap =
{
	return m2_x >= m3_x && m1_x <= m4_x && m2_y >= m3_y && m1_y <= m4_y && m2_z >= m3_z && m1_z <= m4_z;
};

.entity wp00, wp01, wp02, wp03, wp04, wp05, wp06, wp07;
.entity wp08, wp09, wp10, wp11, wp12, wp13, wp14, wp15;
.entity wp16, wp17, wp18, wp19, wp20, wp21, wp22, wp23, wp24, wp25, wp26, wp27, wp28, wp29, wp30, wp31;
.float wp00mincost, wp01mincost, wp02mincost, wp03mincost, wp04mincost, wp05mincost, wp06mincost, wp07mincost;
.float wp08mincost, wp09mincost, wp10mincost, wp11mincost, wp12mincost, wp13mincost, wp14mincost, wp15mincost;
.float wp16mincost, wp17mincost, wp18mincost, wp19mincost, wp20mincost, wp21mincost, wp22mincost, wp23mincost, wp24mincost, wp25mincost, wp26mincost, wp27mincost, wp28mincost, wp29mincost, wp30mincost, wp31mincost;
.float wpfire, wpcost;
.float wpisbox;

.entity goalcurrent, goalstack01, goalstack02, goalstack03, goalstack04, goalstack05, goalstack06, goalstack07, goalstack08, goalstack09;
.entity goalstack10, goalstack11, goalstack12, goalstack13, goalstack14, goalstack15, goalstack16, goalstack17, goalstack18, goalstack19;
.entity goalstack20, goalstack21, goalstack22, goalstack23, goalstack24, goalstack25, goalstack26, goalstack27, goalstack28, goalstack29;
.entity goalstack30, goalstack31, goalstack32;

void(entity from, entity to) waypoint_addlink =
{
	local float c;

	if (from == to)
		return;

	if (from.wp00 == to) return;if (from.wp01 == to) return;if (from.wp02 == to) return;if (from.wp03 == to) return;
	if (from.wp04 == to) return;if (from.wp05 == to) return;if (from.wp06 == to) return;if (from.wp07 == to) return;
	if (from.wp08 == to) return;if (from.wp09 == to) return;if (from.wp10 == to) return;if (from.wp11 == to) return;
	if (from.wp12 == to) return;if (from.wp13 == to) return;if (from.wp14 == to) return;if (from.wp15 == to) return;
	if (from.wp16 == to) return;if (from.wp17 == to) return;if (from.wp18 == to) return;if (from.wp19 == to) return;
	if (from.wp20 == to) return;if (from.wp21 == to) return;if (from.wp22 == to) return;if (from.wp23 == to) return;
	if (from.wp24 == to) return;if (from.wp25 == to) return;if (from.wp26 == to) return;if (from.wp27 == to) return;
	if (from.wp28 == to) return;if (from.wp29 == to) return;if (from.wp30 == to) return;if (from.wp31 == to) return;

	// if either is a box, then the only way they would link up is by
	// overlapping eachother, so the minimum travel cost is... 0
	if (to.wpisbox || from.wpisbox)
		c = 0;
	else
		c = vlen(to.origin - from.origin);

	if (from.wp31mincost < c) return;
	if (from.wp30mincost < c) {from.wp31 = to;from.wp31mincost = c;return;} from.wp31 = from.wp30;from.wp31mincost = from.wp30mincost;
	if (from.wp29mincost < c) {from.wp30 = to;from.wp30mincost = c;return;} from.wp30 = from.wp29;from.wp30mincost = from.wp29mincost;
	if (from.wp28mincost < c) {from.wp29 = to;from.wp29mincost = c;return;} from.wp29 = from.wp28;from.wp29mincost = from.wp28mincost;
	if (from.wp27mincost < c) {from.wp28 = to;from.wp28mincost = c;return;} from.wp28 = from.wp27;from.wp28mincost = from.wp27mincost;
	if (from.wp26mincost < c) {from.wp27 = to;from.wp27mincost = c;return;} from.wp27 = from.wp26;from.wp27mincost = from.wp26mincost;
	if (from.wp25mincost < c) {from.wp26 = to;from.wp26mincost = c;return;} from.wp26 = from.wp25;from.wp26mincost = from.wp25mincost;
	if (from.wp24mincost < c) {from.wp25 = to;from.wp25mincost = c;return;} from.wp25 = from.wp24;from.wp25mincost = from.wp24mincost;
	if (from.wp23mincost < c) {from.wp24 = to;from.wp24mincost = c;return;} from.wp24 = from.wp23;from.wp24mincost = from.wp23mincost;
	if (from.wp22mincost < c) {from.wp23 = to;from.wp23mincost = c;return;} from.wp23 = from.wp22;from.wp23mincost = from.wp22mincost;
	if (from.wp21mincost < c) {from.wp22 = to;from.wp22mincost = c;return;} from.wp22 = from.wp21;from.wp22mincost = from.wp21mincost;
	if (from.wp20mincost < c) {from.wp21 = to;from.wp21mincost = c;return;} from.wp21 = from.wp20;from.wp21mincost = from.wp20mincost;
	if (from.wp19mincost < c) {from.wp20 = to;from.wp20mincost = c;return;} from.wp20 = from.wp19;from.wp20mincost = from.wp19mincost;
	if (from.wp18mincost < c) {from.wp19 = to;from.wp19mincost = c;return;} from.wp19 = from.wp18;from.wp19mincost = from.wp18mincost;
	if (from.wp17mincost < c) {from.wp18 = to;from.wp18mincost = c;return;} from.wp18 = from.wp17;from.wp18mincost = from.wp17mincost;
	if (from.wp16mincost < c) {from.wp17 = to;from.wp17mincost = c;return;} from.wp17 = from.wp16;from.wp17mincost = from.wp16mincost;
	if (from.wp15mincost < c) {from.wp16 = to;from.wp16mincost = c;return;} from.wp16 = from.wp15;from.wp16mincost = from.wp15mincost;
	if (from.wp14mincost < c) {from.wp15 = to;from.wp15mincost = c;return;} from.wp15 = from.wp14;from.wp15mincost = from.wp14mincost;
	if (from.wp13mincost < c) {from.wp14 = to;from.wp14mincost = c;return;} from.wp14 = from.wp13;from.wp14mincost = from.wp13mincost;
	if (from.wp12mincost < c) {from.wp13 = to;from.wp13mincost = c;return;} from.wp13 = from.wp12;from.wp13mincost = from.wp12mincost;
	if (from.wp11mincost < c) {from.wp12 = to;from.wp12mincost = c;return;} from.wp12 = from.wp11;from.wp12mincost = from.wp11mincost;
	if (from.wp10mincost < c) {from.wp11 = to;from.wp11mincost = c;return;} from.wp11 = from.wp10;from.wp11mincost = from.wp10mincost;
	if (from.wp09mincost < c) {from.wp10 = to;from.wp10mincost = c;return;} from.wp10 = from.wp09;from.wp10mincost = from.wp09mincost;
	if (from.wp08mincost < c) {from.wp09 = to;from.wp09mincost = c;return;} from.wp09 = from.wp08;from.wp09mincost = from.wp08mincost;
	if (from.wp07mincost < c) {from.wp08 = to;from.wp08mincost = c;return;} from.wp08 = from.wp07;from.wp08mincost = from.wp07mincost;
	if (from.wp06mincost < c) {from.wp07 = to;from.wp07mincost = c;return;} from.wp07 = from.wp06;from.wp07mincost = from.wp06mincost;
	if (from.wp05mincost < c) {from.wp06 = to;from.wp06mincost = c;return;} from.wp06 = from.wp05;from.wp06mincost = from.wp05mincost;
	if (from.wp04mincost < c) {from.wp05 = to;from.wp05mincost = c;return;} from.wp05 = from.wp04;from.wp05mincost = from.wp04mincost;
	if (from.wp03mincost < c) {from.wp04 = to;from.wp04mincost = c;return;} from.wp04 = from.wp03;from.wp04mincost = from.wp03mincost;
	if (from.wp02mincost < c) {from.wp03 = to;from.wp03mincost = c;return;} from.wp03 = from.wp02;from.wp03mincost = from.wp02mincost;
	if (from.wp01mincost < c) {from.wp02 = to;from.wp02mincost = c;return;} from.wp02 = from.wp01;from.wp02mincost = from.wp01mincost;
	if (from.wp00mincost < c) {from.wp01 = to;from.wp01mincost = c;return;} from.wp01 = from.wp00;from.wp01mincost = from.wp00mincost;
	from.wp00 = to;from.wp00mincost = c;return;

	/*
	if (from.wp01 == world) {from.wp01 = to;from.wp01mincost = c;return;}
	if (from.wp02 == world) {from.wp02 = to;from.wp02mincost = c;return;}
	if (from.wp03 == world) {from.wp03 = to;from.wp03mincost = c;return;}
	if (from.wp04 == world) {from.wp04 = to;from.wp04mincost = c;return;}
	if (from.wp05 == world) {from.wp05 = to;from.wp05mincost = c;return;}
	if (from.wp06 == world) {from.wp06 = to;from.wp06mincost = c;return;}
	if (from.wp07 == world) {from.wp07 = to;from.wp07mincost = c;return;}
	if (from.wp08 == world) {from.wp08 = to;from.wp08mincost = c;return;}
	if (from.wp09 == world) {from.wp09 = to;from.wp09mincost = c;return;}
	if (from.wp10 == world) {from.wp10 = to;from.wp10mincost = c;return;}
	if (from.wp11 == world) {from.wp11 = to;from.wp11mincost = c;return;}
	if (from.wp12 == world) {from.wp12 = to;from.wp12mincost = c;return;}
	if (from.wp13 == world) {from.wp13 = to;from.wp13mincost = c;return;}
	if (from.wp14 == world) {from.wp14 = to;from.wp14mincost = c;return;}
	if (from.wp15 == world) {from.wp15 = to;from.wp15mincost = c;return;}
	if (from.wp16 == world) {from.wp16 = to;from.wp16mincost = c;return;}
	if (from.wp17 == world) {from.wp17 = to;from.wp17mincost = c;return;}
	if (from.wp18 == world) {from.wp18 = to;from.wp18mincost = c;return;}
	if (from.wp19 == world) {from.wp19 = to;from.wp19mincost = c;return;}
	if (from.wp20 == world) {from.wp20 = to;from.wp20mincost = c;return;}
	if (from.wp21 == world) {from.wp21 = to;from.wp21mincost = c;return;}
	if (from.wp22 == world) {from.wp22 = to;from.wp22mincost = c;return;}
	if (from.wp23 == world) {from.wp23 = to;from.wp23mincost = c;return;}
	if (from.wp24 == world) {from.wp24 = to;from.wp24mincost = c;return;}
	if (from.wp25 == world) {from.wp25 = to;from.wp25mincost = c;return;}
	if (from.wp26 == world) {from.wp26 = to;from.wp26mincost = c;return;}
	if (from.wp27 == world) {from.wp27 = to;from.wp27mincost = c;return;}
	if (from.wp28 == world) {from.wp28 = to;from.wp28mincost = c;return;}
	if (from.wp29 == world) {from.wp29 = to;from.wp29mincost = c;return;}
	if (from.wp30 == world) {from.wp30 = to;from.wp30mincost = c;return;}
	if (from.wp31 == world) {from.wp31 = to;from.wp31mincost = c;return;}
	*/
};

void() waypoint_think =
{
	local entity e;
	local vector v;
	e = findchain(classname, "waypoint");
	while (e)
	{
		if (self.wpisbox)
		{
			// box
			if (boxesoverlap(self.absmin, self.absmax, e.absmin, e.absmax))
			{
				waypoint_addlink(self, e);
				waypoint_addlink(e, self);
			}
		}
		else
		{
			// point
			v = self.origin;
			v_x = bound(e.absmin_x, v_x, e.absmax_x);
			v_y = bound(e.absmin_y, v_y, e.absmax_y);
			v_z = bound(e.absmin_z, v_z, e.absmax_z);
			if (vlen(v - self.origin) < self.wp31mincost)
			{
				//traceline(self.origin, e.origin, FALSE, world);
				//if (trace_fraction == 1)
				if (tracewalk(self, self.origin, '-16 -16 -24', '16 16 24', v))
					waypoint_addlink(self, e);
				if (tracewalk(self, v, '-16 -16 -24', '16 16 24', self.origin))
					waypoint_addlink(e, self);
			}
		}
		e = e.chain;
	}
};

void(entity wp) waypoint_relink =
{
	local float f;
	local vector m1, m2;
	if (wp == world)
		return;
	f = 1050; // maximum search range for other waypoints
	m1 = wp.mins;
	m2 = wp.maxs;
	// TODO: add some sort of visible box in edit mode for box waypoints
	if (cvar("havocbot_editwaypoints"))
		setmodel(wp, "progs/s_bubble.spr");
	else
		wp.model = "";
	setsize(wp, m1, m2);
	wp.wpisbox = vlen(wp.size) > 0;
	wp.enemy = world;
	wp.owner = world;
	wp.wp00 = wp.wp01 = wp.wp02 = wp.wp03 = wp.wp04 = wp.wp05 = wp.wp06 = wp.wp07 = world;wp.wp00mincost = wp.wp01mincost = wp.wp02mincost = wp.wp03mincost = wp.wp04mincost = wp.wp05mincost = wp.wp06mincost = wp.wp07mincost = f;
	wp.wp08 = wp.wp09 = wp.wp10 = wp.wp11 = wp.wp12 = wp.wp13 = wp.wp14 = wp.wp15 = world;wp.wp08mincost = wp.wp09mincost = wp.wp10mincost = wp.wp11mincost = wp.wp12mincost = wp.wp13mincost = wp.wp14mincost = wp.wp15mincost = f;
	wp.wp16 = wp.wp17 = wp.wp18 = wp.wp19 = wp.wp20 = wp.wp21 = wp.wp22 = wp.wp23 = world;wp.wp16mincost = wp.wp17mincost = wp.wp18mincost = wp.wp19mincost = wp.wp20mincost = wp.wp21mincost = wp.wp22mincost = wp.wp23mincost = f;
	wp.wp24 = wp.wp25 = wp.wp26 = wp.wp27 = wp.wp28 = wp.wp29 = wp.wp30 = wp.wp31 = world;wp.wp24mincost = wp.wp25mincost = wp.wp26mincost = wp.wp27mincost = wp.wp28mincost = wp.wp29mincost = wp.wp30mincost = wp.wp31mincost = f;
	wp.think = waypoint_think;
	wp.nextthink = time + 0.1;
}

void(vector o, float f) waypoint_spawn =
{
	newmis = spawn();
	newmis.classname = "waypoint";
	newmis.lefty = f;
	setorigin(newmis, o);
	waypoint_relink(newmis);
};

// waypoint map entity
void() waypoint =
{
	setorigin(self, self.origin);
	waypoint_relink(self);
};

void(entity e) waypoint_remove =
{
	// tell all linked waypoints that they need to relink
	waypoint_relink(e.wp00);
	waypoint_relink(e.wp01);
	waypoint_relink(e.wp02);
	waypoint_relink(e.wp03);
	waypoint_relink(e.wp04);
	waypoint_relink(e.wp05);
	waypoint_relink(e.wp06);
	waypoint_relink(e.wp07);
	waypoint_relink(e.wp08);
	waypoint_relink(e.wp09);
	waypoint_relink(e.wp10);
	waypoint_relink(e.wp11);
	waypoint_relink(e.wp12);
	waypoint_relink(e.wp13);
	waypoint_relink(e.wp14);
	waypoint_relink(e.wp15);
	waypoint_relink(e.wp16);
	waypoint_relink(e.wp17);
	waypoint_relink(e.wp18);
	waypoint_relink(e.wp19);
	waypoint_relink(e.wp20);
	waypoint_relink(e.wp21);
	waypoint_relink(e.wp22);
	waypoint_relink(e.wp23);
	waypoint_relink(e.wp24);
	waypoint_relink(e.wp25);
	waypoint_relink(e.wp26);
	waypoint_relink(e.wp27);
	waypoint_relink(e.wp28);
	waypoint_relink(e.wp29);
	waypoint_relink(e.wp30);
	waypoint_relink(e.wp31);
	remove(e);
};

void() waypoint_removeall =
{
	local entity head, next;
	head = findchain(classname, "waypoint");
	while (head)
	{
		next = head.chain;
		remove(head);
		head = next;
	}
};

void() waypoint_relinkall =
{
	local entity head;
	head = findchain(classname, "waypoint");
	while (head)
	{
		waypoint_relink(head);
		head = head.chain;
	}
};

void() waypoint_saveall =
{
	local string filename, s;
	local float file, c;
	local entity w;
	filename = strcat("waypoints/", mapname);
	filename = strcat(filename, ".waypoints");
	file = fopen(filename, FILE_WRITE);
	if (file >= 0)
	{
		c = 0;
		w = findchain(classname, "waypoint");
		while (w)
		{
			s = strcat(vtos(w.origin), "\n");
			s = strcat(s, ftos(w.lefty));
			s = strcat(s, "\n");
			fputs(file, s);
			w = w.chain;
			c = c + 1;
		}
		fclose(file);
		bprint("saved ");
		bprint(ftos(c));
		bprint(" waypoints to waypoints/");
		bprint(mapname);
		bprint(".waypoints\n");
	}
	else
	{
		bprint("waypoint save to ");
		bprint(filename);
		bprint(" failed\n");
	}
};

float() waypoint_loadall =
{
	local string filename, s;
	local float file, c, fl;
	local vector org;
	c = 0;
	filename = strcat("waypoints/", mapname);
	filename = strcat(filename, ".waypoints");
	file = fopen(filename, FILE_READ);
	if (file >= 0)
	{
		waypoint_removeall();
		while (1)
		{
			s = fgets(file);
			if (!s)
				break;
			org = stov(s);
			s = fgets(file);
			if (!s)
				break;
			fl = stof(s);
			waypoint_spawn(org, fl);
			c = c + 1;
		}
		fclose(file);
		dprint("loaded ");
		dprint(ftos(c));
		dprint(" waypoints from waypoints/");
		dprint(mapname);
		dprint(".waypoints\n");
	}
	else
	{
		dprint("waypoint load from ");
		dprint(filename);
		dprint(" failed\n");
	}
	return c;
};

void(entity e) waypointspawnforitem =
{
	local entity w;
	local vector org;
	org = e.origin + (e.mins + e.maxs) * 0.5;
	org_z = e.origin_z + e.mins_z + 24;
	// don't spawn an item waypoint if it already exists
	w = findchain(classname, "waypoint");
	while (w)
	{
		if (vlen(w.size) > 1)
		{
			if (boxesoverlap(org, org, w.absmin, w.absmax))
				return;
		}
		else
		{
			if (vlen(w.origin - org) < 16)
				return;
		}
		w = w.chain;
	}
	waypoint_spawn(org, 0);
};

void() havocbot_clearroute =
{
	self.goalcurrent = world;
	self.goalstack01 = world;
	self.goalstack02 = world;
	self.goalstack03 = world;
	self.goalstack04 = world;
	self.goalstack05 = world;
	self.goalstack06 = world;
	self.goalstack07 = world;
	self.goalstack08 = world;
	self.goalstack09 = world;
	self.goalstack10 = world;
	self.goalstack11 = world;
	self.goalstack12 = world;
	self.goalstack13 = world;
	self.goalstack14 = world;
	self.goalstack15 = world;
	self.goalstack16 = world;
	self.goalstack17 = world;
	self.goalstack18 = world;
	self.goalstack19 = world;
	self.goalstack20 = world;
	self.goalstack21 = world;
	self.goalstack22 = world;
	self.goalstack23 = world;
	self.goalstack24 = world;
	self.goalstack25 = world;
	self.goalstack26 = world;
	self.goalstack27 = world;
	self.goalstack28 = world;
	self.goalstack29 = world;
	self.goalstack30 = world;
	self.goalstack31 = world;
	self.goalstack32 = world;
};

void(entity e) havocbot_pushroute =
{
	self.goalstack32 = self.goalstack31;
	self.goalstack31 = self.goalstack30;
	self.goalstack30 = self.goalstack29;
	self.goalstack29 = self.goalstack28;
	self.goalstack28 = self.goalstack27;
	self.goalstack27 = self.goalstack26;
	self.goalstack26 = self.goalstack25;
	self.goalstack25 = self.goalstack24;
	self.goalstack24 = self.goalstack23;
	self.goalstack23 = self.goalstack22;
	self.goalstack22 = self.goalstack21;
	self.goalstack21 = self.goalstack20;
	self.goalstack20 = self.goalstack19;
	self.goalstack19 = self.goalstack18;
	self.goalstack18 = self.goalstack17;
	self.goalstack17 = self.goalstack16;
	self.goalstack16 = self.goalstack15;
	self.goalstack15 = self.goalstack14;
	self.goalstack14 = self.goalstack13;
	self.goalstack13 = self.goalstack12;
	self.goalstack12 = self.goalstack11;
	self.goalstack11 = self.goalstack10;
	self.goalstack10 = self.goalstack09;
	self.goalstack09 = self.goalstack08;
	self.goalstack08 = self.goalstack07;
	self.goalstack07 = self.goalstack06;
	self.goalstack06 = self.goalstack05;
	self.goalstack05 = self.goalstack04;
	self.goalstack04 = self.goalstack03;
	self.goalstack03 = self.goalstack02;
	self.goalstack02 = self.goalstack01;
	self.goalstack01 = self.goalcurrent;
	self.goalcurrent = e;
};

void() havocbot_poproute =
{
	self.goalcurrent = self.goalstack01;
	self.goalstack01 = self.goalstack02;
	self.goalstack02 = self.goalstack03;
	self.goalstack03 = self.goalstack04;
	self.goalstack04 = self.goalstack05;
	self.goalstack05 = self.goalstack06;
	self.goalstack06 = self.goalstack07;
	self.goalstack07 = self.goalstack08;
	self.goalstack08 = self.goalstack09;
	self.goalstack09 = self.goalstack10;
	self.goalstack10 = self.goalstack11;
	self.goalstack11 = self.goalstack12;
	self.goalstack12 = self.goalstack13;
	self.goalstack13 = self.goalstack14;
	self.goalstack14 = self.goalstack15;
	self.goalstack15 = self.goalstack16;
	self.goalstack16 = self.goalstack17;
	self.goalstack17 = self.goalstack18;
	self.goalstack18 = self.goalstack19;
	self.goalstack19 = self.goalstack20;
	self.goalstack20 = self.goalstack21;
	self.goalstack21 = self.goalstack22;
	self.goalstack22 = self.goalstack23;
	self.goalstack23 = self.goalstack24;
	self.goalstack24 = self.goalstack25;
	self.goalstack25 = self.goalstack26;
	self.goalstack26 = self.goalstack27;
	self.goalstack27 = self.goalstack28;
	self.goalstack28 = self.goalstack29;
	self.goalstack29 = self.goalstack30;
	self.goalstack30 = self.goalstack31;
	self.goalstack31 = self.goalstack32;
	self.goalstack32 = world;
};

.entity nearestwaypoint;
//.vector nearestwaypointorigin;
.float nearestwaypointtimeout;

entity(vector org) havocbot_findnearestwaypoint =
{
	local entity waylist, w, best;
	local float dist, bestdist;
	local vector v;
	best = world;
	bestdist = 1000;
	waylist = findchain(classname, "waypoint");
	// do two scans, because box test is cheaper
	w = waylist;
	while (w)
	{
		// if object is touching waypoint
		if (boxesoverlap(org, org, w.absmin, w.absmax))
			return w;
		w = w.chain;
	}
	// box check failed, try walk
	w = waylist;
	while (w)
	{
		// if object can walk from waypoint
		v = org;
		v_x = bound(w.absmin_x, v_x, w.absmax_x);
		v_y = bound(w.absmin_y, v_y, w.absmax_y);
		v_z = bound(w.absmin_z, v_z, w.absmax_z);
		dist = vlen(v - org);
		if (bestdist > dist)
		{
			traceline(v, org, TRUE, self);
			if (trace_fraction == 1)
			{
				if (tracewalk(self, v, '-16 -16 -24', '16 16 24', org))
				{
					bestdist = dist;
					best = w;
				}
			}
		}
		w = w.chain;
	}
	return best;
}

void(entity e) havocbot_updatenearestwaypoint =
{
	if (!e)
		return;
	if (time > e.nearestwaypointtimeout)
	{
		e.nearestwaypoint = havocbot_findnearestwaypoint(e.origin);
		e.nearestwaypointtimeout = time + random() * 3 + 5;
	}
};

void() havocbot_markroutes_nearestwaypoints =
{
	local entity head;
	local float dist;
	local vector v, m1, m2;
	head = findchain(classname, "waypoint");
	while (head)
	{
		m1 = head.origin + head.mins;
		m2 = head.origin + head.maxs;
		v = self.origin;
		v_x = bound(m1_x, v_x, m2_x);
		v_y = bound(m1_y, v_y, m2_y);
		v_z = bound(m1_z, v_z, m2_z);
		dist = vlen(v - self.origin);
		if (dist < 1000)
		{
			if (dist < 4)
			{
				// if bot is very near a waypoint don't bother doing a trace
				head.dest = v;
				head.wpcost = dist + head.dmg;
				head.wpfire = 1;
				head.enemy = world;
			}
			else
			{
				traceline(self.origin, v, TRUE, self);
				if (trace_fraction == 1)
				{
					if (tracewalk(self, self.origin, self.mins, self.maxs, v))
					{
						head.dest = v;
						head.wpcost = dist + head.dmg;
						head.wpfire = 1;
						head.enemy = world;
					}
				}
			}
		}
		head = head.chain;
	}
}

vector(vector p, vector m1, vector m2) nearestpointonbox =
{
	p_x = bound(m1_x, p_x, m2_x);
	p_y = bound(m1_y, p_y, m2_y);
	p_z = bound(m1_z, p_z, m2_z);
	return p;
};

void(entity w, entity wp, float cost2, vector p) havocbot_markroutes_checkwaypoint =
{
	local vector m1;
	local vector m2;
	local vector v;
	if (wp.wpisbox)
	{
		m1 = wp.absmin;
		m2 = wp.absmax;
		v_x = bound(m1_x, p_x, m2_x);
		v_y = bound(m1_y, p_y, m2_y);
		v_z = bound(m1_z, p_z, m2_z);
	}
	else
		v = wp.origin;
	cost2 = cost2 + vlen(v);
	if (wp.wpcost > cost2)
	{
		wp.wpcost = cost2;
		wp.enemy = w;
		wp.wpfire = 1;
		wp.dest = v;
	}
};

void() havocbot_markroutes =
{
	local entity w, wp, waylist;
	local float searching, cost, cost2;
	local vector p;
	w = waylist = findchain(classname, "waypoint");
	while (w)
	{
		w.dest = '0 0 0';
		w.wpcost = 10000000;
		w.wpfire = 0;
		w.enemy = world;
		w = w.chain;
	}
	havocbot_markroutes_nearestwaypoints();
	searching = TRUE;
	while (searching)
	{
		searching = FALSE;
		w = waylist;
		while (w)
		{
			if (w.wpfire)
			{
				searching = TRUE;
				w.wpfire = 0;
				cost = w.wpcost;
				p = w.dest;
				wp = w.wp00;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + wp.wp00mincost) havocbot_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp01;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + wp.wp01mincost) havocbot_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp02;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + wp.wp02mincost) havocbot_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp03;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + wp.wp03mincost) havocbot_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp04;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + wp.wp04mincost) havocbot_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp05;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + wp.wp05mincost) havocbot_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp06;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + wp.wp06mincost) havocbot_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp07;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + wp.wp07mincost) havocbot_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp08;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + wp.wp08mincost) havocbot_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp09;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + wp.wp09mincost) havocbot_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp10;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + wp.wp10mincost) havocbot_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp11;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + wp.wp11mincost) havocbot_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp12;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + wp.wp12mincost) havocbot_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp13;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + wp.wp13mincost) havocbot_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp14;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + wp.wp14mincost) havocbot_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp15;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + wp.wp15mincost) havocbot_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp16;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + wp.wp16mincost) havocbot_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp17;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + wp.wp17mincost) havocbot_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp18;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + wp.wp18mincost) havocbot_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp19;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + wp.wp19mincost) havocbot_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp20;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + wp.wp20mincost) havocbot_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp21;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + wp.wp21mincost) havocbot_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp22;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + wp.wp22mincost) havocbot_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp23;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + wp.wp23mincost) havocbot_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp24;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + wp.wp24mincost) havocbot_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp25;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + wp.wp25mincost) havocbot_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp26;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + wp.wp26mincost) havocbot_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp27;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + wp.wp27mincost) havocbot_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp28;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + wp.wp28mincost) havocbot_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp29;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + wp.wp29mincost) havocbot_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp30;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + wp.wp30mincost) havocbot_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp31;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + wp.wp31mincost) havocbot_markroutes_checkwaypoint(w, wp, cost2, p);
				}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}
			}
			w = w.chain;
		}
	}
};

void(entity e, float f) havocbot_routerating =
{
	if (!e)
		return;
	//bprint(etos(e));
	//bprint("\n");
	havocbot_updatenearestwaypoint(e);
	if (e.nearestwaypoint)
	{
		f = f / ((e.nearestwaypoint.wpcost + vlen(e.origin - e.nearestwaypoint.dest)) * 0.001 + 1);
		if (havocbot_bestrating < f)
		{
			havocbot_bestrating = f;
			havocbot_bestgoal = e;
		}
	}
};

void(entity e) havocbot_routetogoal =
{
	// clear the route and add the new one
	havocbot_clearroute();
	self.goalentity = e;
	if (!e)
		return;
	havocbot_pushroute(e);
	//te_smallflash((e.absmin + e.absmax) * 0.5);
	//bprint("havocbot_routetogoal(");
	//bprint(etos(e));
	//bprint(") : ");
	//bprint(etos(e));
	//if (tracewalk(self, self.origin, '-16 -16 -24', '16 16 24', e.origin))
	//{
	//	//bprint("\n");
	//	return;
	//}
	e = e.nearestwaypoint;
	while (e != world)
	{
		//bprint(" ");
		//bprint(etos(e));
		//te_smallflash((e.absmin + e.absmax) * 0.5);
		havocbot_pushroute(e);
		e = e.enemy;
	}
	//bprint("\n");
};

void() havocbot_popgoals =
{
	local vector org, m1, m2;
	org = self.origin + self.velocity * 0.2;
	m1 = org + self.mins;
	m2 = org + self.maxs;
	while (self.goalcurrent && boxesoverlap(m1, m2, self.goalcurrent.absmin, self.goalcurrent.absmax))
		havocbot_poproute();
}

entity tracewalkent; // invisible entity that is reused for all tracewalks
float maxspeed;
float sv_accelerate;

float(entity e, vector start, vector m1, vector m2, vector end) tracewalk =
{
	local vector move;
	local vector dir;
	local vector nostependpos;
	local float dist;
	local float totaldist;
	local float stepdist;
	local float yaw;
	local float ignorehazards;
	local float p;
	local float nostepfrac;
	local entity saveself;
	move = end - start;
	move_z = 0;
	dist = totaldist = vlen(move);
	dir = normalize(move);
	stepdist = 32;
	saveself = self;
	if (!tracewalkent)
		tracewalkent = spawn();
	setsize(tracewalkent, m1, m2);
	tracewalkent.owner = self; // avoid collisions
	self = tracewalkent;
	setorigin(self, start);
	//self.angles = vectoangles(dir);
	p = pointcontents(self.origin);
	if (p == CONTENT_EMPTY)
	{
		tracebox(start + '0 0 18', self.mins, self.maxs, start + '0 0 -18', FALSE, e);
		if (trace_fraction >= 1) // start isn't even on the floor
		{
			self = saveself;
			return 0;
		}
	}
	ignorehazards = FALSE;
	p = pointcontents(start);
	if (p == CONTENT_LAVA || p == CONTENT_SLIME)
		ignorehazards = TRUE;
	yaw = vectoyaw(move);
	move = end - self.origin;
	while (1)
	{
		if (boxesoverlap(end, end, self.absmin, self.absmax))
		{
			//WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
			//WriteByte (MSG_BROADCAST, TE_GUNSHOT);
			//WriteVec (MSG_BROADCAST, end);
			self = saveself;
			// succeeded
			return 1;
		}
		if (dist <= 0)
			break;
		if (stepdist > dist)
			stepdist = dist;
		dist = dist - stepdist;
		p = 0;
		if (!ignorehazards)
		{
			p = pointcontents(self.origin);
			if (p == CONTENT_LAVA || p == CONTENT_SLIME)
			{
				self = saveself;
				// hazards blocking path
				return 0;
			}
		}
		if (p == 0)
			p = pointcontents(self.origin);
		if (p != CONTENT_EMPTY)
		{
			move = normalize(end - self.origin);
			tracebox(self.origin, self.mins, self.maxs, self.origin + move * stepdist, FALSE, e);
			if (trace_startsolid || trace_fraction < 1)
			{
				//particle(self.origin, move * 64, 104, 4);
				self = saveself;
				// failed
				return 0;
			}
			setorigin(self, trace_endpos);
		}
		else //if (!walkmove(yaw, stepdist))
		{
			// walkmove failed, fall back to our own methods
			move = dir * stepdist + self.origin;
			// trace twice, first at ground level, then at
			// stepheight, stepheight trace will be used instead
			// of ground trace if it went further, if ground
			// level was chosen check if we made any progress,
			// if we did, fall to floor, if we did not, fail
			tracebox(self.origin, self.mins, self.maxs, move, FALSE, e);
			if (trace_startsolid)
			{
				//move = normalize(end - self.origin);
				//particle(self.origin, move * 64, 104, 4);
				self = saveself;
				// failed
				return 0;
			}
			nostepfrac = trace_fraction;
			nostependpos = trace_endpos;
			tracebox(self.origin + '0 0 18', self.mins, self.maxs, move + '0 0 18', FALSE, e);
			if (trace_fraction > nostepfrac + 0.001)
			{
				// stepped, fall to floor
				tracebox(trace_endpos, self.mins, self.maxs, trace_endpos + '0 0 -65536', FALSE, e);
				setorigin(self, trace_endpos);
			}
			else
			{
				if (nostepfrac >= 0.001)
				{
					// moved, fall to floor
					tracebox(nostependpos, self.mins, self.maxs, nostependpos + '0 0 -65536', FALSE, e);
					setorigin(self, trace_endpos);
				}
				else
				{
					// didn't move
					//move = normalize(end - self.origin);
					//particle(self.origin, move * 64, 104, 4);
					self = saveself;
					// failed
					return 0;
				}
			}
		}
	}
	//WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	//WriteByte (MSG_BROADCAST, TE_GUNSHOT);
	//WriteVec (MSG_BROADCAST, end);
	self = saveself;
	// moved but didn't arrive at the intended destination
	return 0;
};

.float isbot;

float havoccurrentbots;
float havocbots;
entity havocbot_list;
.entity nextbot;

float BOTNAMES = 64;
string(float r) havocbot_namefornumber =
{
	if (r <  1) return "Thunderstorm";
	if (r <  2) return "Deadly Dream";
	if (r <  3) return "Darkness";
	if (r <  4) return "Scorcher";
	if (r <  5) return "57 Chevy";
	if (r <  6) return "Dark Avenger";
	if (r <  7) return "Dying Time";
	if (r <  8) return "Paranoia";
	if (r <  9) return "Eureka";
	if (r < 10) return "Mystery";
	if (r < 11) return "Toxic";
	if (r < 12) return "Dominion";
	if (r < 13) return "Pegasus";
	if (r < 14) return "Sensible";
	if (r < 15) return "I Love Gibs";
	if (r < 16) return "The New Guy";
	if (r < 17) return "Boy With A Gun";
	if (r < 18) return "Universe Man";
	if (r < 19) return "The Evil One";
	if (r < 20) return "2MuchGibsMan";
	if (r < 21) return "The Plasma man";
	if (r < 22) return "Strange Brew";
	if (r < 23) return "Potato Head";
	if (r < 24) return "The Angel";
	if (r < 25) return "Radioactive Man";
	if (r < 26) return "Gator";
	if (r < 27) return "Your Demise";
	if (r < 28) return "The Gladiator";
	if (r < 29) return "Spaceman Spiff";
	if (r < 30) return "Johnny Dangerously";
	if (r < 31) return "Elmer Fudd";
	if (r < 32) return "Kangaroo";
	if (r < 33) return "Thunder Hammer";
	if (r < 34) return "Deadline";
	if (r < 35) return "Light";
	if (r < 36) return "Frosty";
	if (r < 37) return "Roadkill";
	if (r < 38) return "Holy Avenger";
	if (r < 39) return "Death";
	if (r < 40) return "Panic";
	if (r < 41) return "Discovery";
	if (r < 42) return "Shadow";
	if (r < 43) return "Acidic";
	if (r < 44) return "Dominator";
	if (r < 45) return "Rocket Fiend";
	if (r < 46) return "Hellfire";
	if (r < 47) return "Necrotic";
	if (r < 48) return "Newbie";
	if (r < 49) return "Girl With A Gun";
	if (r < 50) return "Particle Man";
	if (r < 51) return "The Good One";
	if (r < 52) return "Spellbinder";
	if (r < 53) return "Lion";
	if (r < 54) return "Controlled";
	if (r < 55) return "Airhead";
	if (r < 56) return "The Demon";
	if (r < 57) return "Delirium";
	if (r < 58) return "Crocodile";
	if (r < 59) return "Resurrection";
	if (r < 60) return "Dark Bringer";
	if (r < 61) return "Calvin";
	if (r < 62) return "Danger";
	if (r < 63) return "Bugs";
	return "Flatline";
};

string() havocbot_name =
{
	local string name;
	local float r;

	// first see if all names are taken
	r = 0;
	do
	{
		name = havocbot_namefornumber(r - BOTNAMES);
		r = r + 1;
	}
	while (r < BOTNAMES && find(world, netname, name));

	// all names are taken, so pick one at random
	if (r == BOTNAMES)
		return havocbot_namefornumber(random() * BOTNAMES);

	// not all names are taken (yet), so randomly try names until we find one
	// of the ones that isn't taken
	do
		name = havocbot_namefornumber(random() * BOTNAMES);
	while (find(world, netname, name));

	return name;
};

void(float t, float f1, float f2, entity e1, vector v1, vector v2, vector v3, vector v4) havocbot_lagfunc;

.void() havocbot_role;
void() havocbot_chooserole;
entity havocbot_goaltoken;

void() havocbot_relinkbotlist =
{
	local entity e;
	havoccurrentbots = 0;
	havocbot_list = e = findchainfloat(isbot, TRUE);
	while (e)
	{
		havoccurrentbots = havoccurrentbots + 1;
		e.nextbot = e.chain;
		e = e.chain;
	}
	havocbot_goaltoken = havocbot_list;
};

void() havocbot_clientconnect =
{
	if (clienttype(self) != CLIENTTYPE_BOT)
		return;
	self.lag_func = havocbot_lagfunc;
	self.isbot = TRUE;
	//self.think = ClientConnect;
	//self.nextthink = time + random() * 0.5 + 0.2;
	self.createdtime = self.nextthink;
	self.havocbot_role = SUB_Null;
	//if (self.isbot)
	//	PutClientInServer();
	havocbot_relinkbotlist();
};

void() havocbot_new =
{
	local entity oldself;
	oldself = self;
	self = spawnclient();
	if (!self)
	{
		havocbots = havoccurrentbots;
		cvar_set("bots", ftos(havocbots));
		bprint("Can not add bot, server full.\n");
		self = oldself;
		return;
	}
	havoccurrentbots = havoccurrentbots + 1;
	self.netname = havocbot_name();
	self.clientcolors = random() * 16 + random();
	ClientConnect();
	PutClientInServer();
	havocbot_relinkbotlist();
	self = oldself;
};

void() havocbot_removenewest =
{
	local float besttime;
	local entity best, head;
	head = havocbot_list;
	if (!head)
		return;
	best = head;
	besttime = head.createdtime;
	while (head)
	{
		if (besttime < head.createdtime)
		{
			besttime = head.createdtime;
			best = head;
		}
		head = head.nextbot;
	}
	havoccurrentbots = havoccurrentbots - 1;
	dropclient(best);
	havocbot_relinkbotlist();
};

void() havocbot_updatedangerousobjects;

void() havocbot_serverframe =
{
	if (intermission_running)
		return;

	havocbots = cvar("bots");
	if (havocbots < 0)
		havocbots = 0;
	// only add one bot per frame to reduce the chances of a telefrag
	// gib fountain
	if (havoccurrentbots < havocbots)
		havocbot_new();
	while (havoccurrentbots > havocbots)
		havocbot_removenewest();

	if (havocbot_list)
	{
		// cycle the goal token from one bot to the next each frame
		// (this prevents them from all doing waypoint searches on the same
		//  frame, which is too slow)
		if (havocbot_goaltoken)
			havocbot_goaltoken = havocbot_goaltoken.nextbot;
		if (!havocbot_goaltoken)
			havocbot_goaltoken = havocbot_list;

		maxspeed = cvar("sv_maxspeed"); // player movement speed
		sv_accelerate = cvar("sv_accelerate"); // 10 normally

		havocbot_updatedangerousobjects();
	}
};

//.float havocbotignoretime;
void(vector dodge) havocbot_movetogoal =
{
	local vector destorg;
	local vector diff;
	local vector dir;
	local vector flatdir;
	local vector m1;
	local vector m2;
	local vector evadeobstacle;
	local vector evadelava;
	local float s;
	local float dist;
	//if (self.goalentity)
	//	te_lightning2(self, self.origin, (self.goalentity.absmin + self.goalentity.absmax) * 0.5);
	self.movement = '0 0 0';
	if (self.goalcurrent == world)
		return;
	havocbot_popgoals();
	if (self.goalcurrent == world)
		return;
	evadeobstacle = '0 0 0';
	evadelava = '0 0 0';
	m1 = self.goalcurrent.origin + self.goalcurrent.mins;
	m2 = self.goalcurrent.origin + self.goalcurrent.maxs;
	destorg = self.origin;
	destorg_x = bound(m1_x, destorg_x, m2_x);
	destorg_y = bound(m1_y, destorg_y, m2_y);
	destorg_z = bound(m1_z, destorg_z, m2_z);
	diff = destorg - self.origin;
	dist = vlen(diff);
	dir = normalize(diff);
	flatdir = diff;flatdir_z = 0;
	flatdir = normalize(flatdir);
	if (!self.waterlevel)
	{
		if (!(self.flags & FL_ONGROUND))
		{
			// prevent goal checks when we can't walk
			if (self.goaltime < time + 0.1)
				self.goaltime = time + 0.1;
			return;
		}

		// jump if going toward an obstacle that doesn't look like stairs we
		// can walk up directly
		tracebox(self.origin, self.mins, self.maxs, self.origin + self.velocity * 0.2, FALSE, self);
		if (trace_fraction < 1)
		if (trace_plane_normal_z < 0.7)
		{
			s = trace_fraction;
			tracebox(self.origin + '0 0 16', self.mins, self.maxs, self.origin + self.velocity * 0.2 + '0 0 16', FALSE, self);
			if (trace_fraction < s + 0.01)
			if (trace_plane_normal_z < 0.7)
			{
				s = trace_fraction;
				tracebox(self.origin + '0 0 48', self.mins, self.maxs, self.origin + self.velocity * 0.2 + '0 0 48', FALSE, self);
				if (trace_fraction > s)
					self.button2 = 1;
			}
		}

		// LordHavoc: thanks to Electro for noticing that 0.3 velocity multiplier works a lot better than 0.2
		traceline(self.origin + self.velocity * 0.3, self.origin + self.velocity * 0.3 + '0 0 -1000', TRUE, world);
		s = pointcontents(trace_endpos + '0 0 1');
		if (s == CONTENT_LAVA || s == CONTENT_SLIME)
			evadelava = normalize(self.velocity) * -1;

		dir = flatdir;
	}
	dir = normalize(dir + dodge + evadeobstacle + evadelava) * 400;
	makevectors(self.v_angle);
	self.movement_x = dir * v_forward;
	self.movement_y = dir * v_right;
	self.movement_z = dir * v_up;
};

vector() havocbot_dodge =
{
	local entity head;
	local vector dodge, v, n;
	local float danger, bestdanger, vl, d;
	dodge = '0 0 0';
	bestdanger = -20;
	// check for dangerous objects near bot or approaching bot
	head = findchainfloat(shoulddodge, TRUE);
	while(head)
	{
		if (head.owner != self)
		{
			vl = vlen(head.velocity);
			if (vl > maxspeed * 0.3)
			{
				n = normalize(head.velocity);
				v = self.origin - head.origin;
				d = v * n;
				if (d > (0 - head.dangerrating))
				if (d < (vl * 0.2 + head.dangerrating))
				{
					// calculate direction and distance from the flight path, by removing the forward axis
					v = v - (n * (v * n));
					danger = head.dangerrating - vlen(v);
					if (bestdanger < danger)
					{
						bestdanger = danger;
						// dodge to the side of the object
						dodge = normalize(v);
					}
				}
			}
			else
			{
				danger = head.dangerrating - vlen(head.origin - self.origin);
				if (bestdanger < danger)
				{
					bestdanger = danger;
					dodge = normalize(self.origin - head.origin);
				}
			}
		}
		head = head.chain;
	}
	return dodge;
};

.float havocbot_chooseenemy_finished;
void() havocbot_chooseenemy =
{
	local entity head, best;
	local float rating, bestrating;
	if (time < self.havocbot_chooseenemy_finished)
		return;
	self.havocbot_chooseenemy_finished = time + 0.5;
	best = world;
	bestrating = 100000000;
	head = findchainfloat(havocattack, TRUE);
	while (head)
	{
		rating = vlen((head.absmin + head.absmax) * 0.5 - (self.origin + self.view_ofs));
		if (bestrating > rating)
		if (w_canattack(head) > 0)
		{
			traceline(self.origin + self.view_ofs, (head.absmin + head.absmax) * 0.5, FALSE, self);
			if (trace_ent == head || trace_fraction >= 1)
			{
				best = head;
				bestrating = rating;
			}
		}
		head = head.chain;
	}
	self.enemy = best;
};

void() havocbot_chooseweapon =
{
	self.switchweaponclass = W_BestWeaponClass(TRUE);
};

.float nextaim;
void() havocbot_aim =
{
	local vector selfvel, enemyvel;
	local float newping;
	if (time < self.nextaim)
		return;
	self.nextaim = time + 0.1;
	newping = 0.2 + 0.1 * (3 - bound(0, skill, 3));// + random() * 0.05;
	self.ping = self.ping + (newping - self.ping) * frametime * 3;
	selfvel = self.velocity;
	if (!self.waterlevel)
		selfvel_z = 0;
	enemyvel = self.enemy.velocity;
	if (!self.enemy.waterlevel)
		enemyvel_z = 0;
	lag_additem(time + self.ping, 0, 0, self.enemy, self.origin, selfvel, self.enemy.origin, enemyvel);
};

.entity aimtarg;
.float aimlatency;
.vector aimselforigin;
.vector aimselfvelocity;
.vector aimtargorigin;
.vector aimtargvelocity;
void(float t, float f1, float f2, entity e1, vector v1, vector v2, vector v3, vector v4) havocbot_lagfunc =
{
	self.aimtarg = e1;
	self.aimlatency = self.ping; // FIXME?  Shouldn't this be in the lag item?
	self.aimselforigin = v1;
	self.aimselfvelocity = v2;
	self.aimtargorigin = v3;
	self.aimtargvelocity = v4;
};

//.float nextgoalcheck;
.float oldhealth;
void() havocbot_think =
{
	local vector dodge;
	if (!self.havocbot_role)
		objerror("no havocbot_role\n");

	if (self.painintensity > 0)
		self.painintensity = self.painintensity - (skill * 40 + 40) * frametime;

	if (self.health < self.oldhealth)
		self.painintensity = self.painintensity + self.oldhealth - self.health;
	else if (self.health > self.oldhealth)
		self.painintensity = 0;
	self.oldhealth = self.health;

	if (self.fixangle)
	{
		self.v_angle = self.angles;
		self.fixangle = FALSE;
	}

	self.button0 = 0;
	self.button1 = 0;
	self.button2 = 0;
	self.button3 = 0;
	self.button4 = 0;
	self.button5 = 0;
	self.button6 = 0;
	self.button7 = 0;
	self.button8 = 0;
	self.buttonchat = 0;
	self.buttonuse = 0;

	if (self.deadflag)
	{
		if (self.deadflag == DEAD_RESPAWNABLE)
			self.button0 = 1;
		return;
	}
	if (havocbot_goaltoken == self)
		self.havocbot_role();
	if (cvar("havocbot_nofire"))
		self.enemy = world;
	else
		havocbot_chooseenemy();
	havocbot_chooseweapon();
	havocbot_aim();
	lag_update();
	if (self.aimtarg && self.weaponclass)
		self.weaponclass.w_func(WR_AIM);
	else
		w_aimdir(self.goalcurrent.origin - self.origin, -1);
	dodge = havocbot_dodge();
	havocbot_movetogoal(dodge);
};

void() havocbot_impulses =
{
	local float f;
	local string s;
	local entity e;
	if (self.impulse == 101) {f = cvar("bots") + 1;f = max(0, f);s = ftos(f);cvar_set("bots", s);self.impulse = 0;}
	else if (self.impulse == 102) {f = cvar("bots") - 1;f = max(0, f);s = ftos(f);cvar_set("bots", s);self.impulse = 0;}
	if (cvar("havocbot_editwaypoints"))
	{
		if (self.impulse == 103) {waypoint_spawn(self.origin, 0);self.impulse = 0;}
		else if (self.impulse == 104) {e = havocbot_findnearestwaypoint(self.origin);if (e) waypoint_remove(e);self.impulse = 0;}
		else if (self.impulse == 105) {waypoint_relinkall();self.impulse = 0;}
		else if (self.impulse == 106) {waypoint_saveall();self.impulse = 0;}
	}
};

.float nextlaywaypoint;
.entity lastwaypoint;
void() havoc_laywaypoints =
{
	local entity head, w;
	if (!deathmatch)
	if (!coop)
		return;
	if (self.fixangle || self.teleport_time > time || self.pausetime > time)
		self.lastwaypoint = world;
	if (self.isbot)
		return;
	if (!(self.flags & FL_ONGROUND))
		return;
	if (time < self.nextlaywaypoint)
		return;
	self.nextlaywaypoint = time + 0.1; //2 + random() * 0.3;
	if (!cvar("havocbot_editwaypoints"))
		return;
	head = havocbot_findnearestwaypoint(self.origin);
	if (head)
	{
		w = head     ;if (w) te_lightning2(w, w.origin, self.origin);
		w = head.wp00;if (w) te_lightning2(w, w.origin, head.origin);
		w = head.wp01;if (w) te_lightning2(w, w.origin, head.origin);
		w = head.wp02;if (w) te_lightning2(w, w.origin, head.origin);
		w = head.wp03;if (w) te_lightning2(w, w.origin, head.origin);
		w = head.wp04;if (w) te_lightning2(w, w.origin, head.origin);
		w = head.wp05;if (w) te_lightning2(w, w.origin, head.origin);
		w = head.wp06;if (w) te_lightning2(w, w.origin, head.origin);
		w = head.wp07;if (w) te_lightning2(w, w.origin, head.origin);
		w = head.wp08;if (w) te_lightning2(w, w.origin, head.origin);
		w = head.wp09;if (w) te_lightning2(w, w.origin, head.origin);
		w = head.wp10;if (w) te_lightning2(w, w.origin, head.origin);
		w = head.wp11;if (w) te_lightning2(w, w.origin, head.origin);
		w = head.wp12;if (w) te_lightning2(w, w.origin, head.origin);
		w = head.wp13;if (w) te_lightning2(w, w.origin, head.origin);
		w = head.wp14;if (w) te_lightning2(w, w.origin, head.origin);
		w = head.wp15;if (w) te_lightning2(w, w.origin, head.origin);
		w = head.wp16;if (w) te_lightning2(w, w.origin, head.origin);
		w = head.wp17;if (w) te_lightning2(w, w.origin, head.origin);
		w = head.wp18;if (w) te_lightning2(w, w.origin, head.origin);
		w = head.wp19;if (w) te_lightning2(w, w.origin, head.origin);
		w = head.wp20;if (w) te_lightning2(w, w.origin, head.origin);
		w = head.wp21;if (w) te_lightning2(w, w.origin, head.origin);
		w = head.wp22;if (w) te_lightning2(w, w.origin, head.origin);
		w = head.wp23;if (w) te_lightning2(w, w.origin, head.origin);
		w = head.wp24;if (w) te_lightning2(w, w.origin, head.origin);
		w = head.wp25;if (w) te_lightning2(w, w.origin, head.origin);
		w = head.wp26;if (w) te_lightning2(w, w.origin, head.origin);
		w = head.wp27;if (w) te_lightning2(w, w.origin, head.origin);
		w = head.wp28;if (w) te_lightning2(w, w.origin, head.origin);
		w = head.wp29;if (w) te_lightning2(w, w.origin, head.origin);
		w = head.wp30;if (w) te_lightning2(w, w.origin, head.origin);
		w = head.wp31;if (w) te_lightning2(w, w.origin, head.origin);
	}
};

entity dangerwaypoint;
void() havocbot_updatedangerousobjects =
{
	local entity head, shoulddodgelist;
	local vector m1, m2, v;
	local float c, d, danger;
	c = 0;
	shoulddodgelist = findchainfloat(shoulddodge, TRUE);
	dangerwaypoint = find(dangerwaypoint, classname, "waypoint");
	while (dangerwaypoint != world && c < 256)
	{
		c = c + 1;
		danger = 0;
		m1 = dangerwaypoint.mins;
		m2 = dangerwaypoint.maxs;
		head = shoulddodgelist;
		while (head)
		{
			v = head.origin;
			v_x = bound(m1_x, v_x, m2_x);
			v_y = bound(m1_y, v_y, m2_y);
			v_z = bound(m1_z, v_z, m2_z);
			d = head.dangerrating - vlen(head.origin - v);
			if (d > 0)
			{
				traceline(head.origin, v, TRUE, world);
				if (trace_fraction == 1)
					danger = danger + d;
			}
			head = head.chain;
		}
		dangerwaypoint.dmg = danger;
		dangerwaypoint = find(dangerwaypoint, classname, "waypoint");
	}
};
