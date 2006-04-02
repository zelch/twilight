.float regenthink;
.float rotthink; // rot down megahealth

void() RegenStuff =
{
	if (!self.deadflag)
	{
		if (time > self.rotthink)
		{
			// rot health
			/*
			if (self.items & IT_QUAD) // Fury drains health very quickly
			{
				self.rotthink = time + 0.2;
				if (self.health > 1)
				{
					self.health = self.health - 1;
					if (self.health < 1)
						self.health = 1;
				}
				else
				{
					self.items = self.items - IT_QUAD;
					sprint(self, "Fury has left you weak.\n");
				}
			}
			else
			*/
			{
				self.rotthink = time + 1;
				if (self.health > self.max_health)
				{
					self.health = self.health - 1;
					if (self.health < self.max_health)
						self.health = self.max_health;
				}
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
			//if (!(self.items & IT_QUAD)) // no healing with Fury
			if (!metroidmode) // no healing in metroidmode
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
	}
	if (self.health > self.max_health + 1000)
		self.health = self.max_health + 1000;
	if (self.health > self.max_health)
		self.items = self.items | IT_SUPERHEALTH;
	else
		self.items = self.items - (self.items & IT_SUPERHEALTH);
};

