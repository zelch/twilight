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
// world.c -- world query functions

#include "quakedef.h"

/*

entities never clip against themselves, or their owner

line of sight checks trace->inopen and trace->inwater, but bullets don't

*/

static void World_Physics_Init(void);
void World_Init(void)
{
	Collision_Init();
	World_Physics_Init();
}

static void World_Physics_Shutdown(void);
void World_Shutdown(void)
{
	World_Physics_Shutdown();
}

static void World_Physics_Start(world_t *world);
void World_Start(world_t *world)
{
	World_Physics_Start(world);
}

static void World_Physics_End(world_t *world);
void World_End(world_t *world)
{
	World_Physics_End(world);
}

//============================================================================

/// World_ClearLink is used for new headnodes
void World_ClearLink (link_t *l)
{
	l->entitynumber = 0;
	l->prev = l->next = l;
}

void World_RemoveLink (link_t *l)
{
	l->next->prev = l->prev;
	l->prev->next = l->next;
}

void World_InsertLinkBefore (link_t *l, link_t *before, int entitynumber)
{
	l->entitynumber = entitynumber;
	l->next = before;
	l->prev = before->prev;
	l->prev->next = l;
	l->next->prev = l;
}

/*
===============================================================================

ENTITY AREA CHECKING

===============================================================================
*/

void World_PrintAreaStats(world_t *world, const char *worldname)
{
	Con_Printf("%s areagrid check stats: %d calls %d nodes (%f per call) %d entities (%f per call)\n", worldname, world->areagrid_stats_calls, world->areagrid_stats_nodechecks, (double) world->areagrid_stats_nodechecks / (double) world->areagrid_stats_calls, world->areagrid_stats_entitychecks, (double) world->areagrid_stats_entitychecks / (double) world->areagrid_stats_calls);
	world->areagrid_stats_calls = 0;
	world->areagrid_stats_nodechecks = 0;
	world->areagrid_stats_entitychecks = 0;
}

/*
===============
World_SetSize

===============
*/
void World_SetSize(world_t *world, const char *filename, const vec3_t mins, const vec3_t maxs)
{
	int i;

	strlcpy(world->filename, filename, sizeof(world->filename));
	VectorCopy(mins, world->mins);
	VectorCopy(maxs, world->maxs);

	// the areagrid_marknumber is not allowed to be 0
	if (world->areagrid_marknumber < 1)
		world->areagrid_marknumber = 1;
	// choose either the world box size, or a larger box to ensure the grid isn't too fine
	world->areagrid_size[0] = max(world->areagrid_maxs[0] - world->areagrid_mins[0], AREA_GRID * sv_areagrid_mingridsize.value);
	world->areagrid_size[1] = max(world->areagrid_maxs[1] - world->areagrid_mins[1], AREA_GRID * sv_areagrid_mingridsize.value);
	world->areagrid_size[2] = max(world->areagrid_maxs[2] - world->areagrid_mins[2], AREA_GRID * sv_areagrid_mingridsize.value);
	// figure out the corners of such a box, centered at the center of the world box
	world->areagrid_mins[0] = (world->areagrid_mins[0] + world->areagrid_maxs[0] - world->areagrid_size[0]) * 0.5f;
	world->areagrid_mins[1] = (world->areagrid_mins[1] + world->areagrid_maxs[1] - world->areagrid_size[1]) * 0.5f;
	world->areagrid_mins[2] = (world->areagrid_mins[2] + world->areagrid_maxs[2] - world->areagrid_size[2]) * 0.5f;
	world->areagrid_maxs[0] = (world->areagrid_mins[0] + world->areagrid_maxs[0] + world->areagrid_size[0]) * 0.5f;
	world->areagrid_maxs[1] = (world->areagrid_mins[1] + world->areagrid_maxs[1] + world->areagrid_size[1]) * 0.5f;
	world->areagrid_maxs[2] = (world->areagrid_mins[2] + world->areagrid_maxs[2] + world->areagrid_size[2]) * 0.5f;
	// now calculate the actual useful info from that
	VectorNegate(world->areagrid_mins, world->areagrid_bias);
	world->areagrid_scale[0] = AREA_GRID / world->areagrid_size[0];
	world->areagrid_scale[1] = AREA_GRID / world->areagrid_size[1];
	world->areagrid_scale[2] = AREA_GRID / world->areagrid_size[2];
	World_ClearLink(&world->areagrid_outside);
	for (i = 0;i < AREA_GRIDNODES;i++)
		World_ClearLink(&world->areagrid[i]);
	if (developer.integer >= 10)
		Con_Printf("areagrid settings: divisions %ix%ix1 : box %f %f %f : %f %f %f size %f %f %f grid %f %f %f (mingrid %f)\n", AREA_GRID, AREA_GRID, world->areagrid_mins[0], world->areagrid_mins[1], world->areagrid_mins[2], world->areagrid_maxs[0], world->areagrid_maxs[1], world->areagrid_maxs[2], world->areagrid_size[0], world->areagrid_size[1], world->areagrid_size[2], 1.0f / world->areagrid_scale[0], 1.0f / world->areagrid_scale[1], 1.0f / world->areagrid_scale[2], sv_areagrid_mingridsize.value);
}

/*
===============
World_UnlinkAll

===============
*/
void World_UnlinkAll(world_t *world)
{
	int i;
	link_t *grid;
	// unlink all entities one by one
	grid = &world->areagrid_outside;
	while (grid->next != grid)
		World_UnlinkEdict(PRVM_EDICT_NUM(grid->next->entitynumber));
	for (i = 0, grid = world->areagrid;i < AREA_GRIDNODES;i++, grid++)
		while (grid->next != grid)
			World_UnlinkEdict(PRVM_EDICT_NUM(grid->next->entitynumber));
}

/*
===============

===============
*/
void World_UnlinkEdict(prvm_edict_t *ent)
{
	int i;
	for (i = 0;i < ENTITYGRIDAREAS;i++)
	{
		if (ent->priv.server->areagrid[i].prev)
		{
			World_RemoveLink (&ent->priv.server->areagrid[i]);
			ent->priv.server->areagrid[i].prev = ent->priv.server->areagrid[i].next = NULL;
		}
	}
}

int World_EntitiesInBox(world_t *world, const vec3_t mins, const vec3_t maxs, int maxlist, prvm_edict_t **list)
{
	int numlist;
	link_t *grid;
	link_t *l;
	prvm_edict_t *ent;
	int igrid[3], igridmins[3], igridmaxs[3];

	// FIXME: if areagrid_marknumber wraps, all entities need their
	// ent->priv.server->areagridmarknumber reset
	world->areagrid_stats_calls++;
	world->areagrid_marknumber++;
	igridmins[0] = (int) floor((mins[0] + world->areagrid_bias[0]) * world->areagrid_scale[0]);
	igridmins[1] = (int) floor((mins[1] + world->areagrid_bias[1]) * world->areagrid_scale[1]);
	//igridmins[2] = (int) ((mins[2] + world->areagrid_bias[2]) * world->areagrid_scale[2]);
	igridmaxs[0] = (int) floor((maxs[0] + world->areagrid_bias[0]) * world->areagrid_scale[0]) + 1;
	igridmaxs[1] = (int) floor((maxs[1] + world->areagrid_bias[1]) * world->areagrid_scale[1]) + 1;
	//igridmaxs[2] = (int) ((maxs[2] + world->areagrid_bias[2]) * world->areagrid_scale[2]) + 1;
	igridmins[0] = max(0, igridmins[0]);
	igridmins[1] = max(0, igridmins[1]);
	//igridmins[2] = max(0, igridmins[2]);
	igridmaxs[0] = min(AREA_GRID, igridmaxs[0]);
	igridmaxs[1] = min(AREA_GRID, igridmaxs[1]);
	//igridmaxs[2] = min(AREA_GRID, igridmaxs[2]);

	numlist = 0;
	// add entities not linked into areagrid because they are too big or
	// outside the grid bounds
	if (world->areagrid_outside.next != &world->areagrid_outside)
	{
		grid = &world->areagrid_outside;
		for (l = grid->next;l != grid;l = l->next)
		{
			ent = PRVM_EDICT_NUM(l->entitynumber);
			if (ent->priv.server->areagridmarknumber != world->areagrid_marknumber)
			{
				ent->priv.server->areagridmarknumber = world->areagrid_marknumber;
				if (!ent->priv.server->free && BoxesOverlap(mins, maxs, ent->priv.server->areamins, ent->priv.server->areamaxs))
				{
					if (numlist < maxlist)
						list[numlist] = ent;
					numlist++;
				}
				world->areagrid_stats_entitychecks++;
			}
		}
	}
	// add grid linked entities
	for (igrid[1] = igridmins[1];igrid[1] < igridmaxs[1];igrid[1]++)
	{
		grid = world->areagrid + igrid[1] * AREA_GRID + igridmins[0];
		for (igrid[0] = igridmins[0];igrid[0] < igridmaxs[0];igrid[0]++, grid++)
		{
			if (grid->next != grid)
			{
				for (l = grid->next;l != grid;l = l->next)
				{
					ent = PRVM_EDICT_NUM(l->entitynumber);
					if (ent->priv.server->areagridmarknumber != world->areagrid_marknumber)
					{
						ent->priv.server->areagridmarknumber = world->areagrid_marknumber;
						if (!ent->priv.server->free && BoxesOverlap(mins, maxs, ent->priv.server->areamins, ent->priv.server->areamaxs))
						{
							if (numlist < maxlist)
								list[numlist] = ent;
							numlist++;
						}
						//Con_Printf("%d %f %f %f %f %f %f : %d : %f %f %f %f %f %f\n", BoxesOverlap(mins, maxs, ent->priv.server->areamins, ent->priv.server->areamaxs), ent->priv.server->areamins[0], ent->priv.server->areamins[1], ent->priv.server->areamins[2], ent->priv.server->areamaxs[0], ent->priv.server->areamaxs[1], ent->priv.server->areamaxs[2], PRVM_NUM_FOR_EDICT(ent), mins[0], mins[1], mins[2], maxs[0], maxs[1], maxs[2]);
					}
					world->areagrid_stats_entitychecks++;
				}
			}
		}
	}
	return numlist;
}

void World_LinkEdict_AreaGrid(world_t *world, prvm_edict_t *ent)
{
	link_t *grid;
	int igrid[3], igridmins[3], igridmaxs[3], gridnum, entitynumber = PRVM_NUM_FOR_EDICT(ent);

	if (entitynumber <= 0 || entitynumber >= prog->max_edicts || PRVM_EDICT_NUM(entitynumber) != ent)
	{
		Con_Printf ("World_LinkEdict_AreaGrid: invalid edict %p (edicts is %p, edict compared to prog->edicts is %i)\n", (void *)ent, (void *)prog->edicts, entitynumber);
		return;
	}

	igridmins[0] = (int) floor((ent->priv.server->areamins[0] + world->areagrid_bias[0]) * world->areagrid_scale[0]);
	igridmins[1] = (int) floor((ent->priv.server->areamins[1] + world->areagrid_bias[1]) * world->areagrid_scale[1]);
	//igridmins[2] = (int) floor((ent->priv.server->areamins[2] + world->areagrid_bias[2]) * world->areagrid_scale[2]);
	igridmaxs[0] = (int) floor((ent->priv.server->areamaxs[0] + world->areagrid_bias[0]) * world->areagrid_scale[0]) + 1;
	igridmaxs[1] = (int) floor((ent->priv.server->areamaxs[1] + world->areagrid_bias[1]) * world->areagrid_scale[1]) + 1;
	//igridmaxs[2] = (int) floor((ent->priv.server->areamaxs[2] + world->areagrid_bias[2]) * world->areagrid_scale[2]) + 1;
	if (igridmins[0] < 0 || igridmaxs[0] > AREA_GRID || igridmins[1] < 0 || igridmaxs[1] > AREA_GRID || ((igridmaxs[0] - igridmins[0]) * (igridmaxs[1] - igridmins[1])) > ENTITYGRIDAREAS)
	{
		// wow, something outside the grid, store it as such
		World_InsertLinkBefore (&ent->priv.server->areagrid[0], &world->areagrid_outside, entitynumber);
		return;
	}

	gridnum = 0;
	for (igrid[1] = igridmins[1];igrid[1] < igridmaxs[1];igrid[1]++)
	{
		grid = world->areagrid + igrid[1] * AREA_GRID + igridmins[0];
		for (igrid[0] = igridmins[0];igrid[0] < igridmaxs[0];igrid[0]++, grid++, gridnum++)
			World_InsertLinkBefore (&ent->priv.server->areagrid[gridnum], grid, entitynumber);
	}
}

/*
===============
World_LinkEdict

===============
*/
void World_LinkEdict(world_t *world, prvm_edict_t *ent, const vec3_t mins, const vec3_t maxs)
{
	// unlink from old position first
	if (ent->priv.server->areagrid[0].prev)
		World_UnlinkEdict(ent);

	// don't add the world
	if (ent == prog->edicts)
		return;

	// don't add free entities
	if (ent->priv.server->free)
		return;

	VectorCopy(mins, ent->priv.server->areamins);
	VectorCopy(maxs, ent->priv.server->areamaxs);
	World_LinkEdict_AreaGrid(world, ent);
}




//============================================================================
// physics engine support
//============================================================================

#ifndef ODE_STATIC
#define ODE_DYNAMIC 1
#endif

#if defined(ODE_STATIC) || defined(ODE_DYNAMIC)
#define USEODE 1
#endif

#ifdef USEODE
cvar_t physics_ode_quadtree_depth = {0, "physics_ode_quadtree_depth","5", "desired subdivision level of quadtree culling space"};
cvar_t physics_ode_contactsurfacelayer = {0, "physics_ode_contactsurfacelayer","0", "allows objects to overlap this many units to reduce jitter"};
cvar_t physics_ode_worldquickstep = {0, "physics_ode_worldquickstep","1", "use dWorldQuickStep rather than dWorldStepFast1 or dWorldStep"};
cvar_t physics_ode_worldquickstep_iterations = {0, "physics_ode_worldquickstep_iterations","20", "parameter to dWorldQuickStep"};
cvar_t physics_ode_worldstepfast = {0, "physics_ode_worldstepfast","0", "use dWorldStepFast1 rather than dWorldStep"};
cvar_t physics_ode_worldstepfast_iterations = {0, "physics_ode_worldstepfast_iterations","20", "parameter to dWorldStepFast1"};
cvar_t physics_ode_contact_mu = {0, "physics_ode_contact_mu", "1", "contact solver mu parameter - friction pyramid approximation 1 (see ODE User Guide)"};
cvar_t physics_ode_contact_erp = {0, "physics_ode_contact_erp", "0.96", "contact solver erp parameter - Error Restitution Percent (see ODE User Guide)"};
cvar_t physics_ode_contact_cfm = {0, "physics_ode_contact_cfm", "0", "contact solver cfm parameter - Constraint Force Mixing (see ODE User Guide)"};
cvar_t physics_ode_iterationsperframe = {0, "physics_ode_iterationsperframe", "4", "divisor for time step, runs multiple physics steps per frame"};
cvar_t physics_ode_movelimit = {0, "physics_ode_movelimit", "0.5", "clamp velocity if a single move would exceed this percentage of object thickness, to prevent flying through walls"};
cvar_t physics_ode_spinlimit = {0, "physics_ode_spinlimit", "10000", "reset spin velocity if it gets too large"};

// LordHavoc: this large chunk of definitions comes from the ODE library
// include files.

#ifdef ODE_STATIC
#include "ode/ode.h"
#else
#ifdef WINAPI
#define ODE_API WINAPI
#else
#define ODE_API
#endif

// note: dynamic builds of ODE tend to be double precision, this is not used
// for static builds
typedef double dReal;

typedef dReal dVector3[4];
typedef dReal dVector4[4];
typedef dReal dMatrix3[4*3];
typedef dReal dMatrix4[4*4];
typedef dReal dMatrix6[8*6];
typedef dReal dQuaternion[4];

struct dxWorld;		/* dynamics world */
struct dxSpace;		/* collision space */
struct dxBody;		/* rigid body (dynamics object) */
struct dxGeom;		/* geometry (collision object) */
struct dxJoint;
struct dxJointNode;
struct dxJointGroup;
struct dxTriMeshData;

typedef struct dxWorld *dWorldID;
typedef struct dxSpace *dSpaceID;
typedef struct dxBody *dBodyID;
typedef struct dxGeom *dGeomID;
typedef struct dxJoint *dJointID;
typedef struct dxJointGroup *dJointGroupID;
typedef struct dxTriMeshData *dTriMeshDataID;

