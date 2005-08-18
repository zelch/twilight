
void() Item_Touch;
float(entity item, entity character) Item_GenericCanPickup;
float(entity item, entity additem) Item_GenericAbsorbItem;

entity(string name, string pickupmodel, float carrylimit, float itemnum) ItemClass_Register;
void() ItemClass_RegisterDefaultClasses;
entity(string name) ItemClass_FindByName;

entity(entity original) Item_Clone;
entity(entity aitemclass) Item_Create;
entity(string name) Item_CreateByName;
void(entity item) Item_Destroy;
entity(string name, float initialcount, vector org) Item_SpawnEasy;
entity(entity item, float amount) Item_Split;
float(entity item, float adjust) Item_AdjustQuantity;

float(entity character) Inventory_GetBulk;
float(entity character) Inventory_GetBulkLimit;

entity(entity character, entity item) Inventory_GetNextItem;
entity(entity character, string name) Inventory_ItemByName;
void(entity character, entity item) Inventory_AttachItem;
void(entity character, entity item) Inventory_DetachItem;
float(entity character, entity giveitem) Inventory_AbsorbItem;
void(entity character, entity item) Inventory_DropItem;
void(entity character, entity item) Inventory_PickupItem;
float(entity character, string name, float itemcount) Inventory_DropByName;
float(entity character, string name, float itemcount) Inventory_DestroyByName;

float(entity character, entity absorbcharacter) Inventory_AbsorbInventory;
float(entity character, entity absorbcharacter) Inventory_AbsorbCloneInventory;
float(entity character, string name) Inventory_Quantity;
float(entity character, string name, float adjust) Inventory_AdjustQuantity;
float(entity character, string name, float n) Inventory_SetQuantity;

/*
entity(entity character, string name, float chooseempty) Inventory_ItemWithMostCapacity;
entity(entity character, string name, float choosefull) Inventory_ItemWithLeastCapacity;
entity(entity character, string name, float choosefull) Inventory_ItemWithMostQuantity;
entity(entity character, string name, float chooseempty) Inventory_ItemWithLeastQuantity;
*/

void(entity character) updateammodisplay;

.float bulkbase;
.float bulkpercount;
.float bulklimit;
.float count;
.float count1;
.entity inventory_next;
.entity inventory_prev;

// the item class this item most closely fits
.entity itemclass;

// decides whether a character can pick up this item
.float(entity item, entity character) it_canpickup;

// absorbs quantity (count) from another item
// deducts quantity absorbed from the item, but leaves item intact
// returns amount absorbed
// (often overriden by guns so that they can absorb ammo)
.float(entity item, entity additem) it_absorbitem;

void() Item_Touch =
{
	if (other.classname == "player")
	if (other.health >= 1)
	if (other.button8)
	if (time > self.lefty)
	if (self.it_canpickup(self, other))
		Inventory_PickupItem(self, other);
};

float(entity item, entity character) Item_GenericCanPickup =
{
	return (item.bulkbase + item.bulkpercount * item.count <= character.bulklimit - Inventory_GetBulk(character));
};

float(entity item, entity additem) Item_GenericAbsorbItem =
{
	local float c;
	c = 0;
	if (item.itemclass == additem.itemclass)
	{
		c = Item_AdjustQuantity(item, additem.count);
		additem.count = additem.count - c;
	}
	return c;
};

entity(string name, string pickupmodel, float carrylimit, float itemnum) ItemClass_Register =
{
	local entity item;
	item = spawn();
	//eprint(item);
	item.classname = "playeritemclass";
	item.itemclass = item;
	item.netname = name;
	item.count = 0; // current amount in stack (not used in itemclass)
	item.count1 = carrylimit; // maximum amount in one stack
	item.count2 = 1; // per-player limit on number of stacks
	item.bulkbase = 0;
	item.bulkpercount = 0;
	item.touch = Item_Touch;
	item.it_canpickup = Item_GenericCanPickup;
	item.it_absorbitem = Item_GenericAbsorbItem;
	item.noise1 = "weapons/lock4.wav";
	item.noise2 = "weapons/lock4.wav";
	setmodel(item, pickupmodel);
	item.mdl = item.model;
	item.model = "";
	setsize(item, '-16 -16 -24', '16 16 8');
	item.items = itemnum;
	//eprint(item);
	return item;
};

