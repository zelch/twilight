
#include <stdlib.h>
#include <stdio.h>
#include <memory.h>
#include <math.h>

#ifdef _MSC_VER
#pragma warning(disable : 4244)
#endif

#define RAGDOLL_MAX_PARTICLES_PER_BODY 256
#define RAGDOLL_SLEEPFRAMES 3

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
	RagdollScalar radius;
	RagdollScalar end[3];
	RagdollScalar fraction;
	RagdollScalar planenormal[3];
	RagdollScalar planedist;
}
RagdollTrace;

typedef struct RagdollParticle
{
	RagdollVector origin;
	RagdollVector velocity;
	RagdollScalar radius;
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
	int sleep; // if true the body is not moving at all
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

void Ragdoll_SetParticle(RagdollBody *body, int subindex, RagdollScalar radius, RagdollScalar x, RagdollScalar y, RagdollScalar z, RagdollScalar vx, RagdollScalar vy, RagdollScalar vz)
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
	p.radius = radius;
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
		s.dist = sqrt(v[0]*v[0]+v[1]*v[1]+v[2]*v[2]) * dist;
	}
	else
		s.dist = dist;
	s.distsquared = s.dist * s.dist;
	body->sticks[subindex] = s;
}

void Ragdoll_MoveBody(RagdollBody *body, RagdollScalar step, RagdollScalar accelx, RagdollScalar accely, RagdollScalar accelz, RagdollScalar nudge, RagdollScalar friction, RagdollScalar stiction, RagdollScalar sleepdist)
{
	int i;
	int j;
	RagdollScalar t;
	RagdollScalar f;
	RagdollScalar halfstep = 0.5f * step;
	RagdollScalar halfaccel[3];
	RagdollVector oldorigin, v;
	RagdollParticle *p;
	RagdollTrace trace;

	// ignore really tiny steps because they do nothing
	if (step == 0)
		return;

	// a body that has come to rest has no reason to move
	if (body->sleep >= RAGDOLL_SLEEPFRAMES)
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
			Ragdoll.callback_trace(&trace);
			f = trace.fraction * t;
			p->origin.v[0] += f * p->velocity.v[0];
			p->origin.v[1] += f * p->velocity.v[1];
			p->origin.v[2] += f * p->velocity.v[2];
			t -= f;
			if (trace.fraction < 1)
			{
				// project particle onto plane at the specified nudge
				// (this eliminates cumulative error, but seems to cause glitches)
				f = p->origin.v[0] * trace.planenormal[0] + p->origin.v[1] * trace.planenormal[1] + p->origin.v[2] * trace.planenormal[2] - trace.planedist - trace.radius;
				p->origin.v[0] -= f * trace.planenormal[0];
				p->origin.v[1] -= f * trace.planenormal[1];
				p->origin.v[2] -= f * trace.planenormal[2];
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

	// a body that has come to rest has no reason to move
	if (body->sleep >= RAGDOLL_SLEEPFRAMES)
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
		body->sleep = 0;
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

#define STANDALONE_TEST 1
#if STANDALONE_TEST
#include <SDL/SDL.h>
#include <SDL/SDL_main.h>
#include <SDL/SDL_opengl.h>

RagdollScalar floorplane[4] = {0.0f, 1.0f, 0.0f, -1.0f};
RagdollScalar nudge = (1.0f / 1024.0f);

void test_trace(RagdollTrace *trace)
{
	RagdollScalar d1;
	RagdollScalar d2;
	trace->fraction = 1;
	// simply test a floor plane
	d1 = trace->start[0] * floorplane[0] + trace->start[1] * floorplane[1] + trace->start[2] * floorplane[2] - floorplane[3] - trace->radius;
	d2 = trace->end[0] * floorplane[0] + trace->end[1] * floorplane[1] + trace->end[2] * floorplane[2] - floorplane[3] - trace->radius;
	if (d1 > 0 && d2 < 0)
	{
		trace->fraction = (d1 - nudge) / (d1 - d2);
		trace->planenormal[0] = floorplane[0];
		trace->planenormal[1] = floorplane[1];
		trace->planenormal[2] = floorplane[2];
		trace->planedist = floorplane[3] + nudge;
	}
}

#define lhrandom(MIN,MAX) (((double)rand() / RAND_MAX) * ((MAX)-(MIN)) + (MIN))
#define MAX_BODIES 128

int main(int argc, char **argv)
{
	int i;
	int j;
	int pause = 0;
	int frame = 0;
	int spew = 0;
	int button = 0;
	int buttons = 0;
	int quit = 0;
	int mousex = 0, mousey = 0;
	int viewwidth = 1024, viewheight = 768;
	int currenttime;
	RagdollScalar step = 1.0f / 64.0f;
	RagdollScalar x, y, z;
	RagdollScalar f;
	double nextframetime = 0;
	double zNear = 0.125;
	double zFar = 1024;
	double ymax = zNear * 0.75;
	double xmax = ymax * viewwidth / viewheight;
	RagdollBody *body;
	RagdollParticle *p;
	RagdollStickType type = RAGDOLLSTICK_NORMAL;
	RagdollVector v;
	RagdollVector mouse;
	RagdollParticle *bestparticle = NULL;
	RagdollBody *bestbody = NULL;
	RagdollScalar bestparticledist = 0;
	RagdollScalar dist = 0;
	double modelviewmatrix[16];
	double projectionmatrix[16];
	int numbodies = 0;
	RagdollBody bodies[MAX_BODIES];
	SDL_Surface *sdlsurface;
	SDL_Event event;

	SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER);
	SDL_GL_LoadLibrary(NULL);
	SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
	SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, 1);
	SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 4);
	SDL_GL_SetAttribute(SDL_GL_SWAP_CONTROL, 1);
	sdlsurface = SDL_SetVideoMode(viewwidth, viewheight, 32, SDL_OPENGL);
	SDL_WM_SetCaption("ragdoll test", NULL);

	SDL_EnableKeyRepeat(SDL_DEFAULT_REPEAT_DELAY, SDL_DEFAULT_REPEAT_INTERVAL);

	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glFrustum(-xmax, xmax, -ymax, ymax, zNear, zFar);
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();

	glDisable(GL_TEXTURE_2D);
	glEnable(GL_DEPTH_TEST);
	glDisable(GL_CULL_FACE);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

	Ragdoll_Init(printf, malloc, free, test_trace);
	nextframetime = SDL_GetTicks();
	// run physics
	for (;;)
	{
		while (SDL_PollEvent(&event))
		{
			switch (event.type)
			{
			case SDL_KEYDOWN:
				switch (event.key.keysym.sym)
				{
				case SDLK_t:
					if (numbodies == MAX_BODIES)
						break;
					// create a tetrahedron
					x = lhrandom(-3, 3);
					y = 5;
					z = -6 + lhrandom(-3, 3);
					body = bodies + numbodies++;
					Ragdoll_NewBody(body, 4, 6);
					Ragdoll_SetParticle(body, 0, 0.0f, x+0, y+0, z+0, lhrandom(-3, 3), lhrandom(-3, 3), lhrandom(-3, 3));
					Ragdoll_SetParticle(body, 1, 0.0f, x+1, y+0, z+0, lhrandom(-3, 3), lhrandom(-3, 3), lhrandom(-3, 3));
					Ragdoll_SetParticle(body, 2, 0.0f, x+0, y+1, z+0, lhrandom(-3, 3), lhrandom(-3, 3), lhrandom(-3, 3));
					Ragdoll_SetParticle(body, 3, 0.0f, x+0, y+0, z+1, lhrandom(-3, 3), lhrandom(-3, 3), lhrandom(-3, 3));
					Ragdoll_SetStick(body, 0, type, 0, 1, 1.0f, 1);
					Ragdoll_SetStick(body, 1, type, 0, 2, 1.0f, 1);
					Ragdoll_SetStick(body, 2, type, 0, 3, 1.0f, 1);
					Ragdoll_SetStick(body, 3, type, 1, 2, 1.0f, 1);
					Ragdoll_SetStick(body, 4, type, 1, 3, 1.0f, 1);
					Ragdoll_SetStick(body, 5, type, 2, 3, 1.0f, 1);
					Ragdoll_RecalculateBounds(body);
					break;
				case SDLK_w:
					if (numbodies == MAX_BODIES)
						break;
					// create a ragdoll similar to the one in the article "Advanced Character Physics" on Gamasutra
					x = lhrandom(-3, 3);
					y = floorplane[3];
					z = -6 + lhrandom(-3, 3);
					body = bodies + numbodies++;
					Ragdoll_NewBody(body, 35, 97);
					Ragdoll_SetParticle(body,  0, 0.20f, x+0.00f, y+1.82f, z-0.00f, 0, 0, 0); //  0 head
					Ragdoll_SetParticle(body,  1, 0.15f, x+0.00f, y+1.75f, z-0.00f, 0, 0, 0); //  1 neck
					Ragdoll_SetParticle(body,  2, 0.15f, x+0.00f, y+1.48f, z-0.00f, 0, 0, 0); //  2 spine1
					Ragdoll_SetParticle(body,  3, 0.15f, x+0.00f, y+1.41f, z+0.01f, 0, 0, 0); //  3 spine2
					Ragdoll_SetParticle(body,  4, 0.15f, x+0.00f, y+1.35f, z+0.01f, 0, 0, 0); //  4 spine3
					Ragdoll_SetParticle(body,  5, 0.15f, x+0.00f, y+1.29f, z+0.01f, 0, 0, 0); //  5 spine4
					Ragdoll_SetParticle(body,  6, 0.15f, x+0.00f, y+1.22f, z-0.00f, 0, 0, 0); //  6 spine5
					Ragdoll_SetParticle(body,  7, 0.15f, x-0.10f, y+1.73f, z-0.00f, 0, 0, 0); //  7 right collar
					Ragdoll_SetParticle(body,  8, 0.15f, x-0.22f, y+1.62f, z-0.00f, 0, 0, 0); //  8 right shoulder
					Ragdoll_SetParticle(body,  9, 0.05f, x-0.43f, y+1.46f, z-0.00f, 0, 0, 0); //  9 right elbow
					Ragdoll_SetParticle(body, 10, 0.05f, x-0.66f, y+1.28f, z-0.00f, 0, 0, 0); // 10 right wrist
					Ragdoll_SetParticle(body, 11, 0.12f, x-0.13f, y+1.13f, z-0.00f, 0, 0, 0); // 11 right hip
					Ragdoll_SetParticle(body, 12, 0.05f, x-0.13f, y+0.60f, z-0.03f, 0, 0, 0); // 12 right knee
					Ragdoll_SetParticle(body, 13, 0.05f, x-0.12f, y+0.18f, z-0.00f, 0, 0, 0); // 13 right sock
					Ragdoll_SetParticle(body, 14, 0.05f, x-0.12f, y+0.10f, z-0.00f, 0, 0, 0); // 14 right ankle
					Ragdoll_SetParticle(body, 15, 0.05f, x-0.13f, y+0.04f, z-0.00f, 0, 0, 0); // 15 right foot
					Ragdoll_SetParticle(body, 16, 0.15f, x+0.10f, y+1.73f, z-0.00f, 0, 0, 0); // 16 left collar
					Ragdoll_SetParticle(body, 17, 0.15f, x+0.22f, y+1.62f, z-0.00f, 0, 0, 0); // 17 left shoulder
					Ragdoll_SetParticle(body, 18, 0.05f, x+0.43f, y+1.46f, z-0.00f, 0, 0, 0); // 18 left elbow
					Ragdoll_SetParticle(body, 19, 0.05f, x+0.66f, y+1.28f, z-0.00f, 0, 0, 0); // 19 left wrist
					Ragdoll_SetParticle(body, 20, 0.12f, x+0.13f, y+1.13f, z-0.00f, 0, 0, 0); // 20 left hip
					Ragdoll_SetParticle(body, 21, 0.05f, x+0.13f, y+0.60f, z-0.03f, 0, 0, 0); // 21 left knee
					Ragdoll_SetParticle(body, 22, 0.05f, x+0.12f, y+0.18f, z-0.00f, 0, 0, 0); // 22 left sock
					Ragdoll_SetParticle(body, 23, 0.05f, x+0.12f, y+0.10f, z-0.00f, 0, 0, 0); // 23 left ankle
					Ragdoll_SetParticle(body, 24, 0.05f, x+0.13f, y+0.04f, z-0.00f, 0, 0, 0); // 24 left foot
					Ragdoll_SetParticle(body, 25, 0.05f, x-0.09f, y+1.13f, z-0.00f, 0, 0, 0); // 25 right hip (inner)
					Ragdoll_SetParticle(body, 26, 0.05f, x-0.09f, y+0.60f, z-0.03f, 0, 0, 0); // 26 right knee (inner)
					Ragdoll_SetParticle(body, 27, 0.05f, x-0.08f, y+0.18f, z-0.00f, 0, 0, 0); // 27 right sock (inner)
					Ragdoll_SetParticle(body, 28, 0.05f, x-0.08f, y+0.10f, z-0.00f, 0, 0, 0); // 28 right ankle (inner)
					Ragdoll_SetParticle(body, 29, 0.05f, x-0.09f, y+0.04f, z-0.00f, 0, 0, 0); // 29 right foot (inner)
					Ragdoll_SetParticle(body, 30, 0.05f, x+0.09f, y+1.13f, z-0.00f, 0, 0, 0); // 30 left hip (inner)
					Ragdoll_SetParticle(body, 31, 0.05f, x+0.09f, y+0.60f, z-0.03f, 0, 0, 0); // 31 left knee (inner)
					Ragdoll_SetParticle(body, 32, 0.05f, x+0.08f, y+0.18f, z-0.00f, 0, 0, 0); // 32 left sock (inner)
					Ragdoll_SetParticle(body, 33, 0.05f, x+0.08f, y+0.10f, z-0.00f, 0, 0, 0); // 33 left ankle (inner)
					Ragdoll_SetParticle(body, 34, 0.05f, x+0.09f, y+0.04f, z-0.00f, 0, 0, 0); // 34 left foot (inner)
					Ragdoll_SetStick(body,  0, type                ,  0,  1, 1.0f, 1);
					Ragdoll_SetStick(body,  1, type                ,  1,  2, 1.0f, 1);
					Ragdoll_SetStick(body,  2, type                ,  1,  7, 1.0f, 1);
					Ragdoll_SetStick(body,  3, type                ,  1, 16, 1.0f, 1);
					Ragdoll_SetStick(body,  4, type                ,  2,  3, 1.0f, 1);
					Ragdoll_SetStick(body,  5, type                ,  3,  4, 1.0f, 1);
					Ragdoll_SetStick(body,  6, type                ,  4,  5, 1.0f, 1);
					Ragdoll_SetStick(body,  7, type                ,  5,  6, 1.0f, 1);
					Ragdoll_SetStick(body,  8, type                ,  6, 11, 1.0f, 1);
					Ragdoll_SetStick(body,  9, type                ,  6, 20, 1.0f, 1);
					Ragdoll_SetStick(body, 10, type                ,  7,  8, 1.0f, 1);
					Ragdoll_SetStick(body, 11, type                ,  8,  9, 1.0f, 1);
					Ragdoll_SetStick(body, 12, type                ,  9, 10, 1.0f, 1);
					Ragdoll_SetStick(body, 13, type                , 11, 12, 1.0f, 1);
					Ragdoll_SetStick(body, 14, type                , 12, 13, 1.0f, 1);
					Ragdoll_SetStick(body, 15, type                , 13, 14, 1.0f, 1);
					Ragdoll_SetStick(body, 16, type                , 14, 15, 1.0f, 1);
					Ragdoll_SetStick(body, 17, type                , 16, 17, 1.0f, 1);
					Ragdoll_SetStick(body, 18, type                , 17, 18, 1.0f, 1);
					Ragdoll_SetStick(body, 19, type                , 18, 19, 1.0f, 1);
					Ragdoll_SetStick(body, 20, type                , 20, 21, 1.0f, 1);
					Ragdoll_SetStick(body, 21, type                , 21, 22, 1.0f, 1);
					Ragdoll_SetStick(body, 22, type                , 22, 23, 1.0f, 1);
					Ragdoll_SetStick(body, 23, type                , 23, 24, 1.0f, 1);
					Ragdoll_SetStick(body, 24, type                ,  7, 11, 1.0f, 1);
					Ragdoll_SetStick(body, 25, type                , 16, 20, 1.0f, 1);
					Ragdoll_SetStick(body, 26, type                ,  7, 16, 1.0f, 1);
					Ragdoll_SetStick(body, 27, type                ,  8, 17, 1.0f, 1);
					Ragdoll_SetStick(body, 28, type                ,  8, 11, 1.0f, 1);
					Ragdoll_SetStick(body, 29, type                ,  8, 20, 1.0f, 1);
					Ragdoll_SetStick(body, 30, type                , 17, 11, 1.0f, 1);
					Ragdoll_SetStick(body, 31, type                , 17, 20, 1.0f, 1);
					Ragdoll_SetStick(body, 32, type                , 11, 20, 1.0f, 1);
					Ragdoll_SetStick(body, 33, type                ,  7, 20, 1.0f, 1);
					Ragdoll_SetStick(body, 34, type                , 16, 11, 1.0f, 1);
					Ragdoll_SetStick(body, 35, RAGDOLLSTICK_MINDIST, 12, 21, 0.5f, 1);
					Ragdoll_SetStick(body, 36, RAGDOLLSTICK_MINDIST, 13, 22, 0.5f, 1);
					Ragdoll_SetStick(body, 37, RAGDOLLSTICK_MINDIST, 14, 23, 0.5f, 1);
					Ragdoll_SetStick(body, 38, RAGDOLLSTICK_MINDIST, 15, 24, 0.5f, 1);
					Ragdoll_SetStick(body, 39, RAGDOLLSTICK_MINDIST,  0,  2, 0.8f, 1);
					Ragdoll_SetStick(body, 40, RAGDOLLSTICK_MINDIST,  0,  7, 0.8f, 1);
					Ragdoll_SetStick(body, 41, RAGDOLLSTICK_MINDIST,  0, 16, 0.8f, 1);
					Ragdoll_SetStick(body, 42, RAGDOLLSTICK_MINDIST, 10, 20, 0.8f, 1);
					Ragdoll_SetStick(body, 43, RAGDOLLSTICK_MINDIST, 11, 19, 0.8f, 1);
					Ragdoll_SetStick(body, 44, RAGDOLLSTICK_MINDIST,  9, 20, 0.8f, 1);
					Ragdoll_SetStick(body, 45, RAGDOLLSTICK_MINDIST, 11, 18, 0.8f, 1);
					Ragdoll_SetStick(body, 46, RAGDOLLSTICK_MINDIST,  0,  8, 0.8f, 1);
					Ragdoll_SetStick(body, 47, RAGDOLLSTICK_MINDIST,  0, 17, 0.8f, 1);
					Ragdoll_SetStick(body, 48, type                ,  6, 11, 1.0f, 1);
					Ragdoll_SetStick(body, 49, type                ,  6, 20, 1.0f, 1);
					Ragdoll_SetStick(body, 50, type                ,  6, 25, 1.0f, 1);
					Ragdoll_SetStick(body, 51, type                ,  6, 30, 1.0f, 1);
					Ragdoll_SetStick(body, 52, type                , 11, 25, 1.0f, 1);
					Ragdoll_SetStick(body, 53, type                , 12, 26, 1.0f, 1);
					Ragdoll_SetStick(body, 54, type                , 13, 27, 1.0f, 1);
					Ragdoll_SetStick(body, 55, type                , 14, 28, 1.0f, 1);
					Ragdoll_SetStick(body, 56, type                , 15, 29, 1.0f, 1);
					Ragdoll_SetStick(body, 57, type                , 20, 30, 1.0f, 1);
					Ragdoll_SetStick(body, 58, type                , 21, 31, 1.0f, 1);
					Ragdoll_SetStick(body, 59, type                , 22, 32, 1.0f, 1);
					Ragdoll_SetStick(body, 60, type                , 23, 33, 1.0f, 1);
					Ragdoll_SetStick(body, 61, type                , 24, 34, 1.0f, 1);
					Ragdoll_SetStick(body, 62, type                , 25, 26, 1.0f, 1);
					Ragdoll_SetStick(body, 63, type                , 26, 27, 1.0f, 1);
					Ragdoll_SetStick(body, 64, type                , 27, 28, 1.0f, 1);
					Ragdoll_SetStick(body, 65, type                , 28, 29, 1.0f, 1);
					Ragdoll_SetStick(body, 66, type                , 30, 31, 1.0f, 1);
					Ragdoll_SetStick(body, 67, type                , 31, 32, 1.0f, 1);
					Ragdoll_SetStick(body, 68, type                , 32, 33, 1.0f, 1);
					Ragdoll_SetStick(body, 69, type                , 33, 34, 1.0f, 1);
					Ragdoll_SetStick(body, 70, type                , 11, 26, 1.0f, 1);
					Ragdoll_SetStick(body, 71, type                , 25, 12, 1.0f, 1);
					Ragdoll_SetStick(body, 72, type                , 12, 27, 1.0f, 1);
					Ragdoll_SetStick(body, 73, type                , 26, 13, 1.0f, 1);
					Ragdoll_SetStick(body, 74, type                , 13, 28, 1.0f, 1);
					Ragdoll_SetStick(body, 75, type                , 27, 14, 1.0f, 1);
					Ragdoll_SetStick(body, 76, type                , 14, 29, 1.0f, 1);
					Ragdoll_SetStick(body, 77, type                , 28, 15, 1.0f, 1);
					Ragdoll_SetStick(body, 78, type                , 20, 31, 1.0f, 1);
					Ragdoll_SetStick(body, 79, type                , 30, 21, 1.0f, 1);
					Ragdoll_SetStick(body, 80, type                , 21, 32, 1.0f, 1);
					Ragdoll_SetStick(body, 81, type                , 31, 22, 1.0f, 1);
					Ragdoll_SetStick(body, 82, type                , 22, 33, 1.0f, 1);
					Ragdoll_SetStick(body, 83, type                , 32, 23, 1.0f, 1);
					Ragdoll_SetStick(body, 84, type                , 23, 34, 1.0f, 1);
					Ragdoll_SetStick(body, 85, type                , 33, 24, 1.0f, 1);
					Ragdoll_SetStick(body, 86, RAGDOLLSTICK_MINDIST,  4, 12, 0.7f, 1);
					Ragdoll_SetStick(body, 87, RAGDOLLSTICK_MINDIST,  4, 21, 0.7f, 1);
					Ragdoll_SetStick(body, 88, RAGDOLLSTICK_MINDIST,  4, 26, 0.7f, 1);
					Ragdoll_SetStick(body, 89, RAGDOLLSTICK_MINDIST,  4, 31, 0.7f, 1);
					Ragdoll_SetStick(body, 90, RAGDOLLSTICK_MINDIST,  4, 10, 0.7f, 1);
					Ragdoll_SetStick(body, 91, RAGDOLLSTICK_MINDIST,  4, 19, 0.7f, 1);
					Ragdoll_SetStick(body, 92, RAGDOLLSTICK_MINDIST,  4,  0, 0.9f, 1);
					Ragdoll_SetStick(body, 93, RAGDOLLSTICK_MINDIST,  4,  9, 0.7f, 1);
					Ragdoll_SetStick(body, 94, RAGDOLLSTICK_MINDIST,  4, 18, 0.7f, 1);
					Ragdoll_SetStick(body, 95, RAGDOLLSTICK_MINDIST,  4, 13, 0.7f, 1);
					Ragdoll_SetStick(body, 96, RAGDOLLSTICK_MINDIST,  4, 22, 0.7f, 1);
					Ragdoll_RecalculateBounds(body);
					body->sleep = RAGDOLL_SLEEPFRAMES;
					//Ragdoll_PointImpulseBody(body, x + lhrandom(-0.66f, 0.66f), y + lhrandom(0.00f, 2.00f), z + 0.05f, lhrandom( -30,  30), lhrandom( -30,  30), lhrandom(-300, 0));
					break;
				case SDLK_h:
					if (numbodies == MAX_BODIES)
						break;
					// create a tetrahedron
					x = lhrandom(-3, 3);
					y = floorplane[3];
					z = -6 + lhrandom(-3, 3);
					body = bodies + numbodies++;
					Ragdoll_NewBody(body, 16, 36);
					Ragdoll_SetParticle(body,  0, 0.05f, x+0.00f, y+2.00f, z, 0, 0, 0); // head
					Ragdoll_SetParticle(body,  1, 0.05f, x+0.00f, y+1.70f, z, 0, 0, 0); // neck
					Ragdoll_SetParticle(body,  2, 0.05f, x-0.30f, y+1.40f, z, 0, 0, 0); // right shoulder
					Ragdoll_SetParticle(body,  3, 0.05f, x+0.30f, y+1.40f, z, 0, 0, 0); // left shoulder
					Ragdoll_SetParticle(body,  4, 0.05f, x-0.50f, y+1.10f, z, 0, 0, 0); // right elbow
					Ragdoll_SetParticle(body,  5, 0.05f, x-0.50f, y+0.90f, z, 0, 0, 0); // right hand
					Ragdoll_SetParticle(body,  6, 0.05f, x+0.50f, y+1.10f, z, 0, 0, 0); // left elbow
					Ragdoll_SetParticle(body,  7, 0.05f, x+0.50f, y+0.90f, z, 0, 0, 0); // left hand
					Ragdoll_SetParticle(body,  8, 0.05f, x-0.20f, y+1.00f, z, 0, 0, 0); // right waist
					Ragdoll_SetParticle(body,  9, 0.05f, x+0.20f, y+1.00f, z, 0, 0, 0); // left waist
					Ragdoll_SetParticle(body, 10, 0.05f, x-0.25f, y+0.85f, z, 0, 0, 0); // right hip
					Ragdoll_SetParticle(body, 11, 0.05f, x+0.25f, y+0.85f, z, 0, 0, 0); // left hip
					Ragdoll_SetParticle(body, 12, 0.05f, x-0.30f, y+0.40f, z, 0, 0, 0); // right knee
					Ragdoll_SetParticle(body, 13, 0.05f, x-0.30f, y+0.40f, z, 0, 0, 0); // right foot
					Ragdoll_SetParticle(body, 14, 0.05f, x+0.30f, y+0.00f, z, 0, 0, 0); // left knee
					Ragdoll_SetParticle(body, 15, 0.05f, x+0.30f, y+0.00f, z, 0, 0, 0); // left foot
					Ragdoll_SetStick(body,  0, type                ,  0,  1, 1.0f, 1); // head to neck
					Ragdoll_SetStick(body,  1, type                ,  1,  2, 1.0f, 1); // neck to right shoulder
					Ragdoll_SetStick(body,  2, type                ,  1,  3, 1.0f, 1); // neck to left shoulder
					Ragdoll_SetStick(body,  3, type                ,  1,  8, 1.0f, 1); // neck to right waist
					Ragdoll_SetStick(body,  4, type                ,  1,  9, 1.0f, 1); // neck to left waist
					Ragdoll_SetStick(body,  5, type                ,  2,  3, 1.0f, 1); // right shoulder to left shoulder
					Ragdoll_SetStick(body,  6, type                ,  2,  4, 1.0f, 1); // right shoulder to right elbow
					Ragdoll_SetStick(body,  7, type                ,  2,  8, 1.0f, 1); // right shoulder to right waist
					Ragdoll_SetStick(body,  8, type                ,  2,  9, 1.0f, 1); // right shoulder to left waist
					Ragdoll_SetStick(body,  9, type                ,  3,  6, 1.0f, 1); // left shoulder to left elbow
					Ragdoll_SetStick(body, 10, type                ,  3,  8, 1.0f, 1); // left shoulder to right waist
					Ragdoll_SetStick(body, 11, type                ,  3,  9, 1.0f, 1); // left shoulder to left waist
					Ragdoll_SetStick(body, 12, type                ,  4,  5, 1.0f, 1); // right elbow to right hand
					Ragdoll_SetStick(body, 13, type                ,  6,  7, 1.0f, 1); // left elbow to left hand
					Ragdoll_SetStick(body, 14, type                ,  8,  9, 1.0f, 1); // right waist to left waist
					Ragdoll_SetStick(body, 15, type                ,  8, 10, 1.0f, 1); // right waist to right hip
					Ragdoll_SetStick(body, 16, type                ,  8, 11, 1.0f, 1); // right waist to left hip
					Ragdoll_SetStick(body, 17, type                ,  9, 10, 1.0f, 1); // left waist to right hip
					Ragdoll_SetStick(body, 18, type                ,  9, 11, 1.0f, 1); // left waist to left hip
					Ragdoll_SetStick(body, 19, type                , 10, 11, 1.0f, 1); // right hip to left hip
					Ragdoll_SetStick(body, 20, type                , 10, 12, 1.0f, 1); // right hip to right knee
					Ragdoll_SetStick(body, 21, type                , 11, 14, 1.0f, 1); // left hip to left knee
					Ragdoll_SetStick(body, 22, type                , 12, 13, 1.0f, 1); // right knee to right foot
					Ragdoll_SetStick(body, 23, type                , 14, 15, 1.0f, 1); // left knee to left foot
					Ragdoll_SetStick(body, 24, RAGDOLLSTICK_MINDIST,  4,  9, 0.8f, 1); // right elbow to left waist
					Ragdoll_SetStick(body, 25, RAGDOLLSTICK_MINDIST,  6,  8, 0.8f, 1); // left elbow to right waist
					Ragdoll_SetStick(body, 26, RAGDOLLSTICK_MINDIST,  5,  8, 0.8f, 1); // right hand to right waist
					Ragdoll_SetStick(body, 27, RAGDOLLSTICK_MINDIST,  7,  9, 0.8f, 1); // left hand to left waist
					Ragdoll_SetStick(body, 28, RAGDOLLSTICK_MINDIST, 12, 14, 0.8f, 1); // right knee to left knee
					Ragdoll_SetStick(body, 29, RAGDOLLSTICK_MINDIST, 13, 15, 0.8f, 1); // right foot to left foot
					Ragdoll_SetStick(body, 30, RAGDOLLSTICK_MINDIST,  2, 10, 0.8f, 1); // right shoulder to right hip
					Ragdoll_SetStick(body, 31, RAGDOLLSTICK_MINDIST,  3, 11, 0.8f, 1); // left shoulder to left hip
					Ragdoll_SetStick(body, 32, RAGDOLLSTICK_MINDIST,  0,  2, 0.8f, 1); // head to right shoulder
					Ragdoll_SetStick(body, 33, RAGDOLLSTICK_MINDIST,  0,  3, 0.8f, 1); // head to left shoulder
					Ragdoll_SetStick(body, 32, RAGDOLLSTICK_MINDIST,  0,  8, 0.8f, 1); // head to right shoulder
					Ragdoll_SetStick(body, 33, RAGDOLLSTICK_MINDIST,  0,  9, 0.8f, 1); // head to left shoulder
					Ragdoll_SetStick(body, 34, RAGDOLLSTICK_MINDIST, 10, 13, 0.7f, 1); // right hip to right foot
					Ragdoll_SetStick(body, 35, RAGDOLLSTICK_MINDIST, 11, 15, 0.7f, 1); // right hip to right foot
					Ragdoll_RecalculateBounds(body);
					body->sleep = RAGDOLL_SLEEPFRAMES;
					break;
				case SDLK_SPACE:
					pause = 2;
					break;
				case SDLK_RETURN:
					pause = 0;
					break;
				case SDLK_DELETE:
					if (numbodies > 0)
						Ragdoll_DestroyBody(bodies + --numbodies);
					break;
				case SDLK_ESCAPE:
					quit = 1;
					break;
				default:
					break;
				}
				break;
			case SDL_QUIT:
				quit = 1;
				break;
			case SDL_MOUSEBUTTONDOWN:
				button = event.button.button;
				break;
			case SDL_MOUSEBUTTONUP:
				button = 0;
				break;
			default:
				break;
			}
		}
		if (quit)
			break;

		buttons = SDL_GetMouseState(&mousex, &mousey);
		mouse.v[0] = mousex;
		mouse.v[1] = mousey;
		mouse.v[2] = 0.0f;

		if (pause != 1)
		{
			if (pause == 2)
				pause = 1;
			for (i = 0, body = bodies;i < numbodies;i++, body++)
				Ragdoll_MoveBody(body, step, 0.0f, -9.82f, 0.0f, nudge, 0.25f, 0.125f, 0.0005f);
			for (i = 0, body = bodies;i < numbodies;i++, body++)
				Ragdoll_ConstrainBody(body, step, 16);
			if (spew)
			{
				printf("FRAME %i", frame);
				for (i = 0, body = bodies;i < numbodies;i++, body++)
					for (j = 0, p = body->particles;j < body->numparticles;j++, p++)
						printf(" : %f %f %f", p->origin.v[0], p->origin.v[1], p->origin.v[2]);
				printf("\n");
			}
			frame++;
		}

		nextframetime += 1000 * step;
		currenttime = SDL_GetTicks();
		if (currenttime >= (int)nextframetime)
			continue;
		SDL_Delay((int)nextframetime - currenttime);

		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

		glColor4f(0.5, 0.5, 0.5, 1);
		glBegin(GL_QUADS);
		glVertex3f(-20, floorplane[3], -40);
		glVertex3f( 20, floorplane[3], -40);
		glVertex3f( 20, floorplane[3],   0);
		glVertex3f(-20, floorplane[3],   0);
		glEnd();

		// render shadows of sticks on the floor
		//glDepthMask(GL_FALSE);
		//glEnable(GL_BLEND);
		glBegin(GL_LINES);
		for (i = 0, body = bodies;i < numbodies;i++, body++)
		{
			glColor4f(0.0f, 0.0f, 0.0f, 1.0f);
			for (j = 0;j < body->numsticks;j++)
			{
				if (body->sticks[j].type == RAGDOLLSTICK_MINDIST)
					continue;
				v = body->particles[body->sticks[j].particleindices[0]].origin;
				f = v.v[0] * floorplane[0] + v.v[1] * floorplane[1] + v.v[2] * floorplane[2] - floorplane[3];
				glVertex3f(v.v[0] - f * floorplane[0], v.v[1] - f * floorplane[1], v.v[2] - f * floorplane[2]);
				v = body->particles[body->sticks[j].particleindices[1]].origin;
				f = v.v[0] * floorplane[0] + v.v[1] * floorplane[1] + v.v[2] * floorplane[2] - floorplane[3];
				glVertex3f(v.v[0] - f * floorplane[0], v.v[1] - f * floorplane[1], v.v[2] - f * floorplane[2]);
			}
		}
		glEnd();
		//glDepthMask(GL_TRUE);
		//glDisable(GL_BLEND);

		glBegin(GL_LINES);
		for (i = 0, body = bodies;i < numbodies;i++, body++)
		{
			glColor4f((i & 3) / 3.0f, ((i >> 2) & 3) / 3.0f, ((i >> 4) & 3) / 3.0f, 1);
			for (j = 0;j < body->numsticks;j++)
			{
				if (body->sticks[j].type == RAGDOLLSTICK_MINDIST)
					continue;
				v = body->particles[body->sticks[j].particleindices[0]].origin;
				glVertex3f(v.v[0], v.v[1], v.v[2]);
				v = body->particles[body->sticks[j].particleindices[1]].origin;
				glVertex3f(v.v[0], v.v[1], v.v[2]);
			}
		}
		glEnd();

		glDepthMask(GL_FALSE);
		glEnable(GL_BLEND);
		glBegin(GL_LINES);
		for (i = 0, body = bodies;i < numbodies;i++, body++)
		{
			glColor4f((i & 3) / 3.0f, ((i >> 2) & 3) / 3.0f, ((i >> 4) & 3) / 3.0f, 0.3f);
			for (j = 0;j < body->numsticks;j++)
			{
				if (body->sticks[j].type != RAGDOLLSTICK_MINDIST)
					continue;
				v = body->particles[body->sticks[j].particleindices[0]].origin;
				glVertex3f(v.v[0], v.v[1], v.v[2]);
				v = body->particles[body->sticks[j].particleindices[1]].origin;
				glVertex3f(v.v[0], v.v[1], v.v[2]);
			}
		}
		glEnd();
		glDepthMask(GL_TRUE);
		glDisable(GL_BLEND);

		// figure out if the mouse pointer is over a particle
		bestparticle = NULL;
		bestbody = NULL;
		bestparticledist = 30*30;
		glGetDoublev(GL_MODELVIEW_MATRIX, modelviewmatrix);
		glGetDoublev(GL_PROJECTION_MATRIX, projectionmatrix);
		for (i = 0, body = bodies;i < numbodies;i++, body++)
		{
			RagdollScalar temp1[4], temp2[4];
			double iw;
			for (j = 0;j < body->numparticles;j++)
			{
				v = body->particles[j].origin;
				temp1[0] = v.v  [0] * modelviewmatrix [ 0] + v.v  [1] * modelviewmatrix [ 4] + v.v  [2] * modelviewmatrix [ 8] + 1.0f     * modelviewmatrix [12];
				temp1[1] = v.v  [0] * modelviewmatrix [ 1] + v.v  [1] * modelviewmatrix [ 5] + v.v  [2] * modelviewmatrix [ 9] + 1.0f     * modelviewmatrix [13];
				temp1[2] = v.v  [0] * modelviewmatrix [ 2] + v.v  [1] * modelviewmatrix [ 6] + v.v  [2] * modelviewmatrix [10] + 1.0f     * modelviewmatrix [14];
				temp1[3] = v.v  [0] * modelviewmatrix [ 3] + v.v  [1] * modelviewmatrix [ 7] + v.v  [2] * modelviewmatrix [11] + 1.0f     * modelviewmatrix [15];
				temp2[0] = temp1[0] * projectionmatrix[ 0] + temp1[1] * projectionmatrix[ 4] + temp1[2] * projectionmatrix[ 8] + temp1[3] * projectionmatrix[12];
				temp2[1] = temp1[0] * projectionmatrix[ 1] + temp1[1] * projectionmatrix[ 5] + temp1[2] * projectionmatrix[ 9] + temp1[3] * projectionmatrix[13];
				temp2[2] = temp1[0] * projectionmatrix[ 2] + temp1[1] * projectionmatrix[ 6] + temp1[2] * projectionmatrix[10] + temp1[3] * projectionmatrix[14];
				temp2[3] = temp1[0] * projectionmatrix[ 3] + temp1[1] * projectionmatrix[ 7] + temp1[2] * projectionmatrix[11] + temp1[3] * projectionmatrix[15];
				iw = temp2[3] != 0 ? 1.0f / temp2[3] : 0;
				v.v[0] = 0 +              viewwidth  * (temp2[0] * iw + 1.0f) * 0.5f;
				v.v[1] = 0 + viewheight - viewheight * (temp2[1] * iw + 1.0f) * 0.5f;
				v.v[2] = (temp2[2] * iw + 1.0f) * 0.5f;
				//glVertex3f(v.v[0], v.v[1], v.v[2]);
				v.v[0] -= mouse.v[0];
				v.v[1] -= mouse.v[1];
				v.v[2] -= mouse.v[2];
				dist = v.v[0] * v.v[0] + v.v[1] * v.v[1];
				if (bestparticledist > dist)
				{
					bestparticledist = dist;
					bestparticle = body->particles + j;
					bestbody = body;
				}
			}
		}

		if (button && bestparticle)
		{
			// apply a random force to the selected particle
			if (button == 1)
				bestparticle->velocity.v[2] -= button * 300.0f;
			else if (button == 3)
				bestparticle->velocity.v[2] -= button * 50.0f;
			// try to keep the body from deforming massively
			Ragdoll_ConstrainBody(body, step, 256);
			// reactivate the body if it was resting
			bestbody->sleep = 0;
			// only do one impulse per click
			button = 0;
		}

		glPointSize(3);
		glColor4f(1, 1, 1, 1);
		glBegin(GL_POINTS);
		for (i = 0, body = bodies;i < numbodies;i++, body++)
		{
			for (j = 0;j < body->numparticles;j++)
			{
				v = body->particles[j].origin;
				glVertex3f(v.v[0], v.v[1], v.v[2]);
			}
		}
		glEnd();
		if (bestparticle)
		{
			v = bestparticle->origin;
			glPointSize(5);
			glColor4f(1, 0, 0, 1);
			glBegin(GL_POINTS);
			glVertex3f(v.v[0], v.v[1], v.v[2]);
			glEnd();
		}

		SDL_GL_SwapBuffers();
	}
	Ragdoll_Quit();
	SDL_Quit();
	return 0;
}
#endif
