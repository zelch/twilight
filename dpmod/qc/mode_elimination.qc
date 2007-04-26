
// states
float ELIM_EMPTY = 0;
float ELIM_PREMATCH = 1;
float ELIM_BEGIN = 2;
float ELIM_MATCH = 3;

// settings
float ELIMROUNDS = 5; // rounds to win (best 5 out of 9)

float elimstate, elimrallytime, elimmessage, elimround;

.float teamupdatetime;

void() modeelimframe = {};

void(float color) modeelimteam =
{
	if (elimstate == ELIM_MATCH)
	{
		sprint(self, "You can not change team during the match\n");
		return;
	}
	setcolor(color);
};
void() modeelimplayer = {};

void() elim_chooseteams =
{
	local entity head;
	head = find(world, classname, "player");
	while (head)
	{
		if (head.desiredteam < 0)
			head.desiredteam = 0;
		if (head.chosenteam != head.desiredteam)
		{
			head.chosenteam = head.desiredteam;
			//head.desiredteam = 0; // clear it
			respawnplayer(head);
		}
		head = find(head, classname, "player");
	}
};

void() elim_clearteamchoices =
{
	local entity head;
	head = findchain(classname, "player");
	while (head)
	{
		head.desiredteam = 0;
		head = head.chain;
	}
};