void() ItemClass_RegisterDefaultClasses =
{
	//dprint("ItemClass_RegisterDefaultClasses\n");
	ItemClass_Register("axe", "progs/backpack.mdl", 1, IT_WEAPON1);
	ItemClass_Register("shotgun", "progs/backpack.mdl", 1, IT_WEAPON2);
	ItemClass_Register("supershotgun", "progs/backpack.mdl", 1, IT_WEAPON3);
	ItemClass_Register("nailgun", "progs/backpack.mdl", 1, IT_WEAPON4);
	ItemClass_Register("supernailgun", "progs/backpack.mdl", 1, IT_WEAPON5);
	ItemClass_Register("grenadelauncher", "progs/backpack.mdl", 1, IT_WEAPON6);
	ItemClass_Register("rocketlauncher", "progs/backpack.mdl", 1, IT_WEAPON7);
	ItemClass_Register("thunderbolt", "progs/backpack.mdl", 1, IT_WEAPON8);
	ItemClass_Register("plasmarifle", "progs/backpack.mdl", 1, IT_WEAPON8);
	ItemClass_Register("plasmawave", "progs/backpack.mdl", 1, IT_WEAPON8);
	ItemClass_Register("laserrifle", "progs/backpack.mdl", 1, IT_WEAPON3);
	ItemClass_Register("flamer", "progs/backpack.mdl", 1, IT_WEAPON8);

	ItemClass_Register("pistol", "progs/backpack.mdl", 1, IT_WEAPON1);
	ItemClass_Register("chainsaw", "progs/backpack.mdl", 1, IT_WEAPON1);
	ItemClass_Register("handgrenade", "progs/backpack.mdl", 1, IT_WEAPON1);
	ItemClass_Register("hopper", "progs/backpack.mdl", 1, IT_WEAPON1);
	ItemClass_Register("prickler", "progs/backpack.mdl", 1, IT_WEAPON1);
	ItemClass_Register("scattergun", "progs/backpack.mdl", 1, IT_WEAPON1);
	ItemClass_Register("rifle", "progs/backpack.mdl", 1, IT_WEAPON1);
	ItemClass_Register("machinegun", "progs/backpack.mdl", 1, IT_WEAPON1);
	ItemClass_Register("vulcan", "progs/backpack.mdl", 1, IT_WEAPON1);
	ItemClass_Register("executioner", "progs/backpack.mdl", 1, IT_WEAPON1);
	ItemClass_Register("jackhammer", "progs/backpack.mdl", 1, IT_WEAPON1);
	ItemClass_Register("grenadelauncher2", "progs/backpack.mdl", 1, IT_WEAPON1);
	ItemClass_Register("backpackmortar", "progs/backpack.mdl", 1, IT_WEAPON1);
	ItemClass_Register("incinerator", "progs/backpack.mdl", 1, IT_WEAPON1);
	ItemClass_Register("railgun", "progs/backpack.mdl", 1, IT_WEAPON1);

	ItemClass_Register("mplasmacannon", "progs/backpack.mdl", 1, IT_WEAPON1);
	ItemClass_Register("mchargecannon", "progs/backpack.mdl", 1, IT_WEAPON1);
	ItemClass_Register("micecannon", "progs/backpack.mdl", 1, IT_WEAPON4);
	ItemClass_Register("mbomblauncher", "progs/backpack.mdl", 1, IT_WEAPON6);
	ItemClass_Register("mmissilelauncher", "progs/backpack.mdl", 1, IT_WEAPON7);
	ItemClass_Register("mgrapple", "progs/backpack.mdl", 1, IT_WEAPON1);
	ItemClass_Register("mmulticannon", "progs/backpack.mdl", 1, IT_WEAPON1);

	ItemClass_Register("shells", "progs/backpack.mdl", AMMOMAX_SHELLS, IT_SHELLS);
	ItemClass_Register("nails", "progs/backpack.mdl", AMMOMAX_NAILS, IT_NAILS);
	ItemClass_Register("rockets", "progs/backpack.mdl", AMMOMAX_ROCKETS, IT_ROCKETS);
	ItemClass_Register("cells", "progs/backpack.mdl", AMMOMAX_CELLS, IT_CELLS);
	ItemClass_Register("sliverammo", "progs/backpack.mdl", 100, IT_NAILS);
	ItemClass_Register("rifleammo", "progs/backpack.mdl", 50, IT_SHELLS);
	ItemClass_Register("machinegunammo", "progs/backpack.mdl", 250, IT_NAILS);
	ItemClass_Register("executionerammo", "progs/backpack.mdl", 100, IT_ROCKETS);
	ItemClass_Register("incineratorammo", "progs/backpack.mdl", 250, IT_CELLS);
	ItemClass_Register("railgunammo", "progs/backpack.mdl", 50, IT_SHELLS);
};

