/*
Copyright (C) 2002 Forest Hale

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

#include <windows.h>
#include <stdio.h>
#include <math.h>

//johnfitz -- add support for standalone 3dfx cards (voodoo 1/2/rush)
#include <string.h>
#include <GL/gl.h>

typedef int (WINAPI * RAMPFUNC)();
//RAMPFUNC wglGetDeviceGammaRamp3DFX;
RAMPFUNC wglSetDeviceGammaRamp3DFX;
const char *gl_extensions;
int vid_3dfxgamma;
//johnfitz

int setgamma(double gamma)
{
	int i;
	double invgamma, d;
	HDC hdc;
	WORD gammaramps[3][256];

	hdc = GetDC (NULL);

	//johnfitz -- add support for standalone 3dfx cards (voodoo 1/2/rush)
	gl_extensions = glGetString (GL_EXTENSIONS);
	if (strstr(gl_extensions, "WGL_3DFX_gamma_control"))
	{
		printf("detected WGL_3DFX_gamma_control\n"); //TEST
		wglGetDeviceGammaRamp3DFX = (RAMPFUNC) wglGetProcAddress("wglGetDeviceGammaRamp3DFX");
		vid_3dfxgamma = 1;
	}
	else
		vid_3dfxgamma = 0;
	//johnfitz

	// LordHavoc: dodge the math
	if (gamma == 1)
	{
		for (i = 0;i < 256;i++)
			gammaramps[0][i] = gammaramps[1][i] = gammaramps[2][i] = (i * 65535) / 255;
	}
	else
	{
		invgamma = 1.0 / gamma;
		for (i = 0;i < 256;i++)
		{
			d = pow((double) i * (1.0 / 255.0), invgamma);
			if (d < 0)
				d = 0;
			if (d > 1)
				d = 1;
			gammaramps[0][i] = gammaramps[1][i] = gammaramps[2][i] = (unsigned short) (65535.0 * d);
		}
	}

	//johnfitz -- add support for standalone 3dfx cards (voodoo 1/2/rush)
	if (vid_3dfxgamma)
		i = wglSetDeviceGammaRamp3DFX(hdc, &gammaramps[0][0]);
	// LordHavoc: changed to call both if 3dfx is available
	//else
		i = SetDeviceGammaRamp(hdc, &gammaramps[0][0]);
	//johnfitz

	ReleaseDC (NULL, hdc);
	if (i)
	{
		printf("set gamma to %f\n", gamma);
		return 0;
	}
	else
	{
		printf("failed to set gamma\n");
		return 1;
	}
}

void usage(void)
{
	printf("setgamma 1.1 by Forest \"LordHavoc\" Hale and John \"metlslime\" Fitzgibbons\n");
	printf("usage: setgamma gamma\n");
	printf("example gamma values: 1.0 (normal), 2.0 (double brightness), 1.35 (35% above normal)\n");
}

int main(int argc, char **argv)
{
	double gamma;
	if (argc == 1)
	{
		usage();
		printf("restoring gamma to default (1.0)\n");
		return setgamma(1.0);
	}
	else if (argc == 2)
	{
		gamma = atof(argv[1]);
		if (gamma > 0)
			return setgamma(gamma);
	}
	usage();
	return 1;
}
