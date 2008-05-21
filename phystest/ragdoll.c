
#include <stdlib.h>
#include <stdio.h>
#include <memory.h>
#include <math.h>

#define RAGDOLL_MAX_PARTICLES_PER_BODY 256

typedef enum RagdollStickType_e
{
	RAGDOLLSTICK_NORMAL, // maintain rest length (dist)
	RAGDOLLSTICK_MINDIST, // don't allow two particles to get close
	RAGDOLLSTICK_CLOTH, // mostly maintain rest length (sqrt approximation)
}
RagdollStickType;

typedef float RagdollScalar;

typedef struct RagdollVector
{
	RagdollScalar v[3];
}
RagdollVector;

typedef struct RagdollTrace
{
	RagdollScalar start[3];
	RagdollScalar end[3];
	RagdollScalar planenormal[3];
	RagdollScalar planedist;
	RagdollScalar fraction;
}
RagdollTrace;

typedef struct RagdollParticle
{
	RagdollVector origin;
	RagdollVector velocity;
}
RagdollParticle;

typedef struct RagdollStick
{
	int particleindices[2];
	RagdollStickType type;
	RagdollScalar dist;
	RagdollScalar distsquared;
}
RagdollStick;

typedef struct RagdollBody
{
	int active;
	int numparticles;
	int numsticks;
	RagdollParticle *particles;
	RagdollStick *sticks;
}
RagdollBody;

typedef struct RagdollGlobals
{
	int (*callback_printf)(const char *fmt, ...);
	void *(*callback_malloc)(size_t size);
	void (*callback_free)(void *data);
	void (*callback_trace)(RagdollTrace *trace);
}
RagdollGlobals;

RagdollGlobals Ragdoll;

static int Ragdoll_DummyPrintf(const char *fmt, ...)
{
	return 0;
}

void Ragdoll_Init(int (*callback_printf)(const char *fmt, ...), void *(*callback_malloc)(size_t size), void (*callback_free)(void *data), void (*callback_trace)(RagdollTrace *trace))
{
	memset(&Ragdoll, 0, sizeof(Ragdoll));
	Ragdoll.callback_printf = callback_printf;
	Ragdoll.callback_malloc = callback_malloc;
	Ragdoll.callback_free = callback_free;
	Ragdoll.callback_trace = callback_trace;
	if (!Ragdoll.callback_printf)
		Ragdoll.callback_printf = Ragdoll_DummyPrintf;
}

void Ragdoll_Quit(void)
{
	memset(&Ragdoll, 0, sizeof(Ragdoll));
}

void Ragdoll_NewBody(RagdollBody *body, unsigned int numparticles, unsigned int numsticks)
{
	// check limits to prevent crashes in certain stack-based code
	if (numparticles > RAGDOLL_MAX_PARTICLES_PER_BODY)
	{
		numparticles = RAGDOLL_MAX_PARTICLES_PER_BODY;
		Ragdoll.callback_printf("Ragdoll_Newbody: too many particles, limiting to %i\n", numparticles);
	}
	memset(body, 0, sizeof(*body));
	body->active = 1;
	body->numparticles = numparticles;
	body->numsticks = numsticks;
	if (numparticles > 0)
		body->particles = (RagdollParticle *)Ragdoll.callback_malloc(body->numparticles * sizeof(RagdollParticle));
	if (numsticks > 0)
		body->sticks = (RagdollStick *)Ragdoll.callback_malloc(body->numsticks * sizeof(RagdollStick));
}

void Ragdoll_DestroyBody(RagdollBody *body)
{
	// free anything related to this body
	if (body->particles)
		Ragdoll.callback_free(body->particles);
	if (body->sticks)
		Ragdoll.callback_free(body->sticks);
	memset(body, 0, sizeof(*body));
}

void Ragdoll_RecalculateBounds(RagdollBody *body)
{
	// TODO
}