entity(string name) ItemClass_FindByName =
{
	local entity aitemclass;
	aitemclass = findchain(classname, "playeritemclass");
	if (aitemclass == world)
	{
		ItemClass_RegisterDefaultClasses();
		aitemclass = findchain(classname, "playeritemclass");
	}
	while (aitemclass != world && aitemclass.netname != name)
		aitemclass = aitemclass.chain;
	return aitemclass;
}

entity(entity original) Item_Clone =
{
	local entity item;
	if (original == world)
		return world;

	item = spawn();
	item.classname = "playeritem";
	item.owner = world;
	item.itemclass = original.itemclass;
	item.netname = original.netname;
	item.count = original.count;
	item.count1 = original.count1;
	item.count2 = original.count2;
	item.bulkbase = original.bulkbase;
	item.bulkpercount = original.bulkpercount;
	item.touch = original.touch;
	item.it_canpickup = original.it_canpickup;
	item.it_absorbitem = original.it_absorbitem;
	item.noise1 = original.noise1;
	item.noise2 = original.noise2;
	setmodel(item, original.mdl);
	setsize(item, original.mins, original.maxs);
	setorigin(item, original.origin);
	item.mdl = item.model;
	return item;
};

entity(entity aitemclass) Item_Create =
{
	local entity item;
	dprint("Item_Create\n");
	item = Item_Clone(aitemclass);
	if (item != world)
	{
		// invisible until Item_Drop is called
		item.model = "";
	}
	return item;
};

entity(string name) Item_CreateByName =
{
	return Item_Create(ItemClass_FindByName(name));
};

void(entity item) Item_Destroy =
{
	Inventory_DetachItem(item.owner, item);
	remove(item);
};

entity(string name, float initialcount, vector org) Item_SpawnEasy =
{
	local entity item;
	item = Item_CreateByName(name);
	if (item == world)
		return world;
	item.count = initialcount;
	item.velocity = '0 0 400' + randomvec() * 200;
	item.angles = randompos('0 0 0', '0 360 0');
	item.flags = 0;
	item.solid = SOLID_TRIGGER;
	item.movetype = MOVETYPE_TOSS;
	item.model = item.mdl;
	setorigin(item, org);
	return item;
};

entity(entity item, float amount) Item_Split =
{
	local entity newitem;
	if (amount > item.count)
		amount = item.count;
	newitem = Item_Clone(item);
	newitem.count = amount;
	item.count = item.count - amount;
	return newitem;
};

