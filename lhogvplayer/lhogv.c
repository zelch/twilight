
#include <memory.h>
#include "lhogv.h"

int LHOGV_Open(LHOGVState *state, void *callback_file, int (*callback_read)(void *buffer, int buffersize, void *file))
{
	int bytes;
	ogg_stream_state test;

	memset(state, 0, sizeof(*state));
	state->callback_file = callback_file;
	state->callback_read = callback_read;

	ogg_sync_init(&state->oy);
	vorbis_info_init(&state->vi);
	vorbis_comment_init(&state->vc);
	th_info_init(&state->ti);
	th_comment_init(&state->tc);

	// read a large chunk at first to be sure we get any headers
	bytes = 65536;
	bytes = state->callback_read(ogg_sync_buffer(&state->oy, bytes), bytes, state->callback_file);
	ogg_sync_wrote(&state->oy, bytes);

	while (ogg_sync_pageout(&state->oy, &state->og) > 0)
	{
		if (ogg_page_bos(&state->og))
		{
			// this page is the beginning of a stream
			// create am ogg_stream_state - we don't know which type yet...
			ogg_stream_init(&test, ogg_page_serialno(&state->og));
			ogg_stream_pagein(&test, &state->og);
			if (ogg_stream_packetout(&test, &state->op) > 0)
			{
				if (!state->theora_p && th_decode_headerin(&state->ti, &state->tc, &state->ts, &state->op) >= 0)
				{
					// okay this is the first theora stream, store it
					state->theora_p = 1;
					state->to = test;
				}
				else if (!state->vorbis_p && vorbis_synthesis_headerin(&state->vi, &state->vc, &state->op) >= 0)
				{
					// okay this is the first vorbis stream, store it
					state->vorbis_p = 1;
					state->vo = test;
				}
				else
				{
					// some other kind of stream - free it
					ogg_stream_clear(&test);
				}
			}
		}
		else
		{
			// feed this page into one of the active streams
			// pages for streams we didn't set up are simply dropped
			if (state->theora_p)
				ogg_stream_pagein(&state->to, &state->og);
			if (state->vorbis_p)
				ogg_stream_pagein(&state->vo, &state->og);
		}
	}

	// decode two more headers for each stream
	while (state->theora_p && state->theora_p < 3 && ogg_stream_packetout(&state->to, &state->op) > 0 && th_decode_headerin(&state->ti, &state->tc, &state->ts, &state->op) >= 0)
		state->theora_p++; // got a theora header
	while (state->vorbis_p && state->vorbis_p < 3 && ogg_stream_packetout(&state->vo, &state->op) > 0 && vorbis_synthesis_headerin(&state->vi, &state->vc, &state->op) >= 0)
		state->vorbis_p++; // got a vorbis header

	// now we've parsed the headers and we've prebuffered both streams...

	// init theora decoder
	if (state->theora_p)
	{
		state->td = th_decode_alloc(&state->ti, state->ts);
		th_setup_free(state->ts);
		state->ts = NULL;
		state->width = state->ti.pic_width;
		state->height = state->ti.pic_height;
		state->fps = state->ti.fps_denominator ? (double)state->ti.fps_numerator/state->ti.fps_denominator : 0.0;
	}
	else
	{
		th_info_clear(&state->ti);
		th_comment_clear(&state->tc);
		state->width = 0;
		state->height = 0;
		state->fps = 0;
	}

	// init vorbis decoder
	if (state->vorbis_p)
	{
		vorbis_synthesis_init(&state->vd, &state->vi);
		vorbis_block_init(&state->vd, &state->vb);
		state->rate = state->vi.rate;
		state->channels = state->vi.channels;
	}
	else
	{
		vorbis_info_clear(&state->vi);
		vorbis_comment_clear(&state->vc);
		state->rate = 1000; // we use sound for timing, so fake it
		state->channels = 0;
	}

	return (state->theora_p != 0) + 2 * (state->vorbis_p != 0);
}

void LHOGV_Close(LHOGVState *state)
{
	if (state->theora_p)
	{
		ogg_stream_clear(&state->to);
		th_decode_free(state->td);
		state->td = NULL;
		th_comment_clear(&state->tc);
		th_info_clear(&state->ti);
	}

	if (state->vorbis_p)
	{
		ogg_stream_clear(&state->vo);
		vorbis_block_clear(&state->vb);
		vorbis_dsp_clear(&state->vd);
		vorbis_comment_clear(&state->vc);
		vorbis_info_clear(&state->vi);
	}

	ogg_sync_clear(&state->oy);

	memset(state, 0, sizeof(*state));
}