typedef struct dJointFeedback
{
	dVector3 f1;		/* force applied to body 1 */
	dVector3 t1;		/* torque applied to body 1 */
	dVector3 f2;		/* force applied to body 2 */
	dVector3 t2;		/* torque applied to body 2 */
}
dJointFeedback;

typedef enum dJointType
{
	dJointTypeNone = 0,
	dJointTypeBall,
	dJointTypeHinge,
	dJointTypeSlider,
	dJointTypeContact,
	dJointTypeUniversal,
	dJointTypeHinge2,
	dJointTypeFixed,
	dJointTypeNull,
	dJointTypeAMotor,
	dJointTypeLMotor,
	dJointTypePlane2D,
	dJointTypePR,
	dJointTypePU,
	dJointTypePiston
}
dJointType;

typedef struct dMass
{
	dReal mass;
	dVector3 c;
	dMatrix3 I;
}
dMass;

enum
{
	dContactMu2			= 0x001,
	dContactFDir1		= 0x002,
	dContactBounce		= 0x004,
	dContactSoftERP		= 0x008,
	dContactSoftCFM		= 0x010,
	dContactMotion1		= 0x020,
	dContactMotion2		= 0x040,
	dContactMotionN		= 0x080,
	dContactSlip1		= 0x100,
	dContactSlip2		= 0x200,
	
	dContactApprox0		= 0x0000,
	dContactApprox1_1	= 0x1000,
	dContactApprox1_2	= 0x2000,
	dContactApprox1		= 0x3000
};

typedef struct dSurfaceParameters
{
	/* must always be defined */
	int mode;
	dReal mu;

	/* only defined if the corresponding flag is set in mode */
	dReal mu2;
	dReal bounce;
	dReal bounce_vel;
	dReal soft_erp;
	dReal soft_cfm;
	dReal motion1,motion2,motionN;
	dReal slip1,slip2;
} dSurfaceParameters;

typedef struct dContactGeom
{
	dVector3 pos;          ///< contact position
	dVector3 normal;       ///< normal vector
	dReal depth;           ///< penetration depth
	dGeomID g1,g2;         ///< the colliding geoms
	int side1,side2;       ///< (to be documented)
}
dContactGeom;

typedef struct dContact
{
	dSurfaceParameters surface;
	dContactGeom geom;
	dVector3 fdir1;
}
dContact;

typedef void dNearCallback (void *data, dGeomID o1, dGeomID o2);

// SAP
// Order XZY or ZXY usually works best, if your Y is up.
#define dSAP_AXES_XYZ  ((0)|(1<<2)|(2<<4))
#define dSAP_AXES_XZY  ((0)|(2<<2)|(1<<4))
#define dSAP_AXES_YXZ  ((1)|(0<<2)|(2<<4))
#define dSAP_AXES_YZX  ((1)|(2<<2)|(0<<4))
#define dSAP_AXES_ZXY  ((2)|(0<<2)|(1<<4))
#define dSAP_AXES_ZYX  ((2)|(1<<2)|(0<<4))

const char*     (ODE_API *dGetConfiguration)(void);
int             (ODE_API *dCheckConfiguration)( const char* token );
int             (ODE_API *dInitODE)(void);
//int             (ODE_API *dInitODE2)(unsigned int uiInitFlags);
int             (ODE_API *dAllocateODEDataForThread)(unsigned int uiAllocateFlags);
void            (ODE_API *dCleanupODEAllDataForThread)(void);
void            (ODE_API *dCloseODE)(void);

