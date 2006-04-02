
void() trigger_ticker_think =
{
	if (self.count > 0)
	{
		if (self.cnt < 1)
			return;
		self.cnt = self.cnt - 1;
	}
	self.nextthink = time + self.delay;
	SUB_UseTargets();
};

void() trigger_ticker_use =
{
	self.cnt = self.count;
	self.nextthink = time + 0.01;
};

/*QUAKED trigger_ticker (0 .6 .8) (-8 -8 -8) (8 8 8)
triggers it's targets
every "delay" seconds.

if targetname is set,
it will only tick in bursts of
"count" times and only when
triggered.

Keys:
"delay"
 time between triggers,
 default 0.1, cannot go below 0.1.
"count"
 how many pulses to do when targeted
 not used unless targetname is set
 default 1
"targetname"
 as mentioned above
"target"
 must be set
*/

void() trigger_ticker =
{
	if (!self.target)
		objerror("trigger_ticker: no targets\n");
	if (self.delay < 0.1)
		self.delay = 0.1;
	self.think = trigger_ticker_think;
	self.nextthink = time + 2; // give targets a chance to spawn etc
	self.use = trigger_ticker_use;
	if (self.targetname)
		self.cnt = 0;
};
