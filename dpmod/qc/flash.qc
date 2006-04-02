//void(entity e) flashscreen = {return;};
//void(vector org) flasharea = {return;};

void(entity e) flashscreen =
{
	if (e.flags & FL_CLIENT)
		stuffcmd(e, "bf\n");
};

void(vector org) flasharea =
{
/*
	local entity head;
	head = findchain(classname, "player");
	while (head)
	{
		if (head.flags & FL_CLIENT)
		{
			traceline(org, head.origin + head.view_ofs, TRUE, world);
			if (trace_fraction == 1)
				stuffcmd(head, "bf\n");
		}
		head = head.chain;
	}
*/
};