//int             (ODE_API *dMassCheck)(const dMass *m);
//void            (ODE_API *dMassSetZero)(dMass *);
//void            (ODE_API *dMassSetParameters)(dMass *, dReal themass, dReal cgx, dReal cgy, dReal cgz, dReal I11, dReal I22, dReal I33, dReal I12, dReal I13, dReal I23);
//void            (ODE_API *dMassSetSphere)(dMass *, dReal density, dReal radius);
void            (ODE_API *dMassSetSphereTotal)(dMass *, dReal total_mass, dReal radius);
//void            (ODE_API *dMassSetCapsule)(dMass *, dReal density, int direction, dReal radius, dReal length);
void            (ODE_API *dMassSetCapsuleTotal)(dMass *, dReal total_mass, int direction, dReal radius, dReal length);
//void            (ODE_API *dMassSetCylinder)(dMass *, dReal density, int direction, dReal radius, dReal length);
//void            (ODE_API *dMassSetCylinderTotal)(dMass *, dReal total_mass, int direction, dReal radius, dReal length);
//void            (ODE_API *dMassSetBox)(dMass *, dReal density, dReal lx, dReal ly, dReal lz);
void            (ODE_API *dMassSetBoxTotal)(dMass *, dReal total_mass, dReal lx, dReal ly, dReal lz);
//void            (ODE_API *dMassSetTrimesh)(dMass *, dReal density, dGeomID g);
//void            (ODE_API *dMassSetTrimeshTotal)(dMass *m, dReal total_mass, dGeomID g);
//void            (ODE_API *dMassAdjust)(dMass *, dReal newmass);
//void            (ODE_API *dMassTranslate)(dMass *, dReal x, dReal y, dReal z);
//void            (ODE_API *dMassRotate)(dMass *, const dMatrix3 R);
//void            (ODE_API *dMassAdd)(dMass *a, const dMass *b);
//
dWorldID        (ODE_API *dWorldCreate)(void);
void            (ODE_API *dWorldDestroy)(dWorldID world);
void            (ODE_API *dWorldSetGravity)(dWorldID, dReal x, dReal y, dReal z);
//void            (ODE_API *dWorldGetGravity)(dWorldID, dVector3 gravity);
//void            (ODE_API *dWorldSetERP)(dWorldID, dReal erp);
//dReal           (ODE_API *dWorldGetERP)(dWorldID);
//void            (ODE_API *dWorldSetCFM)(dWorldID, dReal cfm);
//dReal           (ODE_API *dWorldGetCFM)(dWorldID);
void            (ODE_API *dWorldStep)(dWorldID, dReal stepsize);
//void            (ODE_API *dWorldImpulseToForce)(dWorldID, dReal stepsize, dReal ix, dReal iy, dReal iz, dVector3 force);
void            (ODE_API *dWorldQuickStep)(dWorldID w, dReal stepsize);
void            (ODE_API *dWorldSetQuickStepNumIterations)(dWorldID, int num);
//int             (ODE_API *dWorldGetQuickStepNumIterations)(dWorldID);
//void            (ODE_API *dWorldSetQuickStepW)(dWorldID, dReal over_relaxation);
//dReal           (ODE_API *dWorldGetQuickStepW)(dWorldID);
//void            (ODE_API *dWorldSetContactMaxCorrectingVel)(dWorldID, dReal vel);
//dReal           (ODE_API *dWorldGetContactMaxCorrectingVel)(dWorldID);
void            (ODE_API *dWorldSetContactSurfaceLayer)(dWorldID, dReal depth);
//dReal           (ODE_API *dWorldGetContactSurfaceLayer)(dWorldID);
void            (ODE_API *dWorldStepFast1)(dWorldID, dReal stepsize, int maxiterations);
//void            (ODE_API *dWorldSetAutoEnableDepthSF1)(dWorldID, int autoEnableDepth);
//int             (ODE_API *dWorldGetAutoEnableDepthSF1)(dWorldID);
//dReal           (ODE_API *dWorldGetAutoDisableLinearThreshold)(dWorldID);
//void            (ODE_API *dWorldSetAutoDisableLinearThreshold)(dWorldID, dReal linear_threshold);
//dReal           (ODE_API *dWorldGetAutoDisableAngularThreshold)(dWorldID);
//void            (ODE_API *dWorldSetAutoDisableAngularThreshold)(dWorldID, dReal angular_threshold);
//dReal           (ODE_API *dWorldGetAutoDisableLinearAverageThreshold)(dWorldID);
//void            (ODE_API *dWorldSetAutoDisableLinearAverageThreshold)(dWorldID, dReal linear_average_threshold);
//dReal           (ODE_API *dWorldGetAutoDisableAngularAverageThreshold)(dWorldID);
//void            (ODE_API *dWorldSetAutoDisableAngularAverageThreshold)(dWorldID, dReal angular_average_threshold);
//int             (ODE_API *dWorldGetAutoDisableAverageSamplesCount)(dWorldID);
//void            (ODE_API *dWorldSetAutoDisableAverageSamplesCount)(dWorldID, unsigned int average_samples_count );
//int             (ODE_API *dWorldGetAutoDisableSteps)(dWorldID);
//void            (ODE_API *dWorldSetAutoDisableSteps)(dWorldID, int steps);
//dReal           (ODE_API *dWorldGetAutoDisableTime)(dWorldID);
//void            (ODE_API *dWorldSetAutoDisableTime)(dWorldID, dReal time);
//int             (ODE_API *dWorldGetAutoDisableFlag)(dWorldID);
//void            (ODE_API *dWorldSetAutoDisableFlag)(dWorldID, int do_auto_disable);
//dReal           (ODE_API *dWorldGetLinearDampingThreshold)(dWorldID w);
//void            (ODE_API *dWorldSetLinearDampingThreshold)(dWorldID w, dReal threshold);
//dReal           (ODE_API *dWorldGetAngularDampingThreshold)(dWorldID w);
//void            (ODE_API *dWorldSetAngularDampingThreshold)(dWorldID w, dReal threshold);
//dReal           (ODE_API *dWorldGetLinearDamping)(dWorldID w);
//void            (ODE_API *dWorldSetLinearDamping)(dWorldID w, dReal scale);
//dReal           (ODE_API *dWorldGetAngularDamping)(dWorldID w);
//void            (ODE_API *dWorldSetAngularDamping)(dWorldID w, dReal scale);
//void            (ODE_API *dWorldSetDamping)(dWorldID w, dReal linear_scale, dReal angular_scale);
//dReal           (ODE_API *dWorldGetMaxAngularSpeed)(dWorldID w);
//void            (ODE_API *dWorldSetMaxAngularSpeed)(dWorldID w, dReal max_speed);
//dReal           (ODE_API *dBodyGetAutoDisableLinearThreshold)(dBodyID);
//void            (ODE_API *dBodySetAutoDisableLinearThreshold)(dBodyID, dReal linear_average_threshold);
//dReal           (ODE_API *dBodyGetAutoDisableAngularThreshold)(dBodyID);
//void            (ODE_API *dBodySetAutoDisableAngularThreshold)(dBodyID, dReal angular_average_threshold);
//int             (ODE_API *dBodyGetAutoDisableAverageSamplesCount)(dBodyID);
//void            (ODE_API *dBodySetAutoDisableAverageSamplesCount)(dBodyID, unsigned int average_samples_count);
//int             (ODE_API *dBodyGetAutoDisableSteps)(dBodyID);
//void            (ODE_API *dBodySetAutoDisableSteps)(dBodyID, int steps);
//dReal           (ODE_API *dBodyGetAutoDisableTime)(dBodyID);
//void            (ODE_API *dBodySetAutoDisableTime)(dBodyID, dReal time);
//int             (ODE_API *dBodyGetAutoDisableFlag)(dBodyID);
//void            (ODE_API *dBodySetAutoDisableFlag)(dBodyID, int do_auto_disable);
//void            (ODE_API *dBodySetAutoDisableDefaults)(dBodyID);
//dWorldID        (ODE_API *dBodyGetWorld)(dBodyID);
dBodyID         (ODE_API *dBodyCreate)(dWorldID);
void            (ODE_API *dBodyDestroy)(dBodyID);
void            (ODE_API *dBodySetData)(dBodyID, void *data);
//void *          (ODE_API *dBodyGetData)(dBodyID);
void            (ODE_API *dBodySetPosition)(dBodyID, dReal x, dReal y, dReal z);
void            (ODE_API *dBodySetRotation)(dBodyID, const dMatrix3 R);
//void            (ODE_API *dBodySetQuaternion)(dBodyID, const dQuaternion q);
void            (ODE_API *dBodySetLinearVel)(dBodyID, dReal x, dReal y, dReal z);
void            (ODE_API *dBodySetAngularVel)(dBodyID, dReal x, dReal y, dReal z);
const dReal *   (ODE_API *dBodyGetPosition)(dBodyID);
//void            (ODE_API *dBodyCopyPosition)(dBodyID body, dVector3 pos);
const dReal *   (ODE_API *dBodyGetRotation)(dBodyID);
//void            (ODE_API *dBodyCopyRotation)(dBodyID, dMatrix3 R);
//const dReal *   (ODE_API *dBodyGetQuaternion)(dBodyID);
//void            (ODE_API *dBodyCopyQuaternion)(dBodyID body, dQuaternion quat);
const dReal *   (ODE_API *dBodyGetLinearVel)(dBodyID);
const dReal *   (ODE_API *dBodyGetAngularVel)(dBodyID);
void            (ODE_API *dBodySetMass)(dBodyID, const dMass *mass);
//void            (ODE_API *dBodyGetMass)(dBodyID, dMass *mass);
//void            (ODE_API *dBodyAddForce)(dBodyID, dReal fx, dReal fy, dReal fz);
//void            (ODE_API *dBodyAddTorque)(dBodyID, dReal fx, dReal fy, dReal fz);
//void            (ODE_API *dBodyAddRelForce)(dBodyID, dReal fx, dReal fy, dReal fz);
//void            (ODE_API *dBodyAddRelTorque)(dBodyID, dReal fx, dReal fy, dReal fz);
//void            (ODE_API *dBodyAddForceAtPos)(dBodyID, dReal fx, dReal fy, dReal fz, dReal px, dReal py, dReal pz);
//void            (ODE_API *dBodyAddForceAtRelPos)(dBodyID, dReal fx, dReal fy, dReal fz, dReal px, dReal py, dReal pz);
//void            (ODE_API *dBodyAddRelForceAtPos)(dBodyID, dReal fx, dReal fy, dReal fz, dReal px, dReal py, dReal pz);
//void            (ODE_API *dBodyAddRelForceAtRelPos)(dBodyID, dReal fx, dReal fy, dReal fz, dReal px, dReal py, dReal pz);
//const dReal *   (ODE_API *dBodyGetForce)(dBodyID);
//const dReal *   (ODE_API *dBodyGetTorque)(dBodyID);
//void            (ODE_API *dBodySetForce)(dBodyID b, dReal x, dReal y, dReal z);
//void            (ODE_API *dBodySetTorque)(dBodyID b, dReal x, dReal y, dReal z);
//void            (ODE_API *dBodyGetRelPointPos)(dBodyID, dReal px, dReal py, dReal pz, dVector3 result);
//void            (ODE_API *dBodyGetRelPointVel)(dBodyID, dReal px, dReal py, dReal pz, dVector3 result);
//void            (ODE_API *dBodyGetPointVel)(dBodyID, dReal px, dReal py, dReal pz, dVector3 result);
//void            (ODE_API *dBodyGetPosRelPoint)(dBodyID, dReal px, dReal py, dReal pz, dVector3 result);
//void            (ODE_API *dBodyVectorToWorld)(dBodyID, dReal px, dReal py, dReal pz, dVector3 result);
//void            (ODE_API *dBodyVectorFromWorld)(dBodyID, dReal px, dReal py, dReal pz, dVector3 result);
//void            (ODE_API *dBodySetFiniteRotationMode)(dBodyID, int mode);
//void            (ODE_API *dBodySetFiniteRotationAxis)(dBodyID, dReal x, dReal y, dReal z);
//int             (ODE_API *dBodyGetFiniteRotationMode)(dBodyID);
//void            (ODE_API *dBodyGetFiniteRotationAxis)(dBodyID, dVector3 result);
//int             (ODE_API *dBodyGetNumJoints)(dBodyID b);
//dJointID        (ODE_API *dBodyGetJoint)(dBodyID, int index);
//void            (ODE_API *dBodySetDynamic)(dBodyID);
//void            (ODE_API *dBodySetKinematic)(dBodyID);
//int             (ODE_API *dBodyIsKinematic)(dBodyID);
//void            (ODE_API *dBodyEnable)(dBodyID);
//void            (ODE_API *dBodyDisable)(dBodyID);
//int             (ODE_API *dBodyIsEnabled)(dBodyID);
//void            (ODE_API *dBodySetGravityMode)(dBodyID b, int mode);
//int             (ODE_API *dBodyGetGravityMode)(dBodyID b);
//void            (*dBodySetMovedCallback)(dBodyID b, void(ODE_API *callback)(dBodyID));
//dGeomID         (ODE_API *dBodyGetFirstGeom)(dBodyID b);
//dGeomID         (ODE_API *dBodyGetNextGeom)(dGeomID g);
//void            (ODE_API *dBodySetDampingDefaults)(dBodyID b);
//dReal           (ODE_API *dBodyGetLinearDamping)(dBodyID b);
//void            (ODE_API *dBodySetLinearDamping)(dBodyID b, dReal scale);
//dReal           (ODE_API *dBodyGetAngularDamping)(dBodyID b);
//void            (ODE_API *dBodySetAngularDamping)(dBodyID b, dReal scale);
//void            (ODE_API *dBodySetDamping)(dBodyID b, dReal linear_scale, dReal angular_scale);
//dReal           (ODE_API *dBodyGetLinearDampingThreshold)(dBodyID b);
//void            (ODE_API *dBodySetLinearDampingThreshold)(dBodyID b, dReal threshold);
//dReal           (ODE_API *dBodyGetAngularDampingThreshold)(dBodyID b);
//void            (ODE_API *dBodySetAngularDampingThreshold)(dBodyID b, dReal threshold);
//dReal           (ODE_API *dBodyGetMaxAngularSpeed)(dBodyID b);
//void            (ODE_API *dBodySetMaxAngularSpeed)(dBodyID b, dReal max_speed);
//int             (ODE_API *dBodyGetGyroscopicMode)(dBodyID b);
//void            (ODE_API *dBodySetGyroscopicMode)(dBodyID b, int enabled);
//dJointID        (ODE_API *dJointCreateBall)(dWorldID, dJointGroupID);
//dJointID        (ODE_API *dJointCreateHinge)(dWorldID, dJointGroupID);
//dJointID        (ODE_API *dJointCreateSlider)(dWorldID, dJointGroupID);
dJointID        (ODE_API *dJointCreateContact)(dWorldID, dJointGroupID, const dContact *);
//dJointID        (ODE_API *dJointCreateHinge2)(dWorldID, dJointGroupID);
//dJointID        (ODE_API *dJointCreateUniversal)(dWorldID, dJointGroupID);
//dJointID        (ODE_API *dJointCreatePR)(dWorldID, dJointGroupID);
//dJointID        (ODE_API *dJointCreatePU)(dWorldID, dJointGroupID);
//dJointID        (ODE_API *dJointCreatePiston)(dWorldID, dJointGroupID);
//dJointID        (ODE_API *dJointCreateFixed)(dWorldID, dJointGroupID);
//dJointID        (ODE_API *dJointCreateNull)(dWorldID, dJointGroupID);
//dJointID        (ODE_API *dJointCreateAMotor)(dWorldID, dJointGroupID);
//dJointID        (ODE_API *dJointCreateLMotor)(dWorldID, dJointGroupID);
//dJointID        (ODE_API *dJointCreatePlane2D)(dWorldID, dJointGroupID);
//void            (ODE_API *dJointDestroy)(dJointID);
dJointGroupID   (ODE_API *dJointGroupCreate)(int max_size);
void            (ODE_API *dJointGroupDestroy)(dJointGroupID);
void            (ODE_API *dJointGroupEmpty)(dJointGroupID);
//int             (ODE_API *dJointGetNumBodies)(dJointID);
void            (ODE_API *dJointAttach)(dJointID, dBodyID body1, dBodyID body2);
//void            (ODE_API *dJointEnable)(dJointID);
//void            (ODE_API *dJointDisable)(dJointID);
//int             (ODE_API *dJointIsEnabled)(dJointID);
//void            (ODE_API *dJointSetData)(dJointID, void *data);
//void *          (ODE_API *dJointGetData)(dJointID);
//dJointType      (ODE_API *dJointGetType)(dJointID);
//dBodyID         (ODE_API *dJointGetBody)(dJointID, int index);
//void            (ODE_API *dJointSetFeedback)(dJointID, dJointFeedback *);
//dJointFeedback *(ODE_API *dJointGetFeedback)(dJointID);
//void            (ODE_API *dJointSetBallAnchor)(dJointID, dReal x, dReal y, dReal z);
//void            (ODE_API *dJointSetBallAnchor2)(dJointID, dReal x, dReal y, dReal z);
//void            (ODE_API *dJointSetBallParam)(dJointID, int parameter, dReal value);
//void            (ODE_API *dJointSetHingeAnchor)(dJointID, dReal x, dReal y, dReal z);
//void            (ODE_API *dJointSetHingeAnchorDelta)(dJointID, dReal x, dReal y, dReal z, dReal ax, dReal ay, dReal az);
//void            (ODE_API *dJointSetHingeAxis)(dJointID, dReal x, dReal y, dReal z);
//void            (ODE_API *dJointSetHingeAxisOffset)(dJointID j, dReal x, dReal y, dReal z, dReal angle);
//void            (ODE_API *dJointSetHingeParam)(dJointID, int parameter, dReal value);
//void            (ODE_API *dJointAddHingeTorque)(dJointID joint, dReal torque);
//void            (ODE_API *dJointSetSliderAxis)(dJointID, dReal x, dReal y, dReal z);
//void            (ODE_API *dJointSetSliderAxisDelta)(dJointID, dReal x, dReal y, dReal z, dReal ax, dReal ay, dReal az);
//void            (ODE_API *dJointSetSliderParam)(dJointID, int parameter, dReal value);
//void            (ODE_API *dJointAddSliderForce)(dJointID joint, dReal force);
//void            (ODE_API *dJointSetHinge2Anchor)(dJointID, dReal x, dReal y, dReal z);
//void            (ODE_API *dJointSetHinge2Axis1)(dJointID, dReal x, dReal y, dReal z);
//void            (ODE_API *dJointSetHinge2Axis2)(dJointID, dReal x, dReal y, dReal z);
//void            (ODE_API *dJointSetHinge2Param)(dJointID, int parameter, dReal value);
//void            (ODE_API *dJointAddHinge2Torques)(dJointID joint, dReal torque1, dReal torque2);
//void            (ODE_API *dJointSetUniversalAnchor)(dJointID, dReal x, dReal y, dReal z);
//void            (ODE_API *dJointSetUniversalAxis1)(dJointID, dReal x, dReal y, dReal z);
//void            (ODE_API *dJointSetUniversalAxis1Offset)(dJointID, dReal x, dReal y, dReal z, dReal offset1, dReal offset2);
//void            (ODE_API *dJointSetUniversalAxis2)(dJointID, dReal x, dReal y, dReal z);
//void            (ODE_API *dJointSetUniversalAxis2Offset)(dJointID, dReal x, dReal y, dReal z, dReal offset1, dReal offset2);
//void            (ODE_API *dJointSetUniversalParam)(dJointID, int parameter, dReal value);
//void            (ODE_API *dJointAddUniversalTorques)(dJointID joint, dReal torque1, dReal torque2);
//void            (ODE_API *dJointSetPRAnchor)(dJointID, dReal x, dReal y, dReal z);
//void            (ODE_API *dJointSetPRAxis1)(dJointID, dReal x, dReal y, dReal z);
//void            (ODE_API *dJointSetPRAxis2)(dJointID, dReal x, dReal y, dReal z);
//void            (ODE_API *dJointSetPRParam)(dJointID, int parameter, dReal value);
//void            (ODE_API *dJointAddPRTorque)(dJointID j, dReal torque);
//void            (ODE_API *dJointSetPUAnchor)(dJointID, dReal x, dReal y, dReal z);
//void            (ODE_API *dJointSetPUAnchorOffset)(dJointID, dReal x, dReal y, dReal z, dReal dx, dReal dy, dReal dz);
//void            (ODE_API *dJointSetPUAxis1)(dJointID, dReal x, dReal y, dReal z);
//void            (ODE_API *dJointSetPUAxis2)(dJointID, dReal x, dReal y, dReal z);
//void            (ODE_API *dJointSetPUAxis3)(dJointID, dReal x, dReal y, dReal z);
//void            (ODE_API *dJointSetPUAxisP)(dJointID id, dReal x, dReal y, dReal z);
//void            (ODE_API *dJointSetPUParam)(dJointID, int parameter, dReal value);
//void            (ODE_API *dJointAddPUTorque)(dJointID j, dReal torque);
//void            (ODE_API *dJointSetPistonAnchor)(dJointID, dReal x, dReal y, dReal z);
//void            (ODE_API *dJointSetPistonAnchorOffset)(dJointID j, dReal x, dReal y, dReal z, dReal dx, dReal dy, dReal dz);
//void            (ODE_API *dJointSetPistonParam)(dJointID, int parameter, dReal value);
//void            (ODE_API *dJointAddPistonForce)(dJointID joint, dReal force);
//void            (ODE_API *dJointSetFixed)(dJointID);
//void            (ODE_API *dJointSetFixedParam)(dJointID, int parameter, dReal value);
//void            (ODE_API *dJointSetAMotorNumAxes)(dJointID, int num);
//void            (ODE_API *dJointSetAMotorAxis)(dJointID, int anum, int rel, dReal x, dReal y, dReal z);
//void            (ODE_API *dJointSetAMotorAngle)(dJointID, int anum, dReal angle);
//void            (ODE_API *dJointSetAMotorParam)(dJointID, int parameter, dReal value);
//void            (ODE_API *dJointSetAMotorMode)(dJointID, int mode);
//void            (ODE_API *dJointAddAMotorTorques)(dJointID, dReal torque1, dReal torque2, dReal torque3);
//void            (ODE_API *dJointSetLMotorNumAxes)(dJointID, int num);
//void            (ODE_API *dJointSetLMotorAxis)(dJointID, int anum, int rel, dReal x, dReal y, dReal z);
//void            (ODE_API *dJointSetLMotorParam)(dJointID, int parameter, dReal value);
//void            (ODE_API *dJointSetPlane2DXParam)(dJointID, int parameter, dReal value);
//void            (ODE_API *dJointSetPlane2DYParam)(dJointID, int parameter, dReal value);
//void            (ODE_API *dJointSetPlane2DAngleParam)(dJointID, int parameter, dReal value);
//void            (ODE_API *dJointGetBallAnchor)(dJointID, dVector3 result);
//void            (ODE_API *dJointGetBallAnchor2)(dJointID, dVector3 result);
//dReal           (ODE_API *dJointGetBallParam)(dJointID, int parameter);
//void            (ODE_API *dJointGetHingeAnchor)(dJointID, dVector3 result);
//void            (ODE_API *dJointGetHingeAnchor2)(dJointID, dVector3 result);
//void            (ODE_API *dJointGetHingeAxis)(dJointID, dVector3 result);
//dReal           (ODE_API *dJointGetHingeParam)(dJointID, int parameter);
//dReal           (ODE_API *dJointGetHingeAngle)(dJointID);
//dReal           (ODE_API *dJointGetHingeAngleRate)(dJointID);
//dReal           (ODE_API *dJointGetSliderPosition)(dJointID);
//dReal           (ODE_API *dJointGetSliderPositionRate)(dJointID);
//void            (ODE_API *dJointGetSliderAxis)(dJointID, dVector3 result);
//dReal           (ODE_API *dJointGetSliderParam)(dJointID, int parameter);
//void            (ODE_API *dJointGetHinge2Anchor)(dJointID, dVector3 result);
//void            (ODE_API *dJointGetHinge2Anchor2)(dJointID, dVector3 result);
//void            (ODE_API *dJointGetHinge2Axis1)(dJointID, dVector3 result);
//void            (ODE_API *dJointGetHinge2Axis2)(dJointID, dVector3 result);
//dReal           (ODE_API *dJointGetHinge2Param)(dJointID, int parameter);
//dReal           (ODE_API *dJointGetHinge2Angle1)(dJointID);
//dReal           (ODE_API *dJointGetHinge2Angle1Rate)(dJointID);
//dReal           (ODE_API *dJointGetHinge2Angle2Rate)(dJointID);
//void            (ODE_API *dJointGetUniversalAnchor)(dJointID, dVector3 result);
//void            (ODE_API *dJointGetUniversalAnchor2)(dJointID, dVector3 result);
//void            (ODE_API *dJointGetUniversalAxis1)(dJointID, dVector3 result);
//void            (ODE_API *dJointGetUniversalAxis2)(dJointID, dVector3 result);
//dReal           (ODE_API *dJointGetUniversalParam)(dJointID, int parameter);
//void            (ODE_API *dJointGetUniversalAngles)(dJointID, dReal *angle1, dReal *angle2);
//dReal           (ODE_API *dJointGetUniversalAngle1)(dJointID);
//dReal           (ODE_API *dJointGetUniversalAngle2)(dJointID);
//dReal           (ODE_API *dJointGetUniversalAngle1Rate)(dJointID);
//dReal           (ODE_API *dJointGetUniversalAngle2Rate)(dJointID);
//void            (ODE_API *dJointGetPRAnchor)(dJointID, dVector3 result);
//dReal           (ODE_API *dJointGetPRPosition)(dJointID);
//dReal           (ODE_API *dJointGetPRPositionRate)(dJointID);
//dReal           (ODE_API *dJointGetPRAngle)(dJointID);
//dReal           (ODE_API *dJointGetPRAngleRate)(dJointID);
//void            (ODE_API *dJointGetPRAxis1)(dJointID, dVector3 result);
//void            (ODE_API *dJointGetPRAxis2)(dJointID, dVector3 result);
//dReal           (ODE_API *dJointGetPRParam)(dJointID, int parameter);
//void            (ODE_API *dJointGetPUAnchor)(dJointID, dVector3 result);
//dReal           (ODE_API *dJointGetPUPosition)(dJointID);
//dReal           (ODE_API *dJointGetPUPositionRate)(dJointID);
//void            (ODE_API *dJointGetPUAxis1)(dJointID, dVector3 result);
//void            (ODE_API *dJointGetPUAxis2)(dJointID, dVector3 result);
//void            (ODE_API *dJointGetPUAxis3)(dJointID, dVector3 result);
//void            (ODE_API *dJointGetPUAxisP)(dJointID id, dVector3 result);
//void            (ODE_API *dJointGetPUAngles)(dJointID, dReal *angle1, dReal *angle2);
//dReal           (ODE_API *dJointGetPUAngle1)(dJointID);
//dReal           (ODE_API *dJointGetPUAngle1Rate)(dJointID);
//dReal           (ODE_API *dJointGetPUAngle2)(dJointID);
//dReal           (ODE_API *dJointGetPUAngle2Rate)(dJointID);
//dReal           (ODE_API *dJointGetPUParam)(dJointID, int parameter);
//dReal           (ODE_API *dJointGetPistonPosition)(dJointID);
//dReal           (ODE_API *dJointGetPistonPositionRate)(dJointID);
//dReal           (ODE_API *dJointGetPistonAngle)(dJointID);
//dReal           (ODE_API *dJointGetPistonAngleRate)(dJointID);
//void            (ODE_API *dJointGetPistonAnchor)(dJointID, dVector3 result);
//void            (ODE_API *dJointGetPistonAnchor2)(dJointID, dVector3 result);
//void            (ODE_API *dJointGetPistonAxis)(dJointID, dVector3 result);
//dReal           (ODE_API *dJointGetPistonParam)(dJointID, int parameter);
//int             (ODE_API *dJointGetAMotorNumAxes)(dJointID);
//void            (ODE_API *dJointGetAMotorAxis)(dJointID, int anum, dVector3 result);
//int             (ODE_API *dJointGetAMotorAxisRel)(dJointID, int anum);
//dReal           (ODE_API *dJointGetAMotorAngle)(dJointID, int anum);
//dReal           (ODE_API *dJointGetAMotorAngleRate)(dJointID, int anum);
//dReal           (ODE_API *dJointGetAMotorParam)(dJointID, int parameter);
//int             (ODE_API *dJointGetAMotorMode)(dJointID);
//int             (ODE_API *dJointGetLMotorNumAxes)(dJointID);
//void            (ODE_API *dJointGetLMotorAxis)(dJointID, int anum, dVector3 result);
//dReal           (ODE_API *dJointGetLMotorParam)(dJointID, int parameter);
//dReal           (ODE_API *dJointGetFixedParam)(dJointID, int parameter);
//dJointID        (ODE_API *dConnectingJoint)(dBodyID, dBodyID);
//int             (ODE_API *dConnectingJointList)(dBodyID, dBodyID, dJointID*);
int             (ODE_API *dAreConnected)(dBodyID, dBodyID);
int             (ODE_API *dAreConnectedExcluding)(dBodyID body1, dBodyID body2, int joint_type);
//
dSpaceID        (ODE_API *dSimpleSpaceCreate)(dSpaceID space);
dSpaceID        (ODE_API *dHashSpaceCreate)(dSpaceID space);
dSpaceID        (ODE_API *dQuadTreeSpaceCreate)(dSpaceID space, const dVector3 Center, const dVector3 Extents, int Depth);
dSpaceID        (ODE_API *dSweepAndPruneSpaceCreate)( dSpaceID space, int axisorder );
void            (ODE_API *dSpaceDestroy)(dSpaceID);
//void            (ODE_API *dHashSpaceSetLevels)(dSpaceID space, int minlevel, int maxlevel);
//void            (ODE_API *dHashSpaceGetLevels)(dSpaceID space, int *minlevel, int *maxlevel);
//void            (ODE_API *dSpaceSetCleanup)(dSpaceID space, int mode);
//int             (ODE_API *dSpaceGetCleanup)(dSpaceID space);
//void            (ODE_API *dSpaceSetSublevel)(dSpaceID space, int sublevel);
//int             (ODE_API *dSpaceGetSublevel)(dSpaceID space);
//void            (ODE_API *dSpaceSetManualCleanup)(dSpaceID space, int mode);
//int             (ODE_API *dSpaceGetManualCleanup)(dSpaceID space);
//void            (ODE_API *dSpaceAdd)(dSpaceID, dGeomID);
//void            (ODE_API *dSpaceRemove)(dSpaceID, dGeomID);
//int             (ODE_API *dSpaceQuery)(dSpaceID, dGeomID);
//void            (ODE_API *dSpaceClean)(dSpaceID);
//int             (ODE_API *dSpaceGetNumGeoms)(dSpaceID);
//dGeomID         (ODE_API *dSpaceGetGeom)(dSpaceID, int i);
//int             (ODE_API *dSpaceGetClass)(dSpaceID space);
//
void            (ODE_API *dGeomDestroy)(dGeomID geom);
//void            (ODE_API *dGeomSetData)(dGeomID geom, void* data);
//void *          (ODE_API *dGeomGetData)(dGeomID geom);
void            (ODE_API *dGeomSetBody)(dGeomID geom, dBodyID body);
dBodyID         (ODE_API *dGeomGetBody)(dGeomID geom);
//void            (ODE_API *dGeomSetPosition)(dGeomID geom, dReal x, dReal y, dReal z);
void            (ODE_API *dGeomSetRotation)(dGeomID geom, const dMatrix3 R);
//void            (ODE_API *dGeomSetQuaternion)(dGeomID geom, const dQuaternion Q);
//const dReal *   (ODE_API *dGeomGetPosition)(dGeomID geom);
//void            (ODE_API *dGeomCopyPosition)(dGeomID geom, dVector3 pos);
//const dReal *   (ODE_API *dGeomGetRotation)(dGeomID geom);
//void            (ODE_API *dGeomCopyRotation)(dGeomID geom, dMatrix3 R);
//void            (ODE_API *dGeomGetQuaternion)(dGeomID geom, dQuaternion result);
//void            (ODE_API *dGeomGetAABB)(dGeomID geom, dReal aabb[6]);
int             (ODE_API *dGeomIsSpace)(dGeomID geom);
//dSpaceID        (ODE_API *dGeomGetSpace)(dGeomID);
//int             (ODE_API *dGeomGetClass)(dGeomID geom);
//void            (ODE_API *dGeomSetCategoryBits)(dGeomID geom, unsigned long bits);
//void            (ODE_API *dGeomSetCollideBits)(dGeomID geom, unsigned long bits);
//unsigned long   (ODE_API *dGeomGetCategoryBits)(dGeomID);
//unsigned long   (ODE_API *dGeomGetCollideBits)(dGeomID);
//void            (ODE_API *dGeomEnable)(dGeomID geom);
//void            (ODE_API *dGeomDisable)(dGeomID geom);
//int             (ODE_API *dGeomIsEnabled)(dGeomID geom);
//void            (ODE_API *dGeomSetOffsetPosition)(dGeomID geom, dReal x, dReal y, dReal z);
//void            (ODE_API *dGeomSetOffsetRotation)(dGeomID geom, const dMatrix3 R);
//void            (ODE_API *dGeomSetOffsetQuaternion)(dGeomID geom, const dQuaternion Q);
//void            (ODE_API *dGeomSetOffsetWorldPosition)(dGeomID geom, dReal x, dReal y, dReal z);
//void            (ODE_API *dGeomSetOffsetWorldRotation)(dGeomID geom, const dMatrix3 R);
//void            (ODE_API *dGeomSetOffsetWorldQuaternion)(dGeomID geom, const dQuaternion);
//void            (ODE_API *dGeomClearOffset)(dGeomID geom);
//int             (ODE_API *dGeomIsOffset)(dGeomID geom);
//const dReal *   (ODE_API *dGeomGetOffsetPosition)(dGeomID geom);
//void            (ODE_API *dGeomCopyOffsetPosition)(dGeomID geom, dVector3 pos);
//const dReal *   (ODE_API *dGeomGetOffsetRotation)(dGeomID geom);
//void            (ODE_API *dGeomCopyOffsetRotation)(dGeomID geom, dMatrix3 R);
//void            (ODE_API *dGeomGetOffsetQuaternion)(dGeomID geom, dQuaternion result);
int             (ODE_API *dCollide)(dGeomID o1, dGeomID o2, int flags, dContactGeom *contact, int skip);
//
void            (ODE_API *dSpaceCollide)(dSpaceID space, void *data, dNearCallback *callback);
void            (ODE_API *dSpaceCollide2)(dGeomID space1, dGeomID space2, void *data, dNearCallback *callback);
//
dGeomID         (ODE_API *dCreateSphere)(dSpaceID space, dReal radius);
//void            (ODE_API *dGeomSphereSetRadius)(dGeomID sphere, dReal radius);
//dReal           (ODE_API *dGeomSphereGetRadius)(dGeomID sphere);
//dReal           (ODE_API *dGeomSpherePointDepth)(dGeomID sphere, dReal x, dReal y, dReal z);
//
//dGeomID         (ODE_API *dCreateConvex)(dSpaceID space, dReal *_planes, unsigned int _planecount, dReal *_points, unsigned int _pointcount,unsigned int *_polygons);
//void            (ODE_API *dGeomSetConvex)(dGeomID g, dReal *_planes, unsigned int _count, dReal *_points, unsigned int _pointcount,unsigned int *_polygons);
//
dGeomID         (ODE_API *dCreateBox)(dSpaceID space, dReal lx, dReal ly, dReal lz);
//void            (ODE_API *dGeomBoxSetLengths)(dGeomID box, dReal lx, dReal ly, dReal lz);
//void            (ODE_API *dGeomBoxGetLengths)(dGeomID box, dVector3 result);
//dReal           (ODE_API *dGeomBoxPointDepth)(dGeomID box, dReal x, dReal y, dReal z);
//dReal           (ODE_API *dGeomBoxPointDepth)(dGeomID box, dReal x, dReal y, dReal z);
//
//dGeomID         (ODE_API *dCreatePlane)(dSpaceID space, dReal a, dReal b, dReal c, dReal d);
//void            (ODE_API *dGeomPlaneSetParams)(dGeomID plane, dReal a, dReal b, dReal c, dReal d);
//void            (ODE_API *dGeomPlaneGetParams)(dGeomID plane, dVector4 result);
//dReal           (ODE_API *dGeomPlanePointDepth)(dGeomID plane, dReal x, dReal y, dReal z);
//
dGeomID         (ODE_API *dCreateCapsule)(dSpaceID space, dReal radius, dReal length);
//void            (ODE_API *dGeomCapsuleSetParams)(dGeomID ccylinder, dReal radius, dReal length);
//void            (ODE_API *dGeomCapsuleGetParams)(dGeomID ccylinder, dReal *radius, dReal *length);
//dReal           (ODE_API *dGeomCapsulePointDepth)(dGeomID ccylinder, dReal x, dReal y, dReal z);
//
//dGeomID         (ODE_API *dCreateCylinder)(dSpaceID space, dReal radius, dReal length);
//void            (ODE_API *dGeomCylinderSetParams)(dGeomID cylinder, dReal radius, dReal length);
//void            (ODE_API *dGeomCylinderGetParams)(dGeomID cylinder, dReal *radius, dReal *length);
//
//dGeomID         (ODE_API *dCreateRay)(dSpaceID space, dReal length);
//void            (ODE_API *dGeomRaySetLength)(dGeomID ray, dReal length);
//dReal           (ODE_API *dGeomRayGetLength)(dGeomID ray);
//void            (ODE_API *dGeomRaySet)(dGeomID ray, dReal px, dReal py, dReal pz, dReal dx, dReal dy, dReal dz);
//void            (ODE_API *dGeomRayGet)(dGeomID ray, dVector3 start, dVector3 dir);
//
dGeomID         (ODE_API *dCreateGeomTransform)(dSpaceID space);
void            (ODE_API *dGeomTransformSetGeom)(dGeomID g, dGeomID obj);
//dGeomID         (ODE_API *dGeomTransformGetGeom)(dGeomID g);
void            (ODE_API *dGeomTransformSetCleanup)(dGeomID g, int mode);
//int             (ODE_API *dGeomTransformGetCleanup)(dGeomID g);
//void            (ODE_API *dGeomTransformSetInfo)(dGeomID g, int mode);
//int             (ODE_API *dGeomTransformGetInfo)(dGeomID g);

