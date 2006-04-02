
// itemscore = (howmuchmoreIwant / howmuchIcanwant) / itemdistance
// waypointscore = 0.7 / waypointdistance

float(entity e, vector start, vector m1, vector m2, vector end) tracewalk;
float(vector m1, vector m2, vector m3, vector m4) boxesoverlap =
{
	return m2_x >= m3_x && m1_x <= m4_x && m2_y >= m3_y && m1_y <= m4_y && m2_z >= m3_z && m1_z <= m4_z;
};

.entity wp0, wp1, wp2, wp3, wp4, wp5, wp6, wp7, wp8, wp9, wp10, wp11, wp12, wp13, wp14, wp15, wp16, wp17, wp18, wp19, wp20, wp21, wp22, wp23, wp24, wp25, wp26, wp27, wp28, wp29, wp30, wp31;
.float wpfire, wpcost;

.entity goalcurrent, goalstack1, goalstack2, goalstack3, goalstack4, goalstack5, goalstack6, goalstack7, goalstack8, goalstack9;
.entity goalstack10, goalstack11, goalstack12, goalstack13, goalstack14, goalstack15, goalstack16, goalstack17, goalstack18, goalstack19;
.entity goalstack20, goalstack21, goalstack22, goalstack23, goalstack24, goalstack25, goalstack26, goalstack27, goalstack28, goalstack29;
.entity goalstack30, goalstack31, goalstack32;


float(entity from, entity to) waypoint_addlink =
{
	if (from == to)
		return FALSE;
	if (from.wp0 == world) {from.wp0 = to;return TRUE;}if (from.wp0 == to) return FALSE;
	if (from.wp1 == world) {from.wp1 = to;return TRUE;}if (from.wp1 == to) return FALSE;
	if (from.wp2 == world) {from.wp2 = to;return TRUE;}if (from.wp2 == to) return FALSE;
	if (from.wp3 == world) {from.wp3 = to;return TRUE;}if (from.wp3 == to) return FALSE;
	if (from.wp4 == world) {from.wp4 = to;return TRUE;}if (from.wp4 == to) return FALSE;
	if (from.wp5 == world) {from.wp5 = to;return TRUE;}if (from.wp5 == to) return FALSE;
	if (from.wp6 == world) {from.wp6 = to;return TRUE;}if (from.wp6 == to) return FALSE;
	if (from.wp7 == world) {from.wp7 = to;return TRUE;}if (from.wp7 == to) return FALSE;
	if (from.wp8 == world) {from.wp8 = to;return TRUE;}if (from.wp8 == to) return FALSE;
	if (from.wp9 == world) {from.wp9 = to;return TRUE;}if (from.wp9 == to) return FALSE;
	if (from.wp10 == world) {from.wp10 = to;return TRUE;}if (from.wp10 == to) return FALSE;
	if (from.wp11 == world) {from.wp11 = to;return TRUE;}if (from.wp11 == to) return FALSE;
	if (from.wp12 == world) {from.wp12 = to;return TRUE;}if (from.wp12 == to) return FALSE;
	if (from.wp13 == world) {from.wp13 = to;return TRUE;}if (from.wp13 == to) return FALSE;
	if (from.wp14 == world) {from.wp14 = to;return TRUE;}if (from.wp14 == to) return FALSE;
	if (from.wp15 == world) {from.wp15 = to;return TRUE;}if (from.wp15 == to) return FALSE;
	if (from.wp16 == world) {from.wp16 = to;return TRUE;}if (from.wp16 == to) return FALSE;
	if (from.wp17 == world) {from.wp17 = to;return TRUE;}if (from.wp17 == to) return FALSE;
	if (from.wp18 == world) {from.wp18 = to;return TRUE;}if (from.wp18 == to) return FALSE;
	if (from.wp19 == world) {from.wp19 = to;return TRUE;}if (from.wp19 == to) return FALSE;
	if (from.wp20 == world) {from.wp20 = to;return TRUE;}if (from.wp20 == to) return FALSE;
	if (from.wp21 == world) {from.wp21 = to;return TRUE;}if (from.wp21 == to) return FALSE;
	if (from.wp22 == world) {from.wp22 = to;return TRUE;}if (from.wp22 == to) return FALSE;
	if (from.wp23 == world) {from.wp23 = to;return TRUE;}if (from.wp23 == to) return FALSE;
	if (from.wp24 == world) {from.wp24 = to;return TRUE;}if (from.wp24 == to) return FALSE;
	if (from.wp25 == world) {from.wp25 = to;return TRUE;}if (from.wp25 == to) return FALSE;
	if (from.wp26 == world) {from.wp26 = to;return TRUE;}if (from.wp26 == to) return FALSE;
	if (from.wp27 == world) {from.wp27 = to;return TRUE;}if (from.wp27 == to) return FALSE;
	if (from.wp28 == world) {from.wp28 = to;return TRUE;}if (from.wp28 == to) return FALSE;
	if (from.wp29 == world) {from.wp29 = to;return TRUE;}if (from.wp29 == to) return FALSE;
	if (from.wp30 == world) {from.wp30 = to;return TRUE;}if (from.wp30 == to) return FALSE;
	if (from.wp31 == world) {from.wp31 = to;return TRUE;}if (from.wp31 == to) return FALSE;
	return FALSE;
};

