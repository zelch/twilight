.float  regenhealththink;
.float  regenthink;
.float  rotthink; // rot down megahealth

void() RegenStuff =
{
	local float b;
	if (time > self.rotthink)
	{
		self.rotthink = time + 1;
		// rot health
		if (self.health > self.max_health)
		{
			self.health = self.health - 1;
			if (self.health < self.max_health)
				self.health = self.max_health;
		}
		/*
		// rot armor
		if (self.armorvalue > ARMORMAX)
		{
			self.armorvalue = self.armorvalue - 1;
			if (self.armorvalue < ARMORMAX)
				self.armorvalue = ARMORMAX;
		}
		*/
	}
	if (time > self.regenthink)
	{
		if (deathmatch)
			self.regenthink = time + 0.1;
		else
			self.regenthink = time + 0.25;
		if (!self.deadflag)
		{
			if (self.health < self.max_health)
			{
				self.health = self.health + 1;
				if (self.health > self.max_health)
					self.health = self.max_health;
			}
			if (self.bodyhealth < self.health + 100)
			{
				self.bodyhealth = self.bodyhealth + 2;
				if (self.bodyhealth > self.health + 100)
					self.bodyhealth = self.health + 100;
			}
		}
	}
	if (self.health > 999)
		self.health = 999;
	if (self.health > self.max_health)
		self.items = self.items | IT_SUPERHEALTH;
	else
		self.items = self.items - (self.items & IT_SUPERHEALTH);
};

