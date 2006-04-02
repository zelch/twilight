
// FRIK_FILE extension test code
void () saveme =
{
	local string h;
	local float file;
	file = fopen ("save.txt", FILE_WRITE);
	fputs(file, "// Sample Save File\n");
	h = ftos(self.health);
	fputs(file, h);
	fputs(file, "\n");
	h = vtos(self.origin);
	fputs(file, h);
	fputs(file, "\n");
	h = vtos(self.angles);
	fputs(file, h);
	fputs(file, "\n");
	fclose(file);
};

// FRIK_FILE extension test code
void () loadme =
{
	local string h;
	local float file;
	local vector v;

	file = fopen ("save.txt", FILE_READ);
	if (file < 0)
	{
		bprint("Error: file not found\n");
		return;
	}
	h = fgets(file); // reads one line at a time (up to a \n)
	// the first line is just a comment, ignore it
	h = fgets(file);
	self.health = stof(h);
	h = fgets(file);
	v = stov(h);
	setorigin(self, v);
	h = fgets(file);
	v = stov(h);
	self.angles = v;
	self.fixangle = TRUE;
	fclose(file);
};

// FRIK_FILE extension test code
void() listfile =
{
	local float file;
	local float i;
	local string lineno;
	local string line;

	file = fopen ("save.txt", FILE_READ);
	if (file < 0)
	{
		bprint("Error: file not found\n");
		return;
	}

	i = 0;
	line = fgets(file); // reads one line at a time (up to a \n)
	while(line)
	{
		line = strzone(line);

		i = i + 1;
		lineno = ftos(i);

		bprint(lineno);
		bprint(": ");
		bprint(line);
		bprint("\n");

		strunzone(line);

		line = fgets(file);
	}
	bprint("[EOF]\n");

	fclose(file);
};

//KRIMZON_SV_PARSECLIENTCOMMAND test
void SV_ParseClientCommand (string s)
{
	local float args;
	local string c;
	args = tokenize(s);
	c = argv(0);
	// edit this to do what you want with the received commands
	     if (c == "say") clientcommand(self, s);
	else if (c == "say_team") clientcommand(self, s);
	else if (c == "name") clientcommand(self, s);
	else if (c == "color") clientcommand(self, s);
	else if (c == "tell") clientcommand(self, s);
	else if (c == "kill") clientcommand(self, s);
	else if (c == "status") clientcommand(self, s);
	else if (c == "pause") clientcommand(self, s);
	else if (c == "kick") clientcommand(self, s);
	else if (c == "ping") clientcommand(self, s);
	else if (c == "ban") clientcommand(self, s);
	else if (c == "pmodel") clientcommand(self, s);
	else if (c == "god") clientcommand(self, s);
	else if (c == "fly") clientcommand(self, s);
	else if (c == "noclip") clientcommand(self, s);
	else if (c == "notarget") clientcommand(self, s);
	else if (c == "give") clientcommand(self, s);
	// please keep this fallback incase new engine commands are added
	else clientcommand(self, s);
}

.float isadmin, adminnumber, admindigits, adminattempts;

void() havocbot_impulses;

void(entity e, vector v) printsurfaceinfo =
{
	local float surfnum, numpoints, vnum;
	local string s;
	local vector n;
	surfnum = getsurfacenearpoint(e, v);
	if (surfnum >= 0)
	{
		bprint("texture: ");
		s = getsurfacetexture(e, surfnum);
		bprint(s);
		bprint(" normal: ");
		n = getsurfacenormal(e, surfnum);
		bprintvector(n);
		bprint(" ");
		numpoints = getsurfacenumpoints(e, surfnum);
		bprintfloat(numpoints);
		bprint(" verts:");
		vnum = 0;
		while (vnum < numpoints)
		{
			bprint(" ");
			n = getsurfacepoint(e, surfnum, vnum);
			bprintvector(n);
			vnum = vnum + 1;
		}
		bprint(" point tested: ");
		bprintvector(v);
		bprint(" nearest point on surface: ");
		n = getsurfaceclippedpoint(e, surfnum, v);
		bprintvector(n);
		bprint("\n");
	}
};

void() GibClone =
{
	if (random() < 0.5)
		sound (self, CHAN_VOICE, "player/gib.wav", 1, ATTN_NONE);
	else
		sound (self, CHAN_VOICE, "player/udeath.wav", 1, ATTN_NONE);

	MonsterGibs("", 6, "", 0, "", 0);
};


