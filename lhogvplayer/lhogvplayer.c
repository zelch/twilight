
//#define _GNU_SOURCE
//#define _REENTRANT
#define _LARGEFILE_SOURCE
#define _LARGEFILE64_SOURCE
#define _FILE_OFFSET_BITS 64

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <SDL/SDL.h>
#include "lhogv.h"

#define MAXSOUNDBUFFER 4096
typedef struct audiocallbackinfo_s
{
	// the size of this matchs bufferlength
	short buffer[MAXSOUNDBUFFER * 8];
	unsigned int bufferstart;
	unsigned int buffercount;
	unsigned int bufferlength;
	unsigned int bufferpreferred;
	unsigned int channels;
	double currenttime;
	double currentsamples;
}
audiocallbackinfo_t;

void audiodequeue(audiocallbackinfo_t *info, short *samples, unsigned int length)
{
	unsigned int b1, b2, l;
	l = length;
	if (l > info->buffercount)
		l = info->buffercount;
	b1 = (info->bufferstart) % MAXSOUNDBUFFER;
	if (b1 + l > MAXSOUNDBUFFER)
	{
		b2 = (b1 + l) % MAXSOUNDBUFFER;
		memcpy(samples, info->buffer + b1 * info->channels, (MAXSOUNDBUFFER - b1) * info->channels * sizeof(short));
		memcpy(samples + (MAXSOUNDBUFFER - b1) * info->channels, info->buffer, b2 * info->channels * sizeof(short));
		//printf("audiodequeue: buffer wrap %i %i\n", (MAXSOUNDBUFFER - b1), b2);
	}
	else
	{
		memcpy(samples, info->buffer + b1 * info->channels, l * info->channels * sizeof(short));
		//printf("audiodequeue: normal      %i\n", l);
	}
	if (l < length)
	{
		memset(samples + l * info->channels, 0, (length - l) * info->channels * sizeof(short));
		//printf("audiodequeue: padding with %i\n", length - l);
	}
	info->bufferstart = (info->bufferstart + l) % MAXSOUNDBUFFER;
	info->buffercount -= l;
}

void audioenqueue(audiocallbackinfo_t *info, short *samples, unsigned int length)
{
	int b2, b3;
	//printf("enqueuing %i samples\n", length);
	if (info->buffercount + length > MAXSOUNDBUFFER)
		return;
	b2 = (info->bufferstart + info->buffercount) % MAXSOUNDBUFFER;
	if (b2 + length > MAXSOUNDBUFFER)
	{
		b3 = (b2 + length) % MAXSOUNDBUFFER;
		memcpy(info->buffer + b2 * info->channels, samples, (MAXSOUNDBUFFER - b2) * info->channels * sizeof(short));
		memcpy(info->buffer, samples + (MAXSOUNDBUFFER - b2) * info->channels, b3 * info->channels * sizeof(short));
	}
	else
		memcpy(info->buffer + b2 * info->channels, samples, length * info->channels * sizeof(short));
	info->buffercount += length;
}

void audioqueueclear(audiocallbackinfo_t *info)
{
	info->buffercount = 0;
	info->bufferstart = 0;
}

static void audiocallback(void *userdata, Uint8 *stream, int len)
{
	audiocallbackinfo_t *info = userdata;
	info->currenttime = SDL_GetTicks();
	info->currentsamples += len / (info->channels * sizeof(short));
	// we let SDL emulate what we want if it's not available,
	// so this just assumes 16bit stereo
	audiodequeue(info, (void *)stream, len / (info->channels * sizeof(short)));
}

#if 0
static void convertsamples_short_from_float(short *s, const float *f, int count)
{
	int j;
	if (count <= 0)
		return;
	do
	{
		j = (int)(*f++ * 32768.0f);
		if (j < -32768)
			j = -32768;
		if (j > 32767)
			j = 32767;
		*s++ = j;
	}
	while (--count);
}
#endif

