///////////////////////////////////////////////
// Controls/Item Source File
///////////////////////
// This file belongs to dpmod/darkplaces
// AK contains all item specific stuff
////////////////////////////////////////////////

////////////////
// ITEM_WINDOW
//

void(void) ITEM_WINDOW =
{
	self.flag = self.flag | FLAG_NOSELECT | FLAG_DRAWONLY;

	item_init(
		defct_init,
		defct_key,
		defct_draw,
		defct_mouse_enter,
		defct_mouse_leave,
		defct_action,
		defct_refresh);
};

//////////////////
// ITEM_REFERENCE
///

void(void) ITEM_REFERENCE_INIT =
{
	self.child = menu_getitem(self.link);
	if(self.child == null_entity)
	{
		print(self.name, " removed, cause link ", self.link, " not found\n");
		remove(self);
		return;
	}

	self._init = defct_init;
};

void(void) ITEM_REFERENCE =
{
	self.flag = self.flag | FLAG_NOSELECT;

	if(self.link == "")
	{
		remove(self);
		return;
	}

	item_init(
		ITEM_REFERENCE_INIT,
		defct_key,
		defct_draw,
		defct_mouse_enter,
		defct_mouse_leave,
		defct_action,
		defct_refresh);
};

////////////////
// ITEM_CUSTOM
////

void(void) ITEM_CUSTOM =
{
	item_init(defct_init, defct_key, defct_draw, defct_mouse_enter, defct_mouse_leave, defct_action, defct_refresh);
};

/////////////////
// ITEM_PICTURE
///

// ITEM_PICTURE has a special draw function
void(void) ITEM_PICTURE_DRAW =
{
	menu_drawpic(self.pos, self.picture, self.size, self.color, self.alpha, self.drawflag);

	ctcall_draw();
};

void(void) ITEM_PICTURE =
{
	if(self.picture == "")
		// a picture has to have a picture
		remove(self);

	// load the picture if it isnt loaded already
	gfx_loadpic(self.picture, MENU_ENFORCELOADING);

	// if flag wasnt set yet, then set it to FLAG_DRAWONLY
	if(self.flag == 0)
		self.flag = FLAG_DRAWONLY;

	if(self.color == '0 0 0')
		self.color = ITEM_PICTURE_DEFAULT_COLOR;
	if(self.alpha == 0)
		self.alpha = ITEM_PICTURE_DEFAULT_ALPHA;

	item_init(
		defct_init,
		defct_key,
		ITEM_PICTURE_DRAW,
		defct_mouse_enter,
		defct_mouse_leave,
		defct_action,
		defct_refresh);
};

/////////////
// ITEM_TEXT
///

void(void) ITEM_TEXT_REFRESH =
{
	// first do own refresh, *then* call the default refresh !
	if(self.size == '0 0 0')
	{
		if(self.font_size == '0 0 0')
			self.font_size = ITEM_TEXT_DEFAULT_FONT_SIZE;

		self.size_x = self.font_size_x * strlen(self.text);
		self.size_y = self.font_size_y;
	} else if(self.font_size == '0 0 0')
	{
			self.font_size_x = self.size_x / strlen(self.text);
			self.font_size_y = self.size_y;
	}

	def_refresh();
	ctcall_refresh();
};

void(void) ITEM_TEXT_DRAW =
{
	if(self.text)
	{
		// align to the rect pos - (pos + size)
		vector alignpos;
		// now check the alignement
		if(self.alignment == TEXT_ALIGN_CENTER)
			alignpos_x = self.pos_x + (self.size_x - strlen(self.text) * self.font_size_x) / 2;
		else if(self.alignment == TEXT_ALIGN_RIGHT)
			alignpos_x = self.pos_x + self.size_x - strlen(self.text) * self.font_size_x;
		else
			alignpos_x = self.pos_x;
		alignpos_y = self.pos_y;

		menu_drawstring(alignpos, self.text, self.font_size, self.color, self.alpha, self.drawflag);
	}
	ctcall_draw();
};

