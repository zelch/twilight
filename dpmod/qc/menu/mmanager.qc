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
		dprint(argv(i), " loaded !\n");
	}

	menu_linkmenus();
};

void(string file) menu_loadmenu =
{
	loadfromfile(file);
};

entity(entity start, .entity find1, entity match, .float find2, float match2) findef =
{
	while(1)
	{
		start = findentity(start, find1, match);
		if(start == null_entity)
			break;
		if(start.find2 == match2)
			break;
	}
	return start;
	/*while((start = findentity(start,find1,match))!=null_entity)
		if(start.find2 == match2)
			break;
	return start;*/
};

void(void) menu_linkmenus =
{
	// first verify that MENU_NORMAL_NAME and MENU_INGAME_NAME exist
	// if not add the default strings
	entity ent;
	float x, opos;

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
	self = null_entity;
	while((self = findfloat(self,orderpos, 0)) != null_entity)
	{
		if(self.parent_name == "")
			continue;

		// now go through all orderpos' beginning from 1
		opos = 1;
		while((ent = findef(null_entity, parent, self.parent, orderpos, opos)) != null_entity)
		{
			opos = opos + 1;
		}

		self.orderpos = opos;
	}

	self = null_entity;
	while((self = nextent(self)) != null_entity)
	{
		// find first child
		// orderpos starts with 1
		ent = findef(null_entity, parent, self, orderpos, 1);

		if(ent == null_entity)
		{
			if(findentity(ent, parent, self) != null_entity)
			{
				objerror("Order pos 1 is missing in the child list of ", self.name, " !\n");
				continue;
			}
			//else doesnt have any chilren
		}
		else
			self.child = ent;

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
	// only let the qc toggle the menu if we are ingame or a developer
	if(gamestatus & GAME_CONNECTED || gamestatus & GAME_DEVELOPER)
	{
		// then allow toggling
		m_toggle();
	}// else do nothing
};

void(void) menu_performreinit =
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

		if(menu_hasevents(self))
			if(self._init)
				self._init();
	}

	// choose which menu to display
	if(MENU_ALLOWINGAME && (gamestatus & GAME_CONNECTED))
		menu_activemenu = findstring(null_entity, name, MENU_INGAME_NAME);
	else
		menu_activemenu = findstring(null_entity, name, MENU_NORMAL_NAME);

	// set the selected item
	menu_selected = menu_activemenu;
	// find first child that can be selected
	menu_selectdown();
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

	menu_localorigin = menu_localorigin + par.origin;

	menu_cursor = gfx_congfxtomen(cursor);

	do
	{
		// if not visible, continue to the next item
		if(menu_isvisible(ent))
		{

			if(inrect(menu_cursor, ent.click_pos, ent.click_size))
			{
				// call mouse_enter event ?
				if(!(ent.flag & _FLAG_MOUSEINAREA) && menu_hasevents(ent))
				{
					if(ent._mouse_enter)
					{
						self = ent;
						ent._mouse_enter();
					}

					ent.flag = ent.flag | _FLAG_MOUSEINAREA;
				}

				// select it ?
				if(menu_selectable(ent))
					menu_selected = ent;
			}
			else
			{
				// call mouse_leave event ?
				if((ent.flag & _FLAG_MOUSEINAREA) && menu_hasevents(ent))
				{
					if(ent._mouse_leave)
					{
						self = ent;
						ent._mouse_leave();
					}

					// this only works if _FLAG_MOUSEINAREA is set
					ent.flag = ent.flag - _FLAG_MOUSEINAREA;
				}
			}

			// if ent has children recurse through them
			if(ent.child != null_entity)
			menu_processmouse(ent);
		}
	} while((ent = ent.next) != null_entity);

	menu_localorigin = menu_localorigin - par.origin;
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
		dprint("Setting clip area\n");
		// do clip the clip area
		// save the old
		old_c_pos = menu_clip_pos;
		old_c_size = menu_clip_size;

		// clip the position
		menu_clip_pos = cliprectpos(gfx_conmentogfx(menu.clip_pos),menu.clip_size, menu_clip_pos, menu_clip_size);
		menu_clip_size = clipped_size;
		gfx_setcliparea(menu_clip_pos, menu_clip_size);
	}

	menu_localorigin = menu_localorigin + menu.origin;

	ent = menu.child;
	do
	{
		// if it's not visible continue
		if(menu_isvisible(ent))
		{
			self = ent;
			if(ent._refresh)
				self._refresh();
			if(ent._draw)
				ent._draw();

			if(ent.child != null_entity)
				menu_drawmenu(ent);

				// reset the clip area to the current menu's
			if(menu_clip_size != '0 0 0')
				menu_setcliparea(menu_clip_pos, menu_clip_size);
		}
	} while((ent = ent.next) != null_entity);

	menu_localorigin = menu_localorigin - menu.origin;

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
		menu_drawmenu(menu_activemenu);
		menu_localorigin = '0 0 0';
		menu_clip_pos = '0 0 0';
		menu_clip_size = '0 0 0';
		menu_resetcliparea();
	}
}

