/*
	$RCSfile$

    Copyright (C) 2001  Zephaniah E. Hull.

	This program is free software; you can redistribute it and/or
	modify it under the terms of the GNU General Public License
	as published by the Free Software Foundation; either version 2
	of the License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  

	See the GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program; if not, write to:
	
		Free Software Foundation, Inc.
		59 Temple Place - Suite 330
		Boston, MA  02111-1307, USA

	$Id$
*/

#ifndef __TGL_funcs_h
#define __TGL_funcs_h

#include "qtypes.h"
#include "TGL_types.h"
#include "TGL_defines.h"

#define TWIGL_NEED(ret, name, args)	extern ret (APIENTRY * q##name) args
#define TWIGL_EXT_WANT(ret, name, args)	extern ret (APIENTRY * q##name) args
#include "TGL_funcs_list.h"
#undef TWIGL_EXT_WANT
#undef TWIGL_NEED

qboolean GLF_Init (void);

#endif // __TGL_funcs_h