void(void) ITEM_TEXT =
{
	if(self.flag == 0)
		self.flag = FLAG_DRAWONLY;

	if(self.color == '0 0 0')
		self.color = ITEM_TEXT_DEFAULT_COLOR;
	if(self.alpha == 0)
		self.alpha = ITEM_TEXT_DEFAULT_ALPHA;

	ITEM_TEXT_REFRESH();
	if(self.alignment & TEXT_ALIGN_CENTERPOS)
	{
		self.pos_x = self.pos_x - self.size_x / 2;
	}

	item_init(
		defct_init,
		defct_key,
		ITEM_TEXT_DRAW,
		defct_mouse_enter,
		defct_mouse_leave,
		defct_action,
		ITEM_TEXT_REFRESH);
};

/////////////////
// ITEM_RECTANLE
///

void(void) ITEM_RECTANGLE_DRAW =
{
	menu_fillarea(self.pos, self.size, self.color, self.alpha, self.drawflag);
};

void(void) ITEM_RECTANGLE =
{
	if(self.flag == 0)
		self.flag = FLAG_DRAWONLY;

	item_init(
		defct_init,
		defct_key,
		ITEM_RECTANGLE_DRAW,
		defct_mouse_enter,
		defct_mouse_leave,
		defct_action,
		defct_refresh);
};

////////////////
// ITEM_BUTTON
///

void(void) ITEM_BUTTON_DRAW =
{
	if(self._button_state == BUTTON_NORMAL)
		menu_drawpic(self.pos, self.picture, self.size, self.color, self.alpha, self.drawflag);
	else if(self._button_state == BUTTON_SELECTED)
		menu_drawpic(self.pos, self.picture_selected, self.size, self.color_selected, self.alpha_selected, self.drawflag_selected);
	else
		menu_drawpic(self.pos, self.picture_pressed, self.size, self.color_pressed, self.alpha_pressed, self.drawflag_pressed);

	ctcall_draw();
};

void(void) ITEM_BUTTON_REFRESH =
{
	if(menu_selected == self && self._button_state == BUTTON_NORMAL)
	{
		self._button_state = BUTTON_SELECTED;
		if(self.sound_selected)
			snd_play(self.sound_selected);
	}
	else if((self.hold_pressed + self._press_time < time && self._button_state == BUTTON_PRESSED) || (menu_selected != self && self._button_state == BUTTON_SELECTED))
	{
		self._button_state = BUTTON_NORMAL;
	}

	def_refresh();
	ctcall_refresh();
};

void(float keynr, float ascii) ITEM_BUTTON_KEY =
{
	if(ctcall_key(keynr, ascii))
		return;

	if(keynr == K_ENTER || keynr == K_MOUSE1)
	{
		self._press_time = time;
		self._button_state = BUTTON_PRESSED;
		if(self.sound_pressed)
			snd_play(self.sound_pressed);

		ctcall_action();
	} else
		def_keyevent(keynr, ascii);
};

void(void) ITEM_BUTTON_INIT =
{
	self._button_state = BUTTON_NORMAL;

	ctcall_init();
};

void(void) ITEM_BUTTON =
{
	if(self.picture == "" || self.picture_selected == "" || self.picture_pressed == "")
		// a picture has to have a picture
		remove(self);

	// load the picture if it isnt loaded already
	gfx_loadpic(self.picture, MENU_ENFORCELOADING);

	if(self.sound_selected)
		snd_loadsound(self.sound_selected, SOUND_ENFORCELOADING);

	if(self.sound_pressed)
		snd_loadsound(self.sound_pressed, SOUND_ENFORCELOADING);

	// if flag wasnt set yet, then set it to FLAG_DRAWONLY
	if(self.flag == 0)
		self.flag = FLAG_AUTOSETCLICK;

	if(self.color == '0 0 0')
		self.color = ITEM_BUTTON_DEFAULT_COLOR;
	if(self.alpha == 0)
		self.alpha = ITEM_BUTTON_DEFAULT_ALPHA;
	if(self.color_selected == '0 0 0')
		self.color_selected = ITEM_BUTTON_DEFAULT_COLOR_SELECTED;
	if(self.alpha_selected == 0)
		self.alpha_selected = ITEM_BUTTON_DEFAULT_ALPHA_SELECTED;
	if(self.color_pressed == '0 0 0')
		self.color_pressed = ITEM_BUTTON_DEFAULT_COLOR_PRESSED;
	if(self.alpha_pressed == 0)
		self.alpha_pressed = ITEM_BUTTON_DEFAULT_ALPHA_PRESSED;

	if(self.hold_pressed == 0)
		self.hold_pressed = ITEM_BUTTON_DEFAULT_HOLD_PRESSED;

	item_init(
		ITEM_BUTTON_INIT,
		ITEM_BUTTON_KEY,
		ITEM_BUTTON_DRAW,
		defct_mouse_enter,
		defct_mouse_leave,
		defct_action,
		ITEM_BUTTON_REFRESH);
};

