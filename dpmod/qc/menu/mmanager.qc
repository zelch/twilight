///////////////////////////////////////////////
// Menu Manager Source File
///////////////////////
// This file belongs to dpmod/darkplaces
// AK contains the manager code
////////////////////////////////

void(void) menu_init =
{
	// load the menu files
	float count, i;
	
	count = tokenize(MENU_FILENAME_LIST);
	
	for(i = 0; i < count; i = i + 1)
	{
		menu_loadmenu(argv(i));
		dprint("Menu file ", argv(i), "loaded !\n");
	}
	
	menu_linkmenus();	
};

void(string file) menu_loadmenu =
{
	loadfromfile(file);
};

entity(entity start, .entity find1, entity match, .float find2, float match2) findef =
{
	while((start = findentity(start,find1,match))!=null_entity)
		if(start.find2 == match2)
			break;
	return start;
};

void(void) menu_linkmenus =
{
	// first verify that MENU_NORMAL_NAME and MENU_INGAME_NAME exist
	// if not add the default strings
	entity ent;
	float x;
	
	ent = findstring(null_entity,name, MENU_NORMAL_NAME);
	if(ent == null_entity)
		loadfromdata(MENU_NORMAL_DEFAULT);
	
	// verify again if MENI_INGAME_NAME is there now
	ent = findstring(null_entity,name, MENU_NORMAL_NAME);
	if(ent == null_entity)
		error("Bad MENU_NORMAL_DEFAULT !\n");
	
	ent = findstring(null_entity,name, MENU_INGAME_NAME);
	if(ent == null_entity)
		loadfromdata(MENU_INGAME_DEFAULT);
	
	// verify again if MENI_INGAME_NAME is there now
	ent = findstring(null_entity,name, MENU_INGAME_NAME);
	if(ent == null_entity)
		error("Bad MENU_INGAME_DEFAULT !\n");
	
	// now we have to :
	// set the parent field with parent_name
	// set the next and prev fields
	// set the child field
	self = null_entity;
	while((self = nextent(self)) != null_entity)
	{
		if(self.name == "")
		{
			objerror("Name is missing !\n");
			continue;
		}
		
		// find parent 
		// if parent_name is "" do nothing else set parent
		if(self.parent_name != "")
		{
			ent = findstring(null_entity, name, self.parent_name);
			
			if(ent == null_entity)
			{
				objerror("Item ", self.parent_name, " not found !\n");
				continue;
			}
			
			self.parent = ent;
		}
	}
	
	// now auto-set all ents with orderpos 0
	ent = null_entity;
	self = null_entity;
	while((self = findfloat(self,orderpos, 0)) != null_entity)
	{
		// now go through all orderpos' beginning from 1
		entity ent2;
		ent2 = null_entity;
		self.orderpos = 1;
		while((ent = findef(ent, parent, self.parent, orderpos, self.orderpos)) != null_entity)
			self.orderpos = self.orderpos + 1;
	}
	
	self = null_entity;
	while((self = nextent(self)) != null_entity)	
	{
		// find first child
		// orderpos starts with 1
		ent = null_entity;
		ent = findef(null_entity, parent, self, orderpos, 1);
	
		if(ent == null_entity)
			if(findentity(ent, parent, self) != null_entity)
				objerror("Orderpos 1 is missing in the child list of ", self.parent_name, " !\n");
				continue;
				
		if(ent != null_entity)
			self.child = ent;
		//else doesnt have any chilren
				
		// add to next, previous list
		// find orderpos - x (starting with x = 1)
		x = self.orderpos;
		
		while(x > 1)
		{
			x = x - 1;
			
			ent = findef(null_entity, parent, self.parent, orderpos, x);
			if(ent != null_entity)
			{
				self.prev = ent;
				ent.next = self;
				break;
			}
		}
	
		// find orderpos + x (starting with x = 1 until x == self.oderpos + 100)
		x = self.orderpos;
			
		while(x < self.orderpos + 100)
		{
			x = x + 1;
				
			ent = findef(null_entity, parent, self.parent, orderpos, x);
			if(ent != null_entity)
			{
				self.next = ent;
				ent.prev = self;
				break;
			}
		}
			
	}		
};