float(entity from, entity to) waypoint_removelink =
{
	if (from == to)
		return FALSE;
	if (from.wp0 == to){from.wp0 = from.wp1;from.wp1 = from.wp2;from.wp2 = from.wp3;from.wp3 = from.wp4;from.wp4 = from.wp5;from.wp5 = from.wp6;from.wp6 = from.wp7;from.wp7 = from.wp8;from.wp8 = from.wp9;from.wp9 = from.wp10;from.wp10 = from.wp11;from.wp11 = from.wp12;from.wp12 = from.wp13;from.wp13 = from.wp14;from.wp14 = from.wp15;from.wp15 = from.wp16;from.wp16 = from.wp17;from.wp17 = from.wp18;from.wp18 = from.wp19;from.wp19 = from.wp20;from.wp20 = from.wp21;from.wp21 = from.wp22;from.wp22 = from.wp23;from.wp23 = from.wp24;from.wp24 = from.wp25;from.wp25 = from.wp26;from.wp26 = from.wp27;from.wp27 = from.wp28;from.wp28 = from.wp29;from.wp29 = from.wp30;from.wp30 = from.wp31;from.wp31 = world;return TRUE;}
	if (from.wp1 == to){from.wp1 = from.wp2;from.wp2 = from.wp3;from.wp3 = from.wp4;from.wp4 = from.wp5;from.wp5 = from.wp6;from.wp6 = from.wp7;from.wp7 = from.wp8;from.wp8 = from.wp9;from.wp9 = from.wp10;from.wp10 = from.wp11;from.wp11 = from.wp12;from.wp12 = from.wp13;from.wp13 = from.wp14;from.wp14 = from.wp15;from.wp15 = from.wp16;from.wp16 = from.wp17;from.wp17 = from.wp18;from.wp18 = from.wp19;from.wp19 = from.wp20;from.wp20 = from.wp21;from.wp21 = from.wp22;from.wp22 = from.wp23;from.wp23 = from.wp24;from.wp24 = from.wp25;from.wp25 = from.wp26;from.wp26 = from.wp27;from.wp27 = from.wp28;from.wp28 = from.wp29;from.wp29 = from.wp30;from.wp30 = from.wp31;from.wp31 = world;return TRUE;}
	if (from.wp2 == to){from.wp2 = from.wp3;from.wp3 = from.wp4;from.wp4 = from.wp5;from.wp5 = from.wp6;from.wp6 = from.wp7;from.wp7 = from.wp8;from.wp8 = from.wp9;from.wp9 = from.wp10;from.wp10 = from.wp11;from.wp11 = from.wp12;from.wp12 = from.wp13;from.wp13 = from.wp14;from.wp14 = from.wp15;from.wp15 = from.wp16;from.wp16 = from.wp17;from.wp17 = from.wp18;from.wp18 = from.wp19;from.wp19 = from.wp20;from.wp20 = from.wp21;from.wp21 = from.wp22;from.wp22 = from.wp23;from.wp23 = from.wp24;from.wp24 = from.wp25;from.wp25 = from.wp26;from.wp26 = from.wp27;from.wp27 = from.wp28;from.wp28 = from.wp29;from.wp29 = from.wp30;from.wp30 = from.wp31;from.wp31 = world;return TRUE;}
	if (from.wp3 == to){from.wp3 = from.wp4;from.wp4 = from.wp5;from.wp5 = from.wp6;from.wp6 = from.wp7;from.wp7 = from.wp8;from.wp8 = from.wp9;from.wp9 = from.wp10;from.wp10 = from.wp11;from.wp11 = from.wp12;from.wp12 = from.wp13;from.wp13 = from.wp14;from.wp14 = from.wp15;from.wp15 = from.wp16;from.wp16 = from.wp17;from.wp17 = from.wp18;from.wp18 = from.wp19;from.wp19 = from.wp20;from.wp20 = from.wp21;from.wp21 = from.wp22;from.wp22 = from.wp23;from.wp23 = from.wp24;from.wp24 = from.wp25;from.wp25 = from.wp26;from.wp26 = from.wp27;from.wp27 = from.wp28;from.wp28 = from.wp29;from.wp29 = from.wp30;from.wp30 = from.wp31;from.wp31 = world;return TRUE;}
	if (from.wp4 == to){from.wp4 = from.wp5;from.wp5 = from.wp6;from.wp6 = from.wp7;from.wp7 = from.wp8;from.wp8 = from.wp9;from.wp9 = from.wp10;from.wp10 = from.wp11;from.wp11 = from.wp12;from.wp12 = from.wp13;from.wp13 = from.wp14;from.wp14 = from.wp15;from.wp15 = from.wp16;from.wp16 = from.wp17;from.wp17 = from.wp18;from.wp18 = from.wp19;from.wp19 = from.wp20;from.wp20 = from.wp21;from.wp21 = from.wp22;from.wp22 = from.wp23;from.wp23 = from.wp24;from.wp24 = from.wp25;from.wp25 = from.wp26;from.wp26 = from.wp27;from.wp27 = from.wp28;from.wp28 = from.wp29;from.wp29 = from.wp30;from.wp30 = from.wp31;from.wp31 = world;return TRUE;}
	if (from.wp5 == to){from.wp5 = from.wp6;from.wp6 = from.wp7;from.wp7 = from.wp8;from.wp8 = from.wp9;from.wp9 = from.wp10;from.wp10 = from.wp11;from.wp11 = from.wp12;from.wp12 = from.wp13;from.wp13 = from.wp14;from.wp14 = from.wp15;from.wp15 = from.wp16;from.wp16 = from.wp17;from.wp17 = from.wp18;from.wp18 = from.wp19;from.wp19 = from.wp20;from.wp20 = from.wp21;from.wp21 = from.wp22;from.wp22 = from.wp23;from.wp23 = from.wp24;from.wp24 = from.wp25;from.wp25 = from.wp26;from.wp26 = from.wp27;from.wp27 = from.wp28;from.wp28 = from.wp29;from.wp29 = from.wp30;from.wp30 = from.wp31;from.wp31 = world;return TRUE;}
	if (from.wp6 == to){from.wp6 = from.wp7;from.wp7 = from.wp8;from.wp8 = from.wp9;from.wp9 = from.wp10;from.wp10 = from.wp11;from.wp11 = from.wp12;from.wp12 = from.wp13;from.wp13 = from.wp14;from.wp14 = from.wp15;from.wp15 = from.wp16;from.wp16 = from.wp17;from.wp17 = from.wp18;from.wp18 = from.wp19;from.wp19 = from.wp20;from.wp20 = from.wp21;from.wp21 = from.wp22;from.wp22 = from.wp23;from.wp23 = from.wp24;from.wp24 = from.wp25;from.wp25 = from.wp26;from.wp26 = from.wp27;from.wp27 = from.wp28;from.wp28 = from.wp29;from.wp29 = from.wp30;from.wp30 = from.wp31;from.wp31 = world;return TRUE;}
	if (from.wp7 == to){from.wp7 = from.wp8;from.wp8 = from.wp9;from.wp9 = from.wp10;from.wp10 = from.wp11;from.wp11 = from.wp12;from.wp12 = from.wp13;from.wp13 = from.wp14;from.wp14 = from.wp15;from.wp15 = from.wp16;from.wp16 = from.wp17;from.wp17 = from.wp18;from.wp18 = from.wp19;from.wp19 = from.wp20;from.wp20 = from.wp21;from.wp21 = from.wp22;from.wp22 = from.wp23;from.wp23 = from.wp24;from.wp24 = from.wp25;from.wp25 = from.wp26;from.wp26 = from.wp27;from.wp27 = from.wp28;from.wp28 = from.wp29;from.wp29 = from.wp30;from.wp30 = from.wp31;from.wp31 = world;return TRUE;}
	if (from.wp8 == to){from.wp8 = from.wp9;from.wp9 = from.wp10;from.wp10 = from.wp11;from.wp11 = from.wp12;from.wp12 = from.wp13;from.wp13 = from.wp14;from.wp14 = from.wp15;from.wp15 = from.wp16;from.wp16 = from.wp17;from.wp17 = from.wp18;from.wp18 = from.wp19;from.wp19 = from.wp20;from.wp20 = from.wp21;from.wp21 = from.wp22;from.wp22 = from.wp23;from.wp23 = from.wp24;from.wp24 = from.wp25;from.wp25 = from.wp26;from.wp26 = from.wp27;from.wp27 = from.wp28;from.wp28 = from.wp29;from.wp29 = from.wp30;from.wp30 = from.wp31;from.wp31 = world;return TRUE;}
	if (from.wp9 == to){from.wp9 = from.wp10;from.wp10 = from.wp11;from.wp11 = from.wp12;from.wp12 = from.wp13;from.wp13 = from.wp14;from.wp14 = from.wp15;from.wp15 = from.wp16;from.wp16 = from.wp17;from.wp17 = from.wp18;from.wp18 = from.wp19;from.wp19 = from.wp20;from.wp20 = from.wp21;from.wp21 = from.wp22;from.wp22 = from.wp23;from.wp23 = from.wp24;from.wp24 = from.wp25;from.wp25 = from.wp26;from.wp26 = from.wp27;from.wp27 = from.wp28;from.wp28 = from.wp29;from.wp29 = from.wp30;from.wp30 = from.wp31;from.wp31 = world;return TRUE;}
	if (from.wp10 == to){from.wp10 = from.wp11;from.wp11 = from.wp12;from.wp12 = from.wp13;from.wp13 = from.wp14;from.wp14 = from.wp15;from.wp15 = from.wp16;from.wp16 = from.wp17;from.wp17 = from.wp18;from.wp18 = from.wp19;from.wp19 = from.wp20;from.wp20 = from.wp21;from.wp21 = from.wp22;from.wp22 = from.wp23;from.wp23 = from.wp24;from.wp24 = from.wp25;from.wp25 = from.wp26;from.wp26 = from.wp27;from.wp27 = from.wp28;from.wp28 = from.wp29;from.wp29 = from.wp30;from.wp30 = from.wp31;from.wp31 = world;return TRUE;}
	if (from.wp11 == to){from.wp11 = from.wp12;from.wp12 = from.wp13;from.wp13 = from.wp14;from.wp14 = from.wp15;from.wp15 = from.wp16;from.wp16 = from.wp17;from.wp17 = from.wp18;from.wp18 = from.wp19;from.wp19 = from.wp20;from.wp20 = from.wp21;from.wp21 = from.wp22;from.wp22 = from.wp23;from.wp23 = from.wp24;from.wp24 = from.wp25;from.wp25 = from.wp26;from.wp26 = from.wp27;from.wp27 = from.wp28;from.wp28 = from.wp29;from.wp29 = from.wp30;from.wp30 = from.wp31;from.wp31 = world;return TRUE;}
	if (from.wp12 == to){from.wp12 = from.wp13;from.wp13 = from.wp14;from.wp14 = from.wp15;from.wp15 = from.wp16;from.wp16 = from.wp17;from.wp17 = from.wp18;from.wp18 = from.wp19;from.wp19 = from.wp20;from.wp20 = from.wp21;from.wp21 = from.wp22;from.wp22 = from.wp23;from.wp23 = from.wp24;from.wp24 = from.wp25;from.wp25 = from.wp26;from.wp26 = from.wp27;from.wp27 = from.wp28;from.wp28 = from.wp29;from.wp29 = from.wp30;from.wp30 = from.wp31;from.wp31 = world;return TRUE;}
	if (from.wp13 == to){from.wp13 = from.wp14;from.wp14 = from.wp15;from.wp15 = from.wp16;from.wp16 = from.wp17;from.wp17 = from.wp18;from.wp18 = from.wp19;from.wp19 = from.wp20;from.wp20 = from.wp21;from.wp21 = from.wp22;from.wp22 = from.wp23;from.wp23 = from.wp24;from.wp24 = from.wp25;from.wp25 = from.wp26;from.wp26 = from.wp27;from.wp27 = from.wp28;from.wp28 = from.wp29;from.wp29 = from.wp30;from.wp30 = from.wp31;from.wp31 = world;return TRUE;}
	if (from.wp14 == to){from.wp14 = from.wp15;from.wp15 = from.wp16;from.wp16 = from.wp17;from.wp17 = from.wp18;from.wp18 = from.wp19;from.wp19 = from.wp20;from.wp20 = from.wp21;from.wp21 = from.wp22;from.wp22 = from.wp23;from.wp23 = from.wp24;from.wp24 = from.wp25;from.wp25 = from.wp26;from.wp26 = from.wp27;from.wp27 = from.wp28;from.wp28 = from.wp29;from.wp29 = from.wp30;from.wp30 = from.wp31;from.wp31 = world;return TRUE;}
	if (from.wp15 == to){from.wp15 = from.wp16;from.wp16 = from.wp17;from.wp17 = from.wp18;from.wp18 = from.wp19;from.wp19 = from.wp20;from.wp20 = from.wp21;from.wp21 = from.wp22;from.wp22 = from.wp23;from.wp23 = from.wp24;from.wp24 = from.wp25;from.wp25 = from.wp26;from.wp26 = from.wp27;from.wp27 = from.wp28;from.wp28 = from.wp29;from.wp29 = from.wp30;from.wp30 = from.wp31;from.wp31 = world;return TRUE;}
	if (from.wp16 == to){from.wp16 = from.wp17;from.wp17 = from.wp18;from.wp18 = from.wp19;from.wp19 = from.wp20;from.wp20 = from.wp21;from.wp21 = from.wp22;from.wp22 = from.wp23;from.wp23 = from.wp24;from.wp24 = from.wp25;from.wp25 = from.wp26;from.wp26 = from.wp27;from.wp27 = from.wp28;from.wp28 = from.wp29;from.wp29 = from.wp30;from.wp30 = from.wp31;from.wp31 = world;return TRUE;}
	if (from.wp17 == to){from.wp17 = from.wp18;from.wp18 = from.wp19;from.wp19 = from.wp20;from.wp20 = from.wp21;from.wp21 = from.wp22;from.wp22 = from.wp23;from.wp23 = from.wp24;from.wp24 = from.wp25;from.wp25 = from.wp26;from.wp26 = from.wp27;from.wp27 = from.wp28;from.wp28 = from.wp29;from.wp29 = from.wp30;from.wp30 = from.wp31;from.wp31 = world;return TRUE;}
	if (from.wp18 == to){from.wp18 = from.wp19;from.wp19 = from.wp20;from.wp20 = from.wp21;from.wp21 = from.wp22;from.wp22 = from.wp23;from.wp23 = from.wp24;from.wp24 = from.wp25;from.wp25 = from.wp26;from.wp26 = from.wp27;from.wp27 = from.wp28;from.wp28 = from.wp29;from.wp29 = from.wp30;from.wp30 = from.wp31;from.wp31 = world;return TRUE;}
	if (from.wp19 == to){from.wp19 = from.wp20;from.wp20 = from.wp21;from.wp21 = from.wp22;from.wp22 = from.wp23;from.wp23 = from.wp24;from.wp24 = from.wp25;from.wp25 = from.wp26;from.wp26 = from.wp27;from.wp27 = from.wp28;from.wp28 = from.wp29;from.wp29 = from.wp30;from.wp30 = from.wp31;from.wp31 = world;return TRUE;}
	if (from.wp20 == to){from.wp20 = from.wp21;from.wp21 = from.wp22;from.wp22 = from.wp23;from.wp23 = from.wp24;from.wp24 = from.wp25;from.wp25 = from.wp26;from.wp26 = from.wp27;from.wp27 = from.wp28;from.wp28 = from.wp29;from.wp29 = from.wp30;from.wp30 = from.wp31;from.wp31 = world;return TRUE;}
	if (from.wp21 == to){from.wp21 = from.wp22;from.wp22 = from.wp23;from.wp23 = from.wp24;from.wp24 = from.wp25;from.wp25 = from.wp26;from.wp26 = from.wp27;from.wp27 = from.wp28;from.wp28 = from.wp29;from.wp29 = from.wp30;from.wp30 = from.wp31;from.wp31 = world;return TRUE;}
	if (from.wp22 == to){from.wp22 = from.wp23;from.wp23 = from.wp24;from.wp24 = from.wp25;from.wp25 = from.wp26;from.wp26 = from.wp27;from.wp27 = from.wp28;from.wp28 = from.wp29;from.wp29 = from.wp30;from.wp30 = from.wp31;from.wp31 = world;return TRUE;}
	if (from.wp23 == to){from.wp23 = from.wp24;from.wp24 = from.wp25;from.wp25 = from.wp26;from.wp26 = from.wp27;from.wp27 = from.wp28;from.wp28 = from.wp29;from.wp29 = from.wp30;from.wp30 = from.wp31;from.wp31 = world;return TRUE;}
	if (from.wp24 == to){from.wp24 = from.wp25;from.wp25 = from.wp26;from.wp26 = from.wp27;from.wp27 = from.wp28;from.wp28 = from.wp29;from.wp29 = from.wp30;from.wp30 = from.wp31;from.wp31 = world;return TRUE;}
	if (from.wp25 == to){from.wp25 = from.wp26;from.wp26 = from.wp27;from.wp27 = from.wp28;from.wp28 = from.wp29;from.wp29 = from.wp30;from.wp30 = from.wp31;from.wp31 = world;return TRUE;}
	if (from.wp26 == to){from.wp26 = from.wp27;from.wp27 = from.wp28;from.wp28 = from.wp29;from.wp29 = from.wp30;from.wp30 = from.wp31;from.wp31 = world;return TRUE;}
	if (from.wp27 == to){from.wp27 = from.wp28;from.wp28 = from.wp29;from.wp29 = from.wp30;from.wp30 = from.wp31;from.wp31 = world;return TRUE;}
	if (from.wp28 == to){from.wp28 = from.wp29;from.wp29 = from.wp30;from.wp30 = from.wp31;from.wp31 = world;return TRUE;}
	if (from.wp29 == to){from.wp29 = from.wp30;from.wp30 = from.wp31;from.wp31 = world;return TRUE;}
	if (from.wp30 == to){from.wp30 = from.wp31;from.wp31 = world;return TRUE;}
	if (from.wp31 == to){from.wp31 = world;return TRUE;}
	return FALSE;
};

