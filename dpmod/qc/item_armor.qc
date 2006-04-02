/*
===============================================================================

ARMOR

===============================================================================
*/

void() armor_touch;

void() armor_touch =
{
	if (other.health < 1)
		return;
	if (other.classname != "player")
		return;

	// stop fire
	if (other.flame)
		other.flame.cnt = 0; // clear fuel

	if ((other.armortype * other.armorvalue) >= (self.armortype * self.armorvalue))
		return; // he's wearing better armor already

	other.armortype = self.armortype;
	other.armorvalue = self.armorvalue;
	other.items = other.items - (other.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3)) + self.items;

	self.solid = SOLID_NOT;
	self.model = "";
	if (itemrespawn)
	{
		self.nextthink = time + RESPAWNTIME_ARMOR;
		self.think = SUB_regen;
	}
	else
	{
		self.nextthink = time + 0.1;
		self.think = SUB_Remove;
	}

	if (other.flags & FL_CLIENT)
	{
//		sprint(other, self.netname);
		stuffcmd(other, "bf\n");
	}
	// armor touch sound
	sound(other, CHAN_ITEM, "items/armor1.wav", 1, ATTN_NORM);

	activator = other;
	SUB_UseTargets();                               // fire all targets / killtargets
};

float(entity player, entity item) item_armor_pickupeval =
{
	local float new, old;
	new = item.dmg;
	old = player.armorvalue * player.armortype;
	if (new <= old)
		return 0;
	else
		return (new - old) * (new - old) * item.dmg2;
};

// TODO: Nexuiz items

/*QUAKED item_armor_green (0 .5 .8) (-16 -16 0) (16 16 32)
100 green armor, 30% absorb
*/
void() item_armor_green =
{
	self.classname = "item_armor_green";
	self.touch = armor_touch;
	if (game == GAME_NEXUIZ)
	{
		precache_model ("models/items/g_a25.md3");
		setmodel (self, "models/items/g_a25.md3");
	}
	else
	{
		precache_model ("progs/armor.mdl");
		setmodel (self, "progs/armor.mdl");
		self.skin = 0;
	}
	self.frame = 0;
	self.armortype = GREENARMOR_TYPE;
	if (self.armorvalue < 1)
		self.armorvalue = GREENARMOR_VALUE;
	self.netname = "Green armor - 30% off damage\n";
	self.items = IT_ARMOR1;
	setsize (self, '-16 -16 0', '16 16 56');

	self.havocpickup = TRUE;
	self.dmg = self.armorvalue * self.armortype;
	self.dmg2 = 10000 / (160 * 160); // 200 red armor = 160 rating (200 * 0.8)
	self.pickupevalfunc = item_armor_pickupeval;

	StartItem ();
};

/*QUAKED item_armor_yellow (0 .5 .8) (-16 -16 0) (16 16 32)
150 yellow armor, 60% absorb
*/
void() item_armor_yellow =
{
	self.classname = "item_armor_yellow";
	self.touch = armor_touch;
	if (game == GAME_NEXUIZ)
	{
		precache_model ("models/items/g_a25.md3");
		setmodel (self, "models/items/g_a25.md3");
	}
	else
	{
		precache_model ("progs/armor.mdl");
		setmodel (self, "progs/armor.mdl");
		self.skin = 1;
	}
	self.frame = 0;
	self.armortype = YELLOWARMOR_TYPE;
	if (self.armorvalue < 1)
		self.armorvalue = YELLOWARMOR_VALUE;
	self.netname = "Yellow armor - 60% off damage\n";
	self.items = IT_ARMOR2;
	setsize (self, '-16 -16 0', '16 16 56');

	self.havocpickup = TRUE;
	self.dmg = self.armorvalue * self.armortype;
	self.dmg2 = 10000 / (160 * 160); // 200 red armor = 160 rating (200 * 0.8)
	self.pickupevalfunc = item_armor_pickupeval;

	StartItem ();
};

/*QUAKED item_armor_red (0 .5 .8) (-16 -16 0) (16 16 32)
200 red armor, 80% absorb
*/
void() item_armor_red =
{
	self.classname = "item_armor_red";
	self.touch = armor_touch;
	if (game == GAME_NEXUIZ)
	{
		precache_model ("models/items/g_a25.md3");
		setmodel (self, "models/items/g_a25.md3");
	}
	else
	{
		precache_model ("progs/armor.mdl");
		setmodel (self, "progs/armor.mdl");
		self.skin = 2;
	}
	self.armortype = REDARMOR_TYPE;
	if (self.armorvalue < 1)
		self.armorvalue = REDARMOR_VALUE;
	self.netname = "Red armor - 80% off damage\n";
	self.items = IT_ARMOR3;
	setsize (self, '-16 -16 0', '16 16 56');

	self.havocpickup = TRUE;
	self.dmg = self.armorvalue * self.armortype;
	self.dmg2 = 10000 / (160 * 160); // 200 red armor = 160 rating (200 * 0.8)
	self.pickupevalfunc = item_armor_pickupeval;

	StartItem ();
};

/*QUAKED item_armor_glow (0 .5 .8) (-16 -16 0) (16 16 32)
250 red armor, 80% absorb
*/
void() item_armor_glow =
{
	self.classname = "item_armor_glow";
	self.touch = armor_touch;
	if (game == GAME_NEXUIZ)
	{
		precache_model ("models/items/g_a25.md3");
		setmodel (self, "models/items/g_a25.md3");
	}
	else
	{
		precache_model ("progs/armor.mdl");
		setmodel (self, "progs/armor.mdl");
		self.skin = 2;
	}
	self.frame = 0;
	self.armortype = GLOWARMOR_TYPE;
	if (self.armorvalue < 1)
		self.armorvalue = GLOWARMOR_VALUE;
	self.netname = "Red armor - 80% off damage\n";
	self.items = IT_ARMOR3;
	self.effects = EF_DIMLIGHT;
	setsize (self, '-16 -16 0', '16 16 56');

	self.havocpickup = TRUE;
	self.dmg = self.armorvalue * self.armortype;
	self.dmg2 = 10000 / (160 * 160);
	self.pickupevalfunc = item_armor_pickupeval;

	StartItem ();
};

