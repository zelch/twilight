
void() gibcomment_precache =
{
	/*
	// gib comments (most lines are by Lord Havoc,
	//               and all performed by Lord Havoc)
	precache_sound("speech/gib/awesome.wav"); // awesome
	precache_sound("speech/gib/cool.wav"); // cool
	precache_sound("speech/gib/gibsjust.wav"); // gibs, just the way I like 'em
	precache_sound("speech/gib/groovy.wav"); // groovy
	precache_sound("speech/gib/hehehmes.wav"); // heheh, messy
	precache_sound("speech/gib/lookbetr.wav"); // you look better dead
	precache_sound("speech/gib/mmmgibs.wav"); // mmm... gibs...
	precache_sound("speech/gib/niceday.wav"); // nice day for some gibbing
	precache_sound("speech/gib/whatames.wav"); // what a mess
	precache_sound("speech/gib/whoa.wav"); // whoa
	precache_sound("speech/gib/xtrachnk.wav"); // extra chunky
	// these lines were submitted by Terrorist
	precache_sound("speech/gib/aisle12.wav"); // cleanup in aisle 12
	precache_sound("speech/gib/scrapeof.wav"); // scrape him off the wall
	precache_sound("speech/gib/needamop.wav"); // I need a mop
	*/
};

// .float dogibcomment;
// .float gibcommenttime;
// .float seengibs;       // how many gibbings since last comment

void(entity e) DoGibComment =
{
	/*
	local float c, d;
	// chance of comment goes up with more gibs
	// note that this number includes how long they were seen
	c = floor(random()*20);
	if (e.seengibs < c)
		return;
	*/
	/*
	d = e.seengibs;
	if (d > 20)
		d = 20;
	c = floor(random() * (d * 15 / 20));
	*/
	/*
	c = floor(random() * 14);
	if (c == 0) sound(e, CHAN_SPEECH, "speech/gib/awesome.wav", 1, ATTN_NORM);
	if (c == 1) sound(e, CHAN_SPEECH, "speech/gib/cool.wav", 1, ATTN_NORM);
	if (c == 2) sound(e, CHAN_SPEECH, "speech/gib/gibsjust.wav", 1, ATTN_NORM);
	if (c == 3) sound(e, CHAN_SPEECH, "speech/gib/groovy.wav", 1, ATTN_NORM);
	if (c == 4) sound(e, CHAN_SPEECH, "speech/gib/hehehmes.wav", 1, ATTN_NORM);
	if (c == 5) sound(e, CHAN_SPEECH, "speech/gib/lookbetr.wav", 1, ATTN_NORM);
	if (c == 6) sound(e, CHAN_SPEECH, "speech/gib/mmmgibs.wav", 1, ATTN_NORM);
	if (c == 7) sound(e, CHAN_SPEECH, "speech/gib/niceday.wav", 1, ATTN_NORM);
	if (c == 8) sound(e, CHAN_SPEECH, "speech/gib/whatames.wav", 1, ATTN_NORM);
	if (c == 9) sound(e, CHAN_SPEECH, "speech/gib/whoa.wav", 1, ATTN_NORM);
	if (c == 10) sound(e, CHAN_SPEECH, "speech/gib/xtrachnk.wav", 1, ATTN_NORM);
	// these lines were submitted by Terrorist
	if (c == 11) sound(e, CHAN_SPEECH, "speech/gib/aisle12.wav", 1, ATTN_NORM);
	if (c == 12) sound(e, CHAN_SPEECH, "speech/gib/scrapeof.wav", 1, ATTN_NORM);
	if (c == 13) sound(e, CHAN_SPEECH, "speech/gib/needamop.wav", 1, ATTN_NORM);
	*/
	/*
	c = floor(random() * 5);
	if (c == 0) sound(e, CHAN_SPEECH, "speech/gib/awesome.wav", 1, ATTN_NORM);
	if (c == 1) sound(e, CHAN_SPEECH, "speech/gib/lookbetr.wav", 1, ATTN_NORM);
	// these lines were submitted by Terrorist
	if (c == 2) sound(e, CHAN_SPEECH, "speech/gib/aisle12.wav", 1, ATTN_NORM);
	if (c == 3) sound(e, CHAN_SPEECH, "speech/gib/scrapeof.wav", 1, ATTN_NORM);
	if (c == 4) sound(e, CHAN_SPEECH, "speech/gib/needamop.wav", 1, ATTN_NORM);
	*/
};

void() GibCommentCheck =
{
	/*
	if (!self.dogibcomment)
		return;
	if (time > self.gibcommenttime)
	if (self.seengibs >= 20)
	{
		DoGibComment(self);
		self.dogibcomment = 0;
		self.seengibs = 0;
	}
	*/
};

void() DelayGibComment =
{
//        self.gibcommenttime = time + 4;
};

void(entity e, float timeseen) GibComment =
{
/*
	if (e.classname == "player")
	{
		e.seengibs = e.seengibs + timeseen;
		e.dogibcomment = 1;
		if (time + 2 > e.gibcommenttime)
			e.gibcommenttime = time + 2;
	}
*/
};

void(vector org, float timeseen) checkforgibcomments =
{
	/*
	local entity head;
	local vector v;
	head = world;
	while ((head = find(head, classname, "player")) != world)
	{
		v = randompos(head.absmin, head.absmax);
		traceline(org, v, TRUE, world);
		if (trace_fraction == 1)
		if (!(trace_inwater && trace_inopen))
			GibComment(head, timeseen);
	}
	*/
};