float(entity item, float adjust) Item_AdjustQuantity =
{
	local float c, c2;
	if (adjust > 0)
	{
		// begin with remaining capacity
		c = item.count1 - item.count;
		// limit by adjust
		if (c > adjust)
			c = adjust;
		// abort if we ran out
		if (c <= 0)
			return 0;
		if (item.owner)
		if (item.bulkpercount)
		{
			// limit by remaining bulk capacity
			c2 = item.owner.bulklimit - Inventory_GetBulk(item.owner);
			c2 = floor(c2 / item.bulkpercount);
			if (c > c2)
				c = c2;
		}
		// abort if we ran out
		if (c <= 0)
			return 0;
	}
	else if (adjust < 0)
	{
		c = 0 - item.count;
		if (c < adjust)
			c = adjust;
		if (c >= 0)
			return 0;
	}
	// add the calculated quantity to item
	item.count = item.count + c;
	// return amount of adjustment
	return c;
};

float(entity character) Inventory_GetBulk =
{
	local float b;
	local entity item;
	b = 0;
	item = character.inventory_next;
	if (item == world)
		item = character.inventory_next = character.inventory_prev = character;
	while (item != character)
	{
		b = b + item.bulkbase + item.bulkpercount * item.count;
		item = item.inventory_next;
	}
	return b;
};

float(entity character) Inventory_GetBulkLimit =
{
	return character.bulklimit;
};

entity(entity character, entity item) Inventory_GetNextItem =
{
	if (item == world)
	{
		item = character.inventory_next;
		if (item == world)
			item = character.inventory_next = character.inventory_prev = character;
		if (item == character)
			item = world;
		return item;
	}
	if (item.inventory_next == item.owner)
		return world;
	return item.inventory_next;
};

entity(entity character, string name) Inventory_ItemByName =
{
	local entity item;
	item = character.inventory_next;
	if (item == world)
		item = character.inventory_next = character.inventory_prev = character;
	while (item != character)
	{
		if (item.netname == name)
			return item;
		item = item.inventory_next;
	}
	return world;
};

void(entity character, entity item) Inventory_AttachItem =
{
	Inventory_DetachItem(character, item);

	item.movetype = MOVETYPE_NONE;
	item.solid = SOLID_NOT;
	item.model = "";
	item.owner = character;
	if (item.owner.inventory_next == world)
		item.owner.inventory_next = item.owner.inventory_prev = item.owner;
	item.inventory_next = item.owner;
	item.inventory_prev = item.inventory_next.inventory_prev;
	item.inventory_next.inventory_prev = item;
	item.inventory_prev.inventory_next = item;
};

void(entity character, entity item) Inventory_DetachItem =
{
	if (item.inventory_next)
	{
		item.owner = world;
		item.inventory_next.inventory_prev = item.inventory_prev;
		item.inventory_prev.inventory_next = item.inventory_next;
		item.inventory_next = world;
		item.inventory_prev = world;
	}
};

float(entity character, entity giveitem) Inventory_AbsorbItem =
{
	local entity item;
	local float c, total;
	c = 0;
	total = 0;
	item = Inventory_GetNextItem(character, world);
	while (item)
	{
		total = total + item.it_absorbitem(item, giveitem);
		if (giveitem.count == 0)
		{
			// fully absorbed (giveitem empty)
			return total;
		}
		if (item.itemclass == giveitem.itemclass)
			c = c + 1;
		item = Inventory_GetNextItem(character, item);
	}
	// some remains, check if we can spawn an item to hold it
	//eprint(giveitem);
	if (c < giveitem.itemclass.count2)
	if (giveitem.bulkbase + giveitem.bulkpercount * giveitem.count <= character.bulklimit - Inventory_GetBulk(character))
	{
		// clone the giveitem and add it to inventory
		item = Item_Clone(giveitem);
		//eprint(item);
		Inventory_AttachItem(character, item);
		// the giveitem is now empty
		total = total + giveitem.count;
		giveitem.count = 0;
	}
	return total;
};

