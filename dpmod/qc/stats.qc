
// FIXME: identify by weapon number somehow

.float kills_axe         , deaths_axe         ;
.float kills_shotgun     , deaths_shotgun     ;
.float kills_supershotgun, deaths_supershotgun;
.float kills_nailgun     , deaths_nailgun     ;
.float kills_supernailgun, deaths_supernailgun;
.float kills_grenade     , deaths_grenade     , suicides_grenade;
.float kills_rocket      , deaths_rocket      , suicides_rocket;
.float kills_lightning   , deaths_lightning   ;
.float kills_grapple     , deaths_grapple     ;
.float kills_plasma      , deaths_plasma      ;
.float kills_monster     , deaths_monster     ;
.float kills_player      , deaths_player      ;
.float kills_team        , deaths_team        ;
.float kills_total       , deaths_total       , suicides_total;
.float kills_jointime; // what time this player joined the game
.float deaths_world, deaths_water, deaths_slime, deaths_lava, deaths_fall;

// call this for any kill/death/suicide situation
// if dethtype is "" it will add it to the totals only
void(entity targ, entity attacker, string dethtype) statkill =
{
	if (targ.classname != "player")
	if (attacker.classname != "player")
		return; // neither is a player
	if (!targ.doobits)
		return; // corpse perhaps?

	if (targ.classname == "player") // a player died
	{
		targ.deaths_total = targ.deaths_total + 1;
		if (targ == attacker) // suicide
		{
			targ.suicides_total = targ.suicides_total + 1;
			if (dethtype == "GRENADE")              targ.suicides_grenade           = targ.suicides_grenade + 1;
			if (dethtype == "ROCKET")               targ.suicides_rocket            = targ.suicides_rocket + 1;
		}
		else if (attacker.classname == "player")
		{
			targ.deaths_player = targ.deaths_player + 1;
			if (attacker.team == targ.team && attacker.team != 0 && teamplay != 0)
				targ.deaths_team = targ.deaths_team + 1;
			else if (dethtype == "AXE")             targ.deaths_axe                 = targ.deaths_axe + 1;
			else if (dethtype == "SHOTGUN")         targ.deaths_shotgun             = targ.deaths_shotgun + 1;
			else if (dethtype == "SUPERSHOTGUN")    targ.deaths_supershotgun        = targ.deaths_supershotgun + 1;
			else if (dethtype == "NAILGUN")         targ.deaths_nailgun             = targ.deaths_nailgun + 1;
			else if (dethtype == "SUPERNAILGUN")    targ.deaths_supernailgun        = targ.deaths_supernailgun + 1;
			else if (dethtype == "GRENADE")         targ.deaths_grenade             = targ.deaths_grenade + 1;
			else if (dethtype == "ROCKET")          targ.deaths_rocket              = targ.deaths_rocket + 1;
			else if (dethtype == "LIGHTNING")       targ.deaths_lightning           = targ.deaths_lightning + 1;
			else if (dethtype == "GRAPPLE")         targ.deaths_grapple             = targ.deaths_grapple + 1;
			else if (dethtype == "PLASMA")          targ.deaths_plasma              = targ.deaths_plasma + 1;
		}
		else if (attacker.flags & FL_MONSTER)
			targ.deaths_monster = targ.deaths_monster + 1;
		else if (attacker == world) // physics stuff
		{
			targ.deaths_world = targ.deaths_world + 1;
			if (dethtype == "WATER")                targ.deaths_water               = targ.deaths_water + 1;
			if (dethtype == "SLIME")                targ.deaths_slime               = targ.deaths_slime + 1;
			if (dethtype == "LAVA")                 targ.deaths_lava                = targ.deaths_lava + 1;
			if (dethtype == " met a flat world")    targ.deaths_fall                = targ.deaths_fall + 1;
		}
	}
	if (attacker.classname == "player") // a player killed
	if (attacker != targ) // suicides aren't counted as kills
	{
		attacker.kills_total = attacker.kills_total + 1;
		if (targ.classname == "player")
		{
			attacker.kills_player = attacker.kills_player + 1;
			if (attacker.team == targ.team && attacker.team != 0 && teamplay != 0)
				attacker.kills_team = attacker.kills_team + 1;
			else if (dethtype == "AXE")             attacker.kills_axe              = attacker.kills_axe + 1;
			else if (dethtype == "SHOTGUN")         attacker.kills_shotgun          = attacker.kills_shotgun + 1;
			else if (dethtype == "SUPERSHOTGUN")    attacker.kills_supershotgun     = attacker.kills_supershotgun + 1;
			else if (dethtype == "NAILGUN")         attacker.kills_nailgun          = attacker.kills_nailgun + 1;
			else if (dethtype == "SUPERNAILGUN")    attacker.kills_supernailgun     = attacker.kills_supernailgun + 1;
			else if (dethtype == "GRENADE")         attacker.kills_grenade          = attacker.kills_grenade + 1;
			else if (dethtype == "ROCKET")          attacker.kills_rocket           = attacker.kills_rocket + 1;
			else if (dethtype == "LIGHTNING")       attacker.kills_lightning        = attacker.kills_lightning + 1;
			else if (dethtype == "GRAPPLE")         attacker.kills_grapple          = attacker.kills_grapple + 1;
			else if (dethtype == "PLASMA")          attacker.kills_plasma           = attacker.kills_plasma + 1;
		}
		else if (targ.flags & FL_MONSTER)
			attacker.kills_monster = attacker.kills_monster + 1;
	}
};

