/*
Copyright (C) 1996-1997 Id Software, Inc.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  

See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*/

#include "quakedef.h"
#include "spritegn.h"

/*
=================
Mod_LoadSpriteModel
=================
*/
void Mod_LoadSpriteModel (model_t *mod, void *buffer)
{
	int version, maxwidth, maxheight;

	version = LittleLong (((dsprite_t *)buffer)->version);
	if (version != SPRITE_VERSION)
		Host_Error ("%s has wrong version number (%i should be %i)", mod->name, version, SPRITE_VERSION);

	maxwidth = LittleLong (((dsprite_t *)buffer)->width);
	maxheight = LittleLong (((dsprite_t *)buffer)->height);

	mod->mins[0] = mod->mins[1] = -maxwidth/2;
	mod->maxs[0] = mod->maxs[1] = maxwidth/2;
	mod->mins[2] = -maxheight/2;
	mod->maxs[2] = maxheight/2;
	
	mod->type = mod_sprite;
}
