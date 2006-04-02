
float maxclients; // set by worldspawn code
float numdecors;
float maxdecors;
.float createdtime;
.void() th_gib;

//void(vector org, entity en, vector dir, float splattype, float importance) newbloodsplat;
void(vector org, float bodydamage, float armordamage, vector vel, float damgtype) genericbleedfunc;

// removes the oldest decors each frame to maintain a certain maximum decors
void() decorframe =
{
	local entity estart, e, b1, b2, b3, b4, b5, b6, b7, b8, b9, b10;
	local float bt1, bt2, bt3, bt4, bt5, bt6, bt7, bt8, bt9, bt10, iterations;

	// numdecors is allowed to be bogus as long as it is >= the real number of decors
	// (but perfection is clearly preferable)
	if (numdecors <= maxdecors)
		return;

	// recount all the decors
	numdecors = 0;
	estart = e = findchain(classname, "decor");
	while(e)
	{
		numdecors = numdecors + 1;
		e = e.chain;
	}
	if (numdecors <= maxdecors)
		return; // nothing to do

	// limit it to considering 10000 entities per frame,
	// otherwise it can cause a runaway loop error
	iterations = 0;
	while (numdecors > maxdecors && iterations < 10000)
	{
		iterations = iterations + 1;
		// find and remove the oldest decors (upto 10 at once)
		b1 = b2  = b3  = b4  = b5  = b6 = b7 = b8 = b9 = b10 = world;
		bt1 = bt2 = bt3 = bt4 = bt5 = bt6 = bt7 = bt8 = bt9 = bt10 = time + 10000;
		if (iterations > 0)
			estart = findchain(classname, "decor");
		e = estart;
		while(e)
		{
			iterations = iterations + 1;
			if (e.createdtime < bt10)
			{
				if (e.createdtime < bt9)
				{
					if (e.createdtime < bt8)
					{
						if (e.createdtime < bt7)
						{
							if (e.createdtime < bt6)
							{
								if (e.createdtime < bt5)
								{
									if (e.createdtime < bt4)
									{
										if (e.createdtime < bt3)
										{
											if (e.createdtime < bt2)
											{
												if (e.createdtime < bt1)
												{
													b10=b9;bt10=bt9;
													b9=b8;bt9=bt8;
													b8=b7;bt8=bt7;
													b7=b6;bt7=bt6;
													b6=b5;bt6=bt5;
													b5=b4;bt5=bt4;
													b4=b3;bt4=bt3;
													b3=b2;bt3=bt2;
													b2=b1;bt2=bt1;
													b1=e;bt1=e.createdtime;
												}
												else
												{
													b10=b9;bt10=bt9;
													b9=b8;bt9=bt8;
													b8=b7;bt8=bt7;
													b7=b6;bt7=bt6;
													b6=b5;bt6=bt5;
													b5=b4;bt5=bt4;
													b4=b3;bt4=bt3;
													b3=b2;bt3=bt2;
													b2=e;bt2=e.createdtime;
												}
											}
											else
											{
												b10=b9;bt10=bt9;
												b9=b8;bt9=bt8;
												b8=b7;bt8=bt7;
												b7=b6;bt7=bt6;
												b6=b5;bt6=bt5;
												b5=b4;bt5=bt4;
												b4=b3;bt4=bt3;
												b3=e;bt3=e.createdtime;
											}
										}
										else
										{
											b10=b9;bt10=bt9;
											b9=b8;bt9=bt8;
											b8=b7;bt8=bt7;
											b7=b6;bt7=bt6;
											b6=b5;bt6=bt5;
											b5=b4;bt5=bt4;
											b4=e;bt4=e.createdtime;
										}
									}
									else
									{
										b10=b9;bt10=bt9;
										b9=b8;bt9=bt8;
										b8=b7;bt8=bt7;
										b7=b6;bt7=bt6;
										b6=b5;bt6=bt5;
										b5=e;bt5=e.createdtime;
									}
								}
								else
								{
									b10=b9;bt10=bt9;
									b9=b8;bt9=bt8;
									b8=b7;bt8=bt7;
									b7=b6;bt7=bt6;
									b6=e;bt6=e.createdtime;
								}
							}
							else
							{
								b10=b9;bt10=bt9;
								b9=b8;bt9=bt8;
								b8=b7;bt8=bt7;
								b7=e;bt7=e.createdtime;
							}
						}
						else
						{
							b10=b9;bt10=bt9;
							b9=b8;bt9=bt8;
							b8=e;bt8=e.createdtime;
						}
					}
					else
					{
						b10=b9;bt10=bt9;
						b9=e;bt9=e.createdtime;
					}
				}
				else
				{
					b10=e;bt10=e.createdtime;
				}
			}
			// failed all 10 slots
			e = e.chain;
		}
		// remove the oldest decors
		if (numdecors > maxdecors) {numdecors = numdecors - 1;remove(b1);}
		if (numdecors > maxdecors) {numdecors = numdecors - 1;remove(b2);}
		if (numdecors > maxdecors) {numdecors = numdecors - 1;remove(b3);}
		if (numdecors > maxdecors) {numdecors = numdecors - 1;remove(b4);}
		if (numdecors > maxdecors) {numdecors = numdecors - 1;remove(b5);}
		if (numdecors > maxdecors) {numdecors = numdecors - 1;remove(b6);}
		if (numdecors > maxdecors) {numdecors = numdecors - 1;remove(b7);}
		if (numdecors > maxdecors) {numdecors = numdecors - 1;remove(b8);}
		if (numdecors > maxdecors) {numdecors = numdecors - 1;remove(b9);}
		if (numdecors > maxdecors) {numdecors = numdecors - 1;remove(b10);}
	}
};

