
#include <memory.h>
#include <math.h>
#include "lhragdoll.h"

#ifdef _MSC_VER
#pragma warning(disable : 4244)
#endif

#define LHRAGDOLL_MAX_PARTICLES_PER_BODY 256
#define LHRAGDOLL_SLEEPFRAMES 3

void LHRagdoll_Setup(LHRagdollBody *body, unsigned int numparticles, LHRagdollParticle *particles, unsigned int numsticks, LHRagdollStick *sticks)
{
	memset(body, 0, sizeof(*body));
	body->numparticles = numparticles;
	body->numsticks = numsticks;
	body->particles = particles;
	body->sticks = sticks;
}

void LHRagdoll_SetParticle(LHRagdollBody *body, int subindex, LHRagdollScalar radius, LHRagdollScalar x, LHRagdollScalar y, LHRagdollScalar z, LHRagdollScalar vx, LHRagdollScalar vy, LHRagdollScalar vz)
{
	LHRagdollParticle p;
	if (subindex < 0 || subindex >= body->numparticles)
		return;
	memset(&p, 0, sizeof(p));
	p.origin.v[0] = (LHRagdollScalar)x;
	p.origin.v[1] = (LHRagdollScalar)y;
	p.origin.v[2] = (LHRagdollScalar)z;
	p.velocity.v[0] = (LHRagdollScalar)vx;
	p.velocity.v[1] = (LHRagdollScalar)vy;
	p.velocity.v[2] = (LHRagdollScalar)vz;
	p.radius = radius;
	body->particles[subindex] = p;
}

void LHRagdoll_SetStick(LHRagdollBody *body, int subindex, LHRagdollStickType type, int p1, int p2, LHRagdollScalar dist, int useautomaticdistance)
{
	LHRagdollStick s;
	LHRagdollScalar v[3];
	if (subindex < 0 || subindex >= body->numsticks)
		return;
	memset(&s, 0, sizeof(s));
	s.particleindices[0] = p1;
	s.particleindices[1] = p2;
	s.type = type;
	if (useautomaticdistance)
	{
		v[0] = body->particles[p2].origin.v[0] - body->particles[p1].origin.v[0];
		v[1] = body->particles[p2].origin.v[1] - body->particles[p1].origin.v[1];
		v[2] = body->particles[p2].origin.v[2] - body->particles[p1].origin.v[2];
		s.dist = sqrt(v[0]*v[0]+v[1]*v[1]+v[2]*v[2]) * dist;
	}
	else
		s.dist = dist;
	s.distsquared = s.dist * s.dist;
	body->sticks[subindex] = s;
}

void LHRagdoll_RecalculateBounds(LHRagdollBody *body)
{
	int i;
	LHRagdollParticle *p;
	if (!body->particles)
		return;
	body->mins = body->maxs = body->particles->origin;
	for (i = 1, p = body->particles;i < body->numparticles;i++, p++)
	{
		if (body->mins.v[0] > p->origin.v[0]) body->mins.v[0] = p->origin.v[0];
		if (body->mins.v[1] > p->origin.v[1]) body->mins.v[1] = p->origin.v[1];
		if (body->mins.v[2] > p->origin.v[2]) body->mins.v[2] = p->origin.v[2];
		if (body->maxs.v[0] < p->origin.v[0]) body->maxs.v[0] = p->origin.v[0];
		if (body->maxs.v[1] < p->origin.v[1]) body->maxs.v[1] = p->origin.v[1];
		if (body->maxs.v[2] < p->origin.v[2]) body->maxs.v[2] = p->origin.v[2];
	}
}