void Ragdoll_GetPositions(RagdollBody *body, int startindex, int numpositions, RagdollScalar *positions, size_t stride)
{
	int i;
	RagdollParticle *p;
	RagdollScalar *pos;
	if (startindex < 0 || numpositions < 0 || (unsigned int)(startindex + numpositions) > (unsigned int)body->numparticles)
	{
		Ragdoll.callback_printf("Ragdoll_GetPositions: invalid range\n");
		return;
	}
	p = body->particles + startindex;
	pos = positions;
	for (i = 0;i < numpositions;i++, p++, pos = (RagdollScalar *)((unsigned char *)pos + stride))
	{
		positions[0] = (RagdollScalar)p->origin.v[0];
		positions[1] = (RagdollScalar)p->origin.v[1];
		positions[2] = (RagdollScalar)p->origin.v[2];
	}
}

void Ragdoll_SetParticle(RagdollBody *body, int subindex, RagdollScalar x, RagdollScalar y, RagdollScalar z, RagdollScalar vx, RagdollScalar vy, RagdollScalar vz)
{
	RagdollParticle p;
	if (subindex < 0 || subindex >= body->numparticles)
	{
		Ragdoll.callback_printf("Ragdoll_SetParticle: invalid particle index\n");
		return;
	}
	memset(&p, 0, sizeof(p));
	p.origin.v[0] = (RagdollScalar)x;
	p.origin.v[1] = (RagdollScalar)y;
	p.origin.v[2] = (RagdollScalar)z;
	p.velocity.v[0] = (RagdollScalar)vx;
	p.velocity.v[1] = (RagdollScalar)vy;
	p.velocity.v[2] = (RagdollScalar)vz;
	body->particles[subindex] = p;
}

void Ragdoll_SetStick(RagdollBody *body, int subindex, RagdollStickType type, int p1, int p2, RagdollScalar dist, int useautomaticdistance)
{
	RagdollStick s;
	RagdollScalar v[3];
	if (subindex < 0 || subindex >= body->numsticks)
	{
		Ragdoll.callback_printf("Ragdoll_SetStick: invalid stick index\n");
		return;
	}
	memset(&s, 0, sizeof(s));
	s.particleindices[0] = p1;
	s.particleindices[1] = p2;
	s.type = type;
	if (useautomaticdistance)
	{
		v[0] = body->particles[p2].origin.v[0] - body->particles[p1].origin.v[0];
		v[1] = body->particles[p2].origin.v[1] - body->particles[p1].origin.v[1];
		v[2] = body->particles[p2].origin.v[2] - body->particles[p1].origin.v[2];
		s.distsquared = v[0]*v[0]+v[1]*v[1]+v[2]*v[2];
		s.dist = sqrt(s.distsquared);
	}
	else
	{
		s.dist = dist;
		s.distsquared = s.dist * s.dist;
	}
	body->sticks[subindex] = s;
}

