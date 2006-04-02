
float() trigger_playercount_check =
{
	local entity head;
	local float c;
	c = 0;
	head = findchain(classname, "player");
	while (head != world)
	{
		c = c + 1;
		head = head.chain;
	}
	return c;
};

void() trigger_playercount_think =
{
	self.nextthink = time + 1;
	if (trigger_playercount_check() >= self.count)
	{
		activator = world;
		SUB_UseTargets();
		remove(self);
	}
};

void() trigger_playercount_activate =
{
	self.use = SUB_Null;
	if (self.count > 0)
	{
		self.think = trigger_playercount_think;
		self.nextthink = time + 1;
	}
	if (self.count2 > 0)
	{
		if (cvar("maxplayers") >= self.count2)
		{
			activator = world;
			SUB_UseTargets();
			remove(self);
		}
	}
};

/*QUAKED trigger_playercount (0 .6 .8) (-8 -8 -8) (8 8 8)
Triggers targets when enough players
join the game.

Recommended usage:
Wall off a room from the rest of the map
with vanishwalls/doors/etc, place this
somewhere, target the vanishwalls and
dm starts.
(vanishwalls vanish, dm starts activate)

Obviously this can trigger anything you
like. (func_train, etc)

Keys:
"count"
 how many players must join
"count2"
 if specified, this will immediately
 trigger and remove itself if
 maxplayers is at least this value.
 (can be used with count as well,
  although I can't imagine that being
  useful...)
"targetname"
 if targetted, this will not begin
 checking playercount until it is
 triggered.
 (works with count and count2)
*/
void() trigger_playercount =
{
	if (!self.target)
		objerror("trigger_playercount: no targets to trigger\n");
	if (self.count <= 0)
	if (self.count2 <= 0)
		objerror("trigger_playercount: no count or count2 specified\n");
	if (self.targetname)
	{
		self.use = trigger_playercount_activate;
		return;
	}
	self.nextthink = time + 2;
	self.think = trigger_playercount_activate;
};