enum { TRIMESH_FACE_NORMALS };
typedef int dTriCallback(dGeomID TriMesh, dGeomID RefObject, int TriangleIndex);
typedef void dTriArrayCallback(dGeomID TriMesh, dGeomID RefObject, const int* TriIndices, int TriCount);
typedef int dTriRayCallback(dGeomID TriMesh, dGeomID Ray, int TriangleIndex, dReal u, dReal v);
typedef int dTriTriMergeCallback(dGeomID TriMesh, int FirstTriangleIndex, int SecondTriangleIndex);

dTriMeshDataID  (ODE_API *dGeomTriMeshDataCreate)(void);
void            (ODE_API *dGeomTriMeshDataDestroy)(dTriMeshDataID g);
//void            (ODE_API *dGeomTriMeshDataSet)(dTriMeshDataID g, int data_id, void* in_data);
//void*           (ODE_API *dGeomTriMeshDataGet)(dTriMeshDataID g, int data_id);
//void            (*dGeomTriMeshSetLastTransform)( (ODE_API *dGeomID g, dMatrix4 last_trans );
//dReal*          (*dGeomTriMeshGetLastTransform)( (ODE_API *dGeomID g );
void            (ODE_API *dGeomTriMeshDataBuildSingle)(dTriMeshDataID g, const void* Vertices, int VertexStride, int VertexCount,  const void* Indices, int IndexCount, int TriStride);
//void            (ODE_API *dGeomTriMeshDataBuildSingle1)(dTriMeshDataID g, const void* Vertices, int VertexStride, int VertexCount,  const void* Indices, int IndexCount, int TriStride, const void* Normals);
//void            (ODE_API *dGeomTriMeshDataBuildDouble)(dTriMeshDataID g,  const void* Vertices,  int VertexStride, int VertexCount,  const void* Indices, int IndexCount, int TriStride);
//void            (ODE_API *dGeomTriMeshDataBuildDouble1)(dTriMeshDataID g,  const void* Vertices,  int VertexStride, int VertexCount,  const void* Indices, int IndexCount, int TriStride, const void* Normals);
//void            (ODE_API *dGeomTriMeshDataBuildSimple)(dTriMeshDataID g, const dReal* Vertices, int VertexCount, const dTriIndex* Indices, int IndexCount);
//void            (ODE_API *dGeomTriMeshDataBuildSimple1)(dTriMeshDataID g, const dReal* Vertices, int VertexCount, const dTriIndex* Indices, int IndexCount, const int* Normals);
//void            (ODE_API *dGeomTriMeshDataPreprocess)(dTriMeshDataID g);
//void            (ODE_API *dGeomTriMeshDataGetBuffer)(dTriMeshDataID g, unsigned char** buf, int* bufLen);
//void            (ODE_API *dGeomTriMeshDataSetBuffer)(dTriMeshDataID g, unsigned char* buf);
//void            (ODE_API *dGeomTriMeshSetCallback)(dGeomID g, dTriCallback* Callback);
//dTriCallback*   (ODE_API *dGeomTriMeshGetCallback)(dGeomID g);
//void            (ODE_API *dGeomTriMeshSetArrayCallback)(dGeomID g, dTriArrayCallback* ArrayCallback);
//dTriArrayCallback* (ODE_API *dGeomTriMeshGetArrayCallback)(dGeomID g);
//void            (ODE_API *dGeomTriMeshSetRayCallback)(dGeomID g, dTriRayCallback* Callback);
//dTriRayCallback* (ODE_API *dGeomTriMeshGetRayCallback)(dGeomID g);
//void            (ODE_API *dGeomTriMeshSetTriMergeCallback)(dGeomID g, dTriTriMergeCallback* Callback);
//dTriTriMergeCallback* (ODE_API *dGeomTriMeshGetTriMergeCallback)(dGeomID g);
dGeomID         (ODE_API *dCreateTriMesh)(dSpaceID space, dTriMeshDataID Data, dTriCallback* Callback, dTriArrayCallback* ArrayCallback, dTriRayCallback* RayCallback);
//void            (ODE_API *dGeomTriMeshSetData)(dGeomID g, dTriMeshDataID Data);
//dTriMeshDataID  (ODE_API *dGeomTriMeshGetData)(dGeomID g);
//void            (ODE_API *dGeomTriMeshEnableTC)(dGeomID g, int geomClass, int enable);
//int             (ODE_API *dGeomTriMeshIsTCEnabled)(dGeomID g, int geomClass);
//void            (ODE_API *dGeomTriMeshClearTCCache)(dGeomID g);
//dTriMeshDataID  (ODE_API *dGeomTriMeshGetTriMeshDataID)(dGeomID g);
//void            (ODE_API *dGeomTriMeshGetTriangle)(dGeomID g, int Index, dVector3* v0, dVector3* v1, dVector3* v2);
//void            (ODE_API *dGeomTriMeshGetPoint)(dGeomID g, int Index, dReal u, dReal v, dVector3 Out);
//int             (ODE_API *dGeomTriMeshGetTriangleCount )(dGeomID g);
//void            (ODE_API *dGeomTriMeshDataUpdate)(dTriMeshDataID g);

