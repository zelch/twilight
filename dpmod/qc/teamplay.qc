
float nofire; // weapon code pays attention to this
float fightdone; // weapons update this
float matchmode;

float serverinactive;

void() respawn;

void(entity e) respawnplayer =
{
	local entity saveself;
	saveself = self;
	self = e;
	respawn();
	self = saveself;
};

void() respawnplayers =
{
	local entity head;
	head = find(world, classname, "player");
	while(head)
	{
		respawnplayer(head);
		head = find(head, classname, "player");
	}
};

// setup in world.qc
entity team1, team2, team3, team4, team5, team6, team7, team8, team9, team10, team11, team12, team13, team14;

// set only by various team changing code
.float currentteam, desiredteam;

entity modecode;
.void() framethink;
.void(float color) chooseteam;

void() modecoopframe = {};
void(float pants, float shirt) modecoopteam = {setcolor(self, pants + shirt * 16);};
void() modecoopplayer = {};

void() modedmframe = {};
void(float pants, float shirt) modedmteam = {setcolor(self, pants + shirt * 16);};
void() modedmplayer = {};

// engine feature
void(float color) SV_ChangeTeam =
{
	modecode.chooseteam(color & 15, (color / 16) & 15);
};

void(string modename, void() framethinkfunc, void() chooseteamfunc, void() playerframefunc) modecodeset =
{
	if (!modecode)
		modecode = spawn();
	cvar_set("deathmatch", modename);
	modecode.playerframe = playerframefunc;
	modecode.chooseteam = chooseteamfunc;
	modecode.framethink = framethinkfunc;
};

void(float m) modeset =
{
	     if (m ==  0) modecodeset("0?DarkPlaces - Coop", modecoopframe, modecoopteam, modecoopplayer);
	else if (m ==  1) modecodeset("1?DarkPlaces - Deathmatch", modedmframe, modedmteam, modedmplayer);
	else if (m ==  2) modecodeset("2?DarkPlaces - Deathmatch 2 (can only pickup gun once)", modedmframe, modedmteam, modedmplayer);
	else if (m ==  3) modecodeset("3?DarkPlaces - Deathmatch 3 (quick ammo respawn)", modedmframe, modedmteam, modedmplayer);
	else if (m ==  5) modecodeset("5?DarkPlaces - Frag Fest (spawn with full pack)", modedmframe, modedmteam, modedmplayer);
	else if (m ==  6) modecodeset("6?DarkPlaces - Random Weapons (spawn with 2 random weapons)", modedmframe, modedmteam, modedmplayer);
	else if (m ==  7) modecodeset("7?DarkPlaces - Simple Mode (no explosives)", modedmframe, modedmteam, modedmplayer);
	else if (m ==  8) modecodeset("8?DarkPlaces - Elimination", modeelimframe, modeelimteam, modeelimplayer);
	else if (m ==  9) modecodeset("9?DarkPlaces - Kill The Leader Mode", modektlframe, modektlteam, modektlplayer);
	else if (m == 10) modecodeset("10?DarkPlaces - Capture The Flag - 2 Team", modectfframe, modectfteam, modectfplayer);
	else if (m == 11) modecodeset("11?DarkPlaces - Capture The Flag - 3 Team", modectfframe, modectfteam, modectfplayer);
	else if (m == 12) modecodeset("12?DarkPlaces - Domination", modedomframe, modedomteam, modedomplayer);
	else              modecodeset("1?DarkPlaces - Deathmatch", modedmframe, modedmteam, modedmplayer);
};

void(float t) setplayerteam =
{
	self.desiredteam = t;
	modecode.chooseteam(t * 16 + t);
};