int LHOGV_Advance(LHOGVState *state, int wantsampleframes, short *pcmout, int pcmchannelmappings, const int *pcmchannelmapping)
{
	int i, j, k, l;
	const float *p;
	short *o;
	int wantvideo;
	int numvideoframes = 0;
	int bytes;
	int sampleframes;
	float **pcmchannels = NULL;
	if (state->eof)
		return -1;
	state->sampleframeposition += wantsampleframes;
	state->seconds = state->sampleframeposition / state->rate;
	if (!state->vorbis_p)
		wantsampleframes = 0;
	wantvideo = state->nextframeseconds < state->seconds && state->theora_p;
	memset(pcmout, 0, wantsampleframes * pcmchannelmappings * sizeof(*pcmout));
	for (;;)
	{
		while (wantsampleframes)
		{
			sampleframes = vorbis_synthesis_pcmout(&state->vd, &pcmchannels);
			if (sampleframes > 0)
			{
				if (sampleframes > wantsampleframes)
					sampleframes = wantsampleframes;
				vorbis_synthesis_read(&state->vd, sampleframes);
				// now interleave the channels for the caller
				for (j = 0;j < pcmchannelmappings;j++)
				{
					k = pcmchannelmapping[j];
					if (k >= 0 && k < state->channels)
					{
						p = pcmchannels[k];
						o = pcmout + j;
						for (i = 0;i < sampleframes;i++, p++, o += pcmchannelmappings)
						{
							l = (int)(*p * 32768.0f);
							if (l < -32768)
								l = -32768;
							if (l > 32767)
								l = 32767;
							*o = l;
						}
					}
				}
				pcmout += sampleframes * state->channels;
				wantsampleframes -= sampleframes;
			}
			else if (ogg_stream_packetout(&state->vo, &state->op) > 0 && vorbis_synthesis(&state->vb, &state->op) == 0)
				vorbis_synthesis_blockin(&state->vd, &state->vb);
			else
				break;
		}
		while (wantvideo && ogg_stream_packetout(&state->to, &state->op) > 0)
		{
			ogg_int64_t granule = 0;
			th_decode_packetin(state->td, &state->op, &granule);
			state->nextframeseconds = th_granule_time(state->td, granule);
			wantvideo = state->nextframeseconds < state->seconds;
			numvideoframes++;
		}
		if (!wantsampleframes && !wantvideo)
			break; // we decoded enough data
		// we need more data to satisfy the calling code
		bytes = 32768; // try to read 32KB
		bytes = state->callback_read(ogg_sync_buffer(&state->oy, bytes), bytes, state->callback_file);
		if (bytes <= 0)
		{
			// we read all the way to the end
			// return whatever we did decode, next time we just return -1
			state->eof = 1;
			break;
		}
		ogg_sync_wrote(&state->oy, bytes);
		while (ogg_sync_pageout(&state->oy, &state->og) > 0)
		{
			if (state->theora_p)
				ogg_stream_pagein(&state->to, &state->og);
			if (state->vorbis_p)
				ogg_stream_pagein(&state->vo, &state->og);
		}
	}
	return numvideoframes;
}

void LHOGV_GetImageBGRA32(LHOGVState *state, unsigned char *pixels, unsigned int pitch)
{
	int x, y, cx, cy, py, pcb, pcr, r, g, b;
	const unsigned char *iny, *incb, *incr;
	unsigned char *out;
	int xshift;
	int yshift;
	th_decode_ycbcr_out(state->td, state->ycbcr_planes);
	xshift = state->ycbcr_planes[1].width < state->ycbcr_planes[0].width;
	yshift = state->ycbcr_planes[1].height < state->ycbcr_planes[0].height;
	for (y = 0;y < state->height;y++)
	{
		out  = pixels + y * pitch;
		cy   = y >> yshift;
		iny  = state->ycbcr_planes[0].data + y * state->ycbcr_planes[0].stride;
		incb = state->ycbcr_planes[1].data + cy * state->ycbcr_planes[1].stride;
		incr = state->ycbcr_planes[2].data + cy * state->ycbcr_planes[2].stride;
		for (x = 0;x < state->width;x++)
		{
			cx = x >> xshift;
			// convert YCbCr (luma + chroma) pixels to RGB
			// this math uses 24.8bit fixed point (8bit fractions)
			// once clamped we end up with 8.8bit fixed point (8bit fractions)
			// then we write only the high byte of the fixed point which is
			// free on x86 (low/high byte of the low word is simply a register)
			//
			// get the pixel values and scale up the Y because it represents
			// pure RGB gray, where as the Cb and Cr channels are selective
			//
			py = (iny[x] - 16) * 298; // biased
			//py = iny[x] << 8; // HDTV standard
			pcb = incb[cx] - 128;
			pcr = incr[cx] - 128;
			// scale and add the chroma values
			r = (py + pcr * 408);
			g = (py + pcr * -208 + pcb * -100);
			b = (py + pcb * 516);
			// usually components are within bounds, clamp if not
			if ((r | g | b) & -65536)
			{
				if (r < 0) r = 0;
				if (r > 65535) r = 65535;
				if (g < 0) g = 0;
				if (g > 65535) g = 65535;
				if (b < 0) b = 0;
				if (b > 65535) b = 65535;
			}
			// scale down only on the writes because on x86 the high byte can
			// be copied out of the register at the same cost as the low byte
			// effectively giving us a free shift.
			out[0] = (unsigned short)b >> 8;
			out[1] = (unsigned short)g >> 8;
			out[2] = (unsigned short)r >> 8;
			out[3] = 255;
			out += 4;
		}
	}
}

