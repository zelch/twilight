void() trigger_stuffcmd_use =
{
	if (!(activator.flags & FL_CLIENT))
		return;
	if (time < self.attack_finished)
		return;
	self.attack_finished = time + self.wait;
	stuffcmd(activator, self.message); // the key to it all
	stuffcmd(activator, "\n"); // end the command incase the message did not contain one
}

/*QUAKED trigger_stuffcmd (.5 .5 .5) (-8 -8 -8) (8 8 8)
Stuffs the supplied commands into the client's console.
Note: not touchable, must be targetted.
fields:
"targetname"
 must be set
"wait"
 seconds between triggerings (.5 default)
"message"
 commands (such as "bf", use ; to separate commands)
*/
void() trigger_stuffcmd =
{
	if (!self.wait)
		self.wait = 0.5;
	if (self.targetname)
		self.use = trigger_stuffcmd_use;
	else
		objerror("trigger_stuffcmd with no targetname\n");
}