static dllfunction_t odefuncs[] =
{
	{"dGetConfiguration",							(void **) &dGetConfiguration},
	{"dCheckConfiguration",							(void **) &dCheckConfiguration},
	{"dInitODE",									(void **) &dInitODE},
//	{"dInitODE2",									(void **) &dInitODE2},
	{"dAllocateODEDataForThread",					(void **) &dAllocateODEDataForThread},
	{"dCleanupODEAllDataForThread",					(void **) &dCleanupODEAllDataForThread},
	{"dCloseODE",									(void **) &dCloseODE},
//	{"dMassCheck",									(void **) &dMassCheck},
//	{"dMassSetZero",								(void **) &dMassSetZero},
//	{"dMassSetParameters",							(void **) &dMassSetParameters},
//	{"dMassSetSphere",								(void **) &dMassSetSphere},
	{"dMassSetSphereTotal",							(void **) &dMassSetSphereTotal},
//	{"dMassSetCapsule",								(void **) &dMassSetCapsule},
	{"dMassSetCapsuleTotal",						(void **) &dMassSetCapsuleTotal},
//	{"dMassSetCylinder",							(void **) &dMassSetCylinder},
//	{"dMassSetCylinderTotal",						(void **) &dMassSetCylinderTotal},
//	{"dMassSetBox",									(void **) &dMassSetBox},
	{"dMassSetBoxTotal",							(void **) &dMassSetBoxTotal},
//	{"dMassSetTrimesh",								(void **) &dMassSetTrimesh},
//	{"dMassSetTrimeshTotal",						(void **) &dMassSetTrimeshTotal},
//	{"dMassAdjust",									(void **) &dMassAdjust},
//	{"dMassTranslate",								(void **) &dMassTranslate},
//	{"dMassRotate",									(void **) &dMassRotate},
//	{"dMassAdd",									(void **) &dMassAdd},

	{"dWorldCreate",								(void **) &dWorldCreate},
	{"dWorldDestroy",								(void **) &dWorldDestroy},
	{"dWorldSetGravity",							(void **) &dWorldSetGravity},
//	{"dWorldGetGravity",							(void **) &dWorldGetGravity},
//	{"dWorldSetERP",								(void **) &dWorldSetERP},
//	{"dWorldGetERP",								(void **) &dWorldGetERP},
//	{"dWorldSetCFM",								(void **) &dWorldSetCFM},
//	{"dWorldGetCFM",								(void **) &dWorldGetCFM},
	{"dWorldStep",									(void **) &dWorldStep},
//	{"dWorldImpulseToForce",						(void **) &dWorldImpulseToForce},
	{"dWorldQuickStep",								(void **) &dWorldQuickStep},
	{"dWorldSetQuickStepNumIterations",				(void **) &dWorldSetQuickStepNumIterations},
//	{"dWorldGetQuickStepNumIterations",				(void **) &dWorldGetQuickStepNumIterations},
//	{"dWorldSetQuickStepW",							(void **) &dWorldSetQuickStepW},
//	{"dWorldGetQuickStepW",							(void **) &dWorldGetQuickStepW},
//	{"dWorldSetContactMaxCorrectingVel",			(void **) &dWorldSetContactMaxCorrectingVel},
//	{"dWorldGetContactMaxCorrectingVel",			(void **) &dWorldGetContactMaxCorrectingVel},
	{"dWorldSetContactSurfaceLayer",				(void **) &dWorldSetContactSurfaceLayer},
//	{"dWorldGetContactSurfaceLayer",				(void **) &dWorldGetContactSurfaceLayer},
	{"dWorldStepFast1",								(void **) &dWorldStepFast1},
//	{"dWorldSetAutoEnableDepthSF1",					(void **) &dWorldSetAutoEnableDepthSF1},
//	{"dWorldGetAutoEnableDepthSF1",					(void **) &dWorldGetAutoEnableDepthSF1},
//	{"dWorldGetAutoDisableLinearThreshold",			(void **) &dWorldGetAutoDisableLinearThreshold},
//	{"dWorldSetAutoDisableLinearThreshold",			(void **) &dWorldSetAutoDisableLinearThreshold},
//	{"dWorldGetAutoDisableAngularThreshold",		(void **) &dWorldGetAutoDisableAngularThreshold},
//	{"dWorldSetAutoDisableAngularThreshold",		(void **) &dWorldSetAutoDisableAngularThreshold},
//	{"dWorldGetAutoDisableLinearAverageThreshold",	(void **) &dWorldGetAutoDisableLinearAverageThreshold},
//	{"dWorldSetAutoDisableLinearAverageThreshold",	(void **) &dWorldSetAutoDisableLinearAverageThreshold},
//	{"dWorldGetAutoDisableAngularAverageThreshold",	(void **) &dWorldGetAutoDisableAngularAverageThreshold},
//	{"dWorldSetAutoDisableAngularAverageThreshold",	(void **) &dWorldSetAutoDisableAngularAverageThreshold},
//	{"dWorldGetAutoDisableAverageSamplesCount",		(void **) &dWorldGetAutoDisableAverageSamplesCount},
//	{"dWorldSetAutoDisableAverageSamplesCount",		(void **) &dWorldSetAutoDisableAverageSamplesCount},
//	{"dWorldGetAutoDisableSteps",					(void **) &dWorldGetAutoDisableSteps},
//	{"dWorldSetAutoDisableSteps",					(void **) &dWorldSetAutoDisableSteps},
//	{"dWorldGetAutoDisableTime",					(void **) &dWorldGetAutoDisableTime},
//	{"dWorldSetAutoDisableTime",					(void **) &dWorldSetAutoDisableTime},
//	{"dWorldGetAutoDisableFlag",					(void **) &dWorldGetAutoDisableFlag},
//	{"dWorldSetAutoDisableFlag",					(void **) &dWorldSetAutoDisableFlag},
//	{"dWorldGetLinearDampingThreshold",				(void **) &dWorldGetLinearDampingThreshold},
//	{"dWorldSetLinearDampingThreshold",				(void **) &dWorldSetLinearDampingThreshold},
//	{"dWorldGetAngularDampingThreshold",			(void **) &dWorldGetAngularDampingThreshold},
//	{"dWorldSetAngularDampingThreshold",			(void **) &dWorldSetAngularDampingThreshold},
//	{"dWorldGetLinearDamping",						(void **) &dWorldGetLinearDamping},
//	{"dWorldSetLinearDamping",						(void **) &dWorldSetLinearDamping},
//	{"dWorldGetAngularDamping",						(void **) &dWorldGetAngularDamping},
//	{"dWorldSetAngularDamping",						(void **) &dWorldSetAngularDamping},
//	{"dWorldSetDamping",							(void **) &dWorldSetDamping},
//	{"dWorldGetMaxAngularSpeed",					(void **) &dWorldGetMaxAngularSpeed},
//	{"dWorldSetMaxAngularSpeed",					(void **) &dWorldSetMaxAngularSpeed},
//	{"dBodyGetAutoDisableLinearThreshold",			(void **) &dBodyGetAutoDisableLinearThreshold},
//	{"dBodySetAutoDisableLinearThreshold",			(void **) &dBodySetAutoDisableLinearThreshold},
//	{"dBodyGetAutoDisableAngularThreshold",			(void **) &dBodyGetAutoDisableAngularThreshold},
//	{"dBodySetAutoDisableAngularThreshold",			(void **) &dBodySetAutoDisableAngularThreshold},
//	{"dBodyGetAutoDisableAverageSamplesCount",		(void **) &dBodyGetAutoDisableAverageSamplesCount},
//	{"dBodySetAutoDisableAverageSamplesCount",		(void **) &dBodySetAutoDisableAverageSamplesCount},
//	{"dBodyGetAutoDisableSteps",					(void **) &dBodyGetAutoDisableSteps},
//	{"dBodySetAutoDisableSteps",					(void **) &dBodySetAutoDisableSteps},
//	{"dBodyGetAutoDisableTime",						(void **) &dBodyGetAutoDisableTime},
//	{"dBodySetAutoDisableTime",						(void **) &dBodySetAutoDisableTime},
//	{"dBodyGetAutoDisableFlag",						(void **) &dBodyGetAutoDisableFlag},
//	{"dBodySetAutoDisableFlag",						(void **) &dBodySetAutoDisableFlag},
//	{"dBodySetAutoDisableDefaults",					(void **) &dBodySetAutoDisableDefaults},
//	{"dBodyGetWorld",								(void **) &dBodyGetWorld},
	{"dBodyCreate",									(void **) &dBodyCreate},
	{"dBodyDestroy",								(void **) &dBodyDestroy},
	{"dBodySetData",								(void **) &dBodySetData},
//	{"dBodyGetData",								(void **) &dBodyGetData},
	{"dBodySetPosition",							(void **) &dBodySetPosition},
	{"dBodySetRotation",							(void **) &dBodySetRotation},
//	{"dBodySetQuaternion",							(void **) &dBodySetQuaternion},
	{"dBodySetLinearVel",							(void **) &dBodySetLinearVel},
	{"dBodySetAngularVel",							(void **) &dBodySetAngularVel},
	{"dBodyGetPosition",							(void **) &dBodyGetPosition},
//	{"dBodyCopyPosition",							(void **) &dBodyCopyPosition},
	{"dBodyGetRotation",							(void **) &dBodyGetRotation},
//	{"dBodyCopyRotation",							(void **) &dBodyCopyRotation},
//	{"dBodyGetQuaternion",							(void **) &dBodyGetQuaternion},
//	{"dBodyCopyQuaternion",							(void **) &dBodyCopyQuaternion},
	{"dBodyGetLinearVel",							(void **) &dBodyGetLinearVel},
	{"dBodyGetAngularVel",							(void **) &dBodyGetAngularVel},
	{"dBodySetMass",								(void **) &dBodySetMass},
//	{"dBodyGetMass",								(void **) &dBodyGetMass},
//	{"dBodyAddForce",								(void **) &dBodyAddForce},
//	{"dBodyAddTorque",								(void **) &dBodyAddTorque},
//	{"dBodyAddRelForce",							(void **) &dBodyAddRelForce},
//	{"dBodyAddRelTorque",							(void **) &dBodyAddRelTorque},
//	{"dBodyAddForceAtPos",							(void **) &dBodyAddForceAtPos},
//	{"dBodyAddForceAtRelPos",						(void **) &dBodyAddForceAtRelPos},
//	{"dBodyAddRelForceAtPos",						(void **) &dBodyAddRelForceAtPos},
//	{"dBodyAddRelForceAtRelPos",					(void **) &dBodyAddRelForceAtRelPos},
//	{"dBodyGetForce",								(void **) &dBodyGetForce},
//	{"dBodyGetTorque",								(void **) &dBodyGetTorque},
//	{"dBodySetForce",								(void **) &dBodySetForce},
//	{"dBodySetTorque",								(void **) &dBodySetTorque},
//	{"dBodyGetRelPointPos",							(void **) &dBodyGetRelPointPos},
//	{"dBodyGetRelPointVel",							(void **) &dBodyGetRelPointVel},
//	{"dBodyGetPointVel",							(void **) &dBodyGetPointVel},
//	{"dBodyGetPosRelPoint",							(void **) &dBodyGetPosRelPoint},
//	{"dBodyVectorToWorld",							(void **) &dBodyVectorToWorld},
//	{"dBodyVectorFromWorld",						(void **) &dBodyVectorFromWorld},
//	{"dBodySetFiniteRotationMode",					(void **) &dBodySetFiniteRotationMode},
//	{"dBodySetFiniteRotationAxis",					(void **) &dBodySetFiniteRotationAxis},
//	{"dBodyGetFiniteRotationMode",					(void **) &dBodyGetFiniteRotationMode},
//	{"dBodyGetFiniteRotationAxis",					(void **) &dBodyGetFiniteRotationAxis},
//	{"dBodyGetNumJoints",							(void **) &dBodyGetNumJoints},
//	{"dBodyGetJoint",								(void **) &dBodyGetJoint},
//	{"dBodySetDynamic",								(void **) &dBodySetDynamic},
//	{"dBodySetKinematic",							(void **) &dBodySetKinematic},
//	{"dBodyIsKinematic",							(void **) &dBodyIsKinematic},
//	{"dBodyEnable",									(void **) &dBodyEnable},
//	{"dBodyDisable",								(void **) &dBodyDisable},
//	{"dBodyIsEnabled",								(void **) &dBodyIsEnabled},
//	{"dBodySetGravityMode",							(void **) &dBodySetGravityMode},
//	{"dBodyGetGravityMode",							(void **) &dBodyGetGravityMode},
//	{"dBodySetMovedCallback",						(void **) &dBodySetMovedCallback},
//	{"dBodyGetFirstGeom",							(void **) &dBodyGetFirstGeom},
//	{"dBodyGetNextGeom",							(void **) &dBodyGetNextGeom},
//	{"dBodySetDampingDefaults",						(void **) &dBodySetDampingDefaults},
//	{"dBodyGetLinearDamping",						(void **) &dBodyGetLinearDamping},
//	{"dBodySetLinearDamping",						(void **) &dBodySetLinearDamping},
//	{"dBodyGetAngularDamping",						(void **) &dBodyGetAngularDamping},
//	{"dBodySetAngularDamping",						(void **) &dBodySetAngularDamping},
//	{"dBodySetDamping",								(void **) &dBodySetDamping},
//	{"dBodyGetLinearDampingThreshold",				(void **) &dBodyGetLinearDampingThreshold},
//	{"dBodySetLinearDampingThreshold",				(void **) &dBodySetLinearDampingThreshold},
//	{"dBodyGetAngularDampingThreshold",				(void **) &dBodyGetAngularDampingThreshold},
//	{"dBodySetAngularDampingThreshold",				(void **) &dBodySetAngularDampingThreshold},
//	{"dBodyGetMaxAngularSpeed",						(void **) &dBodyGetMaxAngularSpeed},
//	{"dBodySetMaxAngularSpeed",						(void **) &dBodySetMaxAngularSpeed},
//	{"dBodyGetGyroscopicMode",						(void **) &dBodyGetGyroscopicMode},
//	{"dBodySetGyroscopicMode",						(void **) &dBodySetGyroscopicMode},
//	{"dJointCreateBall",							(void **) &dJointCreateBall},
//	{"dJointCreateHinge",							(void **) &dJointCreateHinge},
//	{"dJointCreateSlider",							(void **) &dJointCreateSlider},
	{"dJointCreateContact",							(void **) &dJointCreateContact},
//	{"dJointCreateHinge2",							(void **) &dJointCreateHinge2},
//	{"dJointCreateUniversal",						(void **) &dJointCreateUniversal},
//	{"dJointCreatePR",								(void **) &dJointCreatePR},
//	{"dJointCreatePU",								(void **) &dJointCreatePU},
//	{"dJointCreatePiston",							(void **) &dJointCreatePiston},
//	{"dJointCreateFixed",							(void **) &dJointCreateFixed},
//	{"dJointCreateNull",							(void **) &dJointCreateNull},
//	{"dJointCreateAMotor",							(void **) &dJointCreateAMotor},
//	{"dJointCreateLMotor",							(void **) &dJointCreateLMotor},
//	{"dJointCreatePlane2D",							(void **) &dJointCreatePlane2D},
//	{"dJointDestroy",								(void **) &dJointDestroy},
	{"dJointGroupCreate",							(void **) &dJointGroupCreate},
	{"dJointGroupDestroy",							(void **) &dJointGroupDestroy},
	{"dJointGroupEmpty",							(void **) &dJointGroupEmpty},
//	{"dJointGetNumBodies",							(void **) &dJointGetNumBodies},
	{"dJointAttach",								(void **) &dJointAttach},
//	{"dJointEnable",								(void **) &dJointEnable},
//	{"dJointDisable",								(void **) &dJointDisable},
//	{"dJointIsEnabled",								(void **) &dJointIsEnabled},
//	{"dJointSetData",								(void **) &dJointSetData},
//	{"dJointGetData",								(void **) &dJointGetData},
//	{"dJointGetType",								(void **) &dJointGetType},
//	{"dJointGetBody",								(void **) &dJointGetBody},
//	{"dJointSetFeedback",							(void **) &dJointSetFeedback},
//	{"dJointGetFeedback",							(void **) &dJointGetFeedback},
//	{"dJointSetBallAnchor",							(void **) &dJointSetBallAnchor},
//	{"dJointSetBallAnchor2",						(void **) &dJointSetBallAnchor2},
//	{"dJointSetBallParam",							(void **) &dJointSetBallParam},
//	{"dJointSetHingeAnchor",						(void **) &dJointSetHingeAnchor},
//	{"dJointSetHingeAnchorDelta",					(void **) &dJointSetHingeAnchorDelta},
//	{"dJointSetHingeAxis",							(void **) &dJointSetHingeAxis},
//	{"dJointSetHingeAxisOffset",					(void **) &dJointSetHingeAxisOffset},
//	{"dJointSetHingeParam",							(void **) &dJointSetHingeParam},
//	{"dJointAddHingeTorque",						(void **) &dJointAddHingeTorque},
//	{"dJointSetSliderAxis",							(void **) &dJointSetSliderAxis},
//	{"dJointSetSliderAxisDelta",					(void **) &dJointSetSliderAxisDelta},
//	{"dJointSetSliderParam",						(void **) &dJointSetSliderParam},
//	{"dJointAddSliderForce",						(void **) &dJointAddSliderForce},
//	{"dJointSetHinge2Anchor",						(void **) &dJointSetHinge2Anchor},
//	{"dJointSetHinge2Axis1",						(void **) &dJointSetHinge2Axis1},
//	{"dJointSetHinge2Axis2",						(void **) &dJointSetHinge2Axis2},
//	{"dJointSetHinge2Param",						(void **) &dJointSetHinge2Param},
//	{"dJointAddHinge2Torques",						(void **) &dJointAddHinge2Torques},
//	{"dJointSetUniversalAnchor",					(void **) &dJointSetUniversalAnchor},
//	{"dJointSetUniversalAxis1",						(void **) &dJointSetUniversalAxis1},
//	{"dJointSetUniversalAxis1Offset",				(void **) &dJointSetUniversalAxis1Offset},
//	{"dJointSetUniversalAxis2",						(void **) &dJointSetUniversalAxis2},
//	{"dJointSetUniversalAxis2Offset",				(void **) &dJointSetUniversalAxis2Offset},
//	{"dJointSetUniversalParam",						(void **) &dJointSetUniversalParam},
//	{"dJointAddUniversalTorques",					(void **) &dJointAddUniversalTorques},
//	{"dJointSetPRAnchor",							(void **) &dJointSetPRAnchor},
//	{"dJointSetPRAxis1",							(void **) &dJointSetPRAxis1},
//	{"dJointSetPRAxis2",							(void **) &dJointSetPRAxis2},
//	{"dJointSetPRParam",							(void **) &dJointSetPRParam},
//	{"dJointAddPRTorque",							(void **) &dJointAddPRTorque},
//	{"dJointSetPUAnchor",							(void **) &dJointSetPUAnchor},
//	{"dJointSetPUAnchorOffset",						(void **) &dJointSetPUAnchorOffset},
//	{"dJointSetPUAxis1",							(void **) &dJointSetPUAxis1},
//	{"dJointSetPUAxis2",							(void **) &dJointSetPUAxis2},
//	{"dJointSetPUAxis3",							(void **) &dJointSetPUAxis3},
//	{"dJointSetPUAxisP",							(void **) &dJointSetPUAxisP},
//	{"dJointSetPUParam",							(void **) &dJointSetPUParam},
//	{"dJointAddPUTorque",							(void **) &dJointAddPUTorque},
//	{"dJointSetPistonAnchor",						(void **) &dJointSetPistonAnchor},
//	{"dJointSetPistonAnchorOffset",					(void **) &dJointSetPistonAnchorOffset},
//	{"dJointSetPistonParam",						(void **) &dJointSetPistonParam},
//	{"dJointAddPistonForce",						(void **) &dJointAddPistonForce},
//	{"dJointSetFixed",								(void **) &dJointSetFixed},
//	{"dJointSetFixedParam",							(void **) &dJointSetFixedParam},
//	{"dJointSetAMotorNumAxes",						(void **) &dJointSetAMotorNumAxes},
//	{"dJointSetAMotorAxis",							(void **) &dJointSetAMotorAxis},
//	{"dJointSetAMotorAngle",						(void **) &dJointSetAMotorAngle},
//	{"dJointSetAMotorParam",						(void **) &dJointSetAMotorParam},
//	{"dJointSetAMotorMode",							(void **) &dJointSetAMotorMode},
//	{"dJointAddAMotorTorques",						(void **) &dJointAddAMotorTorques},
//	{"dJointSetLMotorNumAxes",						(void **) &dJointSetLMotorNumAxes},
//	{"dJointSetLMotorAxis",							(void **) &dJointSetLMotorAxis},
//	{"dJointSetLMotorParam",						(void **) &dJointSetLMotorParam},
//	{"dJointSetPlane2DXParam",						(void **) &dJointSetPlane2DXParam},
//	{"dJointSetPlane2DYParam",						(void **) &dJointSetPlane2DYParam},
//	{"dJointSetPlane2DAngleParam",					(void **) &dJointSetPlane2DAngleParam},
//	{"dJointGetBallAnchor",							(void **) &dJointGetBallAnchor},
//	{"dJointGetBallAnchor2",						(void **) &dJointGetBallAnchor2},
//	{"dJointGetBallParam",							(void **) &dJointGetBallParam},
//	{"dJointGetHingeAnchor",						(void **) &dJointGetHingeAnchor},
//	{"dJointGetHingeAnchor2",						(void **) &dJointGetHingeAnchor2},
//	{"dJointGetHingeAxis",							(void **) &dJointGetHingeAxis},
//	{"dJointGetHingeParam",							(void **) &dJointGetHingeParam},
//	{"dJointGetHingeAngle",							(void **) &dJointGetHingeAngle},
//	{"dJointGetHingeAngleRate",						(void **) &dJointGetHingeAngleRate},
//	{"dJointGetSliderPosition",						(void **) &dJointGetSliderPosition},
//	{"dJointGetSliderPositionRate",					(void **) &dJointGetSliderPositionRate},
//	{"dJointGetSliderAxis",							(void **) &dJointGetSliderAxis},
//	{"dJointGetSliderParam",						(void **) &dJointGetSliderParam},
//	{"dJointGetHinge2Anchor",						(void **) &dJointGetHinge2Anchor},
//	{"dJointGetHinge2Anchor2",						(void **) &dJointGetHinge2Anchor2},
//	{"dJointGetHinge2Axis1",						(void **) &dJointGetHinge2Axis1},
//	{"dJointGetHinge2Axis2",						(void **) &dJointGetHinge2Axis2},
//	{"dJointGetHinge2Param",						(void **) &dJointGetHinge2Param},
//	{"dJointGetHinge2Angle1",						(void **) &dJointGetHinge2Angle1},
//	{"dJointGetHinge2Angle1Rate",					(void **) &dJointGetHinge2Angle1Rate},
//	{"dJointGetHinge2Angle2Rate",					(void **) &dJointGetHinge2Angle2Rate},
//	{"dJointGetUniversalAnchor",					(void **) &dJointGetUniversalAnchor},
//	{"dJointGetUniversalAnchor2",					(void **) &dJointGetUniversalAnchor2},
//	{"dJointGetUniversalAxis1",						(void **) &dJointGetUniversalAxis1},
//	{"dJointGetUniversalAxis2",						(void **) &dJointGetUniversalAxis2},
//	{"dJointGetUniversalParam",						(void **) &dJointGetUniversalParam},
//	{"dJointGetUniversalAngles",					(void **) &dJointGetUniversalAngles},
//	{"dJointGetUniversalAngle1",					(void **) &dJointGetUniversalAngle1},
//	{"dJointGetUniversalAngle2",					(void **) &dJointGetUniversalAngle2},
//	{"dJointGetUniversalAngle1Rate",				(void **) &dJointGetUniversalAngle1Rate},
//	{"dJointGetUniversalAngle2Rate",				(void **) &dJointGetUniversalAngle2Rate},
//	{"dJointGetPRAnchor",							(void **) &dJointGetPRAnchor},
//	{"dJointGetPRPosition",							(void **) &dJointGetPRPosition},
//	{"dJointGetPRPositionRate",						(void **) &dJointGetPRPositionRate},
//	{"dJointGetPRAngle",							(void **) &dJointGetPRAngle},
//	{"dJointGetPRAngleRate",						(void **) &dJointGetPRAngleRate},
//	{"dJointGetPRAxis1",							(void **) &dJointGetPRAxis1},
//	{"dJointGetPRAxis2",							(void **) &dJointGetPRAxis2},
//	{"dJointGetPRParam",							(void **) &dJointGetPRParam},
//	{"dJointGetPUAnchor",							(void **) &dJointGetPUAnchor},
//	{"dJointGetPUPosition",							(void **) &dJointGetPUPosition},
//	{"dJointGetPUPositionRate",						(void **) &dJointGetPUPositionRate},
//	{"dJointGetPUAxis1",							(void **) &dJointGetPUAxis1},
//	{"dJointGetPUAxis2",							(void **) &dJointGetPUAxis2},
//	{"dJointGetPUAxis3",							(void **) &dJointGetPUAxis3},
//	{"dJointGetPUAxisP",							(void **) &dJointGetPUAxisP},
//	{"dJointGetPUAngles",							(void **) &dJointGetPUAngles},
//	{"dJointGetPUAngle1",							(void **) &dJointGetPUAngle1},
//	{"dJointGetPUAngle1Rate",						(void **) &dJointGetPUAngle1Rate},
//	{"dJointGetPUAngle2",							(void **) &dJointGetPUAngle2},
//	{"dJointGetPUAngle2Rate",						(void **) &dJointGetPUAngle2Rate},
//	{"dJointGetPUParam",							(void **) &dJointGetPUParam},
//	{"dJointGetPistonPosition",						(void **) &dJointGetPistonPosition},
//	{"dJointGetPistonPositionRate",					(void **) &dJointGetPistonPositionRate},
//	{"dJointGetPistonAngle",						(void **) &dJointGetPistonAngle},
//	{"dJointGetPistonAngleRate",					(void **) &dJointGetPistonAngleRate},
//	{"dJointGetPistonAnchor",						(void **) &dJointGetPistonAnchor},
//	{"dJointGetPistonAnchor2",						(void **) &dJointGetPistonAnchor2},
//	{"dJointGetPistonAxis",							(void **) &dJointGetPistonAxis},
//	{"dJointGetPistonParam",						(void **) &dJointGetPistonParam},
//	{"dJointGetAMotorNumAxes",						(void **) &dJointGetAMotorNumAxes},
//	{"dJointGetAMotorAxis",							(void **) &dJointGetAMotorAxis},
//	{"dJointGetAMotorAxisRel",						(void **) &dJointGetAMotorAxisRel},
//	{"dJointGetAMotorAngle",						(void **) &dJointGetAMotorAngle},
//	{"dJointGetAMotorAngleRate",					(void **) &dJointGetAMotorAngleRate},
//	{"dJointGetAMotorParam",						(void **) &dJointGetAMotorParam},
//	{"dJointGetAMotorMode",							(void **) &dJointGetAMotorMode},
//	{"dJointGetLMotorNumAxes",						(void **) &dJointGetLMotorNumAxes},
//	{"dJointGetLMotorAxis",							(void **) &dJointGetLMotorAxis},
//	{"dJointGetLMotorParam",						(void **) &dJointGetLMotorParam},
//	{"dJointGetFixedParam",							(void **) &dJointGetFixedParam},
//	{"dConnectingJoint",							(void **) &dConnectingJoint},
//	{"dConnectingJointList",						(void **) &dConnectingJointList},
	{"dAreConnected",								(void **) &dAreConnected},
	{"dAreConnectedExcluding",						(void **) &dAreConnectedExcluding},
	{"dSimpleSpaceCreate",							(void **) &dSimpleSpaceCreate},
	{"dHashSpaceCreate",							(void **) &dHashSpaceCreate},
	{"dQuadTreeSpaceCreate",						(void **) &dQuadTreeSpaceCreate},
	{"dSweepAndPruneSpaceCreate",					(void **) &dSweepAndPruneSpaceCreate},
	{"dSpaceDestroy",								(void **) &dSpaceDestroy},
//	{"dHashSpaceSetLevels",							(void **) &dHashSpaceSetLevels},
//	{"dHashSpaceGetLevels",							(void **) &dHashSpaceGetLevels},
//	{"dSpaceSetCleanup",							(void **) &dSpaceSetCleanup},
//	{"dSpaceGetCleanup",							(void **) &dSpaceGetCleanup},
//	{"dSpaceSetSublevel",							(void **) &dSpaceSetSublevel},
//	{"dSpaceGetSublevel",							(void **) &dSpaceGetSublevel},
//	{"dSpaceSetManualCleanup",						(void **) &dSpaceSetManualCleanup},
//	{"dSpaceGetManualCleanup",						(void **) &dSpaceGetManualCleanup},
//	{"dSpaceAdd",									(void **) &dSpaceAdd},
//	{"dSpaceRemove",								(void **) &dSpaceRemove},
//	{"dSpaceQuery",									(void **) &dSpaceQuery},
//	{"dSpaceClean",									(void **) &dSpaceClean},
//	{"dSpaceGetNumGeoms",							(void **) &dSpaceGetNumGeoms},
//	{"dSpaceGetGeom",								(void **) &dSpaceGetGeom},
//	{"dSpaceGetClass",								(void **) &dSpaceGetClass},
	{"dGeomDestroy",								(void **) &dGeomDestroy},
//	{"dGeomSetData",								(void **) &dGeomSetData},
//	{"dGeomGetData",								(void **) &dGeomGetData},
	{"dGeomSetBody",								(void **) &dGeomSetBody},
	{"dGeomGetBody",								(void **) &dGeomGetBody},
//	{"dGeomSetPosition",							(void **) &dGeomSetPosition},
	{"dGeomSetRotation",							(void **) &dGeomSetRotation},
//	{"dGeomSetQuaternion",							(void **) &dGeomSetQuaternion},
//	{"dGeomGetPosition",							(void **) &dGeomGetPosition},
//	{"dGeomCopyPosition",							(void **) &dGeomCopyPosition},
//	{"dGeomGetRotation",							(void **) &dGeomGetRotation},
//	{"dGeomCopyRotation",							(void **) &dGeomCopyRotation},
//	{"dGeomGetQuaternion",							(void **) &dGeomGetQuaternion},
//	{"dGeomGetAABB",								(void **) &dGeomGetAABB},
	{"dGeomIsSpace",								(void **) &dGeomIsSpace},
//	{"dGeomGetSpace",								(void **) &dGeomGetSpace},
//	{"dGeomGetClass",								(void **) &dGeomGetClass},
//	{"dGeomSetCategoryBits",						(void **) &dGeomSetCategoryBits},
//	{"dGeomSetCollideBits",							(void **) &dGeomSetCollideBits},
//	{"dGeomGetCategoryBits",						(void **) &dGeomGetCategoryBits},
//	{"dGeomGetCollideBits",							(void **) &dGeomGetCollideBits},
//	{"dGeomEnable",									(void **) &dGeomEnable},
//	{"dGeomDisable",								(void **) &dGeomDisable},
//	{"dGeomIsEnabled",								(void **) &dGeomIsEnabled},
//	{"dGeomSetOffsetPosition",						(void **) &dGeomSetOffsetPosition},
//	{"dGeomSetOffsetRotation",						(void **) &dGeomSetOffsetRotation},
//	{"dGeomSetOffsetQuaternion",					(void **) &dGeomSetOffsetQuaternion},
//	{"dGeomSetOffsetWorldPosition",					(void **) &dGeomSetOffsetWorldPosition},
//	{"dGeomSetOffsetWorldRotation",					(void **) &dGeomSetOffsetWorldRotation},
//	{"dGeomSetOffsetWorldQuaternion",				(void **) &dGeomSetOffsetWorldQuaternion},
//	{"dGeomClearOffset",							(void **) &dGeomClearOffset},
//	{"dGeomIsOffset",								(void **) &dGeomIsOffset},
//	{"dGeomGetOffsetPosition",						(void **) &dGeomGetOffsetPosition},
//	{"dGeomCopyOffsetPosition",						(void **) &dGeomCopyOffsetPosition},
//	{"dGeomGetOffsetRotation",						(void **) &dGeomGetOffsetRotation},
//	{"dGeomCopyOffsetRotation",						(void **) &dGeomCopyOffsetRotation},
//	{"dGeomGetOffsetQuaternion",					(void **) &dGeomGetOffsetQuaternion},
	{"dCollide",									(void **) &dCollide},
	{"dSpaceCollide",								(void **) &dSpaceCollide},
	{"dSpaceCollide2",								(void **) &dSpaceCollide2},
	{"dCreateSphere",								(void **) &dCreateSphere},
//	{"dGeomSphereSetRadius",						(void **) &dGeomSphereSetRadius},
//	{"dGeomSphereGetRadius",						(void **) &dGeomSphereGetRadius},
//	{"dGeomSpherePointDepth",						(void **) &dGeomSpherePointDepth},
//	{"dCreateConvex",								(void **) &dCreateConvex},
//	{"dGeomSetConvex",								(void **) &dGeomSetConvex},
	{"dCreateBox",									(void **) &dCreateBox},
//	{"dGeomBoxSetLengths",							(void **) &dGeomBoxSetLengths},
//	{"dGeomBoxGetLengths",							(void **) &dGeomBoxGetLengths},
//	{"dGeomBoxPointDepth",							(void **) &dGeomBoxPointDepth},
//	{"dGeomBoxPointDepth",							(void **) &dGeomBoxPointDepth},
//	{"dCreatePlane",								(void **) &dCreatePlane},
//	{"dGeomPlaneSetParams",							(void **) &dGeomPlaneSetParams},
//	{"dGeomPlaneGetParams",							(void **) &dGeomPlaneGetParams},
//	{"dGeomPlanePointDepth",						(void **) &dGeomPlanePointDepth},
	{"dCreateCapsule",								(void **) &dCreateCapsule},
//	{"dGeomCapsuleSetParams",						(void **) &dGeomCapsuleSetParams},
//	{"dGeomCapsuleGetParams",						(void **) &dGeomCapsuleGetParams},
//	{"dGeomCapsulePointDepth",						(void **) &dGeomCapsulePointDepth},
//	{"dCreateCylinder",								(void **) &dCreateCylinder},
//	{"dGeomCylinderSetParams",						(void **) &dGeomCylinderSetParams},
//	{"dGeomCylinderGetParams",						(void **) &dGeomCylinderGetParams},
//	{"dCreateRay",									(void **) &dCreateRay},
//	{"dGeomRaySetLength",							(void **) &dGeomRaySetLength},
//	{"dGeomRayGetLength",							(void **) &dGeomRayGetLength},
//	{"dGeomRaySet",									(void **) &dGeomRaySet},
//	{"dGeomRayGet",									(void **) &dGeomRayGet},
	{"dCreateGeomTransform",						(void **) &dCreateGeomTransform},
	{"dGeomTransformSetGeom",						(void **) &dGeomTransformSetGeom},
//	{"dGeomTransformGetGeom",						(void **) &dGeomTransformGetGeom},
	{"dGeomTransformSetCleanup",					(void **) &dGeomTransformSetCleanup},
//	{"dGeomTransformGetCleanup",					(void **) &dGeomTransformGetCleanup},
//	{"dGeomTransformSetInfo",						(void **) &dGeomTransformSetInfo},
//	{"dGeomTransformGetInfo",						(void **) &dGeomTransformGetInfo},
	{"dGeomTriMeshDataCreate",                      (void **) &dGeomTriMeshDataCreate},
	{"dGeomTriMeshDataDestroy",                     (void **) &dGeomTriMeshDataDestroy},
//	{"dGeomTriMeshDataSet",                         (void **) &dGeomTriMeshDataSet},
//	{"dGeomTriMeshDataGet",                         (void **) &dGeomTriMeshDataGet},
//	{"dGeomTriMeshSetLastTransform",                (void **) &dGeomTriMeshSetLastTransform},
//	{"dGeomTriMeshGetLastTransform",                (void **) &dGeomTriMeshGetLastTransform},
	{"dGeomTriMeshDataBuildSingle",                 (void **) &dGeomTriMeshDataBuildSingle},
//	{"dGeomTriMeshDataBuildSingle1",                (void **) &dGeomTriMeshDataBuildSingle1},
//	{"dGeomTriMeshDataBuildDouble",                 (void **) &dGeomTriMeshDataBuildDouble},
//	{"dGeomTriMeshDataBuildDouble1",                (void **) &dGeomTriMeshDataBuildDouble1},
//	{"dGeomTriMeshDataBuildSimple",                 (void **) &dGeomTriMeshDataBuildSimple},
//	{"dGeomTriMeshDataBuildSimple1",                (void **) &dGeomTriMeshDataBuildSimple1},
//	{"dGeomTriMeshDataPreprocess",                  (void **) &dGeomTriMeshDataPreprocess},
//	{"dGeomTriMeshDataGetBuffer",                   (void **) &dGeomTriMeshDataGetBuffer},
//	{"dGeomTriMeshDataSetBuffer",                   (void **) &dGeomTriMeshDataSetBuffer},
//	{"dGeomTriMeshSetCallback",                     (void **) &dGeomTriMeshSetCallback},
//	{"dGeomTriMeshGetCallback",                     (void **) &dGeomTriMeshGetCallback},
//	{"dGeomTriMeshSetArrayCallback",                (void **) &dGeomTriMeshSetArrayCallback},
//	{"dGeomTriMeshGetArrayCallback",                (void **) &dGeomTriMeshGetArrayCallback},
//	{"dGeomTriMeshSetRayCallback",                  (void **) &dGeomTriMeshSetRayCallback},
//	{"dGeomTriMeshGetRayCallback",                  (void **) &dGeomTriMeshGetRayCallback},
//	{"dGeomTriMeshSetTriMergeCallback",             (void **) &dGeomTriMeshSetTriMergeCallback},
//	{"dGeomTriMeshGetTriMergeCallback",             (void **) &dGeomTriMeshGetTriMergeCallback},
	{"dCreateTriMesh",                              (void **) &dCreateTriMesh},
//	{"dGeomTriMeshSetData",                         (void **) &dGeomTriMeshSetData},
//	{"dGeomTriMeshGetData",                         (void **) &dGeomTriMeshGetData},
//	{"dGeomTriMeshEnableTC",                        (void **) &dGeomTriMeshEnableTC},
//	{"dGeomTriMeshIsTCEnabled",                     (void **) &dGeomTriMeshIsTCEnabled},
//	{"dGeomTriMeshClearTCCache",                    (void **) &dGeomTriMeshClearTCCache},
//	{"dGeomTriMeshGetTriMeshDataID",                (void **) &dGeomTriMeshGetTriMeshDataID},
//	{"dGeomTriMeshGetTriangle",                     (void **) &dGeomTriMeshGetTriangle},
//	{"dGeomTriMeshGetPoint",                        (void **) &dGeomTriMeshGetPoint},
//	{"dGeomTriMeshGetTriangleCount",                (void **) &dGeomTriMeshGetTriangleCount},
//	{"dGeomTriMeshDataUpdate",                      (void **) &dGeomTriMeshDataUpdate},
	{NULL, NULL}
};

