///////////////////////////////////////////////
// Custom Menu Source File
///////////////////////
// This file belongs to dpmod/darkplaces
// AK contains menu specific stuff that is made especially for dpmod
// AK this file is used e.g. for defining some special event functions
////////////////////////////////////////////////

void(void) dpmod_stddraw =
{
	if(self.flag & _FLAG_MOUSEINAREA)
	{
		menu_fillarea(self.pos, self.size, dpmod_mouseover_color, dpmod_mouseover_alpha, dpmod_mouseover_drawflag);
	}
	else if(menu_selected == self)
		menu_fillarea(self.pos, self.size, dpmod_selected_color, dpmod_selected_alpha, dpmod_selected_drawflag);
};

void(void)	dpmod_main_exit =
{
	entity e;
	e = menu_getitem("MAIN_EXIT_MENU");
	e.flag = FLAG_NOSELECT;
	e = menu_getitem("MAIN_MENU");
	e.flag = FLAG_NOSELECT + FLAG_CHILDDRAWONLY;
	menu_jumptowindow(menu_getitem("MAIN_EXIT_MENU"), false);
};

void(void) dpmod_main_exit_no =
{
	entity e;
	e = menu_getitem("MAIN_EXIT_MENU");
	e.flag = FLAG_NOSELECT + FLAG_HIDDEN;
	e = menu_getitem("MAIN_MENU");
	e.flag = FLAG_NOSELECT;
	menu_selectup();
};

void(void) dpmod_main_exit_yes =
{
	cmd("quit\n");
};

float(float key, float ascii) dpmod_main_exit_key =
{
	if(key == K_ESCAPE)
	{
		dpmod_main_exit_no();
		return true;
	}
}