////////////////////
// ITEM_TEXTBUTTON
///

void(void) ITEM_TEXTBUTTON_REFRESH =
{
	// first do own refresh, *then* call the default refresh !
	if(self.size == '0 0 0')
	{
		if(self.font_size == '0 0 0')
			self.font_size = ITEM_TEXT_DEFAULT_FONT_SIZE;

		self.size_x = self.font_size_x * strlen(self.text);
		self.size_y = self.font_size_y;
	} else if(self.font_size == '0 0 0')
	{
			self.font_size_x = self.size_x / strlen(self.text);
			self.font_size_y = self.size_y;
	}

	if((self.hold_pressed + self._press_time < time && self._button_state == BUTTON_PRESSED) || (menu_selected != self && self._button_state == BUTTON_SELECTED))
	{
		self._button_state = BUTTON_NORMAL;
	}
	if(menu_selected == self && self._button_state == BUTTON_NORMAL)
	{
		self._button_state = BUTTON_SELECTED;
		if(self.sound_selected)
			snd_play(self.sound_selected);
	}

	def_refresh();
	ctcall_refresh();
};

void(void) ITEM_TEXTBUTTON_DRAW =
{
	if(self.text == "")
		return;

	// align to the rect pos - (pos + size)
	vector alignpos;
	// now check the alignement
	if(self.alignment == TEXT_ALIGN_CENTER)
		alignpos_x = self.pos_x + (self.size_x - strlen(self.text) * self.font_size_x) / 2;
	else if(self.alignment == TEXT_ALIGN_RIGHT)
		alignpos_x = self.pos_x + self.size_x - strlen(self.text) * self.font_size_x;
	else
		alignpos_x = self.pos_x;
		alignpos_y = self.pos_y;

	if(self.style == TEXTBUTTON_STYLE_OUTLINE && self._button_state != BUTTON_NORMAL)
	{
		vector p,s;
		// left
		p_x = self.pos_x;
		p_y = self.pos_y;
		s_x = TEXTBUTTON_OUTLINE_WIDTH;
		s_y = self.size_y;
		if(self._button_state == BUTTON_PRESSED)
		{
			menu_fillarea(p, s, self.color_pressed, self.alpha_pressed, self.drawflag_pressed);
		}
		else if(self._button_state == BUTTON_SELECTED)
		{
			menu_fillarea(p, s, self.color_selected, self.alpha_selected, self.drawflag_selected);
		}
		// right
		p_x = self.pos_x + self.size_x - TEXTBUTTON_OUTLINE_WIDTH;
		p_y = self.pos_y;
		s_x = TEXTBUTTON_OUTLINE_WIDTH;
		s_y = self.size_y;
		if(self._button_state == BUTTON_PRESSED)
		{
			menu_fillarea(p, s, self.color_pressed, self.alpha_pressed, self.drawflag_pressed);
		}
		else if(self._button_state == BUTTON_SELECTED)
		{
			menu_fillarea(p, s, self.color_selected, self.alpha_selected, self.drawflag_selected);
		}
		// top
		p_x = self.pos_x;
		p_y = self.pos_y;
		s_y = TEXTBUTTON_OUTLINE_WIDTH;
		s_x = self.size_x;
		if(self._button_state == BUTTON_PRESSED)
		{
			menu_fillarea(p, s, self.color_pressed, self.alpha_pressed, self.drawflag_pressed);
		}
		else if(self._button_state == BUTTON_SELECTED)
		{
			menu_fillarea(p, s, self.color_selected, self.alpha_selected, self.drawflag_selected);
		}
		// bottom
		p_x = self.pos_x;
		p_y = self.pos_y + self.size_y - TEXTBUTTON_OUTLINE_WIDTH;
		s_y = TEXTBUTTON_OUTLINE_WIDTH;
		s_x = self.size_x;
		if(self._button_state == BUTTON_PRESSED)
		{
			menu_fillarea(p, s, self.color_pressed, self.alpha_pressed, self.drawflag_pressed);
		}
		else if(self._button_state == BUTTON_SELECTED)
		{
			menu_fillarea(p, s, self.color_selected, self.alpha_selected, self.drawflag_selected);
		}
	} else	if(self.style == TEXTBUTTON_STYLE_BOX)
	{
		if(self._button_state == BUTTON_PRESSED)
		{
			menu_fillarea(alignpos, self.size, self.color_pressed, self.alpha_pressed, self.drawflag_pressed);
		}
		else if(self._button_state == BUTTON_SELECTED)
		{
			menu_fillarea(alignpos, self.size, self.color_selected, self.alpha_selected, self.drawflag_selected);
		}
	}

	if(self._button_state == BUTTON_NORMAL || self.style == TEXTBUTTON_STYLE_BOX || self.style == TEXTBUTTON_STYLE_OUTLINE)
		menu_drawstring(alignpos, self.text, self.font_size, self.color, self.alpha, self.drawflag);

	if(self.style == TEXTBUTTON_STYLE_TEXT)
	{
		if(self._button_state == BUTTON_PRESSED)
		{
			menu_drawstring(alignpos, self.text, self.font_size, self.color_pressed, self.alpha_pressed, self.drawflag_pressed);
		}
		else if(self._button_state == BUTTON_SELECTED)
		{
			menu_drawstring(alignpos, self.text, self.font_size, self.color_selected, self.alpha_selected, self.drawflag_selected);
		}
	} else

	ctcall_draw();
};

