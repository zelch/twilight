///////////////////////////////////////////////
// Functions Source File
///////////////////////
// This file belongs to dpmod/darkplaces
// AK contains all menu controlling stuff (sub-menus)
////////////////////////////////

// default control functions
void(void)	defct_init = 
{
	if(self.init)
		self.init();
};

void(float keynr, float ascii)  defct_key =
{
	if(self.key)
		if(self.key(keynr, ascii))
			return;
		
	def_keyevent(keynr, ascii);
};

void(void)	defct_draw =
{
	if(self.draw)
		self.draw();
};

void(void)	defct_mouse_enter =
{
	if(self.mouse_enter)
		self.mouse_enter();
};

void(void)	defct_mouse_leave =
{
	if(self.mouse_leave)
		self.mouse_leave();
};

void(void)	defct_action =
{
	if(self.action)
		self.action();
};

// default key function
void(float keynr, float ascii)	def_keyevent =
{
	if(keynr == K_ESCAPE)
	{
		// move up to the parent
		menu_selectup();
	} else if(keynr == K_LEFTARROW || keynr == K_UPARROW)
	{
		// move to the previous element
		menu_selectprev();		
	} else if(keynr == K_RIGHTARROW || keynr == K_DOWNARROW)
	{
		// move to the  next element
		menu_selectnext();
	} else if(keynr == K_ENTER)
	{
		// move to the child menu
		menu_selectdown();
	}
};

// a rect is described by the top-left point and its size
float(vector point, vector r_xy, vector r_size) inrect =
{
	if(r_xy_x <= point_x && r_xy_y <= point_y && r_xy_x + r_size_x >= point_x && r_xy_y + r_size_y >= point_y)
		return true;
	return false;
};

vector(vector r_pos, vector r_size, vector c_pos, vector c_size) cliprectpos =
{
	// clip r_pos only
	r_pos_x = max(c_pos_x, r_pos_x);
	r_pos_y = max(c_pos_y, r_pos_y);
	
	return r_pos;
};

vector(vector r_pos, vector r_size, vector c_pos, vector c_size) cliprectsize =
{
	// safe version
	//r_size_x = bound(c_pos_x, r_pos_x + r_size_x, c_pos_x + c_size_x) - bound(c_pos_x, r_pos_x, c_pos_x + c_size_x);
	//r_size_y = bound(c_pos_y, r_pos_y + r_size_y, c_pos_y + c_size_y) - bound(c_pos_y, r_pos_y, c_pos_y + c_size_y);
	r_size_x = min(c_pos_x + c_size_x, r_pos_x + r_size_x) - max(c_pos_x, r_pos_x);
	r_size_y = min(c_pos_y + c_size_y, r_pos_y + r_size_y) - max(c_pos_y, r_pos_y);
	
	if(r_size_x <= 0 || r_size_y <= 0)
		r_size = '0 0 0';
	
	return r_size;
}