void(entity character, entity item) Inventory_DropItem =
{
	if (character == world)
	{
		bprint("Inventory_DropItem: character == world\n");
		return;
	}
	Inventory_DetachItem(character, item);
	item.velocity = character.velocity + '0 0 400' + randomvec() * 200;
	item.angles = character.angles;
	item.avelocity = character.avelocity;
	item.flags = 0;
	item.solid = SOLID_TRIGGER;
	item.movetype = MOVETYPE_TOSS;
	item.model = item.mdl;
	item.lefty = time + 0.1;
	setorigin(item, character.origin);
	if (item.noise2 != "")
		sound(item, CHAN_BODY, item.noise2, 1, ATTN_STATIC);
};

void(entity character, entity item) Inventory_PickupItem =
{
	local string s;
	local float c;
	c = Inventory_AbsorbItem(character, item);
	if (c)
	{
		if (item.noise1 != "")
			sound(item, CHAN_BODY, item.noise1, 1, ATTN_STATIC);
		if (character.flags & FL_CLIENT)
		{
			s = ftos(c);
			sprint(character, "You got ");
			sprint(character, s);
			sprint(character, " ");
			sprint(character, item.netname);
			sprint(character, "\n");
		}
		if (item.count == 0)
			Item_Destroy(item);
	}
};

float(entity character, string name, float itemcount) Inventory_DropByName =
{
	local float c;
	local entity item;
	c = 0;
	item = Inventory_GetNextItem(character, world);
	while (item)
	{
		if (name == "" || item.netname == name)
		{
			Inventory_DropItem(character, item);
			item = world;
			c = c + 1;
			if (c >= itemcount)
				return c;
		}
		item = Inventory_GetNextItem(character, item);
	}
	return c;
}

float(entity character, string name, float itemcount) Inventory_DestroyByName =
{
	local float c;
	local entity item;

	c = 0;
	item = Inventory_GetNextItem(character, world);
	while (item)
	{
		if (name == "" || item.netname == name)
		{
			Item_Destroy(item);
			item = world;
			c = c + 1;
			if (c >= itemcount)
				return c;
		}
		item = Inventory_GetNextItem(character, item);
	}
	return c;
}

float(entity character, entity absorbcharacter) Inventory_AbsorbInventory =
{
	local float c;
	local entity item;

	c = 0;
	item = Inventory_GetNextItem(absorbcharacter, world);
	while (item)
	{
		Inventory_AbsorbItem(character, item);
		if (item.count == 0)
		{
			Item_Destroy(item);
			item = world;
			c = c + 1;
		}
		item = Inventory_GetNextItem(absorbcharacter, item);
	}
	return c;
}

float(entity character, entity absorbcharacter) Inventory_AbsorbCloneInventory =
{
	local float c, quantity;
	local entity item;

	c = 0;
	item = Inventory_GetNextItem(absorbcharacter, world);
	while (item)
	{
		quantity = item.count;
		Inventory_AbsorbItem(character, item);
		if (item.count < quantity)
			c = c + 1;
		item.count = quantity;
		item = Inventory_GetNextItem(absorbcharacter, item);
	}
	return c;
}

float(entity character, string name) Inventory_Quantity =
{
	local float c;
	local entity item;
	c = 0;
	item = character.inventory_next;
	if (item == world)
		item = character.inventory_next = character.inventory_prev = character;
	while (item != character)
	{
		if (item.netname == name)
			c = c + item.count;
		item = item.inventory_next;
	}
	return c;
};

