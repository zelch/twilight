///////////////////////////////////////////////
// Menu Source File
///////////////////////
// This file belongs to dpmod/darkplaces
// AK contains all menu functions (especially the required ones)
////////////////////////////////

void(void) m_init = 
{
	// init cursor
	cursor_init();
	
	// init sound
	sound_init();
};

// required menu functions
float menu_active;
void(float keynr, float ascii) m_keydown = 
{
	if(keynr == K_ESCAPE)
		m_toggle();
};

void(void) m_frame =
{
	// cursor frame
	cursor_frame();
	
	// sound frame
	sound_frame();
};

void(void) m_draw = 
{
	if(!menu_active)
		return;
	
	// call m_frame cause draw is the only menu function called once per frame
	m_frame();
	
	// now the drawing code
	cursor_draw();
};

void(void) m_toggle = 
{
	if(!menu_active)
	{
		menu_active = TRUE;
		
		// update isserver and clientstate
		gamestatus = 0;
		if(isserver())
			gamestatus = gamestatus | GAME_ISSERVER;
		if(clientstate() == CS_CONNECTED)
			gamestatus = gamestatus | GAME_CONNECTED;
		
		// redirect keyboard input
		setkeydest(KEY_MENU);
		// stop the client getting mouse coords
		setmousetarget(MT_MENU);
		// let the menu manager know
		menu_reset();
	} else
	{
		setkeydest(KEY_GAME);
		setmousetarget(MT_CLIENT);
		menu_active = FALSE;
	}
};

void(void) m_shutdown = 
{
	// shutdown sound
	sound_shutdown();
	
	// shutdown cursor
	cursor_shutdown();
};