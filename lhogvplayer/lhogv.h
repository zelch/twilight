
#ifndef LHOGV_H
#define LHOGV_H

#include <stddef.h>
#include <ogg/ogg.h>
#include <theora/theoradec.h>
#include <vorbis/codec.h>

typedef struct LHOGVState
{
	int theora_p;
	int vorbis_p;
	int eof;

	int width;
	int height;
	int rate;
	int channels;
	double fps;

	double sampleframeposition;
	double seconds;
	double nextframeseconds;

	void *callback_file;
	int (*callback_read)(void *buffer, int buffersize, void *file);

	// ogg top level state
	ogg_sync_state   oy;
	ogg_page         og;

	// used by both theora and vorbis packet decoding
	ogg_packet       op;

	// theora state
	ogg_stream_state to;
	th_info          ti;
	th_comment       tc;
	//theora_state     td;
	struct th_setup_info    *ts;
	struct th_dec_ctx       *td;

	// vorbis state
	ogg_stream_state vo;
	vorbis_info      vi;
	vorbis_dsp_state vd;
	vorbis_block     vb;
	vorbis_comment   vc;

	th_ycbcr_buffer ycbcr_planes;
}
LHOGVState;

int LHOGV_Open(LHOGVState *state, void *callback_file, int (*callback_read)(void *buffer, int buffersize, void *file));
void LHOGV_Close(LHOGVState *state);
int LHOGV_Advance(LHOGVState *state, int wantsampleframes, short *pcmout, int pcmchannelmappings, const int *pcmchannelmapping);
void LHOGV_GetImageBGRA32(LHOGVState *state, unsigned char *pixels, unsigned int pitch);

#endif