void LHRagdoll_MoveBody(LHRagdollBody *body, LHRagdollScalar step, LHRagdollScalar accelx, LHRagdollScalar accely, LHRagdollScalar accelz, LHRagdollScalar friction, LHRagdollScalar stiction, LHRagdollScalar sleepdist, void (*callback_trace)(LHRagdollTrace *trace))
{
	int i;
	int j;
	LHRagdollScalar t;
	LHRagdollScalar f;
	LHRagdollScalar halfstep = 0.5f * step;
	LHRagdollScalar halfaccel[3];
	LHRagdollVector oldorigin, v;
	LHRagdollParticle *p;
	LHRagdollTrace trace;

	// ignore really tiny steps because they do nothing
	if (step == 0)
		return;

	// a body that has come to rest has no reason to move
	if (body->sleep >= LHRAGDOLL_SLEEPFRAMES)
		return;

	// multiply friction by step to keep the math simpler later
	friction *= step;
	stiction *= step;
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

	// put the body to sleep - it will wake up if any of the particles move enough
	body->sleep++;
	sleepdist *= step;

	// move particles
	for (i = 0, p = body->particles;i < body->numparticles;i++, p++)
	{
		// save the old position
		oldorigin = p->origin;
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
			trace.radius = p->radius;
			callback_trace(&trace);
			f = trace.fraction * t;
			p->origin.v[0] += f * p->velocity.v[0];
			p->origin.v[1] += f * p->velocity.v[1];
			p->origin.v[2] += f * p->velocity.v[2];
			t -= f;
			if (trace.fraction < 1)
			{
				// project particle onto plane
				// (this eliminates cumulative error, but seems to cause glitches)
				//f = p->origin.v[0] * trace.planenormal[0] + p->origin.v[1] * trace.planenormal[1] + p->origin.v[2] * trace.planenormal[2] - trace.planedist - trace.radius;
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

		// decide if the body is still moving
		if (body->sleep)
		{
			v.v[0] = p->origin.v[0] - oldorigin.v[0];
			v.v[1] = p->origin.v[1] - oldorigin.v[1];
			v.v[2] = p->origin.v[2] - oldorigin.v[2];
			if (v.v[0]*v.v[0] + v.v[1]*v.v[1] + v.v[2]*v.v[2] > sleepdist)
				body->sleep = 0;
		}
	}

	// apply other half of acceleration
	for (i = 0, p = body->particles;i < body->numparticles;i++, p++)
	{
		p->velocity.v[0] += halfaccel[0];
		p->velocity.v[1] += halfaccel[1];
		p->velocity.v[2] += halfaccel[2];
	}

	LHRagdoll_RecalculateBounds(body);
}

void LHRagdoll_ConstrainBody(LHRagdollBody *body, LHRagdollScalar step, int restitutioniterations)
{
	int i;
	int iter;
	LHRagdollScalar d;
	LHRagdollScalar istep;
	LHRagdollScalar v[3];
	LHRagdollStick *s;
	LHRagdollParticle *p;
	LHRagdollVector *v1;
	LHRagdollVector *v2;
	LHRagdollVector futurepositions[LHRAGDOLL_MAX_PARTICLES_PER_BODY];

	// ignore really tiny steps because they produce divide by zero errors
	if (step == 0)
		return;

	// a body that has come to rest has no reason to move
	if (body->sleep >= LHRAGDOLL_SLEEPFRAMES)
		return;

	// don't crash if there are too many particles for the stack to hold
	if (body->numparticles > LHRAGDOLL_MAX_PARTICLES_PER_BODY)
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
			case LHRAGDOLLSTICK_CLOTH:
				d = s->distsquared / (d + s->distsquared) - 0.5f;
				break;
			case LHRAGDOLLSTICK_MINDIST:
				// mindist constraints only apply if too close
				if (d >= s->distsquared)
					continue;
			case LHRAGDOLLSTICK_NORMAL:
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

void LHRagdoll_AreaImpulseBody(LHRagdollBody *body, LHRagdollScalar impactx, LHRagdollScalar impacty, LHRagdollScalar impactz, LHRagdollScalar forcex, LHRagdollScalar forcey, LHRagdollScalar forcez, LHRagdollScalar radius, LHRagdollScalar sphereforce, LHRagdollScalar attenuationpower)
{
	int i;
	LHRagdollParticle *p;
	LHRagdollScalar v[3];
	LHRagdollScalar distsquared;
	LHRagdollScalar dist;
	LHRagdollScalar d;
	LHRagdollScalar sf;

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
		body->sleep = 0;
	}
}

void LHRagdoll_PointImpulseBody(LHRagdollBody *body, LHRagdollScalar impactx, LHRagdollScalar impacty, LHRagdollScalar impactz, LHRagdollScalar forcex, LHRagdollScalar forcey, LHRagdollScalar forcez)
{
	int i;
	LHRagdollParticle *p;
	LHRagdollScalar v[3];
	LHRagdollScalar f;
	LHRagdollScalar distsquared;
	LHRagdollScalar bestdistsquared[2];
	LHRagdollScalar bestdist[2];
	int best[2];

	body->sleep = 0;
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