float(entity character, string name, float adjust) Inventory_AdjustQuantity =
{
	local entity item, aitemclass;
	local float c, d, total;
	//dprint("Inventory_AdjustQuantity(");dprint(character.netname);dprint(", ");dprint(name);dprint(", ");dprint(ftos(adjust));dprint(") changes ");c = Inventory_Quantity(character, name);dprint(ftos(c));dprint(" to ");dprint(ftos(c + adjust));dprint("\n");
	c = 0;
	total = adjust;
	item = Inventory_GetNextItem(character, world);
	while (item && adjust != 0)
	{
		if (item.itemclass.netname == name)
		{
			c = c + 1;
			adjust = adjust - Item_AdjustQuantity(item, adjust);
			if (item.count == 0)
			{
				Item_Destroy(item);
				item = world;
				c = 0;
			}
		}
		item = Inventory_GetNextItem(character, item);
	}
	// some may remain, check if we can spawn an item to hold it
	//dprint("adjust ");dprint(ftos(adjust));dprint("\n");
	if (adjust > 0)
	{
		aitemclass = ItemClass_FindByName(name);
		//eprint(aitemclass);
		d = aitemclass.count2;
		while (adjust > 0 && c < d)
		{
			//eprint(aitemclass);
			if (aitemclass.bulkbase + aitemclass.bulkpercount * adjust <= character.bulklimit - Inventory_GetBulk(character))
			{
				// create item and add it to inventory
				item = Item_Create(aitemclass);
				item.count = adjust;
				if (item.count > item.count1)
					item.count = item.count1;
				adjust = adjust - item.count;
				c = c + 1;
				//eprint(item);
				Inventory_AttachItem(character, item);
			}
			else
				c = d;
		}
	}
	total = total - adjust;
	return total;
};

float(entity character, string name, float n) Inventory_SetQuantity =
{
	n = n - Inventory_Quantity(character, name);
	return Inventory_AdjustQuantity(character, name, n);
}

void(entity character) Inventory_ConvertFromQuakeInventory =
{
	if (character.ammo_shells > 0)
		Inventory_AdjustQuantity(character, "shells", character.ammo_shells);
	character.ammo_shells = 0;
	if (character.ammo_nails > 0)
		Inventory_AdjustQuantity(character, "nails", character.ammo_nails);
	character.ammo_nails = 0;
	if (character.ammo_rockets > 0)
		Inventory_AdjustQuantity(character, "rockets", character.ammo_rockets);
	character.ammo_rockets = 0;
	if (character.ammo_cells > 0)
		Inventory_AdjustQuantity(character, "cells", character.ammo_cells);
	character.ammo_cells = 0;
	if (character.items & IT_WEAPON1)
		Inventory_AdjustQuantity(character, "axe", 1);
	if (character.items & IT_WEAPON2)
		Inventory_AdjustQuantity(character, "shotgun", 1);
	if (character.items & IT_WEAPON3)
		Inventory_AdjustQuantity(character, "supershotgun", 1);
	if (character.items & IT_WEAPON4)
		Inventory_AdjustQuantity(character, "nailgun", 1);
	if (character.items & IT_WEAPON5)
		Inventory_AdjustQuantity(character, "supernailgun", 1);
	if (character.items & IT_WEAPON6)
		Inventory_AdjustQuantity(character, "grenadelauncher", 1);
	if (character.items & IT_WEAPON7)
		Inventory_AdjustQuantity(character, "rocketlauncher", 1);
	if (character.items & IT_WEAPON8)
		Inventory_AdjustQuantity(character, "thunderbolt", 1);
	// TODO: convert other items? (powerups)
	character.items = character.items - (character.items & (IT_WEAPON1 | IT_WEAPON2 | IT_WEAPON3 | IT_WEAPON4 | IT_WEAPON5 | IT_WEAPON6 | IT_WEAPON7 | IT_WEAPON8 | IT_WEAPON9 | IT_WEAPON10));
	// TODO: convert .armorvalue/.armortype?
};

