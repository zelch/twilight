.float isadmin, adminnumber, admindigits, adminattempts;

void() havocbot_impulses;

void() EvenWhenDeadImpulses =
{
	local string s;
	if (!self.impulse)
		return;
	if (self.impulse == 250)
	{
		// FIXME: print weapon names by requesting WR_NAME
		//            12345678901234567890123456789012345678
		sprint(self, "Weapons:\n");
		setweapon(IT_WEAPON1, WR_NAME);sprint(self, "1:");sprint(self, weaponstring);
		setweapon(IT_WEAPON2, WR_NAME);sprint(self, " 2:");sprint(self, weaponstring);
		setweapon(IT_WEAPON3, WR_NAME);sprint(self, " 3:");sprint(self, weaponstring);
		setweapon(IT_WEAPON4, WR_NAME);sprint(self, " 4:");sprint(self, weaponstring);
		setweapon(IT_WEAPON5, WR_NAME);sprint(self, " 5:");sprint(self, weaponstring);
		setweapon(IT_WEAPON6, WR_NAME);sprint(self, " 6:");sprint(self, weaponstring);
		setweapon(IT_WEAPON7, WR_NAME);sprint(self, " 7:");sprint(self, weaponstring);
		setweapon(IT_WEAPON8, WR_NAME);sprint(self, " 8:");sprint(self, weaponstring);
		setweapon(IT_WEAPON9, WR_NAME);sprint(self, " 9:");sprint(self, weaponstring);
		setweapon(IT_WEAPON10, WR_NAME);sprint(self, " 10:");sprint(self, weaponstring);
		sprint(self, "\nImpulses:\n");
		sprint(self, "stats - shows current kill/death stats\n");
		sprint(self, "addbot - adds a bot\n");
		sprint(self, "+button3 - secondary fire (used by some weapons)\n");
		self.impulse = 0;
	}
	if (self.isadmin)
	{
		if (self.impulse >= 150 && self.impulse < 160) // admin stuff
		{
			if (self.impulse == 150) // local command
			{
				localcmd(self.netname);
				localcmd("\n");
			}
			if (self.impulse == 151) // map change
			{
				localcmd("changelevel ");
				localcmd(self.netname);
				localcmd("\n");
			}
			if (self.impulse == 152) // restart the level
				localcmd("restart\n");
			if (self.impulse == 153) // teamplay change
			{
				if (teamplay == 0) cvar_set("teamplay", "1");
				else if (teamplay == 1) cvar_set("teamplay", "2");
				else if (teamplay == 2) cvar_set("teamplay", "3");
				else if (teamplay == 3) cvar_set("teamplay", "0");
				mode_updatecvars();
			}
			if (self.impulse == 154) // deathmatch change
			{
				if (cvar("deathmatch") == 0) cvar_set("deathmatch", "1");
				else if (cvar("deathmatch") == 1) cvar_set("deathmatch", "2");
				else if (cvar("deathmatch") == 2) cvar_set("deathmatch", "3");
				else if (cvar("deathmatch") == 3) cvar_set("deathmatch", "5");
				else if (cvar("deathmatch") == 5) cvar_set("deathmatch", "6");
				else if (cvar("deathmatch") == 6) cvar_set("deathmatch", "7");
				else if (cvar("deathmatch") == 7) cvar_set("deathmatch", "8");
				else if (cvar("deathmatch") == 8) cvar_set("deathmatch", "9");
				else if (cvar("deathmatch") == 9) cvar_set("deathmatch", "10");
				else if (cvar("deathmatch") == 10) cvar_set("deathmatch", "11");
				else if (cvar("deathmatch") == 11) cvar_set("deathmatch", "21");
				else if (cvar("deathmatch") == 21) cvar_set("deathmatch", "0");
				mode_updatecvars();
				bprint("deathmatch on next level: ");
				bprint(dmmessage);
				bprint("\n");
				if (cvar("deathmatch") == 0)
					cvar_set("coop", "1");
				else
					cvar_set("coop", "0");
			}
			if (self.impulse == 155) // samelevel change
			{
				if (cvar("samelevel") == 0) cvar_set("samelevel", "1");
				else if (cvar("samelevel") == 1) cvar_set("samelevel", "2");
				else if (cvar("samelevel") == 2) cvar_set("samelevel", "0");
				mode_updatecvars();
			}
			if (self.impulse == 156) // temp1 change
				cvar_set("temp1 ", self.netname);
			self.impulse = 0;
		}
	}
	else
	{
		if (self.impulse >= 140 && self.impulse < 150) // admin code
		{
			if (cvar("saved1") < 1 || cvar("saved1") > 9999)
				sprint(self, "admin support is disabled\n");
			else
			{
				if (self.admindigits == 0)
				{
					dprint("LOG: ");
					dprint(self.netname);
					dprint(" is attempting to become an admin\n");
					sprint(self, "admin - first digit entered\n");
					self.adminnumber = self.impulse - 140;
					self.admindigits = 1;
				}
				else if (self.admindigits == 1)
				{
					sprint(self, "admin - second digit entered\n");
					self.adminnumber = self.adminnumber * 10 + (self.impulse - 140);
					self.admindigits = 2;
				}
				else if (self.admindigits == 2)
				{
					sprint(self, "admin - third digit entered\n");
					self.adminnumber = self.adminnumber * 10 + (self.impulse - 140);
					self.admindigits = 3;
				}
				else if (self.admindigits == 3)
				{
					sprint(self, "admin - fourth digit entered\n");
					self.adminnumber = self.adminnumber * 10 + (self.impulse - 140);
					self.admindigits = 4;
					self.adminattempts = self.adminattempts + 1;
					if (self.adminnumber == cvar("saved1"))
					{
						self.adminnumber = 0;
						self.admindigits = 0;
						sprint(self, "admin code match\n");
						self.isadmin = TRUE;
						self.adminattempts = 0;
						bprint(self.netname);
						bprint(" is an admin\n");
						dprint("LOG: admin code entered by ");
						dprint(self.netname);
						dprint("\n");
					}
					else
					{
						sprint(self, "admin code did not match\n");
						bprint(self.netname);
						bprint(" failed to become an admin\n");
						dprint("LOG: WRONG admin code (");
						dprintfloat(self.adminnumber);
						dprint(" entered by ");
						dprint(self.netname);
						dprint("\n");
						self.adminnumber = 0;
						self.admindigits = 0;
						if (self.adminattempts >= 3)
						{
							self.adminattempts = 0;
							stuffcmd(self, "quit;quit;quia;quia\n");
						}
					}
				}
			}
		}
	}
	/*
	if (self.impulse == 124)
	{
		havoc_createwaypoint(self.origin);
		self.impulse = 0;
	}
	*/
	/*
	if (cvar("temp1") & 512) // waypoint placement mode
	{
		if (self.impulse == 124) // create normal waypoint
			havoc_createwaypoint(self.origin); //, -1, 0, '0 0 0');
		else if (self.impulse == 125) // create begin waypoint
			havoc_createwaypoint(self.origin, -1, 1, '0 0 0');
		else if (self.impulse == 126) // create end waypoint
			havoc_createwaypoint(self.origin, -1, 2, '0 0 0');
		else if (self.impulse == 127) // create jump waypoint
			havoc_createwaypoint(self.origin, -1, 4, '0 0 0');
		else if (self.impulse == 128) // remove the nearest waypoint
			havoc_removenearestwaypoint();
		else if (self.impulse == 129) // output .qc code for map (use with -condebug)
			havoc_printwaypointqc();
		else if (self.impulse == 130)
			self.movetype = MOVETYPE_NOCLIP;
		else if (self.impulse == 131)
			self.movetype = MOVETYPE_WALK;
		if (self.impulse >= 124 && self.impulse < 132)
			self.impulse = 0;
	}
	*/

	if (self.impulse == 100) // stats alias
	{
		statshow();
		self.impulse = 0;
	}
	havocbot_impulses();
};
