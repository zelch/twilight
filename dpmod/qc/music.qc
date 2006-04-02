
void(string t) spawnmusicentities =
{
	precache_sound (t);
	//ambientsound ('-4095 -4095 -4095', t, 1.00, ATTN_NONE);
	//ambientsound ('4095 4095 4095', t, 1.00, ATTN_NONE);
	ambientsound ('0 0 0', t, 1.00, ATTN_NONE); // the DarkPlaces engine does not spatialize ATTN_NONE.
};

void() spawnmusic =
{
	//spawnmusicentities("music/music2.wav");
};
