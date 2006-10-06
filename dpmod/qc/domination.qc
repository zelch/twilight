
/*
Domination as a plugin for netquake mods
by LordHavoc (lordhavoc@ghdigital.com)

How to add domination points to a mod:
1. Add this line to progs.src above world.qc:
domination.qc
2. Comment out all lines in ClientObituary (in client.qc) that begin with targ.frags  or attacker.frags.
Optional (if you want dom points in id1 maps):
3. Add this line to the end of worldspawn (in world.qc):
dom_spawnpointsformap();

Note: The only teams who can use dom control points are identified by dom_team entities (if none exist these default to red and blue and use only quake models/sounds).
*/

void() dom_spawnteams;

void() dompointthink =
{
	self.nextthink = time + 3;
	if (!self.goalentity.netname)
		return;
	// DPMOD
	ChangeTeamFrags2(self.goalentity.team, 1);
	/* QUAKE
	local entity head;
	head = find(head, classname, "player");
	while (head)
	{
		if (head.team == self.goalentity.team)
			head.frags = head.frags + 1;
		head = find(head, classname, "player");
	}
	*/
};

void() dompointtouch =
{
	local entity head;
	if (other.classname != "player")
		return;
	if (other.health < 1)
		return;
	// only valid teams can claim it
	head = find(world, classname, "dom_team");
	while (head && head.team != other.team)
		head = find(head, classname, "dom_team");
	if (!head || head.netname == "" || head == self.goalentity)
		return;

	self.goalentity = head;
	self.model = head.mdl;
	self.modelindex = head.lefty;
	self.skin = head.skin;
	self.effects = head.ammo_rockets;
	self.colormod = head.colormod;
	self.frame = head.frame;

	bprint(head.message);
	bprint("\n");

	if (head.noise != "")
		sound(self, CHAN_BODY, head.noise, 1, ATTN_NORM);
	if (head.noise1 != "")
		sound(self, CHAN_VOICE, head.noise1, 1, ATTN_NONE);
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
"frame"
 Animation frame of the model to use (for multiple images in a single sprite)
"effects"
 What effects value to assign to control points while held by this team
 (example: 520 = white glow, 640 = red glow, 576 = blue glow)
"colormod"
 What color tint to use on control points while held by this team
 (example: 1 0 0 = red, 0 0 1 = blue)
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

void() dom_team =
{
	precache_model(self.model);
	if (self.noise != "")
		precache_sound(self.noise);
	if (self.noise1 != "")
		precache_sound(self.noise1);
	self.classname = "dom_team";
	setmodel(self, self.model);
	self.mdl = self.model;
	self.lefty = self.modelindex;
	self.model = "";
	self.modelindex = 0;
	self.ammo_rockets = self.effects;
	self.effects = 0;
	// this would have to be changed if used in quakeworld
	self.team = self.cnt + 1;
};

void() dom_controlpoint_setup =
{
	local entity head;
	// find the dom_team representing unclaimed points
	head = find(world, classname, "dom_team");
	while(head && head.netname != "")
		head = find(head, classname, "dom_team");
	if (!head)
		objerror("no dom_team with netname \"\" found\n");

	// copy important properties from dom_team entity
	self.goalentity = head;
	setmodel(self, head.mdl);
	self.skin = head.skin;
	self.effects = head.ammo_rockets;
	self.colormod = head.colormod;
	self.frame = head.frame;

	self.think = dompointthink;
	self.nextthink = time;
	self.touch = dompointtouch;
	self.solid = SOLID_TRIGGER;
	setsize(self, '-16 -16 -24', '16 16 32');
	setorigin(self, self.origin);
	droptofloor();
};

/*QUAKED dom_controlpoint (0 .5 .8) (-16 -16 -24) (16 16 32)
Control point for Domination gameplay.
*/
void() dom_controlpoint =
{
	self.think = dom_controlpoint_setup;
	self.nextthink = time + 0.1;
};

// code from here on is just to support maps that don't have control point and team entities
void(string teamname, float teamcolor, vector teamcolormod, float pointeffects, string pointmodel, float pointskin, float pointframe, string capsound, string capnarration, string capmessage) dom_spawnteam =
{
	local entity oldself;
	oldself = self;
	self = spawn();
	self.classname = "dom_team";
	self.netname = teamname;
	self.cnt = teamcolor;
	self.model = pointmodel;
	self.skin = pointskin;
	self.noise = capsound;
	self.noise1 = capnarration;
	self.message = capmessage;

	// this code is identical to dom_team
	setmodel(self, self.model);
	self.mdl = self.model;
	self.lefty = self.modelindex;
	self.model = "";
	self.modelindex = 0;
	self.ammo_rockets = pointeffects;
	self.colormod = teamcolormod;
	self.frame = pointframe;
	// this would have to be changed if used in quakeworld
	self.team = self.cnt + 1;

	//eprint(self);
	self = oldself;
};

void(vector org) dom_spawnpoint =
{
	local entity oldself;
	oldself = self;
	self = spawn();
	self.classname = "dom_controlpoint";
	self.origin = org;
	dom_controlpoint();
	self = oldself;
};

void() dom_spawnteams =
{
	// LordHavoc: edit this if you want to change defaults
	dom_spawnteam("Red" , 4 , '1 0 0', EF_FULLBRIGHT | EF_ADDITIVE | EF_NODEPTHTEST, "progs/s_explod.spr", 0, 0, "doors/runetry.wav", "", "Red team has captured a control point");
	dom_spawnteam("Blue", 13, '0 0 1', EF_FULLBRIGHT | EF_ADDITIVE | EF_NODEPTHTEST, "progs/s_explod.spr", 0, 0, "doors/runetry.wav", "", "Blue team has captured a control point");
	dom_spawnteam(""    , 0 , '1 1 1', EF_FULLBRIGHT | EF_ADDITIVE | EF_NODEPTHTEST, "progs/s_explod.spr", 0, 0, "", "", "");
};

void() dom_delayedinit =
{
	local entity head;
	// if no control points are found, spawn defaults
	if (find(world, classname, "dom_controlpoint") == world)
	{
		// here follow default domination points for each map
		if (world.model == "maps/dpdm1.bsp")
		{
			dom_spawnpoint('-512 -496 24');
			dom_spawnpoint('-544 576 24');
			dom_spawnpoint('62 1088 152');
		}
		else if (world.model == "maps/dpdm2.bsp")
		{
			dom_spawnpoint('928 -224 24');
			dom_spawnpoint('928 -224 216');
			dom_spawnpoint('576 1760 24');
			dom_spawnpoint('-1504 -1760 252');
			dom_spawnpoint('0 -256 -296');
		}
		else if (world.model == "maps/dm2.bsp")
		{
			dom_spawnpoint('2224 -448 8');
			dom_spawnpoint('1680 -1024 20');
			dom_spawnpoint('1680 -1024 344');
			dom_spawnpoint('2496 -1392 24');
		}
		else if (world.model == "maps/dm4.bsp")
		{
			dom_spawnpoint('352 -240 -296');
			dom_spawnpoint('848 -592 24');
			dom_spawnpoint('320 -912 -104');
		}
		else if (world.model == "maps/e1m4.bsp")
		{
			dom_spawnpoint('144 1376 912');
			dom_spawnpoint('832 -592 840');
			dom_spawnpoint('704 1344 344');
			dom_spawnpoint('704 3404 944');
		}
		else
		{
			// if no supported map was found, make every deathmatch spawn a point
			head = find(world, classname, "info_player_deathmatch");
			while (head)
			{
				dom_spawnpoint(head.origin);
				head = find(head, classname, "info_player_deathmatch");
			}
		}
	}
	// if points are found but no teams are found, spawn defaults
	if (find(world, classname, "dom_team") == world)
		dom_spawnteams();
};

void() dom_init =
{
	// we have to precache default models/sounds even if they might not be
	// used because worldspawn is executed before any other entities are read,
	// so we don't even know yet if this map is set up for domination...
	precache_model("progs/s_explod.spr");
	precache_model("progs/b_g_key.mdl");
	precache_model("progs/b_s_key.mdl");
	precache_model("progs/end1.mdl");
	precache_sound("doors/runetry.wav");
	newmis = spawn();
	newmis.think = dom_delayedinit;
	newmis.nextthink = time + 0.1;
};

