
#include <stdlib.h>
#include <math.h>
#include <SDL/SDL.h>
#include "system.h"
#include "texture.h"
#include "image.h"

double view_origin[3];
double view_angles[3];
double view_axis[3][3];

#define VectorSet(d,a,b,c) ((d)[0] = (a), (d)[1] = (b), (d)[2] = (c))

void AxisFromAngles(double axis[][3], const double angles[])
{
	double angle, sr, sp, sy, cr, cp, cy;
	angle = angles[0] * (M_PI*2 / 360);
	sp = sin(angle);
	cp = cos(angle);
	angle = angles[1] * (M_PI*2 / 360);
	sy = sin(angle);
	cy = cos(angle);
	angle = angles[2] * (M_PI*2 / 360);
	sr = sin(angle);
	cr = cos(angle);
	VectorSet(axis[0],    cp*cy        ,    cp*sy       , -sp   );
	VectorSet(axis[1], sr*sp*cy+ cr*-sy, sr*sp*sy+cr*cy ,  sr*cp);
	VectorSet(axis[2], cr*sp*cy+-sr*-sy, cr*sp*sy+-sr*cy,  cr*cp);
}

void Transform(double out[], double in[], double axis[][3], double translate[])
{
	out[0] = in[0] * axis[0][0] + in[1] * axis[1][0] + in[2] * axis[2][0] + translate[0];
	out[1] = in[0] * axis[0][1] + in[1] * axis[1][1] + in[2] * axis[2][1] + translate[1];
	out[2] = in[0] * axis[0][2] + in[1] * axis[1][2] + in[2] * axis[2][2] + translate[2];
}

void application_init(void)
{
}

int application_load(char *filename)
{
	int image_width, image_height;
	unsigned char *pixels;
	pixels = LoadTGA(filename, &image_width, &image_height);
	if (!pixels)
		return 0;

	return 1;
}

void application_animate(double frametime)
{
}

void application_drawview(void)
{
}

void application_quit(void)
{
}