void() DM_Elimination =
{
	local float teamsdefined, teamsactive, /*teamswrong, */n;
	local entity head/*, head2*/, winner;
	local string s;
	matchmode = TRUE; // like nofire but checks team first
	teamsdefined = 0;
	if (team2.cnt ) teamsdefined = teamsdefined + 1;
	if (team3.cnt ) teamsdefined = teamsdefined + 1;
	if (team4.cnt ) teamsdefined = teamsdefined + 1;
	if (team5.cnt ) teamsdefined = teamsdefined + 1;
	if (team6.cnt ) teamsdefined = teamsdefined + 1;
	if (team7.cnt ) teamsdefined = teamsdefined + 1;
	if (team8.cnt ) teamsdefined = teamsdefined + 1;
	if (team9.cnt ) teamsdefined = teamsdefined + 1;
	if (team10.cnt) teamsdefined = teamsdefined + 1;
	if (team11.cnt) teamsdefined = teamsdefined + 1;
	if (team12.cnt) teamsdefined = teamsdefined + 1;
	if (team13.cnt) teamsdefined = teamsdefined + 1;
	if (team14.cnt) teamsdefined = teamsdefined + 1;
	teamsactive = 0;
	if (team2.count ) teamsactive = teamsactive + 1;
	if (team3.count ) teamsactive = teamsactive + 1;
	if (team4.count ) teamsactive = teamsactive + 1;
	if (team5.count ) teamsactive = teamsactive + 1;
	if (team6.count ) teamsactive = teamsactive + 1;
	if (team7.count ) teamsactive = teamsactive + 1;
	if (team8.count ) teamsactive = teamsactive + 1;
	if (team9.count ) teamsactive = teamsactive + 1;
	if (team10.count) teamsactive = teamsactive + 1;
	if (team11.count) teamsactive = teamsactive + 1;
	if (team12.count) teamsactive = teamsactive + 1;
	if (team13.count) teamsactive = teamsactive + 1;
	if (team14.count) teamsactive = teamsactive + 1;
	head = findchain(classname, "player");
	while (head)
	{
		if (head.team != head.lastteam)
		{
			if (head.flags & FL_CLIENT)
			{
				if (time > head.teamupdatetime)
				{
					head.teamupdatetime = time + 0.5;
					stuffcmd(head, "color ");
					s = ftos(head.lastteam - 1);
					stuffcmd(head, s);
					stuffcmd(head, "\n");
					setplayercolor(
				}
			}
			else
				head.team = head.lastteam;
		}
		head = head.chain;
	}
	if (teamsdefined < 2)
		elimstate = ELIM_EMPTY;
	if (elimstate == ELIM_EMPTY)
	{
		nofire = TRUE;
		elim_chooseteams();
		if (teamsdefined >= 2)
		{
			elimstate = ELIM_PREMATCH;
			elimrallytime = time + 20;
		}
		else
		{
			if (time > elimmessage)
			{
				elimmessage = time + 0.8;
				head = findchain(classname, "player");
				while (head)
				{
					if (head.flags & FL_CLIENT)
					{
						if (head.chosenteam >= 2)
							centerprint(head, "Dark Places\nElimination Mode\n------\nwaiting for another team to form");
						else
							centerprint(head, "Dark Places\nElimination Mode\n------\nwaiting for teams to form");
					}
					head = head.chain;
				}
			}
		}
	}
	else if (elimstate == ELIM_PREMATCH)
	{
		nofire = TRUE;
		elim_chooseteams();
		if (time > elimrallytime)
		{
			bprint("The match begins\n");
			// clear the round counters
			team1.cnt2  = 0;team2.cnt2  = 0;
			team3.cnt2  = 0;team4.cnt2  = 0;
			team5.cnt2  = 0;team6.cnt2  = 0;
			team7.cnt2  = 0;team8.cnt2  = 0;
			team9.cnt2  = 0;team10.cnt2 = 0;
			team11.cnt2 = 0;team12.cnt2 = 0;
			team13.cnt2 = 0;team14.cnt2 = 0;
			elimstate = ELIM_BEGIN;
			elimround = 1;
			respawnplayers();
		}
		else if (time > elimmessage)
		{
			elimmessage = time + 0.8;
			n = floor(elimrallytime - time);
			s = ftos(n);
			head = findchain(classname, "player");
			while (head)
			{
				if (head.flags & FL_CLIENT)
				{
					if (head.chosenteam >= 2)
						centerprint(head, "Dark Places\nElimination Mode\n------\n", s, " sec until match");
					else
						centerprint(head, "Dark Places\nElimination Mode\n------\n", s, " sec until match, join now or watch");
				}
				head = head.chain;
			}
		}
	}
	else if (elimstate == ELIM_BEGIN)
	{
		nofire = TRUE;
		if (teamsactive >= 2)
		{
			elimstate = ELIM_MATCH;
			bprint("Round ");
			bprintfloat(elimround);
			bprint(", best ");
			bprintfloat(ELIMROUNDS);
			bprint(" of ");
			bprintfloat((ELIMROUNDS - 1) * teamsdefined + 1);
			bprint(" (");
			bprintfloat(teamsdefined);
			bprint(" teams)\n");
			// example:
			// Round 1, best 5 of 13 (3 teams)
		}
		else
		{
			if (time > elimmessage)
			{
				elimmessage = time + 0.8;
				head = findchain(classname, "player");
				while (head)
				{
					if (head.flags & FL_CLIENT)
						centerprint(head, "Dark Places\nElimination Mode\n------\nwaiting for teams to update");
					head = head.chain;
				}
			}
		}
	}
	else if (elimstate == ELIM_MATCH)
	{
		if (teamsactive < 2) // round over
		{
			nofire = TRUE; // prevent all firing
			if (time > fightdone) // set by weapons fire
			{
				elimstate = ELIM_BEGIN;
				winner = world;
					if (team2.count ) winner = team2 ;
				else if (team3.count ) winner = team3 ;
				else if (team4.count ) winner = team4 ;
				else if (team5.count ) winner = team5 ;
				else if (team6.count ) winner = team6 ;
				else if (team7.count ) winner = team7 ;
				else if (team8.count ) winner = team8 ;
				else if (team9.count ) winner = team9 ;
				else if (team10.count) winner = team10;
				else if (team11.count) winner = team11;
				else if (team12.count) winner = team12;
				else if (team13.count) winner = team13;
				else if (team14.count) winner = team14;
				if (winner)
				{
					winner.cnt2 = winner.cnt2 + 1;
					elimround = elimround + 1;
					if (winner.cnt2 >= ELIMROUNDS)
					{
						bprint(winner.netname);
						bprint(" team wins the match\n");
						head = findchain(classname, "player");
						while(head)
						{
							head.desiredteam = 0;
							head.chosenteam = 0;
							head.lastteam = 1;
							head = head.chain;
						}
						elimstate = ELIM_EMPTY;
					}
					else
					{
						bprint(winner.netname);
						bprint(" team has won ");
						bprintfloat(winner.cnt2);
						bprint(" rounds and needs ");
						bprintfloat(ELIMROUNDS - winner.cnt2);
						bprint(" more to win\n");
					}
				}
				else
					bprint("All teams annihilated, round is a tie and will be replayed\n");
				respawnplayers();
			}
		}
	}
	if (time > elimmessage)
		elimmessage = time + 1;
};

float nextcvarupdate;
void() modeupdate =
{
	local entity head;
	nofire = FALSE;
	matchmode = FALSE; // changed by DM_ code
	if (deathmatch == DM_ELIM)
	{
		head = findchain(classname, "player");
		while (head)
		{
			if (head.deadflag)
				head.lastteam = 1; // white
			else
				head.lastteam = head.chosenteam;
			head = head.chain;
		}
	}
	team1.count  = team1.cnt  = 0;team2.count  = team2.cnt  = 0;team3.count  = team3.cnt  = 0;team4.count  = team4.cnt  = 0;
	team5.count  = team5.cnt  = 0;team6.count  = team6.cnt  = 0;team7.count  = team7.cnt  = 0;team8.count  = team8.cnt  = 0;
	team9.count  = team9.cnt  = 0;team10.count = team10.cnt = 0;team11.count = team11.cnt = 0;team12.count = team12.cnt = 0;
	team13.count = team13.cnt = 0;team14.count = team14.cnt = 0;
	head = findchain(classname, "player");
	if (head)
	{
		while(head)
		{
			if (head.lastteam)
			{
	if (head.lastteam ==  1) team1.count  = team1.count  + 1;
				else if (head.lastteam ==  2) team2.count  = team2.count  + 1;
				else if (head.lastteam ==  3) team3.count  = team3.count  + 1;
				else if (head.lastteam ==  4) team4.count  = team4.count  + 1;
				else if (head.lastteam ==  5) team5.count  = team5.count  + 1;
				else if (head.lastteam ==  6) team6.count  = team6.count  + 1;
				else if (head.lastteam ==  7) team7.count  = team7.count  + 1;
				else if (head.lastteam ==  8) team8.count  = team8.count  + 1;
				else if (head.lastteam ==  9) team9.count  = team9.count  + 1;
				else if (head.lastteam == 10) team10.count = team10.count + 1;
				else if (head.lastteam == 11) team11.count = team11.count + 1;
				else if (head.lastteam == 12) team12.count = team12.count + 1;
				else if (head.lastteam == 13) team13.count = team13.count + 1;
				else if (head.lastteam == 14) team14.count = team14.count + 1;
			}
			if (head.chosenteam)
			{
	if (head.chosenteam ==  1) team1.cnt  = team1.cnt  + 1;
				else if (head.chosenteam ==  2) team2.cnt  = team2.cnt  + 1;
				else if (head.chosenteam ==  3) team3.cnt  = team3.cnt  + 1;
				else if (head.chosenteam ==  4) team4.cnt  = team4.cnt  + 1;
				else if (head.chosenteam ==  5) team5.cnt  = team5.cnt  + 1;
				else if (head.chosenteam ==  6) team6.cnt  = team6.cnt  + 1;
				else if (head.chosenteam ==  7) team7.cnt  = team7.cnt  + 1;
				else if (head.chosenteam ==  8) team8.cnt  = team8.cnt  + 1;
				else if (head.chosenteam ==  9) team9.cnt  = team9.cnt  + 1;
				else if (head.chosenteam == 10) team10.cnt = team10.cnt + 1;
				else if (head.chosenteam == 11) team11.cnt = team11.cnt + 1;
				else if (head.chosenteam == 12) team12.cnt = team12.cnt + 1;
				else if (head.chosenteam == 13) team13.cnt = team13.cnt + 1;
				else if (head.chosenteam == 14) team14.cnt = team14.cnt + 1;
			}
			head = head.chain;
		}
	}
	if (time > nextcvarupdate)
	{
		nextcvarupdate = time + 1;
		mode_updatecvars();
	}
	if (deathmatch == DM_ONEVSALL)
		DM_KillTheLeader();
	else if (deathmatch == DM_ELIM)
		DM_Elimination();
};


