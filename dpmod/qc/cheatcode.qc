/*
============
ServerflagsCommand

Just for development
============
*/
void() ServerflagsCommand =
{
	if (deathmatch)
		return;
	serverflags = serverflags * 2 + 1;
	serverflags = serverflags & 15; // 15 = 8 + 4 + 2 + 1
};

void() QuadCheat =
{
	if (deathmatch)
		return;
	if (self.health < 1)
		return; // dead
	self.super_time = 1;
	self.super_damage_finished = time + 60;
	self.items = self.items | IT_QUAD;
	bprint (self.netname);
	bprint (" activated quad cheat\n");
};
