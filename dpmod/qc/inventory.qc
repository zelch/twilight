
.float count;
.float count1;
.entity inventory_next;
.entity inventory_prev;

entity(entity e, string name) ItemCreate =
{
	local entity item;
	item = spawn();
	item.classname = "playeritem";
	item.netname = name;
	item.owner = e;
	item.count = 0;
	item.count1 = 10;
	item.inventory_next = item.owner;
	item.inventory_prev = item.inventory_next.inventory_prev;
	item.inventory_next.inventory_prev = item;
	item.inventory_prev.inventory_next = item;
	     if (name == "shells") item.count1 = AMMOMAX_SHELLS;
	else if (name == "nails") item.count1 = AMMOMAX_NAILS;
	else if (name == "rockets") item.count1 = AMMOMAX_ROCKETS;
	else if (name == "cells") item.count1 = AMMOMAX_CELLS;
	else if (name == "xshells") item.count1 = AMMOMAX_XSHELLS;
	return item;
};

entity(entity e, string name) ItemByName =
{
	local entity item;
	item = e.inventory_next;
	if (item == world)
		item = e.inventory_next = e.inventory_prev = e;
	while (item != e)
	{
		if (item.netname == name)
			return item;
		item = item.inventory_next;
	}
	return world;
};

float(entity e, string name) ItemMaxQuantity =
{
	local entity item;
	item = ItemByName(e, name);
	if (item)
		return item.count1;
	/*
	if (name == "shells")
		return AMMOMAX_SHELLS;
	if (name == "nails")
		return AMMOMAX_NAILS;
	if (name == "rockets")
		return AMMOMAX_ROCKETS;
	if (name == "cells")
		return AMMOMAX_CELLS;
	if (name == "xshells")
		return AMMOMAX_XSHELLS;
	*/
	return 255;
};

float(entity e, string name) ItemQuantity =
{
	local entity item;
	item = ItemByName(e, name);
	if (item)
		return item.count;
	/*
	if (name == "shells")
		return e.ammo_shells;
	if (name == "nails")
		return e.ammo_nails;
	if (name == "rockets")
		return e.ammo_rockets;
	if (name == "cells")
		return e.ammo_cells;
	if (name == "xshells")
		return e.ammo_xshells;
	*/
	return 0;
};

float(entity e, string name, float n) ItemAdjustQuantity =
{
	local entity item;
	item = ItemByName(e, name);
	if (item == world)
		item = ItemCreate(e, name);
	return (item.count = bound(0, item.count + n, item.count1));
	/*
	if (name == "shells")
		return (e.ammo_shells = bound(0, e.ammo_shells + n, AMMOMAX_SHELLS));
	if (name == "nails")
		return (e.ammo_nails = bound(0, e.ammo_nails + n, AMMOMAX_NAILS));
	if (name == "rockets")
		return (e.ammo_rockets = bound(0, e.ammo_rockets + n, AMMOMAX_ROCKETS));
	if (name == "cells")
		return (e.ammo_cells = bound(0, e.ammo_cells + n, AMMOMAX_CELLS));
	if (name == "xshells")
		return (e.ammo_xshells = bound(0, e.ammo_xshells + n, AMMOMAX_XSHELLS));
	*/
};

float(entity e, string name, float n) ItemSetQuantity =
{
	local entity item;
	item = ItemByName(e, name);
	if (item == world)
		item = ItemCreate(e, name);
	return (item.count = bound(0, n, item.count1));
	/*
	if (name == "shells")
		return (e.ammo_shells = bound(0, n, AMMOMAX_SHELLS));
	if (name == "nails")
		return (e.ammo_nails = bound(0, n, AMMOMAX_NAILS));
	if (name == "rockets")
		return (e.ammo_rockets = bound(0, n, AMMOMAX_ROCKETS));
	if (name == "cells")
		return (e.ammo_cells = bound(0, n, AMMOMAX_CELLS));
	if (name == "xshells")
		return (e.ammo_xshells = bound(0, n, AMMOMAX_XSHELLS));
	*/
};

float(entity e, float t, float a) full_ammo =
{
	local string s;
	     if (t == 1) s = "shells";
	else if (t == 2) s = "nails";
	else if (t == 3) s = "rockets";
	else if (t == 4) s = "cells";
	else if (t == 5) s = "xshells";
	else             return a;
	return min(a, ItemMaxQuantity(e, s) - ItemQuantity(e, s));
};

void(entity e) updateammodisplay =
{
	e.ammo_shells = ItemQuantity(e, "shells");
	e.ammo_nails = ItemQuantity(e, "nails");
	e.ammo_rockets = ItemQuantity(e, "rockets");
	e.ammo_cells = ItemQuantity(e, "cells");
};


