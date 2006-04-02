void() footstepsound =
{
	local float r;

	if (!self.solid) // observer
		return;
	if (self.deadflag) // not walking dead...
		return;

	if (!(self.flags & FL_ONGROUND))
		return;

		if (game != GAME_NEXUIZ)
		{
			r = random() * 7;
			// ATTN_IDLE to make them short range
			if (r < 1) sound(self, CHAN_FOOT, "misc/foot1.wav", 0.5, ATTN_IDLE);
			else if (r < 2) sound(self, CHAN_FOOT, "misc/foot2.wav", 0.5, ATTN_IDLE);
			else if (r < 3) sound(self, CHAN_FOOT, "misc/foot3.wav", 0.5, ATTN_IDLE);
			else if (r < 4) sound(self, CHAN_FOOT, "misc/foot4.wav", 0.5, ATTN_IDLE);
			else if (r < 5) sound(self, CHAN_FOOT, "misc/foot5.wav", 0.5, ATTN_IDLE);
			else if (r < 6) sound(self, CHAN_FOOT, "misc/foot6.wav", 0.5, ATTN_IDLE);
			else            sound(self, CHAN_FOOT, "misc/foot7.wav", 0.5, ATTN_IDLE);
		}
};

.float nextfootstep;

void() playerfootstep =
{
	if (vlen(self.velocity) < 300)
		return;
	if (time < self.nextfootstep)
		return;
	self.nextfootstep = time + 0.3;
	footstepsound();
};