// Handle for ODE DLL
dllhandle_t ode_dll = NULL;
#endif
#endif

static void World_Physics_Init(void)
{
#ifdef USEODE
#ifdef ODE_DYNAMIC
	const char* dllnames [] =
	{
# if defined(WIN64)
		"libode1_64.dll",
# elif defined(WIN32)
		"libode1.dll",
# elif defined(MACOSX)
		"libode.1.dylib",
# else
		"libode.so.1",
# endif
		NULL
	};
#endif

	Cvar_RegisterVariable(&physics_ode_quadtree_depth);
	Cvar_RegisterVariable(&physics_ode_contactsurfacelayer);
	Cvar_RegisterVariable(&physics_ode_worldquickstep);
	Cvar_RegisterVariable(&physics_ode_worldquickstep_iterations);
	Cvar_RegisterVariable(&physics_ode_worldstepfast);
	Cvar_RegisterVariable(&physics_ode_worldstepfast_iterations);
	Cvar_RegisterVariable(&physics_ode_contact_mu);
	Cvar_RegisterVariable(&physics_ode_contact_erp);
	Cvar_RegisterVariable(&physics_ode_contact_cfm);
	Cvar_RegisterVariable(&physics_ode_iterationsperframe);
	Cvar_RegisterVariable(&physics_ode_movelimit);
	Cvar_RegisterVariable(&physics_ode_spinlimit);

#ifdef ODE_DYNAMIC
	// Load the DLL
	if (Sys_LoadLibrary (dllnames, &ode_dll, odefuncs))
#endif
	{
		dInitODE();
//		dInitODE2(0);
#ifdef ODE_DNYAMIC
# ifdef dSINGLE
		if (!dCheckConfiguration("ODE_single_precision"))
# else
		if (!dCheckConfiguration("ODE_double_precision"))
# endif
		{
# ifdef dSINGLE
			Con_Printf("ode library not compiled for single precision - incompatible!  Not using ODE physics.\n");
# else
			Con_Printf("ode library not compiled for double precision - incompatible!  Not using ODE physics.\n");
# endif
			Sys_UnloadLibrary(&ode_dll);
			ode_dll = NULL;
		}
#endif
	}
#endif
}