void(entity player) Inventory_ToParms =
{
	local entity aitemclass;
	local float c;
	//eprint(player);
	lhbitparms_encode_begin(0, 16);
	lhbitparms_encodebits(player.items, 16777216);
	lhbitparms_encodebits(bound(1, player.max_health, 1023), 1024);
	lhbitparms_encodebits(bound(1, player.health, 1023), 1024);
	lhbitparms_encodebits(bound(0, player.armorvalue, 1023), 1024);
	lhbitparms_encodebits(bound(0, player.armortype * 10, 10), 11);
	lhbitparms_encodebits(WeaponClassToNumber(player.weaponclass), 32);
	aitemclass = findchain(classname, "playeritemclass");
	if (aitemclass == world)
	{
		ItemClass_RegisterDefaultClasses();
		aitemclass = findchain(classname, "playeritemclass");
	}
	while (aitemclass)
	{
		c = Inventory_Quantity(player, aitemclass.netname);
		lhbitparms_encodebits(c, aitemclass.count1 + 1);
		aitemclass = aitemclass.chain;
	}
	lhbitparms_encode_finish();
};

void(entity wclass, float instantswitch) wsetweapon;
float metroidmode;
void(entity player) Inventory_FromParms =
{
	local entity aitemclass, wclass, oldself;
	local float c, valid;
	oldself = self;
	self = player;
	if (findchain(classname, "playeritemclass") == world)
		ItemClass_RegisterDefaultClasses();
	valid = lhfp_decode(parm1);
	//dprint("valid is ");dprint(ftos(valid));dprint("\n");
	if (deathmatch == DM_FRAGFEST || deathmatch == DM_ELIM)
	{
		//dprint("deathmatch full pack\n");
		self.items = 0;
		self.health = STARTPARMSELIM_HEALTH;
		self.max_health = STARTPARMSELIM_MAXHEALTH;
		self.armorvalue = STARTPARMSELIM_ARMORVALUE;
		self.armortype = STARTPARMSELIM_ARMORTYPE;
		Inventory_SetQuantity(self, "shells", STARTPARMSELIM_AMMO_SHELLS);
		Inventory_SetQuantity(self, "nails", STARTPARMSELIM_AMMO_NAILS);
		Inventory_SetQuantity(self, "rockets", STARTPARMSELIM_AMMO_ROCKETS);
		Inventory_SetQuantity(self, "cells", STARTPARMSELIM_AMMO_CELLS);
		Inventory_SetQuantity(self, "axe", 1);
		Inventory_SetQuantity(self, "shotgun", 1);
		Inventory_SetQuantity(self, "supershotgun", 1);
		Inventory_SetQuantity(self, "nailgun", 1);
		Inventory_SetQuantity(self, "supernailgun", 1);
		Inventory_SetQuantity(self, "grenadelauncher", 1);
		Inventory_SetQuantity(self, "rocketlauncher", 1);
		Inventory_SetQuantity(self, "thunderbolt", 1);
		Inventory_SetQuantity(self, "plasmarifle", 1);
		self.weaponclass = W_BestWeaponClass(TRUE);
	}
	else if (deathmatch)
	{
		//dprint("deathmatch\n");
		self.items = 0;
		self.health = STARTPARMSDM_HEALTH;
		self.max_health = STARTPARMSDM_MAXHEALTH;
		self.armorvalue = STARTPARMSDM_ARMORVALUE;
		self.armortype = STARTPARMSDM_ARMORTYPE;
		Inventory_SetQuantity(self, "shells", STARTPARMSDM_AMMO_SHELLS);
		Inventory_SetQuantity(self, "nails", STARTPARMSDM_AMMO_NAILS);
		Inventory_SetQuantity(self, "rockets", STARTPARMSDM_AMMO_ROCKETS);
		Inventory_SetQuantity(self, "cells", STARTPARMSDM_AMMO_CELLS);
		Inventory_SetQuantity(self, "axe", 1);
		Inventory_SetQuantity(self, "shotgun", 1);
		self.weaponclass = W_BestWeaponClass(TRUE);
	}
	else if (valid)
	{
		//eprint(self);
		//dprint("valid parms\n");
		lhbitparms_decode_begin(0, 16);
		self.items = lhbitparms_decodebits(16777216);
		self.max_health = lhbitparms_decodebits(1024);
		self.health = lhbitparms_decodebits(1024);
		self.armorvalue = lhbitparms_decodebits(1024);
		self.armortype = lhbitparms_decodebits(11) / 10;
		self.weaponclass = NumberToWeaponClass(lhbitparms_decodebits(32));
		aitemclass = findchain(classname, "playeritemclass");
		if (aitemclass == world)
		{
			ItemClass_RegisterDefaultClasses();
			aitemclass = findchain(classname, "playeritemclass");
		}
		while (aitemclass)
		{
			c = lhbitparms_decodebits(aitemclass.count1 + 1);
			Inventory_SetQuantity(self, aitemclass.netname, c);
			aitemclass = aitemclass.chain;
		}
		//eprint(self);
	}
	else if (metroidmode)
	{
		//dprint("metroidmode\n");
		self.items = 0;
		self.health = STARTPARMSMCTF_HEALTH;
		self.max_health = STARTPARMSMCTF_MAXHEALTH;
		self.armorvalue = STARTPARMSMCTF_ARMORVALUE;
		self.armortype = STARTPARMSMCTF_ARMORTYPE;
		Inventory_SetQuantity(self, "shells", STARTPARMSMCTF_AMMO_SHELLS);
		Inventory_SetQuantity(self, "nails", STARTPARMSMCTF_AMMO_NAILS);
		Inventory_SetQuantity(self, "rockets", STARTPARMSMCTF_AMMO_ROCKETS);
		Inventory_SetQuantity(self, "cells", STARTPARMSMCTF_AMMO_CELLS);
		Inventory_SetQuantity(self, "mplasmacannon", 1);
		self.weaponclass = W_BestWeaponClass(TRUE);
	}
	else
	{
		//dprint("singleplayer\n");
		//eprint(self);
		self.items = 0;
		self.health = STARTPARMSSP_HEALTH;
		self.max_health = STARTPARMSSP_MAXHEALTH;
		self.armorvalue = STARTPARMSSP_ARMORVALUE;
		self.armortype = STARTPARMSSP_ARMORTYPE;
		Inventory_SetQuantity(self, "shells", STARTPARMSSP_AMMO_SHELLS);
		Inventory_SetQuantity(self, "nails", STARTPARMSSP_AMMO_NAILS);
		Inventory_SetQuantity(self, "rockets", STARTPARMSSP_AMMO_ROCKETS);
		Inventory_SetQuantity(self, "cells", STARTPARMSSP_AMMO_CELLS);
		Inventory_SetQuantity(self, "axe", 1);
		Inventory_SetQuantity(self, "shotgun", 1);
		self.weaponclass = W_BestWeaponClass(TRUE);
		//eprint(self);
	}
	wsetweapon(self.weaponclass, TRUE);
	// safety checks
	if (self.health < 1)
		self.health = 1;
	if (self.max_health < 1)
		self.max_health = 100;
	self.bodyhealth = self.health + 100;
	self = oldself;
};

void(entity character) updateammodisplay =
{
	local entity item;
	character.ammo_shells = Inventory_Quantity(character, "shells");
	character.ammo_nails = Inventory_Quantity(character, "nails");
	character.ammo_rockets = Inventory_Quantity(character, "rockets");
	character.ammo_cells = Inventory_Quantity(character, "cells");
	character.weapon = 0;
	if (character.weaponclass)
	{
		item = Inventory_ItemByName(character, character.weaponclass.w_item);
		character.weapon = item.itemclass.items;
	}
	character.items = character.items - (character.items & (IT_WEAPON1 | IT_WEAPON2 | IT_WEAPON3 | IT_WEAPON4 | IT_WEAPON5 | IT_WEAPON6 | IT_WEAPON7 | IT_WEAPON8 | IT_WEAPON9 | IT_WEAPON10));
	item = Inventory_GetNextItem(character, world);
	while (item)
	{
		if (item.itemclass.items)
			character.items = character.items | item.itemclass.items;
		item = Inventory_GetNextItem(character, item);
	}
};