float(float kills, float deaths) statkd =
{
	local float total;
	total = kills + deaths;
	if (total >= 1)
		return (kills / total);
	else
		return 0;
};

void(float kills, float deaths, float suicides, string title) statprint =
{
	local float kd;
//	if (!kills)
//	if (!deaths)
//	if (!suicides)
//		return;
	if (kills)
		sprintnumdigits(self, kills, 5);
	else
		sprint(self, "     ");
	if (deaths)
		sprintnumdigits(self, deaths, 6);
	else
		sprint(self, "      ");
	if (suicides)
		sprintnumdigits(self, suicides, 8);
	else
		sprint(self, "        ");
	kd = statkd(kills, deaths) * 100;
	if (kd)
	{
		sprintnumdigits(self, kd, 3);
		sprint(self, " ");
	}
	else
		sprint(self, "    ");
	sprint(self, title);
	sprint(self, "\n");
};

void() statshow =
{
	local float t;
	local entity head;
	t = time - self.kills_jointime;
	if (t < 1)
		t = 1;
	t = t / 3600; // 3600 seconds in an hour
	sprint(self, "KillsDeathsSuicidesK/D%Name\n");
	head = findchain(classname, "player");
	while(head)
	{
		statprint(head.kills_total, head.deaths_total, head.suicides_total, head.netname);
		head = head.chain;
	}
	sprint(self, "Your stats:\n");
	sprint(self, "KillsDeathsSuicidesK/D%Type\n");
	statprint(self.kills_axe         , self.deaths_axe         , 0                    , "Axe");
	statprint(self.kills_shotgun     , self.deaths_shotgun     , 0                    , "Shotgun");
	statprint(self.kills_supershotgun, self.deaths_supershotgun, 0                    , "Super Shotgun");
	statprint(self.kills_nailgun     , self.deaths_nailgun     , 0                    , "Nailgun");
	statprint(self.kills_supernailgun, self.deaths_supernailgun, 0                    , "Super Nailgun");
	statprint(self.kills_grenade     , self.deaths_grenade     , self.suicides_grenade, "Grenade");
	statprint(self.kills_rocket      , self.deaths_rocket      , self.suicides_rocket , "Rocket");
	statprint(self.kills_lightning   , self.deaths_lightning   , 0                    , "Lightning");
	statprint(self.kills_grapple     , self.deaths_grapple     , 0                    , "Grapple");
	statprint(self.kills_plasma      , self.deaths_plasma      , 0                    , "Plasma");
	statprint(self.kills_player      , self.deaths_player      , 0                    , "Player");
	statprint(self.kills_monster     , self.deaths_monster     , 0                    , "Monster");
	statprint(self.kills_team        , self.deaths_team        , 0                    , "Team");
	statprint(0                      , self.deaths_water       , 0                    , "Water");
	statprint(0                      , self.deaths_slime       , 0                    , "Slime");
	statprint(0                      , self.deaths_lava        , 0                    , "Lava");
	statprint(0                      , self.deaths_fall        , 0                    , "Falling");
	statprint(0                      , self.deaths_world       , 0                    , "World Total");
	statprint(self.kills_total       , self.deaths_total       , self.suicides_total  , "Total");
	statprint(self.kills_player/t    , self.deaths_player/t    , 0                    , "Players Per Hour");
	statprint(self.kills_monster/t   , self.deaths_monster/t   , 0                    , "Monster Per Hour");
	statprint(self.kills_total/t     , self.deaths_total/t     , self.suicides_total/t, "Total   Per Hour");
};
