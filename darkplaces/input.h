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
// input.h -- external (non-keyboard) input devices

#ifndef INPUT_H
#define INPUT_H

extern cvar_t in_pitch_min;
extern cvar_t in_pitch_max;

extern qboolean in_client_mouse;
extern float in_mouse_x, in_mouse_y;

//enum {input_game,input_message,input_menu} input_dest;

void IN_Commands (void);
// oportunity for devices to stick commands on the script buffer

// AK added to allow mouse movement for the menu
void IN_ProcessMove(void);

void IN_Move (void);
// add additional movement on top of the keyboard move cmd

void IN_PreMove(void);
void IN_PostMove(void);

void IN_Mouse(float mx, float my);

void IN_ClearStates (void);
// restores all button and position states to defaults

#endif