void() waypoint_think =
{
	local entity e;
	local vector v;
	if (vlen(self.size) > 1)
	{
		// box
		e = findchain(classname, "waypoint");
		while (e)
		{
			if (boxesoverlap(self.absmin, self.absmax, e.absmin, e.absmax))
			{
				waypoint_addlink(self, e);
				waypoint_addlink(e, self);
			}
			e = e.chain;
		}
	}
	else
	{
		// point
		e = findchain(classname, "waypoint");
		while (e)
		{
			v = self.origin;
			v_x = bound(e.absmin_x, v_x, e.absmax_x);
			v_y = bound(e.absmin_y, v_y, e.absmax_y);
			v_z = bound(e.absmin_z, v_z, e.absmax_z);
			if (vlen(v - self.origin) < 1000)
			{
				//traceline(self.origin, e.origin, FALSE, world);
				//if (trace_fraction == 1)
				if (tracewalk(self, self.origin, '-16 -16 -24', '16 16 24', v))
					waypoint_addlink(self, e);
				if (tracewalk(self, v, '-16 -16 -24', '16 16 24', self.origin))
					waypoint_addlink(e, self);
			}
			e = e.chain;
		}
	}
};

void(vector o, float f) waypoint_spawn =
{
	newmis = spawn();
	newmis.classname = "waypoint";
	newmis.think = waypoint_think;
	newmis.lefty = f;
	newmis.nextthink = time + 0.2;
	newmis.cnt = time + 1;
	setorigin(newmis, o);
	// TODO: add some sort of visible box in edit mode for box waypoints
	if (cvar("havocbot_editwaypoints"))
		setmodel(newmis, "progs/s_bubble.spr");
	setsize(newmis, '0 0 0', '0 0 0');
	//setsize(newmis, -16 -16 -24', '16 16 24');
};

