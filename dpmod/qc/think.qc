
//.void() th_run; // just reusing an AI field

void() extrathink_think =
{
	local entity tempself;
	tempself = self;
	self = self.owner;
	tempself.th_run(); // called with self set to owner
	self = tempself;
	remove(self);
};

void(entity e, void() thinkfunc, float thinktime) extrathink =
{
	local entity n;
	if (thinktime < time)
		return;
	n = spawn();
	n.owner = e;
	n.th_run = thinkfunc;
	n.think = extrathink_think;
	n.nextthink = thinktime;
	n.classname = "extrathink";
};
