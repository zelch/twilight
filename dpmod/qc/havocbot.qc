
/*
itemscore = (howmuchmoreIwant / howmuchIcanwant) / itemdistance
waypointscore = 0.7 / waypointdistance
*/

void(vector o, float f) waypointspawn =
{
	return;
};

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

float havoccurrentbots;
float havocbots;
entity havocbot_list;
.entity nextbot;

void() havocbot_relinkbotlist =
{
	local entity e;
	havocbot_list = e = findchainfloat(isbot, TRUE);
	while (e)
	{
		e.nextbot = e.chain;
		e = e.chain;
	}
};

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
	// only 32 names available
	if (havoccurrentbots >= 32)
		return;
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
	havocbot_relinkbotlist();
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
	havocbot_relinkbotlist();
};

void() havocbot_think;
void() havocbot_updatedangerousobjects;
void() havocbot_findentsandspawnwaysurfaces;

void() havocbot_serverframe =
{
	local entity head, saveself;
	if (intermission_running)
		return;

	if (havocbot_list)
	{
		maxspeed = cvar("sv_maxspeed"); // player movement speed
		sv_accelerate = cvar("sv_accelerate"); // 10 normally
		havocbot_findentsandspawnwaysurfaces();

		havocbot_updatedangerousobjects();
		saveself = self;
		head = havocbot_list;
		while (head)
		{
			self = head;
			havocbot_think();
			PlayerPreThink();
			PlayerPostThink();
			head = head.nextbot;
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
	if (!coop && !deathmatch)
	{
		sprint(self, "Sorry, can't spawn bots in singleplayer, please set deathmatch 1 first.\n");
		return;
	}
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

float(entity from, entity to) waysurface_addlink =
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

/*
float(entity from, entity to) waysurface_removelink =
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
*/

float() waysurface_link =
{
	local entity e;
	local float d;
	local vector m1, m2;

	m1 = self.mins + '-1 -1 -9';
	m2 = self.maxs + '1 1 9';
	d = 0;
	e = self.oldenemy;
	while (d < 200)
	{
		d = d + 1;
		e = find(e, classname, "waysurface");
		if (e == world)
		{
			//self.nextthink = 0;
			return FALSE;
		}
		if (m1_x < e.maxs_x)
		if (m2_x > e.mins_x)
		if (m1_y < e.maxs_y)
		if (m2_y > e.mins_y)
		if (m1_z < e.maxs_z)
		if (m2_z > e.mins_z)
		{
			waysurface_addlink(self, e);
			waysurface_addlink(e, self);
		}
	}
	self.oldenemy = e;
	return TRUE;
};

/*
void() waysurface_relinkall =
{
	local entity head;
	head = findchain(classname, "waysurface");
	while (head)
	{
		head.enemy = world;
		head.owner = world;
		head.wp0 = head.wp1 = head.wp2 = head.wp3 = head.wp4 = head.wp5 = head.wp6 = head.wp7 = world;
		head.wp8 = head.wp9 = head.wp10 = head.wp11 = head.wp12 = head.wp13 = head.wp14 = head.wp15 = world;
		head.wp16 = head.wp17 = head.wp18 = head.wp19 = head.wp20 = head.wp21 = head.wp22 = head.wp23 = world;
		head.wp24 = head.wp25 = head.wp26 = head.wp27 = head.wp28 = head.wp29 = head.wp30 = head.wp31 = world;
		head.wpcost0 = head.wpcost1 = head.wpcost2 = head.wpcost3 = head.wpcost4 = head.wpcost5 = head.wpcost6 = head.wpcost7 = 0;
		head.wpcost8 = head.wpcost9 = head.wpcost10 = head.wpcost11 = head.wpcost12 = head.wpcost13 = head.wpcost14 = head.wpcost15 = 0;
		head.wpcost16 = head.wpcost17 = head.wpcost18 = head.wpcost19 = head.wpcost20 = head.wpcost21 = head.wpcost22 = head.wpcost23 = 0;
		head.wpcost24 = head.wpcost25 = head.wpcost26 = head.wpcost27 = head.wpcost28 = head.wpcost29 = head.wpcost30 = head.wpcost31 = 0;
		head.think = waysurface_link;
		head.nextthink = time + 0.1;
		head = head.chain;
	}
};
*/

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

.entity nearestwaysurface;
.vector nearestwaysurfaceorigin;
.float nearestwaysurfacetimeout;

entity(vector org, vector m1, vector m2) findwaysurface;
void(entity e) havocbot_spawnwaysurfaces;

entity(entity e) findnearestwaysurface =
{
	local vector org;
	if (e.origin != e.nearestwaysurfaceorigin || time > e.nearestwaysurfacetimeout)
	{
		org = e.origin + (e.mins + e.maxs) * 0.5;
		org_z = e.origin_z + e.mins_z + 1;
		e.nearestwaysurface = findwaysurface(org, e.origin + e.mins, e.origin + e.maxs);
		e.nearestwaysurfaceorigin = e.origin;
		e.nearestwaysurfacetimeout = time + random() * 3 + 5;
		return e.nearestwaysurface;
	}
	return e.nearestwaysurface;
};

float timediff;
.float wpfire, wpcost;

void(entity head, entity w) havocbot_checkwaysurface =
{
	local vector o, m1, m2;
	local float cost;
	cost = head.wpcost + head.dmg;
	if(cost < w.wpcost)
	{
		o = head.dest - w.owner.origin;
		m1 = w.mins;m2 = w.maxs;
		if (o_x < m1_x) o_x = m1_x;if (o_x > m2_x) o_x = m2_x;
		if (o_y < m1_y) o_y = m1_y;if (o_y > m2_y) o_y = m2_y;
		//if (o_z < m1_z) o_z = m1_z;if (o_z > m2_z) o_z = m2_z;
		//o = getsurfaceclippedpoint(w.owner, w.dmg2, head.dest - w.owner.origin);
		o_z = o_x * w.dest5_x + o_y * w.dest5_y + w.dest5_z;
		cost = cost + vlen(o + w.owner.origin - head.dest);
		if(cost < w.wpcost)
		{
			//te_smallflash(o);
			w.dest = o;
			w.wpcost = cost;
			w.enemy = head;
			w.wpfire = 1;
		}
	}
}

void() markroutes =
{
	local entity start, head, w;
	local vector o, m1, m2;
	local float d, dist, cost, c;
	w = findwaysurface(self.origin, self.absmin, self.absmax);
	if (w == world)
		return;
	//te_smallflash(self.origin);
	head = findchain(classname, "waysurface");
	while (head)
	{
		head.dest = '0 0 0';
		head.wpcost = 10000000;
		head.wpfire = 0;
		head.enemy = world;
		head = head.chain;
	}
	w.dest = self.origin;
	w.dest_z = self.dest_x * w.dest5_x + self.dest_y * w.dest5_y + w.dest5_z;
	w.wpcost = vlen(w.dest - self.origin) + w.dmg;
	w.wpfire = 1;
	//w.enemy = world;
	//c = 0;
	while (1)
	{
		head = findchainfloat(wpfire, 1);
		if (head == world)
		{
			//bprintfloat(c);
			//bprint("\n");
			return;
		}
		while (head)
		{
			//c = c + 1;
			//te_smallflash(head.dest);
			head.wpfire = 0;
			w = head.wp0;if(w){havocbot_checkwaysurface(head, w);
			w = head.wp1;if(w){havocbot_checkwaysurface(head, w);
			w = head.wp2;if(w){havocbot_checkwaysurface(head, w);
			w = head.wp3;if(w){havocbot_checkwaysurface(head, w);
			w = head.wp4;if(w){havocbot_checkwaysurface(head, w);
			w = head.wp5;if(w){havocbot_checkwaysurface(head, w);
			w = head.wp6;if(w){havocbot_checkwaysurface(head, w);
			w = head.wp7;if(w){havocbot_checkwaysurface(head, w);
			w = head.wp8;if(w){havocbot_checkwaysurface(head, w);
			w = head.wp9;if(w){havocbot_checkwaysurface(head, w);
			w = head.wp10;if(w){havocbot_checkwaysurface(head, w);
			w = head.wp11;if(w){havocbot_checkwaysurface(head, w);
			w = head.wp12;if(w){havocbot_checkwaysurface(head, w);
			w = head.wp13;if(w){havocbot_checkwaysurface(head, w);
			w = head.wp14;if(w){havocbot_checkwaysurface(head, w);
			w = head.wp15;if(w){havocbot_checkwaysurface(head, w);
			w = head.wp16;if(w){havocbot_checkwaysurface(head, w);
			w = head.wp17;if(w){havocbot_checkwaysurface(head, w);
			w = head.wp18;if(w){havocbot_checkwaysurface(head, w);
			w = head.wp19;if(w){havocbot_checkwaysurface(head, w);
			w = head.wp20;if(w){havocbot_checkwaysurface(head, w);
			w = head.wp21;if(w){havocbot_checkwaysurface(head, w);
			w = head.wp22;if(w){havocbot_checkwaysurface(head, w);
			w = head.wp23;if(w){havocbot_checkwaysurface(head, w);
			w = head.wp24;if(w){havocbot_checkwaysurface(head, w);
			w = head.wp25;if(w){havocbot_checkwaysurface(head, w);
			w = head.wp26;if(w){havocbot_checkwaysurface(head, w);
			w = head.wp27;if(w){havocbot_checkwaysurface(head, w);
			w = head.wp28;if(w){havocbot_checkwaysurface(head, w);
			w = head.wp29;if(w){havocbot_checkwaysurface(head, w);
			w = head.wp30;if(w){havocbot_checkwaysurface(head, w);
			w = head.wp31;if(w){havocbot_checkwaysurface(head, w);
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
	w = findnearestwaysurface(e);
	if (w)
	{
		f = f / ((w.wpcost + vlen(e.origin - w.dest)) * 0.001 + 1);
		if (havocbot_bestrating < f)
		{
			havocbot_bestrating = f;
			havocbot_bestgoal = e;
		}
	}
};

void(entity e) routetogoal =
{
	clearroute();
	self.goalentity = e;
	if (e == world)
		return;
	/*
	te_smallflash((e.absmin + e.absmax) * 0.5);
	bprint("routetogoal(");
	bprint(etos(e));
	bprint(") : ");
	bprint(etos(e));
	*/
	pushroute(e);
	if (tracewalk(self, self.origin, e.origin))
	{
		//bprint("\n");
		return;
	}
	e = findnearestwaysurface(e);
	while (e != world)
	{
		/*
		bprint(" ");
		bprint(etos(e));
		te_smallflash((e.absmin + e.absmax) * 0.5);
		*/
		pushroute(e);
		e = e.enemy;
	}
	//bprint("\n");
};

void() havocbot_popgoals =
{
	local vector org, m1, m2;
	local float s;
	org = self.origin + self.velocity * 0.2;
	m1 = org + self.mins;
	m2 = org + self.maxs;
	s = TRUE;
	while (s)
	{
		s = FALSE;
		if (self.goalcurrent.classname == "waysurface")
		{
			if (m2_x > self.goalcurrent.mins_x)
			if (m1_x < self.goalcurrent.maxs_x)
			if (m2_y > self.goalcurrent.mins_y)
			if (m1_y < self.goalcurrent.maxs_y)
			if (org_z + self.mins_z + 2 > org_x * self.goalcurrent.dest5_x + org_y * self.goalcurrent.dest5_y + self.goalcurrent.dest5_z)
			{
				poproute();
				if (self.goalcurrent == world)
					return;
				s = TRUE;
				continue;
			}
		}
		else
		{
			if (m2_x > self.goalcurrent.mins_x)
			if (m1_x < self.goalcurrent.maxs_x)
			if (m2_y > self.goalcurrent.mins_y)
			if (m1_y < self.goalcurrent.maxs_y)
			if (m2_z > self.goalcurrent.mins_z)
			if (m1_z < self.goalcurrent.maxs_z)
			{
				poproute();
				if (self.goalcurrent == world)
					return;
				s = TRUE;
				continue;
			}
		}
		/*
		// check for tempgoals that died
		if (!self.goalcurrent.classname && self.goalcurrent != self.goalentity)
		{
			poproute();
			if (self.goalcurrent == world)
				return;
			s = TRUE;
		}
		*/
	}
}

.float havocbotignoretime;
void(vector dodge) havocbot_movetogoal =
{
	local vector destorg, diff, dir, vel, flatdir, move, end, m1, m2, m3, m4, org, evadeobstacle, evadelava;
	local float s, dist, c;
	local entity head;
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
	if (self.waterlevel)
	{
		diff = destorg - self.origin;
		dist = vlen(diff);
		dir = normalize(diff);
	}
	else
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

		traceline(self.origin + self.velocity * 0.2, self.origin + self.velocity * 0.2 + '0 0 -1000', TRUE, world);
		s = pointcontents(trace_endpos + '0 0 1');
		if (s == CONTENT_LAVA || s == CONTENT_SLIME)
			evadelava = normalize(self.velocity) * -1;

		head = self.goalcurrent;
		if (self.goalcurrent.classname == "waysurface")
		{
			destorg = getsurfaceclippedpoint(head.owner, head.dmg2, self.origin);
			destorg_z = destorg_x * head.dest5_x + destorg_y * head.dest5_y + head.dest5_z;
			org_x = destorg_x + (random() * self.size_x) + self.mins_x;
			org_y = destorg_y + (random() * self.size_y) + self.mins_y;
			org_z = org_x * head.dest5_x + org_y * head.dest5_y + head.dest5_z;
			traceline(self.origin + org - destorg, org, FALSE, self);
			if (trace_fraction < 1)
			if (trace_plane_normal != head.dest2)
			if (trace_plane_dist != head.count)
				evadeobstacle = normalize(org - destorg) * -0.5;
			/*
			traceline(org_x - destorg)
			traceline(self.origin, self.mins, self.maxs, destorg + '0 0 1' * self.mins_z, FALSE, self);
			if (trace_fraction < 1)
			{
				// can't directly walk to the nearest point on the surface
				// so choose a random location on the surface
				c = 0;
				while (c < 20)
				{
					org_x = head.mins_x + random() * (head.maxs_x - head.mins_x);
					org_y = head.mins_x + random() * (head.maxs_x - head.mins_x);
					org_z = org_x * head.dest5_x + org_y * head.dest5_y + head.dest5_z;
					destorg = getsurfaceclippedpoint(head.owner, head.dmg2, org);
					destorg_z = destorg_x * head.dest5_x + destorg_y * head.dest5_y + head.dest5_z;
					traceline(self.origin, destorg, FALSE, self);
					if (trace_fraction == 1 || trace_ent == head)
						break;
					c = c + 1;
				}
				if (c >= 20)
					return;
			}
			*/
		}
		else
		{
			m1 = head.origin + head.mins;
			m2 = head.origin + head.maxs;
			destorg = self.origin;
			if (destorg_x < m1_x) destorg_x = m1_x;if (destorg_x > m2_x) destorg_x = m2_x;
			if (destorg_y < m1_y) destorg_y = m1_y;if (destorg_y > m2_y) destorg_y = m2_y;
			if (destorg_z < m1_z) destorg_z = m1_z;if (destorg_z > m2_z) destorg_z = m2_z;
		}
		/*
		org = self.origin;
		m1 = self.origin;
		m2 = self.origin;
		traceline(org, org + '0 0 -100', TRUE, world);
		if (trace_fraction < 1)
		{
			head = findchain(classname, "waysurface");
			while (head)
			{
				if (org_x > head.mins_x)
				if (org_x < head.maxs_x)
				if (org_y > head.mins_y)
				if (org_y < head.maxs_y)
				//if (org_z > head.mins_z)
				//if (org_z < head.maxs_z)
				if (trace_plane_normal == head.dest2)
				if (trace_plane_dist == head.count)
				{
					if (m1_x > head.mins_x) m1_x = head.mins_x;if (m2_x < head.maxs_x) m2_x = head.maxs_x;
					if (m1_y > head.mins_y) m1_y = head.mins_y;if (m2_y < head.maxs_y) m2_y = head.maxs_y;
					if (m1_z > head.mins_z) m1_z = head.mins_z;if (m2_z < head.maxs_z) m2_z = head.maxs_z;
				}
				head = head.chain;
			}
		}
		m3 = self.goalcurrent.origin + self.goalcurrent.mins;
		m4 = self.goalcurrent.origin + self.goalcurrent.maxs;
		if (m1_x < m3_x) m1_x = m3_x;if (m1_x > m4_x) m1_x = m4_x;
		if (m1_y < m3_y) m1_y = m3_y;if (m1_y > m4_y) m1_y = m4_y;
		if (m1_z < m3_z) m1_z = m3_z;if (m1_z > m4_z) m1_z = m4_z;
		if (m2_x < m3_x) m2_x = m3_x;if (m2_x > m4_x) m2_x = m4_x;
		if (m2_y < m3_y) m2_y = m3_y;if (m2_y > m4_y) m2_y = m4_y;
		if (m2_z < m3_z) m2_z = m3_z;if (m2_z > m4_z) m2_z = m4_z;
		destorg = self.origin;
		if (destorg_x < m1_x) destorg_x = m1_x;if (destorg_x > m2_x) destorg_x = m2_x;
		if (destorg_y < m1_y) destorg_y = m1_y;if (destorg_y > m2_y) destorg_y = m2_y;
		if (destorg_z < m1_z) destorg_z = m1_z;if (destorg_z > m2_z) destorg_z = m2_z;
		traceline(self.origin, destorg, FALSE, self);
		if (trace_fraction < 1 && trace_ent != self.goalcurrent)
		{
			if (self.goalcurrent.classname == "waysurface")
			{
				s = 0;
				while (s < 40)
				{
					s = s + 1;
					destorg = randompos(m1, m2);
					destorg_z = destorg_x * self.goalcurrent.dest5_x + destorg_y * self.goalcurrent.dest5_y + self.goalcurrent.dest5_z;
					traceline(destorg, destorg + '0 0 -4', TRUE, world);
					if (trace_fraction < 1)
					if (trace_plane_dist == self.goalcurrent.count)
					if (trace_plane_normal == self.goalcurrent.dest2)
					{
						traceline(self.origin, destorg, FALSE, self);
						if (trace_fraction == 1)
						{
							newmis = spawn();
							newmis.classname = "tempgoal";
							newmis.owner = self;
							newmis.think = SUB_Remove;
							newmis.nextthink = time + 0.5;
							setorigin(newmis, destorg);
							pushroute(newmis);
							break;
						}
					}
				}
			}
			else
			{
				s = 0;
				while (s < 40)
				{
					s = s + 1;
					destorg = randompos(m1, m2);
					traceline(self.origin, destorg, FALSE, self);
					if (trace_fraction == 1 || trace_ent == self.goalcurrent)
					{
						newmis = spawn();
						newmis.classname = "tempgoal";
						newmis.owner = self;
						newmis.think = SUB_Remove;
						newmis.nextthink = time + 0.5;
						setorigin(newmis, destorg);
						pushroute(newmis);
						break;
					}
				}
			}
			if (s >= 40)
			{
				clearroute();
				return;
			}
		}
		*/
		//te_lightning2(self, self.origin, destorg);

		diff = destorg - self.origin;
		dist = vlen(diff);
		dir = normalize(diff);
		flatdir = diff;flatdir_z = 0;
		flatdir = normalize(flatdir);
		dir = flatdir;
	}
	dir = normalize(dir + dodge + evadeobstacle + evadelava);
	dir = dir * 400;// - (self.velocity - dir * (self.velocity * dir));
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
		if (head.takedamage == DAMAGE_AIM)
		if (head != self)
		if (!head.deadflag)
		if (head.health < besthealth)
		if (head.classname != "player" || !coop)
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
	self.switchweapon = W_BestWeapon(TRUE);
};

.float nextaim;
void() havocbot_aim =
{
	local float aimlatency;
	local vector selfvel, enemyvel;
	local string s;
	if (time < self.nextaim)
		return;
	self.nextaim = time + 0.1;
	aimlatency = (4 - skill) * 0.1 + random() * 0.05;
	self.ping = self.ping + (aimlatency - self.ping) * frametime * 3;
	aimlatency = self.ping;
	if (self.enemy != world)
	{
		selfvel = self.velocity;
		if (!self.waterlevel)
			selfvel_z = 0;
		enemyvel = self.enemy.velocity;
		if (!self.enemy.waterlevel)
			enemyvel_z = 0;
		lag_additem(time + aimlatency, 0, 0, self.enemy, self.origin, selfvel, self.enemy.origin, enemyvel);
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
	self.aimtarg = e1;
	self.aimselforigin = v1;
	self.aimselfvelocity = v2;
	self.aimtargorigin = v3;
	self.aimtargvelocity = v4;
};

.float painintensity;
void() havocbot_doaim =
{
	local vector ang, angdiff, originalangdiff, selfvel, selforigin, targvel, targorigin, v, aimdir;
	local float angdistance, fire, aimlatency, latency, shotleadspeed, pain;
	local entity targ, saveenemy;
	//local string s;

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
		/*
		if (time > self.weaponchangetimeout || !setweapon(self.weapon, WR_SELECTABLE))
		{
			self.weaponchangetimeout = time + 0.5;
			self.switchweapon = W_BestWeaponForTarget(targ); //W_BestWeapon(TRUE);
		}
		*/
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
	if (cvar("temp1") & 1024)
		self.enemy = world;
	else
		havocbot_chooseenemy();
	havocbot_chooseweapon();
	havocbot_aim();
	lag_update();
	havocbot_doaim();
	dodge = havocbot_dodge();
	havocbot_movetogoal(dodge);
	SV_PlayerPhysics();

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
};

void() havocbot_impulses =
{
	     if (self.impulse == 101) {havocbot_add(1);self.impulse = 0;}
	else if (self.impulse == 102) {havocbot_remove(1);self.impulse = 0;}
};

entity(vector org, vector m1, vector m2) findwaysurface =
{
	local entity head;
	traceline(org, org + '0 0 -100', TRUE, world);
	if (trace_fraction < 1)
	{
		head = findchain(classname, "waysurface");
		while (head)
		{
			if (org_x > head.mins_x)
			if (org_x < head.maxs_x)
			if (org_y > head.mins_y)
			if (org_y < head.maxs_y)
			//if (org_z > head.mins_z)
			//if (org_z < head.maxs_z)
			if (trace_plane_normal == head.dest2)
			if (trace_plane_dist == head.count)
				break;
			head = head.chain;
		}
		return head;
	}
	return world;
}

/*
.float nextlaywaysurface;
.entity lastwaysurface;
*/
void() havoc_laywaypoints =
{
/*
	local entity head, w;
	local vector org;
	if (!deathmatch)
	if (!coop)
		return;
	if (self.fixangle || self.teleport_time > time || self.pausetime > time)
		self.lastwaysurface = world;
	if (!(self.flags & FL_CLIENT))
		return;
	if (!(self.flags & FL_ONGROUND))
		return;
	if (time < self.nextlaywaysurface)
		return;
	self.nextlaywaysurface = time + 0.1; //2 + random() * 0.3;
	org = self.origin + self.mins_z * '0 0 1';
	head = findwaysurface(org, self.mins + self.origin, self.maxs + self.origin);
	if (head)
	{
		w = head.wp0;if (w) te_lightning2(w, (w.absmin + w.absmax) * 0.5 + '0 0 24', self.origin);
		w = head.wp1;if (w) te_lightning2(w, (w.absmin + w.absmax) * 0.5 + '0 0 24', self.origin);
		w = head.wp2;if (w) te_lightning2(w, (w.absmin + w.absmax) * 0.5 + '0 0 24', self.origin);
		w = head.wp3;if (w) te_lightning2(w, (w.absmin + w.absmax) * 0.5 + '0 0 24', self.origin);
		w = head.wp4;if (w) te_lightning2(w, (w.absmin + w.absmax) * 0.5 + '0 0 24', self.origin);
		w = head.wp5;if (w) te_lightning2(w, (w.absmin + w.absmax) * 0.5 + '0 0 24', self.origin);
		w = head.wp6;if (w) te_lightning2(w, (w.absmin + w.absmax) * 0.5 + '0 0 24', self.origin);
		w = head.wp7;if (w) te_lightning2(w, (w.absmin + w.absmax) * 0.5 + '0 0 24', self.origin);
		w = head.wp8;if (w) te_lightning2(w, (w.absmin + w.absmax) * 0.5 + '0 0 24', self.origin);
		w = head.wp9;if (w) te_lightning2(w, (w.absmin + w.absmax) * 0.5 + '0 0 24', self.origin);
		w = head.wp10;if (w) te_lightning2(w, (w.absmin + w.absmax) * 0.5 + '0 0 24', self.origin);
		w = head.wp11;if (w) te_lightning2(w, (w.absmin + w.absmax) * 0.5 + '0 0 24', self.origin);
		w = head.wp12;if (w) te_lightning2(w, (w.absmin + w.absmax) * 0.5 + '0 0 24', self.origin);
		w = head.wp13;if (w) te_lightning2(w, (w.absmin + w.absmax) * 0.5 + '0 0 24', self.origin);
		w = head.wp14;if (w) te_lightning2(w, (w.absmin + w.absmax) * 0.5 + '0 0 24', self.origin);
		w = head.wp15;if (w) te_lightning2(w, (w.absmin + w.absmax) * 0.5 + '0 0 24', self.origin);
		w = head.wp16;if (w) te_lightning2(w, (w.absmin + w.absmax) * 0.5 + '0 0 24', self.origin);
		w = head.wp17;if (w) te_lightning2(w, (w.absmin + w.absmax) * 0.5 + '0 0 24', self.origin);
		w = head.wp18;if (w) te_lightning2(w, (w.absmin + w.absmax) * 0.5 + '0 0 24', self.origin);
		w = head.wp19;if (w) te_lightning2(w, (w.absmin + w.absmax) * 0.5 + '0 0 24', self.origin);
		w = head.wp20;if (w) te_lightning2(w, (w.absmin + w.absmax) * 0.5 + '0 0 24', self.origin);
		w = head.wp21;if (w) te_lightning2(w, (w.absmin + w.absmax) * 0.5 + '0 0 24', self.origin);
		w = head.wp22;if (w) te_lightning2(w, (w.absmin + w.absmax) * 0.5 + '0 0 24', self.origin);
		w = head.wp23;if (w) te_lightning2(w, (w.absmin + w.absmax) * 0.5 + '0 0 24', self.origin);
		w = head.wp24;if (w) te_lightning2(w, (w.absmin + w.absmax) * 0.5 + '0 0 24', self.origin);
		w = head.wp25;if (w) te_lightning2(w, (w.absmin + w.absmax) * 0.5 + '0 0 24', self.origin);
		w = head.wp26;if (w) te_lightning2(w, (w.absmin + w.absmax) * 0.5 + '0 0 24', self.origin);
		w = head.wp27;if (w) te_lightning2(w, (w.absmin + w.absmax) * 0.5 + '0 0 24', self.origin);
		w = head.wp28;if (w) te_lightning2(w, (w.absmin + w.absmax) * 0.5 + '0 0 24', self.origin);
		w = head.wp29;if (w) te_lightning2(w, (w.absmin + w.absmax) * 0.5 + '0 0 24', self.origin);
		w = head.wp30;if (w) te_lightning2(w, (w.absmin + w.absmax) * 0.5 + '0 0 24', self.origin);
		w = head.wp31;if (w) te_lightning2(w, (w.absmin + w.absmax) * 0.5 + '0 0 24', self.origin);
	}
*/
};

entity dangerwaysurface;
void() havocbot_updatedangerousobjects =
{
	local entity head;
	local vector m1, m2, v;
	local float c, d, danger;
	c = 0;
	dangerwaysurface = find(dangerwaysurface, classname, "waysurface");
	while (dangerwaysurface != world && c < 16)
	{
		c = c + 1;
		danger = 0;
		m1 = dangerwaysurface.mins;
		m2 = dangerwaysurface.maxs;
		head = findchainfloat(shoulddodge, TRUE);
		while (head)
		{
			v = head.origin;
			if (v_x < m1_x) v_x = m1_x;if (v_x > m2_x) v_x = m2_x;
			if (v_y < m1_x) v_y = m1_x;if (v_y > m2_y) v_y = m2_y;
			if (v_z < m1_x) v_z = m1_x;if (v_z > m2_z) v_z = m2_z;
			d = head.dangerrating - vlen(head.origin - v);
			if (d > 0)
			{
				traceline(head.origin, v, TRUE, world);
				if (trace_fraction == 1)
					danger = danger + d;
			}
			head = head.chain;
		}
		dangerwaysurface.dmg = danger;
		dangerwaysurface = find(dangerwaysurface, classname, "waysurface");
	}
};

void() waysurface_think =
{
	//local vector org;
	self.nextthink = time + 0.2;
	/*
	org = randompos(self.mins, self.maxs);
	org_z = org_x * self.dest5_x + org_y * self.dest5_y + self.dest5_z;
	org = org + self.origin;
	particle(org, '0 0 0', 104, 4);
	*/
	if (time > self.weapon)
	if (!waysurface_link())
		self.weapon = time + 10;
};

// note: no rotation support (yet)
void(entity e) havocbot_spawnwaysurfaces =
{
	local float surfnum, numpoints, pointnum;
	local vector normal, v, m1, m2;
	surfnum = 0;
	while (1)
	{
		numpoints = getsurfacenumpoints(e, surfnum);
		if (numpoints < 3)
			break;
		// we only want walkable floor surfaces
		normal = getsurfacenormal(e, surfnum);
		if (normal_z < 0.7)
		{
			surfnum = surfnum + 1;
			continue;
		}

		newmis = spawn();
		newmis.classname = "waysurface";
		newmis.think = waysurface_think;
		newmis.lefty = TRUE;
		newmis.nextthink = time;// + surfnum * 0.01;
		newmis.cnt = time + 1;
		newmis.owner = e;
		newmis.dmg2 = surfnum;

		m1 = m2 = getsurfacepoint(e, surfnum, 0);
		pointnum = 1;
		while (pointnum < numpoints)
		{
			v = getsurfacepoint(e, surfnum, pointnum);
			if (m1_x > v_x) m1_x = v_x;if (m2_x < v_x) m2_x = v_x;
			if (m1_y > v_y) m1_y = v_y;if (m2_y < v_y) m2_y = v_y;
			if (m1_z > v_z) m1_z = v_z;if (m2_z < v_z) m2_z = v_z;
			pointnum = pointnum + 1;
		}

		setorigin(newmis, e.origin);
		setsize(newmis, m1 + '-1 -1 -9' - e.origin, m2 + '1 1 9' - e.origin);
		if (e != world)
		{
			newmis.movetype = MOVETYPE_FOLLOW;
			newmis.solid = SOLID_NOT;
			newmis.aiment = e; // entity being followed
			newmis.punchangle = '0 0 0'; // angles of entity being followed at start position
			newmis.view_ofs = '0 0 0'; // relative origin
			newmis.v_angle = '0 0 0'; // relative angles
		}

		newmis.dest1 = getsurfacepoint(e, surfnum, 0);
		newmis.dest2 = getsurfacenormal(e, surfnum);
		newmis.count = newmis.dest2 * (newmis.dest1 - e.origin);

		// test 1 unit above surface so it has no chance of being in solid
		newmis.dest5_x = 0 - (normal_x / normal_z);
		newmis.dest5_y = 0 - (normal_y / normal_z);
		newmis.dest5_z = newmis.dest1_z + 1 - (newmis.dest1_x * newmis.dest5_x + newmis.dest1_y * newmis.dest5_y);

		newmis.dest1 = (m1 + m2) * 0.5;
		newmis.dest1_z = newmis.dest1_x * newmis.dest5_x + newmis.dest1_y * newmis.dest5_y + newmis.dest5_z;

		/*
		bprint("org ");
		bprintvector(newmis.dest1);
		bprint(" normal ");
		bprintvector(newmis.dest2);
		bprint(" dist ");
		bprintfloat(newmis.count);
		bprint(" slope ");
		bprintvector(newmis.dest5);
		bprint(" surfnum ");
		bprintfloat(newmis.dmg2);
		bprint("\n");
		*/

		if (pointcontents(newmis.dest1 + '0 0 -2') != CONTENT_SOLID)
			remove(newmis);

		surfnum = surfnum + 1;
	}
};

float spawnwaysurfaces;
float worldspawnedwaysurfaces;
.float spawnedwaysurfaces;
void() havocbot_findentsandspawnwaysurfaces =
{
	local entity head;
	if (time < spawnwaysurfaces)
		return;
	if (!worldspawnedwaysurfaces)
	{
		worldspawnedwaysurfaces = TRUE;
		havocbot_spawnwaysurfaces(world);
	}
	head = findchainfloat(solid, SOLID_BSP);
	while (head)
	{
		if (!head.spawnedwaysurfaces)
		{
			head.spawnedwaysurfaces = TRUE;
			havocbot_spawnwaysurfaces(head);
		}
		head = head.chain;
	}
};