void Ragdoll_MoveBody(RagdollBody *body, RagdollScalar step, RagdollScalar accelx, RagdollScalar accely, RagdollScalar accelz, RagdollScalar nudge, RagdollScalar friction, RagdollScalar stiction)
{
	int i;
	int j;
	RagdollScalar t;
	RagdollScalar f;
	RagdollScalar halfstep = 0.5f * step;
	RagdollScalar halfaccel[3];
	RagdollParticle *p;
	RagdollTrace trace;

	// ignore really tiny steps because they do nothing
	if (step == 0)
		return;

	if (stiction < friction)
		stiction = friction;

	// avoid some redundant calculations later
	halfaccel[0] = halfstep * accelx;
	halfaccel[1] = halfstep * accely;
	halfaccel[2] = halfstep * accelz;

	// apply half of acceleration before moving particles, and half after
	// this gives identical results to velocity verlet integration (except when a collision happens)
	for (i = 0, p = body->particles;i < body->numparticles;i++, p++)
	{
		p->velocity.v[0] += halfaccel[0];
		p->velocity.v[1] += halfaccel[1];
		p->velocity.v[2] += halfaccel[2];
	}

	// move particles
	for (i = 0, p = body->particles;i < body->numparticles;i++, p++)
	{
		// move the particle multiple times if necessary
		// (sliding across surfaces)
		t = step;
		for (j = 0;j < 16 && t > 0;j++)
		{
			trace.start[0] = p->origin.v[0];
			trace.start[1] = p->origin.v[1];
			trace.start[2] = p->origin.v[2];
			trace.end[0] = p->origin.v[0] + t * p->velocity.v[0];
			trace.end[1] = p->origin.v[1] + t * p->velocity.v[1];
			trace.end[2] = p->origin.v[2] + t * p->velocity.v[2];
			Ragdoll.callback_trace(&trace);
			f = trace.fraction * t;
			p->origin.v[0] += f * p->velocity.v[0];
			p->origin.v[1] += f * p->velocity.v[1];
			p->origin.v[2] += f * p->velocity.v[2];
			t -= f;
			if (trace.fraction < 1)
			{
				// project particle onto plane at the specified nudge
				// (this eliminates cumulative error)
				//f = p->origin.v[0] * trace.planenormal[0] + p->origin.v[1] * trace.planenormal[1] + p->origin.v[2] * trace.planenormal[2] - trace.planedist - nudge;
				//p->origin.v[0] -= f * trace.planenormal[0];
				//p->origin.v[1] -= f * trace.planenormal[1];
				//p->origin.v[2] -= f * trace.planenormal[2];
				// project velocity onto plane (this could be multiplied by a value like 1.5 to make it bounce significantly instead)
				f = p->velocity.v[0] * trace.planenormal[0] + p->velocity.v[1] * trace.planenormal[1] + p->velocity.v[2] * trace.planenormal[2];
				p->velocity.v[0] -= f * trace.planenormal[0];
				p->velocity.v[1] -= f * trace.planenormal[1];
				p->velocity.v[2] -= f * trace.planenormal[2];
				// apply friction and stiction
				f = sqrt(p->velocity.v[0] * p->velocity.v[0] + p->velocity.v[1] + p->velocity.v[1] + p->velocity.v[2] * p->velocity.v[2]);
				if (f > stiction)
					f = 1 - friction / f;
				else
					f = 0;
				p->velocity.v[0] *= f;
				p->velocity.v[1] *= f;
				p->velocity.v[2] *= f;
			}
		}
	}

	// apply other half of acceleration
	for (i = 0, p = body->particles;i < body->numparticles;i++, p++)
	{
		p->velocity.v[0] += halfaccel[0];
		p->velocity.v[1] += halfaccel[1];
		p->velocity.v[2] += halfaccel[2];
	}

	Ragdoll_RecalculateBounds(body);
}

void Ragdoll_ConstrainBody(RagdollBody *body, RagdollScalar step, int restitutioniterations)
{
	int i;
	int iter;
	RagdollScalar d;
	RagdollScalar istep;
	RagdollScalar v[3];
	RagdollStick *s;
	RagdollParticle *p;
	RagdollVector *v1;
	RagdollVector *v2;
	RagdollVector futurepositions[RAGDOLL_MAX_PARTICLES_PER_BODY];

	// ignore really tiny steps because they produce divide by zero errors
	if (step == 0)
		return;

	// this code is based on the article "Advanced Character Physics" on Gamasutra

	// calculate future positions for restitution to operate on
	// (this does not add in acceleration because it is uniform)
	for (i = 0, p = body->particles;i < body->numparticles;i++, p++)
	{
		futurepositions[i].v[0] = p->origin.v[0] + step * p->velocity.v[0];
		futurepositions[i].v[1] = p->origin.v[1] + step * p->velocity.v[1];
		futurepositions[i].v[2] = p->origin.v[2] + step * p->velocity.v[2];
	}
	// repeated application of constraints improves accuracy
	for (iter = 0;iter < restitutioniterations;iter++)
	{
		// apply each constraint
		for (i = 0, s = body->sticks;i < body->numsticks;i++, s++)
		{
			v1 = futurepositions + s->particleindices[0];
			v2 = futurepositions + s->particleindices[1];
			v[0] = v2->v[0] - v1->v[0];
			v[1] = v2->v[1] - v1->v[1];
			v[2] = v2->v[2] - v1->v[2];
			d = v[0]*v[0] + v[1]*v[1] + v[2]*v[2];
			if (d == 0)
				continue;
			// additional constraint types could be added here
			switch (s->type)
			{
			case RAGDOLLSTICK_CLOTH:
				d = s->distsquared / (d + s->distsquared) - 0.5f;
				break;
			case RAGDOLLSTICK_MINDIST:
				// mindist constraints only apply if too close
				if (d >= s->distsquared * s->distsquared)
					continue;
			case RAGDOLLSTICK_NORMAL:
				// move particles to match stick's rest length
				d = sqrt(d);
				d = -0.5f * (d - s->dist) / d;
				break;
			}
			v[0] *= d;
			v[1] *= d;
			v[2] *= d;
			// apply offset to satisfy the constraint
			v1->v[0] -= v[0];
			v1->v[1] -= v[1];
			v1->v[2] -= v[2];
			v2->v[0] += v[0];
			v2->v[1] += v[1];
			v2->v[2] += v[2];
		}
	}
	// calculate velocities to achieve velocity positions that were chosen
	istep = 1 / step;
	for (i = 0, p = body->particles;i < body->numparticles;i++, p++)
	{
		p->velocity.v[0] = istep * (futurepositions[i].v[0] - p->origin.v[0]);
		p->velocity.v[1] = istep * (futurepositions[i].v[1] - p->origin.v[1]);
		p->velocity.v[2] = istep * (futurepositions[i].v[2] - p->origin.v[2]);
	}
}

