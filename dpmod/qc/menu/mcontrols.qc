///////////////////////////////////////////////
// Controls/Item Source File
///////////////////////
// This file belongs to dpmod/darkplaces
// AK contains all item specific stuff
////////////////////////////////

////////////////
// ITEM_MENU 
//

void(void) ITEM_MENU =
{
	self._init = defct_init;
	self._draw = defct_draw;
	self._key  = defct_key;
	
	self._mouse_enter = defct_mouse_enter;
	self._mouse_leave = defct_mouse_leave;
	
	self._action = defct_action;
};

////////////////
// ITEM_CUSTOM
////

void(void) ITEM_CUSTOM =
{
	self._init = defct_init;
	self._draw = defct_draw;
	self._key  = defct_key;
	
	self._mouse_enter = defct_mouse_enter;
	self._mouse_leave = defct_mouse_leave;
	
	self._action = defct_action;
};