static void World_Physics_Shutdown(void)
{
#ifdef USEODE
#ifdef ODE_DYNAMIC
	if (ode_dll)
#endif
	{
		dCloseODE();
#ifdef ODE_DYNAMIC
		Sys_UnloadLibrary(&ode_dll);
		ode_dll = NULL;
#endif
	}
#endif
}

#ifdef USEODE
static void World_Physics_EnableODE(world_t *world)
{
	dVector3 center, extents;
	if (world->physics.ode)
		return;
#ifdef ODE_DYNAMIC
	if (!ode_dll)
		return;
#endif
	world->physics.ode = true;
	VectorMAM(0.5f, world->mins, 0.5f, world->maxs, center);
	VectorSubtract(world->maxs, center, extents);
	world->physics.ode_world = dWorldCreate();
	world->physics.ode_space = dQuadTreeSpaceCreate(NULL, center, extents, bound(1, physics_ode_quadtree_depth.integer, 10));
	world->physics.ode_contactgroup = dJointGroupCreate(0);
	// we don't currently set dWorldSetCFM or dWorldSetERP because the defaults seem fine
}
#endif

static void World_Physics_Start(world_t *world)
{
#ifdef USEODE
	if (world->physics.ode)
		return;
	World_Physics_EnableODE(world);
#endif
}

static void World_Physics_End(world_t *world)
{
#ifdef USEODE
	if (world->physics.ode)
	{
		dWorldDestroy(world->physics.ode_world);
		dSpaceDestroy(world->physics.ode_space);
		dJointGroupDestroy(world->physics.ode_contactgroup);
		world->physics.ode = false;
	}
#endif
}

void World_Physics_RemoveFromEntity(world_t *world, prvm_edict_t *ed)
{
	// entity is not physics controlled, free any physics data
	ed->priv.server->ode_physics = false;
#ifdef USEODE
	if (ed->priv.server->ode_geom)
		dGeomDestroy((dGeomID)ed->priv.server->ode_geom);
	ed->priv.server->ode_geom = NULL;
	if (ed->priv.server->ode_body)
		dBodyDestroy((dBodyID)ed->priv.server->ode_body);
	ed->priv.server->ode_body = NULL;
#endif
	if (ed->priv.server->ode_vertex3f)
		Mem_Free(ed->priv.server->ode_vertex3f);
	ed->priv.server->ode_vertex3f = NULL;
	ed->priv.server->ode_numvertices = 0;
	if (ed->priv.server->ode_element3i)
		Mem_Free(ed->priv.server->ode_element3i);
	ed->priv.server->ode_element3i = NULL;
	ed->priv.server->ode_numtriangles = 0;
}

#ifdef USEODE
static void World_Physics_Frame_BodyToEntity(world_t *world, prvm_edict_t *ed)
{
	const dReal *avel;
	const dReal *o;
	const dReal *r; // for some reason dBodyGetRotation returns a [3][4] matrix
	const dReal *vel;
	dBodyID body = (dBodyID)ed->priv.server->ode_body;
	int movetype;
	matrix4x4_t bodymatrix;
	matrix4x4_t entitymatrix;
	prvm_eval_t *val;
	vec3_t forward, left, up;
	vec3_t origin;
	vec3_t spinvelocity;
	vec3_t velocity;
	if (!body)
		return;
	val = PRVM_EDICTFIELDVALUE(ed, prog->fieldoffsets.movetype);
	movetype = (int)val->_float;
	if (movetype != MOVETYPE_PHYSICS)
		return;
	// store the physics engine data into the entity
	o = dBodyGetPosition(body);
	r = dBodyGetRotation(body);
	vel = dBodyGetLinearVel(body);
	avel = dBodyGetAngularVel(body);
	VectorCopy(o, origin);
	forward[0] = r[0];
	forward[1] = r[4];
	forward[2] = r[8];
	left[0] = r[1];
	left[1] = r[5];
	left[2] = r[9];
	up[0] = r[2];
	up[1] = r[6];
	up[2] = r[10];
	VectorCopy(vel, velocity);
	VectorCopy(avel, spinvelocity);
	Matrix4x4_FromVectors(&bodymatrix, forward, left, up, origin);
	Matrix4x4_Concat(&entitymatrix, &bodymatrix, &ed->priv.server->ode_offsetimatrix);
	Matrix4x4_ToVectors(&entitymatrix, forward, left, up, origin);
	val = PRVM_EDICTFIELDVALUE(ed, prog->fieldoffsets.origin);if (val) VectorCopy(origin, val->vector);
	val = PRVM_EDICTFIELDVALUE(ed, prog->fieldoffsets.axis_forward);if (val) VectorCopy(forward, val->vector);
	val = PRVM_EDICTFIELDVALUE(ed, prog->fieldoffsets.axis_left);if (val) VectorCopy(left, val->vector);
	val = PRVM_EDICTFIELDVALUE(ed, prog->fieldoffsets.axis_up);if (val) VectorCopy(up, val->vector);
	val = PRVM_EDICTFIELDVALUE(ed, prog->fieldoffsets.velocity);if (val) VectorCopy(velocity, val->vector);
	val = PRVM_EDICTFIELDVALUE(ed, prog->fieldoffsets.spinvelocity);if (val) VectorCopy(spinvelocity, val->vector);
	val = PRVM_EDICTFIELDVALUE(ed, prog->fieldoffsets.angles);if (val) AnglesFromVectors(val->vector, forward, up, true);
}

