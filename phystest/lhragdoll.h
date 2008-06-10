
#ifndef RAGDOLL_H
#define RAGDOLL_H

typedef enum LHRagdollStickType_e
{
	LHRAGDOLLSTICK_NORMAL, // maintain rest length (dist)
	LHRAGDOLLSTICK_MINDIST, // don't allow two particles to get close
	LHRAGDOLLSTICK_CLOTH, // mostly maintain rest length (sqrt approximation)
}
LHRagdollStickType;

typedef float LHRagdollScalar;

typedef struct LHRagdollVector
{
	LHRagdollScalar v[3];
}
LHRagdollVector;

typedef struct LHRagdollTrace
{
	LHRagdollScalar start[3];
	LHRagdollScalar radius;
	LHRagdollScalar end[3];
	LHRagdollScalar fraction;
	LHRagdollScalar planenormal[3];
	LHRagdollScalar planedist;
}
LHRagdollTrace;

typedef struct LHRagdollParticle
{
	LHRagdollVector origin;
	LHRagdollVector velocity;
	LHRagdollScalar radius;
}
LHRagdollParticle;

typedef struct LHRagdollStick
{
	int particleindices[2];
	LHRagdollStickType type;
	LHRagdollScalar dist;
	LHRagdollScalar distsquared;
}
LHRagdollStick;

typedef struct LHRagdollBody
{
	int sleep; // if true the body is not moving at all
	int numparticles;
	int numsticks;
	LHRagdollParticle *particles;
	LHRagdollStick *sticks;
	LHRagdollVector mins;
	LHRagdollVector maxs;
}
LHRagdollBody;

void LHRagdoll_Setup(LHRagdollBody *body, unsigned int numparticles, LHRagdollParticle *particles, unsigned int numsticks, LHRagdollStick *sticks);
void LHRagdoll_SetParticle(LHRagdollBody *body, int subindex, LHRagdollScalar radius, LHRagdollScalar x, LHRagdollScalar y, LHRagdollScalar z, LHRagdollScalar vx, LHRagdollScalar vy, LHRagdollScalar vz);
void LHRagdoll_SetStick(LHRagdollBody *body, int subindex, LHRagdollStickType type, int p1, int p2, LHRagdollScalar dist, int useautomaticdistance);
void LHRagdoll_RecalculateBounds(LHRagdollBody *body);
void LHRagdoll_MoveBody(LHRagdollBody *body, LHRagdollScalar step, LHRagdollScalar accelx, LHRagdollScalar accely, LHRagdollScalar accelz, LHRagdollScalar friction, LHRagdollScalar stiction, LHRagdollScalar sleepdist, void (*callback_trace)(LHRagdollTrace *trace));
void LHRagdoll_ConstrainBody(LHRagdollBody *body, LHRagdollScalar step, int restitutioniterations);
void LHRagdoll_AreaImpulseBody(LHRagdollBody *body, LHRagdollScalar impactx, LHRagdollScalar impacty, LHRagdollScalar impactz, LHRagdollScalar forcex, LHRagdollScalar forcey, LHRagdollScalar forcez, LHRagdollScalar radius, LHRagdollScalar sphereforce, LHRagdollScalar attenuationpower);
void LHRagdoll_PointImpulseBody(LHRagdollBody *body, LHRagdollScalar impactx, LHRagdollScalar impacty, LHRagdollScalar impactz, LHRagdollScalar forcex, LHRagdollScalar forcey, LHRagdollScalar forcez);

#endif // RAGDOLL_H