entity() newdecor =
{
	local entity e;
	numdecors++;
	e = spawn();
	e.classname = "decor";
	return e;
};

void(entity e) removedecor =
{
	numdecors--;
	remove(e);
};

/*
void() s_animthink =
{
	self.nextthink = time + 0.1;
	self.frame = self.frame + 1;
	if (self.frame >= self.dmg)
	{
		self.frame = self.dmg;
		self.think = SUB_Remove;
		self.nextthink = time + 0.2;
	}
*/
	/*
	self.nextthink = time; // max accuracy
	self.frame = floor((time - self.cnt) * self.lefty + self.cnt2);
	if (self.frame < 0 || self.frame >= self.dmg)
		remove(self);
	*/
/*
};

void(entity e, string m, float sstarttime, float sfirstframe, float sendframe) s_anim =
{
	setmodel(e, m);
	setsize(e, '-4 -4 -4', '4 4 4');
	e.cnt = sstarttime;
	e.cnt2 = sfirstframe;
	e.dmg = sendframe - 1;
	//e.lefty = sframerate;
	e.think = s_animthink;
	e.nextthink = time;
	e.frame = sfirstframe;
	e.effects = e.effects | EF_LOWPRECISION;
};
*/

void(vector org, vector vel, float amount) blood =
{
	te_blood(org, vel, amount);
	/*
	if (amount > 255) amount = 255;
	if (vlen(vel) > 127) vel = normalize(vel) * 127;
	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_BLOOD);
	WriteVec (MSG_BROADCAST, org);
	WriteByte (MSG_BROADCAST, vel_x);
	WriteByte (MSG_BROADCAST, vel_y);
	WriteByte (MSG_BROADCAST, vel_z);
	WriteByte (MSG_BROADCAST, amount);
	*/
};

void(vector org, vector vel, float amount) spark =
{
	te_spark(org, vel, amount);
	/*
	if (amount > 255) amount = 255;
	if (vlen(vel) > 127) vel = normalize(vel) * 127;
	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_SPARK);
	WriteVec (MSG_BROADCAST, org);
	WriteByte (MSG_BROADCAST, vel_x);
	WriteByte (MSG_BROADCAST, vel_y);
	WriteByte (MSG_BROADCAST, vel_z);
	WriteByte (MSG_BROADCAST, amount);
	*/
};

void(vector m1, vector m2, float vel, float amount) bloodshower =
{
	te_bloodshower(m1, m2, vel, amount);
	/*
	if (amount < 0)
		return;
	if (amount < 1)
		amount = (m2_x - m1_x)*(m2_y - m1_y)*(m2_z - m1_z)/64;
	if (amount < 1)
		return;
	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_BLOODSHOWER);
	WriteVec (MSG_BROADCAST, m1);
	WriteVec (MSG_BROADCAST, m2);
	WriteCoord (MSG_BROADCAST, vel);
	WriteShort (MSG_BROADCAST, amount);
	*/
};

void(vector org, float quad) bulletpuff =
{
	if (quad)
		te_gunshotquad(org);
	else
		te_gunshot(org);
};

void(vector org, float quad) nailpuff =
{
	if (quad)
		te_superspikequad(org);
	else
		te_superspike(org);
};

// used for various little bouncing debris to avoid getting stuck in the air
void() DecorThink =
{
	self.nextthink = time;
	self.flags = self.flags - (self.flags & FL_ONGROUND);
	if (pointcontents(self.origin) == CONTENT_SOLID)
		removedecor(self);
};

.float createdtime;

void() InitCasings;
void() InitGore;
void() InitDecals;
void() InitDecors =
{
	InitCasings();
	InitDecals();
	InitGore(); // just to keep it all here...

	// different number of decors in multi-player (to avoid lag on modems)
	if (maxclients > 1)
		maxdecors = 32;
	else
		maxdecors = 100;
	// overridable by saved2 cvar on server console
	if (cvar("decors"))
		maxdecors = cvar("decors");
	if (maxdecors < 1)
		maxdecors = 1;
};