void(entity e) waypoint_remove =
{
	if (e.wp0) waypoint_removelink(e.wp0, e);
	if (e.wp1) waypoint_removelink(e.wp1, e);
	if (e.wp2) waypoint_removelink(e.wp2, e);
	if (e.wp3) waypoint_removelink(e.wp3, e);
	if (e.wp4) waypoint_removelink(e.wp4, e);
	if (e.wp5) waypoint_removelink(e.wp5, e);
	if (e.wp6) waypoint_removelink(e.wp6, e);
	if (e.wp7) waypoint_removelink(e.wp7, e);
	if (e.wp8) waypoint_removelink(e.wp8, e);
	if (e.wp9) waypoint_removelink(e.wp9, e);
	if (e.wp10) waypoint_removelink(e.wp10, e);
	if (e.wp11) waypoint_removelink(e.wp11, e);
	if (e.wp12) waypoint_removelink(e.wp12, e);
	if (e.wp13) waypoint_removelink(e.wp13, e);
	if (e.wp14) waypoint_removelink(e.wp14, e);
	if (e.wp15) waypoint_removelink(e.wp15, e);
	if (e.wp16) waypoint_removelink(e.wp16, e);
	if (e.wp17) waypoint_removelink(e.wp17, e);
	if (e.wp18) waypoint_removelink(e.wp18, e);
	if (e.wp19) waypoint_removelink(e.wp19, e);
	if (e.wp20) waypoint_removelink(e.wp20, e);
	if (e.wp21) waypoint_removelink(e.wp21, e);
	if (e.wp22) waypoint_removelink(e.wp22, e);
	if (e.wp23) waypoint_removelink(e.wp23, e);
	if (e.wp24) waypoint_removelink(e.wp24, e);
	if (e.wp25) waypoint_removelink(e.wp25, e);
	if (e.wp26) waypoint_removelink(e.wp26, e);
	if (e.wp27) waypoint_removelink(e.wp27, e);
	if (e.wp28) waypoint_removelink(e.wp28, e);
	if (e.wp29) waypoint_removelink(e.wp29, e);
	if (e.wp30) waypoint_removelink(e.wp30, e);
	if (e.wp31) waypoint_removelink(e.wp31, e);
	remove(e);
};

