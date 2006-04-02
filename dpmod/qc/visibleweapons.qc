// Written by Forest "LordHavoc" Hale. (as is the rest of Dark Places)
//
// This has no relation to any other visible weapon code in existence,
// as I've never read any visible weapon code.
//
// The models were ripped from the Quake Done Quick movies,
// but I did all this code.

float modelindex_eyes/*, modelindex_player*/;
//float modelindex_player_sg, modelindex_player_dbsg;
//float modelindex_player_ng, modelindex_player_sng;
//float modelindex_player_gl, modelindex_player_rl;
//float modelindex_player_lg;
float modelindex_nogun;

float VWEP_GENERIC = 0;
float VWEP_AXE = 1;
float VWEP_SHOTGUN = 2;
float VWEP_SUPER_SHOTGUN = 3;
float VWEP_NAILGUN = 4;
float VWEP_SUPER_NAILGUN = 5;
float VWEP_GRENADE_LAUNCHER = 6;
float VWEP_ROCKET_LAUNCHER = 7;
float VWEP_LIGHTNING = 8;

//.float lastframe;
.entity weaponent;

void() weaponentthink =
{
	local float hide;
	self.nextthink = time;
	if (self.owner.weaponent != self)
	{
		remove(self);
		return;
	}

	if (self.owner.deadflag)
		hide = TRUE;
	else if (!self.owner.solid)
		hide = TRUE;
	else if (self.owner.items & IT_INVISIBILITY)
		hide = TRUE;
	else if (self.owner.frame >= 6 && self.owner.frame < 12) // run
		hide = FALSE;
	else if (self.owner.frame >= 12 && self.owner.frame < 17) // stand
		hide = FALSE;
	else if (self.owner.frame >= 35 && self.owner.frame < 41) // pain
		hide = FALSE;
	else if (self.owner.frame >= 102 && self.owner.frame < 119) // firing anims
		hide = FALSE;
	else
		hide = TRUE;

	if (hide)
		self.model = "";
	else
	{
		self.model = "progs/playergun.mdl";
		self.alpha = self.owner.alpha;
		self.frame = self.owner.frame;
	}
};

void() dovisibleweapon =
{
	if (!self.weaponent)
	{
		self.weaponent = newmis = spawn();
		self.weaponent.classname = "playergun";
		self.weaponent.owner = self;
		self.weaponent.think = weaponentthink;
		self.weaponent.nextthink = time;
		setmodel(self.weaponent, "progs/playergun.mdl");
		setattachment(self.weaponent, self, "");
	}
	if (self.deadflag || !self.solid) // dead or observer
	{
		// don't tinker with the model when dead, might be a gibbed head
		return;
	}
	else if (self.items & IT_INVISIBILITY)
	{
		self.model = "progs/player.mdl";
		self.modelindex = modelindex_eyes;
		self.frame = 0;
	}
	else
	{
		self.model = "progs/player.mdl"; // make player visible
		self.modelindex = modelindex_nogun;
		/*
		if (self.frame != self.lastframe) // FIXME: quite a hack
		{
			self.modelindex = modelindex_player;
	if (self.visibleweapon == VWEP_GENERIC)
				self.modelindex = modelindex_player;
			else if (self.visibleweapon == VWEP_SHOTGUN)
				self.modelindex = modelindex_player_sg;
			else if (self.visibleweapon == VWEP_SUPER_SHOTGUN)
				self.modelindex = modelindex_player_dbsg;
			else if (self.visibleweapon == VWEP_NAILGUN)
				self.modelindex = modelindex_player_ng;
			else if (self.visibleweapon == VWEP_SUPER_NAILGUN)
				self.modelindex = modelindex_player_sng;
			else if (self.visibleweapon == VWEP_GRENADE_LAUNCHER)
				self.modelindex = modelindex_player_gl;
			else if (self.visibleweapon == VWEP_ROCKET_LAUNCHER)
				self.modelindex = modelindex_player_rl;
			else if (self.visibleweapon == VWEP_LIGHTNING)
				self.modelindex = modelindex_player_lg;
			if (self.modelindex != modelindex_player)
			{
				// remap to the visible weapon player model
	if (self.frame >= 6 && self.frame < 12) // run
					self.frame = self.frame - 6;
				else if (self.frame >= 12 && self.frame < 17) // stand
					self.frame = self.frame - 6;
				else if (self.frame >= 35 && self.frame < 41) // pain
					self.frame = self.frame - 24;
				else if (self.frame >= 102) // firing anims
				{
	if (self.frame < 105)
						self.frame = self.frame + 17 - 103;
					else if (self.frame < 107)
						self.frame = self.frame + 17 - 105;
					else if (self.frame < 113)
						self.frame = self.frame + 17 - 107;
					else if (self.frame < 119)
						self.frame = self.frame + 17 - 113;
					else
						self.modelindex = modelindex_player;
				}
				else
					self.modelindex = modelindex_player;
			}
			self.lastframe = self.frame;
		}
		*/
	}
};
