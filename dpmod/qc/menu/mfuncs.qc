///////////////////////////////////////////////
// Functions Source File
///////////////////////
// This file belongs to dpmod/darkplaces
// AK contains all menu controlling stuff (sub-menus)
///////////////////////////////////////////////


// safe call control function functions
// default control functions
void(void)	ctcall_init =
{
	if(self.init)
		self.init();
};

float(float keynr, float ascii)  ctcall_key =
{
	if(self.key)
		return self.key(keynr, ascii);
};

void(void)	ctcall_draw =
{
	if(self.draw)
		self.draw();
};

void(void)	ctcall_mouse_enter =
{
	if(self.mouse_enter)
		self.mouse_enter();
};

void(void)	ctcall_mouse_leave =
{
	if(self.mouse_leave)
		self.mouse_leave();
};

void(void)	ctcall_action =
{
	if(self.action)
		self.action();
};

void(void) ctcall_refresh =
{
	if(self.refresh)
		self.refresh();
}

// default control functions
void(void)	defct_init =
{
	ctcall_init();
};

void(float keynr, float ascii)  defct_key =
{
	if(!ctcall_key(keynr, ascii))
		def_keyevent(keynr, ascii);
};

void(void)	defct_draw =
{
	ctcall_draw();
};

void(void)	defct_mouse_enter =
{
	ctcall_mouse_enter();
};

void(void)	defct_mouse_leave =
{
	ctcall_mouse_leave();
};

void(void)	defct_action =
{
	ctcall_action();
};

void(void)	defct_refresh =
{
	// do first the own fresh stuff and *then* call refresh
	def_refresh();
	ctcall_refresh();
}

// default refresh function
void(void)	def_refresh =
{
	// refresh stuff
	if(self.flag & FLAG_AUTOSETCLICK)
	{
		self.click_pos = self.pos;
		self.click_size = self.size;
	}
	if(self.flag & FLAG_AUTOSETCLIP)
	{
		self.clip_pos = self.pos;
		self.clip_size = self.size;
	}
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
		menu_loopprev();
	} else if(keynr == K_RIGHTARROW || keynr == K_DOWNARROW)
	{
		// move to the  next element
		menu_loopnext();
	} else if(keynr == K_ENTER || keynr == K_MOUSE1)
	{
		if(self._action)
			self._action();
		// move to the child menu
		menu_selectdown();
	}
};

// a rect is described by the top-left point and its size
float(vector point, vector r_pos, vector r_size) inrect =
{
	if(point_x < r_pos_x)
		return false;
	if(point_y < r_pos_y)
		return false;
	if(point_x > (r_pos_x + r_size_x))
		return false;
	if(point_y > (r_pos_y + r_size_y))
		return false;
	return true;
};

vector(vector r_pos, vector r_size, vector c_pos, vector c_size) cliprectpos =
{
	vector v;

	// clip r_pos only
	v_x = max(c_pos_x, r_pos_x);
	v_y = max(c_pos_y, r_pos_y);

	return v;
};

vector(vector r_pos, vector r_size, vector c_pos, vector c_size) cliprectsize =
{
	vector v;
	// safe version
	//r_size_x = bound(c_pos_x, r_pos_x + r_size_x, c_pos_x + c_size_x) - bound(c_pos_x, r_pos_x, c_pos_x + c_size_x);
	//r_size_y = bound(c_pos_y, r_pos_y + r_size_y, c_pos_y + c_size_y) - bound(c_pos_y, r_pos_y, c_pos_y + c_size_y);
	v_x = min(c_pos_x + c_size_x, r_pos_x + r_size_x) - max(c_pos_x, r_pos_x);
	v_y = min(c_pos_y + c_size_y, r_pos_y + r_size_y) - max(c_pos_y, r_pos_y);

	if(v_x <= 0 || v_y <= 0)
		v = '0 0 0';

	return v;
}

void(void(void) initevent, void(float key, float ascii) keyevent, void(void) drawevent, void(void) mouse_enterevent, void(void) mouse_leaveevent, void(void) actionevent, void(void) refreshevent)
	item_init =
{
	self._init 	= initevent;
	self._key 	= keyevent;
	self._draw 	= drawevent;
	self._mouse_enter = mouse_enterevent;
	self._mouse_leave = mouse_leaveevent;
	self._action = actionevent;
	self._refresh = refreshevent;
};

float(float tfactor) getflicker =
{
	// TODO: use tfactor to vary the result
	return (sin(tfactor * time) + 1)/2;
};
