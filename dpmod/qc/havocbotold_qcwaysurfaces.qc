
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
	//self.think = waysurface_link;
	//self.nextthink = time;

	m1 = self.mins;
	m2 = self.maxs;
	d = 0;
	e = self.oldenemy;
	while (d < 20)
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
void(vector org, vector normal, float dist, float fl) havocbot_spawnwaysurface;

entity(entity e) findnearestwaysurface =
{
	local entity head;
	local vector org, m1, m2;
	if (e.origin != e.nearestwaysurfaceorigin || time > e.nearestwaysurfacetimeout)
	{
		m1 = e.absmin;
		m2 = e.absmax;
		org = (m1 + m2) * 0.5;
		org_z = m1_z + 1;
		e.nearestwaysurface = findwaysurface(org, m1, m2);
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
	o = head.dest;
	m1 = w.absmin;
	m2 = w.absmax;
	if (o_x < m1_x) o_x = m1_x;if (o_x > m2_x) o_x = m2_x;
	if (o_y < m1_y) o_y = m1_y;if (o_y > m2_y) o_y = m2_y;
	if (o_z < m1_z) o_z = m1_z;if (o_z > m2_z) o_z = m2_z;
	cost = head.wpcost + vlen(o - head.dest) + head.dmg;
	if(cost < w.wpcost)
	{
		//te_smallflash(o);
		w.dest = o;
		w.wpcost = cost;
		w.enemy = head;
		w.wpfire = 1;
	}
}

void() markroutes =
{
	local entity start, head, w;
	local vector o, m1, m2;
	local float d, dist, cost;
	head = findchain(classname, "waysurface");
	while (head)
	{
		head.dest = '0 0 0';
		head.wpcost = 10000000;
		head.wpfire = 0;
		head.enemy = world;
		head = head.chain;
	}
	w = findwaysurface(self.origin, self.absmin, self.absmax);
	if (w == world)
		return;
	o = self.origin;
	m1 = w.mins;
	m2 = w.maxs;
	if (o_x < m1_x) o_x = m1_x;if (o_x > m2_x) o_x = m2_x;
	if (o_y < m1_y) o_y = m1_y;if (o_y > m2_y) o_y = m2_y;
	if (o_z < m1_z) o_z = m1_z;if (o_z > m2_z) o_z = m2_z;
	w.dest = o;
	w.wpcost = vlen(w.dest - self.origin) + w.dmg;
	w.enemy = world;
	w.wpfire = 1;
	while (1)
	{
		head = findchainfloat(wpfire, 1);
		if (head == world)
			return;
		while (head)
		{
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
	local vector org, m1, m2;
	local float f;
	local string s;
	local entity old;
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
	e = findnearestwaysurface(e);
	m1 = self.absmin;
	m2 = self.absmax;
	//while (e.enemy != world)
	//old = e;
	while (e != world)
	{
		pushroute(e);
		//if (e == self.lastwaysurfacetouched)
		//	return; // skip nearest waysurface if it has already been touched
		if (e.maxs_x > m1_x)
		if (e.mins_x < m2_x)
		if (e.maxs_y > m1_y)
		if (e.mins_y < m2_y)
		if (e.maxs_z > m1_z)
		if (e.mins_z < m2_z)
		{
			//if (old)
			//	pushroute(old);
			return;
		}
		//old = e;
		/*
		if (e.enemy.enemy == world)
		{
			f = vlen(e.enemy.origin - self.origin);
			if (vlen(e.origin - self.origin) > f)
				return; // skip the nearest-to-player waysurface if it is further from the goal
		}
		*/
		e = e.enemy;
	}
	//if (old)
	//	pushroute(old);
};

void() havocbot_popgoals =
{
	local float s;
	s = TRUE;
	while (s)
	{
		s = FALSE;
		if (self.absmax_x > self.goalcurrent.mins_x)
		if (self.absmin_x < self.goalcurrent.maxs_x)
		if (self.absmax_y > self.goalcurrent.mins_y)
		if (self.absmin_y < self.goalcurrent.maxs_y)
		if (self.absmax_z > self.goalcurrent.mins_z)
		if (self.absmin_z < self.goalcurrent.maxs_z)
		{
			poproute();
			if (self.goalcurrent == world)
				return;
			s = TRUE;
			continue;
		}
		// check for tempgoals that died
		if (!self.goalcurrent.classname && self.goalcurrent != self.goalentity)
		{
			poproute();
			if (self.goalcurrent == world)
				return;
			s = TRUE;
		}
	}
}

.float havocbotignoretime;
void(vector dodge) havocbot_movetogoal =
{
	local vector destorg, diff, dir, vel, flatdir, move, end, m1, m2, m3, m4, org;
	local float s, dist, walkdist, walkangle, havoconground, p;
	local entity e, head, floorsurface;
	self.movement = '0 0 0';
	if (self.goalcurrent == world)
		return;
	havocbot_popgoals();
	if (self.goalcurrent == world)
		return;
	if (self.waterlevel)
	{
		diff = destorg - self.origin;
		dist = vlen(diff);
		dir = normalize(diff);
	//	self.velocity = self.velocity + dir * (400 * sv_accelerate * frametime) + normalize(dodge) * maxspeed * 2;
	//	if (vlen(self.velocity) > maxspeed)
	//		self.velocity = normalize(self.velocity) * maxspeed;
	}
	else
	{
		havoconground = self.flags & FL_ONGROUND;
		if (!havoconground)
		{
			// prevent goal checks when we can't walk
			//self.goaltime = time + 0.2;
			return;
		}

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
		//dir = normalize(destorg - self.origin);
		//particle(self.origin + dir * 16, '0 0 0', 50, 5);
		te_lightning2(self, self.origin, destorg);


		diff = destorg - self.origin;
		dist = vlen(diff);
		dir = normalize(diff);
		flatdir = diff;flatdir_z = 0;
		flatdir = normalize(flatdir);
		dir = flatdir;
		/*
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
		*/
	}
	dir = dir + dodge;
	makevectors(self.v_angle);
	self.movement_x = dir * v_forward * 400;
	self.movement_y = dir * v_right * 350;
	self.movement_z = dir * v_up * 400;
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
	if (time > self.weaponchangetimeout)
	{
		self.weaponchangetimeout = time + 0.2;
		self.switchweapon = W_BestWeapon(TRUE);
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

float nextwayspawntime;

void() waypointspawnforitem_think =
{
	local entity e;
	self.nextthink = time + 0.03;
	if (time >= nextwayspawntime)
	{
		e = self;
		self = self.owner;
		nextwayspawntime = time + 0.05;
		if (!findwaysurface((self.mins + self.maxs) * 0.5 + self.origin, self.mins + self.origin, self.maxs + self.origin))
			havocbot_spawnwaysurface(trace_endpos, trace_plane_normal, trace_plane_dist, 0);
		self = e;
		remove(self);
		return;
	}
};

void(entity e) waypointspawnforitem =
{
	newmis = spawn();
	newmis.think = waypointspawnforitem_think;
	newmis.nextthink = time;
	newmis.owner = e;
	/*
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
	*/
};

/*
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
*/

void() havocbot_impulses =
{
	/*
	if (cvar("temp1") & 512) // waypoint editing mode
	{
			 if (self.impulse == 110) {havocbot_makewaypoint();self.impulse = 0;}
		else if (self.impulse == 111) {havocbot_killwaypoint();self.impulse = 0;}
		else if (self.impulse == 118) {waypoint_relinkall();self.impulse = 0;}
		else if (self.impulse == 119) {havocbot_dumpwaypoints();self.impulse = 0;}
	}
	*/

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
		self.count = trace_plane_dist;
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
	local float c, d, success, r;
	local vector org, m1, m2;
	self.nextthink = time + 0.1;
	org = randompos(self.mins, self.maxs);
	org_z = org_x * self.dest5_x + org_y * self.dest5_y + self.dest5_z;
	//particle(org, '0 0 0', 104, 4);
	if (time < self.cnt)
	{
		c = 0;
		while (c < 128)
		{
			c = c + 1;
			m1 = self.mins;
			m2 = self.maxs;
			r = random() * 64;
			if (c & 1)
			{
				if (c & 2)
				{
					org_x = m1_x - r;
					if (org_x < self.dest1_x - 256) org_x = self.dest1_x - 256;
					//org_y = random() * (m2_y - m1_y) + m1_y;
				}
				else
				{
					org_x = m2_x + r;
					if (org_x > self.dest1_x + 256) org_x = self.dest1_x + 256;
					//org_y = random() * (m2_y - m1_y) + m1_y;
				}
			}
			else
			{
				if (c & 2)
				{
					//org_x = random() * (m2_x - m1_x) + m1_x;
					org_y = m1_y - r;
					if (org_y < self.dest1_y - 256) org_y = self.dest1_y - 256;
				}
				else
				{
					//org_x = random() * (m2_x - m1_x) + m1_x;
					org_y = m2_y + r;
					if (org_y > self.dest1_y + 256) org_y = self.dest1_y + 256;
				}
			}
			d = 0;
			while (d <= 1)
			{
				if (c & 1)
					org_y = m1_y + (m2_y - m1_y) * d;
				else
					org_x = m1_x + (m2_x - m1_x) * d;
				success = FALSE;
				org_z = org_x * self.dest5_x + org_y * self.dest5_y + self.dest5_z;
				traceline(self.dest1, org, TRUE, world);
				org = trace_endpos;
				traceline(org, org + '0 0 -4', TRUE, world);
				if (trace_fraction < 1)
				if (trace_plane_dist == self.count)
				if (trace_plane_normal == self.dest2)
				{
					//particle(org, '0 0 0', 140, 4);
					if (m1_x > org_x) m1_x = org_x;if (m2_x < org_x) m2_x = org_x;
					if (m1_y > org_y) m1_y = org_y;if (m2_y < org_y) m2_y = org_y;
					if (m1_z > org_z) m1_z = org_z;if (m2_z < org_z) m2_z = org_z;
					success = TRUE;
				}
				if (!success)
					break;
				// increment by 1/8th
				d = d + 0.125;
			}
			if (d >= 1)
			if (m1 != self.mins || m2 != self.maxs)
				setsize(self, m1, m2);
		}
	}
	else if (self.lefty || time > self.weapon)
	{
		if (!self.items)
		{
			self.items = 1;
			setsize(self, self.mins + '-17 -17 -9', self.maxs + '17 17 9');
		}
		self.weapon = time + 10;
		self.lefty = waysurface_link();
	}
};

/*
void() waysurface_setupthink =
{
	local float c, d, success;
	local vector org, testorg, m1, m2;
	self.nextthink = time + 0.1;
	org = randompos(self.mins, self.maxs);
	org_z = org_x * self.dest5_x + org_y * self.dest5_y + self.dest5_z;
	//particle(org, '0 0 0', 104, 4);
	if (time < self.cnt)
	{
		c = 0;
		m1 = self.mins;
		m2 = self.maxs;
		while (c < 512)
		{
			c = c + 1;
			testorg = randompos(m1, m2);
			if (c & 1)
			{
				if (c & 2)
				{
					org_x = m1_x - 32;
					if (org_x < self.dest1_x - 256) org_x = self.dest1_x - 256;
				}
				else
				{
					org_x = m2_x + 32;
					if (org_x > self.dest1_x + 256) org_x = self.dest1_x + 256;
				}
				org_y = random() * (m2_y - m1_y) + m1_y;
			}
			else
			{
				if (c & 2)
				{
					org_y = m1_y - 32;
					if (org_y < self.dest1_y - 256) org_y = self.dest1_y - 256;
				}
				else
				{
					org_y = m2_y + 32;
					if (org_y > self.dest1_y + 256) org_y = self.dest1_y + 256;
				}
				org_x = random() * (m2_x - m1_x) + m1_x;
			}
			org_z = org_x * self.dest5_x + org_y * self.dest5_y + self.dest5_z;
			traceline(testorg, org, TRUE, world);
			org = trace_endpos;
			traceline(org, org + '0 0 -4', TRUE, world);
			if (trace_fraction < 1)
			if (trace_plane_dist == self.count)
			if (trace_plane_normal == self.dest2)
			{
				//particle(org, '0 0 0', 140, 4);
				if (m1_x > org_x) m1_x = org_x;if (m2_x < org_x) m2_x = org_x;
				if (m1_y > org_y) m1_y = org_y;if (m2_y < org_y) m2_y = org_y;
				if (m1_z > org_z) m1_z = org_z;if (m2_z < org_z) m2_z = org_z;
			}
		}
		if (m1 != self.mins || m2 != self.maxs)
			setsize(self, m1, m2);
	}
	else if (self.lefty || time > self.weapon)
	{
		self.weapon = time + 10;
		self.lefty = waysurface_link();
	}
};
*/

void(vector org, vector normal, float dist, float fl) havocbot_spawnwaysurface =
{
	newmis = spawn();
	newmis.classname = "waysurface";
	newmis.think = waysurface_setupthink;
	newmis.lefty = TRUE;
	newmis.nextthink = time;
	newmis.cnt = time + 1;
	newmis.dest1 = org + '0 0 1';
	newmis.dest2 = normal;
	newmis.count = dist;
	// test 1 unit above so it doesn't start inside the surface
	newmis.dest5_x = 0 - (normal_x / normal_z);
	newmis.dest5_y = 0 - (normal_y / normal_z);
	newmis.dest5_z = newmis.dest1_z - (newmis.dest1_x * newmis.dest5_x + newmis.dest1_y * newmis.dest5_y);
	bprint("org ");
	bprintvector(newmis.dest1);
	bprint(" normal ");
	bprintvector(newmis.dest2);
	bprint(" dist ");
	bprintfloat(newmis.count);
	bprint(" slope ");
	bprintvector(newmis.dest5);
	bprint("\n");
	// start out as just a point
	setsize(newmis, org, org);
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

.float nextlaywaysurface;
.entity lastwaysurface;
void() havoc_laywaypoints =
{
	local entity head, w;
	local vector org;
	if (!deathmatch)
	if (!coop)
		return;
	if (self.fixangle || self.teleport_time > time || self.pausetime > time)
		self.lastwaysurface = world;
	//if (!(self.flags & FL_CLIENT))
	//	return;
	//if (!(self.flags & FL_ONGROUND))
	//	return;
	if (time < self.nextlaywaysurface)
		return;
	self.nextlaywaysurface = time + 0.1; //2 + random() * 0.3;
	/*
	traceline(self.origin + '0 0 -23', self.origin + '0 0 -40', FALSE, self);
	if (trace_fraction >= 1)
		return;
	head = findchain(classname, "waysurface");
	while(head)
	{
		if (vlen(head.origin - self.origin) < 192)
		if (tracewalk(self, self.origin, head.origin))
			return;
		head = head.chain;
	}
	havocbot_makewaysurface();
	*/
	org = self.origin + self.mins_z * '0 0 1';
	head = findwaysurface(org, self.mins + self.origin, self.maxs + self.origin);
	//if (head)
	//{
		/*
		if (head != self.lastwaysurface)
		if (self.lastwaysurface)
			waysurface_addlink(self.lastwaysurface, head);
		self.lastwaysurface = head;
		*/
		/*
		w = head.wp0;if (w) te_lightning2(w, (head.absmin + head.absmax) * 0.5 + '0 0 24', (w.absmin + w.absmax) * 0.5 + '0 0 24');
		w = head.wp1;if (w) te_lightning2(w, (head.absmin + head.absmax) * 0.5 + '0 0 24', (w.absmin + w.absmax) * 0.5 + '0 0 24');
		w = head.wp2;if (w) te_lightning2(w, (head.absmin + head.absmax) * 0.5 + '0 0 24', (w.absmin + w.absmax) * 0.5 + '0 0 24');
		w = head.wp3;if (w) te_lightning2(w, (head.absmin + head.absmax) * 0.5 + '0 0 24', (w.absmin + w.absmax) * 0.5 + '0 0 24');
		w = head.wp4;if (w) te_lightning2(w, (head.absmin + head.absmax) * 0.5 + '0 0 24', (w.absmin + w.absmax) * 0.5 + '0 0 24');
		w = head.wp5;if (w) te_lightning2(w, (head.absmin + head.absmax) * 0.5 + '0 0 24', (w.absmin + w.absmax) * 0.5 + '0 0 24');
		w = head.wp6;if (w) te_lightning2(w, (head.absmin + head.absmax) * 0.5 + '0 0 24', (w.absmin + w.absmax) * 0.5 + '0 0 24');
		w = head.wp7;if (w) te_lightning2(w, (head.absmin + head.absmax) * 0.5 + '0 0 24', (w.absmin + w.absmax) * 0.5 + '0 0 24');
		*/
	//}
	//else
	if (!head)
	{
		// if it found no surface, spawn a new one
		havocbot_spawnwaysurface(trace_endpos, trace_plane_normal, trace_plane_dist, 0);
	}
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
