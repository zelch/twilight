/*
===============================================================================

PLAYER BACKPACKS

===============================================================================
*/

// TODO: Nexuiz items

void() BackpackFade =
{
	self.nextthink = time;
	self.alpha = 1 - (time - self.cnt) * 4;
	if (self.alpha < 0.01)
	{
		Inventory_DestroyByName(self, "", 99999);
		remove(self);
	}
};

void() BackpackRemove =
{
	self.solid = SOLID_NOT;
	self.touch = SUB_Null;
	self.think = BackpackFade;
	self.nextthink = time;
	self.cnt = time;
	self.classname = "BackpackFading";
	BackpackFade();
};

void() BackpackTouch =
{
	local entity stemp, item;
	local string s;
	local float old, new, switchweapon;
	local float acount, d;

	if (other.classname != "player")
		return;
	if (other.health < 1)
		return;

	acount = 0;
	self.items = self.items - (self.items & other.items);

	stemp = self;
	self = other;
	switchweapon = self.switchweaponclass == W_BestWeaponClass(TRUE);
	self = stemp;

	new = self.items;
	old = other.items;
	other.items = old | new;

	item = Inventory_GetNextItem(self, world);
	while (item)
	{
		d = Inventory_AbsorbItem(other, item);
		if (d)
		{
			if (other.flags & FL_CLIENT)
			{
				s = ftos(d);
				if (acount)
					sprint(other, ", ");
				else
					sprint(other, "You get ");
				acount = 1;
				sprint (other, s);
				sprint (other, " ");
				sprint (other, item.netname);
			}
			if (item.count == 0)
			{
				Item_Destroy(item);
				item = world;
			}
		}
		item = Inventory_GetNextItem(self, item);
	}
	if (other.flags & FL_CLIENT)
	{
		if (self.super_damage_finished > time)
		{
			if (acount)
				sprint(other, ", ");
			else
				sprint(other, "You get ");
			acount = 1;
			sprint (other, "quad");
		}
		if (self.invisible_finished > time)
		{
			if (acount)
				sprint(other, ", ");
			else
				sprint(other, "You get ");
			acount = 1;
			sprint (other, "ring");
		}
		if (self.invincible_finished > time)
		{
			if (acount)
				sprint(other, ", ");
			else
				sprint(other, "You get ");
			acount = 1;
			sprint (other, "protection");
		}

		if (acount)
			sprint (other, "\n");
		stuffcmd(other, "bf\n");
	}
	// backpack touch sound
	sound (other, CHAN_ITEM, "weapons/lock4.wav", 1, ATTN_NORM);

	// if the player was using their best weapon, change up to the new one if better
	if (switchweapon)
	{
		self = other;
		self.switchweaponclass = W_BestWeaponClass(TRUE);
		self = stemp;
	}

	// remove the backpack
	BackpackRemove();
};

// FIXME: bother to rate backpacks based on their contents?
float(entity player, entity item) item_backpack_pickupeval =
{
	return 4000;
};

/*
===============
DropBackpack
===============
*/
void() DropBackpack =
{
	local entity item, head, killent;
	local float c, t;

	if (deathmatch == DM_FRAGFEST || deathmatch == DM_ELIM)
		return;

	//if (deathmatch == DM_RPG)
	//	Inventory_DropByName(self, "", 99999);

	if (!Inventory_GetNextItem(self, world))
	//if (!(Inventory_Quantity(self, "shells") + Inventory_Quantity(self, "nails") + Inventory_Quantity(self, "rockets") + Inventory_Quantity(self, "cells")))
	//if (!(self.items & (IT_WEAPON3 | IT_WEAPON4 | IT_WEAPON5 | IT_WEAPON6 | IT_WEAPON7 | IT_WEAPON8 | IT_WEAPON9 | IT_WEAPON10)))
		return; // nothing in it

	// don't drop a backpack if in a NODROP zone (such as lava)
	traceline(self.origin, self.origin, MOVE_NORMAL, self);
	if (trace_dpstartcontents & DPCONTENTS_NODROP)
		return;

	c = 0;t = time + 5;
	head = findchain(classname, "backpack");
	while (head != world)
	{
		c = c + 1;
		if (head.createdtime < t)
		{
			t = head.createdtime;
			killent = head;
		}
		head = head.chain;
	}
	if (c >= 30) // 30 backpacks?  remove one
	{
		killent.solid = SOLID_NOT;
		killent.classname = "";
		killent.think = BackpackRemove;
		killent.nextthink = time;
	}

	item = spawn();
	item.createdtime = time;
	//item.owner = item;
	//item.enemy = item;
	item.classname = "backpack";
	item.havocpickup = TRUE;
	item.pickupevalfunc = item_backpack_pickupeval;

	item.velocity_x = crandom() * 100;
	item.velocity_y = crandom() * 100;
	item.velocity_z = 300;

	item.colormap = self.colormap; // color backpack like player
	item.flags = FL_ITEM;
	item.solid = SOLID_TRIGGER;
	item.movetype = MOVETYPE_TOSS;
	setmodel (item, "progs/backpack.mdl");
	setsize (item, '-16 -16 0', '16 16 56');
	setorigin(item, self.origin - '0 0 24');
	item.touch = BackpackTouch;

	if (self.flags & FL_MONSTER)
		item.nextthink = time + 3600;    // remove after 60 minutes
	else
		item.nextthink = time + 120;    // remove after 2 minutes
	item.think = BackpackRemove;

	// this transfers legacy items
	//item.items = self.items & (IT_WEAPON1 | IT_WEAPON2 | IT_WEAPON3 | IT_WEAPON4 | IT_WEAPON5 | IT_WEAPON6 | IT_WEAPON7 | IT_WEAPON8 | IT_WEAPON9 | IT_WEAPON10);
	// this transfers all inventory items (ammo, etc)
	Inventory_AbsorbInventory(item, self);
};
