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
// vid.h -- video driver defs

#ifndef VID_H
#define VID_H

#define ENGINE_ICON ( (gamemode == GAME_NEXUIZ) ? nexuiz_xpm : darkplaces_xpm )

extern int cl_available;

#define MAX_TEXTUREUNITS 32

typedef enum renderpath_e
{
	RENDERPATH_GL32,
	RENDERPATH_GLES2
}
renderpath_t;

typedef struct viddef_support_s
{
	int glshaderversion; // this is at least 150 (GL 3.2)
	qboolean amd_texture_texture4;
	qboolean arb_draw_buffers;
	qboolean arb_occlusion_query;
	qboolean arb_query_buffer_object;
	qboolean arb_texture_compression;
	qboolean arb_texture_gather;
	qboolean ext_blend_minmax;
	qboolean ext_blend_subtract;
	qboolean ext_blend_func_separate;
	qboolean ext_packed_depth_stencil;
	qboolean ext_texture_compression_s3tc;
	qboolean ext_texture_filter_anisotropic;
	qboolean ext_texture_srgb;
	qboolean arb_texture_float;
	qboolean arb_half_float_pixel;
	qboolean arb_half_float_vertex;
	qboolean arb_multisample;
	qboolean arb_debug_output;
}
viddef_support_t;

typedef struct viddef_mode_s
{
	int width;
	int height;
	int bitsperpixel;
	qboolean fullscreen;
	float refreshrate;
	qboolean userefreshrate;
	qboolean stereobuffer;
	int samples;
}
viddef_mode_t;

typedef struct viddef_s
{
	// these are set by VID_Mode
	viddef_mode_t mode;
	// used in many locations in the renderer
	int width;
	int height;
	int bitsperpixel;
	qboolean fullscreen;
	float refreshrate;
	qboolean userefreshrate;
	qboolean stereobuffer;
	int samples;
	qboolean stencil;
	qboolean sRGB2D; // whether 2D rendering is sRGB corrected (based on sRGBcapable2D)
	qboolean sRGB3D; // whether 3D rendering is sRGB corrected (based on sRGBcapable3D)
	qboolean sRGBcapable2D; // whether 2D rendering can be sRGB corrected (renderpath)
	qboolean sRGBcapable3D; // whether 3D rendering can be sRGB corrected (renderpath)

	renderpath_t renderpath;
	qboolean allowalphatocoverage; // indicates the GL_AlphaToCoverage function works on this renderpath and framebuffer

	unsigned int maxtexturesize_2d;
	unsigned int maxtexturesize_3d;
	unsigned int maxtexturesize_cubemap;
	unsigned int max_anisotropy;
	unsigned int maxdrawbuffers;

	viddef_support_t support;

	int forcetextype; // always use GL_BGRA for D3D, always use GL_RGBA for GLES, etc
} viddef_t;

// global video state
extern viddef_t vid;
extern void (*vid_menudrawfn)(void);
extern void (*vid_menukeyfn)(int key);

#define MAXJOYAXIS 16
// if this is changed, the corresponding code in vid_shared.c must be updated
#define MAXJOYBUTTON 36
typedef struct vid_joystate_s
{
	float axis[MAXJOYAXIS]; // -1 to +1
	unsigned char button[MAXJOYBUTTON]; // 0 or 1
	qboolean is360; // indicates this joystick is a Microsoft Xbox 360 Controller For Windows
}
vid_joystate_t;

extern vid_joystate_t vid_joystate;

extern cvar_t joy_index;
extern cvar_t joy_enable;
extern cvar_t joy_detected;
extern cvar_t joy_active;

float VID_JoyState_GetAxis(const vid_joystate_t *joystate, int axis, float sensitivity, float deadzone);
void VID_ApplyJoyState(vid_joystate_t *joystate);
void VID_BuildJoyState(vid_joystate_t *joystate);
void VID_Shared_BuildJoyState_Begin(vid_joystate_t *joystate);
void VID_Shared_BuildJoyState_Finish(vid_joystate_t *joystate);
int VID_Shared_SetJoystick(int index);
qboolean VID_JoyBlockEmulatedKeys(int keycode);
void VID_EnableJoystick(qboolean enable);

extern qboolean vid_hidden;
extern qboolean vid_activewindow;
extern qboolean vid_supportrefreshrate;

