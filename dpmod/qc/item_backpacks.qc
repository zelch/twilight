/*
===============================================================================

PLAYER BACKPACKS

===============================================================================
*/

void() BackpackFade =
{
	self.nextthink = time;
//	self.alpha = 1 - (time - self.cnt) * 4;
//	if (self.alpha < 0.01)
		remove(self);
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
	local   entity  oself;
	local   string  s;
	local	float	best, old, new;
	local   float   acount, d;

	if (other.classname != "player")
	return;
	if (other.health < 1)
	return;

	oself = self;
	acount = 0;
	self.items = self.items - (self.items & other.items);
	if (other.flags & FL_CLIENT)
	{
		sprint(other, "You get ");
		if (self.items)
		{
			//d = IT_WEAPON1;if(self.items & d) {if(acount) sprint(other,", ");s=weaponname(d);sprint(other,s);acount=1;}
			//d = IT_WEAPON2;if(self.items & d) {if(acount) sprint(other,", ");s=weaponname(d);sprint(other,s);acount=1;}
			//d = IT_WEAPON3;if(self.items & d) {if(acount) sprint(other,", ");s=weaponname(d);sprint(other,s);acount=1;}
			//d = IT_WEAPON4;if(self.items & d) {if(acount) sprint(other,", ");s=weaponname(d);sprint(other,s);acount=1;}
			//d = IT_WEAPON5;if(self.items & d) {if(acount) sprint(other,", ");s=weaponname(d);sprint(other,s);acount=1;}
			//d = IT_WEAPON6;if(self.items & d) {if(acount) sprint(other,", ");s=weaponname(d);sprint(other,s);acount=1;}
			//d = IT_WEAPON7;if(self.items & d) {if(acount) sprint(other,", ");s=weaponname(d);sprint(other,s);acount=1;}
			//d = IT_WEAPON8;if(self.items & d) {if(acount) sprint(other,", ");s=weaponname(d);sprint(other,s);acount=1;}
			//d = IT_WEAPON9;if(self.items & d) {if(acount) sprint(other,", ");s=weaponname(d);sprint(other,s);acount=1;}
			//d = IT_WEAPON10;if(self.items & d) {if(acount) sprint(other,", ");s=weaponname(d);sprint(other,s);acount=1;}
			d = 0;
			if (self.items & IT_WEAPON1) d = d + 1;
			if (self.items & IT_WEAPON2) d = d + 1;
			if (self.items & IT_WEAPON3) d = d + 1;
			if (self.items & IT_WEAPON4) d = d + 1;
			if (self.items & IT_WEAPON5) d = d + 1;
			if (self.items & IT_WEAPON6) d = d + 1;
			if (self.items & IT_WEAPON7) d = d + 1;
			if (self.items & IT_WEAPON8) d = d + 1;
			if (self.items & IT_WEAPON9) d = d + 1;
			if (self.items & IT_WEAPON10) d = d + 1;
			if (d >= 3)
				sprint(other, "several weapons");
			else if (d == 2)
				sprint(other, "a couple weapons");
			else
				sprint(other, "a weapon");
			acount=1;
		}
	}

	// if the player was using his best weapon, change up to the new one if better
	self = other;
	best = W_BestWeapon(TRUE);
	self = oself;

	// add the ammo
	other.ammo_shells  = other.ammo_shells  + self.ammo_shells;
	other.ammo_nails   = other.ammo_nails   + self.ammo_nails;
	other.ammo_rockets = other.ammo_rockets + self.ammo_rockets;
	other.ammo_cells   = other.ammo_cells   + self.ammo_cells;
	if (self.super_damage_finished > time)
	if (self.super_damage_finished > other.super_damage_finished)
	{
		other.super_time = 1;
		other.super_damage_finished = self.super_damage_finished;
		other.items = other.items | IT_QUAD;
	}
	if (self.invisible_finished > time)
	if (self.invisible_finished > other.invisible_finished)
	{
		other.invisible_time = 1;
		other.invisible_finished = self.invisible_finished;
		other.items = other.items | IT_INVISIBILITY;
	}
	if (self.invincible_finished > time)
	if (self.invincible_finished > other.invincible_finished)
	{
		other.invincible_time = 1;
		other.invincible_finished = self.invincible_finished;
		other.items = other.items | IT_INVULNERABILITY;
	}

	new = self.items;
	old = other.items;
	other.items = old | new;

	bound_ammo (other);

	if (other.flags & FL_CLIENT)
	{
		if (self.ammo_shells)
		{
			if (acount)
				sprint(other, ", ");
			acount = 1;
			s = ftos(self.ammo_shells);
			sprint (other, s);
			sprint (other, " shells");
		}
		if (self.ammo_nails)
		{
			if (acount)
				sprint(other, ", ");
			acount = 1;
			s = ftos(self.ammo_nails);
			sprint (other, s);
			sprint (other, " rounds");
		}
		if (self.ammo_rockets)
		{
			if (acount)
				sprint(other, ", ");
			acount = 1;
			s = ftos(self.ammo_rockets);
			sprint (other, s);
			sprint (other, " rockets");
		}
		if (self.ammo_cells)
		{
			if (acount)
				sprint(other, ", ");
			acount = 1;
			s = ftos(self.ammo_cells);
			sprint (other, s);
			sprint (other, " cells");
		}
		if (self.super_damage_finished > time)
		{
			if (acount)
				sprint(other, ", ");
			acount = 1;
			sprint (other, "quad");
		}
		if (self.invisible_finished > time)
		{
			if (acount)
				sprint(other, ", ");
			acount = 1;
			sprint (other, "ring");
		}
		if (self.invincible_finished > time)
		{
			if (acount)
				sprint(other, ", ");
			acount = 1;
			sprint (other, "protection");
		}

		if (!acount)
			sprint(other, "nothing you need");
		sprint (other, "\n");
		stuffcmd(other, "bf\n");
	}
	// backpack touch sound
	sound (other, CHAN_ITEM, "weapons/lock4.wav", 1, ATTN_NORM);

	// remove the backpack, change self to the player
	self = other;

	// change to the weapon
	old = W_BestWeapon(TRUE); // didn't want to add a new local...
	if (old & new) // is the best weapon in the pack?
		self.switchweapon = old; // yep, change to it.

	self = oself;
	BackpackRemove();
	/*
	self.think = SUB_Remove;
	self.nextthink = time + 0.1;
	self.solid = SOLID_NOT;
	self.touch = SUB_Null;
	*/
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
	local   entity  item, head, killent;
	local   float   c, t;

	if (deathmatch == DM_FRAGFEST || deathmatch == DM_ELIM)
		return;
	if (!(self.ammo_shells + self.ammo_nails + self.ammo_rockets + self.ammo_cells))
	if (!(self.super_damage_finished || self.invisible_finished || self.invincible_finished))
	if (!(self.items & (IT_WEAPON3 | IT_WEAPON4 | IT_WEAPON5 | IT_WEAPON6 | IT_WEAPON7 | IT_WEAPON8 | IT_WEAPON9 | IT_WEAPON10)))
		return; // nothing in it

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
	item.owner = item;
	item.enemy = item;
	item.classname = "backpack";

	item.items = self.items & (IT_WEAPON1 | IT_WEAPON2 | IT_WEAPON3 | IT_WEAPON4 | IT_WEAPON5 | IT_WEAPON6 | IT_WEAPON7 | IT_WEAPON8 | IT_WEAPON9 | IT_WEAPON10);
	self.items = self.items - item.items;

	item.ammo_shells = self.ammo_shells;
	item.ammo_nails = self.ammo_nails;
	item.ammo_rockets = self.ammo_rockets;
	item.ammo_cells = self.ammo_cells;
	self.ammo_shells = 0;
	self.ammo_nails = 0;
	self.ammo_rockets = 0;
	self.ammo_cells = 0;
	item.super_damage_finished = self.super_damage_finished;
	item.invisible_finished = self.invisible_finished;
	item.invincible_finished = self.invincible_finished;
	self.super_damage_finished = 0;
	self.invisible_finished = 0;
	self.invincible_finished = 0;

	item.velocity_x = crandom() * 100;
	item.velocity_y = crandom() * 100;
	item.velocity_z = 300;

	if (item.super_damage_finished)
		item.effects = item.effects | EF_BLUE;
	if (item.invisible_finished)
		item.alpha = 0.5;
	if (item.invincible_finished)
		item.effects = item.effects | EF_RED;

	item.colormap = self.colormap;
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

	/*
	item.havocrating = 0;
//	if (item.items & IT_WEAPON1) item.havocrating = item.havocrating + 60;
//	if (item.items & IT_WEAPON2) item.havocrating = item.havocrating + 120;
	if (item.items & IT_WEAPON3) item.havocrating = item.havocrating + 200;
	if (item.items & IT_WEAPON4) item.havocrating = item.havocrating + 150;
	if (item.items & IT_WEAPON5) item.havocrating = item.havocrating + 300;
	if (item.items & IT_WEAPON6) item.havocrating = item.havocrating + 200;
	if (item.items & IT_WEAPON7) item.havocrating = item.havocrating + 240;
	if (item.items & IT_WEAPON8) item.havocrating = item.havocrating + 300;
	if (item.items & IT_WEAPON9) item.havocrating = item.havocrating + 0;
	if (item.items & IT_WEAPON10) item.havocrating = item.havocrating + 300;
	item.havocrating = item.havocrating + item.ammo_shells * 60;
	item.havocrating = item.havocrating + item.ammo_nails * 15;
	item.havocrating = item.havocrating + item.ammo_rockets * 120;
	item.havocrating = item.havocrating + item.ammo_cells * 30;
	if (item.super_damage_finished > time) item.havocrating = item.havocrating + 10 * (item.super_damage_finished - time);
	if (item.invisible_finished    > time) item.havocrating = item.havocrating + 10 * (item.invisible_finished - time);
	if (item.invincible_finished   > time) item.havocrating = item.havocrating + 20 * (item.invincible_finished - time);
	*/
	item.havocpickup = TRUE;
	item.pickupevalfunc = item_backpack_pickupeval;
};
