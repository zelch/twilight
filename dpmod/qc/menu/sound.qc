///////////////////////////////////////////////
// Sound Source File
///////////////////////
// This file belongs to dpmod/darkplaces
// AK contains all manager constants, etc.
////////////////////////////////

void(void) sound_init =
{
	precache_sound(SOUND_SELECT);
	precache_sound(SOUND_CHANGE);
	precache_sound(SOUND_ACTION);
};

void(void) sound_frame =
{
};

void(void) sound_shutdown =
{
};

void(string sound_name) sound_play =
{
	localsound(sound_name);
};