.entity flashlight;
void() FlashLight_Think =
{
	self.nextthink = time;
	if (self.owner.flashlight != self)
	{
		remove(self);
		return;
	}
	makevectors(self.owner.v_angle);
	setorigin(self, self.owner.origin + '0 0 16' + v_forward * 10);
	self.angles = self.owner.v_angle;
	self.angles_x = self.angles_x * -1;
};

void() ToggleFlashLight =
{
	if (self.flashlight)
	{
		// the flashlight will remove itself
		self.flashlight = world;
		return;
	}
	else
	{
		self.flashlight = spawn();
		self.flashlight.owner = self;
		self.flashlight.nextthink = time;
		self.flashlight.think = FlashLight_Think;
		self.flashlight.pflags = PFLAGS_FULLDYNAMIC;
		self.flashlight.light_lev = 1000;
		self.flashlight.color = '2 2 2';
		self.flashlight.style = 255;
		self.flashlight.skin = 201;
		//setattachment(self.flashlight, self, "");
		//setorigin(self.flashlight, '10 0 16');
	}
}

void() superdomination_impulses;

/*
============
ImpulseCommands

============
*/
void() ImpulseCommands =
{
	local float n;
	local string s;
	local entity wclass;
	if (self.impulse == 250)
	{
		sprint(self, "Weapons:\n");
		wclass = w_chain;
		do
		{
			s = ftos(wclass.impulse);
			sprint(self, s);
			sprint(self, ": ");
			sprint(self, wclass.netname);
			sprint(self, "\n");
			wclass = wclass.w_next;
		}
		while (wclass != w_chain);
		sprint(self, "Console variables:\n");
		sprint(self, "damagescale_playerdamage - affects weapon damage to everything\n");
		sprint(self, "damagescale_monsterdamage - affects monster damage to players\n");
		sprint(self, "damagescale_monsterhealth - affects player damage to monsters\n");
		sprint(self, "spawnmonsters - how many monsters to fight in deathmatch\n");
		sprint(self, "monsterwander - makes monsters roam the level\n");
		sprint(self, "bots - how many bots to play with\n");
		sprint(self, "sv_maplist - map list to cycle on servers\n");
		sprint(self, "Impulses:\n");
		sprint(self, "stats - shows current kill/death stats\n");
		sprint(self, "+button3 - secondary fire (used by some weapons)\n");
		sprint(self, "+button4 - zoom (available with all weapons)\n");
		sprint(self, "+button5 - grapple (not in singleplayer/coop)\n");
	}
	if (self.isadmin)
	{
		if (self.impulse >= 150 && self.impulse < 160) // admin stuff
		{
			if (self.impulse == 150) // local command
			{
				localcmd(self.netname);
				localcmd("\n");
				localcmd("say admin executing: ");
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
			{
				localcmd("temp1 ");
				localcmd(self.netname);
				localcmd("\n");
				localcmd("say admin executing: temp1 ");
				localcmd(self.netname);
				localcmd("\n");
			}
			if (self.impulse == 157) // slowmo change
			{
				localcmd("slow ");
				localcmd(self.netname);
				localcmd("\n");
				localcmd("say admin executing: slowmo ");
				localcmd(self.netname);
				localcmd("\n");
			}
			if (self.impulse == 158) // sys_ticrate change
			{
				localcmd("sys_ticrate ");
				localcmd(self.netname);
				localcmd("\n");
				localcmd("say admin executing: sys_ticrate ");
				localcmd(self.netname);
				localcmd("\n");
			}
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

	if (self.impulse == 100) // stats alias
		statshow();

	havocbot_impulses();

	if (!self.deadflag)
	if (cvar("sv_cheats"))
	{
		if (self.impulse == 44)
		{
			n = 0;
			while (n < 10000)
			{
				n = n + 1;
				tracebox(shotorg, '-16 -16 -16', '16 16 16', shotorg + 10000 * shotdir, TRUE, self);
			}
		}
		if (self.impulse == 43)
		{
			n = 0;
			while (n < 10000)
			{
				n = n + 1;
				tracebox(shotorg, '0 0 0', '0 0 0', shotorg + 10000 * shotdir, TRUE, self);
			}
		}
		if (self.impulse == 40)
			saveme();
		if (self.impulse == 41)
			loadme();
		if (self.impulse == 42)
			listfile();
		if (self.impulse == 43)
			lhfp_test();
		if (self.impulse == 52)
			lhbitparms_test();
		if (self.impulse >= 30 && self.impulse <= 39)
		{
			n = 0;
			while (n < 30)
			{
				n = n + 1;
				newmis = spawn();
				newmis.viewmodelforclient = self;
				newmis.owner = self;
				setmodel(newmis, "progs/player.mdl");
				//setsize(newmis, '-16 -16 -24', '16 16 24');
				newmis.movetype = MOVETYPE_NONE;
				newmis.solid = SOLID_NOT;
				//newmis.effects = EF_FLAME;
				newmis.frame = 0;
				newmis.angles = randompos('0 0 0', '360 360 360');
				newmis.origin = randompos('-64 -64 -64', '64 64 64');
				setorigin(newmis, newmis.origin);
			}
			sprint(self, "spawned 30 drones\n");
		}
		if (self.impulse == 29)
		{
			newmis = spawn();
			//newmis.viewmodelforclient = self;
			//newmis.owner = self;
			setmodel(newmis, "progs/player.mdl");
			setsize(newmis, '-16 -16 -24', '16 16 24');
			newmis.frame = 0;
			newmis.angles = '0 0 0';
			newmis.movetype = MOVETYPE_TOSS;
			newmis.solid = SOLID_SLIDEBOX;
			newmis.takedamage = DAMAGE_YES;
			newmis.health = 100;
			//newmis.effects = EF_FLAME;
			newmis.th_die = GibClone;
			setorigin(newmis, self.origin);
		}
		if (self.impulse == 28)
		{
			newmis = spawn();
			//newmis.viewmodelforclient = self;
			//newmis.owner = self;
			setmodel(newmis, "progs/player.mdl");
			setsize(newmis, '-16 -16 -24', '16 16 24');
			newmis.frame = 0;
			newmis.angles = '0 0 0';
			newmis.movetype = MOVETYPE_TOSS;
			newmis.solid = SOLID_SLIDEBOX;
			newmis.takedamage = DAMAGE_YES;
			newmis.health = 100;
			newmis.effects = EF_STARDUST;
			newmis.th_die = GibClone;
			setorigin(newmis, self.origin);
		}
		if (self.impulse == 26)
		{
			newmis = spawn();
			newmis.viewmodelforclient = newmis.owner = self;
			setmodel(newmis, "progs/v_dprock2.mdl");
			newmis.frame = 0;
			setorigin(newmis, '0 0 0');
			newmis.angles = '0 0 0';
		}
		if (self.impulse == 23)
		{
			makevectors(self.v_angle);
			weapontraceline(self.origin + self.view_ofs, self.origin + self.view_ofs + v_forward * 1024, FALSE, self);
			if (trace_ent)
			{
				if (trace_ent.effects & EF_FULLBRIGHT)
					trace_ent.effects = trace_ent.effects - EF_FULLBRIGHT;
				else
					trace_ent.effects = trace_ent.effects + EF_FULLBRIGHT;
			}
		}
		if (self.impulse == 16)
		{
			makevectors(self.v_angle);
			traceline(self.origin + self.view_ofs, self.origin + self.view_ofs + v_forward * 4096, FALSE, self);
			if (trace_ent)
				eprint(trace_ent);
		}
		if (self.impulse == 15)
		{
			makevectors(self.v_angle);
			traceline(self.origin + self.view_ofs, self.origin + self.view_ofs + v_forward * 4096, FALSE, self);
			if (trace_fraction < 1)
				printsurfaceinfo(trace_ent, trace_endpos);
		}
		if (self.impulse == 11)
		{
			// cheat: give the players a rune
			bprint (self.netname);
			bprint (" activated rune cheat\n");
			serverflags = serverflags * 2 + 1;
			serverflags = serverflags & 15; // 15 = 8 + 4 + 2 + 1
		}
		if (self.impulse == 234) CheatCommand ();
		if (self.impulse == 255)
		{
			// cheat: give the player a quad
			if (self.health < 1)
				return; // dead
			self.super_time = 1;
			self.super_damage_finished = time + 60;
			self.items = self.items | IT_QUAD;
			bprint (self.netname);
			bprint (" activated quad cheat\n");
		}
	}
	if ((self.impulse >= 1 && self.impulse <= 9) || (self.impulse >= 201 && self.impulse <= 220)) W_ChangeWeapon();
	else if (self.impulse == 10) CycleWeaponCommand ();
	else if (self.impulse == 12) CycleWeaponReverseCommand ();
	else if (self.impulse == 30) ToggleFlashLight();
	superdomination_impulses();

	self.impulse = 0;
};