void(void) menu_toggle =
{
	// clear history
	// and reinit all menu items
	self = null_entity;
	while((self = nextent(self)) != null_entity)
	{
		if(self.parent_name == "")
			self.parent = null_entity;
		//else actually this shouldnt happen
		//	self.parent = findstring(null_entity, name, self.parent_name);
		else if(self.parent.name != self.parent_name)
			objerror("Parent (should be ", self.parent_name, ") of non-menu item ", self.name, " changed to ", self.parent.name, " !\n");
		
		if(self._init)
			self._init();
	}
		
	// choose which menu to display
	if(MENU_ALLOWINGAME && (gamestatus & GAME_CONNECTED))
		menu_activemenu = findstring(null_entity, name, MENU_INGAME_NAME);
	else
		menu_activemenu = findstring(null_entity, name, MENU_NORMAL_NAME);
	
	// set the selected item
	menu_selected = menu_activemenu.child;
};

void(entity par) menu_processmouse =
{
	// self is parent
	// loop through all childs 
	// and try to find an object whose click rect fits to the mouse coords
	entity ent;
	
	ent = par.child;
	if(ent == null_entity)
		return;
	
	do
	{
		// if not visible, continue to the next item
		if(!menu_isvisible(ent))
			continue;
		
		if(inrect(cursor, ent.click_pos, ent.click_size))
		{
			// call mouse_enter event ?
			if(!(ent.flags & _FLAG_MOUSEINAREA) && menu_hasevents(ent))
			{
				if(ent._mouse_enter)
				{
					self = ent;
					ent._mouse_enter();
				}
				
				ent.flags = ent.flags | _FLAG_MOUSEINAREA;
			}
			
			// select it ?
			if(menu_selectable(ent))
				menu_selected = ent;
		}
		else
		{
			// call mouse_leave event ?
			if((ent.flags & _FLAG_MOUSEINAREA) && menu_hasevents(ent))
			{
				if(ent._mouse_leave)
				{
					self = ent;
					ent._mouse_leave();
				}
				
				// this only works if _FLAG_MOUSEINAREA is set
				ent.flags = ent.flags - _FLAG_MOUSEINAREA;				
			}
		}

		// if ent has children recurse through them
		if(ent.child != null_entity)
			menu_processmouse(ent);
		
	} while((ent = ent.next) != null_entity);
	
};

void(void) menu_frame =
{
	// if mouse moved, process it
	if(cursor_rel != '0 0 0')
		menu_processmouse(menu_activemenu);
		
}

void(entity menu) menu_drawmenu =
{
	// loop through all children and draw them
	entity ent;
	vector old_c_pos, old_c_size, clipped_size, clipped_pos;
	
	// set the clipping area
	// is this necessary at all ?
	clipped_size = cliprectsize(gfx_conmentogfx(menu.clip_pos),menu.clip_size, menu_clip_pos, menu_clip_size);
	if(clipped_size != '0 0 0')
	{
		// do clip the clip area 
		// save the old 
		old_c_pos = menu_clip_pos;
		old_c_size = menu_clip_size;
		
		// clip the position
		menu_clip_pos = cliprectpos(gfx_conmentogfx(menu.clip_pos),menu.clip_size, menu_clip_pos, menu_clip_size);
		menu_clip_size = clipped_size;
		gfx_setcliparea(menu_clip_pos, menu_clip_size);	
	}

	ent = menu.child;
	do
	{
		// if it's not visible continue
		if(!menu_isvisible(ent))
			continue;
		
		menu_localorigin = menu_localorigin + ent.local_origin;
		
		if(ent._draw)
		{
			self = ent;
			ent._draw();
		}
		
		if(ent.child != null_entity)
			menu_drawmenu(ent);			
				
		menu_localorigin = menu_localorigin - ent.local_origin;
		
		// reset the clip area to the current menu's
		if(menu_clip_size != '0 0 0')
			menu_setcliparea(menu_clip_pos, menu_clip_size);
		
	} while((ent = ent.next) != null_entity);
	
	// restore the old menu_clip vars if necessary
	if(clipped_size != '0 0 0')
	{
		menu_clip_size = old_c_size;
		menu_clip_pos = old_c_pos;
	}
};

