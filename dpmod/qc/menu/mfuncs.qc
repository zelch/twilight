///////////////////////////////////////////////
// Functions Source File
///////////////////////
// This file belongs to dpmod/darkplaces
// AK contains all menu controlling stuff (sub-menus)
////////////////////////////////

void(float keynr, float ascii) Default_KeyEvent =
{
	if(keynr == K_ESCAPE)
	{
		// move up to the parent
	} else if(keynr == K_LEFTARROW || keynr == K_UPARROW)
	{
		// move to the previous element		
	} else if(keynr == K_RIGHTARROW || keynr == K_DOWNARROW)
	{
		// move to the  next element
	} else if(keynr == K_ENTER)
	{
		// move to the child menu or perform an action
	}
};
	
