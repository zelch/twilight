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
#include <unistd.h>
#include <fcntl.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/shm.h>
#include <sys/wait.h>
#include <sys/soundcard.h>
#include <stdio.h>
#include "quakedef.h"

int audio_fd;
int snd_inited;

static int tryrates[] = {44100, 22051, 11025, 8000};

qboolean SNDDMA_Init(void)
{
	int rc;
	int fmt;
	int tmp;
	int i;
	char *s;
	struct audio_buf_info info;
	int caps;
	int format16bit;
	// LordHavoc: a quick patch to support big endian cpu, I hope
	union
	{
		unsigned char c[2];
		unsigned short s;
	}
	endiantest;
	endiantest.s = 1;
	if (endiantest.c[1])
		format16bit = AFMT_S16_BE;
	else
		format16bit = AFMT_S16_LE;

	snd_inited = 0;

	// open /dev/dsp, confirm capability to mmap, and get size of dma buffer
    audio_fd = open("/dev/dsp", O_RDWR);
	if (audio_fd < 0)
	{
		perror("/dev/dsp");
		Con_Print("Could not open /dev/dsp\n");
		return 0;
	}

	if (ioctl(audio_fd, SNDCTL_DSP_RESET, 0) < 0)
	{
		perror("/dev/dsp");
		Con_Print("Could not reset /dev/dsp\n");
		close(audio_fd);
		return 0;
	}

	if (ioctl(audio_fd, SNDCTL_DSP_GETCAPS, &caps)==-1)
	{
		perror("/dev/dsp");
		Con_Print("Sound driver too old\n");
		close(audio_fd);
		return 0;
	}

	if (!(caps & DSP_CAP_TRIGGER) || !(caps & DSP_CAP_MMAP))
	{
		Con_Print("Sorry but your soundcard can't do this\n");
		close(audio_fd);
		return 0;
	}

	if (ioctl(audio_fd, SNDCTL_DSP_GETOSPACE, &info)==-1)
	{
		perror("GETOSPACE");
		Con_Print("Um, can't do GETOSPACE?\n");
		close(audio_fd);
		return 0;
	}

	// set sample bits & speed
	s = getenv("QUAKE_SOUND_SAMPLEBITS");
	if (s)
		shm->samplebits = atoi(s);
	else if ((i = COM_CheckParm("-sndbits")) != 0)
		shm->samplebits = atoi(com_argv[i+1]);

	if (shm->samplebits != 16 && shm->samplebits != 8)
	{
		ioctl(audio_fd, SNDCTL_DSP_GETFMTS, &fmt);
		if (fmt & format16bit)
			shm->samplebits = 16;
		else if (fmt & AFMT_U8)
			shm->samplebits = 8;
    }

	s = getenv("QUAKE_SOUND_SPEED");
	if (s)
		shm->speed = atoi(s);
	else if ((i = COM_CheckParm("-sndspeed")) != 0)
		shm->speed = atoi(com_argv[i+1]);
	else
	{
		for (i = 0;i < (int) sizeof(tryrates) / 4;i++)
			if (!ioctl(audio_fd, SNDCTL_DSP_SPEED, &tryrates[i]))
				break;

		shm->speed = tryrates[i];
    }

	s = getenv("QUAKE_SOUND_CHANNELS");
	if (s)
		shm->channels = atoi(s);
	else if ((i = COM_CheckParm("-sndmono")) != 0)
		shm->channels = 1;
	else if ((i = COM_CheckParm("-sndstereo")) != 0)
		shm->channels = 2;
	else
		shm->channels = 2;

	shm->samples = info.fragstotal * info.fragsize / (shm->samplebits/8);

	// memory map the dma buffer
	shm->bufferlength = info.fragstotal * info.fragsize;
	shm->buffer = (unsigned char *) mmap(NULL, shm->bufferlength, PROT_READ|PROT_WRITE, MAP_FILE|MAP_SHARED, audio_fd, 0);
	if (!shm->buffer || shm->buffer == (unsigned char *)-1)
	{
		perror("/dev/dsp");
		Con_Print("Could not mmap /dev/dsp\n");
		close(audio_fd);
		return 0;
	}

	tmp = 0;
	if (shm->channels == 2)
		tmp = 1;

	rc = ioctl(audio_fd, SNDCTL_DSP_STEREO, &tmp);
	if (rc < 0)
	{
		perror("/dev/dsp");
		Con_Printf("Could not set /dev/dsp to stereo=%d\n", shm->channels);
		close(audio_fd);
		return 0;
	}
	if (tmp)
		shm->channels = 2;
	else
		shm->channels = 1;

	rc = ioctl(audio_fd, SNDCTL_DSP_SPEED, &shm->speed);
	if (rc < 0)
	{
		perror("/dev/dsp");
		Con_Printf("Could not set /dev/dsp speed to %d\n", shm->speed);
		close(audio_fd);
		return 0;
	}

	if (shm->samplebits == 16)
	{
		rc = format16bit;
		rc = ioctl(audio_fd, SNDCTL_DSP_SETFMT, &rc);
		if (rc < 0)
		{
			perror("/dev/dsp");
			Con_Print("Could not support 16-bit data.  Try 8-bit.\n");
			close(audio_fd);
			return 0;
		}
	}
	else if (shm->samplebits == 8)
	{
		rc = AFMT_U8;
		rc = ioctl(audio_fd, SNDCTL_DSP_SETFMT, &rc);
		if (rc < 0)
		{
			perror("/dev/dsp");
			Con_Print("Could not support 8-bit data.\n");
			close(audio_fd);
			return 0;
		}
	}
	else
	{
		perror("/dev/dsp");
		Con_Printf("%d-bit sound not supported.\n", shm->samplebits);
		close(audio_fd);
		return 0;
	}

	// toggle the trigger & start her up
	tmp = 0;
	rc  = ioctl(audio_fd, SNDCTL_DSP_SETTRIGGER, &tmp);
	if (rc < 0)
	{
		perror("/dev/dsp");
		Con_Print("Could not toggle.\n");
		close(audio_fd);
		return 0;
	}
	tmp = PCM_ENABLE_OUTPUT;
	rc = ioctl(audio_fd, SNDCTL_DSP_SETTRIGGER, &tmp);
	if (rc < 0)
	{
		perror("/dev/dsp");
		Con_Print("Could not toggle.\n");
		close(audio_fd);
		return 0;
	}

	shm->samplepos = 0;

	snd_inited = 1;
	return 1;
}

int SNDDMA_GetDMAPos(void)
{

	struct count_info count;

	if (!snd_inited) return 0;

	if (ioctl(audio_fd, SNDCTL_DSP_GETOPTR, &count)==-1)
	{
		perror("/dev/dsp");
		Con_Print("Uh, sound dead.\n");
		close(audio_fd);
		snd_inited = 0;
		return 0;
	}
	shm->samplepos = count.ptr / (shm->samplebits / 8);

	return shm->samplepos;
}

void SNDDMA_Shutdown(void)
{
	int tmp;
	if (snd_inited)
	{
		// unmap the memory
		munmap(shm->buffer, shm->bufferlength);
		// stop the sound
		tmp = 0;
		ioctl(audio_fd, SNDCTL_DSP_SETTRIGGER, &tmp);
		ioctl(audio_fd, SNDCTL_DSP_RESET, 0);
		// close the device
		close(audio_fd);
		audio_fd = -1;
		snd_inited = 0;
	}
}

/*
==============
SNDDMA_Submit

Send sound to device if buffer isn't really the dma buffer
===============
*/
void SNDDMA_Submit(void)
{
}

void *S_LockBuffer(void)
{
	return shm->buffer;
}

void S_UnlockBuffer(void)
{
}