void application(char *filename)
{
	int quit;
	double xmax, ymax;
	int oldtime, currenttime;
	double frametime;
	SDL_Event event;
	double playedtime;
	int playedframes;
	char tempstring[256];
	double fps = 0, fpsframecount = 0;
	int fpsbasetime = 0;
	int mousemove[2];
	double relativemove[3];
	double v[3];
	int grab = 0;
	int move_forward = 0, move_backward = 0, move_left = 0, move_right = 0, move_up = 0, move_down = 0;
	double nearclip = 1;
	double farclip = 8192;
	double fov = 90;
	double movespeed = 320;
	double mousespeed = 0.125;

	quit = 0;

	VectorSet(view_origin, 0, 0, 0);
	VectorSet(view_angles, 0, 0, 0);

	playedtime = 0;
	playedframes = 0;

	application_init();

	if (!application_load(filename))
	{
		printf("unable to load %s\n", filename);
		return;
	}

	nearclip = 1;
	farclip = 8192;
	fov = 90;
	// calculate fov with widescreen support
	ymax = nearclip * tan(fov * M_PI / 360.0) * (3.0/4.0);
	xmax = ymax * (double) system_width / (double) system_height;

	oldtime = currenttime = SDL_GetTicks();
	// main loop
	while (!quit)
	{
		oldtime = currenttime;
		currenttime = SDL_GetTicks();
		frametime = (int)(currenttime - oldtime) * (1.0 / 1000.0);
		if (frametime < 0)
			frametime = 0;

		while (SDL_PollEvent(&event))
		{
			switch (event.type)
			{
			case SDL_KEYDOWN:
				switch (event.key.keysym.sym)
				{
				case SDLK_ESCAPE:
					quit = 1;
					break;
				case SDLK_TAB:
					grab = !grab;
					SDL_WM_GrabInput(grab ? SDL_GRAB_ON : SDL_GRAB_OFF);
					SDL_ShowCursor(grab ? SDL_DISABLE : SDL_ENABLE);
					break;
				default:
					break;
				}
				// fall through to handle keys that care about up events
			case SDL_KEYUP:
				switch (event.key.keysym.sym)
				{
				case SDLK_a:
					move_left = (event.key.state == SDL_PRESSED);
					break;
				case SDLK_d:
					move_right = (event.key.state == SDL_PRESSED);
					break;
				case SDLK_w:
					move_forward = (event.key.state == SDL_PRESSED);
					break;
				case SDLK_s:
					move_backward = (event.key.state == SDL_PRESSED);
					break;
				case SDLK_f:
					move_up = (event.key.state == SDL_PRESSED);
					break;
				case SDLK_v:
					move_down = (event.key.state == SDL_PRESSED);
					break;
				default:
					break;
				}
				break;
			case SDL_QUIT:
				quit = 1;
				break;
			default:
				break;
			}
		}
		if (quit)
			break;

		SDL_GetRelativeMouseState(&mousemove[0], &mousemove[1]);
		VectorSet(view_angles, view_angles[0] + mousemove[0] * mousespeed, view_angles[1] + mousemove[1] * mousespeed, view_angles[2]);
		if (view_angles[0] < -90) view_angles[0] = -90;
		if (view_angles[0] > 90) view_angles[0] = 90;
		while (view_angles[1] < 0) view_angles[1] += 360;while (view_angles[1] >= 360) view_angles[1] -= 360;

		AxisFromAngles(view_axis, view_angles);
		VectorSet(relativemove, (move_forward - move_backward) * movespeed * frametime, (move_left - move_right) * movespeed * frametime, (move_up - move_down) * movespeed * frametime);
		Transform(v, relativemove, view_axis, view_origin);
		VectorSet(view_origin, v[0], v[1], v[2]);

		application_animate(frametime);

		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		// set up the projection matrix (perspective)
		glMatrixMode(GL_PROJECTION);CHECKGLERROR
		glLoadIdentity();CHECKGLERROR
		glFrustum(-xmax, xmax, -ymax, ymax, nearclip, farclip);CHECKGLERROR
		// set up the modelview matrix (camera)
		glMatrixMode(GL_MODELVIEW);CHECKGLERROR
		glLoadIdentity();
		glTranslatef(view_origin[0], view_origin[1], view_origin[2]);
		glRotatef(270, 1, 0, 0);
		glRotatef(90, 0, 0, 1);
		glRotatef(view_angles[1], 0, 1, 0);
		glRotatef(view_angles[0], 1, 0, 0);
		glRotatef(view_angles[2], 0, 0, 1);
		// set up for rendering
		glEnable(GL_TEXTURE_2D);
		glEnable(GL_DEPTH_TEST);
		glEnable(GL_CULL_FACE);

		application_drawview();

		// set up the projection matrix (2D)
		glMatrixMode(GL_PROJECTION);CHECKGLERROR
		glLoadIdentity();CHECKGLERROR
		glOrtho(0, 640, 480, 0, -100, 100);CHECKGLERROR
		// set up the modelview matrix (2D)
		glMatrixMode(GL_MODELVIEW);CHECKGLERROR
		glLoadIdentity();
		// set up for rendering
		glEnable(GL_TEXTURE_2D);
		glDisable(GL_DEPTH_TEST);
		//glDisable(GL_CULL_FACE);
		bindimagetexture("lhfont.tga");
		glColor4f(1,1,1,1);
		fpsframecount++;
		if ((unsigned int)(currenttime - fpsbasetime) >= 1000)
		{
			fps = fpsframecount * 1000.0 / (double)(currenttime - fpsbasetime);
			fpsbasetime = currenttime;
			fpsframecount = 0;
		}
		sprintf(tempstring, "WASD: move   Tab: toggle mouse grab   Escape: quit");
		drawstring(tempstring, 0, 0, 8, 8);
		sprintf(tempstring, "FPS%5.0f origin %3.0f %3.0f %3.0f angles %3.0f %3.0f %3.0f", fps, view_origin[0], view_origin[1], view_origin[2], view_angles[0], view_angles[1], view_angles[2]);
		drawstring(tempstring, 0, 480 - 8, 8, 8);

		// display the rendered frame
		SDL_GL_SwapBuffers();

		//SDL_Delay(1);

		playedtime += frametime;
		playedframes++;
	}

	printf("%d frames rendered in %f seconds, %f average frames per second\n", playedframes, playedtime, playedframes / playedtime);

	application_quit();
}
