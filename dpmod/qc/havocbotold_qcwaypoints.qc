
/*
itemscore = (howmuchmoreIwant / howmuchIcanwant) / itemdistance
waypointscore = 0.7 / waypointdistance
*/

entity  tracewalkent; // invisible entity that is reused for all tracewalks
float maxspeed;
float sv_accelerate;

float(entity e, vector start, vector end) tracewalk =
{
	local   vector  move, v, dir, nostependpos;
	local   float   dist, totaldist, stepdist, yaw, ignorehazards, p, nostepfrac;
	local   entity  saveself;
	move = end - start;
	move_z = 0;
	dist = totaldist = vlen(move);
	dir = normalize(move);
	stepdist = 32;
	saveself = self;
	if (!tracewalkent)
	{
		tracewalkent = spawn();
		setsize(tracewalkent, '-16 -16 -24', '16 16 32');
	}
	tracewalkent.owner = self; // avoid collisions
	self = tracewalkent;
	setorigin(self, start);
	//self.angles = vectoangles(dir);
	p = pointcontents(self.origin);
	if (p == CONTENT_EMPTY)
	{
		tracebox(start + '0 0 18', '-16 -16 -24', '16 16 32', start + '0 0 -18', FALSE, e);
		if (trace_fraction >= 1) // start isn't even on the floor
		{
			self = saveself;
			return 0;
		}
	}
	if (end_x >= self.absmin_x && end_y >= self.absmin_y && end_z >= self.absmin_z && end_x < self.absmax_x && end_y < self.absmax_y && end_z < self.absmax_z)
	{
		//WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		//WriteByte (MSG_BROADCAST, TE_GUNSHOT);
		//WriteVec (MSG_BROADCAST, end);
		self = saveself;
		return 1;
	}
	ignorehazards = FALSE;
	p = pointcontents(start);
	if (p == CONTENT_LAVA || p == CONTENT_SLIME)
		ignorehazards = TRUE;
	yaw = vectoyaw(move);
	move = end - self.origin;
	while (dist > 0)
	{
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
			tracebox(self.origin, '-16 -16 -24', '16 16 32', self.origin + move * stepdist, FALSE, e);
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
			tracebox(self.origin, '-16 -16 -24', '16 16 32', move, FALSE, e);
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
			tracebox(self.origin + '0 0 18', '-16 -16 -24', '16 16 32', move + '0 0 18', FALSE, e);
			if (trace_fraction > nostepfrac + 0.001)
			{
				// stepped, fall to floor
				tracebox(trace_endpos, '-16 -16 -24', '16 16 32', trace_endpos + '0 0 -65536', FALSE, e);
				setorigin(self, trace_endpos);
			}
			else
			{
				if (nostepfrac >= 0.001)
				{
					// moved, fall to floor
					tracebox(nostependpos, '-16 -16 -24', '16 16 32', nostependpos + '0 0 -65536', FALSE, e);
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
		if (end_x >= self.absmin_x)
		if (end_x < self.absmax_x)
		if (end_y >= self.absmin_y)
		if (end_y < self.absmax_y)
		if (end_z >= self.absmin_z)
		if (end_z < self.absmax_z)
		{
			//WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
			//WriteByte (MSG_BROADCAST, TE_GUNSHOT);
			//WriteVec (MSG_BROADCAST, end);
			self = saveself;
			// succeeded
			return 1;
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

float   havoccurrentbots;
float   havocbots;

string() havocbot_name =
{
	local string name;
	local float r;
	do
	{
		r = random() * 32;
		     if (r <  1) name = "Thunderstorm";
		else if (r <  2) name = "Deadly Dream";
		else if (r <  3) name = "Darkness";
		else if (r <  4) name = "Scorcher";
		else if (r <  5) name = "57 Chevy";
		else if (r <  6) name = "Dark Avenger";
		else if (r <  7) name = "Dying Time";
		else if (r <  8) name = "Paranoia";
		else if (r <  9) name = "Eureka";
		else if (r < 10) name = "Mystery";
		else if (r < 11) name = "Toxic";
		else if (r < 12) name = "Dominion";
		else if (r < 13) name = "Pegasus";
		else if (r < 14) name = "Sensible";
		else if (r < 15) name = "I Love Gibs";
		else if (r < 16) name = "The New Guy";
		else if (r < 17) name = "Boy With A Gun";
		else if (r < 18) name = "Universe Man";
		else if (r < 19) name = "The Evil One";
		else if (r < 20) name = "2MuchGibsMan";
		else if (r < 21) name = "The Plasma man";
		else if (r < 22) name = "Strange Brew";
		else if (r < 23) name = "Potato Head";
		else if (r < 24) name = "The Angel";
		else if (r < 25) name = "Radioactive Man";
		else if (r < 26) name = "Gator";
		else if (r < 27) name = "Your Demise";
		else if (r < 28) name = "The Gladiator";
		else if (r < 29) name = "Spaceman Spiff";
		else if (r < 30) name = "Johnny Dangerously";
		else if (r < 31) name = "Elmer Fudd";
		else             name = "Kangaroo";
	}
	while (find(world, netname, name));
	return name;
};

void(float t, float f1, float f2, entity e1, vector v1, vector v2, vector v3, vector v4) havocbot_lagfunc;

.void() havocbot_role;
void() havocbot_chooserole;
void() havocbot_new =
{
	local entity saveself;
	local float r;
	// only 32 names available
	if (havoccurrentbots >= 32)
		return;
	if (!coop && !deathmatch)
	{
		sprint(self, "Sorry, can't spawn bots in singleplayer, please set deathmatch 1 first.\n");
		return;
	}
	havoccurrentbots = havoccurrentbots + 1;
	newmis = spawn();
	newmis.lag_func = havocbot_lagfunc;
	newmis.isbot = TRUE;
	newmis.think = ClientConnect;
	newmis.nextthink = time + random() * 0.5 + 0.2;
	newmis.createdtime = newmis.nextthink;
	newmis.netname = havocbot_name();
	newmis.c_pants = -1;
	newmis.c_shirt = -1;
	newmis.havocbot_role = SUB_Null;
};

void() havocbot_removenewest =
{
	local   float   besttime;
	local   entity  best, head, saveself;
	head = findchainfloat(isbot, TRUE);
	if (!head)
		return;
	best = head;
	besttime = head.createdtime;
	while (head)
	{
		if (head.createdtime > besttime)
		{
			best = head;
			besttime = head.createdtime;
		}
		head = head.chain;
	}
	havoccurrentbots = havoccurrentbots - 1;
	saveself = self;
	self = best;
	ClientDisconnect();
	self = saveself;
};

void() havocbot_think;
void() havocbot_updatedangerousobjects;

void() havocbot_serverframe =
{
	local   entity  head, saveself;
	local   float   botcount;
	if (intermission_running)
		return;

	head = findfloat(world, isbot, TRUE);
	if (head != world)
	{
		maxspeed = cvar("sv_maxspeed"); // player movement speed
		sv_accelerate = cvar("sv_accelerate"); // 10 normally

		havocbot_updatedangerousobjects();
		saveself = self;
		while (head)
		{
			self = head;
			havocbot_think();
			PlayerPreThink();
			PlayerPostThink();
			head = findfloat(head, isbot, TRUE);
		}
		self = saveself;
	}
	if (havoccurrentbots < havocbots)
		havocbot_new();
	else if (havoccurrentbots > havocbots)
		havocbot_removenewest();
};

void(float howmany) havocbot_add =
{
	if (howmany < 1)
		return;
	havocbots = havocbots + howmany;
	if (havocbots > 32)
		havocbots = 32;
};

void(float howmany) havocbot_remove =
{
	if (howmany < 1)
		return;
	havocbots = havocbots - howmany;
	if (havocbots < 0)
		havocbots = 0;
};

//float   WP_JUMP = 1;
//float   WP_LIFTWAIT = 2;
//float   WP_LIFTBOTTOM = 4;
//float   WP_NOUP = 8; // can't be reached from below
//float   WP_NODOWN = 16; // can't be reached from above
//.float  wpflags;

.entity wp0, wp1, wp2, wp3, wp4, wp5, wp6, wp7, wp8, wp9, wp10, wp11, wp12, wp13, wp14, wp15, wp16, wp17, wp18, wp19, wp20, wp21, wp22, wp23, wp24, wp25, wp26, wp27, wp28, wp29, wp30, wp31;
.float wpcost0, wpcost1, wpcost2, wpcost3, wpcost4, wpcost5, wpcost6, wpcost7, wpcost8, wpcost9, wpcost10, wpcost11, wpcost12, wpcost13, wpcost14, wpcost15, wpcost16, wpcost17, wpcost18, wpcost19, wpcost20, wpcost21, wpcost22, wpcost23, wpcost24, wpcost25, wpcost26, wpcost27, wpcost28, wpcost29, wpcost30, wpcost31;

float(entity from, entity to) waypoint_addlink =
{
	local float cost;
	if (from == to)
		return TRUE;
	cost = vlen(to.origin - from.origin);
	if (from.wp0 == world) {from.wp0 = to;from.wpcost0 = cost;return TRUE;}
	if (from.wp1 == world) {from.wp1 = to;from.wpcost1 = cost;return TRUE;}
	if (from.wp2 == world) {from.wp2 = to;from.wpcost2 = cost;return TRUE;}
	if (from.wp3 == world) {from.wp3 = to;from.wpcost3 = cost;return TRUE;}
	if (from.wp4 == world) {from.wp4 = to;from.wpcost4 = cost;return TRUE;}
	if (from.wp5 == world) {from.wp5 = to;from.wpcost5 = cost;return TRUE;}
	if (from.wp6 == world) {from.wp6 = to;from.wpcost6 = cost;return TRUE;}
	if (from.wp7 == world) {from.wp7 = to;from.wpcost7 = cost;return TRUE;}
	if (from.wp8 == world) {from.wp8 = to;from.wpcost8 = cost;return TRUE;}
	if (from.wp9 == world) {from.wp9 = to;from.wpcost9 = cost;return TRUE;}
	if (from.wp10 == world) {from.wp10 = to;from.wpcost10 = cost;return TRUE;}
	if (from.wp11 == world) {from.wp11 = to;from.wpcost11 = cost;return TRUE;}
	if (from.wp12 == world) {from.wp12 = to;from.wpcost12 = cost;return TRUE;}
	if (from.wp13 == world) {from.wp13 = to;from.wpcost13 = cost;return TRUE;}
	if (from.wp14 == world) {from.wp14 = to;from.wpcost14 = cost;return TRUE;}
	if (from.wp15 == world) {from.wp15 = to;from.wpcost15 = cost;return TRUE;}
	if (from.wp16 == world) {from.wp16 = to;from.wpcost16 = cost;return TRUE;}
	if (from.wp17 == world) {from.wp17 = to;from.wpcost17 = cost;return TRUE;}
	if (from.wp18 == world) {from.wp18 = to;from.wpcost18 = cost;return TRUE;}
	if (from.wp19 == world) {from.wp19 = to;from.wpcost19 = cost;return TRUE;}
	if (from.wp20 == world) {from.wp20 = to;from.wpcost20 = cost;return TRUE;}
	if (from.wp21 == world) {from.wp21 = to;from.wpcost21 = cost;return TRUE;}
	if (from.wp22 == world) {from.wp22 = to;from.wpcost22 = cost;return TRUE;}
	if (from.wp23 == world) {from.wp23 = to;from.wpcost23 = cost;return TRUE;}
	if (from.wp24 == world) {from.wp24 = to;from.wpcost24 = cost;return TRUE;}
	if (from.wp25 == world) {from.wp25 = to;from.wpcost25 = cost;return TRUE;}
	if (from.wp26 == world) {from.wp26 = to;from.wpcost26 = cost;return TRUE;}
	if (from.wp27 == world) {from.wp27 = to;from.wpcost27 = cost;return TRUE;}
	if (from.wp28 == world) {from.wp28 = to;from.wpcost28 = cost;return TRUE;}
	if (from.wp29 == world) {from.wp29 = to;from.wpcost29 = cost;return TRUE;}
	if (from.wp30 == world) {from.wp30 = to;from.wpcost30 = cost;return TRUE;}
	if (from.wp31 == world) {from.wp31 = to;from.wpcost31 = cost;return TRUE;}
	return FALSE;
};

void() waypoint_link =
{
	local entity head;
	local float d;
	self.think = waypoint_link;
	self.nextthink = time;

	// check if this is attached to an item or anything on first frame
	if (self.enemy == world)
	{
		head = findchainfloat(havocpickup, TRUE);
		while (head)
		{
			if (self.origin_x >= head.absmin_x)
			if (self.origin_x <= head.absmax_x)
			if (self.origin_y >= head.absmin_y)
			if (self.origin_y <= head.absmax_y)
			if (self.origin_z >= head.absmin_z)
			if (self.origin_z <= head.absmax_z)
			{
				self.owner = head;
				head = world;
			}
			head = head.chain;
		}
	}

	d = 20;
	while (d > 0)
	{
		d = d - 1;
		self.enemy = find(self.enemy, classname, "waypoint");
		if (self.enemy == world)
		{
			self.nextthink = 0;
			return;
		}

		// trace from there, to here
		//traceline(self.origin, self.enemy.origin, FALSE, self);
		//if (trace_fraction == 1)
		// trace from here to there
		//if (tracewalk(self, self.enemy.origin, self.origin))
		if (tracewalk(self, self.origin, self.enemy.origin))
			waypoint_addlink(self, self.enemy);
	}
};

void() waypoint_relinkall =
{
	local entity head;
	head = findchain(classname, "waypoint");
	while (head)
	{
		head.enemy = world;
		head.owner = world;
		//head.waypoints = 0;
		head.wp0 = head.wp1 = head.wp2 = head.wp3 = head.wp4 = head.wp5 = head.wp6 = head.wp7 = world;
		head.wp8 = head.wp9 = head.wp10 = head.wp11 = head.wp12 = head.wp13 = head.wp14 = head.wp15 = world;
		head.wp16 = head.wp17 = head.wp18 = head.wp19 = head.wp20 = head.wp21 = head.wp22 = head.wp23 = world;
		head.wp24 = head.wp25 = head.wp26 = head.wp27 = head.wp28 = head.wp29 = head.wp30 = head.wp31 = world;
		head.wpcost0 = head.wpcost1 = head.wpcost2 = head.wpcost3 = head.wpcost4 = head.wpcost5 = head.wpcost6 = head.wpcost7 = 0;
		head.wpcost8 = head.wpcost9 = head.wpcost10 = head.wpcost11 = head.wpcost12 = head.wpcost13 = head.wpcost14 = head.wpcost15 = 0;
		head.wpcost16 = head.wpcost17 = head.wpcost18 = head.wpcost19 = head.wpcost20 = head.wpcost21 = head.wpcost22 = head.wpcost23 = 0;
		head.wpcost24 = head.wpcost25 = head.wpcost26 = head.wpcost27 = head.wpcost28 = head.wpcost29 = head.wpcost30 = head.wpcost31 = 0;
		head.think = waypoint_link;
		head.nextthink = time + 0.1;
		head = head.chain;
	}
};

.entity goalcurrent, goalstack1, goalstack2, goalstack3, goalstack4, goalstack5, goalstack6, goalstack7, goalstack8, goalstack9;
.entity goalstack10, goalstack11, goalstack12, goalstack13, goalstack14, goalstack15, goalstack16, goalstack17, goalstack18, goalstack19;
.entity goalstack20, goalstack21, goalstack22, goalstack23, goalstack24, goalstack25, goalstack26, goalstack27, goalstack28, goalstack29;
.entity goalstack30, goalstack31, goalstack32;

void() clearroute =
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

void(entity e) pushroute =
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

void() poproute =
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
.vector nearestwaypointorigin;

entity(entity e) findnearestwaypoint =
{
	local entity head, best;
	local float d, dist;
	local vector org;
	//local string s;
	if (/*e.nearestwaypoint == world || */e.origin != e.nearestwaypointorigin)
	{
		org = (e.mins + e.maxs) * 0.5;
		org_z = e.mins_z;
		org = org + e.origin + '0 0 24';
		best = world;
		dist = 1000000000;
		head = findchain(classname, "waypoint");
		while (head)
		{
			d = vlen(head.origin - org);
			if (d < dist)
			if (tracewalk(e, org, head.origin))
			{
				best = head;
				dist = d;
			}
			head = head.chain;
		}
		e.nearestwaypoint = best;
		e.nearestwaypointorigin = e.origin;
	}
	/*
	s = etos(e.nearestwaypoint);
	bprint(s);
	bprint(" findnearestwaypoint(");
	s = etos(e);
	bprint(s);
	bprint(")\n");
	*/
	return e.nearestwaypoint;
};

float timediff;
.float wpfire, wpcost/*, wprating*/;
//entity havocbot_bestgoal;
void() markroutes =
{
	local entity start, head, w;
	local vector org;
	local float d, dist, cost;
	//local vector m1, m2;
	//m1 = self.absmin;
	//m2 = self.absmax;
	//havocbot_bestgoal = world;
	/*
	start = world;
	dist = 1000000000;
	org = self.origin;
	head = findchain(classname, "waypoint");
	while (head)
	{
		head.wpcost = 10000000;
		head.enemy = world;
		head.wpfire = 0;
		//head.wprating = 0;
		d = vlen(head.origin - org);
		if (d < dist)
		if (tracewalk(self, org, head.origin))
		{
			start = head;
			dist = d;
		}
		head = head.chain;
	}
	if (start == world)
		return;
	start.wpfire = 1;
	start.wpcost = dist;
	*/
	org = self.origin;
	//cost = 0;
	head = findchain(classname, "waypoint");
	while (head)
	{
		head.wpcost = 10000000;
		head.wpfire = 0;
		head.enemy = world;
		/*
		//head.wpmark = FALSE;
		//head.wprating = 0;
		//org = head.origin;
		//if (head != self.lastwaypointtouched)
		//if (org_x < m1_x || org_x > m2_x || org_y < m1_y || org_y > m2_y || org_z < m1_z || org_z > m2_z)
		if (tracewalk(self, org, head.origin))
		{
			head.wpcost = vlen(head.origin - org);
			head.wpfire = 1;
			//head.wpmark = TRUE;
			//cost = cost + 1;
		}
		*/
		head = head.chain;
	}
	w = findnearestwaypoint(self);
	if (w == world)
		return;
	w.wpcost = vlen(w.origin - org) + w.dmg;
	w.wpfire = 1;
	//bprint("start waypoints ");
	//bprintfloat(cost);
	//bprint("\n");
	while (1)
	{
		head = findchainfloat(wpfire, 1);
		if (head == world)
			return;
		while (head)
		{
			head.wpfire = 0;
			w = head.wp0;if(w){cost = head.wpcost + head.wpcost0 + head.dmg;if(w.wpcost > cost){w.wpcost = cost;w.enemy = head;w.wpfire = 1;}
			w = head.wp1;if(w){cost = head.wpcost + head.wpcost1 + head.dmg;if(w.wpcost > cost){w.wpcost = cost;w.enemy = head;w.wpfire = 1;}
			w = head.wp2;if(w){cost = head.wpcost + head.wpcost2 + head.dmg;if(w.wpcost > cost){w.wpcost = cost;w.enemy = head;w.wpfire = 1;}
			w = head.wp3;if(w){cost = head.wpcost + head.wpcost3 + head.dmg;if(w.wpcost > cost){w.wpcost = cost;w.enemy = head;w.wpfire = 1;}
			w = head.wp4;if(w){cost = head.wpcost + head.wpcost4 + head.dmg;if(w.wpcost > cost){w.wpcost = cost;w.enemy = head;w.wpfire = 1;}
			w = head.wp5;if(w){cost = head.wpcost + head.wpcost5 + head.dmg;if(w.wpcost > cost){w.wpcost = cost;w.enemy = head;w.wpfire = 1;}
			w = head.wp6;if(w){cost = head.wpcost + head.wpcost6 + head.dmg;if(w.wpcost > cost){w.wpcost = cost;w.enemy = head;w.wpfire = 1;}
			w = head.wp7;if(w){cost = head.wpcost + head.wpcost7 + head.dmg;if(w.wpcost > cost){w.wpcost = cost;w.enemy = head;w.wpfire = 1;}
			w = head.wp8;if(w){cost = head.wpcost + head.wpcost8 + head.dmg;if(w.wpcost > cost){w.wpcost = cost;w.enemy = head;w.wpfire = 1;}
			w = head.wp9;if(w){cost = head.wpcost + head.wpcost9 + head.dmg;if(w.wpcost > cost){w.wpcost = cost;w.enemy = head;w.wpfire = 1;}
			w = head.wp10;if(w){cost = head.wpcost + head.wpcost10 + head.dmg;if(w.wpcost > cost){w.wpcost = cost;w.enemy = head;w.wpfire = 1;}
			w = head.wp11;if(w){cost = head.wpcost + head.wpcost11 + head.dmg;if(w.wpcost > cost){w.wpcost = cost;w.enemy = head;w.wpfire = 1;}
			w = head.wp12;if(w){cost = head.wpcost + head.wpcost12 + head.dmg;if(w.wpcost > cost){w.wpcost = cost;w.enemy = head;w.wpfire = 1;}
			w = head.wp13;if(w){cost = head.wpcost + head.wpcost13 + head.dmg;if(w.wpcost > cost){w.wpcost = cost;w.enemy = head;w.wpfire = 1;}
			w = head.wp14;if(w){cost = head.wpcost + head.wpcost14 + head.dmg;if(w.wpcost > cost){w.wpcost = cost;w.enemy = head;w.wpfire = 1;}
			w = head.wp15;if(w){cost = head.wpcost + head.wpcost15 + head.dmg;if(w.wpcost > cost){w.wpcost = cost;w.enemy = head;w.wpfire = 1;}
			w = head.wp16;if(w){cost = head.wpcost + head.wpcost16 + head.dmg;if(w.wpcost > cost){w.wpcost = cost;w.enemy = head;w.wpfire = 1;}
			w = head.wp17;if(w){cost = head.wpcost + head.wpcost17 + head.dmg;if(w.wpcost > cost){w.wpcost = cost;w.enemy = head;w.wpfire = 1;}
			w = head.wp18;if(w){cost = head.wpcost + head.wpcost18 + head.dmg;if(w.wpcost > cost){w.wpcost = cost;w.enemy = head;w.wpfire = 1;}
			w = head.wp19;if(w){cost = head.wpcost + head.wpcost19 + head.dmg;if(w.wpcost > cost){w.wpcost = cost;w.enemy = head;w.wpfire = 1;}
			w = head.wp20;if(w){cost = head.wpcost + head.wpcost20 + head.dmg;if(w.wpcost > cost){w.wpcost = cost;w.enemy = head;w.wpfire = 1;}
			w = head.wp21;if(w){cost = head.wpcost + head.wpcost21 + head.dmg;if(w.wpcost > cost){w.wpcost = cost;w.enemy = head;w.wpfire = 1;}
			w = head.wp22;if(w){cost = head.wpcost + head.wpcost22 + head.dmg;if(w.wpcost > cost){w.wpcost = cost;w.enemy = head;w.wpfire = 1;}
			w = head.wp23;if(w){cost = head.wpcost + head.wpcost23 + head.dmg;if(w.wpcost > cost){w.wpcost = cost;w.enemy = head;w.wpfire = 1;}
			w = head.wp24;if(w){cost = head.wpcost + head.wpcost24 + head.dmg;if(w.wpcost > cost){w.wpcost = cost;w.enemy = head;w.wpfire = 1;}
			w = head.wp25;if(w){cost = head.wpcost + head.wpcost25 + head.dmg;if(w.wpcost > cost){w.wpcost = cost;w.enemy = head;w.wpfire = 1;}
			w = head.wp26;if(w){cost = head.wpcost + head.wpcost26 + head.dmg;if(w.wpcost > cost){w.wpcost = cost;w.enemy = head;w.wpfire = 1;}
			w = head.wp27;if(w){cost = head.wpcost + head.wpcost27 + head.dmg;if(w.wpcost > cost){w.wpcost = cost;w.enemy = head;w.wpfire = 1;}
			w = head.wp28;if(w){cost = head.wpcost + head.wpcost28 + head.dmg;if(w.wpcost > cost){w.wpcost = cost;w.enemy = head;w.wpfire = 1;}
			w = head.wp29;if(w){cost = head.wpcost + head.wpcost29 + head.dmg;if(w.wpcost > cost){w.wpcost = cost;w.enemy = head;w.wpfire = 1;}
			w = head.wp30;if(w){cost = head.wpcost + head.wpcost30 + head.dmg;if(w.wpcost > cost){w.wpcost = cost;w.enemy = head;w.wpfire = 1;}
			w = head.wp31;if(w){cost = head.wpcost + head.wpcost31 + head.dmg;if(w.wpcost > cost){w.wpcost = cost;w.enemy = head;w.wpfire = 1;}
			}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}
			head = head.chain;
		}
	}
};

void(entity e, float f) routerating =
{
	local entity w;
	local float c;
	local string s;
	w = findnearestwaypoint(e);
	if (w)
	{
		/*
		s = etos(e);
		bprint(s);
		bprint(" rating ");
		bprintfloat(f);
		bprint(":");
		*/
		f = f / ((w.wpcost + vlen(e.origin - w.origin)) * 0.001 + 1);
		/*
		bprintfloat(f);
		bprint("\n");
		*/
		if (havocbot_bestrating < f)
		{
			/*
			// don't choose a goal too many waypoints away
			c = 0;
			while (c < 30)
			{
				c = c + 1;
				if (w == world)
				{
			*/
					havocbot_bestrating = f;
					havocbot_bestgoal = e;
			/*
					return;
				}
				w = w.enemy;
			}
			*/
		}
	}
};

/*
void() havocbot_choosegoal =
{
	local entity head, best, w;
	local float rating, bestrating;

	// calculate all waypoint routes
	markroutes();

	// choose the best goal
	best = world;
	bestrating = -1;
	head = findchainfloat(havocpickup, TRUE);
	while (head)
	{
		w = findnearestwaypoint(head);
		if (w)
		{
			rating = f / w.wpcost + vlen(e.origin - w.origin) + 100;
			if (bestrating < rating)
			{
				// don't choose a goal too many waypoints away
				c = 0;
				while (c < 7)
				{
					c = c + 1;
					w = w.enemy;
					if (w == world)
					{
						best = head;
						bestrating = rating;
						break;
					}
				}
			}
		}
		head = head.chain;
	}
	clearroute();
	if (best)
	{
		pushroute(best);
		w = findnearestwaypoint(best);
		while (w)
		{
			pushroute(w);
			w = w.enemy;
		}
	}
};
*/

void(entity e) routetogoal =
{
	local vector org, m1, m2;
	local float f;
	local string s;
	clearroute();
	self.goalentity = e;
	if (e == world)
		return;
	/*
	bprint("routetogoal(");
	s = etos(e);
	bprint(s);
	bprint(")\n");
	*/
	pushroute(e);
	if (tracewalk(self, self.origin, e.origin))
		return;
	e = findnearestwaypoint(e);
	m1 = self.absmin;
	m2 = self.absmax;
	//while (e.enemy != world)
	while (e != world)
	{
		//if (e == self.lastwaypointtouched)
		//	return; // skip nearest waypoint if it has already been touched
		org = e.origin;
		if (org_x >= m1_x)
		if (org_x <= m2_x)
		if (org_y >= m1_y)
		if (org_y <= m2_y)
		if (org_z >= m1_z)
		if (org_z <= m2_z)
			return;
		pushroute(e);
		/*
		if (e.enemy.enemy == world)
		{
			f = vlen(e.enemy.origin - self.origin);
			if (vlen(e.origin - self.origin) > f)
				return; // skip the nearest-to-player waypoint if it is further from the goal
		}
		*/
		e = e.enemy;
	}
};

/*
// waypoint status for searchs is stored in .wpstat, values: 0 hasn't been reached, 1 means reached, 2 means 'leading edge'.
.float wpstat;

.float waypointsearchtime;
.vector waypointsearchorigin;
.entity lastwaypointtouched;
// returns the first waypoint to go to, on the shortest path to endwp
entity(entity endent) findwppath2 =
{
	local entity head, w;
	local vector end;
	local float mark, mark2;

	end = endent.origin;
	if (tracewalk(self, self.origin, end))
	{
		bprint("direct walk\n");
		return endent;
	}

	mark = FALSE;
	if (self.lastwaypointtouched != world && vlen(self.origin - self.lastwaypointtouched.origin) < 64)
	{
		// setup the waypoint web
		head = findchain(classname, "waypoint");
		while (head)
		{
			head.wpstat = 0;
			head = head.chain;
		}

		// mark all waypoints that start can walk to
		// LordHavoc: I realize this indentation is horrid, but so is the lack of arrays in QC
		head = self.lastwaypointtouched;
		w = head.wp0;if (w){w.wpstat = -1;mark = TRUE;
		w = head.wp1;if (w){w.wpstat = -1;
		w = head.wp2;if (w){w.wpstat = -1;
		w = head.wp3;if (w){w.wpstat = -1;
		w = head.wp4;if (w){w.wpstat = -1;
		w = head.wp5;if (w){w.wpstat = -1;
		w = head.wp6;if (w){w.wpstat = -1;
		w = head.wp7;if (w){w.wpstat = -1;
		w = head.wp8;if (w){w.wpstat = -1;
		w = head.wp9;if (w){w.wpstat = -1;
		w = head.wp10;if (w){w.wpstat = -1;
		w = head.wp11;if (w){w.wpstat = -1;
		w = head.wp12;if (w){w.wpstat = -1;
		w = head.wp13;if (w){w.wpstat = -1;
		w = head.wp14;if (w){w.wpstat = -1;
		w = head.wp15;if (w){w.wpstat = -1;
		w = head.wp16;if (w){w.wpstat = -1;
		w = head.wp17;if (w){w.wpstat = -1;
		w = head.wp18;if (w){w.wpstat = -1;
		w = head.wp19;if (w){w.wpstat = -1;
		w = head.wp20;if (w){w.wpstat = -1;
		w = head.wp21;if (w){w.wpstat = -1;
		w = head.wp22;if (w){w.wpstat = -1;
		w = head.wp23;if (w){w.wpstat = -1;
		w = head.wp24;if (w){w.wpstat = -1;
		w = head.wp25;if (w){w.wpstat = -1;
		w = head.wp26;if (w){w.wpstat = -1;
		w = head.wp27;if (w){w.wpstat = -1;
		w = head.wp28;if (w){w.wpstat = -1;
		w = head.wp29;if (w){w.wpstat = -1;
		w = head.wp30;if (w){w.wpstat = -1;
		w = head.wp31;if (w){w.wpstat = -1;
		}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}
	}
	else
	{
		// setup the waypoint web, and mark all waypoints that start can walk to
		head = findchain(classname, "waypoint");
		while (head)
		{
			head.wpstat = 0;

			// mark all waypoints that start can walk to
			traceline(self.origin, head.origin, FALSE, self);
			if (trace_fraction == 1)
			if (tracewalk(self, self.origin, head.origin))
			{
				head.wpstat = -1;
				mark = TRUE;
			}

			head = head.chain;
		}
	}

	if (!mark)
	{
		bprint("no start waypoints\n");
		//if (self.flags & FL_ONGROUND)
		//	waypointspawn(self.origin, 0);
		self.effects = self.effects | EF_MUZZLEFLASH;
		return world;
	}

	if (time > endent.waypointsearchtime || endent.origin != endent.waypointsearchorigin)
	{
		bprint("updating waypoints for a ");
		bprint(endent.classname);
		bprint("\n");
		endent.waypointsearchtime = time + 60;
		endent.waypointsearchorigin = endent.origin;
		head = findchain(classname, "waypoint");
		while (head)
		{
			// mark all waypoints that can walk to the destination
			traceline(head.origin, end, FALSE, self);
			if (trace_fraction == 1)
			if (tracewalk(self, head.origin, end))
				waypoint_addlink(endent, head);
			head = head.chain;
		}
	}
	// if this waypoint can also reach the end directly, return it
	// LordHavoc: I realize this indentation is horrid, but so is the lack of arrays in QC
	w = endent.wp0;if (w){if (w.wpstat == -1) return w;w.wpstat = 2;
	w = endent.wp1;if (w){if (w.wpstat == -1) return w;w.wpstat = 2;
	w = endent.wp2;if (w){if (w.wpstat == -1) return w;w.wpstat = 2;
	w = endent.wp3;if (w){if (w.wpstat == -1) return w;w.wpstat = 2;
	w = endent.wp4;if (w){if (w.wpstat == -1) return w;w.wpstat = 2;
	w = endent.wp5;if (w){if (w.wpstat == -1) return w;w.wpstat = 2;
	w = endent.wp6;if (w){if (w.wpstat == -1) return w;w.wpstat = 2;
	w = endent.wp7;if (w){if (w.wpstat == -1) return w;w.wpstat = 2;
	w = endent.wp8;if (w){if (w.wpstat == -1) return w;w.wpstat = 2;
	w = endent.wp9;if (w){if (w.wpstat == -1) return w;w.wpstat = 2;
	w = endent.wp10;if (w){if (w.wpstat == -1) return w;w.wpstat = 2;
	w = endent.wp11;if (w){if (w.wpstat == -1) return w;w.wpstat = 2;
	w = endent.wp12;if (w){if (w.wpstat == -1) return w;w.wpstat = 2;
	w = endent.wp13;if (w){if (w.wpstat == -1) return w;w.wpstat = 2;
	w = endent.wp14;if (w){if (w.wpstat == -1) return w;w.wpstat = 2;
	w = endent.wp15;if (w){if (w.wpstat == -1) return w;w.wpstat = 2;
	w = endent.wp16;if (w){if (w.wpstat == -1) return w;w.wpstat = 2;
	w = endent.wp17;if (w){if (w.wpstat == -1) return w;w.wpstat = 2;
	w = endent.wp18;if (w){if (w.wpstat == -1) return w;w.wpstat = 2;
	w = endent.wp19;if (w){if (w.wpstat == -1) return w;w.wpstat = 2;
	w = endent.wp20;if (w){if (w.wpstat == -1) return w;w.wpstat = 2;
	w = endent.wp21;if (w){if (w.wpstat == -1) return w;w.wpstat = 2;
	w = endent.wp22;if (w){if (w.wpstat == -1) return w;w.wpstat = 2;
	w = endent.wp23;if (w){if (w.wpstat == -1) return w;w.wpstat = 2;
	w = endent.wp24;if (w){if (w.wpstat == -1) return w;w.wpstat = 2;
	w = endent.wp25;if (w){if (w.wpstat == -1) return w;w.wpstat = 2;
	w = endent.wp26;if (w){if (w.wpstat == -1) return w;w.wpstat = 2;
	w = endent.wp27;if (w){if (w.wpstat == -1) return w;w.wpstat = 2;
	w = endent.wp28;if (w){if (w.wpstat == -1) return w;w.wpstat = 2;
	w = endent.wp29;if (w){if (w.wpstat == -1) return w;w.wpstat = 2;
	w = endent.wp30;if (w){if (w.wpstat == -1) return w;w.wpstat = 2;
	w = endent.wp31;if (w){if (w.wpstat == -1) return w;w.wpstat = 2;
	}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}
	else
	{
		endent.havocbotignoretime = time + 10;
		endent.effects = endent.effects | EF_RED;
		return world;
	}

	mark = 2;
	mark2 = mark + 1;
	head = findchainfloat(wpstat, mark);
	while (head != world)
	{
		// add edge around solid
		while (head)
		{
			// LordHavoc: I realize this indentation is horrid, but so is the lack of arrays in QC
			w = head.wp0;if (w){if (w.wpstat <= 0){if (w.wpstat)return w;w.wpstat = mark2;}
			w = head.wp1;if (w){if (w.wpstat <= 0){if (w.wpstat)return w;w.wpstat = mark2;}
			w = head.wp2;if (w){if (w.wpstat <= 0){if (w.wpstat)return w;w.wpstat = mark2;}
			w = head.wp3;if (w){if (w.wpstat <= 0){if (w.wpstat)return w;w.wpstat = mark2;}
			w = head.wp4;if (w){if (w.wpstat <= 0){if (w.wpstat)return w;w.wpstat = mark2;}
			w = head.wp5;if (w){if (w.wpstat <= 0){if (w.wpstat)return w;w.wpstat = mark2;}
			w = head.wp6;if (w){if (w.wpstat <= 0){if (w.wpstat)return w;w.wpstat = mark2;}
			w = head.wp7;if (w){if (w.wpstat <= 0){if (w.wpstat)return w;w.wpstat = mark2;}
			w = head.wp8;if (w){if (w.wpstat <= 0){if (w.wpstat)return w;w.wpstat = mark2;}
			w = head.wp9;if (w){if (w.wpstat <= 0){if (w.wpstat)return w;w.wpstat = mark2;}
			w = head.wp10;if (w){if (w.wpstat <= 0){if (w.wpstat)return w;w.wpstat = mark2;}
			w = head.wp11;if (w){if (w.wpstat <= 0){if (w.wpstat)return w;w.wpstat = mark2;}
			w = head.wp12;if (w){if (w.wpstat <= 0){if (w.wpstat)return w;w.wpstat = mark2;}
			w = head.wp13;if (w){if (w.wpstat <= 0){if (w.wpstat)return w;w.wpstat = mark2;}
			w = head.wp14;if (w){if (w.wpstat <= 0){if (w.wpstat)return w;w.wpstat = mark2;}
			w = head.wp15;if (w){if (w.wpstat <= 0){if (w.wpstat)return w;w.wpstat = mark2;}
			w = head.wp16;if (w){if (w.wpstat <= 0){if (w.wpstat)return w;w.wpstat = mark2;}
			w = head.wp17;if (w){if (w.wpstat <= 0){if (w.wpstat)return w;w.wpstat = mark2;}
			w = head.wp18;if (w){if (w.wpstat <= 0){if (w.wpstat)return w;w.wpstat = mark2;}
			w = head.wp19;if (w){if (w.wpstat <= 0){if (w.wpstat)return w;w.wpstat = mark2;}
			w = head.wp20;if (w){if (w.wpstat <= 0){if (w.wpstat)return w;w.wpstat = mark2;}
			w = head.wp21;if (w){if (w.wpstat <= 0){if (w.wpstat)return w;w.wpstat = mark2;}
			w = head.wp22;if (w){if (w.wpstat <= 0){if (w.wpstat)return w;w.wpstat = mark2;}
			w = head.wp23;if (w){if (w.wpstat <= 0){if (w.wpstat)return w;w.wpstat = mark2;}
			w = head.wp24;if (w){if (w.wpstat <= 0){if (w.wpstat)return w;w.wpstat = mark2;}
			w = head.wp25;if (w){if (w.wpstat <= 0){if (w.wpstat)return w;w.wpstat = mark2;}
			w = head.wp26;if (w){if (w.wpstat <= 0){if (w.wpstat)return w;w.wpstat = mark2;}
			w = head.wp27;if (w){if (w.wpstat <= 0){if (w.wpstat)return w;w.wpstat = mark2;}
			w = head.wp28;if (w){if (w.wpstat <= 0){if (w.wpstat)return w;w.wpstat = mark2;}
			w = head.wp29;if (w){if (w.wpstat <= 0){if (w.wpstat)return w;w.wpstat = mark2;}
			w = head.wp30;if (w){if (w.wpstat <= 0){if (w.wpstat)return w;w.wpstat = mark2;}
			w = head.wp31;if (w){if (w.wpstat <= 0){if (w.wpstat)return w;w.wpstat = mark2;}
			}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}
			head = head.chain;
		}
		mark = mark2;
		mark2 = mark2 + 1;
		head = findchainfloat(wpstat, mark);
	}
	bprint("separated, mark = ");
	bprintfloat(mark);
	bprint("\n");
	//endent.havocbotignoretime = time + 1;
	return world; // unable to reach it (rooms separated by teleporters perhaps)
};
*/

void() waypoint_touch =
{
	local entity w;
	if (other.classname != "player")
		return;
	if (other.isbot)
	{
		if (other.goalcurrent == self)
		{
			w = self;
			self = other;
			poproute();
			self = w;
			return;
		}
	}
	else
	{
		if (time > self.lefty)
		{
			self.lefty = time + 0.19;
			if (cvar("temp1") & 512)
			{
				w = self.wp0;if (w) te_lightning2(w, w.origin, self.origin);
				w = self.wp1;if (w) te_lightning2(w, w.origin, self.origin);
				w = self.wp2;if (w) te_lightning2(w, w.origin, self.origin);
				w = self.wp3;if (w) te_lightning2(w, w.origin, self.origin);
				w = self.wp4;if (w) te_lightning2(w, w.origin, self.origin);
				w = self.wp5;if (w) te_lightning2(w, w.origin, self.origin);
				w = self.wp6;if (w) te_lightning2(w, w.origin, self.origin);
				w = self.wp7;if (w) te_lightning2(w, w.origin, self.origin);
				w = self.wp8;if (w) te_lightning2(w, w.origin, self.origin);
				w = self.wp9;if (w) te_lightning2(w, w.origin, self.origin);
				w = self.wp10;if (w) te_lightning2(w, w.origin, self.origin);
				w = self.wp11;if (w) te_lightning2(w, w.origin, self.origin);
				w = self.wp12;if (w) te_lightning2(w, w.origin, self.origin);
				w = self.wp13;if (w) te_lightning2(w, w.origin, self.origin);
				w = self.wp14;if (w) te_lightning2(w, w.origin, self.origin);
				w = self.wp15;if (w) te_lightning2(w, w.origin, self.origin);
				w = self.wp16;if (w) te_lightning2(w, w.origin, self.origin);
				w = self.wp17;if (w) te_lightning2(w, w.origin, self.origin);
				w = self.wp18;if (w) te_lightning2(w, w.origin, self.origin);
				w = self.wp19;if (w) te_lightning2(w, w.origin, self.origin);
				w = self.wp20;if (w) te_lightning2(w, w.origin, self.origin);
				w = self.wp21;if (w) te_lightning2(w, w.origin, self.origin);
				w = self.wp22;if (w) te_lightning2(w, w.origin, self.origin);
				w = self.wp23;if (w) te_lightning2(w, w.origin, self.origin);
				w = self.wp24;if (w) te_lightning2(w, w.origin, self.origin);
				w = self.wp25;if (w) te_lightning2(w, w.origin, self.origin);
				w = self.wp26;if (w) te_lightning2(w, w.origin, self.origin);
				w = self.wp27;if (w) te_lightning2(w, w.origin, self.origin);
				w = self.wp28;if (w) te_lightning2(w, w.origin, self.origin);
				w = self.wp29;if (w) te_lightning2(w, w.origin, self.origin);
				w = self.wp30;if (w) te_lightning2(w, w.origin, self.origin);
				w = self.wp31;if (w) te_lightning2(w, w.origin, self.origin);
			}
		}
	}
};

void(entity e, vector org, float f) waypointsetup =
{
	//// disabled havocbots
	//if (e) remove(e);
	//return;

	// check floor
	tracebox(org + '0 0 34', '-16 -16 -24', '16 16 32', org + '0 0 -34', FALSE, world);
	if (trace_fraction >= 1) // no floor
	{
		if (e) remove(e);
		return;
	}
	org = trace_endpos + '0 0 1'; // drop to floor
	if (e == world)
		e = spawn();
	e.classname = "waypoint";
	e.solid = SOLID_TRIGGER;
	e.touch = waypoint_touch;
	if (cvar("temp1") & 512)
		setmodel(e, "progs/s_bubble.spr");
	setsize(e, '-16 -16 -24', '16 16 32');
	setorigin(e, org);
	e.movetype = MOVETYPE_NONE; //TOSS;
	e.velocity = '0 0 -1000';
//	e.wpflags = f;
	e.think = waypoint_link;
	e.nextthink = time + 0.3 + random() * 0.5;
};

/*QUAKED waypoint (0 .7 .4) (-8 -8 -8) (8 8 8) LIFTWAIT LIFTBOTTOM
The bots need these to navigate a level.
Every place they can walk to needs one.
Especially corners, top/bottom of stairs,
lift top/bottom, etc.

flags:
LIFTWAIT - bot will wait here for lift
           to come down.
LIFTBOTTOM - use for waypoint at bottom
             of lift, bot will go here.
             (place normal waypoint
              above this, at top position)
LIFTTOP - bot will expect to arrive here.
*/

void() waypoint = {waypointsetup(self, self.origin, self.spawnflags);};

.float havocbotignoretime;
void(vector dodge) havocbot_movetogoal =
{
	local vector destorg, diff, dir, vel, flatdir, move, end;
	local float s, dist, walkdist, walkangle, havoconground, p;
	local entity e, head;
	if (self.goalentity == world)
		return;
	if (self.waterlevel)
	{
		/*
		if (self.goalentity.classname != "waypoint" && !self.goalentity.havocpickup)
		{
			self.lastgoal = self.goalentity = world;
			self.velocity = '0 0 0'; // stop
			return;
		}
		if (self.goalentity == world)
			self.lastgoal = world;
		else
		{
			if (vlen(self.velocity) < 100)
			if (!tracewalk(self, self.origin, self.waygoal.origin))
				self.lastgoal = world;
		}
		*/

		destorg = self.goalentity.origin;
		diff = destorg - self.origin;
		dist = vlen(diff);
		dir = normalize(diff);
		self.velocity = self.velocity + dir * (400 * sv_accelerate * frametime) + normalize(dodge) * maxspeed * 2;
		if (vlen(self.velocity) > maxspeed)
			self.velocity = normalize(self.velocity) * maxspeed;
	}
	else
	{
		havoconground = self.flags & FL_ONGROUND;
		/*
		if (self.goalentity.classname != "waypoint" && !self.goalentity.havocpickup)
		{
			self.lastgoal = self.goalentity = world;
			if (havoconground)
				self.velocity = '0 0 0'; // stop
			return;
		}
		*/
		if (!havoconground)
		{
			// prevent goal checks when we can't walk
			//self.goaltime = time + 0.2;
			return;
		}
		/*
		if (self.waygoal == world)
			self.lastgoal = world;
		else
		{
			if (vlen(self.velocity) < 100)
			if (!tracewalk(self, self.origin, self.waygoal.origin))
				self.lastgoal = world;
		}
		*/

		destorg = self.goalcurrent.origin;
		diff = destorg - self.origin;
		dist = vlen(diff);
		dir = normalize(diff);
		flatdir = diff;flatdir_z = 0;
		flatdir = normalize(flatdir);
		// the * 1.125 is to turn a maxspeed of 320, into an acceleration of 400 to match the default quake cl_*speed variables
		vel = flatdir * (maxspeed * 1.125) * sv_accelerate;
		self.velocity = self.velocity + vel * frametime;
		if (vlen(dodge) > 1)
		{
			dodge_z = 0;
			self.velocity = self.velocity + normalize(dodge) * maxspeed * 2;
		}
		move = self.velocity;move_z = 0;
		if (vlen(move) > maxspeed)
			move = normalize(move) * maxspeed;
		self.velocity_x = move_x;self.velocity_y = move_y;
	}
	//if (self.goalcurrent != world)
	//	self.goalcurrent.effects = self.goalcurrent.effects | EF_MUZZLEFLASH;
};

vector() havocbot_dodge =
{
	local entity head;
	local vector dodge, v, n;
	local float danger, bestdanger, vl, d;
	local string s;
	dodge = '0 0 0';
	bestdanger = -20;
	// check for dangerous objects near bot or approaching bot
	head = findchainfloat(shoulddodge, TRUE);
	while(head)
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
		head = head.chain;
	}
	/*
	if (dodge != '0 0 0')
	{
		bprint("dodge ");
		s = vtos(dodge * maxspeed);
		bprint(s);
		bprint("\n");
	}
	*/
	return dodge;

	/*
	local entity head;
	local float nudgeleft, nudgeright, deviation, rad;
	local vector dodge, v;
	self.movement_x = '1 0 0' * sv_maxspeed;
	v = self.goalcurrent.origin - self.origin;
	v_z = 0;
	vectorvectors(v);
	nudgeleft = 0;
	nudgeright = 0;
	head = findchainfloat(shoulddodge, TRUE);
	while(head)
	{
		// check for dangerous objects on the path to the current goal
		deviation = (head.origin - self.origin) * v_right;
		rad = head.dangerrating;
		if (deviation < rad)
		if (deviation > 0 - rad)
		{
			if (deviation < 0)
			{
				if (nudgeleft < deviation + rad)
					nudgeleft = deviation + rad;
			}
			else
			{
				if (nudgeright < 0 - (deviation - rad))
					nudgeright = 0 - (deviation - rad);
			}
		}
		head = head.chain;
	}
	dodge = '0 0 0';
	if (nudgeleft > 5 || nudgeright > 5)
	{
		if (nudgeleft < nudgeright)
		{
			// move left
			dodge = v_right * (0 - sv_maxspeed);
		}
		else
		{
			// move right
			dodge = v_right * sv_maxspeed;
		}
	}
	//if (dodge_z >=
	makevectors(self.v_angle);
	return dodge;
	*/
};

.float weaponchangetimeout;
void() havocbot_chooseenemy =
{
	local   entity  head, best;
	local   float   besthealth;
	best = world;
	besthealth = 100000000;
	head = findchainfloat(havocattack, TRUE);
	while (head)
	{
		if (head != self)
		if (!head.deadflag)
		if (head.health < besthealth)
		if (head.team != self.team || self.team == 0 || teamplay == 0)
		{
			traceline(self.origin + self.view_ofs, (head.absmin + head.absmax) * 0.5, FALSE, self);
			if (trace_ent == head || trace_fraction >= 1)
			{
				best = head;
				besthealth = head.health;
			}
		}
		head = head.chain;
	}
	self.enemy = best;
};

void() havocbot_chooseweapon =
{
	/*
	local   float   best, bestdamage, shotspeed, dist;
	dist = vlen(self.enemy.origin - self.origin);
	best = IT_WEAPON1;bestdamage = DMG_WEAPON1;
	if (self.items & IT_WEAPON2) if (self.ammo_shells  >= 1) if (dist >= DMG_WEAPON2_MINRANGE) if (dist < DMG_WEAPON2_RANGE) if (DMG_WEAPON2 > bestdamage) {best = IT_WEAPON2;bestdamage = DMG_WEAPON2;shotspeed = DMG_WEAPON2_VELOCITY;}
	if (self.items & IT_WEAPON3) if (self.ammo_shells  >= 1) if (dist >= DMG_WEAPON3_MINRANGE) if (dist < DMG_WEAPON3_RANGE) if (DMG_WEAPON3 > bestdamage) {best = IT_WEAPON3;bestdamage = DMG_WEAPON3;shotspeed = DMG_WEAPON2_VELOCITY;}
	if (self.items & IT_WEAPON4) if (self.ammo_nails   >= 1) if (dist >= DMG_WEAPON4_MINRANGE) if (dist < DMG_WEAPON4_RANGE) if (DMG_WEAPON4 > bestdamage) {best = IT_WEAPON4;bestdamage = DMG_WEAPON4;shotspeed = DMG_WEAPON2_VELOCITY;}
	if (self.items & IT_WEAPON5) if (self.ammo_nails   >= 1) if (dist >= DMG_WEAPON5_MINRANGE) if (dist < DMG_WEAPON5_RANGE) if (DMG_WEAPON5 > bestdamage) {best = IT_WEAPON5;bestdamage = DMG_WEAPON5;shotspeed = DMG_WEAPON2_VELOCITY;}
	if (self.items & IT_WEAPON6) if (self.ammo_rockets >= 1) if (dist >= DMG_WEAPON6_MINRANGE) if (dist < DMG_WEAPON6_RANGE) if (DMG_WEAPON6 > bestdamage) {best = IT_WEAPON6;bestdamage = DMG_WEAPON6;shotspeed = DMG_WEAPON2_VELOCITY;}
	if (self.items & IT_WEAPON7) if (self.ammo_rockets >= 1) if (dist >= DMG_WEAPON7_MINRANGE) if (dist < DMG_WEAPON7_RANGE) if (DMG_WEAPON7 > bestdamage) {best = IT_WEAPON7;bestdamage = DMG_WEAPON7;shotspeed = DMG_WEAPON2_VELOCITY;}
	if (self.items & IT_WEAPON8) if (self.ammo_cells   >= 1) if (dist >= DMG_WEAPON8_MINRANGE) if (dist < DMG_WEAPON8_RANGE) if (DMG_WEAPON8 > bestdamage) {best = IT_WEAPON8;bestdamage = DMG_WEAPON8;shotspeed = DMG_WEAPON2_VELOCITY;}
	if (self.items & IT_WEAPON9) if (self.ammo_cells   >= 1) if (dist >= DMG_WEAPON9_MINRANGE) if (dist < DMG_WEAPON9_RANGE) if (DMG_WEAPON9 > bestdamage) {best = IT_WEAPON9;bestdamage = DMG_WEAPON9;shotspeed = DMG_WEAPON2_VELOCITY;}
	self.switcheapon = best;
	if (shotspeed >= 10000)
		self.shotlead = 0; // instant weapon
	else
		self.shotlead = 1 / shotspeed;
	*/
	if (time > self.weaponchangetimeout || !setweapon(self.switchweapon, WR_SELECTABLE))
	{
		self.weaponchangetimeout = time + 0.5;
		self.switchweapon = W_BestWeaponForTarget(self.enemy); //W_BestWeapon(TRUE);
	}
};

.float nextaim;
void() havocbot_aim =
{
	local float f, aimlatency, latency, shotleadspeed;
	local vector v, selfvel, enemyvel;
	local string s;
	if (time < self.nextaim)
		return;
	self.nextaim = time + 0.1;
	aimlatency = (4 - skill) * 0.1 + random() * 0.05;
	self.ping = self.ping + (aimlatency - self.ping) * frametime * 3;
	aimlatency = self.ping;
	if (self.enemy != world)
	{
		/*
		self.nextaim = time + 0.1;
		if (self.enemy != self.oldenemy)
		{
			self.oldenemy = self.enemy;
			self.dest1 = self.dest2 = self.dest3 = self.enemy.origin;
		}
		else
		{
			// compute average velocity over .3 seconds based on origins (this is intentionally not .velocity)
			self.dest1 = self.dest2;
			self.dest2 = self.dest3;
			self.dest3 = self.enemy.origin;
		}
		vel = ((self.dest2 - self.dest1) + (self.dest3 - self.dest2)) * 5.0; // 0.5 / 0.1 = 5.0
		*/
		selfvel = self.velocity;
		if (!self.waterlevel)
			selfvel_z = 0;
		enemyvel = self.enemy.velocity;
		if (!self.enemy.waterlevel)
			enemyvel_z = 0;
		/*
		bprint("lag_additem(");
		s = ftos(time + aimlatency);
		bprint(s);
		bprint(", 0, 0, ");
		s = etos(self.enemy);
		bprint(s);
		bprint(", ");
		s = vtos(self.origin);
		bprint(s);
		bprint(", ");
		s = vtos(selfvel);
		bprint(s);
		bprint(", ");
		s = vtos(self.enemy.origin);
		bprint(s);
		bprint(", ");
		s = vtos(enemyvel);
		bprint(s);
		bprint(")\n");
		*/
		lag_additem(time + aimlatency, 0, 0, self.enemy, self.origin, selfvel, self.enemy.origin, enemyvel);

//		v = trace_endpos;
//		traceline(self.origin + '0 0 16', v, FALSE, self);
//		if (trace_fraction >= 1 || trace_ent == self.enemy)
//			lag_additem(time + aimlatency, 0, 0, self.enemy, v, '0 0 0', '0 0 0', '0 0 0');
//		else
//			lag_additem(time + aimlatency, 0, 0, self.enemy, '0 0 0', '0 0 0', '0 0 0', '0 0 0');
	}
	else
		lag_additem(time + aimlatency, 0, 0, world, '0 0 0', '0 0 0', '0 0 0', '0 0 0');
};

.entity aimtarg;
.vector aimselforigin;
.vector aimselfvelocity;
.vector aimtargorigin;
.vector aimtargvelocity;
void(float t, float f1, float f2, entity e1, vector v1, vector v2, vector v3, vector v4) havocbot_lagfunc =
{
	local string s;
	self.aimtarg = e1;
	self.aimselforigin = v1;
	self.aimselfvelocity = v2;
	self.aimtargorigin = v3;
	self.aimtargvelocity = v4;
	/*
	bprint("havocbot_lagfunc(");
	s = ftos(t);
	bprint(s);
	bprint(", ");
	s = ftos(f1);
	bprint(s);
	bprint(", ");
	s = ftos(f2);
	bprint(s);
	bprint(", ");
	s = etos(e1);
	bprint(s);
	bprint(", ");
	s = vtos(v1);
	bprint(s);
	bprint(", ");
	s = vtos(v2);
	bprint(s);
	bprint(", ");
	s = vtos(v3);
	bprint(s);
	bprint(", ");
	s = vtos(v4);
	bprint(s);
	bprint(")\n");
	*/
	/*

	self.lefty = 0;
	if (fl)
	{
		//if (!setweapon(fl, WR_SELECTABLE))
		//	return; // don't have the weapon??
		//self.switchweapon = fl;
		if (self.weapon == fl)
		if (self.wstate == WS_ACTIVE)
			self.lefty = 1;
	}
	else if (self.goalcurrent != world)
		self.dest = self.goalcurrent.origin;
	*/
};

.float painintensity;
void() havocbot_doaim =
{
	local vector ang, angdiff, originalangdiff, selfvel, selforigin, targvel, targorigin, v, aimdir;
	local float angdistance, fire, aimlatency, latency, shotleadspeed, pain;
	local entity targ, saveenemy;
	local string s;

	fire = FALSE;
	targ = self.aimtarg;
	if (self.goalcurrent.origin)
		aimdir = self.goalcurrent.origin - self.origin;
	else
	{
		makevectors(self.v_angle);
		aimdir = v_forward;
	}
	if (targ != world)
	if (targ.takedamage)
	{
		if (time > self.weaponchangetimeout || !setweapon(self.weapon, WR_SELECTABLE))
		{
			self.weaponchangetimeout = time + 0.5;
			self.switchweapon = W_BestWeaponForTarget(targ); //W_BestWeapon(TRUE);
		}
		selforigin = self.aimselforigin + self.aimselfvelocity * aimlatency;
		targorigin = self.aimtargorigin + self.aimtargvelocity * aimlatency;
		if (self.weapon == IT_WEAPON6) shotleadspeed = 600;
		else if (self.weapon == IT_WEAPON7) shotleadspeed = 5000;
		else if (self.weapon == IT_WEAPON8) shotleadspeed = 5000;
		else shotleadspeed = 5000;
		latency = vlen(targorigin - selforigin) / shotleadspeed;
		v = targorigin + self.aimtargvelocity * latency - self.aimselfvelocity * latency;
		tracebox(self.aimtargorigin, targ.mins, targ.maxs, v, FALSE, targ);
		aimdir = trace_endpos - self.origin - '0 0 16';
		if (self.weapon == self.switchweapon && self.wstate == WS_ACTIVE)
		{
			saveenemy = self.enemy;
			self.enemy = targ;
			weaponaimtarget = trace_endpos;
			/*
			bprint("havocbot_doaim(");
			s = etos(self.aimtarg);
			bprint(s);
			bprint(", ");
			s = vtos(self.aimselforigin);
			bprint(s);
			bprint(", ");
			s = vtos(self.aimselfvelocity);
			bprint(s);
			bprint(", ");
			s = vtos(self.aimtargorigin);
			bprint(s);
			bprint(", ");
			s = vtos(self.aimtargvelocity);
			bprint(s);
			bprint(")\nselforigin ");
			s = vtos(selforigin);
			bprint(s);
			bprint(", targorigin ");
			s = vtos(targorigin);
			bprint(s);
			bprint(", aimdir ");
			s = vtos(aimdir);
			bprint(s);
			bprint(")\n");
			*/
			if (setweapon(self.weapon, WR_AIM))
			{
				if ((cvar("temp1") & 512) == 0)
					self.button0 = 1;
				/*
				bprint("weaponaimdir ");
				s = vtos(weaponaimdir);
				bprint(s);
				bprint("\n");
				*/
				aimdir = weaponaimdir;
			}
			self.enemy = saveenemy;
		}
	}

	ang = vectoangles(aimdir);

	// change to v_angle format
	ang_x = 0 - ang_x;
	ang_z = 0;
	// a little chaos to reduce sniping accuracy in the distnace
//	ang = ang + randomvec();

	// add in shaking from pain
	pain = self.painintensity * 0.2;
	if (pain > 15)
		pain = 15;
	if (pain)
		ang = ang + randomvec() * pain;

	// this code makes it turn gradually, not instantly

	// calculate the angle difference (taking into consideration yaw wrapping)
	angdiff = ang - self.v_angle;
	while (angdiff_y >= 180)
		angdiff_y = angdiff_y - 360;
	while (angdiff_y < -180)
		angdiff_y = angdiff_y + 360;

	// give it a bit of randomness to simulate pretty good but not perfect tracking
	originalangdiff = angdiff;
	angdistance = vlen(angdiff);
	angdiff = (((angdiff * (random() * 0.4 + 0.8)) + (randomvec() * (angdistance * 0.1))) - originalangdiff) * ((3.5 - skill) * 0.5) + originalangdiff;

	// don't fire if shot would be too inaccurate
	if (angdistance > 270 * frametime)
		self.button0 = 0;

	// limit maximum turning speed
	if (vlen(angdiff) > 720 * frametime)
		angdiff = normalize(angdiff) * 720 * frametime;

	// apply change
	self.v_angle = self.v_angle + angdiff;

	angdiff = ang - self.v_angle;
	while (angdiff_y >= 180)
		angdiff_y = angdiff_y - 360;
	while (angdiff_y < -180)
		angdiff_y = angdiff_y + 360;
	angdistance = vlen(angdiff);
	if (angdistance > 10)
		self.button0 = 0;

	// compute model angles
	self.angles = self.v_angle_y * '0 1 0';
};

.float  respawntime;
.float nextgoalcheck;
.float oldhealth;
void() havocbot_think =
{
	local vector dodge;
	self.button0 = 0;
	self.button1 = 0;
	self.button2 = 0;
	if (self.deadflag)
	{
		if (time > self.respawntime)
		if (self.deadflag == DEAD_RESPAWNABLE)
			self.button0 = 1;
		return;
	}
	else
		self.respawntime = time + 1;
//	if (self.flags & FL_ONGROUND)
//		self.velocity = '0 0 0';
	self.havocbot_role();
	dodge = havocbot_dodge();
	havocbot_movetogoal(dodge);
	if (cvar("temp1") & 1024)
		self.enemy = world;
	else
		havocbot_chooseenemy();
	havocbot_chooseweapon();
	havocbot_aim();
	lag_update();
	havocbot_doaim();

	if (self.painintensity > 0)
		self.painintensity = self.painintensity - (skill * 40 + 40) * frametime;

	if (self.health < self.oldhealth)
		self.painintensity = self.painintensity + self.oldhealth - self.health;
	else if (self.health > self.oldhealth)
		self.painintensity = 0;
	self.oldhealth = self.health;
};

void(entity e) waypointspawnforitem =
{
	local entity head;
	local vector org;
	org = (e.absmin + e.absmax) * 0.5;
	// find any waypoints touching this item, if any are found, don't spawn a new one
	head = findradius(org, 0);
	while(head)
	{
		if (head.classname == "waypoint")
			return;
		head = head.chain;
	}
	waypointspawn(org, 0);
};
void(vector org, float f) waypointspawn = {waypointsetup(world, org, f);};

void() havocbot_dumpwaypoints =
{
	local entity head;
	local string s;
	head = findchain(classname, "waypoint");
	sprint(self, "// waypoints for ");
	sprint(self, world.model);
	sprint(self, "\nvoid() waypoints_ = \n{\n");
	while (head)
	{
		sprint(self, "        waypointspawn('");
		s = vtos(head.origin);sprint(self, s);
		sprint(self, "', ");
		s = ftos(head.spawnflags);sprint(self, s);
		sprint(self, ");\n");
		head = head.chain;
	}
};

void() havocbot_makewaypoint = {waypointspawn(self.origin, 0);};
void() havocbot_killwaypoint =
{
	local   entity  head, best;
	local   float   bestdist;
	bestdist = 256; // max distance
	head = findchain(classname, "waypoint");
	while (head)
	{
		if (vlen(head.origin - self.origin) < bestdist)
		{
			best = head;
			bestdist = vlen(head.origin - self.origin);
		}
		head = head.chain;
	}
	if (best)
		remove(best);
};

void() havocbot_impulses =
{
	// disabled havocbots
	if (cvar("temp1") & 512) // waypoint editing mode
	{
			 if (self.impulse == 110) {havocbot_makewaypoint();self.impulse = 0;}
		else if (self.impulse == 111) {havocbot_killwaypoint();self.impulse = 0;}
		else if (self.impulse == 118) {waypoint_relinkall();self.impulse = 0;}
		else if (self.impulse == 119) {havocbot_dumpwaypoints();self.impulse = 0;}
	}

	     if (self.impulse == 101) {havocbot_add(1);self.impulse = 0;}
	else if (self.impulse == 102) {havocbot_remove(1);self.impulse = 0;}
};

/*
void() waybox_enlargebox =
{
	local vector m1, m2, org1, org2;
	local float c;
	m1 = self.mins;
	m2 = self.maxs;
	if (m1 == m2)
	{
		// first time
		self.dest = org1 = m1;
		traceline(org1, org1 + '0 0 -65536', TRUE, world);
		self.dest2 = trace_plane_normal;
		self.dmg = trace_plane_dist;
		traceline(org1, org1 + '-65536 0 0', TRUE, world);m1_x = trace_endpos_x;
		traceline(org1, org1 + '65536 0 0', TRUE, world);m2_x = trace_endpos_x;
		traceline(org1, org1 + '0 -65536 0', TRUE, world);m1_y = trace_endpos_y;
		traceline(org1, org1 + '0 65536 0', TRUE, world);m2_y = trace_endpos_y;
		traceline(org1, org1 + '0 0 -65536', TRUE, world);m1_z = trace_endpos_z;
		traceline(org1, org1 + '0 0 65536', TRUE, world);m2_z = trace_endpos_z;
	}
	c = 0;
	while (c < 10)
	{
		c = c + 1;
		org1 = org2 = randompos(m1, m2);
		org1_x = m2_x;
		org2_x = m1_x;
		traceline(org1, org2, TRUE, world);
		m1_x = trace_endpos_x;
		org1 = org2 = randompos(m1, m2);
		org1_x = m1_x;
		org2_x = m2_x;
		traceline(org1, org2, TRUE, world);
		m2_x = trace_endpos_x;

		org1 = org2 = randompos(m1, m2);
		org1_y = m2_y;
		org2_y = m1_y;
		traceline(org1, org2, TRUE, world);
		m1_y = trace_endpos_y;
		org1 = org2 = randompos(m1, m2);
		org1_y = m1_y;
		org2_y = m2_y;
		traceline(org1, org2, TRUE, world);
		m2_y = trace_endpos_y;
	}

	c = 0;
	while (c < 30)
	{
		org1 = randompos(m1, m2);
		org1_z = org1_x * slope_zx + org1_y * slope_zy + slope_basez;
		org1_
		traceline(org1, org1 + '0 0 -'
		org2_z =
		org1_z = m2_z;
		org2_z = m1_z;
		traceline(org1, org2, TRUE, world);
		m1_z = trace_endpos_z;
		org1 = org2 = randompos(m1, m2);
		org1_z = m1_z;
		org2_z = m2_z;
		traceline(org1, org2, TRUE, world);
		m2_z = trace_endpos_z;
	}
	setsize(self, m1, m2);
};
*/

void() waysurface_setupthink =
{
	local float c;
	local vector org, m1, m2;
	self.nextthink = time + 0.1;
	org = randompos(self.mins, self.maxs);
	org_z = org_x * self.dest5_x + org_y * self.dest5_y + self.dest5_z;
	particle(org, '0 0 0', 104, 4);
	if (time < self.cnt)
	{
		m1 = self.mins;
		m2 = self.maxs;
		c = 0;
		while (c < 50)
		{
			c = c + 1;
			org = randompos(m1 + '-16 -16 -16', m2 + '16 16 16');
			if (org_x < m1_x || org_x > m2_x || org_y < m1_y || org_y > m2_y)
			{
				org_z = org_x * self.dest5_x + org_y * self.dest5_y + self.dest5_z;
				traceline(self.dest1, org, TRUE, world);
				if (trace_fraction == 1)
				{
					traceline(org, org + '0 0 -4', TRUE, world);
					if (trace_fraction < 1)
					if (trace_plane_dist == self.dmg)
					if (trace_plane_normal == self.dest2)
					{
						particle(org, '0 0 0', 140, 4);
						if (m1_x > org_x) m1_x = org_x;if (m2_x < org_x) m2_x = org_x;
						if (m1_y > org_y) m1_y = org_y;if (m2_y < org_y) m2_y = org_y;
						if (m1_z > org_z) m1_z = org_z;if (m2_z < org_z) m2_z = org_z;
					}
				}
			}
		}
		if (m1 != self.mins || m2 != self.maxs)
			setsize(self, m1, m2);
	}
};

void(vector org, vector normal, float dist, float fl) havocbot_spawnwaysurface =
{
	newmis = spawn();
	newmis.classname = "waysurface";
	newmis.think = waysurface_setupthink;
	newmis.nextthink = time;
	newmis.cnt = time + 5;
	newmis.dest1 = org + '0 0 1';
	newmis.dest2 = normal;
	newmis.dmg = dist;
	// test 1 unit above so it doesn't start inside the surface
	newmis.dest5_x = normal_x / normal_z;
	newmis.dest5_y = normal_y / normal_z;
	newmis.dest5_z = newmis.dest1_z - (newmis.dest1_x * newmis.dest5_x + newmis.dest1_y * newmis.dest5_y);
	bprint("org ");
	bprintvector(newmis.dest1);
	bprint(" normal ");
	bprintvector(newmis.dest2);
	bprint(" dist ");
	bprintfloat(newmis.dmg);
	bprint(" slope ");
	bprintvector(newmis.dest5);
	bprint("\n");
	// start out as just a point
	setsize(newmis, org, org);
};

.float nextlaywaypoint;
void() havoc_laywaypoints =
{
	local entity head;
	local vector org;
	if (!deathmatch && !coop)
		return;
	if (!(self.flags & FL_CLIENT))
		return;
	if (!(self.flags & FL_ONGROUND))
		return;
	if (time < self.nextlaywaypoint)
		return;
	self.nextlaywaypoint = time + 0.1; //2 + random() * 0.3;
	/*
	traceline(self.origin + '0 0 -23', self.origin + '0 0 -40', FALSE, self);
	if (trace_fraction >= 1)
		return;
	head = findchain(classname, "waypoint");
	while(head)
	{
		if (vlen(head.origin - self.origin) < 192)
		if (tracewalk(self, self.origin, head.origin))
			return;
		head = head.chain;
	}
	havocbot_makewaypoint();
	*/
	org = self.origin + self.mins_z * '0 0 1';
	traceline(org, org + '0 0 -100', TRUE, world);
	if (trace_fraction < 1)
	{
		head = findchain(classname, "waysurface");
		while (head)
		{
			if (self.absmax_x > head.mins_x)
			if (self.absmin_x < head.maxs_x)
			if (self.absmax_y > head.mins_y)
			if (self.absmin_y < head.maxs_y)
			//if (self.absmax_z > head.mins_z)
			//if (self.absmin_z < head.maxs_z)
			if (trace_plane_normal == head.dest2)
			if (trace_plane_dist == head.dmg)
				break;
			head = head.chain;
		}
		if (!head)
		{
			// if it found no surface, spawn a new one
			havocbot_spawnwaysurface(trace_endpos, trace_plane_normal, trace_plane_dist, 0);
		}
	}
};

entity dangerwaypoint;
void() havocbot_updatedangerousobjects =
{
	local entity head;
	local float c, d, danger;
	c = 0;
	dangerwaypoint = find(dangerwaypoint, classname, "waypoint");
	while (dangerwaypoint != world && c < 16)
	{
		c = c + 1;
		danger = 0;
		head = findchainfloat(shoulddodge, TRUE);
		while (head)
		{
			d = head.dangerrating - vlen(head.origin - self.origin);
			if (d > 0)
			{
				traceline(head.origin, self.origin, TRUE, world);
				if (trace_fraction == 1)
					danger = danger + d;
			}
			head = head.chain;
		}
		dangerwaypoint.dmg = danger;
		dangerwaypoint = find(dangerwaypoint, classname, "waypoint");
	}
};
