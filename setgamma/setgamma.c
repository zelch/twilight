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

int setgamma(double gamma)
{
	int i;
	double invgamma, d;
	HDC hdc;
	WORD gammaramps[3][256];

	hdc = GetDC (NULL);

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

	i = SetDeviceGammaRamp(hdc, &gammaramps[0][0]);
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

int main(int argc, char **argv)
{
	double gamma;
	if (argc == 1)
	{
		printf("usage: setgamma gamma\nexample gamma values: 1.0 (normal), 2.0 (double brightness), 1.35 (35% above normal)\n");
		printf("restoring gamma to default (1.0)\n");
		return setgamma(1.0);
	}
	else if (argc == 2)
	{
		gamma = atof(argv[1]);
		if (gamma > 0)
			return setgamma(gamma);
	}
	printf("usage: setgamma gamma\nexample gamma values: 1.0 (normal), 2.0 (double brightness), 1.35 (35% above normal)\n");
	return 1;
}