void(float keynr, float ascii) ITEM_TEXTBUTTON_KEY =
{
	if(ctcall_key(keynr, ascii))
		return;

	if(keynr == K_ENTER || keynr == K_MOUSE1)
	{
		self._press_time = time;
		self._button_state = BUTTON_PRESSED;
		if(self.sound_pressed)
			snd_play(self.sound_pressed);

		ctcall_action();
	} else
		def_keyevent(keynr, ascii);
};

void(void) ITEM_TEXTBUTTON_INIT =
{
	self._button_state = BUTTON_NORMAL;

	ctcall_init();
};

void(void) ITEM_TEXTBUTTON =
{
	if(self.flag == 0)
		self.flag = FLAG_AUTOSETCLICK;

	if(self.color == '0 0 0')
		self.color = ITEM_TEXTBUTTON_DEFAULT_COLOR;
	if(self.alpha == 0)
		self.alpha = ITEM_TEXTBUTTON_DEFAULT_ALPHA;
	if(self.color_selected == '0 0 0')
		self.color_selected = ITEM_TEXTBUTTON_DEFAULT_COLOR_SELECTED;
	if(self.alpha_selected == 0)
		self.alpha_selected = ITEM_TEXTBUTTON_DEFAULT_ALPHA_SELECTED;
	if(self.color_pressed == '0 0 0')
		self.color_pressed = ITEM_TEXTBUTTON_DEFAULT_COLOR_PRESSED;
	if(self.alpha_pressed == 0)
		self.alpha_pressed = ITEM_TEXTBUTTON_DEFAULT_ALPHA_PRESSED;

	if(self.hold_pressed == 0)
		self.hold_pressed = ITEM_TEXTBUTTON_DEFAULT_HOLD_PRESSED;

	if(self.sound_selected)
		snd_loadsound(self.sound_selected, SOUND_ENFORCELOADING);

	if(self.sound_pressed)
		snd_loadsound(self.sound_pressed, SOUND_ENFORCELOADING);

	ITEM_TEXTBUTTON_REFRESH();
	if(self.alignment & TEXT_ALIGN_CENTERPOS)
	{
		self.pos_x = self.pos_x - self.size_x / 2;
	}

	item_init(
		ITEM_TEXTBUTTON_INIT,
		ITEM_TEXTBUTTON_KEY,
		ITEM_TEXTBUTTON_DRAW,
		defct_mouse_enter,
		defct_mouse_leave,
		defct_action,
		ITEM_TEXTBUTTON_REFRESH);
};