static void World_Physics_Frame_BodyFromEntity(world_t *world, prvm_edict_t *ed)
{
	const float *iv;
	const int *ie;
	dBodyID body = (dBodyID)ed->priv.server->ode_body;
	dMass mass;
	dReal test;
	void *dataID;
	dVector3 capsulerot[3];
	dp_model_t *model;
	float *ov;
	int *oe;
	int axisindex;
	int modelindex = 0;
	int movetype;
	int numtriangles;
	int numvertices;
	int solid;
	int triangleindex;
	int vertexindex;
	mempool_t *mempool;
	prvm_eval_t *val;
	vec3_t angles;
	vec3_t avelocity;
	vec3_t entmaxs;
	vec3_t entmins;
	vec3_t forward;
	vec3_t geomcenter;
	vec3_t geomsize;
	vec3_t left;
	vec3_t origin;
	vec3_t spinvelocity;
	vec3_t up;
	vec3_t velocity;
	vec_t f;
	vec_t length;
	vec_t massval = 1.0f;
	vec_t movelimit;
	vec_t radius;
	vec_t spinlimit;
#ifdef ODE_DYNAMIC
	if (!ode_dll)
		return;
#endif
	val = PRVM_EDICTFIELDVALUE(ed, prog->fieldoffsets.solid);
	solid = (int)val->_float;
	val = PRVM_EDICTFIELDVALUE(ed, prog->fieldoffsets.movetype);
	movetype = (int)val->_float;
	switch(solid)
	{
	case SOLID_BSP:
		val = PRVM_EDICTFIELDVALUE(ed, prog->fieldoffsets.modelindex);
		modelindex = (int)val->_float;
		if (world == &sv.world && modelindex >= 1 && modelindex < MAX_MODELS)
		{
			model = sv.models[modelindex];
			mempool = sv_mempool;
		}
		else if (world == &cl.world && modelindex >= 1 && modelindex < MAX_MODELS)
		{
			model = cl.model_precache[modelindex];
			mempool = cls.levelmempool;
		}
		else
		{
			model = NULL;
			mempool = NULL;
			modelindex = 0;
		}
		if (model)
		{
			VectorCopy(model->normalmins, entmins);
			VectorCopy(model->normalmaxs, entmaxs);
			val = PRVM_EDICTFIELDVALUE(ed, prog->fieldoffsets.mass);if (val) massval = val->_float;
		}
		else
		{
			modelindex = 0;
			massval = 1.0f;
		}
		break;
	case SOLID_BBOX:
	//case SOLID_SLIDEBOX:
	case SOLID_CORPSE:
	case SOLID_PHYSICS_BOX:
	case SOLID_PHYSICS_SPHERE:
	case SOLID_PHYSICS_CAPSULE:
		val = PRVM_EDICTFIELDVALUE(ed, prog->fieldoffsets.mins);if (val) VectorCopy(val->vector, entmins);
		val = PRVM_EDICTFIELDVALUE(ed, prog->fieldoffsets.maxs);if (val) VectorCopy(val->vector, entmaxs);
		val = PRVM_EDICTFIELDVALUE(ed, prog->fieldoffsets.mass);if (val) massval = val->_float;
		break;
	default:
		if (ed->priv.server->ode_physics)
			World_Physics_RemoveFromEntity(world, ed);
		return;
	}

	VectorSubtract(entmaxs, entmins, geomsize);
	if (VectorLength2(geomsize) == 0)
	{
		// we don't allow point-size physics objects...
		if (ed->priv.server->ode_physics)
			World_Physics_RemoveFromEntity(world, ed);
		return;
	}

	if (movetype != MOVETYPE_PHYSICS)
		massval = 1.0f;

	// check if we need to create or replace the geom
	if (!ed->priv.server->ode_physics
	 || !VectorCompare(ed->priv.server->ode_mins, entmins)
	 || !VectorCompare(ed->priv.server->ode_maxs, entmaxs)
	 || ed->priv.server->ode_mass != massval
	 || ed->priv.server->ode_modelindex != modelindex)
	{
		World_Physics_RemoveFromEntity(world, ed);
		ed->priv.server->ode_physics = true;
		VectorCopy(entmins, ed->priv.server->ode_mins);
		VectorCopy(entmaxs, ed->priv.server->ode_maxs);
		ed->priv.server->ode_mass = massval;
		ed->priv.server->ode_modelindex = modelindex;
		VectorMAM(0.5f, entmins, 0.5f, entmaxs, geomcenter);
		ed->priv.server->ode_movelimit = min(geomsize[0], min(geomsize[1], geomsize[2]));

		if (massval * geomsize[0] * geomsize[1] * geomsize[2] == 0)
		{
			if (movetype == MOVETYPE_PHYSICS)
				Con_Printf("entity %i (classname %s) .mass * .size_x * .size_y * .size_z == 0\n", PRVM_NUM_FOR_EDICT(ed), PRVM_GetString(PRVM_EDICTFIELDVALUE(ed, prog->fieldoffsets.classname)->string));
			massval = 1.0f;
			VectorSet(geomsize, 1.0f, 1.0f, 1.0f);
		}

		switch(solid)
		{
		case SOLID_BSP:
			ed->priv.server->ode_offsetmatrix = identitymatrix;
			if (!model)
			{
				Con_Printf("entity %i (classname %s) has no model\n", PRVM_NUM_FOR_EDICT(ed), PRVM_GetString(PRVM_EDICTFIELDVALUE(ed, prog->fieldoffsets.classname)->string));
				break;
			}
			// add an optimized mesh to the model containing only the SUPERCONTENTS_SOLID surfaces
			if (!model->brush.collisionmesh)
				Mod_CreateCollisionMesh(model);
			if (!model->brush.collisionmesh || !model->brush.collisionmesh->numtriangles)
			{
				Con_Printf("entity %i (classname %s) has no geometry\n", PRVM_NUM_FOR_EDICT(ed), PRVM_GetString(PRVM_EDICTFIELDVALUE(ed, prog->fieldoffsets.classname)->string));
				break;
			}
			// ODE requires persistent mesh storage, so we need to copy out
			// the data from the model because renderer restarts could free it
			// during the game, additionally we need to flip the triangles...
			// note: ODE does preprocessing of the mesh for culling, removing
			// concave edges, etc., so this is not a lightweight operation
			ed->priv.server->ode_numvertices = numvertices = model->brush.collisionmesh->numverts;
			ed->priv.server->ode_vertex3f = (float *)Mem_Alloc(mempool, numvertices * sizeof(float[3]));
			for (vertexindex = 0, ov = ed->priv.server->ode_vertex3f, iv = model->brush.collisionmesh->vertex3f;vertexindex < numvertices;vertexindex++, ov += 3, iv += 3)
			{
				ov[0] = iv[0] - geomcenter[0];
				ov[1] = iv[1] - geomcenter[1];
				ov[2] = iv[2] - geomcenter[2];
			}
			ed->priv.server->ode_numtriangles = numtriangles = model->brush.collisionmesh->numtriangles;
			ed->priv.server->ode_element3i = (int *)Mem_Alloc(mempool, numtriangles * sizeof(int[3]));
			//memcpy(ed->priv.server->ode_element3i, model->brush.collisionmesh->element3i, ed->priv.server->ode_numtriangles * sizeof(int[3]));
			for (triangleindex = 0, oe = ed->priv.server->ode_element3i, ie = model->brush.collisionmesh->element3i;triangleindex < numtriangles;triangleindex++, oe += 3, ie += 3)
			{
				oe[0] = ie[2];
				oe[1] = ie[1];
				oe[2] = ie[0];
			}
			Matrix4x4_CreateTranslate(&ed->priv.server->ode_offsetmatrix, geomcenter[0], geomcenter[1], geomcenter[2]);
			// now create the geom
			dataID = dGeomTriMeshDataCreate();
			dGeomTriMeshDataBuildSingle(dataID, (void*)ed->priv.server->ode_vertex3f, sizeof(float[3]), ed->priv.server->ode_numvertices, ed->priv.server->ode_element3i, ed->priv.server->ode_numtriangles*3, sizeof(int[3]));
			ed->priv.server->ode_body = (void *)(body = dBodyCreate(world->physics.ode_world));
			ed->priv.server->ode_geom = (void *)dCreateTriMesh(world->physics.ode_space, dataID, NULL, NULL, NULL);
			dGeomSetBody(ed->priv.server->ode_geom, body);
			dMassSetBoxTotal(&mass, massval, geomsize[0], geomsize[1], geomsize[2]);
			dBodySetMass(body, &mass);
			dBodySetData(body, (void*)ed);
			break;
		case SOLID_BBOX:
		case SOLID_SLIDEBOX:
		case SOLID_CORPSE:
		case SOLID_PHYSICS_BOX:
			Matrix4x4_CreateTranslate(&ed->priv.server->ode_offsetmatrix, geomcenter[0], geomcenter[1], geomcenter[2]);
			ed->priv.server->ode_body = (void *)(body = dBodyCreate(world->physics.ode_world));
			ed->priv.server->ode_geom = (void *)dCreateBox(world->physics.ode_space, geomsize[0], geomsize[1], geomsize[2]);
			dMassSetBoxTotal(&mass, massval, geomsize[0], geomsize[1], geomsize[2]);
			dGeomSetBody(ed->priv.server->ode_geom, body);
			dBodySetMass(body, &mass);
			dBodySetData(body, (void*)ed);
			break;
		case SOLID_PHYSICS_SPHERE:
			Matrix4x4_CreateTranslate(&ed->priv.server->ode_offsetmatrix, geomcenter[0], geomcenter[1], geomcenter[2]);
			ed->priv.server->ode_body = (void *)(body = dBodyCreate(world->physics.ode_world));
			ed->priv.server->ode_geom = (void *)dCreateSphere(world->physics.ode_space, geomsize[0] * 0.5f);
			dMassSetSphereTotal(&mass, massval, geomsize[0] * 0.5f);
			dGeomSetBody(ed->priv.server->ode_geom, body);
			dBodySetMass(body, &mass);
			dBodySetData(body, (void*)ed);
			break;
		case SOLID_PHYSICS_CAPSULE:
			axisindex = 0;
			if (geomsize[axisindex] < geomsize[1])
				axisindex = 1;
			if (geomsize[axisindex] < geomsize[2])
				axisindex = 2;
			// the qc gives us 3 axis radius, the longest axis is the capsule
			// axis, since ODE doesn't like this idea we have to create a
			// capsule which uses the standard orientation, and apply a
			// transform to it
			memset(capsulerot, 0, sizeof(capsulerot));
			if (axisindex == 0)
				Matrix4x4_CreateFromQuakeEntity(&ed->priv.server->ode_offsetmatrix, geomcenter[0], geomcenter[1], geomcenter[2], 0, 0, 90, 1);
			else if (axisindex == 1)
				Matrix4x4_CreateFromQuakeEntity(&ed->priv.server->ode_offsetmatrix, geomcenter[0], geomcenter[1], geomcenter[2], 90, 0, 0, 1);
			else
				Matrix4x4_CreateFromQuakeEntity(&ed->priv.server->ode_offsetmatrix, geomcenter[0], geomcenter[1], geomcenter[2], 0, 0, 0, 1);
			radius = geomsize[!axisindex] * 0.5f; // any other axis is the radius
			length = geomsize[axisindex] - radius*2;
			// because we want to support more than one axisindex, we have to
			// create a transform, and turn on its cleanup setting (which will
			// cause the child to be destroyed when it is destroyed)
			ed->priv.server->ode_body = (void *)(body = dBodyCreate(world->physics.ode_world));
			ed->priv.server->ode_geom = (void *)dCreateCapsule(world->physics.ode_space, radius, length);
			dMassSetCapsuleTotal(&mass, massval, axisindex+1, radius, length);
			dGeomSetBody(ed->priv.server->ode_geom, body);
			dBodySetMass(body, &mass);
			dBodySetData(body, (void*)ed);
			break;
		default:
			Sys_Error("World_Physics_BodyFromEntity: unrecognized solid value %i was accepted by filter\n", solid);
		}
		Matrix4x4_Invert_Simple(&ed->priv.server->ode_offsetimatrix, &ed->priv.server->ode_offsetmatrix);
	}

	// get current data from entity
	VectorClear(origin);
	VectorClear(forward);
	VectorClear(left);
	VectorClear(up);
	VectorClear(velocity);
	VectorClear(spinvelocity);
	val = PRVM_EDICTFIELDVALUE(ed, prog->fieldoffsets.origin);if (val) VectorCopy(val->vector, origin);
	val = PRVM_EDICTFIELDVALUE(ed, prog->fieldoffsets.axis_forward);if (val) VectorCopy(val->vector, forward);
	val = PRVM_EDICTFIELDVALUE(ed, prog->fieldoffsets.axis_left);if (val) VectorCopy(val->vector, left);
	val = PRVM_EDICTFIELDVALUE(ed, prog->fieldoffsets.axis_up);if (val) VectorCopy(val->vector, up);
	val = PRVM_EDICTFIELDVALUE(ed, prog->fieldoffsets.velocity);if (val) VectorCopy(val->vector, velocity);
	val = PRVM_EDICTFIELDVALUE(ed, prog->fieldoffsets.spinvelocity);if (val) VectorCopy(val->vector, spinvelocity);

	// compatibility for legacy entities
	if (!VectorLength2(forward) || solid == SOLID_BSP)
	{
		VectorClear(angles);
		VectorClear(avelocity);
		val = PRVM_EDICTFIELDVALUE(ed, prog->fieldoffsets.angles);if (val) VectorCopy(val->vector, angles);
		val = PRVM_EDICTFIELDVALUE(ed, prog->fieldoffsets.avelocity);if (val) VectorCopy(val->vector, avelocity);
		AngleVectorsFLU(angles, forward, left, up);
		// convert single-axis rotations in avelocity to spinvelocity
		// FIXME: untested math - check signs
		VectorSet(spinvelocity, avelocity[PITCH] * ((float)M_PI / 180.0f), avelocity[ROLL] * ((float)M_PI / 180.0f), avelocity[YAW] * ((float)M_PI / 180.0f));
	}

	// compatibility for legacy entities
	switch (solid)
	{
	case SOLID_BBOX:
	case SOLID_SLIDEBOX:
	case SOLID_CORPSE:
		//VectorClear(velocity);
		VectorSet(forward, 1, 0, 0);
		VectorSet(left, 0, 1, 0);
		VectorSet(up, 0, 0, 1);
		VectorSet(spinvelocity, 0, 0, 0);
		break;
	}

	// we must prevent NANs...
	test = VectorLength2(origin) + VectorLength2(forward) + VectorLength2(left) + VectorLength2(up) + VectorLength2(velocity) + VectorLength2(spinvelocity);
	if (IS_NAN(test))
	{
		Con_Printf("Fixing NAN values on entity %i : .classname = \"%s\" .origin = '%f %f %f' .axis_forward = '%f %f %f' .axis_left = '%f %f %f' .axis_up = '%f %f %f' .velocity = '%f %f %f' .spinvelocity = '%f %f %f'\n", PRVM_NUM_FOR_EDICT(ed), PRVM_GetString(PRVM_EDICTFIELDVALUE(ed, prog->fieldoffsets.classname)->string), origin[0], origin[1], origin[2], forward[0], forward[1], forward[2], left[0], left[1], left[2], up[0], up[1], up[2], velocity[0], velocity[1], velocity[2], spinvelocity[0], spinvelocity[1], spinvelocity[2]);
		test = VectorLength2(origin);
		if (IS_NAN(test))
			VectorClear(origin);
		test = VectorLength2(forward) * VectorLength2(left) * VectorLength2(up);
		if (IS_NAN(test))
		{
			VectorSet(forward, 1, 0, 0);
			VectorSet(left, 0, 1, 0);
			VectorSet(up, 0, 0, 1);
		}
		test = VectorLength2(velocity);
		if (IS_NAN(test))
			VectorClear(velocity);
		test = VectorLength2(spinvelocity);
		if (IS_NAN(test))
		{
			VectorClear(spinvelocity);
		}
	}

	// limit movement speed to prevent missed collisions at high speed
	movelimit = ed->priv.server->ode_movelimit * world->physics.ode_movelimit;
	test = VectorLength2(velocity);
	if (test > movelimit*movelimit)
	{
		// scale down linear velocity to the movelimit
		// scale down angular velocity the same amount for consistency
		f = movelimit / sqrt(test);
		VectorScale(velocity, f, velocity);
		VectorScale(spinvelocity, f, spinvelocity);
	}

	// make sure the angular velocity is not exploding
	spinlimit = physics_ode_spinlimit.value;
	test = VectorLength2(spinvelocity);
	if (test > spinlimit)
		VectorClear(spinvelocity);

	// store the values into the physics engine
	body = ed->priv.server->ode_body;
	if (body)
	{
		dVector3 r[3];
		matrix4x4_t entitymatrix;
		matrix4x4_t bodymatrix;
		Matrix4x4_FromVectors(&entitymatrix, forward, left, up, origin);
		Matrix4x4_Concat(&bodymatrix, &entitymatrix, &ed->priv.server->ode_offsetmatrix);
		Matrix4x4_ToVectors(&bodymatrix, forward, left, up, origin);
		r[0][0] = forward[0];
		r[1][0] = forward[1];
		r[2][0] = forward[2];
		r[0][1] = left[0];
		r[1][1] = left[1];
		r[2][1] = left[2];
		r[0][2] = up[0];
		r[1][2] = up[1];
		r[2][2] = up[2];
		dGeomSetBody(ed->priv.server->ode_geom, ed->priv.server->ode_body);
		dBodySetPosition(body, origin[0], origin[1], origin[2]);
		dBodySetRotation(body, r[0]);
		dBodySetLinearVel(body, velocity[0], velocity[1], velocity[2]);
		dBodySetAngularVel(body, spinvelocity[0], spinvelocity[1], spinvelocity[2]);
		// setting body to NULL makes an immovable object
		if (movetype != MOVETYPE_PHYSICS)
			dGeomSetBody(ed->priv.server->ode_geom, 0);
	}
}

#define MAX_CONTACTS 16
static void nearCallback (void *data, dGeomID o1, dGeomID o2)
{
	world_t *world = (world_t *)data;
	dContact contact[MAX_CONTACTS]; // max contacts per collision pair
	dBodyID b1;
	dBodyID b2;
	dJointID c;
	int i;
	int numcontacts;

	if (dGeomIsSpace(o1) || dGeomIsSpace(o2))
	{
		// colliding a space with something
		dSpaceCollide2(o1, o2, data, &nearCallback);
		// Note we do not want to test intersections within a space,
		// only between spaces.
		//if (dGeomIsSpace(o1)) dSpaceCollide(o1, data, &nearCallback);
		//if (dGeomIsSpace(o2)) dSpaceCollide(o2, data, &nearCallback);
		return;
	}

	b1 = dGeomGetBody(o1);
	b2 = dGeomGetBody(o2);

	// at least one object has to be using MOVETYPE_PHYSICS or we just don't care
	if (!b1 && !b2)
		return;

	// exit without doing anything if the two bodies are connected by a joint
	if (b1 && b2 && dAreConnectedExcluding(b1, b2, dJointTypeContact))
		return;

	// generate contact points between the two non-space geoms
	numcontacts = dCollide(o1, o2, MAX_CONTACTS, &(contact[0].geom), sizeof(contact[0]));
	// add these contact points to the simulation
	for (i = 0;i < numcontacts;i++)
	{
		contact[i].surface.mode = (physics_ode_contact_mu.value != -1 ? dContactApprox1 : 0) | (physics_ode_contact_erp.value != -1 ? dContactSoftERP : 0) | (physics_ode_contact_cfm.value != -1 ? dContactSoftCFM : 0);
		contact[i].surface.mu = physics_ode_contact_mu.value;
		contact[i].surface.soft_erp = physics_ode_contact_erp.value;
		contact[i].surface.soft_cfm = physics_ode_contact_cfm.value;
		c = dJointCreateContact(world->physics.ode_world, world->physics.ode_contactgroup, contact + i);
		dJointAttach(c, b1, b2);
	}
}
#endif

void World_Physics_Frame(world_t *world, double frametime, double gravity)
{
#ifdef USEODE
	if (world->physics.ode)
	{
		int i;
		prvm_edict_t *ed;

		// copy physics properties from entities to physics engine
		if (prog)
			for (i = 0, ed = prog->edicts + i;i < prog->num_edicts;i++, ed++)
				if (!prog->edicts[i].priv.required->free)
					World_Physics_Frame_BodyFromEntity(world, ed);

		world->physics.ode_iterations = bound(1, physics_ode_iterationsperframe.integer, 1000);
		world->physics.ode_step = frametime / world->physics.ode_iterations;
		world->physics.ode_movelimit = physics_ode_movelimit.value / world->physics.ode_step;
		for (i = 0;i < world->physics.ode_iterations;i++)
		{
			// set the gravity
			dWorldSetGravity(world->physics.ode_world, 0, 0, -gravity);
			// set the tolerance for closeness of objects
			dWorldSetContactSurfaceLayer(world->physics.ode_world, max(0, physics_ode_contactsurfacelayer.value));

			// run collisions for the current world state, creating JointGroup
			dSpaceCollide(world->physics.ode_space, (void *)world, nearCallback);

			// run physics (move objects, calculate new velocities)
			if (physics_ode_worldquickstep.integer)
			{
				dWorldSetQuickStepNumIterations(world->physics.ode_world, bound(1, physics_ode_worldquickstep_iterations.integer, 200));
				dWorldQuickStep(world->physics.ode_world, world->physics.ode_step);
			}
			else if (physics_ode_worldstepfast.integer)
				dWorldStepFast1(world->physics.ode_world, world->physics.ode_step, bound(1, physics_ode_worldstepfast_iterations.integer, 200));
			else
				dWorldStep(world->physics.ode_world, world->physics.ode_step);

			// clear the JointGroup now that we're done with it
			dJointGroupEmpty(world->physics.ode_contactgroup);
		}

		// copy physics properties from physics engine to entities
		if (prog)
			for (i = 1, ed = prog->edicts + i;i < prog->num_edicts;i++, ed++)
				if (!prog->edicts[i].priv.required->free && PRVM_EDICTFIELDVALUE(ed, prog->fieldoffsets.movetype)->_float == MOVETYPE_PHYSICS)
					World_Physics_Frame_BodyToEntity(world, ed);
	}
#endif
}
