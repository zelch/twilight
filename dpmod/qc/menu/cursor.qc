///////////////////////////////////////////////
// Cursor Source File
///////////////////////
// This file belongs to dpmod/darkplaces
// AK contains all cursor specific functions
////////////////////////////////

void(void) cursor_reset =
{
	cursor_x = rint(cvar("vid_conwidth")/2);
	cursor_y = rint(cvar("vid_conheight")/2);
	
	cursor_last_frame_time = time;
	cursor_color = '1 1 1';
	cursor_transparency = 1;
	cursor_type = CT_NORMAL;
};

void(void) cursor_init =
{
	// load the images
	if(CF_NORMAL != "")
		CF_NORMAL = precache_pic(CF_NORMAL);
	
	if(CF_NORMAL == "")
		CF_NORMAL = precache_pic("ui/mousepointer.tga");
	
	if(CF_PULSE_0 != "")
		CF_PULSE_0 = precache_pic(CF_PULSE_0);
	if(CF_PULSE_1 != "")
		CF_PULSE_1 = precache_pic(CF_PULSE_1);
	if(CF_PULSE_2 != "")
		CF_PULSE_2 = precache_pic(CF_PULSE_2);
	if(CF_PULSE_3 != "")
		CF_PULSE_3 = precache_pic(CF_PULSE_3);
	if(CF_PULSE_4 != "")
		CF_PULSE_4 = precache_pic(CF_PULSE_4);
	if(CF_PULSE_5 != "")
		CF_PULSE_5 = precache_pic(CF_PULSE_5);
	if(CF_PULSE_6 != "")
		CF_PULSE_6 = precache_pic(CF_PULSE_6);
	
	// init the values
	cursor_reset();
};

void(void) cursor_shutdown =
{
	if(CF_NORMAL != "")
		freepic(CF_NORMAL);
	if(CF_PULSE_0 != "")
		freepic(CF_PULSE_0);
	if(CF_PULSE_1 != "")
		freepic(CF_PULSE_1);
	if(CF_PULSE_2 != "")
		freepic(CF_PULSE_2);
	if(CF_PULSE_3 != "")
		freepic(CF_PULSE_3);
	if(CF_PULSE_4 != "")
		freepic(CF_PULSE_4);
	if(CF_PULSE_5 != "")
		freepic(CF_PULSE_5);
	if(CF_PULSE_6 != "")
		freepic(CF_PULSE_6);
};

void(void) cursor_frame =
{
	// update cursor animations

	if(cursor_type > CT_LAST_PULSE || cursor_type  < CT_FIRST_PULSE)
		cursor_last_frame_time = time;
	else if(cursor_last_frame_time + CA_PULSE_SPEED <= time)
		{
		cursor_type = CT_FIRST_PULSE + 
		mod((time - cursor_last_frame_time) / CA_PULSE_SPEED, CT_LAST_PULSE - CT_FIRST_PULSE +1);

		cursor_last_frame_time += rint((time - cursor_last_frame_time) / CA_PULSE_SPEED) * CA_PULSE_SPEED;
		}

	// update cursor position
	cursor = cursor + getmousepos();
	
	cursor_x = bound(0, cursor_x, cvar("vid_conwidth"));
	cursor_y = bound(0, cursor_y, cvar("vid_conheight"));
};

void(void) cursor_draw =
{
	string pic;
	
	if(cursor_type == CT_FIRST_PULSE + 0 && CF_PULSE_0 != "")
		pic = CF_PULSE_0;
	else if(cursor_type == CT_FIRST_PULSE + 1 && CF_PULSE_1 != "")
		pic = CF_PULSE_1;
	else if(cursor_type == CT_FIRST_PULSE + 2 && CF_PULSE_2 != "")
		pic = CF_PULSE_2;
	else if((cursor_type == CT_FIRST_PULSE + 3 || cursor_type == CT_GLOW) && CF_PULSE_3 != "")
		pic = CF_PULSE_3;
	else if(cursor_type == CT_FIRST_PULSE + 4 && CF_PULSE_4 != "")
		pic = CF_PULSE_4;
	else if(cursor_type == CT_FIRST_PULSE + 5 && CF_PULSE_5 != "")
		pic = CF_PULSE_5;
	else if(cursor_type == CT_FIRST_PULSE + 6 && CF_PULSE_6 != "")
		pic = CF_PULSE_6;
	else // if(cursor_tpye = CT_NORMAL)
		pic = CF_NORMAL;	
	drawpic(cursor,pic,'0 0 0', cursor_color, cursor_transparency, 0);	
};