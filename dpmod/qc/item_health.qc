/*QUAKED item_health (.3 .3 1) (0 0 0) (32 32 32) rotten megahealth
Health box. Normally gives 25 points.
Rotten box heals 10 points,
megahealth will add 100 health, then
rot you down to your maximum health limit,
one point per second.
*/

float H_ROTTEN = 1;
float H_MEGA = 2;
void() health_touch;

// TODO: Nexuiz items

float(entity player, entity item) item_health_pickupeval = {if (player.health >= player.max_health) return -1;return (player.max_health - player.health) * (player.max_health - player.health) * item.dmg / (player.max_health * player.max_health);};
float(entity player, entity item) item_megahealth_pickupeval = {if (player.health >= (HEALTHMEGAMAX + player.max_health) * 0.5) return -1;return (HEALTHMEGAMAX - player.health) * (HEALTHMEGAMAX - player.health) * item.dmg / (HEALTHMEGAMAX * HEALTHMEGAMAX);};

void() item_health =
{
	self.touch = health_touch;

	if (game == GAME_NEXUIZ)
	{
		// TODO: Nexuiz health items
		if (self.spawnflags & H_ROTTEN)
		{
			precache_model("models/items/g_h1.md3");
			setmodel(self, "models/items/g_h1.md3");
			self.netname = "+5 health\n";
			self.count2 = 5;
			self.cnt2 = TRUE;
			self.havocpickup = TRUE;
			self.dmg = 7500;
			self.pickupevalfunc = item_health_pickupeval;
		}
		else if (self.spawnflags & H_MEGA)
		{
			precache_model("models/items/g_h100.md3");
			setmodel(self, "models/items/g_h100.md3");
			self.netname = "+100 health\n";
			self.count2 = 100;
			self.cnt2 = TRUE;
			self.havocpickup = TRUE;
			self.dmg = 25000;
			self.pickupevalfunc = item_megahealth_pickupeval;
		}
		else
		{
			precache_model("models/items/g_h25.md3");
			setmodel(self, "models/items/g_h25.md3");
			self.netname = "+25 health\n";
			self.count2 = 25;
			self.cnt2 = FALSE;
			self.havocpickup = TRUE;
			self.dmg = 12500;
			self.pickupevalfunc = item_health_pickupeval;
		}
		setsize (self, '0 0 0', '32 32 16');
	}
	else
	{
		if (self.spawnflags & H_ROTTEN)
		{
			precache_model("maps/b_bh10.bsp");
			precache_sound("items/r_item1.wav");
			setmodel(self, "maps/b_bh10.bsp");
			self.noise = "items/r_item1.wav";
			self.netname = "+15 health\n";
			self.count2 = 15;
			self.cnt2 = FALSE;
			self.havocpickup = TRUE;
			self.dmg = 7500;
			self.pickupevalfunc = item_health_pickupeval;
		}
		else if (self.spawnflags & H_MEGA)
		{
			precache_model("maps/b_bh100.bsp");
			precache_sound("items/r_item2.wav");
			setmodel(self, "maps/b_bh100.bsp");
			self.noise = "items/r_item2.wav";
			self.netname = "+100 health\n";
			self.count2 = 100;
			self.cnt2 = TRUE;
			self.havocpickup = TRUE;
			self.dmg = 25000;
			self.pickupevalfunc = item_megahealth_pickupeval;
		}
		else
		{
			precache_model("maps/b_bh25.bsp");
			precache_sound("items/health1.wav");
			setmodel(self, "maps/b_bh25.bsp");
			self.noise = "items/health1.wav";
			self.netname = "+25 health\n";
			self.count2 = 25;
			self.cnt2 = FALSE;
			self.havocpickup = TRUE;
			self.dmg = 12500;
			self.pickupevalfunc = item_health_pickupeval;
		}
		setsize (self, '0 0 0', '32 32 16');
	}

	StartItem ();
};


// T_Heal: add health to an entity, limiting health to max_health
// "ignore" will ignore max_health limit
.float rotthink; // used in regen.qc
float (entity e, float amount, float ignore) T_Heal =
{
	local float m;

	// don't heal a corpse
	if (e.health < 1)
		return 0;

	// which maxhealth to use
	m = e.max_health;
	if (ignore)
		m = HEALTHMEGAMAX;

	if (e.health >= m)
		return 0;

	e.health = e.health + amount;
	e.rotthink = time + 5; // 5 sec before rot begins
	e.bodyhealth = e.bodyhealth + amount;

	if (e.health > m)
		e.health = m;

	return 1;
};


void() health_touch =
{
	if (other.classname != "player")
		return;

	if (!T_Heal(other, self.count2, self.cnt2))
		return;

	if (other.flags & FL_CLIENT)
	{
//		sprint(other, self.netname);
		stuffcmd(other, "bf\n");
	}

	// health touch sound
	sound(other, CHAN_ITEM, self.noise, 1, ATTN_NORM);

	self.model = "";
	self.solid = SOLID_NOT;

	if (itemrespawn)
	{
		if (self.cnt2)
			self.nextthink = time + RESPAWNTIME_MEGAHEALTH;
		else
			self.nextthink = time + RESPAWNTIME_HEALTH;
		self.think = SUB_regen;
	}
	else
	{
		self.think = SUB_Remove;
		self.nextthink = time + 0.1;
	}

	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets
};