void() waypoint_relinkall =
{
	local entity head;
	head = findchain(classname, "waypoint");
	while (head)
	{
		head.enemy = world;
		head.owner = world;
		head.wp0 = head.wp1 = head.wp2 = head.wp3 = head.wp4 = head.wp5 = head.wp6 = head.wp7 = world;
		head.wp8 = head.wp9 = head.wp10 = head.wp11 = head.wp12 = head.wp13 = head.wp14 = head.wp15 = world;
		head.wp16 = head.wp17 = head.wp18 = head.wp19 = head.wp20 = head.wp21 = head.wp22 = head.wp23 = world;
		head.wp24 = head.wp25 = head.wp26 = head.wp27 = head.wp28 = head.wp29 = head.wp30 = head.wp31 = world;
		head.think = waypoint_think;
		head.nextthink = time + 0.1;
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
		bprint("loaded ");
		bprint(ftos(c));
		bprint(" waypoints from waypoints/");
		bprint(mapname);
		bprint(".waypoints\n");
	}
	else
	{
		bprint("waypoint load from ");
		bprint(filename);
		bprint(" failed\n");
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
	self.goalstack1 = world;
	self.goalstack2 = world;
	self.goalstack3 = world;
	self.goalstack4 = world;
	self.goalstack5 = world;
	self.goalstack6 = world;
	self.goalstack7 = world;
	self.goalstack8 = world;
	self.goalstack9 = world;
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
	self.goalstack10 = self.goalstack9;
	self.goalstack9 = self.goalstack8;
	self.goalstack8 = self.goalstack7;
	self.goalstack7 = self.goalstack6;
	self.goalstack6 = self.goalstack5;
	self.goalstack5 = self.goalstack4;
	self.goalstack4 = self.goalstack3;
	self.goalstack3 = self.goalstack2;
	self.goalstack2 = self.goalstack1;
	self.goalstack1 = self.goalcurrent;
	self.goalcurrent = e;
};

void() havocbot_poproute =
{
	self.goalcurrent = self.goalstack1;
	self.goalstack1 = self.goalstack2;
	self.goalstack2 = self.goalstack3;
	self.goalstack3 = self.goalstack4;
	self.goalstack4 = self.goalstack5;
	self.goalstack5 = self.goalstack6;
	self.goalstack6 = self.goalstack7;
	self.goalstack7 = self.goalstack8;
	self.goalstack8 = self.goalstack9;
	self.goalstack9 = self.goalstack10;
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
	local vector v;
	head = findchain(classname, "waypoint");
	while (head)
	{
		v = self.origin;
		v_x = bound(head.absmin_x, v_x, head.absmax_x);
		v_y = bound(head.absmin_y, v_y, head.absmax_y);
		v_z = bound(head.absmin_z, v_z, head.absmax_z);
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

float(entity head, entity w) havocbot_markroutes_checkwaypoint =
{
	local vector o;
	local float cost;
	if(!w)
		return FALSE;
	cost = head.wpcost + head.dmg;
	if (w.wpcost > cost)
	{
		o_x = bound(w.absmin_x, head.dest_x, w.absmax_x);
		o_y = bound(w.absmin_y, head.dest_y, w.absmax_y);
		o_z = bound(w.absmin_z, head.dest_z, w.absmax_z);
		cost = cost + head.dmg + vlen(o - head.dest);
		if (w.wpcost > cost)
		{
			w.dest = o;
			w.wpcost = cost;
			w.enemy = head;
			w.wpfire = 1;
		}
	}
	return TRUE;
}

void() havocbot_markroutes =
{
	local entity w, waylist;
	local float searching;
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
				if (havocbot_markroutes_checkwaypoint(w, w.wp0))
				if (havocbot_markroutes_checkwaypoint(w, w.wp1))
				if (havocbot_markroutes_checkwaypoint(w, w.wp2))
				if (havocbot_markroutes_checkwaypoint(w, w.wp3))
				if (havocbot_markroutes_checkwaypoint(w, w.wp4))
				if (havocbot_markroutes_checkwaypoint(w, w.wp5))
				if (havocbot_markroutes_checkwaypoint(w, w.wp6))
				if (havocbot_markroutes_checkwaypoint(w, w.wp7))
				if (havocbot_markroutes_checkwaypoint(w, w.wp8))
				if (havocbot_markroutes_checkwaypoint(w, w.wp9))
				if (havocbot_markroutes_checkwaypoint(w, w.wp10))
				if (havocbot_markroutes_checkwaypoint(w, w.wp11))
				if (havocbot_markroutes_checkwaypoint(w, w.wp12))
				if (havocbot_markroutes_checkwaypoint(w, w.wp13))
				if (havocbot_markroutes_checkwaypoint(w, w.wp14))
				if (havocbot_markroutes_checkwaypoint(w, w.wp15))
				if (havocbot_markroutes_checkwaypoint(w, w.wp16))
				if (havocbot_markroutes_checkwaypoint(w, w.wp17))
				if (havocbot_markroutes_checkwaypoint(w, w.wp18))
				if (havocbot_markroutes_checkwaypoint(w, w.wp19))
				if (havocbot_markroutes_checkwaypoint(w, w.wp20))
				if (havocbot_markroutes_checkwaypoint(w, w.wp21))
				if (havocbot_markroutes_checkwaypoint(w, w.wp22))
				if (havocbot_markroutes_checkwaypoint(w, w.wp23))
				if (havocbot_markroutes_checkwaypoint(w, w.wp24))
				if (havocbot_markroutes_checkwaypoint(w, w.wp25))
				if (havocbot_markroutes_checkwaypoint(w, w.wp26))
				if (havocbot_markroutes_checkwaypoint(w, w.wp27))
				if (havocbot_markroutes_checkwaypoint(w, w.wp28))
				if (havocbot_markroutes_checkwaypoint(w, w.wp29))
				if (havocbot_markroutes_checkwaypoint(w, w.wp30))
					havocbot_markroutes_checkwaypoint(w, w.wp31);
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

void() havocbot_think;
void() havocbot_updatedangerousobjects;

void() havocbot_serverframe =
{
	if (intermission_running)
		return;

	havocbots = cvar("bots");
	if (havocbots < 0)
		havocbots = 0;
	while (havoccurrentbots < havocbots)
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

void() havocbot_chooseenemy =
{
	local entity head, best;
	local float rating, bestrating;
	best = world;
	bestrating = 100000000;
	head = findchainfloat(havocattack, TRUE);
	while (head)
	{
		rating = vlen((head.absmin + head.absmax) * 0.5 - (self.origin + self.view_ofs));
		if (bestrating > rating)
		if (w_shouldattack(head))
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
		w_aimdir(self.goalcurrent.origin - self.origin, 0);
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
		w = head;if (w) te_lightning2(w, w.origin, self.origin);
		w = head.wp0;if (w) te_lightning2(w, w.origin, head.origin);
		w = head.wp1;if (w) te_lightning2(w, w.origin, head.origin);
		w = head.wp2;if (w) te_lightning2(w, w.origin, head.origin);
		w = head.wp3;if (w) te_lightning2(w, w.origin, head.origin);
		w = head.wp4;if (w) te_lightning2(w, w.origin, head.origin);
		w = head.wp5;if (w) te_lightning2(w, w.origin, head.origin);
		w = head.wp6;if (w) te_lightning2(w, w.origin, head.origin);
		w = head.wp7;if (w) te_lightning2(w, w.origin, head.origin);
		w = head.wp8;if (w) te_lightning2(w, w.origin, head.origin);
		w = head.wp9;if (w) te_lightning2(w, w.origin, head.origin);
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
	local entity head;
	local vector m1, m2, v;
	local float c, d, danger;
	c = 0;
	dangerwaypoint = find(dangerwaypoint, classname, "waypoint");
	while (dangerwaypoint != world && c < 16)
	{
		c = c + 1;
		danger = 0;
		m1 = dangerwaypoint.mins;
		m2 = dangerwaypoint.maxs;
		head = findchainfloat(shoulddodge, TRUE);
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