extern cvar_t vid_fullscreen;
extern cvar_t vid_width;
extern cvar_t vid_height;
extern cvar_t vid_bitsperpixel;
extern cvar_t vid_samples;
extern cvar_t vid_refreshrate;
extern cvar_t vid_userefreshrate;
extern cvar_t vid_touchscreen_density;
extern cvar_t vid_touchscreen_xdpi;
extern cvar_t vid_touchscreen_ydpi;
extern cvar_t vid_vsync;
extern cvar_t vid_mouse;
extern cvar_t vid_grabkeyboard;
extern cvar_t vid_touchscreen;
extern cvar_t vid_touchscreen_showkeyboard;
extern cvar_t vid_touchscreen_supportshowkeyboard;
extern cvar_t vid_stick_mouse;
extern cvar_t vid_resizable;
extern cvar_t vid_desktopfullscreen;
extern cvar_t vid_minwidth;
extern cvar_t vid_minheight;
extern cvar_t vid_sRGB;
extern cvar_t vid_sRGB_fallback;

extern cvar_t gl_finish;

extern cvar_t v_gamma;
extern cvar_t v_contrast;
extern cvar_t v_brightness;
extern cvar_t v_color_enable;
extern cvar_t v_color_black_r;
extern cvar_t v_color_black_g;
extern cvar_t v_color_black_b;
extern cvar_t v_color_grey_r;
extern cvar_t v_color_grey_g;
extern cvar_t v_color_grey_b;
extern cvar_t v_color_white_r;
extern cvar_t v_color_white_g;
extern cvar_t v_color_white_b;

// brand of graphics chip
extern const char *gl_vendor;
// graphics chip model and other information
extern const char *gl_renderer;
// begins with 1.0.0, 1.1.0, 1.2.0, 1.2.1, 1.3.0, 1.3.1, or 1.4.0
extern const char *gl_version;
// extensions list, space separated
extern const char *gl_extensions;
// WGL, GLX, or AGL
extern const char *gl_platform;
// name of driver library (opengl32.dll, libGL.so.1, or whatever)
extern char gl_driver[256];

void *GL_GetProcAddress(const char *name);
qboolean GL_CheckExtension(const char *name, const char *disableparm, int silent);
qboolean GL_ExtensionSupported(const char *name);

void VID_Shared_Init(void);

void GL_Setup(void);

void VID_ClearExtensions(void);

void VID_Init (void);
// Called at startup

void VID_Shutdown (void);
// Called at shutdown

int VID_SetMode (int modenum);
// sets the mode; only used by the Quake engine for resetting to mode 0 (the
// base mode) on memory allocation failures

qboolean VID_InitMode(viddef_mode_t *mode);
// allocates and opens an appropriate OpenGL context (and its window)


// updates cachegamma variables and bumps vid_gammatables_serial if anything changed
// (ONLY to be called from VID_Finish!)
void VID_UpdateGamma(void);

qboolean VID_HasScreenKeyboardSupport(void);
void VID_ShowKeyboard(qboolean show);
qboolean VID_ShowingKeyboard(void);

void VID_SetMouse (qboolean fullscreengrab, qboolean relative, qboolean hidecursor);
void VID_Finish (void);

void VID_Restart_f(void);

void VID_Start(void);
void VID_Stop(void);

extern unsigned int vid_gammatables_serial; // so other subsystems can poll if gamma parameters have changed; this starts with 0 and gets increased by 1 each time the gamma parameters get changed and VID_BuildGammaTables should be called again
extern qboolean vid_gammatables_trivial; // this is set to true if all color control values are at default setting, and it therefore would make no sense to use the gamma table
void VID_BuildGammaTables(unsigned short *ramps, int rampsize); // builds the current gamma tables into an array (needs 3*rampsize items)
void VID_ApplyGammaToColor(const float *rgb, float *out); // applies current gamma settings to a color (0-1 range)

typedef struct
{
	int width, height, bpp, refreshrate;
	int pixelheight_num, pixelheight_denom;
}
vid_mode_t;
vid_mode_t *VID_GetDesktopMode(void);
size_t VID_ListModes(vid_mode_t *modes, size_t maxcount);
size_t VID_SortModes(vid_mode_t *modes, size_t count, qboolean usebpp, qboolean userefreshrate, qboolean useaspect);
void VID_Soft_SharedSetup(void);

#endif