void Ragdoll_AreaImpulseBody(RagdollBody *body, RagdollScalar impactx, RagdollScalar impacty, RagdollScalar impactz, RagdollScalar forcex, RagdollScalar forcey, RagdollScalar forcez, RagdollScalar radius, RagdollScalar sphereforce, RagdollScalar attenuationpower)
{
	int i;
	RagdollParticle *p;
	RagdollScalar v[3];
	RagdollScalar distsquared;
	RagdollScalar dist;
	RagdollScalar d;
	RagdollScalar sf;

	for (i = 0, p = body->particles;i < body->numparticles;i++, p++)
	{
		v[0] = p->origin.v[0] - impactx;
		v[1] = p->origin.v[1] - impacty;
		v[2] = p->origin.v[2] - impactz;
		distsquared = v[0] * v[0] + v[1] * v[1] + v[2] * v[2];
		if (distsquared >= radius * radius)
			continue;
		dist = sqrt(distsquared);
		d = pow(1.0f - dist / radius, attenuationpower);
		sf = d * sphereforce / dist;
		p->velocity.v[0] += d * forcex + sf * v[0];
		p->velocity.v[1] += d * forcey + sf * v[1];
		p->velocity.v[2] += d * forcez + sf * v[2];
	}
}

void Ragdoll_PointImpulseBody(RagdollBody *body, RagdollScalar impactx, RagdollScalar impacty, RagdollScalar impactz, RagdollScalar forcex, RagdollScalar forcey, RagdollScalar forcez)
{
	int i;
	RagdollParticle *p;
	RagdollScalar v[3];
	RagdollScalar f;
	RagdollScalar distsquared;
	RagdollScalar bestdistsquared[2];
	RagdollScalar bestdist[2];
	int best[2];

	best[0] = best[1] = -1;
	bestdistsquared[0] = bestdistsquared[1] = 0;
	for (i = 0, p = body->particles;i < body->numparticles;i++, p++)
	{
		v[0] = p->origin.v[0] - impactx;
		v[1] = p->origin.v[1] - impacty;
		v[2] = p->origin.v[2] - impactz;
		distsquared = v[0] * v[0] + v[1] * v[1] + v[2] * v[2];
		if (bestdistsquared[0] > distsquared || best[0] < 0)
		{
			bestdistsquared[1] = bestdistsquared[0];
			best[1] = best[0];
			bestdistsquared[0] = distsquared;
			best[0] = i;
		}
		else if (bestdistsquared[1] > distsquared || best[1] < 0)
		{
			bestdistsquared[1] = distsquared;
			best[1] = i;
		}
	}

	if (best[0] < 0)
		return;

	// picked the best two points on the ragdoll, now calculate how much to
	// apply to each (favoring the closer one)
	bestdist[0] = sqrt(bestdistsquared[0]);
	bestdist[1] = sqrt(bestdistsquared[1]);
	f = bestdist[0] / (bestdist[0] + bestdist[1]);
	if (best[1] >= 0)
	{
		p = body->particles + best[1];
		p->velocity.v[0] += f * forcex;
		p->velocity.v[1] += f * forcey;
		p->velocity.v[2] += f * forcez;
		f = 1 - f;
	}
	p = body->particles + best[1];
	p->velocity.v[0] += f * forcex;
	p->velocity.v[1] += f * forcey;
	p->velocity.v[2] += f * forcez;
}

