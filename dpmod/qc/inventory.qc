
void() Item_Touch;
float(entity item, entity character) Item_GenericCanPickup;
float(entity item, entity additem) Item_GenericAbsorbItem;

entity(string name) ItemClass_Register;
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

entity(string name) ItemClass_Register =
{
	local entity item;
	item = spawn();
	item.classname = "playeritemclass";
	item.itemclass = item;
	item.netname = name;
	item.count = 1;
	item.count1 = 1;
	item.count2 = 1;
	item.bulkbase = 0;
	item.bulkpercount = 0;
	item.touch = Item_Touch;
	item.it_canpickup = Item_GenericCanPickup;
	item.it_absorbitem = Item_GenericAbsorbItem;
	item.noise1 = "weapons/lock4.wav";
	item.noise2 = "weapons/lock4.wav";
	return item;
};

void() ItemClass_RegisterDefaultClasses =
{
	local entity item;

	item = ItemClass_Register("shells");
	setmodel(item, "progs/backpack.mdl");
	item.mdl = item.model;
	item.model = "";
	setsize(item, '-16 -16 -24', '16 16 8');
	item.count1 = AMMOMAX_SHELLS;
	//item.bulkbase = 0;
	//item.bulkpercount = 0.1;

	item = ItemClass_Register("nails");
	setmodel(item, "progs/backpack.mdl");
	item.mdl = item.model;
	item.model = "";
	setsize(item, '-16 -16 -24', '16 16 8');
	item.count1 = AMMOMAX_NAILS;
	//item.bulkbase = 0;
	//item.bulkpercount = 0.05;

	item = ItemClass_Register("rockets");
	setmodel(item, "progs/backpack.mdl");
	item.mdl = item.model;
	item.model = "";
	setsize(item, '-16 -16 -24', '16 16 8');
	item.count1 = AMMOMAX_ROCKETS;
	//item.bulkbase = 0;
	//item.bulkpercount = 0.5;

	item = ItemClass_Register("cells");
	setmodel(item, "progs/backpack.mdl");
	item.mdl = item.model;
	item.model = "";
	setsize(item, '-16 -16 -24', '16 16 8');
	item.count1 = AMMOMAX_CELLS;
	//item.bulkbase = 0;
	//item.bulkpercount = 0.1;

	item = ItemClass_Register("pistol");
	setmodel(item, "progs/backpack.mdl");
	item.mdl = item.model;
	item.model = "";
	setsize(item, '-16 -16 -24', '16 16 8');
	item.count1 = 1;
	//item.bulkbase = 0;
	//item.bulkpercount = 0.1;
	item.items = IT_WEAPON1;

	item = ItemClass_Register("shotgun");
	setmodel(item, "progs/backpack.mdl");
	item.mdl = item.model;
	item.model = "";
	setsize(item, '-16 -16 -24', '16 16 8');
	item.count1 = 1;
	//item.bulkbase = 0;
	//item.bulkpercount = 0.1;
	item.items = IT_WEAPON2;

	item = ItemClass_Register("supershotgun");
	setmodel(item, "progs/backpack.mdl");
	item.mdl = item.model;
	item.model = "";
	setsize(item, '-16 -16 -24', '16 16 8');
	item.count1 = 1;
	//item.bulkbase = 0;
	//item.bulkpercount = 0.1;
	item.items = IT_WEAPON3;

	item = ItemClass_Register("nailgun");
	setmodel(item, "progs/backpack.mdl");
	item.mdl = item.model;
	item.model = "";
	setsize(item, '-16 -16 -24', '16 16 8');
	item.count1 = 1;
	//item.bulkbase = 0;
	//item.bulkpercount = 0.1;
	item.items = IT_WEAPON4;

	item = ItemClass_Register("supernailgun");
	setmodel(item, "progs/backpack.mdl");
	item.mdl = item.model;
	item.model = "";
	setsize(item, '-16 -16 -24', '16 16 8');
	item.count1 = 1;
	//item.bulkbase = 0;
	//item.bulkpercount = 0.1;
	item.items = IT_WEAPON5;

	item = ItemClass_Register("grenadelauncher");
	setmodel(item, "progs/backpack.mdl");
	item.mdl = item.model;
	item.model = "";
	setsize(item, '-16 -16 -24', '16 16 8');
	item.count1 = 1;
	//item.bulkbase = 0;
	//item.bulkpercount = 0.1;
	item.items = IT_WEAPON6;

	item = ItemClass_Register("rocketlauncher");
	setmodel(item, "progs/backpack.mdl");
	item.mdl = item.model;
	item.model = "";
	setsize(item, '-16 -16 -24', '16 16 8');
	item.count1 = 1;
	//item.bulkbase = 0;
	//item.bulkpercount = 0.1;
	item.items = IT_WEAPON7;

	item = ItemClass_Register("thunderbolt");
	setmodel(item, "progs/backpack.mdl");
	item.mdl = item.model;
	item.model = "";
	setsize(item, '-16 -16 -24', '16 16 8');
	item.count1 = 1;
	//item.bulkbase = 0;
	//item.bulkpercount = 0.1;
	item.items = IT_WEAPON8;

	item = ItemClass_Register("plasmarifle");
	setmodel(item, "progs/backpack.mdl");
	item.mdl = item.model;
	item.model = "";
	setsize(item, '-16 -16 -24', '16 16 8');
	item.count1 = 1;
	//item.bulkbase = 0;
	//item.bulkpercount = 0.1;
	item.items = IT_WEAPON8;

	item = ItemClass_Register("plasmawave");
	setmodel(item, "progs/backpack.mdl");
	item.mdl = item.model;
	item.model = "";
	setsize(item, '-16 -16 -24', '16 16 8');
	item.count1 = 1;
	//item.bulkbase = 0;
	//item.bulkpercount = 0.1;
	item.items = IT_WEAPON8;

	item = ItemClass_Register("laserrifle");
	setmodel(item, "progs/backpack.mdl");
	item.mdl = item.model;
	item.model = "";
	setsize(item, '-16 -16 -24', '16 16 8');
	item.count1 = 1;
	//item.bulkbase = 0;
	//item.bulkpercount = 0.1;
	item.items = IT_WEAPON3;

	item = ItemClass_Register("axe");
	setmodel(item, "progs/backpack.mdl");
	item.mdl = item.model;
	item.model = "";
	setsize(item, '-16 -16 -24', '16 16 8');
	item.count1 = 1;
	//item.bulkbase = 0;
	//item.bulkpercount = 0.1;
	item.items = IT_WEAPON1;

	item = ItemClass_Register("chainsaw");
	setmodel(item, "progs/backpack.mdl");
	item.mdl = item.model;
	item.model = "";
	setsize(item, '-16 -16 -24', '16 16 8');
	item.count1 = 1;
	//item.bulkbase = 0;
	//item.bulkpercount = 0.1;
	item.items = IT_WEAPON1;

	item = ItemClass_Register("handgrenade");
	setmodel(item, "progs/backpack.mdl");
	item.mdl = item.model;
	item.model = "";
	setsize(item, '-16 -16 -24', '16 16 8');
	item.count1 = 1;
	//item.bulkbase = 0;
	//item.bulkpercount = 0.1;
	item.items = IT_WEAPON1;

	item = ItemClass_Register("hopper");
	setmodel(item, "progs/backpack.mdl");
	item.mdl = item.model;
	item.model = "";
	setsize(item, '-16 -16 -24', '16 16 8');
	item.count1 = 1;
	//item.bulkbase = 0;
	//item.bulkpercount = 0.1;
	item.items = IT_WEAPON1;

	item = ItemClass_Register("prickler");
	setmodel(item, "progs/backpack.mdl");
	item.mdl = item.model;
	item.model = "";
	setsize(item, '-16 -16 -24', '16 16 8');
	item.count1 = 1;
	//item.bulkbase = 0;
	//item.bulkpercount = 0.1;
	item.items = IT_WEAPON1;

	item = ItemClass_Register("scattergun");
	setmodel(item, "progs/backpack.mdl");
	item.mdl = item.model;
	item.model = "";
	setsize(item, '-16 -16 -24', '16 16 8');
	item.count1 = 1;
	//item.bulkbase = 0;
	//item.bulkpercount = 0.1;
	item.items = IT_WEAPON1;

	item = ItemClass_Register("rifle");
	setmodel(item, "progs/backpack.mdl");
	item.mdl = item.model;
	item.model = "";
	setsize(item, '-16 -16 -24', '16 16 8');
	item.count1 = 1;
	//item.bulkbase = 0;
	//item.bulkpercount = 0.1;
	item.items = IT_WEAPON1;

	item = ItemClass_Register("machinegun");
	setmodel(item, "progs/backpack.mdl");
	item.mdl = item.model;
	item.model = "";
	setsize(item, '-16 -16 -24', '16 16 8');
	item.count1 = 1;
	//item.bulkbase = 0;
	//item.bulkpercount = 0.1;
	item.items = IT_WEAPON1;

	item = ItemClass_Register("vulcan");
	setmodel(item, "progs/backpack.mdl");
	item.mdl = item.model;
	item.model = "";
	setsize(item, '-16 -16 -24', '16 16 8');
	item.count1 = 1;
	//item.bulkbase = 0;
	//item.bulkpercount = 0.1;
	item.items = IT_WEAPON1;

	item = ItemClass_Register("executioner");
	setmodel(item, "progs/backpack.mdl");
	item.mdl = item.model;
	item.model = "";
	setsize(item, '-16 -16 -24', '16 16 8');
	item.count1 = 1;
	//item.bulkbase = 0;
	//item.bulkpercount = 0.1;
	item.items = IT_WEAPON1;

	item = ItemClass_Register("jackhammer");
	setmodel(item, "progs/backpack.mdl");
	item.mdl = item.model;
	item.model = "";
	setsize(item, '-16 -16 -24', '16 16 8');
	item.count1 = 1;
	//item.bulkbase = 0;
	//item.bulkpercount = 0.1;
	item.items = IT_WEAPON1;

	item = ItemClass_Register("grenadelauncher2");
	setmodel(item, "progs/backpack.mdl");
	item.mdl = item.model;
	item.model = "";
	setsize(item, '-16 -16 -24', '16 16 8');
	item.count1 = 1;
	//item.bulkbase = 0;
	//item.bulkpercount = 0.1;
	item.items = IT_WEAPON1;

	item = ItemClass_Register("backpackmortar");
	setmodel(item, "progs/backpack.mdl");
	item.mdl = item.model;
	item.model = "";
	setsize(item, '-16 -16 -24', '16 16 8');
	item.count1 = 1;
	//item.bulkbase = 0;
	//item.bulkpercount = 0.1;
	item.items = IT_WEAPON1;

	item = ItemClass_Register("incinerator");
	setmodel(item, "progs/backpack.mdl");
	item.mdl = item.model;
	item.model = "";
	setsize(item, '-16 -16 -24', '16 16 8');
	item.count1 = 1;
	//item.bulkbase = 0;
	//item.bulkpercount = 0.1;
	item.items = IT_WEAPON1;

	item = ItemClass_Register("railgun");
	setmodel(item, "progs/backpack.mdl");
	item.mdl = item.model;
	item.model = "";
	setsize(item, '-16 -16 -24', '16 16 8');
	item.count1 = 1;
	//item.bulkbase = 0;
	//item.bulkpercount = 0.1;
	item.items = IT_WEAPON1;

	item = ItemClass_Register("sliverammo");
	setmodel(item, "progs/backpack.mdl");
	item.mdl = item.model;
	item.model = "";
	setsize(item, '-16 -16 -24', '16 16 8');
	item.count1 = 100;
	//item.bulkbase = 0;
	//item.bulkpercount = 0.1;

	item = ItemClass_Register("rifleammo");
	setmodel(item, "progs/backpack.mdl");
	item.mdl = item.model;
	item.model = "";
	setsize(item, '-16 -16 -24', '16 16 8');
	item.count1 = 50;
	//item.bulkbase = 0;
	//item.bulkpercount = 0.1;

	item = ItemClass_Register("machinegunammo");
	setmodel(item, "progs/backpack.mdl");
	item.mdl = item.model;
	item.model = "";
	setsize(item, '-16 -16 -24', '16 16 8');
	item.count1 = 250;
	//item.bulkbase = 0;
	//item.bulkpercount = 0.1;

	item = ItemClass_Register("executionerammo");
	setmodel(item, "progs/backpack.mdl");
	item.mdl = item.model;
	item.model = "";
	setsize(item, '-16 -16 -24', '16 16 8');
	item.count1 = 100;
	//item.bulkbase = 0;
	//item.bulkpercount = 0.1;

	item = ItemClass_Register("incineratorammo");
	setmodel(item, "progs/backpack.mdl");
	item.mdl = item.model;
	item.model = "";
	setsize(item, '-16 -16 -24', '16 16 8');
	item.count1 = 250;
	//item.bulkbase = 0;
	//item.bulkpercount = 0.1;

	item = ItemClass_Register("railgunammo");
	setmodel(item, "progs/backpack.mdl");
	item.mdl = item.model;
	item.model = "";
	setsize(item, '-16 -16 -24', '16 16 8');
	item.count1 = 50;
	//item.bulkbase = 0;
	//item.bulkpercount = 0.1;
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
	if (adjust > 0)
	{
		aitemclass = ItemClass_FindByName(name);
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

/*
entity(entity character, string name, float chooseempty) Inventory_ItemWithMostCapacity =
{
	local entity item, best;
	local float capacity, bestcapacity;
	item = character.inventory_next;
	if (item == world)
		item = character.inventory_next = character.inventory_prev = character;
	best = world;
	bestcapacity = 0;
	while (item != character)
	{
		if (item.netname == name)
		{
			capacity = item.count1 - item.count;
			if (capacity < item.count1 || chooseempty)
			if (bestcapacity < capacity)
			{
				bestcapacity = capacity;
				best = item;
			}
		}
		item = item.inventory_next;
	}
	return best;
};

entity(entity character, string name, float choosefull) Inventory_ItemWithLeastCapacity =
{
	local entity item, best;
	local float capacity, bestcapacity;
	item = character.inventory_next;
	if (item == world)
		item = character.inventory_next = character.inventory_prev = character;
	best = world;
	bestcapacity = 1000000000;
	while (item != character)
	{
		if (item.netname == name)
		{
			capacity = item.count1 - item.count;
			if (capacity > 0 || choosefull)
			if (bestcapacity > capacity)
			{
				bestcapacity = capacity;
				best = item;
			}
		}
		item = item.inventory_next;
	}
	return best;
};

entity(entity character, string name, float choosefull) Inventory_ItemWithMostQuantity =
{
	local entity item, best;
	local float quantity, bestquantity;
	item = character.inventory_next;
	if (item == world)
		item = character.inventory_next = character.inventory_prev = character;
	best = world;
	bestquantity = 0;
	while (item != character)
	{
		if (item.netname == name)
		{
			quantity = item.count;
			if (quantity < item.count1 || choosefull)
			if (bestquantity < quantity)
			{
				bestquantity = quantity;
				best = item;
			}
		}
		item = item.inventory_next;
	}
	return best;
};

entity(entity character, string name, float chooseempty) Inventory_ItemWithLeastQuantity =
{
	local entity item, best;
	local float quantity, bestquantity;
	item = character.inventory_next;
	if (item == world)
		item = character.inventory_next = character.inventory_prev = character;
	best = world;
	bestquantity = 0;
	while (item != character)
	{
		if (item.netname == name)
		{
			quantity = item.count;
			if (quantity > 0 || chooseempty)
			if (bestquantity < quantity)
			{
				bestquantity = quantity;
				best = item;
			}
		}
		item = item.inventory_next;
	}
	return best;
};
*/

/*
float(entity character, string name, float n) Inventory_AdjustQuantityAllByName =
{
	local float c;
	local entity item;
	while (n > 0)
	{
		item = ItemWithLeastCapacity(character, name, FALSE);
		if (item == world)
		{
			item = ItemCreate(GetItemClassByName(name));
			if (item == world)
				return 0;
			ItemAttach(item, e);
		}
		c = item.count1 - item.count;
		if (c > n)
			c = n;
		item.count = item.count + c;
		n = n - c;
	}
	item = ItemWithLeastQuantity(character, name, FALSE);
	while (item != world && n < 0)
	{
		c = 0 - item.count;
		if (c < n)
			c = n;
		item.count = item.count + c;
		n = n - c;
		if (n)
			item = ItemWithLeastQuantity(character, name, FALSE);
	}
	//if (!keepempty)
	{
		item = ItemWithLeastQuantity(character, name, TRUE);
		while (item != world && item.count <= 0)
		{
			ItemDestroy(item);
			item = ItemWithLeastQuantity(character, name, TRUE);
		}
	}
	return Inventory_Quantity(character, name);
};
*/

/*
float(entity character, string name, float n) Inventory_SetQuantity =
{
	return Inventory_AdjustQuantityAllByName(character, name, n - Inventory_QuantityAllByName(character, name));
};
*/

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
		Inventory_AdjustQuantity(character, "pistol", 1);
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
	if (character.items & IT_WEAPON9)
		Inventory_AdjustQuantity(character, "plasmarifle", 1);
	if (character.items & IT_WEAPON10)
		Inventory_AdjustQuantity(character, "plasmawave", 1);
	// TODO: convert other items? (powerups)
	character.items = character.items - (character.items & (IT_WEAPON1 | IT_WEAPON2 | IT_WEAPON3 | IT_WEAPON4 | IT_WEAPON5 | IT_WEAPON6 | IT_WEAPON7 | IT_WEAPON8 | IT_WEAPON9 | IT_WEAPON10));
	// TODO: convert .armorvalue/.armortype?
};

/*
float(string s) WeaponToNumber =
{
	if (s == "pistol") return 1;
	if (s == "shotgun") return 2;
	if (s == "supershotgun") return 4;
	if (s == "nailgun") return 8;
	if (s == "supernailgun") return 16;
	if (s == "grenadelauncher") return 32;
	if (s == "rocketlauncher") return 64;
	if (s == "thunderbolt") return 128;
	if (s == "plasmarifle") return 256;
	if (s == "plasmawave") return 512;
	return 0;
};

string(float bit) NumberToWeapon =
{
	if (bit == 1) return "pistol";
	if (bit == 2) return "shotgun";
	if (bit == 4) return "supershotgun";
	if (bit == 8) return "nailgun";
	if (bit == 16) return "supernailgun";
	if (bit == 32) return "grenadelauncher";
	if (bit == 64) return "rocketlauncher";
	if (bit == 128) return "thunderbolt";
	if (bit == 256) return "plasmarifle";
	if (bit == 512) return "plasmawave";
	return "";
};
*/

void(entity player) Inventory_ToParms =
{
	local float bit;
	local entity wclass;
	parm1 = player.items;
	parm2 = player.health;
	parm3 = player.armorvalue;
	parm4 = Inventory_Quantity(player, "shells");
	parm5 = Inventory_Quantity(player, "nails");
	parm6 = Inventory_Quantity(player, "rockets");
	parm7 = Inventory_Quantity(player, "cells");
	parm8 = WeaponClassToNumber(player.weaponclass);
	parm9 = player.armortype * 100;
	parm10 = player.max_health;
	parm11 = 0;
	bit = 1;
	wclass = w_chain;
	do
	{
		if (Inventory_Quantity(player, wclass.w_item))
			parm11 = parm11 | bit;
		bit = bit * 2;
		wclass = wclass.w_next;
	}
	while (wclass != w_chain);
};

void(entity player) Inventory_FromParms =
{
	local float bit;
	local entity wclass;
	Inventory_DestroyByName(player, "", 9999);
	player.items = parm1;
	player.health = parm2;
	player.armorvalue = parm3;
	Inventory_SetQuantity(player, "shells", parm4);
	Inventory_SetQuantity(player, "nails", parm5);
	Inventory_SetQuantity(player, "rockets", parm6);
	Inventory_SetQuantity(player, "cells", parm7);
	player.weaponclass = NumberToWeaponClass(parm8);
	player.armortype = parm9 / 100;
	player.max_health = parm10;
	bit = 1;
	wclass = w_chain;
	do
	{
		if (parm11 & bit)
			Inventory_SetQuantity(player, wclass.w_item, 1);
		bit = bit * 2;
		wclass = wclass.w_next;
	}
	while (wclass != w_chain);
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