static const int stereochannels[2] = {0, 1};
static void lhogvplayer(char *filename, LHOGVState *state, int fullscreen)
{
	char caption[1024];
	int errornum;
	int sflags, fsflags;
	SDL_Event event;
	SDL_Surface *surface;
	void *imagedata;

	audiocallbackinfo_t *audiocallbackinfo = NULL;
	SDL_AudioSpec *desiredaudiospec = NULL;
	int audioworks = 0;
	short *soundbuffer = NULL;
	//float *soundpcmbuffer = NULL;
	int soundbufferlength = 0;
	int audiopaused = 1;
	double starttime = 0;
	double currenttime = 0;
	double oldtime = 0;
	double oldsampletime = 0;
	double currentsampletime = 0;
	double deltasampletime = 0;
	int numvideoframes;

	printf("video stream is %dx%dx%gfps with %d audio channels at %dhz\n", state->width, state->height, state->fps, state->channels, state->rate);

	imagedata = NULL;

	errornum = 0;

	/* Initialize defaults, Video and Audio */
	if ((SDL_Init(SDL_INIT_VIDEO | (state->channels ? SDL_INIT_AUDIO : 0) | SDL_INIT_TIMER) == -1))
	{
		fprintf(stderr, "Could not initialize SDL: %s.\n", SDL_GetError());
		SDL_Quit();
		exit(-1);
	}

	fsflags = 0;
	if (fullscreen)
		fsflags = SDL_FULLSCREEN|SDL_DOUBLEBUF;
	sflags = SDL_SWSURFACE|fsflags;

	surface = SDL_SetVideoMode(state->width ? state->width : 64, state->height ? state->height : 48, 32, sflags);
	if (surface->format->BytesPerPixel != 2 && surface->format->BytesPerPixel != 4)
	{
		fprintf(stderr, "Did not get a usable surface from SetVideoMode, exiting.\n");
		SDL_Quit();
		exit(1);
	}

	if (surface->w < state->width || surface->h < state->height)
	{
		fprintf(stderr, "Surface from SetVideoMode too small for video, exiting.\n");
		SDL_Quit();
		exit(1);
	}

	printf("using an SDL %dx%dx%dbpp swsurface.\n", surface->w, surface->h, surface->format->BitsPerPixel);

	sprintf(caption, "lhogvsimpleplayer: %s", filename);
	SDL_WM_SetCaption(caption, NULL);

	if (state->channels)
	{
		audiocallbackinfo = malloc(sizeof(audiocallbackinfo_t));
		memset(audiocallbackinfo, 0, sizeof(audiocallbackinfo_t));
		audiocallbackinfo->channels = state->channels;
	
		desiredaudiospec = malloc(sizeof(SDL_AudioSpec));
		memset(desiredaudiospec, 0, sizeof(SDL_AudioSpec));
	
		desiredaudiospec->freq = state->rate;
		desiredaudiospec->format = AUDIO_S16SYS;
		desiredaudiospec->channels = state->channels;
		desiredaudiospec->samples = 1024;
		desiredaudiospec->callback = audiocallback;
		desiredaudiospec->userdata = audiocallbackinfo;
	
		// we want exactly what we asked for,
		// let SDL emulate it if not available...
		if (SDL_OpenAudio(desiredaudiospec, NULL) >= 0)
		{
			audioworks = 1;
			audiopaused = 1;
			audiocallbackinfo->bufferlength = MAXSOUNDBUFFER;
			audiocallbackinfo->bufferpreferred = desiredaudiospec->samples;
			soundbufferlength = audiocallbackinfo->bufferlength;
			soundbuffer = malloc(soundbufferlength * state->channels * sizeof(short));
			//soundpcmbuffer = malloc(soundbufferlength * state->channels * sizeof(float));
			audiopaused = 0;
			SDL_PauseAudio(0);
		}
		else
			fprintf(stderr, "Couldn't open audio: %s\n", SDL_GetError());
	}

	starttime = SDL_GetTicks();
	for (;;)
	{
		SDL_Delay(1);
		while (SDL_PollEvent(&event))
		{
			switch (event.type)
			{
			case SDL_KEYDOWN:
				switch (event.key.keysym.sym)
				{
				case SDLK_q:
				case SDLK_ESCAPE:
					goto playingdone;
				default:
					break;
				}
				break;
			case SDL_QUIT:
				goto playingdone;
			default:
				break;
			}
		}

		oldtime = currenttime;
		currenttime = SDL_GetTicks();
		oldsampletime = currentsampletime;
		if (!audiopaused && currenttime >= starttime + 1000)
			currentsampletime = (currenttime - starttime) * ((double)audiocallbackinfo->currentsamples / ((double)audiocallbackinfo->currenttime - (double)starttime));
		else
			currentsampletime = (currenttime - starttime) * state->rate / 1000.0;
		deltasampletime = currentsampletime - oldsampletime;
		if (deltasampletime > MAXSOUNDBUFFER)
			deltasampletime = MAXSOUNDBUFFER;
		numvideoframes = 0;

		if (deltasampletime <= 0)
			continue;

		numvideoframes = LHOGV_Advance(state, deltasampletime, soundbuffer, 2, stereochannels);
		if (numvideoframes < 0)
			break;

		if (audioworks)
		{
			//convertsamples_short_from_float(soundbuffer, soundpcmbuffer, deltasampletime * state->channels);
			SDL_LockAudio();
			audioenqueue(audiocallbackinfo, soundbuffer, deltasampletime);
			SDL_UnlockAudio();
		}

		if (numvideoframes > 0)
		{
			SDL_LockSurface(surface);
			LHOGV_GetImageBGRA32(state, surface->pixels, surface->pitch);
			SDL_UnlockSurface(surface);
			SDL_Flip(surface);
		}

		//printf("audiocallbackinfo:\n");
		//printf("bufferstart = %i\n", audiocallbackinfo->bufferstart);
		//printf("buffercount = %i\n", audiocallbackinfo->buffercount);
		//printf("bufferpreferred = %i\n", audiocallbackinfo->bufferpreferred);
		//printf("audio state: %i\n", SDL_GetAudioStatus());
	}

playingdone:
	if (audioworks)
		SDL_CloseAudio();

	SDL_QuitSubSystem (SDL_INIT_AUDIO);
	SDL_QuitSubSystem (SDL_INIT_VIDEO);

	if (desiredaudiospec)
		free(desiredaudiospec);

	if (audiocallbackinfo)
		free(audiocallbackinfo);

	if (imagedata)
		free(imagedata);

	if (soundbuffer)
		free(soundbuffer);

	SDL_Quit();
}

int mycallback_read(void *buffer, int buffersize, void *file)
{
	return fread(buffer, 1, buffersize, file);
}

int main(int argc, char **argv)
{
	LHOGVState state;
	FILE *infile;
	char *filename;
	if (argc != 2)
	{
		fprintf(stderr, "usage: lhogvplayer <filename.ogv>\n");
		return 1;
	}
	filename = argv[1];
	infile = fopen(filename, "rb");
	if (infile)
	{
		if (LHOGV_Open(&state, infile, mycallback_read))
		{
			lhogvplayer(filename, &state, 0);
			LHOGV_Close(&state);
		}
		else
		{
			fprintf(stderr, "unable to decode file \"%s\"\n", filename);
			return 1;
		}
	}
	else
	{
		fprintf(stderr, "unable to open file \"%s\"\n", filename);
		return 1;
	}
	return 0;
}