void(void) menu_draw =
{
	// if menu_activemenu is visible loop though it
	if(menu_isvisible(menu_activemenu))
	{
		menu_localorigin = menu_activemenu.local_origin;
		menu_drawmenu(menu_activemenu);
		menu_localorigin = '0 0 0';
		menu_clip_pos = '0 0 0';
		menu_clip_size = '0 0 0';
		menu_resetcliparea();
	}
}

float(entity e) menu_hasevents =
{
	return menu_isvisible(e) && !(e.flags & FLAG_DRAWONLY);
};

float(entity e) menu_isvisible =
{
	if(!(e.flags & FLAG_HIDDEN))
		return false;
	
	if(e.flags & FLAG_SERVERONLY && !(gamestatus & GAME_ISSERVER))
		return false;
	
	if(e.flags & FLAG_DEVELOPERONLY && !(gamestatus & GAME_DEVELOPER))
		return false;

	return true;
};

float(entity e) menu_selectable =
{
	return menu_hasevents(e) && !(e.flags & FLAG_NOSELECT);
};

void(void) menu_shutdown =
{
};

void(float keynr, float ascii) menu_keydown =
{
	// call current selected keydown function
	// if nothing is selected -> menu has no items -> call menu key
	if(menu_selected == null_entity)
	{
		// call menu keydown
		if(menu_activemenu._key)
		{
			self = menu_activemenu;
			menu_activemenu._key(keynr, ascii);
		}
	}
	else
	{
		if(menu_selected._key)
		{
			self = menu_selected;
			menu_selected._key(keynr, ascii);
		}
	}		
};

void(void) menu_selectprev =
{
	entity temp;
	
	temp = menu_selected;
	// loop backward through the list until one item is selectable
	while((temp = temp.prev) != null_entity)
		if(menu_selectable(temp))
			break;
	
	if(temp != null_entity)
		menu_selected = temp;
};

void(void) menu_selectnext =
{
	entity temp;
	
	temp = menu_selected;
	// loop forward through the list until one item is selectable
	while((temp = temp.next) != null_entity)
		if(menu_selectable(temp))
			break;
	
	if(temp != null_entity)
		menu_selected = temp;
};

void(void) menu_selectdown =
{
	// select the first child
	if(self.child != null_entity)
	{
		menu_selected = self.child;
		if(!menu_selectable(menu_selected))
			menu_selectnext();
	}
};

void(void) menu_selectup =
{
	entity ent;
	
	// select the parent
	if(self.parent != null_entity)
	{
		menu_selected = self.parent;
		if(!menu_selectable(menu_selected))
			menu_selectnext();
		
		// if we go to the menu history, then we have to choose another active menu
		if(self.parent == menu_activemenu)
		{
			// go through the parent of menu_selected until you found a menu
			ent = self.parent;
			while((ent = ent.parent) != null_entity)
				if(ent.classname == "ITEM_MENU")
					break;
			if(ent == null_entity)
				error("No menu found in history for ", self.name, " !\n");
			menu_activemenu = ent;
		}
	}
	else if(self.name == MENU_NORMAL_NAME || self.name == MENU_INGAME_NAME)
		m_toggle();
	else
		error("No parent found for ", self.name, " !\n");		
};

void(entity menu) menu_jumptomenu =
{
	// only jump to menus
	if(menu.classname != "ITEM_MENU")
		error("Cant jump to ", menu.name, " !\n");
	
	// set the history of the menu
	menu.parent = self;
	menu_activemenu = menu;
	
	// now set the selected to the first selectable child
	menu = self;
	self = menu_activemenu;
	menu_selectdown();
	self = menu;	 	
};
