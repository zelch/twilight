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

#ifndef PROGS_H
#define PROGS_H

#include "pr_comp.h"			// defs shared with qcc
#include "progdefs.h"			// generated by program cdefs

typedef union eval_s
{
	string_t		string;
	float			_float;
	float			vector[3];
	func_t			function;
	int				ivector[3];
	int				_int;
	int				edict;
} eval_t;

typedef struct link_s
{
	int entitynumber;
	struct link_s	*prev, *next;
} link_t;

#define ENTITYGRIDAREAS 16

// the entire server entity structure
typedef struct edict_s
{
	// true if this edict is unused
	qboolean free;
	// physics grid areas this edict is linked into
	link_t areagrid[ENTITYGRIDAREAS];
	// since the areagrid can have multiple references to one entity,
	// we should avoid extensive checking on entities already encountered
	int areagridmarknumber;

	// old entity protocol, not used
#ifdef QUAKEENTITIES
	// baseline values
	entity_state_t baseline;
	// LordHavoc: previous frame
	entity_state_t deltabaseline;
#endif

	// LordHavoc: gross hack to make floating items still work
	int suspendedinairflag;
	// sv.time when the object was freed (to prevent early reuse which could
	// mess up client interpolation or obscure severe QuakeC bugs)
	float freetime;
	// used by PushMove to keep track of where objects were before they were
	// moved, in case they need to be moved back
	vec3_t moved_from;
	vec3_t moved_fromangles;
	// edict fields (stored in another array)
	entvars_t *v;
} edict_t;

// LordHavoc: in an effort to eliminate time wasted on GetEdictFieldValue...  see pr_edict.c for the functions which use these.
extern int eval_gravity;
extern int eval_button3;
extern int eval_button4;
extern int eval_button5;
extern int eval_button6;
extern int eval_button7;
extern int eval_button8;
extern int eval_glow_size;
extern int eval_glow_trail;
extern int eval_glow_color;
extern int eval_items2;
extern int eval_scale;
extern int eval_alpha;
extern int eval_renderamt; // HalfLife support
extern int eval_rendermode; // HalfLife support
extern int eval_fullbright;
extern int eval_ammo_shells1;
extern int eval_ammo_nails1;
extern int eval_ammo_lava_nails;
extern int eval_ammo_rockets1;
extern int eval_ammo_multi_rockets;
extern int eval_ammo_cells1;
extern int eval_ammo_plasma;
extern int eval_idealpitch;
extern int eval_pitch_speed;
extern int eval_viewmodelforclient;
extern int eval_nodrawtoclient;
extern int eval_exteriormodeltoclient;
extern int eval_drawonlytoclient;
extern int eval_ping;
extern int eval_movement;
extern int eval_pmodel;
extern int eval_punchvector;
extern int eval_viewzoom;

#define GETEDICTFIELDVALUE(ed, fieldoffset) (fieldoffset ? (eval_t *)((qbyte *)ed->v + fieldoffset) : NULL)


extern mfunction_t *SV_PlayerPhysicsQC;
extern mfunction_t *EndFrameQC;

//============================================================================

extern	dprograms_t		*progs;
extern	mfunction_t		*pr_functions;
extern	char			*pr_strings;
extern	ddef_t			*pr_globaldefs;
extern	ddef_t			*pr_fielddefs;
extern	dstatement_t	*pr_statements;
extern	globalvars_t	*pr_global_struct;
extern	float			*pr_globals;			// same as pr_global_struct

extern	int				pr_edict_size;	// in bytes
extern	int				pr_edictareasize; // LordHavoc: for bounds checking

//============================================================================

void PR_Init (void);

void PR_ExecuteProgram (func_t fnum, const char *errormessage);
void PR_LoadProgs (void);

void PR_Profile_f (void);

void PR_Crash (void);

edict_t *ED_Alloc (void);
void ED_Free (edict_t *ed);

char	*ED_NewString (const char *string);
// returns a copy of the string allocated from the server's string heap

void ED_Print (edict_t *ed);
void ED_Write (qfile_t *f, edict_t *ed);
const char *ED_ParseEdict (const char *data, edict_t *ent);

void ED_WriteGlobals (qfile_t *f);
void ED_ParseGlobals (const char *data);

void ED_LoadFromFile (const char *data);

edict_t *EDICT_NUM_ERROR(int n, char *filename, int fileline);
#define EDICT_NUM(n) (((n) >= 0 && (n) < sv.max_edicts) ? sv.edictstable[(n)] : EDICT_NUM_ERROR(n, __FILE__, __LINE__))

//int NUM_FOR_EDICT_ERROR(edict_t *e);
#define NUM_FOR_EDICT(e) ((edict_t *)(e) - sv.edicts)
//int NUM_FOR_EDICT(edict_t *e);

#define	NEXT_EDICT(e) ((e) + 1)

#define EDICT_TO_PROG(e) (NUM_FOR_EDICT(e))
//int EDICT_TO_PROG(edict_t *e);
#define PROG_TO_EDICT(n) (EDICT_NUM(n))
//edict_t *PROG_TO_EDICT(int n);

//============================================================================

#define	G_FLOAT(o) (pr_globals[o])
#define	G_INT(o) (*(int *)&pr_globals[o])
#define	G_EDICT(o) (PROG_TO_EDICT(*(int *)&pr_globals[o]))
#define G_EDICTNUM(o) NUM_FOR_EDICT(G_EDICT(o))
#define	G_VECTOR(o) (&pr_globals[o])
#define	G_STRING(o) (PR_GetString(*(string_t *)&pr_globals[o]))
//#define	G_FUNCTION(o) (*(func_t *)&pr_globals[o])

// FIXME: make these go away?
#define	E_FLOAT(e,o) (((float*)e->v)[o])
//#define	E_INT(e,o) (((int*)e->v)[o])
//#define	E_VECTOR(e,o) (&((float*)e->v)[o])
#define	E_STRING(e,o) (PR_GetString(*(string_t *)&((float*)e->v)[o]))

extern	int		type_size[8];

typedef void (*builtin_t) (void);
extern	builtin_t *pr_builtins;
extern int pr_numbuiltins;

extern int		pr_argc;

extern	int			pr_trace;
extern	mfunction_t	*pr_xfunction;
extern	int			pr_xstatement;

extern	unsigned short		pr_crc;

void PR_Execute_ProgsLoaded(void);

void ED_PrintEdicts (void);
void ED_PrintNum (int ent);

#define PR_GetString(num) (pr_strings + num)
#define PR_SetString(s) ((int) (s - pr_strings))

#endif

