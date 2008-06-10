
#include <SDL/SDL.h>
#include <SDL/SDL_main.h>
#include <SDL/SDL_opengl.h>
#include <stdlib.h>
#include <stdio.h>
#include <memory.h>
#include <math.h>
#include "lhragdoll.h"

LHRagdollScalar floorplane[4] = {0.0f, 1.0f, 0.0f, -1.0f};
LHRagdollScalar nudge = (1.0f / 1024.0f);

void test_trace(LHRagdollTrace *trace)
{
	LHRagdollScalar d1;
	LHRagdollScalar d2;
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

struct
{
	LHRagdollStickType type;
	int particleindex1;
	int particleindex2;
	float dist;
	int useautomaticdistance;
}
ragdoll1_sticks[] =
{
	{LHRAGDOLLSTICK_CLOTH  ,  0,  1, 1.0f, 1}, // head to neck
	{LHRAGDOLLSTICK_CLOTH  ,  1,  2, 1.0f, 1}, // neck to right shoulder
	{LHRAGDOLLSTICK_CLOTH  ,  1,  3, 1.0f, 1}, // neck to left shoulder
	{LHRAGDOLLSTICK_CLOTH  ,  1,  8, 1.0f, 1}, // neck to right waist
	{LHRAGDOLLSTICK_CLOTH  ,  1,  9, 1.0f, 1}, // neck to left waist
	{LHRAGDOLLSTICK_CLOTH  ,  2,  3, 1.0f, 1}, // right shoulder to left shoulder
	{LHRAGDOLLSTICK_CLOTH  ,  2,  4, 1.0f, 1}, // right shoulder to right elbow
	{LHRAGDOLLSTICK_CLOTH  ,  2,  8, 1.0f, 1}, // right shoulder to right waist
	{LHRAGDOLLSTICK_CLOTH  ,  2,  9, 1.0f, 1}, // right shoulder to left waist
	{LHRAGDOLLSTICK_CLOTH  ,  3,  6, 1.0f, 1}, // left shoulder to left elbow
	{LHRAGDOLLSTICK_CLOTH  ,  3,  8, 1.0f, 1}, // left shoulder to right waist
	{LHRAGDOLLSTICK_CLOTH  ,  3,  9, 1.0f, 1}, // left shoulder to left waist
	{LHRAGDOLLSTICK_CLOTH  ,  4,  5, 1.0f, 1}, // right elbow to right hand
	{LHRAGDOLLSTICK_CLOTH  ,  6,  7, 1.0f, 1}, // left elbow to left hand
	{LHRAGDOLLSTICK_CLOTH  ,  8,  9, 1.0f, 1}, // right waist to left waist
	{LHRAGDOLLSTICK_CLOTH  ,  8, 10, 1.0f, 1}, // right waist to right hip
	{LHRAGDOLLSTICK_CLOTH  ,  8, 11, 1.0f, 1}, // right waist to left hip
	{LHRAGDOLLSTICK_CLOTH  ,  9, 10, 1.0f, 1}, // left waist to right hip
	{LHRAGDOLLSTICK_CLOTH  ,  9, 11, 1.0f, 1}, // left waist to left hip
	{LHRAGDOLLSTICK_CLOTH  , 10, 11, 1.0f, 1}, // right hip to left hip
	{LHRAGDOLLSTICK_CLOTH  , 10, 12, 1.0f, 1}, // right hip to right knee
	{LHRAGDOLLSTICK_CLOTH  , 11, 14, 1.0f, 1}, // left hip to left knee
	{LHRAGDOLLSTICK_CLOTH  , 12, 13, 1.0f, 1}, // right knee to right foot
	{LHRAGDOLLSTICK_CLOTH  , 14, 15, 1.0f, 1}, // left knee to left foot
	{LHRAGDOLLSTICK_MINDIST,  4,  9, 0.8f, 1}, // right elbow to left waist
	{LHRAGDOLLSTICK_MINDIST,  6,  8, 0.8f, 1}, // left elbow to right waist
	{LHRAGDOLLSTICK_MINDIST,  5,  8, 0.8f, 1}, // right hand to right waist
	{LHRAGDOLLSTICK_MINDIST,  7,  9, 0.8f, 1}, // left hand to left waist
	{LHRAGDOLLSTICK_MINDIST, 12, 14, 0.8f, 1}, // right knee to left knee
	{LHRAGDOLLSTICK_MINDIST, 13, 15, 0.8f, 1}, // right foot to left foot
	{LHRAGDOLLSTICK_MINDIST,  2, 10, 0.8f, 1}, // right shoulder to right hip
	{LHRAGDOLLSTICK_MINDIST,  3, 11, 0.8f, 1}, // left shoulder to left hip
	{LHRAGDOLLSTICK_MINDIST,  0,  2, 0.8f, 1}, // head to right shoulder
	{LHRAGDOLLSTICK_MINDIST,  0,  3, 0.8f, 1}, // head to left shoulder
	{LHRAGDOLLSTICK_MINDIST,  0,  8, 0.8f, 1}, // head to right shoulder
	{LHRAGDOLLSTICK_MINDIST,  0,  9, 0.8f, 1}, // head to left shoulder
	{LHRAGDOLLSTICK_MINDIST, 10, 13, 0.7f, 1}, // right hip to right foot
	{LHRAGDOLLSTICK_MINDIST, 11, 15, 0.7f, 1}, // right hip to right foot
},
ragdoll2_sticks[] =
{
	{LHRAGDOLLSTICK_CLOTH  ,  0,  1, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  ,  1,  2, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  ,  1,  7, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  ,  1, 16, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  ,  2,  3, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  ,  3,  4, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  ,  4,  5, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  ,  5,  6, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  ,  6, 11, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  ,  6, 20, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  ,  7,  8, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  ,  8,  9, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  ,  9, 10, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 11, 12, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 12, 13, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 13, 14, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 14, 15, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 16, 17, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 17, 18, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 18, 19, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 20, 21, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 21, 22, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 22, 23, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 23, 24, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  ,  7, 11, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 16, 20, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  ,  7, 16, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  ,  8, 17, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  ,  8, 11, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  ,  8, 20, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 17, 11, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 17, 20, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 11, 20, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  ,  7, 20, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 16, 11, 1.0f, 1},
	{LHRAGDOLLSTICK_MINDIST, 12, 21, 0.5f, 1},
	{LHRAGDOLLSTICK_MINDIST, 13, 22, 0.5f, 1},
	{LHRAGDOLLSTICK_MINDIST, 14, 23, 0.5f, 1},
	{LHRAGDOLLSTICK_MINDIST, 15, 24, 0.5f, 1},
	{LHRAGDOLLSTICK_MINDIST,  0,  2, 0.95f, 1},
	{LHRAGDOLLSTICK_MINDIST,  0,  7, 0.9f, 1},
	{LHRAGDOLLSTICK_MINDIST,  0, 16, 0.9f, 1},
	{LHRAGDOLLSTICK_MINDIST, 10, 20, 0.8f, 1},
	{LHRAGDOLLSTICK_MINDIST, 11, 19, 0.8f, 1},
	{LHRAGDOLLSTICK_MINDIST,  9, 20, 0.8f, 1},
	{LHRAGDOLLSTICK_MINDIST, 11, 18, 0.8f, 1},
	{LHRAGDOLLSTICK_MINDIST,  0,  8, 0.8f, 1},
	{LHRAGDOLLSTICK_MINDIST,  0, 17, 0.8f, 1},
	{LHRAGDOLLSTICK_CLOTH  ,  6, 11, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  ,  6, 20, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  ,  6, 25, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  ,  6, 30, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 11, 25, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 12, 26, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 13, 27, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 14, 28, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 15, 29, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 20, 30, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 21, 31, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 22, 32, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 23, 33, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 24, 34, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 25, 26, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 26, 27, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 27, 28, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 28, 29, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 30, 31, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 31, 32, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 32, 33, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 33, 34, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 11, 26, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 25, 12, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 12, 27, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 26, 13, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 13, 28, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 27, 14, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 14, 29, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 28, 15, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 20, 31, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 30, 21, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 21, 32, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 31, 22, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 22, 33, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 32, 23, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 23, 34, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 33, 24, 1.0f, 1},
	{LHRAGDOLLSTICK_MINDIST,  4, 12, 0.7f, 1},
	{LHRAGDOLLSTICK_MINDIST,  4, 21, 0.7f, 1},
	{LHRAGDOLLSTICK_MINDIST,  4, 26, 0.7f, 1},
	{LHRAGDOLLSTICK_MINDIST,  4, 31, 0.7f, 1},
	{LHRAGDOLLSTICK_MINDIST,  4, 10, 0.7f, 1},
	{LHRAGDOLLSTICK_MINDIST,  4, 19, 0.7f, 1},
	{LHRAGDOLLSTICK_MINDIST,  4,  0, 0.9f, 1},
	{LHRAGDOLLSTICK_MINDIST,  4,  9, 0.7f, 1},
	{LHRAGDOLLSTICK_MINDIST,  4, 18, 0.7f, 1},
	{LHRAGDOLLSTICK_MINDIST,  4, 13, 0.7f, 1},
	{LHRAGDOLLSTICK_MINDIST,  4, 22, 0.7f, 1},

	{LHRAGDOLLSTICK_CLOTH  , 12, 14, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 12, 15, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 12, 29, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 21, 23, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 21, 24, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 21, 34, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 25, 15, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 26, 28, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 26, 29, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 31, 24, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 31, 33, 1.0f, 1},
	{LHRAGDOLLSTICK_CLOTH  , 31, 34, 1.0f, 1},
};

#define lhrandom(MIN,MAX) (((double)rand() / RAND_MAX) * ((MAX)-(MIN)) + (MIN))
#define MAX_BODIES 128

int main(int argc, char **argv)
{
	int i;
	int j;
	int numparticles;
	int numsticks;
	int pause = 0;
	int frame = 0;
	int spew = 0;
	int button = 0;
	int buttons = 0;
	int quit = 0;
	int mousex = 0, mousey = 0;
	int viewwidth = 1024, viewheight = 768;
	int currenttime;
	LHRagdollScalar step = 1.0f / 64.0f;
	LHRagdollScalar x, y, z;
	LHRagdollScalar f;
	double nextframetime = 0;
	double zNear = 0.125;
	double zFar = 1024;
	double ymax = zNear * 0.75;
	double xmax = ymax * viewwidth / viewheight;
	LHRagdollBody *body;
	LHRagdollParticle *p;
	LHRagdollVector v;
	LHRagdollVector mouse;
	LHRagdollParticle *bestparticle = NULL;
	LHRagdollBody *bestbody = NULL;
	LHRagdollScalar bestparticledist = 0;
	LHRagdollScalar dist = 0;
	double modelviewmatrix[16];
	double projectionmatrix[16];
	int numbodies = 0;
	LHRagdollBody bodies[MAX_BODIES];
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
					numparticles = 4;
					numsticks = 6;
					LHRagdoll_Setup(body, numparticles, malloc(numparticles * sizeof(LHRagdollParticle)), numsticks, malloc(numsticks * sizeof(LHRagdollStick)));
					LHRagdoll_SetParticle(body, 0, 0.0f, x+0, y+0, z+0, lhrandom(-3, 3), lhrandom(-3, 3), lhrandom(-3, 3));
					LHRagdoll_SetParticle(body, 1, 0.0f, x+1, y+0, z+0, lhrandom(-3, 3), lhrandom(-3, 3), lhrandom(-3, 3));
					LHRagdoll_SetParticle(body, 2, 0.0f, x+0, y+1, z+0, lhrandom(-3, 3), lhrandom(-3, 3), lhrandom(-3, 3));
					LHRagdoll_SetParticle(body, 3, 0.0f, x+0, y+0, z+1, lhrandom(-3, 3), lhrandom(-3, 3), lhrandom(-3, 3));
					LHRagdoll_SetStick(body, 0, LHRAGDOLLSTICK_NORMAL, 0, 1, 1.0f, 1);
					LHRagdoll_SetStick(body, 1, LHRAGDOLLSTICK_NORMAL, 0, 2, 1.0f, 1);
					LHRagdoll_SetStick(body, 2, LHRAGDOLLSTICK_NORMAL, 0, 3, 1.0f, 1);
					LHRagdoll_SetStick(body, 3, LHRAGDOLLSTICK_NORMAL, 1, 2, 1.0f, 1);
					LHRagdoll_SetStick(body, 4, LHRAGDOLLSTICK_NORMAL, 1, 3, 1.0f, 1);
					LHRagdoll_SetStick(body, 5, LHRAGDOLLSTICK_NORMAL, 2, 3, 1.0f, 1);
					LHRagdoll_RecalculateBounds(body);
					break;
				case SDLK_w:
					if (numbodies == MAX_BODIES)
						break;
					// create a ragdoll similar to the one in the article "Advanced Character Physics" on Gamasutra
					x = lhrandom(-2, 2);
					y = floorplane[3];
					z = lhrandom(-4, -2);
					body = bodies + numbodies++;
					numparticles = 35;
					numsticks = sizeof(ragdoll2_sticks)/sizeof(ragdoll2_sticks[0]);
					LHRagdoll_Setup(body, numparticles, malloc(numparticles * sizeof(LHRagdollParticle)), numsticks, malloc(numsticks * sizeof(LHRagdollStick)));
					LHRagdoll_SetParticle(body,  0, 0.20f, x+0.00f, y+1.82f, z-0.00f, 0, 0, 0); //  0 head
					LHRagdoll_SetParticle(body,  1, 0.15f, x+0.00f, y+1.75f, z-0.00f, 0, 0, 0); //  1 neck
					LHRagdoll_SetParticle(body,  2, 0.15f, x+0.00f, y+1.48f, z-0.00f, 0, 0, 0); //  2 spine1
					LHRagdoll_SetParticle(body,  3, 0.15f, x+0.00f, y+1.41f, z+0.01f, 0, 0, 0); //  3 spine2
					LHRagdoll_SetParticle(body,  4, 0.15f, x+0.00f, y+1.35f, z+0.01f, 0, 0, 0); //  4 spine3
					LHRagdoll_SetParticle(body,  5, 0.15f, x+0.00f, y+1.29f, z+0.01f, 0, 0, 0); //  5 spine4
					LHRagdoll_SetParticle(body,  6, 0.15f, x+0.00f, y+1.22f, z-0.00f, 0, 0, 0); //  6 spine5
					LHRagdoll_SetParticle(body,  7, 0.15f, x-0.10f, y+1.73f, z-0.00f, 0, 0, 0); //  7 right collar
					LHRagdoll_SetParticle(body,  8, 0.15f, x-0.22f, y+1.62f, z-0.00f, 0, 0, 0); //  8 right shoulder
					LHRagdoll_SetParticle(body,  9, 0.05f, x-0.43f, y+1.46f, z+0.02f, 0, 0, 0); //  9 right elbow
					LHRagdoll_SetParticle(body, 10, 0.05f, x-0.66f, y+1.28f, z-0.00f, 0, 0, 0); // 10 right wrist
					LHRagdoll_SetParticle(body, 11, 0.12f, x-0.13f, y+1.13f, z-0.00f, 0, 0, 0); // 11 right hip
					LHRagdoll_SetParticle(body, 12, 0.05f, x-0.13f, y+0.60f, z-0.03f, 0, 0, 0); // 12 right knee
					LHRagdoll_SetParticle(body, 13, 0.05f, x-0.12f, y+0.18f, z-0.00f, 0, 0, 0); // 13 right sock
					LHRagdoll_SetParticle(body, 14, 0.05f, x-0.12f, y+0.10f, z-0.03f, 0, 0, 0); // 14 right ankle
					LHRagdoll_SetParticle(body, 15, 0.05f, x-0.13f, y+0.04f, z-0.06f, 0, 0, 0); // 15 right foot
					LHRagdoll_SetParticle(body, 16, 0.15f, x+0.10f, y+1.73f, z-0.00f, 0, 0, 0); // 16 left collar
					LHRagdoll_SetParticle(body, 17, 0.15f, x+0.22f, y+1.62f, z-0.00f, 0, 0, 0); // 17 left shoulder
					LHRagdoll_SetParticle(body, 18, 0.05f, x+0.43f, y+1.46f, z+0.02f, 0, 0, 0); // 18 left elbow
					LHRagdoll_SetParticle(body, 19, 0.05f, x+0.66f, y+1.28f, z-0.00f, 0, 0, 0); // 19 left wrist
					LHRagdoll_SetParticle(body, 20, 0.12f, x+0.13f, y+1.13f, z-0.00f, 0, 0, 0); // 20 left hip
					LHRagdoll_SetParticle(body, 21, 0.05f, x+0.13f, y+0.60f, z-0.03f, 0, 0, 0); // 21 left knee
					LHRagdoll_SetParticle(body, 22, 0.05f, x+0.12f, y+0.18f, z-0.00f, 0, 0, 0); // 22 left sock
					LHRagdoll_SetParticle(body, 23, 0.05f, x+0.12f, y+0.10f, z-0.03f, 0, 0, 0); // 23 left ankle
					LHRagdoll_SetParticle(body, 24, 0.05f, x+0.13f, y+0.04f, z-0.06f, 0, 0, 0); // 24 left foot
					LHRagdoll_SetParticle(body, 25, 0.05f, x-0.09f, y+1.13f, z-0.00f, 0, 0, 0); // 25 right hip (inner)
					LHRagdoll_SetParticle(body, 26, 0.05f, x-0.09f, y+0.60f, z-0.03f, 0, 0, 0); // 26 right knee (inner)
					LHRagdoll_SetParticle(body, 27, 0.05f, x-0.08f, y+0.18f, z-0.00f, 0, 0, 0); // 27 right sock (inner)
					LHRagdoll_SetParticle(body, 28, 0.05f, x-0.08f, y+0.10f, z-0.00f, 0, 0, 0); // 28 right ankle (inner)
					LHRagdoll_SetParticle(body, 29, 0.05f, x-0.09f, y+0.04f, z-0.00f, 0, 0, 0); // 29 right foot (inner)
					LHRagdoll_SetParticle(body, 30, 0.05f, x+0.09f, y+1.13f, z-0.00f, 0, 0, 0); // 30 left hip (inner)
					LHRagdoll_SetParticle(body, 31, 0.05f, x+0.09f, y+0.60f, z-0.03f, 0, 0, 0); // 31 left knee (inner)
					LHRagdoll_SetParticle(body, 32, 0.05f, x+0.08f, y+0.18f, z-0.00f, 0, 0, 0); // 32 left sock (inner)
					LHRagdoll_SetParticle(body, 33, 0.05f, x+0.08f, y+0.10f, z-0.03f, 0, 0, 0); // 33 left ankle (inner)
					LHRagdoll_SetParticle(body, 34, 0.05f, x+0.09f, y+0.04f, z-0.06f, 0, 0, 0); // 34 left foot (inner)
					for (i = 0;i < numsticks;i++)
						LHRagdoll_SetStick(body, i, ragdoll2_sticks[i].type, ragdoll2_sticks[i].particleindex1, ragdoll2_sticks[i].particleindex2, ragdoll2_sticks[i].dist, ragdoll2_sticks[i].useautomaticdistance);
					LHRagdoll_RecalculateBounds(body);
					body->sleep = 3;
					//LHRagdoll_PointImpulseBody(body, x + lhrandom(-0.66f, 0.66f), y + lhrandom(0.00f, 2.00f), z + 0.05f, lhrandom( -30,  30), lhrandom( -30,  30), lhrandom(-300, 0));
					break;
				case SDLK_h:
					if (numbodies == MAX_BODIES)
						break;
					// create a tetrahedron
					x = lhrandom(-3, 3);
					y = floorplane[3];
					z = -6 + lhrandom(-3, 3);
					body = bodies + numbodies++;
					numparticles = 16;
					numsticks = sizeof(ragdoll1_sticks)/sizeof(ragdoll1_sticks[0]);
					LHRagdoll_Setup(body, numparticles, malloc(numparticles * sizeof(LHRagdollParticle)), numsticks, malloc(numsticks * sizeof(LHRagdollStick)));
					LHRagdoll_SetParticle(body,  0, 0.05f, x+0.00f, y+2.00f, z, 0, 0, 0); // head
					LHRagdoll_SetParticle(body,  1, 0.05f, x+0.00f, y+1.70f, z, 0, 0, 0); // neck
					LHRagdoll_SetParticle(body,  2, 0.05f, x-0.30f, y+1.40f, z, 0, 0, 0); // right shoulder
					LHRagdoll_SetParticle(body,  3, 0.05f, x+0.30f, y+1.40f, z, 0, 0, 0); // left shoulder
					LHRagdoll_SetParticle(body,  4, 0.05f, x-0.50f, y+1.10f, z, 0, 0, 0); // right elbow
					LHRagdoll_SetParticle(body,  5, 0.05f, x-0.50f, y+0.90f, z, 0, 0, 0); // right hand
					LHRagdoll_SetParticle(body,  6, 0.05f, x+0.50f, y+1.10f, z, 0, 0, 0); // left elbow
					LHRagdoll_SetParticle(body,  7, 0.05f, x+0.50f, y+0.90f, z, 0, 0, 0); // left hand
					LHRagdoll_SetParticle(body,  8, 0.05f, x-0.20f, y+1.00f, z, 0, 0, 0); // right waist
					LHRagdoll_SetParticle(body,  9, 0.05f, x+0.20f, y+1.00f, z, 0, 0, 0); // left waist
					LHRagdoll_SetParticle(body, 10, 0.05f, x-0.25f, y+0.85f, z, 0, 0, 0); // right hip
					LHRagdoll_SetParticle(body, 11, 0.05f, x+0.25f, y+0.85f, z, 0, 0, 0); // left hip
					LHRagdoll_SetParticle(body, 12, 0.05f, x-0.30f, y+0.40f, z, 0, 0, 0); // right knee
					LHRagdoll_SetParticle(body, 13, 0.05f, x-0.30f, y+0.40f, z, 0, 0, 0); // right foot
					LHRagdoll_SetParticle(body, 14, 0.05f, x+0.30f, y+0.00f, z, 0, 0, 0); // left knee
					LHRagdoll_SetParticle(body, 15, 0.05f, x+0.30f, y+0.00f, z, 0, 0, 0); // left foot
					for (i = 0;i < numsticks;i++)
						LHRagdoll_SetStick(body, i, ragdoll1_sticks[i].type, ragdoll1_sticks[i].particleindex1, ragdoll1_sticks[i].particleindex2, ragdoll1_sticks[i].dist, ragdoll1_sticks[i].useautomaticdistance);
					LHRagdoll_RecalculateBounds(body);
					body->sleep = 3;
					break;
				case SDLK_SPACE:
					pause = 2;
					break;
				case SDLK_RETURN:
					pause = 0;
					break;
				case SDLK_DELETE:
					if (numbodies > 0)
					{
						body = bodies + --numbodies;
						free(body->particles);
						free(body->sticks);
						memset(body, 0, sizeof(*body));
					}
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
				LHRagdoll_MoveBody(body, step, 0.0f, -9.82f, 0.0f, 16.0f, 8.0f, 0.001f, test_trace);
			for (i = 0, body = bodies;i < numbodies;i++, body++)
				LHRagdoll_ConstrainBody(body, step, 16);
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
				if (body->sticks[j].type == LHRAGDOLLSTICK_MINDIST)
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
				if (body->sticks[j].type == LHRAGDOLLSTICK_MINDIST)
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
				if (body->sticks[j].type != LHRAGDOLLSTICK_MINDIST)
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
			LHRagdollScalar temp1[4], temp2[4];
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
			LHRagdoll_ConstrainBody(bestbody, step, 256);
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
	SDL_Quit();
	return 0;
}