#define STANDALONE_TEST 1
#if STANDALONE_TEST

float floorplane[4] = {0.0f, 0.0f, 1.0f, 0.0f};

void test_trace(RagdollTrace *trace)
{
	float d1;
	float d2;
	float nudge = (1.0f / 32.0f);
	trace->fraction = 1;
	// simply test a floor plane
	d1 = trace->start[0] * floorplane[0] + trace->start[1] * floorplane[1] + trace->start[2] * floorplane[2] - floorplane[3];
	d2 = trace->end[0] * floorplane[0] + trace->end[1] * floorplane[1] + trace->end[2] * floorplane[2] - floorplane[3];
	if (d1 > 0 && d2 < 0)
	{
		trace->fraction = (d1 - nudge) / (d1 - d2);
		trace->planenormal[0] = floorplane[0];
		trace->planenormal[1] = floorplane[1];
		trace->planenormal[2] = floorplane[2];
		trace->planedist = floorplane[3];
	}
}

#define lhrandom(MIN,MAX) (((double)rand() / RAND_MAX) * ((MAX)-(MIN)) + (MIN))

int main(int argc, char **argv)
{
	int i;
	int j;
	int frame;
	float step = 1.0f / 64.0f;
	float x, y, z;
	RagdollBody *body;
	RagdollParticle *p;
	RagdollStickType type = RAGDOLLSTICK_CLOTH;
	int numbodies = 0;
	RagdollBody bodies[16];


	Ragdoll_Init(printf, malloc, free, test_trace);
	// run physics
	for (frame = 0;frame < 256;frame++)
	{
		if (frame == 0)
		{
			// create a tetrahedron
			x = 0;//lhrandom(-3, 3);
			y = 0;//lhrandom(-3, 3);
			z = 5;//lhrandom(2, 5);
			body = bodies + numbodies++;
			Ragdoll_NewBody(body, 4, 6);
			Ragdoll_SetParticle(body, 0, x+0, y+0, z+0,  0,  0,  0);
			Ragdoll_SetParticle(body, 1, x+1, y+0, z+0,  0,  0, -3);
			Ragdoll_SetParticle(body, 2, x+0, y+1, z+0,  0,  0,  0);
			Ragdoll_SetParticle(body, 3, x+0, y+0, z+1,  3,  0,  0);
			Ragdoll_SetStick(body, 0, type, 0, 1, 0.0f, 1);
			Ragdoll_SetStick(body, 1, type, 0, 2, 0.0f, 1);
			Ragdoll_SetStick(body, 2, type, 0, 3, 0.0f, 1);
			Ragdoll_SetStick(body, 3, type, 1, 2, 0.0f, 1);
			Ragdoll_SetStick(body, 4, type, 1, 3, 0.0f, 1);
			Ragdoll_SetStick(body, 5, type, 2, 3, 0.0f, 1);
			Ragdoll_RecalculateBounds(body);
		}
		for (i = 0, body = bodies;i < numbodies;i++, body++)
			Ragdoll_MoveBody(body, step, 0, 0, -9.82, 1.0 / 32.0, 10, 20);
		for (i = 0, body = bodies;i < numbodies;i++, body++)
			Ragdoll_ConstrainBody(body, step, 8);
		if (frame % 8 == 0)
		{
			printf("FRAME %i", frame);
			for (i = 0, body = bodies;i < numbodies;i++, body++)
				for (j = 0, p = body->particles;j < body->numparticles;j++, p++)
					printf(" : %f %f %f", p->origin.v[0], p->origin.v[1], p->origin.v[2]);
			printf("\n");
		}
	}
	Ragdoll_Quit();
	return 0;
}
#endif
