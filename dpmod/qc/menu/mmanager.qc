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
	
	if(count == 0)
		return;
	
	for(i = 0; i < count; i = i + 1)
	{
		menu_loadmenu(argv(i));
		dprint("Menu file ", argv(i), "loaded !\n"),
	}
	
	menu_linkmenus();	
};

void(string file) menu_loadmenu =
{
	loadfromfile(file);
};

void(void) menu_linkmenus =
{
	// first verify that MENU_NORMAL_NAME and MENU_INGAME_NAME exist
	// if not add the default strings
	entity ent;
	
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
		if(self.name = "")
		{
			objerror("Name is missing !\n");
			continue;
		}
		
		// find parent 
		// if parent_name is "" do nothing
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
		self.orderpos = 1;
		while((ent = findfloat(null_entity, orderpos, self.orderpos)) == null_entity)
			self.orderpos = self.orderpos + 1;
	}
	
	self = null_entity;
	while((self = nextent(self)) != null_entity)	
		// find first child
		// orderpos starts with 1
		ent = null_entity;
		while((ent = findentity(ent, parent, self)) != null_entity)
			if(ent.orderpos == 1)
				break;
			
		if(ent == null_entity)
			while((ent = findentity(ent, parent, self)) != null_entity)
				break;
			
		if(ent != null_entity)
			self.child = ent;
		//else doesnt have any chilren
				
		// add to next, previous list
		ent = null_entity;
		while((ent = findfloat(ent, parent, self.parent)) != null_entity)
			
				
		
	}		
};
