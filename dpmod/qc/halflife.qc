
//.float roomtype;
//.float radius;
//.float pitch;
//.float renderamt;
//.float rendermode;
//.vector rendercolor;

void() info_node = {};
void() env_sound = {};
void() light_spot = {};
void() func_healthcharger = {};
void() weapon_tripmine = {};
void() weapon_snark = {};
void() ammo_buckshot = {};
void() ammo_9mmAR = {};
void() ammo_357 = {};
void() weapon_gauss = {};
void() weapon_hornetgun = {};
void() weapon_shotgun = {};
void() item_healthkit = {};
void() item_longjump = {};
void() item_antidote = {};
void() func_recharge = {};
void() weapon_crossbow = {};
void() weapon_handgrenade = {};
void() ammo_crossbow = {};
void() ammo_9mmclip = {};
void() ammo_gaussclip = {};
void() weapon_rpg = {};
void() weapon_357 = {};
void() ammo_ARgrenades = {};
void() item_battery = {};
void() ammo_rpgclip = {};
void() weapon_9mmAR = {};

void() func_ladder_touch =
{
	if (other.classname != "player")
		return;
	other.ladder_time = time + 0.1;
	other.ladder_entity = self;
};

void() func_ladder =
{
	InitTrigger ();
	self.touch = func_ladder_touch;
};

void() func_water =
{
	self.solid = SOLID_TRIGGER;
	setmodel (self, self.model);	// set size and link into world
	self.touch = func_ladder_touch;
};

void() light_use;
void() light_environment =
{
	if (!self.targetname)
	{
		// inert light
		remove(self);
		return;
	}

	if (self.style >= 32)
	{
		self.use = light_use;
		if ((self.spawnflags & 1) || darkmode)
			lightstyle(self.style, "a");
		else
			lightstyle(self.style, "m");
	}
};

