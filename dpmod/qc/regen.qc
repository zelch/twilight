.float regenthink;
.float rotthink; // rot down megahealth

void() RegenStuff =
{
	if (!self.deadflag)
	{
		if (time > self.rotthink)
		{
			// rot health
			self.rotthink = time + 1;
			if (self.health > self.max_health)
			{
				self.health = self.health - 1;
				if (self.health < self.max_health)
					self.health = self.max_health;
			}
		}
		if (time > self.regenthink)
		{
			if (deathmatch)
				self.regenthink = time + 0.1;
			else
				self.regenthink = time + 0.25;
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

