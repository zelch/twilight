//////////////////////////////////////////////////////////
// sys globals

entity self;

/////////////////////////////////////////////////////////
void		end_sys_globals;
/////////////////////////////////////////////////////////
// sys fields

.string classname;

/////////////////////////////////////////////////////////
void		end_sys_fields;
/////////////////////////////////////////////////////////
// sys functions

void() m_init;
void(float keynr) m_keydown;
void() m_draw;
void() m_toggle;
void() m_shutdown;

/////////////////////////////////////////////////////////
// sys constants
///////////////////////////
// key constants

//
// these are the key numbers that should be passed to Key_Event
//
float K_TAB		=	9;
float K_ENTER		=	13;
float K_ESCAPE		=	27;
float K_SPACE		=	32;

// normal keys should be passed as lowercased ascii

float K_BACKSPACE	=	127;
float K_UPARROW		=	128;
float K_DOWNARROW	=	129;
float K_LEFTARROW	=	130;
float K_RIGHTARROW	=	131;

float K_ALT		=	132;
float K_CTRL		=	133;
float K_SHIFT		=	134;
float K_F1		=	135;
float K_F2		=	136;
float K_F3		=	137;
float K_F4		=	138;
float K_F5		=	139;
float K_F6		=	140;
float K_F7		=	141;
float K_F8		=	142;
float K_F9		=	143;
float K_F10		=	144;
float K_F11		=	145;
float K_F12		=	146;
float K_INS		=	147;
float K_DEL		=	148;
float K_PGDN		=	149;
float K_PGUP		=	150;
float K_HOME		=	151;
float K_END		=	152;

float K_KP_HOME		=	160;
float K_KP_UPARROW	=	161;
float K_KP_PGUP		=	162;
float K_KP_LEFTARROW	=	163;
float K_KP_5		=	164;
float K_KP_RIGHTARROW	=	165;
float K_KP_END		=	166;
float K_KP_DOWNARROW	=	167;
float K_KP_PGDN		=	168;
float K_KP_ENTER	=	169;
float K_KP_INS   	=	170;
float K_KP_DEL		=	171;
float K_KP_SLASH	=	172;
float K_KP_MINUS	=	173;
float K_KP_PLUS		=	174;

float K_PAUSE		=	255;

//
// joystick buttons
//
float K_JOY1		=	203;
float K_JOY2		=	204;
float K_JOY3		=	205;
float K_JOY4		=	206;

//
// aux keys are for multi-buttoned joysticks to generate so they can use
// the normal binding process
//
float K_AUX1		=	207;
float K_AUX2		=	208;
float K_AUX3		=	209;
float K_AUX4		=	210;
float K_AUX5		=	211;
float K_AUX6		=	212;
float K_AUX7		=	213;
float K_AUX8		=	214;
float K_AUX9		=	215;
float K_AUX10		=	216;
float K_AUX11		=	217;
float K_AUX12		=	218;
float K_AUX13		=	219;
float K_AUX14		=	220;
float K_AUX15		=	221;
float K_AUX16		=	222;
float K_AUX17		=	223;
float K_AUX18		=	224;
float K_AUX19		=	225;
float K_AUX20		=	226;
float K_AUX21		=	227;
float K_AUX22		=	228;
float K_AUX23		=	229;
float K_AUX24		=	230;
float K_AUX25		=	231;
float K_AUX26		=	232;
float K_AUX27		=	233;
float K_AUX28		=	234;
float K_AUX29		=	235;
float K_AUX30		=	236;
float K_AUX31		=	237;
float K_AUX32		=	238;

float K_MWHEELDOWN	=	239;
float K_MWHEELUP	=	240;

//
// mouse buttons generate virtual keys
//
float K_MOUSE1		=	241;
float K_MOUSE2		=	242;
float K_MOUSE3		=	243;
// LordHavoc: thanks to backslash for this MOUSE4 and MOUSE5 code,
// LordHavoc: however I renumbered it differently and added MOUSE6 through MOUSE10
/* backslash :: imouse explorer buttons */
float K_MOUSE4		=	244;
float K_MOUSE5		=	245;
/* backslash :: renumber everything that follows so that the mouse4/5 buttons can be squeezed in */
// LordHavoc: added these for completeness
float K_MOUSE6		=	246;
float K_MOUSE7		=	247;
float K_MOUSE8		=	248;
float K_MOUSE9		=	249;
float K_MOUSE10		=	250;

///////////////////////////
// key dest constants

float KEY_GAME 		=	0;
float KEY_MENU		=	2;
float KEY_UNKNOWN	= 	3;