float(entity e) menu_hasevents =
{
	if(e.flag & FLAG_DRAWONLY)
		return false;
	if(menu_isvisible(e))
		return true;
	return false;
};

float(entity e) menu_isvisible =
{
	if(e.flag & FLAG_HIDDEN)
		return false;

	if((e.flag & FLAG_SERVERONLY) && !(gamestatus & GAME_ISSERVER))
		return false;

	if((e.flag & FLAG_DEVELOPERONLY) && !(gamestatus & GAME_DEVELOPER))
		return false;

	return true;
};

float(entity e) menu_selectable =
{
	if(!menu_hasevents(e))
		return false;
	if(e.flag & FLAG_NOSELECT)
		return false;
	if(e.parent)
	{
		if(e.parent.flag & FLAG_NOCHILDSELECT)
			return false;
	}
	return true;
};

void(void) menu_shutdown =
{
};

void(float keynr, float ascii) menu_keydown =
{
	// before calling the current keydown functions, process the mouse again
	// so only the correct action is called
	// (except mouse wheel up and down)
	// if the mouse doesnt point to an item, there wont be a reaction on the clicking
	if(K_MOUSE1 <= keynr && keynr <= K_MOUSE10)
	{
		entity keysel;
		keysel = menu_selected;
		menu_selected = null_entity;
		menu_processmouse(menu_activemenu);
		if(menu_selected == null_entity)
		{
			// -> no reaction
			menu_selected = keysel;
			return;
		}
	}

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

void(void) menu_loopnext =
{
	entity old;
	old = menu_selected;

	menu_selectnext();
	if(menu_selected == old)
	{
		menu_selected = old.parent.child;
		if(!menu_selectable(menu_selected))
			menu_selectnext();
	}
};

void(void) menu_loopprev =
{
	entity old;
	old = menu_selected;
	menu_selectprev();
	if(menu_selected == old)
	{
		while(old.next != null_entity)
		{
			old = old.next;
		}

		menu_selected = old;
		if(!menu_selectable(old))
		{
			menu_selectprev();
		}
	}
}

void(void) menu_selectdown =
{
	// move down a level, then search for a selectable child
	// if none is found, then search for a sub-menu
	// if one is found, recurse through it, else keep the old menu_selected
	entity ent, old_selected;

	// if there is no child, return
	if(menu_selected.child == null_entity)
	{
		return;
	}

	// loop through the children till a selectable is found
	ent = menu_selected.child;
	do
	{
		//eprint(ent);
		if(menu_selectable(ent))
		{
			// found one -> break
			menu_selected = ent;
			return;
		}
	} while((ent = ent.next) != null_entity);

	// we found no selectable child, thus we loop through the children once again
	// and recurse
	ent = menu_selected.child;
	old_selected = menu_selected;
	do
	{
		if(ent.child != null_entity)
		{
			//eprint(ent);
			// give it a try
			menu_selected = ent;
			menu_selectdown();

			// found one ?
			if(menu_selected != ent)
			{
				return;
			}
		}
	} while((ent = ent.next) != null_entity);

	// we didnt find anything
	menu_selected = old_selected;
};

void(void) menu_selectup =
{
	entity ent;

	// move up till we find a selectable item
	// if we reach the 'main' menu without having found such an item
	// then toggle the menu (if possible) else select the first item available
	// if we find the active_menu on our way up, reset it, so everything gets displayed
	// correct
	if(menu_selected.parent == null_entity)
		return;

	ent = menu_selected;
	menu_selected = null_entity;

	while(ent.parent != null_entity)
	{
		ent = ent.parent;

		// reset the active menu if we reached it
		if(ent == menu_activemenu)
			menu_activemenu = null_entity;

		menu_selected = ent;
		if(menu_selectable(ent))
		{
			// we found our item !
			break;
		}
		// try selectnext
		menu_selectnext();
		if(menu_selected != ent)
		{
			// we found it !
			break;
		}
		// try selectprev
		menu_selectprev();
		if(menu_selected != ent)
		{
			// we found it !
			break;
		}
	}

	// evalute our results:
	// have we reached the 'main' menu ?
	if(ent.name == MENU_NORMAL_NAME || ent.name == MENU_INGAME_NAME)
	{
		menu_toggle();
		// set the active menu to the 'main' menu
		menu_activemenu = ent;
		// if the menu isnt toggled then select an item now !
		menu_selectdown();
		return;
	} // something must have been selected else -> error !
	else if(menu_selected == null_entity)
	{
		error("Couldnt select any item !\n");
	}

	// does the active menu needs to be reset ?
	if(menu_activemenu == null_entity)
	{
		menu_activemenu = ent;
	}
};

void(void) menu_reselect =
{
	menu_selected = menu_activemenu;
	menu_selectdown();
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
	menu_selected = menu_activemenu;
	menu_selectdown();
};

entity(string item_name) menu_getitem =
{
	return findstring(null_entity,  name, item_name);
};
