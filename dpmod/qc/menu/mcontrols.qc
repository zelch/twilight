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
	/*self.child = self.child.child;
	if(self.child = null_entity)
	{
		print(self.name*/

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

	defct_draw();
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
	defct_draw();
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

