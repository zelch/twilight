
/*
Domination as a plugin for netquake mods
by LordHavoc (havoc@telefragged.com)

How to add domination points to a mod:
1. Add this line to progs.src above world.qc:
domination.qc
2. Comment out all lines in ClientObituary (in client.qc) that begin with targ.frags  or attacker.frags.
Optional (if you want dom points in id1 maps):
3. Add this line to the end of worldspawn (in world.qc):
dom_spawnpointsformap();

Note: The only teams who can use dom control points are identified by dom_team_a_teamcolor and dom_team_b_teamcolor (typically red and blue).
*/

float dom_team_none_modelindex;
float dom_team_none_skin;
float dom_team_none_name;
float dom_team_none_teamcolor = 0;
float dom_team_a_modelindex;
float dom_team_a_skin;
float dom_team_a_name;
float dom_team_a_color = 4; // red
float dom_team_b_modelindex;
float dom_team_b_skin;
float dom_team_b_name;
float dom_team_b_color = 13; // blue

string(float t) dom_teamname_for_colorteam =
{
	t = t - 1;
	if (t == dom_team_a_teamcolor)
		return dom_team_a_name;
	else if (t == dom_team_b_teamcolor)
		return dom_team_b_name;
	else
		return dom_team_none_name;
};

void() dompointthink =
{
	self.nextthink = time + 3;
	if (!self.team)
		return;
	head = find(head, classname, "player");
	while (head)
	{
		if (head.team == self.team)
			head.frags = head.frags + 1;
		head = find(head, classname, "player");
	}
};

void() dompointtouch =
{
	if (other.team == self.team)
		return;
	if (other.classname != "player")
		return;
	if (other.health < 1)
		return;
	// only red and blue can claim it
	s = dom_teamname_for_colorteam(other.team);
	if (s == "none")
		return;

	self.team = other.team;

	bprint(self.message);
	bprint("\n");

	if (self.noise != "")
		sound(self, CHAN_BODY, self.noise, 1, ATTN_NORM);
	if (self.noise1 != "")
		sound(self, CHAN_VOICE, self.noise1, 1, ATTN_NONE);
};

/*QUAKED dom_team (0 .5 .8) (-16 -16 -24) (16 16 32)
Team declaration for Domination gameplay, this allows you to decide what team
names and control point models are used in your map.

Note: If you use dom_team entities you must define at least 3 and only two
can have netname set!  The nameless team owns all control points at start.

Keys:
"netname"
 Name of the team (for example Red, Blue, Green, Yellow, Life, Death, etc)
"cnt"
 Scoreboard color of the team (for example 4 is red and 13 is blue)
"model"
 Model to use for control points owned by this team (for example
 "progs/b_g_key.mdl" is a gold keycard, and "progs/b_s_key.mdl" is a silver
 keycard)
"skin"
 Skin of the model to use (for team skins on a single model)
"noise"
 Sound to play when this team captures a point.
 (this is a localized sound, like a small alarm or other effect)
"noise1"
 Narrator speech to play when this team captures a point.
 (this is a global sound, like "Red team has captured a control point")
"message"
 Message to show when a team captures a point
 (for example "Red team has captured a control point", or
  "The forces of light have captured a mana well")
*/

void(string teamname, float teamcolor, string pointmodel, float pointskin) dom_spawnteam =
{
	precachemodel(pointmodel);
	newmis = spawn();
	newmis.classname = "dom_team";
	newmis.netname = teamname;
	newmis.team = teamcolor + 1;
	newmis.skin = pointskin;
	setmodel(newmis, pointmodel);
	newmis.lefty = newmis.modelindex;
	newmis.model = "";
	newmis.modelindex = 0;
};

void() dom_spawnteams =
{
	// LordHavoc: edit this if you want to change things
	dom_spawnteam("Red", 4, "progs/b_g_key.mdl", 0);
	dom_spawnteam("Blue", 13, "progs/b_s_key.mdl", 0);
	dom_spawnteam("", 0, "progs/rune1.mdl", 0);
};

/*QUAKED dom_controlpoint (0 .5 .8) (-16 -16 -24) (16 16 32)
Control point for Domination gameplay.
*/
void() dom_controlpoint =
{
	head = find(world, classname, "dom_team");
	if (head == world)
	{
		dom_spawnteams();
		head = find(world, classname, "dom_team");
	}
	while(head && head.netname != "")
		head = find(head, classname, "dom_team");

	self.team = head.team + 1; // no team
	self.netname = head.netname; // name for previous owner printing
	self.model = head.mdl;
	self.modelindex = head.lefty;
	setsize(self, '-16 -16 -24', '16 16 32');
	self.solid = SOLID_TRIGGER;
	setorigin(self, self.origin);
};

void(vector org) dom_spawnpoint =
{
	newmis = spawn();
	newmis.classname = "dom_controlpoint";
	newmis.think = dom_controlpoint;
	newmis.nextthink = time;
	setorigin(newmis, org);
};

void() dom_spawnpointsformap =
{
	/*
	if (world.model == "maps/e1m1.bsp")
	{
		dom_spawnpoint('0 0 0');
	}
	*/
};

